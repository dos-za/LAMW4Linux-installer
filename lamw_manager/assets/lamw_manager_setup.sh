#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2111547938"
MD5="51000bdf1ae2b36a243327ae0016d1a8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26012"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Thu Feb 10 16:59:30 -03 2022
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
�7zXZ  �ִF !   �X���eY] �}��1Dd]����P�t�D��f*�[����n�|��(Q�v�I��o�; ��zu�֜5��֋��}12Lt�"~\̻�臾-D�W7�+W@�+kIi]._g�P��
����՜��� 
g�,���di��/�Or��M�P8�)�j�8�j��ϱPޅF(�*k����rDy^�������8���Uj�&�_-�����&i��M0�/��l5�i@#O�;�.�zgC6F����k����/i��%ޣY��š����q��]K�����C����ԯcX'�B8��*L=���2�.z������۰7[�Q�=�:�;~�C�@��4�4�w8T�Pq���_8̤�v��5�@��]�;SF��8����5���L�M�_�����u{�]��*=��J���Ƈ��D����h`3�O�'K`H���Q�j�Q�DR�׸)����<�̱�!�
Ô|f�x��KXV$�$���S�F�5�:˪'���G�h'�K]�F!�օ*�@�%j�}���%Q��R�¯����<������Ӥ;\L�6m� )�h�Uts�r6K�7/��4��Y�xr^��um���y�<��y\�`�y,8Z]UC��c��`1���&1����c�����ZWd�;HZ����G9�3��x�_O�PA�w$�I�)��PX���S�ԁ��g�W��Z�'���8�z��eeb��:�W���8�n-�5��\y:�@�^����Y`#~n y��!GdX���c?��P���N�X��U��`B���W�C=�;]C�PeŃ��J��tSp��p�Y9P죳��q�������C+Ɲ{�ٛ�#g0L��DE���������еn�Mb�PYo+�7�²�w���'�Y���&��s����3(�h��Օ_3H��Rs�Q�F�Ȱ�Tڮس�qs<���%�c�+.��UM����K��-���MN̸y�96Q��
���$.�Ъ�{諵���D^Ǖ,���16���r�K�t��椲��n����۸�v]f��?|V1b��E��Ǚ&@����K��c0�mv�Aaʝ��2�2=�J�-*�R<O��-��r���7�-���Ю<����t��b�1n��엛ؒ-�Ωg��lg���+�0�kt~y��w��D �UZ܅�k����z�ʱ�s�'�Z�mt!�E���g�_���yYvB��~#�0�(��=�¹�B�����\u&;��K�`o]M���8 �瘴�q{je�`�zU�4��jb�pχ���R_�Q��I�:�����MiXZ�W W���Х���}��~%���*3]3G� p��b��$`�0�SXЌ@����W/_���k��w�h�GK?���5��t�~��͓>�"��Fp�n<�˗�Ӛ��u��'VA%���y���o�=8�E�2�����?mߚ!���ux�붠��S6���_�j="=ӄ��>ϯ1��	�]�U��9NR��;�W]{Ê�^�B�X����[�D몱�&Y��[�w27��=�5d����u�^�Ê���zE5*a��=��5)|w'O�&V��&t�ʵ/Ԣ�`�����gY��A�ԃqC9��/�k�a��)	�q�</׃�@A	%-�3��Rm�@u��Y��=�8�4�'o��.I�6�[@fD��c[�����N� Κ6��%�=�;Sˈ�oӚ	�aF��姉�"�/࣓�Ȗi�#|�ʩX����1��+�q�7"ѻS�C��q�y�H+������������b;<@����k���딖���A�u����'�(3:6�Ŝ; S� ;�2�CO�y&B@�㴁^�PC�-�:�q�|�&��~a�.�a����Lzt^��K�pS�w��]�3�̭��a��2a�����?m9yS�r��_
��M���KN)b�_T��#\�'�L��ڽ�2ؑ�ٮY�B��pA����6�`ǲ�m��2�?��,�]k# �� ���YG�v�J��!��U�����e����R|�營�!��l���x���#�4���Yr�lk]�1�X��`����[�oh�@sRx���8���a9����ybK��6�OVLcM�[���L��ι�M�i���ңT%݅C{S��0������",QV裏��hD�As}\P���v�D�`r1�d����`�U��z!a�j)�I� I�ܯ�+�+�Lgeє������&wC�hkfgV �r�|���
���f)�¾]���RW�W�A;o�q߉l��R�˕m���%��:{�-��(j5�T��U��;�c��2s��^UQ!kV������MPQ��w���a�s�	KU��C��GDBR
�C�a����C�ڂV�3r�KQ7�շ�Y���g��?`5��M7�'�u �v��f�!��X$�A\L�'�>�N~�1�J��Kn�}�~Oh���i&�~>A<w�B���gg~��|�k�9w���=����!��]�Q�d
v���ޗs('J��<���ظ��Q�8h=�T���h+�����$:ʶ?	ݷ�$�o�6���ŷ�D�`G��!��<��-݈��:~s�F,�K�٨e�}�\��dK:3�q�ԖY��qW*��?��K� b�f\���e�7�N�a܅2wf�y�h>��?���k�+�k����.�yɔp��c�U\_X���bq��![=�s�,�O��F��.A8`":p�f	�(�=9sj$�2�:^��r�!�٤���z�]�/�J��={s�o\5�E�����=�'8�F;.m����-:Ŷ�����,@u�`�x
�y%��^~؎J�x'��z�w4�&�S����Nsiv�O��Ѷ����֞����Ef��^�`Jɽ�@G��;�-�O;t�� ��j���}p�d��p#��SB��S$��#�vS�ʯ��Ư̑�1t7B�y�n�1���E$�VY���qؖi��j:Z�򼲵�K�k<g�5�1	4�^���i���\;m�!��>�mP?	hB#2����f�Y�c��Fnjէ*���i}.�9��� �X93 �ob�����$m��5-�O�������Ea�\:�V��&���0�4x���G��4'�%!
�l�h\�R�JGM������� Uw����!��4�>������4b���?J����.�6�"��rA�*�1
�#]�\)qP��T�_:$9c%�Aa��8*7���6��^�����T��î�mt�r�{k����{n&_��I/ ����Ӽ��~��3xI��X��jD;���h g�a��
6��F�K
K��|�[W�$"~��V���~7�D�&^��������4���������G?���]3��(:z�a
����Hd%� ��,����#m�I��A~*I{���d��2�����lD����ߏQ..��ǸnE���Ф9�5";f�tW�D�ڝ����d�`:����x�C�e��!���e6` ��dQCTPL�$�Ex�\�Y����)��g"#|_�I�"���k:BW?����Wó��ґ��Gg0����;���
Z�0<x�u��9iE�ZH��?�uk�#�6}��Z�e�P�����H��9�W�tV�յ�B�@�L�m��r�S��"�Es�+y����d&� ,��9"�B�(��p����,���A��`����(��Ѥ`���{-��b-�7�Jx�@��:�6�6y��,4˨��g��pQ��Qf:ߎ*�~PўXր������.������*�>:{�� K���t�Y�1m�?u��$]a0��� +Hͷw�yo���O�$^�!�[į�/1���8�T|[��(�@&�<�	N�7�>��V�~~��H��R�\qc�hz
��W{(;uH�>nt�c��t6�d�@l��)��Q��b�F	�"}���g��R5D�U����G��i�Ip�W �Z]P��i���!.��mG��{��?F4?��])�*�츓���&sH����7�ROe�W#;"��똻�1P)=����)QXw���C�vc�ޫ�Z=�Wϱ��D7̢�����=����Z��-Fr<����'�*�q!�8ݤ�f%��s�2+�i�?�����m?�4�6���C)I�uaVħ��u��栎��.��Q$d}����Vb�G�ݔw����pR���c�¦�.��k{]⚴\'�Q���\U�.p�������)�Ϻ�5�;3��6ZW���SL���g�"c�AnwK���X������>�_: -���ւ�6�m��V��P�-�gHm;7vI+?@�@�w)�pv?��Ow�tW3ܺ�{���?[E>��蓒��j�զ���<�G�[�W4��f�O�nA_���v��K��{]3�����D��p���gGZ@�$�ЙE\x�Bg�<�7(��|�[�R#��
���Q��fn�۵XR�O+�D��:�^A��%ɀ��w.M�(,-�y��΅��:�%�M;$�����`�
u
���:��6��XۈBl�BY�q��c~AZ="?o�68d����JP��l`��E�c�07e �J{��EɇL<|Az�#p���)"�Jٯg< iU)����l� q���ia	����R���cx�������.P+�Ǆm�%ʛrr;������X�g���~�A�����l�W�W� 'ql&.BWF_��('q�����8hnZ���Ap��4�6����Lg6��A]������Kݒ6 ��e�BZ�հtR��R0��]GG�@jzo�r��>�[J��*)�������z��RR���h����_]�97�o�`���Ǻio�����[r��=��u2R�o�D�ً1)&{z�R�2�ʥ��f��B��n�� XV��ג^�/H��(K6�~�%dMH6�.�D_A�+���7<1�c��m[��G����G� %�푭�y��u7�j�:�4#8�	O�rz!2ȩǙT��>��((��^(��YJ%
�E�� ��J=P�Hu�y�9B�:D"T���k}?��Eg-�t��z}d��&�j;i�1�끛ܧ/f��&���^;��D��!�qc���i���jܔ	M�]p�$�bRO�WJ��=�Hx�_��WP�&��D�RSiF�&d:1��2g�0x�R�ϗQ �������4[Y�)���|�w�@l9CŒ?�D�U�^La�v��r����&���lusX��@�R|i�ж	�e��a4�~���0�wfa��@�G��˹���ī�"�3�<L�)w� Ђ�:tt ��>�@�����y���hX�)TB=P�݇�m_����\p�E���x�
��lP9<n��u���'����C�gp�ҞJx	b�oĞ(�2���q�m��a�Pt���Q����!HD�(��FͶ��)�	��]U�A�\���	�Ƕ,1BǇF�.rv��Od�͎��Ē�Ε���p<���$�<f�>�#�%H.6����H�P�4��Re�7���'�j�RV\y�$Un+p1�r��W�:�����^��&�僳Qv���*�(e;:.���@���_B�h'y&�@� ����)�r�c!�zN��-�@}�w��+��mG&x�8�d���ݾu�K̽
_��g7�����KQq��m���ώ��'
���>�(��H�����>�� ��d����S6������p؆�N��r��+��W9��Ch�ZX�+�,���،��2tKeWVl�� Syc� ��k��x�v�&�����H�)���Cs۫z����^�Uu�/]J������[�\C�V��B� j��KY�j[�����NC@�c��~�{��O$�R�ܷ�\9̊����WB9�`��8]��@�gMf���U�\�
��r����:���+��\yȯF���4�^�1f��qP��6O���=PV�b��/�C���vcX�zv��R�0`0�1e >)��n�vѩ���'����G$:|Y�s%�R�ƅ[��9�Gc��Z�mb)���:Ք�����A¨�~� ������X���7v�a52�"������nΛWAx���b�!���/r Pl􄗨��<=���,�)��`h���n�pE�aMσ���eMÍ�a�����[y� �aۑQ�|�Pt�W�T���k\hW_e���R�����n��Z�z��t9�Qd!�}�mm8�(��b�ݨ�䵕�o90�slG�X�^��������.�?N�����CB��*�<����8�؝��U5Ҵ���D�j�:��{�	���5�����gs��;�΄Tz�� 	����=��+�T�n�+�a^�sd�ݰ^�_�)����]��8!�9V?�j�U?00M��'�Rφͦ
RI/�WA��/�̰�Z�S�[_$pF���.�ur��|�LH<���p�����
PV ���&�ݍb����E&b��澧�lf�y��ӿ��L|_Ĺ�4bW�\~����lН�C�p��,���<j�_
٣厰�=��,T��p�n�	Y�/A]<��v3Ou��R�Zbo:\�ߒ6�F�ջ�b"_�+�\7�d5K#��Y��Ӊ=��F�uꫀ^,0W���3��ST�'�4�ыI�P�V�<Ѣ�����r��N�L��z�45>�,ӑ2Dx!w���Y�j +��ݨ�n���e$2�� ���/Ƚ���<�׾m[i�áp�Q-�:���}�����\7�A+�;;�P߳2ڻW�:���<h�yzHJ�[x����X�� 8cAY�G��L���������XI�fr��I	<��4L1K�#ǌ$��N������).*��,�����~U��r��p�$e�Z������T"�2��1����>i2��i���g��2���N<����`]a�?���s��+��g�!�	D� ��~%Z�xw�X���Q(�9�b̨�Ζl���g�� k*Ky:!������;�.MͭiU�0o�Vbjw���!�,�y��U�\�[��Fi��c��uNT�{�� m�d�Y������+Ab���k�h���	p�D�s�.Ezz���U7q����BwA���@%�b�X��Z�&�탕?~.��}\�X��j�3�r��'�eq)B����N"z��-�g�"��`!��a��me{���6���'堕��&�^��4,��WM2X+M0��E0�������pj��&�ҍƩ.��(]3'��ʇ��9�l_���%��\ov����P����_�:\l2��� ��A��ƈ$ƌNÓ������ (�iqo:X[ ��R��[��@t@���W���ަ0>0@[ư�R
�e3��g$�T�~O��4�73�s�iz0͐H�#�K���;��Zzk��0e�psǡq����2T+��`�vO���l�~��d�|����G|-	��PZ`�C�5Z�s�fC�R&Ǫ��������V#`c݆���$<�;(�5��3s-uV����+C涞#s�$��/5�5~���� 9�4��5��W�ێq�j�ZoD%�@�t�	k���ϛ������'�J����H<޷ͻS��!�rܰ|9�,N1qA�ߖ_� ����cm�_RbHS�p�r�sij]	T%��(���V� ��rX��~Y�����NS�ǖ�P�ji'Bjt��(�@y�9� oW�,ml��������
iq�I��}D2�����\��!��w\�ڕ�
]��|'�Z��h�����1��6��	Fү
��_�H���c���|Fv�8��t���bgMh�Մ��4a�16�u���퍲Z*��W*�x��#t�mBVitr�"�0��eI�.]�6r,=T��d�vd��*|zB6�M6#6-8�T�4O��d{�O��f�'�ŀ���H��V�=f~��'�䠑��~zpy��o���=>�B�䇫]��{g<ﳧ3����u�giT�E9_�&�aC�r�k�kc@�}��a��A��`���Ҡ.w� �򸁾��ބL�JxC�]�$e��{��Zl��sy�i}ߙk������:�3T}�3b����h�i�(��0��UG��Ҁj9�d��	�$҈�J�%��A�mW�\(����M�Y��ͬ�
�/2�$r�fI%���
���ߖ�|��^'P���X��%�y��2�4�P�4�H)�Q��:ǽ%Ê�*kL��R�-q��͔U	n�O�o���$8.Y@�o�ן�ֻ����И�Z'3� �F~�����N�V�c��5%���K�4z������`ʃ�|�b��

k�T-�֊�ҝ&�|��"N̠���$��*^�	K�?w��B�|�Nb)�l�U�Yr�V
����θ��t�w;}�ށ��@vse���0��NZ��Y���I��Pp@�6k2	���f�ч��zb��V�U�����ïd��j�l�����J�]j/o�n̟��	�
���iK@�?��H+�K�����:"��ڳ5�.�[���-*	̨=�B垰W1J��&y��Iz��-�Y�Fh�����H�D�Һ53��!�y'� �ܦf~�#(�_� X�!k:��nP4�O�<���W{9}�8���SpK��[Bw"��C����6�O �_�&m�$㙨��R[�ċ,'R���=X����ѵuƠ��L������	Q��(��>����8[d9�)�a@�		�n-I�㦘	,��M�T\d��Z�Q�)4b����=y����Ռ� 7O�տX0,��+P{U@��#ډQR	v�lAIgܸ&4��+q�M����(�k���Ǳ��V q�����s�=�f4�6j���P���Q� %�����f����o���z(�~�ۢOBrY'J��j��k�&_���%�H�\&���Y�y#c8?4"׵�v,�u�|<.q��:�pՉ�y)���맕�j\ӣZK���Z�����Q�ӟj�`�x!�HIć�E���,���DFV��b�s�qMUZ����r������k�g�nz?����,�p��7��s�e�<����W0X�^�O7G�/����z�<#3�S�Y`���q֘t��
�3��kx&:��P.��J4̇��J5�[>��6(�h�Q\Ai�tʍ�}x��fw��гNx�XZ��r8�N8O�����uω�⹛C���2�K�s�QI�8����L��ZE�]��JV��<���$�ޫ��t�o�n}����x{���u��Ǆc`)�aĆ	�̪���ߦ���'���'�2�pw���ȃ�vJ�EIpG��x��D&�I2��AWJ4N����`? ��|�dG��J`UͨS�@���͇�t��݆wVd3�Y�����av���Hc�"�֯P���� ���з<~�΋�+��K���>>��n���-c���1���n���;u�tx����>��	��
�`���-�_4�s柃XvR0�1P������d�����s���X2��?�G�ê-�J�o>C���˒���
��`��~�2����@)��i�!�-ikv>/�Ƹ
	�<�֮�^�dQ���ֹ��t�����L����ŝl3�Yؖ�	��=��ww籂��?fn�Q�h�jJT^�Uu���H��'m��df�zW� ��J��ݭ*zT#5�S�];�!�u;��XC7���Bm�����LxQ�
u�ѡ�N=���}��7\O<�Vl��!�{�D���i^Kb���#r�{��������R��&���.,�@�"���4J�+��o�Q���f)�#v'`Ճ�lg��O�40����z�*p�jT�9��Na~�#A�C1��O��POJ��c�wtM/��!l14�y2���K��9���A&���eh�?z�� ��/�Cq�}�)N�:4}8��0k��&	�����fpg-bgn���L�A1�8�Ƽ^��L�d��t�ԃMlD��T�\OO���D�?[5��L2���Ș-�Z��p�+*�#�23.���x�h*�J�6�W�b�#��٠u�g��y�R
&��{7�i��u;n�A�7an��&�^,G��~�9�9|I����ꔹB�P�J+u���l�d�?��P7�i�����xHJC��$Z�X�&�o᜻��ѵ��\��#��C��(ӝ� UxiJ���%%RO>ޤcV��_����K3r�r�-R1d�h$��T�D�n�ݻ3h�ufIEqD�eg����N,*�?�����P�;�S�CWlͰ� P�NE� B(�����6����?S>��o'����ߍ��琌8�Z��!դwh"����FŔ�ǅ�S�ϳ�s��7XnZ�@Nd�KF��W���o6�H:�_(���,d��:gkzҿaf1�(�Kvp,��Q{�_�I��&��aޜA+Y����V���m�ګ��;���9�f����������Iz�.�=V�I���L-��J���d�3�A���h?�#����n�$�<�T�j���� ��֍0�ˌ��=��D5M��{�t���Oz�a����6ߨ�('m��﷉��^Q���I̷���	oi)U�,Codi����fTE7�j<�Our�&��,`!,���E�ݕ�O�,@��CU՚�������rJ�,L�n;}mJ�"�@�ֱ���h��M�h���KƂ^���|��ב��u{f#�k��xZ*K�}Y�l����@��cƇ&E�U�;p}��.�����Yab0o���K�sK���b���}QV�ls,cڢ���;�򙝚.oyRf��"zSmy�G��H	n��̣AbM:� ���A��w2�~R�^g��� ��	+== '���7�#�&����L��
	AVL:%=���C`�K쟦S�����&=�:�L6�ۧ$�f�(�4!�ZG�6�y�W���mNr�����dhBν ޖ��zCi����ID���J�6�u��/.yP��S��D֪�vC�
�&�xs�P1s�M�k
^d�3Q���x��7x.Wv!K8��/����;��BG�i��N�a���ٞ�2��S�X?�1�qs	z������{v�ә�ә��P]h����_0�{���$���G�栻�Y�j<Et0"��i~��~�8�xnMq�B�z&�>��bQ�� �)SQ�E;�CSS���P3PK��Cb������~V�F�ުP��@�;"�?>eet�8���ƆM�2�Cݎz��I���@�0��}��?[��@��y�5t�����3��9�.�Ռ>�KU����er�R�����I;��ݟ�CW��Dq1�@󂩥=omH�S��ƅGeanlw����O��������i��G�	k�����-������F8m'���'�A��ԡv80��I/���{~�a~7�E0��\��XSg�,��]F�l��R����)!<o���\a�����}r�����p�ת ����MC�V .����n�\��'R,O�@д���P�sQ����2�#��A�� � ݝ�����$B�&
e�*���.�n�s��hh 	���l��r��A� � �Uo�����l (���p���$�Oi��%7����ŃH�|2f9kcY^4��e_n�0�F\��"�Gi4���C���5 ��t]2(�,����S;F�� �ݜ\%�:���-F� N����k����?�*�����>H�]����eD�G]�~u�D�~���L����ֱ��ؤ�Q%d����i�1Ӥax�?�|:F-,>M �/� �=�,�#Z�n�4/�">?jĩ��+�i�:#��M�چb����1�.>�����:?43�)�?�l�p�ľJ�R�����u��!�﯊�}��Q	���WU)_��X�Ԟo�<�����/j3�_~�pa�u���D�B��+��0mt��mI�%�ɎA�Y�ӝm �u��sH��]c���"j���D�\#�+m����	��=�g2Ԩ#�����Z��g8�ir������0���]�݋��4����/�[LUN�(5�ؗ�I4"�2mm*~O:6D�p"����|R�͙��l�?g:����M�?!��g����~$n5���~n��ڬb���1�A�꥞���޿�)|�����!�L��cU�(��W�z�	U��N�����l��f9?1`)���{�^ �C/S��h�=�%��O��m��uTK�9%+X5u%u��e���#�����PMIk�	!����z��V����#L���>��%Uqsg�c�t�~?bf`׷kn\�m�	���� i���t��z�)|H���YxJ3R��(�ax�U]AU�4m���\��]��E�$'�âh�в��ɂ�j"��L��Pޖr�1� �ɝ�.����e��h�e���呑 \���~0@��4�0�[�@��A��
CK��+Y�ʚ�%Lo�@�o���_��n��=@T�Q7�{"�ս�c�6􀭮CMuH2�qm�J�`B�5�u�8xl�GeD&y����c%�Oli���9�-�	L2�A%���l��	���GV�SwRӣ:��4r$^���Pl����j�h3��o��>��Se�p���pK2�ƍ�ӋU;裵��4-|p���F��~Ј�g��Y�'x�W9%�4 ���z%��g�a��?�5�������s�9 �������|ԍ�=Ii��y�9焥�[n�����Q���'���lH�Y�Ƌj���������ΪmA�u���O�eމ���JE����}����ᴠ�f���&��qδ-`δO1�Σ��������R�N��b�R7�.���V$�W�"�,���!~ �C��g����]nW�Z[�fWy�+瘖A�.5�Ҵ�XQ�sihy��p�}|4<�J�[�_���Q��
%e�͡�'��v�dтg�9t���O�Ʒj� 7g�v��~�0�Y+��ܖGZ��GTS�9K ��Ml �u��#�*ԫn�C�B�~�G�۲�T�b^���/�*��(u��p��7kȲ�/�Y�_N�[8�~f�`����bg(ⴏd|�1Ļ�Ů�n����T8��*IF�N�}��f���oa�1���"U&ah��&�*FE������qk�#$|�Ń��͡d��}^uN=j�k"�b�3�Q���+��f�ah��1ԾE��s*E��N?#���+�~��A%V��3G5�r>���쳶;H�KCx�!�"�Z�.��_�����9���v� ޫm�sǠ� ��q�u�������Q�n$�í�|���/��O��+pW�F�W��ݘ��0+`��M��S9�a�������Jހw|o��ך��i`�������1+�ߊ�R�\2�=��0��y��aP��/��5�y�8���OA��0EE�z��J>�,8w����T����q�Ի/�ԊJ7t���`��i��C�˹5B��Z��T�B�6��6\�o��^}	4~IxCѭXmt载oK��@���ǋ����PX/^��mȴ�A�E�d��T���� L�5
�.%s�ނ����%���GkQ��L�¡�ח'���.�b���t{s�AY>P�]lx(��eͱ�+bP������=Yl�e���n,9�����d������z��A���K���>ٕ��&����5&)��E���8��w`�qY��ߟ��M��d�^�ލ0m�"_"����z}x��%�;���9��[�6��WC�}\Y��0q��z������+=]QA����oc�G�����^S�Ƶ��($wv}Y�jVɒ!���	X3����_λ�q2��bz{�׋�1�j����#�d�	M�yu��Cu�x��D`c �A-���p
}�F���y�7��P-0�wrj���;����J�.�d'���oy��0C�9��@ ����F��7d��6�:at�/8���@i7��"F7�V�&�A�k�v;�o�a����m�
;��z�{��@S��\h� &"���y[Yc~s��r1q�*F�p�'��^x��������M��|�����z`-��*�v[�&�G�X�.t���fb���{��TI��+�����->��f������4�����*h|9+�Dt@`���).��u&�v1�*/�y����M�KP�_��"�����4g�A��K�$�]��QXT�7�	��C��y�����}:��&��,<����h�Q�}��z�V�W*��Ԍ��?��")O�X)�j0>x*xV|�W��p�l1>N�z�T���L-��{�e����"'��g�ٽ�p)ZnL�@!�q*ﳎ	8y׿�A&�z�N��䥺�)���z�Cii��C��VKL8�o��y��v8��L����y����u'(݆�)��{黄����Mi!:�������$�B��Ǩ!��U#2'd�m����iBnqi��&R!/|��h��9���2��)�� T����gN�c!�������,t_�{�g��A.8���uh�#̆f<�v�_\���|�����Z�@�8%���g��{ݹ�-�A%}zGTv�3JҨ����ͨHsp[�R����
�M8��U�!uk�3��,+ <�y�5!�f�c��Gi1�s^���s��29cx���c��{d���t�|�C�_V�6E>�?�<u@��2L�ww�0A����F4jw��8Ɯ?4�Z�Tj����O���w�NCa�X�7$=4)��)��P�U��"Pǌ�5������|��{<��]2�b����̸	���LY�F�Җ�� v��Lޕ�Çd�.4^n���ftʟ{�X�R��
��7����׏j	�m����+�C><�Nt�0=,����*X���P3�b-W �Ч5�.�q!�I[.��A�i=�d�q��!���6.�
Ϥa$hOk�n����I|�ٰ|�ny(N��d�@��Id���l=��]�2{�f���,P*����B�>�������6n���49�̜�ؙ�<*@��Ll�z����~)7�'s	T���K+��EXS���`�-ȅe/A�S3�a��%)�ɫ�=u���XNۦ���Ծ#:�%Ǧ-&��n*����W ���L�-����t6,t��/�r�?ᖙ�@<4�;z�?1((g�c�ULR �i���nMPڃ�1��F8ˠD�˄L��^�M��Gg�"fVC.A%��.y D��}T�Ň�93C���0<�*AT�M �����7� oJ�ǫ���P!2��I�IO)�06���S�Mf�kx7���;�٩�0��K�����}�PP�N[S�E`�|`Ru�\8�	q�d�z:�/۳Ȍ��|�6oI�⿦��ܧ�g��'"+&���v̟�)9c�ᆤ�U�-� ��*�E֩4���rM7��ٱ����w?��$Gf�P�P�����qQF��_$�_1Y���Ү�P*w뒛0���3���|����"���A'��EU�~��z�A䚽�r�x�W�F�f]��xX5.��{Ia���sK�L�o�T�Ho� ����c�����_*�w�gEsF�Wu��Ϭ0a��>�ӕ�I�������S�%�lQ�^��vB;�5mm:��ySk���@%_� ��^��'�}�Ԯ��#��#��6�ǐY��(�����-��lZt�d���B_y�1jX�v��t����bϓ}�i�ݎ�mժ 2	�r�7��_c����db	W�0Oj���{��3#fxP�ë����>�5�J']������0�È(�Q� &����V����!��7=cϼ'i�=;\�G��hȶ�ӯ����kV�����ss�M���`y�-v��G�j�쪆���	�����eqx�����aDR���PX�]�[+��C�X�*=_CH��9��|��w�a��\h�J�:�F߽�䡇4ζ>P
��������Y�s�Y��/4ۆ�FQ� ���>C�5����m�������%��[,���C]s�͡�vc�^@���OD=ի�{�Sdt_�{����Z�wrP
�����ʨ>�������gp��l[�䯐����W#bX>�T�Y���Öy�%z:�$����~�>B���i��~�~�8&� <H�л˙��ok��?�w�,l;u6�x��X��*e�}c��Fpv���E~��l|����Q����1�S��C}� �\gҤ�+��e����n[�6\�_����<o�s����
�o�כ$��-��%��6��;�!,��d)�)���:�$a���q���C��H��Ylo�M$n���h�� ���V�I/���/̏� ��D�t�X��ug�$w�I�����o�8ɑ4FC��$��)�{�A2�`�c���
��C4u��T@��[`M @G�b�w�8$�4?Ū��[b}��I��������eK$�2�T=�qס�D��F���ĸY;� ���n�W�|��,���L0��`��!n�T����hm��վ��b�B��ZƀZ�������UpA/�6X�cg���^����&�� *�9
�E	������J��9����>nڱ��
�`��W:M�I9�iQ��-�ӷX���Ϙ%��CKn��F�)fYF���~/�ŷ&��y��������qޅ����\1%���ޔ��x�3��M�NZg����@�(By�"�)�+�A���%�#G���5B�?�Q�{���۠��u� � ��qk@��f')�����Çb��N�9̓
�d�;$�1^�Ŀ��b��,�����.����z
��]ϨU.ǖbo�^��c�>�B�f�Px�p��=E9}��it�֞���&]��юs5~A��8yy�b��7��m4>���R/1� vD�We+v���jS=�Ȓ�RW��+��k���Y�g������}ɵf�H���f����l�(AvR[xa��7|d��"���p㙽��U2��Δ��2~���+{v���GD�[�>b@KX���"�E<�	�k�:�9Tm
�ȫ�<3Ź��5y�Ȍ!�7�&�꺯����n�����BdC+�mB2ӍC�Xf���~
j%�MO�im;��`�(w�d��9�
CC��0�ٍiٚ����n�(k�_�M�o"jb|.���:�'���5OC�e��u�v5�(T�^�,j��И�I�c}����1�KM
\RI[G��<��qn.",�
��Eg�E���ݣ",A�f��m�ɧ����EшK<+9XS��i:���*�q��Ɂ�F鎶����اM/v��Elg���&W�l�u7yi��PA��|y0m5�L�ƨ�\��	���g����*�O ��ޙ�u�(jh^�%����O����۸(�9�&>l��*��\�w�o%3џۈ�C�*m���Z_�^��S[Xw��� {�U���ȎC��l�P�o�.f a�Pƌ�a������DU��D�X��֢�o�w�	�v]C�x�s��oOް��2������'���X��D�� �S�Q2���Q�H��cU�R@M抉�+�#��H�r��YDU���zٳt��F-�Yp�?i��1:��M��r�th�ՖȖן�z�a��"���(��~�����_���$�I
�V �ˋ*� �
`�j3�|���$�I��Y�b����K�	� ��u���-�K�ģj��~:K��H(P��@]����q�CP�L�0Ɠ��Ac���r��/�FK�����
������$�nɯ#B��n�~�m�j�����l�!M�9����n�r��p�����:X>���"Sf*��0�~�E
�����	��4�EO��q$�'�������ưt��zD�F
��$�Af��f`���11����4�^=eh�����:��i��'/<v��X�>�9��� :� ��R��ЍI�:oM%嫱KkQ?w���r�7�OW �����F[=S���q	�
\�uxg���Ⱦk��$g������+�|�KM�����/LX���>��MsFfy��QR��#�$�X��5��=Ŭ�Zj����[����{Y�w~y2n��j���+F�����۫��I
����ܸAPR�4�U,b�u ��5+jy1ǰU�+��"��ђY�d�Q�Qb��S��X9h�[��vq�����{���C���bOމ��K�Wl�Q����?�r��?+�ɺ��3��Ճ���c%B[�'�R��bj�DZ� q����N���
"X�ض6��m�o�:��4��L�����Z��O9qsl��=ޜ�o��[D��<g��9LӁ&�p>����1C,�j���\���b�Z�0��"K_�;$�R��M~6)d���`
��>#p�w\O��~�!!�,� I�"b`���������<��N�`y��@���cr崁��
��/}#$�$Ժ���nV ������oJ(M	=�C^�P�	�ј���5�C�	k��/��R�̂-��L7���YX�JDFc;&c�"�\��+��G26X<D���yU�,�����Zr:�o�fly��S��=�Q�y�8�r���Sz�]I�2b)js{��z��6҆��*�E�c�@����{O��MzC���8�p!�O�tR�*�������&����%�	�1���"3N��i���M��l#���1n��ތ�<�Z��ᘍ����ԙ���ը�V<��<k����_�斢5�J��w��#���5֖�a�O&�GvI�٫�LR�`h�	Gά�P�� ,��Ç%H3,��B���[�N!�1f뇄*A'��	u�H����z�R�ٽ�^{��#�p/o �s�>w��Ů�Lx����0���Cz@9��RIe��+FB|Z��R9�o=�%��U6O����\�G�ޙ?J��>1{>Y���֎h�*��������f.4MW#��K���ڝ�3i�8�\n�P�52�Q6;��8��V����<W0��������Ï�c���� vz�4�1ڊ��F�״����8���D`+����q�s����C�D�Ȁ��>�]��|6N�zN@�nvV:�c�6⿣C�֌I'�v�t����0�5����M�`�T�o�%�B�5|FG�oAf���0���� ��'*��?�+qx���A�������2�;Vq2��T�j��D6�J���z�yS*��&4���kz�P~��`/h�%­�P��V���洽0M�[�j�a����cFK]�w#@���M�M�x�<���D1+(�r����8l�x��Xo�� �y�l?�Y���I�^�� 亅^���P9!�]w�CߩEb�Z�іL��Rq�<3�z���y�0��7�B����R��w��$iܿ����Ħ"�0+�'K =V��Y�����*��\k��:x�V�>p�s�B�&����H�/8Ś�@�ǟ��Y��d�&��ST��L�<�,�1��m\�T�#��F�K���I�j�w�g�����گ�w�x���(Q����u���^��(!��RA1�rANs3�k��u�r��E�}&i�%�6�H.�TeY�I$%�C��,��К]�)���c� �]7���XPc�D�3[;��#�F��C���v���C���mi@O�(�%%���,M�U#RT�d:��tb��[�x���P�y�� �jNB� ������9/Cn�:�yV�V��L_)j&��W`������޸*7@8_{=bS��_|)�4C�<�vZ8H��ߗw���GO��� Q{�9��,�-<+�j����:�=�n\`�,#Y�X hBiC�S,���6�ka�K�&��,z6��%�ɗ�	�{ �2��8�G!N�
��[#kYwMw�@��j��F6�@TG��W7�7	I��禌�����3� �=i�`����TBq�es*_�y�&��tU�2Ye}	a������Yi��6�^��߱����ں��}[�0��k����|� ��kР�ގ���[�D
v' �Ϸ�R��X����'�	 8փ�K~�� r�i��Ϟm*�*���IQ�XE}6~8�{�~��ۼ�q62���cnA�y5IE0�?�F�35��.y��F$ 1_�#{���CEiUE �k3���'�;*��\m\#o��	ѣ�,��R����y�0>��҃�,L�.�
H�f��d�Շ�"�E�/MH�94RO�2P��*�2C�,��yU�r�@������(�~�lX���۲�=����ЙJNB��,���-�Sh�r�)�Ha�
�X�u+h�%�Ga*�5���a'��� \#�j�[,Mp]Ec����Ŭ�G���t�~'x�bOrF,i9Q�of�����P�[�AHGFi��ÊՑ�y&�",�m�Kw�k�=�z᯹���f�5X����4yC���SEE�v�1mK��_:�5+��g�ԩ9�0��ϩ��7�ϓe��,�mb�m�8e{G8��Q?�[��y��&$mXʋ�Q�l�\�`�lB
�ep�#@g�Z�:�UH[�-�GB]�wA�P�c�P忦'�kJ\��VHb���ud��h ��>������!�(�L��P�Q�:�#r��s���7��Bs:��k��&б�{	���>�%GR9�4F��E��Ú|�nM%���8d�I�����f�*��e�Žw2���An��-5I%�M�`<L�'�/�IA�'A5�T��d"v���]�"��s�Ρŋ�KT+\��`,��k����هѬ��f`O-r�:�i&�U��h���b?�]-x�2�hd�^�����6����P j��������+f��%E9��Q��,�ܸa��R�9�-HK6��:���kwc�ʚ�ߜ���8��T���		����I����o��x��7 yOK�!�V�.@���g[��
���ҕd�0l�(����7���$��bV��qͥ ���u�I�M�?4&���4���Q.N���B�R��e�"��ݽ�CA(��T�=m��eI`��/��s, 1[�Z}�.���qs����JuV� Lvuy�Q��������|�'��`�P�K�#����F!h�$ ��<| V�	���Yb盠(���6�i���,�(F��5A:o0��|h�����.a�W.t��/Eص�a
�� ҿ���"B"H�n�Z�\O�z��e*�v�8����h�� �L��:��\I��������d�g�)�Nڄ6��F} ���6/��0���(;�9�퐢����� 2<>Ï<��u2{\2(N��%F�'"�[�a�# �N��������˴�%�#�O�!vt���1A|�S��{��w�Ϯn�=�5��D�гal�o�nϵԐϳ����\�~w�?�(�����S��b���zo�����X\�@:
A���n����׽�	m|WƲAY������7�`��z��S��2�BgwhgRڶfj�D =����$eܮmAbU�B���ْ�E�i��[��"���&�}t"4��I��zF�=0��Jn>��8�5�$�ᥪ�?���L�������A�+j�.����Ki(qZc?�����H�u^R����ӝ%�H�Υz|���y:��j���oa�p�Mk!��Ά�"�>Vɣ��5![Ba��M����3�ָ}َ�a�P��h�/���x����Ĩ=!�g�H��63��[*�#yUJ9�`����~�)�����r]�h�
��7�D �x9.��2�7E	�#�fB^� �.��5B��'�[�	� ���&y������W�����k���J�7�����&`����`��:�p�0�O~:��C�#�a�p0hE\�xY���٠��DӪT�3�u2F����^�������Fe�Hfo ��IL*��WH��//���VӹИ���Ȓ�(�3������M.��V��z31��LUm�`i��m[�?֙�<�-� ;P�zv`v*��j�e������(%�c.�����X+ b�ĩ���!]��>����:�R��E�2�-��ۯ��TX�VP}�b�X�)8r�6�I�����wh����T�-A>/�AJ���kuK��*�q�y��?g����M �,"j[�53��26]P5S��k�h o~*�8"%T�3S�K<ٹ&������
˯Ͼ�z���X`=�@opI/8�7s��Ӎ���ӁV�B��F�Y���{�S=�HTҁ>�.�ϳ�zz^JѺ=.��p�~�����G�D�|���۝f	���?�눖�rw�>�s?š���E��4��� xͽ�3 B���A��߅�%��t5�C/Pn���C��S+��?����{ �C�a��K1c�ݠ��w'���c�x������m�����y��+'���N&���Ɨ
-{��M��@��6��Ʊ�v�?��6�K�j�,^�Q�^��'�^iG/�q�
>ye�b-��p���h�p���͍Εg�80���.-�t�T��ף,0�����q7��~�y.��~R�s�e�������������52��Il�V�
�]em�@��Cm}Lj�^z�uȌ�G'N��^�un�q�ʺ�M����w�J��K���hѸ���@�3�9[�̻�d�'W����(Ui���sO<�+W6|
���G�H���V�~�XX��e9�3����c:O/�;�!�R,P�Z�ٌ�ߔ[�J�T�B-��d�����A�l��"��o\�i4��Py�X�&R���V}I7X���5����H�xh�"h{}��a�Œ���ZN�	��7�]�����ē�Vn�)��1�$1F���w�!�^@u��뙷�q�`S��T���E~�y�n=�+��]��3���1��`T
e���3�,�X7X�Fa��x�\�#a�CfO�#�?���rQ+!&��5oĈ�8�I,'"ȱ�&ш��t�N@(������r!���w,*�<y���ɪ*`�s�b�;tcn*?`o���.�� ���H63�~,<#�;��t�X$��^Y1v=|
	;X v@��ly��G�t����P�S�Ds�U��*QK��L=&V56P�y�o � ��53�P���bF�B����i��yIg�O�c��}����\��r����7���w�x)騠w@\��h?�<
d�S ����1A���˙?�Y�>�݂HBw3��v�}nv�~4��:���~��p)k�Q �����-�-?���g�9�`�����t�+�@@�$Ր+c�nL]j��Wm�tn�yh=���EpD"��cS�ֱ �3���^��^�	8y0[,/�5'v�YsWo;���m4s�Qd��)�qY��E�N"k�b��n���y��$b�o�
:W�9��G5F+$�r�����;�-A��Z���XU]>B�{Hڵ�o��ԉ�.E�MJK�s�rR~��)R��v��8vlTK��h�����8c^Va�1q��\'K4����Z��5�M�G���� l��Sp��oRs�e�(E�%�.B�e*]}���k�qa0ٲ� �
�;ۙ|D;�[�Y��[��`�	aRFII8$�%�2���q��-#�6��<#U<NW����r݃�t5Or5�������u3a�N����k���T�M��TIR��Vc� #^� p⏘C�Y�5�ԃ��"Z]��`v�g�φ��nD��Qc�X��]Г��Ԕ�:��]>��Z��'�,p��7�r
�;>�jI���ɔ<AC�3��g��t�;!��e��h������K�&��P"\�Ϗ��5�ڝ�m�[{�C�juہ�nSɸj����d �91��(�n!�S�ͽ�Q4���ĥu��BG/��SE��#��dM)gi��ͣ�sy��W����<V_�d���\yP�N���+Kܿ2�^mu�K���� >���k�&���[6���˶@#ze��p%1VwU����KW�-��3�D�MB�X0]n����|� h������nP��M�8Hd���hɖ��7��%���nӬ��q�%8��s�UBXMx�U]�W��J��|*JU�Z_"4l�:�1r��5���=x2�=�Z-��d��*Hf���`�?f���?=�7҆Vѭ|B����b�b���Ҋ*�_�[P���}��te��}�XL����]k����~�y�ji���r��wkQ��:�Q�u¾)�Źa��OQ䜝|fT���$e�7 B�B NZ��0-6�o?Cb���VJl���)�����p�]���9�V�\7�e/��"޶<�� ��k,t���]��GI;Ϗ"!��{�b��4��������@{�QK���>�D�I7(��6�ڷ��M������(��ǜ�d/S�C�f��(���*���D�H��0�P��P���w�\y0~ad�@�� e��w ��c�T�Ȧ��ԩ٩է�$a����z�"��^�v�.���>Zb8'l������r��B��!q���ϔ�Sb̰�/zr��x^�."!�\�c���vB�����_7O�kz%k]������pW3b�[�=��o�8�6$���X�c������}~��w���Ac�P1QZ�Dn����zaY�_R�<����v��;.�,ayx�WS�)�쏷�M�����@�(s��W	xϠU�OVg�6���{[�nmb��?q�Ǔ��y�̰:۷c� �B-}�oGG^�.S�5��g��gm`��;���$����}��ᠿ�;2?�n`������q�p;]�dc�r�L�b�>�!ǁ9z��I`鏲vR��&�hZ9ͧ)4!�m)5�쩻p�p�~t�3gI~��_���uh�+9���w&�M��,!����(�D�����ޟ]6!7EB�6�a�IنU)L���}�5+@V�dY��611���t�^lC#�e,q�z����{���Gj��ޙ���PGj����'��2,� ���quĪyk,D�
j0�MI�XV~s�1����d��?O1�+LS��}��W,q�}e1�)�֞�CI�dD�ڈphV˞?��z}Qr��뵊>��U��&�>��� }*�������{j�x�[G���wa<�B� ={�>z�o%�v�[oc�ao4�d9���`����� =3{O�#�6�n�\�뮳���I���g �ʡ���9�*�������l`�W�NBf<���;�+0j�,ը��}�MZ���IR��{�m��H�t*�U��Qφ�_'!>Ke��q�h��?�R�tEκ��H�U^^�b�V��r[KJTA�[%I^�k��B�a�O�����7���N�E˟EL��s�n�йF�8l�1��nu&@d����o�.�pY�T^��0���(ջ��ШWq�U|W�	Gg��Y��s�+�f�O��UC���>�QGNF[�09=�,�_nL�F���ے��Rq��/"�4�]�<U��i����ԤI�J������W4�#�6�^����G��ͅ�f�h�B��`�E�ۓ}��2�~tU�=�BKb���(� wqWv�T�~��K��@�K*Q-�Ի*~�Г���87�F!���3-����<Zy����ĝCf�*�I�(��sf/��Z5��EϧqG��Y�y�4A��)���S�9Pde+ދ�}�]A�F?؁�ia@4/Y��=�"�;�9E�G�����     ���d[�� �����Ҽ��g�    YZ