#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="456374018"
MD5="1892a3a4cf17c4ed8bcd0fd95fa32a59"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23920"
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
	echo Date of packaging: Mon Dec 13 17:18:22 -03 2021
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
�7zXZ  �ִF !   �X����]/] �}��1Dd]����P�t�D�"ێ�~"T�^��BƤ6��G��cR�����.��8�"�T��h�Q}�6����ʘ��u�j��M�8~� w�$��w\&�{�zo�U��*����C�h�xIl�dIA?DF�p��
��F���j���߶_?���y!JtO\������V���/�
5ǜ��K�x�X�ER)�c�H���E��8��$��f�����4�FK=U�w�4��\�P�+?-^G�_x[�E$��ש����z����ݚ-�ut��o�R_�<`;G(D���kh_��;�h�cB�B���_	2�ʴ��x�)_hSO�*�y�3B).&R�X��w��2�M��1�@��0��9�b�h�R�*�gLA�������[G���3��G˛�Ī����>J+��r�F��\n�w���P�-���Qb�Д6�v4y���h��1X*���^�^J�c5��3q�7]bYf�9�!Y������@ʊ��^����(j~�bE3O�5����6���<N����r�z\��FTb��&�U��M��^�l*)��r}���2۽k)�IJ������`���ga�����v�2&��V$����i�!��+����.׹S�=�NU;s'��@VI�-��o҂��Z,J;�N<�eVwl�=T	c֜,�; J�e��6����jߣ�S�gb�/
sQ�u*FK��m2#`��MqŃ��s�}ұE�>"�g{#t�غ�$D��!�lΤr��i�4[~qB8:�ͩf��UУ�<�_BuH�@Sl�2��SkC��2r§B�<��bn���mFJ6dc�ʓ�E(�iH�r���8:K1���h��A��Ƴ� ����J���A��_+`?� ΋�u��WJ�������@�`q=3euv�
/{�-ͿS�x�\W `	��]`=��`�w�����:f�I܊7�1b��Z�j�5#��s]�:3+��#�)��uL��}����т�Uh���d���h�K����X٩p�����tw	��{[D�]L�L�B�2��:��a����i͔?'ǯ׾���`Q��k�qݲq,}��G�I|-3��#-�'��6.�$R�Yu��8����pmE���&e��D����N�w�o�Q+�󱮸�08[<$zB�z�7K���<�`;�
L�#&����Dİ��S��O5"�ܝ��`@k�W�g��;s'�f�jS��T��.<��Q�����-W��wOyZ���4�l5o���:o��I�*�����S�8� �M�X���� Q{�h��X��EV�8�q��_ D@9�'j�.�{��GQi�o i3��{`�@-(2��褀R���"$48on-d��q f��7:.�Rp 1�֣;��6x������(�zDh)P0j��g��O�5$m*�J�Ѭ��������7�͕6��f�؏]���NoXƟ�>"�^[��0��e�'�Kf����m9�W��M�9L]�H�ꔃ�||�k��DE��C�C�mq�=pH�STN֦뤰�j�m| ��NxZ4.swn�R"�_��K�L�����$���s;��_{�Y��JT�:�._@	b�@0�b�I|Y;��x��[�d��,������m�t}M	��R*�~���X��noɇ�qDڤ��1����	?��q����Z��M����T��q����l�I�f#q��.z :��NxoY����N3����	���/gd�-L����P�Fѷ��r���g~�bzw����-����{g�띻��a|���TT̜�?�<ꯒ<nox�;0Oe����`��YEp3�%�}��|#�돨c?�$]r|�j���|D����N�Љ���1�?�f� �G��ؠS1��t��]�WE�`�������l��&ߍ%bK��	R�''�K�|J��M6w -.8. vJ��C%��T�&�����'c5�E� \P��m��Ap�P��Y��]��(D��4JS�*ξ����� ^��9PQB�V�Y�ޓ4�!���d*xG�r����*���e�|���2�j~���e-��}mO�b��oy���lj�l�B�~&�d����IL�~���:֩�sX��C���w��q������~�JʛU��8��b������` ���C'�i����Vy>c�]���2�Ӱl��)���1Vҝ'�W��D�v���q�h*/�lK�L4��^�:��W|����n����Q�z`	٘�;�6��x��	�XL1�}�ėg�Y�"
ul���$>rKEX�+�9����ľ�5�"�o�o��A��d,�Fi k����R��A��Z_w&ƒ$E��C����ֻ�P���1�~�aS�c~T	����7�q$���NHa��jC"o�a����]H�S)�J��~X3���t�]�Vm��A��G9�$�Sӂ�Z�!�)�����<v@��5/�k�Zm���&=��-5�-oÕx���Cw�}���L�����������$��C �,������j����:�q�c���5����$��l�y���"V�@D3zn(��*rY�q���qs~�H�OqK���4��C^)�E����n��0=�~%��r�h�E�b�P�d+N���a��K���A���gs�����8'�}��-o�3`��l�.x��+�Tvu)��#2&̥j$�=W�71M��4#�=���r��!t&&�h����0gM퐞�f&����p�O�1q�=2�UL��f4�ly\��(�:�G���H#�]a�ϡ�$����T;ů��X�ST�KmuO6��YE�M�k��ԗr}ExR�UlU�m����<EY�
y9��"m�"�B7�?ٱ^rm�[}�8����~i;�C�z���_�G"���1$k|"��0E%��C�r����*�P��xG%{t}���b)0�d���OMj��b;���;nV9�7�󓧫%�[��+�ZF��o���A�ʣ&U��s\Ѫ�9٘k$�n��e1�1�Q{3=�0���a��+�ռ���l�K��c�w�t���럭�x�>�}'�l��7��+�aۦf��0s3X5��l}�XS��<3�Ӌ�m��I_�+����I,2_�����Z�y��b���ž�������H��oϐ�S��i�H�a�z���{�ZRg����c}��u5g� �`R�������3x�s����ǁ�4�b7^ ����)�%E�~X�U�I6�q��k�?j�|�-�q��	TkM��Ѳ,~r��l�u�f\_��\�Ϊuɒ�F��J��o6=��b�A��}��xz7�q�������m%b���hd�i���C�R��V$��}�)����	kv�0��T�X��f*��z�Nˈ���D_�����g'�dp%P'ж��5�W�i�]���e�~��M}��k�B�x�45�^���mot�cT���@���+:zʎ0�CR%�ߩ;��jD���˕S�I�P��/k�%[����e�N��c�su�v�,�E��I��Rm����I�	�h[�L� �m�խ7�m��%��`��d�h����m�R������̈�a���\�3�?~T�a�2�+�$�&S7�v� �;>��H���|.A��JS��q�;$�Q�
W�7��Q��VءJQ�����AffF���6}���	�i���)�+�߀���L����IU�flopնU~�"AR��c3���6ͺx���~�8G/bsDֿ7��0�u�}���$���~:w��C:������#��ƙ�Vh1��:����;�TT�ߔRu�v$�����R��0W�:�:k)�[^g�CFV�(�O�k�m�ږ�?O�J~���'[q��
�H�3b~ҝ
�qP�.耖���G ���A�:��/�c���x7�3�$���5�H-2xh�3�R1�Ñ֢����i����ww����N5�fX�@NQ闝=�F@���t@^R~"�\�a���0�wƿ�Ə+�bǛ����+���w�r�*q����M��`K�`E�;N1�%��$Z0҂_�CdB���,/1%U�Kv�/Y�2�I���O�A�_瑒��"7zܸ�����-f�5�l��o�B��z�G�ȹ���	� ���e?6
U�pB ���~��E(bJ^ B���'9��,Hf�揥Bm����
��-�]��~��2Y숷\�2E9��?$��.�||��)Ցt��I	d��~{k��j;����@�k�9�pž�f�tm�H���2��u����;}�&SȒX����JQ"۶ ��l�� �0�G�%�s�\.����*ͯP��1͙�d�8e���N-� m(T��W-s�����
А����t�Fg�y�1�Fo?�h��� O2���`_�>�k�w��B��x$���5i�h�	���E��?�J��΂�����0oA��6Bյ�MZ1�s쭕^CȣA�_8�F�Հ(�1ބ]^;^coq퓒�E��C�P:��"�c/Q��;���#�q"�Z�l��_a$�/�`@`hi�i@��>�'B͞�;g�W����R)[}��z�̩�*��~!t�s(� ���1E���_���Ji��+S�TH�qYx(���Y���Jѵ���'}˦�<�-*84�;N)�ܑ�G�A�tA����	f�,����:�	��S-�_EҪ�uQ�Zo~ƭ��G�ւи*wMH٣�Q`�)�G�:��J����,���36�R��6��B�j]�ZKn]TU&��~DI��+�!cȣP���H��B���[��|i� e��Ҧ�	��}1��5���|Â�ӀN�����Bk��B�^��ª��<���� ��0Q�P% E\�Se��q���G�O&��E���U�
�����,'�aZ{y��o��
;�[�����[����(���d�3���T=f>qL��?!� ����g�3ݰ��2�&�����r�K�i����C���&����.�UC!�$m@X�r.J?�o�.(���g0:��G��5�7'iw��]>(���{o�N�*��&?Z:�,8�L[�	�!_�{b�R7��\�]���PA`���WBY������ ��"7?�M���1��ٔ��R1u�q�l5�/\s�&W�a�J�߄��G_T�,=�Dj����~ A��1�%&��M�'���v|?x��q���'v�m�59 ˭4	�E�C��W��͗0���~��R����`P[�}7R���cX�ݫ	�`�6�_��v�-��J������W�揰�Y�y:�J	>Y��d7څ {�����ɘ��'��~ύ���(���`̱[8�a��k
.,�K�lG{�I��eH�	2�F�rX����~���/!���4�ַD���@�8��$��2�o���jk�������P��ɨj6_ �|�?�iJ=WH��Ra�>[��E5{�"�o����f�C _��d4L�b��䭮�k�q�qx�1�[�JN� ̊X)d����X#&ZNq�h���������1���& ���=}���.D����#�8�k�9������\�zu��V1���> �����XN����w�Sk I��@�ڋ��m
\�b�܃e��L:Sl`3�m��[;}4	�eIk�p䡄����	�c�|���D�L`�2�A�X�Nȴ�rw� 1�A��6ş8MUy���Z��,�F�(�է�1)�"F�_��2uٹ��Y@��a�k��r2�dMڠꜞA�bl���K	�� �O�X�J�m��IK�'��{ �P��fN-�Ŕ~D]?����U��2��5���v�+|���Ċ����b�� �?BBw�i�ԟ�Z�U��_/�	r�n	6}�%�n�T����_��wg�6�[TA���~�*�����8��W��@p��]�ʿ߲G�.���B���ˎYӖ��2{ӕ ���"����I�T�q��vsAe�]iBx	��΁[�/���t�8��q}Qw��d�I��޳5�9����9��"���o��1?�;W\4��0,�!�Dz�=b�(���j8��ͨ����2�o�h��sM���|m��;����D�9W��U`�RT��z���~�f~��<=e! 4�	.���f]7̳��YZ�f�����(,Dӎ�
�b���� (��vn�!4��u��>*���^騐���ʧ�j�#"Fd�t��!;Z@X"��i[;��G�ARĚ٠�����t�H�AF/���a�B�u-H5��Fwc��&-��{w�U�,�����!L�r]Z#�_yI!C����:�����k��#E���h�bc|�5��G���H<4Z~��V]l��'�r�N���̩�+b}�l��4�\Pnh؎�ӕ X,��K�}HO��o���3��{�.\����	8��ԃ�O8Ġ�!L<
�6��)7���Jӗ�Y��!1�����#7�|��`+nLd�r׻bI,�O?EkR�c�Vj�%K�5&i��3�]�*�]��3�*�������T�v��l:q;�ZN��9��C�P���m�ȻL�
2�A7���8����o�&�,?��y
�Z���x>��7���01b��X���x��B�G�8T(�!l�C~̹+t}������lޞ�a�b]�ϰ�r�^z�˚�%#�i� �{N@	S\ɵ?tId.���G�J��EE��	F^�V��.ï�µ�EL1�e(R^]�Ek+�[�`����܎�t��Ik�LY3Y�ٕ�hO8s50��^�Z�yxY�d��?�\��)yG�F{�%x{�\���3U�6�_"�h�t&�F0��,�]ǡ�)c�/^K'��)!h$��G6����ɧ^"Cj�Yw�;!�P&UITk䘞�����]^��&H��E��`_���a]�5T,g��:`/�����?�����u�����Fj���4{DuF�����]�����/�Gz�mGC�^T�-Q9h����KH�5Ēz�Og������y�V�)ll�Ӣ�"tִ�n��Hr�^..PP<W��x��D�[>Xj� ��~@�뷘R%�Gu'����e����ըS�W������\�_�(PB���Z�bq
-���D�ԣ���M�,��7u�g<����܎'�X�'1�_��T��ޏu��&>�;�Z�z�M�Lb�	�K"E>B�'Dn"�Er�@K��x�J*�8\�/��*!�����8����)~����̾��jq�p��3
��G"����'6t�nJi^?)Ge���>Kߔ��*y�g�&�R���U^����3@�x'�����n���� ?�{��B�{��g�!�#1�zJ>���n!v��P@�{3SN?����g���j��لM2��@1��V��.�I����Ԥ�����C��|�O"zYɾ�E��-� zG�m�{*��<2��]�Z�=\�^��������z����Ry�\��}�Ƕ�TKӠ�����@�����ڼ�ʼ����R��W��\��#K�����Q�`:�O>��3�n�2#�/�O���@�ONPm��Uː/�(��LzɉY�ֶ��4�P�4�D!����"���U&�{��hA�5Sj��������q;_��Iﰿ֯�ID#tX�P�_C�'�繍<zݯ�~�U$��R�d�K^�v�Q%4�ꓼ������%y����B�+ ������Ԋ��D,�D�±~5��$b��E@�O���q|���|_=|�>~��R�p�tݫd-�~~��+i��qKI*a����=ߍ�ȵ�<�NU���T�A��(?{PmO��,�_���Z�S�P��.5��h�l��EY%!S'�Q
�d���`���0e�2�W�Z�}�N~������
��8�}��~�l,�qp1�y�{���(��;��9`�z{�6K��Uhk�/�������c\�S��y5��$n�(+�S	b�6��0����@��Y6����6��tVMv�"���v���phyN�r�]`H���9߷�̫�1�ub�jA��8i= �Sj�n�np��|)�R����[�D�2g��п��D��l6ǳ	GN�=�*/s��oI>�/�g�XI���4�Ӯ"���6ə�� ��ۀq0�Z�Y-���{�p�r��㟀�/0`����\ܥ{O$}|Ğa�o��+۵�Nn����Y�X������$��������F�I���~��xr>(�6U�k롗��dk��/��#�߅ ]�������uB���~y4�u���o�|�9$?�;��H�05\=}���m|��,@%��Y�Z@��^Z����붿���X���4��tQ\�`sin[>Չ��eA� �p�Q������p;�:
kݷ@d%q�3���gU<�[1E�)wtz��bu}������
p}�謄H�!���2H���.�rB]�p�9�ks��0r�T�~��W���5��0��>�^րۡ)g��׽���k�u2#@l�G�F'�Ǔ�.� �2Τ�`Ҳ�/|�L�2>g��fN�^�L�~5	��+Q�i�fZV�����;�D��,���|D#Ѧ\�P�Hbگc����ks_C)�����33�����T���}z��w���~�lSI�4U�m�W�k�?[mB�M,$�Ȧ��b�.�_K����.�y��viЖ`���Y�+��%�?�ň��s4vG��-��Xچ<CQ�1��JL0�Rgh��-�`�K�/���wO�)��J��]��A�A�s��NH���n���N�R�m���`�N+Wct��	�^��f���[Q����GJ��x0���h���.6ŷ?��Z�cR;�A�05~Kz�F���.�mr><(�m�����٬�*'\m�%�[*�x����ٝɕ���'��a�BI��*V�.�\��>�@�����/�G����5B&�g����b���h��-QZE���Տ��G�VO�W�!j'���ݺVA>�|J,�7�p�q81�#5�cf#����1�kPvO9z��4�~QNt� �p��ȉ��t�Խ�x��_c��jr<үN"��P���S���ߋe��@Պi2yW�P������F��ZV��Vӣ�ÏW�?���/N3�^�v���'�����ܑ����:�����HI+/��F� �`�q�]�}��P�yQ�䙾�mt�TH9���g*Le�3���/d��t1�܏��`�m�'38q�T_B*�=�J�N�,ƭ��J�HEz�����JcN���H�[�!C�2�Y��#}�^2����M�f;�F��uH#��K���ּ�W�0A�$�ˤk�~ؘ�Ku�vsN��ۛ����֚����f�'U�+�?�Ғ�l��v�;�Ԧ���8��u�����{���<�W�]K�7G.��+�
Ώ��b[y�+��mL�hU=�?��s���mCk0����2)�����B��f'�q�,4fo���K�B��t�d�|��#�T�8B�^�Q�xHTn���Q�Ej��"j����2��q����`؈��;$� ��m|�6��Mo$��*�_�
#�};pعl�!0d$���8}}��s�����^��v���sy��@��B�'�����l*̽u#��ڠiL���>���U,�#�\"�׊j��:{��u�kML��/�@�A�t*�,�m���,��x�S����;��}�9�NsM!I4�?;1T�.Q�Ň��l�%�8�P�?�4ޖ��l'_�B>C2Y�����m��m=>g/^�+ciK�5ͨ���׺��`'Ut��N\�Ք�}	f��H_�9�&əFQQ���O6��`wr�:_cf(x�����~�t<�G)�^��f*� �n����
H��ZH[T}�?QyY�d�L�hyx�r��ϓ[�I���i��u(��n�f��H��8����Ǎ�-��x����31A�~�����~�Y�G�����T�oo(Vr���b��2uq���5�
��q�4�l�l�%����a� ��g�_X�;:<��M�=(3rK���f�6��c:�R9����wx�b��M�fd�-��n���I����q��H��V2 �������ǌ��r��� ۳,��^�K�l(I�(b���`E�\�QP��x��&0���f�=�W%"�oy�(�v;�u�#�,��ZJ�ջ��!���mWB2R?xQ(Z����j��D�Ҏ��|t�:|��/_�?砚���<z~��>�M�Ԭ�\��O��k��lx�He�a��=n��lP�L�����
��F�wM`(�I��
������ Hq'�,Xt����5���!�>�U�U��g&?e�:�BVo��_ӬB!�^c>Q|�����T�`�2��L�uj_7ѫ۷g��h�D0XV;����$I���U��W���B;�U^e��m�5��}�$��*�pɞ�TD�Օ�-x�}d4vK^�S9n����%	nR�V�&MY=���?Io� �O=�`�T���5����Pjb�1�L~�i�ur�x,��� 졼
)��Z!�Y���`1�Ę]��C6��El톋ɒ�*L7�}|>�h�0Zq�[1�|V��8oS����3�L/aC�b��\�w�<���_���fֿ E�\�`�o�Rٝ���և��-˨�
d�����*�������\��?f&���IH��y��N&���.1ͤV����Y�Š���GJw�z�5yH�m���8��0vp4l:x4�_��βՋ�%�2���5�-�H	�N��6!�/����kuA��%�е�#���Lo���,��{�C۔8��WW�<�$Ke����@�1l�ab��S�EO��>���`L�{�\�3��2�^�TK�Kr�U�,(�N�\>�=���ۉ�����ct�N&�D)
�i�����*Ϥ�y�u�M���|	 ����4�@�a��ޮk
5[脆8�Z1�֑L�m%�6�,��)�=J���_Q��wU��"u��e�ь��k��6��g)�aG7� 3\���QZ:.>74?��}v�9�4���J3$�'p|�t��N9����B2�	c��9+�Y� �t�ŵ\k�QnB��qf~��Ƿ=<���q�1i��'��<�FS~��)�!�u����Xֿ�Ƚ��?p�|��x���$)F9g�s�ڜ,b�fD: S�)��ra�� ���g�B}�`���/#߆�/_����|IIa�m�.k_�-�+I�����jn�d�Z1LBJ	�AKd\qm�-�~��0]�V�Z��1Ě�!�G]��1���et�!�biaw%��8�"��U�Q�؅�I�E�/0�Y�xk.���-����B�������椓ow�d�=X�$�[-��ԇ��T�>J؎�����*���o����̊���t>n�r�e%�<�D����4��\���L��^�7�jG�s'�P7���Q.�ڬ�V'�mǡ(
���:��͂8bᲇ&a�,McZ�h�,������ͮ6�:�����A�t�xKԌ�&8�d�&>t��ن�xY�֥n��A#�X����]�:��> 5���MJ��x;H�oI@_����Q��I��W�����O�t�Ť�g�u���q����O)P�Zv�I��]o-���]�Wi ��`l{�<�=Hd�����|���	6��)^-���B���. 7����d���6��H���-Ӈ��|�d�!o���CNsV*}3wG
 ��i�ޫ�*(m��uV�/��xۃ�q����y.S}����h�d(�C�Q,~^o����k�Y�!��y/)j
J�N#�c�a������'O���1&+�"%��]��5d!��H¡�\lIH�̄
�hxp��Lq��\�=�����.�u;�גt,V�s9��X�*�.�?�4�N)��s]����͌����h�V.\��ev�@�pQCӆ=�������$����n$�頴dhɚ��f迁*��Fw@�n��q�vڄ�t+o8id'�8�����Z"��/n�!�J�l�� ��,8�Rߥ���|���w�<�:���/D�ap�FR���sX�P��)1fljs�lt.Yʟ2F���"*�>%�D?��M`��A(>�*.� ح�L.��{��K����_��<	���?�<B�G�p|7W*&�q�|��#���S���Rĩ
�x���F�S�L�Dg���`�i��ܷTD���`,Ȅ#��,J�����N� +�`o���|�gk�����Pd�s|�\��iM9��y�����tt�\h��9�4K6$7���/�h+�7��{u@�Ic���i�q)���(*7�|��G����?��{�^��B��%N��C0�f,OU�葿���^��8�R��q.B���t�T_��w�m�n)�;�ț$S8ߛ�l��vLRo����,��X��[zЇ�@�����@)H��P���N���)���-4��|����u�u=�:��EL�zZ%b��s8�c�(@*�?ќ���3J�B��#��w��J��:E����)b��H�W�`Y���K��
�*���������Hv�9���ɤ��{�e'~��W��g��$�SP#���{�7�#xd�_&8>��)}]���'کˣ�i�z.�ctH���A��Nc%�I�g3pk�q����aB�i,�s�k��S��d��/����ٷ\T	�t��)�w�����]R2�����;�BU�]��	m'�X`��>������>MU<~�����������z�/�\��Z͘"��<���a�-U��GT*�����G"O�(@�����V��w�c��ȡ��C+�V���u'iۇ�ގ���v�rk	�^b��E�b��0��>�C��z5C�ZD"T�x�M���զ��Nwy��"�U~1��~�.��d�f�P��n]��9h�|�^O^Z+�c��M/���-C�dU%{w�`�Qy���/׿M�
`Fzg���|��"QD�0�i���.U2�����/KQ�E$�T�^,hA��]1��ͱ�)�\e�DZ�Q����3h��265��I!��������OP�5��s��Ck׼���B���8'=D�<��9[ rJ����,�`�dG�ma�v�L7��푩�h�A'��K�]f�$�ͧ/��Ґ�f%%����Y0��ޮP`
�"?��LY�`�P��R��Va�ݤ�х��袞�ߍ��-��e��5�������
`�C-|g�%�������w����_��?u��0�h�	�����3p������DI�E��-�D�2u��V.I�(�Ր՝�yں�Rg>�:�H%\�T�-���sܘL�M��G������V7��b��dQݢ�cŅ�c�Y����P�V�}�b�Ը�$�H%]��e�)�O)|g��;�1^�6���v��m�{�gIw�q:�7Y��+~��nj��yv�,�t	�drW<M�R/m�t1��]_�_=ۚ��>UUr�^ϊ�v����7�d�3�4!�B�G��8�]=���%$�V�- ɪ�H�&Z9�AJw�n��5A�8����B�A�|P%�t�̈́e4��'K���Ɔ��|Shu�B����}�����L�EcA��{w�ʌ��[CY�������������w c���^zR�{Z[�߇�I'3{�@5.g/T�-݉�/,%��,�wp���W�:�>�����	|�v[������
�����4Ŕ(��Z�z�5J�|)x�g1�]z��;��d�,���)�*��,��9=�(��.F��/>|��CZK]�^��8cX�����l��3�G�l)F�TYn�1�E<H�h�L�O`�%[�g�����[��X�o�B�fk�tS��V�%��!.!J�*�yE�~=�pL��mE�<aJ< >I���!Zx�X�)�rH��\�n0$���0�L��|u����0��3؉��n��)61�nw> EQ��8�{��MQ�����CLD��Ș��t��5m �[�!+��RE�+�^%�@&W+Om7���ߥ©UDq�,�qDa7
���"\��j�����KK�f�R"�=���r�G,��m���O�/��>���M���ug��2�w�c��y�DgT��V�B��D4BQ��>��[��l��;��];����Y;�/hp�)�ym�?���"�gm��K�6���u�j�[��-������a�f��������]Cv�=�T�51�]��,��l9�*�/N���s�� �����('v�H�bW���B��G]B�B�S��_V ��h�Ų����V�
�z�1T~�$�Hu����BB`���1lcD?뀳���.�)�73�
��R�l*|˛�5V��gDR�/����&Y)��Wc�E�w�Q���L��G��/��6��P��zm&���z�P~��ޕ(bxkP���� �o\f�j!��R�<��'JD�怙�N�" K�q�N~��5�N}adU���=��W�?��1T���m7#��lupss�����ɼe��ħ�9��66	"b˛��S�8��8c4��������^r���QB�f�E�q��=�:Ox��KS��Q��|~�t&N)�|�,`[{����Aϭ�5��>�a�2�t����N��� �*���|�\<|}��K'�j��ș�A�����6���ԋ�~���!ȌC��ۺ������q0"ɉG���A&��X�`�W]������	,�?[B�h߀C68��;�!�_1HR	����`���ڟ��]��nq[��*�=lc:��� �vg��Ϣ"NI��袸�y�Q��{.lif:;>�>�3�'˸���ڙ���3�85�_��u'��>��	����ߛ�}p�ޕԿ�����R��f<�LV���v�6�{��3�ZכƇ�`ĭ�����QN&3H��+zQZ���ћi�'��T��DP�C�p�P�u��/��U+o,��U�'t��ݫ�m�3-�g��z���t�t�s
Ŵo3xH�d���Qх���f��	?x���/�{��{��|�ej�W#���qf�^^���RX8p<�yI�<q�C"��'�'�h�V��\�y�#3�,��d$�?7!IVĐ�7�	t�X��7����V�)\p<&�j�5\�b ���o�Xտ�5PG,���:�k��� �y����a���x�$�0���y��C�JT'�\���W��?N��NK���	6r�ĳ��2Ҕ?�w��8�+�(;C��.�$�sǏM
ċmO�+�vᵳ��`��c����~�z�ҏ����$�nv^���� �~�QNC����{�4v��BB>6 xm��!��S�C�?�Z�t	{>{H�P_:zQ�&���4����.?���w׆��8�Р��Ҫ��д,���	D�u�p���<�p�M�t�ފ��� l-��Z�(��?{r+!�)il�G�`n�3�#���(�1�k?f�4,�#��g._k�Z��Kr/���N;�v�q�����f��}�stZ� $Mj���6���R�a���<Pݻ�3rD^�=?0���њ�{?d�R�<}���.V!X�T=��ᅘ&�Cq?�^�n^����G��f�̫fJ{�tt�y�Q���EdA�����$#	�Я�+i��[�G�8ʷ�^ˮ�%o��D��"��$����M_ �|WhI.'oi�m���j�P���1�K�	bW�5?��IF�ҢM��=�2~�Na+-��|��B��>�3��7�|{2j���';׵R�p?��:|���T� �E�����=\�C�6MDLO�P��_�PjQ{������9ڤ��Ll����m�C�;��D��l:WҞ���:�����c(�2�"����� ���w/x@��
??��9����yErjZ�R!L�g��2v����ye����bj>��t�ն8�� ����&(�8����68[���&�k�G�]�^��������tJ�cxy���G�y��������"����Ar�`2kVjxlԊ�pڊg,�g����Gj1���g�dy1�r`A;��S<�Zge�#88p��7塞�W���IIqٺM�Yr{:b��_`S݀h	�Lp�d�:[��5A��/M����ND������E=x�Aq���K��a�n[ҍ�Z;�3O��ՖI�̌�|�ɂY��K|��wwI�[�*rg@�_c��~4��m�����ϔK���nd�ɟ�Òl;-0Y�R�~$��q8�)�aB���(/��C��w�6n}x��F-����Z�E�'�_}^j���ƻ�m0a�:�ǎR�_�j��;DB�4�/�K���l�������֜��5�4�Tw~�-Ȣb�8���Ua1Eٌ��7����U2���?�������n�iY�1�6� M�{���U��%ga@8�Ǿ�߃z�PN8d���*M�7Y�;1�x��H��x�	5����ſՋ�� ��Y�S()?*�r{������������$='Ig�.�}��^O,<G�ō�:<@�x��ژ�kz��B�m�}��'R�\<�4Pk�)�IA֞��q��2y�m���y�-:sQ%�6{�m٠7٘-�w��h�9��R��fN��u�я�����Bm�e̊��J�lK������99*�o�cR!.Z�ܦj�Gހd!����Q_7y��:�ƶ��t���Yi��	@$ڣ��!�ō�(#�ph`L�;2-CiEc�6=�&P/=����٧�Gu��t������U3^�҅��G��ɌY�5 0(�W�pK���y�h�$Py�΄����Cm�Ǥ`h[7z�Y��kk,Z���Nk??a� Fത� GPx���0ꈟ�)�#�!9��=��K`jM�����g�N�JI�pېIt�H�Aiz��޳p�b�>�Q�zO�9��U�>p��O����_��'��9�eڋ��䦏�J���Up���Wq���%�:�K��/�v���+��;�f����*հ� �u��F?`�Q<TK�~;z�6�d��{�B������p�ME;]�姨H�Иx�O�D�Xyr6����~�x�1�l"���׊m�Q�;|�+
�'�P�o�'������Os���{R.��]����e�uX�v���̆���H���?D�;�����*=`_��
q�	��!�v�]�&�b��GP��G�ȯ�=
Di.�A#Ѳ�Y[\d׆�rBqʚ����������5��&z�!�ò��[� a���j���&�\@�t �*�R�bߘN.�d�lG�~�~�������������D9���mZ:0�yɥ���k���0$���+v)Fm}�8
4���k�y���j���q���P��l���7��x�Y���P�k����*�s?Mn�.�.6���n��Ewp=���^��(!g��%�d���4�0�����$��i���,h[��Ue���q\����C��㜆I8PE������4N�}�QE�!�Q/T&��ash��6���JAw+pU��	�7�!?0(0��IB�&�g�O^�"!тXC�-ƚuU�' �zqwg��'!���z�&�0�Nxm�����;:�d�݉!:��b���ܒT��mS��dg��P����x�R	H�A����n;�x���E)�os�/�G㝽�sTG��K�O���'8E,Z�~�L�������E^� ��.f1��+s�z�� ]q�����m����e�.�i��q#wʛ��ϊ�/^�v����Ѥ�'���:x���vT�<5��/GTL���q���4�O/��fQT��\���)_���e}3�S��g��{��n��ϟ��H�k��_1K�X`&8�����b�=*�+M\��'�2Ȅ[�w�jL���jz:�U1YvW���v�#D
���Ϯ�P��A��QS]���������p~��|�_��{�;�~9q�Y�[׉Ǡ��+U�"�J�c�o|6�{� �._}$��.G�)1��Ƥ]��+1���P����*�w��0 H:��J�7�O�*�&����P8Jq�C�z�qi�A����	��k�c����i��#�\�?�֎����Y'��	p�wR���YQl׹����a�]�1�-piMo��Y��-���k��T����ɟh
���?��o���찎�pC���U]������q}�!�*PH;��1��F�Lђ��D�5�Č
N�}�2��@2�|ހu�^�\?5�W�R.9��c�~Y�c���V	|L(e`ʄ�'r$Z�*ER�~Is�6���Hc�������h��F�A?�Z��>��R�ח?ޯ�4�/dI�Z$���@�� A�G���?���?h��į'K�\US�b�U���َ\ 1� l�	�I^�h�/������avQ3�M�8Z�N��h.�-�~-c��g��ޥ��-�MG'�v�����7����0��M��d�Hx�ϫ'$V,9�T%ľ�:�'*�ԇw�P��PW(���șY��,d�%ʘ�ԈiB�S�Uy�W��{|q�N�HY��j � ������UC�]�9�m�q�!ϼ�멱PP���Ty߉��8���6��V*�t�5���h�S���I��b@O/�H�D��7k�\��\�i������FU��9�_����׹�e��I�1d��a|S��EK�~�N�H>q�A��j�.���|���a�0��w���}��?�f_�4�$0�h0U7��ƙ1��N�xӁ�aI.�m�R0��(  ���a�6�2����?s$?(]3��>��`Đ4���F��s!/q> �	8d!�0z�EJ*y�T�b]�v�S�3�;�^Y�ȓG?�?�α���u/���7��b�7�e�r�c�6-�TU̨�XmQ�-���e�D���ck+�25	���oq�2R]���b�����0)_S���$�I�}���+p@{>�y?�ZKt����L�鞒z�t0v+w�Xh"-�D�Z����_�D��G3{	��ӷf�J���X'xY�RCf���ҤY;�ţ"3W1��wB<�K�'�K��j[��FL����B�c��v���W�e㸴�)֟>�.51!���2`��js�g�Rc�8�Ѿ��lֿ>r >��[���Q����p���I�PV\���#������q��ѱz��<(�$܀�N�����hE��"ĈqM~�A8�>�+���g��d�G��S�G�=���,�ZEx��{
��G���N����6żP
�G�3Kp��T��k��FHO���jP]���,T_�~�z�krl�f�d����������+��ywfI�^�,-:9�4�2��2d`z��U_��)��~qff�KQ���X|�gy�T��������azu�q�.F��}1�}��b�Df
g�jRH6�"_��:�d�4�Uu�Lb-�o�~�(�y�?�e?�ʇ����	m�+�x&d3|�b��c�JF���Z�~��[Av��䳠���\ _r��D&��O�,㏬	��1��)��#t�xI�ִ���]cg�7��h�-F�Q����CQ[+�=��5�˖�e��h|�hc%�K�������k��HY�h�͙�Q��R�l�-�X���T�g[�	�u0�p�}9v'�q�v�q?�d��N	/��Fɶ�>ND�L��3m`�#+r�ck�V.��!������٭@3"␄t��Jˮ���%;�̹�T�N�㚺M�<��jm�5E5^��锵�?�7��g��Ɩ�k����0-Z�uD��Ҝ��lя0iq� 
�L?��"^����b���6wRg�<U��6dS�Yt�k�1U�Nh�1�j�X�n�\���6��O[Pk���hM���3��nP������z\���8b�����^2 ���-r&Թ���7A�\Fz��:��@_Bi�I�#��h�釺Ay��}���2�`	e��(�&��9�JJ���<��Ɛ�a]�:��w�Z��qi%Cr�A��'�w��f������9B�n�����9b$�/`��9�X�AJ��O���o�D)���\>lr"�����9�xdC��X	�^�Ix�SfS`/S�yA�Ҁ� *v�TȊ�D�v�J}:�*�
��9�%�¨��0��\2�<���j�ű�j_��7�fy����o����B~���Cr^A*�� �����~�p��j
��[�DHO��>ء+g�G�;U'ug0��du�B���r��́��J��������l����1g�h����L��#���e,9nF+C����K��ܻ#�mRfil����5��K���;�}�����bqZ!Q�ٞ��1��GA1�	��
��X��MrQ����MuW����G�NH���S�1O) k�����p�9��.���9Ħ.�+���ƨ�X����k�G��
�d��f��].b�wG�V�P�H�j4O�񚆐(\8��5]��],���	����������V� �4D�1��<��M���(B��`(��w"��b܊�A��;khU��UL��ňdc��_��#�e��<F�N���O��<B�ee~9�9���O���ӄQ¦Z*44!τ/J(\$��ʌ���PS��n���QX��Mt�a.�ĔF���G^�����؃s�}Is�8tt��SO���a�h��ȶ��)�F���q;]	J�h���CtM|�5]ZEN���:��i��Ń7�ɮ'�0��s
 ��$U�R����'���'#��Rd����O@�I^�_���U��i�C�+�j8w1�T�|͆r�=���9bU����uo;O=�;�E�Iȑ_��5?^��n��n�Gz���Ǿ��N W���!�gi�$��� x�`�&���Qa5N��6@=�J*8�e�%M�,g��o^�=e�9���N�|m�ZQ2l�|=z��5��,��&\�r\j��uR�<�JIA-���1�C�MuH.�9\�~�O���S�X\gk7�Y�YQ����MN�PJ��F@��ˋ?n�#��awl�TZ��l׾�Oa�=����#����;/��Lp�D}D�_��M������������T���rR��~�'l�*�Dn���M~�4���L�����7,�"���P�fa1C�o�.��II��p�9��9�0aC[{c�QE�,��lYC ~ݯsn��cy�|¶X�Ҏe՟�E�.[�S����Mi7"��Ɏv�⠣}��a˹� �ׯ���b*�t訷-{��l�2`��ϓB�_k����*�8a�5gS6.�\@Ń�M6O�bG����Ѻ�Y\~8�d���g���Q�:%�Y��M7�Hy�EY�v�\�o�25$�*��C��J|�t�Ae�����_���&�{K�!�ZN�G���t�,��f�m�S��Z�(w��&δ���620�'bi1I��>���D��VA��iAuȢ~�q�y����5�o��♕�r��=yR����Z��Sy�ג1}�X�ݢT����޻�N_Gs���?-zE�DLP�v����}���u��_c�}%f�Uw߶V���2�	�j�g=��K�sf��,x���t��}v�����g%lLY d�!��&���.N�l��
���E&1�F���g+@Qe�"lMIg4"�7D�� �3�HR�����ݱ� B��w��&� *�@���l�.9����=�O�C��{b�����Ct��)��z#A�d�U�OV���	w7�M��=ݫ�1�"[I����L-���q��l�M�pY�Z��ct�}��(	
�ާl�.�sBS=7�<{	��'P��
��|.FF6��_��@ǲ� HMɆM��('�J�r��bT|�F+�>� �o5�G�\f�^Z�Q{6��9`��Tt���ꊢ��=��m	pEa��3D}�M�]
�>�;5�@�ɾ J�Gb�bSr Y�i9�r䉉�f/�̉�&���\B�}7��3K6�gC�O"��E�b�@�cI���Z�-11V�f�TxwA��Jv	ǩ����;W�]��)�-�`�@xt��꼼�H�hz�u�F�w3�/�>,��!�`g��)�P{i���jY!��(�
|�Q�ˬ e��q���pG�����p積f�I��*bҨ����}���i�?��R&"yv�I�'�S������%�S} %<i��O?��)����KĈ�K����Gj�v7� 3�L�)BD�<���́�E���^�36������CD�R�{��;�>�ރ�И�|BG�csw�^��xiÈ������#x��6S��]-�;O,�M�
����V6@��pGoq�0t�Կ!PM�v#�13�^>�l��I����j�ڔ���PB�k��V���p[���
��9�t���>���6�Sn�oE"AwJ$~:�a�J�HH�-a���	�W�rt��>��( �g��"Gc^�����olJ�f�p�A�W�^A]t����}Z瞔gPU/�v�\ޚa�M�/��$��O뗼��I�p6��)W�w�t�S.��B)O�;���;��㺜K���QS��3� ���Òn�z�d��y��3�]��(�)������I�$?���C
��zE��T)��-	H�Wc#����a8��@+w?��9*�I�A?�������Fu턾��Hj'�$}�#[ܠ^-��i�=�n�LJXϷh�x��6g��TY�$""ϋet�xd�yS��X{��"�C�xR�ˊ8�a��S߆z�(�k�Um�������!����!��ٔo���I�pKn�7(�,8�9�ƕ�>�f��+�8c�/N���1��;ٶ�i�i���s�X\��Z���'�'1�����DS���
���4Xg�rS$6|S�A�c�yTҍ����}xG'�IH7.��r�}�X��M���$�N1uyk�Dz����x�L�o�>���-j
8S�p#n��	��m8��������d�aπ�;L"�b�
�.H����E���uD�w�RIL`���3�j�,)�jQ)7V,�A�=z#reldS�Rǲ����ܥk~~����*U�MG��/�=.���2�u��]<|�$�._��Zz�h�m�������%���$�r_{T��o8�!ơ}�v#��J{��F7��_l���)��}����<�0`_�W[�\g�B�'��{��lk��
��}= �|*�]���Ď��@��V�!J��S�Z)�,Z,a:�MK��9��I.�jiܖ��%��=�l65��OcS����P���!+:�,���|������� ֊O��&�.����!��AR�i�q��=��L^�����5J{��Jݱ�k:/��Y�
r���U���1w&	�ڒ�RZ�����j�no��v��~}3 �#ڛ7���q�|K-d�
H��Е:G�����;�Zs�� ��n�]jxܛ�� �h�����jha��JkyP��bm����H�h,��H
'�� ���G�����ȳ]�y��u�D���cհh�ڣ͐�}\G����z}�ۏ�_���\���O���]h���*�����,<8�R���C7���   �q�9�7�  ˺����g�    YZ