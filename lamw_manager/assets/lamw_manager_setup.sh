#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3636277470"
MD5="2d88448cb918336f5d17d0e0e5e733ce"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22976"
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
	echo Date of packaging: Tue Jun 22 21:37:19 -03 2021
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
�7zXZ  �ִF !   �X����Y}] �}��1Dd]����P�t�D�r�8jYG�0�BZS�h�@Wy|���<%��;ŶT��Oӭ��~��T� ��ӾGřXvD��sG7��竳b���\��ǖi��.B���M�QA0��R�\>��Q{e���7�ش�[�������V��nR��u�rX��Y���E�rE�{��Ԧ;�)T[��Q`ۉ�^�
��G�X�a}���[F�g�������E�`]��]����l;���]��u8�cO�x�!��o��
�Q�U,|�B��|<u��$F�楎u��zR��Lb��H{N�Nd����TC�����>�`:�Tvژ�G�V�+bF���tM���\3�n#.}��9&Ѓh����nn�S�I���:�/f)�y"%�>?.�E��=�J�RCÄ��H��$��<�5����<��ۼ������|՜�
��?��(��R�n	��w��T�_J̃�U&!.��xF�*�#���%'�Ơ�wp0x�Ʌk9��9�#��QКZ�/�VjKE@���V�ω[o�O����;\��33�:}Ki�Vh�U&f�h��@Sx�Sg���X~,���{��-/���n��T˩�t�
{f�EЉs;�
A��/x�Ï�p�[�QJE.E{f��oF�}z�"�.jk�R���"�)�^�5���3���c
� RrB�q���kvD��i7�x��Y3�{Z���0��`���fpu	�e&٧�O��G�]�����uG&.�^,��quP���T4T��q����3�!x��bKB��ǘ͠�27"?��Fw͟x��p#���.Ƕmx^w���o|%��>�I�X/Q�.+GX,˾F=�
),a���y�R L�̕t�z�6�錊j"��K��q"'?|^0��h�����N���C	j.��4q�X�ǵ4a������c"gٷ��} I\F�a ڤ������pє	�t�f5Sh�Q=�����<�WQ�C��T0G4�y�q�;uf�_��3 ]�
_�ѮM�kI�zCN�Uh���ҩ�!��`�f�������t��Ṏ�C!��K��A�
�X��Qm�Mwc�:xp\4�m��h�Ӧ��R�R�.>b�>l�� 󐯈+�4D���= _5QI�`���bvd�]�75�F]���}�����[����m�ݡΡe��/X�Z*�X�ni�����"�q�0�N����V�U�P;*�H��9����X&F�Yxt��.�����f��z���Id�}��7x3b� ���uf)V�r��e	)މ}z>��H��u�������+�}a�>�^���I�&tΉq���	�i,<�ɬ{��XZ'	-<��0c��9����� �j�b��ZK7�`uJC�`6�n9�m��|��p^C�H��P_�Ƹ�e���O�X�i��7�y���.�a���B�%V��R�
�B��P>���4������C�xKR��3��>�UI�
"���b$;m8�O�!r���j���ֿg�N,b���?�t�����*�_��=�)����u֕�0S:.ȸ.0:��B���	��D���:3�8��ly��P�'���ޱJ�o8�<��:T���S�&:�JD�F��s5���ˌV�A���m�UbB?&퍷��^k4i@R )}G��h1��/y�j�[N������N���bԳ����>���mz�+C�M��tgǇ3�Hz��[��,�M�@�+Gg # 2 �;��j�;��B��8�^J|���b�{����G�o�m�@��H!�%i1�]��O��IՙLc�?��U��4�fM��lg���xiq*��ԟCgT|]�.��ɠ@��Җ�l��[���,�Z;�&C��ǝ!�/e�S���Di��V��50�P}Fz���7���4c�89����ߧѶm���*�49�6���mNؾ�	��)��8����h�(5�ΐT'6ُ�G�] .���S��=���iB��#�*�mo9h>TJ��2l�{<�+9sˊ�N!��?q`?�TC�^>��r�+�O��li�T{gH
5C��lY��֟=b5�[�.Jc��sfp]�\�D)a���h�,� ��Ы�^>f71	�	�gY�b�U:��y�U�GV���~+.�J�B�7���>W�Q�yV$��^����8#�3 'WɎ�d���*Ó��=<��|)P���ʸ:�\f���J�B%���p*�*+�6d���OJ����u�B��YPw���'6�5������#B�W%3����O�]��ъ���)]�)@�̪fr�¹ۋ��v]���jf��U����9fӇ���t�"[l�h-����7R��A�������r"�$Y��>Bs���tg���:�Bi#>�)���<���Z���G7��t�c�Y6x嘮�r)���/7;k���"�$�� gF���!O����]���e9� ����aݏs7=�6��i�|���
ܿ63���_#�Y�V<sAư��'ˆ'
��	+�˗U���z�\�'�^V�J+Z�l%H��.*�$F�2���QH��lOߛ����Qs3]��?��Z��� ��`�!|��%� �$`�� ��7.�I�3��Sc��i�V��J6�3�d��S�k�C�|�v5�j���\y��-H�j�bӎHk��W̼ղ�5��[�B`��ů���
D�zi�D��MY��>�Rz���?�������J����kz���+�8J�@�*$�z����z�@4�oE����$~�.�I�B}�b�"���l*�>/�wi��Bm�����)L'�V��`���2�o��ݐ�}�V��->��J?'w}y��3K�'T���iA�r7͋��W���[�&q�o�*�� �i�'��dmD�h�ɓ�t�9��6; ��w������^՞4�ջ������syG�@o�1��!i�:�6}8	������ku'���J�͍�p@��������#���b��������L/����e���|��uA*ـӪ�,���ШHr+G����R��7��hxd�
��|��'�	M��D#��D�}VoH~�Q �D�����aS�v�,�M���N�2���
�R@��B��d-�y�n�J�j~]r�ގm�緙!�C�?{�b9�%Qt��qB��s�+w�N����#JSK�|X�M$R�q:���!�[���?�q瞋�V�
B3�R�I�;�I�����xkR��Q�2�m~� @�w�&z�E\�q�X}�/N&����M��2�Oc'��Ґ�ǡ��h>�)(���e�.|�q괯!H0� ���_e��D�ǁZ)DD-�V���Z�.��+���i�[�d�iٿ�b�� a��Z�l�Bq�vŭJ;?kX՛���I��o8+�k��7|	/V&x��8�{����?��#~\�dBѧ�����wF�A+qy���&2_��#q���yp��`���O�ZЛb�S��^��oi҃�s!�$WWO8Z+
�������`�͡��5R)_��,�c 뚸�ԑ�SqXT�r��_GF�$w�zp���00GLCG�1�*��	(:�ҖVzWj-�Dg�$Gh{8[BvW�{��3w��}�eNj�<����̗�Qp��k�~`�Z�Q ��!AKW��ׂ\���XV3ȅ@��,�j�2"�v�@�z��/���gJj�x�K" Q�>�a*�4)U��g�^<�H���ם�{���L� �L'�[;�87}�A�O>�$�9��c�#�ۖ�\�� �94���<E�Ft�4%�~��厒莪wݧ-�w�q�i����ux���C���I�^��h�JhoiW���a�t�aip���3��~{^{)�զ�ԁ�y�=�?,�e��_"������	)<���~o�8_�xї��->.aXq� КjS�q1��5K�YG"��{E�c2��7B��ǴBK')H��aϤs%�D�g�_X%%ѿ��gw��Dס �>����䚲 �/R�ޔ"���v�T����{g�����ip�.���{$;w��l�"y��<�׍���)Ω�9��n��*��7�9@��F�mH/��>o��Pڢ��Mw���{9v7��gE��k](!.�qEox_U�@x��f����NJ;�+��xn��-�05X��Ax���\��T�2���4�e����R�=S��r;�����5e^��.��@����k���-8I}�/���t7m�z�2d�ߗ��U�ҁ�N��k�:e_��aJ��٠�&Ec�H̰�6������5�vN��B���o�u�5����{t����xfcJ�ֲˤ� 8��
���Q��D��f��H��b��ŧg<�d0��O�)�+�R���֏�F�O������JyT�L����]v��V��p��std�1�{�+c(g��by_I�����Y�Wg�,i-�mnj���w�Ӊ*�Қ�S[�#��5S�Ј�EщE����g��^�v���$TP
w9�j������+\��8}ԡh+����	�h�����p�[���`�����\2�� �5"n�}y��^B�r�)Pl�������%y"�s���Y��1ؚ�A�Ǭc���z T�W	Ո��y�m?LnB<�����;��I5Y��o~�Sר��ٚm��]j����%jpt1 ;ւ#7�k���i����;�׵��c���T_]:k��z|h�ή��0���L���P�����5LS]+=��}@J�~nS���������]�Z[�t�L�6�v�<:yR��Q���b�#A���4��7ϝ�M%���hM_�&k�j۪�ͬ�G�'�cj��._����]4��B9W�y�B~��@z^Ĝ��c����-m~&��bg���):�*�.�P�%][/�sop�o�tYg�E$���e�"���jQ0�<dX�}�;�������!p.��rIBK�h�n)�o9���o�VU�\�e�"�y�u�H�n�L��3[fe}	Fԝ�N�%��2�3!Hx�%�x�.�UG*���*UqjF��*ܸ9�U�x?i�|��{B���t�EL��2�6j����j���Pm�*��%��o?�Cqh�� nW|�yE��xd�0�g" $�Sq��v[��D�{ �
k�^�H8����iH>�B_��pT9�E����"O*%!�f 
�?}!s��+�c�@>~I<�Y�EÝi�̢�O9��f�O���
��V;YlSO�J/�T�BH���Eqʁ6z���[P0�ֵv���&wa���8�f+y��*de-���exǔǪv���2�"Ҹѫc�n*;�@�׸�,�6���"8w7۝��&G����`~m�2ؙ����1�B������Y��g6,f����ş��E��n>��a�P	荱!L���h�/.�;eR鶘�)�J�Ē�U�,oY�zT�
z3#L�7;� �,6M`��$�gR����d������GC���I�Q�h��m�,]K}��wƈ�<�NJ�U\~~� ��:'C}z~l_]�S�Y��9
'&~hĤ�m����3"�\s��?�������Emp}jd��5�jDS���ȴ%}k�k1�|T\��8 �Y�&"��t��CV�����?�	� ��⁲N.�����=c�?�^1D�
���Z�%ꤹ(���/��T܄яO�@0i���d�3Z�*ڈ��u��?$�4���Q�A��*���̍�<�l�+V4I����@�+~{D�W�$-��|���`�)�-i$���#�&۞7+w��㐓$tg*�"&�I\����4C���K��"�饤p�h/L�*!f	�aÖ~^ ���sY�E�1ٔUy'��0yzۻ���՟�]�e�|D�|J��=`ﴞb{�LfN����e~��[�m���Ιjn����mw�Җ�*�m^:Tq����<T���^~3�>CB6���@k���NK�R��B����qe�����ظ�b��h��Eex�>/v�/4��P�I۷m#�A��Ќ\X0I!�l�~��%=t��(2�Zz�7�'xO��l�����������Yw+�Hm���<D��i�bj�UѰ�'P�/n8�����b{��u+w��9h� ������x0O&�VqKLF�&I��C'�R��V΢�	��B���{^��rxp���?����u�E�	�xT�E}6� �i�;'���CQ�Ԋ�6:+G�ݯ$����e�/��H#��Yf���)��=���p��#_SBo|di��g>�·�|@<*B�ʼ���sؐd?/eo����
9��y��O&Ƽ�KA�(�� �I�pI�G4������,�aq�SP��:�f��3X�����2I`yq�#�������4X����4�r����7[fL�$��P%��hU	<�_U���+ӡs�k,hj�}��A�����VI��%-v׸�.���h�qQ�w���C�7��O�����6�(Ǩ�MÄ��c?��S��2�>n1|5�c����y��,�:�j�9����wӖǆ��f_��2����jC/,��` � �Up�oy����Fܺs�E�2;�W��o�F9�uh.4�h4�2-<���#g�"k�ۢ��|�s�C@"�`^�do"���h��H� �1��nG�N��u���S�R=]VT�q���bd��7������M�GK���u�U�~z�$<� 9Wn�D��ސ������E	�%����7��^�|��ɿQ��b��t�0/Q�xpU�zk��u����1��nq�i���	^|�-a˪����dK��Q��$VM�~2����;wJ����M��=&K���M�g;��q���� 0)]�n�b��q�ד)��{Ӌo�+��[�;�Tg�[d9�og���DoT�_ۑ�;��-P����U�c���0��7�VDc�`9���̭�	O�y�ٸk �U]z��qj&`�'/(�U�!��R5N���2�a 4���8ٖ�X�P3��e/��_��s�A2?:!"�~@��q��Q��#���f��T�d\v�a�}Wg��4�p�-w�b��ebLC�ғQ��xb�jH���S�Ф�� ����W^@Q�Ior�ꧭڒ��2-�(�8/������;�,�ء*������3Mq��􅀣��u��{�D����	���l3����LCS�Ѹ	X�h��`�k��(�C3]S�׉A�p�"f?h����&���|�n�Mj��,���8
q�,;�2�_�B8��N�3 �e5n����.��W�-0�B�gl�(���5�1�����F�ge��F�O�
-���v�2^+f"$������r��LT�"�����t(ȝ��"Q� ��s�᱄\E�Z�Hj�5V�Z_��SƖG ��:A����|BKJΛ�m���M롎����1&�Na�,D[�|�R@���Ӯ(z�_�L�2£Ags���,s-���۪���f��}
(	|�Ol^HlFEh"A�Ҍ��{A�l��	���I�Ft�R�a����}Bj�ؑ�:��	:�⫅|�xe_mm�
�o*��=� 
NZ���\�˒{��ʌ<ltTZďqb1
�/�A<�F� P��;��P�N�%.K#�#U�����O�٧�'��n��jI{6��m�kך��G&�;h�8tǯ�^��e�>@2�u,���?"�Q��:V���DkV��43�r/��"�X�_�ns�<�&'iz�7�s�>���(�<w)��	!0��3 ��4�ly����:)5$��x^�,]���'��Q��o ����?�P��6Ʀ��q��"��3�����/l��8'��o�#9s�6�����J.�,�pȔI/��t�膦�?��:�k�]׸�~QȨ�`e]��,���PM$
,`�Zq���I��p�{28_>�1�)I\Z�uC�gW,l����ӱ��3������f]�����t�l�e��;G��cw�h�-�˺恭�,]v��-藚�W&���=����=���`p����oA�Kb5)ހ5-$�g�P�<���ɵ��N�1�p@��~ g9�6�K6�5M4�ݔ�8T>QU��6 �$��X\���By�k�^���ʮКk�j�[RϔK��Ԅ��HL�����I"
��R���D��m������M��Z��P�ӾIϢ��fM�D���Qv���H'���U���N �OT�x᳇�͓~x�ዏh
�0�W\���/��P_����Z����6~�C�� C��j�b�g%��;kZ���)n�ʱ��<(��?]G+5+O�E��$�5���E����^�3�#�xo!1��TEO��3`u�+�����	�z	��f擺RE���b���"��G��Mw>=�_kw�~��10��3+�4�Ƶ��EpQn�Wc5H+S�\�˫�J��b@W�,��6���%����
�i{ڊ�/�V�AT�0X�,t>Ӷh��b�H��W��qP8�׵�Ǎ-�!�/I�Lq�DP;�TÁ��_��e�	���?f��̓�0��H&��L|cȥd���<�L|��"?
�u���")~������_����M޷��n,u(ѣ��Cr@Z������Q�5�ƌ1�U6��:R��Q@�ߑ3�Y�ݎr�7}��vn�HED��j�X����భ��J?�Ĉ"�	��9E?�V�F�S��n���F|G^G=s��C~��ֆßV�z��l�CZ&��H��"B,{�`1�7r�z�����rp�W��"��wsK����l�T�1(���J�(�T��Ө2��˳����=�5ب�b�6�YZph���+�u0�Ֆ?LB����@�3�	�W��W����`�zwD�E�~Lv�hPF��l�,"����iq^�N)qƌ�4Uߡ���3O?i��l��rW�O L��+���W���������x~>�u#���of����k�m���O�/� f���\�ޡ��w�K��p�\�r޴�|>��;5�����!�Q�����'x�J������{+Y�D��s���������o��;�8�@����T�W�5��q>005s�q�ܜ��VZ���`:8=�>�$�͜�HYI�z��v��iJ�"J� l+�Q����i�R�"o�e���~�9�S﵄�C�}��Um�A ��!�{P�fF
Kp�v�j�׊U�@���I�?G�"yZ>>J�ȍN/�+��u�e�l��B�e��f�w�F���Ȕ�Gq��dW��棘��w�}�ޚ����g�����6����|˕�C�/]��S��f͈��Ӹ�P����L�\�U���v,�Ɵ:�$;��5�|E�¸����n6�i�N�UF� �w��ws�"�l�o�`>��=�B�lhi�ڸq������؞���Q>�7|�]F]d/��n�E=�&����� �f64$ù�������å���h{��6	,c.30�("88c� 8��_6�hj���Nd�a��U�ϧ�D�Va��S��L"w���tr�UL�B��r�i�ga=�3*��N0:��s��ҫ$l~�W'ubqi���&�*�(1Φ�.��{��ؾ����)���Y�
��o>���};���<ǍF`��a��{G��yv0���χ�X�F��Wzp�����æ��y�5�G�;��a#iFW�z{� �a�o�gQdݞ�bYƱ��w�y�7T��G�f�ۛZ���gߖ�/A��:]R(�>��:�wARj	�r����r�TQ�.��=�߸���/{�c�1e��Zס�Oo������GX�^%B�J��9�G���;qN*yN���f��
�^k0���萠<.F�{�C�^vd�����Dzrr�+,��c�N}��j��Rr�Z��6^���	o�)t���ܪ�&;���}Ȃ�C���S�u|�´ٞ����U�_��EC�����[	ߜ��mq�P@ikχz&�b�Q�x��}��|Fi5��v�
��*a��!���\1N�s�+%��^��
�=����t2h��CZ��@a�X �l����E|ozxr����wߤ�������`*E���Ny�?W

��
t��m�W��x�cN	����ć�23=6��]��sܶ���<�'|��-�ޠ��,�%���Z�3�]Q��I�����rb~�W[�2�i�� }q;���ˬO��ޫe�	��h���f���[8`���*l��@�{�?B�zsm������%Ä�W#���[���(�
�dJ�K�1
��p��v���t�2���Y2�kr|\R�j$�l�hq��\�Q-��.�K��᧰|M9X �/Z��`_��G�0a�D�T<��:�9����i6t}������^�RR�������_H��8I ��o��3���?����[h��N��x��D��<��F���p?ǧ���I��-&p2�3����:�;��
�Upj�vڶ��#]J���p~{n)�oPՕ��5��4�
�%�}�(�$UY���7	.�17�A~��9�%�(Z��N�-��e��zEî;l74���u`�:��{%�8S挛X*�[�����6;�(	.1���� -T�y*��ǣ��ó��ʴA�<�c�d�h�Mt
R�2ѱ��Q�exy+솥��B<�F��[Ab������0�0�Lj���M{<��{��X-|�j���C�BZ�����U0�1J�(�������~��I��''ٽ�p�ǡ��YĚ,I�Q7���K醰~�ҿ�^�/b,*�V}eCϜ�������߫D�'k
1�m���ܒ) ��兀���VP*�)gW��:���O^���5���ƥ^Q���M%�еn[0��q�[��g�h��Af��W�HT�NoAkY "'�Q�ҼjC�>�1�S�3u����J2�q���JȖZ-�A���� w+L��
���-'q�V�1���*M�qE�'N؉�i��O��M�]�y���F�����ꗪ�Aet���*��лfZG���=���A��3S�}j���<[�݅/��(ú�Ͱd�I�&����I:���d+����c�����,4&u�r!�w��j2�n��$1�Ńz�2��8k�v��U�����]0�d�X#�\\�0z��V�!���h�±+��G�V\���,	)tb����'z��ĩ��7|���E����\�zLy�+u��������~ʼ�%H�g< �]�?(^lq�Á�G����R�859��vL.Ē��e���^
@���B�O@m�)tt��� �ĠT��E�ߘ�ߊ�f���ڌ����R��p�!6�R*2
�#���� +<\�Z/��ܪ���yΫ�8I*V�/d��/���#ٱ&!��(ΆGO���^���p�	��6����;�ɍ�GZ����"���Z)���r�w�@۵9Q�+�����C�i/�G���y#1��� �D���rU�2	$!N���rm�;�e��xe�#4��z�(( ��C
g-T]^'�ۢ�"k@X;/�f���0�<\WR>�L���Y�- ��2jcP������B��ϩ�W���|��4ET㒶��-�<UF��<�T������kZ聘	%�e�cE�\S3V�����Q��wiiZ<=����8�4����E{qR�HT��m�|mW��ѐ(|�L1����<��~�tH00S���Z#@����T�͇K��ƿR<��ѹ+��d@�8-�ƶ�,�E���[��ɀ�F!$5�|2� ���k�|�f�Y7���o��#4'����
X�D5]d��%$.����`�B���F+@V��Y]���y���<js�8�=(cKQ#?ǞUn���K�~���9�|�M�3�4����PԒLI;Y%����u����HH��  �p�Go���b�_��jr������;����D�#d=�QJ�ԍ�������>�{���K�?JI-UXSb���� 3U����`���&�Z��WV��[~5�K��tJR�9`����V�W�� �ha�t+<2X�Cz����4G-�dr�q�Љj�v8�/9�z�-�Sml��I�mi��rc��ڑ
������@ő1� �i��KPL.�5��V	L���\��d���?���� 2x6����
>�ɡ�%̔ut'҅��I���"�R����'4}��p6y�5�4���%�w
V�WTg$�y�NA;f�=a�g��F���Wsb��R5e��Gj�K��X���}���5�W�ܱ���ӫd��mml'�P-����R:��͐T�5��Rcʙf��G��}�F�}���Z�{p����|S��Q]^��q)SN3K�o�z(g�]�=w5��!	S����,��-��a`��Z����ۘ(�-��I�g=�tl�)%a����lx����U�$�i
\�^|ߓ�xI������Ǒg�gz��39P��H����-
��eg�Ѩ��ּb�a��g��P~�����/�#��px���i������ǧ�P#kK}Bdy��3����J���F{��{��=Ȕ�bhNAٳ�Y�.��AQX5�3U����l�׎��3��EV�>����g�v��m�W������|6{��t�7�J��R�[�4����k���o�测$O%��3�&=<��ێ�����#^�ɻNxiJڅO����Ռ���n;\�ٝ�G* Yv�)և�Gw�L�D/(5Ι�/-w���CHx����=YD&�V���cx�<�M�%�5�lO���{�� =puQ˒#�Ly8r륢헐��H�%���VC7f��MT�VJ�<	�5PH*O|�zyW�
h�!�%�����D��Sȿkm�j�Ĳ7�\@��ꜚ��K��N�.�Ρ`�>��fS~OR>�]��ݽN>q�Q���sCR�w����2e~���]�̍'zQ=���ӿ��࿭$_���jч����s�#aVFmG}H*k$niIm�7N���>��`^ݿ�{�� �z�	��hG>zfn��ʈ����)���>��s¸I[$�fw�M�R%�n?�عbE%��7��ۦ?C���/Rp�]�W�&�|�гn�R1��&�1�^�JY� �v�ƍ4�u���N���x�5E@K�]$�(�
�|���ݱq�Q�a�ۂeJ��M���uQި��i��r�(�ݤ΁�.��^�P��-v��[!\�����[4��Ax���k�e����)��C�Ơ���ٰ�oA=�E�R)>�gC�������T)�-P�<��u��]�V"��ʟ�,��K�T(Rބd����Y��+XNvk.�Kk�ռ�5t�9?ꆹ��\q��{ĳT (��Rm���� ���)��;&�ۧ�9ӳ���p�΋w�̆q�Ɋ��"�9�����<,cq�zM���>y���H-&Cv���q�.���z��H��"�q�?Dl6B6�EҏC/��|�6�b�Ƕ�z��ʮ���I���a��_Bh��W�TH�s^��,G�PVL-H�0-B�M�AY��y����̘���=Ң��ƥJ�nɓ�>�u5`//MqB)�s5P7LAR�)�C����:��{���D����l�ۋ�#CH]����q��. t��3���{}����?��~'��*����ɶa0yT*��7,h����,ϑ��[�	�/�J����������f6�@�k)�c7,
�K*�8�gf~�b�N���g�ΆԜ�l �,�-9�c�RwU��a(�B#&�$���Qͯ��1_�tn�^o@�j��K�o�x��,�_�V(_�yo��1��R*(s��`a��/?Wu)�B��� spk���=io��沍3`�����g�n�T��lY�_a��e���c�`��A�0�1���z�_@�t͘�ȩ��~llLF+�u]>˦,�)�w1z�ؐ��N#ɕ�"i�L��NJN����0FZ�'�bӹ�A,�}���<L\di�m8x0���������\�[�4-�:��E廕��P��/{C5�r
���j!=�4ۙ���&���ْ�b��IA��G�n�UY��F�?����9��wp779���iŦi���x��R���V��2�v$��2�\F"a.����У�	����ϗ�A_����5n�;ı&�CW	��z��	<���U�&���4�_{�m��L0�v��%��n����<V0�6XT0wQK�B=��f�TѤZ�ub(���@s�x��ΫE����lzdY+���y{�w����?��_��X�t8� Y(��-΢�����*LH����R�7'���� ���
L8�j:��`9\ǝΤ���Z�� a?Q�YD�L�Tf6��ň#�8�?���`�����e?���Պ�B���_tB=u�Z�l_��Ʉ�D�At<=��j��:�RU!���L��W�6Xnb�/${�}.ҐH���"]��
Qd�����>����źl���&f:>o�e�!0h�_����ʋ>���8��U��N�tm�3��q!��,JB�N�Ѵ�n�g�9� #s�n��|K/2��s߳2��p���>g��Ϛ����;[���~��X�c��<�fZc܁�`���*�0��G:�.��a�V���F
�W&�ia_�c�˵Sl?����v\���B��V*v�d",3�s��灐@T!�=��s�q�*�`C'֍.<I(ʪE$'l"?��4�0?���̣+��|D��0�%g/`�v����p3@ap��*�O��E�#�N�\�B[����Db�&�� �Is�K����Z�ڦ0A����3	�Ս�V2)�q�a�Ջ�N�8�[A�7�4Uh�rv)���yo_���|�Ez�m$������ʴ�*K��9�a�`<P��C)?�8/NF����L���ۓ �Q�[m�8��RA�[�#9�BY= [%\�
n�mZ����嚑�`��u=�"i.�Vw�cғ���W�sc`��m���B�@wT�0��4�qSSa\r3�OzC6;)�鮈RZ���k�%!���Tn7�>�[���l���{6�xԐ�x^�㣡������)�Cf�vya�[)�x_�i{6����vmNݨW[��raiR�ی�� ��o~�E��ݸ@��ݓ���"�Q��p�,.��Tݶ
o��E�P=�IOI�ȶ#�>��k&)%e |Nc|��X���̮���k��d�G�C�#��'��O�A�HG�h��+�s���O��ۇ�
�7�E�S�'j�/�[�������q�!	�����?
ܚ2+X������=iSW'�̸�~V!Y��P�&��X�:��^�~���u��G����O�x-�G��$�U@�/=7:;NԀ��S��+���#l7��$��쎗�ܪT��-� �#�{��9_V��*͖���'�"�J��ϼ�4�R �+J��*+J��h]���T�y��D�M��`NČ�T�aȱW�~"�sC>s�rXʀb� I����7��*�(�3���.Yc`�4��&������,||Fۮ�R���§�4����Z�+��ɣ�b��P����8�M�u/���zEا�3$Z
0��^=�s��� ^W���<�3���Pא���.���ʟ�
z���n�65��8p�.q�]�M��% l�)�Taf������(�砦Џa�D�V��S}���������~��)����z�gi�*Q�W����2�1������+I�P��kg(2��t8C�/������I6�m-� j�A�Q���i!�E$=_N��(�Gbs�\������X���i�dWL���i�,��͞��M�-u�x��!�	C��
L�1 N\����]��$���(��.���W��s{e�ǋeì��iha�9j��bv���#ʍ���KxG�CDӺR#����W�9>� x�5���]e�Z9�w^2�x} HO�
���w��g"l�O�S���V}-KgG�A���W����i%J����~F��D����{9Bz
{@@��R|!ߑfD1l�sP�8 �������z)BYrڢ���?ҿz����4��3Y�&E����:W���&���I5���-C���p%z���6�z_	 �}�ǀ�"�F�i���7�8E0R��!o0x�P�Ȇ����8�p�����C��SI�W�X��ˁj=��㲹:�3T"�8-���Z3�c:^~��{�? ^��X�A��Nz�N�<pc��!�CN7P�30��q�=���¾ͅ�p�_K��Pxi�/:y�9�az�U�I����'�!F=8�/����X��[�'���)���
6��'b��4^���Ǡ�j�CO&,��q&�:GH�2�E��%;RR�M..Q��安ܾ��m��k�����s*r�%9��sw{�ϭ��K9s`mO_���s+WI����zB��|��f)��� Ȯ�<h�NV�ͳ�mo���!���Uʦz� ���Ȉ����z�/V�љ��i>���(��d�`j��U��a�6'V�G���x�lv_d��ܸf�Y���_��ا�TKs4]K���[�\o	�D���q$��R=����1�7�����P:�y9��.�&��u��9��!���es����+�P��%w쓁9}�M#ARG���Ҡ{���{��6T8�f�O%�`Ż/i�q!�˅ �G��#����xF?�. ?4�A`���r;��(�n\����XYb� ��l�Y&HX�&OU�����j�E���Ȟ�� Y�2L����u��As?H����պ������B�g�B{Z����Y9sU���9�`1�ya���� n��v�[)�: �P3���x6f�3�E� ��d�p1&gU��!oi�c_�%�����E�L��6ҭ�H�x��}���/���d��ѝ�X,��'�G�d$G�'���d�P�����2፝?-��1���1���[hK�	�V)f�.Q��9�^AP�D's��dk�FR�xZ�F"ۧ����n� i�ѽD�V<K�[�>�V���d���T̾6�f��)�Аޥ�9�15s����M��Y�'��\�h�ͶI��R�ʤ|8����g��T�};6n�W�Ξt=m�y�^�ۜ+Xq�s:�<����
������>��%�|�,qy{ǀj��F��
a�!��� ��-��L?����Y_reRY���)v�k�^��#H��M�Zx���6$to2g����X	2�~�뚔뽌��*���l2��ba���(�$׊>D�2�.�L[ǥ��5f�_��܏Y^�L ���%�kzKg$�'�c�\�e�>��a�B����0&!��3 �b��/\QX�BD��[ҠB���RR��g'&@��Q�%�E9mr���#��O�� ����܉	���v%%�Bf�K��\S�ڗɶ�����Z����[��f@���	�OϏ���W��*� ��6��rl��V�\ǯz���hw���$y%J��,)��o���j:H��?��-nm�v��5��a�F Z���e΋�nn`v���$����3�h�zj�8d��F-VۓF��� pW^��p	������a5S�{%;�H�0�������)+�ݹ]4��n"b̒[g��e�r	���⥪[4�,ۘ�$RC���b���HVp��ca>Mi���77:l�sA��nS����m�n��t��25��|�9ĝ�pqU�suv�n�"<D\������ҒY���g3	c�k���|z�K��h��6��0��7+x�)��v��͂L��J�����iJM2^7Oo*{���p��մU�V���> ��G��$����������\���=��~Ь�bds��z��.�J*)���%iU�|�S2B��iU�_H�b*Ds�ڏT �{�;ថ�� ��	�"��fֲ��"��NHo����M�bM������I+�����L�9���΂'�'Kp�@"������-�>)-o��Cj`qv�<孊kU�S/�ȃAxI`�����%�4M��i.o�P.��ޗ�ڤ=�g���P�IK�}w�6�c��t�������D��s��b<H.$��r㶻W� ��0� ��Z�2�����as-x��Z����[��6�S��v��R]3��I� �S`�|7�_�0��k� �`��{���W�2EʇK%ܲ�N\>�p]���V��*j����	���546BU���` ̩��5f�����UI'���<��.���i���D��([�/Q6��8 �7.��Ұ0w $wS����7Cß�MJ��=�@]M��9��t(	���?�p��o~,W/�=�	P4�
q'�[�����z�-&�-�+���g��h���3Y��#cf��L|!�!ܽg�8>�m���g�1/l�
���4����-u��kV�O������q춉(	���P��*�攺�1]�)f"Q�gB���'E[�OrdUظ�r�w���fd���v��턬��{�}���� �����$��f /ѿ1����>���G6�z��j��d�/�����_t�A	p���/���6�,�	Y���2m!��2���.�#P�Bz�g:��"a%Vm�rc���9�;�K``!�4�K&|c"t1 6 �/Ό�-p��5^;ڹ~����|��}�o�<[Wt�����M�J:tYď^({�<���V|�A,�X\ڲՍ�xi-Lӝq#|h� �A��nҐ�G��|�T�٩Yڭ�<��^\��|�M�r�Un�l�}���B�͙�)��Э���L�$s���c�$^����`�z�zE�s_�hAN��&<=���?�=��\nnZV��1}�v�X5w��p�F��O�1�?������w+_ܿ�;V/ƨ��ȴ��=�F�ב��yp�՝dtϾ㇠ŽPo�	�����N�hW#RJ\�Y�v`���4N���U���CTeW�w�Gk�r�4���v���N��y`$�8�	ΛH��w븺���?��PF�_�n�hW��K�Ph8B���cT��+�tb�ސ�8�����0�����}�B���S�X��H�٢?V11k�o��ʭ�)o�#q��u�r0be*ne2�}����Jxk��x�H�:�*x��+����dr�w/���L(Aۗ��(� )��N?�!�/�'���P ���U�({�(2�ti��<��v�BD���ص�<S)��}��u�Lam�Ǟ�'���*&m�*р��lMD6��ל#�w�
ϛ�c���_�a>��v?q��#����Q�����,+�)y����u��������qd�Rέ�hN�K�_`#>*��f���V!ci�o�"�8�6�p�QB���9ݬ�ljF.�mU�z�K�����0�����8յ`.๋��	:O�׶�������	ù;��M�&̹^��H/��Q�?W&�]�gW6�fa�[�$�~�84�.�& &s���a||r	C?���n|���'Kh׬��\�?�Z����C`Uޫ�;��ˍZL�^�>^���uo�AE��\�U�׳0e��;۷T9��3Q����Y8G�9��t�8qm�$q;fo�Q�	m+�ڧe������ӴH���@ݖ�"(|�����KZ�K 7��7GNtp���\�n��k�1�Z�k�{�G�!23�+��
�B��+?�h�X�Py[Ad�Y�lZ@�6�Hc��p|�~���en��~˹hш1*���I�}��Pc4�q��S(#^{ߘ�����\Z�p	x�!�>��1uZxO/���őGX7��Sq����e�/�L5�]���_�Ζ��kVĖW�Á���Xf������u���������;���a��ɁQ�\����=@��onv��>;�f%��2�>�P_� ��U��i҅�x��Y�Su��Ӟ�.Q%�u�4��������Ah�����ՑQ�,x?�tн|d���zr�DnkT���Z�����5�G�3/�s�3��a���M����N��|��a��C�\}��s��<��@��O�<im�MΣQ-D�P��%��/�Cnh �6+^��y��9�="�.�9�xP\p��}�S�ED΁���[�r^D��Z����:���%��� ��.Up�_����:~��Wu���,7#c���.N��(�:^$�̫�ߡc�5$�w��كi��Q�w,��f�D�^�^�	f��t?��Z�?7ʌL��ـܙ�j�s}ig/����R�0J�W*%���o|���l�WC5^�|u��5�M��{Sw��d�2�n���Lֆ�:�a��r���a�!tH[Z�qk�'#$&9��U�������D�0�l�F0��%P�m$������;D���Z"+�a��X�%���������"�db||5�Ty��=��5`TC�a���Vg�G�4tn~eCI���~�X5lL��Td (Ctq��q��(t���%}�t
B�R77�B�l�s�ђ#X̃�%��	�:�<V�e!�u>�����e8�(N��Eן(b�x'S�j-S��(���Dc���PP���xyQ!� ��}�m�#%�$<e���c�*:'��^�Ĵ�:�a�+�Xo�]8�&4�|�=_Na����)a�Z�=�J�?3�h�4��D45=G1� �#JA��]�Q>�d��'ˍ^�7�����( ����LVH���Ө��zl�����u.rN�޿U�[Ȯ��0Ь�E�M��� j�M�㦤6��~�t^�$fT��D}� Ě�����*)-���!���3�ؔ�J�R�ߖ1-z�ݣ���b�aL����iBHz\�̝Z��h�e�˱���w�ʟV�	)�1�λ���=���9����>S���I�F�kpP1f�'x��,[8�1�{ck_
����	.0�Uw��%',i\�$0�˿�#���Uj�������l{}��)ƹ�_�n�mޅѸ|���`7t��3��4{�ҿ����#�����f������B�w
��>˦6.�wu-����1�Չ�up%qm���v�~Ӈ@>���Q���V�r��,�wy��V[3�
��Z���§D%�t	L����y�,���� *���_������#���q
�J�b	g{aŕ�T����Ű;�c�K�~���󄪆c!��5�Ŷ4�KXVnCGK���U@-�^D��{7bdw8��	�2����wr|��v����_��/?���=e=�L"Hf�����M&<��;�?j�s�үP�lW��gFZ�#�n�����{�p;�I�-����q����EA��G]Ꮯ-aa7)O��kg~�ЭyK��Y�EP$l�3��VSy=�&I<W$�[6�]f��Q����lz��0�-�ّN�����@������@�ގ�O�!�	�d%�;�i��8��лݫ���n��Τ5���LH*2/��Խ�7�uP��II����yoݻ1��VW�	w��t��Ap3U[w	}���=��jVJ-��N�S�VŊ9ӳ�hT�hcl��7�h&�u�c�p=�m�H9���9��/6<�-�'UQ �Y?'*�^�Yb��$ɢ@ƊN|�A^ȥ+K'\ܕ[�Rʉ=&�&�����gP�w<Ƀ�H��ֱfG�Yfo����mBn�e��2�����^�{�����㝄�.Pnb�?McbbHߵ?����p(�KA��F�6Č��� ���thA%�����f�]:���]�6�ogk�:�H�q�����C�)��[�ӌ9"��|��p���i�}�I�2KPU�C�]���<�qy�??�,;��x�_5��Z����6��[B����د�/�w�����gw�z/ǆ?���m�AD6�t�I��G:8�N���(���SI�~l{������䗣AEō�{��J��n��7�h~gyR�$|E�,$��*V!v�~�Ω?Z�u��9x��#�io"|�S$��k���)���J���2�$j�����[Đ���@��o!��³*���r��A:�]!�= �
@��|ǋ�~�ȏq��R���نȮ�'a��dC����-AFP%Q��=�������q�����9��#ky`w0��.�ϟ�q0��g^[�#�S/���K@\ �� �_��~��A��e�w�ehTn���@�lm8|�p@��ֶh��ΠC�Ψ�%C�[{�x�����>eT����L�̭�^�q}�G����\=kQ='�8��v�N;���o2t�����x��4d�a�I�����;�{�v͓�gHWS��
�&�0�+�fa �]Q��gr�����nr.-M��F5#5N#�������J�I/[[�Y�<����&h�B����LG:S�g'��_��v#��u�~����|6��ܡ�Jt(̥la�$)�d{g�����́�u�"w��c�To<U�۽]�`<X�7TG){J�}��I��%$�>�������	M����,]>{Ȓ;�R  ����Q�����	�\�B|JX���}֕��q�C�z��_ �8�}}�~�Y�|u}n�(�}�Akʯo     Qő�NDJe ������L���g�    YZ