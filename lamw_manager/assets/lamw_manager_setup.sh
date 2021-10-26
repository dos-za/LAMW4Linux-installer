#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3299787177"
MD5="c30f2f8b91916e86f56111ec2606ba00"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24176"
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
	echo Date of packaging: Tue Oct 26 00:04:08 -03 2021
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
�7zXZ  �ִF !   �X����^0] �}��1Dd]����P�t�D��R^���:!9G�4�HP�wEe~�,-j��2���Yҵ�a���Ǝ#�-���Ԡl	���]��G���+�db<#~{9k�Ga�D�o��$M��t>q�2 �g�<�9j�r���t|�K<@w�����?uǙ��g��垸|Q�ɣ�D�������Q�L�%�]�\�B��3w��ƂzU����Re�γ=N�=���u���$���~o�bd���܎bnң���g|lT���-��q��L��,�Z��4 ��쾼}w�Y�M%PY������(m�[�E`y��� �8b��G����!����݉p�G�������ap��N)Y<����&����k>�����?�O.�돞T��o�q���#����Zs��S�+�1�(v��C,&�B�4���W�gO[࣡=-��-�zV�>�e�����/��	g6�Kwo"�-�`����jͪB<�uW�e=Ch��Q
�B��7�-�*ݕ�y�n5gF=x��z���'8rS�{�p�ͽ�D��܇y�;)��K�K4P�^����cV�6@��Z�f���f�'�u� �q^lL�v��,s��A5�X��fxvܸ�WCx��8�`;hv|}�,����pe/h��KK"��]T��(��p%ힹ�S��x-� s+��.Q���<�U�SX���1�H�}��*��c�N����v�wՕ��L�%Wd�y`�\Wh<J泪�˂=�l��������~_j��!aG!{��-��:��@�do�?T9Q[J;s�TN�$]�=r�M-�&x��%����5Q����h�Y��l�\9YiMVӊ�����v�ճ�L����D�!AJ�lyד0���b�̾|�B����\)��I�UƄ��y����t���>���+� V�.M���Q
]�?����vHeZ�.��'-(y#_��;�� �J[����s B��~��0�'彌h����x���m����K�J��8�ð��o�xh-cQ̘6?�S7�&���a���t��C�48/a�Z:q�!���u�O���`E��C�H���8@<3�Ty8��1*�$] �=0a`���6E��4����m�;Z����$�]����Ώ s�BR�-�C@ukb���OX���#S+_!��_TI.�a���/�I�ZG�����]1��V�[L���l��ør`���@��v�}��æOek�ܩָ�N��Ҩ�:G� m�{���>�v�MM��F���:�a?\�ɮx�!�m��݋Vh1יOR�� /�j���xG�Lb�� �����qߔ*�{�6���y��H7��J�?��$G�*����OCs�vd�m[Z�պf�p3\)�_
��-�;H�FDb�s�6
+{I,��0�I����C�Α\wF1��0��2�XJe�$��8����9 *�����3�3�[�����.�(���rBZ60s����v��Nɓ�� �2W �]�Ts�1]Ըs�*��+�͐�*�I Ʈxe`�5��L���<�sl�ݗ�F�,k����3?3�4������d��T%�8O�pi���ko�^A�*`1l�\���4[�s����̱�@���V²�6H[��M���*��Նͮ����Fgx������]�f�����g+
�8P݃-e�L��<���ALC�AU��r��e\%�;���,o�@���"q���w�8�X���k:��W΋��//P�H��m�޸C�i*Gg���&��h0���|���O�N��f���Nq�g)[�7��>�&Z���ko�:�{�5�Y�����X��3V�,.2�̋r�FG�)�.�s�V�i�k��H�\�p������'��[��N |���'�a�|�\I�"�`3��(���b�('�����PX�5�J��1F�UVC���~|�m����� �]�#p�N�Ƽ����U����]>�|�R��Q��7�F�KВ�ޒ|T�u�W�Y�̓�����{��BR��p%>����SrƔb���f�#É�Y�)p�v�
t��0���ՂM��bf��q%?���+/��7���`n�4Ut�buZ�R�'���2�t@�W|�pz�9ͯ|�Fg��'O�d}�]�3������PY����+зs�c�P잹��4Q(��J�QuIr!����J[&�I��1��3̔�8?�mV��!��1���҆W�>�z1Iڧ	�h��B'�ۅ��_3�@�p�E\}�S~�{J�9��,�]z���@ b��,Y��.����ӱj�bU���e��t
e0�ZS@��1\���3Ln�� ������4ڠ��VH�tD[V���֠��ͽ����M�؋�"+.�� �n#���}l��J-H�b���7�
z�6�T�����F�l'��O(���c^�o۱�&fQƎWV)������e���y�W���kU죳�㳶��e�N���	�0����+�X��;=h�G�8����!I���{����k@��=?~��.�&�s�t4��D/�TT�90|���C���ԙ�>���7}��}���K�S�y���ǉ�#A"s����J���"Ն��*LK��������[��_�;J"];��]�j�w��.X�YL�����)�@υbP�u�".�B	i�S� v4υ�N9�.q.��"�@�t�I?��L �8���Z��_�h�������� �uT��IJ�Ijv���� Z����Ems��#D(+�.�;��Q힣v�ǋ;6Km&���/�7q�כe�x��oچ�..@�����i�F&����$���Fs��#�X�{,n���v�?M����~)������&�ցD
D��;٤��z��������������E'����'K�G�>�q��ý�[�z6Fo�DO�A(���#������A2x���i�'�QK�^��k�B����ڗg�(L�k"|ϋs��������}bp�Y��ߪ���ovB-u�Rs�G�Ї	x7f�?��X?� :��Y�L�����qea1�?(�	T�~���|�K'���El�GN�.��v���1<���˥��8ud���\��옦���+Z��������@�r�J��?s���j���>�ё����*(nn1��j軤dR{�g蓟�N��E9���l}+�{
��&�� ��ۅg �D3#�f2gcL�3�)�+%_l�V�OG>�����R;����!
����E���W	ιǉ��d�/����<;%�q�
M3�v,����n :'����@_����j � ��r	U��\�^B�?"����7��T-�$����=������>��Q(nC��OOM�I�*T/�*�X�	�c�j�0�������uJ�O�gw��[J��8F��]_2���N ?���B���ض�����J�{��:��Pwe0O���A��Ob
���ךA;�=�n,��Ymƞx3�a�%a�ف�S�Rp�A.2��d��!���yI��ۋ�DH���x΀�䚟�����bw�����wBAz������(�����j�(�ǻB\&j��)J����1���ǡQ ��]��b�1��6:k��C���Cz}	���b��8���s���
��Wt��� ��!G�P�-{笀�!I�u�`�>�(� �F�8 2X,w��R�W�y1#ߊ�+±���-�c�n�ՈZ���j
J�����yi
p�����;-v���=Tz`bP�@��f�Q'sVC�e�kF�-�� ��NL����IyQ|��iq��.VKI@B�y���b��V�о�$�vO��|P{/�<x��-��R�P�m�1'j�9�<����=���:�.HW�1Վ� �#�2 �
n2`��cS�љ�w��r��?���֓��	��x��A���h4hE�D'�ㄲ͟���z�	���%�qD�5��c���Z?�"�Lo��-	e����+2�w�d�tc�5'��97�pz��>u�R���?���~ϊ������U�ň.��8��E�m뛳�d%	]�y��lTI`�I����w���2@� 
q���8W�_rd�t|2����	��rCB/r����*�	��` �,o𿮍���n��}�u WjY:v��
��lʎA�"��31ۚ��\/���8pZ^D�	��Mk-O��o�A�q��1�P|��C�!쟬H}/}
�pe>��:c!�ϱ�˽�RM2������j�Rl��,S`�R|�_=��ʐj�W})�9�1'OeMP�� �KV9?�B�������8�$��Σ�~���:	9&�lT�S��rΦ��tP����Y������ f��T�*r�<�d�(�5���H�Q@tL�㺩�uQ���o;�WxQ t����W��d�#j[�L�r���]�߅0�Z:T�ÐT�F�D�ey��ȟ�%v%K �C��s�V2S��Ţ1ǵ��]R�Vg��	����x����0z{�/^�8��̦�h-;pʮ@���|�i����}�~~R�C����Qf[�C�Z@��,4b͟d?��N*���1�Ϩ�t�ת!��z2��@�_qIbLZ����>n/�j}�0^��U���������P5mDT����!��x�k�����7q��u�ل�a�T��L��J0QA���>:��Z�5q�rݺ�<��T&D�ItrJ1�+�L�O�,�.��ǻ0��#���N�ei�!11ߩ����as�m	Uu�>ެ���b��Q*F�5�y_��<�w$�YN��1n�[ϰ�NW�k­���5̘�j,� ���,�w60G�YE�.�j�v�S��� �TF�!!�-CL�X�GP
���˾�>�<��E/�[TJ����H2ْ��5���`�7>��{�@�>�O��2d�D���QRl5����k��Ʊ��k
g�!�l\+�Rh8�C��tJ�۠	�����qQ�C�b+�8�E[૾o[�i��r�6`����V*�z�!�h48�J犰��N����X>�&���*��ܦ�G���+pjD5��GQ����%}I;,�I�뜲ˆ��6��ۭ=c�f�oiZ�1�"t��I���V�����6�&�Q~4�M�H��F�$0ix��@kk�DE�Ȍm��l��׃L�W?2.=4����lU,�L���IM!�|u{p���1{�,�\d�Bˢ=&R�uwg��H
��n�x�Lt��P<���5�qB�ÃP��6��
�6R� d����<�RJ�y����p=ﰳX�Hc���I$Qe�8�u}�|a�YC"!5�z-x�q�	x����m`4�2N�!�t�x��-�{	�<�c�%�c)��U�*�M!M$��H���ԫ	�����|lZ��W�_����)��g͉�^H�n�����I��Qc-Y�gI��3��������>�Ź�E�D��%VV��QLv?����4�o��ư� h�Ut�K��$ʢAԳ�=�bh`Qy��d/�W�xB�q���981�}�wЂ	�C~��L^���4�t����{�kv���1��� R�Jsl�/Q�����c������@U��IZb���������2����w$`��8�++syW���C�w�R-�A������_L@�Sn\�hly{����I�1�O���o�r��Kx3 ���^G��������~���˨�^�\zrNM�uH~ 	�zN�T֖���8[��fv�4� �olx��Z 2�sz+�^(�m�����76�	���ޒ�SN�2qT4Ĩ$�+i�oa����x���6�.#J~|�/�Nq���MD_׵lY��X2W�e}�O�9N�"�I�o�a���׻��������T������*��� w�_�����X'I��X�>����=S�!�uؿ�0���f��ܗ]��Ra7�3���=�U�{��_x���aǜ��fq�.=����8�������#��2�oŖb0R���Ue��sϼ�Jf%�[�2�����iL)��̾�B��KG�[��fF�7�M�EWǰ�C��F�:C�&��h-�s��Sѷ
��?��N�b<�|��A ���j�e���&#CJ:�$��0�c��<+P����L���K�+�rL�Yhu�m$��x�:i�r��>l�?/��^^�S ��Qȃ���u<gρը����$g>+�
2���ˍ�76S��j������&WՍ�W���0���r�<c�zϽ��{�h�uΛ$�JG:NBI�{�[2� �e�����ͩ���pU���1/99�Si�I��uѼKIm{85R�bci���B�B�zB���LJ\,Om��@P����5�˄\�r׻\�.+�=[�#"[#���wZ#��K�S��[r��G*~3���?s�[l�"I���-��/���<;>�����Ai�����hg�3�-���Vz�R�q7�m��Hj�T�,³$���KcL�ߢ�j�r����M�?�B�^��2%Fw��o�C�������ݻ^VS�N�0D�Q�^�~N8�p���>���j3C�8Z���L����:A�h�*���_���K4�WeûT�?y��o!)��R��9p�6�����n~�0��Y�q�8{9,�V8�h���e�<Pcn�����~��>"��)� /��=�@w~R������-H�d}X�������C���>O����?��~���oJ	���Ğ� �;��`mz:t�'ƿ��h�K0���4��`^~i���0� �y�i��H�=�ֳV�/�;�'�vB����U	�^:��չ����=Q�G���a�_����;.��$7�a�f�Ģp���O��tbG#RBݬuݶ:��A�~��Nڇj���%�;�7B���ˤ�ۯ�p�<ή�2߯�/��9�Rc�Ԇ�=�e)�Z��3�p �O8λ�����l����	��T�D�Y��Wы��.�u�s���?�1I��ЈJA��ƨ��͞7��ވC�h �AK?'�L|���-ϡ�R|��� ���J=�,w��QD��&7o��Y�a�A���Gw��
�y����*�!�Ka�.]k�nZ\6E)�v0��R�)<;.P���;���u��p$��c�����.L�"`�Kҵ�
z��Y��r�g2A��u�F=���o�y���k�Y������2��E}8��4�&m���@�����tz�4��c����"u��I;Kb���_�Q����6��r�y�X4��;',�p�@/J�����Z�Ͷ�B��fz�P��ehsF�L�4W��鸋`�������J�_ ;���R����篸X_�+����_�����H&g]���
x�������i��W ��D��)�1����0~5�d�:bYd��3��ݢ8/�LT�)�B��o�?j*ư��� �8�tʣ!䝃�7�.�c�1���\�/�;��\��TҜE�鈪�0B�ָ��\��*��t�k���{h��zy�emk���hK�T&�u���P��ߑ�ZΉ��3i�T�$���W���/z�����n*y�t��V��|�x ��iZc�U�4�0�;w��?(�DA�b�"!S��#��5@|vF.�/��}�tn��Y�Ә��?�x&�%�C��/�(�� k�Gq�M��壀�P�P�x��Џ�8��tƆ��O�Oڡ�ϔ��7�^���&�u��G�	�|"HF�2j�TY0�xہ��^��Y��8���f����kQ�G#�PZ�d���b�I����^pd��;)����� �_G�Hi�_��S�F��1�������!�����O��&?�O��Y��$��:�M�������%N*����f���s-	*U;ek	!�%J��b7m��Vbr؆s:��ey���� ꗔ�3wߋ`'7�Ar�Y���
q�b%��P��$����)�'���!]�K��K5*k��-l771`�U�;����
d�}�ݻ�	m���.�_���vw�+]�oQ���~�W�x�#`�&^.C\	X����L�as4�v�h`3�	�2k\K�w�[���:���n��|��I�/j��J���F�NV��o?D/=g���5&�ʔ���9'�'��[�!q���B	{ ��|vg��Yg���Hm���֣Wbc��7�x8㣒�%x2󛏗�rJVx�6��9���;֚$���M"��TU�\Z@�ܹ�yO���v}z	d�QTR��'�kJ
� �ZO@��) k�hh���8������_+�m��~�+�p�a�� �B%�n����e������tvG��qUl�xw�m�Q7K��#���>�v�ᡧo��8�� &�������JeI�H��0z����e���8@
Tw�Zg�$.���}$�A��������u{ܬ�ŧ�I
�"xt���L�BN[����O���P�Io���(EX];���w
Cހ��9WM��d9�B�\C��
������F��?��20��ҫ���S����XE�Z
b��4͹Jkt2�Cݭ�SqU��1Y�'�ƚ�w�r�����~+OL��W��B��b#m�����.5�'�B����.J����l�i %�i�۽�=�6�>L�+��*�K�{�	��<����k7�?х�����~�}��"�H���̔ݚ����*x��Lo�͎��pF�`������:@�s'um2�{�T���S�w-�f�a���l�Q�`���=���]���6�����O٥ׄH��n-6�-XVVi�9�f��ו��ұ�_��<��A�u�l&��{f���a�(��Ia�[�]�@�AY�
�4�x6w'����Ԯ�YC�9��\���2�Y��v���Vx���qE�2Ͱ!k��@�k�$%2צ[�w�ۯa���%�����5���L����=Rv��Kxu@3+�r𿂙�d�s)��9=�ZW�ļ^sm������ܿ�YUwK8lg��))ɵ�K�X��p�����aϮ~��������vAB��x6K�r��&L:�����	9,<��K�D
G]��;[s��9G���6.�Qz��չK����%�����O�>�� ����t'�R�A��|#�]�B�f(���+��cw̰�(l�βd�j�G��JǶ��B�t���~� ��e��`�8Z�/�n��U��(4���/�"�V|/�����y��-�������E��z�UzȐ��ӕ�M���G�'�ѵ�,$��%U$�=�jPG����.���K��lW��xy�~��C���7bSN�1��c,aZ9F�y��<�3�p��bV�o����*��k���C�U�1�
7g��q�@$�ۑ. ɀ^�u�oEUh��K�}SX��\siq���D�D�2��q�Q!O	պ��ʵ��#Fk�Cv�ͯT�.A�Z8�,}?Έ��� U��x˙!��E���G�$mjG2���U�z���TI�_콂�����N
�~��)Z���33/��򶓃'�Fig��l�E��m��v�=�^���4�
f���Ԅ %%��T�txًY!�����v0���g�Ķ�������� �+��1 6�*�y��ł�&����0���D*��&�/�fYڡ�9Ƒ(C�hj�߸�m@�e_�,2ا�9 ��l*Ig����������u��,{��co���y=�K�?��~�l\Z�Әd}0�[�Ǌ�9N���;Ɋ��s��Ǭ��z�X�Ĝ��x8��F�O#ݢv+��e&�s��cm��i��q��@�.{�k������,Ow���!���y^�>t�WzX��tHpQ��d�q��[���n�9��\�J*�ji.���qe����Bt�{>f\�BZ��f��-������n$�������}��	�5��u,$��*scS���K?�'OD���Tgʐ~���>��W���fߠ���[�Xo��B��6,����t� �gjm�e��ʏ�A�:���|�@am�h�.��5�nH0�]�;�B4IE�/:���t��|`,Zn���]VY��'��UU�I�G��(t�Bɾؤ�2�N ژ֋|�S��-Y��<� ��_�==�餫� G�v�ـ���q{,X��Γ��M�bZ�a'Iގ��Ӡ��s(�X����u��Q�2���6�H.t�>4�~�0��ģ18�ć���ZB9�K�d����s��z'RB���*<��r8��
|5�4�`' ��a<�� ���t�C9��n]���P���S�'z����7����s
�$iN%�����OȳE����@���h&��v�ӵ.�/��^�����pU������s��^D�����9��̏�V��]��k:P�A�cƔ[}Ʃ���(lGl�f��ҫ��bgQs��\a��Q�%���������v�5~��b�� �Z�Zs5�ȸ~c���7����F�M�횔��Ɨ�ٴ?Y9�x��a+|B�C4�����s���P��GOT�Hz�B���$d��p��W*�$߇gQB~65|΂��=���R�������[7�W���*��V-d�w�dV/�C5�L� �@2ls"�\ʲ����p[������Ӕ}��\��XsI�[�����z�@G���??�8|��*q��N-��6Q�1_�3tCQ�8Kr{֞;D�9��ܽ�[���40���xHMALqOף^��m��EMj�}�@]��v� :�^��{���r�yN08p�xD�^���0n��Ŋ�3���;��֡�+ǅ
�zl�*�"�	z���[C!���-��������|�ݜ�!���˓j=�gL2?b�ސ����#(�����n N�4U.��"�Q��dͻ�S��q�OB�@�zޘ��&��"#�T��5��4���O�'��T�Ƞ��]��@�"NFT UR��.5>���5ãz� W�K�m�I*q�U|�lK�Ng��8�j������j�)`��>���J$Q�$�R̻�(We��9j1�@C# I���nK�B���mL��:Gh�Ʉ{����sg��&Nc�P�..&Gx�x�Q�~���z[���wdR��y+*��|jFR��{{�ժ96��n�>@y)������C���{�oT�|}=s5kġu����S��Qp���랟��jڒ]��G��|N֕�Kz�	��t�D}N��ᜀ�I�'�K傅�=��}w�����x*�\.W-J��rY,���|�Q��)��u��f!�b���BL�(�%�*j�W��ag/�2�'/���cı8�2��ړ'��֤\EN��|�����[��
��@�}���d��ha�i3���@E���?�*&w<[>�=-�V�_�-��T�ŷ�n�xt�A���Π�#i��
��$ [�{,���p�N���h S'�<�n�� ۠�;��q��{a9��s�	���9��ɭU�j,wT���Z�� ,.��n�gZ���qUJ��Y�(�߼�iI����;��]1���Z��R���[V许�)t{��5&�����t?jY�x�q���	Sz2$Ͼ�y��8F��T��p�;�V�����t@u���O5�v�x��}ބE�z�O���2�n��Jd�`�F)G�fQ��V�ꔵ5~w�c��Ȱ�x0���_���m��\4G9��$no����h�K���B��Is�.^�\
��,l�M���)�E����biwp��y~Tm�7y�����P��_6m��	�V%D�SG%��׺�-X$�#���P}�Ok�醱�&IW>�+��(>����U���Ys����<�4�>Kx��< ��{uw�e��@��l1|iA(,��I�ok�>
��`����x�����쯮Fp�y�xvN[f�}H������AZ
���CY#���א�Hf:��V�ޝ�Oj�Im\��H|ä�zߧ]6��b�\��Ou��� ?��a��g��f&�F�[���˶;��me2���a2zD��-O��u�ڢXܬꚥJٻ@���D���G�,#c�i(=�_�fMf�zZ��,�ظ��C�J?M���jmA���uA�<���{4��y�b�3<�!�Vx�D-M�6ؼP���Fs04��	o�
�pf���j�+I��Q���p�<@U�)���N]��)Xa�<��WU���
�9����t�N��n~�3T����}�R�w#���B2:�?���s���YK��K���L,�u��_�v2Z�'��4��\:0FR��
���Y����#���bZ`O ��G��\�>a�
\R�o6X���� �:[�<�S5M q�gC4v��R�~�}/��rj�&����:<����g�h�j��ٍ&h.�걦~qXj����n���Qeע&��KWa�C�4�)�i��F+[�;+b�o� dޡt�V�θ��C��ӂ���<�α��O�4�^�Isv��M~&u3K|�SK�Y!0q�P.��� �-s���� 6wmբ���^T!#9�2� ��T}�yǆc�H&�k=^L��NpyT��f}`{�I�Q}��#���N��n���J()EG�FX�k��Y��8�~�GL���1dzo^F��'��OJ�J)I��s�~��Iod^����L��b�w)����O�C8���3�2�lC���ʯr�&�GʄV�g�z������3"����)�T=wMT��q�|GJ����W���P�>K{�+��h�$�A�1�}�9w� �/�b@��8�e]���J�(����/s��y;�pY��3�p�8?#�r�#�1���K��5V�皳��d�P��=G�[yu-����]G�[�e��1e�1�k�LR�k�q�ŕ����RJ� �Sh=����G��,6�� ��>�&e��6������ZDn������� ��3�U��9�C�%\L� GP�v#��}:������)�k��k��g/�g(J�B�F���fx�0�W����K��V�HD�A/ȅn�Q�
m�$sp%<a sC|c��܀s�^#����]��/���jPT��ʛ=��?KW�A?}8<P٘�v�ޖ6����H��]����A�{�_�gl�E�A�@a.L���?�
7p��Ġa`���Ι��.B���g�h�W�#l��J�� \����̿ɼ�zڨ-$CS�TǶ�h�p����,���˿�R�X�k��_c:��Z�`�����Ah��$��f��;\'X��L��7?Bq!���M�L�C�n�7T�J/޲�|��Tt�ߝ� q͘Q�����5T��si�>���<�iy&�j�ff%���tSJ்����G=�0.�����Mބ�{��ݑ��X�k�S�u��{��lh���z�K��]P�M,�o�_V��EA#5�f$�в�^���m�;3MD�wm�gڒɚ�gA�����`�$��J��:�i�Ձ�
R\5�f�'M�䱞��czN?y$���;S\aA��q�!h,��DS)�mj�a��w�2�b��K�:X2��{FY4�s�����$@�?�桝B^�e�q�S�����&���s�XA�Ӯ��l����f�+�3����"�1-�)*J��u�5���<c��-��33\���v��r�"�����thKQ�����YPn�����9>s;|�!܃�^M�-ǻ�b}L'�w/y!H��:���Z��c�x�d�Ա��'�ﻫ���Ol
�����*�nK��X,j�{�C�������h�3/�zR�b�;�J�� &uC�P�����v�0������|f�C����
F,�>����p�kЪ�M��3A�?z(h�O��2�=�tq�_t�e����>$�p�*��,!Y]��Z(�������M����ބ0�j��[�D�դ�_&3�=�o��:�**�a{�Û�U%�Ɯt�/R�:����$_�=H���;��������G٤��폅���P�U�=j�|��fA��X�)��C�JGAdB��t��/i�a�H���ޔ��D���D��6lv�@�R�=�7�Sj'��Ws9P��-�|3R'6�3֖JOD8 ���-�M���d�yw{�L��E<�ݫp���_VN��r؂qW!Ɩo�(Z�R�I������w�x1����

d�:�l����ol��x�b�}
`���?Opa��}�B4%ڀ0��7z��*Y\��,fM̿,l�C��h �r����Cg�٫�«o^2�`#�R�`����xV�˕"^{E�7�4��=IJ�2��k�:�y����ߕ�}μ���9$p�@̸j{0՗��r����kZ��.|���Be��u��P�otI�2�Gv+�ephR�|���z �D��n,;t�OB=u1]Z��b���'��K���d�~���~��L�j�'7c���_��:��/u���4�!L#�J���~��ĜYc�u�! x����O��������-n�rɓ��C�����?�����[]=��Q��U=����A!�<��)�s�&���,>��D���P�II�,b�f1�OaE,���LE
���u��э�S�.<��Z�M��pg��&v&.��n�|�L5)>GT'��ʬ��������k�a�f�'�������U�I��&,W������)�M��4-�|�爎f�$ۚi_O7�����-�epl(�+�~/�E�
�!԰�$�CNۣW]K�l���Q ���G����fUc�|��1nH���[n�nk`���B�W~�Y}�F�Q�(0�߂�PI��Z*Ā��=VMJH�'�K(��HW��#��&���M8dR]�t���08��	[ol�fC�����-�����j"/�R-�l}����Y i�&%�����\����0[���1T?7jy8��([��g�:m���Uyׯs� ��g��,�"�8@��	����>>�sz�4�\<�o�s��ǈ���x"wW0��N�+ak>cz޺��|L�%6"�>���p�K.��'��D*ɿCm$.k;b1U���.�_u	y�������`5)�`������[Y�eT�?�M���d���;l?ȗ
P�K`��
d�qy�����d  �<�`�a��_��7֞!*�p�ZY$ .�.ԓi�����9e��Wnq��@��w�Df~J$yk�?C3�2 �
�q)_����w[4ڢ(ܢ[�T�U�����\)�8�<�k�I�ʬV��8&��9�y`�>lId?�Tv�z���P�#�$җ������mԐ�U���_L|(k�]���Th4n�E���=�>#P�ܻʩ�x���u^���bȅX���u2�{OO�X�H��`�@կ�!W�5�\���JO���������-�Qި�I=|�IUsc��pX��n	�ۤ�Y-���ƯQN���"ڊ�"�9Z���rK�8Q����i�XaNqʰ' B8�N6_�t�"l��B��33r�vҚ�4=*C��U�6���g���r�ob���sQ�U^�����\p�B�=�d�ց�Ŷ@��C�!b��tګ�e�4d�І�����,�N�T#��ɨ�,vpz*ݭx��Ycc�DgD�L�� _�	�3�YhL	�} 9�
K�a��>�>���:C���g���Z+?��X�F�{9&� �2e�U���H��Vb;�j��Sl|[��X��Ç�ˌ`��Q��3Y�Դj�;���[j_m�C�W��8t��#���.�۸YD⎺��q3�UЏmm�×N�R�㡪8���@�UD�;E���j����0\+��N���"�c[�Q��������g�.���0��o&�Y�T���]x�#��:�)U�X�!C���^�Β��x��d�̉!ݦm��Sb}�M�#��v��$%36�R� x�Сk"�޲�8chh���>ZB>�Ӊ{�Z���?4_X�8�i�G��\��!=���ڕ�D`�Y^*�T/63ּ�4�&~��ֵ�x��������P9z�ˉ'�>q"�M��/�u���Hi���D�'�蚽��ohJR��,v6{������!y�jQ.�b��@ k���(���N���
	���-��D�,�e��X��7�3]�b�G#c������c��
����[���tQ�z~7Ù+^��6pÏ1,3����0��F[�f������C����޾a��
���j�H[kfp�\C�?��A�D	�����&����C}B�O1~�����܈�,�Z�AŢ�i(d}���5G��j�z>x��\��ǅ�a&��k
�v���=A�A�+0^QQ��K��O㡭I��g%�d26!���;
2)@�	���Zp����;S)
)����?�K�p�?���w �:�z�Lt���jPJ�c�o�yP�$���v�t9��{5Am�#ž`c���tc4�"۩cw�.{�P
��FvbK�%B��.�ئ��Mn��׽�p]Af�t��g�W���5]��5�j���࿝��Q�fQ8O��+5�3#ϣ�db��_�x�S����O����w<>0+�{��]8�w��֮�b���' ���gd�#=W�m��'��Ho`Zq��a���6a)�l$�H�n`�"Y��p�������m�r��Y%zK�e����rA�mU�@���[D�~,.�݊i�H*	gBo.A9�Pu�x�_MGF��(��C�cqP�hT�2�yB2KNjps�-D:�q���7�F��Fֽ��
Y��eՋ�W����H��."^�� �u�~�;j\B��X��_,��:��Mn5撾^y�8�O�;�Ȯ�H����8��	�٢S�7�[@?ӣ� ]-PxB�s6�CW�u����;����~�*x���28j���7�v��lQ`&2W,��9+��,�	!����J���/|�Bэ(�%r�/NԦrƜ�/���>/��q��Ki��u���;��x_(���qx�"����Z)}Qc�|j���Z~�����d�2�]���a<��#��-��u�;���$��*}6y��I�n����Bo��);��.4oĦ�Z�5��۟����E�uz+���}�b$��a��Z��D(��}��F�)�Qj�JV
�Ou�M�e�d�TX��;��JԒ5{���a���('?�p�R��ċ�{Gj�����㋿���s����`:�F�?�T]9�8dm�սU�l�Ǌ���R#�؃K���6 ��8��h�E�,P����O�<�(Yw��9�l����8v7��~�g���D�>�@頢m����b��p�}�-(��� ��7�a"�����3/Ϛքl�K�����Q���w<O�w�wdK\�(N�љ2/l2,��~�1�k�x�h0UQ����+jT=,EI+���x禮u���Ր�5	�\����u?r�Lj���)e�2�y��b�nc�W����|���E:���:�}�V�~(�����`�+h�P�a�Ճ�8�/���J�B��G�fȦ��o��.<&33.FiRݨt�!Q����l�^��tQ�L����>d,�"˭?ri�|`���}�Ҁ����o[���c�����e��$���<�:^Cb
�sW�2�cjהS͐�.���qXhH�4�>>������׾J. ��.)6�k�iK�����\@�����O;R֚=�p�9I�T&Y�/�N�]:n�ƹ	�i8�?�ܜld4�r��5ͩ�t�z��L����S�E��QZ��~�5�.�4W�%�cF8Xn8��K��STN��K{�큮~i!�H��8#c�§�ͫ�:���2�xY]�<�̙|/�if	v���&�/�>�M돗s�1[�c�s���a/�d�OWpN��k����b�^��I�C'�=�<Y�� �<C-�:~�wϪ�xGZЂ��"M�O����k�$��C�)���ҵ�4.����8ok�;���6���X%�Q��Q��[s{pOp����T4��u{��J��ϳ�#ϱ��qH��`s�'A�(�J���t���E���Mw!V�К��&��pr�O��������F��8��+���T�g�Յ=q:���|�,֞�T�-@�L>:]��x��{�8�4�O�Wbe�Թr2�~�d�p�[�M�N�`�}���ײ*ɖ�N����? �rW�wZ�v�Oc�ш�ʵHK!��������ONZ�����}���U1�w;��X(h��ӱ+#�#Z������l�>@z)iS�	~㜸9�<��drs.ODSFD:�Ӯɚŷ�n �:�6D���>
�,5���hA�f��,~U�Z�]g�L�!.<�ϡ`9Je��^c��^��ۢr�.�D *OH|j���i�ّq��5a��]!���ߑ�$a��{"5����,��?�'�5��6��"�ގ����`�<�-I�ǽ��Aޗ��h[xʼ>���l�m�<>f�yY����jR�?T������8TJ�J��|���E�	��\i�O�}_�F;��+�����uL�ύ9 Y����ƻR�Aд����Rϑr��P�]}��d)��w�ۣ��?7&��:)il��ڐy	��;��b�U~�/���Lp��Rc�qK�/�8���۝��+\�[ռ^���5�������`e��]��sdg����UA�L�[\��Y�3���@g����I��qz��D�2���!<Q�X��{��8I�f����2&���bO}/2f(W/[aM9OTǔ8�J�Ss�
�7o<j��Su2��ȀA���m#���~a�eؽW��� {�q,�x���%#G�L ��?m�d% L�l����S���w�o�&ȍ�1�[>�7��]����@��`�Ns�2Q��؝1A����'bR��d�Ļ��w��R�Q!�����x����1:;&��%z��R(i�_�Cb��ӒQ�n�t]}�R��I^F�ޑ�뭭�zv##Y
jF
R|�ٲ�)�V]�a.l�W��`ն���˂��L�P�4���	���p�A3�\��L���lg<��{ծ\0�/�N��v���}�[�X�ȉT����?��@�|<J߃��R�h��~�%�u���3�w�܇>�tӐ9ۯR/��5���=G�&~�҄�^Y7�f3i�$W��+�����g���ū��A M���}sH���!�IN/�c%���j��+Yʫ4F��S�
�7��C��\R�\h^O�'��/ٺ��~OQ�՜�w� {!���'p�].7��/��L�����_��7�����~���V���'�a1k�"hwp��sk��B�}]��,h�����ۈdR��#�w��!�oH?��@K,������bPx�~�M齉nn�_u��,�3J��29��l�z�5k�0-��.�z8��.���Z)P�C�(�ݍ��=�/�� �'�Kݸ�j���\�'1�����Yƌ�E�-�d��>iC_�1���on��������j��ټm�zȊ8���(=���ܡ����uh.�͌7��v'PЦ�bѻ|�7Y⁃��~YV4Yk~�t��qjp
��<�h���bW�Ԥ�+��5Vdpz��,R�?�Ͳ�u����*A�c�xz��٭�c�'���Tf.�CA�+��g�ʴᓕ�
W8�)������h�/�x�8���c���L^��1��
V�ź�ƽ�枠lV��[	ք&r-�>�� ��n|�W.�
�bD�^}Q��<B��\������Κ0�Hk�QX�wk�����"��T�iZStɢ%�)�y�n�CAH�O<�@Y�	�Sٕ��d��r���F�<�vs�kÔ�*u����s�� \la�F1���v�<��|^)o�'!����]ON�x�Vj(�������~����K(O6#R�����Př�ʪ��e���Pt^���"T|S�oe�����5�fi���Y^~z����VOI���;n�r�%��׏O��P�9�����݇�N->�:޹��5��G��(H�1a65s��3�qv���q��HSڲ��J`:�߰���b�m!��|�Q%��wE�ڡ^�|'j�wM�T�*�[l9��'b�.�^]R�k�M��Q��	��%�f�:t�ц5R��y�9qNI�2��A!i�������)a;��&�`��g_�]��(���T���rg�fsG����XRe��{_܊�D�`��Q'�5̱C0FBҎX�0;oI��煴�1� t�a��H����ic��~�ILC���
4���~�����g����J7@�uq�]>s��k���ā��DT�=�s�?`���>�)t��:�g>�K�TiT\���� {2�S�p�2��z��y�
t��
v#l�xri���O�Ʉ� 遶�z��?�ᚦ�ǽF+o�P�JQZ��M8
\*qQ�8_�����G}����^�e1�Iw�{Z<��{��D�$�.n8��4"'����%�#Ƹ��bX� ��[��d�/+O�����w��S�
�va|	YN��M{����[.H/u;�&[����QA �	g�:��A5[����]�b��u�t\�lΈ�����"�!����oU�'S'D�[�|m�c2t�贬�q�@-��sX]���+��
 7p����َmX}IiE�����UA�B��X�,�b��nM�������=7:iqƚ.S�D�-jNm�g���{��Ŏsa��ؖw
,EM��[2�u�4�#���Q1�j�x!(��i�a�.{�eZ_��Ӵ�Pt�ƿ���f��v�1����v)��:�l�<)�F�
��V��p׈�X����-�/�)v���#s��d��js���@mp��(��dc�*`H��8���t�Ы�aӣB@�>�ޯ��=��[���P�AM�Nv�`�6��Z���,%�9cK|!B�&om��U�Wh��(E�:aWLf�Qxk��'�y�l���v�5Q��]�[����[-D��OR�?�cոfA��]�2D�ʗM��{X}��x佥����ya�+�E�1�`�|}D~ ,~y�[��V�E.���Q驪���_7n�!`!�A՟���ɺW&x�lI&..Ꙩ�3剼�9B]-)%�K����˸o�!���㡂��2}�6@9�c�xԌ��8DUh((�߂���*w3����d�B*��Y*%,�+�.��IaH"��*Ԩ�� ��$�jf��">]$���~M�
`�[D;��ˑ
�\�ǟ)�t���{��%���Y���E�p!K�����# �l2Y�yH��e�g�w�"m邡Z!����:���N�кYw��';��,��辖��GO�s���~���Ķ��Azd�p��E~ȩ+^���g>af�["��w�Sv}�|�Sw���W�� e1�����#�I�)^��G]�^~9n?�,n9t�B����9�?�3�Bۘ^!�.�,���(^dI����^�e�4��t<��Q��J�5F�o���FI�����!��Z.а�RC+�x���!�)
\+�Ґx�t��q����<�=�z�������ZLԶ\45넛$i��sߧ1�`&�9�A,��������Qiv:���k��dj؂�=�WI��T��i�B$ޢ>��署WZ�����Z\%$���A�-E���#��%6d�(H�Ռ����^�}�������6E�tT,ǡ@����0G��Њ"r�����9�
��7\w��th��JW	��uq)B�u[?��Ǚq�e����V30�y`V!�Ci��ꊖ6�;�-�f�&�xp�����ȍ?���`Z���N8�d���y��q̳j����M�9�؛�p�	�������S:[���WV�y� �C�ޟwv2!�rBZ�g\��6�<���dɔ�2�Zzhx������)�+��Η��'R���8Xvp(���.�ˀS�!Z¸�$��<�$��Ttْ���l���a4�L��h
1���c1�rV�?)�e#<}08Gw���^���ȥ��O�J!�f�^�wAW{�3b�f ��+:6[��g|M����8�p*:9v���hgMx$���੍ �~�wm�$׷�rJi��0Ϊ����Fuo��=�+oD���~�BS����D*��p�jN�y�I]$P��[���<v7����˥�-�e�o�y����|<"p�a]���re���q� �t5�=��d�)O������լ��-M�?A�k�|3f�_Ti��5K����8_o1K�2��hњY��_��8Y��}�G�_JGuc�X+tX�z*r� �i��,S:w���1�6����l�[�к�rc�Gl^�IEߞ(zh���3SƢ�S�[�l��Η4�z��$��s���3H8�uxɟ�a
u�HLp�C�ݑ�[��D�p�bǩ��%�d�OO�~ٲb= ��!a����������G�rB"��	���іB����`�3�d�p.�4:�@�J� O=uZ���a���
=;�Z!AE��`ѽ^E��c��!��lif3}�L��T&JD�;|�^	�6� S#�H㔇��T��Fӵ�1F�����m�:���F��Q��H���rW�@�_�AH�q�d�!��tv�<
���,HM�Y�:����A�ap��y*�x�c�����d^Od����C@D�_�'�@(TSe(S�	�ߺ�Ҵ�a
a����ի6��dX�v|�� ��Z� P�C1�w2�����Gb/�T�Y����.r��L-/��"�'(�=�h�J����	��T�(�&Ȅ��
 >\����#�ʥ�&7ˇ_a����(�hq}@�T��j��݃�}I"%�K>឵��
xC��c|��{pP��-�O��~��*t	#�d���U�S�^��G�<˚Q���l����}���;��(���E�L��JL�]�{	m1A+R�ԋR�W�
��et͠�	_�qĪ����~oe<�ȳ:�iWI̞�ظ�YOK���kRr��,��a���迲�	�@� ��3x}⯍���r��Ҳ��&d����NLC�s�,��'Fk�ô�����f	�YJ����zr���0�Q����k��%7\@���b����?�nSu�������,����+�8�R:V�`���_e�m��-ZJ|Ӂ��,�P�a�w�h�>��#ww�}ǈ�:��Vʦܶw�HJπ�P���}s��o����6�����<ɣ����?�u�n?s�����B{�*�F\5��G�n��W��7�T�p��1}�(�,!hf�?��~��������O�	�m�)"��ti'Q�bl>�m����r<�����>=�p��-��>68e�[0��/*�+#���Z8.�c���V�&�d o��"<�7��_�|^Y���I�p�)��m�%�\	� Zb�{E1�kћ��h��X�N&��yU���JG�o���}&���]��6x�����sv���!��Auv�wZv��i�7��� �G|k��6!TZ�h�\t�~���n�l�۳�~]�GJ-1�����������"�cY_� ���(ܙ%[L[��L�b4�5�v�`���������h,�d!C��ĩS�]�yȞ��G�T���W��a�+��go.o�!w��[<f�)5Iw���;e{է����-����ky�"k$/HQ ��#~�����N&c�?O'Z�j���ܴ��1f?/~W���pu��*B�s� m��PseΫ�!S(6H�(�rD ��9�9�m_\�-�k��D�7>^ǲυ1�\p��b�� ���  �<qW*3N ̼���_|��g�    YZ