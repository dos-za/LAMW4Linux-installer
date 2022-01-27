#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="753068703"
MD5="8b7844fb40489e7aecc620084585990a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26016"
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
	echo Date of packaging: Thu Jan 27 17:08:09 -03 2022
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
�7zXZ  �ִF !   �X���e_] �}��1Dd]����P�t�F�	/Mu�%_��T�]���ReS���$���:��FHѫ�6bM|C�@�����JZ����n��X�s�o'��,�����Q��H��#|���˅�Z5l{��ŗ؏�����|�#2�oS�>��J$A�S����c�߇�U��R�%��ƆEW���S��xU���xk?#�Ѧ�R�v�Ü#KoB6l6�<�5V�4���X��{ކ(��trB5�y�3%y�$�;�7��oFo��ᴩ/��kކ�*�ȩ��t�֟���V���s�]��:���k2���9���J�=�\�=J��,�!��WPzcAԚ��
rT��Vm P��VLW�]x��ׯoy�9�>a��fk�F��&�� �%����VB~vL`�ԯ6�7Ti]�Ƨ/H��?֊���j���ட�H�υ���(�	~�Qxc��Y�(��B\�^`�}1���c�����s��j���cb#[k����	�{�iV��%�lv��q*���4�x�.�v�����w�b�_�B`�V���g��8.p�'F޽�D�t����O|\����΂��=���#�/��]�� ��x:�Dc�D�O��Mo�4�o�+��
���4����#��t�v��qEש.�$�A�P��` �K4:�H��ud�0�f1��4�Ĳ��H���f?�Қ�c����uX�Pٕ���S׀�.fl�(��%� DGNq-T85z�ì_�,�dcΥ�S�,ku�ɡ�>�woȓr�n4��|(���v����V�E��'Up�β�����}ᡐ����e���`��2���L���w���<U�'����=���f�����Q#�':�z�6�锢&��|B�Hs��޺#��A���+�����d�nm��x��")�]�ƽD���L&�6��)|(��/��{ɧ-�i�=��百`+��2�1��Ӵ!�Y,0�wR}1,��ܖx3#2JT��e7*��=o�ۡ`c-�y#�m9�l��5���<���o:�[��O�-?uʾ�۴ ��.�Y9:��ֶ
{;�[��ߢ��+���[�(�����}�+�t�(��,��s�1R��-��П(�U6�a3�a�e���������J�Q�ߺk��'T]z�F��������0��i�Jg�زzh�:|Y�b�(����e�������z��,��a�6��u��������,������4s�}��� ��RI�>߇mRT�h ��M�ڃ�#Y{�Z�k�����j(I���^�V�����SwU�ᆚH�aj�[O�`R��<� �nµʧ���k�4��nw�Ap�K�i3$���7x�;�r�@/�E�����F6��+U�TO�/�X����+$~���b�z�K��#rR�����M\�R�X�����'�eQ
�x��̻�).�L�`�}.CRi�����o�a��$�� ��g�_���`S�[�}�$n�-����k���4�~�]���H!.��zɳ� S��O�b��m}�1�V�W𧹖,�t���j���ȕ����\,6��O�_,�p��'H���w�A��������J���I)ܴ�m�JmrU'|^1Z�m
XU����qY��q�p�V$�ܪ��y�fK�Mn`v t��K��m�yQ�d�	�0%\W��Kn�/J���b���Q9���
`����/~,O~�v8�Y�����T�i�A����`�!�������,)sA���+	�6�q��!� ������X�WI ��ۑ?��V�TIO���A"���@w���X�|��p� �F�µ��kg���\Z�Í��U>j��H�?Lu��sQa2�Z� �@8���3oߍw��,�٬�'��O|�4�����͆���x����8��i��_�"�%�F���>	cs�\Eȕ0`��A�hOs��x�G@9�(�K��Ƅ�<�W��tJn6���v޻�%E7�Lt��ZpI��P�FKD/f��AR�.̀Ԩ�[Y�KI))��\�zJ� !�q�����I����
A�u���G,",b%�B0*��c�D5{�Q�z�ʇ+��Q��m%|(�4�E��>���7�]I+�뻌����Xx�)���4�j���U�˚Zy��i[[�P��m1�$�_��;���݈�Y*p�Egĉre���8��H ��}����0�@��|V]2Zr���B�<h��3w9R��Y� H��d��sH��q�}�Az����wbZ-ft'�!G!���6�yW�/�q]|'�PK% ���Ϥ3�9�l��bH�ݷP�C�b�%W{ɐ��6��q�^�N.%D�Ys���X|P�쩦�aW�zt��[�"	��P\;!9.���=>�^`8~J��Qsݏ�ü�B��{õ�hQ����q���涥3�LGuہ�he4A���9��7 �gٴ��A���ӈ*�r���aEB��v�F�[�i.�E7:�0���+;��x�
X�p�τ�ʫ����iwzz�R]<'ѱ.���>Hn�䲗<N@�� j�1
��<�6i�o�)G(�����ƫ��k����Ga�m��ֲK�ϳ}���&q����ku�EHh����n���yP����}��SK�mM]��O�����^H`���z���{�Jv��~�M����#Z`��?Cs����[�D�t���6G�����nV���e�eD��Ƞ������~бݳ�5i���ݝ��T	ǳ��dA�me�����v1]��G)_�q*��{;	���%X`04����$�S]v1�e���:�ҵ�۬��W~�"���Px������ES+��p�?�}��ϸ��ز3��:>qP����]Vo���8$$�SG��7Қ�ڭ���O�f������s4G)�P�7D^X@�ѩ���o{1�Z^k�������w�h�B���OO�mě�GIl�p�̈^i#���tu��e�DIc���-nDk��k%���_����T�)������] �,3���d�<�ى��#��-�Ӷ�����ğ���5�P�scU/�-p�Ut�7厑%ǞB_���~+���iX�e:�&M��͘����K����,/�Aw�>�9��T�ǰ?�>�F�ku%1qٽ4��V��tN�ʺ�=+K�k7��<������l�!/7��<�`�w+i*�{bs2���H��,�ɓ����h�\�>�����J�(w�=2��t:���ap���F��Cg�ڈ_��~����N)�-.3VB�\�x��H�In:�\y(*$\�/N^mYI����R���̖CbM�d�����9I�QHk�GX��C���u���d�����T�a�cd�b�O�E}�S���?���o�d��E���,ě{kQj�� �m�����[ӗ�G s�%���u:��Q9�h����ԭÛ�FR����7�C�MH#�=��u{�wn\&'�P?�K5����-��'�``�����\���b"��;R-�Y����9�����+P�M� �f�N`s��B!�Q�E��1��6�l�	M�8�ַи���y�R�V�
��1upc����	�P��5���-I���{11��S~���&)D�l�����3n��a_�Y� ?�5%/�m�ZE��v�x���y�,s�J) �e��)�:H0@���n�;��xB��"�ٝY�X8�����ۅ ���ȭ�����iB�N+yb�S̲V2ߺ�(��)�k�цe<:�ٷ?kel������ ,��f�a��3/;N۩��ɱg�#�졍���I��ߍn�9"�t8ї�՗L�	O6ݵ4ʙ�����?'���Z���r��ұ�3�m��b�FC�f�μ=���V�,>m�W��<Er�i�8�D�>�BT�\����U�߬�i���_��P:�.����A]���8
���4ɔu�^��x
Y��M�\����g7y�&?��2óS�����Ɔ~�^}L�O7��(���tue�w�q�x��xz��]g���'�o���"%��a{��*��A��#L�Ʋu��V.���bsz��ˎ��x���QL�C.a��O�����
X[K�F0ӓ���@�⒦�'��V�W�c`�[���[��<�`������X}����`$����s"C���	٥����is�r�ڟ�/Gσ잎S*%�!�V�D�4�5���8�\��ءǙ���wn�ں��
�~�f�P�s-���$�#/�Z���P	��8o*p��Y]�j�Z�=!V����Ȧ�޻9�7o�w�� �B|��c���ּ�Y��niI����,�"�E�3ɉ:��4��&�e�*���� � �E �EC�/\�QT�N�M6�n��pގ�?!|T7���z��|~��1��qx{�ޒc����#���9(���'W.?�u[�	g#�z�� ����M�r�t�_ݮ��{��2��*�����>�sF��B�?.�Iz���1m�{�*^��TF�	��׳a���^��>Ý->���c���L�[��~��S����¥8�4�8�R%�]��#E��ߍ{>�h��f\-|\�@-=\���e�7��V�n9�V��<�9����Dc5r��`����΄6���S!�
 ��e�5g�!%��n�hB�|{Ev�)��&�ѣ����ޑJ}�]��[�sc$�i���>���p����jr�����,�K{�.4~�ba�]��a�l<�V�Y ����<n�"!�����F|�zʯX��S��כ#� �����7?fvD��,^�z��xџ�a2��.����)����.F`Э�D� ���q�͙�A�"�Q5����AGDi��_�C�WTNu�-c�'D�����[1�H0hqb�{�A莪���j����z�!&c���t���n����Oi����Q�O���>��ԝ�>}}�QV��k���#1�%3�}ȸ?�N�����w�Rk4�p����`B���F��U�ئ�|����"����D8�'��[%tm�
���C��a�T�����ԧO�	���}yqz�_0����[�4	��q8@�1�)+YO`I�䯑c*��,iŋ�_�:�x�)ﭒ�d�M)V�=-�O��)�ݍ��p�@Tϧ#qXP(�n覯��I���(/��;��cL	��E=�f�[���ˎU��9��!A[b� .��f�X��(?.#d�e��2�`,�x�/��oq�I���a0�n��l��5��!ؤN-av�Bg���Wad��SiĮ�''�a�G���kr����z�\�A�]p����ƣ�y�pQ��Re]�����LW��J���a�͜#-K8+Y�g@,�_������y+��H�0{u�#��/�%��.4��VWðw�YKj��<�)�^��Tw��h��;��S�:�޻X@����_�p.��4�J��x�PG��S�?�E/@,Гx�R��0��ɘY��T�,cd��4lUbAM�~,=_�O����6y˗¦_��9� <8�@�vJ�7�s�ۛ�&ǒ 
$��Ɓ�"�޷"]L�-r�xo�M�p�ٺ��J�Z�F���r*؆`�������'�b&��?���J��e���$��n�ĩj�����ʶ�ޅF�ʹu:������ދ�H��HO��Ԓ[i�ǮՍ�)d���lj�KE��ø\� �`�-閇��A�A/��%�NW�i�g��9%�~m���z�-  y�����2Z1�!��BT���,%��2d�kRi�cĂ��3D���gQ4���	�U�۞�Q�F(Y���1J�z\�fA�z|@X� ^t+�Ⲹ�,Џp�[t6�:Yҩ�S,4��Ϻl���Ȳe<o6V��dNOrf^������|=:鉋�o�Ɨ�^��N�4Tb�7힊[��>a�m�ǤR���G����|��DG��PƈV�"@�e�_��֥K�T�F��mU4az��ٯ�vj������VÁ~��B�-����"^|����0{�,Iԫ�4�o��>�Ƙ�x����l�}i'�smd�6�P��s2�F|c��5<^��(�k��<�ߔn�o�):���"S/vr�j����Of,U�mH]��A�7,��4�*LbЬ��P({���%�yS��W���=靼����h�rؠϫb�E�¹?�x�lW1l� �][�Q;Ȣ]s��#�D���hc�F98�L�Spu��>$�@�F�5�C�N�I�Dw���`xz��W�['��=­"'}6@L�E�v��4stV1T�ߘ�����Ejν��fn����g�����@v��������c��Q��>{�/������&���$���ڜ1��*� ����	�<08��\�M��C�ƞC%P^ǣB�wt}Θ���ޕ��WR�i/�>
��[�V^`�N%���c��.�Ub�]#�dHFI�F�$����>�6~q��#��8D�jJ���Bz���A��EI�9�X��r�w�����T����+�j��*ڻ�\�-�+K�'&
�f��zu)p͑�ж���������p1���<6��q�t�ɹx���m�O�Rb�|�������;-GFI�m!krD*�\7��|&W`c�RgorV��^H&����&�r�,6����4\��&�����Gҫ��� �E���!g��{އ';b���G~��0yk�d��ue�/������穳_J�R����mԄ���e�s1�<)���$�@{,^�n��DÆU&/�ũ4�Q��(�[�-/�w�4|si���=�7�����,̌���@�G��< k-��i�B�����±�2���F\j��"b)bK��[rC A9��^��ǡd��I�f-_P��f�h������ﶛrU}��1��n)���%�H��z�ǉ�	!�$�f�I|�-�7��y5�m)U�D���،�5�'^z����lC��5>�OQ�X���c��ǌ�B^^]�*�zxB?���@�30dF�+H����+9��4��U·.���l�c�ƅsAh&]+7����FC!
��Z�
�dN��M9��ݲ��a.WN�)#��o��|�.�攷�%��J�mrK�����`��f��2a[3��U�C���D���?�|�����Z8�z��p6�x~����CՈ[�@,N��+Q<O��K��>r$o�U4ƎS(��\r��=��!�L������1 �^}���vG�0��6�8���`�B.��I�й�Z�nIuDbH���/���Y}�b5�PZ�j��c�?:�d��A��}OHg�v�[���x�W��IЩ��������{��<\
�3G	���gZu���:�� ?�Z���5�e��u��0���4��O*Be�{m�l����I�Q�◔���TqA�t��� Q�q�h(u�~��e7!���;�ef]�?��j����x9�W+fV�y��V�Oϐ�^����x
���z��<�R
ª���8�d��PC8G1�2�z�zM2W���n]�4v��	���"��dF�]�m�Oj���n�o�K�uj�_�mDO�}���\ڗ��熤K��1�i��zX���|���i�xSC�)��CٓH���a��Nص�2�#1-���ј@�1��S�y���E���zw]�����G67����1����t��\����>���Y[�w	ʓ��m�H+��e�1���Ĝb��%�L�.��XM?�Y�����]��	��X�z�2���U�n�f�H��Ā�`⫻�G�Q*����]�Qĸ�^Bϒ�{Dꢬ�k�Nr���k���U���ث����@V�a!q�݋>4OlN��b:?Mk� �R,Ϸ$E��MƸt�7Gg��A�i���I)o��m�ۄ�-(�GH��hS@-��(Q�s�Ҙ��g�غ�ØRM���o~�Z6,�C��=��j��l��'/��8쵞�POz��悔��)�q�GD/��ٮ���	v����%؞U@(�*	;�)g5.07�'���FP?M��J�a����WZʈ�(}P�y�P�FI �6=T�%�5C�mk�
S,���Fu����ӔƦ���a]=�8S��*�v��w��2���
�Y�x5(x9χ3Y`͚�#���?�9��kG����G7 �#�`�6���,���z��y�ը�ç6�������"L�'���-R���x�^7b����j���FjwB, `�������K"�P��O˵��v�\OR;Y<i��J*�������v'c�l�u2}{����]��&l?�6P�T�kT��g���$����#�TCȏַnwߊ8����������i��lS��Q���Z��Hn�H#��A%�����֍
��T���zvN�6.�e��*
�x;-}�#3b�iH��{�������р�SL'�C�m+�� 1妷\��@I��;�c�`����$�E��'�Q�*ⴧO5�xVy��
O)��N�2di/ 0���Cq�+
���!���r�xg��������=�SR�
QQS��D!��,]�j���mok>��8 i_��}4j��C���"b�VR�� 	B�*� wg���9�G��ɱ"�i��w����f��V�U^#]�'f��+�=�7<��m��[�~��6���|K���<��1K��pn����f�na����Ƕ E�	a�Z�ɣ�|?ǄK�A +�48���R���Ŧ��|��JW�aay��l�<x��f�q�
2�P^����{��RgF��)�E����@R��f2��q�����QU=E[�T��)��6�]e�論5y����d3��q�d���"�)D�~r�/đ>��:I���o;��^�;�p�Wt`"��P���[����{���c���
�,�2�t�Ɗb�F��O�P�)��toI��UE-��3�!>8����?T��G�<�PE����*sK����ٺkC߹Ec���]�>�uڙGBNt�I
��T�N���=kو�$�/(m����܎>-����;����}qg�&*c�3������D����IS��C��u����-[�E"ˆA����;�W|�^/��GH���Z����B�T�W�@%a�ːF�n��@;I���:z��(G��2���fֶ���չ�R]�&.<=�N��s��?�H�l/NТ��I���4M|=WT�ڝ�����u7+��H���pk�Ox�b����{�M^ ���՜�/Acz�R����]��R�!&P>�e�����-n�U ��IM]�7��,Q��9�cq.g,T�v�I�hy4� �Đ+L)mLS�����6O�-/�2��A"pQ��y�L�7zd]z6-y̞����0ή���� ��a������*r_.��	Uz�a��]�;
 T�è�s�ꎇ���^�c���9�z�LŻ_����g����=Ю�B���E���珋��r/��o3�-�{f�C����ܾPCX)A��l�܄1x���!�S���EKq�a���R�8 �d ����?�w7��)%ɽ1�ԖJ��x����TA�<�7���(������,��Sm�n�<"n.ǰ��}?J](O�;�O�J�'��9l�c���ɠZp�TB�l�C�,��G^�Y������(��c�D�?\]/���cLc���T�4Cb�����u=�����S���Q�eb���r��Ō7��T��qh#&,m0±i/��y��6�k�����p*ʡ�:J;�bh�+e3�<�w��l���m���_�Г>�4��m#53C(�V7�DN��G�C(:-r<�Ǵ�r|�:�1�V��-�b��k֤ �}��o�V�����+^_9nؐ
&1��w��B�<�j}�G�4F���<]M]�]���P�c4���o^��i��48��^��jZV<^c��n������Xk�ǡ2�okn_�����mWחUn�&D^Z-�V��i_�0O���F�.�N�C�O���d�	>�0�4�K:��%%���w3K�֬jDu�fsI�/�W���d(_YDr��~�|�5C�jC�F˝_�oaۥJ�]��Cia��!�B	��^U 3BN�)c
�H����k��� �eNK-��k�Ee�,(��9J��`!,#�t���w/�b@JOZ�bUl�}"�lv��r;m����"Vk����!��z4Q̻��Aht�\5:*-�3K����vهA��B��#鐯Cc�=c�������h���zl�'�_ެ��sc?�����Q*B�;?z�Fⓒo�.��x�oɌ�+�cB*�ۿ�Ԡ��^��>�]G%7��Hؤ��'~�{,5(�k�����`��:lLB�h�σ��A�|�R<H\�������l$FR�mz����f����6��\��1�JUCq��P����5#�~��9�L]&��*rO��[dl�4	;NK�+��ݸ�[�p;���_G?8��Y\ܯ�^��E3�[ps ��j�;��Ɣx�30�_���ufV<��0�.��d� �j0��<t�ܷ%�W��Ǝ�=eIuM�����k+c�0�&^�Q�	h�xA-Y/���5�����U�)%�������B�b% �����9�f�l��i00���y�:@�c��="ws`w�W3�`�(��f4�l�Ȍue�h4x?\����e�;���<5��͂�-�<�Q� p�[o�z	�-��,�5hy�`y�����ps�=1X)��Q�,�g�N�	�g�cQ6�������=3�GN�(�c8�
����ޒ�a��$�,h3K��yϼ��-�^L��l����5Z�
�Jp��e8!�����7S|����`��JqS�����uW��� ��,Z��*�dR��yS�.��?��W�<�jLz��YQ>���y�+�e���;
��FJ�B{��l皠LCN�a��{L���ִ�%��)Kkѫ����$�p����S���1)[����Վ��6D����!U'�8_x�:Z���C:J�3�2��7���,���FW탠�z���]���N��7(`=)�c�q�?�Q���P�)[$M��Z�Xd0;�')CpyKL��@�/U� i޳���Xh�L�������gra|^���|h+��3;ڤ���7�-��픉����W�ST���Z�1������.͂�]�'T�R��(��J^Oآw{���x��M���h�	���x����&�N��H0�q�m�������0��|2�$��(�M?��{ԥ��{Y�`hqbH�Q	*X:�v�P��WR�F������d9�
����.N�ipq���ʏ�P����T|�.�B�:4��_c�4ƈXV-L
��^���4��*W��)x.fSg��G�Ʊ*�r�n�@�/I<�V�NI�9�eA~A#<T�i���(��r�~ 3ƱX��I<�!���g�e�J���0?Ї��n���>QY�٣�iڱ�]��1���g��5q�X�L����`y}l(^���9��%���\�1�v���0*'q�9ʯB��'����-���Hg&�-���ծ�~��
�;���~����VXE��[��B�17��aUd���06]�!��� )���L|���I}0��eޓN��xU�o��TH�'t�:g�,9��L����V���͕"a��=���B0����4qqG߲.x����Ҧ�=���:USÊ6��k=㓚?�����-���~Y�5�d�Qj��谅2lKw:_|�������'7P+:؊o�$��M��U���7�Oka���Ts��"Z�t�*�'�<&"g���Po˧$L�����XR���u1Ol�90ՙ��8OC$k�q�2iR�9�[<÷8I�x����?��I�]���D}���?F)�ڱ������_��/Ј;Iˉ)��:���{H��O�����!��S�.�aA�M��=�m7�s@��Pp9���W����z��ҩ4'�mĞlVI�Ӥ����J�� ѻ�H���� J��[�4�E����Z0jM��}g��q Q/y�~��}�
Z����u��ѮlA����\򈓪��P���Za��p���N�]Y��:�,��y�5n��-ut�V~��\ԙ"����I��ŋ�' ���c/x�wW�Le��E$5������f�+$����#��_5��[��%`���
� �%�3]��c�I�3�sp>��R��Y�nD��Ǜ�oP�F�v�Ս�5�2�MA	��Z��G�����4`XOR�rVR�_z���.��3�!��"��V��][�Z2��x�shɹXl�*���a�G#�/��`��N1
7�����ˠ`E���E�*Tq�������u�E�c�h/Шuz�~�x�y��� .�q�"��=�|̆�"���k�}�jdGԀڋ��\>v��^�W����a&LLi�R��:/M��0G�2��X����ps�ֿ���Њ�XƖ�Q���N�9l��?܆HT��Ӊ���$���G6��W����Aۯw4�� =�fZ?�X��ԑ��$��V
�lX�wԶ�� ~3����x����>�PC����X4��mss�_ʎKT�0\g��'?$�qF �	��q���f����d���W�����L`�!w�ï�(�8 �5I����[v��*R'��l�Hp�;��w	b��_�*�m۫���o��HX�[�QǴY���͐wvy��e5�,�4��y)jڼ��(Rѳ;��J��R����mqȦ����A<�\W#����^Hg��-�sx�xU�� CX�}R_}�w�d�Xr��U��DB7�q�M{�����?�\�� ��sp�
T/���ޡ��s�z���dx3�҃�(��B��|D(YG��ƃ"�4Bl,�K�C�M�"����[�Uf�l�/|zz�p��H+օÑK�CCJ�PRİ��IK��ق�J G���̆+JxE�#EH<�/��(6͊����ndzU{�?���V��dc���w%��Yp�ɠ�T��d���" ��ҎnBzw��m+�h�y�=����vדO��u��<�`R^�'q�I��T��rKvZ�v�J	��w����U�ߞVU��*�g���`��"�ψ�r�=<���)᳁8��)�V��d�b)�tR�a4)7�� �c9F�U��f��	tm���?q����蛒+�e�K9g��2��g%�f!�(���r��l�lֳr�L#)Of#R�r�c�6�P �9��^�;���*UYvfU�WX [�9���|9[5a'���m�� ����V/�+4)����7�dvS2K(7&1+�%�J��r�#�G�a黨\ZsR{M5.7�xh	ٱݽ���@M�mA4+�U�tU�i{�9<��=�)߼=k/j�� #�� ��2�g�eYީ~ʴ�Dۑ�ͳ{�
X����S�*�����b��9=���<���]��M�g���:�ܫ4r���p�[S6�	6a��%���I ����F96B ����z鍊3�S�|�.��[������_�A;N^��U���|Ұ����Z C�K�WB��̭�+H��'U��K�/Zų��~�(�P�i�(��\�B�����Rd {ŔgT���^�ҹ���ν5�$ �u�74�����*\o\��I�5��3����s���;SX�c���z�OTQ�3L\q:����-_Ua?�0��ǭ`�`�歜]�Ĭ��rx�r${�A�$]�`��ڑ��Ձ
�����򦁑��щ�=;����_Qmעr8Q������{\da�P�p#���x�����(���F	�����ȘjQ4�Pn¿���71��=��6"FO�՟w������u��IU� s�Ao��jJҠ�\�_��k#�F�b³7� ��6�ˌi�cE< ��l�$���W�5O~.�:�*|1�_H�.ݦ�@yٮ��q^�Z1��H���R�ӂc'�-�C�������М���i�g���b���a�����Y�wH`tȸ< �y�[�ZTs�U�ѱ����1 B�S�W��~@���NJ��#;�s��΅�הic[�����E3mĥ��f֖�T�\�8�NX�a��7���5�y�q���?��\蒷�f��q�-��'�=KW'� �$W�`������f�:U�l8Lm��]8x*��e�n�x��Q﮲D��Q��<�]!H:�!
j`��N�t�
�cuW$�7'X� ����9�U�d3�C(��	ò�?!%zDǬ�V!r�cH>��(��H�G���3����95����Z�w[��$�aEvЎÀ�iC�؁�J�����o�����?����T�Ɛ$lƀ����Yv(��{8T_���I*�"�&�(2�f��!D�:��Ԇo�̏�4�V:WutN�˺������~�Q삺��˲t��6�c?̣{}Q��|H�j�[P�HZd�-�,�G'��f��^@���\I`�ҧ���_éG��b:�:!O8_�\��fmH!CTb��&N;�'_:<��G�`�9�Y^�Z�Qr���_�@4LW�y}QH�ǚ�V ��p��.%��?��=��֪� ~�L��ƥ� �Q�G�H1y��x��'�M�.�o5jC5��������DX�����s�P�%A��+\�;g�/���YO�9^�k������?}g�-c;�ܪy��߆�HX�<K�R̴Tkfl�<�--ܽ6ӑ�.�GH	��݂������2H�Qj��V�6�=��`f9�qn<&CTʿ�����6,�7R
q�
~5�`�$�����;�IYP6|=�A�y`�|����D{�8��Kr�Qq�-H���K�UҦm��_rUW���7���_"��fn:~��.Y+�@�"}&�Zy�w�EIY�����R��ql����V�O�s�ԁР��19�^��%Hx�!�w<a�[�ys�&��͈� ��Z��#t��g!^��,}ʙ�O1Z�}�ŝ���zB�x��&24�o B���S��yh&3�[���Z�d��CV�؎Hu*=�+\
�����2e�=�*��@�7�4�hjD1���9(~��Z�sH�z�C���D0w{?���-	������m�Wv֏����O�.�=�A���)�̵��.����W.!¡E�$����>(�_S�Ttc+�wK��͹����h�H�T���ج�cm~,1&4�G/nX�M�487�yo��,y����:N�}�uL����쳇G�"V7�haF�RR-~7�;�f/g�r��'�ٔS�*��C.��B���N��,PG�d�[1>��-�B,y�k�<���3.{0N�D*%�7<�a�껜�T���EA�!iqאyP�o8��:�(����!����yg��7�fM����z
�4�؅�>J���4��*X����\o��$�Jj^埪3�6J�bo�A�s�in %�i��>�MiʡP̭�� �Z_��.`HV�6N�2(��=�d��BVｇ\'tD�W��G��jP#>UR�(�Մc��v���Ge0�l�Tr^���\A��]�����
Đ�߄DH��"�8�q��
�I��P����6��Η�v���I�.�mbHz�9糋�*8�c5Yk�!�G�Lr�[�ԩ/uwu���M���٢^d�Js�YD���J"x���!|	�2�.l[{�J��F�>��9��!7e~S����OF�=�!d Y������1_���܆��!_�^n�A��ʯ°�=��cb��^�;9���b��jetC�]��c�2k00��ho�!˺o�	��&��46?@\D6%k�~-[9"�=�y�*,���P���*K��l�;�'�iYgI<���7���+�%��^8��Ԭ�#7���[dl���_�:�K��O��R��W��� t_��G��+���[N��Mc����üT�X����ף#�I�[S�
��M��\�/�~��� ��H.��LE���׿n�݂����{�KA{Q�� 6��T����}g>/�&�7k.�&���=9����pdJ�<sӰSC�1��43ț�3�<^�L�V���@�vr�����d����i:�蔷K�>ʛ���:�l�jts���B+��ܵ�.9n)�7��.@l�w�:w l�A8��
`l�i RB��Ӣb�����Ps*G�X���7�{�GLhM��y��h��m�u��%M��F�
�n��)���f��(ٱ�w`Ȧq�^�e�
N�9ꯂa<�VZS[���xU"��Z�/̔>� Ȝ�c�n��7�f��=R���
5w�(*^��,"�� #�g����@ms{�	�D�[��z"��t��K���[=�,�������*	�M��:����E8c�5c��U}$ׅ�z0-��a��-oP�h��::��Y����zWxk`_
ֹ%3�S\a���^��X��Yg�2])~���
�����g�PpO��VQ�����x�6T�v�¾��h�l��jY�Y���9�#a�.Kј6��Ƞ!@�!� S���Avx���=&��S�38����e���K�>#�.��$��z�O�������_�I�A}E>����Z��ǅ2��݁�!�xRG�3<�>�r�Eo=5'm��m��he�����n0�ܑFA�e�X���}E������4��������ձ��G�&�k_����)�����А�n^|*M�Q���`@�*5Ğ������
�FA�B���ܗ��9�����0O"Y��P�O���s(�J�#Rv6&�9����ogad��/n��[���vB��Ϫ����!cv��{`���py�P��^Ư�J�����[�\�p�#���A���72�7B�f���-��D[���k�{��=8Q6�v�\�3�ﾸ@m��SM��W<�c���!�{?aP��ۜ^�a~�(:S@uDQ$���[H�z���f����@1�s��`~�X�|���Z�@W��2�B��@Uګ��b��ĳ�M�h1"���t��y� �N!H/�j�}>�D@��:�yg,']�<� �n ���~ �#)r�H��~��>-�<W�*%����4Rl�.�e2G��R�Y�] ��vܜm3����	��X]'9�1}��5��zd��OX�C꾔,���L��N���u�'��
pݻ�Y�_j�	ou*Zi�c�x�չ���(Yo��{�n�e��;�A@֗O��(R��yɔ���/�g{�I��S�>�~_!���B��\�Ǌ�*��W�B����̈�� �0U��;��Y1[�s��n�.�{)2�)�]��KՂ��]j���%�Qy �	��NZ�;M�"r3\t�Pr�]��D�}H�z���2;5�4��'�@P�Jr3mܔ��7�ފ�O<�!��Ҳ���V�>����z&}�+[xi�N�Ie!{��(��ed򄽛�6C�U��\�4S��<�_��~OL]Ա?>��>�*�'u�������,l/�W��F�D9Ac�[;��.�T˾�(�.Jh��2}.�u��Dg$!����.~cxP5^�m��H�
z�(a�����'�?-�[�'��d��q���=\��k�]\�z��l����?f��%�i��_�}|�lH��n9e-�V,Md���$�e�/�)�x�imߎ���~�R�Q�Awk"�5�R�+�G��"�wg��W�KE�q��ף�c!J�aR����{	9��,W��c�F�mmYٻ��(�ɴ2�-��#�=�k�wTS-I&LM���ν1�����=t\����`DV&Z6D�V�P6x�ojQ#����/�Ȩ�I'���w�ڡ�y_��5�A���u�]\B#�����MX�j&L�e0V%���Ь� 6P	��A�umy�_	��˔G$U6М�n,�K�S��L����#�޵G�a��nb�.�clP8�<���i/�g����#4ڦ��hG��ϬoX�4�T��f��w��I�����ŞK�ܜ�+=y������/N�cNA<�q~w[M��2s�+�ǴbD�u����W}נ���_��@�u"/xq5Q3��,�z9���4������+g4��>������������Фq|H��9R��i��j-�����$2W+Y�}���Z���c��y�-娧������puv�n�����f�˭s��abw��/���q��I�=����*�6�;a3�}�4u�M��@��	(��Z���Ę��NTf�W��v����4�d�P���	-y��^b@o-�����}�g����W&�%��XSZdu>{������`&��Td&��
��9����7^4�VL��К�yCh�7�i���	��f"�}n����a���W�8>C6+�l �v�e��U����rbVc�Ǔe�s�YLq��)(H6��"���y��>mlZ�lJ��B�и�%�ʽK����yi��#p?�K�O[)�s�͖R�GG�qH�R�M�d�UmH�D&�{�k�f���_'P8E����%�ߏ����h�S��Q��J�9�QP����"�P�,t�5q�������zl�o#C�j�GӚt�JԼJqF1��k��0���?c�P�q�[wX�&�6?�v������t���#_SL��k	���ZQ�*���+��3tY���]<�X��nc��Kк��h����^��Mr�h�Xs����^�X������VjD�xOk�O�t�L�8��M���\�����J�l�$�nw�egW�yc��1,c�F�����ꪪA��t�TLO��@� ����jgc�pC4�R=B�����)EWE�������a��g���w>�����ޏzN����aG����H�ǩ�������*�E�La�y�&�G=������,�K����ђ5�DU���;T�����Dm԰ر<�1�1{y���A���FJү<ܧ�(�;�E�Sj���j�3B����J��(de���c���6LB�̅�)��U�eN���[y��cI`}���� ֲhE�J�Z�:����R���m�jr8���*k+� ��։��������g�=��߀���rS/�^�;<��4��lrzU�]��.�8�(-3�,Xi #t��ʗ��;�t-��E)���9�?��;�dmh�k�u3�y��a��ɱ��{�� <�f�H��� ���^뽩�w�*o���b�"q1|��vK���I�_����4��՗G�z^ū�7�������9�����8�rߏ��Ly����J*B����UY6L�J?O_��$)�TO���2�:[>Y�@o�����\����Rʺ<�ĉ
>3�����j4��/�_�A;uP}�d<�je^p(��j�dO|1쥒#��EH"��X]�	!��c�uw_�bH=I�-6b٫�[R����9��ε?�c�G[qv��<�4���v���$����s�w?}�/6P>/[��&��ɘ�|�#y��bA��[���o��2iN��JDbM<�J)hP"'�����L4;v��#Z8=�"bw6I��3
#�H�$�w{��s1*3P�]?ҋ�"��xyO�8}�h����>RS$���ku�U��?*QH+�C��^��DR
�`;�P�=Ko��S���dv9�~��$&2�r�{�)�FLHo�٨J�=��6C�%i�/�¬����r�Zf�VM�m
�9-qDU��}�y'H��'��O��x��n��	����J�h�����z(%i����t�ZÍ�хZE�:��^ń�c��K1���A�Fp�1`Z�"p�{�[��[�zK^7��st�J�8&:k��B��+�>Jz�`U�3�1��m	Kd�4�p敝��BVG�]A��~����1�C��=.<V����2�_"a^�Sv$;ʤl��G)�J����X�Q�/햳E����\~�����W�<M����>"Y2�FӞ�
�Ej�����گ�B~������d@%�wb5��^t���0�uT�O9_�`L�%���4�'Y"[6���@�4�S�=Z�K�\jZ��N�7��(���N0R��-��t�9;�Nىi������S� �ZNY�C�n��ȧ-U��3����ֽ�"�l�;,�w+���F�b82����PĽK��q�XK�D�q�Q]���AoE"�VR�)�I�j���8�ln|�jb,����@����C��QF��U��gz<��}���ƃ#�z<���@o,F��(\3�și�{S5�;�O^seA>=�N(%��``	/Z�.Vb���)޺BfNzfd,�V�F]v�?&�VX���N���6�;J'��[_��"	DB���:�� <���[|Y�ugǵy�Y*vi�څ�]y�l���tz����"�˺ֲ>��A�����1�S��n6�iz�w֖w���v���W���4z�������6��T��x\�U�M�� � ��OR���6��$(�t��2���C����:��$�f�����s����I��h+�x�����������JL�\�yiM_�%0���yM�$HC��M����rR�g����v蘑���B��eC,9_Zi?�����}Y�1�թ�Al��?����������S�����Ar ��k�e��9��8�6�~��dqB���[�5����١r�N����WE��v"��X��k]%��[���
�d�R��f�sȇ���quﱮ�d�����J��@5�\�\�l�L�`g�2<� DV���"����QI��
V���੻��#�+�$ԙu�^J
(E�DP&� [|S5��������mٵ�>��߁��ޥc��?���酴�	��n�	�=�dI5�
��ǄQ`�#	"
�����f|�~��`�FP�sR!��<�藒E��b�Wt����p+y�.6���	8��f�3��ٗ
����x���Y�U�=��z���#®M��D�&]z~�/�˭^�����1c8�v:�r�Cў=۝��T9���v��V��+�Q���2�8��3VѺ��z��*�>cS��iC,K�}6���<�c V��tT/�N� �%����4TWn�	�h���8�ܟ$ff��~�Z�P���_pc� �qǏ�E=(��f������ �'���S�loS몛=q�
)���^�?C���_����C���LH���8�f+�|���9e����;aEFO���l��ZE4<X ��,3s.�T�X+Vvq�2��E֚cH�]I��@"Te�d��ؔF&�C��f"f�ޙ�Nj�����0��+"�DZ�rg�:��!U�� g�x{t�� H�dg;�?�P��s܃;#�&D��ȭ���9]�����C�k1@�l`0��c^���&�ة��c�b��s|��)~���򿩟�|�{�H�����A�j-�CW�xc�l�B�������1��,�v)��J��n��?-	�pqh�^ ��f��p��j�&s�:��c�C���h���F�œ�V�ʝB�k豀�����d�z`�\�
���۷�l�� D���������PY"����8M觑������#�j�r�=�n�D��=���JzBPy٘����í��e0�ty��}}��:/q�HCqS����+Z^p�߹T$�`���fMNF_\Ʒ&���&,'�LS�k�0�A�k���<8O>pA���/q��A>t=�g�_�����kUGU���%aF�������#	x|�xC�	�P"�%]��*!A�%�% ��`�MU��<C���zI����W�q����n|$Gf�%��b�J&Y�#[ڗE�rMH�i�P��y���"�5]� H�greA-��̭�����j���������Q_�*��?��uCɜ@2h�Mu�gcˏߖ\�~L��A�xT�u{? q����0nQG9���ŘL�d�g�3`�Fjs5�FB��JV ��̏ƙc4	�{�C����n5�K^�� uR��7�z�'5���PW٫��Ӷ�Y�W'�.Z|�H��NvҔ��p�6���#�;z$�t��|�2��j]�S�a,8R��r���E?�"�W��9-���%4�e6Bzy���?����[uZ���}K�}-�3H8��;ĕ(�I��M��ϭdЅ�6U�h��M"��!�|@<�b&��7���?9!�o_|���\���Þ��_n_)*�H9	 =�u��9�I�����"�w��s�Kō� �%&�����	��{�a(X���U���&��?��L��<KB�TD�� �^ĹmV�F�wP_�8��������{d"���	���aG,V/�cxK�ȿk	�BY4�C���#���m�V&�+��Ԝؾ�� ���������Iw�r�&��ցq"���O� �OG`~9�+uE�  5a���A�)s�g�(k�eu;�1��e�JYѫ�?P��.��(D��!}6�U����p'GG^
��C�+�@}�(메����~:8c�Ӝ�bg	�.s6(M����ۚ�NGs��F�'S�z�b��z)\3?i�����0`�&W(j����H���ZfC>���,C|�L]�|��p�M���?��Xr��&��'6:�uu�黂��J�DC�d6���F}�i8Oy�!x��/�:��Z�&��8�џ>RL��;�
韪)������(�wQ�����UqT�؞���n��FA�#�iVxf���?@����x�r��/�k)b	�9�fd��k%�s�o|��t���n�c���H�-2��� ����x�k�&�mfFIc�4��i�1����uq��O�[C]����]�	d��np��\�l?�jt��G�V�aʾ�T�		�%e���)�K�={H��Q��I�F�r2Ŧ�T�e:�:�/��"R�h��S�vK��޶�4VJ8��Lh���&�����E�
F���;u���3�q�~A��Z���9�t�EF�WC�-�V��$�Ȗ�U���F.�o2Z����,�:�<���.���yy;���'������0_-�x��94��u�rH��+~{2��j���#SH�>4p:Z]�^>�O��Nf�R��ų����:I���e�[Awhv�5���H�#"l�$���� 7�^T�4ݜy�΄N�[=���v�b�*�L�*)����A^�w"GQ���\��Tw_���{Z���KRj�8/y׿�������Dm���E�U~�/��������KR��X>Qa �3}vx�'��5���4E�0E��'�B��g5;��{K��e�F�e�o�߁���-D��4�Nf�r��R�1e�2�h#LVFγ4'P�]д@Ip~���4KE�8��
,�/��)��Ff�g�e�'��k`��B�(�\F��А)���L��!k\a����5>>�P��*����ފ��ަ�2\���<و9L93�,����*�$^qO������@Zw��e��I�d� i#��/X�� ��m��t� )MquYc��K]��� �pX��߉����+u��s���b6�������Q���@[8����qC;��_�U^Z{F/���'�X��m��#��	y��'!�\���Ż�O@f�q��д���M�,�d����u�ޙ��d��u�����4.X�p'I�䙖���"�۪��zhe�GX �m�O�k�,�h���)��T�/YL��p�BT�Q����Ws��g!�%4���ʻ�3����6HH+�V�g�@��K4^ou�ֳ�S0��z�C��h75$��@���:m���C�b�H�k��s�3 t����=��Ľ��.p�**��ѧ�6�Ϋ��]��*�P�.M���k���J�؀�U�f,�׷O�^L���7�R���91��?��'I�~��q��Ĺm����-���8d�{�W�L�,��pg���7JK
Эpb�����*袗u�p�Y���F.s\�)��F�t���M('/?#��ev=��~z0��;u��?�F9ck�5�i�~D<#��'#ȾF�Ȼ�����n����r�Z�LL)�]޻
�k�t??ՉW���#�^A��\�=�J4i��f�j:H)ܤ�l�јW��ǣYC+�(��M�<R�y��~�$�l���f��9�{߭�M4��=�f� �$�2F&����J�<�+�Q[��I0����0����9�})̀W�/�z���7j�r�@0��(\�	��+���=��&����%��q�9��]��S�CN��^tc2Bkf<;�/�0�u�/����Thj �Ul�O(��a�N�dG�3K����_��Q��J�Q;��Sdט�[:��j���Lm7wh�㹧y���}w��6eR��}5���֞<����7+
M2gX�cQ�9��{�����_�6d��
i�mY�@��H��h�~e򾸁�kt�Q�����4��^K	�y~�����A.�	M�q75L�Mɪj�{{����z� �7��<��������݄�<�X�i���1�6�/��W��J,SR��ʱ�6� B>��/��3�o�����n�]Y<h��[|�}�f�eack�fɩ�"6";���J��p�f��� .t.;n���5D�L.�����V�#�GU�]F��5��r�<�\|��8�?׮[��ѕ����������tO��a����zشc��Gw��)��}�.B_�	�g����|�[-D̒`އǎ15���N2ga��]\�o��v�Q�f�1f3��,L�;���I�2+o�3wx}�޹s	�G��lc݅�WR�u��\P�tτ�6�t�ݵ4EĪ]�L#���C���U�����ܳF4�����(x�OӪ2Ӊ�B�s��Ը���ۮi��/wBb�&����ay���vG�vJP�/��o@v��V����t���|���W��uvfY�<�j>��3�Ky��v�݉��f^o��Y����x@�-*�A�S��\���K�\�Gk��[�9c_`K���>hB�	��a?Wxp>��vɃ�D#����r�&�Ş>p�?<G�3a����5P�#ޜ0H���1�D��$������X����(��*����|g�T̕�hG~MD��8���6��g��8Ҙ�tj���_�]��nXL<=g 7��c�+6��0}B�W�w��;�f8
jz8�����E�[��z�̄t	���%Ê��5W*<��fٷ��tӬ�ԠGw��o���`10:�2JF���)A�4�PJ�*�	�����ې�y�{���>���VpI��X���j�r]�G����G�x`�#�iYߛ�s+�:�O.+��M��RO�y�A{� T��wmJUf_Α�~�٘-)�R�L��k�FQ��P.��$�/���^*�u�[����`� ��Yk�Ѳ�-$[RrI%���g{���Sp�"��n�o����Y�I�ۊ��KE���=��Q���%n���|sh�6��4��F�S���lnŗ~��W`��$���sp�J��R���Q-$L����������cJ�\*�D��g� dR��Zr�
1��   ��	��Ir �������9��g�    YZ