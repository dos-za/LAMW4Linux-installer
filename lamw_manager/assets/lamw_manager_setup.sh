#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3372042087"
MD5="e27ba46425308da0c253d5ae81c9ddba"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23332"
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
	echo Date of packaging: Wed Jul 28 04:21:30 -03 2021
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D���C]FVK���y��e~2_�z�uVQJ�����	W=)��������t!���=��U��U��t�")�f!�C�VZI�v�RB�F�?��g���(�1ˏ��6N ��6�$I�877��m��k��l3M*8<����IWq���)n�jĔ�y���2>�f7@[�V��%f��ŵ�v^?�����2�̅٨�=1���͌c�(?��e���d	չu�b;�6�q��pU2G��Y+�W�%���/7%�u��d�+L`�hv��4�������2ވ���(1�y�]&���^��,�*�B+Fk��/L�]��H|T/;��멵yM5�wP"}�_�m����Ȫ�΂=翝�7*�p��8�;n�;��/8B�k1Xk�gq4��5H��q���f�rF�	>�vz�{���I��%��_�4M ���9�Ƙt_�����ME�\7z��H�+&ݰ���ڤ�(��Q�b���!1M�-!2��>�*���ӕ_D���1��i�t�*&��2�O��� �QK���|�M.���ΰ��s!��h^"9�����zCx&��b�3HpP��GS�3�#M�,��,Q�)R��~�C�=�t�)����/y�t��s� ���%ԟ�81�@X8]>��BEgg�࠯%�Z��V���)�����>1����:��z�dL��}]����b��G�p	.�`�#ވ(w�n��?Eik�f�-lȠB}��Q����J+��"�=�x���c�9����E��ۮ��~��0��b�z�X��d�Ȼ��mc;�."O&��jۙ{��jo���j��oH�V]��o�lP~K��O^YG�����a�d��n�I����4Y�FE&團.��a�3��#׺�]�]��x5@�x�����iW�BN�n�l�P��;C+'S���J�(�w6>c�&�V�7��Τ[���F��=Щ��ͥ��I�G诗9����,�wL�\ev�2�=�8L;�q�n%�y��P�l�z�~+��i�O�UI�6��3�9�1�̏�P~5��g�',.��J����~���ޣ�m> FѲє�'�&���Pgh@Q���mE�RzM0Y�[�3��=k�OѠ�8�wL�U���%�)��@�0eh��M_R�e�sk���ow~Iuq�H������d���""1h��Vߚ�8^%*$;-V~�a�"D��2h�[�1r���@	)O��˒�����MRE���|���y��o����1))��D�q�b����[��*E���YRw�X�����ŷ�K�<]��
)���K��� l��͑ʂZF������l�<�5[�u�>��*J:E�[�ѣ�]�+�z����b�/W�Ѥ�GD�*r�2~��x;��i߃e��f�Wn�]Nq���h'��D��~gl�{^���Tn:J�%�d�0�8 ���m����D��l��L
�L�i-�����U~����*X�+!��%kp
F�(�;�&?�;����q�
E�y1�yg?Ԟ3I�%*G�)�K����
=��ԝA{'�@`L�0z����.���1zG�X����?^r$�!.67��:�@[(�
t����>6dV]P��@(�B��~!ý�����)����	�:�1���Z���`�gx��F�0�Dy�������i��
�7C�f���
�q8���~I�5Oq�E����D��o>,0�$Y}$�z���`U���D�����ǚe���T%��H�.Y������=M�$����j��Ȕ�n0A|�o����������P�m�;��-BR��Q���E�hi5�����L��vT�>�s�h��llJ��:I��-�ֈ%H�Y�i�vr�3_�_O�0ؽ�y���'p�ie�.��ש���ZJ�X<<��ri���ۓX� ��Q=���?0?2xel�"�j�1D)�	>o@�[2C�"F��۝���&��.��ICL��@�]̃��-��@Έ,Kr ��_�a�	�N�܊K.��(�<o�;ES]�Z9!����Xv�H��m삋:p���7bֆ�7 ~�%�-��z& ]�f'����՜8}ᷞ��٩諝@����Z�V5�7~�`��P�DD�p����x-���@6=[�x=	�8��u�}U`2N�]a�|�S 3�}4���{�9%�i�i�2�NC� ��`z�Z��u��١�60� f%R[�Aׂ�ʐh'x�9�*
@���
F�Q#A�N[|���b����\��ZJ�:_�\�
�[*nd@����MN��W`j�	\���+�Q�jx�埤ÀƓ�o��8̉�)�\=��Ҹp �7i����9���(;��K�{r�T%^�5]�Z�Ha��!�bD\����]�''ƛ�\_��jFW3�>W;¯�8�1�)��m��P������Pd-^g�` �8I�E���T��dvY�d$��:��=)/��&�QY�8�S	��t`��zW(���X4d��~V��*q&�x�B
���\������	������1�?���|�)�i>�j�N�ɥ�R0�1ޤ�R�T���H˷I�OLI�=Ym�Z_�����3�ݒxZ���}�!r�׍��4��C������N��+�2%&Yg�	"_��,(C���
��E�~��q�����Z=��g�m�f�'� �{���!��=R,V��C0u�ě��«`�],ВD�a�>z���Rf��&u�����#�b������ΣW��&׍���d�����Y.p8Д��l�P�IC3��d�U_?�'���`}��:�ʱ��F��/ڻl1�5����T�=:�_�{��v����^�Ϟ�ؼBZ1�D%B��w�
�i��=p���l�&YE9\ae|%c��Ȩ,<�yu)�ہw���ǋּ����M���&��R7>nī��G��_�lg����&�������q��T�E ��j��D��;_��ꕓKhu,�?A4Y����Z���*޿��	���鐬@��ےCI����4S!���O����T�,ư��`�ȓ�v���DkҪo 7[rR��ØyݔjfoJ|i{hp�M�HƬ	�53#�ħ}z�"���������cĤ$�b 5�_��̼�s:z*����!����!�H�n�8�O��̷��d��9c"`5�!(iQ�}5�]�n���-݆1�)aC���4tu\��u�W(�������~�<F�9�*#��e�$�ͻ��Փ�v�0��%�1|�D^��2�m�!�˽_�ד������6kj�2,��vmW[��7�1���.a���ϡ�G����e��~P��E�|���8�h�aW�	Q��Uo�;�()w���}��z��~�����Y��ɺ
h(L!��3��wT���lahfR�o{]�����
�i���V����a=�^�ߢ	.a��3h��c�����Sj
��c��
��L31��#vh�54�i��g�5�=LP�/���ׂ�� ����騅�:�L� Sr��9r'y���n����\��h�����ԋO��a=>�#��;󙾠H������w�ȸ�$H5?��#�G_11�w^5EDfw��翘v[��s?��/\���e�����ɳcW��{m6t#� ��� ��|S��.��g��g��g^J�z�S��t "P�}��>�\���h٠����:w	r?�SOs���x�U�Q�=(��HP+��ް��U���{�o�<��"� K�#6x�v�-��H���mi�,F�x)3QO���Q�X#�A9�w��L����%@r�$����N���u�_��﨔j�^��bpY�s��q��qM`-����w;����B�+U}e�2`l=%ob�o����P�s��u)i���81�G��Ϲ�g������.����v�!m)�ęh&�<!|p��U��ʷs�h�
99�̞~N`������i쒨��}��O��e���0�����s���?�~xaqU���^��}!b2'}��ʬR�-Kf8�(ot��< Y'��%� �^�YсKH�-�ڕ׍$���ǡ��-����Ë�ë9�
N�)�e{h��"��LE`����H|�SLꐯ�4m�����^��l�cɃ���]R$Z	��W���Ϫ�<��e�c�u(Qh.�$�2H��\����/���8��gx���cilBx��#��A������ڱd�M:>ze�I����@=&�E-
g�	��kFt���&_����T��o�*�Ӵ�eT�	J��!�d��P�p'!O(˅�v�Og��z�t��ېvП{�	R��!f� R%� =�B x�<
�K�Qx.G�d7#�E)U�J^wx5�km=[�-g$��gE�lF� u��>�in74:�1(d*��W��)��F���[L�1Wh�'lA���B���8$��t�S���$����B���#�ՠ�	���^�U�@\�� ��m�@;<X QW��X�e�0׫�ޗJW�$8b��Ր'`��oPtYj�JV�x֎wҾ���(B7��@]u�8���32�����H���K?���x�B�VdWCH_�[��+s�.�����1fb�9 ;�@O���f*$37i+�t�����"��f�q�tG�D���@�s���yD���g����jSc���͑�Uձ&����dQ���W�/�������C8�^ӫ#cn�f�#Rj�c��A.��6�!:Y�����y�H��m�g��;�8n�&�R�&�q�zW�N�Tp;�u9��RR��9��6���ʻ ��\w�8jeԩ�Έ�� H}��)Q�P�^z�KgJ��_�8U����AZ�3+µ�؃���^��#U*���c��UU'��z�V	V��a=��'g� �3���X����K'��Go�J
).o�.�i��6�P�@���ֹ��̑n�JI��ikD���1d�x���z�t�v����'��U�n�� >y ������ȸ�ᐫj��Ѭ����vf�Mu���2'<��tJ!����7S�]�K�DM�E��.��{a���q����?c׌Ƅ;͹�U1�����OR�!bua6�g:1�z��R���Ё�!8���|�q�(V{Ǻ$�a�ހ.����L\�_mM�u�O���m�,�[s�<ᩆ86q}3�,��ۀ1dj[焁�]rc��W�'d����#��2�E�pG����˯��Xb����$A�l�_\�qXם�4�۱f�~Ǹ�%)'O��QI�[����@B�:"	+��J�v���ѪW�w�<_o�h��3p����-��d�c�����4!;�Z����^!5�U�n�S�#!�ߥ �l�Y�d�ǎ�)���n�V��`������Y_�KՍ��)*�蹒{gb�M���N<Ǻ��&����K��D��!yB4�P�B��c�E�w�P��<�@�"V�����P쌥�ȯM�k�XH�ܞ��s�Y�L6��U�~W��~�8 :+���;^@rɋ��4�H���jA�����9����$��l�[�2�Ҏ��*�|� i�#1~��T�k2Ϗb��:�G����Q��=rٲj8G+w3�U���u�w8�WA��])�dݹ��1��2�k��Dp_h!ס��p<�ƀ>�c?�8luI>�<�g��Aw���&ך��}r�R��q?�
�׮����ZOE��ډh����*�c�%��%6c��]�W��$��Mg;x���ـܮLM"D�p5�p.��)?���E�q����B��|5��w4�U��	��3s�JQ���=�PZp3*�y��>�
`���������vs��!U�!?zl���P?kNoJ����!i��f��<z�g$8.�i�/��ד�m3s���vT�e{8����Sٰ �F���@2�IY�N�Tulne���eo�8P x0:�:��߄��7>����i&�,}U1��<p�e:�TR�V0�PX�>~כ�^���9􋛪�̲�����;h���5K����j�Ae×�Ķ���u��n��g��|Q݄�	��x[v��pFn�t!��mWL����-lv����!J�kMl_ϐr����ʅ2c-�!��ؗ�����g��!�Y�z�|9�#�1� ]:�ň'@���_��X�7��)O���u�kqJߗ|�E*��q@�����(T*߸������G�p({bu�!�����<���P�u����^�}��v�z��<��:8����EW�S�O*qb�^�;����J��� ��<�0!�ӏ�s`<8��:>����k,��&�=��N���op�*�o�l��q4�q�t���}�v�ͺ��đ<!��7xx$�G?�F��1��M�Cwͅ"EG@�K�3?��m�YFi� �2F�e� ڑ�YR�UvS���[��?f��g����i���&�2@�Z�l��lY&�Rݬ�K	�JA�����֕{����	<A{mu�,���iω�z:u���d޾ۂ�7Mw����)J�B�8�a���h.����Ǡ|�K�9��ﰧa��=��w�3z����E2�����X[9\3x�&��M��[I]��<�5O�|�#+�BM�4q���1Ӓ��U׵��=��з4ezYK�PI�����E\T�X7�)�G��+�����Q�є��jf3��x���� h�J����X0.6��]��K�sFHS8�����fZ
�}&J�k^�"�3�q�_�bQ��((��٩�m��a���v��Cx�%C��{l�E{����˄�u9��?�QΥ��T��ʫ�B�h���`G�Wi����Z�;h�/Y�qc�YY,l6��������M�/�n���"Yf��H���2�z��:"8��L���;
z��A�yA�>�i3�g!�����( ��t�iP�0z-��.��V<�S�-�O��<:�օ��hGº�M����
3����~�������yr�Y���	\P��U��Gj�Z~0�~k˔B���f4�K[�u������-���ǩ�LX+XX*����?w���Ȯ>+��V�S(��i5B���5�r͕U���ު��39���{_*wd]oCT�B�&�~�,q��}l��'@����[Vi
��A�YA��--��4�5�;Сj��c��s���!$mf2�����c������)��y.XB�i�G�Pş�)-�9���+�kyT�X¥���ư��0������b�Ç��u�ǥ�툍�����~8S�G�<����mA�T��k��9h4Ώi7P�"ְ�[�
z d�f*=2$/��H��� 0������/����� �o�lq���'~q1�[V�
�vCQe!�"��t���H��z,9#����7�
��$[�[���`%�x,A�v���,ђ�|���_@�5 7v0������Ϩ����&c�fk>�����O��pn��2j���0n8�$̱��i��r|I1���I`J�\�b��_!ͣ;=��6�~����!]�LΫ/�K�w�i��1u�^_HX�z�+�Ft�CT=4���p��KI��b�H�P��J�H��TȰ�:*Y$JRD�����e8�'�S;��|���k?�Ѻ��p%�nNΔ'?F�퀹��d{�w�C5$C��: ��N��ِ!6�yi~����גRI�R1��Xf��uL���Z�1�)ȟ$U�^�z�d�߇�����zbQ\���)8���D����b�+Lz��y.tmk̿���5�p��KP�rY�k�b_�H�����auKf���O�-�g%�W9�RV!�ʍh�e�E�/�c�^ v/h�o�N��*���1I$���1�;�Y��Z��7D0\x���	/Y���(����N�!���я�`c��8��!����M �Gl�0��ǭQ@@���/K�ᶕ��N,�9s��<wJ_
q3\��8T��ē�7y��}�Jy^��7X����M��X�Vg�����.'
��F��h�)ȖiB��D�}��6I��ɰdI\�G8H��J� A9@��caɭ�^�ȴݤ� u�����(��mO0�\��4�ޖ��F٭�][�S�A�v�h��Y@#u���fK	��?�1�.������+qkp���@2'݇
d)�P$�W�pW�;����x���'�%{.$�| r�S��$s�7+};��dϞLM%���}s�/��b^R�<sa8�5�E����(>,d��F�*,aY��ɓ�g<�*fUt�[_��nZu�{�X����N�Ycb*'�`�+GL�U�r���Ʈ<�&'b͕a���,.](��ǀ,_Hὠo���j�ϟ��j��^o׽�iT	�Vi�H�L,7*@�7u%���"��C4z�'Y�0�ߍ���[ع�sL?�?�����jE��7B�i&E-���֋'`�(XZ(�k�00ķ�c��
�*�rU1I�+U��Z��RG���w��=��+�({=4	?ǪQ�"�t5I�Ǟ�|w�۶���;�Xn􋳀�q�Ϋ��V�J�������3U�KN�U&�+�0>���m����I�R([J��D�Nd�T�����7�{>��+�h\Vg
���bi*4*q�|�IZ+�;���ގ��[C�V���K��͐��9'&�iL�mXq�ezbepĔX>�!��-���|	%c.�����v����n��� tob�=�#%����w��x�=��r�g�����eq�/�9d6�����A%3�|I
6�|����S'����{��ٜ3b^%�-��[����/��e�s��л�k���� �J������<XU�S|	0P�%��R?~��2���q�r�`� �q����/��:9Rg�c'�l�}6�l�h'|)�L�Tn��S��T�.����^���<0((3�l-�(sɸ�@��_c����0����
��u�|@��e
��s��ek�QD��ݏ�.���[�Rdn���RC�:7v3����h4�P�-��I��Lخ�~bv^ȧ8��/���S�&��&�zP7�J�k)w=���K��Κ��	�Vq;�4�(����C���IM,��˖�p�@D|_<��U�0s�#��㏰�T�N�-}��*�l5��~��^<������|��0̜ }�d�|tt�h&z8�;����+!��pؼ�[G���4)������}R^�:���;�15:�|�~/8w�G�J�w��"�;��Zxy%�#�Iڰv�h��+i%8�0YY�T���+�ξ�A�O��a���UW���`�Ǿ���[�^�@E��8���Or�^F�4�,�x�zj�@�ֱ�c�	��]mO� "<�C�;i���ۡ"��J���Jw�a��	Ԕl�T�̀�ͤ�\a�yZ=�A�7�B�������p?�T�T
?���!����nvNJ��{��s��`��UN?P
�	mi�dK���7�,!����v�ʰ�~��\)����Z�]3ɡ����[�W�h��EU�����g��?6)΋T���?���9�� h�IM���z�è�0�e����73�?,��V�d�_��Bʰ;b�����~	��[��de�ab�/o��-�d���k"�k�Dt��t�����\��?�Rm�+�Q�֨G,M���o)|��j0.�׮%e�s�u����S�oX�/�ے	6���L��ǴA��?4]�©�(���5˧���IKP��	:��O����8 /NF�ҵŝ���Oa�g�b�����}�cbB������0^
�^b���87�|d�3]H�P4�؆<%�z��: ��i���󙣒�:G��
v0�k��5i۾)�!�����(L2XD��u*p�f�3���i��i7�UK��W-[�Y��u�5j�ގ��J�[xin�`�h#��c�vu����M9`Ҷ?D�B떛��3��}���Jf�x��Q�P����)M9�d��4�B*"&(�G�������nao"5���&��|���EUr��⍨{W�C^�&D���$�\ٽ@��Q��ӗ6M7�U���6Ze��bP��5�fbmx�6���z�-<9<�������7�B��� ���o#R��xΨ�❙�;��3�c򏳵Cyk��U��qQ�5 l��凉�բ����z�F��r�8�3? �m�3i�ǡ����QW�[��.��@謰�ik���ӺHJ��~�jp����u�a��.{D�̮mݔt�|�n�Y��9�i,�uR�ݰ�K�,�@C��nmlI� v��\?����lw(f�!뉰3QZFqO��������q5�����e�L�'�g�Ѥ.p+�����E|F�����A�n�r���m;��6].�)FlB_�m��|*6������#���繈�JΪ���Ļ�RmN�P	��\͖�E ��uH ���RXs�����z�X� �pI.�`�B���ȍ�@�얨D7�U�|�>pX�$�C��7�ap���r�{�0�� �:3}z�PߢI傋��R��ġd�9��/��[]Gx�mf?�ܰ�!s�ƍZs��v�g�I��(���Pf1̅X4?�4�q�H%c�򇚨�2i'�[��#����}p�i�-ӛL9�UY�y{�+�@G(.�����`��>T�3��^�%��+ڞ�n���S6L���yUʄ����:��!���:.��E�>V���@����lʼ�v�k�G1>h�
p�3}3:��5A�Y��Hm�Ar��Z�G���hz��8BSQ!
01�oׄ�c�d�k	��� �5�^�t"=� �M)���X�g��OL<l��z�:��Պ^ �n|�b�L*v<�Y��yRXj2	O�]��jmϫ��ϔ�@�R9N�C��P��u�s�VR_<���׸��":93�<�mV���������Q��ОQGl��3azV'���6P�))A�>� �F��v��0
�ڦv������	���Ԧ �x��v�2� V��qK'J�,�ɇ�G�#�k������z3�we�O��ijG�^q%�O1U��}&:�����9l
�u�ɳ
t��[�XD�{�<޿�]�E��\]��Vd^;�k���Gw���>�Ӛ`0�og��C���FM���H8��ظ��S4�su�$�}	�n�=����1(�%��I�ȿ�t��(���T&�]`"�F��g�!��?5�à���e���<q���BI�S��Mcɇy/'ܴuy�O�=�$�+���$e��][#&�$U>�L�?���'��t2�zڡ6x��R�\�v~��κ��dF�/H��o�Ar2ЕX�@#��P�K��q+�/au5��CF]d��� ��`]� W��<�Ё%s��!4���&Z4����R���>	ln���	�d8-��ՎE>MA&�^U���*��&�o	ϵ�S�k�/N�fXn��+��Q���˗CUhQe��~��٫���U�`&eR�A�Z�h@]�yt"�����̎�<9O��~�` գ��$_��ǰF�����&�6>j9}Z
�2�u9! ^���Kc)�4T��k�L���ݑ�柀&+���`.������J2���08HA}l
��������i��n���A���
\���Ύnt���IR����S"9��3=�������C,�=��8��S�g9��Π�� W]��Ķ>���.�{iʡ�`���Yz���s�PP\NR�XO�Q2j��\`�@�Gk�y�~s�l��_*��aO=�c�����ѣ_�ɰG/���/��r�������0dU�7P����ㆌ@m��5k�/���A�}�?���y��2Z_V$�#/	2�.�Z�D [�V��`X"l�{�\���1�Yh�ٵY�^rD^�����n�`�ۦt�itHLv���J��!0�k�4Ñn̟8@}��f�7e�������vȬlA45#�BH���p��q4�U��������"BJē&$dy$���6�0�B5�:[/#۲ϵ��"0T�9�D a�0D�����~�v���C`���:�6dD�*��/
��'Q(�.9&����o=�kR��Ԃ�ƱYi>i����Z�]Y�_���	~J7P�4���{����]x�U��C|.<k�L��٘�S��ݏj�I�d�(p��m@�A;�f,Q
���iD� �����%fl�gI�Y�P
{(�:t [�m�ŧQC$ٔ�)k{i 0�2����Mᒑ�
TrM�0ij�OV{w�p�4�geYs�ro�=����<{�y�7Q��æ�Ҹu�L�}!��nV�Y���.0�*�*��GI�'�)S�܄�c9�����J�.�� ���A��m��A멊�IOn�������Sf6wMC��"�s�i+���:,F���ol�����+H�t'��^�a2ͼm��B�������:��Դ� ���*y�ؤb`3D5L�q�\R/)�?�:��������w_X$j�Y7�3�x��KWV�
��@9L<KwPD
���oR�3��vR��K2����b�9�>Ѕ�2j|n�m��⢓_O������c@��T����"�d�=P����y��:�ڮ6�ɜX��H�b"|x���E�VqC���-plRq��O8{�CRV3���o>����5<uU�!#CpŞ��Gs��k$z���U�#���!f�"䴨g4u��Q�l
ۣ�<�5�Z,��Wh�9��S��� `R-t��J����Z�7ߒ�_\�B�qb�� ��<����5��E�K�1�K��w�(�B߻^V�(]�n�f�gY�UXYv#�g2�fa6�!�l���i��$���RG_��~Y��-�����Y��(W�Ҭ���]��e�كg�Q:?%`YV�����C{���*POJ�y�u������Pk{�z��;�e�����f�r�Pk	��edpS4+��&��Ȣۇ���Xw���&	y�	[�e�bB�ƿ��|����?Ҏ�]t0�QVKl?�����5 SP'��vÇ�����!T�?�?��Zmi�7&�
��Φ�J�{����78�;b\�,�׍�P��Go0֓�HB�!y�L�'�%�%eХ���k�[m�t�VtA��v��U�QW�H��;r�B�=M�R\	.j^�;�b�醃ѵ=�=��}���f��4�v�-^�N�?jȼ@�o�'�MU������5���/�Ը��x3�����O�FY��پ����zKc�6e��B�D��P �8��XŐ;�/��,L8���!Z�ӥ4��$6��f�;O��Oύ�bέT���P����bO�N�L�}��4:S�~a�Q#,1����n�6���g� �ߴjFx;�,u�f��˩�k���y��ZD�%ƪ"H���zd��Ӭ�y^��dg&I�B|7^'>*�NAx�N���D*bO�Xw��ʴ�L����tXԁ���ޠ����i�eF䌀����"wZ�i1��`���!�����-�T��=�8��ـ)Y�vϖ	��%P��"����Ӱd��D�c��Y�<'�r	Z}�y5��|��jM]0l}�7(W~7d\��J�W�,z�`:�H:J�o������]�c�Z�X����U �w��u�n���)B��!8���	0\��$�"���u�y�3����c(�;����8X=�Yʈ�������#Bï`��H���֓*!�!�.(�$���iO�sg�^�EE�A�r�G�� ) L#��up�B��u�qsVu�Fl�c;R�tv�nB"�
lᚰX Ap¨M��� (�բ�(�������P[�;
`�"���������u�1x�w����ŷiT���S��|3��ػW����������x�����n����d��Ŋ`��N���V�����y(���Z�m�<�彤-�g%L���N�NT�R!����{�jB�S���� W(�ȁ_����Xb�m	mP���#��PF��̔����J�֡�Җ���!v�D�pC����"�3���ڵw-�>�\����A�߭�-�,�)|dł�q����Ü����'ί��`�5ZLx��C�	�DThܤ��uH6z�Uu����C�)Pv��V�<��F+à��^���}	
��#���I؜o)��w�C�"�,���p��'�P�-�%F��I�/��QnZ�� ��ª�[L\e p�"F_n��!I�ꏓ=�I\t�R{O���ȏѤ���YM�_^WzHm�V'��ȉʘ���G[+j~;jb�Z ��\�3�h�[P&,"G1�1.�<�N�_>��)�v��U(1[�ZAGq�t2O�e�G�x�ŧ�e��nۜdN��f~�Hu�_?)*�Bʽ���L�aX���ภW��ի`?�hV�C}�a�=j�=E�*�@m>iP���ϙ��q�M���������Qu�����-��%�*\�GZ~*�؛Wp]>;ʎSA7���glm�c�Z�����ʙ�o��L��ҿ�1�r?�u�"$�6-g�k.9V�x�k�����H��A�6Z&䍯��;?Vg��SF�5W()r��({i�$ôTʺ�̄`9b)Y;�X}�@�>Z�h�dW+P�@�ʣ�5*����q�h��A�jq�4�������:E.��T�����#c�G�2�)���n���d<��&�2����C�6�{�Y�.4j��0����Sy�s��H���P���
��\H���n�W-M�R���� 1F`P"��y�����8���Mݣ��S�b��e�V�b<$s���6�B<�D����i�^��4W�i뺼%g2��2�LC;��;Æ&�F0g?=|��<��v#�SA�;)��3������XήX!}=�Aѹ� eO�s&���#���u�M=�O� 6�z��y_�*�}���#��B,2�;��)y;�v�x����"}1����Y���ou�����%R/S'NG�k��'4fy����,J��Z��d��G��*B� �ɤ��Ve��C]Pܒ�zٶ�Tp����JDa^R�;���^ƪ�8�8����@T6s��CL~>� ����R����x%���ޟ�!��-Lr�D�q��a�[��dߌ�g��z��E����O�e;��g��x�k; ϪO?g�%�Cΐ$!0w2��mͮ>�XD3#!IXG�pg���pbVs��.����P^s���{��h����a�!����4�&�G�i�ɥG���m!'�f],:�56�(o/iW�������t�F���XH&C�u!��5�L�5�`X*lb�\W���o��r�3�.QT�%P��T��L��e,vza�Ւ��(�Q���4Cu�X2��`]�)�M�C.p�<`~Y�+[/�%��h��<���\�U�L����d�kL�����)�%����x/icT/���fJy�:��&�Sf*�ۻ�'�R6�� ��?�AR1�f۟�	`ur/zGۧK7x�@�#:�.ꃇ�t��Ls��k�^���uE��z*w��3��S`l��@�jX��i�ǡ��]}��H����HF�hl��<)��͐�B��'z� �|iX��3��J����������a�B���k5�W;9�:��f��[����&>8��
����kB�t<쵦#ƈ2َ�'%�U&��������8��v�k�K����F�����J;[�_{w$x���m���)�.�8�ձoڙ�/��NGt
�6�J�UQqM����[�% 93|��5-���G�T��w���Yv�_dd��p��6n�&剡6��G�����k�s:�/5�?�q0~ë쒹�v��s��k"y0�9��2k	�dM���N�B�CL�2��P����1e�\A�z[�t�X�8@�I�Ѹ��{��D�G��X�'��^�0N�r%�)��.dv��rD��]e���7�*�F/d��`��V&�UD�X�DӖ�ϩ��t�`#��D�����e@j�N�8�T�`���[tw�^���PN�X���
@G5��g#]oAg��C���*}3������/��sy�s� ���<tW�'tީr�.��r��iS�Ro�.Z����p��oѐ��������J�PT��+z���T�c�ΧF�J���V%��SZ<�>���D"hf3Jj�ӆQ"JГ9Z�I_����n����EB>�2�%x�t�?!��L��Mj$iz�Eѻ����i%�2��� ��ςa�8��s��z�`	F/��P ��MUgC����`n���袛��b�ؗ�XbK��������0�y͍Q�j\�I�̼'p*����KEz���\fZ�y̴��f0�!��pq�X<e��ӿ�|ZX�8����<Y��(̈���H���]L1���~���&B��\s�/:�DYl9���`%�~�w:ĕ���,Q�঱s�k3�������.�:z��}Ǩ ���7�A6���o�_% �Xl���ay/0��,��!A*����'�5��|�+{�ٞţs\����|����l��?v��m�E��A���P���^@����e&AW��,�,��k�j%��tl@�t��fKv���b[/�2���2�6"��ϩ'u���0s��b���}m^x6Yw�������M�F9�L���������k�S�������W3���֦��|$Gl�.�^7��M�/�+�a�uܻ^�Cя}']���;-,\��!jc7+�8�_U�'|���ɂ�y�<���B�Șo����~�d5��q���V���&I��Kw��t�������E�	�����/���`d��&���ř@5�;T�Lǃ��-�=����0Sd}܋�t�]�VZ�ul�&�>���ӑ-�s�+2�9�_��c"��2!��X%�u�yD}�hdq`l�uV�mF�\
:Mљ��>�NܶL����;�/x�����"8g%�\���kA<O��4�I.<o4`�\�:E�^�}y���w R�6�jkI�Yb�E���TP���Jm/n-��I� En�QP���f���^�n��T|硲e�B]�R,�{����M��O�|�ɶM}��ƪ�Sj6�!�Tw��l���.
�]�-ʍ��-g:���.�x@��T������HR��:S�̚���?�Jn��ZR��rs��t��HVW*e�럑E�� IFK�%AJ��q�jNF����q��X��
P�d2vJ��L؉@�AM�����1{��k�� ^@>��,���d)�+@A;�?L�����'B�&$�}L�P��%V?�����o-`�JX-��l$)�� �86�ԧ�?:����_�^�y�Y[d�dL`D ���b�%�C�$��C$����c��~�TA���ٴ`�E�YD�P��/�l#̨`����6�^?��y��G�AF!�)S�1+ti��^EE���ObD���<i�U�x��v��A�p��\�wCC�2ň-*�!U�����s9x��X��A���%*�)�Ol��u��)2/��ov�Ce $nd��]oOU���7nHr�kz�PG�hP=?�F�$�M��z�p����-V�y�H$�����S�@�x��o�4�B�5q�
Frs�G0ޒ���g��
taJ�>ġ������U�*e^�R�B$�\��J�����2g��u2ynR�8��du����>8��q-�3�`e�F���r\htbv;*��
	�P�8��$KR%���� �`uA�C�)N����*$�/��sE]�+�hMZ����R��
�K�t/9�Fh�H��uUǜ�z�D���cO�҉i�"�#��I"���{�lt��6\�&���>� �fvXfN��Q~�<�6E٬���8���xd���QkB4��B-m#��-�P5�N۞��gVl�<�;Ȉj���0;	��!�C/�e˅�ʇI��Fu�;,I�5�i��>�CEeP�UN�]�R���Θ�LD+���%�nJ���	ZE�C�ͣ*U���&����_;�'!<]:�%e1x��\p��(&g���4?7���a��s�M��mW�L'�����3tô� ���,�݋Iem��
�{��dh[D�g�ߪ�Nn���=[�o$z�P�9P/ޅ�BD@�iݼViϬ&쌞�q�D~A��K�B�y���!%6t�t��Lb}{F,� ��m��W�BRXЈ쯛�E��~`��� ��3��n#?e��,GN�v��Kg���=��� ��!�A��A�fk�������ȃ���@G/��ke��0��rIզ�=�I���ʆ�uǋ�~r�=?B������V�f�l�%U.��i�5C|b�8Z1���-�ڐc՜�H.��Ķ(�{�~_j�q��14�Y$�f ��R�|CΣ�յe�m'�'�2�*R��^��l�_u�ɧ���0�.�rX�w�X9�zJ���1�+K�u	,���\|�O�	���L�����g�gSW1U�!��)�*�w���ƶ~Q���D�]��3��]�`���k�&M7:hm�|C��s�o � l�>~�l��b�t���D�(��J�xU�7ܢ&	�{PY�$��!��*�Z�ʰV��Ue�nc����(TPu��ߕ��Y?��q��i���4V�d�o�M�3G}�z��96R�iZmt=�>N��A0� ��.�J��tI(T��	��l�@�"I��'�E�[~sQ�_����H�7R����!�_D����ʰ^��*C�.B�E��Ɉ~~�ĕ�x}�V«�;@��$�����X�kd�o"�k}L�n0����i�B�2�,�1���)��u���<�`�VGze� -s����Tt�`������z�~̓;����ȹy fv{Z߉,E6�W"��&>�gD�)�6�M�_A�'.b:��ũ/,+2�����@"l._	%k���K�ǼN�����r� 8/�	������i!�W���Q��v*6���6�Ъ�
E��k��@���zU+.-��Q`>��0��u�	�I��6�����˴�s�ѡ!����ԧ�*�������x�\T�r���9�����w�;�L��Ls�D�Bo�!1nU�zK�$�^�U�:v�0�`Y�#;߉����(�3�#4�瑦�$5�� ��f����BچĲW�i�����o4jހ]]W�+F)�$�m7j�W	���G�|�C\8����q�gei�Pش}�섡oR��^�>S-����0�Wv��짥���`v$D�v�b`����\�x.��N�+�l���R[y,�t����λ�wB�63k4��g4�_�!�h#�L�1���P'wo�v�B~T�C⒩�i��gz��S�e�l!�e{`����ʀ]`�Q��o6�$����9U�D�?�!�~�1���8����"�<�/@���b+�̎�vn��q����� �x���B"5�O��Z\��~V����R�s;%zأeڶm{͂lh����f3Kd�8�	L�X� _o�����MV����bG6�d�a3���Lg^ą�u��r	Mi�F�H,�A4ɂ����W�����e긅��-8D����8��;�1i��NE�]�$o4�r.�p����!���߰s��u����#�����00Ç�X��$ ��G�E^�$��g7� U�|�K�C/�,�L����	�T˾�N�u� {(`�Vi��ʱ�m����B�+D��FVSs��_t�y��^����ADm�w�ծ�R%B#�pw��q����xկ��	+������$���_��W(�(��ܒ�ҍ>H��&3�t�#a��]�Ǩ"���L���].KG	��FqF�?H����x�oxk�=�j3h�N�6�[�:빤3���a�D�^���.U}�e��1��8�����w󔫃���Ї���W�4@�S�)��\V`A����$;�J���&��@�UH��5���Mj3fW�5~n�$�5:����c���\�99(O�������2���&�a��g�Foks�!ȩ]����깷����!XS�syۍj>_�K�ҋ��`̈��d䗚��°;��AB���U���;{�G�zċ����&Cf�GM�˻�S�_`��iS7�}��/�0�۪�o=��Ξ/�������B�rT;5��OL��r��͑6�`�0DK�OH��|�s�D�Q 
d�d��JY[�?G0(ӎ�eR���Z�긿�Ў ���|1�D�bƐm���uc����L�ڔx�K�Rr��Y�D�Hec�1��݇��P�չX;�����}�����1IO��y��3g`�%����}�H.��O�Tzy�Ӧ[Jd�jуt!�x8�
��p �/!�(c��B�+	 ��8�VE�2SX�u=)����
Wu��;|.	���id� K6��ɶ�^��T����R4ǩ��h<�DH)��B:�Kٙ�3��ci�0��t1�W�,"�G ��/��x|���7�V��F�%K�SE@��GwR����������ĺ�Y��U���a�]����3����߭(]���(盧�2ӽ(=�^bŕ�C���u��ِ�l!�)fB�T@^ָ��$�`Z��L�:�G۳NK�}�_��zsL�;�����4��\� \R�����<�<@�s�xS�h�N~�p���=�}������i����d�<�]�����f��L�K�5T[0����+��sgR��͎���4��pX��H�-�ur��B�9�Ѩt�K��(h���M��b���W<I���L]�0[�����J������tV����_�171����1myUC�.S]Ԍ^�8Y�7P���J�~~������S�^���][_;AsE&<�2jl.�pt[����W,6E�7���/m�]�ֳ�������J	m���tw��m^��oim�#�C� ���e-����*��?
��_uG���7�+�m�),�ł,��g#�9�v��f�7�z�P����U�@d���q���hb�w�8jo�%�@m�ǹi.�Bkv�u�;��^_�v���R�i���p�ZOa� �'(��Kk�'��@0��<,P�I󤀵E�\�����dH6"�3E%� �C6b=�Q2o����!W��X�PWl�/jx��C�֐pu8(T��"�^)%6i�X�P������L|NЏ�N���Y����)���Z��W��t���Y���ֵ�]r��^\��PA��U���,���1#��!~>=wd�y�� �
@۽nm!��-I��O��q`�s;#|��b�v�e�'� T��ρ1��6_<����st-k�3t)�`�b�j!�mJ��Ƃ<i��bA�B�$i�m+���>��VGГ�۰n��h�ָ�����[0rHYO
�vי�-�4�i�2� 7�N+�9Zm兩�U��.��\�L$8�Rh����&�8�P����N�>gPk	%7;O(0V9'���S#.Lv� z�00����-����EGQR�����T�Z秄�� �a�|��g��<ivɗ���E�#�����5X��bXa�����a�����D.�n�����|)���LPd���Λ��c`V>���d��(���lEP�F�*UL�0*v�ɴ5xH
yC3��YJ�-tK�~�ȄCN�mf�������_ڣ���/y[
�ɾ�F��()�L���}J���;̉ew>��G�u=�t���ƳqcB���:p�YTfj�)
ќ�Y�@^�
��"<i}p>A�̨?��=���-9/ꍔ'��Ҝ�B�[�/���	P�J�lB�������}|�YKo����Z-4;���ַ�4{�T�����7�4�L��f1��욄�G9�=�T�\3��Vz���5�$��ut��Kΐv�U�����`dE^I9� ������dA���M���Z�ĝ�)�`�F+���١���ےI���*�6�#�b�R�:<�d�a�OEߊm7�]?�|e ���R�=m��������n��Lq��W~<hN��?|s�^��,����k@2/�S��@���ۛ�7wZ<��%�S׷#�>�W%͞I��hZ�m�2e �j������t���8ǒ����p����5b7��du����k'�P ��U�iTɁ�e�f�1��ؿ�q�L�je1��Y���R�G�����f�5�!�8&�9��sR��!�j�l����g&�����'r�(&҆����H�
�_�$�z�E��翁�rl����VCإ��h̿��o�-!dX
�$�Q�q�gE��=fM-��34h.:)�A)�
������h/>���a�R����)�k�1#�� ܜ�*��	���<�؀6n���W4�{�	�5�e��C� �Q_����� �k����HKo��!�6��.� a���ѹ5;p�P<���Q�.z<P��LxT [0�<�K��P	��߼��p��ԭ`�����1,�1����v������@�J����R��͡kA#i������h��;��Va����}*��@�^p�����0oR͊���N�"��wV��X�EcK��yٵ<�[#�s���L�=�+A��!�GеƊS�ty��J����A���6�f�~aJ��yz/���`������`<���k5z�2~ O��7o<8+��y�e�ӓ�U�(C��0)����ߠ�6�ݺڱ�����i}E��k�˭b��t-y��$?ݟe��r��T�$-�D���h��ck'#OjTU\�W4���1��0
���FW�y���Ԕpy�j,�H��eZj�����{�cR��4w�ވ�e?���/�i�N~4#u�!��}r���P�����3MF�ͪ~�m�dJ��[�E��S+z�9��FY\/s�Q�s�ħp���	Z�v�q�\�T�I�fҥېor����Jw	x�Ij�D�X����w�xc��a���    ��[�b ������8��g�    YZ