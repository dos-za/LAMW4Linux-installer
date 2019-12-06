#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3684676218"
MD5="027d70647aec465c569585093666cb4e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20216"
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
	echo Date of packaging: Fri Dec  6 18:06:46 -03 2019
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
�7zXZ  �ִF !   �X���N�] �}��JF���.���_jg\`�&��͡��jۆ��
7_0ji(�U�/���� ��:��z�,��+��"j�$�!j����$�\W���ng�����.V���� މ�.U
��SybG�>�������efU��A��Vz�d�	���.8�Q?�`��Z?v^���T �,Ý�I$A	�Jݲ3�P�K�ߘ����b��u~7���Y��PX�$2,=�@(*��2�4�W����G_�`.-L�-�1<w�Z��[������Œ�-F��E�rӣ5���gC�|�Bbl�҆�a�$KX�%"q��T�or�W����9��̵ fs�>Eʱ�w��x�B+�� Zkg����E��h���͟i�rw
N��|qf�d�=�|�f[["�]��v ��F-�̠�����w[�xaJcW�v����!�*�����8v�[X?P>V#�S~/�pT��*��"����2�#���3�2�c��]ݾNtkFI���^�Q�}�"j4�h��@]���gf:ܿ���J7��{g�L��s��-0��k��d��1��Z�>>�ڥ��GC���ǂ��X�U6�Mv��H���^�����,����~�$c���p;��:\�SC��8];
Ht3i�1gY�ذ�H�8K�r��h�L��o��ʹ�f�� �}�Ti����XO�
�>u�/���ՠ��#�B�(���+ܲ �5M���"_��+�Z���A�z���^�:FL)��-��x���3i��ǟ#ኗ�3u�(�7}��i>����.����G*@����/�,�`�ʙ)�Pom�/̂��Ҩ�?��r��)���}�[����;�5T��e^��t�y�G�;Ɓ�\�2�!�Y���rx�~:�6�-G�V�?StF\�L��;qܿ�PB�j��:CZ���J�@�" ���UE��+U������C����TkZ͟%,x�M�@���G�A�;N/��;lx�+D���<c���XY�X|z����0��+�p��yBj�.�����u��4	����k���H��f]r P�Iڒ菄�oZ��g����q1B����I�S"��?c��a�hZ=�Q�5��S�_T��B��[x) �Y��Q)x�tjY�Wʑ��#����yRv�BQ�m��=#Jk�� ��=я�_畾�HÍ����\�(�&��R�M:�;�Y�^�v���{-E�@E�m�h�)��mx�s���i�������:��?�80��^:�\n�[E�/��8��,�1��wc����x�Ko��K���ie�qi�;˺�kxC�������'04#��W����R��%�a*���f3(��es�
�}�%7l~�f��f5X9nT��țQ)�����K�͓����j���6F���ff��E<����'�s���_OHm�2k9�2

