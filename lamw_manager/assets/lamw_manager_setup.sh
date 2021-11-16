#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1260929669"
MD5="368426c6360cf50f66267292a1782c4a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25000"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Tue Nov 16 16:07:27 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
�7zXZ  �ִF !   �X����ae] �}��1Dd]����P�t�F���5W��;�X���=�a׶S�ր���t�;v[?*� H_�E���QcS�"@Ќ6d4��WHM�<AEt���4A�Wڿy��H9��FZg�����`[�Dz�dGZ�%L�`�d��=Z����A�0věh�V�" ��8���Ś�ZS�P.�
	���@EdQ�sCq�T��T:�\�b�x�?kz4ј�[�c��N�1S�pփ>vd[E���[��\ɥq��&9pPS\/��݀#ǖ�)�R�gB9�ק�����OC���K��$�R���P�.r&��ǔj'g>�ʹV�S��5o��	zs���SVNo�m��}`�Ĥ���3N|C�lN��c_��<�� �}$���`���2"�`*��X�l�����o��l�I��B����{�����5qy�gy2�O�cXT&�}Hs��hM�C)}�LP�E>߃1�q[�h�]�h�QX:������?X(���vn�Yv�(/����50Y���-#� 6��g"h��u�S<-^1��_X�C��o�O]+��>�ԁs-3\M��o�K�g�F*z�\li���;����u��VYwÚ����Y���5b��`y��]k�C�U:���o�k�=#��w��W]�co(9S?�J�L��
O@�D��#"�F9	���yO$l��/+j�g]��6gT,A�4@J��.a&�!ԉ�����`0{fKc���A�Fx��|�;�:=le9��wق�̥f�A��/1Ċ�&����ޘP�>Ok�b:pZ�6�Z#gg�g�d��_���Y�XQ���k9i��!U��[�ܙ��큖�yz�~4�I�0���:���+�v�dJ�"�i�&˥2m�k�4��tB��K����:j�_�!��۫o��4�9@�_�!
��� ���(� r�'��p��у���:��X���wk,�D~�g��a�)!�Pj��f�J�qPǻ�:�+�-�̜�⬶�%��&����"g�̢��fzXN��H��2�HD�X���2�S]�+b������F����n4��^r�Ry���<��ѿ�9��ǌ�m�	�����W ~j|�#�N��_S��TwÂ�� ]:���%A��H�a����|�Z~�*Uð����@N*��K9a̮L<����r����n����ȩ�u��CV9�򅈄�P�:��4.�����V�J�
�j�{�rӔ�l�Qp��j>�2�� 'GZ*���~�k1��;j����8C��9����g)�����M��0����'|�\�S���f��E��WP��`�#���|Բ6���
wckN'�y�/�[|�A1�}�r�=꒚��y���HG�Ē�P+q�R9����&�*Q}?U��0���>���Z�>w�0#��/��` ޝp�p�J������뷒�/3͊�_M_�R���O)O���c2�[��#߭0��6���9�SI�@v��r�|s���o�!��-�n�;K���Oї�;��i�2��%��ڝ��k�np�\(}D�~F�����EOhq�U"����jz|B�;��i��C������x4aN��L���G�[��~�p�݆��ދU����zm��w���c8:2�
�� Q���3���w�E�?��KŸ��;�f_�"���#��)|+FI���	��ܿ��w�s��NV8������\��=Dk��}�����%:����$�{}I몤G��8�����ɩ�2�	���	�vWn� ���ʞ�O��*��]~Icd��a�n
_QU��@�J�	}�ԛ����ڳ���irS���~ʹ��>��]�H�d�mchdq;��%9:8�|<�����_H��4M�R
7�&A�l�)�'��E h��h
gc8%�9���^Ѐ�v����-F�:��H/�'V��ɣa^�!dipާ�?���&���z$�i��^sK3��g$
��k�2��S����F�f-
^'�a�d{U*���q&T �WA����q�-kBXE%��02-4 o�.��y�|��Ф�W'�;A^�h��׃ZR4i�A<L�[gU�>3K&.�����D"�n�2�z̓�=�@K$�J�������L��ÿ�����h�C��/��ܔ���5c~A�.�pou ����>X��3ç���H�3��`��������6��Ny8�i6p18��f ��'�=��D9hR�9M�9'pqv*�p�R��'�I��m|o����0Z<���b����������Ah.d_yU{#�o�.�LN�s������z.nT�!�Ah�h��z�Ô)P�\�)�!P�/N�*{T�i��c)��E1ܯ�� �ra�"�kU���C�a_�o�ny[1i��������һ|���+�}>��mD�_��c�·��jW��{ϸ����+���zC�b�1�N��N�/&Qq;U4��rQ���a�wQk[2��C���	&�z��A�9�r��/���V�Ϡa�A�*$OƷS6٭ S ���2���qR^�ߌ�^�7Y�~ $,nN&�?��S0�͍�i��r�1��黰WU	��dqlR��n�_�4l>�H<�'(
g��6��N�nս��ٿ��\&����|�%���^���$0곤Bo��m����tI� 
^���1KWu�,4���_�`����px���z$��Tpvkk��	���r�VE��s��2�y6�D�����UQ�1*��sWh�j�y�l-O�9:%-Z�֐�q�.��[��]�|��X?���}��։�%S~��L��l���z$�6 �r���$_k�5!W0���Dn���_1�j�S��P�>���atlO��Y�5����G�C1�G�d���(ԑYx�IM��P�>.�9�G�Bj���I�YX������U(U����A�V���e���ro�kF�_�!�������s����j(����GIk�A8~�{�=���HeMG��brC�B
Sͨ�T��B�n�`��h���~�AA�)�N�X��;+���2=]O/�6$%�M�U^h5hy9k�:��Oz�"y[���A5�>W;ar̬j/�h�C��8��U�.X�ƞ�1���B�p�� ���Md��W�hyQj�P�����I���V�P:���6ih��I|Tr	��s�+�Ly]��͈ u�c�� ���R%D���Vͭ��D�J���&���=e�EtU���[��a��������0^sZ���@<vi�}�5L1|R.Rۼ��6���� N�"�Y��J�`s���,�����F���� �?8�nqi����q8�	�?59�݆�qRn���H�qf�hu$�@T�v�Z��4W��gv��s+�V��\���yN͟��_�ݴ��+Kڤ��+܉|���+;R���&�ǭ�����P�'��y�${�(.�5����//�b��O�=��U�&^�'h}'�]+��m��h*�-K/%�(�R��,&:doWKGV%�Z~{��z��q�[)��҉|H���XJU�
bf*��p���$��n�����R�r�����y���_����3�ECn� B1�\��C����f;��;>?0�y�����Dp��"�+$�û�ͤ������t���u6 34D�ꦜ�V�s�  ���kؚ���#F��2�Y1P���%��Y0���p��Eo�A�=C�2
A]��C �l`�J�0R����,��m���ԛ��������Fr�~\�m�L�����LG.�`�?�<Ԙ�Jiy��Q�[$�PQ����@P�������|���[I�_XllPU�=)B V��iP���WW����7��M`06��0)�`1r]kv���K��ҩ�ƏQ@�ʈ�+`�MdѶ�%n�e�X�4��a� ���rD�a�۵��� }[�gf<V,{��F�m�RY*�d}��<��>�����j�����F���
�d���X������F�K��/�ͼ�eI����]U�I��L_эi��w�X"��ěՙ��n��5T�y�M����3��,�*4�4[m��s,�-a���~�:)��X$*�L��y.��P��=��p��ɌF��������Ot�=���}l���5Q�t���}O��P��}�P""$S�4R���Pİ�"\��z��ڭK�ˆ+/*�i���5��
�I�Li�P���T$��t)jZGU�F��V��v��E�g�m�+B%�R)�T�=NNp�V�%�������� .�Y	�b�`X�̓��/2Z�6�<i<y��²K���H�����-��Ӫ��px1g�+e�o�y~�\ ۦ�?of�YYB��=�	;g�����gF��;�t�O�@�F<!7������ �p��K�|�9(��X�I�_�Ƅ$�f#6��jt��{q���oCX"��ov�,�Х!���.:��-�t����1��K�'�B��Ż�R>qUY�E�����܉��Qo3�Z����x0�����/:�R�܃�Iyn��,����:���8��"j����y[9�����p/r�䐷F�[�T���Ajx��ݖ������gkɺO�S)`�p倧�d�g��FY���̦�9�x��A*�OO	�~<�^���J�m�2�曈W2���N�4�ӼXH	tl���Cs0�s>��l8Ih�h����0�w�����Z�t�����l*hڰ�+���#o���=&J����Vl,����+�%�@1B�İ� ����,/#���F���ч��X>F��Y��+4�tqſb}���8(�t�]�Ѩ���gB&�	/���:hhDD2N�Q�\biZx�ݡOmHۦ�i7�|��[;1�C�W��,����O�T#F��`Y0L�H≲��*���$p��Uj�7Ɉ,%UՓ�b���xi�=F���x��5�:�E�ǊF���8�Eti�%r&��_	��뭳hu��,:�<$XA!^y�q��cі|�0�p�m�́�r�Ly�����GU)��r�����\P�g 
��6}��q�/�'t��$=�i[%����V�����ޣ)��A��t�=�N�� `�D�B�y�,��|+�O��% $HRtٺ�W� w&�:'Uv��qa]�E ��?��}�U����ŅQ�E��T�]� 1��a= �g���պ�"��\v��u�+�.��� ދ��Ul��薶a��V]�q�����Hx&�o�A��P��z�U�*.%��x^�Ф���Y�����z�%���T��C�l�,���B���f4j�䩱 B�#r6�/i-]!7��S���^@�2���]��	IWR~�H�D����_��K���RwfY��ď� �
R���Y�}$F������F�K�HF#8���rnk�e`��R�N�"�);���dH�m�k���ܺf]^�a�]n���m�U�n(�r�7���h�ECiQ��ܱ:X��Ͼb�"�YA�y�v,��1'N5�C6d�O���u~�A�f^��+*;0����?���`v������ωr����Vng��tT��A�m*�駭�~��`�(�ɳԥ���>Bg���p�>V�̲���N�Ios ������% �.���
9�����h�i05��Jl�V�L�a+�
��6�C�p�"�����8�h�$��C!4�wj��]�arOq�����@_Y��
U�U�E�]xuX�O[��}Y��\[Wk�Z�}&'J0uY��@���a���X" �"�c
�,W$6��[f�MQ�2~�����l8�;w��Z�ڪ�ɉJa|�e�SCe\*��
�揹���Ӗ��� �3��E�����k���*�����ö{\�b�Y���>�[Z��!��"'
�f`"��Ƃ1��G��5�^n�JX�WJO�N�긦m��}Glh��@�2֊e\�u��yܢ����� �M�f.imwz�c������h ���WX뱝�����|�X�js�)C���Ot�o#�5��Jq�H�	��徍_�� --|�R�EF��P{(C1���^��)��#;�ۋc���׻�r�W�5�m�d��i3.IWFHjE���՚��.�f��:RR_Rad#ub��$�NN�HG,T���i����u�	��� _Lpy'��`_����[�6�ڧ��RMJ�9�DG���C0���π�ً��w}j=�)>>�&pF�ia�$���;��[��v
FxA���0*kZ*�f#6ĕoC
�#U�T��Н�@"�z'xT~G�����cL�!k��mL��o�&�ntC�����-�����c�C��d}�8���RJ��FJ\���A�AS��Di��.g���w�_�/+�����$�kag��3]K�Ƞ0iқN+�G�w��Ve�1�1Uǒi׼g��9�N&tQ��O��w�n��p�i������Y���\c��8I��K�z���o�=Vb��2&t)�6D�K���4d�P��z@�kw�W������'
`�,~+��XHG���y��sc�����a����?w�~ۜ��ӭM��6ֻ��%5���s���$��ހ��ux?R�~j�����&ڽ��@5�R�*;��`E-[��_T'餱�z.����=�Rv���n~�Dn��g�{�� �r�0y�r��
6|����\0?����]5Ϩ�jЛ&qT 9�rs�A��w��%4db��Q�5�\��e@�W����&NR�$�1�O��뜤mE>~����S�[���P�,��8��G|�/���u��Æ�xm���7i���ՙt�"7�{���sG�����jB�#a*Am�|�j1ҭ�[&&�p�Gfv��$�.�{=����pݿ�g��,�<�ƔO���(2ċ�����M��Ţ(:�A8�*u�[v�*�K����wZ��N�"h�Ɖ����!_(~d��^Oa/l��\zF���CXl]�
�݀��KUĜȥޝ_�_��	]��OV~�[�4�Q�e��c��&H<H�z{¾䝒IV��/P|s'dH7�I �"�YvE�m�;"8�rf�Kj[�/R&����n��kˤ��in�S�޿f3��j����U�+�ǀW�/�m/����dy.��-x�͋���]0�n8/�̆G~R�ǩ4��
�VKP�P�]�����I;�?h�*��0���:�~?l�0>eja/�(�%��(��/s�� �PL�R��U�e��huy�*�v_�%x�iG�&���!#��v�Ǣ�Jx\�:2�_"H];�⁔=<���J%m�׳��+� �.�Brz-t��3��Cy ��E}T��5R}�|3�y�M�۩P�so �N��iX�O,0�3�h��ݪ��x*�r��믋�ڃbv�Ѥ�Z�R���P��psj��Ng�j���C���b��H����Q��M��6t�!a���	�|$#_?��0�-`YM~jܶ�	Qa��6gU"$�r� @����i�/@��˫�k%��=�-����� ��m�p�\�0��iC²��|bĞ 2hL��mh]�te^���r����&x�&Uyuo;���5��5������,��zb��� u����)�q���<��;4U㊄U�5�Ƈ���L��(�L�-o/s��pP�8
�p�I\�\���a��|�9!���whp��ϻr�k�LWA�@���b���O�s�-����x�ѥP?b���[t]3(�{.g�n�����M��P�ϓV�ؤ��hT ^�6����ԑ�-�z�?�����/O�`^Z�4�h�b�&ط�1?�,�z�����'�wK�P��Y����lX�}F"�،�Ŧ��$]m���SI"�,͚�?�N���q>���(s.���oޡ��#h���;|@D�$dE^@%[+��p|1_uY�I��V���b�jL�vs�����%/��@���������P��fe-z�"x#�R��.�b`��#�ލ��k��Wޭ!���ltC���**�|����*=y�ve�Fl 3��&.�茖��g�AM����������<{d��K���h��w��پ�1�x|$/LR�����)���	�	i9t�A�1�j�z�"�<\*�X
��O�~�D�������5�	����S���<��R�uO�j�-a�I�%a�j_���:fR�f��,t�,l��=͖J�w!��W�p_��46�)6��f+����ȳ
 ���V�{e��o��]S�[n<�l:�D��ƫcD���u�)����^��8�u��`��=����A���(�'������R^�W�G�v� �S�8�9 ����~mDH�OC�5��Ϝ��=�W1���ە���C8e3P�4y��W��J��@�!+���;Bm��6�*���#���J�'���#�oK'�nmC�R��iF,�-��S�N��g����Ě79)-��=�[�ĩ�i�ӦL�P\�0+D]:�4^�,vޤ`�@�&��P��w�4��1��,����+����P�j̓Q'�W�ߴ(EH�y�Kf�=��3L5*��TNq1Vq��- H��zǻ��D�+ƶʨ�;W�TM;S�s{��$R����\.x�`$
:�����ׄ-��>�6& {͏���j����,X��.�؅� �]�R��]♽N��?@��_hMB	[�/E����s�CIU��jP/��l퓾�H����Х�;�${�b����9�HebpS�@��{�ޘ � ��\�\
�B���/u� :���L��r�֢g�~
Zr��lCa�@:-EW\'�#���1K�.�y��4��LR5�p� ����׬>�#"����Z�Wة�JN�f�fA06ʏ���
՝-�;js� �<J��7��1/~������
ܫM�s'���3�_����k90�-G�N˩-�&�U]���o��`J��P&��X�$v�Y����ͬ��F�&�B^��?k����'`�_��Ƨ�upf.��uOzb�_dZp=p�h: �G�/��T����<9���%2��%���v��0�tv���V���PS�qQo�BZ�x��^WG*Q��?�=��|Xt��H\�\��e��)R��"���e�m����\�����&QCu5.'�� ��/�MR�s��M�ʔ�����HVJ.�����$��O��z:��Yt!]&A��T,,��݁����Į����\����9TA��-�[�(��������mB���� #�l�t�Ё�^��U=��6�s�L	��R��د8�K��+�������J�=1��̐��]&��l�5��%�8y+�⇘ڄ` �H1E��	��*��_�'z�|�g-��W�j\�5
C'�i�Jh2t+��?�𔍨4�|M�%_V����D�蓬L��w8��91�z"#m~��_ -
*С�F3����P),�!a�
��d�	�-�k�]_�{��u>��P[��
�;�{���R9$��kZ�긏�qd7�}�"�����L����U9/��S,)-�:��q\�?���D7&:	�T��g.�V7�:%�?�M��=��BՀ����5���__W���'Ѻ�Xe��	��%g��0��VRS<�K��Oi��X摿�K �E��5���\b�"T��cxC}+(��<����ƛ��~��%>�0�������T=q�؞dsgtU�k��������cX�V�����{��Bs�%�u- �ki��W�y&���	�!�E�kixQ�8tG�8O�І�%� @��[3�� |-���S��l�s�6:k�v��zo�O�Iv�ͯ�߈ݴ�w�B�LJ�J#ͪ��hQ�u���a���4��A���f��Eu�����V2Cqя~����9�^��u���q�aR���vT<�&,����{��j��Rs�\/�v*�8&���3��!&YI1�?`�6��>�e�R�DB��b���R|r�+��r��鱯�nV�6VGVY�v���1��d7u}^�6�׾����W!~�i�E��*��\JC��Xr=�};�;l��)!<��Ez@��_
�G�uW�8�ţ�h$8|?@���u�_��k���@�}oT�����w�K3F�Kkl#5�|����,$�;���|����i�q3?��_��Q�by;���_wn�?Ы[����ax�{�k8|u�{�2�֑��4f�Ld\���o��K�)��^CG5�u��(G�I��	��9Ct����u���v��a~���WzY>����FJT������2��I�H�^�Ƹ�����vR��{>�2ce1�n�ۏNd	�kT2�h��w?+��*I�|�����daA��h1��|��eD�4a�lz��"|5�%���ځ�z&{3� ؂� %�k;�c��*��� K;q_�f��9�;#Qy���j������Ȃ��I���{�#��x��M3���9 S`�0��p�OJMQ���-��d���4�����XaΌ`V�2�D�)��x�Ȯ��ޙ�����r��Ͼ����	�-\V�>^��9���c�n���	���W#�S���Yo��
��=�����d珀H9
1�?�:��Z	x])D��GF������]]�*^�_�Bܦ-�?�6iε��Ж�7p��BZ��پ
(�d�)+����2�6�d}˶��JC�fj�����_"�z������f��~*Ը�\����{�@�S�*V�b��ջl����ji6D�N���"7l���	z<��Ũ�#?��$rntV��*�d���L�4�+�	ou��^���ן�����h���P;)���N�V��༌��.�C2���WZ�q��:�f�lR��֟�������J����R�rk��r3N-�DV!�-��C�7���H�}� �j��J�$O� k�����w�x����z��-#����!y|@^���ǥ`�@#�ob=��f0'�]a1eP���V"����<X�;����pE]��~�SsR��Z`R��{A8��>0؄닽��|�թ�&,�sի�������=Be���"�z�"�[��K��jnd�	�w�9A�]��%��!�kF��0����Ðߔx��m�(lI�C�-��7�k���{�0n'i�A��es��E#�z��;K�ٞ��M<t�eS�^�2 s+�bA�L���E*�EhR��w�հ*Ҁ�~�%�9�2���'�攘}��}���ཀ%��\ƅ��dq��Ь���<�y���5&ԯ�eG E���z �daQC�NZ)�(����ڿ٢��.�uS�lvʶ�;�2�P�yD�luC��������B�z��J�;3��{�
��4��_1ǲF(��n�2寅y~��}�}��β϶�QW�S�O�p��w�y`%���-��mp�l�U�H��ܖzd^~D�������wp� �Gj|��3�5�t ��G�=��)z����;�mā�Ga��5���BN,G��I�#��޼sy0��n��

��1z`k[��W�p�0�P��Ծzm��&LU��Z���s�tbv�,�% `�w��݆��.��>�ZZE�9Z���L�C�yc�!�^}w$�eȨ��h�G��oM���iկ3�%�|ϐC��1�'���%�]�R���JK���ZF���x�9g98�g�J"�h+�2��f�ă�(�1�� v�ө��(3!>�IĿ�����jM�FkU�W6�F�@��u���{btVLj�I������p�/�( �51<�4ή��ə.;����}O_]�V�Erw��.�u�!7VT���d7��%�z�	w�?^Knu"e�Ips��P\t+�D[��М�5�Fyz��ሊ�#�<J��%�fs��"4�e�����7p�S�3�{��5z���R�P�UVj*������wJ0X�1XTZ�v߷7Pk�)����c�-�"�
M�o�����;������g�3�_ѣ[�^]�%+y��I"�~1���4U<0GY�I�OǪ%��ˤ��3�5Y���i%���ۿh�r��bX���)^S�,�A�4�0b}q�Td���Y�FM"�f��>��ტ|Q�#P�d��}�>�����
�9��`Lj�p^�8� K�	�� ���r�<�:	�����OA#��2�����[۾[%��`��]���%�gm��y��-e�Oʌ��lC�Zb�ky_b���V+/�/��CDt���0YD�7�SG��[���PZr�qK���	�X�%�g���@������l�8�/��y�>͇�6�,2_���`*��F�|��)��⺄�f��a:V��z!�@RJ��x�����<	7�B`,�\h�u����l�����k@I=uJ��`tY�mH룼M&O�|(�&�cu�:���=
���|)�m!b���Y����/�_ǹq|&�8'���C�Y��؎�Q� vO�H!��U�bB^x����Mk�{��	Q���ׂ)ߣ\�M@�f���-9q����/Ox 3ڱ��y�c)~��o;������d��>mh�+-��Ur�&�N�C�Ă'݃����ݚ�)�g5-��!0���򈳫<[ ��u-V�2Mkm�`��g�����J�7ē��79�DfR:����_@h�Q�|�(q��w�D[�r�2�NX��4KV0k�����S7.��\������Dg	'KB��-�π�aܖ����
����S�,�j���[�	��n���Q�#��}c�D�P�I���h�R#�,��T��	"�	��rا�%�"/
��Md<6&�)��q�q$�j=&��I���(��290#�	p�cg����'��]jC}e�kJ���SՀY�f���)?������5!�"r�n+$������z"R9mR��uE�=OH6|q6t&�S��E�BW�uX��|��H S�ٲ�j�1���*��5�N����^�j�f�t��Ls�~�Bg*F���9�s�qW���+z�PYa`�}���P�͕��l���q0�K�1B\��#:�\)�x�{��)�Q|�$*j�j����Tw�c��չj��fj�m�P��&���Vt�c�7{��2�&����!��g�&j[k�ir$7=X�2��Pce���6<�iuk�����L���{��(zIT�>-�/r��GY}I08��oN*X�cǡ/T�<�RۦOk�֢�Ȯ��s��?���Q�a���A��FTB�����C��V:j�<����
r	ޘDV+F��
_ )�����C�����B�`��Y8&^�0n�6�J�j���p�g�������/�i��%�8��e9/���������=0��3Wc�hp����������q�I�-Z�t���(�3��k�l����@2$��S	�I����}[B`@r��:M��Yb�fv3�g���!���X��;�v�ZtY*�j�����T|rOEQ�5μ: ��1Ft��ks���<=P���g:�&��>�>�5$��z3?�24KY�� �����N�{��j����Θ�o�J�q�b��^/K�z�I�B����H�$q��jTI���˷��8&:��v��S���|m���0"��+"�œ��泙�O�>|�Jb���%��k�I.��s�1a�Ć��J���^�ڄ�0ل�~�U��R%��5�?SX�l���0�B����lO���*OB�!�-�xI�A.�u=8\��L�0VS�T�1�|�=(%'�+'o��ن��-"���f[.��_��˙?[�/�4֩�����I��N�E�B�ͬgd�=�c�&x�`7'��\��J$�|�����*� ��_)8xg���@�'��H �LA�/����A�"��LH]��?�j>�
�F@�$��`�6��/�M�#>[M����|�˗ª�0Ͼ5�?���� �R68��7��!̖5y���
ӵ#����#��و��c�Sm<O`m�-�~$��7����VmT�0��<��M�����9��LT�P֖/}M�-�*H�DF��|?��Wew���?�`#9(��N��?2m��0�3�8BK�������JCz\A��Z-�,����,^��Y`7No�x2��$��# �>���47C֗�����Ĺ��X�Nu/��>x�&%�xF��2��ɪ���OloѸG���]��[�w�A���P56�{��!jT8���� �Xԓ�NcAb��nH��?>�������B����h�F�q�b���l���|�Qx�vu���~���� �'�����9`i�y����>F׆��\z�6����?�����s��Fj�V1xx̔� �_6�������t�I(�!S�%���qU-e&�wS�J[�xgC�`U����'� ����o h��8���bu,��q���:�W�%�O���Q�Q	�='��;>\��b������q+�̿�@9���O]�����hg1
ތ�y���P=[�m�I�xG��G���`�H�J!���Wv�0�����7�đ���.����w V��])��u~�h�L>��.y�n�7�7��V��Nt�	E�
���Exꪶp�Ed�Vm[��I�=4�u����8���)��8=l�M'����G��@��]���F���J���fڵ�>�Ur��t�C;VPd�-�E�'�n�.�B��2���a�!��%�w����x��J���S��:2�&�2pK;֘��č4��ė�����h�c�`�^�0<�����^���M�F��V���+FV��u�ΰ<�������'_��6�k�cROI�ų��QY����]Q#6�V&�0���`��a���j��j������dByC>��+xc��Ȣ?N�e`~���-P��J�I �!X��j�)�
ru��a�����`� ���[,/<��q�\n�>J�$}��^kC���݈�����чr깭�n�vܽ͒�"<i��UIF��{^�T��] ��+ߔB2$48��3C�:�Ϗ�l�x⨞�1p�։���f rˈ* sY89B�e���E<q_N�􅁬���F�m8�/Ow>ފ�Qs�����.�'#��U[o,<��W���{+���`�R���ە�}�og0H�%��(�������:R�`+����c濏�t5���)�q8�{S^y��r)aDC�����?�����Ũ�������+��.q������/���Yl*%��>i�eX򥄎}{��l�]���l�on-�VP3���sw�^�`s些���w�/��������:�-B�H�������ܼ�X����1t0[��
��8�Wߤ:y֋�g�Y�ƅ��,����b�nюZ�,�n��J�9���ș<4�^oB�q�Ҫ����h5��˲c��i5�(���x8��|�h|7ve�J[�Nn�dPE��9�5 S��'/o�n���K���~��&%m�*QF
{���f!�#�PHGO�)�x'>�[gP��7L�V������	�Β�_��Wh`s?z��w�$@(_��Pi�כ*�TN�>o�D�v���V�|u��0�I�Ϫ��|�ߙM���;�,$rH]��cg����J����4m-(	r���,4z`�P�Bv�H��m��ĳ��N��9�Մ|I|Uq	�v����8! ��9m��ӗN!�#��Ļ+-D�87/��`'�h�X��Z��./��{��Ljj[����8��N���b2@L��ͫ���Eq��13��NP��=U
��->i���J������yq�I �a�V�����Y���7�L���U4���~�U���u�m�c���9Y09y
^Io��X�0\shL�w�]O"mo�c���n��f��;͙r�Fzz�#�����Y�_�k�m����8)��O��{�QW,���u�`
5��k�#�<�8уZ��U |�[�.��Nj��mM���A0���v�OQ5�.y��|�W,k0I��(�����,��uӠ��'��CZC�goG.�؋�+TC+�2�k��t9RF3��â/`�EY�a�k\C�Q�;J���0�U��^������vn7��
�[I�~�^��x��2��Z�f�K�>3�|�		�x�@�ќ��M���H� :p5����h� ���6��T�, �'BDlx��\C�R�dک>�J��R���u1vTB��RJ���zh�@m��
�wijDʃ�:Eg3L����c��������
�Ν�3.��.~�E���y����y��4���_������m��9�}X/��%W���қ��*Pl��{'�S�g�G�,������i��� dI��Ž�-G�� �?��M+�����l��
�ʜ��x4X�<Ӯ�=�5�����'Q�*��o`�%C�8����8f=����:�"�r�3M��֡;Q��-<�H�y�Yϩӯ_����RE:8}"���ha��&�~��ô�8�G$��㱳>�x�Q�z0HD6y��������IgE�_�����0b�q55x�s���?r<cPϜ�T*�hߨn7�X��	��xav���b�l����u��/$���br.z�=�Y��+J��G�4H��я<��p�K���f|�l��"h[W�*�-u���9��UK�-7$]k���Ée�+e�	|9S3�/��-��`-?V���(_��k ��w1�[j��;�:�sMV���=���$@�H�b�=�`��n�9��J�z~��E�g8���Lޞ�E�aDg��0�ߢ굠l1\'r�Z������^��5�l�G�/C�75D�αu�0b0�l��Ye����G�+&%�����@>\��m�d� ��v^[u��B�5
�����1������}C� 'U:�کq��_��UcQ�T���0r��Vҏ�`��Hˉ����ek��G� =�%YV����>umɄ��Q����LV(�jm[��dΗ�C盍}�<O��J8�>��;N��J|Ľ8�2��!����ז �B�R���y$UC<�� ��"�q�E���L�����^<�m�h��v-�q�Ü�<C�S�̟D�������V	�M"B�E��lxލ���զ�(l������S���S�N"�@GL����܂���E�x�"�����8M$5t�g��g\Ҁ(�/x��=~�Z��G}/���(:��ݕ�4���ݐ�Q��T֗ɳ<�������o���J���i��(�PQ���t�������7��kt-.� �ָY��D�J���Ǆe�;56�_���HXHn¥2����I�U��6�C"G��~s%f4��3:��i��+������46a67�2��І�^�SGZ�oM��(2]�/���yE��C[w�@�����Zh*� ���R��'\�I�?76��������=� ��{9?�r���9B��9�I��~Y�� t	`XpR ��{j@�l���Ċ#m����YK��EiiՀ���m���kS�x�֍g���͝d
Oc�,�2��`ON���}ĬBZ�[G� ���$�r�<{�"�AZ� Ðy%&��	1U7h���ϳC��OhU�i��1y@��sN���
ۿa��=e�U8��͌�D�R���%HS�D�DPs�+a�_56(��#��+�/\$t�Ӂ�P�,x��d�{�Sg{�ߞVVH/G�&mV�����dbٰU<��*��л�����ReW�T+ߴ�y'�?�$C7oT_���0���_��m�=y�D�r"C7����u��
�;\�U��7jju��J}�u�� ��/+�j�Do�}S�U���O��.�R46ع�cK�OW�����B�K����M�:���j��X�t�9��	�l)$	�*7Q���!|�4WE�V���@�$3��Ϥ��˃�ci��7۾�X��]����];i�8Ԟ���ث��iZ��,������!~�u�*�E���/���+]��!z�����޵���ʹ<��,�T
�%�U�D��	k�a���S�8�b�E�с��$��_����(�@_�c��e��z��'��$I{��yE���?u�ٰ	��z `��oD��b������+(��\錭w���al�9t����e]K�
��y:���ٽJ�!F`F�x�QAs�<�;���/�e�	:�l��a��Ɋϣ�.��U������լK�F?��X���x�s؃�hf1�:= �6C*�.F]3��8���n[�T*��I9P��"	:"�?�,�L���?��p��z�雂��"8�~���,rs\3Õ5b�fs��|�r*A�N����J�S��cX�,�&j���T��GEN��ٙP�<��SƓ� fw2i�G�k}[,�.�݀V���L&��X&�����x?���D�6	!]6��Bc#���m��t2��p��T`��m��;��:������!D��Ѿ��?�eMKwd䌙M@7f�s�}��|f��r�>�$$�4��5�=�|%�y�л5�(P���Q �^��2���sP7��q�u7E]';���2��O��������w�!2_r{!���1������ ��'�Å�,%�
�M�2Zۓ]�
D����8�_)ת`��,YP�� ��MO	]�8u�
9�� �ڐ��v�uu�0zS5������(ʡ�ܚ�Cd�3�/��p�	�Cd	�����:vG�U6�mK䆘>�HVr�i�Z�),DC}r�5������C�Xl�'�߄6�Y2t��w=���5q:7�S�o���Ĭ����%�������j�RhW+e���R�>��&��ǮP�k�.aR#*���U�K����o��onSC�9<!���B�	�2��N��f���9��WtL[����n����x�|�w��	U�z>o�`��k�VrF)�J���qIw:vB��/[d�{hڃ[�I��sR��������:s���E���/�/�쇖�
=����e5�v�n lt��oE%� �O:�ĺz��ay�  o�9=ϘB�}��U�n�����4Å�a����t�OxÄgϤP#P?*+F}g���,r]�
���8�F^
w��N֍Yw��W��X���P)����8���~�c��+���>�����*�.�W�l���< ����`��i��vy�&�?� V=�E!m�v��g9~P�=�Qm�?`��p����m�G�FN���e+4P��ߵ"���y��Ô7i����n?�Χ�|���`��֌X�?[��)�Y��_��ٹir1��r��b�A��ܶn��^�|`�r(�૞�O��1���9�!گ�M$G7M}���P XF�;�%����a�*�����G6.���%H9���j���[���!�d2g���i8�zc�^�S�#%hf���.]��di����>�n�#��J[b����{���<���W
;�2��	�*w}�g?��6/i����Y-$��'*Fr���&��C�	6e
4LIobuɣ��	�M�W�L���|j��'�0!S0S���L��3���JV�@�g�}M�~n�?�}	�j��T^H8�I ��W6�4���ָ~�_���jƑa�/�̅8g�9��)q��3��zOW�y���y
 ��۷Z�ҭ8^�җx���>����3��y�S#4�@{^�0�:���
��AT�n��m�?���Z��=6���$��-�`�V�Ӳ\�f�6NdXI� �Rk��EgP�)$�ԓ}~�I0\��x[����$7	��D��ya���I��6�|��d嚶�-��%y�p��+��Р��֎�m+C�x�}�&(���!�K�`�Z��1�q�9�+«Q �����$�����"t�6�LP��w��#�N��1��(�ײ�˾�>P[ۤ��-D7G�E^g<�`��$����;7:�V�|�ˁU�s�v�$a����\�d�7�/
f�����O{'j��:���6(?`Ie�Br�0;��j%��!W3=Q����o�\���R�����O"cr{�>G?}@�b��ּ�\��F�����䓼{W`్9v�n�80(�@,�ձս��MT��탉]�Q�X¡��^	ł��U��Xuk} ��VT��R43����߂c�]C7)��
�I�R�����6��O�m��}�Y��s)3����P��	[)������椦��ָ��j2(�0���IEs���\�IO@d��,����Pl�`K[v`�~�)�Q7r�'�}����Y�~w$�c�m=tn]�|L���E�m괤�r^���5�B�C�5n��"���${�,�l`��I?M�]0��K�Lv����:P�S6���.����Z+=k��j�6I�����ɟ���H�X�e�LޡN�G���\��S���ۛ��� %����tiF���o��
�)�P�j��J�Z� ���eB�R.�!���V�۲�"��ӽ/��a$n�ܜ�!j�C�}h�}gZ���;^͚6:z*��Ü�X�A% �c�C���`b@uv��>��"�����^a�5��[�I7y���'S��
�w�ש����4�!X�_�8��7�(�����T�":��4�"��XOv�Qp�ۨ�WF�w�
8Hr����& �d⻝�g�FR�k��~ޓ��o!Y)�ó}鷒�v�E[�z�-ˍ��너�k��@M%&�ꗔJ��J�������fVK�
���XO�s�fG�H)z�O$�0���g/�a*��p�P�J��{�U,�M����6e3\���@CZ�����7�@��I���	�YJ;�����.,�F��ڃ2B�&�hAZ�i�9�בBI~}������� �����>��]9�*т�h�"��|~ \�!:sh�>����iȘn'Ӿ�jt����6�P�������JqC-D>�O�$������" Sw�Y������.}�l������w4�/����L��� � ӥ�HS��A�j6v�OaH�a�}����^3ي_��J�Q>�Qƪ�e�'[Kn't���\��O4�<,�P/��1��5�oj��F)w��z��x���
�%$5'1�5�k���ۜ�je�}�>�q��G�)��[��[n��Ia���P�G���U�a%˷�!��B��uv�b�\P�O~�E��1l�K?���xqwʡ{ǳ���p�66R�ffN&a)i!c�����(k�e<crB��.��4W�7)��&����L�d�X��{>v��)6��Y9�ƞ+�ۮZ~�
�r�;g������?rb(��n�j7��Ơ�sGT���s���/��g ,�Xm/hf+YcA;N
��d";:`=� ���U�pBž;
�8,��V�3k�Z����n&c��������,M��͒�n
�مG��fF-���ֲ��0�؄z�t��@#>᠚<l�\>�"���i��5�E됓ջ�s���ĻIQ��*�T��	��8����� ���6��m���6�����&=�|��~����se����feV����f�CZ�O��Il��w!ư�&{��c��:(͡���`"���������Kb��	q��f޻s,��i�^�eS��;�6��~��)TA�O�'l��v�b�/�I�u����n���y��b3l9�����Y(� �e�R��� ���� P�?y�<2}���0���w����ﹹ�A�	<�^��!���{����A�w���ŕi`W���ί�m^nlw��P��Z���#O}����Jt�p>����h�T���@t7�:˾"��~����cR�����|�w��W}e� W��E�>�����v�zY����2����2��"M��˧�|���^����6��vw�����r���D�����Y�I}r�ѻu�Gw$�<����K�� ~��P��J��V!$'����i{(����Z�ˏ�].#�B�Y��u�/SUC�	>Q�]~ Pr�L���f�7�Z�4"	�z��O�9�a[G��.����pY�
�6jy��Ӵ�r���Llc��Ї|'ܷ/�ڷœenv�C���Խx�$�I�n����F�'����|r�HW�5m�;>N�Da���4mg�꠷�6�x) }Fq�\֗�Akvr�d���O�����H�O�����'��v�j��ě �`�(�h��)��<��o"�_�'�p3�H��l)';�<���M�.�:3���������i����aX��s�ʀr�CⓀ�J55�W�طHP��:��Oxk
9��{�P��
�j�EFM�U������
2�ŷ�ge����i�XU�8�$���vy�E-<�
"�z^�L:��\�Q�%}	�&�.l7�����7o�Oj��-cx=pS�����p�d%��?e�E�(dċ�F��+�T���P��]m��[;A�fI��T{^	B� �`����D��?� ���TMM%�i��n7�p��C����2�i���d<T�`_�v�L�:�
u��ѣ����~�60wk�=��K]0��)u�MlXS��v�<��n�����������L9���+B!
3�閖�	$������$��&E;�/�;��ڰ��{���S@pd�G��vM�\ە��P)!TFԄ���,N%ţ�Y�vc��3��]��4��l��#wrN5�a�ᲹF����S״I�B������	�4Ϊb�ɸ�Fm@n&p����,@�>ˮ,�u�t��,s-��yE���_���]�e3kR�4��o��\�i޾*�ͣ��KS�����rн!�;����[\��52��Z$�V�?�6�Q���(iO�I8�����8.��f4D�>!��Xf��+�XTw*�����G���2R����;;�ʒƥ���N�C��BR�hR�d����~��# �~���֓.ʙ�<�V��.shf��|Gq�M�-�!�\}�S 5�,�ó�l�Q�J�,��h2��+d}�y��ߣy��8~�b8t����,�k��s���L�V"~N,r�]���d\���9S�t1���i��Pf󨮘���V��c�~���M�re���<6�$��q�2`�澜4�yq ���߂�*W��V���l#�su��ӻv�;Z��#2���{�S�W,��T���'7� � !F.�r�/%�c���d1��e�	�6�;�J�&@Im¯tS�%D�2��B�:*L�ᾦ!�d�3�v����kS�����2���FX�,9�&�^U[z3���V͡'��5�iÿ�
QR�L_���ҽ>qU��e����์%��4��i���q�����c�ȋ��*)j%؂�
��v�� TND$�
�(��R���n�y�n��Σ�%�{C��ǹݥ&�����,,O<9�b���R1&��r.�����}?��S0q�yA^!�!�`�ܗ�=5�+�[?`��9R޸��~9K�3�O �^�gcE�W]qe{�j�O�Vl��c?�%W�E"]�6!�+�	���J��T��*N�(K�w�6|��g�*b��m"Ϯ?�8���ea��LQ�/h�B,����c+4-pd�U9�q3���B鼖 ��܍�x}D�"m�_�T�Y��V��F���,]*oކ�{l� b���=�ăF>���0�#_��7J0��ń���w�ng��9�/YQ��.����a�s���Q�-H�]ر�9{� �;(�����F�6I^����"�N{Χ��e	#��8�#\#�D@��D�����)�H��>�TK��?X9{��F�7��I(?�h�[ ��$sxJN����T�)��a#�S�ۮ���	j�Ҡ��5����2�ZXn��y\�>Np���J�`�]a4�G�vs�/O�K�w���3��!Z)���<��wگ�g�Dտ�;�^�0�H��lz@5��-��}�2�6�!;O4���OMe|��4�)$3�m�-["�d�� s�^���z wBF���U_���Z��Xi9�qK|��'�%�ҫ�ZQo��Y
�MZ�*|��h�,_NA�F�B�����+��q�-I7�0o[���w���8�c��1-�����%�N����~ ��9{�\���H[�eY)��AMz������F�Rw�
���Z���~���u\�Kn�9�e��a�\S"+���pnV���2�Xz�~E��rzk��=����_3�&;X\`�Ȯ��F��$��%9[{��Rm��Eh��,���YoqŲe[)�h:�6+iY��nj�|i �!�k<fF,ys�c��o�'��j��,vTf�c%l˩���Kz����c�2�ۮ�̱�A*�!���{t�VZ��]���f��C��O�s�������ې�o43GL/~���<�B��<�$�Q�'�յ�YiHOa��E]��3\�M�	b�_���A%
�����upePT[X+�k�Ԍ%��*�lXN��7Tpf�Æb(��8&��5��*�b��c��cD���6��u�ȉ ^�Dh���v�w�����U#y�M�̑�� �[, �Z:��&x&����?�ˎ����=rV�˷j�~fъ�^W:d    �[�+��� ���������g�    YZ