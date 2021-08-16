#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1940199149"
MD5="7df476b257782bb740bcbf57980b9829"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23540"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Sun Aug 15 21:21:45 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D��8'{i�F�����|���?���T:��cv^:ܸ��Z�5���)��(n��]8��
/�+=Շ���Z}���_mB#��ξ���b�e�@lʡ�%��<�G�b5R��f���jN��p�mp)��h!�>kh���_V���
W�>t��^�.R8�0�YΘ�ҝ�f��c5cW���=d�ӟM|Zĸ����+3@Ď��5vy����b�o%ݮ�kYPr}�W��#4���͹G�{5x���\=?��6�c]:�+���O�1i����	#�_��A��-%�5%�p��O�B+�ô��P�t��߭����z��f ��X2r�'���Q������^D������Ù9 �V�_��$7�K쩛�nZA5mӐ���֙K��~���u��V���'�y։3XϤ�����\l���@����U�l����Ï���jAC]{�Ng�@&=�)Ε	s��q���ε����}`����-�_�^z_$�QZè����)v����F�-?��*�t������}�f�o7++>��:�����o�3�*Кs��`ޖ=��f�9a��{������[Q[��ۋ���+�Y���4�'��ep��>��*ۺ�kf�����)�ܳBB���`�W,�[�7�T�ފ{%~\��?���7p*T�q��eW/���}�:��	�K�a�� �V��>��n�J}�Nq��:�h��la�D���;0�g0+�J��H�;�%Zr��τ��^DU�o����Jm-�{�7b�Z�*'�����������g����94���v"B�������g8[���p�ciX{.�9�v��4�ϐZ���_C���lF�|p�篕�;#��j�b��m��P|��7֧�s�9�x֣}k��\}�H\@8���D����nկG�*�a�� .�XI��(_�����|���l�8S͘vݘ	�=�E=��-h�-OQ���s++(����^[Ґ�MLMQ�*���{��N���X��`�mM�}6_Hd0�x;d<��x�g����_ܸ%�!_�1l���O�\ORK~.ccn�l���7W�SU4MT!�h��Sm�Qv
f�
̼�2�O�C�,�y]�>P�Aԥ����j��EU�`��G�!R:��,ۃ�em�#���!��Zsҡ�X ѡq�7����r �Fc�lS]�ݿ��p�Nfi��ة�>E#�g�,����y$L�j�Q߿<��Ui�zH���LKɳ��M�Iy�ц��,_-��N�	HxN����=)�W���#��7d).yWo��Z���u�F0�5&�%?ק}f�t�I�^Z�p����}鯅���Zь��J47����~����a@t#�q���6�3���3?��h����T��C����^P��rb���L� ��xӛ���5e!��Q�[�����˅ޑ>��<!zU!	?<�&��q����[�ᢅ�8����#X�x�����ו��eٗ���x>[�H� R`%��|���[D�f؇�p �Ŀi:�l)�[�$�x�U(���w"��S�u�5V��`P�[�e`�x%��F$)gP�W���U�����?h��@Z�1x��N��S����l�`����c��Cꀲ���V�:�D�"*�1�rSyM���WV)��ѱ���*+��F�>	�J1\b�.�ӥ*�kN�hG��1��m���t�^[l~*�	�]�v/��?Ķ�L�y�\�.��1� 6����W���{p_YO9
�t@b��%�|.��0~��y��/p���Df��n�c��=��`d�XҷR��ę�{3��h��WIQ�j$v����b;���-	�4u�?�[��,��x��*�CQ�,����S\�g����x��`h�ɩ�f��|��j��d�A�ӀZ#B�l\���6����):"�'bp��tS���<Lrp�3g�L�;������5�F�a��[�N�b�Ro����Ōˎ�3�FSÅd�Gم�xJKgu�i����y -�.�;������6���@I���gz0�+d;i�[r��GX2�ր_忒�\�]�(R�X3K�  P����M�R4�MB�I�Y��ϻ˯��d�N�E�㑞l�+�lR&�a;�ç��>�Y�3��-����q�镭챚J���W�U�}�NI�����E��ГE,o�J����A����n̮��fňc�gZ}ۥH������$Jmb�дj�cs"4�:��p>U�qa&U�o�>&�ѣ�,���AW�<��@u�s,"�7}�)�46�0�N��_OC����R`Vp��&�pWkxU��c�A�C�U�񍿮�U�P1�<v���ZNyb��:��R*�>Y ��J�������}�g%��~�aF��A	~���Q�=l���\;���u�iY�6�ڽ�a�{SF�Z�{���m�	 �����ӱ�Ï����mm�@�(]Wy�Gz��+��d"MAs��juܮ���E6B-����a��rf:Y�'��2��Nۈx��0�����Pe�W	��G�
G�/_[��R'nH�K��;f񢝌��-�����V5D_,�L+�t��5���:�};��	���:>(^�,�EcΕ�F�l;gb���K[���۪��j��Wu���D�T���5��z@��_���Km�K�<`���֧:(\�F�Xx�J�N�5��t�F��h#�>?������S��c�i`9���q�̽7��L8{���16^/��r��6t�O�8��Fn!�>9�l�?H@\�������-�v$S�{e�sl�U g3O`R1ګ�2~(\F攉|P�c.ۯ�\MƌQ.BF��؟5��w�C6��J6a'��3����}g1�����g~�g�wP(-3�x^���pL�so�,Y��¨��
�y���V�ޅ��u��L�\e"�&U��j�|��ס>���6��q�om��#y%�^���G���u��#�T�̫X�4%x|mXaM2b�lm�^R�iC8BKq�p g�l6�_u[��o�.�-YC��ܭ�1���,�t)�d�_�դ��hr��Y����;,3��1\��g	�w%��ꥪ�>	X��RN-8W�_�1�kTu�)(%�2� F�Lad~Vo�.�& ��g�_R�u�`Xi!+)D�ܧ���Z��'W`qp��0UJ���T�D�
<5Q����{cPG>��\�w=�DSy�1ݵbNh~�HBd�`��>�}���Ӛe�KӖOlBxr���*G�b1}^&�̅�����%[`��* ���ARf�G��yE Ҙ���d =N�L�z)OI[�f�z��jR������G�f��& Lt��������RͲDR�s���W[����$<}ـv���W�$��A�k�Q�#��.��	ĳ����<�FM++�N�/����ڮ�V������tIe�}0���.w��E_�eB�6GR��ƿ�V����1�R%���J���i������W��uss�!�eaH�eW�7�e�m*5-�{�M4�A�Yc$Ã�Ǒo-�J��&t�Ͷ��=p���W
^*�\JU�r�8��qZ�)]�g���#g@@�?�,�@����1O�=�Y/a�I&, ׿]�o�O��O83!�|��it�<��ZX��l���p���{�C=��־B�,^D��欴n�[0��a��j�����q�,p�
U&��X�=�%=��v��P=N+@;R���|��B1(I��,G�,殦~��^����M�O&Z�Ēi�~9�)e;�\#=�|��6 Lq�|�G�5��Qtd��������P��|�:�x:5�'״h
�7�c}y&���"YR��(��l����ژ�-���@�:��T]oAZEG#Zy���Tsj��C�L>f5:Msr"D�M7�06s�廤՛�8y���F��X����%�'����
���A��X�B���{~���c���9�U�l}<i-�L�F�3� ���u�/��1��J�=��6F��?f���,��@\�k���
����L��Ô�F�w��A_����9R���]`�ژ��,��Yo�D�/Hƕ.`�'�5�:���؍� OI.-�q��Z�cY&u�'�z�R1\4��H^�L˼6��[�&vD�m�"F�j@w����< 2��! b1��S��d����qfD��r':x�}���u�y�%�"���2W���.!8�@��)�iE��r�&z�-d_����Q�nf�%��2}��}dU}|k��D��R�m��B'/����o����{�������c����Q�ﭢ�V�y����bBޖ��!��'��(7*}�Ad��D� �BU_^g�;Y�s#�Ν�JT7��2nSN�}(�5�	�R��]���/7!�'�uVv	J���[T�'&X���u�Ln��-	.A;aX͆ �=C'��>�|S���7�u��m
��#J�ؾdF�mI�����ێ�0cs3?%FA`CD�K��1_�mn�?mj���|j�x�7��O�Q+����C�h[��:��H�������n:��"D�vȸ��fhag ��p��;NZ[~���tr<�����^����n0Pv��p���6S����#���U���7����3��͗Ug���4��Է��D~���{�Y�Ļ(������i��O�z�Mڱ��]/SP@f�H���`y�&(��t��8����Jy}.ѣ������C3��׸#��
D �H�t���P����n\V&��)��e7%�.�Bo��T�N��R/L�Σo����˛p��8��'��ÑeХ��&	-͗U��H��h-Ф(IrU7E�%`abQ��3�Ҟ�~"ݾ�+�w��׫�V��.mX8U�g ���Q�3�q6W
n��߃�e��lv�i~G�P�xYg�[j
RHأS���!�yCS"�����m'B兪J�����f�8�Ak�r�5}q���� ;]��I�����!A�~'�h��?U%�/g囂��`k������~�fJ'IQbi+��x�L���0l�����#"�I�M���6��k��r����Nh�����偐��҂�����	0<)�{�K���шb���� R���ك8�gS�~ܳY��ʙ�lGU3z�c[����"�3�%{i�Z�e b)���,vV_�'�
B�^q��F2=�B� PF~�@0�	��9`���(���@^��G˭OD�x����)T=�N��@{���3=�x'NhC���lw�8vB����w�\�AU��v�R��&)��������G����|:H�J�Јw+��|������unp$��ԗ@�f���J*��F-�Ќ*���-h}J�N���_���&E�`����ei�v��ϐ�h�AE �P]�.�&KO>E��A$�6����r�[oǚ"Q1�lտ�K�����P9��'#Ƃ����)*��e�ў��u2�+�F[��_���o����K@[�=?l[B�8�y�^lt�-�s��R��'�!��aVs�}���/'��`�,��ٴp�jL>"�`�y����H��򕫿��vy���N�ښ��ȿ��`�����k��Y���y����U9D�a�f!olt3?�~z8����}tnغ6�"��l��y9�˼��Z$�\����H�/1Б�E��X ��;���M�g���kjR��ڥ��lg������K�XX�c���+�S�Fd�U�i
?+~���H��plR�� lƦCځ�g���q�ڼP}p�A�:ɍV�p��������]ѿ���`��&X��qY�,�X_�⣾sk5p��h�����D(
�1/�jŁ"���M	�XA�V�ぅ��RΊ���`�W\�����ޟ�d$ D 2��4L(9�3���+N��ԋ2 ���yr`(wT�7Y?����Q�?�����r�Uk�j(�������A'S���YOW�^�pA�]Q<�ɨ��&��V�h[QrHlM�V�����.8�CP�F�]{�ce<@J��X�&v��� }zb����K0�[��gT�.i$ڒE�L��2p��E�jn����]C�MY���;�싱p)�S0�q��zY��*9�â��/QG+fQ��,�JR3D͝���ɷ�"8?4\��"~mԿ�����]Vd��T��&/�#dM;i諃��`#ۚ�Y�كu��`T*>ю9,�J��6�3���v?��zs�/��3�َ��wKT�M�D���v�g��C�C^
,�����^O���5/�M�3�����u���,�i��Z�w�N�G��9�G*��˦�H�hī[t�����A��:B���Ȳ~����1�z��/�Ɍ�#��@$�0��!�����DUއS(�H����A<���%H�M��iJzqk앧H�2ʤ�e)N�����c�Jj��h��J�Xl<;���MV$�P���'i� ����nᾌ�(<��M���pkC�*ؤO&�GWZdFb�����2���J����;h��Xq3t),�2B�=3�����۩�9]ܾtO��TF�wIT��ю�[�]5i+�ݳV��
/2;M����5�߬1x�&2�ux�xRbK��:�¾��V<U�6jIL�i`p�J�p��uVqį��Z�Cg�|&3�C�����t�*��*!�P{9<j<JX�B�p���g^yJs�ع��"�c�i���ȫݕ)m(���µ��f��ɝ9�P�
<ο}+��J��>|�<�Zb�:�K���)W)�<�$�����r+w���2�vC�Ŷ1MPe-��`��z���<К�2��&�H0�L=d;b�8P�y�0i�C���*����ո �
�wϪ=��Pd;�k�*Ff^��ZQX�!� �-��#km��0�q��@��m��ӱ����9U����
���ƿ�~��M�[�aO����������:��%c����~�d]t)?ФC�
��KS=T������ٌ���M���������7��^2t��݋y?���w�g�6���.�Ei$;��\�QĥQ�p����B)��2V�T[B,yc�;���g�O�����EDA���}$�uv!�[���2ڼ�7�f�o*�*X̊ѓ}��A) �c����F�o�s��wd���GOM� K�����SN�\ 4�_k"��!�p������բ8�J?!�|�E`��>�>�+��$MeJ�����0�؍��K�M�hzܴn�K+���>h7�c�'X=z��W���n���\����(���{���=����N9�1�Q��L w��l��M2��X�|̺ˉ�(/ً���u|�VC�{�w�V3�4��C+�A䰛�E�����S�?&#O|�����Ҡ�)@U� ��h�v����ޒ�\@��^4�ð,6�#7{����(��֘�Q�	�w��4���8�5%F:J$�����yL�zRe�kS�I�G��z��U�8W���!��|ՆI'���~�M ��/NA��t�^�
?b5|fi�;�$�Ȩ$D�X�O���]�k�&�x���hD�wӂ#1򕋌���[�h{����F�5�K�U�����y���rn��2�<��q� ����J�͐���"Ս��&�����U��:+]�\������f���GM����M��'5\���dzr��a����QL��	�q��	�j-������Y`��}�y"@n{:XO�	"pP$�ҁp�d"D,��hOm����yI7^n��������:���q2�����`�\���N:+D�Vegm�Ny}�1���I=�uм�Q�E�q}��2�S���G��%��H�e*j%~�YM��bIߪ�sjpYT��?}��?BRؖ�����>�<���;�d�����|%�w�D#������.����,��Iw%��	_Z����Js���o���vJ��Y n���V�CК�YXȣ�\���m�܃���P�܏$I�W�SVQ�V��e�6-�����\̀0���8�U�"Q�\`c�(\�J�M�Ԣ� �Ύw�q�i��hލ�~�c�NU�"d���I{�9�lٜ<��Xu�뎖�>׃�F x`�r{�D
�g(��zFU�N{f��%�%�?���]Q�t�e.ҿ�2�L�p&6%J�x5QD��j9oV-ls�|��0|�?p�S!G�
�7[� � L;!b�ﴃ3d�d�(v���r;��Ա��$�+���:ӵ���+�7�f�_9S�TX�K� �xA�]���Q��c�\[���5"� ]���M7�%j:0 ]�W��U��ݯ�����	�E����H�H6>f�ϫ)^��#C*@�c(j��1q<.�}�9P��h�/U�g#������
�_K}��革֗գR��b����K�.;[�1�x�ּ:�u�]���cI�4�{��_a0K��i�ڪN	Rj�n3�2Ė/{�mXE+ƫ�h��ė�6h{�g����T��t��o���� oP!�O3o�7E��9y�Z��q�v@h�@��Hi�5��}|�`�{$=L8"��o��8�-�R7�L��
�.銏D��v#@?�qX������$Ki����4n�lV�u����u����3ț]�"��>�e��9s��&[8��fu�۳����o�3�J�z]!�A���S���\C&�#�/�[��)!�,�H�]�#a��q?�\�2�����%xκ���C�~�.�|��sG���kP)dp&��R'V�����qn�H�lv[4���t�d�LH�+O3���6cB�a,�?ꌍ��o�l�S˦/v��ȎKd��3�3\|r� J2�	�~��t���F�>�R�W�m��(P(���_/.��b� 3��!.��W0���m��e�g�Z�UFB'+K����GF���^L�m4g��ڷ-�*�c��Xc`���omg�/�;=z�q�^j����C� &(;_�P��ȿ��vl\���E��ё�K� �eb��j���Mh�Z�vc���F��e�KNA�$�L�Ԗ��)�ܹ<@T"�ӃĆ�TA�N�E�7���a�m�C̌�1	n6�+���t��r�m�D��\��!�p �+@��Ͱ��w����.@��s�ZյoN�0���#['�0���~mb�-�1������'���q�4�ϔc��ӛg�E�3U��D>�ɣ/��^#L�Lc�j5������y����������0�O:�bnh���$)�"�H{:�|����a9�z�kD��,����$�z���D^ΙMu���nUZ����:�Ck�%
���ˍ[��;u���1�#��	�"� ��iy������;S]��h�U@����"�[JMn�L4IsZ��h�@$v�c^���K�+
써Z�̎/��ߜVMO=2�HBG���:IF��'Ӌ6���v�W<.�ջ���uކ�A�$���-7��3ҏ�XGq�r҇6�	t8�'B���'d�� ���x�I�T&vx�\��b��IY�3��+D�̌|��������g_|�0ؙ�$�Q�vS�Ma)?���Xд��~��)~zs���'+n�9Gݟ���tB �V�p�Σ����;л]S ��|�Q�7s���Q�fs��C�_/��v��#Vi���m����_R���(���� �f�����ݹ�d~�����B�~��B`2TM�d�1�Z�v�� �S��Pa]��DUW�A����;B���(���K匇�\LAa�~�t�
a���;ع˰��&�}4�%y<�����b����J�8
tG��-5���=�+���MP�OD���SE%���F�V/�}���u=�m!����>�*Ɉ��m���3-���zo���&oX2Ǩ]�����瞣���z�C9�$��	�B��[=~BJ�$�~x���`�zVl4rL� ��p.���L��"3�Z(@�\F��W<��B��ģ1[��m{�y�؇4H�Jk��������Ǘs�6��Yl�q�Z���ʖ��Nx���0�F��8/[����ʹw��% i;,@%�C	o�>�,w��1m�v�������}��uTи\3:e����f�Έ�/n9B��Tv끁��4-��ł��Mt�^Do�?�u��ֶ�`��a;���I�q�ȝz�G~ڱA��������������Tݭg><�!�v_�F(v	s�D�E��Z?U�n��9.f%J��ȥ?���t�r��- ��%�
h��\j��k �F(/��b1d��Ȝ.$@6.�q��wR��<�pC�3��-���ߋ��CT���,
5:&0�xL����I��,�� ���|�y��-��A
��}u6Nm�.�R�8>�b��,3q8!B��h�2>2MD�!=��!��������O�!f�����xJ�6�v
�b��� ����$l���2���1��*�� N�'��4�g��B�s ����9Jr��I�f)�Q����2���-[t� ���B����r�})ʚL�L�-��y�����L���(t����[��+1���ߣo�\
���V��~�f?u/��lOD��.1cȤ��?8�g�Me�t���-W����d����7�� �yq�
b o����U���nn	�Ǥ-P�*�d��8z�i�z3�9�6bA�'W�MMg��$d�{\;�����~
�~���Z�[��H�V֞.�â�c� �bę�;)���t�	�O~�D�ScȢE�f�EĖ�Ň�Z�؛1�10zU&�d]W�
��qd�3�Z�jy��O��iz�$�^� R���S�ڈ���;0��FwBs��gN_�h�Z"-���3������,�QХ�lK
�s˛kk��py�-4QŦ�'�a��J>�������*v����B
�e�q��&DO�ɩ��k�$�j����
F*g�p	����D��`�!9K�G�Y�JD�bjz!cm��
w�_�x���޼�M��۲z��ɓ춊$��.���;�4���F���I�J7�X1�H����7c&yg0��R�N��,��ƌ����=	�����}|ٜ�7�$�Q� �R���z��7	�Izz�ik�	�5 �ر+ ̈́�0�&"gO��)z�ǈy�|�Ź���ީ��N���@�E%��}v_������ڻ����7�����Θ#ҩ���Ƀ�|�����>r����Y��.��s@�y�6�.@�Em|���Z�ܵfU���ʁ�����gU|$4�"]�ð6�躺K'4C�?��
k�J�"B�5~{�1/��x#��xY�Q}Dk]�m����U��H�)z�r�or-�;T%bVO�.{��W'k��{O��r?a�W����|�W���7_��eO�
�P�%Y��m,�3g�D�`�,�i{���p��
s�Si�F��E�˵v{���Z��#)���;���в
���M]N��M��	�ڧ��]�%�Aq�܎$�{�g���^q��P:��)֟r�7���6�ȫ�i���H�`O��ft&�����*wrag\�駱����*��T 6��ѠGw���2��R��|cw�Ҧ��v����+b�95��:
���	_������~�}��s����W�����/���l�D�ݚ�aXB����������>��$���ўl7щ��鈜��I͒T�P?����%u�N2�fs�MO��[�d5�_#t����X�Ё��1 �������:����2ϵ.-O��|��2����ju/Q�nL�+[P��>��g�{x���CN��dO�=<{b��F'���VR����7Z�b��7��C���~�n�b�nq�t��	A����1A�«��.Z��Q�G$�y���/x	[oV�Yr���Lb\$� ��vO�D�U ��߹[Q⁵�C�2��6�I�a=O[�%���B�:�Jr�
���+���OO,A�kvL�ĥ�Y�ǜ�CU�Q��q%�5�)��ϸ��=z�2���Xo��m��[v�}.�A��3����\����lӂ�h��&�r6 �,�*	�5�ҕd�OIH�m�9&���׻f��x���{�X��y�a�*�G[�9$#���_�*��dɠ�B�����+}o��v2��XkI��S�#���|�E+�Vk_�Q��H�x�]���5ƭ�$���p6w�*�,k�w �hO��ы�g���w���4Ip3����2��@�;�8�{��r�u^sN5�e�$��:���F)�;R5�!p�V�lq� �p3Fă��vB|���X�q�v��R��n���(,��F�F,�%R-��m�u�ꎹM���eao"�&y)�����o�05��4�ʷ�VQ�v ���2g��Y)	3a,\�}���[v|Z4i��esc�A�ef�i��V���n�73��<Ķ�o�F^C9b�!����hC;J�-��!^��- �Y�����9#��lo�]�j.�4�~MA�����\u�ҡ������C�ϔ���<���U���t�F��5L�ņ��O��wp+�KJg������,�hf'˳򲽘�C.� a.��IiD;BJ��0��!f�<�,������+����rar0�t!����c0`f�\%W��y�OW_�[���(o��x�[�2��O.&�������Y��T�T�����ͅ-�5�.���}\x�`֐0��L����|��*%��s}z��C��OV�3~r��8��u�fګ)V���H��t�� �29�p����K����e���	��F{�kX/��W�N1�JvDi�<��B�b� ��^IHɪ�VG��C�=^x<R S� 2teQ���-h�9nLA�l��{�?kZ`7`�T�rl��H�`M甚�}�+��~ɴ�]���s�^+�hw�����N�G�v�� ��yƷ	=�~�S]�9e1����W:�4�s�J�.��M��G<��`��z��$ QT�R:$r�po�FY}��`_ބ�z�s�ئ~��AM֐V����}P�J6��W���9�֊�8c
��l�9+Գ����㊅邡J�]��=u��.�`�v���7��[��ΚGZ@|�UtwG
G~�cy먴�`�R�nZ�]w���X�T8���
b����w]%#xZ3hr�\S%6˴����[TV�*�S4��_2���Z�*GY�&š��;c�an�-�L�0�,k�Σ4mȩA����E�m�����?�����RN��Ǣ��л��I%O�+ƌ����GhLU5��q*&
��;7ܑ*3�Hc�a�hVT�������h���A`������S���496�EZ�+Ec����|���s���A���ǷKu�µ]�zbʦ3���1��ݤ�۰���NG�B�N�����Ջ��'p��NT�4��7�C����8��'HC�����x�)ၘ;K!��W4D-h	1{jyO��~$���w#���nS���C�c��6��"_1�᥾Ѳ�"׃��n]�-�O?�}��u�����q�7)blK�:]�
�)L͏�b:����򚫼m�ӭ������a�K(F�^�!Cc��خ�0����0��S����6\�lu�eǑ.Q�9�������V:�����(����\ȪL\��SÛ��{���%_?���t��HK� ��uˊ`�"P�k���3�}����0m���-���;��#?k�K��v���RF�1	b7p�Ktp��Ee���m��=ڢK(_)<����P1$��d����B"41��Α�6R�4gTRޤ+�~�rb�rȉ�t�#��i��G�V����`������ì��2\;�ІX��9�J�е- !�fg]��������l��b*fF	��'a�.xʌd�x3����DU�V�]�<)��_c�p�?�y�[��25�氯�T#-|��\�S�#3(�� ���Lt&?	M{#֣��d� %	K���SS4u2�G���]��K��X��/6PE�H����<J;���/?[Yv�m��)Ͳ*���?s=s)Ws�Y���A ��F������<��I�ah,k�?����T�D�N�h�3n8�U��D��w�s@�]�����O�6�������8ۅO_͔�P�T�6�8��i��B���(��c�i�b~zP��;L*�6�\���J���vU�J��׃g�f��?�W���
`(Af����c��0D��s���Tr;�/m���p��G����H��B��M�4a�[���l/�z���l�Œ}����umb�=Vh�{�0sX-�RJ��� �Ӕ�H�m�(P��ݗY��y�������B����f�0��RPt�Fxٽ�G��{�# >&���/�ܼ���r �D^��T��B� II�J����1����QC�,������5#���������B�tx�/9%�ı����ٛ����o�η�)�W�ת�����>m1�{eڪr���ҝ��Z���ؠ_��`���&À�!�bƹ��cօڱ����t���d������W:A)������ ��W�H�s�`Mn*�`��A$T�9/��?��{��V;B��V��Glo�3���_��--������2ʆ`Ef9��5��r��E��ຩ����2Ɉ)Ht%�u�38���ي���T"ߡ��?U�66+��9vL*��y�~~���E��`�
��j����o6t�7����.�.���Z�u��4�f�크� ?OT��j�H�
Ӓ��燐+�Gr{�\���{3�
ʖ �i�!&HZ�=.���j�h�f�!>  (q���%���ŏ�`�n(9p��1�ya`ŭ������7K�/�W["�]Na)�.*`�m�^�c��a��ĭ�{k���%D�,�Yy��8�#V�}���2��cOV�W�Aa_N[\9�u�"�ç�HJ�2uƍI������?i���m�i*8���wG�z����@���L��<m��/&0�H��b���SS�)s�:h�]I<���z�Y��^Q�tx~��R�ob���@[��۹�fE_̖����~ߣu�.�<L..o;���6>3�RL�{��Yz�LB�G���>|�3�7�F^ۘNj���Ñ�ӱ��Kυ����]���b
��H���Y�F`sRB#!m'
{E�'��J6ĕ�Ry�\$��T��>��nfk\O��u�$��b��x�A��3�^�T������̂��^��+[\�R��$��:ట�*y�X��� ���X�<�9};=P�1�H9ڧ�#-p�À�V�RBR٦�E��PLh��ı�h�Ћ�mK�u�.����/&ګb���%�s�`�R:C�-�VE��h��=������>�̘��&d��ļ[��)m�Ϋ3��?�Ǻ��̙0��������?�l�.ng�8|f�*���3�ٰ�HAm'RT	(n!TS}�R�di��'���j3�YQn�#<���&öZ�'����0)5�����Zv��,��)�b�g�A�3@�':@BK7��Pnz��]m �T;<�τ�� N\o�B�{m�dD���jֹ����*d\��&v���B@"RC�>��@�tú�)��� �)�˅ �������Y^�2��L'���д�7��6��6��p�L�5�H6��{�xI���a���&��@�����hǽ�M�XT��V�a�N]����:�$�5�����]��>��0���L]#O��7�+w��*9�4�&�gӦXM͒��(�CKթ��1Gۚl�Y���W�K�0��+�uZkԃ� @	�\��93u�a3O�����R�WZ%��2� ���n����I 4	�@�W� ��Ρ�l�dT����]ef͓KAi�N��x����Q��o[nc�ї~i C#
�� �8ӂ�]:�G8�{�������T�k�7ȯ��~#��6�,�@��|�SH�MڏW��(�Ult�uv�q���d=Z߯O��ޒ��R{��d���T�"���K%`�√9��p��iF���)- 3s��&�֧�	�**w��8݉g�ծ��U�m���D�?��An�,c:/�<x���~21��(p��I��y,@)C�- ,HM�'�}	�v_j7��+��;�I�(�K�����k��
0ϲ�x��ЕQ�	�g�qB��}`�b�)Ƶ��+��2�2�ݹ�F�z`CWS�]ZB��}��ꮆ�@Mr6Ҡ����4��W�Yl�c._����s�i���\��#P5ex'!H���_��Bo0�|A��9Nc]���ms/�K�⇕��}E1���Bʙ��(c�|�� O�+cuڠ�q,'�"�)v�~os��H�yO�Ò0�rȰ��1�l�1��el��Z]�X_ƌ���33�,K�S����$(8@,��h����9�'�\�P�t2�נ8ȇ	�!�^M!�N�kbp��=���?��z&)�vW���Z����v~MI~͟�YM9�u�Y��̺�W8�^j���8*�Y�Z8U��@��&_�L�*Bf�� i��<m��C�D�;�����L*�iP���vq�������< �F�L|��l6�W���m;��z��6�!I�IWa��9�$=�|z]c4�WC^]������%���V��t��?��*�.�(a�%mk|� W��Нt�K����ȥ2Gw��͞s~W�u&U��d`��N�VV��r/~�#Կ�5��Em��D���������ƿ�v3��r�4���0J�n���4+5��7R�5�Q6�To�i��]PW�%�bԈq��4�+Vw��2Tq.k!�8�ҟgS�;����	���>�����P�m+C	�����g �i��f�7��MT�	8dg��ʂ�/�����Jn�l�����t+��o�u��'�|�u@e�����ڣ]�~I�I ��c%��8O"X��>���a�E
X�`�ȵz8��i!��U����EnR5��Zکհl�E�(��z�t��YS��`��;�:�'u&���E�}���>��:ϔ�C��Y�d�E� ��U���A3��񊞖�J��3�͚��U�`F�O�G���v��y9�7
j��`�j&4�%���x��a}����r�w���X+�J�8U�P}����ʅ�P��6b�]�
��Wװ=�Ƃ6�/�۟��Ns�Nbj��7�pN�`6��p,� ��!��m/nnA��c<��օ���?��ۤSIA.V-Ϥ:��"��ɌV�Y��/n��=��@�yq�,Υ��Z�"],,2nuU�|N�Q�ڐ�'h#r�4r������]>]��b�@ry��:o~�ܠ�]�>7��Rڻ�B�R΋��]xc�!İ}4뮩$wc�!K�Z��x;k�$�_�ƞ2��Ov;����5���>�'���*ŭ�h3��"w�N`r�2��.��z:�A.��i-�����ρZBuc)�k�c(HV��c6#�kF-�1�oq��L7��s6/�����.Iu܍�A����p�F3vAzGS�D�{�3����+�R�Z��3U{ۊx&x�gV,9md�G\W�<;֯�IF��a�6g|��R1V���(��RT�ы��^"D:�95��!T������I|fU��&�fpI�-����.� ���-{�}@R�4\��p$(�&��B\uz�u����2#�5���B�X&۪f��I���u�z���7�F�jÉ,�|����L}@ſBD��Z���{�Gc�K�%t��w U�8��_/�X�U�$)��A����L�OI+Wiwspf=�{�M� ��ێ8�Fq�"K���Nz��+��7�A��U��`/��6:SS��A5���LÆI�}�9��^l�HX(.��a/�&������WZ&���u�G�t�*�?�r���ߕq�Ҿǐ��u�;�?��(+���H/�6wU
fp��|�e�)j�y}�~�P��`Y�sbU��$��S`�C׈���n�����HG<�L�4B�0�9�@Z�+��w�>%{	�8� v����k�7��]��g�A�ӸB:�^�����jS�h"���������-�w��	]9���p��U�L�)��/�	� ��j�G�z=I�0G����+�B���3��~r�:5AZ��$�*�/��$����In�sY!�����8�{���,��>�#\D���=uƠ�4)/EZu:�<�V+?H�D�.F �a�qѕ���,b�5!��ÑԒ�W�x�W��{��QSy�uVX��F�Ek��n�m�6ж�{_���I6@�E�A뒓�����5J	��oU��}oo��� �<�*h�h�D]<�H��Ʊ���
g��3`HoI~Ҹ=����QW��S{�gHϴ�]� �)�ja����r�;�,Fᖛ�K�0�i;�e�"��3ٸ���~��FG�5�v`˂�Hk7(�N��	�!�ڪĝc������aV��b��4c'`[U']��FY/0gB�L�8.�U��Ү�G�H�қ�~�\K种��S�����;f���a`�#?����7*��%«���O��T�A�m�/F��ZЋ�e_e3�t��De�Ǚ�rHg�V��X�}��Q
͗w���L5�}��61�ϣKuv�>E�#��n%D��Z�O
$t�\c�=Rܧ�o�,���
nf�]\[�30��~�����y��d��X
�]9������J�g>YQ�e��ǩ�2IǪ{9�S�m��T;���r� 8�x1aoO(֯���)���Φ�#%�r�VQ=�ٷ�ln�����n��.���跂�R��I��9$��M�w�fK�
��϶;W�H��ʌ����>��̼�d��c�!R�y�[x/�s����<����m����ě���3vn��K9s|,wC�V��H���������QPt��c�P��Ja�$0��7u�ݻ�N��� tnk}�$}dY�b 	�	TxH���Gc�� c�b�\��ψ��0����L�]���#`lw'c9��(�q�[!xm�X
~�05�Y�3�<�<()T�Y�K4�N�G ���� ���ib9�m9e�pY	�K��4/ͅ�G�CےP��w6j9}�n�\ꪼ�/�m�@�Jo�BMO��tT�"��t��#�������/�����|S�-3_��prY${ļ���qv� N|���n�ia0�)!(��jT�ͩ/೎�|���꼹 ���[��\�V�(*��4,0=�Kq�|�������.-��*@�X.�g5Y,f9I�����T10X�Y�gj��!�R�u��F2!������ ��!���9��'�g��Ѽ��+e�`�*7N0���� T�I@ *8,*AMs�cC��PS�h�� �/��gj��i	m��v_�����,�d�.�H:.{���� !�u^�]9�M�ޘ���6�E1D �"q�J"��yQJ�P������{C�W�0�ώ��u̹��i�l����n�/��o�%�T;x���@Y���ާ����b����F]�H�l��=�j1��HC��7���'R2�������R��֠�<�P��Nw���X�̂w�(ҾX��3ܦlm�Ұ6�RH��ƅ�~p۰�Ŏ8�;�X{;˳�g��&!i�s7����\4�}Yf4�
7!��`5-]6 �
����!$YH��)5�����Z�g�ߐRĿE��p���23M7�eC��9�{�toj(���,�^�����|�8�is+"-��k��⚦�8g��z�L�7X0qz��mA��N��n�-W �����ʤt�PD�Ÿ"*���Hzl��T���'&!�v������q�L�$�b�%v��ڍ�ɝKۓ�ջ}Rxrs!ܩr0�> ��5�Y�@��]�G�(N�w9!���mVq����Bzb8`�xNp(�i�`�1d�Q�dhĞ����==��?�>ie��aa��2zz��?uM/L�5Ɖ� ��z�p��2�l��!�T��mc��yM"�p��yN��uTDd���؛�q��Xx������J���#��V�_�J�K�.r@$1��ІƔV�Hn���v-�F����;	"%��[i�$���-��FX	�;�θ��3�|�Y*R�d��Hl���J���83l���!��8*Rq{�{K����F�����Jȉvyb���y����Ms1�C�P� R���V7��Y��W����,�HS�����p5�R_K���5]Bor��`�B�jQ��)����G����_��n��~�Fr:�&|�i�B�K������R�A],!=�?+�gP_L�B�������[H(��M<½Ԣ���z��5�������ϟ�!;�N������o&?���"�Cr����ԟ��y��o�ȁt��ۚZ�l�Ǿ��|��Xϔ%��9�)Fƥ�R�����#�]��la@hA�c<�\+�]�k"�o������w+_.XF2��c��9�w挼�l@�b ��<����+6n:�L�?X�lY�°?X�ѓ� i�L�[BS�;�'���!�aF)@i��:����ӭdi#��ǌ$��f�#3�q��/f �΁��!��c콠�cޖ
jt7w[�Ҙ�9-P�|b���	��>b�N�U��7˚�;�����	�p!4��u!8��%ۀ2Rq��	P�x�]���a�GBAAR��܎c9ɟnU �7��G��)FҾ�25+�X��K�.Y��*��R��t0�Z7&=B��)(j�y��]8�~��c���	޲6/����%�O1�E�`�x�IEP߯ھ"���WK���O�/����-C�Wv�8�����)w8�V��f�O��vcH�����!��eFV.��选��>��(y@�G%o;M�5?P��!�1���������={T˝GEfU�n���^����.�[�H(RcH��(�#m`�H,lR���${�7���sօ����~9x�É
X�e�<K��Y��;���/� ��ٵ[�R�&)��[����i�[ ��¨<�{�	Yu�5έD_`�0�A�����`��d�_[���1����`�@PQ�����F��pkz�� ڎx�ع�1	�6�]�q�Ŕ����ስ���*0��F�=�4��Oa�Ź�'pu��{Ij0i���G����z�<C�]I���ubr>��v��O݀S^%q/�΂�=}��J�Kb~U��&�>�'#r2=�N��K�EA'��n�E�^��� ͼҪN�F�2�m�GaKS|V��	�\��-Q�jdq�He��c�4�|bS�!��,,k8hܠ"�;,sm7��~��kJ�Z�c�3k�c�:r��.�0���,ڂ�]���G�c����]CO�� Dl$DD��	����J��|�#��E�����:��o2ǈ,�����m�P�����f}Z�lT�@\���I�~�/���E@K
�4��\�������pD~E�eC43�&|v"Bmgb�]f*$܁ S�Sg1���@6��w��iӬ�a�٬b4�]���Ϗ��-����8)W��u*�Y��+�gG��W*��|�T�+�|�����G�_����]1Äc���<��{>X�ӳ']��62[���I��b�3�FO�׻A�D+'�����Q�ۮ'�������9C��8]�q�St����n�Q{o�6uM�k���x�NS["�f�r�X��������R�%,���^�@�i��ߗo��^�D=6؝�Es)�Y(l�|L�O1�-���^]2@[s+de+�qH��`��;'�?������p���r%��_�^�_����]cb�@E�9
�:ND��V�HN�]�_��O1��@.�Hb�����mJ�"������R��:$�_|.�`&f�T5�[���ۤ����t��>)C���X>��<k�u0A ��J=��1�$bE*3;��q4�Ljb>-�f�� �JM�8�,���싧�sw5"����@
`��տ�+����9�����/���	���u��J�7Z.{f�?��G�sư)U�/z�c���%ֈ��d��Jm%�j��D�i�]��B�r����ig�qb��c�>�A�>u9/}�C���lʷZ���%�k�Ԥo�3�:��y�x�p���(Z$�AÅ|�ܱ��qp�[a�����cנ��l� E���hj���t	�R�,�7�S���_s�s?����kI\:N?3�-��rl��u��[$an]�∀��mH�z�fτ�y��rs�$l���r�,z� �2w��8�_��u�g�\|�":}& �Q���˄Üo�s+XE���5č��eC
�[t�/L7��Qx��	�2* ����l}��M�.P��	Bw� b�;��IN�sdz��Q����O�
	�W��F�8t����Z9}��d@� ��o�K�Y�����-�g=C��q~�+MGTL������e�dN����l�E�l��b5�z��h:��� M�}��n���Է�^��ּ��Qe<������J0D:@rX�I��,:(k�uw[|
l�v� q�Gn@�嗭qܫ�3�0������=��'�z�1�+~��~�ө��1����4Yn�
b�[� *���,_n)��E:�.N#GN�/0ط���g�6>��a����F�ˑ�t�a������dY&�$���!t`�Pk� �t��6z�^剑��e����A�A�߇E�+�n��#�ݚ<&��6��g'7���@� ҭ�3WCI��W����"mM�v�8r~��O�}���.X���[� ��A>60�u�ъ�܈��TJ��J�`M:>��t^;��CS��`�����Q���qu���[����n�n|�գx[1ͥ[:��! �����/�e4�$��,Jm�s��(�c��񜏡����F�SZ���RD���vSŸ5-車:��.ꇶ� y6�q�{o:�*���-�H:�4�P^]� T<���]�F�L����+�FY0��}t,��c�3�_�|����}6T"��9V�M}��� ��T�3!u�w��k,�&���Sb���
�hå]     ��uq�K� ͷ���3����g�    YZ