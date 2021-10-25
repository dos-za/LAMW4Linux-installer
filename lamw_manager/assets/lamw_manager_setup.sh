#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2761471398"
MD5="95282c44d5744f43bee64d76b075134c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24108"
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
	echo Date of packaging: Mon Oct 25 20:32:33 -03 2021
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
�7zXZ  �ִF !   �X����]�] �}��1Dd]����P�t�D��RϦ_ݻ�����<��E�(�%vY�@b�R��'ē��/^$�-�w"ڏ`�Ep��>���+!����;Gd��}Ё̧��ɦ1f��B�Q�	>y詬:��F�� ��۱�["�ĪK��>��.�֍)N����'��`�~2�RL������j豓�v7�eع�v#��ah$�����O���r�Ko�sŹcU�m&v��}h���B���"v����*����H3��I��T���c���v�r�6�H?��d\͍DrG+ˇ�q["	������QB�9}�-t�s�oa�p��
��c¤�� ~�8�$lA�?;J.=H���}�A�W���� odp���H��?I���z_�=�{XL~hr�R�z��2�<���q��m�]�Y�}�j�o����s�5�MB�ь���NI%g:��C6{p�FuO���G_�����%g)�֊�(L�ۖJ	Q�Y5jb$Z6�sH��|+1�t��˝X�1�xlϿ#Ej��->yS�0� ���qQ��\�s�)�x���V�z6_��i9�Nt~&�UrfpHWP2��L��l"��|�7����U#渉��/�D�Ro�pWE]|������FI-��>�
�i�*�0���� �Tc���y���x���"ä��"�^u&S�����N�N��7�u�GY���\����I�β^������,�+� �+W�W|�Yd�o�z���)^�q�4�}��X
δV��=��ǹq}�z����Y��u�`������iḬ�1;��y�Å�>���>Fg!}߳���^N�� >	�`����"����K2VL�� G�=���~dL�U�D�s]g�t�N�Ȍ���V����JZ��m�oW7�I�'Mإ|�}QU�,mz�J���T���x=�Y���MIB`7\G�ұUb��'T�5s.��)-��֪-�Z�p�J�Z����*�~ְ�^ka�ˤXJ��2�ǹ=$y[��9�ڲ���&��i��R�v.��?��ewEO?��8����u��M{m*��*���e��KD�X^]h9;\�Et��l}Q�V�J�K�.��X��<�����ie�j��񜎷�k|�36 X2$�ɺ㫧S����D�|#*�frD��W����y�
���K9��������d��_(��eU}T�&��-Hh�����cp��uIN� 4"o.�
%��P^/�=Q���K��9�\�M����Cl����]���:�,��S�����i
 SgV��:����>՞�d��r[��z���?�՝���C�A�m)r�����dĩ��U�����	$� |��p9���>7|��'��k�
