#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="512633229"
MD5="37e2b955f21ee0f55c13ede038ee1ed7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19784"
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
	echo Uncompressed size: 132 KB
	echo Compression: xz
	echo Date of packaging: Thu Dec  5 00:25:07 -03 2019
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
	echo OLDUSIZE=132
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
�7zXZ  �ִF !   �X���M] �}��JF���.���_jg\_~ŝ��	���3u���Uڜ�9!�Ɋ2�?}�زjt-��g��ᴓ�3��ؖVs]0��>�6�s�j����+j��A\՞�$h����T`�gL=�v���H��Xz���\3ҜZR�79ź�ph��?]���{���6I:
���@d˷h�|�S�����=�?�$��#���A�oK7QQi\�75�vu�9?��k-]�a\=ނ�XƓL���J$�e#��Yi�3���d�Y�!?O��9�K+�8�LW�;�x�o�p3�$��\�x~��4�h��x�TEd*0N"�)�@S��jq�T���\I���ai��V�����͙��h
�3�9�T�+"�m�b�Y1���	��AU!_���� ,D��JЈ��y����a��/A�eJ������o��HHHt�}�f@��z���*�q�H�:q�!��K�>�R_�)B$��x�PZ�%�7G�I�a��ɔ��@�J�[D�%���t�!�ћ|��-y��q]���~^�A��M-�=�r�h��B�P�����5Ɓ��W��qJG�ї�8a���Å&��ߨ��=9nJ��3 �U��m~���2׭<���g_�Vd'T��!�>��w��LQ�|a�s)m�H�@nP����Φu-��Gg�5�4�
�e&S*w�D�
w��w3W�%�39��p۶ή��_vL���Jc�kz�P��v~^u'�3�9�c;�LR�݂e��&��'�|w��R��+���I� ����#�4�CH�'�ٸ�@��I��i<}��k��2�z5�Z	�/�'8�׻s���M�\�4�8��\�� %�7m	S�W��A&�,޾�u�������{�Cvyx�����=;���%N4?�\�Qb5T�p�]�Rsx�\ʘa�VD�_4�\�~��e��c
l3��ѡ�؀�d��1,Eo�|��+���q�fq����G��m��^�0#� xҞ���;Q�DOCx��$������tOx�+�tx��Χ�p	|ܣV�9Wu^��o�K~Y$0��av�#wݝ�r�cI!Mhv���pSĽ?hćC�mC���'�)�͔��>ᏢB�F������ 3g�:��`�U��WW���q�E�Lp��m"Ѽ:_�J��t1P�t-eG|S ��>\2}{���$<fh!��yx��yiC1��\��d��PGD��PB�i�������[�y(qB�.�K�^�\���q�o8�=/[�h��( �:A��+����������}�MJ��i@�cÉ�Ѹh�����?��9i=8_ż��k���?m�]�*�Na/%�7eA����nWh�5~��4F�M��ďzw���7V����f]�
�`O�`�eU.�Ӕ(T cy�*�EQy�z�$�]�w�m��ɧ)��T��
øVDPXKh#��rX����B5)	�quе���f|�I�A��:��M]����3�\�X0�巴ǣN/FH�JY6
I�5l�YlZF�tF�s��Q��"����͋�0볡�7�%8w��CT�2E$�D����4�͉%S�5������JL�^*�G���yN��q�x$X�dT�c��Z:�_Wm �0�a�->a�p���D�D �;�F���Y�wcyf(� =@�x.T�ӛ�� ߍ�aF�:�Y��Ϟ�#�/f�eY^3z����~/�=�_������\�u��r���*�H����^�߀��u&s��c���*����l.#k��9A����M�3�����,R1�"�P��x@����?��y؇F[�A|0��}2z|n�������l�ϗ����\���?![J8�47�ve����@>p��G��W��L `p	yݑ��)P+������/mji����1�.��C)D`p@�G��:��D�[�%�^|��a@V8�5'�Ms2�%L_dXX��rr���?����ꤪ]���׭e��΂`���N�(FWd�r8�ͣ��r��)�ygJ  &R�C_���9����N��,�*GVR-[&�m@PjF���dИ��QƮQ�1Y�2Y)���"����\ߤ�36�^^���[��)��R�;j��ل�)je�b�&2du�S
�G~������ɕ�>��Ty����5�q�0�ܾ��}_��ݎ�� c�aK��
��b�6�)n��@��P#�8�ȏn��v���-�	֖YQ��r�.ěb a�|���y�� .�0�ә��_ͮza�"B����B^Sl��Ѹ�3���J�s��R�륡�����A���^n�R������3��,n��c)���ǟmƆs(N�]ҥI��;�	j~v�7VW/N�bɸ���H�-˛,.��B}z�,}?�B�m�{��*e�h-��Y�d� ���Ê;��W����
����!|i��U�C�b��_�?�{$)cpj�@y�9�ԘQ5�U��~;�����uq�}4<r�EWMv��|�X�f�G�<ld�6MH<p����W�!}�F@eGe#��w���$�Tf��x�;C��oݩ����>��������e�]<�~��L��jYr�WB#�+İFp_JD _��Ց��#4�#պ�8*7n��^_�NRx�9��p�ҫ����C����;�����1@м�\J����㻊�V_��x\>�.�`��L���������$X;7��Dai״��d"Q��W�6G�mŌ�7�T�nڭbW�Y�����x8�Y��'B$b7h���{E^���:78OJ���]�����K�L
ȭĂ����p&�D%�z�(d<A
��XL&>�ύ!p��s��0rǐ��c�Q9bҳ�^��������!koߓ�Uqc���
�0�}���.Ņ8�py�ϒ㠙a�Qo���d7��o�0����^�Nm;�[���	4d��l�xA��$k:��p��e�@���Ɂ,c����_	��Ց�Gq�2S������	�z�޺B�_f�4ws�P�٭�:����@�0��]�GGl+�7�
�IX��A� 9*�u,}�8Y�����>�3���F𡾀"�$����Y>X����SZ���X��`v�!�e	#jx�Urω57�x�R?��n�6:�7{����8R�S.U�c;�3O�:+��1�;KT��� y���F1ٗ!IV=́�r�;���
0 }U�ƽ����d}�'����N���	|���8Ͼ�Y�l�[��5��~��3��d��}H�5��Sw- �&�"�l�=��wP@�d<61%��3(8A��_����#J����[�mj`��8P&<�Z�Da����dz�|�	�U�~�(*z����;�G��J+�Y�ʞЕ�o8��������񩁮�^�ˆ�BX����lC �c�l΂6�w! wL��}X�2��[����ڷ y�ƊC���V��]��qvO�Κ�&�Tϲ١P���|���/J���cЕ&�/^����>����%��襀�V�����"�ޗ$�.ly�"$�gV����aD��/� �¥���R,ȧ���KL%�*8g|���e���g��*�D*߶�=�{c}�o�s_/�Ѳ�q�;m��NO �=��-���q�SH�}cj��ºOl��������V�q����P��S�>^�h��,hA���1w=:wj�nb���k��Oo�/9����V1Vf d�����-I`\
��;�r�J�8X�p�wc���"m�!eq�~�Di��	+L?A�
5��#�
r r�?R=w`Tza�i��-`��7�z��/*b�l3����^*���;�q\/2#�R�q�w�W���Q�Ƃ[H���U����C0"��aռ򵊳���d|ds���)fʑ=�n���Q� k��K�®2�QG�r��H`��@7�����Gݐ$�&#Q����݉���6�Ū��>�t��]m@�'K���k�w���4pAK�k�0w2��j纒xҭR�uY��w���rJA �u��?�2V��@��Z� YOv܍����Ֆz��QPj���r~��-Q��kO+��P�8�m���K��t��ټ� ��G3�� ��w�Ɲ���� �U�#���B�*�eږ}E��^��&x��8��L�T��&��I�����1�C���(�A
	g�;f�C�vVJ�z6I1��s�ҴO��`p��"���[k+����l��)�m&6x�ٿ���K���w�L����`�Ԙ��-�uQ �:�����Dr���@lZU��	.�Q[�1��Rx�ځ�r�P�Ԉ�b��8n^-�پ���T	��	��R`{��K&e�k;8�0�u���i�_���|_F�YF6N0͓�2b�Q�b���&�˓���m'���;��H/�� �z��1q�oy��?� JlT��:�������;�6Zc��`F���=�L� �����7d-�(��Vp:��A��)�j@�?�*6�a)}�+���v�*Iv&p]������s���6P�Hެ��A8�����K�:U߽�C���P��m�1n{?��4��g�P��]7Jl����Ti�PP�Ĵ�݆M?l&b��#��P�������-q����,F.L�(���L�Gh��u~ڦ����7p�W.K���s"�$��1]��ı�v�8�XH��V"z�?x�W�z%!��J���"��V���!a�`�oX2�	�k~���~��{$���zq�����\���]�<d}uG1��#r�S�Q�v]x�r�[�\�"~D^�rƙ��*�p�5�U�������z?�9���*��n%���\�b���ڏ����Jq���2~����`5aZ�#¬��t��9M�3���5 �'g�w%Y�<�b�����9҇���P�,l12HN;��
�ʘ�(н�Z_I�jꟐFr	��Xg�f�l�1t}ޜ�Q�k��$��ֆ�>�����=�yB�3��rx2�v�e�Kfu!ǳE	$w�B�uJ6~L��`�X�[�ء������dC"�
`�՜�y�����m�؏"B���b.v6�i%��C�pQ+/��cyz����LK b5"�zӼ�I��|��u]���*\��I���=�� 6��A�RI,W�Z�#�u��������JhN>鸴_�?��kJ
���d+#�U�y���7�"\W��8��,���Wor<�{�}Kq�P��L�_�*(�<�2��C�s �� "��U�8��v1���:(���e�[��%����
��(�l"��K�b�Q�.��H]��֝^�GK�)b�- (���Ύ�¸����T���#|%j����ݴ�J�ic�Le2��և-ʯ�E]�Q��d�Ը�,�ɬC�(���U&A��j�P;I�g:�bH�V���ԥ�;6���1�/^��S����9�L�(A�~3��+ӖC�wUM�BX �!WM�3���­m�-{��)��E�N3b�k�]~�YBӹN/�R�uF�	�뾄�U�IA��ěf�W��k"���DDu�"����.w��'b�g�0��bM�Y@��o�X�c��9��;|��Ԯ��I�ܯa�b�B�㕖p4��~���\��g�1��#8������Q�Ԋ��'i`e�|M��<�-���kH}s�S*���@TCi�M�*s̐\���J����Y�lAϟ,�[�<=�L.<��T��F���+���3��(�*^�_A8�����g? =��C.#\��|���2�q[V(�z "�R�T��B�0HPJk��ΰ����Oy��]��ʩ(.x Q�F��[���u3���x/��:�8)�!���dl�a
?
�y[�Q��e#��J��%�9��W�B�5�1����N��?�!�X@E�k仓O��Fy�+� �6���$�V��C�j�Gx�������Z_�r���p��~�R�L�q:� ��OU�۾%h�^v��c�ז���q�d��sؐ���;��]��y�������@��c�5o�B#/��PЀc�-4!	1/�֛��ʃ�T�B��i%j���}���x_K����4��2n��=���+�q��5�*/0Q9yR����ky��׃?n���&� ��� �'����s)~����:�J��l�PEX�l�:�M�U�ȺV�Ѹxꊛ`~]�}4yh{��h�y��`�����	7ΌȌl?H�,��_؍	�B�U�C9����uc%�dԃ"H������r�h�E��ě��M�8�.��Oc��� ^�,�N�b$%��6t����^�ZS��6v)��Z;4��A��G۳d�6h���A���]�9��h%���զo�B���ln�x�F��U��j���ṥ%<6E�D��@��#=���1Oǀt���MT��㫖�aF��ѿvCK��ݫ�}eKk@K�w��VX^��Ġ�z=�~l�?�¢ �h"������5�o[�7>�ȹS����+<+[�9�nG����ĉB��S�\�U������%��}����!*��|fRل�ZJ���-���F�5�(z7b�x��h���^��৶3�͹�+K�R����&/�4�l3�'H��8k�q2O'gz��*�"��:�;.rѻ���tT�=r��n�#UE�����t[`�,3v���z�Ho�H�I�����s�T����X��NЁ�F���9�a�������Z��(��D��F��>���PV�t�c`�3n�^�!/�ˢ��������F-�}���[�	Ѯ88�����@�U4��)Ȍ@����E^qU�E-6�R逤I'�S�7R_mf�U΢Kl�K2���7��z@
�)h������mY�|Q�&�N
�Z��)E�j"�� l�l����EE�r�W�8�v�J6s���݅�W�"��YC�E��S:�i����Aџ$����t��ހ����YUZ�I�2fc86X�04�}C�l�͎�S%��p��Qp�n�|��^���Ҕk��r:|)IS�5�����|��*Te(�4�z�b�c0�`���/���k�o~�]W#�"��^	"( �߁�������.'�ޟ[Ͽ6�ŝ����Q�oǙ���('~!�Юn���n>��H�7m`9my�7���P۱į�x4#��0W�:��m~ϟm\�9'�sc��K�`v�i�c/����(����ރ���h�JL,�٫��-HU�n���Ϣ水(�	5M��P>���.5��h��֨�5bA-��`�{�Q�{T�l��*���A�
���l��'����c�����q�� +zX~q�֧��S�U��d,�Ҹ�B�A����MO�n.��(��<'z��.*0@�)������#�*��X���	ꄈu@[-@��<ST��,��@��`�-Y�
����?�E>t�-�UA|���k���(p�n'�[��')/rr"6s��ze�R�1A���H����J|��ߍB��oP�^׏)mRG��.ϧ�����5�� �b����\K,�y�lz�]�TY�H���VK��}%�C�>aE�rnO��	�l�¿�<=˘��C�a+קʘ�i��+���X]����^�$a��_n��V��0���T#��J���������
[%>���� �y�=/(/8~��J�q��3HlB`�*DA�M@����w"�0��I���~�F&Y8 =��?G=�q?d�5�0ۀ#6aUے|M)v��b}\؆�RC�0��;G*� te���px�j�?mh��b	��t3���\�'ɩ�~y4�F$TYyٷh:���MЏ&�D/5���t&�*��
����hn:n��ύ*^�Jδ��T�*�=��r�˔̺�ɰ��xt��?z��/m�[]��X���(K�[���ð�ZѢֲ1�<��q����;y_���Ҕ<g�D �f�,5��s=�-0b�xQ�:=���AC���&�ؓUM%���#�EkY�q6wIЬ!з�T�ai�e�(�5{��( �bp����8���5����'�;�7�w��mu��l�l�h�����಩�9Ru�Us��?���5�=�X��/k�əzdp9�M�H6�EF��t����l:�C��c�vmr̨�V�w��?�(ҋ`��e��P���t��/�d)<WAI��Z���6�vL.3:c��x5�viIM�Q�<�B(�,JjG/u�R�f�:��S�Q�;��o 0���-��ш	����I2�{.V�ɴhJ�
A�V�$��v�l��騭o�Ɣ=K�����e��#��g��u]��Ψ�W4��o��|ͤ��W�L����\��-9��<�Pͽ�$�5 b�tp�2���NP0 �Տ�އ(9ٯ�Q��v����T�w��+�(}`��m<܈/��yQ����v�v���Ɛ�~d�M��>Aa�F���Y�A�-�_�"�7:��2ƛxj�� <�ꅣi�r�KU ���T���^�h��J�����*LM�����M�����䓍�����-�o�ǭC��k�`�F;α���0��4!/�m�9�>ѮZ�o�����PF�������f��!�rC�oc��F�ƥ���
>�i��}b��5���dhlڙG���g<H�<J�׿�6��Q�!�Y�Md�ǔ1CHZ�߰�!`�U�
��^N��%���ߍ�:�A�c���T�!�x�����|����ᚭg�e!���^ �Υ��a��|r�Vd��o�-�)��� ��c�ѫ$�=���Lu���B���C�
�x���
�s�����#�o�d��\��> !^	��Lv�{h�w�˅���ko��yZ�h)Ϝ�o�~P��yxȏ�1�^��n����ka��r"$)py��o�^� �����9�w��.�\q!V����O�tB��ġw"{�R1�n�!&E2�n`*����vkf4���U����j��pX=Y]���ۃا���W��q�����v�d�Hr��_ڽ�0����s������4�a�J��>W֟�͞�A�z�\h;J�^+-h��,�BΧN��ǇY�n��X�fό�/J)b.��B�#[g��b��{J�>�nP�՝�����vU����~o*��ڞ���2�e#�X��tiN�]+�D�ʴ��Z�
�,��h����[eF>�����V,��	����� �ԀO|�N��q��^=���@9�L0i_���Ѝ�:�Wo`�N����<:��c����ƕC�ͅ�|���fK��M�.:)WV��H���Fm�K�I)��@����̓3�^�t�Z�~a0p�n��~�и3�fC��~�1sb�BAR
��W���ދ��<��U4��W��ߛ��=��*���^�fI�N�!�m.N��2���l�)8x�&^kr�roP��^�<��l��i�x�v��)O��3d��M)��
.B2������CY�[J�O�mK?�j*]<�;���ɕ?�wpO�]�Wd�1��*
ܐ�����PQ5�C�R+h�{�����P�íE��ML��$�<>��bݺޝ`?{@5���u�W\eǵ�Ί=�] �{�*+Y{���U����)�EWZC_��E9o�i�������{3F9�aHʽϐFV��P�\;ƈ��Lͥ \;���p�.m�gH���� ��n_;��S
�v+}xi��;3K�nܣ3����h���m�M�˟�0��a�*�V�zE�"�zG���LP�i�ejAE�*49�K_�^g�V���$o�� q��:�C�&�R9��SFv1�Ks��C������d@$�@rY�l�B�f�#����~�YQ��O�Нǂ.���>�7}��4��<�A�_S|/ް�Ou�D'kލ�B��Բn���I|M��"�ގ~�.�4WB�(�=��?w�RS �D9.����x��X���wϮB�p"����N-�_F�~�tx��N���)�iX�b��t$��AM��Ǒ�?+/'�������� �0 �.�S&*��[,�N���a��v�+C�|�j�p?Յ�%����d[�h����l_n�/%�+Vz��� ^ &�.�f�@��Ux�&n��.��P��r���F�s}�3�.jC�ӈ�6i+3!! ��T2+�3Iq��4<���_P�ͫ#�lyp�m$N4?��!SĂf�Dӓ?Ĺ����?RΔҔ��[UW�;�?��*� ���gm�C��V.L[L��
j��m�c�;��t���w�F�F���A�Io�Ͱ�����*����Yy�Ցp�G����Z���C��]=�o��:S8���^������6o3N��(g�J*z�t8bo�b�x'��Tb��(��#"��j&+z�y?`���*�D��/Q���� >�{KM$���/�����y�5TT�U���.!/�3mZ�p��Cww|��x��M�Bb�4B�\P1�)y����S�C��.�hO�ͭ�ɼ:e��1�8(���A`���D��Ў)� (p���s��*��X�#j�HG�=�4\8��U���~��wS��`9W�4�6I��U���cy(�<��+&��{�
T_�7�P�3��=��c��W���'�4����w��+�Qxs�ZO���D�׭Ps˞�٧�6I�r����i^���Z~9���]�g����j�>�)�R�y��mS�:8y��}�d��wW�cA�ơ���@PF�y��n�_�$G�ǭ
H)5�8b���C�nAD8�#�s��&S��8T��R��^���|���h� 1Ӈ^!gmac���InI��,�jC���sF����q�/���o�iS�H�gJ���P��ki|�����2@���y��Y��PT����[��m�i�_���x����˅ 5G-=w7*��qzNm�`�0}�ͺ2E.q�@�%�@@� ة���+y���mwO�cj߼K%1�/��z�d"54� FN�e�G��m`8Y��$�}�Q� /c\Z�o,��0�$E*�jH���d��*iY x/W�=�����o�C�z��9��d�g���w�9������	������[��-5�*���;�	�(��D*�?l�gԦ�4�Eж�k|P>{DM�r̹�i�y�叁��-��Q6��D4V��*�YM�+�j��i>�N���C��|���l�D\���
��uwe2���ӓ4;�*o���`<1�jIQ{�NM�R������Y��#��FZ������r��@I��9�u?�	8qRȤd��[�ȂkQU*4I�>������>�Ta ����B~ ��r�]d���D�9��A��B�DIa�N'f�&�����^�6�)�����2S���`r{*U�o�H��5t��A	��,�&�1Ϝވ^�ĜӇ�s���+�Z�m��fIxZˁ��c#ɩ&��.�S&�����6��[��XI�VW���m����8#�s��+��h��o��?�wM.�{�Ơ/��5��t�X����8y�O�Z������1�Y���ˡۍ ����%��tKWJ��'�s.=�Kky��4�icK��c�֞\�L��HbS(�X� ��彦%���k���T�����ګی5��d~�C�Y��3��ڟK!A\��i��ᛅ�t��m�����Q��)����-�&l��DNb�dR�6/�~��C*�?~�*[� EĤ�='`�=t��mYjrU�E��R�_�h_��CHE�Ù0���@M�x���GcLPS=3��F��%<bvlY?��ʶ�ai��Y[te�J���k%�[�h���
 [��V���������t<��j���_��L���Mvw��L�`i��?��Ŝ.i �ʿz��(/g+�˸L�c��� ʤ���7׻?�/	Ό=���wB"�h���ʒ�I2x&�?w]�h��E��:Ǌ��nшƟP��5�Q��i���M�o���浝��d���\���JG�	�)��`��]�N`E
��.o`����7�&����g��/��>�5udWMH�x�_$C/��Ba'I��GP��,��b��H�M�O���P�]&ё�t�F;�BfP|F�+6L(�3
N�A!긡g;&�V�k�b�{w%h�$D#ê�Ͱ��@�]�[3�������*���Z����TƁ�"2dp\N� M���2�l�3*�.��TH���z� ���:�~i��RK�V�[�{w��7��.4�p�܄�X�5<-�5JZDDD����_��W1l���н9�qm+f����������#��}��ԁ����T�����kf��v�[OE���m��l#V�U0&�����S�ce�F�i�����b\���0�,y��JM�JW�C0��l����)�pNg��I�����x:���t]�s�p�x�@|��yC��zzⷼ�$�;�Z�CAF��0��������� �(��Pn�7e�(:d�b!�r���Z��ө2=��$��5i�6����o6%_8��3�Hu���&�6���ςI��̲�¥�:YI&C���~�ú��y?�:�4�f�ci����諾y��?I4[~�L&fF�#�d��&��ٛn�*�?��,����=��agv��8S�թ��h�_�Y���q�Zb��&��U��s���d(.3�Ӳ
:����u�	��އ\ް"�&5fS���a�.!O播H?�5��G ���Qۢ� �r�f� ��㝾���K� m��#]��+�	P٤�E�J��%���j'����}_Hs��V�d3����Mj8�?$�g$� e�[���.��;���x��G|_8��e�hV�l�o�rג��|�M����|�
JSq��]H[*Y͢���%;�-���7/c�At���ii!8�|�b8x���0�T��{rz�P��J��_�3W�a)��Bg2�m��山k-H��!	� ��\��¶�K�� D�1k�|H, ����M�]@Cq�6	Wx��2H𦩝���[�嵫9<Ȧ.\��E�nP>%�S?�Y�%34i[n�J��Q��L�0j��L� Lq�?V$� x*��E� �1�7�Y$�|����Em��`�qH��ߍ����Wwf��T��r�E��@�n�`��
���O�@���M��+�m���.��l��k���p�#��L��e�<0��a�%�i@�-�Xӂٺ�4!�/��z��ױ� �=G��n�&�����+���3�lT^s?����(�-������y5.����=�,��{��8m,�G���,D��N��-E�"��2�2�?
�������i��Y!ș�w<�]Ru��v�yՕ���	j�S��+t���~n(u��Ǜ��OY 97���'d��{��G�Vq��bދ�q��MЎ��<_����>�ӊE�h\�w��D 38��a�8b�g��3�z���!��İwT���4[R���M}��;<��.c��5�=Sz�i��r:CL��;/�-f��4�7�oZz��ǝ�Lc]��wx���kf����{�ݐ«��YC����u�1a0e�F��������� �?�*:�CC���:���@��:�	��N�/`kP�G"$$ٽ%a�s�{���c�k��Y����~>Y+��8I�W����N� T]����IŋE;�8�P>��'����M
A���(�����lay���?��J檻���6��n��"O|���Fq���W^U��B�W�^ñ�t�OT��v/��9��I<����=��Et��(w���ߴ4b������ܥJ��k-̸񊙬������D�[��T���n6L���)X�V�Ax��X��M��$����.�y]�i0�\Q �5��#{B�W����v\$֑���τ��L��}�v�΅^��� ��%�sì8�>���.RYB�Sk�օ\��d�VyY��=�0/�i���ޙ^��z*
��\|����w�h]�w��(�H�&��ò�i}'���{'vF�
�GpR��G}��7�T�.~X��� ��S�E�"�Wl�A�p��^^���
C(���u�?jO*��3� �M�Q�ϝ]R�1��J�
!��M���Ҭ�#���� 4���cYzT��Z/�N7>Բ�r�a�V�:���!��.��/��<�L�-����������/�v��.j0��!5�Ca���H��,�u] y�2�4?��n?�s(j�fY�L���F���܀�j�Vq��\��:�!��բT��Z4�G��ܗ�ssfBz���v�~����%�a��nX�r��s�9���/�d^��.��g��P����0�[��u�pT�����m�J���x� iڰ�yI��M��:��軭�G����2��D��,0Ҡ�N` ��Y����O�֤�]o�E��hzQ���q.=�S+�]�[��B��׹�^U��`'�/�v,u�z��j,�:6Ő�V�:��
f�I�]%�[� �k�Ʉ�t�]W�5V��/�����Ф;�{����a�G�ڎ���\�B$̷��re�ܼ&!9�5������~���9D�ۗ�TU�2nH�La�ni��-���kkR�p���*�E���=Vр��J����{@��\��dg�(��}8������/�;����O_����?µ>!P��*9e�x-�U�|)$U�ޛ�{4̣1��=c��UW^�b�Djvu����>��41��;P�ʴ� ,;�r�B�h��$
k��@�
}� �nx��-��C���߁�S��S/�A����vA������h.�a)%nR��Q(�@Ds��n��F�S��(h�fo� $��:\�8�k{G.�ռ�������R�s�Z%g=���1Ϋ�_�B�
g%Ub��X!�r EW%-+1�s�� �V���p$�4�GE+u����e��N�in�EdZ� c��� a�פ������?��X������v��Ý��9p��i��|��Y���L�}������՚��j��{n��~,���q�T\������q�����	��Zz�_��-h$�Fl}�Ǔ�>{$Dn;��'�MV�~Vc�G��� �y�>�ǽ{G����#��{����	T�%aTCC����$�ti��F��������K�P�U���gvҢ��-��B�k[��"��ʱ�����[��#���n��,� |�VS��d�7�r��GU<��c�����[:�yHMX{���w�GVE:-]~�8a��Cp�ژP�~��Vm�4�"{�|�-��((t<�`|�-��UZ��p��XA��t�R�����Ƒ�xx;Mo~a�����)����@��|�#���uݽ�i�EＡ�x4���d��g [cА]ʗF�Zb�ȋ+4ph��{5��~(�ԑ_[�O�q�n�����~�b%n��Ѯ��)8hk���)�"�f��nW*�%��Gd|uP!�����lK}��X�&9�w��f�@������A%Q�j�1W��g>QDbب7�/��|��J�E��S��D��>hl��6:Q���R�tg]���E��,D>�eq&)��x~�V�,-e'����&�Ԅ_�?�.�H�4[|��8 _ Ǘ>ⷓ"����|S���A�<�S�q9��b�B�����2'��4
�����E�c�ڒ��_��[A�h{Yc�����3�s&�����P�me�xcv��n&���
�KFչ-�L`"�UK��X��ܺX:v�;<\�+�]��7��CΕ�� �rx1;��I����p/%�9N��3��X�N���yk�[3���ި��{!G�	7z3�	U�'�}��"�R�'��;4���`���^����Y�MPH���w���S,�Ւ1N�Kvǰ�꟏�}�*�
֬rᒎ�9����Vpň��eǬ�v��5oHG�M4�c��"X(0V�5j�����^�݋��7e�5<Oz?��V��O�SZ�@y�Vʋ-���1c�K�g�r~q�Z���0q��% �6��hk�$�[�Џ��a��ɛ��z;,�Z;���^+5����g����؂x8<<��'�卽X��@6O9͙��E�	��4H�F� 6A���vS��u����tɚT�xWd����y򕀘J�!˳2q�i5�>�bvfkx�}Z�YhE4e�k[�3"����	�{r�&;�oa�������
��!�%?Z�\�m�8����R^�C����J�����=,�wu�]7��8`��e���N��c�u���:�Z�K�!��11�>MEq8�{=tl��1�y�8w����� ��w�ɧ�ܒ@gavZ5�*����r�ϴ7��Uj�z6�6����5�"}f_��(���i|�a�ҁc��2�}c��v>��VX��l�Z"X/�[�>qL$�\ .b
2#���Ԥ�(l����'�
;�"�Al+�F����f��o�O�/_R�]����\� �/���+�ֹ������v\Z�!��_Њ�)��,T���g�hGH-��-�"�*�8�c`rԺ��O�4d����0dt���mM�&�f��:G��{�����w1�6H<�N_4
.�K[�@잜��hA���`+ո���iH|��3��7��$E3i��L�1089́����vtU�}�Pa��I�{�2��,� vY:��fHڡ�p��e᷃�P�/���լTsD��]�3�NB����JX�O�͇S�/����O,P��C�ք�RߍY`w�j��\�q~��x;!��+_:�8ƮPގ�������T�uU.F�HsƋٱ��9�Y.�v$.>36�%�sy
�X����DS�I������tJ�k�0�״�Z$�.̾�����-�5�hz_<�X���'H�ƹr����y�Xn�U)ۺ�=0�j ���D>ʑё+�`t3X-3�}\���t+V4~�-�r���m��EY�wd�C�p��2sO���Iţ��l�\inp7��"��C�����M�� ��<_�G��w�v]-j�u�o'�s$a&ܗ�C�l��l��&h1�{7���<:����~=�?���E����e�T��P��B�Y�.CRPrY���R^�0�	�<��;���m�\�%��_"�ZI!͆r�$��뭱��$�d�abp�N{��IEQ�pW�W��vn,������Cnn'����^�����\f[N=q�uc���������r�2���Nk{��Nʝ�>,M�;O��T2-ӏ$:N�يv�f���Nf����i�x��C�/���K_#D,�p�E>j��r	I�jJ��<}o���_����G��v�x�
_����+x������@�	7�&�&(����p��_��t��0����A����uL�䜴��@�(5��ò{8��$;���Me�3{���"��L������ �X���%������#K3��.����Fx�|<4
��\��Mמ�����gt/���	3g�LZ<��k�U�d,(-��(��p��X�Z�C�@���O]ɐ��m�M�M�ɯSu+��1

�{�$�ƌs@���W~��^�*��o�6������DnE��5!Ln@H�Su�1d��2��SEbj#fC�I�h��
s���5�4��,�=,>!�>饏�FR�e��}+�����{�hf_#����2)l\l��_�Mωd^,;7�u�l�������Y�t���~�ק��{|+�b�؝���Ӯq���A}�S$,tcI�F,Uh�����"���/��/ ��_���[����rj�m�C�{����`�!b�J#(�V�Q�]҆��T�W �;0[#P-����[�'��p�:��Of��]H������&2B'd�; ��C"�G;�������g7-��U�ب�)�Z0o2��\`֌NC1W{5��۫U�(+���܌\�.�i�4
]�qZ������Y+s/0&_���׈�l]#�K�k�q�b��K�&���ӔE h�i�ʠ����D�2톖6��ͥ�'(ſA�E��Zs!2�1wq�<|�ei�+����a�6�Su�P��]�$�>Q�Q��tt�(lau�W�x��c�Ac�1�jV�-��X��0	�89�=,h�j!�WR;�(/B�-����ʅ ���J����X<aش����}��9���������4E��������RPb5���Ĩ�k�)];_���Cqv�$����-�����~�,�*��@=���4�4~�VK9P�h���QyϾD���Y}bx���A��ؼ����ЎI�p���D�t�&��r���LA�+Tb~$um/˵�M�i�Y���3n�Hn���~r]È|E��d��<LBC�Ҍ���:XF�����#�L���!m1$�(wK(b������TQ�6C	�O�E�d9�htak��Ǜ�/4�\[���1�bj�
h����)n&Y�w'�-Û����Ѝ�0�9�eMjh��D��%g�r�̱����6�jR�o�?@�QRt%o�>]9�B���o���f����	o	���3�\���[;n�� G!��Y�҆|&]�R��L�6ͩ�]��r>h��9���G��(/�S� ɽ�<6�n�G �ҽCI��mipl4 �0�w�����z�2�6H*R�j@%ĝ��{����cd�H���hI�f�4ä�a�4n������b�4 �U跣�&�Ay� ���-/�NǻT�����
(\�^%��.�L�t	T{x�$�:�ǆ�ͼT�˽�gR�P�:U�>�{±��R,5"EX5�D*�pI���-�����K���Q7C��Be7{��7
���� U�:��n����yLo�K�>Ǘ/ �X�y�����#�@��e�P����=��{-�N�=o��M�9���Pa4<��M:J�����'�6}t[v�6_��
b*(�qa�m��#�T�'����*/c��
��l}��G1	D%`�00��\���nkV�ԡ��Ӥ{����aUde��ؕ���^�]�dn{XW�MAյҥ�;���S7)� ��<���3h�`�6����K����4LHA�/ݛʿ�0�5h�F	���+�&�Wb�kH���l�����R��3Η9:L`k�֫g
S�~E���UW����-��xK� �4H�F��C��c`Ń��[
2z���p8�o.-���8m��W��ѻ�1�ԇu�Ԫ`�����b�f����/�ֶ|c�1Y��$���jyD�4B|�(�ަ.\h���9Ѷ�r�*�"q�:� �@�ve&o#H���͕^��4����]\��f(/�I���$����3P���"
��%�`�G���ݿ��hP��F�ޙ){dy,������y�����H��>p��2*KJ�"����r�`�f ��b�������Obկ���	ܼ�VW�Z8Js{hR| %L�6e��=f�?gO�+ ���bχ��i~	�� ��6�=X,D�fU�{���X-#9A��1�}`(,�t�pɂ��BN����M��p�!��/3X��%f^�'^le6#�m�{x��� }F7��x� �����݃ı�g�    YZ