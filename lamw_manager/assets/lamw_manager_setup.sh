#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3130454690"
MD5="eb827254ab69706a04be1c4c1749003d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23576"
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
	echo Date of packaging: Fri Aug 20 12:40:57 -03 2021
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
�7zXZ  �ִF !   �X����[�] �}��1Dd]����P�t�D�o�~����k�ب!|W�N���֝����bA�����B�sb�w��P�iQ�rZ������|R������d���M���z���o��](��dj����_-�>���7��'�^Pqص�6�8���N	��$�DH�����ߏ(L)��/�@
�,�7�v�wE����T�%OK�|EP�(Q�N�����ڠcHd�i����2��_��]K3�H����ـE��6�R���tɆ	O5*��M$��}ϗ���[qDN,WO��Wj9����kF.z���tN������SM_/+��zu�P�M7Y
�)�U��.��=�@
�A���hC�!���
�̊�I���kF�Q�ja4F�o'��V��x��
]B�鴰etR�i�yǸ���ۄǁΤ�!j���;��L�;���'�w	L6��̘����.�R,,@QO&�"�t�Q�Y����7�{r���t���K�� ��a�H g��H�n/QZ�A左o�*8���=P��n�+�����w�?7r�Bv�ʩ��ZN��r*�u�}�C���]�B�x4��Ϫr[v�~�$p�h�l��v�^z���JI�|��r6���_�H�A�I��&�5Y��O��J��p�~�0�c*��AIj���/im��������)F�M��z}�'����
�XC�_���m�I\��y�o�Β>�2)��n��ثu��q ����/5��Ҝ�&'KJ�d�/<�m����B��4�\h�@��L�Lq����}\��'�W�l�
��ݤ1��)LϨhю8 QA�O!d��Dwgtr��RJ���^��b��
G1���mޭ��קJ�hk��"v���<�ۖ��|\���Z����l�tv����V�ZO��s�q��H�����/�7��/��dJ�}$E�~4,*��2�d�ѼGBh
ؔ�����1 A�ӡ�{a	D<ڛ�Ի��E��v��ձ��@/�QM�ٜ�����!�;�-mPN�0Ջ�V\�W�$"o
5�	#<�8)����6)�q�$F��j��$��#�_3����%3b������=���l�dEP}�HQ����x"�dmA��|�#�������W娿�0�!K���&��?�2QEq��pV)ƞ���ܒ�����]�����Ǧ/ܡ+q�F�\�����c����v��t4jWv�$^��=�uo֋]4�������`:�)�jJݢ�
����gu���6�r���^3�l�_vG�BT�""��GUmi�z�
���]�N���X��&'©,�#���9������i�B��P �x���6�1`�o���Yr�Y�!x^W��rښ���=���[���MB�(�����O��+��-I;?,j����:� ؕ@�|���`���γ��e�����ϵ&��<@�Ӳ����%�*��8���'�����=R���~�E����\n�j��X/Xt�<��\�A9���gN�b9����:N{�h��[��W�:e�_����ɐ�/�눅�C1����K��'�]4���I>��k|�%�U�L��J�x����Yl`}��<PX5>�A�O1p��pw�<tH-��J|-��x9'(�*��L�!~	hW���y�JU���oYj!K~�4{�l�I<�U�7��H�V�������q��;F�+��)�$���l�{c��Z�G=o:?��l�#lG�6Ŷ��
լ����;�8;��6w+o�o��a	F$���o�n��}E=g����1��FŋSt�$�%�����&~�[2�P�s:4ׅ���nI2T��'Xl��g{�E��_��)��1��7.���e�K�ԣl��u�����7d�0v.9�p�� ��~��r�i&���	�!4��J�1>���u�$LZ/�&)[T�} �t�9��*]o��H��g���&@��k�i����5L�/�>��Cs��$��+N�Α����v��k)5������#�!�)⋡�,�����Y�8ǈ�'u`�C�RD�;tm�m)vd�0���A���`|`I���Т?�_����o��.�A��cp�÷�w��wLrV�PO�tZk*[�偏�� ��Fzz(�%��ņㄧ��qd!f :rZ�摰�'�O:9- �vi	��dA�l��Ƭ��VU��.7|���!��V[<=oΪ��|�g�^�S� W���WzSr�'�c��*q�uJ�1�x�Ld��n�5�i�2�N�nˋ�eq����Nx��$}�Ør��N��nWV�����uu�5eb@�f�
9KM��J��A���N��_�5���o�0<���:���ߘ�j�޳��>��H�sQĮ)�)���������0ط���UE�$�^.�Y��8@�t.U]{p�m��rj��l"��6d�G�����k�ak�o�$c��R������$��2xL�Ƽ�wv�|�Y~�Q�?�˖�$R1���p9!�@�X�A"�%~���I��Rs�?���z--Wj���#�1�}��=����.B�6��=Bd���s�X�����O����rFiS�XC[�,W�4�(1=�$e��+(�n?�hd��-��_a[��?�g�|�y��?}ì} �:)E��TI�q3%��U	N �)*�d#��Z�.��.���Ʋ�SQ0T�p�U"=pw��{5h�S*����c�{/3�ԗZJ�	{g��� ��R�Ƃ��9H��'[���ߐ5	B  ����#��s/�X�p�^/���_:4��Liř�[�66n�N��r�k��S���H��C}������ڔ�FMM��=lE�"��n�HA���׊DW=�B���V@�H2b�Lb��w���w��;��	��
\�3Ə &1�i�F�.��j�3�lu�W���L��L�"��f9���s[; ��o���m�cE��̭K���1^��X̍��TA/�������ϰ�TF��_��:~!f�p=�J3l0Q9i<_K��)Sw��"`���}x >�=t��TA��p��5~N��e�?^o�ƎV��Ǯr�"���2V.�Z"}t��:z����`63�(�Ԋ����Pf�Za Ԏ#�e�b���h�|��������ObiS���z?Ɇ��S�<v�zd{�ڃ�W�����}1*�yh%��a�฽�NS&'� ���B�tA@��U%���Ŀ�R�Kt�PݖJ�S��#t2�+��D���̯,������(d���G�M+�^6���5d��bH8�f����tc���u��b�"�����aI����&���%
�u��+MZ���pF<RK��s�"�":?¼<O�51�ٻ%a��?%�!7#�yQ�<褨��|�=�z��  M��czEL<�Q�G�������b�qPF���d<� �cdȫ`˧H�C�W��9}�c�h�i��]�kE��6������yj������q������+@ڮ��X� �D�bf�O��:����5)Ar2�5Ys�� �x0�$|�%'�9�0e��"i�Ǟ.�c���p~7��ڞ��t#��C�.�P;c�t֬�ٮ��J����C;)y=#�ʟ7��1��T:��[�<ڻ�R�)�v��H�l�l���+�H�z�܋�=[����N���S�f}`����&��M�a5�9/�Ĩ@EK�?_���d���A���	/S,�C���S|�:?;��8KG�Ϯ��͍�������L��/��ʩ߿&���~�4�Ֆ�g઻�&~��+<X�V����.[G�"�t?��>KKY�(^a+ƾ_=C���t��aV2F��_���s��O���¦6������F�˛��)�6I�> :�8+J��?+�eRȬ����K�w}z�� �h��=�V��ݥ"�&�xL���G�����%Њ��Eū�İoq#��R$s݋�(�8�7������7j�鲳G�2g<��D���6�Q�t�XSN�sd�R֗p7a������� �7g�uC�#�o���2yj�]j�6*T�a�΢�<�E.H�iSC�ᤀ��Q՘�d�Ũ�8U�������jaB.�5�EA��\���5�(�-�܈����P�m�͏�~��y�U��	�5	dŸ��*��8!rD�-�K>�T��<�s��f}�`��t��yu�	����ե�DW�<����?��أ�t��o��f(���<�p�й� {��\�Q�
WM�Tƙ^��!�Q�3]7��膞d�:�U7�](4��S7?L��r�ӡJ^!)�+�u).��s�y����W<�"��K�(gz�)kv`����4�A�h��؇
�*d�"�>#�0�D �o�bg��m&)~�aǀ+�EY��d��{v�Sd�mQ��}}\��	���������tZ@��4��"j���T*�-�BV,zs����]�u�8-Jn �y=���g�ͣ?�)mE����~�hEH�.L4�
ҋ'�Q�"�L�mR #�����$��{$8��0.��7��Jf�C"�A	ڕ�2rel�AdX��;�/WU/m`��39.0���A}�����dX�j)��>��4�1�,��p���i\�M�Ϫ�+�b"#ht{���Q+}ś����}?ԍ�9��zEpa  �Z�<�-��i�������&��R��$�4����SϘb$v���l��'):�҄�.��֞1l@J�=��&ׂ�.U��VbB��$^'��%� ��5�1�ơC^�υ� �s7�5�p��_Մ��+c�J����-yȼ�ZWS>L@H;��&V���M�W��|`8��辡�jܓT��G�{X��U	l�2�A��M	��<>G�^�O̦�������Ce�
����TØ�g\����y픯&�@B�Hl\T���I�JQ�U�W,*���Sԅv�b��$�B�u
�c�>3��[�v'�=2��yy�W�@��K��{?eur��.X�PP��h�� �9�o��}��w��ڏ�z�t�
�K�����8\��n�n��a����і�m �lx�9,�M��[ �g�a�ڑ�2HV5�O��Z�q���9*h�oIe�Ft�����;�*��`�#��X����,�n�����O���S�M��8rȋ5�j}��rBBN5@ɥ�*$��~d<[FM��_p^{t��/�HTvI�j�&�L��}M�C�g�K=����_qJ�.'f���!�8�~ofR_������M���bOgFܙy�N�(���+Dǋ�A�]U6��@]��+Vr�����?�c����7�,U���/�\�aY���-#S�d56�f�,�i�_��i`Ĉ�\�˛`B �Hu���d����S�rb��=l�4�ػ�ZX��윱%[�.T��������^�b�H��ȕ�װF:�C�	דp�d`���j�ӯr����K�V	�w�w�j�UG�����x8�����q��$#U�<���u�?\ً�w�/h��a�A��p	�"r��U���M�?e��G���n�u;�Ѕ8*˻��b�x�Cw�������o��]F�$}f^��`n[�q��́�	����AXt��On��jtP՛��ј�OH,�X��8��"EB&k8�,���
(zw�T��l��vw၌\��V,��q��F�B����jǳ�)��%Eg\&+ݩ*�#�S�y�_�'`��yC�"�i�5e�1����Ԛ��E��P�~��}S��CfMyF$L�ʉ�j@�'1��p���In�����������í�,���m�.�����w�w�3hE2�ٮ>ü��' �t���g�3r�[Q��Bj;�W�� O�l�p�WB��
q (%{���mO�RDՋ%��"������� �;4
N�:`t����)g�U��mh3�\����M��NH�n/����0o�ܒ<�ɯ����dk��G�]�vz�
���ҌWI��d�0,��]̢���/��������ab�H�sHYf�}�r�
w"�����u_��k+Vİ'_�e�8���w�����]"��u�L��n��5��[U�Yf(�t4��kؗ�+�ћ�"]� ��(�<21���3*��ݨ����(~��0�{�l?~�ّD3��� ��׈L���#��(����H����_(r�-�\�����$\@���hp��C2[��������I�nQ�2�����vS�ߋq*�bG\t�n�@BA�����Zğ� �@�-���}�o�Q�
��SVH����M�,�X����+V�g�g�b��":�U��oT"��õpFB�����7����2q�	{����B�sN2�!;��9F��q��W�o5��1/.7��/���$k�V�Fs�1Dx�!���b(�sO���:IW�j���{�T��CEɽ~K���y��e\�;���	�aN�L�P�a�8+_w�����i�?t 7�רC=�|���El�H*s�|�hA�O��S�3n��q�IC/����n�'�m�ń�ޙoT�y)����Ox���Q4�jʀ�N�p�8ÓicK���(\k̠����O~с�n�7�EЩza�~�2�#���b:�37���;���+�
=� 蒜࠙�]�de�)�0�[�q��fÀ+[�-~����҆�������c�Z������4�";|l�]}>v�z���[�@֘X���$�kDq����Go0S�+��'�Kw\6�ݿ
�3,���|0ۃI������J���0%�r:�;Qtص@U@�<,��p���C?�P���9�+F��78Ҙ,�L
�h�5� ��˷��!7w%�8���ŻY�i�gn�>>xg6�d�I�4��:��y���]��D-��3��{jM݊L��$5G��ŝ.q��#��$f#��ɫ���txZP�'��>M�`A�q��ii�U�C����������Klo�2m��6�Fh$�?�����^��D����&~���d���3T�ti�,���@��\M���)�Z���P�s�$�~Z�3ſ۸�&/�Z&����r�k%_��t2-L[�
8��QG��q�!c���ܑ"��p W��uÆ�5��-�>�e��OY=ls��;�����Xa�]�8����>�����c?uΖCb�5��w�V���+Q&����{�6��:Q�kAduxH���XEA@�1fE���|�5h��7\�&�i�\t#�Pk�z��Ɠ����C�ys����Z_�=�#4[ԑ`5^�Es�HL��|Kה��VF��CA���o�H�a�F�SwcE�*��-� �^�����qoqT�ص*��w�6��;G������Rc�����Փ@ZEd�B�{�BU�a��A����B�-K=1�Қ��{�&���[�C[0";H�p��<�[���EGQ��Q�L7�\���,(��JlC�q"�tz��q���Y���O\{X��hrQy���T��˜7v!����(h�ˠ��*��J\�NX�g����ƿ�-��D��L��'�y��׳�,�a	�ׁq�(�E���_�B[�G�G�?��G��כ�χQ8v-SR�S��@��$t��rd�&��Ԣ��Ȟp��Z>]�҄ #���B'�ԉ%ZA.R����<�úG�-Kl7ɵ�.�k��Zz�+�����B�MA�7��oh����H!�dN��Q���3��ם�=i���F��Q�\$����B��K�g�����X�-���nNy�~��p�zD���'w�/�������\.s^Sp���f��c�f���<�����X{߰F*m�����o~1�sv�g�c+d�Q�ةC��v��N�O)�}���<K�ɱ2�V�:�v��N�����A���q��UkI��̛T-��QOo�"���F������_�y���	�D�h?S*�6>�Ko�5���o|�~����%\����׊�9�
Χv۽�e$!d��$+��w�:�X� �U�Cj�J̚~�0h/�άdE����b0��ΉcG�|)���Ee&:���v�Qk���t�E��}u������Y��q�L�˭�\���Q(rsu?PR?��"�[�`�R�;ҟô�4H�oe�+;�G&�LI�B9��?5q&!�PI�ah��fiz�$�}��b�@h�zTG#C��6�ֿ��Q�C]����}��R?����oF�Bg����γ�F��gsX�xz�F?<1�^�}m���;�'m�\r�I��؜a�i���F�.ZڷJ���ڑ�����NZ18���!��#�q�١��'*����2�1 e���n�ˮg�sA��/j��t�7c�n0��@U�b�>�|o��[�Xc$Vt��	$<a�)e�_{۳�yLMd�9�����"������y�
k+DX+���Iu6�K*����åuˋ��l��ұ�*$��B�$����� x�@I�c?d?��҇྿ͥ�1�=S8)@<9������"Q�d���;ռI�ʡGL\�	�����:��Ƣ���-��$�d%�an�'�X�ł�8�c�X65�� ���J�8��6��K��YŊ�Ͻ(�1tBu3��1Zw^/�gђ��t!�B�I2򔉤��1�B��}��-�1%�R�W�n����1�I�.� 5��$��0ȡ(�u�m�+����΅YUW�b楘����B�A��<��p�I���7��m�
A�c���$�\8xG���9Iuз^�'vn���i��|�(9{���[�7O�L�sb���jk�
��n�}%,��p�T���CK�,��@g�Eu�VsNL�@lQ�ݝ�Pز6��3V�/�\�� -�҃�0�_6�q��gUI}�W�mP&�=?=P2��]������[�K��ɳ���=
�A�3+�'���ۼH��~:YXf�"�'�q�}�� ��`UZ1��"qQU�˥~�#��pXX�xo:5j'�����.���O��R�[{W��>�m�>As�QX�y���0��@�WϦ�a]|,Im[�*����%+́[r}��[@����<�.��=�>:Y��Q��K>�*R�pKq�R��U�s-��q��j`���m;e$����Q��=�4���e�|��BN_1b%�B ��iuγtޖq��ǥ�ژ��:�y�Մp�F�~c�m�{��`�Z�ԟ%mzpF�[��(�7�C��Q=5F�7�v�m����wM��  x��8�Ǿ�nً�NMK�e8����i�)8@[N��x��<�M�W��36i]�?�$^�+B�4��cmb �m!���w&�3�����p�!�4��+���Ď���H�cꈥ�Q� �h��ϱ���Z�!x���%t쉒�O��?:tq�:��9����҅�PmY��i�?��M��u�\�'@{܆N(�^o���@��}����-���B@�~p�G0�#u&�Y��ޢ��8b)<0���j#�9I�{\K��m/pv�ލ,}l��_��U9)�>z=�j�����Q>MM��o­���D�,�qG��\�^-vk���:[��o=R#	�"<$~�vѱD�����ot�{i��v��}J���16���a����c$�v:�^����%��曾F��	g�h�Vή^��5E��.�dH9��kͩ�F�g ӕ�N������7���fj�G�O8^S�f#�XM���j��� M�(�t���F��C��]|^@����IW��V��UL���z���HC	�.m�W�Z ���nN
����9��?�fF��96�D���z�ujYu�Wd��3��A_&HQ\N(�k28�P���}hj!<��TV�.'�~,>߻�;�->7�CH�{�����Q,�1=�l��J��cx��0�+%\�+TܦI�}���	��!Db�:g���ۭ��	�Z�_�;*Eb����:���î4 V'�4��;!~T}H\�Y��<|�P"�t���~�F ����1cP�M�0h���n�֑u8L2?��3�.�����*�ʿ!܊�@��x��)�u�!5�D�0dc�	T�_�ےn>	�w���ND�6�+�҃�P����ܹ�]�AXC�2vl1�����V�����|nV�k�k�8t��PD�NM�E�?��g#G[�G��獝����Yސ(ߩ������ZM1�Lʮ=}�k�Gr붼q'��Ԝ�`��N���CC���	цN�+�H��V�ET
flO��Ws/��g#����ȟ,}h�}��)&XyK� &Nu��|�Ϸod\�(@��R�@�Ǣ��8�5V��`ʇ�#����!E�mU.َf���<��ر��HR�:'JE'I��,n���)ZoS�:��
��h�Rsȩ�5:7��(#�>��ګv�Y�=�`Z����)X��<&#��k�w:B+��$E�l��Ｆ���32�xI���_���7T��mۮwn��kr��H��o�44�-����L��[a����*�Q9��9����(��A~��V��r���sZ�?��&�B�aY9��=���$��t�(�,�t��G�R�&qϵɩ��&��"�܇���)j���h3���W#��	�5����}�O94�^���F��3�@�Q�P_о�!^l��Oa�o��ǉ:^�Ϲ3(��Ap͗�pRZ-P�LH��tƫn����_+ �����c��5��A�Y�2SΆh��x�a����)PQ�=�4�8�y�6|��(A��"g���aK�h:��q}�<<\�b�����rN�Y�����NO�� |��.�%=1R��1L�\���!"d[���N=����ܭ"ɛ�$ӆ�23��d���xD�MvO�#�G3�m�?n+#X/�Ĥ���� ���t���*V��ϱ��Zd�1�"�51�v�ـ1ۣ,�'�i��Cf����2������q%y�m��I��`%�M���W�bU>4���d�8� ��?���Y��$�c0NP��Z}�*c��7���N��=�rH�ghxvª7~�>�����yX�#OTǞ���5��_��-��8I�����&���X;%,]���=�����!H�n���n������-o��2|]�8�h1IKݦ�=���������<L�Po�{���D$��bi�G]�D1��
�A�՘Ʌ�Y����M{�ԉ�#�{+0Y�+�������߮���?Vm+2����D���$}3r��i�;��t�.�-xן�&}�|d��oįn��;�H�U�֯������0�^L6���`�3f4>v2�`��S���,j]i��˾��Y�@�x��z7*�"�F���އ۰q���[A��w��3(єj�;;?���S���5�����hH�ǫ����ʁ���\���r�{|O�zLbN���>���%f��  ��dJE���~�'�s��T��6�$�^P��o�>�t�#[I�U�2�^������M�Y�x�3���f��@sm�&Y[Ə��H��(�VD�ж\-�	o��Ļ��
����8�>�Ut�Ez�+���+�z��� A;m��0�,�f$���.�l#��>{��SSiϤ��7N,��ǅo��
\���+��+ L�S�����St��ӱ�C;�/@g���UX��2nv̩U���d8�ik��1�a\�}W��f�#��h*���xC-�-�E B^���U(+���� �s���àS���j3�x;aVv��H����`}��4Y��;u9!������#K&g$e�3W�䔤��hVmD��:���5hx&ڞȉ�l,���"ѬXK|ǰ�%Aye��<1"��Ј�:
�چ�| ��$G=�Ë��˚+9��i^����!&��BYTk����iVn��p��B�|�k���@�y؏����n��=\w���5խ(�@�y�SvҢPg��wo����͇�U8"���0۹��L��z�z�*���	Z�|��K��>Es`̙9�on8+��/�0P��l�rWS����q��K�Y
QԚ_Ƿ<�P�F'"��)�~ͭ��!��&C��!Ո��0,&�)�6I�	��\HW�j0����2YJ�A��/1y�.UH8��ե�&\"Q�^��k &l��T�����g���k:��^DǏ��.�y��+����$��N\����*fφ��5YL��	���:�lq�݋q����ٶGk�畘��K���I�3~�w<�i��<�`�S�~��}���,��7AYb�:'阦pχʀ1���9d�����,��
��)��^�Z?�;4cyߡ�6uY��̠ZC�zܙ��10�Ƿ�z�4"�\=2IN@$G_���}��uT'�p�)�׊�k�B�����Bw|_�#�p��W�= �;����Ƒ��k�.�^���;2h�8kH�����a:�/��<GP5��J�<����x�;|�ʑ���b�S�]��t-�ruH��˯mf
1���M�`ϟź_yu@:3Maե�n��u!e��v��$�a�g{"ޒ6T��D�3F��ᨃ�������cc�P�{\^�q
�cnB��k��`�~���X��@vK�HL���,���r�D���0�OWw��k��]P��AI���ezϙl{�����E�IwRȦ��{l�h�Hsi1��]Ev���g�e!���L1�3�j�� ��ևF0.�D�@敛�D�ײ��ʛ�����' B�[�F��؆Z[�i��ڏ���Nc!Ab�-��w�/ˎ�q�Qc4ϵNq�tJ`~�*d^$]Bf%��@}�x�k�V� b�����ݾ�Xmw)�mVa%sOΊi�b\��-�Hϓ����q�h�cF�=Ҳ[���U��AԷ�\۱
�(:��|T�l��G�{���O�$ʐ����
᭺��혪&��k�S��ZH�q��}�����3{fD��d�/��TI1S���cjUf#�ݚC�,\�E0�#@s�L�$�D��*�� *J��	@���p�BK�5S��De�4߬��'	_4�#GD&;�Kf�Np �꛴X��JѥA@��A�6�p$kd�#Ρ�x�`X�Z}�7ݬ��i���b6���̴+_kOOG����l�|B#�ۙ�(L��2���CD���+�!(���Uk���[ƶjUn��WA/��1�A���Μ&�K�qH����ʐ���{���qw!�:/�uȿ�0��;�{ġ��6�F�5�|CME���5���9'��Th��^�:h��%�Bw[��E�eH�k�#��lA���X�9�ª9o0���AڗTx����0lo��I���n���$�{7�&�����*��x(����������04F[=K�?Y"�^���Oʦ�@�۶�K��Wֵ��e��l|��)9���!�l����wO�W�<s�/��3��=p�`�
�?Ȱ��<��|�g&W ��l����ޠ2�N���\0R �ڈ.�c�VT`m�l����B@��LV��U��QL��ĕ1]|�pڑV�ndc����o�ѱ���m^�a)�X|��g�U�#��I�(���6���!;￸/�����޹4���R*I�щ��@z��V=$n�!�zD=�����C����߇�A��o��xz��tE�b ��>�j.c�w�	f�}��8W��/���c0��dҋI��7�yɝ� H�Xfr�
��N�ō�r�&g&b��!��	(��P����	%'9L���h����Gұ������3��!9[�WI��d|�)c�^���Ջ;|��~D8�Ӌ��ȴ��X�k�/�V�X�v��AVx_��|�/i ���q�J���!�wζ�4���G4�yc�l�a%��q1~�E�œF�5=��Q%�]'}����*�,l��G�~MzH������O�w��7������1�yB���u߈xҠ�pb�T���o�)��X�m�={V�Oִ|n�o�j�N ��
	���y�Є��B"����5͜>�罟X�CP�!�7���͙�)Q���,	��d�0�fw�o�*w�ω���W�����z�~V�ۮ��Ŗ\��GKlf6�r�V�ђf�g����֕� ����&<L 1�!n?��q2E/jV���"�p�	?@�h�#�!�q���$�Y�	�Vgr��<���ѡ�����Kx�4������L9p����G+��IsHGL��_��6�A���٥�D���Z����Z�5&G��4���j� ����J�]��xZ�K;�!%�Oȧ�c�[���/5��c�b���(K����j��"���p~��]�ڥ�-ʉy4)
�>į���X1k���[ծkgh^���*�.�u��g���v��;��'��������U��|aM唼�lSoA�a�iD��Lwld�ؓl��V�t�lp�A"M���rhc�8��1�%NC���� H;毪����R��NUw��*��߻���ڼ�����F.�c��Xp�X��g��C9-�����PQ]���k�{%:	3�0�Ɣަ�5<�-bENaFa�;�5��&�����n4Me5��t��I6�n�w��(��m�In����_e�q��*���������κ.�fU��Ɉ}�a	NX���ҍP$��,5�Z�t�r������an?�oV�;��|�1��y��J������S��m9�y�A��K�+M�� 2~X��V�k���uĬ�V[�e�k?^{�����-�.��>�lK�$�infO|��x��/D�
�7�E8�g�>�?�\l��M7����Y_	�	�����ܱ�9~-VpP,Y�ۼ���k���Vh��������aV^�|��	�Ԟ�ɰ�@O�<@����d�S�7�3
�x>����W~3�6�kh���ݩ�;]���b�q��xJ�W����'
k�1�U�Lhx�x��6�0m����ˤ*<l�"�pRG�RG��|��Ȧ�,Ԙ4A��܊Й^�"Mr�$ag����}���������;^#�y.��$/|~���u���BX��c��� �	c��4�|�>��T/i�����K7#0.��EF=���xD6�[���i�Y��LhBҫ��{o���SK�M,X��H@�jv�#�J��bt��Hf�I&���㠩PQl���Ew䥄��2�0�|_�4��!T��q�6-̽F�ttg�����U	�-�����A%��A"v��iu#7ے�������F���\>P�/}(��:�ˬ7�PT���	G��^G՗j��O�@ص$W{q(B��l�Et���!�[X��q��2�,��j"vJA��ߛ$�z�h�W{�DY��Zk;n�� �r�z�ϊ����͟��]�R��R�2���2��n9D�8����x�/�"p�J6C�*�w�6�E�����;]q|�:�;���ɩ��qwT��OG��#�u�P������}������L���KR��-YΩ�����a�S�4�	��2mP��@"Ih�Y��!}���C�o��E��dy����)����( �.Ф�=��SIa33Ypm1�Զ*G���x��OZ����#q�T�ImsXb4�l�8wV���j�`M��P�!�A
t�7Kv%ɍqX��e5J������(]��R`�S�z�K��&�9����f$�+��X�$�k)����J�c��-�k�����㦙�XG2K)�ZW�cg�g9��@ �B�
��N�}�c������!��-��@!S�IS1�vk�U�Z͇s�D��~W�l���nh�oY�F���Rm�� ��:@��Y����>5F��_�k��K���y�~x������½� EA����L`���J��h���Z4�:g*���!4� N@,Q��/�9U�niXM����!4 2:�y��v��D�(�Vk"hm^�9���A_ᥐ=�:&* "���
�\�~�����Pc�N�H�s��p��Í#|Y&��]t�4�d��jCsN+L�|�Ged ��`��wtJF�l�l� �`W���U�a'*�L%_�5��?2/lE���$�>Y�!����[޸Z<)�)əHX��T�!%YO�nI��`d��*\���9 � �%�����38Dֻ��bm���K<���'PG}�}é�i*s(��Uy�^����8�]4�'�:<�0"H �M����Xo�*v^.#��2��m�2��wb�X!��(�jh,ʋ��d��F
�A���H&V�Of4��+�'Su$@G�|
U�nt3���¦��L���c��n~K�|f>�� �rPP�Vh^��J,H�����0��"�F]W��C������1e�|��y{�I.��#=�ҭ�Wi_���;cT�v�E����S�0�7�\�d��Cԅ� ^X��z>�}�h)
�X~�F���=�Ji'hSR��O�?�.�?��|���%8Y�)��^R�W+�G� �N�?��`[��JrR�B��$���yeF�͟1,�B��y׮��&R��MOΠژx�߳����Ɂ�W:8���Z ?e�s�d�V�(^
���`�=�^H�c�lA�Ֆ&���3�����Gs*��a�܏���zK3��^R��F���}���6��m_I[@"
�M�+E���*��$׷�AT��^f��5A�i���+D���O�g$�=@�����t�%��[|�?FU�0�'�=��rj#�n�v1MQ�}�*�L�������	m�g��/�Om V�4��)*��9�|<n)Xn���n�
@s��̶�bG� ň�#�﮺�]����r]pr�Ԩ��G`!iZ-��k�y���3��G�u� ��Ru=፿<��wv�3�q�r��g�N�%{�2}�j�=m�����A��'�arr������2qDywЕ
�6M�E�&��!��j�]Gݵ"���X�OS��.�L/`s�R|����������C:����흌��N>Eن��zDڈ.�˂ָ��ބ��i�c@E�ٍ����u�:G��R�!��mF�*������_ht��.���M��%mBg�J)el��G	|b?ͅ��I�6	�	c�W��W�z2�{:���ݔa���-	��N��*p�=�����9[W�aq���� �U��pB݊'+B�Ε #,���4Ib]�� �o��!Cn�v	 �v���l�~�pR_V1�6&S��ȡ�%%5�lR!�"���O�׺��W�4���s���{(4g��Q�Ӆ�C�S"��U$��Q/o��M�x���L�L�����	�|�N8��a
~d|��\I���A<�����]�,�K��`]�;nZB��T��3ʋOa����G�V�%O�����ݰ3n����ӻa�[���Fv]�9�Ѿ����8�4 L\�$���[�7!.T���4��M�+�uXÆM\��t>V�aw�n��/��"����qZ#����v=(��'M�X��
��D6�����g�PB%��+\�8g���>����hRk���2@�%�N �3g��d�ǿ!p��A.�T�	�gp���FnkAp�
9�+�S�gP���R3�!ϙ?�v9d�n��H9 k��T����s��C���^W&'��
��V��*eK������c�����x��jRo����h���6\(-`ʛd�g�\h�r�9Y�s���)�,��f�6�S��a`�V͊��1@�<�	�q�G��B^��❼�=jGWy |�H�BQQ�n]����ʬ��θ[l�©1%r��S}��v/U�;^qt)Y�0"��6����������Õ��Pǐ��uT�E��.:s�s(2(�Y| �����G�?�ƩØ7�T���H	�	�H�I�#@���=״�����c��IT�q�7εT��*?�n%b�e�ݣA�8drMϳ��mg��jo��D���&�g^�`q�ﭑiL��焢�Mx�:�-�I`�$_ɳ_���X�~y
�e�C_��c'���`g÷�r�&\>98tsa����}���B���6��>?���*�!P���Ԁ ��eΐW���N�k�q�˜�/;ô��˚�� ½�K��'6W-l \"cx�?��ĲF�㼵q�E�(>~���n0�Y����d�I�"���N3c���_^��%�o��{��4�?F �F�v�)�=E�mذ�6�Z)X8�\ꏶ^�?1[غ�����ۨ�mE���8�g]9��8=d���;��H	3�G�4��R�FQ��VRr����%�^+u�a���a�Z�:0�k"4�SᗩǿS�=��ڭ��G?X=�!qۼ	qƜ�b�6��s��6���SY��!^}�8c�h�噠׫T�W*1�����?�~�\�p��r+"؋:2�[��E�n7X��-=��e�g`�&+]��H�1L��2� k[n�`3��@��z��4.Q|̌l7-�N�H�) �W�}����h_��I�̥m�W������KQ!�����4K��El�,ýr�c=�EO�	^���M�@s�T���L�X�k�ի��te�-�?� g^�#�L�X[OP�\ɣviE;�ܿ��X���bTU�7&U��O�HMeQ�t�u����<���e:�"N�����ݍ98�JǢ����#Q�3jw@� ��hɱ)U0����0��%���bJ͏P�x�u|���=�`JvP�O~���v�w��D<y��DP��g��>n��Aw�Z�~S:�ʸ޽�*z���t47�"3=���1���,lWE�wrn�D�: �@�׊s<;��0�y}���-��u��=WN,�ڔ��ի���L��V5M�h��Ђ)"�T�K��5�/_sS��4�t�Rt,J$r�i�6MI����Nפ�P`�۸ᜫ��T)�&��Y4P�Y�,�r2�"����V����]�|#��Q������s,�ZM�Z�P���f���ry9X-�X{���j��	��)�b��h链!���j��P-5�d>��.>�w*?��G�R��e��&n�]Q�3G� 8ݪZ���o%P
0r6�`��΄LaR6��̒�K��J3C�3t���+'��S�e'"�X�#䕭�V]�Ծ��xGc��Fho�p�"��;�� `]AkL-)����Kȅ�4M���{Q�i��W�>"^X�P[5td�|/�ܯ��6��J�o�+ �9��)c�W/�-�wPA&lՉq�����ꁰ�5�?�t!��.�64����{�,���Ŀ�ϥK�A\a����&Pq'R{O����.�רN������p){�ṷbU�U���x�Gd
�O������`=���,%G@�I����M�x�3�]l��n�O%���CW�����Z
�����l��m�X,����.�ĉ^X���TP;�töx�&7��H �p��6�%f|$�T�n�u��Y���z=s$)�xb�9Z���!����:�vT�vQ�k���^ͼ�V��ǡ}��/����p˟禠��v�Ӄ�%�j��\9b��#4�D�����m�s�?���}J����ձ���i&ͯ�W��������K�H�zҬ�oڍ�S����z���r>�P�>YJ՜��ڠ �[um����h�2յn�M�x`�D"�T��HD�ꪏ�t����G�� �-�+���Q��ui�3�S���Qqk%�����'�/&�Bn��!ڰj���|#bc탦T]�i�1����B�b�y��$Z��x���Ӗa�ԝ��f`����{!U�%�SI�=��)�<��s�.�dJf$���z���j�d��ZM�b�*V�FҔo	�8�cz��W��q�%�yKi������_8���H�����a�K��yL���:�zY��t�O��M��j�a&�A�*�2��4�W�H@ ��LL��I#�ƻ��m�h佔�ĪC��e���{q�aL�B���hUt`Z��-�ؠk���.�"������,��#�(#p��D�w�G�pw4�����1&�����	}��~��?��xx�3XD�C�8H�=������{�G��A莦Ġ/�N2�������o���7a췠��LC�"xMc���BH�Tp_�,�>�C�^n�Y��3��Q6���5��
�_��$�e���?��<�_1i���V6	g�}��5�NI���@م"��2mkD�0(oh\(���ԸNI��O���s9�[���� NAmѧ��H�q�ֽ��T��_>W����j��F�:#|�{�H���\��7l<����Y�E̊��6N�M�.��bG��B�U蟹��]O#G7>����yw�$l��np�Y����zO�m�V�>�2�J\�]��T�Xd[�Ű�2�5-�\
��"{��?�ѫJq�\�}��1:��k��8�KU C�%`�~M4Ҭ���rfall���Y_|z,N0�	%j8M���9F`�>�,�;�� W-;�+߬��s_���u�*���C}.V&�k�t��!���Ԡ=WV��ֺ"�)x���5@����.(hAEm�ag�<��j�H�L�#~v��qS{����À��e���ʚF_"�i�v6=���}t��ܔ����CZ;`
����GF 6�]�ؒ�M�O�q��G���?�̟A�d�/`��xj�99�w��,�PѼK7��t'Ԣ����,o
��\� �� �Z�)���6�Ԏ�.'�wC���U�,��eg\������+�e᫚��YG��~��<�,8 M*C�)���I��{uw�'D����P}L>��A!�.�Ut֕���F��6��ɃA���*��V�q��Y�z���M#�M��0��xl,�U�t]Ʌ�[�Re��[U���8�c7�3���|
��տ���,]�o	�V�̘�F��?K��qӈ�{p�^&�Q_g}��_�j�B��0�Ġ�|޸�̫�?�I,��H�op�Y�L9���Z�tե%I���* (�d ���ǝY#q�t�	�4�I���mD:��PB��9q2$ބxs��"%r�K�-�"�f ���o2u���(C��|�;��|�j�ߔQ
ud~�2�d ���-�L|�q���a�5
�d��
�$��Nέ�a��]�^ت��*L0�ʉ�0��[\�'0�=��)������έ�S�h�ͨ�؎2����TP���4�T��3j�"f�ڦ̣�K���ȝ硵�,L'?Ms�F�H��N�����!q�[�Y[?b�JKk!z���&�mc�	�j-s:;�q�n�(��O`��F�8oko��y_����B(/�j])�Z��!^7�f�$+~4p��a,q�o��$�F���p����< ��Նi�]�~'Y��a��/�\��{�u�S=�;Yl�/,g9� �S!?�ъP*El�i> E-z=������~�4�iVX©'�Lo�W"�ֈ�l����iz�I�7��h��i�9␓�@����W�_� �Ƀ�{�s2[��"<kATͪ?�4�SC���l���Q�,%��>��:�A�5DޜC����+�)jq��[˸)F��A#��� {�:�ֵ�6���u�K�c��2ÐI����	��#�+�6�vL��� �j`�W[����q���#feXã�P�Q�T����0���0-p��^����(OKG�T󻱝�� �r2ZÝ���:I�٥�v�s� ��~��{!c��I��>�����n�����Kv�;�Rm7;A��4�deX��L}Y�'�}(7���Tsxa��\��,��z���iZ7��yCR���
���mhǖ�a
�@r����`�FGl�I����0-�ٖ� ���B�e�EDpo�5�Vh�a>�pV��1�P�C;��e���x��M�+$�	 |%賢�L�K����;�<���IeQA	�`�%�����I����E��[#�VbԊ�1X2p����Y5l���=��0�D��2TE �4=#�Yd�3�R��*hY��?6�3,��m_���`�[��6� ��� Ul��q�aY��P�5&�'��|Q7F��a�lG��hG�Tߒ �=r��wZ�Xg�A��%�8��Yyv�z������䄮2a<��|5'C��ς�J��Hy:p4��#�e{u>��7쨁�w8���c}ev1ݎ�-k )?�싟�D!I�Q�:��0��f^�II�sO��y11.d��j�Z 
~#�׃xArWGIg��yC�^��'�K�������PȘX��Q���7��h�IV8�'*�s�_�;����2�D*b�9$B�\��tŵ��.�A;f0���j_M�vR?�19���@Qz�.;v�u<�N�j�+�5�;���:� �Q�|�@&i	��0T�nm=�:"L�b�Y���pl��$��G��g݈S����R۬j�k�
¨�T�y��v��p��s�/����QdP���Kï��5ܒF�귔����P�]ג����ą\�$�l7j);�Ŵv�܂5%�ݍ#؄�I�sJ1E��&��ʱ��H���Y���\G\?/B��ȏ�F�7Ŷ��(o�tѕĸ����2�����Ǽp��Hg��S�D%��� �xQ�8^��s|�F�I?5~s@k��)M���<�g��p�Z��fs)�
����吣��� �����%�x�3Gwh�{Bՠ��ְ��+�!�����`nHM�8��R�|�D��.o:Z�im!�:ܻ!��^IB�~^�N��i1:�{d^sE4'�n.	���G�Nv����
'�A��<bW�"e*���x4c�d�5�{��u����m!@��dOC��+�R�x;mQ75����[t���L��n��������.�x�kσ�]�:=$�EmO�Q����ߐ^�r`��~�:�v7So��0BG����O`-A����@����~�3	�,`)A��B���1�h��y4�\ld�eA�'����|� ��=D�gوN��F�}ɷ�G�q��r�ƻ���5��l��7�B^��q��1R��F~�`�����.��}�7��
!u�Rp%aE�OM��J��r�*PS~��5A���S�t�u3�ʰ�����+%K�����M���q��� )mFρ���n�H}OZ� q	�J��Pςj��T�x�2x�2V̳Q)P
DXz"�F�	�d��� ��T��!���~�P����=��Q-�9mȄ��;Q�"Wt����v����Gq��Q�y�-�~_})�i>KyB�e���>lEU0SO(�8ȕ�JV~��i����Sr�E����x��>4aia��x�|�U�l����b�@�q�آⵥ���@b��[Y����!g-�j�N�m�W�Ib�IHP�j$�, <?���ƀӐ%�l*)�ck�eJ�9p��u[J#��<��O�p�B��ih-\H@Hs7(1T  Z�[S(�� ���fU����g�    YZ