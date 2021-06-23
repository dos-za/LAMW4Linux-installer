#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1584554990"
MD5="06f5b4474da9589fce7e1ebf67fdec18"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22968"
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
	echo Date of packaging: Wed Jun 23 00:35:04 -03 2021
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
�7zXZ  �ִF !   �X����Yw] �}��1Dd]����P�t�D�r�@M��w��`P+��	�d�]ZQP־�sVMH�w���	fO�qꈽ����q��3����U?��'ج�7dG�-ݍ����\R</CPSf'[N�(�І���B��cU���F3p���;��֠��+�P$aB9����"e_{\�������ݢ1X��E�ǭ5~������f=��u��+�T#�(kWc&{�:��߉ejҾ-��+i�8/��ġ��L��P���gkp��5�{��ԘQ�������Sv�sf�\�}m�_�{�.�D5η�bL���_$C�Cç"F��l�ɑ����~�9��AzH�M�0I�������%z
6�B��D�sPD�a�\�nҶ����md�v\=q��8�ifk\�U<)H�����d�!��0�G�Gj�%,Tr�ᾄ��(1�A�@�FO_����V}$�
f8�D����8�%�`���)����_�Sw�Ǣ�M��Y*+�t�)�nWS��1�>�`�R���ˀNwd�Ė�Ի�`���~�4S�"�,��i�|��X�
��t�RK
��W�talX�P}4��뾉�	#��/��6�1pKj����q�a�d�yh�M�C-+�M	��$$=�l��նf����F����k���t��sW���J�I����kr�n<�fR�������3�c�^k�5�������C�?u���&%h����o`'ݐ4u�^ i��\iS�|�-�B�n,c�H K�6��r�����p͚ `o�Aj jn������G�$2���,>�l��5Eu|���	�E6�8�n���Zo>4D4hj�g8B,@=c�|t������0���C9���j�o�99�}ej�_���þ�k�Y�*�xi]߃IVk�ñ��bh��r;w�/t�:�+�B�Q;fƨ��K�"� ��Q*�WHK!��;}7P�|�l� [5eȧ{ O�e�P��ŀY�&V�yӌ"X��#���>'�9����	.	���տh���.��� (�t��UBA=4wWs�����\���XbΩ1��ݞC����",_��]�ŧ��z�lh�Y�0J���z���<�]���~딄0�^�HwY|GM6�����)1�� M�z[E��v��p�-�([Ϗ�����f�~�%��%���Q� �d��"j���87Tu�>�H@"�d6��k�f�4����77P�b��q��E��]�(F��MK��Wj�U��L!����V�Z�(��u�w� 4[LU��P��d��Ձ��n��N�Ⱥ�u'�ry/���;x+�qy��~~`�֏ʬ�������7��N��և����ڐׂ��Qj��R�)r.�.A��cQu��E˪\(>��2��[{GC*̻�N�Fʷz�O�L�]��M��tk��m�Cru	�? �j�@�^L@�[��TI�0l������&k9�<�rK�`�B$Jf����4����#xˉj2x�H��9 ��H�KIy֨ݸ�;��2�ݜ�y�/��m�j��fZyi0�+K��5���KJ��D�����\_�/l�[�GW�ɫ<�:U$��_� ��4���5Y��9H�i�NE �H�u��'Z�S't��̲<�s��hG����ځ��)p�=�$Z�O2����0Y���"7��̪�_�Rm%{�\��I�t~��=Z�@��,�~�KPCa�l���6��U�5�l�l^.��K�ω7���C9���i]C�jm%L2$�5,��P�~�T���rs�cd���|df�JA#ޑ盍{����A�#{t������J��b�>����?ٮ�[R�7rљd� ����WQZY�`�b���Ӏ���_
%����>�� �̣4z]N�'d��0L�������s:��-{Q9�{07�G�V���?�f�T#�>m����PUY�9�T�Li�k��-��beĚu��}m�*��#@
��gA�s��c�6^5(-��6ɜTT�I�\ ��<]�����D�t���u�
��JOԿ!pd�o�Ϥo����=��5r�O@)��NWs��a{n�ݬ�_��WwtR+Ky�3A�y��Z���7�pa2>�u{�u�~j���6��}E�LDBHH�o%�&�/���(X��$ȕ<�¶���}��k�O�y_ƥ�s�E��[�����1�!>���[��n*�ƿc"�~HҐ����o� �&���֢�����O��}t���*[�D��~S��~���f�ٍ�%�����t�Ӫ�%.�)q��+_ .$a��@�;G̛����\�jS�K���^�!�� �̰��r�E�e&R,�Qe礓��1/�6����W��',܄�����yHi���棚�r�
�/Q����h�0o�sF�]�}�yI/9�� �k$�,� 2(����#r.�f�cQ��H~)P����!03_����S�i�i���}���:���!�8�4ʂJ�o��P0~�+ķC�0�WȮDW���c�x��2NE�Y�0Y8���S�eQ����ܴnEf��_�r����x~��Y�s���8�W$H��� _kЀ�����N� I�z�<�B��l?����z�J��<W���0�<T��^��g� ��Q��i��Rn�Y�Y-G��nA��b�k3w뎇��↬�!�}�󋀯EH
��A�g����mJ����<��~?�\fx���4V^��Р�	��!�
���si�����2����읷t;�YQ�ү�5�J��pNʣ��#���:�Ә�ѫ4�)���ܭ��ބRz��.��C�"���&S��*�W-~�FPB�!�7m�+�JqU'j����	�l�R���Mi��nӶ���2�կ΍��}�Ƶ�J�4��,��Fn��N�A�=��a��Lp�fC_�1
��`<�͛�wA�>��m����6/�m��S���$+�� sU��}M��u-=��f��R^7*u#��KC��l��phc���Ln���n�p݇���^�c�󋢗EcM��v���G��AX���!���<7ǔ'��ɤlx��j���K��e�*��
b������o7L�Ҩhv��%�[oS.3�Q��$=��gɈ�5%vs��N^�@�4a�&jv}���!I��Be����2Afn�m�W��hi�|m���f| z��s��Է��P��)Ѹ]��%;NQ����
Mo��;SUj��� d��cx}��F�	bXU�\\t�S������~�ց�,󦛉���W��D��7`�,�ju�m����qQΖ��s<S�\��p���>!1�}*�[g�v��C���83��I��}֠�l���] ���L���,������+ey4�����>Si�V�b�;�aZ�05�"8�j�B�!۫ȇ=
w`�.}#��T�ŗ}�B��F���J�Z�ɠv76	�ØT<^�C��[Q��I/���� #�y�"��F���{`��G�&8�tL�-7�!b,g�ު3e	T݌���]�qt<̑u�+R�)�[������")������X"��<R���#�B2V_��QaN�p	�{���_=�>��|+	~UE&�H ���^0t�K�d��8O(�|f�����ŎÚ�5 �f�PΗ�\���� 0��l�����;?���]� ��ws����"��4PwF�RTRRB���)�D4�8'3-~~v>b0^�PG����y}'i�1�u)V���^�hC��|5l
��ҿ������Cx����9B��zj�.��%��7��iӓ+G�42�I{�M�'ų'�a�Xx�U2�;�D�-�F؂s7D�t=��K}�R��d&�}�6�׬�9��,Wn�d���c�s�K(�K���.la읁��������+�'�5.HaA�!�j��T �^��ɗ�5qXk�9P�ۛ� �Nlh(�8�\��Z����Q>�����qg"��7��w4꾘g���gY��U~Ɯ�0.�֗ha��re�ET��~��M������Haż�9�}��&d�!"��w�}}�p�	44���?�!FO��jW��L頷ظ�����I���k}� �fXM"T�B,]ԯ5Vj!M�H-7���s�t/7���	�kwf�2��iw��4���ٓ�/��#�W_vd�34�Y�����y����9�s��M�`\{Mܻ���GB�u���v'�Ԗ�*�ǎ:};2x}��_A�6e�	�K�����z�o�x�3�3�D��m]�"�QENI�2]FF�=1�Og0F\u��b@��Y>	��o˕è��|��ڟNu����'쐜sz�މս�ڢ����n14�n���Hh�S ��
�c������|� �r�wH����n'�b�T��3�0�Bz*��Ô䧙���$�:�z��T����HXU�g�,�*�}XA��ޯ��%�=NjAf?g㿧��]������|W�Ly��w��jNKo|�s�49r)7�vMM�3M훚G���!{��VD���(Ʒp��Ӯ�  N2�x!${#X2�w�]�r�߉f	�ʺDY�51�F׼��N�'#��}^hpf���g?����PY�V�=�S��w{ �!�!Z@�2���-@��Q�9�)U<�*:�x�����"2�ѾW
tU���AU�B@ێ�1����W�5a�(�����(J�dm������m��?PS,>�w��P.��E-�U�E�Oy� 	���&��\���b�A?��,x䚝�b��dz�L��H���o�	i�Vm������cQ����E[�}�a�`���f�� �1���M��w{�CmȽ��N�P|�*>���K:��n�v���:&���/���Wa�z�����K's7��S��q��X}�p��4Y��-��$#ٟ�5�N^���R�o�^�<�"�b�n�4~G��)��regtn+�`������?��h�u�LE��`�)q�Q��������Ҿ.��V����̰�NA8���B�V�o�)ɛ�	?d���g%sK�V�*�(��>�I���P�7"�����փw4�_�	���U��Jm
z�Ƌ�z�4e�-�(.��&�����:(�	�����T�Af�f��
°
I�V,k��)Q*y�Y�eU'��	�s��0�
{�O�λ`���ݝ�g�<�}Ė?����a�K�1�W\j.5��X�9��BV�j���ۏ[��9�����F����얘;du����,���w-C6�KD_�����0� �o�/@N�U Z#�S�]�ۙ�Kr��J`�Y��{5��WL�H4��t�L��k `��{����A��|g��1}
ep������5���q����� Qb�80�#�L"3�x�?�k'�A��#����@����쳉�G���i�
���Ff��i�{�pj'k�Wf�Pv=��(�VI{�x�PGE��V��g�!����g΅bD����]� w�����*W�0��5�"�K�Q���I��>q�����ê��:�~�G�˛-��$���êf^;#�>����Й�+K/���}HQ�<���	o�*�C�<�oT�a���z F��@����P;����`&uf̌m՚�7�r�l�Q�m1��1#��1�$�Q����J4� 
:p+ 올N��3d�q�VRf�@�����O9�@^Fue���<*qH�w3¯�~[�s�4猜i�>��WŐ�36�]��y���%�E�5��.@��j���2
w��g�k^\E�M��k�h����OAɑ�
�b�f����HX`��B���������#`9����^��f��Y#���h�z��8~H��P����{ڎ���S��� �L���Y�_F�ૠ��e�_%��B�S�Ϛo�'��mҷ�h�~I/�a=�)oȆ�%���F��^Һ�������D��Z��R��6��R�\Z<�O��{a	�e����{�Ogph���(�_rL�{s��̂�C7z�.r�+�	Dg�s���D���&�G�[c��,���8���dd�l��7Q������?S]8�w=��Lq�Y��	��;�T�k���#��+����R��.����}gRyv锫y��AJ0����dM�M��V�
�1�RUh)��u�{�p�Z�~�n���3ƍH�^@$M�]ċ�rJ��^�R�\���M��o���Ӓ{� �Y��R-w�m��L�hƱ���x��6�m�����Q;�)����\R6�;um��9�QVT8�.Gb+��cD��]/���%��`�~�qd��96L;\�J��t&,f�iG��V�����'���x�K��=���֠���������F��m\9��@������*������}���l�vb[#u�;���vk�KgԌ�%>�ˉtiu�@ۘ��u���	w�@�
�k:-MyJ5j��	��H?���3��O����	�0��Z偯�T��4F������V�!	�Hnx���껱��>K��}ck+*���J�E��޻���'�O�
�֒�o����鋄2���s��&(����d�1?�r&-�;�2�]a17����gOxl|����I�e�������9q#xeS�nDU��k5���VXã[k
r��/m �j�{f�#��l=���W�k��Rq�w�@W�D�:R/H�X
UF�DثZ����Z�ΐ��q�$L�ߙ�{1)�q�-Ƀv���|^��u��aY>����s��`��`l����U���0�>��[%��d��x�G4?`���}yc-����K�ƬV*�w�i���}�w'�E֝Te�C�(�)]�p�U�KPD3�S�	X�ntޭ&�PD$��B7�n�����)��	Yb;���$3���_�,��hZ�{Ӗ-�ڶ�_��F�C�yP�J���}�~�9�Z\��Oi�<N �ZYf�d5�I�;��,�\�5�"(��N�n�Q �%g���������!����}�A��L�k2���_ǰ�5Z�(�Z��fQ���OU��;r�a\\6� -��E6j�S�m\+�M�	%�s<֡ &�k���3�&b3�>���NQ��Zhiч`���#�d�������@*���1��w��N���v�Έ�E�BW�\�ܡ�~WVs���i�f�� �aL�Lʖ0T�`�׃/�t��
�
T�p�.ƥ�X��W��_��k��oX,C��t	�?-��:߷Z�(׽]iK}���	#�H����l'�ͦ?��)���#�{C��:7Y�'���E�OgT�s��ϝ�؃x�����r�����.'�L3���.�dɴt�ED]�+�`!��ƒ5}��Ep�&D�<&�J<(˩��g(�z5��4�b �?^�����q�%��Տ���aQ�Eg�up�a�0�
��,1ε�2������V��ޡ��������~����m�����-��㮤����4�����c�x��� ?k�/�2�_τ���z�2�1�ޤh�
M�um֜ 1��� �����ٲ� �<u�B<�k�05�~?��t\|�\������3)���X2����=�g148��&r�"��H�AbE�I�Z����'��xi�U��k�vlU��u~�P����[�Sv�C�[����- c�:�'��~�ʸn����<=����M�<����F]�q���F���v�����r��	�>��q��̓��N��UFǰQ��#��V�K�nS��®�b��x Gt�c�{
�g�YMS,��-�J��<gq���_+)*l�g�T���n�;��:�-�=���k,����fX����Z����+�mzݸ��|�'Vh���80T���?�#(P��p(@�\=��A�>����W�6���D(�0�����l�oX,H�K���6�ކ�&�yT@?p��O���5�hQ��X��ف�a�I�F�(��l�D��GEڋ��Q|���̵��)���c����+�P:8A&�,����ze�X�(��������kf���hp�1�A��D����/��Q7���غ(�HR]%������n�(qs�F$G	���JeP�%Kn#S�d�WV�1W��(/2Hp��5�!�ϯ���Dr1P�}qf�v�]���-���ӈ�:��w���V)r���߰��S�:�`�� �-���%���k.r�ga����Y�[���굤��tcNҭ5�$���}Y�L���&�3��w8�D�	����ldF�x�~vT����_�Ԝ[�p����㻏,�ع^5�mw��7Y"�0��޳Gd\�c�e3�lL�n������;Iwo��)�n���!k"s�[��fc�4N��ar��}��rU�Z�S�+m#{����H"iJ����=h����Q�	p�4;�Ns�bn�N0�Ѓ�Z-`��B�����'VW��c�Z���pV�� F���Ȣ�������
����4Jo��D��L��*����$�8g�>�-�Lp/ޫ_�i�{k}�=F���2ڽ�gJ�����=�jܸ8�����Ѧacv>��?j}R�?֕����Cx�	�"0�]�2F�hF3�7�`?R*
�?�Hh�"1���60�a�HK1���ra -2��R� mb�N���<�ᘶ�X��_��.���J�5�v��Pym�����������5+b*A�nxY
��N�#ͼ�ɥ@-�I�j���ʦ�����<��B!�S��O�6
@i�'���@�AX���{`��D+�j�K�agG��ج��+v�^z������`9I�/�_r�+(.�Jö5CV9�v�D^�$O`�<�+�hN���9`0^��u~��z�������g9x��[�����w{#t�b��K��xZN��<9��H4�bm�%ڂlc�3 �Q���HV)V�頇D�s>��7ŀ�S��/݄EK����zn-B_�A�m��GZK���	.<71`�/�4)���т����3�v�{�=��/�D<6�M�l���}\�|K\K2�?��!���u�l���c+]��udSvaWӷ��<9��0�2թ�Pv������}����I�=k���.`�*���ͫ��cH�,���{���M}k�7��aP{�8��~͠�4�ӛy�eaΆ��Z+Ѿ�>*�S���1!%(% G����m��"x1ɩ�hT�E�$�\~G�/���Y�-�qa�\�j �}ᥱ�Q��&�p�����_�����FbdO�b��ɉ�)�ťTX#U�4Ϳ���A�w��'a���aa��G(�'�s5P�Ko�	�w���@��z�cN)Ql�n��?,�m�d��q�x� �EE�#�\#ƨ�G)k��� �q�`�s�/%QQN�8�ћ�����W�،𦿞(X�䱠��-?+�_F��+�te"ݢ����t���s�E����P�u�t7�8��ҧ)߽A�O�@�iW����KX|)c;}������1�pY9~P~��W���A������Q	�wݩ�P��S�� a���T�
�0R�������`4��H.���{���*E��Q�9J�*��V���ف�I��"W�5��B*��念Oe�F�*<X)K�7қ�ӣ]R�C���&���ˀ���\�נ*�6�sL��˙Ā2���<8~G3�3�w�3�;��D�{�Vt�O�q��$Y���T�_���0�!?3O��HRG}<������9�^d�O�ܥ���y�.�{�(#�4�Ϛ����y�l��K�?��"l�Mԣ#*D��t�i�0h<J�}mD���:Ё�E8�w_�!�[�T�;�x�{����X	�Y��r.���31��^�#N;jK���-6ǯ�� �ꌦ��ӎD�@'�1V�l)�7Կ��G��#p���9����3�U�=3$f�^C2����\�rT0���Q0Og�JS�V�M�Z���5��k��jS�P9�ܨ9+0!JZ0��Ⲓ�jK��itL�J��x��E4j_�oy{�b#�=G�)���2�,�u����T�Kt��1�}}W(Z��F#�0`���B�Я݁{�M��Y6�9;F
|��SjUC�#�j*�c{�&��om���J��t��\��E�T	�h�/���p�$M���Ȕ�:����4�}j���0�#���<��QuB���6��� ��L�f�r/�Y;�{�8y�"/Hv��Rط6�@9�O��2|����xG���1��:��
��C���hf3p)iG�&kȪ�˟�:��v�1r>Oй�:;�k����� B�΀�6#˗D%��%�"��V����:6����^������֔�00�}���_g�p��m�s��� �Y��rk�$�fآ^F�e�����䙣��z�FG!"hM���*D�q~EB��y����y�����/�	����JX�A��Q�:�O���1\4�L��8O�}l��6��}N�Go���)�E/��8+�{^�D Q��%>ήHY��
Wo2�4�ޠ��f"|�l���X�ܔ��m���q2NT��2����ttF��n]�<�k��k���Ta�����\�s��*��K�w��w��C��2�R��^���/H>ɝ�������'�7��nHMC�җ�-GZe�{�b�Q��ٟ-(���n�WH[I99ކ��spBqk��_���#��L���󭌆����&_.�3��x�j�Q�ǜW(�x� �T�
s�`�͚c�` ߈�s����a�J��~�bE�	� ����8��I�&8�Ջ?�$h'��'/�d�&'ε:�����b�n9u��u�p�on����j𣕵�DuX��q"_���鰂���AK3��@�1E�`k'g��e��t/c����*���=��9���h�4�n45�[��*w�(�
dF��ovP�%	�OP���m_�L\��\H�#Y]���Ŀ/1Xgv��`��`-��{e�n�rLWh�@�^��Dv]-@G������	X���������<�qsȿ�N�@n������ݾ-x�L�����%>��c8 ��z��g?���)zJ��i�l���$|��-=@���������h;�c�`�����0�z�c��>�j��W�d�s���2��HT�Ӫ3zY_[1ip$=��8���AC�"�i���L���Z�+��.��ug���y��*�i�W�J�k�qL*-��.�� ����oV�,#�I��NL��;f��Z+�{g�{�Z�k�6��s���2�:����e��}��:���z{����y V���G��f�&�_�H���-v����0%>I2�u`B�2Q)���1f3TG�:�S;A�^�D�5A<�����.w2:���!��ѪZ*�JLE;�����ێ�ɹ�V(��=5퀗~��s��Oȁ�u��=JN�Nu���ݰ�u�glo���#����p�HD�='��ٙQdi�,�.ֱ�C@��xD���n=	_7�'|�(8d,�"����0��]h�2��Ǥ걎�i��ۻ3�a��w��T�?���G���n�"���5�z|Ae�	�7W���PH�O���y(�e��"�ѵ�l�ܳ��W�|T����5�;�8wS�*�Mxt�C�B�ʎ�m�1�j)J$m�Z[`wǫ�|�p�_b�\��#�)U���Ԕl�>�U��O��ac�v^*�ʒ�:C�]�д TM�*�x��H(MfIS���f��Y��.	Yu1|J���K��?8b��D!c��D���:��X�E�XD������<͌��m��[|m���Rs��r�Æ_L�N^�W����=w����q�AQ����XD�HU��\��<-k|�N��V$��f�2�ɢ���c~�+��
�[��u6?��!.P�)�I�~����S4��?���ő �"�j��Tg� -����4���J��C�{wԷ�V����jj��O�b\�����<@#�|��L$@o֭f8���]��{����X�Q&��i�d��@,��=l�C[��x3�� ��̛E�螢��H%��`��HY4R��4�s��w���)T9�vH˥��gF�{�-�����C��#�A<H	#FT��#��N��n�/Y�=�;�(w]",��D ��XB#+�9�0�F4����۟z5���Րࢗ�����am�9H18�~2`=4E���T(�ie�ȶ[�7�}0�e�)b���ڊB�a�b��`�- g��*\5��
�p9a@�g��m)����̂�;����j��nQ0^z�o��?Š*{7>��v�.�tƘ�X�7]�"�N�p2m�_3dV�u�ip'�%8�ôʋ�Bߚ�4��5g��O7&�'<v��1�P���t�n$����c��{l���
�����{wX�:�m�l����s�A����g ����R�nڃ\���l�	7�B?�z\U�c!W�^w����bq�7�4�B��8���--��6�W'%A�K��Fk�<���C��Y�]�ހ�އ�dyx�q~���l��Q�\NM�����4!òvU��
���i�y��`eX���i?A�G@e� �Ƅ)S�]� 1��-f Y��z�^�1�iD��ͫZs��38�|����}��¾��q�db3߷6��{�u�P���2����N�����G�9���ۤ�f(I�����M��^�d7����X5~}�ާ�w�@�a^ձ~ߣ��a�Ux���GߕP����T��Ȱ���ѪE��M	^��jH�+� �}����u8<�t�Ԏ�{e�+
���\�0�������3P4C��Q<��1�CD��>j�nz`�8Zji�A��+�K�0a��d���̗���Ʀ�b�]K{�h�q��I����4<o
!�j0�`�u�m�=���m�Q��+f�K�n-�ʍz�ɅKpp�s�=�}���66��.)Š�ǡw
p��0�����Ai�kͱn9��N	��j�����c�� 離kW�Zm=MȦ��X���`:Zq鑗:�nd�������`���G(I�:�������`Ѡ�� �o��n�����#6k x��7�d�Cn9:���%�[�͚�j���m2[����K-��/tէ~�~>�Bƽ�|��Ը�g�*f����Ŋ��S����#ǲ�Y��ITk�P���EitD���$D�1h��{nJ���D�G�����
�\������*�����K�N���Y�O��n|/ 8��~� c}�yZ����ԗ�6�$�L5q]g����v��z])'M�OH�[�уI�+�����#�p�5��d�6��#���hv�.���"G׮'�<fl�ԃ|��:�5t�qψЙ���OGt�t�f���&�ÿz1d�]��}��#���t�yw|�V���pj<T���Rh{�z>����*�8�r���(�����Y#��r>�Rh�A�ߎLШeU�_���V6��a`��~�����=�V�l�\!-���:��>��o���I3���y���.i���|ܾ�Hڧ�h�en��R|���h0jP!w&���g%ֲ2W��J˽|���U���Ń}�K>���r=d����w��8֪���A6�p�����?F3sC�N���r��+����d`S�ןU)"�7.��������5�V���$>�*1��C�L?����Ѹ�ѳ�h� �g�d�;���@O�7n>'<��z�u�#�xѓK��Z�1�oރM��7U'�eˎv�R����	
H?��X3l����~�5��l�
���Q���z;Ə|>����.�Dd�hc�1]�C���+�d���(�������5�v&��^���G��|�e���𼍓�4��1QVH��r�H��"5��8��	(u�~M�G��h��n��}T_{�&�Δ8����ùs6Tn��G���1���D_% ��b�G5;��w��.D��q�O�0>�q�^\'���]�s�z�[���Nm���s����Q�ڷ4����e{O�OUQѐآc��K���^V���3P����zl�ؚՊxո�lW��l�ro�o����fZM��A$}�!1�{y	�Q(�,��>�t�\����x��:��O�4�#�R͆��k��i��"�F�Vp�(��[V�����^��9Gl��]��]�_4�;��X��X_f�7;�uQ�:e��$�^kt�Ecrи��4tm.�M_�p�'�Kj�(+�Ú��r�ɫ�/F����l�u.�:��v����<&g]W&#N�a�H��C��_QCf`��O�����O������b�6¡^��¾�k_��Pp�7�4]%���wTvx��P�lĘ��0�Jj!x�l5m\����Y�u���cha�<�Dp�D��r�zJ	4����up!�A����)MEʓA|`��3b�i^�A4���U��cm�{�r$x��b@�Y��ɴ�Wv5l����̞� h)���l��EeC�~���U�V��m2H�+��D�$!�q.��o��V~�����.�V:p�
&��do`Чj2��N�=8$`A���_�wN�U�]��f�n7Ź�R�ʛ���@�4��mz������F�?+� ~1(�_~����(��quf�i�qS0�w�%A�\�9H<��!�$�a3�i�0S���t3�C|�e���4J��3�Ik§S2]�{)���d�R���Ʒ%W�#W��p�l��L�چۀrs2ɗ�&"�(1�H=�'���V��?�I���-w5�s�e�*�'�s��W�{�#��Ѡ�r�%�˹�ʴ�uc��u��o���+P[!�w팵UĮ��Uʅ��9����Z�WI���R�yK��G%t-?'�,�l{�y�h܆��"��d�Pb+��U�]��S��X���@$?Wt�0�n���fHl�_�A��d�(k�hT�,�ֻ�V�d��6K�J��\��t���Ay��RH1����ʲ�}	8���p���z�������������3�u0h���4�̏�aT
]� C��8��M���趠h�U���[�e�f�����jD[$����V�������'%
��h	S���dR* ����)�w����F�J���#�}���=_�J�����C�y����3Q�UB���Z�n:'�� XЦ~�n�4���%�E#nM�G�z��������hϡJ:��A,������5�l
}P$�l9��P��c�t���lNz�h�=�W����Av1���kF�RV-y
��z�4�C�������)/'J7�{ �	a�Kj�3.\l�co�=���'��`p-W��^L0�Jk����80���]�R��Y��?B;���P��y�ڹ�tY��*�������X�(�g"l΢A<�&���K{P��y3?V�矿|��#�u0�`��!N��WB	p���k�HAY��U���&�$��{)T��o��H��'9k��D�̤�������8������:0��+�t�1� �5���W���ğA1H
$�����>�Dד�yT��r�v���xl-�M�!v���^�-]&b�}=��@h�=�ne�M�r�S-F�Z��}����t?\Gb�Af*3�

