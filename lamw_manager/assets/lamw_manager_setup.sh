#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3443862606"
MD5="fe5a973bd56648beea9838d60f2d1e5d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22564"
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
	echo Date of packaging: Sat Jul 17 17:30:26 -03 2021
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
�7zXZ  �ִF !   �X���W�] �}��1Dd]����P�t�FЯRN�b�;ß Ɛ^�e�=��ѠQc��i��F�3��R-��0�6h�hu�^A�O��t^p�3�=�*��UtϨ�_�.���5���k���9����wT1�uA���p:�0;��պT���]F��mt�,ڀ��	��f'#1{�_@{�n(�y�.;������K��ь6|�����NM�����L���4ܢ�q�:����Mz�]R�w�ZX�!g��	�A������k�<͸��`C~&r��8���pP)(�K���یyLR8�P���P��$���KR��՜ǐ@��܌��ő�6ǰ<��|Ed^&迖`U��X/�.�B�#�J�E���PJ4��R�����w��i$�7<+q�)���l���9�����턱�_2R,ք�#hZ10�~2L6RM���'=����n���>�a;����^#[��.e��w�#א~� �j���S	��DCp8�bx�*�ksx�΢�uW�M�>!�Qk��֣����_
��~k����M�Q�/x�Uxֶ:-=>��w�%���7��"�����#��Ĺ�2��0���	���苽����� |o���|���������ͺP׸����A=U���,�	������?!20�7�*1��ayc6�g�XT�M����!Q���4l[y�LPVhd��UK�|(?�������^��ފ`�g�����+OC!�m�
���%N�64ܻ��S����F��?[�R�� �!N��cC�����0n�V���F&�S��N��2�Ղ yX!9�_�O���5��>f��h $gY��c�`�Y--�^��N������諸xo��2������Wo�azoi�skj_���*�a�*I�>�k!!{N�9^��$��ηwF���L9B<�)�آ{���q���STki���k�v^�,nץ�|,�o��12�b@k'���&��Z�ۜ��2�yG��I�����8k�G�x'�s���>yn�X���a��x������	�'*�Ό�r�P��`�)E�����#tlI�$�������m�x��rA#��I8G���~Xi�m*E|�nE�=g�~>m�B�v.��BѼ���?m?�6CJps������u���Y>������b�#��N+��EL��C�.�N�e6�
��km�ϵ2�,}*;@�r
��1���[i���fhڪ�n���O�U�h�e��w� u�pP�ш
6��]���H�/W�Nc��t���eɂ�8��!R*d�y�T7��F�{��:ug[�)����o贷� �F!Q���%�~���׭Y� �.w��Α��Ե��82Bg0�>������ԧ��\�)?�r�)�_qt'ߎ��}�/+}q���3��*|
�L�B�T_n/��r ���W�/�V�xa*��v������@�x')q\���Y�hOI %T�@�c�ϪN�����M�����+�����*:9(���}h������#��9� �,����_��ZZ႑w��1�W�3��냿�7,��5]�gV�Ǔ�LN�H�	;��Or!n�7�� 7��� ��w���Y���x�|�?d��XkI����z�~�ڀOZ��&(ߔ�2&H��H@8�{��|� 7��;�:�1��p#x5��.��\5����a�&
�`��3�����6�f���@6dx�$��u>�YĪ!V�����&��'�m�D���������`�ہo�"3xAӐ�Z��йW�_%��^���c�b��aj8�W���6) i*n���\<����	V�x�W�&��V����N%u�Ҹ�E�|��Y��j &M�H�Φ��WD�3��U0VJ|qJ>�٦ܔ�D�_-���'L��.��N��}��@�!r>_q�� �x4l�6^u-�Ny aP?֦�H�q�N��z;�hl��o���P$�.j^��8q
�O� ��߭���.T	��-�T�Y�
>] (v#e.���z���EZ(��k�D��K���l�߾�': *�8�@wA47��%#{�s��+���2�V�v�j�t{W��mX�d�ԱqԿa�t�wA˯E�*����\'�hylK��nq	E�5]U�kPK"����\GqC�4P҂;�����}$���S��F�6�Ӿ{�<��<��q�?Y��S�G�wK�>����9E �#�Y~B���?b=p�
U�<6�Bb$SToȕ�>;�o��ȳ�O�zD��h�C�QЎ�c�x��q?&֝��f�[��Fs��h$3�T�@+9�6b�|z2i�}g�BD3&L�¸��7��y"62\[^�K��C�0�	�/��d]C��\k���a�S�v����r��vS�.�E0�ut�	I"��y���[Ő=?���J�P��G�ZKݜ(&^Ҹ�YVN�x��I��X�8�|\�5�w��bt_��}��AlOe<@@i/n�X�*�`�-��݄�]9�dM�cS�4^�2[�^Vg�Yk�hn�y�%���.j�u2�B�|Ɛ����� �T��l;��B$��7
��}�˽$�B�F��;��f����Q�G�:=�.U����.�g�܇&>m�$ń}�ԠD?��z�SV��9��::����?M���\�yҊu+c�/ZΓ.|=L*Fǯp�m�#ﮯ� M�z�Z��ވ��S`�ԄS�|���`�����A�!/j�`xB��=<D�D|=T��2��v}	�q�s3�7Ol��ݐ�E��@3�.A�qJS����	��>���_��=���8#��"����Y2d>������Hw�Q����\Y�<�S��e�?ڮuS����KA�Qy�k蓮~$?R�7�7��=>xg�C�|�7�۟������
�p�u������O=��uy��U<g�}n�~8�Ԇp��Yc�'�Sq����Ej,+I]c�P|��E��O��3�^D����c=-�"Lё֫㝭�\KЄ�����ƦyW@����@��u3uI��<��L:y;c��= z�q��'��E�UF�e�&S��ѭ^�f�*@��(��K�;�h��w�����O-t�#��X}'۟��4�zR	%/���t���{_�r�[��Q�oE��K�4K����e��/�#��0��Z�۳�����:�t?s�K��^��2�RXm����n�>D$���	{Qe��h�W=� � !��{Bw��=��l&��e��?L?)|��n:���S`jn�jt�l�K����G��7�K�*��4
���#i��>+U��>��V�Cq��Jb�It��-p퐔��tK����DRo�H����)��x��a����lg�6-@�՝s�A�$�@��[D>����8�X���lH�o[!%IP4�������k��KǅSi�j:��x�e����jS��~�v�-��	�S5�2\�.�2�_6aV�	���[��:�σ����-M����)m��0��K'3hf�� A+�O�H�����2���k(�����0J�(�sac��-Q��f�"�h���XW���Dh8��qr��V��+�#����Rx1lsHQ���%"�����H�-�>����A��[0[������*�p����AfW�ؔ�sP!%O��B��]'�oc�i�$F�� f}��v�*��4b�C߇fM+M,b��)�/Ã���P(��^sk�3n��r2r�P�-r�������w�{B@a��D�{L�D�1����u��@-��H����F�F�!�׶���O�ohhJ��S��=�d}MN�
�愽���f]���?�|i�%�-G ��@`�7iYh:]8�B�Sa:$�g=T`����Ά�eo�-���cR,��'Q�p��V���p�dd�ΦGu|Fb���I����f-�	�;m��}�|���ÄE͏Ot�,���.�
C���%Fӏٛx��(<�b�8����"�*%�뾴J8@�_� $\�!O]Z7�l|��I��u����v���Λx��T�/� �E3���5���{�]�/%�����mF��q�%��:�$ϱ�PO�\p;�����`iD��8���:Y��
EU�.n���*$!Rd�S��.�3z��kzS��,��!��ff�Ul���3d��[K@���DIֻ���j1�x�t�a�M�.7�C�c����zv|���4w�'_	3P�ꌞ8�fX��kD-X��-$%����1���D4_9�54��5����Q�/� F	�zV�93Șh^3ю-ڇw��}D��]ⓡ���8ɱ�6�y��i�j���.˝��>u���6?���W�/�)����M~�YRVJ�dUPf�I l\�p'3������ʻ?�Gjע;P�hMț*y3{_VK]��`��	�3J4N��:@X'Ec�?DQ��o.\�e�%j ���QE�"���^��k0��}�,�z���Kr�Xm�l��Q=����SF|�G$ߕ�-d��s�.��y�>x�r��KM[BB�C=n{�տ�o��/��e�!5F	��եk2��F!���g��4T��#���s�FRu3��D�iz˭����'T�����7���D3v�[V����ڛ1��4r�Z�UL�����s�_�Go|���:�Zg9�}� zN}��h�Q�� �}Y����9�"�S_W�%;���7��H�׊�lRA���d<!�BZU��v麘ri����5�����b2�g�+�786A9<������[����rV���(��HY�Y���-�Z�v�S�x(Ў���|���k:�O�ɀ�iy���Zn�'�@���.���5��ce��.4�	F�	t�g��T:�^�KZ�*}�9Tz�'�E#��I+fޏD�*Z�eO0�9q��^:����	b�T�Svj!Rjm���!��t�kP�$�;��I���q���k�>���x��7���9�����nr4
K���A�`������pK����!����nOP?�{����3��˵ݗ�c�
j3�V�����OOen�����P�����y� =MJP�Z��Ϸ�X�x�^'>�"p�U��i;�5��%�w�3�}{s�"K�e�OhO���
[����1��b��Ā� #x2�O֗�.���v]u������6���^����%AB}�4>IjkI@���$��5��0+��TRE�'=AL���1=�v�/ٱ�9O��v���nl2م�ؽ������8��n=������M	*$�My�A�t�����s5��/Pq�Q���A�L������Ҫ����r��0�K�	^��xY�-��&�>>������^"����7�i!z
 ��9��$��$�o5�e�TMd�ܣ�| 2���c��
�$vR�x!%�-�a��d�����`���o���}EI���u��7��ݘ�uF0��ǹ�Jgb���8���D�+�Z���tJ�=�G����*	A�4k,|�YʟO����P8@����M����X*/s�k���s�R�t�]_Mt�7_|if��]p�zY��VK����B�($[N�u6���w�8�Gq�U4'j�#v�G�8n�o�k�@�^���v�QE=\|�ӎ����3��Զ��2���+�>3����xPUi�Q��ۼ\vdu��-��O�DG`jGeVU=����]]���1��K��q���J1`i#�Wۄ�H���C�(�zk�ݩ�Ĕ$�tD�"3��P��Rrb��w4.,����*;�m�X�?�P�P���HR ��{V��G�I��۾T]��^�C���-+��a��ǹ��H���P��J�߸0ÀI	�[���g���]T�Èo�>��{#��8�:��}.(��r�В2��tad��J��`�J��['+M��O�)@�?m#ld���4���~��=�T��6�m�fv�i�Q� "�U~�?pNH�5�����G\ݿ5�Z�G�g�$��-�187:o�B�Q�B-�3Nb_h��	���k޺vm�uX2O�dO)t����a�����I����cvd���>��Q���
�@��ȟQd��r���<�"��.���]�L�V;�W�z��v��GpG��h�(�r#P��R h�����mӨ��p��y�-a��,{�_=5��y�$!gV�5#�N4_mk6Y�PTP.g}H�����4|�!��|ZzD6n�1�$�V�1���]ZN� Y�0:�� �k��� ������p	ճ�-��:�����]�k�OQȸ�V"�[��K���Qc�嶹��$�	�7Q�-����.s�)G��N�f�'�nD����Q��Q��j׼����:��M2'�	3������ihS�s��p �I�m�(0K,&���l�C�fЎQ�Cq~H��l�S�����(�\�%MF�='�U(c��_t1�(3\=j?&tk�a���G�	����aO���
�p�����C�呓���a�98�`�,�C���|�P��:��/�� �d0u|K���+�}@-g?$�OǁI+�O��9��h�y�`�Ô�1����P�U�s#F��&���<aiE�2O��б��KY�nR�&vch,�!��BC�j
�.yw������]����0L��A��Oh��A�T�9P�㱵����1t�P]m�N٢�݋���n��J��-��1�
��{�[�zt��J�f��7P���@6�g�
�v�Vѹ:���Z��!�y��Z��j*�A؍J��⟆�"g�{pӸ$De@�-:��l9�\{N�5*z�����`�O�Ɲ��mw�=ߝ)����M_�������p}Ň�$����ST~I��uZ�T\��L��#�Ku�M,�1_m#�0|B��� h�!�5q4cB��+�S�ju4ߌ���B�������L�,��np�̗�����T �(�1��@�/�~A\ B�� "���/c�@��2n:��xI�c��R�����3�Q��@��q��+a��Ocf�Ê�`)����3�$t 5���r�˕��Z��&�|��m'k��6���4�^i�� B������;�fw2�Y�e�4���.���H�����տP'>��0�I\�w���H�n�>���'84��Ů#�Ʒ�0�҇j|��ܖ%��<����O��[�٫-�9�T$��5�-ur���i�(�?���SĽT���%ȡ�3�2h�C�k�4656{*�5�ʬ˭��?����!7(Q�$~c[��C�j�Gj~"�.����w��%���z��G�Hκ��F���D�X�ӑ�Ʊ&����2�W]4����P����x��D��h�J���2!IP^�����2��|{9����@H���Tͽ���g�q}\cU^O�F9��r���6�-�v�M�Tm7�9����߻#b��)��=187f�%Bi̧�inU�!� � �]�jN>�b��������[:5����ȹ��]�-���{悿���\|?*&i1�8hh�z�VU:�2�}����Ott����1Ĉ�l��h�N�ͻ;�5W���h`=h��u{�Y�t$9v{�j�#j�exO�<�\u(U%]j\c�NC��2Q]bN����f}�޸5ơ�����$�z�Py]{�������L�M"ߒ4��Bw�vE̅��x�Ƴ �/� f2f�(]e׋�-�K�}Ε5�}�X�G$����t<��,���p�)(L��Y@�r+%�n74��m��$���_� N&� ��xH��װT3~��l�8)�s�MU/���H�������z'�|�M6<6��̛�@��h�Z��v����O&f���LY��ͺ�o�5�opt��Rf̬2;s��pu���|S�s��x��j'Ҹ٣�����$�3H���*h�:l��TZw��j�M�]�Doy��fz���8N(&�/ǖ�7�k1����_W�g��V����
�G�.C�Lŷm����8�3�ȃ��1���I���p��U�2 zH������f�;��eon/��zMK$S�;=az����B�T5U��f��%���I�.�Q�w�����3��Lq�/�h�&ũV�O����E�g��K��������hA��~�Jh�W�V�}�i�v3�<yOͿe���{�|}9��:��b�#R ��9P�l�@,3Iv�Б����G���4d�%�^�2��gA~o�?�^Z$�fX�&��Dfտ�!:�Z��¦���_b/j�/;�MP�}��E�?�a����������ɮ^���[z��s����HV�8�+�kTL���wB��i���4W����<X�ѿ�����W9�D'�7R�
�w�H� ֍�Zn]v? F����t�!�=wٖ9�
�}�7���X��f�I�����-��*��j�J�]
T����s��e�ì��xT8�8ڵ���;~��5BZN�l)�t̒�)����`Uj���wB�g����'��@
N��� o�Is:�ڰ��j���S(.wc�V�
W��PDT ����~����7�`��ۡCsj�G�����
�saa�x,�\�"�L4��?()�We�hw6�����W��~�2�
�B���]J.Z�U�`-bT���U�n��y�,h�
*�L�;b�l.\�\�^* ylے��T3W�\�'s�?�
�*m��g������¥��)3����ấP~�SK.���n��E���ү֍&��P0��I�+m0s[l�� P���懫���s�t��8���6}�&�1J��u�R��uv�n��Z[��	�M,f=�ʊd��c���N���Iǫ� !�X�Q����X7չ/��+���X�1�`#�5�)4�o�d
x��F�N�d[jP<n�Ci� x|�>�m��4P���)�:=/y
U�݋j4Xf@
14�>�Z��U�&\[�<�<��1_��y/8 `�[����1�����r~�E@b��u��Dm���	]��q��-ԃ���&ԣ;��w��=�,ګH�c+L��)�p�$p�Q};s��ݨ@�KeϬ����wq
dv_�M�ݍ�Yƞ-��Qj�)}w6�$�ـ%��V-eo��;<;	3C�}��&B��a��ۗP0ǌ�5!���C��1;sH�}xEh���j����`TQed�����*\����yҹ�Q�>I�\d[aj�E#��ѭy~3t;�# S�QC{5v�t\pQ�]���4�M<�~f��K�ʊ27�+�
G�d[e��!�
F�G���\��s)���uj���Z�Ȟe�wvx������9��A����(�$�c��j?��k�:CvSe�:�������ω!��W�.�g�#�Ѽ�c��a���E�F��:G�O�w5���tN�kU���	�%k��F��T+U#��(����^��߸0�ޯ�\��S���k ȭj^���7�s��R�V�0m����a��sv������hГ��v�L[|$�3$ϯ�S,BH��ϗ6�UͰ^v��%䃸'�&�������Fd�pDW��#�q?��� }?��ܑ�P�d�[{��A��v����2�x��Ҝ���-=��pk<���t�n�����b���|�9�������4ǐ�,��
MR�2��	��0���1'����B]{}�/s���?�SbIT�2�ӹ�/^`=,xWR`�VU5|W���i�����{S��>~�ӻm�Zm�V�圭�op��)����7s0��V�0Ao�@������<k$/ʝ���~�C�i�^=+�d��n���V2��+0*�	���4�z�5̞��n^Z�.�S��U�֟8A`-%ذ�l�8�g+M�'��Զ�u�p"��ija��P� ������Dm� l3"K�܃��O�$t`���SƦ�P��zVr�\E���uU����v��[�W{���^��S$����ܙ�ӱ�{�����N��?]*�� ]�,j�,���I.����R��{���+���z�|�P^~�+e/��ԫ�	i�w���_�D���*�����&��F�|:ɜ]�����	)u�d/ͩ_`�4�UQ�Yj�,��w>򆫾
���Y\On��Y���-$ӽ��V�;�0��+����ai���#��;�9P1 ��pۀUm�a#�|i]��Q`���<��Y-`��y�]3xo��$]�q��,�~:c=OW9��ࠩ�D��QJ!f��6I�}�r;;i��O�x�e׸�?��w�R�BHe0]q`��u�	��맖��؞�
�Ƒؘ*X<���7��Dְi�������zx� �!s꺰��ڪ�K+2ㆴ�^�Ǌ� ��DXe�A�e�@ɱ��|����K�C�!��Z�qs�q0�.�R?A�
�ߞ����a���)3�[�Or��	,je��f��tK���&�*���Y�Tv�8���P����4�NbƸ��$���e���R�m��^��i�!Y����Ujk�dV�n�h�r.:[�5(K�P�������� #4��R�rq <�>q�W�.�!ďfRt}T��Irl���'d,&M�o��hB�T�Բ�}K�m�J^�,���7��j:��s'��??��v�`XP�� ��Ĳ<���`�M��́�c;H8��%d}Z8����*��EP�4��@w�`��*N�!��'�V��u�_j;��3�Ǎ"1������M��n�i\&��-��|A�`�T�7F!%��,���@�P��;7p�f�Hz>?��*�<��?Ks}�ı�n�\B3�dX%Ө}��Mt�i{�cn��u7ҡ�?|�H�EP���W��qS��ȕ^%	^C�v4$B����w��!����K���"tS����֞Y��7�G�����8���:�k�S�lj �č�[���&r<�ϙ�O����*.S��]Vܻ&��R�w�F_,������;�H��d�m8�-	�Z�k�LG�������ӑ.r(��!率��1�����=ɱ'�)��a,��\�����؟t��=��i�0(��4'��Q.��/	�Y�}�$��ȟ���N��8{���I�,[�
��+�S�>���UP���_v
},�wp��K����^9#]��"�X@�FU�-d�-���	�dYX����R=9�rr�t�l��<�=��r�L^��p�}��>��:���Ń�s<`6<A�5��B�)�faH�J`�0�i�����,�Of��z���Z\i
�z[J��.����!ʣѱ�5��win�Ж��/
d�3���Q��zk�r�k�^;�WS��u�55n��!���7i�O��)0�{�C���s,1A�l���WfP, ;*0,�?d��0>p����^���!MPA�������C��Ζ�1�p�y&�9��O1���$^��x��펓�L�{��)d�_Yތ^ : �2�=���"�R�P}3���ʢ i����B�խs0�>��l[�&��.�N�@1	��M
�0���\i��ýkJ�cE�\v��0YM#�lh-��-���ҋ�2Mp�;�S�CX2��R,���Ƚx��8<.R�,.�r:r�4���� $�.Q�I�a/5�M4�)��YtV����7���4��`�t��?n���}G�����A��̜�ğٳ�Gؔ|��I:�:���|��L�c�3G>e�x,���0i��M�'jE��Ըi��h�RvX(���Z_��?���u�5y�O/���� ��9�st���$n�b�ѹ8�����WS���i{He"�7}���.�+=I	¤7d,�$����/�s
N'��h�AcI��N ���1���	�1�����2}u��g���w!��}��Bb��8�Fy6�*���N�	{	plm -�b�ڤ�ec�	��_�����	52��z�|�j�wsǸ�Jnj�]��z�.�ŘM�D�'HĤ~!�h��X)�7D��5�h\=��H�̠��.%Y�LB���Y�������:1u����Sg�~Y1�e�CFm��x{�G�S���t₃�B������̸�.��+^��,�y]�R��ܷ!�#��v���
�-��D$7�h�`F1-�*F�d�U���@��X�:+��?F�/�":A�E�2�m�M��U���F����f'|��VZ�ɀ�9�&wD}Z�J�z�I�嗜?�,6C��5*C:sk�U�U1�8�X�����	��JM�l���G斔���_v��E��tt:c�
Y����^Fg0i����cs`�"��H�"!����삀~R�Q��L<O�g��pqd�"��B�l�۽��v�v�kX�����R�v�ra����*��2���0�e��e�������_�3((:�WBَ�bA<��,p@g ���?-9z��fȆ���DQ��p3E���*�9���y�F����W�90H�@���O��\��G2,���6�����_`���Q�$U�.�O��<l	+%�߀/�F��ֳe�aǝ��&Ԥ����x�V*�w��h~�E���:�zIX��ob0��Y]��)�z���4�~�-Qs:>e,���#� X&50��(�����w$���%aE�>��@9�ԿfB_� ��3�.�ԡ4ǢU���LV�N\Z�����ת���F����mJ����K���,��⃜���Lܻp��3�V��_]0+�Z�yH���H�W���[��^!�R�!����)�uЧ���N^$��{oF�VNzP+&����&$|�裥���X&���Np������6���Fq9�� ^S���a�����z��ôx_�氂ͦr3>�?��5�U���TY�i�_M��x�o7ls��Ҿ�	���v	':��S2�]���K=�y�S2�޸K!k�a�����\�e�a�i�0Ӥ4�>��A1�,V#����C.5�F���H�ho��sJq��Gc����VV��e��5��� �y���`.�PΗ,l��랬�x��f��SѦ���@51+���!�-�ܗj7Ǚh�<HI`��� � $����)��:-o��ݙt����=E���
�v�[djN���Wcuq�M��dX���+���[��.�;�Q������ϲ{�ȴ����1����l9�\�����:��m.�垊�����7�I�pp����x4�p|��~�[V�S��X�W8ԅ�&3�v�?D8��䆈�r���w���SR�ba����Z�o2��i{�t��\�޵���F(ݷ<j:{>G��}T������|����ח���Dq�U�R��=�J����3*ʥ)8�N��ۼM$��NKwNL�Y��a6��|s��}wl���ָ�|D� �:���o�n�_�}=(KCv�������Mi#|Kk�C&�*>>�C��0o�.M��¨��]!{Z���g���.Vb`7��L���<+��5����Ce��L5	CY1�P��T��S͡ɘ�$��o�@S���79�֫I����B�6�>'���|�Ym)j��5u}znk�7�3�T�^~]����#��*�Rr����q���H����	�%7�ֻ���M�u	 w<ޗ>.��a��ƹ� tF'��~�vN�\,&k
F[�����i�g��瞉�H�}t�!TF�7$����NP���il�320����[����c���C��$��g�	KM*�?� ��u5��n�WH�×�(Q5�Yǐ�1r� �����s����fw	�dX��wuG�[���9�'�.6-tAD��	R�EJ�����"bڇM$"ع��ȷ�'�v
9��q1Rr2�P��N<�a���ZGߓR�*���"d�\5���.�*�\����n�\��M��o>����xbe��������,!�#�q���K�=��q�|π�P0�m��J�'��y��,$����0��oy09�I{=�I39��}y�lw"���d��rhvIr�3L(90����ga�V�c�,i<�A�Oo��Wh��Ym�Ҝ�`��ަz���n1I $���y��GTQ<���#��>,I�}x��T�uA�-� ��UD����'$C2���L�=?T������|���;��BPDjH&bf�2�5>?ђ5��ݬ�n�ۉ( 8s4c��W���ٕ�N��e�sܭ�g�j�O�p���Tw=5��Ӈ��]�Sm��,�i��
	����~���qra�-�}���°O[>l����O�}��S��Y�'�G~W�s���_��M���!�uJ7�ؾ.�Cx�&��L�������5}��zO;ݓ�y	���m�k���y�3���G!�� ����>�2�&tUZ~�s�sO�ܔ�<��="�hu& �\ob,��_�����Tѝ+�Y	+ ��j�]�
od�9t.2�T:��8�..*3�t�a��/��d2O���(JhqS�]ӷ�:�4A�:q��7���nO����͟qO�Z�����Ÿd��������g��>=|��~�%�~�f��\��)�b�h&?���_H[��D�X���}�f���iHۉ����q@�n��ϛ�IWP�Eho>��{�1�x��C�,���D�l�É�S��/{���V���4L58�B�zm��m�kƣ�}���zWJ��E����˯�lW$�&>RO�-��q���N���Hv��E��{ O��dٿ"@Sۭ͇���pPu' !��Iۭ
��g�埛�$UE��L��y�kn�f�ip�����Wi��^4
�m�Y���M=��8�/F0�a%�)��}
�43z=@��wZ�E�A����[�̗�q���("��NNR��764��I���HF|�S�́�(ώDO�4�1���9���|T�8u�1��B�Z�� Z�X-��F�;3�� �M>DqR��2�Mnb�3Z�Bmp��N��1B�b���*j;W�������'���(\i��}���?�����ǚ_��� c��*.��QR�(v�r�/?����m�%��(ƣV�����r�ѷ�� ~�
��^�\M3��\�.
�U|�2�1H+�g�Y�:��`���h���^���&V="�jV1�	��E�3�t���`o��|H��8b���>��N�m��,-�90 �~M���%M��p�0r#:[�|\�W?jM�	 �׽sX�rY̜7μ� �pu�Ru5����	M���+�be-D�������W��G0��69'hV��ށ��*:�2|��F7访y����Cߩd�~�P2��h;�>��T9@�8^�
~'�P�1Ge2}�����g����j���^����S9�o����rB3�S1Z�#�{�h�JV6�wV5�.!���K���������I�Aj*��Z@H��Euc�"�=B��_Uv�5�������D��&�R��>�R�:Cm�3��q%���2r�B,qyG(�$"��W?Y%� ���-���5��>���ݛY��gD^��yРQ�k!V!ί$��ì�ɾ6M��o�_,��:��M����z��yZM��5.�����0O�eQUTc	��9��jwe_/B�l3��'���\����J��t����GDbS-�铸e���2��p��o�C��)%�apn�$����z����vOT	� �%$ Q��Y��o?�4���2W��p�]���
_���
V��-2��r��uT�emI���:I'��+�{�/�%~4XVŁ��@AΛx('U�X(�?Nr\n�7�ԕ�_&1c�O�j�8CdBeV���An"�(�Y���ȧq�&��㦊���lj��$�xa�K:{;4{˴��p�����%���9�f"׊��F.�#���]>ȧ.�jS��4�˾�@�'L_6��̻
�A��@��n��� �9
7������W����Ǚ��Y�a�g]p�=�&�W���1ԴO�*�b=�]f��6�K���0��&C�H�$6f��)��u4+�*G-��J�>���Bl����ex&�z����)s�=�Q���a����L-A*���}s��l��䆤JZ��<
�8��+��)�h:z������N�DA=���@;*�Q�7Df�&��EH��|��0����0)��:�#����#������|yd;�S�yjF���/¼hda����^]���������l~L�NAr����T���gcD'p�-�h2�l�?@��-3$'������&~���Sg̯�^d�)E������L7O%�� :R+��s�W�V��Vp��O�!\�r'N���L�{%�ƽ?�־����,+�M�0�kz��|�܉�[<�'�hv@����;�EK@�6�Z`��m)r��F/��&����l�������)��9��9r)�8n����#،�x�6�������M'��,���緻k"��\��J���L���Z=_Z�,+�R#��w�9�悔s2O��C�R��}�{Z�E�2F�Zq�Jme;������E�Y!�����d���Y�	4 �����m��[�R��
iN2S���}�_,mm�`-X���M��D$��gq+�k܁So�#|y���\]Pw� �L�Q��/1,�}
�4wm�la�V���#udl[��[崉�����/?��$��n���3�jw����J(�y��Q(�Je)�WEK����Ռ�� �Le/���p�2% z���Lj�I�b	.�<�2���-[6���l\wd�[�Hs�#P�B0�m�	�D�E��Ay�0�)��ٴ��_Tr��V�:��QYІz�<!����nP���]�ݕ��F��~˜3e� ��ad�0�Mؤ莗|���&�IpI������i�LgAk�0Qd����b?'ե��=HC�m~*��%�����d�FA@�N�	s�6<qw�M�\m(Q���12��y:���8�'I*�����NX�!��; p>MU�~���<r�~����������`��l�FB�B�p�3���hX���o�ח�����R*}di_�3�HG�W���)��ӿ�{��yTR�*��Λ�?&T��%��^Hw ��}ꁛ� �����2��BL��U��#d*Ls��E�T.pU&���'mlW�3pbHؓ��r@�!��}\f�|��)�O��;qTV�+�k �0�Z�g��F�V��|6J��h�{�J١!��D����T>u R� '`�� #���;�
H�=����+���6qԀ�g'bV�w��Y���۽/&�Qb&��˱�����#�ka���4��$�e�I���P�B�x�'�n�Z�cal�B��{���0U�����N�SG�ꝡ�,�ip�������(������b�G0��ނ��R�W�e=g��ו���Z����9~q=��,�}��Pϐ2Sp�"Ԝ7v��>���!��
s�&U%%.���ΐ��Z��r�&���W���Z,LX24sq�Y�B���=�����ee�h�n���{��÷�8�8���Ya�n����:�f����%����U?�AɾFK��c��z���W�A�Y�=�p��jsp|5��}G����`��f�����~vL'�g��ǂt+v�t��0�)��3+����^��:>�qM��h��R(Z.C&`��JJx}H�G�'�ñ0Cᐜ����]k]%�v�������HR�jm
��ڍ�3'O�a��\a��⟾�+��4�}-gQ|��x&���`�tFR�ju�]ͣKT��m]:��5@��&�V��q��Ap��YÈ Z:�؛]�ƅ��%Dg�_0�ܛ��#�Y��b3�+S�<�:��l[k�b�׋�3���8��vQVܨ����Iظ��������z�����w�r��u��Έ�>Ys�S�V�w��?��T\֯�+�bQmc��b���b�LY	|o!��/�m -�pΗik�����}�+J�r
�e��/������@y�}�BH�/}�ő�:e����V4*I ��3�{�YՀ��b���O����鉛$�����h����z�%���[����ޝ0�e� @-s��+�\��˿Nc��y� #QtY�.��q�8m��ہ�B�>1�"�ӣ_���}�����C7�X��Ǿ����[80,�3������Is�0�,�	�)p��l��PV3��%m���۽�� m����mB�O0�J�GaR����G�m��#u#L,t��i�G2���&f��tc6x+'y*���ƅ����8��Ƴ]_����	"�3�:��W>�9��+3~��Mi��}�3����G���"S]�q�qm�_C� 2� %����.~�>�/(�Y��΂\M'�V\]��5(�_%k��֥���W���vK�)��M��Y�Ď��Y�d�LP@TD��[ �un�[Rt��xp����{5�c���ח��Ȋ�m [/��@�F���r}�g���(��&�f�q���AKU�q�{:	Y2��dN�������z�:y�GY���u�3�����I9�ɕ���q/<јq_�Y)$�����L`��
�k�O��K��qW��,����\aX�!����݄�#����y�$P�u��3�O^�� q��u2-�nq -�.��up	�y���9?�
T�$'ͥ���Y��Z�Ơp���J��O�I���@�;�M?�oBfՉ��C,k��ڊ��H����{�7[:�TU2i�ɠ�, �ĢcZ�S��}�N�W�y1��4[.EC�Πn Q�em5$��b9���]�&{�B��k��=��8����A����\֠�,���,��Pquȁr�)��lFh�ҨuT۞�����O�`��^��6#�+�-�¤�`��%֋/x�#�c�pe�t�#�5p'�����i�Y�(Q{"0�yM���B>����P����(�VL@��C�n�3�.�_�&u�10ق^���K�iZ
ZS���A���
��}��$�_"w!�W�]�.��p\�4�;�:�E�N�u�"M����vd�2�����@
u�ZՓ��s�\�Ƈ��8r~�ViެW��|���V���1��hCx����a�p�%٬ОH�s�Vn�A��d���]��-����� ���))�
���!O���L���B[Jv}�n�G�t� �<�+�lZA&�\�H�I���%귈�OY�?f�ʁi������5�僑�`���f�|�a�Zf�ܦ�u��${���Ri
�DT�ɱ*ȴ|����	pW��kB�'}V���b�:���X�FN��S��h� [�1yK��h�r���~�+h���C��sB?�O���gH�@&R� 4��/�~Ǵú%�m���c���{>}2r�^n��V����x<����i�r#=��!�ԩQ>:�jY_��;^,��O�&<u!�������~tș�!��+���W���?:�}k%�}���D�Ё��`�,�K�v���=��Z���W|ХjE����ڸ�C��@w ���Z\�p�ֳ�e@}�)//�0e_���4zn��٦�X��=��p���_Z���\Jx5!0Á�U����TZOZ��R�@)���or�Q��X�]�ƏC��q"�����hr�GJ"o|��U	�_a�e.2��5�a�|�C��ؕ���-�Ev��0�3H[�}hj��SN��I�t'�Uc`�����[9;�����n'����A�gn�2��NP/|�>�y�QZ�e�[M6CS���Y�i�5���ܵ�k�+l�"�K70�ˤ�'����^ϱCǷu�[��~����n���c���I����'�*�6��T�b0��[9L����S� w���	����8�Y�\Wokp������=3ٙi͠]*���Y]N�	GvxN��7D� 5o{ok����E�%X��_�P��]��{���	�{S�[� ��{�!
C��t�nk�VO YG3��QW.,S;]W�ӈ�p�T4�ݍҒռ'�=� ^�q��@���M�v{�q�m�:<����g�j��˨ڑГ�p-p�}eF�;�Y�4bC>����g�1LN�+okE�*�*	�5?c��P�̬��%Gg4 3I�	�s4�\��r���O�
@�y~�n�>r��"��~l=݁Vb�w�L�Ɵ�2�����b-9e�Q{�P}sQ�C�.�)�
{�QK�<�)�3؋P���6��\Z�F����j�1$���x�w�+'��$�mj���0y�>aَ]i����z���^p����{�qXr�Sg�/=�x\�ß�634���:,�%�4�[�|��>�'nt�j2l���f��zJؕ�;���y�:�v�6X���b��Zڲۏx�W���qu�%^*��$YB��tƓ=���ե�����5�m���*���Y�[�9O�}~��)ON7�V�4&�ܻ�N����`w�(
����� ~������վz���<P[�L�M���D�m�&KwDML=i�����km$�T.�� ���Y�g�xȐ7}���0�D|��nІ��~�aw�~��K�n7K[�oa3װX\�?�7#�Hǰs����NME��-�$F�[��Փ�_[Q�mQ57��n��F]��XN��au/y���<������#�q�V�]��4z^,�I�e��.�jj[88�_5�R��LgØ�W(��EUL�Ò�N~]
�V�ѡР�ꉁ!B��L�+:���kK�>Xy �k�.�>���o�~��l@Q�:g�P�\:T�g�3������ؘ�Fq4?��@+ Q(����<�}Uo1J��0��7�y�]���w�����G0 �ݩ-=�{�����=}�2C3��!��t��������Gu��N�G�St�.k��=l��x�mo �W���?��hLA�1_�i��U�?��?�;@��s6��J�&�?���|C�٘6rB���!p'�u��~)�ҽ���uռ��jZ �K���;�ϙ�����%=���1��u;������>�����K�3��(�f�d��-��q14e�1.���H�K�FL�򒈎aV��r*��E��s�?�v��-��7��P�I�I���7��\'L{��"�Z���gX�%�^��ѱ�4��4w(<zH���|��r�6�>{�t�,�b�ʊ��4:��d��j��zz���3��$��ǒ�/���`+�c��a�>X�${�D�rDI.Հ�QЪ���w5|�BYI�4=�N�_@��L"^<���5d�����T�a��Dr���7؄���bӇC�0����]�EX��L��R
���4z���������pr����N�$���	�>��b�2���pD�lA��=��΋N�I����aP���(
����7Vx����>DRHZR1��H�� }�r�ҰsՅ��#[+D���P�_&�	�\@�{Q�m�d��EU��A#N�/��K���Z_��A�Bi��x�]x|���c��q�[��إ��	Z�-��PZ̶��ߝC)t\��/ ^d�Ғf��2���q�<y������jL���w�O��otC�ʈ4�$$.M�0��:�v�mP��ov����&�ٖF¿�v�h���G��Y}���7f��R; K�2�N76q��9gkwك9˗�sP�)޲d�ߴdz������a!H�;T\I������fn���J6GXZF��%�5��8f
�A�ؚ<���s'������,:��%���ܿng�dnx�2�)��ިaXB�������m�A55S��/!/Ӿ�kψp����,[���ͯ��u���4/�f���Ǿ+�?F�_CU�WQ<�V�myC�b �M���&��:��l��@����Mͱ��q����bcpd���|��5VMqM�����B.����t����
Vw�����,z>�=��4�3J���G��t^�I�8wu���a��i�z݆)I�'v��m��ݟ'C�|�/%���4b����|.9��]3��oߘvJ��*8�R*���ȋ@F~6��o�a4��I�î�Y��J��3�ox"T�����:[��4�e���'�~�%�������ĸ���3 5/+�@�;�>�{��?�a�׀u��)J�Cg���T��l�~��h�6�^����Bp���J+�HQً��>%�6��5�q��W���W�"�lʕ��
Mqt�D��9��.���A��:9�7�/+4��.]�󶯐�{*%u4D�g׉e���B塟Q��W���7�q��
�헑�r��8X9�����U�����*
�  z�l�1��� ����;O�q��g�    YZ