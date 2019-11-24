#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1755091843"
MD5="38e0f59de8820cd0b61df6e2b0bf15a5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20449"
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
	echo Uncompressed size: 124 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 18:52:54 -03 2019
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
	echo OLDUSIZE=124
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
	MS_Printf "About to extract 124 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 124; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (124 KB)" >&2
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
� ���]�<�v�6��+>J�'qZ���8�]v�"ˎ��Jr�n��C��̘"�)��z�e�������3 ?@�������k��D`0�����/�Y���g����ٺ��|56�mo?{��7�7��<{�>̀�G��W������S�s~1���9���d��6���c{s�Y��/��~��mW��L�j_�SU������-ӢdJ-����f葃�c�#O�����)Ֆ���Ħ�7�#�R�������f}S�����X����Ə�B�$����g������f�7��xSB��(�>j���9P�� L��&�Lߧ�zQq�!�vA��:;S�
'z�{@�^��遱�<6�C�=U�\����?��ͣ#c�dAs���5m?�G����v+��}2l�G����3̚[0��Es��PQ�R5�� V���:	���w��*���%�[��zO�ע����s�R)'����+ j�:�s�������Lme5�k��%�+��� ȷf��瞫�3ʷFA1v�0t'�-�hҹ�o;�=Y�&J%��}=]�x�x��"�|5�.��&l���9�5���{Y���6G� ��6�v�@�L̐�4����|�W2�/�ſ���nх�F�S]��� ��n�b*�b�P*�:>��c��֥�0 �����o� 
?�m�2j�Ó3duCMhQk	�ZNQ9A�4����\��t=E�ߐ*�ρ�$�,xȈ;���7X=����2������4E����S�x�/[�)���4������7�.�t�~��u����ĢS3r�5@���N�&>�D)kOS��u������<�m8�C1#<��!��?��tB�� {�A���Q��7����n�3���7�|�WI-gي�����1�
�.��vH����P�J9�:q�;A'������Jc)E�"�BI�J&	�djR V�X67��t[ycL�ܴݔR�8Y�z�����>�J������@��$��D��y~��1��쌂���JE6�� N>,�oEM�X���:�/�� �U/�/�oom���66���-h|�����w�6)b4g�v�J�t}�|<@��MV~E�=Ǐ|��ܰa�b����SK1 �-����q^
���_M�� ��r�������U�h{������Z%×����	|C��=n;��JZݓ���i��G�W�(	Fz��W��@�E�(�0��QXp�=ó�B&	�O@�eOm�I �a|ܘ�ca=_X��}3`"���bAx�׃�U��8�'�&F[Ա�6���&�;׹yNu��f��4��`@�5���Nw�Y�lGדau�ӿNQA��rV�N{�A>C�ʑ嗾�2ў�	��L���L&�t(p�N�i�a?���y�ES�V?���״����oV�ol�?�����O��#۱hPgg_1�o4[K��������Y�o�����EA��@.H�xnhB�C82�F|����; 3�Ҁ�$��v�/�QA��xNt�l�[/��4�t������ؕ�EC:	M�Qp>��G,�L�I�ƙ�I\��Z�&�����¦�Xi��6� ��ZXw�(Ǜ��,M�F�IZ	��hݥ����S8`=/�>UOǑF��C]}
�i˟#�^�"0rB�ˮ��|ؑ�F��b(����#)3'JJN##c��^_��9��`���Ddl�֧�����3lҁ�zhΘP����h}��J� ���b�k_��@w�1�PU	����!D��'�Ye�}�nچz�į��A�{b�K�YzM�f\G[ ���[��؝��$˸�a{�栠h37ZZWZ�rq �!(�\yQ3��x
������a��\t)y��x�������FaP�a�O�	|N�=��cO<>w��ɍ��Ϳ���ݾ����.I��߫�+�S�k�%ݕ0���ߴ��\�ٓ3���TE���ŕr��������I9�"G�US�o��-���E�^��7=O����*仴BB�Oϕe8<A�#p�8ݰzrHRC>�QX�ϱ�Ɋ�Q_����l�W�^j�����&�:>�������G�[G���7����6vfBt
�cH��y��d�<��Ʊdƛ��Wu����7�du� �N�����BoJ���F,ץ� �"�⠧�uKMy�3�P[^{�xH�����Q ��
�ŋ�	�PLx������9�`.Ny�LwF�s�����"%��uW*X� ���}�N��d�#�-�V�t4l��C���U���>RIw���������@ �|�z��I����~�զJ������7�LEp�ʗ3�+�2�[R�dw$q��[m�QIËX1D���� ��o���D�����{����m�#��ӹ���� X���ݛ}p�vx���L�MV���I��<�Q��Z6\�U*Yb���i�T�U-�ij�].�+�*��2�/�g���Up9�ZݗhD���.4����V�>�ǐ�l�������_"�y�x��$�e��&P+�g�C��&%�x����`)�X��Ɍ/m>�K�O�>$����E�HN�\мغ��m�?l�cH6d��`�0�-^x^8��ʖ\�dx���EB*q{Kj����5F�]4�͓�~��7��p�A�)�x��fKT_�5<qv	5�K��CN΃��!)}9oKb
��呄X�]�,W*�b�3'��
����o����u�$�k�K~�%	I�ok����'�5P&~������5#&n�0�Z6��?�|{�wk{���l��p���q�w��_�t��X�%�p->o,��{փ������Cym�#ă���F]<&^'.+�u�z��p��X���ۡ�g�aMB�ƕ,�ߵ��x>?h�F�!�nw8���	~��x-q	��C9���f��9 ���t8����E�RO�̫L+�@oM����{w��{��YF	�)�}~\I�������C� 6ͽ�wj��&!~`��<���:��C��X��4����m����7��ӫ��^��3�w�چ�V��Ӟ��N4��;�1!���RQ����s��Y���SZ�MH����" 	x3�'�x��5�bi���58������I���ۢ��,~reD�x��7�Y�����X]�Լ<B@T�rR�$I�� V>�E�8]<�`�G�i��I�v�a�$�Un�Bjє�(�c����7V�b�y\��w��c[����Z���k��c�`��L����d�x�I�	{4G��r���q�^w�y����Dm�����
u�-�qY�Ry��G���?a��L�- �3>�������c�K�t�}��{MQ�:xAIlI4o��INt�E�T׍#ۥ���809�����{�h%Ⅷ\q7�LzR�{0�kdGdb������~������%��d��q5%�O%�D�JHZ����M��α��:?nB�|�-7%�D��@-f�zH��3'5P^�ſ;��~s�-���=~u\�y!�$���t�q'�w$R�	����� ^@��n�5����.%~���t���^�zū+���'o����4j�x��	Y�y47���8�vG&���ǟ���߷��F�I��e4��&�Յ6xQ���k��&��1���S<Ǟ�
��	����� 8��0�1�W\�R�F`i>�I�"3�=�
�i�M���/5�'c�ǰ2���Jf�¥A�q�HO�z�s_��C"}�B VVrG�1n��Duj$�S�.4"J<v��b�1�,K.��� �vb��������f�t�/y�8jc�RVR�N��Y3i�R�/�M���3^ˊ^N���w�0�s^_C�W�&�%qB"�D�xw�K(�S�<���]���uUb�ۧ�ov��[r��84�d0���`�FIw��D�/��+� ��Z������]��#�#o����@;kC��>�T��(w��AL�U(M9�@\�z��.�ye���D�So�T�Z��v��۴�\x�9��	�����?@8����z,G+�+f�����|?��w�xy��,��=�IY�Q+4��O�ي��cL���C�a�{4Ƞ��8�ɞtF*=�N�2HM�Ԙ��FH#��XLF��^�����*v�˦�&q���֠#��(�A2�w�A���źX�����Iw���u4�pS� ��p��A�#D�{�|��L��)�w�j����)W0g�`�n^�6<Έ�rr�R\5O���{��o�f�� �c�-��9u#�Q36�'�ڊ%�[\�n������F��	?���z��o0����(�����.D�����K9��X8�{R<��T�E}���]�=Z̛��e���;3�o�D3i��#�E�sjd[���ޞ�Qm_�I���P�n�<7�+MdTOL�}<�<C�E9����rR�:tYy8�V����xDl��ա���`n��cLM�0�t�S���[̆Hʌ��T܅�v�!��Bq0<�=8� ��pqW�}\S�>n9&cEv�vr�Bzꗚ�C�˟�c� Ú�'
�}���AV ��--E$D�������gQ��1��*��������@��Ə�vwv�Lzٲ������p����R�}R����l��{b��^�ND�:0�?����Z��j�=_�6�8Ƿ��l���ONG�a�8I�Ku
��3��w��lt��0�.ģ���p����t���MlST�:Mߋ:��_��ޜ򻥦r��+ҹ��Yd[�g����*إ�A_?�NMJ[�N�f����s�,Q�-��ᗉ�GB�"�9�	�7���ކ�/!g�;�tx����~�HT�Q�5y�>��%J��=����^��=��ݭ����%�Q4��?˟
���>�Z&G�2�R����ܫ�a�ILX	��a̅�D��x�]�����ةծ����/�������:�̹1)��A����Zn~�T5i͹�b����9`z@'tL��`�{��
��$�M7(yr�VE*Y�u��[~=�I�Jl,b���O8��S��F�����O�8�@����l�\[��S_�`�U� "���|WN\� �����L"x��OѤ�^��ˤC�u�1+3>�����=fƝE���?��&��.-ܿ`ޗrH�c��υ��0�<+��/��!��D�m,�=q~`u��A��ښ`�vx�a��#ǉ��C�4w�%��؈�0>���Y긅r�݋P��d��s�|�8�%���LZ� Y���߹S�U'
]rqz�����Pu��)�=P<C!�L���to �G�W�k�ΔZ<�x���3y��*�̺�:6�A�Z�TR-�~V��D-a�*�r;��%�\�jDbո�Q���˄I�M�r�RV"���*���
�n���J���̩a|��O�P>1L��7�΢qr����S��(���޷u��$�+�)�%M^KB_,��Fv3��H���SHT[Ri�J`���:���2s�a����mD�2��$AcO�,:�F��%2322���J�CV��ӯ2�)�T�%������	���\x���z1#�T��r��L8���-����.����ɐSBp��w�\У�7�౩*���i�R�h�R�KJ'8��*H.���*u#W\����]���	u�'$���X�Ut��$�i�T·�)��1S��^ј��.+QE����=�mR-���V��Y1�	��p2`.�Znp0Sm��ɖ3�֬��nT*�1��2'��us�@��D*�F	�-�8gIuc�v��>y_,��ˉ��T���u�@(���jp�sEٌ��<T�E���1�rJդA��(�Հ���������"���Hf\��W�✀\{�Z���l����|��L�"��A%:�'2�ƴ0�y���H��l��%��$�5��a��Ӣ?�/��G,�|8I��˸V���>���_Ӊ����F0��Wع�U��rz����8�����#_�F)Nn�I�g5��A�/��I��5M����'�W�d�'x	Q_��'8�a��W'	����G��.��G�}����;����?Nx�ñHA8,���UT:��=�hd�+���W���T
e5�fŷ�	�o2r��/�����z;��z�M���Nӑ�FT¿"~����:��$	'�,���c�RJ��L����D1R<ډ�px����"K:�W�i0� �����-���m���UbҬ�P�Q�>/��h�������ؗ%�I�38#����C���u�yu	�:/�rm�bĉ�����E��J'5��;�[�wNW��F�~B� 5~��/�zQ��M*Xxf�k��*�sV�W�O�Á�&�Q'�f��Net���� ����z L�,�}Bܼ@���L	��'��zq �p�+��f��:��ڵT�o�6����J�m��'��R�$�Qn���)BP�$+y1|-mJU��r�������`�~�d�ZVIS�gH�j
��s|y:/T�q˟,���1@�|�M/\4ꅓ$n��=��N�Y�E6���㱎�)����/4�����S��"I ��i�	��	#vxDtE�.k�?��m�9�Z!`�������36�Z%K�|�T�B��^���c�F�49��\���T�H-� x�ֳpz�!���/��t��m�m��X';����[�ˋ4LgF��R�y��Az�	��Ɇ?4���b�%�e̨̩K��������c �'(NL;<\�$�,���A��*f���fX�ɝ��>:���-N�89���-`œ�'�a�cٍ��<��EJP9=��'���R>�
���l��!w�Ƶ�Z9S�����4��Y��%�����FfGv�#��Q���492,����l{��17�Z�喝�k���.ϳ�]Nn#t˼�V��B�Q��(3��N�>S�+�o�)h�칚�ik{�w�ߏ �B,�������T�v�b�;�[�@�ֆf&z��/킪9o/O?���a��E���r �r�:��E� ~����-X��=�S���O���.�a1�m�cV��S|��G�X+b.9*�~�F(��V��!�9`8q/ˑ���l=�Xe���Ms*+�b�Vc��㛭J�Z?�������1y������o�@�[*�6{2�&�Du�Z�]&������N��״`ytm��X��D^�������K �+凫˙�b�
 (*f���@r�ܨ�E��%A�b���|����2�a��d��[%�<ǒ�����5#m�yAwU�^���P	H�N��ڒQI|ߙW�i{i��AEG�>})�"�֗?���l�*X��3V���\�7�1"��򸜮����Ǘ۾��O�q,m��zuͅ@?�&�t��^W��zA�|�"����=��p�*�~S���wym)^�?qk�ȯ�MM(�I���pEYB�H�7�F�*�h�J3?�Y�HQ�k�/��[v���hU��ӂC^0=/�\��n�I40��֑�|nbݬ�*�M<Bqn�Z^���]|�����g��	Jw� a�Y��ɀ<)���|�G���*�r�J��j
���5
�`\��p�*`����C����q�X�c],����#s�
1���n#����I��'�֗58��|)�k�k�F����Y0�%F%	;i�-�A��K~O0��S�'<�A�79����`�׿��#+[�������ꍍ��9�_��������]��okպ��fA3�|�9�F��v{�v��1�?
�\pi�<Xm��
�|C���R�=��A�,� Q���xsJov^�v�����wy���a�ɧ�R�}���n��O�w����hY��kuڻ<j��Ӹ��K8��mmc�
�o����,�4��U�X�zF��l�H����*`#�H�������1�q'wd��7��;��q������*py�1H1�n��������Rz�|$_�aa��������G�<`#��8��� B����m�T17t ���0��Zy\�R���'.�~��i?p�7�9�n:�rES~�B7��g�G�5�C�d���u�6��||��)Q9����H�4�y+����x���O'��pN�\�?�o/[��2����г]�����`vrU"��Ҝ�����
��[^05\�B�K��$G%?����c��ǌ%���M#I}�8�����̱��v��Jy���:�e����/����"�k.�9PJ� y��ʪ� ��&3�`��iO��<�+/>2T��Yrk|�U��O�V;����U�^��[81D�Xf�{�Y*q�M<�a��Ϋ�Ԫ�m��ǭ��&��?�´0��G�'��#��糙mU�ٺ���l'y �R��̓�AXM�&i�tww���۽V���+�*f���D�����Wh(Y>8r�J�Gi�r.�d�Sas��:�g�M&t������"��TR"���*A��X����s:��M9�λ���7HΜ�:}b(e���2�����Q�N	��W6�]�N�7��k�@�ɣ%�J���,M�R,��t��9��,׷�o��aE�����u�,��P�3S�h��U2����T����K���2R�|��D!���I�^��a�>��L�����u�g�^��$�^<{�������F�C�q��W�7��c�y�{��T'�hp�87�IT#�91���ՙS�k}z��,��������
@r�(2-0}*�ʔ�ej���꒩�K�OƷ�-��(��H$Ҍ8�Q!i���C���k��qF2��(a�՛�e�L��fF�15��ϝ9�݌��V�eEe"Gj�����w5Zo77���<V���t6-cK�++Xj�͌^����a�:a���iw�AZ荂U�P	瞫.��܇/Cy�'DL��M��Ð�hjc�㉸Y]������$����=�s �(��)?��q�[����*�Ћo0\�?ݙh9DHNF�䎓��u�^Sp?�mu�s��0��� &օ�Ϻ`�OW�T���Y���������*T����%-�,#�9A8��6��!��� ����(�f�^=p-�VN�_���יc-7$i��e(e㝌w��|���>�,qK\���^f�tK���Y=C!-�Δ���o�B/��6�3�8����	��\Ui	몛�#�aMtH�Y�&�3�X�ǩ�����RY�\�@��2{S,9A�}��M�B����ce�ǣs|Y��
R��H(?ıy��=�O|�Y��|nn�'6��d�������a�{�ߋ�Yod��?޸��}���n��nA�:zy%}}��EA���@s���|%�ޥI䣂*�N���'p6�d$:rc�e�\47���PM�iǴM��|�.�-9�V��8���˔�g��p��p��Z��'YV�ʪDg*$sK���hC��-�]}@��*�G�s�O���X��i9�8Z냞��@��.�P�;g��_?��l"Z�e�qK���[��Q�-��R� Q�B,(R�)01-�:�����ÿ��5�[��-�C*%P�˩$�th=��D5�Ԉ�O5\a+��-�p��eo����L�dY��$�Ȥ7{խ����b�ٕ�y�0��v/�Ɯ�%��tc��|몪��?:����[�e������4j����x��x#Ť[�Fc8CҴ ��
�)q$C��z���ɇ�� ����~�?�J��4�k8ʫ��Y��뇉o�$����\a����9� g]_e��n/����ҟ%[�$�@���I 2�:"U�hFU:�r�GƑU���JWP$�i�"& JȀKy�o)�Y2��eaҭT�����P�f�D�S %�9~u��?�I����D�L����t�"�b�q���Q���:����|c�����e��X�(<i��Y�[��*�׺���O�9TE�N�d�����)�X�J^��dQ<NH\r4�^]�������~���;>����S��:�>�m�4��k���?���wLt��ދ�g��h5����*�:�t�n�����̊V����Q~�����}&5\b�B��Mc:�y�z����K��jw3�b�e�{ԕcĭ�9�)}���I&K���ӎ��a��\}��r���{	��j]T+t�NU[k��S�S�<�e��6W�-p䂜˲������o#aHE�� �-#,����@_`����Y���X(�	�c����Vo���� ���j�H��=���〟'k�#�r�x�¹A1:b�h^ M��쓱��T����PN�nq��(W_>b+�!��1�sN	-�7L�,^����S�L�ѹ���+��c����x�M�'鴟18�y�a�`�3/��!_i$�'5/���,��/?�w��+�W� ��yR�h~�Ja��0W�l��p_W��i�2g��~�U��%��B���Q��U@r�'��.��Z�e�`�q7	'����ş�+�V����/��[���-��T� ��B��Ys�"djbY��)mil��["�#9%�R�I��>>��$�8E�Ζ�Ѥ�\��qY�őN��˶ԡM����۽�g� 9nf��5C�І�L���$��\s��j��^eo�te0R� :�z���=V�y�$��Aȴ��6 :[�%����ki*yc�s]%M" �:��H�C�k.�$��u�|?���� ���fOm�Y*�[f9���sBk�䨳Ǟؙl<�c#K�����ˮ��z�n�rcl|�_��J�%�"Ǡb�WlЇq":��O�0&�C�8�̳ͺ�k��U�IE� `ͷm�/w�=��
��*P����*&��E�l���nS�66��׬�L3Ş����>*U#eU3ԁ��;����vF���k�� ����0���6�q�#����_�G/�t��r�t��Z�Z��7�N��޶V�;X�m����4������J��9;3�n�Z�rU����geδ��RqiY����J�!�rzo�h�ftl���?��(+R�2|���̌�̌������[BDA����
ehf�v���C�0Jq��wۭn�V%uT`r�֢Q��^A�s|A9w�Lo�v����� �2���� 
FU	T�Fnv�\�Dw�8�,�.F3yD~2	� ���&�3��<:C�7>�Z\�0
B����t��������+�`#J.Ql�|�і���T�u&��������+��0�������.N��{��F�DJ@�:$�̨|.�䋼�uXz�>�/����@W24��Z�nҮ�:^����o�Jg�/��?��,u8OU­�j<�u#miX��2��	��|��Y���ElA�������0d�
|�`zC����O�d:�p�/R�FM��'{~/D�� %����SV�\���P7o,��h^&ial��Uz�FݤU�z�*����(87��3�T�K�MeE�r�J%|/�K2����ℶ��ǵ�������V��ZX�Q��F3Vmt�'t��P�c�����s�4%���e�)2�<K���C�LG�p�C5�y��fy��aog��Cs�����^IY�o�p�Ҕnk�6���$U{#.�	�ib��MP&
����$y`�Z��窮���~/�Ds15������&gDi�&wf��mH1ݓجAk�R�?�j�B�B�m	����ǝ����co�`+���~M'ɪCѤ��
�!���O�?#�}3�q���C����b�[���n:�Z�Q�I0�Eu0���?p���PH)7j}?H�dsg<P�?�&쉕BL�9���[����)`v�D��º;ov��`��T\�ø�V>���K,g{��>�ƌΫ�Oԕ:��Z�-���k;_�d��$w�;��l�A
�d:m��X���%��@
�y�Q����p�/Q$;���9��n�x\mT��DJ��.k��y��*p_e�T�w�O��(�#�Uaέ%��7��D����A�l*FP�����P$mtؖ�qJ�F�ޔK�m��D��~�l?��t��sg���?�*�H��n$��3�i���7/����.AS�q��0�[�+?�xK��䑺��kى+�UP\�`3Bo���p���$�n��� Cn��P�X8Su1ŲXѫ<g	oQs��h{��C��ү���fGv�����ﱯ�_��A��k"	h{O4��������׸�X�F��M��-�F��q>����Ț�xy��+PT�?����/������b�;v	�ݚK��Fz̫�H��%��~��+�*~���C��UP�j�h	sog_�,���E�8w{W���sɬ��z<��'�K��"5���E�؆�Ԕ���ES�O�J�mU�c/�8<~[ƙ�l��uِ�$G�U�\܆fdHY��kD`����I��[��k]e0�C6�s�S�W(qj�ܢ~7M����m��V*7S��,X�*�w��D��fx��K"A������iۤ��]�͋���:�J1UM:��5�w���hC��K0��e���d�#��0O̳@�ȗ�<�%����a��nH���+�oB�U�9��xQ�-��ϲ�dL螙Mc8nʞ������\��g���+�t
�97_�;���M�Z���s2��o��) b_�C�qq\X�a\1�w���%�Xc�� ����H�F�P�׉���͂A�*[,��*���4dg~��_�#�bH�Ϥy��5O�򐲞�8%6Ѧ>�_��UVҍ�	� �_�C)ނ�FA�K�����,�ZDU.�!ve��6����tL�=`�<X_b+�9�fFuR�`V�ii15&K#���đ�j]G(���R���sR"��?b�9o��	���r�"ܹB5�0��#���cv/�B���+E�O�yr��[�m�c�HU�a@���H$�.1�P'P���Z)*��w�dY�?i^���W�T)'����`Cd05��)����|o�潏�}�%��p��?2Fq�y�} v�'��O�t,�*���Vi':�I�[���2fjiW��JМ�1��h?7k�F�-7l̆���ڵ�gbVg�9��Yي�6�#]Z����al���0T�)na~G��+�b�%T�8*}���$��T�Df|?�v�g�F|�J�bE"M���Ւ�0ܭ	u�*�L���8=I�n1��3�+��G�t���ɞ$�������Kd�)�%���O�*�Е��&��"�'R����2	���C$>��nx.�dSM⃫��.5�K��l�Be*X�э�c$MmK�� �u�o�vii�F(M�	s4����!��A��xN��|����{�3L�3m��f��_���2[�oP��[��PŒ�ĵ>�ꇒ�g�h���^x���f]p8�ڿKs7pQ(��XJ��d��k�Qg&p@avG���e��d9jfz຃�K���9���~Cْ8}�k�8���ꮈ�S�x|�ء� ��uS �EU%��m�`͝�.�Y��������ś*��Mpu3��.��7���w���j��zue����p/y�G{1��_�ő�~�+ܬp��+vKI��ɗ�95��BV
O}؉D�q;�p���aZV��R	HL����k-��/���
7�64�>4�/jBԁ�~p��%����眜�9�;	����J&"�P+��}��
L�3Q�Hm�GV�!�2�(�P���B=�c���i��:��E��s6�� ۉ0�q
Qꌃ.s�9��� �+�T��Et��+�/w��Θ�L��/��W%�,�5�/��������}#����~��w��wS��"?}+�'�D���2EI�:���mJ�����ep�\��WO�� �Y�.�����*d,��hoXQ^���+�r�;�ܗ�ge�)�IؕI�_2�Q�}�`��>��+y�H�a`��Ag�������t����)*�E W`|&���&U�j��o��&��
5b�4#h�S�.)#�ң#�y����Y��*�{M?W����18>����ep��TDvM�����1p>��fEC����sTn��Z�y-<��g��O\��&��+�6���9���������;�=���)kJ�b�ZO�ĸD8���|K�d��Bk\zS��x)J/��A��y�I�����wXĸ��vDq�8aB#	6������h����N~��w&��5������D3M��ZJ@r�e�t������]u�-A��5�n*U�v�ƶXk��N{���'ˑ7\^�%��߁u�LR�B3+��������:j�]F��������ʌ�:V��KK$����
�b�Y�>�>��m���4QrO���0��#����Ɓ?dCX�A䡱�O�tV�.�R�'�C��GJ�Ǆ���O�kl����x�����{@�i�ҡ	r�8�����v�=#®��
�J��(�5B�C�j�k��Y�3�E���Ś�������٤����!/R*�~ZVc�ǁ��#����~wtp���������"x�A�����N�rhn�!�øk��3��^�§H|�A4-��؀n\��I�?��ӳQ��'�f��x�Xo��6�'���fQ�S�nk�[׮�<������|�-z��-5uCˣ�S�1�kF�g�z���E�ԏ	%I+��h��gOzO6rm#���fV�h�� ��j���Z��]'c!5sL��`6��j%���@3�ȼM R]�=V$�+�7�O1�2���U�,I�JZ�U�B�޻5�\�9�_]�wk�M���[jSH?����}+c�`�QdI0����lc�ٝ�����N�j��vd�i1;2k�Q� k�a�h�P���p$�S�~M|�ƽ��$��9�����˪�w��;P��0��v��2��h���p����XH�1 =��4���g���rۿ$6�0
��	Z�T����=�x}_����hq�/{�����Q{�Hog����gB������1HBؿ�Ԫ-l�Z�����e��hv��ȟ�	l�����)�����=5UM<n�� R��y՛�	� �5D�E$���=
�z	�(��{���HY�k{��O��C��qӬ���W�ad��T��:�vk�J{�^O5�*L� �%�Q��(8�r��3c�S:�2����.��G1�.��w��p�=�F7]��M̜��I����J|��'F���I8c�\]�7��#����}�ZY0�dP���I;$�6����Y���iP!�&�ZK��m.�x։�eʁ��������3.�:Y�4#��A���o5z@��S�ZJR3�%�dRI��J�W�U)��j-�	S+;�n���S���X&xL�̎:�E*D�W�ǒB���MI;.�TTt���}��E����k=]>�\&/������x]^^uJZ�0��q���-Ծ�����#8ÚU*�Ćs���j�Ae�_��C	IN�w�s�9����!=,�:�| �� x��
4�p�c���rzA6p�k�ǚ{WM?�T<�V���E�A�:Tx�_��6�����ｻL`K������Vgw��������C�AE���%;��S|ީ9�=�/-���z�2�/��;=O>�f�~��c|<��i�}/��k�<����8�߽�s~ѯȚ��8N�����N�.�tG�x��z,��^r�4y|Ƨ8j����apT��8�"&��s������M���RYul>h)1���2��ʄ��﯉�9$f��;$�^���q���*hTsG�&���{�)T�+)���wO&Үou�$���7{ǆLS�&d-�i'ۚ����Q�����l ��H#�|��iP٨��6�|$��R�$�L�)v��طmhf�{'�hQ����J���sMs���xhK�Y�2��Y��j�6iJͩ=@^hl ��e[H�4��p_�}?�;�:r}���2eW ��p�}U��94����]VP� ����o{����l�.�|���{�S��g䮶������Q6�v����c:�t�����j�H9��Ư��h��݂`�kB���5z����h�d�®��ݙ��
��=ڨ�{��a�"��%�A�|ޚFښe��+��p(�m�	�].}�5�g,�'��M�BdjU�$!�ˆ�Oc�<���ߧ�������.�d�xi���S���*M`֛V1�#ЫZ���l�ǿ�S֒�o���SXc���t��P�U������i�=E����i�(�j��L*���h��zDˀt���.�`����kX����!ͣ�#��v\!OP�,�k6��!%(#F�� �(�BR�T����J��sse~�q�!�.:8�tPZ.��,��f|�lf�J�-,��g�S��ۃZ茩��㽗�Nv���N��̵d�48+֪�'պ��E��'�/�a�u��y��'{y��N���|q��+�|
a�4&%��r*�Bg%���F�ЄC����r*��h��w�s�� �7D��k=;-BT�J��Nz�gp<ޫQ����8_W�����i^��������������F���f-����:'s�*�*����Q<��l �[�fE~*��CvWx��q��B��e3t��E2�;�p\�Q�gd�<��@}�9�^\���h^�0p����)�Y�A7ŋOG���`�q�ޟ�I���9iT9"�0x�#�<���W�djP무�T(	p��Ju
�<
B҆�q�+�S��rH��ł���&����[��@�SB�SN�s�#�Օ�n�,p������>@����ﲅ��fnY����!)ȢZ�23�0ng��Ҍ�pwI#��a��D�u��گ�V�j":��+etii"JbDݭd��>��r�BÏ���-�/�3l�k������tv��:���	!�V8�>�fJ��Y��(����!�t�%�BQ���|��˻6�
�,K���d3�6u<Y���d���D �0Z���R�j0����0^�Y%>�[Rg�	1�V"��ŲѻG$6��3fiEF���|Л���p°e��������	$�ӡ/G��MV��N4`��E\�Q
�ۃ�;nP,������+SZ�.�hk'M!��N��T�`�S�kky�E�ƺ��O�`��23!�̮���:
�Di�� *�L�|G�ד>�{��(��=Ư�N��Z�P�8zL�Z}���w��2:�C��
r�."ԯ
��s���$���l�^թq��k�TGM,�E>�?��z��~���@O8�#2y�<�/����!us��ٙ�ۆ�1M<H����⛆B�¢�z�
�֝J2Ե�)x	���B�dl��ɸgB
�:g�����E���|ڐ.� &��.H�����1)�NVd
R$k��>��DǼ�A��>����1�̳UyC�?���𿓖!qʣt<�sP�J;�Dpl ([)&C��l~S�o�aI���]4z��~�N��̖H(9̆-տcl�4�u�8ت�j�auJ�>�������f1/�����EwsC3�t~lV6x�_�Zg?�)F�$�K��h���KǴ@�ε"��&ʪ���:zms8���q�s�c�	�?�,=M(׆��1��xH^������D��"�`���h�cf�+o��0�31v�9����&~�M"T�+iEz�hϦC�L�xN�1��2��r�~���u����@.�"(��[:)�0��V"��0�z����D�%&s�OF��e�5�NL�~�߲��e����$Vx�:���D�4J��*���,���N[4���^j�LwS�v*������[$�\\4,:���}*%�w�tF�g�JȜ�� 2��X�|�Y�!���Ż��E{�:�� o?f7�����'�Fif_�L��`��!��%�b�m����вJLM��D"?A�^���?���Sė���u�a��MS8*|���ʐS%�o�+���Ό��*%�X��,�Ǣ� �L��Cs#V\��;�y�񊹲8�-�9@�~������� �ǵ/Z���d��b�������q^�=����������_�w��󿾶^Ͼ����ݿ�~��?q�s�vxY10��Gߚ� Ϙ�Ϫ�5=g�g.#T	����)�T#�1���S�~��[{m�ԥ9QI�0��EY�;��ݝ�c��4r4$�����%���u��O8t�gc�d��l��ix��&�q#�� _V�UݭT�N*'�̇p��O�WF�v1�I���c�����Pc�u|���a0�?�>k=¹@�^���G�ԣ7�aR=Ӧ�r���$Rmh��U�[�*��Ɍ�<�jW�X���JƖTrh���H�cg�f+��y��2����HN��z2c�0m������牜P����ڣ����z��#��a3)T����~'�g�I�_!�#�FB�Ju2�**t�kB�ζX-*t�ET�Y�%ǎcNq��m �r�������yof��p��C?��~+��[5��@�ֵ.쌶XS����c�uv����e�MQ�?J��� ���II������\�A�(T#�?�~�j;>����d�yV�{�?_�	\�h���8���������O�WG���������$�����}%�?Ȯ�逡�r����
�.#~�`N�i���;����>�z��sI�y�l�}t�G��塙���g�y�D����~�mw�yM�����_z>^�StNQ=z^�@G�:p�&��N�±<G��#$sB�z�>v�}��z�3�g�6�s��@ڄ=|:���kc4K{@G�m�� ��6pܝc=��)��t׎b�4OR���zV�V_Co�IW> �\͛�7L��_����W���k4�r�_����.� B
$Ep�>n�M���\@�����H�>�ʇi�tj�D}�#l<Z�%�A5{�y^���� �� ����$!cϊ�lV/5R:��꣔��?Ȩ��xjF�0PJu�� 7B28T	_��l��r)�3�E���+�&@	��NB�{8b�"P�z�.1[B��L����A��RI4�ĉ��5:Y܀�2���������'�`�"F�+ X��x�g����'�Y�V����3�ZYnBM��	��]>832�~E:�lu�.���|�,�fɧ^C����W�;l�K��qv�q7^7��2��dj7�QvSEߜ$p�i�����3���gjƦ�;�]�����Fk0C{�5l�%,L
��u��24�\�_6��:�è��n.�?ڐ�O�1�bo1^����)&
@�,;
�z��t�Eu42j�������X�w��/���?}�����{��W�<|���4�l���,�J}�2M���y���
)^$#�����<|�bd��[��.}>�|�C|L��1�,�F����C)x�_Q��(��mr��r7�O�Oc�.��Yۭ�4��j�Ѣ���Gf�䡟 TP�&	�����|�2ӥɺ����g�������Χ��c̐��͌� ��k�N���@�>���,b�^X�AyK�T6_T��4�!~�ľ�$�43��L��HQ~�,��P�!޿�n��O zפh^�6�$�O�ĳ@� �);j6E�����`�Fz�f"K���?�� �(2�Cp��v���1*�yCh<Y�dv����;���?t����1ףּ׈�*�w@��EV���b#���q>�

y��:0��o�=��<n<����_G���꣩�S�L���Ŭ$%����}��R�o������z<���
E
���`ۂb��pȒ��tw\)�8@|2☭��,V����7<��E�Y���b�k��z-�r*JR;��p��2�Z����kٻ/�6ǃ�.��� ����,�P�u�no�_��ݴ�l��T��x42\��EF5&��/��Ϸ�m�YO.��Z:"ҁh5ʕ�<E(�E�����g�_{E�h��d��h��a\���?�/7�=&ѓh/�葏,:X������ׇ� ��]'�5�*�OT:$h���Y�(��� ���;�rl�q8D��xS"&.=�4�b�c���UFxo���Z��TJ�I��$��Bƈ�o@]%�S�QW�F��*���p�р@-������=-�ĪE�y������?�������s�����?���������� ��[� h 