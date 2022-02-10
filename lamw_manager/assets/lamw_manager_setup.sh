#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2928402216"
MD5="202568a941504de22bed6b6f50d20a29"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26140"
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
	echo Date of packaging: Thu Feb 10 17:47:59 -03 2022
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
�7zXZ  �ִF !   �X���e�] �}��1Dd]����P�t�D��f*� ��
�EXx��wg�Rg�Z�>֦��E!��xv$�M/Q}z�>*��3HwX2?�=1v��$��IX��{�f�@��P�v���;-��!K  �[�,���%��S��5g�H�-�԰��i}�O��+�� �d����UF�‽A����4�)���Y��N/�Wo���E���o���.��u���yX6�{bG�ֳ��+}Q!�fg��my�e-��"���j���R*/�J�!jA��2t$�*�r��?=��8����F�<���ƮQ�R4IΤ@���`?&58k��mp��ƀj=f�U��? D_+9��?:�l��V�$Q"j�]�1���;[sY����j�STg�#� ��H�Wq��.m����9���sA[Ld3�o�I�Cݫ�Vc݀�ީ��)�)�J�ły�*�d�ta.��׽񀩱$"M1l��1
l��J�>�X�&{ު�b��܅A$,&{�В�B����0��b��WiD����fyc��0����g�<0�%ؿ��G��I�.=���@�u��z�&�-�Np�6c�F�R�]��p�f��W�H��d&ȧ���<�ʃ�m ��X���^��5x�j@G҄���]5�"Ƿ�`�/_��]���p�:4�G]���I�[џ��kQGL�֐x�����P{�m�Z�	O����;�>������D��7׵�R�H���J7����hK�ep�l��z>�Em�b�綐���pF� Dm�wr?�#�������b�F��/�LU*�md����PⷝY�Ԥ�ˀ��r��+��K�6�"N�b59�/6����z��%�<.H�=�}f�����:!�
=?��걵m�i:�%�W��t 0��ܛ�|�I��!ۜWA�y���؉���:�zLޖ������R�ʳ�pfm������7�XZ"�+}9����	sQ7��7HLhC8�}Ou �K�+�Y�9P�j�vy��L_'UUe#�5���p�m����;&��|�zK��(,'�y��}�_� H�}9�`8�Vjv�g�՞��K�F�_%!ܗ�9`g�9)�D;O�)����r�c�=� ���a���}�x��քX�����I}�Q��T���>Ȏs4(u��c{L{�7�- �q���_3h��43�5 ���T�|�0omUO�� �X.<P�(��k`k(\7�8�#<�w��wg�^+4j��'!�4�l9cgH�=�]���/�����oҀ��1r�J�*7���D]A��A��ڊ��Vo�H��)&6c�T�h��<�3����*^;ʜb8�e��j9CX��w��φCn�lH�\Cz���I|�&�����Ul���K�F�����h�ȣf�|�ߍ3�_t�=��c���V��2�&ʇ�!��5��� ToPBK.���� J��w/c�y�$Yڦ�솶�Į�]?�ᬽ&okS;/d�ĥ|�M�E ��p$]�O�nLp���)g�����}J��۴Nf��H�f��)���(�_�����;�J/�T�
 h�\Ƌ�z ��.���Qg�)�'_X�ճ�ɪ��Y�Q1��Y�q?(t�gˑ��< ��%�=Tɴ�}�t�shFm�F��~i����R��5D8�0���s��2ݷP��04ڮ���iȪ���1	�"����[DP��i �3w�+�O���ҽ��
