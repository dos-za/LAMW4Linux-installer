#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="437891875"
MD5="6bcc81f9cde8dbdffc1658a1f09234db"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20216"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec  6 19:26:02 -03 2019
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���N�] �}��JF���.���_jg\`��07C̼w���l��C<�w����V��O+�S����AI���v�n7@�+P�%T��p������~��P��鄟q������ܯ��w1�I!	�By)���_�ok�r�S���
��w{fL[p҅4��`<�#@7z~Ķ���A�b�rO�$Ͼ�V��,�e5^J"�z�E��F\�4�G��\��FB�`R"������ʹ1l�ɩ0Х=i����L'�e��ɭ��f�+���x�C�V�����U��� *f���n�`���C~2!��Y���P��!JWM��[�t�x����_G��Y�nG�[%�.§��ي!c���*LIY��hT;����F}��	.�����o��P`�[�R�=��TRu�O䙖�.�l7y<_F���躼���+ڇ�/��Ȉ�cw�X䄁&-wk)o!M�ա�D�����B�l3�*�_�@����+���h5�׍8PD��2_e���U����pZ��c1M�&D-mK��	n��^���2�n�BF�aj6�Q�
Z�--����#�:�b�k�h�4�b0�h:��y���,�q}�Uʧ5�%�{+���ڤ�Y�}��e��[����C�P��p��,q��mv��-M��o�g���l~��I�W	[�ܶ^����� /�l�2�0��y>X1v���oq���J� 3�;��U���{�M�-���C�C`�&A�8'=,~�_������&0�`T�`�c3B*�s�Ϊ�}��9�v>)��z=�c�rk�.��c�D�
G�e|琧�X۴�
4�4���	�\u��$'C}�ὃ1��[���YEN�o��~�����P��`�_D��`2�୆�l����3�ĵJ���	ƩAx��Tf�Q+(8�B=�-�`X��(iG���2�>V�Pul�PC{s֗��ː�gX�|��D�S)
��So��NOe�e7�I�jb����'Za�f�>!.mD�Q�)��j2=v˟���UMŤ����c��ѣ`�?-Ƞ�x�h5���.�.�D�5���^
N�<7_�l�/��8��q���eI��x����_���8�#b�4k�Y��4_��G!3���A[�%�x@�旃)=i	��/����【����B�Sj�|��7]!�){&(��&Y�RE���w֊y_��j�5d��v��@��}J�6�5�U����m�����r���<V;jv�|�v�|���b�ā������� '�őR&lSJ��,[��$~�WUD�yW��j)�v�=T�� ��f�u�<��rs�Yl���0�5�����&6g�^��+�:)�z�7'�j�|�B-�N�I	�ݽ�,;ٿaɖ55ж�8 fg��t����5���F�� S�Ԣ��X��&.�ɸK��߼�����J|�h�ظ[���e.�@'��2%ej�#7��~J��q�Gmן�\Q��6��⿥�u�9���s�a�I��!������c�V���~]��i(���S^�G����S�)>�yZbInP@2f@(��U�����JF yc�Y 
~�u����_!����V��&?��4I���e��X����@�첡�9'r��R��yj��wյ��(�߿7���·1�[zm�%��bK�c���Bc��D�iU���=cѲ�m��C�t��k��u<���&F�w�y֏F1Y=�ci�NJ�"v�f"w����aLGB9yEcF�ї@U\휦[���n�@J�{�t�y�1d/;���H��x����e�s0���<��Ǭ��������A�\�"�:��������\n!E�δb/DS' ��d����ja�\?$B�3/b����Sm
p��Ov�f�f[�����ytít(r�-�xl���H�ΫY��6FËW_���Y>jݭ����Xo����5�-���U��}u,��r��	%Sxak�^;G?�\e��|'�i��X�m蕺�@���u��S�n��*���1���-e�
#�,w����3m��u�L�K��c�-�VB�ѱ�@p�Ӕb����ļs�R���]�U���A^��u�d*<�K�h�c��=�*6���A�w��=�m�!�A>#tue���\��v���B˞2���z�6s��?7�Ȓ�;I[�.�Ujq�wD�I���Z��#� ����Db{��؉ ��R?��4�P~+����:��N���e�-;�8����_��/h�;!��8eOC^	=��ȃ�&9�}��?E������a��(�;���㘙�o�U�=PZ�F�U7#TЀM�j=N�S��w6�[v�p�ǖ��!��������}���M����3� �&�7����v=΀9pS4���T�!�����z1κ��OL�{mĥ��;s�
�P�����������$.*��^v1ۃ����N��XL���!��qu��Ilw����);�{�­��R�iF��n"A\4`�R[�� �s��V`)�S�������^Z���&H�/\
�:z��} ~�dMm�>�0 _������"�_�T��BwN�U���G�<TU�Q0}�v��_u��y� �Ǥ�����ќ��_����	�Z�_XcI%^�f�[�������.��wQ�g,?�-�Ê�{��Ī���Ju��BW���yO��n%D���XTL�:�0 l�E��t����qU���r�o_{_q�"�'�C
��4:E|�a)�80[���3'_t�<��u3ӧ�҆�/�l���������KBXU�$kM����r�w��+�t>�DY
W����
|���e�P�R���`;s�N�	xIg}�V�+V�e\ �[ ���x�_��?ܲO��C6��� Y�"����zS�K	�ب�@�M��#�B��J�F`l� �b��S����������j�dV�|�f���k�
�-	�i}��?����3lk@�
�m�8ވk�Ӿy��Z���b��
��o}afz�s��-:է_3����ˆ���"���V���?V<���;���)�`]xZ}���ô9|E���1$*�_�!��!�W{I��~�����ŀ�j]q-���sp&���>l�/|:> Y�v;�a���_P�wP����|��wT�*?�_4[��V�dQ<�P�� j��
-�s����Cξ�7P�~>yw�+�Z��C�;%�Ɗ��%}���c�������m�Q���� �4J�1"�88���r�>�Q�k�(��/%waB ����E*u"|wK�D�}jEVôҤ���gw����b;]KU���>̺X��*�����\^1�3��; oG7�59|!Ykaᮀ���)q���w�׾<��&�H�����z� a������+�{Q��v�<�`\뒆慯��Y0*&r����3���̄q�!�F��6�/��(6U��S�c���`�����b#?� Xqυ��K��Ha������?�>	���<�h�,я��H�;Ou_�c�Ѯ���!q���)Cs�f���Ӎ&�Xp�
dm�h3����y���s?Ҟ���G"r�#�z�y��J���e�t:��X�_����݋`��k��	p��Ξ���*�h�eO�@B=��~���K�
�w���E�٘�&,���]U$߯���b5�3.` ��ҝ�z_�o��80�p}���O�I����vݩ��>���"lU�_⹿+��Hn����.�c-�CF9D8�_q��@s0����n0s�q�y��� �����
2|��;��áz;��g����%E�%�M"]#�h��b�th~)�r4�́����M��w`X�ø��7���������Ǻ>t<*�\m�8˭���F�i(w��/�2]MrqG��:��'����}�y<K��]��n�"�-�_F�)J���^�\�lE���T����J��M-�,�c)V- ��Sd\�ɼ�@�E��_۰˛)N��� ���]%Xi	N2F�tHEoڠ�f������\�kf�A>����9S������`��?8S���:^pQ�i�}�)�L6��q�rci��\{��!h|�*B��R�mkfN�s�.�U�0��Ą�1�[`��"L�gD�k��g�́���C��cܻTƇ�Y��G�k�[�C)�Z��$\0@Z{<�,p�b#E����� �ӯ�����8bP�G�0Ds �O3�r��>$e����,�GE�0YH>�Ț�e�T�2h����C��P ���l��B�Y[Iw�2���*�興�hK0��]v��6!�r�����H$H�.�$
�����2b2dH�%�^�>����'�FS��@���:�@��c���U�A�F��4�m��1� +��5Ca��D�L�W��=��}�������U<=��<3VkJN��&>�/_G�i�(��j����E���`���~�;?�V����}AP�ם~�|?��S��C����6W긫����tb��:M��{���/3(�(F"D$#�$�*xʁx^O
Dp0O�9"Q_)\�$^�`�|`�%��ǝ�A��k�?t
�w!�к��+�nzMP����~N��J��a�������w�;/��,���'%�I?�q�o.���S�����nC�#s�|e:q��)���1cS+j�z�W��9�n?��6�lV£I�=X�n���(����Y����ϵ�'&�\��]�5�o+pkiؙ�0����9��P%E��-�!�:ge��|�Ҋ�+� �W�#���d��5�2 �p@8&*��M�E���R�3G
�A�.rO�PW{u<�>��k^�E�aS���z�;��,b�HIWArĉ p��������9�{U�H_ľ��	7�h���.�M��(�w�}���5���-ږA��o�ȭ9g���;­�-~0;u���I��<vV{�F�F8^
��5_B<�u�w��mV�D�Σ�:ǹ����!<���,����z��[�j�5\pV7��z" v�2��Q@�qnG�ϩ�������b1x�B1=h���g-v&S+h�n��0uv��4���A���#���ۃ>o���i�{�e���cK��ȭ���b�U�ˮ�os��o9d�ZŸ�LO�6����\�'9��T�_�曱���˞)W1����KsÓR[OJ.�>'�@6Y5ˁo$upm��'*�E��4Α(%q�z B9��v���UN���-���g��=ftT�q؉���t�t��tX��7��O�5�.ʬK��b�n���wQ�@#��X)�2壝t�w�'��L�_�NS�-�&ʊ��(2�m��~��_�Z� ��4�<�r;'=W��vPH{a�Rf�_7��9Z�+�Ҿ��~��/������C�$wą� ?�i�J���3�.`����?�s��GPq9hB�;ޛNE��%�d�����ۈC�*?66��4Z��KeG���~_�!,�헤�ܺ��B�
�ϰ���ٶH֪�.K���^,�ow�nqi�Js���Gd�͒�$;��+k�
��枮zz�V�p���(!�"�XB��L�TX����!+�ń݁��&����e3�^Sc�H f��5��
�*�7O��B��>����XyY�I◙|2T��n�����i�(��Wu��F��	CW����"�J��I$9���Mx��
G�j*B�K��.�If��zᪧa1����D�ͥ�����B����᩻�aɬc��t)�?4Xo,I��X �*��U\�TToi9�`Ͱ��cG#sh�� ��]^	Q�?
5M~�J�v%m��Y��SD�c��2$}��\J���*�K�i$H���H�$N��	[C6� �*)�隳p�rc���˽nU�E��tD|���H@[���c�o�.X.W�5���	4����I�O�r"�&�g�Lp!��g���[ �}48����F �@��v<H$ho3C�3Q�p��ܾ��VK�i	�y��4`�����h��d7L�U	�'@!�@�H��U�x��ߵ�����@M�g��K1�ߖ���#�]�R1���[X��c�����apǾ,��
N���J�`��HO��v#eu켸#_�����-Z�?
�PA�'��$:0\hJ�|�,�wWcL�z��3e�{M����N�H�K$���g��ul,��V1�ц�W��<c��C���8�E~%$��=���N������}��\����\��AY$���H���ŁOH�K�.�?�^�`���aC0�>L�)��Ћ�x
�6��3}�</Y��ՙ��ڔ�b�0�K2Ј���c�YM���g3\�yNƉk��̍mg��?�6��(~��Ï���,�L$�A�1�|LU������U�L5�f���M-�X�Fy�;vё5���YO��_��K� `>������2�7�W%v'j��_c���^.���ó	�R �	R�IZ4u}
�j�x;_+�N�oe�>�d��������H��	�(��٦���,Xrj�g�g�]��v����蟲�B𢠹��My�3nc��F�2��qׇ�� Z���������l���:���I��,f���Q���6�������C�e�7���a/VS��JYl \��t���,K��e����̓���ܴ�D���M�m	Bs�c���u��J??�:O�F��_��y��D�ZN��%f)G���Rzo�=�[ �uƾ��S�w�!���W��,������T����}�~û�Z�t	�G�HI��V�CPj8�f�H�p����[��O|���^�L��u���A��wVC쭋J,�}�\·����i���x&	�ϸH�f!>��ԹbVU�x�)\��L�/8t�qޅ��t�{�A�?]�;41��+�>�1�f���i�q�I\�O�j���q�eyĚ��<9��:_3�G��c���c��
$lPu�ˮCzm��f��m�m�:kY|ǎ���s?p��/҃`��'$��d�*Fh;y��=p��|�j5�����k	5|v���p٣yr}H>��Tx]d��=睈B�?�-q�I���Ji�B��zM�����1���m:�^C�'�.Ԑ��i"���.�WDvde��X�L�l�Lf�H���LQ5�/0�1^uS=�����%�I�n�x�T��G��!�RN�8��y"��2r~�?�ݰ�y�n��I��UᮏG��}�Ed�?�V�jس�Z���M���L��9R���%��͹�e�K���p���{���x������C2��I@z˵��{X/������㠑��n�I�V�or7ʛ�s��O�K�Ibo*O�bo���F��/#U�a�(��vh����D���Þq7Q����pu�Cj�&fth˧cJ�RҾW�{^��Ap�c�t1�_o�����p�`���t.���l��C��/0!�.*#Zt&�f��껈����&�B;���{$��$/.��z�ړxr2��]%̺���q�*�Y���y�j�U��J�'h���إ�r&��1���b�L}[{�kVp�{z�k�Z�|5>a�P�эX
��5��K^4��t�zN� -���e�1-v�6�o(MNI⑒��FL��4~"&�%\XZ��G�#C.�m,p���e3v���AzoUm��=�I:���e��w&Ϛ����P��抔��!A>�qn}Ej�O���eo�x����G�V��I��V����|�����밋����+��M��=����ˍ��3�"Ʌl���S�Y�8�ʆ��y��Ǣ�:9�Qzf/�1�9�\�N9lh����7�s��/����qF?���W��k�.�GK Z�8�龱&�� S1�72�{K,�L�|R� _��z<��'E�!����Vi5Gu�3=A0A��Y5�ͬG�|y����z+w������tك�E(�]x3�/�bGt(���
��g��]a4y��pxU}��"�R��٢F%��im?���U�2<�o���:T(\޹�����! �.�_{(��[�wez3�s���my+kB��1?eyG[��Jd��x6�b�x	6�Wdj� �,q��&v���cVY���D�-�i� �w\�ȥ��|H�'����Ra�@��m�0𻅹̒��L$i�9��+��2B�sO%��3~� �Q��>W�F7�����O�ȿ�v����u@4�����zs�pgþ4qmvk/��x۫��#���j@��M���Ղ�vf7ֱx3U�Ki�Ɋժ����㚂9K'�y����ש��VX�+�� �=�ݎ�����Ń����p��MU3U�rI�AU����W�u�UG���?g	��B�A��S�j�q\�e=��,����R��t"��~5�Q�	�������hKްҼ���KL���\:8!d���snlu]�C� �u�G1��@�E�]��*��$��U��6~7���'�_�����L�1]j!Ү�IZ:���h��6���7���
)�>~~<��#c�l��3 ��>}����Tܳ\)�R���{�YQ2ڇ�mSk�*H��se�{��N�|�H�Mb��:I��'n:�ߢ %!ou�`�������T�҄|�>�)�[Έ?�}q��1tKPR��֯
���S�<�wN�Ҁ�ӭvO��:���e��Z��
?A(�BU
?�IS�6�D�<��`�-ѣ&�l8<��A<>�:m$���1;��M!����mr�G<�������Z�%# Zu��@�o!F5Z����tG�gkM�����^��_�'`v��[Y$'�w?�M0:�����H��ѷ���'��We����X����ŇW^�""�:��-�Md35��
���K�ˆ�c���k<p}M%��Љ�e��{����2�<8����p��Y���<w>��/��l�d_��37�����H0�*��38}��.��=v��b�D��b��ߖX5��V��d�]�2*gZERRѓ���9�����u}u����/�N�v����a"�k��p!&��!��˜=���%�FS#�q��^�^}f�*1�`��7��
m�k��.��EH�]��A�mx�eBdM�#;W�
)�Ne|=k{ma4�8��u��6�]���]�mMk�ԓ*Mn�sH��4uᨠ�@X�)��X�O�ױ�p��Ĩ՟R�?>)�\�QC���ru&��!�4��@��T5	i�z^]�r�똌cq��?���,uO�Iw&$G���cB���%��t�߹v*�Q� 0�ȵ�o�1�p�dz5	N�/s�X���a���b/��"oP�O��R?��U����ɲfK5�bi�ܛ`��]V��2�^�,2����?�<��iɾ#���~x2x3'V�.���0hE��ͨ�����������`մ���Jإ��rV�\��� ��x[��+Q���K�,�gM�OY��Cp����B�	{��S�R�K�e��i�*�/C�ހ��[��E��`Ĕ��^w��я��9~�z��e3R������7w��U�d�D*x�ٮn�	�ڿ3�70@���O�q�aň��;?�#���A��/��'���w�n��}	�C�b=U+���o���Mف)�ե1yF��l�ሊP�N�ƃ����?=I�o]�Q��f�Z�Q����@_dD��X4Pk��+�z̲@��� 7�[��2�=h
B"��x��S�R2�o�s�X���讑A3>�veZ��?H�\�
uy�tD9�`�WW�J�����p��I�G�eP�>H�.}�!��}:8����jc8�o*�/����٢!�z����Q��7=��/H��e�Rܲ,/�W ��	�
�r�ț�B�C~��@�%>���)��(���z�����a̵��?�����~x�g0m��hy�(V�peأ� ���p��0��]�j���WQ����F��{��i����'�h�ȍ�V�F����t������������g{c��kSF���l�n��ڑ2����;nC%vo�i�S5B�2{�A�~"��X�9�t��A.��T�j9Y��{���<���π�u�R�h�rk?P�ҟ�
�'�~cb�lǹj&#�=A��N�c4?��e~ԧ5`~
#p�G��K*فO���c]�f��~�%�����yj(�d6���$b���$�K��џ1��q��4�]�����w2��%����I~�6ٹ�t�'	;a�[uy��S���t�?��g�.��k�� ;T��42��1B���m�l�#�a��A�>�:2P
�S�e��J�z������!��IV����IiBQNZ�`Β�˻��ק��63l�5B^yy6?Z���c�F�U�2�u���l��#�_!����� Rcޏ����Tg܉h�ic`�o�.-_\!���_T�Y����@��»�e_�l�H�n��f�0Q���K@�	�iw4�H�0r�|Vt��)٦�%���U"�q1�p�����ih��s2yF@?5�_���|�ֺ�r	������Lv~��Z{f6�ʛu�r�%��NS���k�0&C�wW�'�U��	�.TVm"���� �@�]B��I�ŗY�o��`D�Fd���۽�ʧ���S)L��;����P-�ts�ȹ"_�P�t�Xq%6��L���O����Mk���ai���x��u?+T�%݄�@��b�$[*��8f�-!��n��|����lgW27�3~I�7C����H6�l,�O:�}����`���0f^y!���IS'���\���c���(nC�n���������C�%CQ����\�~X�1KJ�;糒�����T�5F<����}p��f��*�-?	�kc�v�t��+\�Jz�Q5���N���a�,���j����&�r�Ф_�˜Ō��Mm:�h�ݍ�gȰgBF��r^��6R���e��W�맩Olt���P�{$+�k�*�^#������t�$����|�zF,����Й�"1n����x�?�v?U�Ƀ_��+kt�!J1�w�����"�+G]���=��G���2[JT�����y�A\HE�-|��Q�9�h�n��*������NAx�h�P��&�M��+-c�{;�!� ���]�J���LPQ?�B�pZ�����2�U�|!��}��s0O"Ԣ�ߑ����Jݟ��0/���l{ʸ�Q!���"Z�q��I�E������3���"���D���f0!Y0;@r��u�{��K�|�1�\]��Y�&ŧ@}~ =���lX�=��{�Qjq�'};Nl9�ځH~�T��^�����d�|_�O���5x=E�f]��հ�m� Io��K�q@[�K�$W�����U���J���b:Mnk3v�U=�^F~�ii��psaq��[��d��B�+c�
���3�0Fs1����T��6�������������J-�旗��Eh94�7��r��
)X�����8��q7��N�T�M�
Q���2ꚍ`��)2�%'�.٪ӀA�Vny�T��,z�~6M~�}]md#Q���T�;EY��kwO�-��[&��[t���p�m��49K�g�ӁO\DTkⰂs}$�D� sB�Pz���{p��y��Ade����c|�@��F<]���qs>?a���⸗�(��%����Ŷu��\A�P���G��$�C���l���ڙ��X����٤r�4^�mr� ��ʌ=uw �	(El��]l�O)�Nܸ�3����LN�r.��h�t���zEQ�߰�@�n,%���_���؞+	]��;;GP�k_}���D�&�/S+���u���+�2Va�7��!��2Mß,�z�A ��̞�e����am+!#�4�P�^� Z��Ð;�K�P	>o�3҈7aCy�b\�>Lȍwj�N���M�R��tڰ�n�rlPiT��B8�f�0iP����H3�Zv}��X�:a�b�ʞ]'��(�(˝�\A��ô���e�!�c������|b��ܖaDq�������6&�<MHfo�ؖ8 ��X�q)���<��C�����;�Bk�g�#S$��3���G�
�)�����&9��S<T���^LJ!+~��*.��i����0�ȢG�հ%p����궆�[��b�d��~�Ѽ����p��6ȃ `u��
|o�@������cV{o�G,���f�1|Y����/^.���(?�m 5i@��GUcpwH5����X`'BC�������!,�	Ɛ\"�¦�É�Vŷ�^#��_Y*C�zOԩ�(�6���3,~���X���!r�
�}��i����8�Kb�\�Od!�N�D�����ٟrﻏ�,Q�7�lY��"���������L�xU���-J�+�:ҁ�FI��7̘Z%P�8}���Ftџ����+���������$�r�͒��*�����[�޷��G��R�B<Kc	紊�(ϪI+ܼ��EdI�.K	�'�l;F�m�{�Ҵ!����r�S�8qkWf/�����KDnuپ]�q��]�޹�|�f�6w��Y90�r/�ҙi���'�Ǩ��� ��:�":��EF`]'�|gd`�l�P-*"ov(m/�attCͪ���kN����%�K`k���QЫ?0b�=�9��u@*��M�qm�g�Lރ����G���;F���R�x��S�Ɣ��@��{��nv]J=�ؤ[��k*w���/U��P�	�z�eHiaǺ;[s����X>,<�������12$���7��~�Ef�i���W1�hɯ��!��2^���%A��_��`=J����z�JQE���.W��6]M@p����Ё���s���w
�Ԗ��a�iY���d�Y�:Vi� _���2M�:�@+=�W�j �!�6J��I1-�G�z�Q�v	�����b9��j�hk�Ѯ.ǘ�W��ȷ�=���V$�Cz��?�?ٌm�J����8�$3$d3©6H���i�U��w,���VF,�~��5�d�=_��5\v�o�lS�Y�)�a�J2�ر�릾WB�'�����b��ErE36�$�m�c|�0��0���22������	�d���=���{f3��l�T�<�l���>XI{�}ax�iԊm�lҹ��v s��
K�;�:r1�l��a3�VTn��$�<��(7���La��`��PF#K /��Gc�KZ�86���}���;��5��|���U/��)՜viyd�R�I�
���c��T��� ����W�SK�5L��5;�.;��d�ԝ�R�Zq�߻b����kg�_	�n�c�zю�Ws���!n�Ɍ�?�������`�z�@�^�L�����	c��	�{�yx�0o��$���E	3��c�]9��'כ�y��
�ѧ�xZu|�J��fj���;̓��Ǫu�j�[���e4Aǀ��۹��_���W��Ǫ�Ny(dj�-��o�ȍ-�A��ߦ�*nք�Xڭ�~�E��n��i��Cf٫�5[g+����K��OIG�����7��]+C�����}���M�DgSf\v�V��gOa荂������RE�.E�y)"��lS}p�-t��/��'�n<GD췻���$�.�ߵJa�Ŧ���y _a(]�'^q�Pt��"�%�ԉ��l�l�ר��ޤ���TfD2�sI�5=�K���(�O=3l��R��ͧ ���T=�z5�`�LŠ��v�)=DQk�t�_C�	��y��"&>�D��2W�ꖍ� Ѭv��S�uo;Eo�\!����?#���x���R��X2��kӉE�kg�Uz�[v�m�d��!���!r�6�f���[R�Z��N��2<�f���A��.I>�1\���)lG+...����ҿ2�pF)�6j�_�1�9�z�WCo�B	������M�49��,�F��� ��{T�8l����:S
��8����u��a����w���D�o����@�Ӥ��A|T���\0�ܗ�����(�����P���;�����P����YK�ĉ	ߣM���uS���E(��I��`|�ƙ���]������\$kT���i��l	���2vC��C��[�Q�ZCf�㚥�^N�`�
����1�8�}�Yqo�#��PS�-�]d�. �Y��{� ����	O���ny�ӊ��Q��Jq^{w��R��`�W��,W�DR%�eU�
"4�۾��²���06\8aCh�Ȝ�  �����7�н�+|�q#�k�
i�<��=��*���xj�ty)�>�o���8���t\��CQ�L���w�\2D�ӛ�f��7����7m �B����d��HYR��W�Xsٵ����B]e��� Wx���ח@��1��Cᛀ�P�j��0��y��xw8ecъ����V��&#�����/���<A�;�
ɹ��3NÈ\MY�gh��ɞ��J���U��$�P-i���U��� �'��0��f�`84H��6�X��y��:�)��\ �3�\��|�`S�ko�؍9\BwDQ�����i���sk�%~�6�L�K��L)���N�(nm.Ջ��e_8\�O>�eP��#~4+�X/�ց����p��&h\^�R��M.ح�ܫ_��� �s��=��J�#�Gp�)'66�;�.@�EDAf�z��S��2(CF��&K���#W2c� ��Y���-En�*a�9}�I��C��'�̠�d���Ab�}r'6]�!a�(������"��;zͷglg�� F��:�,�)9��V�^T��Xh�g��� ���9�`���h�"���K�U@j�a��3x+��k!.���=u�݇���[Z�[���0,Ǖ�=`B�~��]��eJ�J�Hƛmy��֭�$��42ܭ�j�e�*�Y���޻t{�WqP�5�$[rHcsVՕnc���34���ɓ8���-}�ey���9ı��x�6���w��7�������`�Х�*/�C��T���@�4��Z))lt:+c���a�)c�*��^��2C`��c�#���`�g�:B����Ȉ��\�4[kOŔ�������~��8bg:�?<��xw_7��w3ה�C����dM��<�������Q�{��,�E35�[ho��k��,�)�`����;D7m�l�E�cb��W���ɂ%7��3N���2�xK�h{�$���H!�����Fя�oU~}~��c�ΜU�!J���~�s卹�]�)�Ѷ����*5V!xorm8�� `j���E�����~bJr��3jb:,�W�ke.%�l���}�_�$�\7���C�qj���rS_)��*w=>^Cs��ε��x劥�0������� ��慤��z�>��y��l/���?Wn��� �B�����k���j}c,��_�Ǆڳ���-6af�Z�W�ܖN���Z�H5���.n���C�N�6o��K�x���p"��u����!0; ��:3�w�ޚ#z���	fMb�m�G{�$��]��[˖=�#�B!ՠ��6�e�����m����eH+��`��[��"u�i8�=D�+6I���L+�h��I����	-�@���\v]J8,c�ϕ�����|�� ���K1Ο�q���n�
g���-�b�T� YF�'��t;tSӊ��H	Y��9QB�Oz�x��Ɇx�|�� j�(hh'��,�!��k9��;vPw�]���i�����`����FNe�Q�7y�H��C�/ݾ� �7�u�����i��c��.���yea���2��g��I���WZ4��b}�W�L�u��e�kG	`
�\UK��}k��-��-��7-ۘ+1���Qc#1L'����� � �~u���&<�8��<;������0оyN�}��B ����^��p�NH��{��d�����v�o�
�A���(��+�[``#y��������q�c��xy1I�5G�8�k�.���a�?m1�%�����0�2�3CAHM�4$���Q�參��_^���I�I_�/�σy���o٠ⱴTm���@�E���]
-B�_:#�O�Luz������`'��W�y���4�`�%�}���x�+Oһ�.�3���A�7�2k�Ґd��9D�&��X?#i7�m�fB����G�K���c�������O�
N�Uc��/�?�N贮)��LU�<7��W�T�A}��<>/��p�����ރ�%����󛯛��1ή�}��bװ��y�Tx�%�~���&�@�[B�_1,$�{�e���0���{�q��ԍ�q&(�Ⰵ��<~��>�%��ǂ@�Z�RF}B�G;%p1�[�_av��@��:+gA�K���@D�8�f��T���Tb����W�K�d�I������Dd;0+��V-�Y�����#�/�f��++���{�C����~+�z�Q��/f|�<:�>�9M)ٌ;�]4�Hг�sf����c�P����W�5��c�O�mhJ��l�N����n)t��_k��yqj�(|wl�z�^1����p-��Ꭼ�����bN(�c-ܽ5��@��2��wё�R(W�0L]y/h���4&�L!��h6�J9�B�>�;�;6Z���y<n,��;?��c���f f���qLG_]=�]�1�8ȋ�ؽ���ϐ
�w�|�B�;?�4����b���]%l&%�*���Ni�ܞrG�F:�k�X�m6�#��<��]!�ӹt��J����.*趒r_�V�~(�T(�i���C|�ӵy�b�K"�p�̏58�a&~L��bh�˽�r��#��)�Nr~֓P���`�2�¥|�տUB��<���Z P�ܣ���X"����h\��^����M�G�]<Ɵ}`0��9W��9���Y����?����UK�|��,��������l�N}�j�Qn[�t__O�<�2��{,5t���7�PSV}U{�3��{�2�7ZFΗZ�^A�If�4v�(|�&I���=^���R��"O?$�Bߍ���F�p%q�����3�׏����>�w¤"��A,��Y�2]ឣ�;���V���Z"��REHS'��ԗ
:�k-��]�rљ���`Txz��G��vC󪓜��#�ue�\�P�p2��<B��}�J�m��
�3��� js��	�֨f����[9o5�v���n��]�����6d��P���Q����(�|�� ���&>��V�(�^�;͉�֎������UQxvNJY&� ��b5Ȼ�4Ff[L��/����25�6�^��z�A_C�&1���bA&��Ip����C����
�Z'�k�Tw�;�7�-6�.��|�o�j;�%n�"f���>��R�Z2/�N+�C�nhR�}\G�'i�7�J���'��ǝW�M�����#��-���QY.w:����Q3R�+�;@�w}��GU4���ʺ�y7�0t����w��ޯ���.$�4�m�?*S�h���pm2רBle�����=�鲪��KO28�:g�F�iC�#>���d!�Z�+G�6#jG+4z9���,� F?�E���m�C�ˤ'Ŏ��P*N�6?���w[�]op��l{�4��.�5�f}����A�pl�+��f�4drQ���F,,��E�_ m�1R��B&��`�Z̆n%�3�w�M�����I��4f}y��K60�d�C�>�ᅾ�:�{b�֌/�Y ��6[�Jv���4�Q;T�ʕ��8��Ċ����H�b3`���^������o�IK�/���F�;b���UB�	'd'#"�J�+M4�շA?/��E�.C�;5*<)d�Ʌ�j,��~�vz��M�V�?�&|g�a�.�8-��T�]�Z|�i�*�f�οk%�g1���w���=(��Vot]������fr7�#`\��N����L����b�5 �����_���q 3�D��Ƌ��@�[��R��-�3��@��Ҡ>�`�aEɼ��L�x�h1�� ͝��������H���]._������`�Ӱ�quh�#�?cI�]�2����'�fuv/�Ѿ?�����R�tU��\O�R[\L�8�B�X�hm���X�SvA��΄��%��t��K^F�K�U���J��a��F��c�He��y
"���)��MOn��N�y�Iy�8�g��B����g��������t�(7������0'�6��Y�M��2U�Z7��I�4`=Ru���T�^0�zՎ�΀�7�Bu�1���!k�����5����@�l����Č$s���+�tfmGQ?��;��4�nwHV�����>���X��V�����j!r��[�5Xz���V�>7��봂Cզ�x���9�d�`��������6(/���gj���W��8�\��5<b����3������!3�Ӿ"@�}������p�O�ē^pxs�a���mz8���l�W���<�Ќx=�!e��k��`�����xY�N{1Z�kn��/\��7�F}ɤY�3�9�e�����L,��W,u��,��%՛��LJ�K�KCC�/F����u�׻��	�T�Z�����d�j9���� [����o}�c�L�W+� �ѩf�C:'�-Ĕ�cUTGҸ$��s��CWi��(G�����߳@7p����=k��e�T�A��{G�?O�[x�x��Ё��Y�l�yi�n���چv��@�2*oN5Nrh�q�����\K��3��������k�.���*���-6�/R�4%����	�L�oR���h��`i*��*3?�6�咰y��c#>���4|R/F<�p����s�Q".x� �+�������/�H�Q��e�yd	�+�LmW���n�g����4��:�R8�ܚ���)�b۾M�T���-|;�+��\�N�2e�Ӏ��/�R���6+lz�
;(�%C���8:���J��x�A]�(I�f-�3Q[�	���ƚ�Ų�q�p�c������4�'����ɏT�S92��r"�7�HtV���1Jg���`n��2�!h\��%9)�P���y{�r)��Υ�u�=�Tr��d�VQE`����t��ډ�,k��\�U*#Ĥr���4�4���R�{����C"+�7�bl��C������W�u���x��YJuR���a��F�\�O�#T�l�20ȅ���v�۝%:D=C{s�� ��z���|�n���MRҩ�83p;��^6�bnHf�r�� L��c|]!W'�@�l<� ;{r	�6N��᫥rzCe�d��֒v���D+��\�U�[�Ⱥ'�%j���s℠�W�`5/=:�Ս�F��;
 �AZI4��r�~kU+�Iٓ��H(Z�@�޻�N����Y���@�ȁ�W2V7���BKpP��G����Z&(>�`a����q�"��j��\��@����k��$\T��;��0m ,���i -pP�W���Y�L_C~�O&?�&M�A�Q�O���x}�[±���ًT�Y�׆���ԉ/[vE�<��v�����*�B��)�S| ���G�_�8���:죠H��6��c ���n�N���`��E��i��C��?J.6Z� f1��o�}�q�!�,�\3�����
�F����=Yt~�����D1	|�Vs�3�m��<wmy��2�_c-}����	}�soKD:F� ��_b��~�vfT~�*j S��/1��wg/>"�[3��@�c
r�:$��vy#��Ԝ��b�R!���[��OZ�}O\��dE��,#4�֋*��ǥӹM��:��'\Hԣ(6/kb��gМ�T�]C��O�l����g�8�VZ�ۦ�[�2���H� ���j>+�#����V_5���ە�22�^{�>4��;��     ��S [�� ѝ��ϝL-��g�    YZ