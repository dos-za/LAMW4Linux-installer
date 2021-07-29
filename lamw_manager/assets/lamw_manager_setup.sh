#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1048981788"
MD5="a612c2a0bc6a86f3d03cd45d8acbc7b6"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22492"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Thu Jul 29 16:15:25 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
�7zXZ  �ִF !   �X���W�] �}��1Dd]����P�t�D�� r�<S0wG�B�U:P8
ؙM��IF(|��'S�;�Y ]�Y���'�5u�^:R��̴�"��$�NF)��S�DP ���(#��a��|��&����hn�HQ-O(�ʾ�B&] )��6Is�����FI�L�� ����hf�ܶ��01��D�G8[������>��_��ղ����3�� �ٳ��=j|��M��5��9�Z�����|�9�;��:�_	�!�9��w��K�xc��D�D�R)���~a�!���m&�]���+���p������0��Տ��ڭ�j&����z쬊��r�\�z����g%��$\�aY"�ѥQ<�"�����Bn}#4��Mn;�3����;H�jNERx�J�����t0S��������~ ��H��ž�Z�m���)O,q"���(<�s�NR]��:��B:��o��ϲt6���'v�A�c�=�b��wj���1Yq,}������͍��M.��Gּ��*��H�h�Ɂ��2�����0�sw稺#[~�A�f����v�y�~��p-�PNX���y���7l��ԧ��6}��D5�Fb
�\wdO�o�n�t0�[��r6^j�\�J�ZP��f���x�T�%RO2�ɡ��d�����^�|�~�7&tY�5�]a2'!+v����A�ńN.��qӇ�خ\� �vz"jQc��r�N;��o��IY�q�<�v�c_�[�?d(z�l��]吀�؛�z��~W���H�gˊN�0���w����9_���oֲ�j7KS%󨌒&�&�HOU�8f���|��"��>��I��e�U+`�%��Y�79�e3�ZqL��n��zU>�L�Ř���]&�FA���Y��3�ު8���� yBh0�yB���]��g͊�P@�z(7l����>�Mu�T�T)8v�a���, � �b>55����������W Q��&ͪS.�:C���٠�i���� ԋ!��ѷ�8�m�eI�v��f���B*�]3���CJ����ζ-�PQhk�d�0s�6-��~��S1`O'�vf9DnM��j@�����{V5�g��qx�Z�-�칀��-W�!�gP���:w��Y�d�:a>����K�;�\�K��@�b�hD��E]m]S=���t���z�k^队I�%r	���W����{�q��|yң���ۡO��@�,�qmͯ��sQ��6�W�h))8N����}0�c�d��T�'�)\���n�M��C��t�sd����3���W+3�N�-k�,�)��p�p�.\.���_�}���� �&�H|��j�F�N��Sӻ7j�N���]K���u
���wqgs��߮6�[���q�O�G/�_bb�1�*�Pp�5�5 �Z3�N�`?_�g�{�6K,6���iɠ��;�9&Z�P%��i0ǼS8!$�g�~]F���4�攭�҆��JB��Zo~1fr�יi�!l3�8(���O��l��m/m}�Fǈ�T ���z�+���ˮ��'����d��fOQ���"�]�V��F�`����8�!�ToL;�M3���;��s)zH�鎋@=j�:�j~'_��=;��HYH��J:��^�|@��LО~@p�d#П���#��R��DV�#�Yח��? �<�9�,��nR��B��AL&�O+Z��zڈ*�:���#W��{7>��$�c�w��4G��bU����������	�ڑ8�����a�Z��BV#�G�փ�\g�� |%��V�ʏ���[Nr7t�R����^�~;��ܶ
��rhr�"�2�}��8�=�oey�ƾ �6�<*�W6w
�cn���>�>�+5�Kۧhxj��!ի��l.u崣��$�i�bK.��Z�(���*�>x�FeW�-dG����DJ����$�� �V�rf$���Ǒ��ҥ��&��07��Y1�t
��òZcҞp71،�[���꣥�t5?�	t��?�p�E\���D�tک.Ң�� aM��������FP�N��0����C:unv�2����.���~��N�݈���~�u��w�ķB2��rt�[!b�<�}�u��e�%��ٺ����>�����h�f�'!�7���*�=W�#X�_���~�.=2N8޻���������/~��e�`9������		�1�OU��w=M��dx��ɨʙ��v>��N*t�l|�^&��6sbkVb�ܷ��9����]~��+y4�SF0+��e����(M��II�T**�.0Em�G[�]������p��y+�K��E�RӜ�wܝ���S��p*M�J�V��#���d��jG�<��M"��%�V�V�S`ɡ��C�*2�Ȏ\��xXI�V/5�'f�b�ת� :���!�נ3kw��,A����N(�G���aG��v�9�@Ħ�������-#sIDW��!/s	0�������,c�&�X�nJܓށ��:*��s���#���E���*�H��Z#Ry��Ji����u�p�~�b4O�%t[�4R�����b�5r���|65����"�5�)����
D�'/�?{ݮ,�%�Ĭz�-�� �Ҷ����D	̐`���:�t.1r��Rg���A'�v�Ȁ.�����vz��(�xQ⸙�r��e���*l�谂�`k�7:���\F��̃�6��Ь�G�.�#��P�ӥ��"�����ά�U@$��2+���n�,)��i��i˜,K�U��I�_�@�Ӯ�V慿����S���;�NC��,�������p9
%.���I-O�k�b�=<֕�W~ug� �l,e�`'���W�C��I
�A�3�y���0��]D�Nj��NY�KX�	�U@ᐛ��&�4��jH��P��d�yƕ~�#;yY��Q�w��d��hP<�j0��و��M�����E�/������;�08{�׿�x����X����	?Uf�&�K>W��Rv@��f�2;�x���v�����4���6�x�c`<�HAZEY��D��-�+&�R	��=��w�|�X��v0-��e���4�N����"�6��D�n�W���y����u6yj�C~VqN��7�-ᘋ���=�kʓwF�_T����p�ع�!=n�����F�\�C�A����`�?npϤ\/V��f4��Ĺ��@.KB�l��vl�lh��
�M���@Z���q���]p�hn��<��-��K����}��C�ԓ/恷'�0�p�ܑQ�;�	Z2��� ��@p�~���;I�}�=9/�O��]4���~��b&NGN�FG��t"�Jͮ�~�bPk����.ǧ��JpZ�Vu�6�_ .����A�A������;�Ed]yҤ`֗�6��ˋX��:\H,��}e��J	�?&-� '����o�����x�t C4���i��G�^��~�zN8+�b7�j�N�������^`5Wm`�Zj�s����yVJ�-��Ȅ�Ku���1��Bx�l�fM��=��ݒ�fB:`WO
�ܔ��$R�T2���4 #�lypKaS�=1l�j��d�x�*gR�o�����T#�-��l�U�̊�F,!;�'C�9�p�'�A���a!9�v$�����[����I�_�B*�Te�9c��;D���5����w���Z��6uM��?��||��x���������6*�ؚ���h�D��F���yQ��+??K�p�ٔ������?8<2k��10�CSw6ۛ �֛�.ˡ�����L���`}�� }��Pq/#� 	t8��p.e?]d�L��|���2	�����R��@�sA�2r��J�˩�����pI��7��[Yh�g�~���(p� 2B����5�f��E���P��[o�i��A?qW�(w �a6@��\�?ɑٸ��F7ϡں-跄���-d?�?�/L��l��I	���us���zt�+��P��T���w�?�?�4Z᫖vr�YD�t�`u�z���>F�e�If��� �R	�)=��'� �D��=�u1ܦ��#<*��N*Z薨���L���:�8�]�C@�ŋ��f|h�iS��̔�R41��E���Ѥ�"x�K��X�Ƥ��	A�
�̞A�&�;��H���L��HI�q����DyaNJ�yibN����|�d��K��)Z�����t��� U��j�/���N0���6v�f��kbr�뛮{@��ܳ5��NV9��(�\��t��n��t�x ��5U/��4A^{ׂ�N�V�q� �����rg�ܸ��!��]����LV�;^(��XÊ�f�Qr���z�p�y��u����mU}�5���� �8�������'D��Q�i�Qg:�&���}y[��ꓽ,�_��yѢR�^�2jvNj�-I2/��
S
���ɎЖ�p���aQ�_���O�� ��_�(FK)FL`Ԩ�O C��G�N-$��t�(����i:��G�f�'�۳�t�R��d�YLb��X���?�P7���q�m���Dh��~��wU��.�\4��{�'�6og/��Z�Ґ��]#�ѣPPJ/}�X������c�����y袆� g����R�N�I���tI���70��ST��f�[�s�d�G�S�C
G�������|f������P���CL������JB���2�4�B�#b	s0E|g
�F`��-�$�a��O����v��:B���.Uy�o�hm�����sy���2g]I饤ɚ��3�zz�G��N����߭�$ic�m��Z 1���=iS襍bB��T�QC��B��� e���"���\c�ak�yƋ�u,�Kp�J�b@�!
���i�=��u�Po���|?������?B^�c�!�dd0����<)�{�n�e\Υ������:�;���{aҘ�K*W[ǀ�,�y[m0�����������z�A�%���_>"����Ͳ�4�s#����(�E���7�b9����Z9��j���4�v�.x9KR���$��ܙ����jk/B���ǂI*���V��:#\��
�26pJ�J�NI��� ��~�E->��r�rf�B3,̿#��O�/_Ǫ��*MW�/�Ѣ�"����
ߣ|�Þw<��o�9�6���\�H�{;t��u��҆�h���o���T�!�T�S���r/G�g�½� 
����NVJ�
�u/�Ɍ���	?����s%ֱ��:l!����~����e[!��4�5ic-��~XqC�tH�=��$���Xё(�d��%Y���u�!�6��j��r�GF.�\t?� v�w��p��Ø�3�4G���?U����eh�ՙ)�E(��ؓ��߶H��J��j�w�Q�'A�1��&3kt�D��pؠ��C�e� �)�n��^����P�ӗ�{̵�|T��HJCrs���i+w�iu �����I�8a�8���[���HJ�ǰ�c?���-��������um��an���?�]���yʆ�"tDr\�N��ک��u��,��p7�?�����ߡ܌���%f�m;4�GlU��Ye:<J$��!E����s��kXa�R�^�!�#.T'�8�e-�̿ZP��+� Q 
 g*d v�j��P!>�_8��K�E���e��-
�.��4%0�U�K�`2��og^�U�e��'�{�a��1�n��F�T��{r$s_��/���jXA	��`��e�=�,~9�F����r��%`=�ݎ�ct	������B�w.	��Ԝ����������7�b���6���̜�\��׹��A���-'1a.��Z�Ҹ�`ȖA�M,b$�qg��(���J�̈�8g�I@�G���Юo��HI%��O�p�q�����vuRw�	�>F�r��X��΋$�z��Ā��uꠞ����XKuq�nՓڋ��^�X�|N5� �C¦����9H�P'�G�ئv��f�Y��(u�/��Ô��u�;DiE��V� ��6���#�H�%����0�`�Q͂#	Em�}����7�����ѡ�F��wX�K�b.��D�K��H�dܙ`<=A�wߖ�K�	����}x�!
��<���]�����<�9��H�C|z�a�4J2^j�blY�n��=�xZm�[�۱�q9�I�.��U�8�
���pH�q���
���>���o/��3E���z��GWB��ן\X��+�	�8��2Z��n�� -�����\�*���Ug��YF��\�\��+� :<�f�B|b>F��qk:�'��?�5\h�(��\1��G��;�R��K��Q�޹��b�@���K���)�A��|F���yŹ�[mP;�em�:��ϩM����VZ�/��W�
��S��Vk�~�35��(��[�������ۻ�Ʃ27������u��J�*6����DT5���/>4��U�Lvkn�8?;h��/�V����t��"��!�7�ŸA*���`� �O��I��e�Y��G0Ֆ�6�8K�0v�N�6��r�o�V����N���K po¢ؙ�5p}���LŎ��5/9|gJl�����RZO@<:?/�W��s��x�d�щ��g��!݋��Sn�.�hd������*���k��0U=3)������Ԓ&�p|^(R{�/03`�Җ���YW)6%uy�����cuG�� �Κ�t!I(6
�ŀD1!ǰU�#i|�����}|�~� �7�.��O�Å�Bm��Y
%N�m�:��%-ha�Q+H$أ��$�m\6w(g�~ i��D{��Q��������(y�~<X���@�4���f�@���3�L��OA����s;�4�1wC���g����qf��rl��	�LYK�l\�5KF��H��Y�!0l���U���tR���>vS�����B�M�,Q�7qH����G<	�B���x�A���IAb�|��êG�ȣ�߃r��ƧG7�K�x顳x�y�����'0اu�l҉y���oN���-̳h�K* �(�>�� f�P��nl�5��c�p���8rǷ"���9{�e�l���@~�"��t�.@s��sr��X�� ��I"�h0)�\��,8:�8@���������e��:҂o^|.;�h6 'I�'C@`�QVr��rF>���:3K_��e�b�� S'̲���5����ݦ���� K���N��b�\ཎ/�{��Q����:���ْ���k8V��g� y	R�"�J�%��Z��f{��qQ�V�� eS|��]TU���%�ET"{�ଓ���Э���A�_N����jVq;��p��_�)�atʿ>�X�,�3��z=?	r!�$Zމ(�����e��EQ`�۩*��|�h.w;�����$v��TdIr*�W4�ڑ]�
S���W=�{�Z��8�����V�E}�B�X��1Vе������r�M�?�#:�3|E0$;��S�S�������#�V��iW�Ü���������?�U���ۧ�r�v@[K��-�U(�(�����)F0���8H�A@t
Y_'�;���O�Dh�B��=q��D�whȲ�M�����EY6;�.��O������;�3V��	ڔ�t��}GP��X�8�OK�E�6@Q�·��S�xw-��b!���%K�@r���a��8����+U�'���N���p�@�6�e�ϽpU�a�B3)�lL�L��r6�Ͻŝ�-YN� UYT����B��FE��q��t��WxOO���5[j擖&�w�w\�Y�P6z��k�d�CXZ>A�f;�_��+%��O���p��7�$R�bZ���:F���{/6��=�0��h��v�(I��Ht]?8Q��Q��̜l�1�홽�(%Ѣ�H9��  ���ّ ����d1�f�b�^M<c����i�񣹡��A�;�g�p�~�$�,�po��>o���^�n��(%	�3��ߛȉ\T�g��T��|���A��f��!���#,�"�7�|Ҁv�}F0�Ҳ:6	��Z������dMwP�.X,KȐ�9ϞEI7�v�x3�VlBTsIGޢ9iZB����,A`W��[�78	"�N:��Dڊd�(��GX���YP���9�O1R�u��qנ�[ɑ!�eA��.�ׯ3�%�}Xt^�����Q�d\�}l&㰍��˵�vN=P��[�� ޵(r������:Ñ=l��M_�Z`5��]��Hl�y���V������nh�����q�O G�����	̹�_���PN�ߺ����Q�k�#uM��-/|[rq+��}F���$^�;r�5�;r+�ۘ�צ}���K84T&_�X0�N�jf�Ro[<�#M������C�����:޶螿�ou�6�2�������/�[*���3���^>1��o]����Q'��s?9*|B� 	�R�t��}eQ��>�騢wLB߳�++���&�3� N�Z��H��n	�Q�#"�����I�we���Nχ�^Q��A�^Di&WwT�����x��%�!&.U��T��J�Zl��w!ɬva���P�|��Ayv�F��i\¦�W��)�o�gt�0�T�@RE�/XB��J�t^ ����Z��Q�['��Њ�X!�'��E*�C�i�4�d= ������%��Vj��Ӟ���W��wy���q��A~p!ʩ̃�j
�;���n��ĵhK ܵ&���@UKd��@��#�;�^���U���ǝ�т(I����h.;�[G�O����4Wt�B碻��wV�`����v"sR�	*��i3/��H�b��)�1�r6 �=����D=`ލGMG�4M<-�#��)r �����m��]��C	�G����`M���yȢJ������u�j�4&�(pa^f�Q��>��MHe���}�w������{�Cl�d�'"�F?�4� �lGK�z����{��W��jZH�M�1�*_�8&����^����<��s��6s�bn(��gv#���Γ�-^���˯�7���S��a�|�{�������vFN��t�:ˍ�p�%�v�L@���о�
aĵ�	�J����Vx��5vil�xo��,�y�i�%�Y��%����U�F�C�e��g����mk��.��W�C���t@���k����|�{�F�(���N�ӷ����z*���n����xgKx\�s�ͩ)>H`��FY�a�2�!�B�ރ|f���F�=hN��7x���މ��:Xp��(�<W��]��`���H����?qҟ��\eS�Թ��p�~�����F��sH�||��� ��G*7T�1.��v��hp5N��#�ړ^�7~[�N�I{G���*���k<��C��׊��U�0z,ޒ@��Lv���Z�y��\(=�`����mS�P��7u M�i��^�q��rֆ�^ރ���:d���&�
�QX���?���v�| ���W�5��7��_щ�\x�y���>�JS�e;n��h�'[�?���������n�P��K�a~L#��ᆚ�V��j���;����MgZn4�t]*+|x�o��|(�I�]�˸/�:)s�7�$s�a�t��_�-18I�~ ��H�����eqp(���ɉl��D������E��]�)U����ˇ)QQ�t�	�%��B�>�`5��|p�l���6άjKp���n�ͱ6�M���1��]�!�C�jS�C�"��,��y6{P��]��R��%P�xԴ_T��|>�<]�,�V��k�����6��r~[q5�[�a]$��#�'�0 �:�jhB��}�x�j�rBtGc�
�	J�ޘ�>VDL�c�د%@��z�:f�R����(�y�HH[�rA���\���QP���?�K�?_�ns�T�;�2���Ҧ��/l^����T��u1�b�����N���^�¦jI�v�C��P��⊏�*9ȅ�֐��b���B%�X�� 4R�%�YML ށb�Os+Η\i	1����t��6L��B�
5tG��T�BA_U=#�<�yy�&�\�$�HFy���~�C����SQb�;��
��q�~��E�O�D3L��Z/1o��FMF6�S
�c�H��^���NC�5�.���"��xTwx���5��0#�']f����[X��-GK�q*�ذɆ��N�b���i.,K ;&o�l��[@7��*�>:��'O�/q�)i@<F�^�[t�n�Y��=;�	[p-׭ҥ�Nx����3�ۈt��'mG�a�� ��ύm��v�����m6����l�'��:d����y��=/mI��XY�ߘ�X�~�y\
��^�-����D�:{�R�r0\6Q/.�
�48�$w$��6�P����*uU±��7V�*m�B������
��(Y�p�k\-�>cw�D���� 0��#����=�	,��hޞ������4�#xݓ{&"3�T�u�`o	� ~x���3*���a�E�;l*�Po��c�n�L���V�HC���N�͚������+�z�r�~t��PTu?�׏����}ם��1���R�p~*�pL�J�x�����~O{I)�2������c����7	eX��<X;��^Fʬ�l�-��s��ɇ.�����$���I����Z\{�uTMg�W�Hd����!��㑐�͟�Cz2��r9�B�p����X�ҥ�x��� /�Ӗi��Y9��8N>R�G�v�9̴d���z��q�b32?W�����P��O�_�ϣѫm�O�/�EC��T'GZ�������g� ���/�ݹ��W�DR�i�SmNM]��|.����Uؘ��ȣsEw �o4�Fm�*�w�F�Zk�!|��eq�"s��`��~�Ny!V�=�+���f��Z�貉�7���Wm���H!c�j
	�%���UE'�NF�+�a�
�ut�^��,�i�����?������#�=�� �!�¢�8|CY�������/�1<�2�m�+��m�=����w|lvA���hܛI4�4l鶯
�or~(N�	� ���9�|�8�u��gُ�V-l��dbWybA��mp2�f

wP�$R����p��6����,���>i��_����f)e��=EG�}��A,c�����3�_�}S-;5eAU�b#�';�xQF�a��~���;Du^n��aQ,Ԕ� o!<0�)@[q�uK���ϫ�I�(jWPI���)�;;t���@`�th��3#up��_c�=&Ł�r�D~�[Hg@ v�C� �\����!i�G�o,x�F��*�}�nI�*ZD�O�1��	<����F?.�-rA�LΎe�X��.� ,�_�"��g�F	ğB%���ا n�p���f]w�y�Z!:ʘO�pm�Vj�Z���e�í�/jQ7건q����rq�򑦨�c]GEn�`��I��Qj�B7��cU�m��JS�dɏA��G�{���x��&�1�����̍���[��tC�������h{Cr���lJ@�k�
��a2*p(+���{[���1�$����K��ͷ�!�+��Hs��?Q5j��ŎV�����+2��uT3 o�q���6�}���=x����o��GF�֮S{d3�d)����E)s2��.=�Q���� } �k�b�Si�@����ȓ6�!ƨC!34�;�r4��b
:���6�wG34�G���rD)����f3��Q��\)��ݍ$�j����O ~݃��jx��dXG/3�����\�1����p��-R!�Վژ4W�5 �w���x�NT���Q#*D����Iqmyp!X�C�a�ȳ ��[F��# �o�Q¢������)�����?�L
��)�WD�T��,�⺝8��V<A�v��ߊ���©H:WU�7���a�e�ڭ���-�f��W����8�rMP8�Jp����&X�9�d?�h�|�����#ʨed�_�?o��۳�����z>�,K2 ��_��� U���T�v��c6/���BR��_}p�Ĥ���-/�ELl��������>�4�x�o�!��~C;y"�nv�XF��Jk�'K����T��G��h~�;�<�EZ�D�%���Tǅ��'��ʣ\�1q<�%[�S���ΕNc��wN6+�Pw��tl$�y�V=��������d�3����Ug�=�ѝ���|�&��}j��
��Y8#�O��H�ж�e�}�I�5^�'A�l�ޙ�<���v∾A^e"S�);nJb�=[0T���WD?���C����]ڐR�����]pm����Ehn[�� ���}��浑�I,�s�b�8���Q|�9w�BS�;.B^`�:�	�Crwǂ�����I��'����^U�3E� �\�nFF(~��ڧK%T+ `r������Kí�4�	TQu�e��-��2�4�l��>>y#�]�}[Tu�:�9lW���O�H3�D@�_b~�,���>؅ʁnb���:(�3Ȥl�,��S�Rv(��3����igH��I�����Mt9���%_�l�\�?~ IQ���<$��;6��F�]��⩆:܄�WĚ������������b[1�� !�D�(���C��"�Lj�Qߙ��| J�>�.z�x��C�C����3h�cH����<:�s ��_!o�S%�[�7�0��g�q�	g��N�fܽk���^�C��an��V�}���i��A��(��VW����-bb:h��������4H�����D�r������]�X�8$����$���?��'B���p���Qk	=�-�(P'OXZ�#0�U���q6��)&��>�\����P�|����H��%��ͨ���h;���uZg!G����ΪbG�b�,Hgґd���E}WeW��ö��a"�������U�c���w�D��U��~�nѽ��w���yo)����G�'�j��d��y�Q�s��v=�<]��U�
@����Ē�k:�@7��!�Y?-�
�9�W�9Q���&x��C�9*�M�Lw��?YG�ޯ���i݄���I|�5>>9lS�_<��$�.�Br�&Y� ֖U蚕�U\��C��y�4� v��M¶�0f	G�e8��P�alZ���c	��j�~z=��th⣻:f�hK�p�,�5wP��'��g�2I�,�jp���ƶA�;x�,}T�(`n�a]`F7��}7��-�g�S8�̾Xv%b0���$�MSC7�`x/ ����p�R���R��wj����P��(j���H�	W9�M�ʋ��[�I�G�c ]	2��qs�z�?�b֚bq��[d}��ՙ�,F��vNMXGí�B4��>'m��-����s.��PR�K��<.�Ԧ��8���p�[��?M��7o�mEͥ/����/<8���j�`�P�a4K� �.*����U�]j�:�p���^���_ܾ+��a���_�!�@�t�Bx>���HLY#Ԙ�9w}6���+�: /�}'H��|(`7�i��GGBG�Svx�Z'��~_x O�u3P�oͤԶ1^!�!x�������3��.����<�v���#�L0]*�G,h�/p������@�3Q)?���r�� ���O�/0�u�},Uխ
ޫ�П�ڱ�#pZ�{�ϮH�� �gH�2��-�D����-�z���qM�ݚ};M�7Si���ͷ��\_aÄ���6 |҅�~���C���5�_P�<D�Mo'����OZ\]�Xe��O/�.��<0E�2$D�q]T�Uq^�����03������Lt&��	��υ]4D�.D $^!�y0�c�4����+~od��6;���a��7�:��a�.B��RG���Ґ���}-[����"GC̢[���}�&�����w[��i��@��j+�y��߬����L�k{p<1����P����}�!��T44f���bo�f�X!2�F���=�b �Fv���Xa-���s�S�}�"��� A�d��8�#�8�3��"l�#]g�m�Y�Ni�r+e9��(�2qMݔ���KGg&k�c8C�C�Y���^l�+�r��� ��\!:[����!�y����o"R�4���n2@��/֔�0|}w$�����}l[yL��DhU�m����1�]����\j%�yh@���V�B��l)�ڞll_�n�D[�P��=Œ6���a�?'Y|��P�g�$v�i �}VxT ��P[�P+��{���U�Q�W��z�q��͍�z�S�S܁��Md�Ne��4�Z�q %�>��vX��Z_�/Txz9��&��v��_<Q#�1��%L�w�͞�$L͜�7�\3�|f����Ì뚮~5ƊJA�+����'�c���ԛ���㴒�"@k�_��iUw����MV׎���������wF�;P|�^�H���D�$��}q��}e�9w��`���Jݢ�&�I=��V�%�t>�4�����?C��Ÿ]7O�C��=��i�u-�h��:kG<s��3�C��b��W˧^���(�ح.n�-�F��e3���Q�l���w��2��Z���}�]*\;���p�,�z�DEv��t�INT��F��IW�F�69To���m�������������#��J�"�c��n6%+\2c�w$����a��Eo�DG�R;���2R�E��K�NА���������t%m���P�Xf��˓��4�hm�VSd�1$�*HְR߆]�>dLO��ȅ$�咔Q!Ra|�Mc'�fwK�5�V}&qC�|{��N��}$�H1\���xLƫ�{�1�K#���i�u��Y�q��Tv�����(��N+q%b< �O�$?��Uƙ|4�g�1���%����/)�ߎ1Փ�e?Ԩ�u�E�a�G�#�++�MZ�4�LI�K��X/�s(��Lsbm�K��R�}�v�)������n�E�^�É�V����C}׬0F����#L��3(]�L<�5�[���i�G�O�x�)�ԡ�U��=ZM˜�|�{��]�٘�nz�~���m��}}�1E��ɦ������,���`��7�߈�C,��D�}��0�k���l7-�!���8�d��}L^�s�0T�]���[�$�E�K=BB������o�P�͔������o�����R�-�-��T�2�칮��w�Q���%�MCi�4�aH��2�������[���#��)����d\� �~lΛ� ށ�-6��㙐��2��C��&�4^�9�����/q`	�(����Ku�Dh�f>��?bp���E�Z��a�ɉX�M����'�ӟoD�Ae�a�8p��[�C �W��<`T��*5��G�0�U3��([��ε8�vrG/:��xB����Xh�p��{�O\y.�K��k�0w�����P~��x�rɖjy�I'�FVR]F��v�5�Q��[���8&�l�V	+�k����[-�L�[/#�h�*J���Dk�~.Vi+����'���&W�_��j�7��bN^��#����'�ͻ����`).r���i�n��G�ZT���Td{8	����f3.��ZD_)��.4zѐGЫzF(=�krqF��Ĳ�c�cY��0�W�هgxy8��r���Z��T�?e��8�����>�0����U��捳�V�{wߛ��L>jc7Ԩc��lΊ��^ �2�[9�V��A��9��|�������|����X��p��,�8���X�G�a��/FJF�>�7Q�B�'3|s2x�M'�=ev���/���/�I������z͞�(��]�M_���+I�-�s�ͦMU�#��nw��\4lL�?VY�]<8}���<[�����o�nv��_hE��i�<(�?�B j�-�7��ԧ�- �-����}+�o�2��R�tR��m�;T;Z+�p��b�õ���y����̌?��_#:5�VR��"��}*Xb���>�	~h�ӹ�z�8��#$�H�9B�q7��81���ε�Jws��.�$0�\J"��'b��pD���,�d�idh]���_;���A4�e��"m���\��.3v��R��P[W>}d2��9Aц��|�cSN�����s��;Q��ݭ��)���NJf��V���]�1�fj_[T>���j�(Z@M&A�sC� ���v�c_Z�T3�\��q�g�M���apf�	~�n��du�^H^�bG��e�l^&���M/F�6RՒ`U�3�Wd��H<���g�3�t��M�(
9�I�,�����Z�����z�,i���"����z�3����)]������A��f��{L�3��q��Ӌ���DB<	J��)��k1 c�<">ǒ��)uٳ0�^�� B�w���'��C�-�lg�������q����j�B��G~�ޯv�����1�a��Y�ƹ����K>��X�����뒨zD��wYS4�
��_Y��R"�������*eҥ���Kn~�[,㚼����i>|������J�c�dx�*w�^�}sJ����8�N���/ˆ��?�-��6b��׮��ᮆ4R5U/�7�V��3�X�6���ǻ\�ҏ�'i��9\��G�0�����
-�����Cw� ㋚�hT���q4�KP�!�_�d�g�{T-����>gM�!N3���V�����y�+��a �ᾤ���և�}�"i^����U��2>�1�<�\��5��Jw�'���@�ܐ�x�k=��S��P`�v�����{�婬4X�%������#۔��0K0��q��.f)�g�/��=�mv�	2�}2�MZ�uL�=�uUY^�|�{�A�Fӷ�`-�!̪���y���~�ҧj�[�>C�^S�v�R?�z�q[;A�8�RϤo����D�k��hw�z�uE�[4wю:St�� HcRX���.������'�l� r�����h$)=c�d��NT�s�kD�����̹�䇚\��uAb�A+V�I.�ߢ������w��J�1Ә��ճ��M��/B6(n{�)�Lu!`J�����ai^Y�I۾	f.�S�&��e�;_���F����\���I��Bm�9wt�2Ųcw��d� �,N4af,5K��P���@��~����}�l�\(Q��+�Ƌ���n2H�G���9�M�;�c���t/�W])�@�%�4M�hx�����г�-G't�,a*��UM4p,>P@:af>�;|&�*PDѩ�A)�)u���C�.�m���Ńh5p�KeX���x������P�0%)��m��'�e�7$�C�BF����7��>;V�ol����+�uy\H����q�1��7H��5@�
=d���lr��I�8Q�
�R�xX�A-��\6��>i �E?��b��_X=۷u]��-\�"���PJ�Hn����s��$m�bB���gR��玝���N�&���q��[�q�wfz5�OGtc;S�� 8E/��i0>���:����ΐ{l��ټ��QkiVA@�H��������ɱ�P��\{2Bi�Z����D3�^K�;��Dj���W�G����C�I�o�C
�>F��6�-ۅ��NH���8IMZ�A��O�4梎��y�c)�Xj���.�<0���T(�5�3����KB:��vB��+�'l�	��k�fi[%��`�M8�\�L���������/���kh�˥I\P/�v��0zO��cT�a�G�B�e��: ��O�`���3�b��D#�e�~��7��)e�eDmnN98<$4x�'~��no���B��o8i3�Os�X�K�y�6�v���L�"em�K��ܝ��X\����٬Oczl(��j�}�)7��u�A����k������OAj�Mg�c��Ŗ�|���qN�~��o�ݧ��t=�Ժ��I
��٬�,w��3�ꦡb���p&��xP���G(UuA��(%�Ʉ�v��J�9n��o�/�B �;����l���{6߮�]���0�Kl�nI��o�9�]O��NL�;���iI7�p�ʣtM$��¢���o݄���ʥ�É9�Q��7LɆ�2����A�¹�$��D%ʑ�c��C�#������.�ڕ;���ax�@��]��k�	i�:E�z_��1�5�rrrZ'WZ� �ȫZtf\����՟Z�0aʲ$�=c�� �H
:��@e��n��X"�H�����E�^7�eփ�;��@'���+����j:�����1�����k�dSU�8�±�~�kkYA�A`en"H����U���j0�~�C�b���Ƒ�X���&΢�?P�h$�$k>FE��%�b�H����ɅkS��ތ	b�ҙ�$�� e�҉�F�X~u�����_�\>�@��T�R��7�?����-�#I�b?!�&��C���v}�f�J�� 0D��t���b	O�{+��e�X~�_٩+�)\	����]�\�ҘW��H�P�6Be�/d�K�>�s�M��#�ryUx�����P�*T�%F����G����#-��gW?i�|�
6o�q����(D����^��ݑ!��%9mg};��`it"ʐ��^.��"�%���&���?�n��D&PF5�A8��Fڦ G�)�N*�&�L��Q��4�����>|2��p�f���m)& =�$��hʖwz�qi��%�ū7�K�N�kٰ��e�j	�W��uK�+)��U�eRh�t��h��\R�v�O�!?��o��8����E�!-��r��R'M�O\��V��sM��X��3�-�WZ��J�A�*�T)�Fȩl���$�Z��R~��Ɠ���R#x{Ku���W�iud�������핋1ȏoO�,��&��"��UAY[F��&_/ҫ5ħC_7��VE�#�@|�W�s��D<������*�"�D\ogE)xp�V��D���k�Ϸk��m�8	b���C�gŨW�T2����e��y�k�9D��(~"����\�TѪ�54�P���jb��bj�����"��*�I��%�w�䗬�viqֵ"<�7�5���{1m�3� .��� �	���za�퐴A�h�q����H�P��d)������|�����<P�h�P�Ղ��$kS]MfdB��6e�|0�������h�C�~���Ƣ�-�$ ���i�o\�ܟ��@� �Or∅ F����J��>�r�P�"�3�7������%#�eƈ�<��k_��pa���7�-2���d�p�9}x���Ր]bX(ɯ`^n^�*窅̟~�������61�ݚ��jG7�wX���]�~��r�����Y&�y7Zs��V��N-�7�S���X�H�'�b��!��c�Uge:����2h�e��(K�����|n��:at~��:�2i���c�j�!X}.X�XL�&�嗝�,itz��̭1�#�f�jC�A]mµ��n�Wi,m���	l �c���5|VЖ@
\�t	�#�?�1��}Z��or�33�-�-[�O��q��	9�ٽxU�U�k���I%�7���/�K	���
&��)u�֫c*o�/,�Q�'�7w3�TY12F�i�eH*kZ&��������?N��͋�Pa��	1�� �d����Ww�lb���r1�`mL�9+�V'�DCwm�L�ZX��$���s&-�d>�����×0&�ut�r���9#�Q�7@n�%�E�,)Ƣ�<��b�!<�?*���Wo��?���_�}y����Cp`*�'���b����tŖ���z�Ċq>J�A�O��1!8����Ar�������Wg>Xf�MW��m�U��-��ͫ��s_nMJ�dF���z;��q�Xu�6�~g�\W�h,9��@��$p2$#�Mu����|���5���o3Rb�'n��WS(j�,�b�������iA_�����f77裰喦-�G�O�ܹuu�TS'���d�ED|���
ٟS���L ���{�s�F�p�Ku�T����@�F�إ7��H�Ő�83�>A�[y
4��v���AS����E�
�=��s������?/y��E�X������N4� �0
�-������ݺ�;�vN��������_�	�,̉�<��A�3�@�J5ݲ�=�Z&Ҫd/YJ�p�����hrE5����6r�F�a��9MA_�e��L��5ts=�H���*���:D��o߀&�#mQ)��q�>�x ��/zyYK�>>�.�l��8r1��h�l�9�p���y��=��5]��mb}4�#�]�msyZ�]�o�v
:�#��	���7��$�2V~�A��ݤ�kM����%N7��߇��~M�Sg�T�H�����[|����X�Q*�ê%@U�n�"�M�ޞ��R�Ωn%;2�m�S<��-
����� �؁5|?�i�s{����l�W�̺I��Ǆ���^��R9�u\̮!aF2�d��p�@�vu;�t��:*<*v�P�W/*�>la˧��&���ՒsǨ���S˃�D���S����z�l; i5���>R��8�(L�?��>&V�J/I����>�h��|��\��w��f�~����d!���0j��͚�?�n;ze��T�d�ʯ�{4��)����fjv�O������s�<�/:ku7+��?�E�Z�UK��L>��&��K���)�k�o��,m�3�� 'θ
)9ޙc8ú@���&r��Eu)I!���:��X1�K��y���݆�8{zaT�pE��6��&z��-�Z"����_� ���1�I�yxE���I��Kz`1��������6{� ���]]��:xA�֖?�.�Qw�E��v?v�ߒV�!�H�N]����ӺKNd5J�ҋC@%��cq�#��Fv���9�3�>�7�.ni��b^���ǝ�B�tS��2��f>ř��|M�%G�
7����b
 1QrD�'\��ٕ{��xȻ�dXX��cfZ��8eӸs�9����t��i	,8�x{�U9�UqkH�{�|����Z���+����aw���B	>�_�	���O�	UFN
lk�T��Iaێ~�+b�Q�e$\�����IqR�;��1����m�<��WJ�볠V�H��!�B�D~\R�(F!�2M�������O�� ��
<M��������}��.�U�ɩ[�C��� ���TL5��?F����H��9��Т��gsƦ1�[G��(�ނye�m���g�>ծ�e���C�#竝��7e����޳u:2re��T���=���H���e����=v��#���?�T�f�o4GH��Љ)se?>X�v�i|�/Rn��5Q�Tk,�x�)����	
T�;��CMK)��p_���z���>��{zL����"��=2��R�T�w�&z`a�zݐ�����Ԛ�m� ,�G��dz�(��in��^n�,˽"4H̨l��ߵ�9%�)�����I[�zI�v����$oK�s�ؿx�5 @�t�cǚ����Pk���bF�w�6'�S�P��Z�S,Rl~?S<�g��'ʍpHԪ�b/[S�@4&�+��F����1�L���?�5'�n/�Ti���Y��D9�8z�zQRr7&�n��	��A�Q�#�{���i��'�鴉�Z��!`�����ɲ 	5f��Q<�B�������浃$��*�����ל:�\��6��բuX�K�u���������qǩ��he��i�yd��~�Z�UJ��>��_U�%y�j'Q�Cc�5�^g�"������[�t�9�2Rm���>�b���I&�L��&�`����[(�ب�^ľ8�\�����2�1�*x֚Y �Uʵ��@J��7�h���%Z���Yz�����>�^w���+L�Χ?`>Y��TJ[�����t��y��9.��Z���N.�+f�
#꾽�ਜw�Ɵ�=�Ԩ�y���
��/�_���Q�455ci,X���~�p����΀O2�R�(�Q0a�^�PC ϙ��pV�3�r��R�G���
m\��
CUx'r���"hQAoP��M&�7���>��zE��.�7��P��?�kĻ� ]S��"a+[��TKy=�.
��K��u܌�.��\/r0N�.Y�
`h�"�Gw�����N"W�    f!�l'[7 ������Y��g�    YZ