�8yi��0�$C!��'�n]%�A�K��q�;v�e��q�[�.A�RJa�y�p�{.��L�F�u�^Ɲ�H�/�P85(8�����
 �.�����3.��ɭ��{L(A|�цē^<9U �ٓu�@�����9��k�Ҕ�����3���~N|_W[,�5?��L  q���x6M�����Y\S��&lSyWHgR�:��0��� q}��e��0۠���ʦ	
oV�$�,(�������s`2ܑ�8ʉ�$��)���"���`�g, ŲY>_��U�q��2�V5�4y
C5~���+$/���_pF��J�k:�tm�2>�f��T^Q~f�=�q֖�G˸J�>��nV��#��̡R1u����V�0��H���./���k؉�w?�l1,��������:٠��6�W��.#!a_n���Z���ܷ9^:�! Õ�|e-؟hC0��:�A��9Jm�9	e=2+�tja��a��BdD�Q3?m�Q���ڶ�F\\���|�o�&]��� Vw�x$�ke�=/���E�F�����C�Qy
qɂ��~#I��	ɳ�K�"���V7k��<� �P���_ qc�~݊�y�N�
>��%��2�0k���m�Z�F�a!�0	!h�v�ش0ģ��#�)�S:ީ�A�0o�,(2>��|��������b�Q-��(�9F�����I��s�}�D�	�4�7��i����340*�=Y:�$�0)�$��y��ɲ@�
 h;���?ы�4��\��w�[ݲH���(���aN<�goMcn��A�e{�h��|�+�s!s?�V���C&���+<����u��E��j�Αq=oL�ׁ6�iV�Ηx[&�:��e<��>D�|1[D�F����n�`�	;p��)�mH]L��"��"�.�������
&��~�_G����id�­U���L���n�i�T�Z:e��y-N�4P���XF���M��Aa �x [��W'j���ɺ�����\��eW��T���-x�T܈�r��Eqj�a	��ܳ����4�ɇ!����RcJG(� �����M��6Cx�Ƿ�@�_;'�\0ا;��˸z8��2G���9ͷ��N�p!�5���&���`X��n�：#�A�"�/0G�8��ʖr��>�(T ��ח�5���cֳ����c-���b9��چ$�q~>�}���Ĥ�.~�Ҵ� ��ك���E{�(s'��e�%�'��d��l���Fn\�r���&��t��l����|*��Z�q��~*hU�v�P���J+����%0���G>��N�R�1?C-��s!���kkw���E���!E ��HL�6��1�Yjл���W�{� `�(+��Q0��i�R����ey��KXg�������O�!�ȅ���5�� M����a긜Sw�j���]v��ɺ_y߮���=0\տ�i�
l~;�Ơvr����Vt��!�������1����HH�Qn��G�%|{f�/	�t�**S��mf�������a3ؼpN�i׆fy��rV@���$���g����gzZ̕�,��`>��24�!�Y�1�=�v�c F�6�H9c����!E�J�B��A��� +*�y<.��C
y++|1�hr믶��.)|�$����у��d^�5Mo�!�3�'�9��z?}�D;g�fxJ򥬨ǙND_�0A��-���Gl"�jj�g�h��Y�����Vrt����ل#�x���T�5F@+z��lZ\O���CfS|�yY���[�Y=�(�����3͉��o֌����?�&}�X\s�vA#c9�4��{L<����/O[c4�����y�08T����uS�^`���-�<�Q��#O�p�3>Y;T`�Z�n�:�Bc�Ä�6��S.h_J�Uu�M�����FX\����e��\^�rm! TbW!�Q�8O�o�Ǿ0k��c	4�e�I�A��+]�$l_�c�Vˎ>T�x|5�������i|�eh��(y�ǎ���JZ��N�泵���q�dLbL�[�b_"�r3Z����V��#����rr��wIpW7���g���r�N?Ѯj���%�J]z��%��
1I��_���ԏ��.��:��ù?�����aY�a�{�j�I�����-�HE��#�n�I�W7�P�<���CD ��NB3߃� S~w���-D૊n�$A��*��������l
ݮ���Hr�b�G�����W�����\A�r����ߍ�}��ETK��YXA��Ep=X0`Y�ǣ�wi{$ge�!G��@�pz�b�s 9+l�On�|�����K����طbp��j�H�n�jE��D��w<L���ޱZk���ᑽ+��AB��H��E1&�a���B�����ߘ��D�I"T}�׀��<����O�zdHϸ�g^�țå��	ya��%���ѡO1uY������=� �����d��4�F��}�����/�2�+,]��L76�3@�E�|b�a�\M�5
���q�^�4$,l7fX-���T���!�;/�-��&x��4�����/x�/Q���r��=�':��n��T��q�rcxK{�lf�\�py6��'��J�7@uv�.�+|+u$F��J�[R<��%��$Q���c��p�ףM�|�Q�e�'��e�0�~ v�6]Yh�q7Ȱ����&���q2 �  ��T�t�f+�..�wѬHPd	��̓꼭�'��ή�\��������2��t��",5`HXRm�Z�=��^ ��ޣ9��	��D�d�x"���P��e�?�/�#͢�e��O�TP¥�Q6n
:�	]�x�#1���R�v�Y��w\?�(���ӛ����L��:��quț1��u�X����Ҩ���r}�U��fys�lqCI�II-F��YB�w��el����=�2;�ׂw�z���b��h��U�7\�o�b�E�H{�`�ٮ�={�y7�������$|@/Ѫi��p�=�2���`Y���YR�6�z�m���p��3@k�U���P�NF�4��#�..6����ѓvo��C��
����.~ V8�I��}$��2Da#��2�`��CF+K*��{�z�8]m��3M� p����f����G�sj���Q86���a�Ɉ����z�N8�(�G�c�#�Q��쉥�+@H�����0�ܹ�%��wn�ڎ��l� ��{��q��~�d+X7ͯo4�V��W�e�G�;���Zq�y�����3z�-'���dm2��:�C��IB�I�6k������؇�K�b wg��?P!0+M��]�b��Q*(�ƫ����!׭>��Q�@�鍀�����}Rg���y�$R�A���sz���,�ϼ?B�1�?$��V�:���)�z�Н]T�TJ6���0�f��^=���6��(.�{V���	���Y�������ogN��b�#@!x�䣂JV�U��{��+��l���DB���p����ܪD�}�u �����'4Ѯ��[��K��������k�8[I���M^��@��[�q��a�X�p��%̏����N?Qyx>�o�������yr��Js��i\�.歒��ݱ�8�zg�~�Fē���C�wT$6ҽ���߭�J�Wو(SoMN�P��kPGo�k��f-�Ȭm��rX�UN����O!�`��~x��q���-�Ty[g���z��j ,�=�
vk��H�+�ji ��T*4��S r���K�B[��,8�B��͘_d�4۷���r,�Bv�����s]����.Q�W���wc�A��3Q�+-U�Vw�<)�F�<�����E�ܮąʅqEC���_ѡ6	�� ��m.�JtY80Ӏ�qٯ�H9**�e�.�奶��m��Խ�^"����WG��g�W�Hq:�� ��î���xϵ���Igrq�e���D5z,��%
dj�D���C����B�
���7�~uZ���-���	�P����-��ǧ����]`a�|�ÃaH���{���o|c	V�������9ȼ.�2i�� �����Z͝����.!��J��=|�/1x��PV�<I�1냇��\ⓓSn�K'��C�2?Q���͢�����\7��Ā�.���WK��K�Ӧ�>�λT�H]��N5D#{T�`�M�l0�bl�?ܟp1q!dq�Y�t$�(�+$����>L+@���/�@ ĵc������7P��'�Sls��*}�v�#$y��Sy���2l>ڵM���}IM*��JJP�X��WՁ&*��4+�'�������9
}�^��þ�+�?��c��EKP_qY^�c���#�w�P���qI0ˢX�P�֍g=2��7n���J.� (����%���-�R�:�o*>~�\�-l{z*SHh/ T�Nb��.Q�X����Z�;��^:�_H�b)+��W\�#u����_a�����E�-l]��9��V,.L��N;�(d�E�/|,s��c�9��``pBuq`�%���,�
����1���9���,����qSf�c*�-���~҆_������A$���:�gdR��m;�p�y"���<r�@U6����g#Zmyd�@�y������g`� Fp~O�Yg�J����kY�Y�F3ȴދ�j�p���1jzNXqs"c��^�aHg+[�� �o��:.cKnUV��A��A�!���-�a�+��a����{]rPS��hWv�nRl6~4"�>rt�������w�ڧ?#W��V��s��ʉf3�Z���϶!������r�9@�~��HE�K�gfS�Rp@p�Eke�ޟ�Frl����?���|uJ��)�a�$0Q| �_vj���Y�Lf$�
&T���7,VӖ4����劒P�H��U��2��v9e��{�G.��91��f$y�'2d,���ny�RͶ��cM�Q�E홈���-{5�?.2�v�q?��g�<���-�{���<:1�9�,�Dn"c�38&cr��iΐȈ��7�p��&��^��(标�	Å��o��,M��I��q(�d��VU}餧�. ���<��6��M��K��� ������Y�X�������Aѱ���7�n�~ Z�u	��v���*D�ȸ� ��tv~ �����
݂���� H���&ր�W���_�Z�}7�GlT��������St򫈊#���fT�����W��p[�$��U;��ݠ]�z��� ὥr�.IJ�`Nh��N���J�w@��4���ϙ=ҥ9X��> �ʺ��HH�c,���`_�CU�?;.���� k�����4�?
CP�{љ"��v��=��?��� ��{�I�Os�mXEqK�&Zmh���I�ħ�yG7���)o.��G���c�;�\��M=s�Y�7��3V�'�=�Ҩ�n!B�>�]�dkOh������g`�ߵ�Q<"tĈZR�2���i���/���������$Gɠť�j���"�{�Nj-r�N$dw"���Ӈu��o|	HPd��L!^�m�`xDϋÌ�V�v*7�zV�<S���\c�}�#��4w"���D��5k�p5�9�oz�=NFvP :��y�P�P|�h|L$�	d���)�~�K5�z���3?/�O�+7�r8#���#3p	Zv�����,%��e̠�x<����$�
 ]�X�n(�����Xk�� �R�~*SE�8��.dy�^y�X쭡z��X��-����7�e�{_�>�� ܳ�|�B`�⛱�|�{3о��C�Fcƥ�l�h����X*6��k���r9dPWO���ADZ�K��G>K��I�t�����>�����]��/��o�Dq2������6���q�rs�l��,N�?�5�tǉ"���[O�E}�*Ne�}��`@�yؑ�N�K�y��Eht�z�)\X%�/�Z~8�;Ą���7���"e.��-P���w��7��o���p���g�=HQ˦�N��/�:boU��E.�WR/x���/�x�mX�16�\Cjkd��vq�>���*�z����<����k]'���C��A[.�ZD�숬��?���[����i�uu�TӴ����)�ɃЌ6{Hy(}PĈ�l>4f���(��y,Bj@$��G��B��|�o��~�rL�>Ψ�a9�&�srfU�ӮX���s"��EɗIN}jh6����4���ݒP#-�'�jH!�Tt_'��)H��[��t'���[5H����`X��1����@6�i/
y��ћ��r_��I�i���`���~�*Ԋ��	\o&�)�沭S<���u �[ep��lT���JQ[m¹9���.Ye|�m/$���NJ��y{���v���wL��n5���eW�X[ʼbG����ZV)5D0���{���f���5qXx�d��5���z)���.TV��dL���ړ�~��������t��IO��y��I^�2X1n�6:'�8<a��\@&}/%E�n.g>��V�� �����G'4�G�	 =��x��)�h�n�=�x�g���&Z�k3U6�ؾ���$�@�w���N��,{Q�9��W����p2kA�t��h�(0r\W�y��|Ԃ�z��%����P�U=KNoᑙ�Wi�d�S�k?���
b�j͒�%�,tǏP ���1	'V"�p���7��r��I��e�ʮ��4�
�,{��+��yQr�h��2قR�"�Ne�ϛ<����z�q��ɍi��<��G'�|-ͤ�7�L�FB�S��V�7���oA�F�>r�d�p#wRb�1"�J�K1ƛ.� -����ĉ%b>��gW��
-���u�������r�I
)���τ��hRH�g-��k�[�W���_Ե�45j�Do0���C%�o3<��'���ݪ���^��7V)*������B�	��t�Ƞ���5���=�n�7%Ƌ�
d*�ѧ�Z��th�[-����(�0OS��% 	�)��J~�9��%
�-ə�=��&��YK��v��x������mgb��ٻ*{&m}m�/'A��	Ã��F�,矖��6:����Yo�BL�t�=`i���O�XJ_5�t��DQ�s��W��6V�U�����F�/z�{?<�.ɮ�,$�}�3bC��y��/S�ϵc�kre�@��<�d�rH�Ƽh/�>������;�ږ�R���*��������#M�d�y2�K����ƻ��&GqY�,P�5+�h���<�}�6H,�8$�
z�}5;(����4|Ŷ���#����S�S�;	�ǩS?��D�x:�<��>i���S	�m�Iൖ@�ֳ��gh\���	�s�r�\<����Z��pc/���^���i�2�P��9F�ї�-�#$8��#�	y5�16���͙pq�c�&��1[�Ţh����o��s�ԅ�����ג59zO�OGz�yy��p����iͮ�z`�
��o���Y~�ƭ�z��|��n5@�]9����h�_@K� vh�Mr�_�搿Ǻ:��� #ҧ�����9��	���T;z���,����}3�=�yJ]�������'`�ܠ+���>�a.�z��ڡ���`ɬ��le
J/z�b$2N��t�d^:P6�g楎��?������n����Nt�sI�P�kq����Bdw_�&�xW��20�Y��g�`M�t���ݣ 8��.����d��]��&�_�&Zƙs�
��=�c�w*�D�Ω���	D��e�Pʱv��볏�V*>�.���z(5���q�Q�w�����j��@���R�v�Ь^��<�����Ő$�5��|�d���@Uf�2��X�/"�5��ЧDD�#S��[�l<,�T�{��FG��A������ԩ~#V�?j7�<�˽�}:
m ⨯��݅*U���|ߓ9_1&ȫÌ�`����5��K�9��Y��K���Z�7��`�_>��tB[��X����;����wA�*�,Ԝ�.��ެ�b��V�#&)��昤}PgMɨ��Zn���[nk��sCU�р�Y1J�QR���V;�OÀq�ef��s�i(���o�7 ���'�����Z�L`2�t~��������'���_�j����p�[{A�� S&/dB����0؊���v��9��B�X��1v����z�Fm����doIY�[L�~e$	��ȏ�8�72v�F�ݫ�7 ;�/��E0��H�la���cI펟��!y�J�w�_EfM�T��a{���ּOE�$P����6���w�WN��B�擔�I�~?����I&�Ȝ�Ak��ڌq�>��q����G�2=m��Y�L���%��R?�U;���Di�K�GF�&��{ܠ�l���?�8�o�m�(��M����y������n����X''έ�����3p�N�8���-��'��}�T��u5
Osh~��$��%E���	96g�Dɂ�@T�7D:G �uI\�_l�F^����RE��F�1j`����ā�ڎ �^_�n5鐞1�c@�Z����I
kF�S�rS�:p�I�R3�^~��=��Y>�y�)�bET���IF�|���@Tӣ���s����_��>�5��-���5���$�5e�O�l�э�wW�xN"A0��W��y�cݒ�UV�-��ҊE=p�F�2����o+���Y�ȴ��Y*0���VnNݸq
'��1��W3�Dٻr����v�bq����[��t^{<��������ށ�iVΏ��û{FQ�~F��+T��	��q�S#`����2��/�������FS7�@�=oD�ܴ�q&3�5l���62-�I�.�G��k[��L�+j'��˵�5Y�A�̲]��Y��B�"~�o�$^��n,T��\-���}����;�QX멞�Y�L�kz�@7�`���$��=)�Ӆ{�X]'� K���i�#+G���e��˗5v�a��+8����{(�z���U�T��lב�8?��9��w�=�%ݔe��4d����[�E�Ɋ`�v�:1]�c�TM�������U�>��O�/��b����4�\��:d$�����M��B�p��%�hS|�Zހ{� �{���p7"������L�_���r�"a��2-a�ʌ/�� ��}%^I�% q�)��Q�+i�N��Cy�����Q헱�i�C}R�/:��o˶W����|Za���{�F|1�F!�Mথ��ae�=��?���/m�8.��>�����ܵJ�x	��i�HgIa7O�q�t�HS�#P���u>zq�~����E��
eEW����^6�����6�Vom�ڋ��c+��L�� 	�;&�� w���G�H�0��Q��^܄�at��D�.f>e���n��@�8{�ŏ��{�T��j%�|
��������s��gB���ۃ�����ݬ���}��e�P��m�3h�ڳ��v� �`�(���O^ҋ�����r!�{�φ�OeA���ޔD�t91YC�l�g����J��"$��p�I"��H�#<��j�-��!��O�����
If�y�\�I;�7%�w)�Y����}i����r? sLқ�ܵŰ���r�ԯ�H��CA(�'bN���c��?�Fޢ7�Wo�M1F�̞km�i�i>t�'���\��q%�����5Z�T#G]'����`D��7��5�l9�#�ݼ��;g�Q��;��{���ʋ�2@�)��B%L1�OF���k�Af���ٸ����N@<���GA�p�Aj2����Y$�Q� de=)&��RH�Jt	�u�*�A�C��M�+�5�ـ�P�؅��ͩ<�3���$;e���GeS�:��J��L�����S�-^)鿪kF*l�s���l��t���֍ɏ�M��E�/�B� �k�\�w�##�B%���E�i��-���m��4��J��@��fї��L25N#+Uة��9i�ϊ��D�F�F��m�dW�L���{��j���#���������a������r"�ch7 ob���xX��q���9�+�0�:�W�:WV0�]�n�c!�m8$g�ג,=M�gЫ�@J$�	c]AF7���ޙI�'�Z�@��W>p��m5.�w� +��)�f��EP���]�BԠaaGڬTJ:�2�	ǀ]�W�/�b���*�g�UH�vV�1�[�'_��	ܫW�o~65��؅��r`�G>y\��ڦ�}>c�Y Pow��B����,lp��f��Z��&b��
��w`JH+��T1/�$Q�B=��!=*��N[�!9��jH��
�'wn�a�j��!�bz�QC~��^oP=�@>��L8a�h!��W}�&�2�	�ǧM���e5�^."cg��뢼�c�Gl>q��+H�87	���wa����C�o�;����^�ڍ~���┷��P��Y	�0�y�Ӡ���nX.G��>�6r�铲е�YTX$`�;�V������(�jJ�چ(ذ��$X,d� ���-m�j|�"���"��V��*�hp���,��fb�l��T��M]E�>��CE�^Tb���T���� L�������[K<?��x��`��,��B�Ĉ4[T��S�A*De5��:_`f�,�gm���-L+�P�m��A'�|�a��]�\����N���Ä�e�;CH�.e�@���c����+#7��P�9�l7���&�3��SKW)I���x��!Z,:o�
>��/\�`��9�a�r"?s{Πݾ<��9f@����b)��
@B�)|w���z?��|`�Z(�-z_��֝|T�oYI}�?�f6��FX���4'0Һ�(o��b0�L�ʹs%m_x:�1�F�#��P�n=�#�t����3��P7	��l��dn�����,:#f��"	�%�_�h�
�wF/�^�?/]b�w���){@\7K�C���9����j�x����׭$V5�l��X$߰c=�qc�7�!k�*���[�ǩA�rD�3�%�n/u�Wx�Hi������l(���Y���y,�eN����B�B���	W��-Y����vu������]��]>8>q8&����ȶ�B��O��c�4њ�� D�"��_��`�g�O2Tڶ%V�o�B��3.��d�3XޠS8�/�3���طJßo�i��	�P��}��m��
��v}Æ	�΋�X������p�/s"r?��ۅ*s@�r��loHq�F��Y&y䑇�F�1���'����^�p7�i�v����ӡX�"�DV����Cr�.b�q��y!�R�J�R��������f
���{��~޾���[��JK��Z�]�I��kg{����k����΋�����~V��=6�JF+oET��,[5���>������i�Ǐ-	�@BF��v'j����V���P��-����J��s���!���"[݄�aN��L�Vc�`E&?�E�/��Dk�,�~H؛����:<����ġ���#0��s8��3'�M�mM�TBP�������y�����A��\IϽ��'�ҞP��X�a��[��W���F��� ��j՗'���1�4�1H��A@��%R�AI�i��qRe���8��L����-�����{ �iJ+|�7�\�k���aח,�;i�A�>T�Z�?�����@P�
'�uT�sŵ�^>0�O�}o��)��[�8����"��dJ��T�5��6��%��M=�;���/�,rWHϔg���Ud�	]B#@yb���p�c��\=BA�n	��+w�� �>1X���R(�o/fe�>v���2�kd���Tx���!<!)[�Xb&P'w0n�zD�������Ò��qg��@gmB��aG��I�"(I�F��,	)oy�7�%bJ�����;p�����V�X־J(u"����&�g$�Ԝ�b�[��� �\V����}8��ݜG>�j�����'�ؚ�U͙u�������'��|�a���:*mJÎ���E��d���H�pR��Ta��bv���s>2�����jiI�A5-��/��K`�mȁ�����u�v��^Y�f��ͪ�*7բ��@�N�݌l��@SDE�A�������By�MN ���{of���/T����A	Sbm�swKy�",><|p�7|B%�_�_`���/� �J+�	��&�R�� POJ$d�mb
���y����0b��p��S��+��V���B.��Ĵ�����(�8ST&ǟ� ��$'���a���[����@�*5)āvK�!�<��(��b�'_j?!f��JFP�1p��C6�v�0<5��2hܡ�/�zHIXά��a1�ox���'kZ_���t��lB�kmS���cUjRM'o<&*y-�uFP�ޜ�YIr&������D=~MY�9�hɻ�L+��$)	��)>�����ts�1���6���k��)n�SO�(:u�2+����3��9�풌��Wչ�A�a�_;��nV'�A��B����?G�4WX���U{��߲
;�?|���$������&Xr��_�����\��?0"V�ix�I>?9
H4�����v���k��L!��9��`I��#7�% �D�	�p^���R\|6���[�!{)����Ap}��`m�Ys�^e	�P_��*ވg��wn����'�쓑[�0�J����Of��NO���C��ZD
[X)�m��0��X:�t�����|���p�c� �F�Y<a��Wo�|���#.�)X$;��y�r~��ͥ B�J �Bhݑa��e�d�M�d{���z��O�~J�R�"{�#E)�~��d�[�o�AM�H,*d4�f�&L�]�����WY/�M;��P6�S�ooK�jf���I�vS���*�e�-d��y:���!.kQ�=E1�g��t���w� �:J]��q�h_.�%rb��)�B�%�~�� ��JȭQV�1DVl�X�ꔵݓIըR����q����G��~�EJ]��&i"#YQ��Zɺ�;�F��!�̠U�`��hv۾��K�� wˬ��<�a����K�yŷ�&zEI�엑q	:4:�2o���zФߝ��T�߯Մ� -���,��#/�]8�nHp��(G���=h$@�o���0�N"Ҵ��)�G�z[L������2₽����9��3[�y�ha�Y'\a����@��!N>)1���$��週4��7��#��}��tA�-CɸF��U�@�i>֯��z���n�*�4}�r��mCG����WP1��}j�S>&�D�G����mΰ/�H���o�Y]K���i��6�6	��C�1���'
��G���5mmB�c˛E�;�1��I�����:�����̿6�.H�1���^������HǬ�<KꟉ,]�18��DCM����(
�v�ٽ��]�r�O�/vL�a	
[���0�3��Y�j��G��?���Q>f�Ƀ<��T�~��V"s��V�Jyj"ך�34���u�c
]v��$	@I�E�,���?'|�]�60�Y܉~H���K�i8a.���O�g��Ba-�PV����B�2	�6�#��p��HC�&{�?Ț�Bն��:V~47�hw��>��Be� �Y��f(B�&�AsV(�6����n�rw�L��V2tMA��ei�~�az䠍bԋ �H�#�kʲ�A��G) �=�!gQ�gZ�囪\O�+�_�E_;k���B��h뿂9WN�G}8��aF�-!�{zLf������r��8�H�H��ʃ5a��:�6JP� �h��p$T��J��L�3ȯHLe���������1��ՐD�a[�,��V��r�i�@jZ~��� ����/����Q�Lݏm���;�#��N�DYT��< 8�[�	��#�NQ��L���vN���욌�,����Qf*� N�Ay���A������WB��.bqd�߮:`%�@���+�py4�a*�.�	E�O�	@0��U�Oʰ��Zȋn��F��V}�*���T�/��:�a��}'��^h�=|Y.��J	T��+#�UH�ڭ�S�X�B�L��hS����eT��Lޅ=X�� ]0��+Aa@�[��>�������֭3�6)���N3�sA�HBя$C�S[���>����>>��x'�G����@	�Eڡ{�USq��om��a���T�"�J  �.��oP����Km����R�!��N���n�z��Lp�V��	m.mk��G~���z �N^\2*c����&.C�(�����x����ɥnd3�t�#��K�e�T�#�g�����&	��Q�t�D�/���&&�z^����/��l�PS?ݪ� �7�%��rϟPd�-SƂnM�!Θ�hl��c2�|�f�AM�D�6�h�݊ >6�����r���r�B!�����2)	�ȃϋ��P?�'�����F�Qq؉j(i��'��?�bX�
G�Ä31kH@˭[�(~��;	=��-������r7�Y��q�mܪ��d*ӜL~�l�7��e2?7�N�8-~�i��+�4�X���c��dWN�����~�D33��8)�K�9�Tu���"/�)��
�<�[z�p��H%�D�<�l��Xv\㷡�p�W2��\�L켜H=$��W�ߟ��#�� I,M/;j3�a�����qn�|I:��I#X������M�N��}E-g���;d�d�^�V�~ç
���e���_\��d���k�0!��b���@�<�W���G��l����U���b*�A���#�nb�i$l3�4����f�����3���nv�<�uo�.��K~�Zh�'m��:~�/u�Nh���i|}�Zpa�֐d��b
˘X�~�1b�*��[�n��t�a�G�	� kU]t���lܿ5v����]x���Ç5N<Y�~s��O ����}�,EV?Ή����7�I�f��j����l	cS�O_�.~�Pł����o�JJA>cB�@�#r!�Ѿ(��w9{	�^�.�qꬸ�B����t;�����Jȷ�i������[v���`\����{���Cđ_-Y�0��擦����><����Q�`��j�*m�O��
2,4���}��"D��xe��<X)�5�zg���0vR��l�uK����'5}ո.��ڈ�H)_��KjO>�[L�89S��$�^�Ű�ʨ�b@T8��,�Ɵ�"�{ĉj}*�N���4>\ד�A�T.3���iڎv�Z9���1�g<��l�}Qy�)��:��,r��83Z�鳑�Q��V��j�3:V��7���Z|�T�X�2e���G�,�4&f̆�a#��>����=���H(L���C�ޚ���,�#��޳&�4Ś� sF��6����th�?I��)��2-�/0�s�Z;��B�l��;wlS1�]�r�	�Y�L�V�D��d��.ѹ����a/����:Q�!�>d �-���,&���W60O��g�v����|Mfxo����i�����	�/w�h�9!�
�Z,����@�5�y����<�]{��b��즱�v�iKiaa�����:F���>���ATNq�m�����:��*�k�!��k��Ż9��|(����Zo��G�fӚ�v���'x�|=�Xa��+���X���Ex���Pnq����&��� k���ao�����g��!7��FZ�[�
���X��Ƨu,:�f���t3�4��3YS�wtܴTq|����Ao�i��uX�vD��.>TS!goEO���,�\Z�=f\��g̽8�Iۿ����U��c�e�z��ߦD~�����WC�}���&.�[�{�mI#Ӎ�I삣���8�T/��ѡ��=~���!A�R$�ù9��O�Ө�p3wڸ,X´$��p}�V�v�51Ḽ-��*���o*1�M{=�ީ\�'��IO	���x�ٷ>ֵp�kwA����#���J���Ri��A �~fl�o(;�dŰV��iò:�ۥ��`s�l��a?����ڋL�4�A�H@U�BI%ŀ/���A�(���L�&� ��u#�;�+����D	�{+���I�񫄈A���iv|YhÏ��.�N?�BȲH�q �y���Rh�א���?����	ɜ\����Ч	�g8 p�����q5n�9Yr>-���^]Q�
��j���(�����
?��oS�,�&�v�妛���a �O�G�d~����{�['���s�/��M���*��������V�/$��;�Lp�>��r�=.i?mՑ�YHQu��
��k#	$-b)�b�J'Wh�[-ǐ�E/�aag�`���Zg������	�2���:ۛePَ�JN�,)�����eW��q`b�+$��˞¤���3�t0D� �J:J�����FOB6,��(h
[��n��B���;?����Z����S.Yoq��#];˯ˇ�)j~sI�l1%�Q�[[8Rr�H�s����v��䕣d����=p�������(IC���3��\&���d+͑��o=2�H-��@TOk�ɟ4׾�����k�)r<pl��Z���e3Y�Sd�<���>�!S��9�z�F7��`)��d�t�ZQ���@U�|c��n�S���~�Ӟh���T}.l�K�o���mw(v�3�c����&/�:��� I珱$=���2�`65ك|��[�H�-�Y��8 �m�l<d�訩Opg�y�[-Q��V
53	��O�N�_i٨��W�G��>�\��k@'�����Yi���m�XR"���7v��2|<I�L����0��=� ���]�1�@��u?4i�Z鰷�I�����)���k���՚(c~(���$�,<��d�|�������?~%R��^��e5w���K��@����z|b��{wDy6�%W�����p�t��\��V����9��BA(�<��lALr�x��+}ih�of�I��.bt��*F�&D"A��}iYa�s9�W�Y���׷�G�i�]�|F´��W�W��rȮE�)��p⁎QW�#�-j�U$e��W����E�2Jq��5�J�@�t"FE���ݱ��x�=g�(�[�������*8rl��{�7l�L�����_��^���7))��Hg��ݽ#�Č�O*���Q=�ɘ}�;S[<jW��i��"��"x*pG�6�li�F����f�W����ﺥ�M�f����gq��$E���jW/�Hy�$h����|3�)�7��<�j���9�N|��7�b%�G*g��1��h0p�� ��:�B����ci�UBW0�S�0'#�=���6���!E���kL~$6�9Wt|3̓?5>���2}	�sTBԎ;�@f1��l����K��������R҈Ǻ}���s��s^�X&e�<ǁ���.�<��֣쿽��-]c'���������3��z�Cpfƶ3ߺ�9rR�n(M�>�o�9T]2RhlE�_*�t@.�ZK#��i���d#q�Z(YA(<��.�>�f�^�|=H	��-����Di����u�f闻�0:�����^�'Y�1ds�A|cR��R*��q���5y	�,>�b�z�r�V��+�T��[AZ�-�_��%z�f�����h�pR�`�UfĖIG��ȼ&k���C�jrڜ��I4�%��P^���\ݪP�������?��(c�Jqa��i�"T�~3������1�ﭰ�yS����[�!`��c�@h�2,����G?������ɓ�3�YG����e!����IS��{43�V��\B%~B8��'B�VB�lP��_�}Ĳl`�?�j����~ r��[u��6d)?%X�����'��j�*�s�ʶgߤ)���o&*7Ja�Ee���"B�IZH�R��-0��%kM%��廡ր���o����]�{�lL�j	��A 9��n˳֎����!wRs{"�|ۄ�Hp|9$�a�H��v.�G ��e�d����u��q?7���V+��$�Ԃr&�������=7��&00���bS��6�#�q��^6S�0N�ڣ/��j�a%v�[-���⇝;[$p�:��
c3��Me���=�=m��mI<_��XDl���Wj|�����<���k�yri�NCM�P�Ϛ�=�(��ۭ�&����r4��e/s%q����V�%�Qd��=o5C���c'4��x�Z)�&S�2��ቯ���P>&ڞF[��T6	_s�\�.���>7�"ߞ��'B"*d�Z�<�@�	�uzfO����H@j�C��_�%�R{Qn�E���؆dY�TT�@���J�!e��E���43 5N���iY�th�ڇ������C�H;���׿Z&}f�Ǡ��ߝ�o5��eӱ���C�-��%���cet�r�� ',,�=K���4,�N�Ve�     �tfv|� ѝ��ϝL-��g�    YZ