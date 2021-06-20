#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1095679197"
MD5="4ade95447aa1e0323ebe5bcd729d1c93"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22956"
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
	echo Date of packaging: Sun Jun 20 14:40:06 -03 2021
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
�7zXZ  �ִF !   �X����Yl] �}��1Dd]����P�t�D�r�,B���"���y�lKi_�UW�F�%n)RCah-�9��9�`�-���I�t"6�U��"q+��JP�fi�dL�3�	ֲ�&�V��U.ŗ��s#S�U��� ]��9d�=�`k1;���"�a�݌;ð(�2�י$��_���ݠ]7��0�4�x�����/��o^�<
9"��ᲲTy�˯Rv�<��HZ�3����-��'�#h�ەjdg�v��:Ӭ;>��l^�V.TH@�R�Q{z��b�T:�Z���O	2�A3�i ڱ�~~�������qw޻�}��Os��g ��a�Sg��t m/z��4�ܵѫv'~��VgZ���h�2dl���FˉxX	V���/�l�����/�PS�h#�q~d���֏9��xB�)��8߱�s�����/�l�{a��yg�t����`����Ʋk.;u:�Ӊ�܌) `��E[dP�,Y���;�Bp�r�JhڔP��Gϸ�*ː�$�vK����vS��^1���'�a��K��H�<rw������0n�[^T��{�}/��Zi|��v!Z��i��U-�|�)��׆��MT�E|q�K:�O��ƽ�3�����5����S0�vIש�H<L�\`��^�{��7F��dx]���eOS+�A*}]���/_ʤ.�����/�������Ԉ^���M-�Lu��ނJ�ݗ:P� ����
���QY�#�H!#�;�G��O���Y�Ͱ���C��g�c1e�r����Q0�0k�PMKu[u�Q�Z�K�T�x�R#����#��w~���K�	�ف����)���ůS`�����k��.�EJ�I���X�l�Q|�0��]~Ћ����^���0�C�C��	��ȵ�R��ii�N-����]4�֑��4��Q�"�n����
߄x��'����bl�ܟMD����ӤW������@O�c�S�Kͽ�����x��7���2f�6���nX��r/��=w+�k������^B+߯���*�CR0��h��-�tzd4)z���-[��:�n��v	��2���@<�6�z�����OGZ�!�v���y�N��B-	�;5� ����6��`N�a� }�Q�F��	2�g��J0uk�B!in��Mp{����4*W�;�T��nb�\C�8{��i�t��M�d�o~�?�)�����z`;��-G-)�����sn*	�����8��>3��H�#c+��t�57#��	H�7�k ���9�D�1�?<��`����(�F���b���E#�T�@**@娩�xw���ƚd�C�JH�B�N�K�.��Nv��䷿���Xz��*<q�m%�^�jU1�P��}�K"��3�L������,,8�����8��*v�f��jvhA�^⾯��I�̚�t�a�|Ѕ����&��������T<ֱ�5��M&�'R�䍧)�Xiތ[4����b�����Q���+/�ڑ�*Dd`�Xc�[��"*�t(�gx!Lm��髫x�?�#��7?��aX~ىu|���7�3�6@q��h���i�2�wCJo�܍�c��DP������؉�	&�@Vk�c\���	��~����	�t֫�S#�9|{�gk����5�J�Ҩ���Ot��O�ĭ������1�?My����N{ͧ�L�����1�y��Ox�Ve���]�W�ndi"8�	b�����BN`���>�Jӭbys�g8P�_�Xo�H\���rq��pd�����ҧ�20�7�%.�u�۷P�(�J�]�N��o��v{3�"��oC���TzX�P����w�:`2���U(�֠����X�e���싒4Ɋʼ����(���M5u푎`t���` x������XӪd���,��N��)��7`H+(����#�g�]�;��Ӡ%��~R�O�?c	�U|�T�t+ �xKȺh���%���{�\��^�#{�ˑ���|���C!"��X9�G� ����u}͜���V�/�q��Si���X��E�sP1%��f��X�\�t�C�����[��\�O�9�{s�g�hd4d��n�(D��Zˮ%���_:R�Ӹ��zM�p�@� @�1M<���)50����%V�F\�+ã?���+"Z�;����A:w���:LDťJ�����]�8���%�a��B�F;��T9�-K(ŕv<
����c�ЉY�_f�`u�yBӯu8ʍ��d���#�� �UL!�$��X�+S�b7�?cd�Ķ����� �^o��[�7������{���Cp��b
����k+
lU�pKO(zW��eY��FQ%���:�,W�1QF<�e�����y���b�s�
U�S�:�~U-�����O�N��!��e�t�@շ;�Gκ�p�*Y(�XT��3q�W-�PA.%;�}w&��(�r��g{���$���t
�V)@VÁ�4��Cz��N�qe��O;�5(ps&(�����
*��!�J;�z�X�-�-����֘\-�z�����I�� g�j#S�I�@w+@�����+22��j�(����a��tY*o��6��>�;4߀���C�^*�L�dVha����s���ۭ�=���,}L��E�"pv���V��X}��!�<L3�k�՝lfy�o��4���w-��qؑ���D-�쌫`L�F_qp-� 1���,�6zkH�zo�Gnm��bl�,�0����_X����Y������-@0�ʶ��z���n�m��G�Q�m4�����������]�e�8�Jc�`���jȱ׫M�}��K�B�Ũyj�3���R��X�{�ѷ��_�B-[b������x�8泠��}(�c-Zm$@Wl����~'k�c�g<OS>5��J�.�� ���{WfYRa�4���F����zs� I�H���9�EcƖx���5�[i�"`I�n�I=�[�sk�Mp�QcgD��s���I:����/����5W|�%�t�*�!-��M$��Ǯ���_�R>�_�i�����D#K�b`��ᦘ~�BYfY`��_`<���n*�����3��}+�bQ�G��v����M�4�6�,!�w�6����Ҫ*��#��N�UP��qX��[F9�ir	m;�$���U����igՕ�r�Ez�LIP|�uF�����:+��?l��G�;��fh6�rA�"��6qC�������y%��t(����5����q�CO�R�<�`@�دK0����s���U�p�*�a_�r��D��7���t�+z�j�T�K���sѩy���N��ܬ;6PQ�$�[;�zAGW{�RrG)-��zȪj��P<�ρ���f���>c�$�o[A�G'VO⋘���W�ޏuK_=���o��P�����}|k����,�vG�K*��W& ώ����;6ZJn����D�J��`��5�`ȴ��!ԡ�
��`¤�"S����Ӽ�o^kV�$��r�	�wLY���u�&X�F�G�vH��*(Zq!i����|i.<�}�f��#���d�H�߸���%��n����_�QvWe��ֶ+R®"�AB��i�������?����w˫^0Oo�\����)gUh�ĉ#�IН�b��I��]/�TG���<��l��В�E���o�k�w�)஻Ե�+�g%�,7���0in�K����Z�ڦ�1�.ũ��w�n����g���r�1óc��f'L��2,�<�(�~�7�PuT4��4DS���t�\��o[�{�=�5lѐw[���^4��o�{F%����$;MD>�qE����&^��X����Ժز�v��C����ڄc��$�"1�e��J�
@�8 �M+:]ZT�\�xw�tP(�q��K$P���)m?��.���v�sb(���iUaCK�Ex��/����G�_-�Wn��v>qY��AY��_�_6��Ƥ�LY�Ʀce_�-/Ձ�m�r&鹱v �t&_�O�B�a���N�o s�>;��Yn�V�J�$@
b>+��ޑ�CK�yiuj���T�t<7C%�Z��>��� 7%[ r�o����2��$��xE��Ŋ ��M~�>�X��v3*�W�P@�T5��Oy�5���U(M�N��%T������\��s}VnP���
c/�B5A�*l|�3��5��N��Bn[�p;��~|�H��8@ ��E=2��hs����2��u.�e�@��)&z��3� 8�s<�ҿ��)Wx��(n]����?;�O�f�����~@R:(��]@"�}�i��_5p��d?�,�R{��c�\g����w/��������
�Z�λ��j�^va6���XQ���N�X�8�q�u�.|ޢj�VOgd;����Zۅ���d}�����N���hÂ#�m��M�t�U�cn�;�aY����=4i�a�ک���4��]C�%D�&��y�CY32�n����o�	܊4��0�+�j1Iv�R��>���,,(A��_�5A��!�L�d�f��x�CX��,��op���r����4�XU��gO�O���f}Ƽ�k����mxV���2��jCP���?D�%8�̌�����շX1R���4j#���r}[� ���ߴA"�����3{'B6{ �������-�_3ފ8�?�	�p�+��w`���*qL�_�ű����[h�[����^�-Dx�
�*i�@��d�����ಘ+-.ŻI3�{껄����+'��Y��L5M�s���Y�Y��p!}�/H&5���"�K�@�90�h�)��CN�i��P��|a��=. �6�s����n(c$=�m<�H�3�2��0: -2!�/ͯ���Hpk�B�䷹'e�������L�K���3ы��Lo[��K�|΁�=�C~��UR�jz��>��u?~ѣ�S*/ca���Ƈ!a�>䳥wN�-��	$�oG|8��'���?x�	q����i����'T=+~�S��{�ق���,����(ͅ�M�]*�t����e�J0gC�"��e��S���dzze&�J���`�ظ��ݙ�#F�<��P2x�'b�ǲ�0m�2!!^W�j��x��KH�ʑB�ZU��7�7�&*`0��:��lǭ8�|L��n#����m���r �830M�@�� ��ÏY)g�)�>��<�1�e�F#J����~�Rg犲樟�?]�
ZQz����^T(@	�	���_���RS�4��:���D�ec�U���bo�Wa����.�{J �C�e�<Ԙ��Oߓ?��.���-���J�W�i����(�O!Yu�GP6��0�UO������5&�_�sR�!~f��1���BB��#$hq�h���%�o˧��)]��	 ����>�;��4�`�NE����@o�Q�΃I,T=9,�y�B��10�Ԡ�,�[f��v��L��B���R*d!��[�345��9aǄnM\��Eb0���t��a�\=�Ku�U�|�@�
$P����yo!ėnP�=1D�i9"}�-�]:��+N,p���[���I�c(��:GYC�fa�Y�o��!����+�@F�����7L#��94H
���c����;��y7t<�:@��s �K������;�"��2}�=l��n�H*�죗�)ϡ^�����G�t�G�z����`���DYM*DXN黀8,	���s��"5lH[3���-B7"��ʚah���=��:l�E~�}�Szes��l$\���!ΐ;��n^O0��Y�\�,�3-��^#W��,��Y�
^ʝ�J�V�Uq#�D]�v����F~�����+�2��V�]���s�'�
CU�]�kZr��d�G��Q����a�G9˳����O��s(b��9n���t��.�И�(m��͗��$C�xȳ3����pzq��\�f�������TY�󘹺�U��{��&�Ad���̦��Ӿ�47�A4T&
�Gt�����ND���y���EP�ہ�U'8��t-��|B���T�@�(P���i�⃀Ű��Hy}�2ީ4������:T �cj��rl����\|W�����g����R�� ||�= P��d,`at�AO|�Ef��_rU]C*o2��-OBD��p�Lx�b�y�z�)�?�����J��	�V��V� �~���c�Kndx>�;��mI���>��7�~߰��zBD2%a"��P!��X��,~v�����v�
>�Ҹ����CKS���8~p�!�����S�<��*af�UD7�}N]����ҩ��>���������Mc���؋_H;k�XeƩW�)��ND���B��5Q���`᩷�~�wXpi�U�
=��>*c]���� ����5�l����(�����y�����HH-���kU~C�О{�u3��en)C��D\w]��W]�'�F��ή��is��&>�=�V^yʋ-�q76�Ȇ͂��Xj)3�+NIM�w"�.|�$�>\m�F�+>�6g��l�����)�G����:�EPR����w��ƥ�㐥�-[蕽���>��3t���lCU�"Ọt��Y��]/��QH{����5X���bĝ�I������
�]�h��1Q�柳
2Χ�����y���_k��j�7��g���p��m�Ec�DR��=�_M@�$l\i�ⶈ�q瓳�v�4c �p��˫����y�w5x��N����'wPx���?%źO�x��kU�]�@�0f��}���s�'���b�����i��񴖕�^�r���̾���/�M�mA��b�5�~0����d��x��p��KO<���2� �^~�G�@Nȁ+��g�I����
�c�`�0��97��*B<L~����s�a�5�:N;�(���BVEDlɋp� >W���"' 2'5D][�7��u�0��S���}5HX���	�#LC�uMH��O:�Ư!
9�`� iѢ>��ʙ�ZvB���$݊^@�N���}س�SM��.��ڕ����
��:�tYN�2&x�Ĭ	2�H ��0��kH���NJ�Ĳ ��7A�&QϺ�Kǌ�6k�0z˼0h-70$����LjS��T���$9�PWG�����)eq>�d]Ӏn�K-��]B���[ys�f�L4{��c���$���_|�i��"��N���^l�)�.^g�N�N��"���T��ux��'*���gM}�v��@D�ps�h�sn-�	���@'�������K�PXX�X��p{��j�n�~��Bġ'v��E�s9ַH�s�,������K[γ��F�e�+���Q��C�2��9j#�@o%9�XQeQ��(�4�~dD�@%�<G!s���P��̖�������@�X5#O%O�/���mpu��F��s����������Xn2�v�\TYd���7p�mn��4Q�Qpw�c��S,��/��;c����Ͼ����J�F[0�T
xv�~�7>��;x^o��+8��i>F{�P�G�w�,l��9>��X&!V��o�m�>�+?�?ME@b���j6�bvhZ�Ʌ�2
�����ˌ��{���;9�Y��o��0�U�@�V�d�C��p�_���;�>e�OQa�s�(%h�e;}Gg%��$	)Z%B��Gj�钽H�zs�yb��=��
i��{�R����t���(Ր$��n�����T�"��?r�b2O���h"��8�M�9ŷ(0?���ny;u�t�o6�:o�eh
�lv+�\�)�8Yu�>'9s�;��~��xT�G��Bk�m$�d.��}}$w�;��v�1{�	�4)*���u��:�]�F�k�2:�����v�������*�g
��h/�>M��*�[��m,��_}B��\8%.ޮO�	���9�Q���^j��d�^|��Gn�tɚȅ���H�*�D�7AtW�s���x/�2���1	�����q1p���/hHO�p�3�� �;nY\0!S���,-Xi�`+|Jӵ~��5��Fꥭ$;�z(��`���;e	T������?�(�hF�`�����֥�NEGچpL1�b�p����魴�ft�8~4W��A"���D_�B��rZ��0̸�����:y��Q
��Q��+���
����s�cÆ��
� 7S߈�ew�Bˀ{�{7Es��1g�A��:��E{��[�A�-�,r�����z�w)��4��jA��"C:�ƥ�j�mL�>����)�w�p���w�Za���L����! �qNH ��zw|(�&>��Q� ƞ%���{_����3�D�r�W�\`N�jb��k�{'�s���Q�/�_��V ��y� ٩t�CN����d���Ւ��Ҥ}WL�7Ǭ
Q�i)�8�$Ӎ⾥��_�}1�K'��*Ûؚ�Q{D����������p����q�0l�דcٞ�(*����Bם�{����X�[�Ȝ�/>�pp6�f���)Q��Ɂ��G�X?�K6s�I�7���\\�䞌�9��q��1�-���Ñ�"N~���0{�Ȧ�?]��e��	��k�,�� r���:���$i^krd��(+*�u����g�S���$�����YL�F
�MgT')�tB���f��t����'B$����C��l�r=Ez��S�E_�?������9��";A�J2�pb�@Z�y1���m�9��G��5�6�o� �H�ڨ�/��䪻�XV���Mw`��sK��3�	�'��3��I�9g��|�]�e@��`�3+��ϟ����K�����`���I���<n���Ab�3�Y�R�����My��q ���ɪ� �Ch:�k��<��;����Z��t����x�-�������ѿ�}�i��.��B�L���R�5�Ʈɹa�X���޴*mDq��_(&Q5ר J^'J�#���	4��{޾�)�^�����~��>���1��P�U���_U����g1������M�q�>%�pCw�K��b7�v�&6�7����U��A�hgL߰p���`2��S)A7�]K}��V+�b��C!�ﷀ�z�_�aN�76�yo�<5G?���@������E[�𣄾�'��Д:N�� �7�׏\	z�1C�T8�|`��q�MҠY��4ҝ��}iM;qP�#b˷*�{�.��9�H���"����̂��s�ʫ�3��m��+]��ɎD���C�����KRR�!�l �@��n��K����d�~�QΏ�y�v��X�|(�H���ޫ��#K1 �+��ϋ�3�u�v4�ιjw�۹�&� �� ~�@��xjf�����E��[���Oܒ���8ϫHA���Ϥ�I�C�v���X�����-qvJ��2�Oչ�\A�
�D�/��]�Vڤ�>�@��Q��n��ҷ��`;�d�X�S&[o��$��}��Aj�v����?��O��D��7���"��PW�d-�(��p�u J�@�� �xk����\Cfa�#�ʦ4���9��(�� �Lm�{��V�d&bWe����9
{?�cɡ�3r��_������,&vYO�Z;�t��U��Mn'�c{B	uy3SG��$�f�_��?a��D�Ľ�Ь�S���|�xۢ�!�_Z���{.�>�lR �G�������yZ���z��lvWM����`&��W�g�32�1�*�.rT�L��e�o���bS�͔������ 0F-��s�(0POm.;'7x+�7�ʦv�Vu�w�9��,��'7�,����_m@-��@~�p%<9�%2 �x���d�`w!O�)������~����C+�xs!�26�u���3s��|�=���%��}�N�1=��隤��/�:/Sk��D<��!�Le�Z�0aT��Ѭ��m_�]��*Z�2�$��xj��gT�m^h�1�մ�����)���<>���e��G�J,�4��Ł#�{�'̞����a|�ky��(��V� �9�����ja �ԃ���*�l�L�D�w�8�0G�I�V)��H���<+�w�;���/2����	�.y,��� p�?b���Cn 58�
f�y��=,'��nm���$�r��LCQ{u��:h5��V�ഫ�ϰB��v�gҵ�9+Jj,,���N�zŬ���+P�/�_�G[���볓�g�DP\�N��.�P��ELA%�����v*��1]�����ɖm�����)���tqߒ�ۗOf\���2�˭*c�v��y����r
�}Q���'����V���})�������$ߨ[c�ke�2W��]�����l.��1��}�Y���|F��f�؞���ם%�v���(蛃f���H7�}��r��p��b��y7����L��6e�]��kM��ȈF)K�����՛S����m�%'�No� �y]��c(٧|��4�B@fSZ����@wv��9�,�R@`77_���4jZF��iOAH�"/]�l�<�(?��me�I����Z^����l�|���ȋ�85%٣�R]xu����3�gL�ݜ������_�'��`�%@�C&�i��L].���>����gfu�A�|����0>���h�,��uQ��w? 4����T�Q	t��J ������C׫��==��5�)��0�}l,z�1��5cj{�:&�6̈́�휪ȯ��%�<���h��`��xӾ�U�)�2���&�$q����@�Y�������3�_��Zfo/W���U���Z�-:�U��__Ս@�鿥�R4aO�wW�_ɶ<�ω(>B���t���:=�A�Ƥ�|��j��	x/K7�@C�x/gQ}QN�����M�nf|��|46.�t�t`��K�����_O�U&;��x*.r D4qJ�̶B�Eێ���`bcܢ�Iب*���1Ez���!�#���N�����%���ـ�Ƈ�=QTD���.P���E]���E3�V
|�rE(�1˧�O���/��wum�T���c���hC�1��Sx����3�I�n�bvҀ��n�ڥ(�P`�s�,�ӶȔ��ˌ;=כ#xr�����ƾoŦ���#"���u"S��:��9{�G̪W�e��.�\�����۴U������q�F:ò��ZY�2�X��	bv	���3�S�+ju���h�.8�d%Y2�Gܵ.����90E�D�K{x��Ԙ:*0��/Ҿ��#!��$8;�*u�ފDDq�
N��ְ��/ ޾�"���-�h��������M>����l�tf�.P�����G��ܥ�'Z��UF����/�Fq:�_�"�A��b��'A��r��'�� �'��QJI���'.nw��w�҄���'�l�7@L���H��z����)ҙ*�ώF<gƵ�RAɏ�-",��L��>�(Ŵ��oƷs��ŋ�\��1���xp7Kp]�Y�ט�a~v�V��s�#\��!mZe�'��I�O���LѤ��;V������t�����ZU `�(��nfD�
�@ �9l2������7���.-��L����Wx�ru���kZ:n�����Cpr���K�y'ʰ떶Y�.J.Z���	XH��no-�]S�x���7�t=�a�]�1yU؏�	m2���;���i�{�3'���S��W�|���}����+U�h�;�w�p*W�Q/>&�|"�6�}��e�z��3n��p�ޅ�kKRWZ�~*D��b�G���:���1�`����^K��	4d�4�Z�t�K�w �mϸ��8�B]�g���-.�a�?`�?�</�"�c���
W�L�`�)�� ޷�䜔�e>��9MO���9�?J���/B��$�=tҷ��J��V���݊7�H���Y��XM �V���g�> )�ڙd7Ʌ�]��~�<�-eX��8~���6&�<W������)���c�by����$�U^F�UA=�a��C��k�d�T�h֤1������l����5h���H�.�J�.���f� ��Qz>?2-\��a:��΄O�N�<x�����=��#mBҋ>�B ��C��2��
�{9�-hpٙ��_	 _b��e�QAL C���a�������w@�2�75�|\�=	��d�}�%����S#S�!���:�xp��K�i�R����e�I	��/N���L--�2���m#��{y��J��v}1n�	����o/1�#�_1�AlQ�T(��zG)�m��g�ڦ��G�����[I�B!�Cɯx�qɨg�n|b�4<N�@�n�����yc�n�h��\y�#~X�vGi�ֶ�F_*+�&��0�X%��'����=~Wx�8��P����)��q�T�^]]��ӻ/Z��r1Y	�(`�������N�6|}�u=nU[��5�m!�@���������1*�Fa'�0��P�*���sSS"��u.����~�<~*J�9�#�{��=_�N�͏���������X�ǙHL.��Z�U��[����]�<��&]�N�k4���ի@����r3P�;�8��h�q�B3g!≜3��/۴�l$v�+�*k;+m��	�}��cl��;5�+�a�:�I�{?X3v_�
�@���'�bԼ��TD������������h��z�z�L<Dߔ��Qq�,0L���V�C}�A��4�{�.��dw�̶��RTK�u"��������\��ȭw��t	%[y��ï�s�S��5�`|���z��;��pM_�2MN�i��I)�Pi�x��k�?r,���F6�R��{8�t<�VJl�����(u��U��q�ǹ{��&S�<B��E/�l���8~���m-i�
��l~v+A{Lp��M�,��[���>��g��p^4c#a<�V�&D������;`�rCg��Qgf!\@� !�S���:�Q�<:�H3���)'�C�.r^�ޯV����Щ},X抩'��=@ͪ�h]!��#�ȴ���؝�wq�0p5�W�m�����}J�5��J��U!_���l|g��=H$R L�٫���g������ ����(��?t�줬�?$!P6�9*��۶��K5���M(��-jo4iҖ�
�G���V�7�o����2��.�TU���?z�y:tl����哮�~�6�%ƿ��!dvg�^�r�*�B�8W�M@�.�*�Y��cZbw�Z�cS/5��B���͖��t�g�4������K��$��)]2wu�ք"��ev���j�^%�%o�M�f�Ίf���=<�ދ?p���q�IT)��#P�-3�Ew��;F2��w�lR��`1�I)u�^����`j�ԷCQ���s�����0��I�B��	���>&�^"�U���
Ԩ�#�xR�V�w�]�Ϻ3T�_I��z�I�`P�1S�eg,�{�e�1"��rpH���6>^�;TV��Պح��l��v	C�K��إ���{%theĂZ��)b6cb����W$��eޣbu
=�U�����w5��Wfp	��I��w�p��t�,��#�&�WaSV�F������_XW��'��ݹ���\�6��U��c��sX=�Q(5���3�)&��So����mK?��,�+5�"R6���Fk)T�v#����!Ҭ��Z�퉈s�}C�Fi��as��)��Q.��p~���"��j���I��R(�P1�G�Or�p���Y���٨�,q����K�~�2�|�&�+s�{���������e[P:*���q��ࠆ?QwM.�<��ʖ��ÂM�Өe���v��.DP I��M���ƐM��h�gΣ��C��+��ǭ#�ľ�8��J�$��	N$ �3T1�\��k�Yb�6�<����!���o���p��QH~R%>TPQA*p����3����7k!$�������.��/�[r�O�������ǔ��]ԻUܲ!����Ā�×=
BWn��=~{�#����K{ۑ3%Iة�1(,C\?���g*��m��
jo�_����C�>�y�h�a����5��Z�k�/�j�m�_h�Yj�＋v�7m�[� y��}A��. ��)�Ϗ��,�D�X�!\�X"�`�n���%v�p\b=q-��3�й睶�_0�y�l�����嶕>MJ�g�����C�6��:��.y�?T/�#N����ԋ|d7��� STDT��!���2�eC�*9���I��r�������59�ڽ����F��LI�Aja�7���YJ���[Ek&����2�4{��� �v�>����V�)y��D���Ц2��$�XG��S��R`�(��6DO<`$����x�7������h�*Pזs�w�Ӳ����X(������hAl�xW3�I�� �Y\[�E������Y��
�cE����/��$D�'uE0�Q6�u+�Y�a�F��m���_�6�C@A�Z��z$@�eه +�&� ���b��(�������|�
�*��î�)CQ�jʻҖ�q��?	���=3��}�b+H�$���-�H���z�y��zQǵP��f&.l����_ӿ��<����Ix�@�����5%*}���&&p�{t�R�l�]Dl̹$� �qË��o��R�L�`�/9S)0���ى<w����T�:N�&��2���[ �V�_)[��t�S���t���ii��'5������6�om��!8J����[L���y�1]}��,Sg'��h�g�g͜���1��C���Ŏ%;�s���Y�Mo�G{����o�����K��Sѿ�۪1~
����`�_��"��`�ul@=�����B-�0�����pōwMsȐ��;<q)�&����T�9#LiS�H� >��qh���¡�~��,Ә1�Z�p72�$?�hM����-]{��;�ق8�tj?�`��	)!�JO�{���P[�L��eN	7F�E�S����Ɗ�{)���ݔ��R��:�و?��U��ʈ�X��8��/��kj�B~�����FM�`��8-c�����C�ON�Ж\�T��-�y*U��;"x�_k?x%��Z��M�G�T�7\|���»�ql�q��z�����X�~��^��_g���n EbK���^�����Z��&P�q��������u�'[e�J�Fo�JD���7��K= ��hD��X�G(uD��O&�й���BY5�A��-8%J~�}�x5�Xk�=�)�j�����j��ϖ��Z�:j�֗�7�xa��|�xr�����k*�3�}��;Xl)x�1��P�}1��8�����G*>X5�k}w��xy�)-Nqk�ǈ�.5���I�8�~�g �3_�o���i��F��RTM �1��<'�Y.�<+l?��%��E���ek�ʚ��D�qmՉ&����������O���)���s��ZLwf@hIܓ�8td�UK��;�L�-��;��� X$���b^Y��0D��+����T����L�8g��ˮ|���C������KJÄ��03+�d��s}u�7��VE�
ϰ��L���ݏ=���G�U�oy���<"�n�GNr���.��q�����v��~���K� ��-I�*�[�_C�!�֝/Or���%?Z�����;5I���ʏ:]�;������ݮ�:��)�o��"� uB�-^��H��׃�`)^M��9��ىӏ�Hr�n�M��sJ��yL�#f�'m=u��{a���T���b���jK���T�X�29	�㢢�>��9D��	W�SgL��Ң��&R<�=�Qi�DC���mn���q�Y��yR��;N����U7���\�؇��5�0�m�T�w�-@�n� ���٦��tߘ�y/3�=�.(*Æ����>��ef����'�Kb>�*9���1�E`#ta�Xzr���<����9�*q�F�-��V|�B�譖�6W"�V�0mS��\C#�g�����w�:2�	��2ց���\�q���2�0������r�G�!ԷhF;o�xj��{���"�[ԒX�����	Uy��"�)f����dHؕ���C|9�F���ϱ��x���C���ߺ� ���$���W�X��qGW�����j�a���/��!���Zvc��<�*{���z�"���K�l���x�(hj����^��# ����^�d�V#ggi�G��o���i��/��qqӓf�6�1��2 E瀍�ݘ��+����{�߆%�|f��z*j�	�x$��_��?�Mp	F&����)O���u"�sX��F���\������xɻ�[���9�23X����*(4�TH2�@&.�J�aǭ��m�fr����'�w9g���H?�w~�-����])��C�<������
Wy���/$�T���J�/�9��ýV�����_�K���q܌�~�����nE����{��P���4��� a��\p�X�9�-�|��|��(���T���yG��@�k���%��υ饀A�,���ti�����gt�B�]�4�-Z	v�N��A˼nW�>��!(��NS[�N|S����g� ��������`O�R�/�)_"U@$���NnjD@���Ã�+��Oc<�P"I��Й��$i_^��U2ij�E�R�i�����J��bgTSJ����~��`�j����I�Ux5�D�H�͉�{���}�v�4��&���4��we�]�N�P��l�x��?)��g�yc�C�AQ��pO	D��w��NЇn�N��pēr�`3\��_��ŀ^ �fʔ�D\.Q]�΢d�g���Go׍X<^��%ڗxm�jm�����!�#T��>��B[V�ryE~�:�-�_8�[��!�X@(� TZ+�ǁ��6q�Kn9���Ɠ��E��Šf�Q��+$���p|�Z���=����Dک�a<u�^w!
my�ǜH�������rV�ǟ�t�ב��`Q�b�(ɥ�30�֎�zڈL̄[�,�LD�C'�A�p���KnE�!ߏ��52k�q:\p@����>�,��+cT �.��x3�t -�@��S�@ۏwVE���b�[Y�����ډ
�p�*����8DA�B�.�z���c��{s���G1���[B�hJ͟�������&V#_b@(��*����I���R0���l��_C����.l7'%��K�L��V��,(Y��g`�K�W��Kt��n��<�eD� .���JP��sX�3�UaCw��&�v	��wkfI���5N�K����\U��B�(�P�M�g�R��G'{�q�-c���qM�#��T��ʴu����V��]��0�u�].W�C�_�ى����x:=��VI(uj"�H�� �s�-:�ڭ`�|Gw;���?Gn��}�vO����J�
���� ��[�����Pp�5�
o!�7qi�_SH��Y�b��r̩�g�d�6�$A��~ b����V��Ǚ��r��D�L6��Mu�b* jgP'R�	J'Q��y�%K"j;q8V�`s�@5�������Z����H%l����U��q�k5�u���~�R�ǎoa��[w��J���ΫRc�m��-�
�$�e
�+� i�L�yu�\c4Q�9�,��q�X�P�2��,�:�"��]��U���a�z_To��+��<��1�5�ܐ���z�]%`╠�_"��[�p�y� ���,��7�K(:b>����,'��Ȩ�.I|e @�h�����
}k׻>�;}���(��S�	���\%�⢙v�gş��-�J��w���+t[(hL�����{i�k[j���p��$	�6L�zt�s=��.�H������L��Dڡ���*�(��in�>�\z�ɋV[�)+���PCr�a���?+�Xl�����*Yï�1�XNA��}��݀����@���;�^�Ch���JSˈ���O�(V%{����=�ea�>�ړ�r��s�	�=d��1?q�`KX)�8��G�J����~~
�q���`�}�l��|�vWV5�>���X*��ۘ�)�����V´�e�̟�+9L����W��~���CLV���F�_6�~��`����Jn�Ħʹ�a�P�A���3�{|\�N���N.���k&?��K�N��W|ID`;� y�_�#�HX1����	�xR��۞]n+�@`�S�������L,X��/�f��m�Dzۼ���o��YƲ�����.���p1����n��"�k�!��f�R��棷��O�usצ`��jR��b��D��\Æ�f�- oA�/5k�F��(�R�wU�]�%�N��)$Pq��h��.��9�+��d���Pb���M��0�O~@�Z�v�����b5����a'�>�G��2���&���4 O��Q�(��3�������~㖦�i'U����"��I��9�۷���<�6�h��Y5���$;����r���,LSg� ��ukH��Q"lU8U��|��t�
z`��{{hb�Y��9+$Û�]�&բ\�;y: �o�jg��`qZOC=w��Fw࢔N�lR	���o�G�uU 3�g�g���<#���2���3�+�n�UE�;���E��-[��HP4��I�����i]9����z�ϣ���z|C5.����^��z`kbP:e<i�a���&��r��Z�ncv�6v��%�>;��yR�ltUXZ���L�Ei�H�<+�Q?�	���bJkݧo�T)��Ms7�}([<z4�>��R2J��������o���i�Ǒ�?'�6rc��dK�'>Ok��:���i�gW�O��B����<�a���d6������!�D|3� ��$79H��I�n��[<�\нTZ����%ƊГ9r#5��+�U@�%��\�w�(:��Uj�F�%ne�TXMs��f�F,�p��>_l��Ϣm+&�a�_~�����?�>ݺ�z�	g���E!!w�>�=ޭ�uw:���&����j����Sw��^J��%ڵX���C9��ث� �MK��`8�*��ö���
]ㅌ��\�㮑 ���#u�ff��(�O�pJ�XZ��PvQ�T��}uY�-���@�uRJ��� �Vpi֏z�����$�sZ�8^|���N-�H.�О����.�Y"i�u)-�V��'U��p�:��&I�3�J��n�ϐ=Cg��z۽�?G��%���f�Q��ێ��>0S>��1��EP4�o#^��=��ޟ��w�����tZ�ծ�Iq�_��� �U�+A���[`�=J��������2�Rp_;�/����W/)��1��Ď��DE��,�i�R�b0$�%�
]�3Y!��in_<���A/מN�:��*���Z\���}J�摧-Ts���PY[�y[ܭ�+�J�j���Wʫ3U�Bz�ۊZ�
N���� �J�HQ����w�67E裟ӧ�Z�����g ��ڤ�,4�i?l�7DF��]�2$�� r�� �6��"4�-Yfx1��ui��z�g�$hdĀ�9�s�a09f$��1d=�Lc���!�U�P�r��j��B$Y��ed����;勚����=���^�fC�+�7.�6�.T��<ׅ���W�}�AL8� #�,%>��`:<q������F� ���sqH��H�W뾵{�7�|g^��vi�ii�m�d-l8��E���Έ<'���D����P���/i:&[BMgj���װ�J�R�
�17��N�y�J��!B;��ʇ�r鰈�V	*}B~��g�DB��U� ��$��mu�m5�tJ��CwD5. c�o숺�Iˈ3��B/X����K�ݳ^i �k�҄r0���������5�Nz>��$�9Q��H5>�M�Є`�>[�ܪ*A���&X_�mZ~eK�=���{��������zId������t����4���f$/B{�z���/|���$�N�N����
�W���_�LE�T���7.+�a�>�14b�}����6�64vӴ��[���J��M��
�>��h���u6��"Q0��
���2�ɜ��gDN\���-�pX��$�$���h��O+@��Ͽ8g������w��)&C����#3X];��wd����n~!���ĉ�_�O��hE	և�,����r���.�g$�%
Q�|S��_�#��𖎾4�
���ƕ�V�킍��څ���`g�>�3YVHf��<�\P�j���uqs|�cq3})Zq< 7�R�#����;h�М���"��m�ڕ�T�&�u�F�?���=�s��m'�g����)��~�i-�؛�B��r��ftv�]DBcQ�e�^+�S���nǗ�Z}I_o*6 ȥK�����ˌ�Y����[�L`�����Ⱦ���Rs���&�ۿ|<�<�Sw6�J�o����ǐg�?�EÞ�6V=M������;���!�%��� �zn���㝩jE�ǔI6��5�x	���S	�z��(�P���u�]DX�K�x�:�uj�%+�&ս޷�Q�Q%�j���%��Hy,`�e�R8_��L',eF^���q�)����O��!rm�y�6��k�qI�ivp N�����_��)8hf[Ϥ�^�8�Мq7[��V�Xʧ�
�����lLqP�Ɇ]R��h�#v��0���i�0·TFq�Vf%QF~$v�+����[�m��urܒŚ�ξ买+�0������{�*��%{��״u�%9�.�}�:��̈#W�׋��IF�UdV"�0T{����AV\���#!�y8F��r�E�)�G�����Pf�;z?1�~��C$SeQh2}��,���ӕdb��V!�Y= �م��f=��zsU��5,�����c<��� �_�����Hs"i�:i�c�Zj��/g7�e��� �/ui&���� �b�n�7_��8���d�n�T���	���vv���eV�O%��9X�՚ϛ�D+���2Եm���~��j��V�cV�b����^]��$��O��=~��O���Y�!D~�y���^��r��.ݬE\L+��L�aZ���U���Xϩؿ2��m�f~�*�}}�7]�d��:��`�B����x����0o��=��ڗ��+�+�3gy��ln��yC�5&��,�����T��="����
���:��E((2�3ɾ�蓢U^:���`�w9�e�k�@7�����:	0��n ����³��>�p���d��](��'$���_��&!���*㫎G�ްPK5~А�����;_T��Y2�2�T�Ș�W> �Ҿ���.�֊�ħ&߳sd�XGy��i��Y��K���0�(-����?r�(`?8�W��ֱ	�ڮO��l$�Q-���k�LF���zb,�7�A����~�~T'�ȋ���J�r���t����18�&˺��ϯ]ݷ~8j=��㫂�&
����z����#{����(ز�&$Nȿs�5Ļ��q\Ѐ݆W�(e�|�}�\�_�~��a�����]l�8t��N�PV�٩I���zU	=��"�өT� �;�Q��bL{��I�x:�6)�J�k}�6Gw)�:�1VXz�ͭO�.�4,����v��O^ 1Jf(����Ǘӝ�-�'�%��T���.���<X����G�
�xH�ڋ֫��TL�B�-���[nd�{�
Z�36�����:�u��Y�|7�b���{�!��|�&X}
�,���뒇7��ٝy��w-IGڊ�B�/�b�D�d��8�PH���ݯ�V]77�X��hf}�j��-�<�CǼ�f���G.)�̬�-m.�����Y�N��=��H�T��PǤ�E�]�3���f韾�t��㙉L��������:1���W�:����h:�4mݹǟ(����Vʵ��B��*�j��`�Gە\��J��i#̇)*+4��k���@N��ߴ��d�2�iU���-��~�t�x��<�73.�_�cI
L���n%�LTn�I<K�D��l�~�v�u�$�O��K�\��!��:�Z'y�qoգ��U��}���E:]�3��B��ӺI�-%�m�gH�<�5ۆ}pF͸����Q M������������};��d+���
�`���_��kc->�����z�)����@|d?{��{�4��"pb����v'��*$��_�m-k �`w%�S �s��O���W��W�7��C�e��"�<�A�%����:٭wo��F�(�}�Z�n٤�����Ԍ�*~�$VRK{�ݺW�z���<�F�;�u0�>�ւȳ�!�c�t]�1�ÿ$�_�π�Nc�<iL ǣ��.T̙A����R���~é���JK��������j�)8�1Ģ�{�]�j�k0��薑��Q�6�9���U�saxHq�-M/fW<�H��ʚ:y�����~s~�S1Gj�]p�3�ݒ��}`�ޡR�V�6W,H3���+X�Jm�\��J?J��ǂ��a�	9����Clex, |uI^غ|j�[�� �M��z6�VDh^�=��30��6s��X8	:w!� XYƃ ������j��g�    YZ