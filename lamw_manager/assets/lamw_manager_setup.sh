#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3596977086"
MD5="4936cf232530b2a7c68848a4e899b794"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20291"
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
	echo Compression: gzip
	echo Date of packaging: Fri Nov 22 03:30:56 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� ���]�<�v�8�y�M���tS�|K�=�YE�ulK+�Iz�J�$��!H_���˞}���}͏m�(Q���dvw�K
�B�� ]�}�O
�JmU�m�����|rG����fq%7��p��T�0/ �{��jlF��((�����E�M:��l��Ǜ�D)%��ù�硫cϝ ��U$��9�U����_�X�}�	�g��9��`sp�h�f}h
����Nñ>
����v-��;<�y C�jB�ZI@�b��	J��gm\�*����)Z���|,&�g��CF<�� ̘
mR�h�&�+�:����x�6�����Rx$����a���t-_ʧ�b@�[�������b~5�����/�������΂��Ԟ~������L��}r�>i����s��1b��4;gG���^됌n�Q��"27o�����xQa�ͣ���G2�gӅLb���=˞ؐ�@0���%���j�,����f�DT'+���ȯ����!q�O4M���c�mL&w�s�2�L�L#$��I�����k:12�1��Y�l_דaU�ӿNQA��rV�V{�A>C�ʑ�׾�2��̄	�WQ&v�`s��g:8S%o5�ðxo��΢)y�v߬�״�����_��~����c�UE�cѠ�f_1���A:���^����V����}U�Q��<�	c�
����ڰ�J� ���l�m���@w��Pe	�yt��!D�UǓ�"�^����މ_�z�v�̈��YzE�f\G; �v�Z�νK�^�N�>�e\��7sPP��-�+-헹8��@r ��Vz0���pn
�ʰ`��-:��v�H�Q`O���?@�0�_�a�K�,$� ��0{>���{|��3-�
j
6\���.�}�V{r�C��`iw��ҝ��������i������X �!a�<4��q,��*�U��:���.���S��]^�]6<Ԉ�Y@DY��n�)Or�*�+@Bc��^JY=
��X��x�0�	T�g���������t�4;�_Z��-R )Yw��U
/�'G��I����S�=��N'w*Vˆ�+�JK,|5=0�j���:M����d%T)=�<�NR�"�H"kYt�x��S(��؝�ݑ6g
�����*��\*��!�l."Gr���˝�h��
R�ۛR�t'��q<<ꠍk��:��a,G�d���&fn�D�%jP�ߔP�Xp��9��></��җs�$��,��H������f�ԧ(&]s|aN�p������� �Qj�/`�E����$^#�[ư7����W����~+��k���5#&n�0�Z6x�?�|�w��to{����W�v��/\��c�W3����Iz\��$~�zp�2�s�=r(��r�xЛ�ب��ę��%��V�~�;�	$6��޹E/��!�l7�������o�A��0Ԉ��Ic0����K�Z^p�z�:;��~����a�Pk{{{�p��C��;��o�
I�������ߞ��'i��"�`�R�J�dl��z
j
[�'J�������i�%
�
��
�u�_k�����ރ�j�?E��.��Y9 lη����F��]�{ƞEaRǼ�|Ao��X��Xr�(�4~v �s�gқn��4o��_k/[�,咶�C�_.z��߿�CLCx�KӉ�Q���ך�F���@�v���F��J�aѩ���i��|��N��S�Naf�����n���A[<�ys�`�w@
H�7�MqD�I��׌:~u��~�ִ@�uv�B:���6�l����a�X�A�6�"F��,�;U41)m�:	k�n.b�^ϝO�Aq*�g�_&V�	YE:4fH6�,o2;�
��0��jq8�2�&jkTɕ���.8�"�U##����\�_&L�f�e����YV�SJ��%�	\�((�����V�0���ҿCɬ/`­�Ы,%G�x�~�Eը<M�!Z�~��O9��{x�A���vB�'|'hf� ��X.�i������6r$�}U�
8�iI^�)�Җ�ڢ��%Y:��Uݥ:<)2%g���$%��޿3g�e��üv����2�$��553r����@ ���/�}0�.@���f8K���#.�_���`Q�AH��rp�ZТRЏz�"3M$�@54j�/h��kC'�dqM?ಟ���[����b�t��P����_�vW�I g18l/��"�*)�R��ς��T��WV椽/JT���o;�/�6�p���7#����΀��k9�`�Z�/l�+gʕ漬�fT*�:Y\Y��j�=K���T΍���߼݌���X��O��j.Ѣ�XgN���w�҂�-���N�V�k]�6�0M��~<+:�%S����s�b�gd蒿�qx.�o��s�f�[��̫�����y�n�c��1�C>p�YR4�g?�Z�Mo��A���1���A���2鍫��9?������l"��وF=|��-N�
7~��~�A��@�R>�LB=����~��'�7�	�|W�
��v��.�`X٪�O�[��{n�6\�J���WnR�ҽ0��i85�ȗ�����J�����#R�!�f�AT�M�3��\�Xk�-�)��[&נ�%�􍲲��X�jδ���Z�Si��A��#Ld1#OH����x�7Va*��,�"�5_��Aw:�%��r�i�<��*�^�!���i�)HXs�[V�jb肆X�=S�����ɑ��IkQ��K+/����K�j{��[I.E,�0�������%�q�dd���{��ݖ4�+	��*��7���\
����E�N�r�\
�ę���iV(�#V���f*���I��;�t�� �3vo�	���)�WK�BU�f��r�쒖�����9�r+B@�7\��M�}�9{�0��^-N�]�т:GGhB�w�2Æ?�����Ǒ�]��aS��e��x7��~���V�׫����1�	�(��|�������&^�@�������'��,$��F�[q���}1@�u�����'��wH��IK9H�	A���L�����T�jE.s?Z�˲)%k�
ˤ���8;�&ɳ�p`��Y� 
��jF���!��y9�{^,=zoA�nK������}ۺ/3��f�eD��n�E:n]@[���q�U^�'���7.��1_�)��+�tZ��{�����z�m����� ��q�vIR9Wk��..����t�-]�R��I��� �.P)�'��Z9W�]��4H�Y��	
���T�~
{��<̊!�F#z�x���\H�{�vZ2�E��ԧw^�Oٰ�O}������x�ȅ�@h3<���>m�N���'O����5�\�f��
^
�D0+���7q�"�SB���wo%[6/a��l�c�Z�:���Aegw}�K�'6=G�P��F��op��Y[w
pC��)��e�>s3RJf�T��S�{)3���8Xp-��9A�D�+aRzC��0t�$Hp�?�F���";U��Az�Ěbyn��'\���r}[��3fT���+��;�M�V�x*�MX�[W%u���(K ��5"��V�1�<<(d6�!3�Z��K�h�G�#���q�=d� ���@��\3p�9���w��0�
	�	:����7��1d�z���Еc�4L�;Y�Z�$�� ^�lm!1m��xe��Ȅ�I����̗�
 �kT����e��}����������ѭ��ʶ�%���aA6�R:*Z�.%Pt��Z�$#���0��͆ezm��zF[�	���{N�B7kj�͊�*�K"�n?�kӻ�Q�������73�	~��)�ep���
W�jt3�W�	0�=O���}D��h��%���%��(�!���=V�^B����l@y�p0fp�R�'�+:#lK�"�ųA9��(�����"LNG-8n���V�8�^���¿��D�P_���Ëv�d��L;(ٗ��L��I���+����z���m>m4��}��,�����O�9ʗ��v��Ku}�XaB:�S?E�-�=��J8�fo6A��p%�lȍ�eߍi�@8��[ڎ�9E^�t1�i�Z��<k7ϕb��2���uq8�y����[���JgI["R@����`�ٞI�
� I᳃����63�c+݌ڛI���g�d���k�28(_)Y�#�f�V.ꅟs�ʣ��R8�d��rD�k28�y�)��^G��?�`R[J�`*�ȡ�#��������I/m�+��`�/����J�(�`�"����4J��F24RxF%r����.���xa��f~�2��{N;�`:K���<�U��mڢ�����I���Z9C'�f�F����v�9��	/�(]ж�ܭht\{�<W��%F�D=��/pn��������L�g1�2�8>H='&ANۮ��0����O������2����R���X)�����(cǈ`2�@o�p�lPA��9��C�1P���r������s�>�� ��H<����~���IAS!�Rt��'�t��#��.9(1v��a�c��PlDԹt��0t��;�|_�Q_s���~�<��KKG#�+�f6�խU�C"t�6�q�(�;�%Z��h��a���`6AʋZ�C�Y�
(�CJ��X���F�∋l�JO}C�䓑~�n}�M�ty��9�B$A$����	�j�d�-Lxs�Z8	��8잂7-3����IƆ_�G(�R���PO�?V��$�HY�?��L�4I8�s��B���<�
NG�s�y��S��s�q:�c_�Hk�� ͮ
�j16����eR{hQ��ƽ?���	ke��މr�2�jBqtvj��H�3B�^˳R]6�gFx1�5�p��r�����s}0���F0����¾�R(��u�v�ѧ�0JP��1d%'��=�%�z�6�1�MW�aT���H�`G(
��/�u�7'{��q֦���D���i�zlp�'��y-SX�Iܸ���fyT�Je4�R (�&������<Z��9��/��K1G����+��H��\���P����]�z�$��T},���,���iw �G�!�NL>vɄZE�̴����WN��L�}Q?W��sen?��m��:ִ�!�L ��=�������H����4���9�/�9����"p�5���Lvl<�ݯ:w�Ocά+%�7�ԼGû
���{w�<���2���W�$\	1xM�A��)�t�Q+�NI��h��[�N�V��7�F�=�>�����bA���]�X ?Y�N��R�:]A-Hg77MDYW�}^�����Ϸ)���8��H�6��0'�
E�KG��5�7�Ԓ6���zʆ��{Hۺ��|��8j4�
&���o�o�#j��Xϟ?��e�L��E�qΪE����ɱ�I{�JݤVR9y'
�/^s4=����,c6�U~��rD�<��0��u���p��	]��EsE��X]��ja�V�z=�8���h4�m��\H�I���ױjM-�0��zǰ��I+Qh;ƨ�c��>��5z
��N����ߺ��+��U��ם�k�eH��.�e�a�;99BX_3x��'Cd怴�cs��k��V�E��8!��)Y>�����!�:��X��hl�g��9�d���w���U���+���2�M,*��f�d�g�ŕ[%�k��c҃�W1���r'K6�z�d����@N�U+JU�Gx��:��KT�����N�b���<a�<�C�m5F��i��X ��I�6ꥵ�G5�5Z�J���
���oI!?A�ϖ`�y2[X���l�����eڑoz0���������N�D_%�V��D�]T1�Ɛ���[�'���Vݜ�W���]���VrqR��A���� �>�
+�5O}٬rb�I�"��BV�$�v���!	��Dg0�4�a����(���ax�߬~�[�{l���y��p�OF-���Lq�d�%s�;0��w��l�}��ݸ]�ͻ;�e��KN5�="�r�RBV��p^9{����7�Kf��?��V�]d&X�Ku��#s$/^���c;-	��z��ə�,j���E�p�1f�.�
��j�ŕGK���bm�۔�<!�"Fa�[�=�d0$dU�kD$���I#S��,"K44O7?��}r�����:�n�O�|�)�#f^Y��IŰ�f��������/WS����ӎ�44�=m
� ���L��nB��G4Ɲ���jG\Eh�z�P�d�}l8�:
;RM��)(&	9���c
�!�~J5p����p'��b*;���>�=��(�?�]�4ea��@i�!�$�CM��E��B��(HC�3�(Z��&*0G��
0��4^:㦤�Z�2e9�|G%�+l��S�M�鋛.��Cvt3�6�t��?$�`����-�%���}�[.���K��'�c����<��ϲ�6~��
% �n��p�j<��y�Z��KC�P�'8$��2�!�
�����	����<(��K}��/�TT
f�R�3+��Lj�ä������-��h�4����l��s��$�0�_`��)��#�x�QP�c2� 	qH���fw���iH��dnQ�ꤕa�V!�ݬ.[��ܰ2[ꄩK7���!#����V$���Q�q�g�1sT!��\K
�s�M�_�ho�Y���4X�G�Pc�h� ��/����L�_��L�<*��3��`��3�i�)Bw:o���B����\G�kv�8#Mv���ߢ��oq����D�}�
c��Z-��,@�F�(�V*	�v,�;0KQ��Q�J.x
8����W8��������Pv�$�g[�+�I.#Ra=�Z̯�A0+*��\��u���e��f��4�3�w�
���Ɋ]�I��\���[�K�eI���WJ��f�XhFyo. VavOn�	wz���@�Ə��}�k�	v�T��x}C[���S�1}�-���צ�<F8�z��.^B�ѻh*Yr{$.
���D��pm�6(OQ̧��
Б����C
M����އ�k֟H-�V�fk��t���Hj)��N���+؊��^n/�g����q2}+#������
�s� SQ�6�J���O��?��V6�����o��7�.���s�8�p�jg�׈ ��Q������K�'�z]c�˄�ճ�ևK��a�*\Z��>$���WtԸ �'ThFA��-ݴ>k�B_x�`���O����=<8j����J���#���e����n�Gz|��$�c��D�;~��� z�aqS��/� �+A0��@��b���W|IiW�}Ab�u�"vvD���0�4�qЀ QU��Y�J*���K5���$��;Q�Ra�_>G�F9�����yT9s�"�!�9'�����x��4����������������C���ӑ�d �Nb��(t����S�O*��x0���x��S
��T�ԕ���aj�.@8��Z{1���`��(N���6�!�*i^��V��p(͢��{��$/�|>u��T��{��!�;s��ͽ���C�7{���-p�:�r���y"6��ɐ�+�NՁ?�~��m7��{�Ύ���Y�_��\����T��4�3�o��E^�y+��r�~�g�S�bww�?��N��WaL���(
�p �U�!�K@)�u�k�J����}:},a��H���	a؊���Ɩ�?��>��~�{�������C�w[o����ڇ0H����#��>K��'1@5G����x�@���0��ｑجK�?����Z��9����Io�L႟�T %���̡�BeQiA�4�0O?N�����(W����mu�;><Z��G��ãc�r��O6��pZ�͂��|8�?Mj �m�/<^�I�	����F��\6�ou�ۺ���Ӵ�'�
ʍ9!��!+RV^D��3����I�N0*�4Sr��!���
�^u�=t�g��(b�ς}�?�?�@	_l�s��e�$��H�
���o�<vفrj2}���I�B��Gl�/�UФ���"��?�|���m��O�� v��n{��=b�7��w�BDW2�si%�N�5���c��d�}�p
���i�]�{�1  ���Ítr��/?�'�O\@��$r��K�I��E��#��Y��nR}6��@��W��ĵ6o�
�ў��W�gHm�?�uqq�
C]�l��t����x�e������w��Z������v�W�}����.r&:���{�(�E�N�uv�^�g����Hq��*��1���ŵ��&!�(`��t'3/�2���[��n���jw�sa]�� 5������S58%H5��a��,�lU�X��!n�G.Uӡz��v@(�����,ŷ-�f�s'���ȧ����h�R��V��N�x.��/�N�������CꯑW�[��'�,F�(iG�@���Sv��[���
�
�c���⯆ʎ3d�T�)ז<rX�񍺧3,����x����5A-s�t�2��cg��J������/r���;;��% 2q��ʩ��[�._�%��ljC�FZħ�*��9*@�\�c�LA�a,��Q8���
\�<BCΤ&�-���A�U�o0�?ۂw[o�����ɫ�.ź�Ի���UqE�k�0�Fɼ���?��Ӳj�_����ӧϲ���Ƴ�����?�6 2���l���<�0,��`<A�N�.�x<�g41%��{1	�K0yg	��}��Dybc��υ��)�*<��y�$+H~W6˖�_&�*	��b�,�G����-	L%���w���%ɏ5��@�Եd��N
�>�<Ò\���]�&;6 ��Ϝ��o�No�����pQ��-�.WVJuz�����
����S.٩bVk1q�7훍����� �Xq:j��H��̹k�-���t����m|�eUƛ;��,�?��Q�Nd녕4�G=r��0��6L$!H��D���=U�6i?�ۼ������|���
F ����w�UT�v�6�	Z���.#U�NI��_�#��W�X��� iK[��9t��x�?.�t܅��P�'�����)=���^�ZA<��0���	M�r���li��n �"}�X�<��U�&�t�~�����~=O+(ֆ#���΄;ߔ��"ɒ�d��2�`��Y��E�!�[��,���ͱcS���:�`&�)�s�;
��~Q�f���6o����h�>*�	!���m^ 4�e0�u�Ly��[OBz�!�d%�w���t�[FAR��/�ua-��䉖I!G�c{�B��*
�\Fׂ�ӥ�73E�F[���38"r��׹�P�
x��
�ʪ�3�][��/;������-㴚��y�����n���ŮФ���9	�H��Ͷ��o�^�b�O/��n��?��p,�{������?��H�OŎ��&�a��667s�_[�����������<�_$��h�a���>�B��x6��J������p>����wI�y ���0~"�,= ^M^{+��i<]�~�����UM�������j���ۨ����΀JӶ_�x_[�w���&��ë|yU�NӸ�FI=�F��aQ�31ӿ����;�����d��	2B�ʬ�jX�W5h7��o�1�o8���3�����n��n�d�
(� 7ԯ囕�.C�i���s��ό�ĆߢUm�ʸ�#��焰4��g�$��%d;�LS�l�K(3R��t($h��<�B��-"��
d�@c[D�5�9�5���4d�*�P�+�F��޽�j%�*`�iJ5k4�`!)k�OR-�&�3v*��U��b����[Ho�@6E�~�Jv1���Y5QfLYp��g���0��8����ʺ�%�s�_i�ݣu���+���[��麹D\VI�
^ Rp�'P�81S�H}d��S"Ǥ�,J�5���x�~������ß���?C�M	 h 