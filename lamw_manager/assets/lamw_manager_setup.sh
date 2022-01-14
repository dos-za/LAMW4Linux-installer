#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2039349509"
MD5="89b828ce4342cd209cd91471ce1a4f1e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25856"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Jan 14 17:35:15 -03 2022
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
�7zXZ  �ִF !   �X���d�] �}��1Dd]����P�t�F����?�{�Ɔy���P��g�˵����e5d���
4m�w���<�����%�������Z��؋��3 Z?8�ؤ\\��y�I�j9pm	������U���" )q8ta����=	⫔�R��ZSF|af�x�G�u��.ם��Iq�P��Mi֠˄�ar�Hpr�>ӬT�)rW��>��m����8����*ޫ�o+{���e)�GQ����DI�O�DR�>4qo�&�n��x��2�7���x��R���S&�����V�N{N{q�A�t�E�O!���'TŐ*}kGl���?���5�|�%f2�w+0�u�QUɰ��4�9q!���?�za�2��_tFGp��2�۳6i	��'!�'��΢2:e�a�v�VX�w��n9�F?�	�/�Bu��ڂe{�VQ���d���_)�`�o�#ػ['�Xq�Gm/�q��V� ��R�'xE�jñ����e����--˓���O������o_e�hɩ�R��'T�BK�L�Ý�����VA�4`�&x���K��R.�5\>iS�Օ姊C\=AE�@���qO�������&\�q��8���
�y'I��
�!��v&H2�cv��m�^��g�=-�u�XŠ��]I�|ÕU�G%r�u��������Ͼ��J^t�Cʏ���h-��
�"l�߄���{}�OSM+�3��u��	�w@A�_
�c�K9[j>�ή�,a6��76����vqu��v��粸�z�ÙQ��*=�X�;�����!U;8	�Nf����7�<�SE�S����ˬ�\>
�_��r�W��;��d�X	)B�� ����Ei�ҫu��*#�sOO(fDC�Y�-��崜�PО,���4�����W�e��̲r3��1R�)M`5o]���X�ͬ��6N)�u��B��vv9�ɭ���b�z��%~���19�y��jJ�^�J�s�/E��} AM�nl����G���c}7���#kӓf��&�ߖ'~IH@�)�W�A�
�O�v�D�+/�E�j�����T�l0���m��"���� �Wu��T�{ݣ�.m�z�@�i�+t�l��ĺ �f��q������;��1��?H�7_���{���%��;�;&!���'j��5 �!�29 )���C�u{3E0|���уC_�CS.N�G�)�: ٵ��<�c����8ic����߃W�x�DXES=�r)�6qk�W��	�&3?4rj���n'�b�r��DڹSJ�	����ɦ]Y�`��Oc ��n��;m��zG=�~2םVL�J�Ϛ6�������jq��!ChА�^�s-��_X'��<~7@��SV���͍ͮ�����slILb���\�L@]��ꪪ��0���0L��`�c��v��@Q�h�tA��������J�(��<,V�9�1¥�d�KzO�Tc�������dp����t	���G2J�G�1 �a��K���a��o8k�&�Q����z�F}Y�'�@������-�.�:Z�E��7[>��������[�YL�1m�?�(�YO�c͡~-SYb��{���ē�zvM_[	�l#��e3���z͸O9�M��bW���ޭ�~����Ztp��� ��,�w2����(J���_ɘ�Or4�둭9 �=2E��f�xn�[�e其^|Z3�U��W�_È����J����tBi�����##�����Љ��b#�j�O(����b�p�;[q���~Q<���w��p�ϯ�"�h�Օ?ʬ�Å���ۏ�N�C��Vr:O�[HҫgLD|�� 댶V�|#t��'l�A#�a�){�+��b^��X������R�`�'>��g�*�$��",!�/<etI+��o Y�S�L���6[tv��B����@�z�ʸ׻z�SN��FqW��hE%0�a�����q�����=��R�Xx����-�3c�(p� �i��P��x����'B���d�4CdT����[��T,�/�:�����lz�l��q�I���o�@�R(��
J<t�MT���������KV��a�EF/R�}��,0/���ʬ���O^C$�\Ҹ��tB��@w\���4��{�Tm^q�x�牃D������䦤 ��4���Eo�tV�sV�2�Z1��IІ��[ex��'J�����>X�)�h��S	�>�	�y��ɯ7-/��M�`V�bɁ�N�� :�8���N�Eذ{&`�{>j`��Q����צw�t"p��h�1��L����;��˿�47KDs�h��Λ�c���<�o���My��|a��x��"�g�_q q:X��<a '�a���9�����J�V��3�c�M<�ƪ���5�擣�P��G�����-�,BiJ��'���v�b��Y��Z�I���&�.�e�/���6���v�j�u[���9b�]<��R�w`
�	�A��ˬ�"����މ���;��/Q��>i���˹6eĤ^IƖ|e�5��m�r�:	���[�<�n;�t�� ı#^<��}��%�\�����pc.��v�'��%�O�,0�r=٢� ��>�3�\�j�J�j6<X�7��ݬ5S;h��d0���Q�� R,�m�W#G�#��}]�!J�606���ςɡ紨���&���9�����卮4�ݖQ'�G˗��<R[C���u�P/�Z�&�+��K(�,��[������U_�2!��6u5��� �;"a��^�N�'9Bi�/5�>�.�/�+J��Ts5�D��8����4�NA�iȆ�4{���W�c��A�ڦ�#�9�G�u�ui7�ι���?��A�8�J�_/֖��k[��E����S1���욗�i�סO�ǵ��i��s�:]�d�V��4j�.��7��(w@�e%SPpU�ʨ>�Ļ��xN�JD��M�R5�v�N�5&Q����B�q"CE��ŧo��}oJ�����"^�֊LT����f����D]o�����k�i�j�c.��K�)C�]`��ûԨ�Ν�C�9���oA��x:Ha�gw�x,�ak�A`�z�n"�b�&$?��r4V+�թ��tok�A��G���Z�;I�c�Z[��i�x����V��{#�1 "H����fD!��EPĭ�J�P�zC�A*�#a�"%��s9(̡���W�F�I��w�f?�O@���X���/#i(<&�
�tE���O�A�d�w��/Q��3��Q��#���W�|Mn����fY��;�T���006k�F�E��E�����rM���)��GN��Y�H� [?q*4�H��!�Ȏ�)����?&��!i4b�x�I��F�����N�ʃ�p��G���q�@-���hG*N��ŏʨ�E�8n�V��ߘ�n�?r
2Um�Ru|7�Z��o����Yn��2V�]@Rkqݥzs��ƣCSQkP譧-�x����e�qC�l�a��͜�nd�;,������N(�g1�ɮ]�qn�`<�F�`^��QO��L-����	C�\څwf𔓕�K�?�[E`B!�bFm��0����L��$l)��Ċ�W��p2od�ъn��� �zi��l�o��)x(S\������HZ`��\��À�9<����nq��p����s=d]-5����Z�^��~��6�K2|C3ݙ�ߍ,�hV�J\���̹� �֍;��6�;IB_�g���	����?N�TX����E/�~8�ʞre�	_ �'B�\�-�~�m���~$x33c�VRm��
��^�rA:Z��P�6� jｕ8��?j%�6&W�UO�w^dO ���V�yn(j `������(������Cd��d��ѭc��1�g�E�*�X�5>�-@\�5�x��}�)76
�H�`�e�e��%���FL���G�ѰjiO�Mlۍ�??���3�h���J�3IPWF�� �{o�L��� jϵ�h[nD,��%U�A:1�|ičUS�4oa%�:)�IL�����9+��;5v�����؎j�_s��g�[��G�"W1|��4+�� ��)F*J��շ�k�:��)m5b��3?�_�#Q�O�O�D�M�1.�ݒ��uB�v�D��y��7�)"|�m�X���tꥏ��I�0��8J� 8$ k��^��h����b��1��({N�U���O�7���o��׳�4���yM"�ƕ��;��Rv^���ߪ�[Ŝ]B�K��9��EɃ�bs�y�X�b�<K4i-��J*B:r�
m�
�G&�ʘ��(�_j1�ϫc� y�~��|� )9 b���R� ��%��z�Z�di���-�Bd�c�C��G(Ă�v�ԅ��$ʶ������BEAK�1	��{�s$ ��v)���,}T������Si�W	��].7k�ҵ�ҫ�e��l�t��0#@(��0dC�:�׃5�rq}n�lB�s]��޳�3�M�J����ds�ޢ�R���덪��qYg~ŉ�F�L�� @��_o%&�U�3�H����;~�)�>�	�-9!OT40���)^��,Iַ�`ߝ�K�4�՘I��l��q}��%Z�D\Q����a�c�=���?��R���jjxX2��6���3{B���l�\`�����ݳ���ł�J�L�u��	�]�!"e��|��6�`'U�.�U��$*�; �D�,�9�V ��V�f�
��la%88��U�c���vфb�������!E������� VD��_���83BS��c�Rfa�����H�l2h,��nBiZhl��>�R�c3y�l�����o��gi�:���\8���w�t�A!��?:��T%���%�Z)Udu�.�?��x�8!�{�l΅�R�*��$������q*���hd,Qr��!���)\bv��/FO�K�\K �cĢ�eu�mZ]�4�g�֭M�d^rE�C�6!"J�f�Pt����(�,�`�i�ARZЮ�Z��H}ت��@ϖ֨�y��M�"��@��Jk~k�#;��k�����``��C���㎮����� �a>�,����Wq�������P��5i�Xy�[G3<T�ȁ��z�A��hfdh"�Q� �@*��ÉԞ}��(`�
�����&�CZ��e��sL`�%�E��|s??���2���vu�p�лW	)$��t�%i�8�5#����LA�U5��;2Q� ��_����>�N�[��F�ӊM����@�{0ڥ6�Ȱ������8V��?ҙ�y
��9M
�{�8��բ28*�u�7������������l�3A)P��X�;!��-��^D�2F���SX�)ų�N����XP���$/�{���c��o��{�*�W�'{��[�@�>I�X�~4(����u��Ϝڐ�h������׬dc�O��z7�=ӻ�_9>���=˯T?�� <��.\+2F�񼠯C�����/�[R���`���P ���s,є�:�i:6٫b��RPc۟�{"�;C�֑z��+�%��M1��4�O����p �D
t�+��D�!g����/����T(��U�x]v�r��� ���,f���RMT\2K�) ��@l/D�{w��W`ps��"_
����-0�ԡR�ͯѮ5��+�����گ���x�.��H�W*�r����΁�ZT��(Ifr���S;�7�"�g�7UdP��t@Ҽ����O}�K����{����G�#���L�z��m�@�ڹ���2��� �H��}[%_�Q�?+����LY�;6���*d�Ej����o��4:�S��2��_i��%���؛u��A?��EP�o����������	$,%��f�CyX?��c�tF�X�?|�
)�xvC#=)D(/���.��F ��H�'b{�7usW�11�H'�Gm7Y���<�VE������\htj�˲�K��5ȅWYPg�	4R�%6��<������_ɚ�_IZB]�vp�L�W0t?�Ȇ�~����.z����Q�e5Y��	%��oy!�vA�e��Jϱ}j^{�e#( <�ώ�Kֺ��m���Q�W����׻����NqI�x{�I��ڑ�;�we�#"Y��V���������F�����,z*���'�H�r�bd9*|=�<+en;�.�5�fn��Ls/���?��HK��*\Jv����P񅃕�/��uѨ.9Ù���:o�)O����ӑ��|����F�@&pί��-v�T�
���3]�!o=�_1���xev��ɐo	3��Z6�R(��2T���2wa���M�++G��Q:��j���5�4f������wE���5l�鉋q���Ix��%_ͨ��9i!�y�y�(�Ѽ��g.A�N8���j-�\�u?�ߟ�\�^f�5�E�+B�2%e�`i�����ғ�Ǝ�*b�-֓/1��J�M~խ�����(�8����fL����&S�M?c^H];�l"�4��K���~��=h��,�Q�=4���~�H��l�-�H]�9�E7E���+b������6�d��jHW��X��oN�Ed!�Z�,�׊]y�1לH	�2�U���R� �!��-l��T��(�ј#%5���Q�J!B�9z�CT��	^�snl���k4����y+���u�F�'����$�l؃J���bN���=��͠U^�[ʯC�/��۵mO0j��FS�B��{�$c�	3�	H�u���:���p�b�$��.�v�z��4`geH�e'As����ѡ�W�g�-�Oϼ؍A���&1Z,��]��͵��\Y����S2C&�O��Wj���¿�F�_{8U��x2 C�V;�#���E�,C9�y�㏥oxGR��m|Ol�w�]�J���J�MHέb*y+���_�Ӕ������������k$=���F�"�_�V����ͼ�!�{��e[�#�l�����������}l��WU��\y9��z)��E������䇆/���ɭZ1K,� 0<���,Pn�m7�FCpo������p� `Q}�3F��U�����ācU<�ie�u^�}��g�^v]�o�ҧ�%�ܤ���J���WP���~?е��2\����ӳ��>j��u-M���e��'�D__k����>�f�\ug��W��-�K��oIE�,�����Pk���	���� W@�i��=Fy�m|���tp]�Te}�J@hh�eI����v���j����3�����Zdg9�r?�$���'���ymu#�š���R�M������I���p�.^%���0-IQ���j���O�Q6gcn���h3��|*3X��������FA廊ݰa/u��xZ5���׋��B�I	��x�
�]��ƖP��ʪ��4�ύ)�؛��(xv��}3���RS3~�L��q���b:ڠD�$��ʓ��nˤ��9M�n��h<�S���`�L8��'�`_Q'@�5�<�!�u�� ���(�ݳw{>U���/o|^,$�!�o��&'W|F�I
�YþTRq��]���K����-�}�&.��?�U�Uz��Wo�@����B�K17'�(�i9�+�0�HW�S���:5�q���ف+�K�x�ͨH�'&ٜ��[��Z�v:�����Z�!�l�I�@ h�؁*�	;��&xK����_`G�w$!��&R�b�s �R��	C���S�vjX�K�Q�D>�r��JnC&�0�W
��SH���
'�*��CɌF�i~��3i){�ҳ�7k��ESho +��a��_�Q�إ�w��9�r�S�]y*qm���LS�Ї�CB^�V��ΉT�ZBl?��-�㭭�"�y��R��py����Q��=���ض�b�pR"`۞y�`GdVMj��%9�<��W�n^���yL�� \fN�&�ʊ�gk�՗"p��)N�E0-�tU����x�o!�o�C���NVB�k�ԙp[@���P�Ŕ=�fd���Z�r�-�
��<#����^6fq?�^66�fK1��3R�y'�+�i��?.�O�i��lb�Z��Gg�QF��������f�`����#��9�"k2�	� �S��ro�N�H7ߗ��|م��hy���ڬ/�-� R;D\�so�'��e��^EwS�,�����ѝ �vm�&� ���/�{?�O_G���t~�R`�Fr�8������r:����]k3���ƽ`�5	v�}�$�S�ߣ�݊���@B+����7�M�E�z_����Gd�����H�-�w1y�Di�̭�C1�7��fK��]�V	c��|m(�W� �d`��Ņ�)D�/����������4/�#AP	1�hSY��.o�y�o���J����4�R8��ۂ�&�^�5�ZE����U?�Ȧ�nؑu�:��0�1�S���0�v�Hp���"��~o6Y�`�@X0ĵo���QZ]W��b�t��A"�e;���4p5�ǐM�o�|P�A�X<ݿCȢX.)W��$e�J���C�6�1���"#�%;I�^�eQ�=�Zى�LWsۖ_oT�*�x���H	m��,)���l>�����)�	y�퀣8�YĀZecR^��t�W�@˟e ��%t.?]�� ʙ� Ć�g�Z�<(Hg�e��s��[:��NQ��vg���B<����(��������5�0�l����Q�U��f�m������mĴ>=4�0���BZD�L����s�]_�dS�O�8UV�Q��˱��>KJ� H?p���_�o��Du3ih|h��+���n"d��f@}�`"좊��?� Ix꽖���?��f��J�ϝ���<-[�Ǝ���L�����GF�w@��[�
�p�w�v"4����n ��CI��>��2�x@*:~���EWe�i'�����G���놫g�Zi��WH����حl0�-fr� '�FD�'����y���)VՄ�w������[��C�| ��j˙Կj�j�n��,����|��i�RU�U9��!N�k�E�	��	�a���g���-���dG�c��f2�d�4[l�n�|����݌��a�3Yud-b�҂��"H[�Y��D�)ͪ���X��"K!,�5]dtҽ�+��� ��(�����y�}Ǐ�/ό�g�Ňȥj
���< �V�DT [m��-�`��r��{��:�No�
�ο�/�\N�p���r(n~� ���C�����e "����v�xM�&���E���#�X�8`�0�7p��9�5Q��b�$�{��2`oL��J��u{R���>%�x�� ���Y��f+�bz�z�4�T���v���)$Q���;Zɼ�����m���sB�
)`�+�σF#j��2e�wC�%vHG�ʵ�����<p�#
;UR	ȇ�]Mϊ��_���ސ�S���ND��#:�V[O��?����4ͤ���yu�^�7RǶ�Ss��_LO�ѤQk&�t���]砀�k�I1;�� �(z�bʦ���d�o���݃�����H`�͔Jg\�٨����*�a_�
C㯴['�(9l�U�o;��ُk�&�'�Ac��[YRR�Q���=��� iHf�^+˔}>R���|�D��oΆ��/U�����1���?A"�Y��Bw^��(4�XRB�d�WsQͽ��T�R�i�T�ߥ5�B��P|I�x��u:Ui��7����4��J�l懦�ql�b4�1��V��_��L�мh)������1��U��9:f����ڬ��^����;�n�.\���G���L)�lF��Ilk�&��9N�I[҉K�6g��O5�a���ϣ�j7Iժ@���{x�f]T�57ْ�G�vbL>��͂�M�V� �	�����z9ĸ�|�� �T�Tn&_�k��<
+�����Ӭ܅
~-��G׳?B�*s�5��߶W����ݍY��	��t�~�I�z�sIW��pl�o�N�k��)���6\�����e�KֳBY�\0c���Xi$@!ʃn��M� �'���c�-��r��r��¹ճr.��:�sD~o��-1t�_�.>'��xPuA]dz�6RU�Ak��(����W����`��|
#@=�ܣ6���m���m|,k)��HS��k8�/�4k]���9d䇖��`AS:��*>��I�ֿf��4WS�$�^tO�OVjS`�6��^�T��;�$6V��ޙU�i�*GU�}W{"\o���}�n6�:O��huf��?Fl"y��\�Μ*e($%h��6���b^>�n+C����$Lv4j4U�Q�+{[�Qk�{�T�C^�3�zrد�������u���C���b8{�0��r��7_�C�:�i61. [Ʀ_@90%����I µ�`[s~~���E�һ��'��ۘdh!�ӱbdhi�W���`8�70���ʆ�f�]�7��-$�Nv�6;|�e+�%>Y5�mҞU`�w��+�_�;AvdE�.���u���S�wQG�%`�s@<�*?��d>1Q��a8j9�g7�u=��B��^a1���)�C����Q\�����	������t�ث�w.��_,@�����\�x�%�8l��	'���V����Ygh�4��>�7U��x۶A���K���X��fL�V�Pq�."2�Pn[�+��@7�l��W��������|Q��i��#s}�2o��0�> B�r6`ڸ���Jd�P��E����+Qo����K;q��DS�o�`wl&�����nM��,Y	p�<�Uu�����J:�I��q�Q��'p�2 ���7o~�~nd�?.Aϭ
h&�]}˥n�vq;|e9=u&�Z6�1"�P�LBhQ�3N��8�X��l���1�j�C�g��<B��ٛ�.ĔM�+BkʽĪ�Р�0A�\�=��#��=P��I���l����F�xX��/%���9�zj���'�c	���i9I8��F�B�;Ϟ��X`M9z��4�� �A�6�Q�7e�����0�b��_��]�y���U�T�e��旖6|-�g��ȭ�u�628<F��s���6=gk�tMKe���������P��M�ި|�yr�L@/��CH_�b�L�0N�a�?��d_J�2�I  S�w0U����}�<������Y���ڟ���&1�aIj�b�*.J���b��t���@((\/NsI���n��*GA��5�"�y4?R���W͎ gz��N(Ӷ�ߣ��KlPWo�������H��˒ɳfv��|�=��[ҽ��t�xkª�����$��ytAu����}R����-���w!oz1�+ː��(�s���b��	p� ��v���\U��9����1|�(�5.���o�2U:�6��j�/p�:��І���,`��A�aY|o�)�/Y�cMހ�&�j�0�ze-�*m���cVt�D������(Q�Z�o����@���v�-����F�o�tC��ʂn:\�;��g�~�)�;��v�	;�{kUϼa�t�k��TD��$N8�£�Śǈ|���zׁ?S"nν��>k��:f��߰���ϑ�s�����_	��س�����{��e��JÚl!̇{�&�>����MO�T&R?�k:'#�g]��Ŕ��H"=���RG��q�5�Y�d/b�"�8��W� =�o"(+��\J۲
�I���w+����jU]�e}�1*���h]�bf?;�+-ա��p[��N��������"��[L��/=Z�H�<e��bd�w��|y[�?2��o��V�)J��17Ra�?�����\n�L��ُ8ޑ���z��)�� ̝�AJ��Lq$g�ha~�Jݭ��>�>A9S�j1m 8{�D�w����A�n�̒U��#�dW�OɌT��6@�4�֏�"jm�d�:M�)�/������T��q�]�.�3{��6Q�.�8ј�����/	��`�ހ�e�{HG>���l�iܽu~�0W��16h}F�v��r5�;�VFi�"�mR����p?�gq�Ѯ$ f?n�ys�D�;��2;݇`oՃ��]Y>��3�O#�:�0&�<�x��^����n����nWұ��l�:鞬A7���_���*�~+A9b/F��B�ݸ&/;�C9���e6����V��l��2�cA07�Kފ�� =��­S�H8'��9Wj�N�[�q�R9�F���P�v3c�[�C(~`崱�i��G"�m2�5k�&����¢6�9�7]���-$[C�H���I/9�����ǣ�`S��Cp{{�TNgɒ�����r�����'~X?w&#2I�D�Q �`�P�k�b�-�@{��f�o��\�(�	�`����ł��^���.���)�REi�4��1��B��B�OS�>¨�!��;����JkZ|=������ǺUf�����%ꀀSK��iɗ*��	l!�2�	�R�Dc���ި'wʺ�#�
�L��ڜ�z���x���ٸ)[�|T%�r�z���+�oI�D��~�5#�\S|�V���$�K)inJߴ���z_�23�9(��G��� &�B<�1����E��9ҿ�L�^ v�4��O�@E3�\�3qT�%�>̋9�S��˭'}5�}��?�A�&�!2:�<a� SI?�Z�3+J���0^X�a��I���6o�U����,����$�[��@��w�Ů�\�wn��b@`)��Lt4��>��"��e�(�K}}{�Ϟq��\u
�K;ɀV�u�{$���[@x�뇻7EX�ugQ*�)��]�{��^�Z�@{�#Hes5����J��<�
�,�@��-�px���e������!n��UU`\\��]2$���UV�s�xћ�y\��޶��A�&n�<[�1�>�b�w\m��j6�׼<`��6��Y�ݳ�\�����7q�������o\�*�!�YR����4�;m	p4�ƉՈ���zX�N��A:(����A��g��͗`�T�,o���~B�/���4���ҵ��"����H��(,2c�-�ۂX�n��QZ��j5)�s$F��K���*<�P��p2�d�heW~��$]D���=xL�}�s�$
g`�7�����.
���^�1��۸AX��Ho���	�.JN��A�}��N!%p��W��A��+�չ�t 0<��,�z��'��Q�m,:���U�,||עG�vƤ\�a�8�>��Ɉ,p�1Ik�5)<��lX�wH�H���42�.�#�ma������C��A��~��h���^k;�Yo˓�aH�#����=�q�g��?R\@2`�ɉV�=�﯊�L�M��v�ˠ�OUۏ�O��g�v�s�0)��������⹗\Gg��醯�!l��L��k�7Ǎ)+	�Ah[S��Q0v��'R�)�*���~F�p�\}�a����o_�zWg����0H��e6x�猛$�#s�8��w����|�&�|��8}�L싀�f��(B� �)OL<�}р6M��2O}���M�+X[
0%�0�4���V�v��hN��$70���k������R¶qcy��b�* ���b��S�w��5�I{U,���G�$��b>+e�,�3���6�WdL������3��]�9��)���]b�.YU.�o�XB���f���zXiB�8���X}����#bZ�T����w�$oMF>���j�k��Ph�)�	!%�3���n%�XJ�r�ßu~q-�-Н0�d���q}V��z��,;D�3�=7}y�ڮ�'�=	SQC�~g��yA�j�=��S��yr°%��|J�X������_6�����Ul�9U�Ȫ�Ň��zaiR�e+��ب� rG�e�^� �Gf܂A���z�L�����l�=�ې>�����Y%d;o9�<�=s��z耖�%Y���e��	�\�[�3h$d:�V�H@�[�����t�i�Q��2���F�YRO*��U1yV��|i1�46$��j�Y�%��p"�	��`�i�'S�]���kL�k̑��{~p:�xZD�ZTc Q�M<����#x)���q����N�aM�B}*��Vn��F�~�S �kz%V)��t�9p�U�m~�&ʻ� �~�dt�������TԻdЈ�>H(}��k��D�ԁ��Ŋ�a�%7�) �Z�#GP���I��î�⿑Xl�h~�@��i;�B�@:�m���We������a�5�r�mT�#^�����ϲ9lF	a%~t�P�o���9��e�u��3*Xͩ��-jmx`,�"&0��Ꞅ7敬��T ���5�H�[V����k\*=�c@����]Zfl,��.��u�3?�ƛK`<�~	.)�<�|�5rE���)'�F��ؔ���IV�ս�H�I��T7[&�g�D���"<�X�eB@A^��y<;����>� 7L��k��'�%ѧw�:��Թo�AIN�b�>��?Vr�jq��K$D�`�	ܦK<#��M��A�au<�7��%%�	4���	�i�Z}��We�&�y�~+��We���?�ߒ���!g��������U�����W��F�y�$)Ac����>j/�"��I��U��n�������?������?�M^ĭt�µ��)�� 5�%Y�Ml��h3���l�7�`��=�;���^q�h����$�P��*�_!���]-��� ��b�[�UH~m�v���$��tn3���	�}��X`bad��]�
�+�.�d'���ͣ��)���X>��(�H9V����$�g�VVt/�Y�M�����RͦE�T�HT�6�R�=�u,y$�����^HSp�K�]����Av�9x�dTK�O�m<.��N~矈Kܿ�1��� }�v019ʴ:Uc���-"%ѩ?P 5_q��J��n�d������B��U!Yd�{�5�}��^l��s�R����tĕ��Qy��v�ԛ��R���T��x���iև~�c�p�}�d�O<D�>��8p];��~�U����'�����<�����X��.�sA���S͌�T�96ve��~�kU�>��#�^V����cx�����۽��[6V�$�C��+���lK���MK6+���M��r�g6xXn�\1�༵�<�&Q+Ъ���ja)�4F_ �Q�8�m���1���Т2?|%�u�=`2��Ya�� ��G� W$ɍ�Z����-|\|�TT�Y��`T�*6�[b`�%�#�(��*[FaF�.�	̟1
���`zQ8��{+���������$N3W��џ㣠%���lu�67x�B�맹/���Qr��-�Ћ"A�5l�u>=�a���E����B�&9_rhʭT�h���tv| ԑ�M1h�!'0�L�+e���>��\jXZƏ�~�����1}��lW�})+���5�C��KN������G� �Ɏv�d���U)�2������;8�U����UK�/�]�w�"�욗h׾����<��|����A�?������+�U��`�U��-?l_������쯬,�0lsC��ӑI�37�i���k�ά����zu��9b��c������#GS�a6��ھ>'�`G�ƌ3���	�P��iQ1�MG��K�&�z�}q����E7�j�ŋcL]�L��z$�,�G�n��2o��	FB�Z?��,���Ki���2Yto˩�V�JI�\�u~��^+W��@��7�����粱R�g^<����P�Dn��H�F�,�Z�#Qͮi)����YV�pex�[ėD�����j� b�RA�Zj�+i}CXM�
�������gdc�^u���ꣃBG����b�~�e0��� [�K-�u�f���l�s.	�(BmK��ޔ7�i�y����r'g�_��'�)C���œ�	���ϋ=���i\{W �ЕǺ���3!����j|kkS~���}�4E�CG=��Ug����l�m�FQ��8���:Y�|������!��N�����lc���_{X1��7�qH8���~�<SuT���҈u���;m���<���4/2�o�:c��·�)��}��1�+��$�2M���:�Z��;�1��<S�_�aS���W��ݕ�Û�}��}-(��5b�3��I�ixف��о�*u6Wô+?�c��C��w�ꐰ^%�������Jb�����o�����|q"�<A�<���L�5Я���0{7��?C	A!N��p�:_�����Kr�}ZZI��;�@��|3��&�����H蔢�-;|8\��+�}� t�|����C64�s��Vlډ�$��V�Y'a�N��q�F;��~ǲvlHA��E���<IND�C�^5���*���4�_�]^-��ޡ����D�)�Y�Y�}�նu�,�#�D�}�I�v;b}��%��K�o��Rl�H��1�U��^�_x�WGnМ2)�P`�FU�	Z�u�3�G^�toSX�F��K<��%��g_C��JtG��;C�; dz��Zw�S'�O73������s�`���� ���Ot���I"]�p����)^��m�i.�Ȱ����m�n1�g�9�MffWcg�	vb����L��^C�����b�L��7�͍��k
j�-߅[fg\���A�x����޴��9�䖢�R��[@�Wm1�@���>�4����� ���)��������n}f�q�{�k��Uc�w�j����Cߩ���H��fk���)��ڏ�00A�'�&5XD�oG�
�`��h{ ����Tn��=-�<��)o�\J���Eo<�aC
6��`����b��~�R�^?M�@T�ߴ��ڋ��Y����,�~祐��u�s��2���;Tʬ��&ʹ�S�-6��%� ��S�)IH7T>�� h���e�K*����G�
�F�|��Ǳ��#7D�ٸ�M�c�������~����y���9;5fZ��W��N/_`s�"Q)�@�T����L�M��<W6E�ʾ��ʄ��x� 2�7��xם�id� b�X��X}p~��u�v�Ncq���2��j#{z��d�]Z����k��7M�G����e2;���]y$̄J���3��R�~�S'�ʑ��%l��]��C��%�52"�H�\"��8��Rt�a��;��ѓ�!h�֧�e��J�����
?׃��E����󡦘��i������C�}T7�������՗<�51k$�NO���{svh�j2)�~�]�k�z��-��:�@
�� ����.-%�e���B�3�����1q���{��X�CT��+^eM0C>��UN�6�n6����Ͷ�`�w�,�<�xq1B�sA�|�<�3���J�����a����} hg,
�Q���vH��t��,�:�?��V»`+���ۚ�M��,o>�UE�l������^�LO@@��b=�Ot�.�PO�҃�kݍ���~|7{�ғ��G��:)?�'��{u7�?�OQ��Dm
e��W���3�>�|����c?���[fr��H�8v�}��N��{_]�P{���;ð�aJo��
2��h"ˊN c+�ж,p��!D�����-�Ԕ;O0ڟW ��*X�
����k$1���b�9���1�����=4SZ[�/S��a��"��޿��V�RM��̑��Dh�`{�t�l?�r��
��Ǌ��u���b3���3{�V���%R8Ӫ�X�+Z�Q��QU�@tU�"m�9��I>?W���7�R.����p��)���k^I�6�KW�Ѿ|_�Y"/Eا��"��<AY�q��t���l���������QUL��F�7�,���R9Mѩ�U���m�Ӷz�s2$�U��|��q���*'RN;p�b�")0�
�2{N��) ���s�PɛA��6��]��~�s�1Vv.Jn-��I�2+~� �4�G���>t��w���CBä����ت�4��:q�7����cq" ��-������:��PL���}n�`�^�^/�M�.�JC��Q��n#v�ˋo�Gl�^�ϵ���N�5���+(Fp<v�	�=�kt����m^���C����5��R�����!E\ID�n��H ���Y� �)��_����$1���?�����~}h�hx��� ��00oR��鰃9�٩(mA-"׋2ԓ���,��=����D�r��Vڍ�D˼k�4E�P�)�&̺��2?���pX�ҋwvB�~I�9+���J1_�X����Nw?�Ē�v�Al�Q�本$_jǑ����33>kS��@(.�t���'�?/j��)x��H���@~D}YU�R��? Ͱ]*��"��&���9�j�QT��4�C�l��B"1Re5�d��B���ݵoD�d�*���q��Ԥ�rTb:�P.ri��>O���'=� ����3(��na���틔��dŖ������b�i�i�/�	*b����<L��F�P`�ݵ�ꓺwR�d�07��B9k�&ew}aiQ{���R�f��X��B5���ZFRL8�E��7�SC�Ϻ���)<P?$Qr�Qt^Omү r?ɠ��g2P����}:@���#Oy.��9��4�zdYS��r����)MOLX�A�v��?����G����G�T�t����RY,�N��E�6 t#���4�&�t����%����1 �f��z���(�.�XA�9>м�TY:>�C��L�68Oe;MjC}G�\��1@���ς���ݛC=��u�@���\�w��Xڲw��?,��քmpߧ��9Q�<���z*V
Z��5�i b)��y�G��a;�=����� �٠a;Zr����j�"H{��������M'%����͐�k�\�Ĉ�z%z��%���w����<GT`�c��Ѕ���'��*!��t�5?Bz����tJ����iD��;N�)l~�ҙ�c���q�Ϋ�wrյ��ڞ���.0��ZE��z!�@Ĳ~\n����+���u�Έ>R.y����d=D=�'���;C����d(�~"�ҝ0�{��wAjW}��z�/��4�Z�p�8-ΝXeOB+�`ښ�&�9����HQؐ�{�_�M4��V$
>"����Ey�M�Qx����.���`b(�η��t�G¡�!26�yt~4��������y^��l�(�����ʳ�:|잣ۡ����+�s#���s�y�(�I����'A�C�����&=��Ѕ�]���²��ӑ�T;��p�ڟ�2�� �
��� :��/�`n�	��#d�S=�e�.�	��<��*bc��'1���[�z	ꊎP�]'{���`(�{�C*+W"���!ȳ���k}pg@�/{���m�2x_<��H�t��*)��Z�-X
=����c�' ��@��ev�ˈ7׈��։y��ow-��kKL�!2~C���%^��b�(�s�ԛ��s���QwS,>�~���DK��l���9�����Y:ь1��+'�t�F�a 
��C;���GG�_X�U�\��IkG)r|l�WaN)����8t�̤�gY�y�}�i�^��t���&p5��*�?N��6�f�Ƥu3�C$���#�{2\�6��!7��r��mP8�����6��q�:|�;�v�	�-��'�}�i 
0S���3e��a�+bbk�.<:�{�~�I�5��8��Y�з�}�#�b�<��5>�({c����xD�X�D�f��!�|�D[F�j`�`��~B�}�-��N��\p3~0N�xݸ�I�O���P�xQDɄ@�p_�7�������+G���1g�sZ� ��#���)J��翇nh���}�Y�c�R������Mm�R����M�:����
�~C�-��t���&$UD`��.8-�t����3�q�Tr�_?{�l*���;�p4�c̷�av���ٻ���X��DU?3}x�U]����6M��ߗ��;cg.��Hkm�]�e�n��g�ǛE>�]�7��ҟZ�,nC��\Aoh�i�,ꅦ�Y�������
�P�@��4��DP��T �@Ldh��aÎ�(����r���N^��P`S��z"r �\8D���1R��/"��Wk4 �#ը��&�2: 4Gԥ���ˇdYĦ��BQrJ�=��},	�m�-�f�\��Sޑ6���]�'m��C��W�T(��!~���Vb�[�,�X�(H%S(Zu���x�Ղ�9<���f��o���o�Ⱦ|��W�XT���h˶0�x���Bg�ad��-��C��.0�]$H�1���t�=�W��z���g\fm�`w(�y+}"�"��8�����~� ��R=������4��i�C��7�O����]�-yJ��0��/΋�sc߁�����L,�SUe'y�L�����M
�K��Q�W�'�j�$1�m��[�CxG��������n�ɉ߮�E����埀[ʏS��A/iQQ�!���e��xm����X^N�>��F��"����sO3Q���*؇��j���]�7�6�پ]���]�4���7,�hL�1G�o�/0%1b�`����<�f�~F��>��`WO{�"�'��%�89}3�y�tz��؎o:�=2���]]J��d�r�g?�Bv�[�c����>������~u[gx���o��l7kv�ӳ������0l9��j���a[��f�iւ��R]�hm��f7.�.d!n>�����*�����i���k�VU���l;Oo*��e�΄���:2��Rp'��Qs �p['eIu�x���sZ���4������k�L;�n�M�Ա�$\�m���tM/j\�z���K�	�)U~`d)��BD�v�x��TPtx8���)�B���&_�#���Kis�g���$��8Mch�ՙn�fY����a��ԓ�tb�p���'��A����]]N0�`2/x�<Hn�}k+C~�L�t���pA-�g�_���ˁ�#�k;d���&{�B|2�h��W��<�s�R����]{Ыy�;9t��JV�WS&�Kb���G0��I���o|M�	P0-h>rx(��d�m"����\���mj������=���4�����	I	�+���K�m��B�c�r�]��EteC�e!���029�� iv(��!�&�k�>�<�N:m='�u�YF
�6�=6�g_�F�yQ�*J��/f�����#ʳJ�=�[���aNg>��~��/Z�"�E�םh���v�~w=�*����;|� ݍ;s�7�*6�\B�L��R��v\8q:	D�WwxbQ´+����ǭ2���@�̌�hU�P!#�pG0�� r�Lت��,N�ڹ�����Q�nK�YoO:c
�3�������=�e�C��h��0�[k�����-�[��m�Zژ����*�^��з��Nyӑ˞�dʹ�@5��S@���;�&2���ֵ5�;r-¨@K���NVmfN�ˌ�
�#��l�X�O�X�&޻�fV�P|��%��)_��G7FW=�B��
�e�d��ӑ���1�Dl�/�e�J.K�ة�s^k4�70���� X���)��@�a��]���y&�|֙�����5��Y*d�������L;	�n5`�݃�Q�u���vt�ٝՃ]�<bv;߇@�D�&�$J��F�O|"��b�vx�XGo0�7�Y��Dʏ>��ߵ�,sd�ދ�cqy�/��#�ےP�X�C��{�*Y�H�{�3A�T+�/wJ�<���@')4�_*�T�vP��~��
����DLШl��������N��r�P#Ss�J7��(�_dX��Ct ��~���xS���l�wDB�I.<���0��g"�I@>Z*H
��O��W��Ǧ>Chf�v_�d�����CZ������Z9��'�`���UD�  ���k��,2��N�'V�Ӭ(c���L�O&�TQ+h��'��k|����'��=��b?)��G�0�
��n���ݛ`��a�z�[��a�A�?���C�v�A+�1V{�೴�w#o5��ė���8����&{⹔��J"S*O�~��`�f�-���-��I��-�Y�U&<��k��c�U��Q��҉��,��v�z�P�,J[��d�.?�ݚ�E66�$�� X:���%K�����e^�	Ƿ��*�7�������cK�:C_���'��ϑ��ek�3�GQC�1����虸Ԟ�f=����@��7��00a �6#���[T�$Hx�M)v��z�4��uG���m;9���V�/5��ȋ~���U��Ao-�n0�'�E=Ta�*L����ۿHA�e|	��0������U�����yD���i��6�u�t�`���[���B����	=�v�=��C�X�B͈��w\$�j�f|�Y%�rM��j��wgdaI�̀4���'b��OWj[I?5�4S�aa��$�ƌC'�{���Ot��C�-Q��j�MH����6ŚUX�̇�GA�/to�?A��w��3�w�]�����!� ^oZa�� ���ؒ���?թ=UFg�U��%�5M�τ�Gw7QS�Y~kw�6U���Ϳ��F(Yd�����7�'�[��EȔ��r�������,$�-DDdS�;����WŴ�l�����x0N�Q�GC+���E�.7.��~r}�z� �����zk�OSk�hQUTK?�e�pg?�dg�%��Qk���H���BD-f��<e����`D�Z|�mZ������7�Y��4�i��u�0l%�6n'X���^�:��D���R��LYb��כH�}5�Xv�[C�G�,�!�H]�����!�!%�i�c��+[�l!���w�v0�ғx�l~G�M��Ѿ��1�Ul���J�b���G.b��	%bDU�0�R9�Cb�����%b��|�<���kWVjs�FL!6;�C�i0�R���񪺩`z�|�9�1	� �'��O���V��D#��>���L�zeh~�)5���0Յb��_(�1�����ڱ#�@dD��#�G7L"�q
�L�?�yE��Tm]�m���>�fU��H>��ZM1%F���+��)É�L�m�_sis���R�z�u�� q�WD��T9#[�	�$?��Fƕ)���Q�[ޮ��	�����0l'���.��LS^�=��k�T��<�2טro��XO_|
�u1�ΤʋI��Ț"v37B�5��+A��B�·��#�
@/�m��+�����#�7͖U�Β���k�Dq�#��Nv�.��2����V\��9��C�pT��)�]��˚�0�֕����!��^T'�7��u�`6���~zI���o�u��n��1����J-���.�6�o��=�
a|�G�7��C�4�ӻ���D���3&7E�8>HWj�~����� y�4}?�z5z�n��/ ��C�	��O��Kؓ3k�.�'�P��gmλ[�JV�mBS�#��ь:�C���n��B財�pRʗ���Ka��(��q]�˫捻x)����1��.a}>П�����#��z�W�����l`J��H�m��0.��j���~��!�M�"�O�g�7�|����t$���ʦ
�,�x-�kbI�P���a�!o�!K�^O�3��e�_�?��P��yq���&o�?��N>�v����[}��ՠoe��ۚ	T9K��%5�>a��[A�6���3kxzU}d'�/^7GLr���t�	\�j5�S�y4��w^�Yw+��?�+��L�~������78�]�㾣v�b c_;TLi �����
N/	d����\W�]�16! ��hdi�Y7#,W�QU��Y�`�a�����p<㶎ۂI��NB�"�2�Sؼ�+4HQ�,�ܦ��<OD��`�]�z�\��TBs��*�����g�)���s�RǇ���IP&;v��V��~.*I�9�Vb��S�V|���p}F����"��]��W��H��-�K�z�� �)E�Ͷy}7�%R:E�`q]+ׁ�t8�u�s7�z>��E��ƹ�^ρiq����!���ɵ���]�Ȯ�/=��u�r.�����:\!��~$|Oj��C�����
�A9e��V�]9=���п���XW�a��?eReeO����=^T-�g��13�&�?G
����ut2�t�H��� �ҵ��}pڵ�c%�h+�P"Mjޑo��jK�ߨ�튬�� �:�
�
��a������?�q���f�۱9��Q,�/�4�RP�:u!R;�K_��ί.����T��3���7
}e��Ojr� �j��X���۶G��Ѽϖ���&�	�)�z�)mpi�<eQ��zP�jN�/�@S��k�[IK��.�^��C�h�5�����}n�q����ؿ�
�Yk��m+�4s�݋�i�X��Y����*�ei'�玏78M�K���=dx����H@ ��d��h��f���^�� ����	�����E�_����bWT6���;���>lq)��(3&���e?!/ΙسA�ŀ+;`4�6S��n-¥7�J:�N�훨��d������ eh��ۆa�<"��{���V�]�b�t0�6��S����m��x�P�ν��As����=\����C��t�zlL5brh5*��IC�:�@�r�0�� ^�8�=�T�lt��=�b��m��O�� ��>�sCM�g��N�X$罜}��+�4̞6ƀ"�Lt�8�M��T��I?l����H�߱��]�9��2�9�m �O�8���WÂ7ʠ.Z=��g#3l��d0ƫ��v^}l>��^�����O'���2O  t�[��GJbz�"��}��� �IQ���OB v�l1�@Q��/Et'�7�*Ux0�M.v9�Ϳ����"�xұi�6aR�z����Z���
�5�n��.ٔ�(�>V��Ø&�S`�yӉ����N�y�:h���L����ae��R������Q�!&�M!���q]^�����_���0��eE̈!�[7n7.��֛��� ��$�z��WL��r��š\��q�8R#+�=���݆<��ء�R�RN(�U��h?�V������QF%�~����½��MQ|k�b5��e��?�&��d�ݑ�ERޏ+�ƦM���������cQp��T^��X������"(:Å�9��촔���|���z���V�ȟ�]��=�
u)��������v�\�q�v�g�*:�4�I�$�@^de���)��	~��,�Oj�$2K���߇��U�K򈭒���1*��#/�%�_s�)���7U��RfP AW-�%�����)U?q�ö�ܤL.[�+�_�+�8�#�YY���D��e1����T�{z0eE-�����4g!���īpP��/�-&�L8�0s�
Q�ܹJ�2����/�fIKᖲ�]�n��A :N�y�j��I��  ���5��| ����V̺y��g�    YZ