��&�s^Ko(I��+q�d��Z�d׹du���}>T�%M��8݌ݤ���?���q�Q��	Ѷ[!�_Ë&��_y��܆s���~c,��t��	��IUl\����O.�Mh����9�Xp��:j�_�P�y.�Gs�&@S	�M��Ƹ���%f�Qgj�6����)�+O,|F�xሯ(2@&<8�An���>��r�-h����4�##��A��2 ,����6i^l[9�����1/V�WH������v�J��k:����m���A!��v��+����2��&p'9e3��Sq@�F`Jq۩C���bЭ�y��f�
y�!f����U:v+�>����k8F�4{B���ZߺE�q�L���m�uj��H�����"<ǳ��Ԙ<8�"��@j�*��9c�Nk����_Ɵ��Hd[�Һ���c"�����o	���!,�V-3����d��m�,�{W�+�1�c��8g)_*M	��`�Nʧ�m�j.7�e�6B�}|��ub�f�E�)�L���$=��:��g�j�M�P	�ҹh> �2!��cx9�v�& ��j�ۃOK?���S�ĄQ4�>��7kH�:��񛥇o|/��[Z,�t�u����;BS�i͛�V�[����oZ����M��I�wlrq�)B��d["<���7��S�k]�Ն�M{q9y��͐}���v���}%��g�R3Q���F6�<�ӡMC��$����O1�.�|�k���0�$"��M��v4�;�m��������Ҩօ��㙸�k9ｦ�=�"��������d�?���l��Y�M��~���߸d��Z�C�m�����A�UN�$/�>\q֟Σ�q������1@�0�uXUЀ�Q,��.v*GUMy���X�/�'�b���@D�u
u�A�Bn���Xjzmd�����J�n�m[�aƧVqx��w,�mm�.�'R3��L$:z�$o?Q$v�62$���H쾘�J)(A�\W�[soq�=���~�!�J�R�8�}�a?���)�`==��L��o�r�"@�#�.	��^`^�-�u8��\�4�[�\��`�yM
����R����Ԕ%�)�$���� q�f��;S���撾�s"](�KЦ7uN��D���8�|�m����%���g�&� Cbܩ�4�[��C���ۅ�?Ȥƿ��}�5U��N���H�Z)�0>�R*�����'�@��8.�W�(�0�DY�L��ao��ܺGQ���B
y ��ȋ��i�I�C�ٛ���Z˓����Yˈ�t�BS^$�?�u���"�v��Pia:L����V��,wA����۶�$�br^�5�7�eR6��t����@-���U� ] �up��ix�m�1#�'�.�f��_���M�k�+��yM����̐.;V��d��T��B~/T��"�`��E�p��y�/b]�p�r=_١�>��K��`���1q� �\�d���W�>%Ԧ���ą�ḏ�P�^\��% ���P�;u$�	���N�|�������0��D������`U�<D�fq���R�.Dw�;�&�1��8[��&z��j�v��k�x�� 3�3�l"��C���t��O3�OO-L��PX��E��ޕ�v������,�!%�[x�pU�t+��v1���L�#v�d��sC�O:�SuV��;.6 qa����pX(_�{�Y��n�6���b�L]y8�K�d �s���I@�6o��S���#߱��1#�*;�]�Ļ��=ӷ,G�?@�F�D�����+�<�RIx�"�b*�Cb�1�q[��ق=k���%<KI�P�5�R'�����ŖUl�$��i��U�~`u�36CY��q�I���*�C5٥���Jĉ;q�"�XWSF� �Lt��nݎb�]��E�.z\�4���Z�@X]�;}���u�5P:�h�1���KT0,>��/̵M!ˣ$D�+2�~X���S+D�,G�$�W���eBWz�ԯI�*����*Qq�J^!�>Eu��6����Szz�h?�p/�嵍7�
�1�ߩ��Y��v�$Y/�q�?=�����Ŕ̽^��?o�����%�?f�aoM�.�F��A�� J����9]�����~���9v��n�F����:�rt�#K&)�e�`(&��l��e���h(>=�FEo�Ʉ9��Q�����*n���ze.g։Cll�\�X�g�u
5J]��'\{���sg�vQ���~?iY�&s�r��~q}j�~�*r N����-���!NKyѦ�UW5�QSj����
y��rv+	TYǒ�M�*lu?{Qg����!? ��H�\ 0��߬��e���ߚ�4)yG ��N%Ih��֮�����8�0���c�����@I_��J�+��@�C�#����PU`e����Z�d�uT�g�^0G�}��d��YѬ2�����\"l?cc�UDv�4�ͩ!FX����e\�s��*�G�S���y�V�Q��£9���=}�I�Rh��� _���+\2�_d%R�� k�!࿫��&��=�D�E�� n�>exk��rFb��~�4�y��o?]=�����%�N��#}C�w��|)��Z^ڑ�/���?@�	I[1tV��.���nq/�DB��+^L�T'i���u~�&�� &�3eKK-��%�j�1��.� �*&'(N����{���b��-�hʒ�d�~)��n�5Ls�"��+I�=G|�\�t��E���V��D��깢�6oOLQ��e�����Q�e[u�kH�
��Dh�'�U�lq�����S#��u���n�����c�f���_���i���ʋ���oW�[��ΧJ��۬(�On�j�����k�8����^���Cԡ@M��2��Xp��(m6��̗�o��b4�i�R�P��rE`�/���֐ �i�Uq~� ��c{�����P���k�yT��&2�t�����1�B3��-`"�1/��K����޻Fl^�ym�?��R�DY���n���1�<�݆z���m��Ƽ�R�`7�����ц�J����ȳDf�_劍���M�9�)b�M��f��L�_DR4��_.�����r����Z�R7��4���Yi=���_�Ώ�9W�nL}��T����'<�!*�&�c��iB&Ts��ת�eP�J�F�d���FS��TсW�>'�3�Kr��>�֎8�k_�)�6{#�2(HEG��$2�%,�lӹ�d���9,�$����6ؔ������-���g����p�g:�E~P,;��vo�K�3
,[)���t�t���^M0����ڼ��'GN��(�BA��|U�1���k;i���+����<z=�ٕ��1���x��_����>E�jr=J�<��pL]]^:h
��>-%n^<�p�9�[�K3�0�#PY�Q�H����V��F�q �1����� %�W��^f���Z/ ^{,vzc�r�i�a3țV�n8� �M�5g	��ˉaO%~|��Ŋ]�|ƥ!�ÏG6?m@�zr_e	$�.��,��XR����2���B�TȻʙ�̳N��V���(��^v7��/J^�<�`u����We�r�d�����:[�����1"��KN�r``��nQ1�,��A,9��lqv���9��7�]��Hڷ����d�
���T�<Ѡ�/��J|D����G��b�Uys{u"���Ň�T�b����uӟ��.bop�Lۇ7�8���c�T�G�"Fst��tsΒoL�9���+/Y�4���q�(Xg%l�E4���Σ�!b�E32��YR�	�$�x�%���$�'�h���^p�i[��Bg�A�8��.m��4\y��0�H+�����ڇ�5����/W�ny��ˋ�����{zԹ=J������]Ky5���?�E��W�6���.;�6V����^C�rJ�j�&D�8n!8�����r��t��^"��w1�u��Oh ���	l�P��q���NP�|����C���ڨǯm�B����.d��юY�q�rm����˪$KDo��F�M|GH�@���!y�M _l���%:�d�V���e)��+LV����M]!�݀��tuŪ!+�P�%��A�a&As���\'�&�G�p�b��>���� ����r,�~�ZA�y�U  ���Z��v�l犵;�4�E�ڙ/�e�C� UN՜A����\��^bd(�qz}撏�����i!*�ئQ��&�y�4�|��s[�d@�����,.B �ʅ?�M���h鰉$S&���L�&t��x��ᒩ�^Ͼ79�c�=��f/�����R��->`,%Q-�R5"u�H8F�s
L��(���Q�'W�3B��T�>�q�R!��s�V2h��}/=������o��o�b��*�Hw�������>����)�d�&�R��*�GM�I�Eϊl���Eh�WF	Ǉ���Qnxi�?������O��/pS����(F��υ�_��?��T��
��Br�z@$L�?��1��z@����bf��Tʥ?m�l����V�Uɣ~>[g^\�+�kwf��E\��?��DQ����O���%J9n�����_*���_�<t٨��j�q��Ƿ�F0�~R�h�]�Yp=>s��$����F�O $�����L���0��_"�.��7G��$X_��� *p��X�-p�� ��_���qO]fĴдr	d��Fp�� �� r
�|s���RY�ro;b> l:���WO
?�G�7fA�e�·u���(�Ny�7_&�����J�%���c�znIf�Dg�N��w��S���	���J��\�YV��c��'
��$��
n��'���A�P�}=#�՗�U=��g���W	��6�9$si�+�0p���J����y4��{�BH_���Wᔜ#�Q�_����F��c$�7>��uq��f�LÏǔC��������2X�27t��������|��Zu�~:k��uO��msd���d%�c���aD�,�РP�!�B�#LH�2"g$����f�b*�|��O]v�S�`~�8K~Ҕ�!l�lҽ|�h%���P�፹��B�4UJ:�%㒀�(8�]s���A�4]4<v5I���Lx�q�+ҥ7�Zi��]S��9�*۳����WH��;gvϛM�AB����t� �&,D���9�2��^rp��"��	��c0���Q���A3xc?-����Gh�P��������i�����B��sϏ��r��CJb׹.f�%8�b-�Tjc�Vo�M��Fz ��D�� l��kP�N���~F��ݩӾ䝮Nlج�}��#ٺϸ׉�b���xχ�g=�� A�`�6�����i��J7s�^���t�:O�NI���h~�#�v�XG�ʋ�z�_$6����;?}?H}�Pt�:�����<Bp���f�{�nt4*�Z|l��� #������"m�dP��/�K�c�љ�R`7.��T�%å�v^5�����4��N:��_���"�.v���~�O�.5K�s?�m�{�t��J�KVM���QZn9���LW�%'I��3C����R��}����|���:�=�`<ى�؊�-�m9��'QU(shJ$t�-iN�EY_9V������lZ�aG���eՖ+���1(� ����b	K�^�Q��A�6zh�_��
�7з�"%��T�{ÙR��\�|Ij��^���A��[���?��Ro�h�"�0���su7�V$�,p��l�\p�OȰB�N�v-��d}~�u�k��r��)Fs)�O/���P��� }�9D0�Ĭ��X���&yҁɳG��ۖ7����#PN�����H ��3�a��P>@��.X�K~.�X��vJ�!*�4�����Rtp�O����d~� ���=�a_��4(��Џ���* +�r��	q��8YIk+bs��C˽��?�@� :\��t��fn:����d�u�Ų�?��抌<�!0�$��O��I�֑ryk��M�Cr������X@kP#E��w4ʑ��9��xO h£Lͪ4�L詮��#�9s/�`�6m>�	Cx:͌�<�OX�Q��.~#>Ev�r�k�l<D\��s'ۨB���=db�"�i��⾑�w��`��oԀ:ڕ;�ز��]��f޲�mnɺYpPbO��$���#�{��~bj�r�_`�Ќ6?�hh4T�HOѳ~�.��R�U�q�q�7Z��ܠH2�P�qc�]��K�6�o{A�c��Lԧ`af�(�Π��R>�ML<�¨��h�Zf�U�J�l��>��镣J�f��78޶==Pw4����C�����:���X:��|�6������3���� RFx�B=�=3�Q%scuMD���� �_�%�ZH����Q��!�����;'I@�J�"[��F>����#�h#Q^Q�����Z!  �]��'�O,�`^V�E���Gj�1��YӉ2v�K�J�R�R��x�V���0��9<�������ͧ��)A���t0�x'H/�I�5(�P��]�	�D�}��ӷ�
��y�xJ�/�2�P`�_�~	��F�[D7�O��{%�j�4��X�EZa�>r\�5! $�� �6g���D>��S��Hq	���g;C����p����G�S�hŷ�n�s5c��@t��T�{��Y��{�8�'�:����s�-����A�΍ۡ�N�d^sB��4�iբk��FJ<��С:=f��y����=5�55������]�_���j��ݸ#yj�'N�G�-rST�AD[x2�1I�*��Pv��(-�(�kX��0��ͧ�������~V�eX{7�ĳ�VC�pw���^J*p�c�ؿ�o�i�Nuض�� �SN:��N�-��g̥����X���w�W\&n�t��3ؽ̂D��_�-ت� I�q�g�z�)����i��WV̛j�!�$x#�z� PY><��n���{���U?U�z�/���_��.�C����B��}l�������p�>!����aug-Lb�d���R�b���?{|U(���Lϙ��g��3��ߨ  2J9��{� ���������g�    YZ