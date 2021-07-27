#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4135448582"
MD5="2b1a06b37c5245f6934dbb47f3466a04"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22676"
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
	echo Date of packaging: Mon Jul 26 21:10:52 -03 2021
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
�7zXZ  �ִF !   �X���XT] �}��1Dd]����P�t�F��F�A�iJ3�g�-�@
ǔ�!a����d��� �� ��pW�6I*`$����5����s�GN�>��B1����VM��rP9k�x�������*��Տ�9��?է��Q�ł[o�R!D*���M##�.ԁC;���i�\a1�[��,���k7���]�����عHv�����Ro�c+��Zݎֆ����n4{�0���\+���ӟ��4k��`�n� �q�8e�`W�1F�i��H�Ѕ��K�VT���^NX�"�ƧV����k
��X�Ƨd�!J�������y	S����C�G����S9_�W
��M��۸�k������d�VMJXNB��e�>qǰ\���`�8�� 1.��-�;YW._���� _Tr���z��A&��a��q<Ƚ���d2)���ɰ=�x&F{J�����k+�~�n��؆��"��4Q�E���� �*ѦBb#�?"9�� �8�i'sѳ��z;�iv�䱵.6��\�6&�.�|�2J�t��$'��:�Q�/����SA���4GE�y����v(�|����hU_^�U�քp���a�-� ��;mS&t\����qs	�!Gb���U�}�F����<mޘ���z��F+�ȟ�l�!�LoxE)rV�Z9߀ijר-������XM�י_!�Ն�6�a��Eǒ�f������;�"�u�^��*LM9�}��n߰f��T.P��O���GT�{�w=�oUd���7d�]f?z�1����������޾RǺ��	"�)��+�yg"Y�2����zw����C)��d�ל��PKƥ}���e���nb
0u��1�<,p�Z� �1/F�������^�]���qz3���w,7��A�+f������[���ci>�����m���qb�!P��Fl+v��C��ы
��F@��T���a��݈�=��	�
���:$�5��YM�I�ۃe��*QC�o@�H1���B�`��XѪ��+�r��1��j�*lY��0l}�:OF�m!Rƴ�Mً[���fXC��^	C�ԁ�� D�c�q���b�|�17�����5�o��O�����Is(�V2">V��ԏ!�����4�vS���ll���w��I�
�L
�Ju�B%����aaU(�D�)J����u-�ZG��R����#�%�y����KP���9�ǟyfxG�=̧9����q@&��s�ƞ�+���R�OJW��u�v����^kZqy��nz�Ie	���Jn^V����Qn-�h���)��0���f#����$m�ٝe�M�z�����SL�8X=�s�maJ;������ T��Guߞݧ�]�CY�-J����Œ4}b��Gr�����|h*��ϋ�X�Oy�>�R:�ι�2���t��������t�����H�of@����Ev,��I��{w�ۡZ����2�F)��9~�kJ"��s@Q���>�C�2cw�[@�I}~�9Xl��kͶ�p��u�1�ȟ'Q�����4���a �������h�+�:�����4�f�u9Y\ި�VӲ�8x�8���j�Pg�b�h�D������Ok�`����ֱ&��f2���c���x87�����}��>��Mz4˻@�x�x���f+��jy�ˠHj;�Q1}����l��E�`�֠<�}o. �D����D�E�/O|x�Un0wm'�m�]�#t�i����	P�*���=�=���T������+�%N�UEV�}�X�"\0������� w�pYF��:��T�w��m���6o\g�r��v�&��Cun�˼i�%S�P<A	�>v��������xx��J�;�x�v#6g_�D�j͝��Z��=�������0xhW���N<^yV���9V��h8p��5��՝�P(���Gd��W�F,�V=Wxqڴ^7.�d��oaG��rmH%cF�<{�F�9iqr����Q��P��灦����Dn �/�zMǠ�CZ�*��z������	GHg�&�[�8�Х������*R2�P)	��A}xY#��iA��a5!Sv�vE%����t�0#V��g��m̫7 �lS�ͯ�;�!�I-SX����lGO�4U	�^�b�'ݦ7J��k�[��N��/�`*u����8��G�%�XmrKV���!~��9�3�=C�I��6�`O1pz�gr�1���\�Iԗ���C�u�2<�k�K�в�*�W�]Be���mg�U?_aҹ��끤�-���?9��u�Ι�&���ӭ��`��<�P�ZI���O_�/�c���	����ߖg]a!:e%+���c�b����w�H����`����'b�S�	*�ftE!������'w6� rj��N��d0�E2餺;�����K�w�zj�Z�eJZ���n3�O�� =��r�i
�!Um�Y�6%���TRd���+"�;Sx�����o����A�jwc1��_/�?�]op:@�ꚸ�W���rT�2�����:k�G=~����&]����=b�RYD��񛴋I�;_l,�ÛQЀ!��vqT�?���J3���9	t�[�%��+[��HOO��/�<~߻�5��!(P)�.%;��$Vh���m���Xu���zEƕ��4�@7X�oC�گ"����H�9�~�97x��I��SX@T�1�f�f�<��DE�`�\��3	��fi�W����4A_5s0/[0NH�X�x�����u��"t�\օ�>V��us�i�Y�׹�[�`�!��������2Ơ�2�Ӷ�;�gf%�,�$_ۊ��I舢�m0� ���Y*"�}����1y�q\6��Ojn�BbPj���bӖdU��%.ơ��H�/Z^���V	�*��@� ���龟�ij�$dR�Iϔ�X���7i ^�(��!�����
��=d�xi�Ub�>QT1A�V�\���q�N��m�<�ke�~�*�L�{4oR=��'n�zNi� �C ���2�r"	����8tE�������N9{�f�rȕ���d�x����$�x���%E�r��O@�E\�]l���P�U�O�KH4<�0�<G����:�#'f\�"�6�g��7/)Y����R�qF���_��+k�|����:���C,O��螃Ѥ{�h���۬�0��lct�/ΑO�g���P:��u|�GxƐ5Pӣ*$ oo����)���^����2Ϻ'��]%t^�?�fk�oS�	zF]l��웭�QUI�P���ph�Q��t�y�Q\�ᝐ��m"y��o;�YWR�0Qywיw�1џ��Ok������`"�yx[ߴA�������6n~��s��
)X�F��"�FJ^�)]������)�Ӈ<�,|85�b?S��K*+�#}�dn��m��ML	]��f�1� �����ӗ��x�}>T,�G��̩��(�u��B�9�{���?x~rW���F�� a�ݥ�YT�$��@�rB�{�8j(1��*rNn�,��m����a�ub�6���Df;������^ĸp����ƁC�9!%�D0��Dg��޻t�H��>���W,ŏ|+hrP�x��C�p'F��I�)�=�i��~���U[阫��)�פmX?�v���M�o�Ry�7��v��.��m%O��y���-�"����'�e��)d��Ұ�w��~�6!�E�^Ķ
�-�	��Nq[�0}���	n�N���z����SL�^'{'B�K�R�e���DՂs��@�d�������/~���RO�g�ʳ��H3�{��fHk��4�N����9g�}]\�!YD!������ T����@�݄�6F��<'�����f;�������Fs�˒Ռ�Y-�A�^�F��19��լD)^�K��(<,��: �w�B@,2���f݀��j)�(�v��i�?�F"����ȭL����Ϝ�:���+e<�@�����.�o���o�J�'�k��Og� �c��`ْ�s�a�dQ��hz/-��y��.ϊ�$���e��~(�2vZX�B���4��XI�X.1�[oby��b��(}|�����D�0�p���	ј�9!{;W�2<�`�ܡZ��U�	�0DI]!�r�d���ɦ,�q&Rv��7�p�,��ȿ��'�<��8�o�w���+S�vUۯ��I���j*-l"?'ț�ϸ��!��ȹ酮G�7�Fu_��\�_|= iˍ=�i7�����~ݏ��&���β����7׋�����"jz%j��@��c���j�Ύ�ڿ]��g��Ri���g�C"��
��*�B��0^���Y<V[AV����0���ebC0���.����(�?�:f�>z�,��0��>��l�q���h[a䕄�p��1&��>�pS/�k�k�dˎ�>�jTB��ڬ<\�>��ГǌI�?�/�����<A]��B�;��>8P��X�Y�/����3���_!��;b�!8B���T
�	���p����\:� ��KLn��d��:�(�c��%�{j#����XD����"Yv�/�[�M<�`,\O�'�j5����l�@�E7jZ���H7r���@zd����f_؈���xhpl|��C�I7q�N,sL	�ck�R�.̯����1N�������,*�fd.��|k0YY$� �%�	�Z/DŤ�z�M�ر8F���7n�rn�Љ&��]L��9���]�x��e��%�Ar�M������:��U�a�|tvɨ5�I�y�{��ZFZ�{���05���Y�ʆ7 %���R1��ZwJ4�Pּ͞M��ڤe������:�<��1���0E��U��g��g��hi���T/�ziv(X)�XE�C�qK�d_^,�)�\����}ޜ�m�(9�Ղ��3�������@}�s��}ڂ��$Cg9��˰����i��&�,n�,�W�	�!����A,֫�<���p^���{V?nߵ��K��$J7�,������H��w}։�P^����*C.|ɄgE�tv�AEq�*�*{��FO���Yė���K�uT�~�ޢ`0L~�R�l|��Y�ǻ��x!�o�>HG�ƍ�9����SvCM����qpI�t�=A=9�b9np���S&K��c�Cg���{�!6�Id��B � -�?_u/}Z��e�"p�i�3Ŷ��$G�x+l�G�Ơ6��E�*���B��/��Lȹk�Qf�s�Xe1�8���g{�Ai���Jr7lu���Ȉ� .��m���w���.�]6�eJ�S��O��B�����a�{!LK�^w%��ߏ3so�:��;���=>S���O�P�b(d�׻(R��ʟ%d����b���Ol���t"�`���ˡI���[��y��/F{�}g��X z]��C���R+q���K#��Ȼ�)��s_ydEF��:�p`c-��9���fg�N��� �Q�	�v/e�7�~����dA������Ӈ�[�}�*)����ĕ�W��2w���[}r�2*��	�$�R�e�� ��h� �(��
JK��1v�@�#k���
=��w<X�݀�{pل2o���<�_��;Ӷ��5�E��恜��j�C��o�(h��2�J��塑L6���$>Q[��S3�!���t�K�8���(~;��^����%���YہW��v�Q��3�F�S@-��="u�T��րw���_�j�H�+g=e�D^�����&�z?dz���ߖǱs}���B��l���!�u��'�e�Il�8�x�2s�s�������L}5�a32L�e���[@��^�sv���p��U�/Wˊm�Q���}�7��zw�(�3R�M]��v��Ѡ�)O�x�8��r�yQ�j�E���|A���y!���M쏬���S�!}��qaf��D�����t����r���qȥ�Vf�
�q�O�oK�K�H�y"��R-���y�A�U��bsJf�aWm�G�`}c���*D�#J�>
���Ut!�=��6�Y�P|&6Vk$1�~>"�ö��x����?�C8
���zb���s��l�2)�M��q\��f�闘�X�Y��p���'�2|�0K����~���V��eX)<�k6��wx����q��Rt$�PΛ�oB�>�\t&�!�6�S7Ȣ�K���:|p�!ke��MK�Jֆ���$�0�,1�NQ��g8@O�����B���(��o���d�2$�`BQ0����U����_���c�����ƃ.���(�t�,'�,M{�3�$�PmU���^��
��2���X5wX�̵LE��H;�r��j丂�A7���2���~�o�&GZ�x��DI��,��{�?8e_$�bz�]�)����ҍ�`�G�2����Pv �H�X����RRz%�,;��;ժ@���˚�f���:tƐ�C��X
~�sl����v�x�� �nyP����W# ����7�/���i��������j��~SDds�4�y�(&�ixQ��������-<%�p�z�d&��]�w#T��������/��"7�Z���,�w��,l�#"C�_o���HC(��M:�1�� �Zo嚽�hRf!��D�"ftD��w��O��K:�ΌÕ�!t�V?�²q<�v�#�.l�0q�y$o��|�X���ۮ���{��6�7|P��\�T�a���'��N4��o"H[����Ha~=]�Á�2�x�uD��?2=R<{�{iv��h��T�h�T����¸X�&�v�~���4s6� "`Y��P�k��*9rd�M�(&
'���3�d�V�;�+��d�刨�	�14G�l�����)�J����!�`�1� ��@�N�Ӷ9������l���8o��%0�kSݿ�ً��M��d��Fue�sN�!�˒c����̗��iz�l���*/7]H0��`;��/�j7�ey�,79��1��0��:̤H4d:��[����J?���A?��a����(Rc
�Cc����oa8���Y���u��c9?ݖ�O�Pk�Y 8�|��Q��7{dQDϟ��Q*�lV�t�>�z����VPE2���YX�{|U'�_&�eK�e�I�~��BS����xZ˄3�O�iu���f���%T�zO%��m6B���܍�n�?i�wL�Fg�8�`���G;qv�-��[j^/��\]Rߤ�<��!��/�����t>�3|�)_���EUOv;�,��_�	���8q)��J#�F���Z��`n���H�1l�J�0Sm����ܤYp Pq6Ru[��A`���x "��1�t��{�y�;3���X\�c'u	l9�mr����D�hf����Dy�!�ӤA�_�L��*���O���-�AWșǇȍ*\��O=�f�������
� �8����_M���{՛
q����{�u+*ƅ!360vG9}ܳs�v�-b&ᄘ��m���7��f<��.Fev�A��E��
:�J#��+�;h�J���?Ly�>{�M񲰘�N�M��S)��	�{�?8�wJ�؜�- rׇ��p� �3_֟7�3��|1-�RQ�g"S��ӍSr���p�I�INSǤ�-���yRp]X��gf�^t����q`�lH���Z�����*ݝWˍ���e�m�G��s�fTH��|��i�]C�z LM{�O@��6'������� p�HH��H}7h�v� \c]�V��T1Lr�n�y
�t�u-�*ֻ@��m�	�R<�<��§�c�Abp�����Ҵ2Gk������b�>������@p>K(Z-�J�6��E-j�O��ף�b�B����;_R�	8�'���tI
��� 
����"�GSNZye�c�m�(H�_tgͭ^j�G|����Ҿ�u�OՔ3�uL�@�̗�f�\��ǜ+��O���W���cG�مx��܈�a���@W�=����2&ջ�G����6�ï.�n]��7�3X�>֠G�~�t�i�����)�g�L䚩TWx5��YJ�nٍ�_�܎P�)���a�# X;���J�]<��M�u�TA��Q���!����yE��G���Xμ$�4����S%����O�EZ�������=��[r[>�ٛ���;4b�����vR�ׄ�b��-.5�Z+P���d����Qwq�>Μ��=�lj-"��ۂ�,H�A�o>o���
�}Ռ�2��R\4%=0�s)�5� ހ����(JN��
Q��y�a����]���X�8Co�X�L?�3Z��Eo�a���)�~��"r���pe
���\c���_�&�	��e��*��sq��$$v��S�C9��r�7Il�#N����%c�7�X�?�Ǉ��e<E��X@��/s? ���0@�7�����6x���]���y���}��n(���(��
|���F ��s�9>�'c:5B�[�[���~���u���`�a�*4;Y�q=_?r==Y�z��'��|�>��$*J�����&�Fn�جc�쭨E>Z�f�XL��fUm�,]��~A>JJ8�/����*��\mFT5������-�`��:����06� Ђ4!őQ��j��]����I���4H��N�6�J�jd��P�%��oԊ�B"���9�,\�<�nFb�����Ё�ʠ���P���9m�'��)}�+P�]e�u�$�m���϶˕�v����q��]5=�ɺࡨ}����������n��U�F����s�U�.Y����x:U*q�/}s.Ψ��7����k�At��Sj4M����~����K�z�VI��h�5��`�&y����Co�T���C���AB��R��v���5?�FM{)�G���R����c䦏.�����=�l���(/� �����4������~uϖ����甸�xyQY��K+H+��;:�Ǎ/`�KԐxfi���o�P����V(�lj��h�a�q�S��q7O��F��Yl��V����gAX[������
i�\O����>�c�Rb.�ף�ќ���Fh=}ͫ�P��棥�Sj�W��b�t�i'�7:D��EzB;{Q�"�Y��}!�ЋX��~���9^�¦��B-�"D�P$C���w�)!�a���#�a%�8u�O��U��O�fy2�07��
+rv}X�q9�L��f�zEB��$B�Ww�q��Dtm:�x.d|]����O&��@"�iiBHP�~#g�a��ΰ�~EKY���[U�.\���'3�=�}w��rs24�G�o��v�B�J�:p��1���3S��6|���7�������I �IFj�?�Zɮ�w��b�Jg���K��%��=�cL٬�8_Le�a'i�?�Un��ώk�+ ���,�=np���S4�ٚ/n�;5ku`K���]�^�@��u�jn���f�!����8Q��!(0ԏ1�n|�������K9��2�!*u�w)>症�ޱ�������aM���7��C�U�W0������t��Va�/U9�|��cv�ٻ�����Qܠ�&+�	(�[���<���m�]<kWftjM�T�'.��l��7�3�����d�S����]��j:k�ewo���89NS�z���?��)z�j��WN�RbG���TU��K]7�VSgGi������]S�������o��R攝�t��ִ��&���'��D:gE���uH򤐽C1�T? ��l� �h�>���pcJ�x7���#tR?ۃ���u�y��H��L��I�"�&D�¸s>�@�ʝ��b�A;Y��C�ݍjQ��{⒳�ȣ\���Td^�V��@�s9r{ү����F�h,� ���(��]k�#�P�k�- ���N�U�J(G���1�
4�\7��ҧ���ď�J�
��׸П)�MW/�ي�
��7�'��OK�+O�I��Q�'��@c�\4�t���\�a��:�\m��U���w� ��Sdy<�S��!�qf���6G��E0蕈���>�JSg��ԑ� ��z��[�VYd��"~w"W:z��E�&��Tb��S���x9S�nK��qg�>�j��'���|��֧.˜mI�b�G-t�x�ez��qOu-@�3���%�&�����+�Y9����O .Ak�|���v����+�;>M��Ѧ��%lS1�K�3c7A�/�J6��t7=�����9a ���S!���D�;����^���J�CJ�+�r�i��o$΂nb�*� ���9��5Y!c�j�*^U&:u��w�]�1%Oy~�y�=��v�4Q~E?SI,y���kk�]�f��
'��90��2U��9��2�U�y���R��x�cj��<�����fN���2�<3	�՛�s�m��2�K�	(1O�mW�%�^%��FU� �°��-GoU��+n�r�:g)���}��Y��Έ�"��@��p�:E �!�� -an�h n-6<�����C�i�ЊfG'|e.����0MT���w
�}�%������ ;L�&D�(͚}�M�j���ǁ#LC_�Kb2ȹ�V�T��&����BVQPxw��Y��B��T��^�5���_��_VĮ酭�S�*�˅����P5��8�?)�Aϥ������:J%�a�r�s�ۼ��8��#"y��%�bjΏ�9
 �)S���ğƙ)g
'No6�DcP':r�E���TH��v�-�~>X�>{u�Q�p�jȰ�}3��#P����)K���BB`��0��I��$�Z�X˽�	���j�卲�^V&�o�	�>�\fO��n�?�J���i��vK6�!�ߛ�/YI&�rd`�ġ1^�L��G���[��vO��$bq�0~ٴ�����v�Y�����.ee��^i�2����գ>Ո�^u/8)]�8H��8���!�PY���GA�ZF��.�q��1@�q�0��/��T"��J<�Y��'��k����ؑ��.�48��: R��M��ݪ,�-�o?�LX���t���0��M�#���.(�� *L},�P2 �t �]�ϭ����db��ܟn��E\��l%�'�m�������x ���i7����'���N��˨C6ŗ��#�Y$[4��fYNЙ�3���9��"!=��+�����++|�y���gs�B��LL�]�o��@��?x¼Y�ZƷ��_|m��,�e����r���3�������~Q)G4��4����Իq�lϏ���:�`����O�	��Pn,�'�i?4Y�H��&�*?χ�H��UN�(�Ǜ�����Gμ(i�٨�^#/�����ó�#����J���8`�!�b"�5��h����^/D ���ܚ#qH�� m+׸4_���Ĥ[�]f K�|w���Yʌl2����n�a����68�B�����zw
g��?�:�OE8u�L^�R�Hk�/�r?���Z�g���o��
��Tj��뫽f螣�P��p��p��U������X�/�_���2u�ˉ�HѠ��b;����#�R�[v�2��T����u��~��\�B�����y���R��D[��]|��8�[�	��CH�q�:	�O���Q����K��>=�۲^6�vL��K!p�yѓ�Q�o�'*���"� `�ق����R+I4��=}�e6�8�r^�h!1�@�h�2�G,���M�����B��>�n�Jʍ��s.*Yk�[&$�ݎ:���8O독��:����4�s
UGҹ��$Kx�Z�����A���V`~S1�a,=�?��X�I`���t�uSj]���i��TO��l� �7�dR{J����_�"}Ky���:_=�:l�ɛ�wP�<W]��ޅ��j�M>�>k�Y5�O�`cC {߽������B��e��,��Z_��غ�V��ܞ�;U�����W��M�\ �1����'Obm��t����PD�02�6���ds��p]	r�8��G>�_�zagic��__�q�7��k���Z0a	?Cx5si��.S�J��q����{���y�(�N���4V�pr�&��R���i ��$f{'n������%:���̺��[�~�0�QC[��	���9�GB��޷躴�0q�	�o�)(�65Pi	13�~��2��]���>0N�ݕ�u��U:�W��Is�Ę��d�&e��0������^��R�����,Q꼁�P��%,�p����ݪ��P<|^r��Z���ڵ ʺ���r�Jώ�;�?�Q��1m̫��ڏ}��:If�%d�1�a�#��f?³�ma�K�l^^��L�sĚ�� v�(aހI��4�
��U�w��'/���BƑ!��r��{��-'>���Q��G�w͇$@'�?����V���?���_O ������ ��	�"��V\.7bP۠J��F9�5����b[�,OhD��wSǲd�T`�B<KGh��7����/+�}UF��,`�Ē������E��bE
����wЃgRu&'��� �5>i�lqTQ��f`"�h�7#Q?��US���)�����<d�տ�n�#�B�)�[�7��DD៓ �zw��+�3"�&� �R��b�O��8���F(;�m�GVW^�������{wE|�V�ȩp�&�,.�V�>�Dw�?Ws�yc�vDǙ;�6oV�H�AGtY����j��i\8~��F#�j0G��DF��L�Ow	�9�.o��漄bw[��M��X�]];,�M��5?2��mq���y�R�z�������V@�/T$��xUK�U���j�ʳ8���'�`�5�_�q���*��=% ��p�O+i�;Bt����ɼ���y_�\1 ڢmAp��Ǹ����f�$����@鴽J�oYF�$��_�/����0SK�[6q~��Z�UɲG ��ޑ��2?���l�Z�r�M6eO�b��mؼ)��¨��v����S,_�T��6��9��r�E)�7AL��52�R0���W
�{�g����w��s��;�c�k��ҾCCҜt>uN�m]R$�1g��e)��dHR�0�!�w�~L��	ˁ��2�bJi7��*�3��b)	�9��ۏX��� �a���s_�EU�p�����n�L�
m�c'��U"��@��}!�ﬁ�*�|�����z@.��V��Zu2��2�+R��2���+Q�k,�6N�2<Jv�uH*�P.o��^�ݿ[xT����ޠ�q֚oɧ� ����jQ�R�Ge�c���J�����`8U� �KKJ��Bf:�[�\4Nq�}=�l��4,�*��lV�a��DgР��U�+U�eњ�To��\*���e�}�<���J��ۗWi��K%`�B$Q&�0[;�ʡj����[�}C�Ԧ����%�"��I ��C�� ��`[�Ga���q���-7V�0�-�'��òg�X)��2b��v����a����[�#�J�N>��ny�	oe�!�^;�s�H���\�MF�o/�0��Mtk`1A��"l������̮-���%�g�ii������8_�a���L����;��T�8fq�U1���8���o�Dy��ܗ���k�h�	^~6%3ܩ(�GSL�6�6Zkm������/̏k�N*����p�˼�-� ً^j�r��=�L��m���@萞��;O�D[C܀�[�T���3~�B���&�P�����2�a}��B�|N��R}�TSk!��ճ�5��睒�d� P)7M��w�8�vDˇc�aLg�Y">?'�MXPF�<QA��8>�c5��@:]�칄{9Q��0�9�!��{v�����/?�JR�ܐ���U��g)�M��3��O�ƨ���R��5� �q�&�4[R ��cz�o�F����o�p�Ku���]w�����I Շ��bu����*����{��26��!0���7�Z%ܡ�k�R�ǂ�:3z��L��T7SN^��ט@Kqۮ�s�p3_�tmL'�7ib��}+
˞˽y��ҁ�<�2/]��3��J7J.:��m�훺a��>߷��~z�C	�=�5����J��Y� �<�/ΆFfB���j�ULs`���U x-4�s����=�fZk|sς~�]\�G���ZC�`T@c#��{��ri��t��g����������WW� �*�p�������O�Q�s�/�Ē�=0��m��x������y�.^���(?����ym~3_�^5��q�#I��������&��kyբ�-��&�?��'�l�� �g��`}�u�3a���d���s�'I�?-�z׈�����8�~�#�B��ݧ��eU�%gE˕�K1�#����5Y-֮B�e;IY�;�)����*՗G#�+�J�_����JE��3��"�����'N�C�ʿ:ǀ���Tљ�@�ꨢj��=��5�6����Q�8U3��M2��y��'�"*7]Q<��?�U�.�:�&��[;��;�)��+��#�_�f���'m"h���+:�9��($;(�	�ӗ!�U.��j���a��m���b�'#-r��B&iP�C�C+H(~��[��܄��l$��r�/���%������a}��s	�#�LQϯ�j��c�>GA�����w3E�9_��:c�*B��T@�Wߩ
�� �i�%�#`-.T&x��%���}�OB�~�H�qf��I4 y�羘%����+�
��-�$�Z���+�~��F�=���԰Hd�ъ���������X�m���=o��8-���F�[��<�c�6�@۲��%WR$l��{G�%�'y���pņ�qC�����Q5�q�C[Đ�$K�UJ:�F1O�T�B��Q��3]��1h�/4P�o���D��NB�r����wnVg�f��⩊�t�.��G�V'�/e�q�CP�=�ΡV�J��ɘF}�4�G�ΠMwLV��>���?�h��E"�����/Hp�G{��\_k�²�(j��E���T�W�g֪��������L.|is���B1{�a��?o�*�L�����.}�'������8�6����`|�����Ռ~�?���<�[���h�vW?y@-$S��/��r��H̩:M<Z�Dh[���	y������H�+	lFD��c;˯�k_��sk�[_A���������գ\^u�=��m��d )�F�>ʲ�����,��Xj4� ǋ>6�!�CM��`��+`�_y��m�P�l���v>�����I���j(�<��yӻ���lB3�L_��W(�1Q=�p��@9����?e�Ŭ��La@l�l>�3����?N�w!L����$ס�K�0LF�"'|�L�Qԩ�]{�G�U%���l����Ls��!A�"�./�%��kP��\Dns��L��U��O����1�1�O��Əҿ)Y���o2!����fY�JF�:�p�a\ ��y6�[R��a������I��a,Ǖ�œ�q'��5�)W�����(�M��6����OARk��`�f=�ս(�&5��>1�M�Æ���	�A�-j���'�2����0���.��;̣@�B�9N��,=*	$vH�r��vM1�ݔ��	�I#3VG|�n�H�#M��E9����V�3		*WA2�TƹNq;�k�VhrC�-�z5�C�*�(S5ό-[�(N#�XWb�N���d}�ؠ��2��/�i�ԩ/2�r�R	gS�����nq#���9~2S>��!�W{� ��� �v�k�H6��Ơ7�h����Uy���0���s~��~���9���R�C*����6{P�ۥ
=&�g�p���M8X\��&�!�>	��[�(k�f*4��\i�;�]�+�{˚7Q�Ѩ�;p��[�?���V�� +�>'af�i�����M��±��]8B�c���+�'V���Q�ߌw��F &%��rް�@<�ش�q��t���C����]�8�#� @��F������|� ���6�;ArP$���Z�gq�+��y�h=����^�G�l�"n�=�UJ@��V�|��w���c�����
�o��`���`�"4����?��;)洖��쮺�?�e�F����
�M�՟K��	�{Ve�_��[��MͷZH?/�8{��?؁��\s��e�c���;3�j��R9"��u��`�m�+[�)���~84�:��`!�}|oʓ�6�_� S%?����J��@����)\B�~�������-cJ�b<M.��ܲ%���㫎� Tg�b�7�ć�_�������;�����ʑ��b��d�ﬡ�3~�n��{bݾ&_)�?f=�A�D(Y-��OQ|y�+�jz1���W��䣸+\M����>�<X͒�{��qI��'d�DH�~�}5���G�l�N+��GbOF?��5x�H���ԙ �]�(�:-b/-j)��2����hF��*��)E��ZH����ZA�#�7�l+ay����@v�g9�#jD:`"2Z����{�ϯ�<���*���gPQi�'��ux��0B����*r
\!Ban����4Ѧ�b�dz�,�]���������liF��N�X�Qi�{R��~���0�����n]��g=!`B�)K�����eW�4�/:��.f�	Wo��pa}J��?��>l5M����x��2�"]z�v��w��Ds�$��k�P0#q1�W���^U��:�ڠ�si˻^pݽ����)���D"n���v9�F2�hfU��j�ħ;vs�M$�f��.q�%���硟��M��C�X�Gj
�p�qi:0��� @p���+�� 6�$>�k�d������6��LP�6�ʶ��A��X��쑟�x����+%W��.�okA��a&���2z_�̏%��_��*�Z�b��܄�&�?��G�r�6�� �2w,+��FH���N������I�&��w�"lg�$�l�M���'���
1�R�=�����	>��}8������E� k%���B��a�%��N�O��60�����Ǎ��N�p�>�Qt79�	�܏< �~0N��w>V׻����)�O{8G�y�;�Ϥ*N5>�R3���>��T����Z���L�˻<U��>�.�)4�Ƅ���0�t����p~�j��'�Z�Z�ae�0�$��E�v���W����TQ
�H-��Kg�X��)�@��2gx�i���Ko����8�Z�h�X��F u��!�P�MÓ�?S��B�c��~_��O-�5���蚺�"[f����Y*"�L�J����&[H`����h��QMJcw�L���vFc�8������}�����3����Y3�k��?�H����FpT/�RG��7��mO>V��;�9=<\�66-���IÎ�M��Vg���t�}�}��gM����]r�`��y�P��0Q��*I��_ӂz:����U��F��E��aW'���	������R�5�;C��7Z 3�+���N�q5T�R۪5��%
.d@&}�z�����k(��<3�:�+xVw2�򁌎��!�q�'5mv}K�d+��Ef�\�1Z�Z�ø�7�u��6	�7TH��Is��m�,�d�����f�8��P��|��qY����k�d�����g�#��`���g�F���%q!����x��_�|���ghU��� 2|!���P�E�f���L��W�F�?�[�����y[�$qE�M&��EOn^#�s�&ú75U��p!���}x��,T�G���e�m#I�W�ON"@s"�Tc`���n^@wswEӶ_2�߰��_�-��m�
�?���C�nJBi;�]6<@.�+I���O�X�i�B�cq�:pe�&�Q�N��Ʈ{��^Bzs ܶd���=UmQn�Ӎ:������.(�~�ވU	�;U��Z�(�?�tZ�s�����y��zE�~Y�����kQlZ���)韀�pOI*�:ξ����33����-f�y�Z��S��ĝ#KkSTu�y�����k�Κ�jfu[?� �ȣ�~�PN�F�K��U�FN�;�h.'+���~A�r�F������q��k]_���L"�����5��L��vJk���DB�!2�z�qaX*�X�j^�>0O�|>T�>f'�J��x���R��cV�X��H��I�_c*V��G��ԏE�H���� ٓ�|l� �`�S�[W�QJ�ðİI�BD+��;��s�����v���7ax�y��2��I�kA��ؒ#�����S�)tATgs�������|����d��o�X�Vz��~�+��L.�AX=Ɖm�k�ш�4��L�Q��5,%�j~CA�z�{J?���2h6A��w�B�y�X0�,�Me;%a�0��>+z@E�Q���(M��/�;��u(Z��"�����&3 �"����9;+㩙��kK�t�6��'ߌ&}+��'4YR����W��h��W�T�%@�W*w�Ā�%�:?�!l�a���8�ˈ[�X���1��s�𤽸�:>ّR��� k��{��,�hT7�3�=�*���F@�ރ]�RA�U!,��q7@m2�c���3�vu����� �H����ܶ��0!;O�|�9��K}Fe�)�?�����'�(��F9�W�5����<�
ꇒ14������Q��;e��!a�
�MS��m���[`�̔ԟ�B�:��oP�<��^�/�r��#�K4��E1rS�U�)�`�r|���O��2�@Z']�jJ�%��Vr�S�_GW��H�qԃ$Ԣ豧jCB@�����.�K��M����jܤ�\�&Xu$і5$h�lkSaD]���^u���Л�Qq��9��aLE!�M�jR�&�|�V'��Nl'�L�6�0�iyC�~qL��N<S7GG�yu-���:ۀ�{|kh��/�L�g�c��F���m1�|�f�M��i�_C�ڮq�OXKȝ��s`m�;D�{.�ӥ/����1��vI�;'K#�	�g͵���
ķ|ߠ�̈3�Oڶ��*Z%���m��C�����A�t��;"U��ԃ��d+X�j�����4�F������?�)�ı�'�i=d�Đ7�+-\�!�GT��"��1�5��f@c���}�\���c���Pn��D���G<��-d ��Mؓl�l��!���}z|{*�)�EQ���ڵ_HX)���_��у�UF���F�	�b�A�C�{P��a�2C����)��N�E�.�a�'�5L4w�w�hZ<�����h����c�	,�m�:�KS[r̢PGu���:��,�ɖ��g��[�l>ak�
��T���ϺAǂ3ZNA���	����J4�Kΰ%���C=���k��6k��Ost����3����G��R�I��!�󈅓ɲ�XԘ��)�����rvRl�5òC�y)@k�G�L�lI�\d�5b1�&���k��}���LK�F�;�\�Ax��r�q���3])K ����ԑd0q>��Y<�!�5��	���W(p�b�`j��4��b-��>� �i2���ʀ�z@;V	�$,uE����}e�F N��ߊ�)�%�ƛ�0Tp���4���(!�
��em3���0�Fg�`��g��Lxۙ�f�s���z��Xc��g	�(�H\7�,�u?4{B����+��2(�ؼV�Q�0���(/?�f>i��_��R�5�!W��(��Q�H���p�R5��Ƥ�g_��^WUӺ��X�рA?�0*�4��aNF���������E� Fw��v�s�S���F���M-�x�65D�$b54��ТOi����d0#�A�&��"�]����S�y����+�2<u�C�!����¾��B��0H�qN�֠�	�Os�㽩���^B�K��ℌ����q]J�Cjb���P�J��+{����H)��� �~E�'M��x���@���j�_;����;{��Yk�o�7�FO_�x��
O��:�8����f*�,�	0�d=O�C�)����oF�7!�7��Xv�+�7�/{gB{���Lu�o�c���o������~�mΗߖ�L���^.���f���}v&��oz�BD��Ϣv��`�,`�2��3�0�ۆ�4�&Q��w+ԩj�&�Qf���>;��~v���Ëح���\S�K��u(h���r{k���(G[e�%Btk�4:�H���'����RoC<ڨ��/�|U�],����-��t!U��^�L��~S^�� �x�17�ei�W��S�
�L���9�;!�΅Y��w�V���\V"���y����?�
��%w����2���Of�^� ��u� ���z� w��L�|���'"����0�f�vB��:���C�CJ�@�C�ذu�Ĳ��)�+��9�\?>�j�fYc��ٗ�8qL�-It��Vu�B�
�M�\�	�V!O�9^�$=����#����L$���W����U?#�|�l��KhyX@d�|5�||*s�I�
.c4���L�4�4���	�im5���]�o�y��g�w'x^/�/�-��t9)9@}�'9����祄^:����Ds�~b~�F3?����;B��� -ǣ=Qih�U��Z���,��U�^-�u-�)X
�4w�gȞ���y5>����Rc�0���+x<�?0����Z�{�(r�&���W���k�s�pXȅ��H X)�!x@���b"������sa��Q�	I��9��l�	\��ʝ������$ ��}���B�u�B�ֱ;".��Z0^؄ri�$H	k�!+ �B4h�Z/���n����-i��~6�+�1;k���M�n�pvg.��0����0B0bO���f��.�F����,�)�&8����തq��=��K/��v*ҕd ̪A.Jr�w%@�3eu�x�N�H��c�B���X�y�S�EH|�:D��݃;�P-~D�["�4�'��#��
����ҫbO0,��Ք��q�;���HuE/P-/��y��C�7絢�b���eJ	��'5<��)6}�6�)��1�Г��V����|��0�#H�H�CN�7)�e@�˿�
d�fٜX����,#�@u~+ʦ��Lf�z8+QH`��7����.,ʰ���sc��v�$89ވA�"�Ua�h��f
/gA;6P*�k��]u�'e������z^��V��VcǞ`9̇U�:����2���d��-�0�W)$� �ZKkǔ�$�U�'�w-�H��T��vg��Lv��g�����a��$[�I��35��7蒎�Z��Co;Z���g)C
�?]NC���0Nb8n(�H_:�fƙ.~G!�o<��	ƪKy�I�:���Ny��趻Ѡh�������!1���3 |��_T;"a{��(�g����,шqV�o�o�pԀ�*�®u��0h�3��o��(nk�j,��s��a@X�0|dP����Ƕ5�]���~8���`�^ke�p����1�����}E/�"�	{'�Ӂۖ���j���� w^
sȯ���DE���}�sg"�wQ��� 6����t�Xn�oi�v�l9�������E'�?�n��1��A=,T?$��M�ώ����}���O5��G��c���B��0����Pa��8�1�YDU4I�! ���������J3�Z���s8�.�L}��j��jh��-LA^L�9<e��k�E����P��Dl�hg9�1�|����8��<���uJ8�D� �/�T��+�;Cz���Le�Jk���,��ގ��8G�N�⾖��;�E�h�.!,�*հ�	c��:�t�e;4�"2YǦ.�P042d̑1i�m��ԦO�,�?�H�����v�D���}�E�ٿ��__����_2}��s�����T�"�H3̯��X6��X$�U��$FS]���\!Fe��G��D�%�}MfwWo�&uY|d�!��r���I4Q�!>Pp�D�_F��T�)"���6��,bInjo0��͢jd�!VI0(B�JR��4qhHP��_Yf�u�Rwl���\ݑ�sL����m�Rʭ�'l��Z�V�[�`0�7��ʲ�G�2.�A�lݏ�e梓���_�-g�Ö������o,�=8{�'��h�� ���=SnĘ:�V�r��ԁ�ݍ+Fdlq�s���?DR�Z����_�u�w#���d�}����#�4����:�ے5��}�m��+���Y4 ��܋]GHU`�/Cbl��H��m�l?�U�(���cK|�����������`Mfw�˘�zY�Y��!X�%J�_.����m���K�]}4HV���$��9S}�1(�F.��s�3P��eU���خ�*M�u�Qʮݷ� 3ͨ�掉 �����Vb��g�    YZ