=�[,���I��ZM"���<�-��i��o��^�PW�-O򷠃��������&�t�m�Q�׃�"�?���s?p�~���k������a�,�Q}ߪy�Q�g��Ks�0�V���T�x���m`��̯��b�Ҡl8[������g���>�X�@L0�]�jF���=������:�T�����uTߵۿ*�������)���ʆ�;b��ta�����]�$����6̹%+V�f�=�D�x��Ve�_��l���C��%�Cl���Q�k,Y\��,Ё.-ı���h�g��R����bBB����ԋkW?`��A�w�S�%��o���Ǌ��{p}_4\4�m�-��_�V���(�کA��ď�e7������	MM����*k] sG�҂�Zr�1 E��i)8�P��Jo�}�OwPa�r���%�;��3>kLÉ�m�RDDl�s�ZPw�� ��\�dh�Q���F�wN\[a�9���D���S$ �d�[�aQ�.��x���Fa���!geW�������+;M��.ke�
P�C��F=��+z��E[	y�2�^�2]_	&��lU���2U�s�ٙW�{V�����s����]E,[�3�cor�����Z-H>US�#����>�ykQ��DG��!z|�5.�\�7�O0��\4����2ۊ��ʐF�F>.䠱qS��2dƥ$J����3:"LӸv���U ��认�-^w�M$�>1�8����"wL��2�Y4�����{%iĎa�"�U�p�r�3o�>e=,�N�0X�L�*B$d��2�RRm�Oǘ��dz3\�}t�b-�{�!��F!�B���8��A2c+�y8r�sjdBHd�.�T��� ����E�n@�yu~x�k���e	59��9��f���=(�M��*��́pDP�\��88�F�q����G����w��)z�*H�ܐ=�����pM:��p�-w#vI@�]s�6;6 3��#Y�[�F	vى���~~�>Yj��L^��~������u2ˊ5ě�a
馮���MZ�y55wL��"G88a�K��C��y�"P�wQ��;����$a�P�ß���t����9��j?�4
w
j���_�����W�X���i�hw�첂�7�����椘 ��u'3���к:N~,��}��M�zNҳ�P��#q������f��_+$�������3�P3��oy�U��O����.Ĳl�QR���j֢����eB�A˄�̖PI}�6Q*hn`B.~t�����H��c@�J*"�I�|`i��ʢ66�Y]O��!�d���Y�3���E2ě=m( ���Mv8�&v<��ƅ1$۟p|a�⃜b�),�>��f�C��_/`k�6�����C��0eV�ɓ*����:�_j���W$c`>���E
��c��*` ː�3Km�SAw�@�����v.Z٩VÁ�A���^�3�8v���r�k�O2�������]�5:�]�J�wyqe�č .�ξ֌�d�vƎ��ؒ��Y�zJ�f+�Ŋ�9��95Mv�3�bĹ�ր�lG�s�l����:�����c�=h5J�Aeeo�I�1��-W��hU���v��\����N���B���w����T�����5�Y����_�@:5{v�7�SE�|Y^٢U�Yc9��t,ʴ�#�q�4v�`��k�?.?`g(�1ر|�z
XA��,�\�b�f��[|�'�\�H�4�/'�,ieot�jK��ؠ0��E�X0�����4;h����)(H��;g�;��\Ѷ��C�|V�j�_�12X*-ϙ[��9x�3�<xX���R1��Ʊlh&��KF��K(Y8-.���be�'F}��ª������8�N��ܩo=uqT}G0�q2�j����x�W? �:J�&l«������7�r`U�m����ո���ƨ���$+�.T~#��v�ڙ�B/ր��@)ɩ���Q^M��N������T�+"t�[�nG�B<Z��c+&�
��/�����-����T�����-�hŭ�^����J��I�� ���$�(��#���e
�a�����޵ꏈ��	|�
jn�$��wF+�R�d��C��a$+@� �B"Y?HWL��xJ���%�Г@�2'7���i�!�U��Eʇ��[�>��~i.��%��![Lr�
��l�>"�*�u6H `{��S��Zq����m�9���~�v����_�����T�۟M�i{dV�'�2�����mj�^��ܻ��Mx8�"Ie��?&{�l+9k�^m\��#��(�O.�F�Fy"��J ���|��U���S��Z`��T{�S~�M�ǅt����o/��C%B�%���%m&f-<ͼ�eBT8�򰳹�}��\���CF�ꐿ��7���K���A`	�d/E,=(�}�v|4���0fgG:�D�޵�7ï�$ �����	1'7�u���< y:�O+�U�F��ȁS �`3���".gz|�/>��0�"��H`�*B�G���UN2`�Gr<�����_�"��}�c<���,ҳ`��}] �Ƀ4�)NqM�� ���]� nK��~�-�f0�	f�t5�.�e��Uxi-�����l�wWHi��52�mA��!e���9�dɬ�Ο�k0%���c=!�K�F��2��)x�	�׌yT�[*�Y6�FB�.��[E�����K�G�4�Pt�L%�5�U���Ӆ�\�AѾ���S�$��u�4���NN|0H���rݕ�DCO�H�h&W� S5�W���d�����6ń�/�Ԉ�8M���|n�{��Q�y,h����|�t�5̉��#��7����8V������4�C���7]MT����8p[ �Cl��d<e��$x�ƕ�.��qBJe��/k���)2u�F�XeC�RU�����o��»�'H#-�fKDr(Lۑ�_�@>A��Y�L&�&������"�3��u	_0�~�����.:�}�r5��h9GDB��M�f����Q��)�~Bl�:�e���u����-�4x p��gc[XD�su��ͬ�%q�>�L&�^�b��|��_�1���������A�l~�7g����P��ꄝv� :�n���~mnjq��!��n�U�痡��|!��~%�zRL��L��Rۣ��zn���?:<�/앰�"*�i�,��I��,I5õ��&�3�3
d원0Gw��c��EgY|�MYk@�&쐥D m�$qi�4�#�<y����RR�ʐD�^9+L[���ϛ�4�~�ވF{2��$@�2�zR�Ƹ�.�/����m�7�4�-���'�XFE왖\R����73.I�{r���H(�?3�{�#���	M�V�xo�X��Г���6��b4��'}�Y�I�=�;o^p�����u�z'����X�]�~�������P�1Ay��j
5�}8p_kpN�.P���^숬Q8��E��!1D!f50XO�5��oN�PqBq��{ �1,R�W���>�U��EI�&��wɅ0P�� �;�/Wa9�}�EqS�~����
k��nV���
"(_R�׎���3~�,c�%��Xņ�8}�,�H�R���o�㗡��hd(�G�SU��,~��d��_L<m��=�37y���|���g�k�d�L|4�5�N�bR�O`!�P2��t�$Mi��*�(����`��:FC�k
%���+rl�N�:��r�<���*�kF��څ��xX#h�f}jk����œ�6kd��:&H�?\���Nt&�ci&�-�!2,�_7%�+���$S%�#%BǬ��b��r�E�Uxg����~!�8��	���ǉ��
u��c�>�g��  �i�y2[j��Ee<�\��F��*�K0���NM�5~hآy�^�yN.�V�,�C)Y�Hk�1���`#�sM��bt���22�;��*A�]��/�}3�0v��Sxl*������⺛�#
����0ߏ�(�9�������,͠4,3�]7�5kd��8�<{�&��QGo��8)v���Őlc[P�ԇ��t�:�>|-h�JJ�viσ��f��)���^���2h�Q�ǩq�r&�´��������>S�-�v}����XCJ�7��v��~�Z�
E����������
��������``�t�dA��˔.\�����+@�g8H����8g~�ͨp�Ⱥ�Bԁ�盇8�	�Q��}�ݚ��xU��$��F�rp�x���ʖ�R�|A
��Xu��(%(q�?�;N�]x7��r��!/�">��t���$lq|����&H��.��х��MhYN/0d�J%�G�
�~:�;�G����[��ZW!�RuE\ �zh"+a��X{��o��:�1��谅%y{�i����H�$f�����Dx��D�e�6�NG�v�,?I�Nna2xF6Gf�`��)H.˖� xc�b��,�7�s�@ȉ��Mo�`�u{��r'�yw��#��AL�u&$B%U21�\lW��|�T�8�iΟ�j�S��S�>:���&B�dמ�y�9�u�v�uFA���/6M/����e`�% ��{1���%��$�����������k�W�tL�c�)�Og�Q�8�^&�������?��k�=���H� c�h69�@���!�9[��G��S�T�~������z�{8�z�à�������8��Ւ��1fX��x��v��?8�f���W��,�*6$O���'*��d��K`�5���:�k/�� �
��I����&�|:�;��l4'4���8��,�pNX-;Y�����1��=k�H",V���ӍV?��jQH~f���G�)1�'�{ڼ	�o�_���QQl|uU&	r1���Y�u�Na��AB|Eh4x�����T�����D�Ě8#ڀ՜|��ǟ��S��|K��D�9��WJ�[�xG���NM"��Q=}4�gjg��-v����)�G'�@o����qP�a���Fn��I� ^�:`�!oSC���P�	_��SN��LG�V��SD�P|�홈|$���-�g�Ό�' 0P�H3#���-F��H��ݎ�f�L<e$�FZVq@�s/�Ǣ���Ю��M�ރ���$�a�Sx���2�=�P�NfZ�\k1����3d���V����H�������X����@)�u�9�(�)�N��+��
ٓXI:���7�~N�Z�a�1�yJ�e�E�.�~�\�
��3jsa���I8Ƶ��8cO#��A��LΖ������J�L��2P.xo�H���F�Z8(��]��&���})1�PRX]�z�WZ/��2��y4�{��
�y�M�B��#x_��j�s��!1ԑ��o���>Iꢣ� ��%��t���]q+�X���C�?9?��<�3��av'����DM� "�����킵�-�,}�F��/�~[;o�-Lb�[��;:^�k)'6|C����.�h��^9>}#g<߈Ȥ��5�^/�Gz6�i���p�+!pf�F}���SdA�ks_���G�_�2�K���	H?���	�(�K�|.����O7t�$d}|ɘR�Z_XD����P3��c��|'�K?�&^�e��2����X^O�mH)�3ߺ>J�`�O���1}Mt�휳e#��꫊qk_����K���ﾋ.A��ͽ�_r2��]�qF��A��G<�:X���L�
��	tu(�ga#	シM{2*�Et?� �$�y�b@�������~[�IƘ�^Z�Hc���iz�fE��m�+����-c��<���S(�XVf�%v8f�y�teN$M�F���^��&�BV����e\�	�*�=�P/��A���� {���W�Pg���l��7���a�o�Lg�ZF���J�龵1�ˌƝ�;�:�Dr��a���Q�N�]�yJr����JwG~�ߠ~�.ޏ������h+����qL5��}���L��y�R�����/[o�)SwN�_i�\'1�����(���G����9 D�TN����{��z*X�����P�O���9�� ��տ�x�Ȩ�R�A��Ɲ��~�9����n�?Kd~�T�R��-��4�$�Z�V��i�t��dg��G�R�'���<H=7s�O9G�-��3{�&w��4_�-���k�v��׾i���=G\c�����=���yy~)����}Z�=φ"� o�2_���
J1���-"�O!�c�L�iߊA�M�8�x�����z�T��FS�,1��9�Iu������}�/<`V_1�\���%n$ⓀT"��U����uK�R���z��ZG��*� �p1�^t�[���B+��,�oj��7?�S�-_t=�yu��C-L�����+w6�������xNV`^���������=�#�&O)�E0�{(�S���o��?xAl5Ny� 
�	��+Mn,�4Q?�WH�Cx9/po�\��HS�N�G�0վ�7$����g���5�n'k�]�Y�bu��Ɠe�9J��h��\C�L�^&� 1_���%�̺�Tw'H����w6��g?x�3�f �E]{:�_�0J��+�"m��VܖP,��N�i��a���k��sG��9*�H:NE��rZ�mZ��o	Ƭ�Z�6���W톣��N���W��HN��q��rQ��V;�E�LH�W����g^���b���6Z������ETJ���,��&k?��׫<cը��	�ȗ`�^�At
�G~w���]غ(7U{�ka �Hj%Ê!<Oj��3(����⹡t��>C�E�ub1���q�h�`G�/�=~��O40�����k E|k��᲋����CŚK�2��'���� �A|C�&c6�;m��f�f�W�`+e|��EC��T��ATky7|7��~��Bo�/p:ڌ=�I����\+��m寮�w�3���b�KQӂ>VcD��J��&s1yf'��ޏs��
wp�+N��� �ڢC�0�z�7 w�Mh�8ֵ���Lf���՛�KK��4���3��Acݓ���#<�z�%w���Y_���_PO�TjD������;�Q�PPz���4����8.0��PL'�8NdՐ_M1�?����c����wv��Ϭ�D�nF4�]�m �kQ�F��Zr��Uq���A�Y��;[J�[\���r�*-qR�(K��J�N�D�!Ƈ��3 U�f��H��We�Y��-oJä��W>u�h��2�}e�E;./�LNC�3�Hl����\�)<���yk���e�W�F�	��C�]1X�=-�����w�����H��$:�`��J�+����ך_��=�'3�ʨ�"���f�:�!L�K�?�TTڂ w�+$�sLpp\����z���c���|Ž��g4P�=W��&:�]"�]e�q�Œ�v���"��p��N�Z�5�EVI�d�`&��];{�`'-L|��F����,EAFp4���??�~db8��-�s��
{f���iI����G��7.���� �����%H�)��彃P�����;�@b$�l0��g�v��V�����5���{���_���B�K�B��ÑX-	,�a���߷�����S��d��F.��"{������z���"�p-���\Ay�=�0J.�����űt��X�ߺ�π�E����o?�ʹ�	޻;�B���iA��6IPp�@���9�`���J%�vRB�<"�d�?g�3��zJg eA����8�+17��\/IH�`�!)T���P{ptat�KF
2�5s��k����R�d��K�T�Mҹ9#3��uu�O���{� R)���bZ��8���f.�,"�m#�.��F�����sb���R\O��}���}�IX���(eV\V	W�����^�TC�s\r�`�~<&���3cz'WX�C�҈�qHr��K�}�$��_{���<%�$+Z�S�'�H0!�n�۔��̛3��f8�j�}��HVZs�wf�ِ`����$dQ�.��q�l��Ў�8{mI#@����8�U�����Aw�����4dc+��K�f�}t+��zc�0����G�4�O�����h�õ��嘑P�N�ZTӥN9
�["���x� ���D����T2�����4D	]�i3EWȐY�s'�� %�!�Qh��e_�����>Ȅ�W(i"_ /�8Q�9̦z��ȹ���/��~�@S��J�i���=�<�m�E 1L�����/G�Uߙ�# ��&cmFY�+�n�Y�^��#:&�j�l�`��W�ϟ<��á`��Z����� q��HFt����7���a9���9�"R�œ���.���vr���mJ��3�5[�ZP��٤��
z��Y��{�S�s�_��i�wI��]9�xv�9�Z�mU��
�K}�/T1
4��M�n@�߷%`�s2�l�oq�e�S3������	u�j���J��/V�ԂƸ�6��3G��"��/�=�G��d,��c�	^��dW��$��ԸW����0%F��H�rO���IE�oz��.w-�a��!F�	��\&j�(���/gg�h���'^�X_���.����]hA�t�"�>�M���,��(&�G��_��e1���z��I/v"5+OQ(�e�@��mԘ�7`���Ư�yɐ2�6��hv>������쬬�5O�"�	���|�P��f[����4|Y1�u,M����[a��S��_��-� X�S4<Xp���$l\fME[�B��fRM�qR����n�3B��4�<�i%gJG�M�~�) ,� ��Y���/�n;ڊ�`d����9�on��g8]����N��\3��;�W�t5V��)	ss�᲋�I��pNYZ��U��QV΄�X� hl�K�����J��K��`�!S֏=F�.쌜%U�i�ڒT`���	�?W"�Nq����ć��?i��2���A':�V#��?�mk�2-W9��F����ބ��5J> �q����R���/ֿs���i�O��R�u�W�LN&*��k`� ݔ��`����]��'��u������孊�B�dT�q�������5̠�a������t�Ԇ_©���J�ps��Ņ�8���>���]l)�$=�!u���5�6G(*]�t��e��(
? ��9�H�ad�'冖���|#|}���M���6����L� A�52/: <.�w���Q���m��U=H��q����
g�����I\l���-�SY����f����K?ʿ�*L)��)֧<��-A�Ѡ�6������1��h	Et�Ê��!���jҘ-)4jOĘe��R@�Rg?�a<c�2J��\��dF�O�|��[T�]G]O��������[�$:�V֪� ��C}w�w�>�ԃ�(j�q6p�	��<�����"�Jq����q�Sq���}�^��ǿ���خD苆���	��њ�Q��W�k�����WJ�8L�/��7E��/����Eyi�@AC%(���K��h[Y#���b�f��Y<y��}E���C$KK�a�-=�;A��@�G��1E��KB�_E��|
I�'�a+���aRa�+c��iܵ���7U�����||�;%Y���u�ͣ���^״�?�/ֽ!o�a�A�(��Na��Y~�_o���̦Tj�O�A��)� �J��tX؋g�0!� ��P}.p�vIݕq\��b��=`]�	�Ǻ�*W�.b.,���! ����2��U'��ʓ���V&܄/]��n�\,��<O�<J.E������N����R>������+bأW�*R M8�@�����
�3��g�q{�����p�V�W��4��֬�ڨ�_�� �K����e@u�f	 �w+�8�]�еk'�$GZ����� ��߮/� �C�ʆHX��p�F���CC�;4R1�SJooy_n�����S�"{/�����]�Χ>��lΣ���@��;(����<��5L$��a���x�Fa�I�����[Vr�� t�L�E%��k�����Z���]���A���5+o���u1G/mPDk)��B��� � �dD�/cU�&��U�Ș�Kg9���
"�
�I��.�=��^�T)
��j���7�UL��>��f�����)�O�j@���O�z1{�l���ZYq�ʺC�������"OR��w�y'1V3\�k�Ӑw��Є�;�-`�1�V�f;��&�>c-�������bM������CEpG���7�\ޞ��qy���3�;}��p�Չ�+ #�8�]��Pw$�?�m���Y�Ý�=SguC�2���n�x���`���9K�)��/��SE	���'j !�~{f�!u�v����Z��V��õ�I�+��K�`�>r���^$���è�mB�9_E����˹W���"?ڈ&͕|�gn�Ⳡw������*�����Hc,ʲ��s�}n�&~SaN ����(�#E�aƓ.�a)z3]]�B'o<��x���i����C�t�G+��E̅oG��vr^�0���'m���e�+>�M�T˥熨5x�r�j;T[��ܤ��~��̚%T���O�*��i�	bL1eFh���}ޔ��e9e�P�9ז��4���6_��F�����g�l�����iڤ���m��*��I�Y9=ŔR��'���`���F"}�{����E�3��L���.5���ӵ���R�0�K�5#�H����5��Ǉ��1����L��U�ِ��I�u�
��Cc�O?��-~�Fq�����tEk0?�.����l��� [��+]�.���v��:�e��+~� ɺ�cne] �U����wӤ����]�����M�[�k�޾ʫ�ܻL��
��m�$X�kշ'��r��`�Y�r	{ �@�{��B�W�����q5�%�_�(bY��=J��Ԃ�8
M
�Z��;�-�pc�����:_�3�=	L�E��o6���%��G}���WXS�X��ӰkX�
>�1����k��3�w�#I���b�&�'���e&�����(`4������L��`1g�2�ʝ���<w��M~�tsiQM�O�� % t������������^���j�ӏ�lS�_ֳ��7�ɰNJ��]��3NV	؍�{��V�0�����l|��g���,�g-kA��4���>DQ^C�����QZu)�fͽWp��fN4�	.�����ϐ��'U9��P.q]bF0�Nkr���{����m4<D)�����$��,�2ǻ�DOc�	'��==���g��umw�^S(=�w8�i�i�[��0v|SU�>���
/��7���_;��lw�ͽi����b+���W%��%�����-޻K� P�;E�g�S���&��9!j���|*P�:YҊM��2S�ʰ6��Z��P{�3�z�oUPYg" F?~�-���Y7��ޚZ!B-<���N�U�iZ)�$�bm4}"�Q�i1��8�������)*�)��Fb �Xm����N4�/�<���m���%������!g������(�6n�Z�O�cܻX���.��ڤ�K"~��\O_��X뚝=�o�鏪�V������eZ۷�2�;wT[8�`���	��
�3$���}{z����,p�}΋��k/�5�<����a�^�������u��%��O�X'4ײ�f��yG����w�N�B���׌�ʹ����M�gܫ�V���%����)=��I(IB�w��A}��� ��De>�R6Tͩ�շz�qj�CP΂��r�v˫�̢ݙ*+L.B=t�m����@�{���%
f�l����Ю��9�J@y�A,�=?��A9��{���e�\fĘǙ'�QYPL��Hϊ^�5�=�r�2����F�B��1�j����������G}\��g��s+�_1%�;xo���Tc�7�m�7�����%�l*� ��iz���ab
�_| ^�������7�,e7�ڹ��q p_���?�ï;�(�b"0�݂q��k �C�F�F���v��4:���=��nV���U�gֱ��ʅ�K~qn"�m��#j��Uk���%TW$�ӓ~!�B*Ҏ�?��3D����xʶ�/x{T�C=�,`��@�r�&ފ�WL�������lN"N
����	�'��M�,[
U�P�p�<1$���v�,�����X�k,�����gq��YW���hQ!���؁�I�����]�=z��ʅ��J����6�'�55k9z����4ɏ�,��������39ew�ܕ�=6�$�vx�M�ꉝa���"�U�s��v����Z���P�[�r�j#���W
m�V���$�g>&��5�P�� �-*0($�����t8M͆�BTϑC��Q~� KM!���Z�~��6V�S��F��l��b|wJ���u ���KF��Kb�[)v� �ʰu�$d�����PR��z�a���*U�MCev5�f�d�*�"�/�2��?f�"��+���39�J܉��mCk��ᅲ��7Twf�=�A�����q:�726�E���Fh�Z��i5sQ��+�|s���W���4� Y��GK (=�#k!���&R6\��_|(��4
-L���"^���;�¡k�k@��J���Y��ݥqg�s}�(S�m?��g�w�:f� E�~��(���?������b��Ӈ&C,ء����H�\s���]�m`�YoH����ҩ
�
�ݸ��+�!3�y"@Gm�T���bp#�/4�q���HT�Ҩ<��G/�����$�����tF�:����fA>D�eCW^Ѳ�����ƲB+e
Nˊ[��P�e��l��R�d&�皡�f5(�.+��e��-SQ����Y[U|���@k����>�xu���ӌ�[���q����NV�]/�v����i˼ss!ޚ�j&\׏���2��jWC�>�#�tI������P�p���h��%1C� �OP�,�;j�ׄ��j�Z�*��+����O5bd׮����ӭJel���Q[M���Ka!��gE�R�쓎�����n��0��h�U�s��C�	�e�LAl�a�FE�;�<�[~����LC���>)�3�^Q>��ʠDS�P:G\k���O�����iK��i�U^Ʈ���i
n�Gpk�WJ]����W�q���������x����V�C�Qe�|�)hq�����ષ���>�؂O��/�ۀkHy
��U��m�����4�6��xӒz�����1���w�xF�Phuf���9x$[������#��ꕱx� !�%�û�%�7�V���������㘎Y�T��*@B\&Mi?��ȍ�_~�>:��c2��]�%e/�����m���u~���-	����l�����-
A��ŵ��	浓QK���l\AM��v��p��0�7E�H�&�{����{	'����W{�/��<L�9��\���_�e4��=j���)q:U�D�#l��d�u!��y���vS%p�	��9�h_���$�P��l��r֋v��D�nGх����h���l��*��H�� ���P�3>kw)8�	��rı_R�7��O���V�f�w��*'���ߦ5|b�j˭�J��1�S��C��䙖����<�����'RܺQ��s��"�|=�����`�O��ָx�A�y�jߕk+�Ȍ�0D~�`��X{��-D���� 8�3��dH|(;�*:�|e�<$�&A�������^�@�Mo�،џ�1��A�	�}r�)E<l2���zP$J�rǽ���~�	�z0z�{�`�$�=֒ X���e������g&�![�NH�K��̪v	�����Y�_�K���+��!�?�EO���D+>�[Xf)]��s��n��&t��,J�ɕ,B���b���<��x��	�\��|���9�-����E4��qsY�U�s��L���z�z��sr��~�:A��k ��d�m�I�����'$u_5�q���8��z�}�g��Zgf�'xD��h���� 9���h�?����p31�۬�ws:`���K���']��"�����Vsv)k�,��K���~��ޠ�.���a!� )��u�M88|�^�'�ž=����ޟF���M��M�a��H�aHNY!�9X��E�U|�=#�Jɒ���1߈��,��֮�E������!D0���"���$�"s��C !��s��IVt�v����?
�W/��N������H��� �V���\i-���������'�H�� x)���{�����8u0΂����P0i|Z��0���̶v�Td�����A��e������n�"{yB}�NZ {#V,�ZaC��!ה����h؋����J�O,��nn��N�w���H]���-���4��2/�
��0�s�$�� O��Ƨ�#n�4�����	5��2{|���Lq_�y��*� 	e�æ��w���t��l#a�ɀ����Yi=�x�V�P�Ql��b�-�ϸC�G��c@�-��iN��3�=w�NQZ.zM�bs9<е�:�dk�/p���S
��P�I3,=��Y/.��k�Q�_&��ܟ�.Mń�%1�@����6��cx��_3.j���KP��347�m�~�j�`�x�l�3���ۂ�}�3��v�_�&obCe[&�{�V?�>�Z�AAI,D��݂���?Ң-
�%��ѡn�[
%�n|��2��f�J�a%[��g`�i��&l���	��Қ���v{�]lI�F����u^�Il'��������*ml�w���H�����L����]-ADz����`�&�<�����2����c�#lj���Smx�3Ha�*�P������PTۮ���(�����sU��:?s?K�������S*�\�ǀZ��6��k�?2��Bn�&.uH1 �t�Hc�کz��zU��)er(/Y �_?l���~���u�*��/�)�K�+0�R$(�j��5�������_�<R��Oh���ذ��]<�a�4���ּ�ڧo'���IL�X7�`g���hbN��sK|hT���27,z�)��9:玏6͔�Ov�����(8e�`�W�$�Q��&����5:-��ͣ[աQ�5=1$C��:�ཿ���4�{{7=I�vv>��][N�hk��E��S%h�����@b���|�|�N~������O2ms�F�9E�Ɯ���cN��*U��,.� n#l7W�L1Խ/)r�ռ|�Ⱥ�RpmȎ޴	\=�Fu�:vI�@u�t�~�c��I�H�N�;�u�p��#͡�����}��=����+�zC�B����_D� 4"Zgv��-��x�������4���穝���$g$��D����6я:��S�!( r�4+@��n���a�9���!�߀�����:6O�c�X����tV}?�A0�|8Sje��F�yp���z�	�xҞ)�N�<���B��58��T:�|J+ñ�Zl��<���TS�#P���ke�1�}H�������vB�ˊa@%}���8���/?\��u�}7����Mܥ$��j�\PX�?$\l��A������ȥg�����)@���<ף~�K졭�@@���I�gi���J�n���O�Ӥ�b���(uw{I&�^��'�|pb�Ng�>�Hp�h�}����U�PX��LxY��/�7�N!��)C��*X�6�R�FD��W��ʛ��tZ�뿾��=Q{��g�*�;�65���HEdB�c�z'� ��ԗ�N1ua�o�y��h��/:u�>���bW� ��>���煮;��c�Ο�H:�w��Y٩ cC�J��"�/J�Ј�at�������-,/��2�B���6[B��vh܆S���0mf~"'䣼�z�k"��Qo�[��E�r���I�������
6*3�yַ�h����^,j��>�ڟ��	 �ժ�����*&?���"��ى��8N�K+�=J����:0,�ҵ�s|�,�� �*�-5��QҚ�����)	�5�1�Hb�=r��^l:��#ñ�Av���r5�NQ�#���c0��[g�c��9���,�{�-��5X̽���-)#��=`����9�]PU�t0HE���:?Ð�[r7���X/Ԏ% U�0�z' ?�s�dS|�7^7�#?a�5V�c��a�@%wt�RiZ�i�]c8ٿ?�	�]Z)!s��_��c�P!��;��#3����C*�;'֒+P��~{�R��d�8i�>w�����_�Zy���oƶ�mh��Z�3Q���� �4��Z��=ս�2�<(���p\��kzFo�^���Cs83�=���vQj�,H�?�'_�d�W���~>ʙ��6iy����aK����q!�$v�����Ev�?�}[��&8��?�M$�@R�ٲq��F��m�����U�Y�"��9��W�Ft����d>�Iu'F? ��P���0陖P���'D�-C&��OI��0ǈ�J��5h�|����|6-��_�|v�Ń��>�h_{����9諞����8�é�(ߥM�@
3��� �I�I������`0�i>�Ǘ�g:?c�6�r$(�9���-!� Ӳ���,�*;�kw���8u(��\z��_�oq�X����U)U�rNjZ�9��P��������o�)��1啀鯵P;�&��:�_!�W�W��[�ٳ��ߴ�n�6Fk�vG �"�Ѧx��t�C�j�6�޵�=7�}MvF��9%�&���
!�e��q��V�$b��+��Ey!of4���NWЁ�C����)f��d�ó�m����1�n)��à�m{�@��#%C]eICr?c,��VV����zW�/��-�\h{��XA�����љm��6��I6̳���y����ӫ;�e����سׄɾ�3�f�@��B��;�.@��V���c��ZZ\bG��l(�ØT��/[����II��a�G̅CQ���ZI�q�4�����L�2�u��,+[��<��D����%\�/6T�#��[�9s���[�kwX!/�o��a���aQgOr�Z�z���fPۖ���3C�p�밢�u�.�Ӛq{�Z��'��?�I������	���Q�_�G�n���7(�6@�-��Z����y��rüI��@��j����nןL�`>��2�;<�Q�R����o��0@X���Ω�	g-`���L���@ц���tK�f�eoa�n~�a�A��9��q������?�b��:4n5Y��0��/4�}�fz��i���/���eÎ]�W�/�%"��l�� U������d��Գ�0���\21oΝ:#�r�7@p��n�bQM�);c�iS�� �4W�<Hل6��]�4�sp�O^��K��G~d���ʷ�?%Y%d����&�|a�Z �'��p�(���4 E�Ko!�$ 8{����#��X'�8�Jܒ��F���9����O9v�u������;5��`�6�on�}O�l�V�w[��~(Q���_�w�l���9�Z`���6e�ɞ�y�ȁ��%�O���N�������ο�Gl�--w7�4Fv��V���4m�`�p��o`�sc�.�Z}��Wħ�g7f��c_&�a��c��V6]F̟���y���i��Y�3_�|7^Z&�ޑ�J`ZiP%zܤ�~�B��E�u`g��S=���S[�	g@�|�t=jZ#�6��s��s��a��U۝^��p���Һ�ks#�S��d>�,[��(�p�r�SJ�ބ=P ��%�L��:3ǧђ
��Q�-j���O��:��i��,�B�=��$#ۅy~VvNb�%~;4z�QK�e<4�m|q)c�5���݃ӧr�̆�h�Nt�P������S|Ѳ��dJL6v��5��&�J���Ϸ�+ʾ�pCQ4N�uU!HcF�y�oҾd
�a�u
!�j���t��DHa�����F���JF9��M���@\��ݪ��1&DM��W���_ϽF>��d��0���|��.`��8ZW�.�����N��-�i=߾������	�<� �����`�Ԭo<�j4�Ml�[�~�i�����Dk�l෢-�O��D_�V��}�
Vw*Z~BZ���!�>8]O�#������&�=�ԩ�qװ���<��Z��fW�<�n����"�b��t��&��o�իt-��i,���>���%�Ǻ�-��@�b��{,}g_Vٿ���9Y!l��͌Z2���G>oF�R|���O�(Z�e�S�b���:�
���� )��lV��	�4"%ب�$�'C_u�B�� ��i�:{c�*=���B���a�Uy�^��!JA؂5�`SI�ٕ���7����jJx��Ơ��T���ݜ�ðԇe����nQ�9�v�.5�*�|Y����*����}}W�;Ԕ��<��<��q�Hz5���(g��;�0�ڈ;#�l��2S�c��[�/�H��O���m�HX�-m��H)�X��Q�T�		%q@V5�V���8�p��@<�q�pOig���8r;2\lȮ�t~�;`��w�^����!x==?�l��[�R��Qi�	�rm��D�a���v�C'�JI�."��u�o���f�$v/�B�n��[(�f��'�.^���+���{mH*#MErV���\��{�Yi��Ϝ8�\�WԎ�+�z&�G�

o&hF���8dڿ$��@�;����B�A���Y�A-�f�5�QqqN=��"���a���EUv�.��չ4�4m�@
܎��ٿ?�2�9:�g�5� ҄I|-ja��b�z�w��Z��B��o��]�R�P*,��J0r��}{���\���#��}��r��qyl���B�X����[�W���:�v�lp���t�~��@O�355��ی�x��Ֆ���*:/�l���3�ؽ�)��U�c���q��� ��TpmK��.?��z�5
��h9WlH,��&�X1%�}���.�U:d���n�J��f���L���9,�eFJ��n$�tUp��.�ۼ�nV��1�k
�O)�+J���ѧ���FS����-\��G�	�'��#8'49NJ_S�_I*�l�;?5}�,L���j���W:�uMR�t	uAs�̸���T����7�U�. �d#d'ج�Q�y~y��ާ��b��9�/O���z>yޟ�]���-�q �
�!4(��N�/{iqn���rA�K(vz6��������"�*:�~�� ٮDD��L�҄���bݚyliszc/ ��}��`ې���\].�����a_�#8��o]#��˲�O�����!�Q�|ڇx���@�{vp�3�*5_a�x��0��w��:?�{�h"|y�8�yt�T�[&e�1�-��f�@����z��#��]��4�(��ކ�cC��i
������o+Q�2�O� �ؓ�5�t;�u��b�x��� $�N�d�Q������#�v?y��mlKLO��V�������L7(b��ǖ髳b���{��^�>�y���w���W"2"~v���w�˟�]�Z���N��ӥ��5T��P����Q�a��O`�5�˵��؋��/���q�r��k{�.V�M�Y�8(� Z�R�6��f�a���J�c��3����\�\��`��ŞMQ�(Ė�dR�+�H�]h���&�+��:� 5�⃫@���apW��3�ZN�R�J1ւn�H��qEO��Y���@|Xfi%�'k��=Jl�S�g�a�+�f��W[<��DF`�]o{3J{Չ�# ���d��!5�B�a��Pۓ�P�#��Y>$_a���]N�0μ��ū"��&ι�8���+-��*Ӯ��<���\k�i-�ZK�>����Ds�+��Y���o��_7������D��T��~������o29&,i��N!u���R���¡	�	�-�E�t�?��BI���'�9n�oi��s����H� 'G�
��i.�أ)�^}�������H��U��}�|2�C�U�[j�$�7����a�� ]�����I(�/��v��%��Y�_�Aj�| ���2Ǚ"'�a:Z�r??)p���ǫ��Hx1�M�!�S�̄�h(�˚Fn;:�����3S�N��O�&98��~:5��b��S+a[oY�i�]�G��0�MGb�֙�R��[@p����;:Q�U�w���>�	Q�
S�U-.�O
l2���.����ë@XݾЀ%NS��Z^?��� �e�]K�֟�ܸz=��imCHP��׻�b�����B{����������^�ųШ�10=�^��!α;e��'wx��}�ڇ���&����Pv�B]�N|(���b<x{��`f1�n��G��*Q�Q�Z���1H�Z��]��ѩ0�[��4o&fCn�tw]#�`4Q���Oe�,��q�+�+��窝ڎ�]v[+��3P�L�����4�F�af������?>�Tr
��6���k:ށ���b>�#1'?�!�|� g�6�7-�/X r�ۣCR��s�,C)X�T���5۫(�'pH'���+Ī�
�
m<X�z��� ��6=��KV�%o�j3�"{I@��i�-!���s��Y�ʏ;ע2�U��T#�K���@EJ >gSL�b�:��Q.�"��hg�O����TE� C ���
��lhmū��3
��_"o��G}V��+
_�5tH\�i�'q2O�̔�"��M���A+O p&w^�^a q��H�K9l�'0�"�,$�z2>�M����ߘI�(d˕ IB�����s�j(/��h���>~JϺ�G��lE�z�O>ֽ30]���^U,�#�'-�>��.�\�U�G����(�3������A_��(�=6b���,��~hd�����c��b����|� ���PΕ�CD�+9ia��Pb(��_�8��< �=zM�E���v"`�OC;��dUV�d``1��h�a%Qϰfheu o��9wϴ�2]5�)�ף��[7���&��;pI1� k�Fzc:��p�>�$Q{3Z�c��2����@@:�,�x��Z͉L�����|�c�(fX�#/������C�с�����O^�,t�e�s�`�ܜ:[�cɗ�
���-	�%?UƟ'h��n8˵ᱍ��˅`<  ��3E���)�s�8�S�d<�s�&փ>�F�pڟ@�pzb��0�fo��v����@N9�	��2�&3z9Ͳ�u=��:6�#
�����r��x'Db�V˥��Q�=M}���{..0��-n9�	���� �[�;u*Վ�6V��;F�9�I\%���>�'�|�������/�\p�~��qe¶���Q�����9�!)զQ��#k-�/�L��O?�N �1�z�rp:�,��d]�Z:|��)��P�8_�X��?�׻�x2U
���h)� �)Ɛ��sJ�y#�&���Ȑ:�]=�g@@��d��ʟJD����;�7w��R�)}�d��SE�;~2��cꜜ�M���~%=�|{�{/�ɵ;�1�ٴ{�~A��(�����E)?"Z��4� p�����$���zJr)���/�/��DO��YPۻ|n~f^f�e8�f9'E��Z�<,K��>n��~d�/�G�l��P�TWH��Hz�z�������>B�Ia�7�R���ٵ����<��6��i����N�IPϏ�;�_��~���r�N��x��{2�ټ\i��Dl�3�	������jd ��#���#��Vq���QE�z;�	[�W�������-H���ҋ+:�����p�ͭӀ~ă�z����X��c�(z(��wvIЄ���=Ken�g=I�q
&�;I���GVq�B�)��&m�* ʔ�L����?��*����dC
���eH"�rc��]����xPY��8���ù�OO���rb�ŴBQxq�p�5H�)NbC��?l0�'��0ث6,Iw��Z����`lX��R&2��1@e�[��_{33.phDz��fsV:�[�!��FqP�Z�����m5���!��;�a�a���F�����:y=�b	6g7���>�-��/߄=�Ub���걧^�`	z�T�׭�9j���Р5A����O�j�;�=���?XNW��&=_�����#䮍o�f�)�(�L)Zm}��{�c:�{�ZC[�3���D5�����ѵ]����z(L4�T�����bnI������F�&��Пzŗ��
P�R�w�@sD/sF��xg�  y��j�}� ����u����g�    YZ