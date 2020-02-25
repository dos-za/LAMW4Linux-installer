#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2108756504"
MD5="f0fd022a84dadab42aba13e50b91c3d5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20412"
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
	echo Date of packaging: Tue Feb 25 00:55:35 -03 2020
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
�7zXZ  �ִF !   �X���O{] �}��JF���.���_j��`*���j�B2h����<�����s%������ģ�:��
�*9T;�%�-�ٳ�u���7�&I���k�9����J��qٖ�=�A���Z��!���6"6�4\�9+�TRP�	�|�"�����x��C���o��:�"ɬC�٠SqsH	#�%|���kE}�)�r�)&|X�o]xC
��ѩ���=���~z3�[I�F%�5-h�壂�����h���G�́����~�@]h��E� ���a��
j4�K�&��$w��D$�v+L+h_w�
�9�STׄ����'�RE5�c_�5fz�}��\O��&���9�4�[c�m��92;�eޙ&xy)���H�xKN�����ơJ{毼��t"��֮�n�����ŎD���+�6�\������ �bmL��tx���J�|w�/��2�7��V���q��37�\X_���je��}4�V{�\�+32V���i0����a��o��h@U#����_�Rv����*w�.�g8���s6��3D>�E���H�
t�{���(��H8Ţ	h ����Ϙ�(i�c��G�����b[��Y"*�߫V���b=��<��s*"L��䟽{ӭ��Ԕ8�usuw���6��]���vS�	�&ǁG� ���w,� ҇s[/,Q��, �O��X��:�xSmU�W�B���3Yx�R,���6_ryڃBm����^t�%�̡~	�9,<e���
Y�tk��s�N���1-�u��.K[}��Y�5������A�K񤲍y	���ן'��o���"���t�s��,�#��}�i O$��_0��5��mY����kQQ�kś�C,�q$h��=��W:iE0ۘ��s"�%-hj}�t���`F�j�T�v�]y����&1�=��1C����t=WDą�h}�ؼ:bIM#^��w�������*)��*[�"�%�X/��Dd߰�Ut
�D��m�Kgz�kuK�]�N��qs�޺�m�9�2Y��۩���|H��Wz!�ʬjv�V�nP����]��GR���{���̱<��wc�.x�⁬��u�#�O�x�m���S���]�]���p���@V�/p���6(�(��������{�{�f��#]���4H�:Dc�ȧ�a�a7O1D��8�9L�x�pW��H�a��Ce\�Z6�)/�����\��S?.��>O� ���+H�x�X����fnm�q鄭.N��4"7m��?Դ��\F�JͲAE����Bz� �!�k�M _^�t��1��F�}�T�a(M�}�fԾ;��~��_�竂F����cU��f�Tjy�n���A��j�`c]:��%�/�M\�E����@1ʙ$��ԩ<lqy��tF�����X{����Rhm��c����)T�Dw�)�h���@����F����M�#�I�*A���j�H�B�˧V�Ưi8��w����+VNO��Q��`��B)]�Џf�g�$�y�E����F��Q2`U6O�h�Fi/�c������,�BK��,Cb_|*�NW�2��w8�݌&�����5�pF:���v/���*����uҀF���Ak�}h�3��D��F�b#	�ܴ�M���s�/شhaĜxE����y9o�g#tg���	I������Z�}�ߩT%��v@˙�$`ud{��α�g�g3��8�Rz'7'J�`��� ��V9s�P��r�5��}13�ҭ�P��R�{|�2�[N��I7��9^d�/���&r̃���󛤔���@4�\����S��#���~�t"�*� ��S�/�"���b�W)XU�I��e�V������uotB�Ϣ��1��t�óМ�}�g@�^���՜��?4��U@�X����7��/VoLe� %��!������"�O��Xo%�>�\t݅�Y`Q3�=L�1��e�����߇�����j����0�����^F(}-\rBz(I���WN�L�ł)ٹ�E�n2}W���&h4���6��T���f�?����\%-N��x���Ҩ23��tq��d�_�t�����xDM���ø���ϴ��?�so���t\_Fa�87P�
�� �|w_31K�,|��E��{���d\"0k�?r�f5�en���W�c�C� bEe��,3��|�r�7Q&!�aD:y��tW�Y��N00���,��34�tgq݈n:GB�f�����?�!:� �����f�p� �*V��d�e�����a��^^B�ª��aFd��ɿ��i�������i#q�QL�d4�������"-?b�m�T�y����"����]󈦤�Xe8�I�� �N�~n{�O�;���"�����{�	��a6	�kߍ���7�`-䛕���WD'Tl�؟��F�9m[�~5ҫ��'�Qz��t����F6�sx�����V��m_����>���b�`�/����n������o���,8Wc��c�Qѯ���J���R�  w���F�6�	�h�H��9�P.�$���;��]/)����.5�V���UB��6��d�7l���j�nkd���(]X�����ne��MC�S}���-:�Ϝhc�⅜�<EQ8gp�(�G�66�aL?�qD,���z7������n����3�W>��Z�t����&��4��=���Z��/�#p���d�B��X���4f]�wW�D�ӁU
���TJ����� ��2�$:w��D	�ʈ�pkwcDMh�x�we�{�M��*q��AFJ�")	�@�^���1��n��E�7�lR�ٵ�tֈ����J5�L
]�eQ��Ki�?<da�M!��[���F�z�x����hg�ac�Q��W}=���Pw �[k�=�����%`mY�A�O(\�C��7o�w�>܎ I"9dv*.���s����v9�-E@����g��
����ݱ:\w0=Y��Ձ}a�?��^�f.�տ�ӦJ(|��ӿ���Xc�U�fF�vZSYpԇ{�,�i��
�5e�]!Ѹ�ǲ��:&S��A�n��d�Ir2n����D98�oA�3ð�Xa'/́ud�hK����ȃ�Z{g��Y�Ew�����"M�f'&��3MV�u�T8�aJ������R�boɼ���+���#>',�F<<�*������ȁ����c��M<�)i�l0N����?垌�7+�TK:׎L;�{�q#�j��47(�oqQق��7�b�CkX�N3�Ò���@����$m��(~�<U%����?��P�Û)wp��b�����eq��t�o��*�R���(�֌d<�	�ڸ�(MuR/;���1��0����&��[3�I�H���ܺ���j�_�Ks��BV+��π��|�o
��C�z��ƺ���� 8]�h8�'p*�5�	��_>Rɔ���MxH�D��<o�RD�z��� ��4�w����=��6��sAOE�q�n	a��Հ���l��By_�v� I~�:�]w{��H@WuQ#��H7=���/�#�1р�T�Hi�w�弦d�#��!��S�Jcш�H빇����3;I�TPι���~�K�%֭��dj���!��z�Hi5��� A�v⇊�6�3�:X����<��6�˺R�Z5d3�|/��q!�����|I3am�9��c�c�3�-V����^�q-�rU�KH?Lf�aWkc�>wC�җy7<D!��ه:
+'%�:3�u^�%_w'�tnO�����+�y� ���9^��W}�	��L�Y j1Q����1o���/F�ݩO��qܨS���Zl���`���?l�cB�\�8|6���V@�*h\#�Ak��V�ð���!.�B�V�J��m¤��ln��������-/���$ʭ*�dV74��H���[Չ�OB��3�����J�z���W�s?SF�G���FGx:ō��9���IF卨�a�X(<�xj��"�9��q<Vat\�}i�����vy1f#�-�����:����d��w=i��k��	R�ׯ,���w-�F��hC�>�.�ޏ��
Z0�}!��ޮZr.On�F:�
l��nlYO��h�@l��@_��YF��L��.�n��aN�(^	�EBG�M��,$םT|r��y�, ��6�v�/�>�g����QL㨶���'§������1�!0A�3�XųK̋Ybf��y��u��K����t��N�Ȝ�$��3���n��Rgd;���s����>���CQ?{c��|ugg?���2[������O�"���R���x�>�&�X� �����cmR��{#��85t���M�h�(��)y�ꇇ&��T6@\/l�%a����fR2�� {��H�)��	��@����j���	v�GA��˵������Y�g��;1�77���*�[��,�v�r��t�?��f��C@�r��i��C��(s�h9�\%�#|�:c��U���ґ��,.�RWQ���w�*��O.�1&5=�^#�J�g�m�M���o�+���j"�kDótǔb�]������BڅZ�]�L��O�,k�h� bw u�Ԙ��_ܩ�+��wt���Q���N�
���-tt������
���H&�]�g٨_��y����d�H�5IGW6h۬H�ܴW�OP(�.4a��AU��B��"e��kr��%�,j�o��hX��wǋՉ?D��lB�r�Oa�NhЕ^�Hu��z#	9�b��z�*��w���
�T%��H�wL�%A��o�bT ����n-2=�`�eY48��W2�5�C��H�T	j�{��}{�*�q"������.�ʁ��!�3�+����ND��u2��(U�ymgx�8��WK)S�� �7�j���َ;�բ�xc*g��������`ܶ�b�6	��d�GI %Z�谳1�]Eb#�~�`$�g� ��r���»̀�@P0�3�4+a�}$��r�_Qq���v��,НP�^<JX���Z�do@����G�,�S��8���ҧKD��)|�|����!R?��@xcGJ� ��5̇�
����|��)Ɂ�F�Jޕ?����.�Y+I�\����� ��s5��졚�}@5�v���S�	��h�di��
W�G"eːo�,.o4�v�N����f�x���c"�䷲^��+�Y�����1��&�>���8��[����[y��6�R���������N��%������}���G.z� r�E�.�W��*j��fQr��~��:����
;P�#�v�$K�pܳc���뉎M)`���M/#��ƄW�f/pk|�ݙ����[X�PxK4��Ef{�/R�m������u@��0i'$���{iG�f�O��Z���$��7'=�̭��^�n`q�S(N�{z���s��H[�z�i�@�!wf��V~=�S0����;��#<�pu�7"��`�nqw���w��΀oIЙ�S��f����WGD���u���j#r�N�q}��2�V;e���$�/Y���-�����;��N���a��4�4�T7Zd$�  �������ě�
�4��:��$��ER}
/[*e��%b�SB�V[̓œ�0g*B� �om���EFӸh���ەٔ��*R�R�YT�$O�"���9����*|�^��,����V��[u���+�ގQ(M�jm��M�mk� ��Vg0�g�c?��`��z���3,q#M�\��7
9��R#0��6κ֌!)M��H���;[��1E@�n���ɰpR�����yI�*aI��i�9y�'�	wC��,[�b�%dy?D�%��N������#�Ǚf�&�t~3��Գ����fc*5����������%>��#Kmq���rT����ωS���J7C)[���=eW�-�.4���C��v���S���@�m�t�{���x��J�7��5~�\\��tѪ�/�*�.�;X����1qq�uK'Y�S�6�����£�aC��Mr�!��nQwu����8o@K�1�᪲l���I���>�_ȽD���|��~����Ӧ!^��ݽE�Su�
x!ANxH�u��I�0�3:U�p�D�7�'(����1䕚�i@p(`F62��.s9YU����v�|t{SԐ���{hfc@������wP!��6ٍx�T��Z^���.z��3u��;~~�k�A ;49>)��)ek�h[��q>���Ü�Mߔ�ݍL99{_��i�t�!�q��A�Γ�K�IP�R%:!C����nτ�b���0 �:j'�EކoR��x����S����]͈"EVg)��?P��%pԾ\:�ɑ}�mR�{�yT�����~���;6��E>�=��>�/g鯤5�$�i�o���u��aڔ��G��R��R|V������/��qp4֝y����݄Ufi�ŕƅ-<�P�gҌF�>M�G+NC�Z��$�z�T݂��h�Ҷniĉ�_՘y�DFW3�.�R�M���MW�aê��Hw����nKs3�5 ��R�\�y��	����^��bǅ�+Fi7�3/�B���Z�8	E���0Asm���Њ#���Y��k��)�����a�dS9.
O!�6$'/̦�(��[i+fr9�&C&�A��c�?����a}�-ǰ�o�U�������\��L�&jE�\Ƴ�)x�7��I��O�	��aW; ��X����9�ݯ)�ʼAQ��A�wW�:�F����j��ԴFKj��8��&"��!����<��d_�1j#�8<i�Us����0`u<���}TC��d����5�ɉQ�t��<2p�ʟ�}RT�`M����ү@��g���3W n��`��W�D��5���;xl������󇳐өm�gK��ѯ��|M����d��`mB��C�s�1� �Mϧ#��eH�s��x�δ��mB��p����_*����Xz�mYqV��9��Cﹻҫ諐?�CZ�FY>� ��)3�}�|�\�,���ݪ�;[0o,�x~G%LR��S~}`��N����]�x40�M��9�m�W(N7mh�c,e��Ȇ{��&|A�㚞� �`0�7��e�NIs/	��YI^5߳|v�N�b�>?����玮�
y��H˃�yg��<)�ݽ��?S��A$���b{t�u�����`�İ��hbM�ʏ��.�~J`��'�u6j'�a5�R�>��'Տ�Z�!s@J*?��ĳ��i�P'Ef��-�3:�%�(L�F��v&uz8rb�i��E������N�&�ؘ����\\^C-'�IE���p@�O�7!�p/�7�C�� ���ۖ���S4�E�b9������HM�s���;��5�C2v�
��44���Ȥ�9�a���"1h4ݹ]&f����R5�9�x�MA�����>�RX�k�8�:>ma�7���k�3rL�A��>�z��(���;��v�N��esH��Y�dF�ߚ�|M�uU��[ς�53�:p���sh��cS-�S{I�_�l4YD�<=��j��~$��\��珖`�=@
��f2�Bp	�ܢ	��HzOFh�O��S"޺s(z�f!���e��� ��eW����3��!iޡ�oӂ�PbP-Y���ߌe�ŷ�1?8'2��[1���;��Q�ާ���4)C��}��8'�ͻi�,L�i�k؊�$��7��(J�����K��i1�3bf\9����3�wr��./D���3��t�6���U��D����eH� ss�O�5�,e�7/G���ک��l�hU D��Ir������_t�_;xo'l9��� �Y��̕�� �"�.�b���A��q#��|c��O?�����z�A^��˪����o�I{��W�=�].���{װ&H�?<`4�5/�jRyX2\J)��,	��NZ��p���8�dKc0�xѷ�'N������x��(���%$�3����X�+���:U@Z�7T;��.+ӯtٽKK�o�[f�L\�_&OI8������LE�	��z[_�"f��h���Ä' ����敗Ҡȡ�oQc�aa�Z[�K�J�����R�����)����� ow���}`��y�2������*��л_��b����3��Wrp?�Pi%&�:ΤlE���R`�D��S�C5�0����$KGD&�z+M�oO�ka�I{��i&��Fˏ����r��a�����j:9W�P#����N���b`9SՒz��8I�1ȗ�����
(��	bGH�����t��"J5�SY#����s�ԔB*�u�?�~����Ɉ��(��Ի$�n�P��:]~(����&� �g%�f��g�e�k��d%��w��M�tF�uv"�
�a_?�|�3�.�i_�������I����얀��1-�d���h�;�~�N0֟o��l��r{bV��<���6z��װ5yڀ���J$En�S\Y�U6����ꌿ��%ȹ��>��/֛�����
��H#xLi��e�e�-���C����MR)�/����m%C�G��Ӝ��]��tE4�!�G财(}Iy�� ;D;R���DfvX��.Gp5E��C��;!���:;��<�00�G��,is�}��>�q� M�[0VbE� ��d8i��&?�X'���!����j-��{::�9�FE��klq�j�esjğ[^TEO�z/�:�����h�;Dȯ�7�2�w&v)��I�}�B7vg��#�2�����&�N�b���頾=��?����� D|���;	�
�JD	�0�Z{1l�;B*7H�F�-��C}?�fu�kgt���������K_��A�ۤ\�O?d�R����hwN��
mu5@YZL�V%O:����0O4Ǟ�T傋�FE`1G��y#��B�S��_�/q%���B�=���?b�q������w��z�n̊�2���n��q0H���}��ow�2s�{����^6R98�/u��餎$q7s���(�l߽���]�da� ��~��_Y6ݣLxd�r��m���AB���c�?f�mS+�d��t}��q��M̮P�R�C:�@
��5,�(�d��d��O�BJ�����PxJRm�>�	l�
��8}��@�z���X�n�-h�V�?�F_u�+�sF�@_���e\���vӹv�F�yV:H�`��1���{�GG%�_����� nW|ǭ>(��{�>�s �(��ַ����	)�`��#��l��1�������#��^N)0t� ��	�)1ͣ�\�t�\<�[.�� �|���G��h���=��Do���Y�>��a�B�νQ�v2n���q�R�*����4��I�T�Em5�'!K�	�
��y�U�G�u���JC���3�����;m�Ӊ��9/��ˋK!�-f��������p�H�,��֢��g�w���q����yށ�x0�}���N��	ⳁ���g�BP�Bǵ�!�
�����	Ţ�(�fЕ�m�yP;2�������<���i�z�`�q�{P		$&+'��/��MK�`�*a���u�6�5f[F�)�y�/�R�34�5njO�:�Qƅ�w��{��?���`�Jk�!��ȩ8R:�5#^���m�`�蹊����/��:k��	��Ad8������0��\�D��������#0W��ԡzΫ�W簏j?�j�/���W�j���1ybצ����Tl�����l�NS�A�߭���0���9��M��5��''�R	�t'�+-�G}�e�)�J�v7�l˶ދO�^§ �*�6�e����������b�7���Jw�H�w�W�Ok��0!��S���i���� ��Um�.�/��:w;\%��q�B!��U�n  e��9
	����V�E�s��2����ť�O*!�%���.�
����}��a�]JOei�����}�W$����a��4�Իw��������/�]��΍��|N��@�I�"$�pM�@�0�HE4�/�f�O)�Q��#�FD�~'V��+��~V��7��D�R�à����P��,�s�' ��//�������jM�lCO���+�7�'�&.��n�]{vkem�ׅ�[�����P��Io�~��2Y�$a�s[	@|?����x"���@҃�W��L2�v]�!�����9�m����<�`�M�ꉴ�82��3�f>��N�&�|u딴6����R�,�_�ʿM�$.�YFp$D��'���XT�K�D���:wm��MJ.���?9�!9���ɀ�B7w�.V�������U�rV���V��̂}��B(�(��`��!ϋ�S2�~�s� ����8��{k�>p!��(���8�w�Ԓ��?8�k��3�:�Ӎ���;y)��.ʗ����+@f�t"Ԯ+qtFb���6�V��@d�x�|l��D��]�*2���[})��=������0�P���B)��m�:(	��J���(-�;EҴ=���0�Vʣx6�ד�ER�T�C�( 9RZb���"-IL?f�<U�������M*>c�i�����,���j�- oe֐��'�Z��A)+�]l��:�N���Ė���tiP��+Gxz���C\�<�H��W�*ta��Ǖ�T��wf�ާ��ԚjY:� ^M�j(�r�sB��g��}�?������UBW��M� y���Q!������XK^�W�s�|�G�?��M�� )h�9m������{%�jJ�i�Q�g�Ȥ��M�����!���Z�(��A���x�6�aO|�c�mo_J�C/�t���q�O݉�U�L=�$VL�����K���$[ķB�$ˊshk�?Fjp�]ݸh�@�s<sM4l��7�v�b[4Bڲ��/r�QP?����y}��]�R`44�92+��X3��*<���HC�Y�U��Hw��B��>��NV�G��
F�i�>�)_���3�G�~A@��f'N�7 ���;E�2�_O�sH��.�%'jw>p���.��{�s�{�,k^ũ�1�@���Opi�X��֠<}�����2���s��B�z���������k�Q�� ��R�ܙ{���Tg'��6�1x��"[��z�7�"�`.�5w���1Ο�irICت�E8}��uc|zu!�"�U+A<��[���L����/>@���D���늉�}<�(+��+hڷ ��A���T&i�{�;H��� ӑ糠u�3�}�#�Lʙ�t�]="��dp���X#Fv_d	v��ݟ��z������2¯�Eq[��H�7���x�~�+���F��� �|�W��<�WTqJV������s��g�9��:!��z��c-��p~�"���-lCD'�l��]h�C���@Ր�Png2��<A�nd軲� "-XƽW���|����y��P;C�W�wO�f<�vNx�+���O]��脭����)]�dյۙ���-#Gд�G�+i�1Q�h�Y�U�ʊ)�aT"U�@�'
�]\���p�h3��s���/���*]�	dng#e�+n�Ct�p�B��U?VM�6G�b;D��$�	H���<�V|� ��p`޴���N��]��T������뚋P�	��bKF(f�#��y�����i��<@��N>��1�4�G=�Ό.~�dp�^�Z����s�ף^�`�����N�O�:69:O2���-��bK���R�'Ay�@��/$�
{���C��H:]cV����&��W"�W2�����T��sP`o�7r����HT�{��R Y���ֳQZ��\g��m[��X!{U�_���dl�6���Q'������#]ռ��smHb6��2�v�<h_Х��������{�U0�ش0�h�aD�8�R��d���IxiC����;j��}�k�nbDRbqP~I�T��E�,�yfl�z��Og��~Po�_�������(��#;60zR�@����:����"�]�RL"r��Pm�J��H�KҔf�£k��0���<�$d���_��������ג�^�"�GM�)��U����Z�>R�핻-�,;#lT�ںs�z�ׄm���v��77����1Hܯ��~�h�~N~��w��C�Fe�H}@�ԌF��L_��,�+�?04Љ����S�]�2�%_�Fj�=ĤϦ��t�X{��!�G�4�x�A����iJ]"8��.A�[ʃ�C�8�/s�~�Zs�yᙉ�r��B��ſ�Ҹ�
����*B�\3��.FT�HJ���%���CK>U��C�ow�|\R�]J��f_�xjSj��EC}�����3��i�߹e���k0���d�z	v��ӻs�,8q���=o<������j̷ƈa�W�mP �AZ���o'�߅��Q��;�>�����)�. ?��0��!��2�5�� ���_60X�>ew������A�=����ȶ��� �.!��揭���@X�%楞+^� ��D�7-s����x�2VT�~ޓ����B����p����W�'�QUM���On?�%���C̜n߃+�M��-ū�	_vB�
��a�oS�J�g��L0�i϶�5q�7�(�e���H1{������C�w�Ŕ�����)���9�6)�C
[��ʘR:#��Oneu[βV�l ���b��Sz�ČBr�x��S1Q����h�DB����L�j(�T�D�gĄ��;��%0�!��?���[��D�{����4���|�u#@ng�B�P�a�SjҼb��!/�` ��U����PWg�>��4�g��.�����ꯩ���Xh,��,j1��P%Go8�Õ�(Sg���p��lJ�,{��BZ��ES���P	S��L�j��Η��J�R���v)z������Q5ǤТ$6���K��둂歕���je�Dω�I𹎕�A��fr�`r�g�G��IU?�#�q/��
l���q���$(��*' 
g��\��/B�vx6B��^�/�)�E͏g�Xy����i5�<Q��EX����ʡ����5("&�!���v/YZE=D�5%��I�ǟ���D�5��rHYK��R�I��=��6-���@f��K�4&����x�#؆62�Z�U9D=F�(Ǯ/zCk/�#�f/��\_�XIƛ35m�BD�����v�WE�?`��)��ZbVQ�c ��A����)ܐ��ׇ�[Y����� ��ժ(ή .����3�u��2+�-�ل�����7a�^of�F�YBI@�P��rN]���G��{o(�n��z�=�ɸ���r�?=ꮼ[!���Y�6ߡcZ�y��ď��Y�]��;�������x�zz��&�.t���
��]�3�z4���;��_��<8���kw���I!�Sk?����Sڿ�Fn�a�K�mR�Vr�)b���$۳���j:ş��/�y�hQf��޹I�O4M;���I�1�C��ö�IT4��4�e�Km�m?�KO(v�N_�y�����'3���;�4��U�tOvݍ����͚Jj��.u��n�x���ߵ�K`q���|��e��������x6��6.���ݚ��$�$9�N�	��[ٳ��<� �l��Q�)Cn��\�˃^��(���|i4y���9$�p@����;��jM`�����0�`�uq��5�;D��C]P��\=槴.2���(z�"����r�q��8g�~�ix	B�$#zz$#���&�bH�z��:l�ӓkz���4�FE��yL��QR�93��{���`בZ�LX��]�K!yܦܗ��^k2�����ح5�r/��l�D¸���.1�pz �Zw����~޶�U���C���9�h�Ѩ�61�ґm�-�R�	34��7�n�b�݌��LD[�b\��z��ª�=T0��@�`�ͮL	�z�J�j��;�U��,p��d�G�:�#;=�E*��;<�/]�J�H�Jj��KA�!p�\&��a>��:�>����I�UB�5�t�N9�YԠ-��`�5'DI
�٠�	�cgK1?�8��?m���>�0� �\F ����d��8#��A����C@qxk�5�(%��ѧ}��n&W!�H��\�$�7���h����S�
�+�t|j(���N��]`ս8n��N|�a�^9I�'�ux�7w�u�O/B;5
 %R��9��������� ��[���� �{�>��z�1ۯ�Y$�D[k�nY�R���Uj�H����Y�TV�m6�`x=�xY!�J����+��wN+���܂�ف���eG�
�W� �/��AgG���0V�$�%���q$��^��={p�24��XOt��^�!��f��H+� 0�R�C�Er���n�2������{���\v�ƭ?��s�������3U䧑xF��-)���B�0;�0T���V-!�Q��+�Sr�%��6������z���h�Z��$[r��\n6���#7q[tEQ(�rl��3v�������� ��%�-�K�"��9�կ&��������[_��a�Y�� esG�^�k��ٽ��'M1��#S�$�{ݝ�7|��ﴻ��k��X�v��@��e�e��P������Te�M$Bl�s.�M����J�!@�J���Mgh�tq0R�Nas��3�CLg�����8��C�>a�n\<'�j���p��W@����o.���_r"�Z�v�tg�����>
�k��kQ9Q�1�bN�$l���d՚��J�Ji�)@�fMX�:ȍh�X�$�������G��$	<;M43�u��,�*7(�S�q�#Dm{JM�8��J��6/Ui¶�WW�*`�i����}y1ҫ&����(�U�b�P5�~X�s�x�Ļ[U�4��8� �����6��(���D˸
��=�Z?2\���r���@ /e������J��H�'��2ͳ����-�[uz�h�	��T�D9��;�[���ّ K�P��v�����ơbp��� �D��Q���^�GB�l�N��,�ѧ<e��Q�ѧ���1(a �9�4%l�:>7_�
���q�qx�_�+|#�{X�p�B���e�K�B���ނKZ��.��N��4�����p�u�e�tF�Z1���ə��٩z�L=���^`�T%W#�B^T�"�N=����0$�6\���������Wr%�ɛ��r?��Ѳ�ۻ�Q[�Ig?���{m\]���`Nf���3Qr�:(�9��{A�J%Lр�7��x^��sC�c�^���w)b�	�"�!�����Cn��_+簶>k=�Y_�6����ِ���N�|�~
8�E��X�s6^��ЩM��iU:�!��h�
���0�`�4��Qi,Ѱ�7��A�A�^T��52L|8҂����
��bJ=*�U-c�H"bԐ���=�V����ʂ�DcSĴ�Wk�$ i�������'ɣmR�m��@T���A&�n^��l��Hr�V��>�IC�e��8�'M� a!�r*�BjZ��.7V��G\�ϯE���ZM��,�^9dX*���)/^s��|+�w����/��͋�L�U,���t*�`�T��\�R��N?Q��-��m׷*�j�Q����N�a�uu �_�|�6�^1�J�$7 &���\�'���"<x�v�GS���'u_���M���	�������YLM����YG=Ĵ�E�"K��u+���>�ŖZ{3��HH
�+O�A�����j.��E�Q�}��R���^;iԃ_%�Q?_��� �/� ������"h\C��{v_1��](��A�~��\\�w�$�����SO��e����5���Y�|�����`���`����_�j:��x�]����;�u=��:�*<̞٢`���p��\MqV����N�����ci�:ށ&h��wj:��+�4��8��s7g{0Rg�X�k�Eؘ9�*%���PR��yI�{�X�%".z�Cs�E�x"��VE��4�r��a��R��Y�m�G"�n���;"=��{�}8֐ ��.�Ϯ�ުx;�J��/���'�#81��Pz��q�1\udˉ�g���,g��A+2�)���W�T%�Z�_�3%��-�L�؆�z_��lp.�lx������W3%.�O�9}�xt����+�4T-�DYw���H=���:O(!E~�u[)U�������ڈV��m�+Z5�NdX��:�Hȹ`�������[0��A;(U��a�-���F�$��4�k"��i+o韖��v�	@������i��I#v�+����T�{�ܐzqV%����X@G(N�>	/�_���vb�
�+�'�Rl�������^B-�z���5�,�M��q��i0�mlf/��J ~��-:���S���rG4���nݫ�.FKFJ���{:���1��EC�S�f(��=��4�ޟ�oV�
��.};�!�H�֘��:�ޏ_ySՀap��W���-�OST��������JD )��-ء�ㅙk�nLhҍ)F��
ũ��@!@~�(E
u�y� &�����z��(��{�&�+ɛ�#�b����̓q`���#Sg�Z�m���!p�b��*v�24�6����̠%�g������~���	���o��S�NUJ,�)��Jሇ\u�|�~{p^�����gE�K$���S�P>�D�.���d�H�Z���ň��������].GF�LWז��� ���2>Φ�LVTYJ^�X�.	ߧ�|��ģ�g�@J���[D൨��~���"�<6�{��Q0EG���Kme�GD���ґ[�@wW>����BF8v�G
�:=L�7�;�Rb<&��?�b[�oaR�@w�U^?ә99�����'����)�K��j��2��f�m�Y���b��*5睧�^�
<����K�������h�IRd�+9WY	[���!��<:�<�� s GD�����Ij*3Q�c���B��/����W!��>��	���=�׭t����3�Х'��No��֊`1�旍���}�f֧��� �4��{�!˛^}��	���ӻ?R��x��&�I���7��:�E􉺨F���C���}8��?�c�-���`��e4/�)���p%�> g(�1�:��W�'�(l�������9�`v��8)PY���M�8��5=����ME���`�M������!d�p�I:��Mz�R�T7-\���?ה��ЧgĦ�PN��m��H��U�_S2��(�"ǿ�]8'�D��9����WsL�.�:����nG�,N�vmv4���v�vo�S��޿/�����D��m�{��K��/�^����#�(g]�J[�8��Q��}y��l#hR���L�h(_��X�e4S��}����I�-L�{Y���å����fz� ����|;�1\�w8M��"��pz�>�B^PY�zJ�����4n��1l�M.ڵS���R�Z\�O������[8[�m���X���Er	��/���<0�/��c�C:Y?�Y�#�4�%+֬F�{����d���Qָ䰜ݷ�V��;6��bb����W�|���	7b��,�q.ˈ�ݣ>��辶i��N�"5�_u�����|[[r�U����K���L����b��it�3^�]��FV�t�tC��)1O�Ҫ��T�v��<+&�
Եp(��Y��n%��M?˩�q���4K$������r#�4�e���<0�԰�m����;���:��_1��H>مW1M��u�W��t[�m	��j
l��Ice" =��͇��G����XM	�n�����7��5jn��%�.u���l�~(	�2X�QYZmz{�%Wmۉ$/ ��0�$sJl5D��䨰P( t�=�a=�Ĳ,�Fw���1-.��2���P��\c�7hm�]��ޅ�o���Ʀ��6y�=��l��F_n�it���Wj��]�?�id�<}�U���
`�馫�ϐkZVs过XtT���g���1���i����׳1G@�K#k.�����깩s�`	�2�3'D�8*�HqM٭+$F;�ۺy@wc�Q��Q�����uYN���=���C�$�ޗ�q�����qQ��������iBkuv�{|���	V��E �>J��#�W�n%�s#%�K��<$�vw'���ؼC8�?�f^�.�~Q1�(w��:!�.��oE4	�>��!��!D����PL1�"z&�^�W`��o<�c�$��x����D	+�|�#���q��4t������h�z���}Vfo�2��\1g��^�J�m{��:�ȅ �B&�{\�!Nh��!�˽/�0��Mœ.Ѱ�Rrqs:�<�ֹ)�T<��A�E_����/7�l�[�!R�(Dn���/���!4�h�;�:,��p��BM��5���~9�Vf�ՌI�G	~��:��-�n�v�{���V�����4Ր��9{K&���������L����@KxM@Z\"s�ve����������3х,^�y+�W��ǿ.>�E[�;�颙��1p`���ȥو�8�
c�pj�E₫F�E���ڧ��������`�sѥ��SsX�=W��+K�:�S����̰4�3���48���b�p��2�?���Wi���]�����~��zVwh��M��$�?��7/됗&w,�ϑ�*��g�)qf�'��I)��2��|��4��\"�s��PN�:����83�;'^�N�i���1�h�Gv<�(W�ؚ)�g��CdW+NвȕK���.Tө9��bP])�A�Y�ɷ�\�ڔ��v�1?�_�}��"�(�Y~�~>$!Q|�� ��e`�r��j�]*5��)Bb7J��&m[�3�] ���D4�@w�@��9�ė�ާ���ԚXr<\s�a�����m6Ʀ�C|��H��>�v�`�l�]4 �����F@��G��h�S��q���^,���P�<]�=Cp����F(þ^��2d��",ى^Aq�ԩw|�р]?>��&�=�t�<�i���;��F��SH��<�|�9����8��P�
P���ttZ:�+�|�>��$�9�G���d%��Q^�Q{�w4��M"�MTw���m��Յ.��.����Wl��DҎS��l��B�X����rT-(�8S��1T�'�?���`²�-�^������D�U#�OpNXD\'ծ��$�!�$�u(���)���pZ&,���vB�#��C�R�ɋY��fV(ƙ��W���rI��e���w�����Bܝ!��{g�T\�؜�Q��t-:(�0�gT�4��7�1txq��gXN���,9έ�t��c�l�ԅ�\*����ȧ{A#��xiK\sFU[,�!���vR\�'��?�M�П ��ַA!��U��mN�oK�;Ζx�w~���Z��(`A��"+6�$v��XF�U�����!���б?��|s�dM���h셵�.j b;(��fb<�Q��e��=��R�00S��C8L�ւ��#�Sv����2���=u��N��d P/��>��egÑ7W�*�nL�T�$Y��Y�ȍ�Z'$�%��*:���M�b�]/r����PJ�᜶�G�y�
�� �kVcf7B��A9���V���~�C����>3�zh��r��x��p���� ������:$���[��D��[�?7�j��B�ɠy���oԳ�\+� ����L㭆'j^�!]��G4�a�"{�Ҡ ��Y��DW3E��9��}��.3�'�o]��B��m�X	�#�I]M����h�?��� �KdϏ�jw�7�9�B����wC�1Z�sU�����'�
}; .���|}M�)�@h�r}����I�& ,qK�X�pPw������F�D@H��(X��"��Sw��������u�e�r G��G���;q�BkG��+���$�7�gUҀSY�/s������Gj���o)�2J7�C�I�l�Ǒ��s�u�L�^j�!�9���n��K��hH1�\���xX$킡�`c�K�c]��"�u�g*C��cp�M�)|�`�}���c�,��k�  ^0%�U�y� �����'����g�    YZ