hMX>����3�ap�3΢s����mI�b⒫��-��(�KbՇi�G?
o�AE͞}d��4�	���{�t�k�i}��a��ǉ�7+#Gb*=�UMN[�!�	gic�f�pLO�~셃<�m�B���ڎ�f�q�u cbT����'�/�;�x�_r��)Y9`��Z���2��?~���㕇m�'����.n�zV�Ujp_B �Zׅ���>�a��nb"����v�&V� ��4ب���> +��cew�* 7�\����3���'��,��^Q�:Q4r]='�?�	��t��Y��r���bB�1׿�AҪzIa�-�Tq S9�v�9�)t�G�u~���]�
��Nb'B��/:�~��%��l
�e��w���x	\�(WA�X$���N!d��T<ؖ�xܸr�I�mh�e���*��'9n!����[��|�Q#�Ejf7WM�b�C%���H���R�0�/�9�Ae�W��ݭ>t��	D���g��8�R��q�L0g2CP-fԯn@�����v�s�+uD1 ̺域Xx��=wq[#-z��v�$��ͳ��\w�>�����Q���
D�g��4vT��'M�$@�jm�j�6�zupv�Xٱ~A[��q�i��^�t�S1 ���`2��V���u{@�Ar����%�� �D�CV]�Q<jv�3�0X���T���#k"�?y�~��Y �&E�;��������]��!o��Ƹ���)YŸ,�щe9��[K�.��R:�%W����DC�?��0��M{yV(�-�g��`b|/q��Btugs��7���,�[�C��q@�v�F��&ZGA~4�"�W���bD��US+��&v�tTl)�V8H�|��7LL_�b�0g�����ű���`����\`����4K�Ny��>bN��f@;��@X���N������o���*-�8���)"�ҥ��~��}^��6U��Md�����}G7�U���qɒd�Ւ>��#\VT��wzd�Tc�m�
�@�b�S;Ê{l]�u��a��z�M�0Ԫ�8;�����N���L+����dW|M�H��M��])���V1\���s��X�1�49�S�H.-���F>G��G�菝<�&��hqڲ�s��3��KYCD{L�<e�T�vOA
[��2�@���#��c�	���И�c�q�/��eE����Fr&�>��C�#���D��}*f( +Y&��t��Y�\[�j���.���B O��D�S롲�K����-�x�å��@���䒏꣘D��}���m������vNԪ�e�T�*NI��@aA�}�ڍ���l(��@"π���uG@��Q��}��
��Y~����=%˴�6Hqu��%u�]��sP�Q�8;�/0v*�&[Z0#���}oә=���C����W謐2ɑw�/��j��HE�o��̇K��G)3}�U��76Xk�Kb��s��|��!�h�G4g6����:3��Fz�wx:������d�BS缐��:$ʥ�Hf2��N���{
3n���\����[w�"pt�M:ZL֍;�f�\��*z.��O ���+�\������l�X�i/�/�HK�\�û����)�1�b�o�I��x:�T=��j鿮8�i��tQ�a���@�@@����OY��}���,m�����*R�.9�\�u?@{��S�O0v��H� � VǪ(�gd�r�pc�v�VI]6�Sy@j��:�������nVV���r�Zkx��x̺�S�1��������©4dL+�W�Dl�U��3�-��s`�&9���b�v��Hn�4���`�W_�l�s!��2MC�/��4���F�sd7�/��Rd�A	�[���η��9U�;tWa���{_��s�k��]U�c��McdO@�Zd��8�۹<J�=Y�Cފ�aFl%=z�.r'qI[c�9g�J(��n��q=�P<}~{��b�۱�o�8�]��\�'9�������t��If�Ȁ�h��30��C�����1�Y7-!���]��	�W�X��V�tsY�鍏��d`�zP�B� ҰU���yX����I],���ҬI���NGp�����f���W*�/<R��N/6ui�Š�Rzʓ(��~79_	���Ϩn�44L o�}���*?�K�}�͸ F�|�Gv�2v�{/\/)���r"�ƨd�ϋq��:-(��Ꝏq`��H�L�	��Q�;�b%����v�;���@ox�-7�'l8r�r���ES���7�-���zZ��E��q�/���P�f�a���ܕ{�����\��BuO���pwo��|��Es�j!>�����w���^�]5w:�k\7O�t��ގ���&��P%���s��|�oA�Ia�n�q�]q��m1�5�Lϕm�=mC<��-P��L#3FuL]�\����s�[~�5v���FUѰ?&r�G�����b'��Z��*���Ϯ#��"��9isr-?�L�;�Xx��ME�FQB�K��c���<h��h�2��H3^K�����vn�"(�����b}c���+tJ�ԙ�z&Y+k��FR�j=�
�"3�)�*����X�}*�6-�E��U¬��`��[�Ŗ%p���\����#��уV�T��J��	=1�wr�R,|�jاt{�A���
��]��(�9��v
n��_���X�t�xߖ���Ә����U� h��ū�L��eb��haEb�:���o�عXl��uk�I���
Sç%��[fc���7E��=��Aq��#z,E*ar��3O�"���m����6{j~(�����q`�ˌ��<���(��@~�T���>���xY��G�[>6��B\g����`�ӆ�07�4��˹Fۈ���9
�P���th*�m��h��m�ȶ,,�Ք�t�r������;�0�GvLk�%j�0�A��zbB��T�әK�чr�-� $pZY�<�d�r�7�+�0B8)lN���p*�G��v������)A�,�2F�ˑt��b}���ݶ��	�m��.�$���5�O�3��h6j�(��]�w�Ҥ�ae�l6$k��Y�t� @!��Th�Ts��ԡ�1����{��=X#�*t���e��G�� ����Z7=�`b���%G1 �͛�500Ԉmy:�����_�d%��el55"d��(�h~_�V~�:�js��Y�#��FLP��ZG�k��2�*��h.�~�:/�%c�\��!)*L�~_�B�a��f:��OjMi�䱧�^�|T�a���|�B��D��a��jd�Է�>�[�ȱ���
T���0%�%�,���V�e �����q�8$�I����u��}K�#�]�}f�ʉ�)�c���edȕ4�g�u�IRĄm�9��Z]<��l�|f����}6_8�����ϰ��O � U��֛�1�]隆�J���(�7A���o�	r�� #�:4^ev�Jc���maK|�(9�#�Ƈz6fJ�#�c���[l'9e�c�?�>P��vI�Gx\Az%��ᙆ�tx>r6m+�N�}�^Bٜ����1xQ�kQ�c�_28*��R#dy�%�g��XP�&[F3
8�_��5�m��+S��*�ܺ(ϫ�/T9{�X���q���2��NUfI��t�,!��c|k�o!Ar�-y�c�� ]5�v]N��~�C`/DI�'��$j���\���
�=�K�A�n�m$�c����?9?kOuRj�$���Bo���޲�.=y�5ђ^%�+��7lb(<����,���M�c$��E�֛zK�F�Pl���K�7����Z�a���H#���ed-�r<�Jࠪzߞ(�����U�H�$��]���	�����N�ko��'��6[�=����uJ���_�~���<&/���;�r׫�a���'D9v�$��	��v���ζf.<���+��H���΁ޕ�,J:��о�Ky�J��H����U�1c�\�kZ�~&��e����
%O�d��8-�hA=�@%EtY��	���2"Ԁ�f/�Z��zY���ҰH��u9�+R]���M�s��@	R��2�tW5�7��O���K_��f���i�f�[
�|���ٯJD��^��8|�(����LC���ȷ���A��R���^5@7���1�U���`+���0�]�\�^�l��%z"O�H�,���?9U�u%A�������4U�ݶ���G����sq�R��B �%=�Q�}��W�#Z���u(WWd��_EyثJ*�yw�HCW8�fڥ�jV&S�Ӷ������byZ�Ș\�-�~��#rR���䛮�X#K /�gj��=o�;X�
����b0��V�JF����`�aH{z��{?+�ƶrZ��v�oci:�0PqY�k�,"�.1����_��%Ơ�#���@�����{bT��
Ϥ�f~M����[�����"Hu̹ѩ�>j���Z�_A��!��z���p;����N�.+��amHF(Ԧ��v��k�kp�5<MuC��<�
�_W��@��{{�˦�uX�!X�+<��u5(���:�������-��M�_$�H��j��q�@���^��hH����ڕ�+�<�C�T(�suT��[���B�Ur���t���ˤM���w6=�Zq~�(*(�
0����_�hɱ"b?���-{��{�\����1��`X��g]ś6o�1�%�d�.�Hl<@
�M��H�����	��6�-wWC]�p�i����u��ʌMTPyp-a�Z����ʶ�Y،ĸ ܷ�u/����
���ܱT7$�.<���"+SЉ��&���n�@���˨Ҏ1'���G5�3�����Pmi��l���L$�	���i��1X6g�+����2�z���d:~�H_(�m��i���*b�;Kr�7���[��-�{�R�p�E�,W�"c.��)Pk�-:�X�xI�]R�i1T�i�9�pΉp��1m���?��%���s�jY�)	�߂�!��M��tPT��Z�|���љ>����
�5C�����#�d(W�v��&�a8AW����Y�R�����m�5� ��I2+�(7���B�e`�MH<��s��ڎ�|�R*t:�� L�L4&�'�}ܘ�.�I,�=����c�s,���)��-V;f'R�(,SiT}��{&	ZZo��yz¶��4?��W- �)�
��X��/��iֈ<�-fù�G)ㄇ�`]���4��P����v;���k�m��:�@,/`��z�#���;�._�eqy�h�q5
+@��(v����u����]��S��.��-NC�y�K@�����PtI���~��hEˀ�������}�(��5B�YAd�4���ĳ_�>�R���Jq��d�r����턞4�G�3��[��~��h�;�=����ed��1ن`IZ��wڄ�1iT����Ǔ�Z��:�'�4Љ�&C4.����Y��t}�i��.�a���+Ƃ9��X�QGn�	t�pn ��Z����q0�6G�|�:a^i���)�7��p��`K����q�,����?���G'�_��ĬzSu�t[%��G�J��1V���4�j��!��x�����f�H���WS�fJ(a&/(� ������G�����'/.�v����Q��t�uc�^ۢ^C�wa�Y�J {��	�:�CX��@b���!�We8}�����Ũd�Yp��B�:Ŋ�l����6� Pp��/���,8�S3 �p��Um�
�Z�=���i`r��|��M����aڕ2�)A)fw�g|��4�A��7�x�g9L�4ʠ��6YY|��	||@�-�y�	ff���s]��J�e��4-I�H.@7F�S�"(�N�� ���>��x3XΜ���~j�CX)\�rE�m�b�uZ�Ə���?��sO2���-$�y8p]-�Y��fSK���L�l��@�]�����h����f�M^�[�3�Bs�AۯZXWi嬹�'�K�g�O����j��� �n#�H����:U�o�W�z����;�,[w|�A�~ku#B�Cp�����[���e�F��W?7���_3k6�xAWz���&����ɤkZ�˚�0SNBRIZfkb�G �ӭ���\�Ԯ7 /��u�A��b�� RK1B�=�ʑ������Z�N��X�N���~y5���7R���2��fq7������1yZ��z*,~�XT	�}����C�i8ݧ�7�����ʊt00�/�d��#`jA�(��+<<ɢ�V�9�]���!1m���0KZ{V�5wQ��pm��|h���zl'�p�!+��*������u�'���F�m�)0,����"^�q� �h�+�5��!�%��<��#��$�i�8XE��,�*����hY�,0�D�aW��8$v!
���4�8�ڍF�r��Ć�m��g�FE.����
�F�Nn�qϝ�&��<]P^����Py�1��*��@�p�����M)��|HT�3�gp�Q���^��ˇ�a�̷��K�2ֵ}��.�/���p��s���ֱ��f��1���p�C���B/[�;A�;az50x�w3LӒO�ʷ�2]�c�Į��;mJ��9�S=.dc�19N%��ڈM����j>�2؜RHm-�X<��}9+�}��3#�z
�+b8T]G��똺���kK+��82�9-�E���t���I5�r�㯦!p�3��I�a%�AG���l/�{z�u�����?H��|�E��ů�?�:lz�qn��]�d�f}}�`���*�Wg >V�}Ŭ�HG��U��[�qy�AT�fuiG�f335�J��G�%c�l���=���?�9�Go�a��6�B��7�n��y������B���Ʈ�ͽ�Nu�@�P�������s3l;�P�IBgR��ϴngR�����f���d���*��ΘNZ�yE����9��+��!�8��~{C���E�A�`���G��_�\�H����9�xcث`}x��U>��,��Lڷ}^
���
ί�\�g��?���d��j���؅�W��%�_�U�: ^��{��e-� ����f	E����YtێXЂ�#�XII
�B:�)a���,�'j����p��w�xfkE�CQ����o����d��
�5�)�����=���������Z,!���4���^?w����������6���?�a,��~��*k�T����N�c��s	\���K�0%�g^��^�ae	\xx�9��ʆ��i��0�F�C���Lre@��Z���D)�nj_�'M0�  ULzF�ǝ�e�b
�K���3G��\;�P����Z6��������������������G�I�$�o����
�f6t��j������͑�ʴ�F딈vߎ`Q��qUm"�u���y�>�a����_�\T�@�b3mq`��}d�2D�1擿&�S�(�۸[�� _�/	�i��C���9NA�q:���	c��aº��Jx��� �r2�	#	CS����@���姟q��b�]oJ�r_џ@�h~���xrգǸ_a�51�ēX)�m�n"�H�ic��O;W�8?�O���׺.��"�"N�ں��<����S���k��̓�M�Z�V���3�qh
���Q ���N��J@�W�spo2Ł����2d��j�-r����-Ā_=��t�W��qQ|��\)�0�.��M��G�!,k-��X�g W���Z��S��ES�{%i�o;�����=�ݿ3	��'Q�^���}[�]�#�J8B��ݧ�+��y�+)��VY�O�\v7�}yk�|�UG�Ȋ�B�s�7�w�$5�:�t�XLs��k��Q�p�=7���uiD��<�X����r�W-^@F���`則��E����O��q��;N�,+�@��W��#�۞kG���9�x�L����]��7�u�뇱!�g�uU4�]����P4�7b_�9 ����}���i�����/�_��5����ӧ���|��*[׫��U� ��� �զ=��T����2��' |V�/K��2̳�K6�
���vÛ�����~?�a��pdSx�T�p��"�����nn���!Ԏ2{Ȱ�J�&UW藪�Aʝ�:k���h��jmI`E�Ұ���y�@_��=�he�,��D�.�)S2�jD���9�~��Q-�Y���ڻܷ9Pa��2|�޺2<�Ǽ�9k�W��&Y�� �u��h��k�'���^R�� �u}Jym�Vs�U"z�,�E�u��V�v�g���K���}�$��z9[�>:��q��@��=(2ߑ��,��?����#�
����}�W	`�iKr�/�5���=��R_d�N /o	��0��t�\J��y�)�6h�̨�U��_t�*"1�L��@���ti��:/WJGCI��_j�����lt��V-#})L�Uw�&�ݓ��Da���S�{�j3N�#� }n��&2�ѐ-�����G�Ѿ�d#�<�W�طGAΨ������	�66�05�ۅI{�瘌G��Ƒ�v=�w�����Іeh�Aj�m���'Ni��#����6�MC3�37/C�&9Ek���W2�G��p:ыb��a��u�;*q�sh�`���'��^�=w��ϟ�#�yD�)Պ)p�9�D���Y�����y-g�t��F�d��=���Qc�������	�\�҅n�o��a����ARs���*��C���̡��}�=,��5���C�r|4 o�d��_Q]H�r\6���jς�#�g�������0.@�� ^��-�K�t�4t��ˆ�=��T��ǺJ�Xϸ�i�ݺ�5���G���h�3�̒`l/8[�ޭ��aU^��>>}�/�������s��~�<#���Ӭ�C4Y��?����ߡr�v� ��h��.����t�2�ZGʡ4�G���6]	*���L��B��P�	3��F��h	��Fwzc 6a1Z�]�j?��:�?�|IU��.v�p��1*�ҾG��Z���	ށS���t��6�z.�y	�Ԑ{Fܼ���΅�7`hˤ��E�O��׻M������m�1�;P�M����" �`�2��s�����ߺW�EV�a�sDٞ#UZ�<�0I��;���M�i!�0#�0�n:�m�s��95�hСP��LD]�E(hN���l��z$�+�����!�{�ZD1��CKM����w[��Ŏ����x���+�ۍ����������8pUYڃ}f���;����`2;3X�o��VY���T�4�zn���(
�2b�\������R�`�:2/M���;�kW�)7�ns�F�����31e�<��{���M:f��,�ᄂů�^,�sj�����z� �U�r\�G�^��T3�fo�ݔH�S�}<7$�&{&�Uf)N�����O����1-��VCp����)�;k�pAOu�D�J=�:�k�M�r�͆p�lpC�ȝ��QP���g������d?�E��XP�f[��6iUzk���#���2Ynt�D�`-�+z*�>4�>�� �
�����}�,VA�y��d�%K =pl�ݦ�7r�����Qp<���;�{,_�a�允*�js^(���r���P�Á��[G���U,�F��� d�(z��qx���Z䂁�L�~W˭��a�>�ش:���K�:ჵg*���}��|@L-9�f-�a�4v��cA��r#��ؔ����a��R��ݕ��	P�!KVW��+1�E^`k��^�c�[�#k�^�/�q�E�̰�K��ЛE6�=�C�Јl�@yDE��'�N�F�gi��Q s�)p���;��e�P@�V�v�r���ͫt3'_��R_E������a��(Nc����]���rL��b@���rW���o�>�T�Vogy116�b��F�1��%��3�i�&�(9O��ŰlI�%e`r�Bi=�4�_��Y�g���0^������}��R�`�+�B�"�<�*�f�E���܎F�Sn�#rA���׵;���KvTk�@�����q������ky�7�QӐe�zA��em̚b]����;O%��Ki��U#�	�?+���"�B)�0�.�Ŗ���X�:a���h�2j�K����^͔��ɦ����⫍vЀ��R��bGfUX{r=�W��yU�=���K�Ⱦ4�Q�s�f6������I��+'���-�5c���v����B�7�CZ�H7@)?�@�l�X
�;裭��6 Ϡv��,k����%�e������q	+�@w����h@ ?��Y����Um4����W&��5ԋ��Ǳ�0a���nr, �SN�43�>.؛�l�G^nYHA��y���C����K��Hn��$�pK�}���l3˪|H=L�MjfW��zWg˶�rEڶ��Z��3�"�����΂\����G�ΠN�����vȤHZ���&�ᰳ2�{<�k�1P��b�%fT���+��@����N@[�`I�'��+4����3��G5�т�d�I���Ow
��d�����K}lr�dn�n)3(f�Q@�hɊa�^�^�����X��0�!!P��;Xe3JVB���!�s��p~����X#t(���Ui)W�B����Ed.
.��+�QÚ� ���l�Χ�J)����&Z뷆�HL����m��S�~���1ӽ��CXҭr �XC#V��؏Ntrq���I��(wV����ϙ)�|qyq�2���?�uH��sN�!�<�]�7;��n�73�q!!ʂ��ǶT��zt�
�|���I@���`��h,�\��2w��7<�����j����i��Fnb�'w������f2L,9��?d�\�O�F
��7��5�T¨��p�����&��[����n����!����<Nq�I��静(f�:qY�l��Q&|��ǻ�0�?�?��t�t��<�fiSbZ.�ƭ:f��� sI��sclh�a�ѽ���Y*�j�(&{�Q6����}�Fg��|D�U�������O'��������C���):=b��e�D�ﶷl��^�zX�t�N��cr<7e/_`ul5�y�zD�C_�Gl�"���%E,L^Vg�e�`>��� Ħ�D}���ʤ�Aq�aĠ4��h�l�+�\@[�Z-α� �R���=�$>���v�d�m�;���&B7O�X�����`@�V��<	V���� ��<%1��;R��[���cSk��>��u���p��͏��miJi�C1���KǱ��GKM:�7vB�{S�55���D n=sCn�+6�m5ZD�K��7��7�n�,g�"
��i��/q!�P������e����"���8��+�� <��X]����+�+	.j#̜Q��}�2К�Y����iu�.�p bejp���K��t"!	��.%cVi�j���  bvv_w��`�߷��`x��T�dg�$QLoBAD5띛���x���ߙ�JI)��RJl����.`@�\��(ZkTeGo��ږ3��W��<e1s�(or)�#雵{�|v{�L��L����R�=V{�x� H���r� ҷS��� m-���Z���N0q�VeHuB^��y��)鿯=���<A{������v���Q�i:�c�J_�e	.�m���Q�&�̂r�m�I8IqN �iA�ݜ�Fb7$�G{�}O~��|��E/�����V�)���jt2>p��ߢ6ŉ-�΋7y��h�.('aY˦WN�_��c�Y��ل�L@WN��������i��<��lb)�dv�^4%N���7�~槁����TF妼�������l̹g�7���*�e���E&rRH��|�}U6S���xf=�7�(�H����$k_j���a��HcJ��h�R��B}_���D��p��(DG����~[9��ˤ$+b�����=G���RL����HGT�
r��蜍�葫HK䆓]�C}Ym>Mh��W�J{Q��)#�~u�W(~Kf�=�:�7��8������<��������'��4��3��ciF�f谿��ؖ=�h�B���hC��Ή��HT�n9��6w��^,�͛��)|l�7^��U?=ڡc1��ks�g���>#)���CKnw
V�X；���(s ��c�tT�׿�RF�'�Ju�}��Qo8X)'�X�O�1�cۻ�N��(�֌��vxS�&\)� �͐�?���~ �u2�ʀE��s�ѧ����Z�f����Ҭb#?�޼��Od��8����������35<^����a�R���֒1T'1�&��s޻O���J5�!�]���F��G��� ����QQdY�T�����2/�Fb��1��\0#���`��BX��G�T�
[&ld"�G��_�KmO}[�@7+#1��
�G�v��xx�
6��ɩ��mR.��^�k�>(���	��;��� c�n��0�^��;�d���s�qY�4�B��� gꓫb\=�}�<��r(�[ڴ���b�����|iR|��*X��]�S	��^�ʔ���p�����ŹRS���i�0dFv�	��z�J�^y �1��<��X5�y̩֯w�`f��eEhWz�sd�
LG����I�I��Y%���5O�R6~1i'�ڊ�w�n>]��6(��w�	�]T�j�=�H3��Ȫ���D��Qc6ˮ��b6�B�	�0]�5��8�I�/��~��	���^�Hf� �c�>G�|kz �������א����7�`°M�M&�I�< 5֎JZ>0���Y������ʢ��#9��mqߓ'�ђ�U�ݤ���x(ud��.�.��}�o��h�����N�?�|���ʐ���n+�v.ܪE2ޭ��Ի}�aK*I;��,��H�+a�I��FCڪu�@�L�l-���Ko�]U�ۃ�̜���צ]w���z@���`)����'N���య�^Ô�p�e�ٵ�*�+բpw�����b �Uy���qE7� �s��Z�]��F����&�S�{V��Lo�<�;����ׯ(p���݁��2�-"?-��_��s ��~e:^�\l�-0הqg%4�rswN� ����H�s�d�ܢ<��'T^|vb����ɓ�]X=�@��
����r[|Ϥ���ȔQ�^�[㼾^3�I$�p�
A'��a�����?z��V�(��-ץ���l��>b����P���䶵�������#����P�a�C|A,N�e������F���u��" P@i����T��U�K�t[���W,�U��<@��~i�s2�2�S<�QWn�h��=h���;�l�gϭ��Ec���7�|e5�4�����EV�L&'U�ƀ;��0bV�@���l��c΍$�
h~������.�W���*�xM<@�WV��N���f�?�"�VE[�ȩ�N���RO�����	|���|C����>�O�WVnF�Z�$�G��@v��-��V|FG���B���8N!D9�do]�[c�T���Y��T��� Gn��S14��f+k�Eת���h2s��7XyY��~F�ۃ�H�!�/�Q�;J�Z�n��`�o������-�i^��bJǶ�b�y��[�|�����A+��������v`A������({� ;n��*�}X���awz��s;��Ɩ��F&6���q�y�n�o��~<P�c�9**y��ą��H�_��2J+c�J�p�=���7��,!.���tҙ�w>-���hۺ<�~sR>^��YM��������셰3��9�	bIdER�~8^��[�]�Oz"k���~��b  ��bJ��XFx�n���9��X����e�[�٪7	&���\h>/�F�HN��&�X�i"�_������̆���[6�0�4����`��y�z�#�Nl_�#|�ˠy����V%2���A�_W{�� �9��&���/ēu/M���w��g���w�Zj��D����Va�LU�f]d��6��P�28�z@��ӣ�g��;��\���@/;�daW�a�6�O��� ����{�8X"���
�B�iil�ua�D�?���|�bt��UzW��1�v�,Ml����en��j��i�R&	ܰ�Â��"��OXH���:�v��D�1Ծ��=˧u{��j���3n�f�6k��3���2U��lf�g�s`�����
">@������p���~���O�A�y_�,G	-2��kY���0仑�9���!i���欅a)e�����u�(w�v(͹���3�B�U�9u�a�m�:-�0Axm��6�'|���N����V�T�	����F��OA#zb.mZ{����@q�	��'}K-��'L�c�6PO�4��]:����/��L8#7\|ޥ_]<�0�[l�v�kL�\�R�PPr��fkQ`�W�v��~6�y�>��������L^+j��І��~,�Kua�����i�e5����C�c>�7FK�[�(��a^��	�Xɐ�b^������5Sȋ>Uu��E�M�Vq�ݙ��ge�������4�r��3�;l�	b�W���f�Lt�M�oᒰ:k�3��ڲB8%c�HH0Di���F�)���� �ش�Ƚn�R���pB¯L��49$| )��/��/��bRD�VH���D��I1̒ �V��y�	y�\�U��T�E���toI3�V�yH� ԗ&�7ۙ1���t�z1��4e�%��>p`�W�����̿+�'	�c��֜Y�=p&Ԥpwwb�_�8��wp���
�&n�PL���/�[J��y��ȋ)6&SB�D��\E�R�����^磪��VP9������8<�2;��?lXʔJD��ɋ��-:K6R��_���ط\V���Cbn��T�)u19��@�L
��6�E��{���%	Z�-p*�7VQ˔���b�m�"����z=>�tl�c�X��uvL��(���<{Z��`
w�7"&����֐v�P���b+�k7��IK״C9l �+�J�`��pݗ~|����/�K�y��z�f�w����K��V�<W�K̃�OP���ÿ��T̓:q�Ϧ��幂�Ƞ(T�[g�m+��+=�̠�l���O��)C�������mT{b�2PR绥��d��FS��/�|%W�n�n���iP�#����k#���.�n�����n���^���ac/����8�4+ęmI��������0��¼_%�]�/6d�[�K��s�:қ��h���4�j6d��98�r�j<w�4��,�T>�M��v`�5P����b���AY�~�a�g�XE�$H�bFH`�LC4���k�4�+>tSb����j�?п�'����+������R�Ch%�p�ꨅVum�-L&�Fon��f�42X6���ӄ3�Mb��2���d^�J�����{6����i-J�U��)t3)��:!m�,��~"C�`�S�y��P?1	\�B��J���4݄���D���������І�^)�ݤb�cx��"�hU{�Y�������9�P$2���ŞAU!��~��Qĺ&\b�[x�lI���"�n�� �����qQ4�}և���:��x�9p0���l�\���T��� �3aC��ru����u/n���!��E�c�e�VmkTծV�,�d�z��h�gA�@F�JN�Q��R��F�"Q%=�1��/����s'mP$k�PO��f6�/+6�+k[x�"�]
;	']�cQPxߗ�O�۞�Đ�pV��M�x0��@���A���7�@u
���r�.K!-�*�еP�{�����0�V	��'o����C�b15}t�Ü���ڃ�l7�7��pH�jͣ�ʝ��3��!D�\�׮)혮� g��.��v�Vn�����l�q[P�v��+'�˴ԫ����[򱉅����:�l펺���(e�c�ե(�e&��Xt�'z]SԜ�L���o��_,�93};�Ђ��I����O��=ꀷ��Y� ����7,��MjA����~�%�rdn؇i�f.0�g[�#�mO�6�[�g�1��2U;8���y���.m�T^1��]�8Y���}�$Y�8X�?/�;��,�p>uG3����N�2�b~/��I��F��a�x��u��:�|Z/��r��@Բ�e�?��	5��F>x��&	�\oT�$ޗ��IF����-c�&\�ї����G&�+@1���&�9�d�!��d/�C���6�Z侏�#�-�L?!�<��MN/fDT�3��DU��r!N%U���jڤE�-n;����v]BQ����Ԃ����O
�	����g�С��ꄩ@)oOP=T��#�`��C�����P���S���s@V���֭*C�����a�'W�s�zb����uK{����,!��^��T��|x���DՄ �ƞ�t����r���c�(e�v�]�0��;t��ţ��ԧ\������9�'a�:u��w�GZ�3�tTM��Z�E�\�2d�S4"�l�<C$��۰y��T2���!WhA��W>�Q��Tר�c��$*����Q�#����[����i�:��0�/��to��Wʩ(q_xt4�����HW�d��2�e�Z��,�?!�	�Xe��̯*Ƃ�vwc����趎�F�ϼ�!J�y�k�OnT��Ket�<�F)���Z�<,��@�~�AI������#f\��v��1\�w1D�frro�6��O�Kǳ�/W״0�ỷ�]�?E>_�W�.7���&^$�x�m��`u�G���4F�Bg��ZmyV:�۳�\�K_�lY��.���N������$�uF�u�>+t5wc!�$�Ky~��W�U�� >Sͤ���aWc�#f���N�T��Ĝ�c�����$�B�K�������):=A��O�à[QT]��1�!{�z
���S�����;��pL�a.m��7���5�?8MS�t�B�8q	��I����;�� �wj���ې[���t:A��ܯ����������J��P�R[�3��?��&1�Wk���@�T�3o���=�%��D�%���ُ&��G=����f��!Fr��	���
![��c�o�ՠѼ I�K	��Oƣq~�h7�Z8�HS����L����!�q���b�5�4�h�2)�ՎSgO4>q7��%�Dq�zi|DFg�{yD�sI����� @�^�m���F�����zV�m�F����ll�cN?��[�W�1tFB�4dX}�U�.9��{�1['6d�������sK(���o�B��q��/��B;����������UD�?3\4Q���"��@2 Ho�+���A8�ϾA����~5�����SS���n�z�.������Z�|Db��ȍߤ�^8��Q���C���Z���̤~fQ l����x��s�.�f��ճ�m�-���B����:���axsNw�t&�I}�c�,�����/5�"P�;�DO���RZ�p���-\�Ng��H,8!V���C�OرX��?�i��� �,��Ӿ�h���!�W*9���9tK˅�0�2�9���%ݰ.XH�Q�/\2U�5�\�V�˃i�FI�V\�(��넬?���7�9݅+�!H$�_���5�L�r�'~�������Lr�3�?,������1%U˦
����<N}e�K���� {����>> �x?q�ۈ�G�g���lHW^j�>P�'O�s>_�ʡQ*&����$��S4�C��B:�[�B7C/��e��$Ik�>=;�ҚΘZ�K�,�Kf�e���	cfh�(?$��g��<c�k���r�f!6T���|�HFeb��A^�%��nH�t.���Ď�Ŧ@?��������qs �W.��L�)}����bP��$������7$�:C�~D�
�ƾ�.�-fv�Dn>�P�i��+#�A~�kQ���<evvDH�̞e?�vջ�ȴ#�ǰV�.��¦�����c/I��J�bBWh�/����&�Gk��])iA�x�I�Ht���ox�h.0��ĞZ�i�®�t:��?��/;!o[�xk�L�H3�9��[&A�^8�}��F؉1hh�����T����(��@�)����&������	�:�#�lҕ��`\�b�e�+~�˅wA���76M�*��?ۈ�HJS
"wO���x��vc�h��
v^|7�p�ط���V�B´��n%�7b�$)�N�H������y��ɾ57\�H���ٶ���CJ���3w0���Y��FE��d�n��Y�^/�:�/�,��x/"��ȧ&�=�ŗ��T$K�+�6�/�S@������ߠ���|��y2�L�g{W=�c���s {���JD�,T@�U1�p	�~ё�n�geGv�zU6B�^��>v�Y���i�1]�Mg�!L`���ۨ���EM��I��ù�/�k�h9�tߑ���
�����<>}|����h��/������së�����,�I�թ��$��p�w��8�����|I1���8��Z�WYf��+X�쀙�$u�FK�a��ŵB+p=��<��.4�;���`*������U���`F�6�ω����\XH��U�Ucߍv�(BB��+�根�̼�)gJn7�@��[�q���6r�v�֔��Ր,��׃D��:��b�;��Z��j��ӪP3mEb�ɒ��Ə?�a��a�xΠo�[G|���}��ʣ�/ȝ��h�̓+���~��Jc�����]\>�R¥ku>�,߶z5.��,I�P�lv����S� ��iw��BC����ll��Y�5�0�v8��c����X�>�	� �4RJC��~���Q�!O��y��F|Kh�	γ���'��麳m���'"0�+(�n7�pD�I5������7�_�1�����L���ysTg߶݆KT�J��>�N�ԱF�e�i1��[����C�~�'F{�w�[i�$���´՗��g=����lS���Bޠs�����SLѰ˭��W&KY_o�Wf�	3N��le��� ���s?���]����CeZ�1����z�����I�����7��T.��^�*�s�5/�[�� ���f� �9G�frVl����V�^����=n���X���j)�gP��<�\*z��Q��DsRŤ���X#���E�l_�7�OJ����D�������m��T����X���DpL�g�9=���܅�������~���P<0�va�����Z�dM�]p�+�ᅩ��IM����x��XTbrZ}�ls��+z�m�Lk<�8
�ٞr���frx6'By[)�S2�v�
xId�� H����[�O�U[�h�0�"i�zd!�C�ު�^�Y#uG���U!݄�#G�Hu�+!��o��+u�a��:�T��*i>�Hd�N),B8�d�A.�*�Z���T�G����q��/�y~�rV�P4�������F���Gu�w�c�n���hI�� �Io:�_z�oX3��3�'g���ӧzZLxb
C2�V�}����R� ?
����`<�p��N��rlZ!C�����������b%V���{�H�'���3�ӑP�&d5�wg�s�yy �!g-�B���"�]�AG ������_��,�r�Q�p!�XԹ�ދ��uj"�v����_�}iJ�5f��}��dy��x<�p}�Y݆���]Ҽ�R���a������*�t��c>u��Q<�lta�3�
!w��dA�X_r��"LYK�Nk�����5��Aաc �:��*ԩ��P�7%@M�����@Pm���Ŷ}bz.gҘ�u$���>Xh}�*��3��(�	h#M	�C0�GS�����x໠(�b���fA*���!�L�he��G@�N�������҇*����n��c����9Z �qȯm�����X�.�I{�bI}��1_W0�5hx��xY؁��W��ɳ�������}!�����ZYK̉ǰ�P�>����	m�m�'�0�Y�_�4�����}�����Ug �&�6�a������L���P���? &_�E�����G�N���Zl\�f���T�h���F(��(\�y3�&�)���j.���MGބ�"���ͳ(�y�l����׏� S2h��"+	4�}�Ӝ�?��r��U���hī�a�B�s�����|>Za���JXVs�cUJ��]��2� �-z�u���@�^].�Q�3�ӓM��[�@,B˿^��ʝ��.�*h�+�+�a��:�g�VmtۻG�>�|mQ<�Ȇ��U�ި��`6���K�^�)�Ԍ;{�f�5����%qrՠ1�g�`�������N��Ԍ��=H5(Ӎ��.��g@�	|��?G�?e�o\;��5�.�g����{��o�3T���;h�����+Vm��A�S��*��&z�I�iH�oO����gK�1���օn�']6�(�x|��՘�g�Uh�2h�����?9�-�2[������U�\6.���L�	z�_�QT�e�)�!���xAW�k���LѹiCOp���M�0�#�i��j`֮?��3@z���\,$ � ��?�g�W��Æ�:���찁���,;�ѡ$�=�0}L^!)�n�"|��U����=�ؕ_���Q���i�q@?)�V�1M̏�Hh2P�{ r���X^ZH����~��h ��Iׅ;�[���Txv�ɍRh�������J�T�Y��-�ӧ���r�F�V4��1I�1@��
N�!���,�P5�a����g�]�˲��'{��z_���+������и"r��;0�N�L�){h���3��TP�,wK�ͅ��}^���cb �%���7(�ͤ���U5���T�c�ѫ=g#��B�4Wr2G�fM	Og�p�Z8��X.����k�IK�
�Ho�)�7i�L�EO:
��!)�?������nq�H���"���@�@-���fHy��b�/|���I�5<hP�c$����ůa��wvV�_B،�����X*�"^#�I�q!x$<��ä�:<�+�1�N�����S'@��<;�b���ـ��_$n5u�J����,/
���˲���&;�� OB���������L���az[��oG�j����fdD�+���S��S_����%�*����P� 5F�����2�ξ�|����3�"�ElƎ,�D������� ��~�s���_�ϧ�����;y�u����7����}gS��B�u�6��e]��wC9O���+�s �V�k.~Pe�Ԡ����Y���B�~�9Wo��̦�o."-�h��Ӝ8v�@����޹,�Ʊ�'����{q�"�rD>􈠌���?��#�ρ��S�0H*h�^�U���{�g$5
��*���N#�����vv�³�k҃��mV�ֈ�/��ӎb��N��;I�k'��ܻ�RyDn�E��(�	�n\�I����������@c�d��	S2��RqO�+���ME����#=8I�oζ^��ES�;��]�cO҂�'H�W9B涩���/�;&��g�%��C4#��M�,i��7v�$w�j^��t�/�6;W����K��ЍޕvgY�d�heÍl�i��k�#]���33�h�;���,��$7�?+Yu��&����Аk�R����}��$u *�!aH����d'����q������@r'���^R�,�f
��#H�w�z�5v\�����%��;�5�vY����%N�h���:�S���x�g�e���Jf�$�Б���XG�~Ւ��)}�����k�5h��
�jq!�aGO�6T�ȹ��N�����7�����Uu���]�+F�k!v�1���H����{2�Z*Lt����0��,27�����2������|���Dm���n�n#���^���2��:d�����٩�OQ�To���b����]ͨ��#oW�m�U򃠟d��d���1~糲:!��4;�\K|ʆ}1��M�����M�>��R3H3ޣ�x��������䷷�Hƒ����heDgu���|���]��'J��;��z��&I�Ps��.]��O{a��kr�(�����L�Ӭ������I���w���� �[�I2�BV�����J;�.a�;k}D�_�|��de2�{Y�{L�W��%W�:o8�2���e���q�Km�i�U{���ql߰d�%,�ev=���p��=b��? �@�A���ǓfS�h��	�V4�ۗ���5BO�D���@����psh��!�Qo�	B:li���A��Ԯ�8Z ��"k湗�[�G%�����)�ս:��1ݡ������QQA�F*��r$�����;¬:����'���3�6�6J�B�˯�,,\T(�i=�u0Y�<���n4��2��𪂨�I`�ai~�I�iωk���]8�.�%1������S�����F�k���.�����)"��K,J �ڛ�ө���.���ۼ՘��Dc�ig5�y���k��P��^��,�
�ǰ8r8����̳�K���|��ؙ�ۃ��L�f4�d�
�T��D� �f���*V沯��|r���t<�z��d�.�)�����H2�25�0���i^L�8dN��0����JaOfO�Q�D+ں���U�MO}It�����P�d�XY��G�h"������w�2M*4T��Tix�����6+����a� ~��%Zn��HرI�>��U�m�IeX�"�-��C?��?��(:_�]�D_�C|���{���]H�x�p.��ӰD���tҐp���.��َ�)x���w��#U좙&�W�-��Ӌ��>�aR�_f�#���6�3⢀&el Ĵ���J�.���Txb� ��d����Ú��l�q�M�g���ir2�dOӈ�gD��+�q�&�h��x�"���#c�� /����4l�9[!����PW���N����	7Ƨ�D�BV�F�Ղ�SR���u?!�[=4/ ��NV�[׏��b� ��:��
���^�s����:�m��D�i�WГ����u*:|bUG����pV���!�(��2V=*�-�g*�A6��\\[E#$f�w�*�u�5���E��%q�D{�?�x�oxy��{��XJ��ZZl*�(�����*���r/��W��"ПD�5�	���r��B�r���U)VS�ג���Z8�5SU)m��=�vѵ��x�X�K��F�%ڂm�.L؟���"w�dJ㍒<����r��Lu�����A\4%>�! �Eb�("5��Ph![o���4�ZL=�f��a�mP���K=���U����$2�A#�W��t�C:C�V�st�E�>ap\����%US�a��i�]u�܈wؑ`a�G�NJj��0&EZ61��r�'߹������7��
u6bDx��QD7�Y=R�H!��r���L�PA��ש�ӭ�:�ԑ|�c�
��+�kB51��6Ԣ�a#�"�E���h%�O�D�U�s=��Ԇ�@�|^xx�b�RR����s)Y�-O�2Q]6<�0�or3�%��N�K]�����)��tRd)e����+�a���r(�-$@|���Ny?H��@
��I�`W���Zq.]"��ڢ?ց����V�'�(h��F�5SI-:������Y���
����N��Ξ '�8)�_�g��҂���%�)���E�/9���~O�*
V����/ �9��㮈Go %aR¡�zW���Nr��n���L^��^�x����ѧ�az`R�R6�f��@_~»o��%����@��Y�S�������J��KY2�G�%Lª�����SD�-����Ҟiœ-���U��q�P�
1����L\"aBI6�yvH����lTGj�&U�_p�?�B���C�5��g�*uh��h2E�  җs���N ����{Zs��g�    YZ