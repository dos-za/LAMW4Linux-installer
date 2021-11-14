#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1297004263"
MD5="e42a375faf5542c6abe2cc60f767c54e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24548"
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
	echo Uncompressed size: 176 KB
	echo Compression: xz
	echo Date of packaging: Sun Nov 14 18:44:33 -03 2021
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
	echo OLDUSIZE=176
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
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 176; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
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
�7zXZ  �ִF !   �X����_�] �}��1Dd]����P�t�F�Up<�*�3���$���J��%��jMѪ	x����'��)��u���m3Y�/y�>�0,��ír�c(����Mf{R�쑶CU`�o�9f������T+kN!9�6����az}�L&�U���ٗ���k�w���#�t7�Ty�	t&���-��I��)���Y��.�I�g�!+�˷q @�t�j�kJLI>�@)
L�dzq};T7����/5w�(�>�v��׫�ձ�8V�Jh�	��gzM��X�-�By�&�P���+s姷f�]o6�v֊S���h}��KB�]c�\�G&�S��渔A-�Mk�iU�ccY�_T|�Ro)|�,6$տ«K6^�m�AL���H�c1�I�m_��N,D��J���i�k��I�a���G���ȓ����L���k�hy��S�}詄��՚LU��('bu�����%�:`�%k�Ur�����T�5���N�-�om��X��ڌiew�$�c-ĥ��7��,D�<��@�UU�
{c_ ��`�"._^�.��"<�rm��o���G�M�(�:%���F؈ӎ�8ݟ���9+��GMnm���Y�E�~���79-A��[+�����"�.Պ�VG���(-�$��_҅��t����tD�Ѝ����`�&J2�zrM��h�4j��ň�QCx�w5�������=��i�]n��fw⌙K�%�,4߭��Hr*rp�6��"8���V�3�v:��s�pj�kjkRJ�m3,�e���
��T�ѓaFL����E`���{�~Ӕ[�JF�E���W�8E�G�9��ǐ��6�>'��9�	����v���NN�ɮ���r��Iҩ~3�sf� 5%���$�1��Q�`O���rE� T*2����m�n�ZT���޷I�g*�_��%��D�0 "(��VuQʟ_��6�ܴ8W�����M}�I=���GH�����nk驇(��e����h�0��Зڦ�x-��)�\0 ��)j��|�an�d��]�2h�.}��?�I��b̚q.ǃY���a�X�Vaz\9�1�H�U��"�w:��\E,v8��5p� �J5����I��Zp)D����-����I[9-��O�
N�xb�H-�W�Ӧ}�W�$b]�zH�8΄b �uly�,��e��$�P�d� �V��%B��S�W��_��:����%=�ܣ�f�F��(�&HF&� ��U�ԗIBv8)���,ʌW�LN�b��Q�x�&�GӱDO�~��#O6���FES`�0�Ͳ���n)x�f�Ri�|���t2�/��9��v};�h���=�+3���Lz�<Õ�����[P<�<��0W]�g�"�YF:�F �L��\����Y!�F�NK�� D=7׽J��Y�/}r�-���B��)$#{K"�>��j���R�j�Ȯ�N���'@d>��m�Ì�������DZ��罄-���L1��%�"2�Dh{_�"6�\�So_��O��!�q	4��Vr��#9$_�P��'[呜Dٿw���'��_�Q=p�]γ�B���=�Xi���f�.��c\�6���7w|m�gs�a!��*� �%�y��B4�Z����^�2y|�s�'�^C:��#�3U�ɽ�:t;�0��X�mu!`e�(&2P�e����!}����u1���F�!�Ě�Ka���|Iy����]	��Ǌs�������:u�!% �}$@�y��Y��
�H)�j[y=U�+g��s/;�U2�;�x��˳����p�����"h��b� ��h�)�)#��8�{��h��{k�f���k�	�����TLM:A�3��>�W4��O��3!�}<��^�/r�̒���J�Q+�Kk%%�S���{��y0~�@�kC1��v�n3���#)�knɡ��7�
z��q'z:�j�����L��:Ԯ*��x�������d<��w/��BSVe-���e��!��Sr�~:�A��-2 �v�9}8�m���xZ���;��,�ݳ��S�j��(�N�1ne-��Í�/Z��5�b�ϑ�;��U��e`3�x``y���2��N��~1�ݽp6=���w��������>�s�|#z�ϓC�{f�\i��� �#YøS��n��W���6$�����I�s!f>@�C ��&�.�3���>1���T������My�%�9&K.�� �jvOh +�Zɑh,��ת[4��D��s��@�Q��mx�I5���5,-\�Uw$kd�:vx���򜱚ac�J�t�O��Xau�GZ�4�X����펡����^Rժ�)�
��_�3�j��>9"#z�c�\j��5.P��@�'(�W�	l�%L��A8ǵΰ�y.|��ӭ��T��]c�V�44^�rE��ƌ�Q�O/��V�2x��.�x4��浑͓��%c��J�GP�`o4d�O���* 󙍰M�-�GGpCbF|'�d��	��roOX� &��"���-ʋ-񝄻���$�ʦ+	���C�:�����$�'�^:b�p\��ns���%Ry�Ή�}�V��FٙRJ����"�-�sS?b**H!�+l�NI�Z$KdFl�3�~\���Y#��X tb�ʉ�G�A�1��K�h������ݻ����Θ�����I�S6+����`|]Ɋg)0[��J����R��׃-&ܼ<4e���b�HJ��\!g�����*��2w�i�6�H>�+i.�e\e�J��z�:Ol��E�ߣa��Cm#�pnG�2��6�}�A������O[�P��x�j%)�e"��=�h�-�郛��r��PD�Z�kYyo>
;��Ȗ4uuwM1ُ����꓉�oX��}���=7�<܁��୿��,�*X4�{L@9�u�},p�y�s��<�Q���&�+�*#��D�K��~?���	8�[�%�f`�$��\:=���A�(x�����=؀M?�ُ`�u�]"x_��!�����i�T�ʞS�Y��<h���V�������!����K>�d����u�RK5�"�8�u��\�3�V�[�ӷw�=��]����(׼~+����
�Y:J	�Z�/�m��m���2͖�G���RnVh~u����љ��yTp�/�2��n�j*��d�/s��g�ːi��ǧ�(w���?�鞁lx�,�w����P�4k� ��L5X���]o;:��$�ͽ	9E|l�3���ES��3>]��O�{l�� +�O�Rٌ�/��OLSx�:�x{&�W���ў���F�Ů�u�
�zU;D��F�A���aDmo��Y.��NB���������6��L�gBC���(����L*�
�6�P3a8�b��i� �0�[$�^]�� ۵�Fke���o�6w��9�6�8Ú<�o�����`���*`����pU-X4X�J��i�[,��~��$ �K*��P�����L�,�%X�T�g�]F��	�:v!���k&6�Lc[j��&?n��f7&�eЎ���j�Y�� ��d�ʤ�$���/��A�/ƃn��G�7	�)H�����:�RB�5�-Vi�Y�[��\O�ec2��$!K/=�}M+M=�B�М{WG=)������4����^��f	���c���*�hM�C֖Y�?@fKL�$��}�8����!A[�������
���e���҇�)<S���a���8L�^��H����L=8����͌%Ô,a�$���s wq��c�`��hU
�k�q�e+ b)n5���&g���T���ux�M� s�usj��T+Yh��!��s���L�J��'�8��bQ���`&�l dZ��2�3��K����q4��?�a�R�Σxy����'v.���a#D�٢ۄ�
mi&�=����?M��DG~�ox�CN�S�	��Ad,�j��"��M��:�B	�<^B|[�y�w�[=:*�'�l��*X��Qs�tQEB���ކ�`���\o��ߌ$Sߴ-[�fp-U�r�)� 
��2B-������T�s���f�-{�WPd41���S�.���xҵ��F��l�Y���p��ͩE{.aq��,��b�5���5�z�<^d��͙�Q��#`mWf�j��(V�XW��V��EYql>j�,������uMsvv�Y2��g��+#�%2�*��Ie�F�Z�Y6,�U=_�G��	cPE��T]h�IrF4�Oȩ�u42F�owv��x��/r�k�3�ݜx����~�&�da��)P�E��NQ�9},��\j�����ԔQ�)?���M�P$ j*ĎM���i��Yl��rV+��3���`��I�Yc��
@!��ڋ�O���c )Rj?��л9���s���C�rrt�"�4����3�N�'� �� �^}L�@�%�DI��,^�:t�RzO�^���'�f�����/��f6f��Qn=�2N4R���~o�H���`�$~|�mzU�g��\�.�Ї2�����B�@QC�OAm��X��!��D�����#L-2���'�L:��?��|��6o�RꩧL��R\8�@n%ǤwV����U`�������1Er�"T�]�F���yc�����bF2@����"��7h�w]7���Nwᦇӈ��6�ڙ�X� n}}F*�'�{ɰHx��soZr|[���P	��xjY���`$O{QѸ�U pVO�D��̗��6����.tc�,RI�C��:L��i� �,�?��L3�1Xq,�������7Ni�1`��Q'���F^P�R%B^l
+q�8k�EW�820�S�r�L�bg�����AN��ߟ�S�A��h�l�$9�����0��8|Ы� ���>`f���{T�U���%�K�Ik���qƙ�^ڈ�S��J�Ƕ��r��&�������Ic_��I1�J�v�KO6?���@nl�i
�6��l��<yd;
�{G$�����dE�iQ�2�(q�\Ң�~�������9;�pο��h2��æiD�F�<_�$�}9,��J}1R��;���
OĴ�m�VeV�� R67� �1�{?
��2G�=R���F�h��;+�̜��T<|��w,Fu���|L�QU?Y���
���x���棅�0`[�!F-�S�~�%fJ��j�a�.�ˡH��T�̡6��Tt�# \����"u�8Ѕy��pQXi���	Ӝ(�#�/W�^R�����ۼ+�����+S���/����wu&-��z��4+wf�`��D��ԅ1�7��(Q�"��nn��B�$5l�n>1a��O��tTL&j�����^{�D���.���զ'�Wfm�����Dh9+ʴ۝��ב�JN�nn�U0j����rF$����yE(q����<�E5l�#tW���ֆ�O�'�;��S[r"?�I�볲��+p�E������$�R�Xf�+�����Л��Q��G'��^�J�U�;� ����r�("c��g�p;H���ƈ�'�����Sԣ�Q�jD�}��.'������<��O�+;m�� zZ8ߋ(�3z	%�'�Ŭ���������������;ɖ���	
E!Z����c^ߎ���\PܩI{��Y�rdZA���mA�ӏu���GA]���(��$�l�do�����nl�([��|B�!8c�RՄF{�r��R������wp��R�<��7t��d�0�w�"�fGEӅz�6��\r
���ت?2�$1�l|�#����������~�R~��^4������#T��Uz.Y��o�Z�v����}�v	�W��X����a�o3�B�T�&��礓R5��M��M��d���\�[~U'_��4���0�S7I�dk��J�&���`y��Iѵ���K���;�׺�0k����D�+��Ʊ��%@�&e^HT�D=F��s���57ն|)`�i��Z����zB�����Tb��/�Zm6�a�S���I���g�_!�"~;#��.�{8�~��.x1���c%�k6g]���'�-����}8�߶/��C�|���ϖ��$��!mkf�2wm6BQy�11�b�[�c\�sQ'��o��x��v�;�c�]MFNw�E�)rQ;hd�/��V����*7�bD�_��bO�`�	_Tr�V�9|sE�����~ �����W��g��Sc��$"|8.��W�5��F�}HfV�X��4���Y���l� �mǼ۪��j~?M}�m�^��l/���]V�=����Y���.6{���u������"�#�N��D!��u�8��PƂ��:��򯔍�<�/OU�8��j��<�!p�A�#�p	ǳÍ2��Q��gs�X�]��H���od�&ս��3X$$���k���Pғs`�Mf���z��x�y$�����}҅/
n���K�����*�K���B0a��k���J<b���Z�RٚȢ� J����`�;�������2V�o�<�n��q�c�vN�wE#��Y��&>�}ä߆N��T�:,��e��"o@cw���b�$m(UFD�L���
{̱H�i\ņ8E����\���+DXn��}߀i����qN'�c�<�����4�.�gn4E�q��4./Den7.[���j�m�Ɏ�����jv��~�1󙿞�4x5�x#_�#�C�FS(��:Q�K��_vp��e�z0�*k֍i'5�!��쐏m�(e�������"E� ��������^����_�M^�~Z}��x�LA�!ze�]N�܃tm��w����
N��ҙ���E+���ȃL���g�~��ewH���`=e��0�"S�	�|��,n�l�������s�C	���]�]�gxL1�����Ė�T?RZLF���|�O�K!'&�Dղ'�l��e�%9ݟEªx�C��c��J<�)_m�`0��'c�ej���.:���<�t?U%+p�L�<����5���gw/��rB��fjsƎx������:�Ӓr��A���t���3T�"§F��VJ�0�V��P��y��.�M[f52�x��aό��۷:�X�茺g�5m�W�-�Ӓ��شj�#F�#!��@���+b�u|�%��^T�����˅bn��q^���SeK̞�|������=�
�[����h��O��í�[�PK��9�0w-s�5�<����?��l��B���7���ކU������ɢ���c�+�'�&�{>'*_�B��|^�ݴS+?u�[:ǿz'��O�+>��Wfm1D?����V�r�e�]�2e�lo���Nv��TW,6De��{�ѿ�;����o��K�����{�ƲGeU�'!��.���g���p�����!W����isHB͡xQd/ʐ��7�z�-P@&�z  �B�jjb���ó@�z-�?K�MG��`��ˬp��`S��O)_���?�q�f%�P��Gz�^��M9=H��sW|Q���69��L�}X@ŵ�O��aIm�<N0X�#o_ �J��ƨ�P��_�Z�	�y�G����D[Ӧ�Q9�E�H�N_�꿠\LZ�y��f('�t���r�v(E+�x��5��O��$"6I�i��!̡j�ӏ`�h/T����������]��Ҫ �I�R=#$��q.���K7k�D�"��}Hgf�!0b�ȗ��q��t��bd.[$��[ ��%�ew����q����І��a6>k��\�����2�:�V��9m�aG�
D�d�Jwײ�3=+�R���݌=�]��*	��|�Զ���J���R��I��!�ވ<4�s�S5hs���`�cBK70�_`k�S#�~fH��5/I���V�'��u%����!8v�6˜�P�0ȉZ��N���MSsD���%��tj����ﴗ:Z�����c���X-�a,ͣ�*Yo��\�j��:�t���4<1��+�	�i]p �ĵ� ]u�`�o�t�/�A �AZ�����w� �u���d�����W�� �eLI��<�%>������"��9��R|p1m�����1�ݾ���w��9���M/�SS���M��oVY�t�Q�}*��,D
�N��1�"���7��o'ܛm�sP�תA���٘�|��̺SD5�S┗`��sm@�@-H��Z%�>�qx5�ߞ:P�G����VY���o�\Z����/����Q�W��r���%fX}_�Z�f�9��N�@۴�e�&�_}+�^��ּr0^��ěW�j��*d��R�e�>e+ ��i�xD)���)�v E��?w���>�q�x���J��;D.�覛n�E����ƣ�̸O"���S�ZN"_v~����<�_�%�D�P�-�~vH�Rכ:�rև$�h�LlQ�$\
u����P+�S$�$W�I\jc ��a"��g��^�7: w�m����#��+p]ŕP��k>�<�/���=�K9��G�C_���i9�����)>��÷2�z��Y������"����"�;K�|��,倆��_�'�򒧫�N}\�􈭅�^�{~��
�O�}�_1e��U@�./p�N�_�О��S��"��%��W<�[�w��(�K���U��'�G��zܛGb}'�[���������@G�(�0����Z4Y@0�%[�u����t�^�`� �S3Y��&�Y7a�<�Z�y�z���>��k(�J�w1k�B.'���t����Sw⯰z�]f��B!�V����c㍎�B��������A��\|�M�����ѣ�ߦzKh	�fL��{O�ہ��Z���7�G=���[]tѴ�ڪ�R�L,��p���#��x��t��{�����T�Q�����o%0�:A`�h����):�����_��R�Y<��L��#���b��G?�Q  m���N��uO��W�f�����]�ER�'���ahߊ�}�2QO���>�+13��<�S��}`��ibC4.�߈B�#+BS�,��hs���;f���1�����b�{ �?f�vTQ��-�D��U��.����BAL�R����Ts�i�~"����_�y#�6<$�OJF� |j.`;Q����NMZ\���d�E�S�'�}+�R�Y{Ş�62ϙ����wb؊��+���ќTѢ�����]^�"�o��E�&+�����S*>\Vk8M��E_���_��$1�w���'�!�0���vS�V�vF��L��X�З
!�AN/G��S�	zybnO,`X2���q�X�ܼ֎4��E�e>885��EW�������xI�]J8����ɉ+���f�=B��hrS뒚`� ��[N�2�U����D�m2!�s���*g����D��Bġ.gT0�J���fu�v����}4b2��ƮJ`"|-ɆcW����Wn>�!Y��A��<� ߗ�pQ��nS���|�&r��0������B�LG��Z���H�H�O��� g|�K�%�������@�?(_�K�yF�"����_#]�~�D�omS)�����Z�w���Q�5 ��ζ��u���&oN��@��:Ϩ��Ų��ڥ=�v~|��9,E���g�,i�OUz�����^��:�;i@���q)\��h�G'mw�_����W���_E�)Z⺰i�g�p]"��B;N����H �v��"�l�j;��p��@�宐}���wyxJ}�QI�v��6���\1Xȍ��d�	tD�?U�Qi��w�\]�Oc�Άl��ϐE��S��<���$2T��j�Y�$,���i��3�	'c_s�X��d��,�ƊЌ��u�NN�:옔�?�&6���t�t� �e��Uk����W�s�".xO]�Qt(CD��k�C#Y"�eLVs�c����'��s�!�����r�F�:;p�x�0X,����`��Ov����Cr(�6`Ϧ�y�?��IA2i�>�M ��l�)�#���k�w)v��UF�FD���n(
�^�^,9��X�n7.�Zl�H��!��ŉ��h��<�Wu�\g�W���J�e<� �����o�8Re�Њ��
�y\��W�g������8��?�}7��-U]�V3'l���Rwx�#���t���U!Ғ�_Ƿ}����Ub�jU�Ӌt߆��;_�ƌ�:���?�aR�~��������|T?~
0Y����PtЪ��T���8��7�.�5�>t�|����&���|!h/����OU�t���O�' ��.��Ϡ�G�N�*%Cóm��vT�j�h�7z�	����}�U����C�S��֪W��ӕ��@�A4劔"����'�E&hF>]��������r��!g�@Į�a0�F����ޝ����a���G�X	���,n��b�F���uq�v�l2Ժ�� �e�L���#YA�Mш_��f��O��с���s�������}��)+i8�̂|��QK2����ѷ~ɩ����8���g��%+qk`~����N��l����!�_�iب���v �ŵ].dg��3��w{PX����aA������Ip	�l�f�F�M�V��M�i(�V�Kc�c Y��۰uzJ�鈭����=�!O�������Qi���h�@��l�3%k]�W����/L^զ���\�D����df���o�;�ݨ�`��y��$m�X�k)ksz�MQ�� %���E-�gmM8�n]!��������� �0�:{'����5bn���?��o39�7A2���x*�5�q�D�5��c&S|�Y��<�(S���!�rRh�':X��`�t/[���/�KL祃��_hk����zn�����Jv'���xM�DP������6
��ް�hГ�P�c&����B1��0�*�]"�֎�j�f�a�u�l��[	��N�Ob�w�׉���Ju��<t�c����6oz�p�+�:c3���@�zߝm�!W�n�QT�;�	�tQػQ^��`���Ũ��Hw{��7���6�
���{����ɓ�ZQ�F:XA�z�+)�������	��ڽ�]��k��,E�if�`��-� Q��Gk�E���}طwp"jDG�^�Yb@��L\�L-A�>~N��e���D�`l��lMҰژ���
�jLs���Dԍ�n��ͅq��W'�!��#T�����*����O�:�Qa�.'���R�[�4����3~t�$-~8���+�,cK�Wq�;��즬ׁ6�~�5���������ek>���n�b@F}����[)�1��/q����8z��B�I�b?�y�Y��L��e) ї�; *��o���˃'`��;yK���"6���h"��x)��� �Kkny[�Z�hO�P�81�V����*�0�5�9���,�[�Q>�s��	�������U�(����-�"T����CG�'��A��+�6�/� ������3\�@ym��`�#���(���8�l���Xb�a͜>���'Ww�=���]��b.n��*�-8�kB䝂Ѿ&�Cm���8ǧ��!�s�'7��e>$��I��[��΀@���D���[v�JUj��CY~&�q�d������4Ւ��>�D$��I�������q��%�7<��H(f��1�.�jZ����{��]�%��Ub��"�cL3:�Ɛ&}:I��Ϊc�-�p9���w�`�G�}�rt��z��R��)ZP@���4L�7ݺJ�K8�N��xQ����'z�&��ia�.|��T�ю��M��[԰G�pzM���Xd[�ʹr��
Ŵ��ٹW���1��l�;E���ù�a�ӗYH.��u:o�')�]̃پ�bx�!*�8��?���F �1�z��0�r�$��C�?����\NM���F)������-��eD̭ ����D�1办�b�',I(��~�ʨ��[ԕ�'ZN=�}���?w�[��Vi�g��M%��ٿ�b���}h�nx��KLv����&Q�oᄑ�j��1�vȼ�&�����U�\.Hk��n�o�����y��PSX��E�i:�zH4L�2@o��2�
P�Ϸ���>`���:]�͖t����0̛�:h��!��CuqISG��OH{
����l:T�|c���ot�6�����$Tlt=8�!��i�ux��UH�K�f�C��
�8�LNqU$Sn�~��!@��9[��Z^t~��/*�q��/���Rc�1L��c�
������:�*ۉ���c���ި��㥉
�8���}ԩ���M���y������k�W��
�	w@�-����|m_���hG]� P��tr��a�y$
.�>�n�2��<ӎ��wϋD�(qW���fTKq$�h�"�aT���+Ǌ@���?Z�XjYU���ei<�*
~A_��K��ւL���� �d��fn*)vk��C+�N�XjJH���N��L0��B9�˻8yoW|l$�9�&%�sL��ӵ�O����qo6�$n!�&����(������m+��)����-�v��i�Y�������t��֓ J�IYTku[���NLE�՟�'�\�5.�B��|�a�qܬ}
��yȒ@�F�ֿ�~q�\`n��=��g�c��"���4J� �XB�sA�������P@�'j-O����_���0�T�;r�,�������Hݣ��?�C!\Z)䁳���G�#��Z+��y\���������?7N?��Wb����h�=
O+���^��Wz�);E���􋯜(��P�k�[r�H�r�� ^.�RR���ٰ2�?f�ŘC3�~�85�+Gp�g���k�)�ꐫ����l,��a?���J)G�~C������(\_�I��.�E������-3k.B	�`�[��{�����YD{��9��g|�7�oQ���AKP�x���|q��9ݳI��A�3��g���Vj@��Ֆ��o?X��	��1����d�&ը��">��T��|!����6�u�Av �.���P��9[�F����~�u�݈D��Gúk���bmT��5F��v�E��� \��
$�q��i$/�������,�K	F��;X��@&!W� � ڸ�Z��*FQZ�M7ik]v��&�b�9��޷o�������u��*Su/@��[US���� �m��gZ�d5��x��w�
W��&M�6�Y�E3~G�ͱ��������O���],�c4S3�I�%q1	�ph����t�2-]ly'����.�W���?��i�,gs<�O$Y���v�{O�陃�Kc���l��e��A��`7Q ���Fh	�ި�çBx	�y)o�%9�$�D��B��Od�K��E�fi~ǖ�_[�d����e3w�7�¶J+�₲2�}TPo�L@3- o�����.,��]/�rN���4Jo�/�g�����Z�J�׮�g�P���͑�E!����D�����\������Ԯ��5��z�D)LYx�vw.���F��Ca�m bK#�$��)<�'�GĨ���(T�B�_���I�`ȆX�(�j;&�40wx����2�����e��Y)�ų��[Ƣ�H�C2�W[�e|52֖Z���h���2�T�)��e�qx)�֦c�[Iw��14G�yZ���z������%\���I�:�PhZ-��76��wC.5�+E��Op������oJ;�@ԗ������d�R���u-@�*$	C��dJ�9ƴ���?T�L4p��t��	
����G�j�C6�5�h7!��12�]᧣���C��ِ�g�	�E������A�������Nׅ��ױ��9�����>
?�>6,E�X}�0��V"T!>TH({�V׋��MP|GXBK�g?ޑ}O}���fW�z*����O�|��Va UaQ�4����ZI����Ͱc�ʃx����5��S��GOV��J�p�������]\���o�k=X��;���}-���s}\y�����sj����r��]�~�'�%��"�c��z����
���O�폁-ք�X�������$/T�bI�~h�'��/u����Mn�O�AALH�OlQG!��١*P�kw7�d�X��w7������)���P5��������.�M[����k8���sʩ�^�Vʹ�z��P���ρg� m��]�>�;󲂬��1ު4����F��	��I�ʻ$���!0�<o)��x�+R� �����f��m��ǘ�������pa�u���e���CH3�2�2��������<N�ԣ��^�^����8����)D��:�M�@�,h ��j*�p��y���UWC�|M��k\�%8����yMӹvp����７|}��d�c�ld�"Y!,�(�qӆ�"��ze���_�$����w�EȻ��3*���B�kq��1�ʍ��3F������G���ҳ8��H�S$hj� =����ClK�|���HA�#��x���e��u�Qqg��A�A*<��f?� 
����7'Qp��I}ي���1��y៴c�S0.��~Ҏ���1>�	��e�@bqj��f��:��O���E��dd�Br���V�h1ʾ�[�D�U��D(�N� `f����&3�:�;|k�b��u�l��������Iۈ���]� �w������=yf�Z�$C�hFy�a&�|2��e�P40���"�����*ܒ�1?�h�X��H��(�W��?u=�_�k�ExR�F�[(xjl_��Ӟ'n}��{����84��� ���4"C�c�z�����Ik"F�A�t&����C:����I�
Xc;��Z4Xf��C,虑p��O��󪺏Ov�s�����/�z?��-�������mC�1�����ԇ{C���@�,E~�"v`csJެ>�HXDk��2ª}�h��s��{Ӌ|��vo!	�����N�n-ˈ.�/����3������t_�6[� II%9�]�f��Pk�҃WpW��7����x�(�[��;Z���� ���%Lh�/�.�glR��i���m׿���8ۦ����*�)����Т�G*~��P!c(����aMt��4��4���F�[q�TN]�Ԣ�7��`.2P��W��C(�V|pL��`0��)��[
e��A��ᾆoұ/���[.���b~��v�7Ғ�;f5��&b=�*�d"YI[;'���}��hcT��1���ڇZ���ZJr��Äp,�ݽp@|�9m��s�����˙�f�itp!�W���)ȉ�E������؍i,�6��mYH%�(.�>�����J�K��mie��#��C�^�]q����O�Z$�<ԅ��A��͹w�]��$:T^h�����I�h´&Uц]�p||y%����R���9�*G����GM1� �����b�DR؄6�i1��v'z�JҠ���s���.�.%�*��Η�E���~�N2��f8�F�,���A��o��eA�̰�Ȕ��A��ýeQ]�r��e_��=�lp!9|ȔY�Be�����!���+N^���FN�n��H���6�V���9U�����nO�L~��愲+
v�Z4�=�x�J��_$j} �w������� �]����g�#g3:�0L��گ����GCn��Ӹ�ЛBOY|��*)I�ÈSҸ����F���m3%,+���I7��������^2/�����#�Y�5�S2��HP���Ȳz�i��]]Z"���}�;�s���d���ZRR_X���O��4�2���>)�Ç��2@=����k�h�I�FW��X�>]�6s�4Ot���3q"b~��3cx+���l�Wѝ����FI
} �IA�N�7g�X>�6dN|�IvV(�#�?1�;�9B1
/	�Y�[3E1˔�^�1��Uv�b|�y���A�o��RX��a����KE�_����:�T`MB_I{c.��hj���6&c~&���r�6�'xi� �������'��}є+�m�m�;YSN������3��PG��C�%lin���Hk��>?�=�UX,|m)G�̹�D��|��+V�leh�����M������Ң����+�[��Mi̗�{4;���f�qj����t���OcE�F���v�W�=�a^2S��$ԟ���I3�K	����L>�[g���Um�ж���d��Nt�~4���H���\�km��%��9��I��&��qAD[thH��Og�ְe����q͊J�fz�C��4	��R���R �UZ5��x	D!.���cI8M=}�]a/�Pi�a��F�)���-����	���إwf�g��%��׋���"K�~��=����Z��ڑt�.���c<�B�eE��Ǐ���L����gFW���ɧ��H��p�l�T��?����uMY�н�E}���o���c�a�k��㩨���2�͎}��޺>�=7ce�8 �?�D�-p��d��C/��d�]6W���@<$����B�� �����8�d_���f�pT1�ޡ�z��������K(�W���9j�>_�4"N�� ���j8�:s��ZqgD1XX�5|G�$o독��8����۱0���1i~����b̲2���#Zs�]aD��=l�X��+c�����Ƙy��=�h�pכ1�p�k)o�gbXM<��f�@B��]|K�d����p���z��)�<}_��u�nZ�u�����1�����<���k%�@�	�u�y�@� �b�5o��Ŕ�_2�
9y��\��Z�%��{�2Q6Z�MTMQ����Mb��3����#,)��K�!@QHԅmڅX� O��l��KL��ֶ~����ʖ3�& u�W�@Ug����\7ܦv����2N�p�˰˨�_��gynKg/�.�S<^H"���B�}����P�M-=�Np�ߕ�`,�ڄZ�;��&�t���C8e�E�(pM>����s���$٠��Z���T#�=6%6��v�_vm�RAUxk��"�@%xu�'mW�񠐚sN�S D�Cs+*�f�?��ѱB)��!^u��zk@Z� j��aP�5q R1LV`;����ț�q)Y+��I�b�%n*��u�BY������o�͆j��[���x����4+M�5ﵧ(��-��a�v�����U�&gl�k~��@�kD�&m���nVGSuz��b���3���ĵR��]��=t
@/a�����4#���ѝ������o_�̴�Sj/Ҭ%��a���t�i�z8R&�|�{'�Ǭ;�A��/B'
���d���?�Ï�k���*��� ϐ"�+l4=�-��u��n\
 "Q���	~n�k�I�#��a��T:���f�W�I48:�,[Dp��3�m=Y˕�M�t�Ax?>�魥���J2�h�[�&�
�4��ˋV�8�R]�j>���!ͫ����Ȟt�ӛ�oK��U;,�6��J7Ag�$�.�(�)H�#��X��PO@�l���>0rl�h�kۼ����w��[���A�h�w������ϔѬj#g}Q��N�!n�i]��{�_�8�-/'�qi۱&{Pd������n�ܴȌ�|�?�F��g���F�e:���S� եk�V��(��#�EeL8>%ۻ!�ԋ;��m��4�͖ v5޸���'x
¢=S�����F02%��Kg������1��=�q�m�f�V�����r��w���9{�_Yg -V2Au��`�0҂��v�N(!@���n��R}St�B=��x���#;of�63�����7���vΞ��oy%��"AY��Y1S�\��)C�ƛ��$ӹ���-�r6�{����7ZTD�9�cB.:��4I��m;^a�R�KOc���H����]����ϯ�(ِX��揦]I�e�p�����>�Q�Nv��ȡE�z$����ꟶ$�P|~=��=�p�$�Mf�1�ף8]R���{173���l��������|57oa�I�v#�M|�e����I����*�
&_G���m��#�]Qá'��_
L��V�`]���~�8̖w�Q�b�2o"���������i�:UUA}� �:ר�Τ�����Ƃ�e��Wt�g(�Hu� �f�1���| �@S��է
�׀��X��&\t�䞼97�<�~�ib�V{K�.?iFY"؎�PS1Z����l���%�iM����l�f��3l	87[[-h��ex��|HIs]l���Y�u]�!l�5ZDe�[� ?/,ң�RgѤx��.�9�~Xw�����]�3Q�h-�R�X�IH�����!I7���ՠ<�v�׸�����L��s�(_�G\Q>n�p�kX������m���D��2)����}�J�����ޗ�c|��:�g �2�o�c�$�v�S���C.�.��,J5���sY��Oׅ7bs����)bw�.+�c��t���*2�7�T����N����;�}�y��Fa lYc���ؿKy�pG|����4弙]$!��Q�v�ѝ��"�_��Ǫ_���A�Wb�0�����w��.z�'��r�����r)bhl��qn�^���S�.������&�����В5z��3+����d��!��ei�j8Xw�|3�������.GS�.�r�P���7�Q���9G�J�/d�G���ڥ��_+WlY��i�P��� ��<�������ͺZ(����?����AJZl�w8 �4�3�D�(��k�.�:dWz�ViN���mS���p�1�m��������v�^�#�C;^�/r�D�#�H��V[{�5���\��H�x� ;������͋4�)�F�:PߚWŗ�VEiw <��=���d�߰����|��b"e�j��6���j�_y!������K��Q��߽�1�x9�̂����5�sÂ�渠��3
k,�!�W2��͂��hug|Fc�j�M?��)<PۂWǮ����66��iS�?2����nzs�M$ҫ?b�������K�?�Z��\�9��M���D}��0_b��$�whF*�<>R.��zxPd�ܲu��Tk�X��jfC�f��΂3��;����a�Q\���c��g��\��	� eBú�_���{o���hC�)��Jv,���c]bmxm�����6pR���5c�8���T����ߛI���O�Bv*H;4��W(��gɹyw˸Rt:��ꌶ/)&����rؔ]CB��X������ȧ��9���;zVo��6�E�g�|��s:F<@)���?S9��=��9�~���9;.��5zG�een���K��P��	Pv춲I�E3�����ٮ�	�B�=���p�<��7C���5�οl�^xWazu��0ه�=-��>ث|���0���[?�URmӫCAf��b�l9�1�L9hk�YU��Ɓ��f��.,8p���B�%~o�-��m�-��6�P�2�DJf�2w��Ҽ�\��1lY�����)�<�K����l����+ɏr<�Q�T��mƟ�>#9���;��zb۸3v��=�W[Π�o��ؠ
���vu�-�3��mu��)�ij��W�LW�Y�Ɖ�V�%���Zu�yR�h<s�ԍ��02��؊��i�L�0i�nf�1�Y��X���,��@a�wc��M8�Ӹ�L{/_�c�"�Y��"�iq�Ԫ3`jkwt~���N=��U.���U�x)�
R8m��=�H_��3�C�����#ˉ�vr�J9[UȈT�ߺN��[d�?��G����?����GL�+�������L �^k�X�(��;�z�YZ{�?�'Mja�ou��6����9�v�kEZ&���F�mc ��K�t�݀��횻4�!gp��ë��P���x��%X��"5�U����^��}�vYFO�7b?���2�$o��Xa}�H�=��BA�U;�+*�h��Ejռ��U�{._���j��4 2Nw����*IT�dԫI��~��c;���c�~X�b?���F��,EN"�]Ѩ}��{��N�2$t��1�_��u�Nc?WԞM����NvTۍ_qFD�J) ����GH	3M����x;��׾_�ch�&�U�N��('4	^�~b�������,�wT�̰�9��mCϕ�z���u9xF�-_��1��z���[����&D��[c��(&Xz�� �ۃ��a�������̟V/M�`�Ws'�|�����ʭ�5��	m���@�Κ�ɵ��@�h�#e���)y���cսd� �z��d��0��p����tV��*)���}��~h
���M/\Ӥn�9��T�vX�G88u�� �;��%�<��i�@��2��������<�m����ݵ����chX��,��]�T�L:n�Ye��W���	�doP�>Y����K�]�������c!HiU'���7|.��H���%���Y���H�������d�SEΏDD�w����o]���Qj�[�[�'�(��Ŋ��t���Ӷ�8��+Bjr��%˾R`jk��<{)��	�$L�HU����Z�Z�Sh{�o?��aЅͧEo �;���J�a&����EhOU�0H��y���b��ZH�1���Oe�����j�rC������H5��P|LZ�A��v�hg�<[4k_NX��O���
�ZHR�R||��r��x7Kp���
u�����7�P�ؠ
L^�I�=H����+F��#�:��5l$��7M�_@"��.a��Ɠ`휬�}ϘVi!B"ߢ�YY0z��\��uX佪�8����=0��!�ܾy&>ZT�a���3dyr���ﮢ��̗�)z-g�花)���*TB�-�������ע4��(�h�	���I -ot���f*�,<�؎SW]H���b<V+%�X.���_��d
\]�%�o!S�L?��ε&u�!�ju<B?���g����r�J�Դ(�����c/�R'�8yb|_ �e�]�j��G�%� �YF�E{e�e�u/��w�?AL+�����2"��]����6f3�e��w(,�ߌ�"�a�=X�D���X�,&	6J77����,]~n��(�k�A�2<��Z+|���i������ �-��mI�r���ˀ1ܡ���l����('�1`����y��{�Tި�۰�g��k-e34�0�4��u�b�~�q؅5�z$�*W�:<�֏��u���Gq=��	�ތ�h���Z����A�j_C3�{{.� ��H��Q=���lg�l�}��Ku�1BA`�c�����4g@nT��:@<?�A' �(m���ۼ��I�_|��H<u�+lDWD��Uy����	RK��d��7�bAc7�d��[Xힵ��+t�Ö)�X���IJ�@��� K)2%[R\��P�$0L�<x2>������Rߪ��*�r4�xv��x��>�Yl��@j�5�Iq��A���PF�Yj�>a2CM�e��H"�)"ZN�A�Y�V�9*+�x�K���i�����[��=N'{�vǕ�3�=��+
��r���^��b�/X��р<S�,�j�u��-8w鵮���,�|^�*(iʇ�-�@������缾���@�#�4<�[[nM@�_�
/�}�-' �����/��̓^��� �ւ�̀A��yW�;=E+��2O!R�����D���ȍ�����<��A	=����E� �G��{�̌��돼�b�f�ă]ļ�����Ge�;~���;.i�=c�t˯�����n[��QM^��g^;��8C;��\�VECM*u|��������+��Ր�����,�,�'��	�� �1�q�1vfka �!�05c���Lap�PCh�Rٿ�Y1�J�����.z�N�[�8Y^[�x���"������\j�2�v�S��n�Wv��OM��}X�����ènr0������׹w�ʁ�f���LX��L7%Ċq���c��>5'^��L�eN��^2M� 7��	���.qO���X�7�d��*��C+x>�˒6{������}ڜ��i���[��I��$P�N隙�=��kl8ŧmž�~�XϚM�Q����.İᝃ�Ӵ=�%�#VFT�k���3S5 	LZl�1p]�Tv�}:����ڤ�`���x�вE=�7a�N��R�MQ�ei7֔���px@��M�ii��lt}L����Xeٌa����A����܆����x4ݷ/�`���f����i����4E�p^6#�)guNDv�rf+�E��a@����ίԝ-7�d~ϥa�������S� O�r䝱�"R������E�M��M6%!Pz	��#��<¿�+Gm����6�±S#����&�
���?6���K�N1ڼ1G��s�y�X0�+�mo������d��:Y����h	|FWd���o9#��r$n�����f�@�Q���^"�
��5'��k��ԏ"�k=^�,>��+԰2��|;Q���@�!��#��"�ϼ��%����,���i`[�� ����y ��할"`������A��@��(Sd��+n�&����T/�#��|�ո�M��Xn�gpփ3d)��`�y�p�q��P'��&:8M�l�V/_������b��A��E+��k�Y�$"�b���e�E�7S�d|�_�-r��ؑ�䇐S��,�í�������m� ��jc�ҹ�y��tþ�<6%����l��ճ������:�4�C�K�w,�3<:3�'=q;�����{�0Z�=$OKH!��U����A�f�1H����³�p��I��>ʵ�h�oGG�%�K���'E�k �T��٠�:�/䨄*(��8�Hj!JO�h���o�ĝ^)��W�itf�yA-W 5s�I����s@�����;M6V�p�p/z;Y�	��hܩM9!��!,��_��xh���c�^o�S3���b9� g,�f����D[dЛ���4M֟�]��K��KTw��{��U�&�%E��b�+�����,=����n`fpj�;ϡ��� P�ٷ�zƍb�z���:wL37b���?{Ọ�������N@w����E 
TlW�-��zƁ{x�̀⧀Y��^�Q�r��eg+���������4��(�T;�����j��,�V��� 7u�BOX��%�s,N33r��#o��xNS��L����=7�	�?<:&�<n�(�P���*!�f�K�*�O�u8�a�7Q�̎�R�(���p�l�8��� ɸ�	B�I<�\���q���¥PaQ�u�������t!!q��#�c����8X�	~���Ѐi<�-H�� '4�}@�`�	2�T�ݕ�Ź��i��4	��»���sө�,݃w����@��8�@�ujڀP=�޺�F���b�cL��Y�V	Y��g������W1Ib|1���D���%�� �;�b1U�Nb�)����A{�џ:��Cf��U�xHy�cM��{<��d<H�s��.���ߵ(~��l�SѦ�jh�@�J����߬�
M1���=���%_�����C�����9 \��`�\�W�ZNJ��2 �4Yf�Ǫw�R�9Bc:�!���$�`C ����z|5���)�1R��u��O�l��P�f�� :�B���
��!��"�~ 9�P��%-��lX�Ӿ��?N&͉�QsŵV[�� E�g�|Mvz����?���Hs�bl�"���^yf��p�'`H���u��ۂ�=��{<}1������g:��zԽ̡��6���n��q��ォ9���}G�6�Y}��I;o�Ӣ6��c�����*���\C�LO1V9͑�*�m�\�����6y�06	-~���e;�b-��ߨ�� ���yq�i3 g{I���ځ�n��ú+m��>q�O����7��� Fμnx�N�,�*P�;7n�FT�5�5"O���)�ǁ5����f�{��z�W���-��|'n��V�����͂`�P>t|������A���� �0m�Q��(���q^%�"�T֛�m�-��R��@�#��b4C��tܓF�*�W��ݧ��y��;��^�R��T(aK[��<x%5\ ����R�^H����RZC�]�w�G�2F��)     >��E3� �����u����g�    YZ