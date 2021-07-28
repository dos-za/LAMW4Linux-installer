#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2614094255"
MD5="e89182a68fc6b06050be170801e842d8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23584"
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
	echo Date of packaging: Wed Jul 28 00:31:48 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D��IAg�-׿D|��gb�!��	_�U��jA\�k�Qu,e���̐b@�-n�0}6�H,�:<�9�  �3����'ݞNC	D_�?9�R�1�'uJ~zO�r����$'� ��_d.���pO��mE��j�0�:���Ӧ���䏸�2@Ā%t��E�
��-����l̺ܘ�wóg�@�c�����'Yd�W�`��q�TMTn�p�d;��|	�{��
g����2V��Z����G����sxO�u�;Sب�&��O�݀��	�Z�-Е��� v�p�D��F/DOfd#IwwbN�w;R6���*}�C�l���s����;���}wcyS��~�z���&�|el���W�Db�2�xDN8EdVt_+v�"�d\�d����D�`Y�\˘�3�� "$����?|���T��`0�U�Sl�K[F��iׯ����l�2ʃ�W�Q^h�,�D�ϡ����@;�<�8V�	j�'�5����Bi`E���_���p������ =u���`f��J�ΏL���ge��eg��C
�Tp{����Ֆ����� x�%{.�k��%�eo�"��nFc�Zָ�JZ�J^3�T��&���bh�jq�5^E��[n<
!��@�o)s��`�z9�]���tiO6�2Fj��zi����߷�y�(�~��\�2������C���Ŋ9��8QgS	����[�`�a,�����V�MnАa>�۴�~�tmH�<d�V���~צޯ׳�/�2aq�-M�
v3�(Tv���>@P�y�����ҽ/z�xjj�+ �ݞ'�Se�(�2� ���l{�t���EÇ��Z*D�(3"�� ��c ��Б��|���8KS)�o<YYZ,�Sz�{�_bF�%�!��w�6.��Ď�T�/�Y�ye��/���(��?%�k�j��6�_s�I_�Ɇ�y���M�:+�;o`[��[<c���B�7ث�-�5����CQ�8����fѫ$%f���ɰ*�19�b݈3���R�hF���Wl>��gP��n|Bڊ��mo�� ��UE�����ĒW!BRt��8�H�c^�����m�
v�1j��{_�l��60w�F&��('%$�M;0�A}r�0(	��IEX��)S��[��r7��fNgZ��b
ci���NFۈy@͊�f���Ѧ�R5�"�H_�`���)7D@�q��6ˎ�T��?�E���KD�ߵ�G���O�A�����oy�.��9�tz�n�mI�)M:y7VtY�<��X s:`s(�f\�Q�Vs������}��"-	��b�+|-�~�L�/�.�`_HWߙ�z�-'��E���(Y�|"�@&��h��W�*��K#�2ڎi7��jS����L�;n���H�аt�c�[&b�2�ĭ�I����%P��+΃orn�Nl�/�g��_wuUz��+�?k��T�(��w}S�}e�z٢W��അ���ґ������с��Z� ��ʿ���e ҿw��	m����r�o��`�۾,
4��x�y�c�,):ub�ܕ���XxZw�ֵ����B�i!�8��'�ZY�.�/"���e$���#]��v��I���o�$$<��[��Ϋ�ʗ`�>��#�mw�P�.� ��y]h�z.Փ��_��!x������Xu&O��Gw Y$�6��16.�x;jo�7Լi��O8�Ȭ�J�*�hG�3��h+JCA�`�Ev�x{����L|�/��/�12���� �'3�x���v��Z[�{�-�C��#��.���~�`��.M���H_���FC��
F� ���@�mp⦦�$��o�����)�(n��%ңz#��0����� 7���{���D��:+�����ն4��ⲊY�!?&h�;|��5Sr�Aw�!�I�v�y�����5,�ػ�l��͔5rҋ�Ma�1,%����^e���
���c����0��F������ٍv�iS����a��TwՎ��[�NQ�w�\�Op�B�w7��n�K*]C��$�I/�q�Ľ_��X[��7��f��1��w������􎕉�'
�_�4w{�5�����y��p�<}���tT���{4�K�i�E7ؿN�y����Ԉ��E�
�/?�d��<�DC�*%��k�L?4r�!��-俊������2�A�=�.u�ՠ=Rk|�����8/9���#��&�b
��LgQ^��7Wb�89�z3>
q2Q���)�^�����S�%�K3F/U�7�ri�Ц�r��3�y�u�i���rɚl���1ŋ�\���	"�<gw����]�R;C�w�s����J�5��@����*[ɣ'����B�[�U���R�����Ŝu� :�):%>"���g+�󢹷\T38�E��FZI�T%�(���P���ןi�?�?����A�Oh6ت���shz��m����ؖn7Xrpn��$
/m�^�X��n�70][N�ViO��&��np?�$�*Z�i�β��͞�1'����Q:)͍>T�<�E�V'u���#}[�}�)�]�҄�h����>�TG������O������X:�w-�wV�E�l<�X�V,�>�~CRK+c��(�[��-����&�6�3���n��=�(ϯ��0<��f��E׷xaEW��D�Z�7�>��9{J�eg�B�B�N�F�h�����ZȚ��%��$��!ƶ��c�F8YU�t�yH��{x
���e6��
��,��ݠR;n�����I`JO%7����/����>��Y�=�>;	�"Bz�]L�.��t�#��'�}»5�ͨ)�|��EE?��R�����U}���]�d^�aܒ��Փ7�"�v����#�����n��^\�����7;ۑ��N���5w+��){$�%�huJ�&����e���>�k�͓�|�c��,�x���b;�Կ�J�������9�o]��w�֬�~���N��aId/%�P���omuO-ڜ��≢��:��i���ɑF�؁ܠHq���5}~	}���mQ��L\�\�?�`1��=��JM�&8�:�ر���A��b��X؋r���R�%V��|�kI ���Y�"��T��H�[��.�74�B �Q�m���[��]$Ցq���}���/�
�%�H7�����{��Q
���!y)�Ϲ�	F-���J��@z�<���R4��F�n�������;����!�P%�8j�w��X �M<<LV��͕XT�U�i*�n*��$�v�ާk��3ŝT �y�;{�X���sy�1����RӉ���L�p�^�Հ�y�F����D����՚�.d	J�0�_ſ7�G?�ӹ^;�˗����/-����0�C`k:��@o!�Xc��22:+tS���A�Y��&,?��V7ڌ��%cp̮��p��AU�h��7=O��w��m����蜾)�M��O��z�b��� �)�"��i4nۨ2lqQ��.���s,s�)��b>�(��f�aV�
˗�+�U��N��/�]�����U�DYvuא]���Ρ(ay����ߦ�&\�
ڬ���!U��²����>O�\w���R�L��2|��u����1���ɘU$����ޙ��-p���YY�'�,���\2 ��mz{�����U�&g,���%=���,�6+�ޅZ��*�ι1*Si��1��b�t�)c��D��nأr#�jO�)�ڐt���<R�B#d^�[����b$���G���_	{�.| ��Yv+���ݔnVQ�	��c��06˔�)�ʭ��h{4K	氷Y:�U�Tn�뙪&ĺT�ÐT�'9c H�`>�*���D���v��/0�1uR~ڬ1�>\g��M��[�ԯFO��UXcx�M��ԛ��Mc�̨�wC����n�8�6l�Sh��e�򝇕����M2�(�'=s`G�$�S�t8W�L��<0�x��z�U�8��r����R����jO�|�E-e�y�f
��?l/e��n�~��b��uQ��D�3�m�Mq:�D�AIzu�S{���G�!�i��0+<
��{e9)�~����s䨬e�c�iӟ�+����Q���1�u,ۼaǟ�,�-r[�y�2n:4N��ұ�4}���YT�E	��
�7?�x!c&3���7*b��i���R x��{���+��Ϣg��!�)�ҥ>5����1~HdV��e��aP�C}?���p-���y��jU���R�^���~�~�
���ܓ����m��۽��"_��ow�-�����֣ֆΪR����ⅉ��Vk�c�s���l�+5Q�_@�p:�%�GY�E�:NW��8�\�m0O�C����9�G=�k@-�T�\��n�2׭�,�pBJ�����[ϰ�аs%I6��"�:�����R���pA�0y:��6-���.��6[��k�b�'d�������:�yrw�2]
C v���.F��HW3k��Mjs�G��Ķ��gТ�g�u)�׏��)h��Mw�@��Y��b��JQ\tq���I/�#�7њ��M�e�zgL��n�f���OA�FI�d�ح��o
m��/G)�@:�1��^���Y�7���%�'��%w��]���l��g�<9K��J�����~�
�S�E�<�Щ��N��n��
$���`��afQ�r�%��	�y|fX�zJ�ɗ��$ٷ���e�����Q�	�A�]+L�����V]��G��$۵��[�\=��>_���L�GTK���ÿ� ��}h��v`q���/��F?TԑʪTRx�W���ZV������ס0�T�K���Z�k��+'0+O%�#�Y�zE�tRu��d��=A���:�����f<Z-�L�D)?,�NВ���Ą�f�	�<;;UX�A�[JfjmR!�����?	�ɼg;�-o�t9��cx/;ng��}���.d�)�l��b��l�U����ˑ��]�	��2��BR���f�P���)GU���7N�r���+xz*�I�h"B��9(θ�������|�$M���>���{�ӽ��@X��������#,ⷍҁ���$Z]k�}o�,�  f�g�ȼ��Bg���#N�zG�OYk�B!��,��n*��w_w�bZ���wD%jC��� �W��M��m�Z	�Y�qD��UЂ��d&v��"*��O��H_Q,����Es6�Z$��p�qڡb�Caf�p$��3F$7�t3*J��EW
�Vh�e�q��:�fŐ������$��~������yC�����f����ME()1/���$�?�m�x��Djq�o��7�b��ȁ[ɖ=���P��7�~��Q�Ճj9�W����P�vH��6&(MY	���E��A���U׆S(�%=,8��9�*�¥����H�4���L1ڼ8��XiH�l�Gb�ɫ�N�OA�A�%O�v.,^��,�70�~��x�EN��ۆ���x=j�g�ϴ�}R5DH�f�g��������e
#���W$��*�Ì)Dq]G�ir&[�n; ��$�X
+K�y�������\Y~�8K�������9�W�fQ��*K-a@zAA�&w*Z`�sx�-QYY1���Lힿ�*k��R���C��s��7�k�u���l|=%�����R)���@���S�������_�
��zƨ�ԗ�+x�����o)�v�µ���mѲ+-�٦
��Z罅Y��l`fvs^�h�W�6��� �t&X�<��-q1S��.L�����C��i"�+0p�a�.�8�͸*@�i�:@[���{�w��bN���Q�]�͘#�6�Y���eB�
qj�Ҫ�}�I����>�9�Ț�h�Y���tҒ#�'&���.��;��F�±��)���̷�gW����?�FZ���h��R �>�p�	|���9��:��5k�f�v�<����ܞ�̠�b���>�i��L�U��R��EI���e`�b��	��7U)ތ���6��!5E��U0���ILW��G�W�*�'�2�zߤS�W�^j���Z��p�!�͘DIe6�ϋ2Y4��p�Ჰ��qP�vR@Ꮄ�9\̏HM��i�A,��AyH�-�!���%��O�n�v
=�P��k�F��A���{�]w�p�ǉ̩S	�8�lb�����Cl&�"M�g��i�1H�"UĄf����kvJl��3m���Pf�kb�����$\��ļhΌh�`����4�ۄ��T��a��;T���pBh�8�}I[�c*p%}�b ���osja�4gʙNa�P�9I�	�}Z��sY��>����	ů
N��/b;�}��"��,}7�^ǷT��`^�Y�X,�_잦?������'g����P�7O�~��a=$rˍK�EOW��0ΛC���̬O����h�ҩ���7��H7C��j�M�/u[V٠�*%U�u"���e�}װ��yaD�����+*�J���1L&���#.{?H����WᎥ=B��Hxr�|<$f
�v�����/��?9�?5,�K�t�lT���B6>�ﻑ5N��@�2WT�Y0 �X-��.E����5��{�.-Q�_5P�u��m�10Ȩ��r��Z�J�9�dU��rѡ��G-m@���S@�����^���;�?��87�*��N4��&ozN
�;N:�6�˝?���K��"�o�e���O$<<�{�N�2�.,��O�H�`!� 8U��\8ѝ����{h"f�Mf�s�ˤwS�c�9����g�o�6�X_�٤z����&h��=�����N>�mE5o�N�s3|5�޶덁����B��ҴI�G��hͳ!��=��q�"��O�L��<'i1���i^N�u�\?��V�5cŶauH(w�W�<�^z�N�-����M?�*VoSV�D4�
Һ
-H��oD�5Hn�b+�.�z�g]��ʐ�`��:#�b`#�ޱfC�B���"���x�L�-7Ғ��������)F�'qϮ�x�H�lP8+�Ϯ�y��g@ άEY@G8	|����S/^ϵ�Cm~�l[��`W����;����B><2�~���J�ٚ��R�ӤTU��/��uQ����3F��!E��&�p���p�6��?�v��+�ݴ���̈�ǭ6�$�}���$�-�,��}�Ԟ����M��̛�t�%(#�*�)�7bc�H<�A���%M!�/̝Fg����#��hF�z��ú�V��5����`��ڕ�v��o<'O|�We�Qw�HD��չ����?M�%YT����P�\�i��r��H�'�Ļf
��V�4n���m{��C��W��~�]Ɍd.�T]�&�au�Jf�� uS�u����V�nM��Z�YO �k�#k~B��\��p�ԁ���e��Q��$�@�����<c��xR�Ģ���DK1#5S�F����Q��w�R��m�L �e�[��J��[� V�D�h}���_-�q�W���5L��Jè���L�J�ַ���ν��&Da��=�����u.�y���D.}vk�1�fuޝs(�\YUY�Ku�L�^���c�<��#��Ç����������*��� SF��ݼݝ��Gm�;�ޅȚ�,@��y=�X�q�(O9N�}ޖ�2b��F�Ϯ���S|���P������~�Dt��
�@�Þv���M�elg8�ڧi�Ks�=kyWw����PDo������C_���HMpյ����"�*�����]�<�-�+ߩthD��Kd�IB��%����S'�s��R�y��0�WLo;b�5�\�IuLw&��S_L�{�/�K��B^�0M��Q�\y��j;��j:�svl�S!j�@�Ԃ�L�2"���AСAq�I~ش����k�E�$=��@�K�)���v8uN����>�� ���!�f��űhHОHίQw��s:��T:�Xot�9RZ������)?���-�&T���bL#&#Hc�Nw��XP�A��?Sl��$)��An�e��V�'�NL^.�
�����k���q1֝�%�T�C����E>k�&߅O6c�1k�: QSP��,2���-Q=3y�㡚��3�.*�w��t�kM���j����X�7���O�/��7��S�@t�)�-꠺W?,�.�y��s��	��1�o1@�ll	5���l:�iΦ>���BQ�-FkI(��,� |�����[�q$�����$�t�j���M:4�"ǪI��Q�|�âC�������[���A2)���e�5_���$(�l���%e���\7Lը.�������JӾ�em��h�)�`�hB��W��f���-=N�B9K�����,r���)���9yƴ���v�*�l��p"N�Ά�!���� �I�
����$�Ҳ���{bh�u�DpyO>�b�.s�)�c���jR+�!��:ʵ���d,�5�����X8����u�)��¯��NF�!�<���[[�>�nk��"6���]C=�[`��)���oIw�'���3�yss�Jd�/�Sk��t��(���4�Sc��G~|�VQ\�O�lu
H�ֶ��>F����q�9�
�a�x\u�"��a�+����uŊ����7�F�Y�����G�B�G���e��n1���!&�Dw@�-�X|P4��p�_�&F��_{�bJ���6O���t���Kfb�HO��<E!��2��lZ.]��R]l����By�^�nÇ�1��rK���05�Sg4j�E@�3_W-<��Є��*h�b��j07ե�I��"e��F6��nXB���I�e�~�0
���i�E�+_�y��F:�Uv�]x�=
Ŝ7�%$�C�!�+ �Br:6�4:X	nO$D�T솳7�*�2��1�����Q"����I�3X��5��`�
nY���L.�D��R�P�@g�[e�n�\���`"GJ!��pv����m��9�ʴj�I:뉊��C^�ޯ��,��RJ7��i��d��Y���t�O�o�$�Lh����v�>�^\���"�eA�c�� �U'��GY ���X΅S� M���Q+<�Ԗ��w�o�-��&9��@�=�G��`PĠ�wl��g΍����|�g�	n�S[6OQg�?c�d6�t&�u�@���ө8�/.7�z���~!�~ՍN��V즺�nN�	�E���~��|�:?��_�6l�e�A�C^���^�W�����J4�(}dz
8��������K#��]o%(����>L����p�ݒ��:��?ɖ�C�����<���}-��-�z-��ʨ�=?��	Ie���,��sl�_��J��tr!���51����Vj��0*�� �l��R���
i���]�n,LQ���Cd-l�DMkʼ�!yV�4w+L�WiZ�TAЛs0�ttY�*q�`�!�IP���0���8 �s$hh����p!�yEa��`'��D����o�d�&�e�(=�BDg<��wq�^4��@\uZe�-X�Y�����ٕS�O�tu2'+��7��_������F�b�R72��'k�o�/�p�C�<.��h𡱣jN��;3Gtǁ�_L!z�u����	j18h�Y��J)����R���[�7W�o�]��Q��3͡
N���	��=!竴ҮD�L��΀#�b�U�5gk�^���J~k�62j��`�8wR��Ӱ�SU� �H�����Ds;�z�� �C��eę�����jp�4�]b��\�'���T�Ξ1���I_z�9�9�ݡ�\�Z��-���傣�P�(ڑA�oz�����7���kTZ�yFn>�SZo�sЂ�J�v�̫IH�.��-�6.B�9��^�d��0��p�FJ"�jyC%Y��2�u�[jHԗ+>��������iU��?XSnb��RX��|.�M����{�\���A{
>8��q����
��!������̡5֦�k ��[_L����Y�I4��3�`L��#8�,��*X&�B����R�&Y�z�=x���m�$:!���=+%��c�(�N
J�pC�Y���u5��ħcj�o�z"�d���
�E;�[)V�t��X%�}�_f�m�
�]i�S\y��6���Ơ>���ʔ����R�B�k�"Ԋ֗"N�\��g�쀜�O(bJ!?����33�l��&ͦ�e,�u7�#�lXv�<�H��,�����ǉJ�<�ҧ���'KPo�3.�"��G��F���"����F��I����\8�_4���u�}܉J���!��ޭI�q7�0��g�.���A2)�@l��Rc;��1��hV�G;D�ϭ��@��d��<���S��D�s1��!d$��n�b��j�S�BT�'�D��B�[��L7��;�Yt?��]�,Z1�ɦ�cf�C��.�����v�n��H��u�%Q[@��m���D+�LnN�ȍe�|6��M%8����4
H�uQ
�/��Q��>~���o���V�����>	���1��墍Ga�?�B2Y'�ۧ�(���'�4S:���<�H�w�o(~�M�O��I��A6B9J���&�&L�u�-�ց���51_�>�Ȁ�(:�j@�<~25���.:ܫ��7[�஝��h�u_2ګ����B�kxIux;��L�#ż�x&Q�I�c��wHL�B��-�61�#!>�%�^��ia	6e?c�V��>o�X����@��R�{��:���gۤGr������?*ւM�>��oF۹�?���{���,[(>GdO]�#�
���}�5Z�
���n����+�b�s�g��#C[M�O��������Y<��|���K��������)�l��D��xA��aC�	����SQY1�S+����I���J�5:p7�7����wQ�WuVB�M�������DK'�F�a�W��)����\~P�3��H~���?������ �i�lM�,��Ҫ B�A#P�߉�KFn�h�B�>ٕ����#�a3�:��΄,�,����KH�Р�y�?�s�� j����=O�L��5��n|��VfS�
&��w�-i��ru�@�0�t��9A\q�����D������R�E��VBE�4��&[t9���6~�4��[�_!��� 5��y(������� _���_�QHd���=Z�h�q��OQ�E�+��Ub�fy����nr� �9��ڟ�';�krCssQ�KDKS׫o��Pi��Z-_�0r*���ʔ�=��v/��᣾�*u�<I�/Ҽy�Ϗ����� �3��r[��ר�'��� w(.�*?aE��Jze���s��M�Gǌyl��T$�Mq�f�HⲊ�kkݙ��H� !�}�
 \b�1Vwxv�=z�In���6vU���65.�z��Co���e\0�|��7�ٿddJ�%x]/CͺI?qUxfY�����8���ֳ�,}��
l�shF���.f/dH\=�g'�&�n��ge\�á�bv����e�ɬ��1�r�gT���<nRmEB�T����6
�*6�[#N��v��f��O��Ff����%��b}�67Fz��-	J{[	���/L��ώX&��=&��@SJ��Cwo�V�2��c����g�'�pK��su�X� ���LK�}}G���w�X��Q�by��e��٘Ӊ<���SbeV�컺]�n���z�}��ù�>xD!�vM{�4����B���_�ȱ|�Y�޿ ���X�o��6����յ�Y�.��Ws��O�]����i�1��8E�X���-D,�nex5��5uKf��՛�č�	��&E@��>%7p$�w����d�!���k����h�*�@Ȥ��>1YX���?T@��������N�7�u����`ʰ��4DNN0��a��{���;H�g���� ��K&��8��nUv�BY?0;�+֤(d歂=�P�r�L��${��%-�6��1{�0�e�)�:�[�V	T/�1TV}阳N�~���N���d��:P�o|9��(�
e�����s�OGh7�ޛ���W G���aS�^�l�k�
Q����j,����
�����lãb��r�,����C0�<�;K��O�:u�����}�i�g���Y������挾��t=q�V�~�S�(a�6��������f�:�ޝ����<��d�7���PU��Uz
����w�@d;��RG�$,�ڹ���!�.|����1�u��P���$�w{0��<�I���'n�d�dκ*�Yў� ������l�.X��wU�s�uRI�n����U<���FFl���Riz;	�E�N�`^E֐1��2�TXDi��>w����"
>�T��O�:�xJ����4W���x�<6!�9�����_�N�܄U�lׇ���!�fC�?k�"uφ��>s�Gk�=��H��sً��=-aJJu������Mޢ5�+�X���.���>���幤M�D�8��ы��X�����K��*���Z���!��!�T�tچ�ٌ����EF����cg==,ij�������&�����9?@����hR��ع&�γ?O��%��z��Ss���%�j;<�43Hg +��O���_��"�x��5�)�EX��Ⱦ������w����갤�Vy��> @,[��{Q"9x�[X?���1z�%zMu1��[>��G�mE��]m����q�+�P��(^]�ݲ��I�
w�l��_�ڦA���v�[�0���X�D-� �a��fS��*�+�b&��I��X>�5N���`cQ �⮥P�$_����el����ʬM{q�`<t�y
�i��|\�����W� �$ p%�$�0���e�	50�6�~����\{�<����w�C����¤��M��u�$*��ҹ �� ���F�^n��st���4�Ei�0�i?�D`�+��AZu�$�y��ܷ��a,v������t�@G��-��̀LH[�z�C�yRt��2�)Ho]I�c��vD<�`�,�'�j��i
nQ���{������w<���ܭ��� �
���G6ǖzaa.u�-+]������G ��NUm­ΰ$�� �R'q'+��Te��_�)\Iy�����8��="�v�����O�zI�<��,�)R=����P� m�D�N� ����vcj�����$8�H�D���&u[wW�a�v���&��&]�*�M����h2�9e�6A��g�ݮW{��
Tqv�l��;�5�kIQL����j�3'P`xʗ֗U���)�J���掰@|��x;�~wj0��$��od5�W,��,p�E�!D_��Dᡂ؅�֍�Fc���f!��l��a[��
�O�H��SA�9b��?�7����^�zHT��dj3�]}š	�ComD�d"�,��'��*�����3~q��	�j��":Ah>��w�@�#o6m|�����^FJ�1�Z�nF�]#�^���t5����\B}�n���*=5�Y����c��gR���`�[[O}��@�K���tj#NX�̧�zn����>
C3�8jӃ.h�Jǵ����걿�n=�	0���#"!�s&D1��;��\=�Y�Z��|��D�Ju�9r7���?c���k��q�	��-��H�j>��Y���]��a	�/L�fO���z u϶Z�y[ʙ饞1
����2�1u�������3ʙ�D��ӂ;��_�ƈ��7`A֜����9ޠfa���SjOҝ��ߟ�5��4�(����	�~|���%����	<��s��^۝2lJ����I)"���������a/�����	`4H!�ĄF�������0��' �J#��Z�s0l��E�U������^gZLԐ��c�^/B�d�E"F\����*/�`Bx�;X�r�Zf��9�����R�k��4�}s{W������5`�nj[�]/��DM�	��]\f��� �ꆎjC�|�3,q�A@���Y�C�Oʸ�K[�t�[QwaQ�ׂ�-ҔyV�}����ߝ��8TW[�� �e �3pn[��w���N}��l�t���e�����@D�.�����-���'+,@l>i)�/�_��������<L���8 97�M�`(E�aW�ѧW��t��ݖ1���i쿮$�����n�a\kf�����x��c�*0oC[x^���_@d0�-A����?l��퇂o*���7$f���x[���ۗ���6��@D���\<�L�E���*�lw�j[�穽��\q��}}�"N\�#˜<~�^�,����"`�4�jC����.�}%M:8v�ً��HS�G��	�$�wgx:>yE�x� E[����բ\�;#�r�ǬԿ�V��&I	x�k��x��f�s�������E)e��:�y�bŮ�0�*�����@�{���mi�д��SK��������{c^W�$V �g4��)噝0H�xSE̯�a �Fsv/h��-��;{z*�;rO�4#R;�}-����#W���ؠ���c�z�m�-8<���7!#��1r2����r���Y��`��!1�!/ -��~�������Pj�oe$Or�$.q��~�J �����z�TA^�x�W����~��x�D�o��7���w ai�6�DL���dVv���r�3�����ȫ"-*��+�f�_�^J����Kʉ0k?�Y
��)��_�#gz��E�ܠ���+�n
6��fU��JQ�H��ch7a?�'��3�;���i��f��L����]�62�B;�����m����U,&���P�O�8��E��c��N�d���B8F��D
��3�B�{�D��v
?��Do��x�lCL"�)G�.�E�K��|
�>����y��.j^\�V���HC�����^�	v�o6�9~��O#7�����f�[Z�Ʃ��D��Ʀk�{G� ?�N�"�)	?���by�A�u�/�.��J�^�k B�л��4@����0��G�P�3�OI���Z����������zč'��E/9� `x�6N�o��hv-(r1��PwS0���<��2��e�C�N�A%�<;�Cs���Ǩ�!n%^�ޗ~�/&D��˔���n0��,�p
���<�	�#��~��ö[,�UȾ��o*Z	��{�P&�h��V)[��ܰ(����j�6�P�A�L �^�Gm9��#[��;�:+�#��+�d)<�D3�k�����KB�������`�eWT����?'�	|vj�꫐�n��Q ������1ܥet@ۣ2.܀$����� �����Q>���n���1J�����WH}$������~��蛍��H�?b�u;�����']��N��``��:)��cF��sY�����:S����H�U�^�g�?��?���̌��j�"ŸLE^���4$���o$Y/VE�n��0#����!�z:Ȕ��B�3"��$B��m��[���]���*�G}�]���%#F��c0�F��^�ޮ��f%ZO+z�'�?<٬�wZ��b�0@�4�Q��5Ǡ�{^����'�K���p�#��� ��BZ[F�؁��ʢ�G"X�d&����x_�D=t��,_�\����aO_sTaǪ�,p�ғ��J�J	=����4��|�R���lO�����"�S�4R��!CY���Zm.ҿz�&"���NZ+j>%
�N�T�$���ۏ�r��kOI�gS�ݬ$_��{`�v3�&��������k
��(g��&�����g��}�Nǵ��o0�I�^Ͱ���h��AD���n�U� �*+�x|s-�ڛ];�d��!\���0<��m�fSR��\+�s����m��/,?f#��;6�&�������f���a�x��G�󹓒�b�Mu�[Kf�ox�^m������m,a�s�tCP�l��4� X�i�ފ�][�dH�܏I����	��F�>a�-d+V{^�9*N)��mt�e���qiP��K�{�����,�C���%�aQr1b!�K������Wo��!VJm+�h���tf\���^*.��b���o���T{*�⩿����D&�|�8��0��i������.m�����!�0c�P�У�;q*֟���F<�tϖSW�j�WJ�{U�y;a/'Z�/������];Rq8?cB�kVq!4�0Aٹ�4O��4���4i�SEN�K������0�,s��%�V��ǫ5>��)����d�G{}���!�ag�m�>5����#�T���.(��@������� ��4�rD�N��~}Ӥ��/�l�`$j�y�'�7�nW޽��Tw[T�^�MT9�ϰ���{>��Trm��xD��|��d�	���4�K}�_Mʌv397]]�mLle'I�Q�!�q�\�/�!>qJ�A`~�����V9%
�}�7�m�ЏI�?�]µ0$�;�f��2(D�C|������V�}`�>y&7���������̊�t�/rL�<[�V�~�:i��ҿ��K셻�J�;b�ᗿ�3#�=Z�ҏ�#� �a,���ӊ�(��ee��&�;��_�jXh@�rBR�Bq�>F��6㯬��2�2</eKw�.G�cE����6�ZW����iJEpP��"/��O��둼)@�_�,��g�ɺ�b��-�,h3�����y�����J������ƿ���=��(s���qQ��Ի��4VL�D���?�o�Xd�:L��8�ǚ�e6�u}�~���ۛ/��i=���5�6��N��#��Y���3L�G�gǿ��(؁]�N��<F<�[_��͍��ݤ����q(��,R�S9'C�K@+ƪ��Z� 3�PJ�xv���M�OH2���n��|j��@��0�����U�<�ģT�B/S��4��e��64�aR�[�s��	$O�'��Z
���J�9��ҜYh�a��1g�@�`QsI8
����\J	�~�S�;�X�8m���3�'�l?�ߢ�R�P��QS�і�w�rHa���?�zN��7���%��k�s�G�3��Z`fl~�6U1�2a�qwՏPG%�Pί^�x��<U���&�?�/�P5vݮ]���FP�
Ѣ��j 4U��1�E$��1C���2J"'��v�r�)��ʯ�}�,5n�Yq`�r>�j/��0ڋ˖����� �S�I^b`�RYi�a�T��[�[�v��Bd��mݸX~�P7fr�e���a~�V��rj�M0����b�	fqL�aOo�k,������^E��U~a�+6ؽ/�c;H�M�3ؙQZ�1=��)'��;�R6�A�-�J��';h�Jac�J��=59��79��^I{��W8�+�g�w��*�B��:���xܧ�=3r�qǵlU����Œ�7r���IW��[P�8��V8Y��&���N��/��R�W��zs�4���95��k����1���S ���N��P�x�����&.J�j3��:�M���$�h�l؀Ya-��L�տ��eL��(�I%�Ҟx@�[Ɨ%���/l|f��a��Z�(4�p�q�3�ڱ���M���C4�9	X�i��Na��X1�x%ho��g���,�)���E��,�B�m%��Ǽ��E틒
T�dt�Bz��T�z'�+2������{�q�{������	�ۆ�J�1����_c[z�L�T�\�ֶ�N��oפ��`����xX�� �Vf�(n�o�k��sY��'�����4�}�h��);�uʭ�@�W�>�Ne1��Db*������[��=�,�W���q��UIs6z6 a�}Vށ�S�F>���%b��AV�Z��g�3C�ڊ�(;m�!8T�!c�C����s�nܠ�?�Y�z+�L�JH���4�F�,<ǦAE�q!��Έ��no$qi����!��ۚ2��nڐ֪�� �	
c����ĺ4�2�6���q�1h�o/���hO�
o��ђ<�b@�p�B�ϧ�	���F�5�D�Og�yBQ����o�F	�.M�JV�9X}{&�1C�oK�G��ؾ�X������Oؖ���w����y�b]oC���V��ļ?�ר���� �Dy�����'r�e�%��o�́�a�Bl�o���Ž\��O"�����C@'�Bc�:�d�p��E�x�Hs�A�
w\�z��E$6�W��B#<���7��,q����$z|pVQּ�[/�NY���a����eB�W�ϣ�].1�#�wzY`������I��W�W����@p��-�<{������k/���-�O�!5F����?�}���i`�t|ѩLBĬa���
�		��<�B�n|����F���]w$�Gm���ZJ��V�z�v{��b����Pq4d�ReU;�+l��:�}R��QK.���$g�l��Lj�(�[�3
�k *$�5e����WX�>�r͗Dr�&�]!��E����)��4��c�aIn}9�2��X�����y~^0��NLH�C�B��y~��|O��}C�m��G0@<��r�"��AH����WƇ2�y=���&Y�B�	��t�2*{���"�K�e��Ú����5"J	�N91��
j�"�3$װP�Uv��R���h��������'���6�G�8�ݓ�%�,΅w�T�L$��!�| b��.| ���kV�����rNG���t�=��B��~��a*�v�x�|`�S��Nj�'|�rhv+s7����H��DV���v��
�2g0��$�E�Úɯ�F9�sm���0�`
�{
y��,�ثne�Iv�@} �h5��o6"�����U���Ym����!]�/�Y�������)5��SFg��������:aS���n�Z��"ݏ4@��n+�D�N,k�ټ���4L\�yb�\�ҜZ2�]^���8ʘE����,�����IY���}R��L�&E͌��Cԛ�]҉�<�1�-i���a6�X�V��o��n�I�Rm�R4v���rQ��>�8o}+R�n}&�㨦��X����/$�o�$�=qM@?(r(�/��� ���ڌ�[��ʓ�����l�T�q�?�dx�rF�E
��ݻ.v��u�Bz�+�$�t�Ki���O�6c��a񌽴���w��`?χʬp�S�y�����\�\��Q��(j* cv��>�Ig�-�P��|��ЇS#�ߓ%�!xf�x[�L,S��������׏�jK��\F��rOIʻ�:���J��?�H�e���*m>�;֝J:/��@S�9V �:$9�F� �)z:Qun�,Au�Q��'Lÿ����.���5��D�A�F[1r�$�Cd,�Rp��xT!��g- �LR1f����O���	Pݐ[jR�b� T�؇{Q#mY���I��p.k�Ő���m��l��y}�.�lK)p�rK���	j�bߺ(�3��55�Sg�/����G�gC6�n�w���!�luC�mS��k��⬸���؄sc�lq}$[~%g�Ö*�)�~Q�#D%��D�0�����h���C��1�tNv�҃�2;u�)	ȧ����SS[����uz���?�V<����Y�%��^�m���*��}�EX� ER
V^OI��A���X�b�\	�Q���mz��H\O�T�=4���ME��7$����'�J��nV�n@�˝� �>��!��zk��<�,�K�~�<=`4����A[а����P�:�
�RY��+�u��Ca���%�vAް���_򽍶2��H����lݺ�s�n�^�P٫�ר9��Nu�L�j:ְ�Ɲn� mQGA&����է4�Plg��*�i�7#�e�k�!��������B,o���B�f#T��y6�[Y�G(��h�g�r+DQ��V�=&�q�C����U�ǻ �ӗ�H�)��Q榃��z�!KqZ���s�Jk��;X�0��f��Gq�CQ�(��za�����xۛ\�Q��î<���>ǂs�D;d�P�������k��77'W����Xʘb�����W��c�0�@8F�2�~l�2*fw9ϰD>��i����D�2�����T�3C=S,�1����ż�>�s�|�ᰨ� ��<iW�W����Q����t�\}�fX0��6�f�Y.�返n��0g�̈́,�΢�6�'(��Da˫�������'b���M�1�^ܝ����nx�����.|��)�K��e��,D�%��!NMg�m����]�D�ɸA`�Џf�8b���8q(WKi$�ӵ:�����܈�+x!6Ś�۲w�0��3�P�z��AD��Zs�֮�O�_��=��$4�K����\��l����R�^��.6�	/���Ԩ�?b�=���=�ؚ��\�����6<��L�v��Q�q�1�� �V	������{����!����n��1p��!�D�|R�����A:�{�\4p�;UF���}�BU��E�Q���W�2�>�j跲_�������J�}����,jO8E�jJ;C��|�p�Dv��Uq�r���S����*f���(���7"��(���B�%bLu���禅����8	�_CdY�cl`FN̤�H�UaG�c8����_K��`(����>_���i��f��,�>.~���x�O
!�	|T9�>�*W���e =ͣ]�[�$M���c-]c �����)N冪[���=���]h�0�1_�;�S���/�QYN4�T���|4v��y;|��2�$�o(�TB��%�{͞�8�b��a	X ���5]Իi��q��v������/�?�T�1b�T���i��21� ��SC���-�ui��Vp���pG=�^r���{`��+�����e즋�ڣ]�\	^-$۹���~?�U=�}
^��8DdC�Nz�8>(����,X�Z:wj���M�u�(^�����+���	~c��m~,a�T��@Qo)�K҈�E%C|�E��3iji��,�=|s���!������y�&�ia�ͷ��DhU�K��;���b��B&�����	���<�ς���I7'=������Dx	�L�iY�W�]X��������tb]l����n���Atm�V1��*����ЫD�ȱ�ƕ�����Z��\9&2�Ğ�6Γ����s�}�H����k��cC�� �q����v����P����Ȓ�2�������?��!�CA'��>��^3Z�6��KJ\I"�%�;��D,�{|�d����{KN� �95�8`\�Җ}�W$z,�P�D��j�?3fs���Ok}C�ص�6~g�pC�"�YL2�1�_��<e�5�wU�N�C�������|c2�39�HS%]M�6���fOmq7���bh�{��S�Ue/��0���{�S���,B_�F֪I!�'�3�EZ����B<��K �>����v���	F��5\,q޽��@�t�O��~B��xsX_�w)o�Mq��蔦��C{E��ݫp�4�ŝ	�T%�Wg����% ZZ-��+M�d��3�MtYoUE�]6�Ã��,�՛�ťp��՛�w�~��H̓/�����EyV6Q{��x�{�|�+ް�r����H6��o�Ն��{w�r�E;Ո/@���������K����D�g�H�s\i����,a�-��ɲ]-:n�Y��N�����$�.J�����+;�N�T&}�"c�?-�߫$�߈�4� ���嬑����w@ڇ\��� �L����K�?��Әa�Le�-�*�bk@E�4���sfY�;0�=Q)B �W'l[b��+�V�f�L� �x޴??)��(i�:�6L��S���b�%��Plb��1Ԏ���O`F0h=���O�â'Y��Y���D	��0��c��:}��O��Jd>�kհc���)����0U|:ԉ���J�������U/�s��Q*?c{ba^T�٩{�4�k�˔�������O�ynmH��X�9�2E3H:���Ts�W�}��^��<���� $�	�i�V��A��V�:��'R��+>y#lǄ�؂��鮢h N�b�P�����+�� d!���՛F�G����*�W�O�OV�!;���<�ߎ ��F�QUP��9}R�$���Y!�Gu*�"h[��ھb��9�	�n�����z.yq⏋�ʹ��:lc
8��ѨH�,Ӛ�L�$�,�4m?�5��+n����w�JE%�߻����)��G5偘s�o�+Me�(oH����?�j�|�����P���%p=y�������J0O��_�έ2��T"��1%]��������J�� �A�y�/*����{�+�Vi�A2PטS��5>������yGW����b��Y�L��;��jY�r���mk�)�kJ��FC.�wN=O ��՘Ժ���v�L>��Z��E7�_
o�r���es�;H}������󬷔(��.��	G���S	 z1B�(�?D����j'%�u-9��- IL9��1��^�L�H�E-w���(�`��+���j	j�h� �N.vw���*� 3�ԏk�H�4L���,�?Gmu(���6՚�/�մ�]{o�)<Ё��F|�7\J�),n�Bk����%N���W�ͽ��L��!_�-$���txK�*�>��ӝ���E�+�	���sڦ^�G^���Ϫ�QC�eN�h��6/;c���6��S2����pRz�@Ιǁ��-C��$���q;�[pĳ�Y@o.���-2���:Xc8��#�o��~�s�A˘��}�kj+�l�EH�D��$�и��ąV�eB�s�U>���|�� \�&�V{�
Z�)�1s��I�E�&v�[��\�A��Kx�V��ߜc�����7�lRQ� �%��Oi��3z �uo^�o�MZ��
ι�vݚZ�b(3e�M�Z�]��EC��1��mEIU��Ҷթgw'a^b�뭩�IH\yy�݆��������F�k�#�oo�7��:iK��m�Zwk]B1��s?��	�E@[��|������=�슧cp�5�$d�{������^��d�!.�q{g���~�m�/�,q��=usY���S���D�LӚZǤ���E��     Y�1+� /� ���� v8_��g�    YZ