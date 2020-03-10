#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4044761954"
MD5="27a1a0ca64cc112a9fce964dc38bba98"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20816"
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
	echo Date of packaging: Tue Mar 10 03:23:15 -03 2020
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
�7zXZ  �ִF !   �X���Q] �}��JF���.���_j������>ZU���s����� �����D��|��¡�'����̯hҔ��ׇW� �M�[;y�1h�]�yx���j���Q�3���(�g
d�Hv����MEn<k��V,g���|�@*�C�V�#��;�{�'D�C�����;'��k;<1�]徏���\��ʛRݓ������$�r��}P�m��=vTu}7 �����oe^����������
"`8�[�S.r\���l cb��*} +�8��~�-9�ue��txK���ۋ6����9(j�س&o��Cx/��0���y�ٞ�Ev��o�}��TH�֚ۨ�bX��G�{q��h��oz��ڸ��뒜 1CA��̽ ˪)ݰy�����M�o�26b9�Mz
ʣ%FA�����B?K�}�t��<D���~�ω\)A�ޅ)����f�FXY�k�D]�W�b���RIخ;����.���c�@5H���Hae3+4P�"FY�q �b�J�L����E�A; N�v���dٔGZ�}2�o6~c���֖���2ޢ�R��l6�(�j&{�Y�pkk�cg�1��)(P�"�x�C� �X�OPX�\�	C�?��������cp����
��j�G�=�qܟ�~r����X{�M�,#2���\�&W���%����H٦��a$�oL���#��݆ffk #��4�B`�]� ��9w#��4�W?��d�pT}�^��/#�N�@�d����{_r�^
|�4�o������'��+.�r#����k�zEI�9>,�Q4�����H�E��4�FGmUV����X��y��tW�H]�e��py5��f#� �CD	E��y���)B��ކ���O�r�2��T�#O�7Qun\�bd��L����ݓ~�B��cw��vN��h�G��`�Fy�%���AX�i?����-���7bAY��&�uĴozW��p�P;����"��wd�ԯZ-��/�gh:Tf�Xg�MI/o�0�V����������.7r7���9�P媵�v��� ���}+`lJ���(.TT^��(_��8o�U
�>�� �[�fa`�U|�)W�p���c5��]���(!Ǻ5!Oy��J+��ul+.�g���U�v��1Y˺����#�Wt����``��x.�������i#d,I����y�R��̥K�a�ha��\I^7���!R�a����]��(g���E�8�D�(e��N�gL<� ���ŜôjIF�/$��5%f�3@�.k��� ��n���v5�t+�K��?K1Y*��5tr�o���7�Z��L9��w��9�z< @<�jd;[2���O�jSo�E���P�J�5<V��pC�ƑX��z|4/UWR��b}��w섕�E9l�+.^\{LxZ�f2|S�[�X�1f�J>i��&\(A��@݁�PMF�T�~s�X�RvV	�o�i��8�4��O��E�vՐkQK���@�hT����ٓ9��)�T֯`���,���| $���'�#tҍgHq���'�8_o��%"�;�]GBa�t�7�RĐ2EҢx�������)�xE�D0��̳�q����w�#A����!��Uܱ��RsŊ�4*����]�a�w�o�r�:�,�˶��,�2�&d��G�+��["w����Wl�ߤҝ-�A��	cw傈3#Iރ̖���}��莵@BX�0�G�%j�|;���[P�2���D>���5ߴ�@�tֲ�39'n����ϋ�A����������fl��dl���%@�9���W|j]V 	V�[�Bmc���ͫU����*/�&S?��B�ӯV�7D��H����u.w�lW5ܒ��"tBcAqj�w;c�����i$��f7�|^K��SӸ��b��k�%���	H � T:@ ?)8�����+%?R:�M��� O�/��!�������?�o�ހ����ے��xR��!|t Ih?T�}+��5����Bp�X��4���֪$�QZ��2+ k��B^^
��3�OMO��|��7�*�Z^�(��N�p�Q�溊���@ց
���i�C�i���Sj��C�#<�U羚/4Y�R �0��Z�ң��Y*/���j���S�I߂��0����P%���a�g߃��̩`��D.�;�b��������y��٘��r��xף����4� �Q�-�(X�qh= ��������c���3� �C�T��A���6�|�WPl�F#s�V̴�B'��B0��G�"bu����!E[:c^{�ḹo��)hHn��F�7,00�o���[�qn�;�(��`CD�]l3	���9�,��]ME����.�j�$���X�M�2$BR�k�� �/]����L��a:c�}V��3���(���q��%������~��])�1� ���=�ߣ����@�w�YX1kT5) �G�W���+NB��d	P.v��PL��)e ���V�n��:]u"�r����2J�uq���Y����!������x�9�m9b�2���w3�����3����aS�0�����S���#7��p�.π�A�j~�M���^�o���-U�%�#�G4�0A8T�_6cO�c��-*F����ƕ��G�`��&��2���	��`g�����pOniW$W��4#� ���"j8y��<3���K�"Tc��T`I+�a6��#�o�~I��G������;�pS_���ǽ�,?�?H�������E�a�P��>E�S�A����uYV���1ѿ��o�5��7SW\L�6��: �j����ڄVL?�oo¢�V���WLF�y*����.�ZէLlӞ���e��F1�q���r�B��~�ڰ%R·�u�ܬ�3��$1Fs:@3� �OT�: S/hr�cl�8�7��ǖ�+��p�X�.���JʌN&|	��#?��<T�e��+��a]��f��/��U5̦bM�'Q����=��g�� ̣���>� �yu�#/�������JxoQ��y��D�F��i����'�.e�,�� ���������5!57�y�oF�t�q�&�k4�+K�t�-R�5I[�{\�b�Ύ�8db������ �d<��q&�M��oIP,Rۼ��\���'�n5���H��O�J#ݡR��\XUW-^�%�еb���ΕM%�5=�хV�Y{�Þ��	L�?�:$���C�@�M:E^�7wi��%��:e%�>�j1#&,)6�%Q^��G�k��y���+�7V�c�x0�*��M��NA�!�G�d�~l�M��ʕ�9�Ю���BX$���c<*9a01��H��Y�g�1<�����2��L�X����!��ldT�������m�S�)ڡ��'p�rpk1�)�.&5w�J���c�V�i��ʾd{J�;[��~}�㞠����)@���I	�k��F�Ǹ%�w��}��St�䗒+y@+����$��+"��):d�n�:�,ˬ�Z�^��g[5
���'0~ �0O�K��pj�g?���d�1_<J*OV��DA\��uP*,��fZ��(� �i��oeѧ�=�wķ)Q�x��F[��&[��9�m��C��(��b��8��g�*/_E�ݷ�9�`��LE��Rz}�4^,<����P4�K�Q��I�1-� #�G���}	M��ъk`���?�Z!q��Ԡ��z	�}��\qOk���`�fp��@6c.$�T��N��Ҹ@�	zS{��D}���3�Q��`ྚF���j,�#^�u"��"�v�V< �q��ϑI!.���w!��TǕ��-��㗄UK�� ����}�6�t��	�^A;Ab�������-�${�Y�?Hbi�්�'P�kx�@<�i$6��� �}�^%��V�����+>G��*����mB�pȰ�âe��{�AY`F���"�ڭ���@>Ae��8��է�+ ^Qc|߻-/�04o���\���4c�/�A�9 ̓̂�����>b�W��Tӗ�`��� ��.߳/&�O�(�y+�$����1��^u�`��Ye�N'G?C�J�;�
q���k]�:�)�g�Q�m��;UD��I��/|��k�iR�W���0�S9ȫ��;�:����Z�w�z��m��T�)(�O9raZ3R�l�I_ւ`^U~�6��(~̱
ރ��:\ ��rXj�C���BQ޿��ź��
��H�0W�#R�� ��H�\��ƺ�e���sߣ�!�d�+A*;�c�i"CE������|_����-A�z��}�LmWv.�U{�R"�}���=��q�&�2KFV��Z���+1u��K�S��`��߀�6
��i�����n��ې���=ʠ}��[J"�����9u�ŲA:�wpa�&�NZV�4���7\���'�*?��4�$p0�v�	�#`y�����)��r��*�`
�Q_�u5T�FBD�D;�M�笝_t��{H�0�&m��ϡPY���å?����\�~�T�,�4�W�<fٱ����K<X24��M���.����ٻ�
��]�__!+Y]�q&`�4q�Ő�%xv��mp�p}!d���奂���a4��6~Q3DX��(>�P��ow^�/Ԧ�;�$��`J�]���B���g�Q���,]�*ĘP�ng�+Oq�c�)H�2�e����x'���/NiW!�B;|X�b��ʔ[�����'��Ѩ��W�j3١_?���� 2�q���˧R�h�����:����:��_(�_i?��g��`L�4�44K[� l.�LҦ�:U�"M��~�}�5@�(=>�z_D��7Ƙ�}�|*�s!'ѓ���m"_!�=�� �L����f��7�y]���]n��m��&��-��K�Ĳ��>�@�j�e��/��9y��n�-I��mm�Y�.��1�#�O�2���6��{���/C�B�ԫ��e^3[J۶��5!X��
�&e��&]8�?r�B���̒�_�;Ɂ���`�?9�/�S�C����T/6���k�\���CK-b����V�lkNwTwTU��Th5|R�Y�"@b�E'DI2�N�I�2�����Rs���.G�΂����;#������w��Op�wy���	�xx������$/U����n���[<ꈚW_��
gT�c������)�ovb���1��:gD��!<�z��8����^�ޤ~�uM��,��D? �/�o�k���x���[�?F)�"2Wf��S���������Y!1s�3B)AyfL�Rb�����>��N���:�"�o�k���j�PM�QTn�[�"���/!nDџ�亨8F/U�-���y�]YZg�`lA�n�	���g�'/t�-m��{����o�T���6ƈ�5�J�tm�	>����yV�>����͢�:���ǶU�2o���ɴ9��_�^T�Sv���?!�T��qF�y�G}x����!@�1���Sܧ��}�*�5�i��@�}�=I��$*~{��h^Ey]���Xcb-B9s3D���|�Iu�E���w|�&�e5��lo�6�����_�w������2e�F"��ph*,�k[��~����cOq��Vұ��&>9Q|I�'_Ϸ�V��N3�&y�	�����/�b@��~�ߌ��~f��8������w��k��3g+�d�H'���cu����$8"�FA[s��X��)�3��W\B&�7�`Ƽ=�;la?�1q;6 ��JL�k�:y[�U�z�!B��3�硜~���Ux��e�8��K����[S�V�!�|h��ׇ/R�q�����Y�K�{��Y���ҝ�r���o����A�˒����QxjXȠ�3T)��_��u�<ݲb�ʑ2q��Y��w��Q���E��m�g�f�;	4l�
��({�kJ�]�-�0N�5U&z�Hw:���z,%�W�b�#�h�.�I��-P@
ţ�4c�Em�9�C�_V�*�����������fa��F�y ҤvbAݯ��;Hg4�)�g34R�L��e�ݟB�vzBf5�ֈ"�_�`c�{�b�I�h٠N�#���'= M�?������}�1���PO��=�kM9b<z`�_H��3w"UK�&
�z�`�ծ�WRD�@�}�,��=��)C�]����lÚ��S���j�P:	��(�w��JJ��)����?�~s�W�������}�>�#i�d����V��/�$��):Ъ$R�J�j1"�0�+]��U`���eT��(���K��u�:4��C�sҌ����l�qNࠉ�Jo�Q���@�W��������7D�8��/���P�4��@�Zc�s����f�wq]��*5`�������r��VY���8V}����Vj��>�ђ �a�"����c�y6���*��ZW�Jk��?#�+20�>~�Y�0��o5Y��������*Q�����x}{oC.�s����?ƼÊ���-��!�J)�"X�>���3<]���㴕y/��1.>�����w��yP"��|���~ދkU�DקÁ���+1�z�ԗW�2�6�r�3��`����'��q\����e���'+���*#'.}�\ R�ՆTW�N�s�(<�?p��j���3Yo��y��i��T���HGD߅�چQ��jc���Ve��P�5�dQ
W�_����[��U�A#%M��J>r\V�d-Ϲ#��z'�	�@U�&�q���J,r��
E�T��q�0�!���
�ɐ�;���J/PĐB�/~x��t	�FO>��|�`��7��Âf)e�e�_�N����{KYz�p�{�YC4�B���J!� �X�(J�z�9�w�mŒ�dVTf���7Z��7�������(�W�Z�Z5�ָ(,� �4�;�� w��ʷ<a�Y�����5�����O��i�Pm�RUm�ӶVxA]��	�q�����{�繭�|5)h�гA�2B������&��6ާ��O�`��I1;�_�w(@p@�ܾ���Z8�ǃ[>�AM�ģQ!u�� }7*�"\!t�-R9F��źv��Nfh��c�+ֶs����� �{��{\r��r#8���@9ڼ{u�=�����"�d��3�Z�d���W��\7>�E��A(�h�,}Y0Q�<�z�`�
r+�%-�f ?\�Kw�%$���ѷۨ��#�үD�����]��g;��Q�:x��:��L�g_��a�M��pjˠ��1����j������V6����������,�K���`T�� Z����e-p@�P�c|�bT�_�%!r������Z���c��B�W�Dk���"C�ɝ��
<s��il�����K�9� �C�����+s�cA�R���
���\��KN(��pآ� ��ll�~} �I�B�>�k���ܬ^��)^)�F�;o�~z-��V弿���ZO��z&���geR�>�R}?��[�>6�L�L�/ K�2��n���ě��t?2�̻
��
'?��@bloR/J�+׃F?/N�>$��L9\����4S"�Kz
��� �G yd�=IohL���㜠����(��t��C)M���241	M��~#�#�٧D�D�'���#QةH��Q�{�h1�Ty���� �!�-$�%Cθ���4,޴�Sk��B���:O���f��v����w��N{v�a����ޚy�J��m�=4i�<
���(���/�{y_&�,���~����o'�Ryt���+@��Ѻ�3���m[���sq;3���c��z{!+W�z���E/���1^���s�}����>O�Q�)�D�Gw"�j)�/��{M%d#D�M�^i�~�fq.�b4��jz{���Q����C�g��X�")�,�A�%u%�pJ�U5}]G�(�ŀ\�ǽ�q����Kp�;w���r|�Gi~"�8�r�����!�E��ДS����`�0Bn^�6^+�:
/�%;Ӫ#NǾӊ5�fm7�����3�@~�����(Ct}R���Ď��_�:%`���}�b��(�.Cu�`gj���g'�h�Y�}�}��=N��g�/�b�7Z��-�ȼW� a̽H�n��]&��ۗj���{m3Q�е@T�<��s"�\f�?$���-���5�����4�#�^%���B���FG�-A B7�������ĥ�*"�����1���RQ`e�|zSq ��ѕ����`��/����uif��:�d�(���Ӧ��J���o�������q��"����X���$ <�g8�6�����n~���?ă����*�@'R�2{xф6|����M���lp8yߴ�U2]u�!Nt��)E�b��^�kx+X��5]��,*�!�g9�ǎP�����T�Ə9Z�/�]|�
�����\��bw�x���t)�����d�@پ�h�O!��>��X��ҠyK3��k,�mT��DH�T�c��D����t[�`א�j��CVg���J}�̧��c���?dC��~/@��ә��&>9t�̿,|�
ǡ�������ȟ�rk��Ѕ�F����:�a��AC��S�w�d���C�l�w]n�9�JE(umi��=�1f�z�����|8�.�*f�2�1��c"d}]����ܢ�7D$�����si�-�N�$1Tq�s	���FE�A���R���Z0+Ѳ���m����V�m�"�`4C����N!Z E�;1������,w.S?�X��_q}p
�i0њl��
�����[���;x$�rӢ�v,@]&cu<T�����ӧ��jbq��}i�2KF-|o�	�ߟ;Q�u�%�8����@n�(�^pE���]U�����W�4�j�@p8��\���B����>b@�W��B���~P����r���8���&M/u[o��V�joM\rht������$FI%�X!�l猈�u�1���=������TK��]� j$���&r�	��������ӀF��P��U���N�<u#@n��"jPju�^>ٿ03;S�T\�G�=˴�&����&�>����̠3*Y�s��]>%���69� 5X���y��U:�M��ZjQ��w a^t��r�-�����Rs�&������X+q7Kh�6��x �x�T�r�!����T��5[����<�}�o��9`N`�v�?y=ݨ���������j��!q�]B��H�]&�������k������M�o!.���MU�����0q��wb@�T<��6	*�7�<N��@u�
��;F�+׊(=
�΂�H�ڹ)ͬ�Y{�gm�yl�9�~��?��� ɋ�]���uA���U�Й%�lK�e���8!}e�n}��0	O��P�Մ8J��8!c��+��Q�]�sD��2%!J��0�p��grfu��B���7sфHfl�dz�!U`���6�2�<N���+/l�������K��~j��Z͈��I��öt�i��*�;o�&tn@e��g�z
��g�?M?����|�:�'��3h��b<��k�9b|&Va[n�f�d�U���(ʁΔ#��3U��~E�M�^�Ֆ�(�D$܎	U���������SF�U&��OӀ�v�u�|sAH�d##��rL%�
5�ϳ�֨'15��̟�0�} S�+d+�vg���SY��|[#����A�(ѓ�;��y���S�|���"��ѕ.~���P���Ϊ��kE'ȉ%j(d�aW��˵���U�͝�Q�tM�q���qe�"�⏤�:Z��%[�r����[�]B�<Փ�1/�*j�!AA~%��>~X���'�����ĳܒ-T�L7z2I��a7��Z�H�����4�ŝ��>�1��ȇ��	͌�I�������A�7B�������L*�/)�6)�#�:���/�$�\��A2 �Z��C�V���<�X�v�ʋ���r����p*l:�%�7I��cyNJ�c�*��Q���c:B� RύGDO�M�W�>�ߎ9O����E��e�ӿѵ������k�o81�}A�Q*Y��M!AYُ& �������2�PJp[�̾�̶<�e��i�lo�u�Iw�b�����@�p��7]��/�}�˘���n}�H�`G\�"��U���H�
,�<K@���&�/a�kC�{��s5�œ���G2��ac����6�ͳ}��xRN���ӾIK���R�F�2m��iB�wH�����%���[�.Iy^-H�޿R�uApNW>�'#��/���r3!H�=�c.�R�ʅ���	������in��. 6N C){ڒn�R	�h�>��E��W���l�a�Y1L����2�"?"��0��.}��B��=B5JT�-��;�pH �*�y�hxW�vY: ��	[ Ų�����8\�V���S��=���w�A�Nd�j���@��^z����u�4S��$/%�T�{��^gP��M�k���'2���+b�ڪ,�%���Ne�{�����h��S��`��E��z�%qp
��SŃ��z�ky�h��G����ϝ���n�P����8�t�Zw�A~$è�p�ﳮ���^e�F0��F�}y�z�d�Y�TT�ҀI�V"Ĩ�B��1!/�m������ڝ-�-8����OdO�jk0���_��E�/o[�H�4�K$w���ǲ�����<�3�sP(��7$n�ކ}��.P�*D4^�8p�ј񹉔TC�Nh�C�@b��D����9���X����}}o	�@7R��;�^a�@�/աb|��lDό2�]� �;�B�[���:@G�Z�z�l})1�d���cя���#�`:aj��fGRaw�Y�̻��gS�=��Ts6�=�3-jjP�&?j�֤���8�Q����_H�l�+ө"�E6�4��Hޑ�$"�=|*`q7ō����U�����L(�?����(�`�A�mق7��>���E���ެW�j�� t��P��G��w5�@��kn���'l"c��������Y;H��z5��3+�S}�7��p�����ۢpe5&��^���`�"�ta��"RY�Ⱥr'�t�)�^�B��r�N��!i}��lk��;��yq�d�����.�'�j6@DJ�+�ѯ�UfP%iS?�Ժ�֜)Q���=i��p1��Ұs�l��y<8��Re>� Fvj43�����^�Ѧ�P���']|�u���Q��e��F@*�I�mm|N�<���F/��9x5��3��	�XQ��X8.�&�����oY�O։��gI���!m
������P�UF���^�Ԩ���d(�E��X���<��@�ؘ����5��Q�xP�5/��a���>��9h6���yÐ(�?�T�ז�l����<NA�#��F��̐Ļ��n�T�#;��5I��a���;_;<�f\�"�
��R���@<8��Wy�Ԫ�AJJ������ N�S�5�	���U����>P��S{1�ǈ~oa�'j�`�����#���$�T�]�T���2X�+��i����`=]t<�U���=%���D��3YY�ݬ��x�Ô�գ�������"g��Z�	������P�wK�0���=�z`-�W$�;+
d� ~���m�i����.���k�v�?�jDz$N� �$��B�Q�p��X4�
@F��qs��:e�`�#Yӭ�kD^�������n|Vp<��9;*��G?g~9t �5zB��}a�щ&���m�i��d$�#�hh����+�ad����+�9�d�%o-�}.J���l�@r���;�G�v�p�#]�/�$����I}���hK H`����)�^��GfE8_ӯ��K�[�g��Ң-��
d�*�b.3~]�e��L��5�w?�ndJ{;@f�4���3|=��a4_H ]�����Gx��Ɵ4~�g(�{�}`@� ��k=���ct;����Y�dާg�BW�l��<�H���Q�<x�O����7}�A--9:c �x�vF/�����64<�a�橻�S�~��Zsq�M_ᶶ ��,���t��������47(c�b��e���H|NB�hZ��t����Z���c]�,1���!1��R(*D�hj���j�8�#��e�|�Wޮ䙻��0��?];/۔OvM9�F���,!�&�Z�埄.��h�k&�M�:$<p#1�J�lj�wW}�s���\>����JQC��_�b�����B�,��4�Һ#��a�e�.hy|qe�L�I�����l�z|5�t��Re��D���T�6��Ԟ;�Jy�!��C��5c]��(j�N$W��A��"��Q����=�T��i����/s*�G�#�R�$��y���/�{�~�"Ze�5��:GG��F��X�3 e�eQ@L�|h����7��j:��`�Vd�>���A��#A���Q-,�fo8mSB|�|��6�e����|����e����!��X�1��^_�>�_�SZ�6��J3e���cz�m��#��;�����q!dƍ�Pw�G�̜���i�]�`�e���Yl���h%���|ӏ$�Ma�1�ǚ@��'��}��D�>��Z�R����P<��q$k�\v����%��yCQ�i̎��Y���~��(H���[�t�*�\r����T{����7aV��<J�����2/u�4D�
t�mz��*�[��&^��ǫmW}����p˕p�9ˤq
o)c2wD�?���̤|��~Z��r�6�l�HLoݥ٦n�((�6�"
RW���Գw��XW�;U���s�Rz,��膨�$V���`��Cͯ�G쭕33����PaT�u�ɓ���6v��.'�M��"J�9d��~l�ج�M�,>i�7��雟	r�r���oJ���}OU\<rvXQ��mIt���\�S;����+'C�W%N�������v����E���dz�FS4S"�mE������.##I\�>V��]�s܎�Q�h�D#�Q9VNi
G��t_Ufx��D���E,n���C@��.���h��h,y ���D�[g�x,!k�����я+2F�Z�l����1p&^Hv�(�e5q\m�W�1����R+,J��,����a
�#��{�t�`Z�h�f:���M�l~�:/��`|�.H�����!H�@�H�}�(�4}��������Y>̞#*������#�����I�6i�`���p�Kə
a�E~����8��� c�x%؂�Z��� )�7_�<M�L<)��Θ���h5��=e��V�ܢ��
j֞c*�$j�{��VL9c�	�<�@���\#��0HR~F�m�?���ڎ��-�
��	S��,�z�-]��epx�D���VnK�	��6U"��VL[1PZs�ؽb�{s`*6{mHT�>`�����Psj�7�BvA�^��8���T�Y(��K��EH�×�9rN�_���,��8��-��אBV<x�Է�WG>�� H�`�
�Q�]8��e���{8�«�oj[}��L|�Fr�݌�B�h�؄�Q��]߿�;�#m+a6%�Y�)L�2��J�h�����Y��O�^�F����d�-�����ʖ�3z�79qހ��q�(f!����Y�%˷t�ܠ<�?R����_d�褆������Ib�ᗔtuI�4��Ȏ��\kG���(���`T�eֽ���uUj��P�K�|��㰚�x/$ؚ���{�߼�@v�FC���/�>|`%�?��ω\�=D��GJ~�YN݀^#���hk�rG5�{.��e}����|56T덯���Ur��[ȉ��O�ԫ⸿��Wڟ�Ë[i dPR���g~>x��ɷ�6�P�z+&�UvVձ�J��Q��?9�����Z��2�St���b�4]Z�4cz̽1��q �>���7M�����P���BrW��#��Ԝ1�^hՆKs*�����o+8�޷uQmU��9���xv��O�v��'$�{騳i�����io�e6ǋE�ZK�u�>r�:�{Q�ۛy2��hyM����l��6'9�Ш�S^�3��X۽��`�.k訰�v這��z~
�:�Q9:�}�srF��QS��&p���"��t�U�#G�,�Q�3q\LE��}������㽖�]LU�(O>��>I���\Ux�9w�5���aDc�;��@Q�o�4-���>.Q�n�Tr�y��6���Q^OT?���^׉��X�?�숃�ٸ&Aεs��>�iT!��=oj7򶖣����`�R�(�B�����9p�y��A����5=�B7�I>/ͱܬ���]'�]z���o�b��}2BA-�9,y�c0�i�jMH2;JU��C�Ȱ�ǺBA�V���R��!�5O�t`�Eaj�ഋ�4j�"���`fv/�6"��]�^�_�?1ah�1�x�@Tɭ�
w<M�#q!My��1SKgL�-����)��]!�[�k��0�uq��5�>Ո����Y:�$�-�d���3Fs�3V
9�����L����yj��I���'��4
O�\��`7����A[�Rx�ӄ��f��WY]��� 1��J���r�b��/�~%H�z �IX�����Z�4<��"�=��'t��=:赯�m�������QJ�R>���l,���������g�����tk�p�2c�A�D�K�or�B���n���K��ֽ��/U.�Nߠιab)�.���`�r!vB�
C��}��ʊ���-�-h��0l��m��4vrE�gy�<gX�P�V��=
��Fi���ۑ�l�䣚& ��#�S h>L��5�~�����Q��2X��M�]��H1F��q��d�ˤ���y�X [�[i���Ɍf�����Ǻ��[9e?�1�tI������Y�:�.<�gޮ1䈿v5E�V|n���	��kI~x0ۅ�Yβ'�@�͍mgR��j���2X�Z�5e����6KbCw{��û�H�+��z���s��$�:N[V�M�i�x��;)Э��ly��ރ��H��g��7w�S�=S��BY~��RqJ�7��R�z��H����}����R8����,��;� �wض��SaP��ӏg��[�)V=]!��v)�X�9 ����
�@Ծ���1�ڧ7dP��TE������ɱ�gY�{fm�č¡���?$�"�M
�\qq K0����A~ZF�����qx�F7�l��(��v�_��hf{�	���Ҧ�'�@9�I�6>��NZRc�MO�V�`�;w�Ct���łJN;}�<U�?�9�]�/�v)S,@��Fn�@�ZP��$h~&��e�|s0Df���S���{g��Ϛ�\
��~;$^��nu��dM��Xz]/AD6��`WBmk.t�OlY �4���A�Xæ �nm㡡�Yȇ��i�Z�!̩�4�E	{�`�b���[�ی�TԢ0�� "�ڤ�f�S���r�Ye�����q�n��F3��"K«7�톚S���gpl��Mc�����<��K�Z巫�r Q�J܆�G����<&wx�6�?Pd����/��Τ�6��l�n��@��	���F�:l�@_e�kɗ?�e������'�?5�֕��_+!��LC��t�ew�m�K�[�&���(���c��l"G��Tn�9T��[u���+��cK�UafillS��
��V��&J�>]P^hO/�tRޕ�9o�� 7�Vq̺��^�� �|��q�<Q���p8�X�@�	r�
�k��]Cܵ���큤
��p8���W�_��"Uzx2T*�x���D$��c���d���E(v�My4ӵrm�+*[9��}�*�v�:��`���}B�n�<���P��憪ʪ����Q�2ml�ܣ���`� ���/��+����5�<:E��P5�g�e��F����c�m
Γ��E�Ñ�!"�!��p~�N�D!µE\�5�������R�&�	"�zR���T5.��M��]�Wlՠ���0`>���8��1��Y,�=.��8AH��a��v��,3Z�i��������`�H��^��nsQ0�8�����ڙ�2��T-xތ]/1T{�����|jv�r��45���qc���������2�G'*F��`�%��\1[³���6*mf�\N���A�Ew$����9b��뻮h
pq��"Ъ�������:��/]u4��'g/d�N<�����\Δ3+5��h�NjL7{)�2�"�RE��b��kP���v���qT�vc�߼wWR��4��{1��ԭn��Dp�+\p�%�k����gx.��p�*�1V��(Hy�_p��y��l�Ц�"�!�Wk@�F��������q{g����G�O�ūD/E$�2��q����7�q`�-顋�(A&��"��� (�P9�r��zb�a~v�)<U %O��F�xD�ge��R�Ȓn1a�4fw���%1ήtO?�Q7!Wa����O3Z�lt���%� A�����&�/lN�I���/~0�G1��5+-5�n� ���]���	�q�ʄU=R�vG�i���B�W0z=g����0��k�yX�i��^F?d�9��F���]�a�V��R����[�����kD��Q�;���(�n�d��P���ik���(��x�b�sB<��?U%h�7t9�vA�z��`ǟI�\�؎ۅUy���C|I�%��=�*��f��`�2�����y���O��J�?��Q�����o��>T�)��?����@�Z ��,�ٸ�4���=(c�AId��Q��gD���>[�)�
=Z/aqTO;�y\V\=GCI�Āg@���uGA����N�ۯ�h-u9|�\X������]���@.ߞc���d���X��*��P�/k>�.L��
r2���i7�� �)�Q���r�~�X�U�Ch�E��f�!�T��ĵ��ʏQ�:�	��_����C-+GsǯE��o"�	�0�p��ݙ�ch3iF�8|�2��
31�u�"E/tH���~zO哟��S]-8�%���i�̴gR�3���^hO�5��X�7y�fE��j�sq��!+�����-�n�O&u��B�M�n�z0��̂!VOɓ&��n���I�vJ=ҥ�#$GHo�ZVB��&I9�h䟈Sg#ծ� ˞c������>�
#o� �(7����Ɏ�L�Jz�Yܴ�A���Ƭ-y+##4K'rx�}]9���v�S.1aW��~+m�eؓ�u����F�9te��r�o�5�CU�E�=8ݠ#n���xkXm���w� 2Q�<;�2���CufSv�;%��?���S�Ʉc���f�P\��
���&W?�@7+�s}H�Y�Y�!B� ���:Ү}$_��'�c'p�@���Q�� Jf��MwF�!�ݴ8�6�GJ���l�/�Y�T8c�1�s^h�	���_bRq/��\} �M�?r�.����tE�.�<��٨9��&W ���zF1����ʛ��1,�j[8Y_ ���R�|Q��`~%R�SX��GBB3q�J�O�i>���lr�%/q��|D̉3�K#���z2�@]h���j� ��0Ɣ�J#<P��/��?�,Np��f�$���kXb���2c%�?{v�,�
�r%�"c[K���tq��M!�s��ȧ��]��P\o�͆�>�,�*S�%?R>㭭��6n��%D�˕\���N��$����/���R��w��eD���<@�լ�Y�{�Q��缊A�6�t1|c�/�M7zy*b��Eo4Ss2ʷ�0y=�;��0��e�8w�%xX�ؔ�D��]"����[}�q@�'���N����S	�4���k������dF����S�m���{_.�W�~��.���i��ht��Ѩ�o��aY�<u=;�P�A9%��6u�6a�>XOl�p����	�X���L
��C��'Rivp�����Q�����}k����Hi��GG��^d�V|:I��~/*�y�Y�nG����	��a<���i/�4����yQxfj-����ҩ�u��T����0#�!���O��t����H'�r��Sc��������! �褣F_���Gem�����\�v��&�;@��]?C�No�ژU�\'�rSBS�����f%��e�s����fu��e��])���2���"�N���T�'��	Ŝ)jx����f��_|���{�˴��˯C��)��ܘ"��������~`~XxC�Y�F��==W�(�
.�燻�k�3��D#�V���Y���i��_�����3��B|z� 6;d��X��;�}P�%	'4���>���,k�ͬ�Ә�Ա���N�"1�
��%n_��U��&v�ӣ����4�jZ�a0�_���+*4�fP���g
K]�"�ʚx��/3��]l�D�-�wgN�JM�j���@�s�N����P����n��{��Zje��bo،�@�-�@��
��f�,�H�ZCS����6��p\�!�Q�]���R<�7hN�3��(�J�3��`y봈r�g����]Zۜ���Lql��D���w���;?i�w�G$u`'t�̼��z�7��+-�����&`h2��2�>_�t8g�c�4�0 �u����o�"���]����?����L�k��dy
�E�Z�(��pt3a���6ZUĊ�z���G3��,�y�q���5�;yw�W��/�g�;�`�
�Y��y;,���1_0�(2�}�fwMU��]����X���?'�dō�/U!��RG����Ȭ&!&:%�z���w����m�_z��Y+?d�j�c$�E�B�Dz^���KsA�3X�r~�^T΅ݬ/bٵ�uT�Ye����LD�:���)^ȼ4*������O2�l�y� �ơ������|��6�ݽY`�O�	0����Wq��p�ۡ��_��9L�_ۢ��m�I�hv���~�$�w(Ύ���ݿ�� H��G��E"�%�V��%�_5�5���r�]<N�E]�P�-8�T����:w*�En�m�1>M�~o���r�mBD�� ��3H@)��H�?�_�Qd�E�C�GBy�ψ���i���ƚ:e��d��O�a+��k��I�������e�g���m˔^�d]�W\�<"0���,����k��0���p{	J��l�0��q*��I�I}�7��26�fi8�E�4����J�=(D�uuY_pB�n��DQ�w��]�L�����i���'	��2�/v_��n��y����r�w�y��V\l���Jr�����|
�\�B+�u>WEA���.�$�yL'V�b���Kt� �JD��n p���U�KS�Uv�rw4}�b;��a:֜��n&�i�&�?�ź�\���^* �j��B���E�����&f�<�z��N\����iu����:�B��Y��R��^Ok�N ��}8�$�8��YjbɵJ-��S�#�UZ@�t��ӗ�#�0�w���������(�H2��k����u��*5���SFq�X���
�@������}(��O ������C��z���;55U�P���a4�K�a=�:wB��1.r�J�m����x]�a�m�V=�:���{KP���{W�� �xb�eT��Q�P���魹!\�������$�S�
�{��p�g�Q��e�x���s�¿����sO��Ip�J�
 ��C�\]۬J�D��ZLd�h��	�b䳦�6YrǑR�0\�%��{��=�5h��	%r���ũ��X���d�fJ���L�ɤMȂ�T�#�z��l���j����� X� &s*.F��r�$��p�e����v���
ЯGT���
*��hb鴫 IA���I �|���˪����|���g;,}B~��h��&~�Ʈ+�
���]5.��<�	��t�/�d���yl::CݸVc	��lt����j��X�}3:!qӚ��V��bǟV��/���5N�FIѴ<��ܖ\T�����̿F�I��U�mXlCM���9~�cV 񓥬�HX�p5�2��t���$�a��mހ�-���p�T9v�S�CÚ5[i�u��	����pH���8�qh��5p)�$��m�>v����p�o ��Mh��/2PS]5Y@է3/��ՑZ�B����4Ic����]��w֔��1�:���j��~q�W�W�	
=�}�M~��3��!��\�p�d%����=��Yt;
���Ij稖�-^ouV�j:HBM.+�V�8�ɷI	N�]J��? �1e9W�Y���.
/^�S!��lQ������f�x�e
��W�Z@V����[�o�	��ZA�s�!�~�����$kQt&rs�,��E��
�59�i�cP���R2Gio7���䔗m��dH�0���M��8\�#� ���l:���}�yQ��'󲍕�Ä  �"��Z�_ ����������g�    YZ