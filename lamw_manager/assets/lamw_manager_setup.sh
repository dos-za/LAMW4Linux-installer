#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="985143234"
MD5="c836ae27a924a86d4f5c6668bcdd054c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23568"
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
	echo Date of packaging: Wed Jul 28 00:34:06 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�o_���L=��E_)h$fJ�
F�.��M���\F���t|͵��&���=�^jG�T��vn�ױ�ʢ�l.d�f�i�I�ΝF�%�熏gQ
�Nlq�U?�=�bSc?G��KͰg������w@�慣|���x�b��C������F-^�S�|G�`��3�6Gk_�K~1�S[?������@�a"}������.�_$S���+˲��'"��-a�kd�Br��v` �t�c,Uu(c.��<r� f�7����l�R���Oϟ��K�����KX��RA �ޜ, ��68wʾ�'�^{��;�Wr��I��u��w��X�8�DT�.�x��C�Wѕ����Frv�e�u��wF}g�"���:)��c�D��e�Y[(��Y�'�u���G���!���ǌ������d���NH:�W<X���Ej���Y���
��G�j;�x�c����GfK��4��z��#��Tu� �Fu�2��썑��V�t�4�����/�K+�֚;�]�m����w��A�疩�Sg���\m�O@�y\�C �`��~�"�n;H3���\q߱�Mg�C�r$9� ��
t$�n���(T�
�$9N�S£�=	�Mփ�%q���$U��>�FMZp�A���#V�v�c�F-��W{��G�<?��bV���<:�������ȱ��p*�+P�#�
�SYJ^<>uYs�$�8�U4��΍l��PژV?a���븇�0QA�uOV�U���KmE`mr-d4���R�${���w�i>ix��q�M���P�l~5�y�#><�(���+}J����˦�C�u�0o�O���l��t�U/�+�\��2�O`3�*�k��1�T="����cD&�v�oy�H��+u�[�!&�*7���U9��:��;�e�(/O]�Uf��A}{�e�$�V1Zx�0b�M��?Bk�"	R'��Ť8��>����P�Y_/�oF�,᧏����{�X�Y���3%��=b�s��辘�?�\*��s�����.�/���j�V���9M\\֡p˗�=�8�"���R��>q��!��ɤz�|J�뀂�( Ek�MDU2��Z솑����%~<�-9�v�)�Gr�O� ���$9Oi��xt͍��U[�5��p�C(�nd�_���u�"��~�C9gA+�Ww��1]̣t�Nx�ɇ�^��=��U/}:�Q�ҝ��|�����G����rr�B'_&�������v�����{T��*l+YH<��jGUZ�����ҟ0�̛�/��Z�3؄�9ͬ����k��������jmI ��<;e"��*.6���[P�bX;a|y���Gh�'�$���9J��������G��6�n��y���N�����r��>����sP�����*�p����ѡ��ܸu�moQ����+�U�r��Jd�xr�����0N�=T؈5}���Ow6��/|7��&�?	�SGn��0/�xDٴԧ��m���c����׿�V�FRh"��_Z�\J	e�Ws�I�5���^��G6�����vzeTĄO�*`���U�z)]��l딣���s�?�ߟ:��[3��P��G��7�eUlp���Q�Z�������iu3���%��T��?c�}�@��3#���C�u�vW"�ݜI�]��,E!6>�À7b���	�t�e�*y0FL)��*�,�) �p�ʾ:��_�ep�f�C���{�>�qTP����>��T�~n5�҂�j��^�ۻ����`�h�j�l&˻ѵ��kiY�g������wئ���������ϩ�6v�|� !���FV&��^�r��ΌZϊ�����`(�TI{u�<��3�eE��Z�mgEp�Uﶡj�y�o��h�Iu=C{(ɓ������(�&i ���x�M�Ԇr��&��8�B��,�V�bkS�U�ڊ�0!po�d��ְt�>��d����� 1E�Yno�[�9��-�4�d����+���'v�������r �H$ȝ�`���p�\w9>�f"�����CN�ז��x:�Nxp5��J�FI�7�:߉�["e�*V3�\��J8�@liW�r��569�+:��b/ �Z��}'�i��� ��J4���\�!�o��Ÿ���G�w����f� ���>�G�.꬧u�0����@$�N느W,R6E;���}�$u�������~���Ӻ|SO�8l��ry�>�\t��m��*P��>�v��["�3�rT;�/T�����|@�}� o������P��Hkj���z
���2��JK���v�q.�EE�[ ޯ��LZ��sa	�}�Bf-_�l5�]������H�E�A�4
}�-��%����;�[+@5,�F܉��C;9�B ��E�e���K�d�=��E�~PA��>\��/z#i�����e���}�֑�p�d2��\�m<\s�Hh�TN�?>�n�ϚdKr�0;F>��;��x��5�8�y-��﹨�Ӆ�7a
�n�$Rr�w���l�	�F�(|� q�+TN����ӬtR�o���;''��]ؐj<0Yc�[�0%�����B�m*H��'����7��w3�r�S��q�w��N�i������tey�4K��W��Yܮ7@�p^l���&+��ЩR�*���ʥ5����٣���l�+���?�Q�3X$hOxɤ�%���Cw0�L�hc���_����tƨ��o�G�I��|=� ,��Õ�}U��u�����l�M����������L]���q=���\�6�{���њ/q�js4O�}ܚq�D�>�<%�T[�:���d�p8%���L�{TW�����a�6�cX�G�r�f�9�Cz�Z
`º~`���,�aR1����$�����rY�B��WIu�3	Ψ}Jy:+k��zJ��ze�r�a�Y �6<��̲:��Ʈ����W�Lӷq	@���^��vj��h�.�.�6�t�lt�6�/x�?#)c%k�� �Ӄ�z�&��JT'�xxm���8���ۻx�n�R��8��N w�
'}[^���d��A	��3�Lw&	X7���#�+#��1e�K>Z�����.L���Gk�ʠ�n2|*E�iu��ǹ*���11�1��m�pPء�f~��L1��c��ci
�|��AE� n&/'!_�.�Mij��?=d*���*�E���:�D��x��X�����W��bH(0��j�Y������e��L�r����H�/4����?	�^���j
i}����HKQ�eJ9;����N<�iT��'_��בq2���%a��#RdS����ï�AF YXU��s[_)K}-��N��k]IOg�hg����hD��-.;y��P@>�3�~�����	�M_"Ŭt|%��>�򪕷�r�T-��u�w�P����08d�"P{�i��[��w��$?�P ���N�¡d��QH�cA.K��G��&#��)�h�{ �S'�А���̳o�;��[>=�S�#�I�A*,�k��|<!]AO_���Y�#Y����s>`��4xK^�w@e�>�`ʢ>�v�y��Y�$v��e&/�:H��� ��n��ٸ�m�����jV��A��zP���<x=i >%z������ī�G�J���5�tw���m�A��J�a���H�,���!��6u$ف*�<�w&;�me�;]�ʘ�x�Հ�-�-L��S���X:#��T�kիN�(T�����ݡ���������N2g��Ox�0�2`���˶��I�BW;�����/��[����xÕ��f��(G�n��38T�������L�����#7	��;���D�$�mD�$7KQ�U���zSL�5ٳd��$�,D�����Z�*�`����K�;U�&_�SG`s:#r��ѧM^����cX�y����#Q��i�8���2UP�=�����|�6,�碌��K)���4w��{�� ��j,�b�G B����B�q)IN��i$����`�k�ǳ3n�r�#�y�<H��#W�_.��X�����e���pz��5��dv"  Q�u��m����z?�'�< y(���@��=�#A��]��G>fk��?�q�����22���uV)lA��S+����U�7�^?S���KU{�X->��Ke�_�AA��ɴ��f_��f��IR[�A�K����x�Q�$Ė��^�AT+������4�30FM d�W��������|�	�;.l�{Qq2<1��Z�i��dT�"@t����"��m�BV�.m�=��ǫ�un:t�� %� ��ὂ�x���c#�I\Kl#��+(���~0��ld>�%�q�URR��3�vq��qj����@�W�u>�>�]d���,��(M��1֐p;ׂ=�_$LOXw����\Wk�� |Eɺ~L�Xۼ��9���>o�BQ�����K�2�~G�3�tE�m�ش�˵ �t�����κ��d\�6�sKk��~�O+dN�0���Rm"�߶�NzV��
�)_a��a����G��z��I��v��б�on��ba�N����Y�{̟l'#8������=��H�7o���gXt@-vل'r�Y�H-�N��~��i��P��]�^��Y�D�_|Fli�#{���"�{:��;J+�p�����[RP��4E���f}"��O_���/��o��z����k�>CW��k��k��A�����+.=�)t�Wѐ͟��/Ԛ�h��M�G�sM��h��?��<Jr܍�#��K�%fNf�@5��;�z_�/�o�"|�����rgI�AZ��ZD�U#�pp6�_W����%a*pM��z�W�T���_��0�V&	����C���|��&�[� �� *c��0}Ja���]�zn����9�\�t&��������h�nS�/����FS|���T
�&tB�|p��fw%Ȭ�ne�(e"C��l'M�D����Aj6O �qmظC�o��tb�{�S��ߎvnZ�yG�jO����Z���Պp3���|1�ȘZ" ���/En�ᵒ��g���������x�s{��pZ49��~M`ҷo|�G�Z�F�� H�g���p.(�pH8�@�*��j��*,e@*�Ħ# �S5�ߩ�Yy��0�`�|\H�E+�!���63}ǪJ���3W�s�Q�7[߳�錾:��M$~��>�έ	��|��hT0*"���tAVL" �ۚp����\d�`3+�{���f0OR�,)�)�P���P���ieK!�xk�'*�8���V�(o�ys���RC�Vc�H������Q���T�(<�j���W��éԁ���Y�.#���3 �RH�<4����!���.��ˀ��Ʀt���
��1[b��������L��9��B;�ܺ�l��;Q|�'\��O�N�	�(�,���M<��s� ��U�����Z�ٿ�O8�g������^��HY�e��rOp>��%��R��f��Ќ���3���������v�2o���
E�&Q�aNWXN��쌕�;�Uf�bܟ��C��?�:F��˗��Y�1fQ���!.X
D��8Xss��iW��4�8z/b�����ѷŎ�urvWNJrC�P���_�~�Ӡ��~���≏�n%
D`�����Ł�m��q����s��*���˰��'Ŋw8ǯ-(�
�+CVS*8z(�x�����:����4�E���#�X���p�sg��Z�7�6���B,oܰZ�?0��e�����$�m
>�k�-Ei �=i E�S� ���ĥsEV�;koIEɯ=���Q�L�y���Y��ߞ���,E����I"�2dvh�F�A�*aq����2�K	ƹ�(��	a��#����@��L�5�!�'����@"?&�a[Tx���Q0 Iy��2U|������K�0����T��h��fH�[既B]�rJ<�s���I���wE)z/�,T��Wx�Z���~1�&�������J��������sp	�r��N�կf��.��Ĳ�c�(ƛzEh�	������
�bW�8��&J-��sǏ#�ی��i�mwv��ʛ�ec��z�`eWT��3�}�0�羆as�'�^�Ŧc��iv�-�`G�%N����ݢ��q����x�Z잀]��PPN�eX�/^%~m��>أ���+$��M�s������*(q��l[�
"}�]>z�6��1�@��~����Þ-߉]6�ҔS�O��~���8���`�@Z�-I]��x$F!���ܪaO~&Oc��S@�X�����ٱg�k���t{'5�%�S�?����b	-o@�U�n����N���2{�(��1����C�a"�q��5~��s��A�.��a�swˋM���V�֠ͻ��m �k�;��ƾ3K[}�bd#��w�A���5x$��l�	'!��ߚ����=y������Qia���+`���B�#þ���"��sf�!��L-�m��4ߑrra�S�C-�ω7�@R�8�"Y��-�X�o9���
����)I�ک%���yPjİ�f*�(x��0��ѷ�rN��z�Et�x|`�8լFޠ��5}!��T���s�z��pt�J��p����m�h���U_�S"���O�Q��A�P�X9��صK&}1Ȳt���CIt.��;ȴ͚�۷��X-�)��h���;����x�%,�u���;���`��t)�dS�#}j�f,Yw�-�z=,���>ick��i�_���>6���?F83�R�轳T���&G�4,~�Z��ʻ� r`��\
k�.��T_��'�d���o��,ٚLH?Z�I�|�L�!}B'�����?V�d�Wq"\���W(ǒy�g����)V22F��"뱈ȩb�&�'�P���e��VlZ� I8[I#��{�)�b�`��5����w������s��>8/Qd}kT@����	�EȨ	�j����S��Yo
�N6�G�lD2��j����a�5u��c��Q/lS+@�9��Zo�ʆ���غ���Ԝ�u���Φ�Rj7�{�>Z7����\�&Y�?+��?�=����r�d�����S�W��v�py�M���嶒�7��Oi9;��S4J{[j��� fn����&��5��!O9�v�������Ͱɖ�H�-�E�w��~ *�x�>�D���r/���
�0���� ݚ�F̭�ś�A?h�����$O�d�Y;��dX�^�\��Hl�9�1�x��v����A�]t(UJ��_�[�v/O�z�S�t���ZǑ�{e��'�j�:��x.�����%#6����Q5߅%�ML)�KR0�<e�+�����Ss��⌻y��_�߾r��m��3h���?�R����75�A�:-�A%���mQj�9au�-񘻇�A�ˑsh�rrV.��V�t2~΃{�'a��	o�К`t�j�悊Wr�c�m������+��9�S5���}��&��J!�Ȭ
�a���3��s'�r�H@�裛Q��W�
"L*4�kW$97qn��b/t'�ۄ���-o{埤�
�_x�{�d~���%�mw��l
Y4A׽Mv q:�H ��-?�����R"ˠWĝ��JK����Vsp�q�$��So��%}o� ;Qq�,�V�T��r��O! �яH�v&2qΰ�����+�L��7� �_g?��pR�B�5L�?�V%Oֽ��Ś��4-1��(�/²N��䋓�;��!LZ ю���eB�y�1o��'�u5x���!k8�W�z;øo�ߋ�"1:����'����|�Ӓ�=]-8i;��l��2�M�����u���Fy��.�S'c�<����_���P_,��2/H]��S�*�{��P�3�D?�����wk<��윰Z�(X=�ܴ��Nm� �Ǽ���,+�]/��S����� ��XTU-}|�K�;��*����ft��*�yd�ʌ��<�1��'T�$b��D������4�7"|�s�7�o��d5]w�*��r�{��C��o+�.�[N�?-�����	e3%�X���A����0*8s�Z"�s�{{��&�!Ӟ;�1#F�J*zVO����'�zo����(;�ĞK��ihT	�]�A�sx��|�5���������c]O?>�����a�G�d�|M��g:Cɾ!�a	���+�����+$j���!����y��0.�!�ҍ'��{���pDYE%#�)���+t��%b0!f�s{BFZ�`���r�G���<�X�@�7>�]Pu��a`is�i�YhNR�s����[�&�mQ�ӏ�}���T(� �p%xyma�h���*��Q� �1��m�F�"�l3
�D�����ӄ��v �N�~/K��d2ڸ�˭�_�M	�z����,.E#��)��3���3�K��3�Y+1����N�~���p��8��:����K�W�Y�N�0j�UfNHdw��4j2��bUNp��T���0����{)�ǵ�.�P���%�P��Mгm&`����%f=�~N���V��ɛ�����z��1(��h�>g�A���|\[f�AtN���Xl8A�,^�Qyp�'���[���S��ڦX�Mm�0S垆�|.�˘�ș&A^��P^�z<'1�QH��d��k,�xYNS �Ů99�W�٤�k��h���݀�ᓆ]=�ZU��m�����Pv����2�-؆v?.�47آ8%��Ӵ�2
iw�.������\��Swr����8C��n��9��C��5���Cf�c(�#.�Q��_;�Y���7pѿ���o7!H��k��F풛Dl�M�S���B��Jp���5;c ",ϱ}���$����y�]��_OS���d3����\����9���㒦�Y}SoEa�t�i����0>{F�7*��wPzzI"0}ă�k�:N��F������+CZyӮ�����`O��Q���1Q��#�N�1b��H���.C�pdX?���Jr��1�7N��4HR�*X��I�SQ�_��z%*�֦%�[7Ye��E�rT㬁Ը{3������E�T	��+��4���1�N�5$���	���\I����\������:��_/eLU�za}x&�h��M~��H�-�����k�`���ڹi����П��4K�n j���M�{!�Ł/�G=4)/�=ч����
|"��#���(c�n��;�A�>��N�JI)�xKi�*�~ ǻh��S�}��4��|BN&vB�L�E��e� ����K��x2s���V���.,UӜ���"%��Zz&����|U��8���wv�H�c	���ᶋ�/%�({x�t�(@��zm?~�`�8p3h_�*�t2nmIk9�O�6X_��V�PgN��*#�U�.I��?�R��{�Uf�&�^7:���\(�/�;���z��B�F1kk�od��U���t����A�Q!A�kkxh�'��.���/���88R�Nܣ'	z�|L$Z)Zc �wہ$F-9�/:�*�MP��r�Of�w�����-��=ї?��Ϋey�6w}�!�Ӕ�"}�>tP�ڐ u�n�r�L��t�b�ٗjq��vk��CdLU��Z@��)��w
��&��G#�<5�5.�b���`�Y\��Nd��]Hw�4ky���<�,��ƻ��sf�/[}���[Nu� Ǭ$·��xb�mH����-���B��w��5=z��P�VZrK����HW���/ڵ��g��n]�X7
�KҼ�� 
y�)����w�w}�i�%��j��+E%��^=񝝥S�d8V	�+�͚sZ��Y��y�H���8lH����f*�}�:�0&��`�=OV�mؘQW�m��3�NOR��	 ����K��'�I2�}H� U~ʌWQc���>� �7����&��}�o��z^NZ�2����`�����?G�Ίч��k)'JP�iR5�i�{�W��k����Y:I��:�)��}�3�PR���7�+0Z�(GP�ab`ɮ�h�4�G�
k�Ǳ횕i��!٧�OC��ImB|���h�����m�v�ņZZ��:�V��%7hιV�T���������~
ٙfQ�q�%�E3Xt�C��M5>P��f��g�ʡ���9�eҮ�d���zIѮ�V3�҇J
O�� �6�E`�1�Ȯ`y�(�?�b@[̍�U)���hx}�
'��+�#YѼ:��PqH�gC�U�;F�TBT��dɬi8�֢��
ZR��ť��^T���?�X�]��rsbE�|$�(O ���zXTOS�!�=_�c(����S?����@��v�ⅷ
�x�\��.N��,��WÀz<tD�5��P��m��a��N|	 x�;�F@���ʀ� bU�K��El��k�p�\t����z���Me��#^����l6����p��A�T�Te���F���t�5^ߪzc-��0�X�EC�B������ORZ֝�sl�hOV*��*�l����ͧ�^�i��MW�b�.rՋ!˔�;0�H�>Ia�ꖯ�>3�gj�*g�<A�W�c�}��\L���N�_��erH�<��B��bZ"tR,}�P�m\������q��#pqكl��9O����l�0�z0)�!��ʌU+,ag�AV^����(���=�o�X�Oc?��['�pz��������#�X7[s��1��YR�	#7�I�i~����3:9/���.|�x�ϕ�/�g�]�-�w�5%�A���u3�M1H��X��
s�������'!��j�\ȷL��,�'�{��:��CF�Y��9�H(��@aާ*1C��K>Ti��V�����S�����؀_�����D��m��):��HY͑�
�c��w�����u�!���� nF���a�ܥ�ܯKO��u���z(��4�<�qq�w<�S�כ��	��'W���X?�.l�L��SE=�Q[�{ �/�^8�}�c�S�m��`o����\�8os@�ڬrΰ��"�I�H�9F"���9ס, �}�(��J,Mo��rI�[���#郔�{Ö�r�_:N������vr�1�<u
ȇ�m���8 ��y�)����]ԫS�?���źx)2+�;[l��k^��\��p��i�V��[4M��j`tҁ1H��ivKB�%�yb�N�ӝ�>Ƒ%�;27�J�"d���jp"���L� �ƴ�w�卹i�Ͼv�"К-(]��̹�c&�J�z!�{�$/bYBJV�P t���L��o i|�t�7*��7;\*uK��%# ����Ch!��(�P޾��\�諱��X���^�t{��R�<"/�-���|[���33�887j�6x���iUp�^�O�"����X��/j4��A�vG<u�3�$�c+Ӣ��{s#��jj��;�~��'�[x��7^_x����ب�7�ea߻%��v9��|TA�����C8U�It�Wn���g�zm����Q�����4�~�x=�o3EC�����o�	�#������|5���Z���H˕w@�t����s��lN|�-��Vb�fϹ@�i��C�����掱���P�	L�Mȏy���_�,+zz�J��SilHB�h��W�j�P���ċH�AH������\#�6tp�����0^�ȯG@:,"�YF�Hd�E�Xk�� ^�{	�屝k�����y$Z�����O^-s��*�g{�J��Am5�Ğ�d0;���G����Έ���H	m��}X��K3�K�x
�����Ӣ�)��H�d`�7j9�6%N�Cn�
����/�H������b��nK��xæ��bI��}L['��Jhn��z����5�6Ch�����1����:y�Hq�b~ɕ�]r��@��!�+ڥ�Դy/7֏��N?V�L;�%ZJp�J�^�:�6��wpӱ�`]�˵�NO��c.AEm_g�ä�2:��#�	����o$}CHH�c���λ��:q��x����M_1�"L�(�����άΥeڬ�*���i�n�,�mC����>R�:�L�OG���Pl0)���$��Ӫzf�:Z��?�TӯU����)����6�e޵����o��0��$f3��Pz��/��~�E6�^p?��r'Y<��),�R�q7����NU�}�aѳ��]J��sIo�X�-�
�˦����ɵ�~��D�!؂�0l1�Jҿ(�f-��"ݫTb2����u�'�Y&&���r�@B����A�8�E�c'^���тd|׬?et����e�wƗ�2��iP��<�n	���n�'l듯�����_ѓq���Џӿ�X9&Hɿb�K�Ŕ(�<�T;����#}��B�<�f�wꩫ�4m&�ϳz�}�^���$^��$����
ĳ�+r"'Na�z��d�a��bK��*�!�~�r�XI���xnH'���\G)%����X�����Vl����B;�.ܡӶ9�8w�VwSpr�5h��e��gRFӶR�t�hjkm$�2�>Y��qQg�:�@jlh��\��Y�~p	Lp�Ģ��lˮIw�ue�0�F���Y�pl��>������f�`h{���2ؗ��Fj��e/��=d��c���"�瀋F/��Ekۮ�r �n����J
t~K�6�#B�86Oi���N�h��m��j�(!>P���2��'?�p ���.�#��6D�Î����,&�֮+/3���pߖmP���m�?���I,�>��O'�J�(@�ZBOW�'�8��	��bi���ޞ����>c�T_I��f@���2J��]$r[�h���֖.*e�&��a ���٣T
V�Xk$����>��o*�k4j�A|7fB}Ax�~��ͬh�%��;�Y\�������t�~B�EaF(UW��L��[�QF�j��^K�w{9���b)jV�Q`x���Up�� @+���5�ڊj4��SR�T`��S�n����x)u��_��9�F1�1<�t}v�^PُsRב։ ��A}o��n�M,�\ }I������/�{���P��`X�Z��]�n�;G$6x����3wx2����Ѩ��]���-�$z�`Ň}��~v�(I��)�JA�T�ɨ��#��}j
������j ���I�޻��C\�P�-�vsz)S .���u�X^6t�����+��åY.����[��ϺDsI�\h��
�Rg� �kg�P��{f�{�[�'��ִx���sC KrW�ޙ_�e��o		��+���M�ӧ'	:�3����1Y�1F�~�Ю��U%k���6d� �Dy��
6��w����Ȑ;r�^��]U!��Y;"Yf��2�,W�|�ua�>n�4�7�<:�9*�s�،�I&C\�)������mK���ʢ|7;�<L{�rq �����iOjk|*���;�*�W�
q�]�	�=�	`��4��|���\(���#�e'a�g!��ex���O#c@�1ϯ2pLj���	�f�\XI�Fdx+��DN�.�~��(ծ
�Ԡ4�^��-M�~�\�8Z�96���!��"����~��e���H!�2I��Z!I�R����=r㟑��&�h��@�:�뇉�jN���#X�LCQ,��`iR�q��U~<�r�/c/6e��J6����҇��l��2-�Q��&�)S�?�N��&|9����J���u膷I����,��$R�}4��%��Ф`�E�1������f��kLܱ�[���[m���.�F��D��
�ZW�n!a����nV�w�6�W�Ik���/UE�]U�hC��{��Y��:S��vڎS�FÐ�rZ�>joVJ���9O3 @�D�+��>��O7�K�L��YS��������N$��]43��()�wz{�M��ͥ��ضCS�Xx�f�C�h�-�Fj�{	��-�<��?Z��)+B�^�Ux��Z�P(�}���H1(V�b����#5��Չw97�/b`U0]����aQ�fῳ�I�؆o �9��4A6��ʗ�.9G�}��?u�	a����ad�u<x���1��$K~�X�iæv2�?9�?��Zx䰊G�B�׬���˕�w�����N��3t�$%��f��5����o5���Fo�Ina�[y�]�0����{c������7��·fK[=5�&�m�ޭ_�*�9�1����<�!_���0����d~Y�Q�����l�϶#��������P����f�L������m׌��z)�#�v�e:�tG��.>[d*��3M��Q���8D�������c[��9,����yр׽F�p�Xiς�Z���٭E�ѳm��
����aS�vp���r��'T<s���z�j��#D�������ɖ�U[-9|C*�:4*ȞVs5л<�2�ֹO$�)a݈:\���/x��{�\sH����f�j�vn�4P�5RF4���$b����$�E�D��#CɟT��"b���"y&��P��˙ps�&
A�S$xԴd�;�-�VoiNv\�T���?o�C�����;Ŏ޵у��q�/��F�fcH5�{k�9?lض�^�j�㵢u@�����ȻP��\�{�0�N���r*�cjV�TT�)��u�ܪ��t�F�^������Q֥�`1���YMb��^��V������������!]��@�?ڟ��M.��������{ad���ϐeC�ZH�b��������B�.�[h��i��1g2i�|=%��69��A�L�9�U���]L
�q
�in��w�4W��@{�y��#�D����/9ׂ��>�a��>�$uX�*��z6�ny*uq�TRULT�6�vF��C�1;��Dl��;��1��xS��u	��c�����j3�ҝ��V{|��X��$�k��&�����fB����,W��nH��M	K��H��(R�pѓ��ƍ���|h�C����U�o@���J4d�ηlc���(�8���� 턪�FÞޘ/�uyV;��*�4�Y�Gs��e� ��LfJ�qb	����f&+�q̙�UU�����=w8b�Q���od�(�G��CC�D�!��q&.24<�JH�R�˔�00�.��z�� ��뎅���?��C1G����R�?Y�m��ڧ���]�0퐌��p	��X��yų�cĶL6���F7#�U�R��a�:]��$�hQ���؁m�.����h�+����� �]�˸9\�� �:�Tչ$Qw� �X�BB����������=� �j�M-O.ve���nћp|(qZ�h+�D^T�
�^Z�o��l�Zv��c7A�S̈́9�ө��ai����������o�1��G%���^��43q��P��	�]�
��g
���z��~i�&IP��c� ~�����.7�p>�o��9Ź2l��W����2<���M��{]�oϖ�N�'+���	�de����X�x*� +���dܪ�ɨ��ߺD0hgH���g��;��wou�{joO��*��@]��[&�~�k'��J�����t���GG���x�ʰ +�~��b��0ƕu9�0V�{�H�U>����Or�m*�W���4]���%����ĳ��7�.��aD������������V���8k��WTƌ.��cy������X�{��e����.���^�I��!���׀�e#��ŗ>�QXQ�{�}Eq/jM4~�4�Ʒ^\�ę)?E�Q�\5`�?}��� ��jĳ����pT1�(��R�7a��m;c�e,׬���2�g1��8�8[�a�G�/vBv�҇`�0cN���"^o� Aj��^�ir"yPj47~���ť�GI��R	hu^�X�����Y0��9kS��a]b���*�q U^�[��$1?�2!\�����^*����^fFW�l�r�ÒU]�%n�\�a<��_�Rr��RUH"����7Mqw�/����M����%�+�P��uM(T�1�����S�y%�<(ۋ�}��jkY�D|._�GJO���� L)����Cl�ϡD�O���&����Vh�N<y�3�� _�)�2��Ԋ	|;��˾�V��,����
>�4�b�z�OӁ�ӳu5��G�>3w�~���Yh����J�4=�-c!	�Z4yR7HZG�%4�NBR�4Zh�������Ua9�~R�8�Q�4��̥��
`�k�HL~�)�*2�/�g�N��[� ����9RA�,{���2Z�	��2܂��~ɫJ'��g���������Vq˪h�-D���2R���`�������K�%�C�ګN��p>I���g�X�aW�q�+�_�M��t�M�ԗ����Ӱ0���y�~��8�ʙ��*�:
���]v2�E)h�b���w~KP`��2�24��*mWc�p�E�IˊH��dᙹ��$Ń�ru��>~Z�������7��79 N�[nj�����t���ΐ<	��÷H�������i�"R�U�.,k͓�����(�~��	�%(y=�r���aI,�����i��7�PG�u��G�����8�'���1���V=�:�Ly� ��Ƈ3�%ݚ�*��X�.W���R��	���D�����:��.��}~7���2��mwӺ�s^�����E�Ce�k;P�����n����~���/���������r�M�k �eiZ�ˏ�6B��N��%���A[��
!{���������"fau��5@�.��ށ��m�����|��ES?GM�%m/Q*�$Ҝ�Ǫ}���)�$';u����2��\�ά��Ei���:�4t`��Q68TG!�
�_��/	u$]{������r3��q*�$\�Nn㺆؅+z3��I*��Lq�+��\��N���"��L-�)�38=U����-pI� 奋�L�Mg_�q��6��<ɿ�XJ𔿞���q5��Q����0y�eZ�("��զ"�M}�.뼖��]N �W�j"TlHl���!�RTs,sH=�$Ϧ�M��
�'�����uZ:�`O������>}Y�k0�<��L�0~� �)��gƧ��	|�~�����Կp3��7�( 
5@�?;_��U=��	B���K�q1�x�y�)����@��������9]���"�I��n�_�,��M��0�/��%>T�_�:r��DVC�z
�s�޵�Ep|�Mp
��h�Ȋqf��0eoS{/�'��s���~,SbyiM�qa��k���
�ȱ��^=���X�9�e��8��9̘�~�v@���&H�� k��u7i��^R��,P(�_,�$�lO4_g��S���s��3��i]�2����|5.��|;X����{�2�z\C��~C���C}����(�wRG�<R<���Z�H>����˫B�$}m[�����`��O�p|a$[�)� �`UX�/��(m|�m����j��)6N��x�U�b�����z�ȶ�{~a5��r��WFݾC$��o]�у"��hFlBb�"s;�[�+�bfoI\��O԰�-��Vd�U�?Y�qRV������5���!�H��7�g���j��N��b���h����$�Ď#
�A�'b�|����q�$ERX7�n@,0u�����뛨v�ԧ���Qm�i��IM��&	
�c����F��
5�+O�K^PR�ϥ2���X�T�1�i (I���B���13����=�<�9�[Qm��<9���Y���G4 ߋF�-��@�v�'B��i���55�mq�0{��#����bo�G��t w�O?&��[z�SoU?�/j��zt�p���(�����z�c�̶��lRI4�?T��L���hWC@[�^+��'��-�6_�\������5������r�^���b�����;1	y�6Pg,Fy<`���fy͖�Av����m��gv�8ƃ�m�Dj3�m���d_mک�(�{�:�Nnn�a!���)���̬K�`���&�i��rT0[�ZCh�_�}��?S�:#�2[d���crG�l���t�N��K��3>��v�#�6���+'�T�;]�F1������My£Gz!.��� ��Ww&�K#p��;w)��p��\"�bw����h�QX���y{�|3���瞯�:|A�f���p�˓�+(%��]��)�Y��\Ç�z7�|��@���<re��1��c�@�D]�x��0��i����BFd�m�)zU�끚 }} lI
�E�⒨��������`3�,��,�]�cx����|jM��J��k���_�f<��HCG.Z�+4TJ< Do�e
� ����R;*-=m��⌽��� q��XxT�w/r���$8:�H .K�) k��Ҹ�{�rux���ϗ�sF�sڳ��@��	8M���ǝ��[�q+ �4�1^�d����ܑj�Y���C��z��ź���ғ4t���=���d�7MTڛ\^$�dtR�X;Go@�Ű�㉅�7d8�����Kt}�ݥ����g��^h�� U�]�)jJ�+��c����qO��2��hpG�w?�H��[n6"`��<�i�����"8�(���c�
�Sl�Z����EQ��w����b����CO��̀�y���$#�V�"+��P��i�W{#3�'
�h]�Mz��'�(w��.**��ʫ��eN�z��>�gYAh����p�ҧ_�7�l`�Q�go��䴠�o�1]���28!��O�ݛ*u�a� Ad��Mrⷱ��JOZր�0����;d��4��L�������^�Q�^���p����\en���yc�G^)�H]YT�H1ȧ��FzQ<m�˹Z��\B�4���b�H.A��T�z�ɧ�Hě�<~I��ϪI�rt�l���Gk�g���'���y&���9��Ts��{zu f^�w�`�F�V�떰��t�!��$h�j5�F^mBCN����sN�e���u�b]�^ 62ɟ!V��7���$��]�ov�r��M�u�͌R�'� B�}����,VA�H�%�]�T��� ��I? �+��v��g[�jn�x�gCCs�0�N]��xrD�ѶN��L�){`�ŪHg��u�.áЂ	�����#b�27�
嗰�����>��ҙ�� � P1h�W^��Sf�K7(H*���c�S"
��_n��ם�.�$
E�L�/a_x�"Bl2&���5�S !�,�șZ��ȼ���%���9�M�^!�X�ug\V�G%Ѝ� ��3�?�����Ǥ����a���$LKg��zl8��S#��$G���l���E{������*��(�5��=;ݰb��q1M�ہ��U�C��?=4]�C}������lM�c�g,1�K�}����@�!,z �˭6,�Zꇼ�����	�4J%� �C��Ͷ��*���y7#�����4�o�
�8TB2�	��3����=p��?�hO�U71�������)�h��	t�/I��l�l�,0�.vM9�T��.�WЫU毟Xj�Ο���e���I����&���;;�-�T�kk���+_������v>m@M�Ϝ+*�C*P�HM��n��v6@��%�c~)b������k���0F��z�A^�����H��C�(�"��1 2C�=�.��EWh��-aqs+ ���|چj�igjVж��#���a<N��<����G�\L�j�I6�u{$mk�j	����y��ǯ7�oZ��@�$?5���d�.	�?=P������VޤOQ�S��bER�O�0n�(�m]��q4��� ��������v��]Mx�C�5�@��hȏcA� ��w�}��H΍�fQO���Xv�J�-�\����'2��ۍgݔN��^`=�3��u��Pޘf=��܆s��*��Ϧ@2y�q�?R�c�7>o;���T��/��1�o,�!o�G'`E�e��w���4r$�rv#�n��Ǖ-M�K��E�V'M|C�N�����{s�ڴ-�y�冲f��BE�.h���v�&%��f�v�1~@Z:[��Vi���r;��?�������#[�?�&�Q��� E��\� �r�F-~=�mƗGok�G���q�����bi&�{�����#a`�y�"�����KNs9�J<���f�ؕ��s>�o��PگU�����4��x2��+��Nq� @�^�!�N\(3����r.�W��#�O+?��D5͎�Lj��%�t���ȯ���\���E:�bl r5���S����l�]�g����;�G8f�`��#״�r���p�F��/djb�h2��E<M���P� g���l�7R����������~�k,���|!+PZq��9��Z�kh�����%��	!�������T�Z.�:l��v���ԧ����nw�o�z�h�'�0d�}r:�e��V]T�y�>��J���*�Bf���6��$�~p�B�_f�Ne��*ɶ �O�T�����5�픣�R���m��$>T���｠���j��;����W�&IJv߮���(��'�i�ߤkj��| �_�
�!r�q����x8g)�c�`�u.�m�SZ^w��*�O��o:���>J�;����Q�-�Y�:�ڕ�O�9�+�y�?��$!?��vF=������fTz(X�� 	d���������%K���X����&,j܀!s!�^�����x�3K��0mQ����A���><�02.���We-#�ƨ�7,U���S�\W�~$W{�.Y.�t�M���S`�qgz�0�J�6��T y,�pn��uˉ�3�o����6#C7z*�-�+j�d�)��SR������\����S��,�zh}�?��zs_��)�ƫ�^%��l�KU�SP��4���!)�S�E��p�c��I�0��Ƥ�P����ur�u�8���[>��{ߝwi�`!�8n_�h�.��d$��� ��Vy���+��Icމ��?���|�K;�~��::򕉁��������v,�O����'�H�Ճ���1��6evtZ��J_;�A�h�OGx2kr�{���4��k��ՌfEǆ���j@}���ds�ȸ� �k"�on���3���T�f��'�s��"�l/��'�"�&��}��91��d��z0@�Z��J&-Uov�_��4�Q͑�J�C}qх�[�]��Q��/F������kr�>���\�ѐ��$CF+��ԃ�b�Fp��H�� 6�D��ݏr�H%������i���˗���FdH8+E����rV�ø�b��3.�� ��e�$i;�JBo�\�����9�<�����[>{�d`���ĩ"�L��zHAw�Cm�l�e_8O����|s����V�n�����Q��-���\G���?	ܬ���j�sxS���R�W�*��8xv�*��x�-���������j���+J�vi8�j%(V�z�����\NO�}��xt�ChS�:��{�(.���4��ȴ��?�[8rD�*���a}\D)�A�d���%!�n����9� 	z#���o`*��*GWJ_�w7R��2�}�Sd��t��hcO����s����{_~���W�~R)�21����|�JO�$°ҕ[�����1�H7'Q�5�Pe�(���� 
��nu�g{(�ʀI=I�N��J�&��j]�{=��{u��
� �;+�EX_�~�Չ@�x��?�A�&���i�<�?�InT���/�ඛ���Dy
���=aK�1�՟(7�io�ʩ�< u�-��ɪ����2�?�i����57�jI�	0%��c�L�����y��9T��3�Q�nt)���+  ���>X��"V�&)k~����#)�K)���50b�H�/Q@��$��[���wq}9�!/+�����ƃ���c��E,d���( � 	�j��аn��E��c�-��lHW��UQ#}s�3�t�:��~8gl�?V��};���u� �Rxs�8K�@��)0?^�g{�=�nמ�RG���P�0;?8���&5_˶@.���?��{Hʆ��8;.�O��+�:�ӛ�G�$�_��H�Zo}/���ܘ��/�N��+�|����tQ%�vU�A��5�S
�'SX�b-������ @�M ��t�qA�j#�aC�VLZ&^ĝE���ePL�B�Mr��Y0W��G�ɚ��s��	��z�eс׹�<�[�_�����W��OájW�=$�Ԧ.?�J&�V�Q)�Bo�H�)<�*�ᴫ�����/�f�w���cB�:���ٔu���mmk�]HZ���As�5R�F��Hu۰�[P5z6�r�2�G�d)9�̭l�o5��i� �J}	{u�Lޔ�7�T�e��&����i)*�.�;��>��j�������j7��g�dvٟ��p�LV$?S4�WC��ZQ��Ȟ��R���U��A=_�A���M�Z��q�lS��b<�6i�0<aW���WeeW��ع}W:z	�/�A3�k�7n
�Ԝ`v��8�2�>o"�Ӊ��l��6ć-�'��z�z�yb�k��6�I��?T�����V���u�?�B����ծz_���M��Yc{l�
�բn�T1n5r���� �ۋ�9��1������	����pRcb�� ��i?��޹�}����$I�A��;1�t)
ߞd+@[�蛡.~���.�Tʁ\���i�o�}�}�h~L{/,9c'8n[���m�$�{�K2zR�{K~�v#���9���oy��g�z
��3�ל,$���ð�n-VXH�����p�(�6u�]c�PV{��P�~Q>�������q7����XU��ʵ��[q���Ga�V����L-��ì#x=�'}�,�����9��U5oan1�U�	=c�H%��O�,��٧��j�Wu)���o7y�Tmt�`�kN��:�eg��ۡ�	Z3�j��~�@�=^D�/?+�u����r��2^O�+�o)/�kR��Y* 5���VF4���AfB�,!Q6h�՗YG���!kl<#Ɨ�k�N(     �����p0� ����t�\��g�    YZ