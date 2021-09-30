#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3126836238"
MD5="94f39d0c2fac21689100045337b5adf0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23928"
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
	echo Date of packaging: Thu Sep 30 18:42:34 -03 2021
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
�7zXZ  �ִF !   �X����]5] �}��1Dd]����P�t�D�|�?��3@��G���|Y'��D���I	�EQ�L��}[G���eph�[���ic�q��I�o�����B�g'1d��A�,�P�p�����LJ+�Tj|�>t���Y�݌��J?MX����`�'-��g^�}:�<ˤ-���������� ]�b�}2[�n"U�D�b��?~$��Z�_��}ҽfz\�'�N��
�^���i^6�����F>'6ED��rjC2����rw� 8�Γ��.����.�=m�q۾{%���	J�`���~�`_q���ny(�k?Ax��3���\�?�>�"�1:��ɡg���LR-L�%د��\�>�_5-	2SbAN�IUU��Wus�͓���j�%�!��e�
��]�wqRĦw��cMn%�pz ���ʧx�Cc��^�)�z(<�lUV%j��1
�/���F^T�
,=�cc�E�ǒd�|
�%�~ фPg��}��ZG,�h���u90h���j��0Lm��/�^Q/��6Bl�Y�Q�+�����qc� ��	 � �������|��]�gF,&3��l/E\��x�z���JHfP�����\�#�����RD���
�L��8���&�(�@�Z8!�:R:�������c�����̈́�M�߲t�=���[��EqW-9�0 ��)�R��劕�Z��Q�|wF>Y8s�Dy�ޑ�]�b+K������C����λ��ܿ#T�m�Ȧ�UC�����
䁋��7<~����C�L�e���Gc���`0S^�{�X%��㳯$��u�o-2�@�?6�Qʛ����y}N��
� ���l��	 a&�&ߋ�҂���6>�C`]]ЧBR��(㶂�'K]����p��҉Z|��#%�֬�8O�D�%f�DUZ���.��_� ã7$���\\�3Q� �/0(�wԮ3�6:a�?(���u�i�/���8�\������y���^�@e\�~5��	�{u��Lg\�(&6$P����u��l��8�������=��=O�D�@�\�f�u;=<wPR���k�r�k4'�j������&���Eo��gP{�)���@Uɑ�d4l��Й�����4��_\m$�塹��XX���t����V#]�V,��	�����P4qP������=�L�9c����|uZv{��5A���|1�)�&
����Hl�Ļ�`�t5�;@�Ѱ�����R��g������bI���ɀ�c[�mz�����c��%Z�W=M�������ܐn\y�1�'<�V� T6X,�Ǽ�����Oӧ	㛺_a'q@����.he�����	��i����/"�(��k `�bX�[(��ߠ��M�-?�Q� ��T\��F����+�%@��f5�E�Ә:�tݝ\B��ٝ9*Z 1�{��,X��ʨ��(dr��p���:T�?�2��n���I4b32r£%�o}K\��d"*�AN�������h%��PEn�q�ƴ�]ٮ�#��Z7^�bRȃ���������Ƨ8]Y�ݾ�I�.ƺ�ʹ5���/Rl��,@)�Ċ��$�nȡƷM�,A�3z�C����������
�W�q�2}� '7���(�E�4�/.j�����wf��u,#@���qD���C�	��Y=gV�\�袌.��7A$s�h�����Ô���`SFUc��XB,��oʻp23���Ud����Ԝ&�ϝ�l0\����HGǃ���`�7R���hl_}�]˝�ZĒ	=0���(�(�&�qp{)Y�|_l�v�DK,�y�s`�q��ʵ��ӥ�5+ZQK_�<?������6X�%=y-��|��r_<��ek7�W�}�y�:�L�|��e�Ô���陎�������iqs���
3�|iڑ�Qh/Q�>������^���� 7����������t�D�>"d�t�pO��5�,�7i�����3��J Xq}�rY�{�sUk���TN�p�IT3�����|�|k�s��\�:EVP��5~@l+jEG<��Olۜ�:n�w����2�<ָH��xUE��|1��٠C�m��+LrW��߿�u�.vTsIq��I�0P��v�=�-�M�r����K�C-we����+��K�`�Ew�b�=D�8���f�����j[k���I��,�H�4#�D�M_��iL�w��Q�IF���l�
�ۑ�`X(v&�~�E��4\՞^d`.�Z�;{[P~�z�0*�Ώ1{�1����Zjh��2f��7�RE�����b��և�8���Џ�ft�Ά���B�y�SH��T����m�6��=0<,=*����l�$̸��	p�\�.��b�� i:� �Ԓ*�[ҳS�J�;�9`�4si�Hֶ#z��	w��k
�Uy)�<l� �ڒ.Ì(ǆ�@,~��y�;F����)��eWeζo�5GS3���FH늒źmB#�|]2�n6��pb� �>W�t�?�kZG��0(mt'�o5?�ʐ���_�w�nk!�Ջ��mx�c�G�:S��=���Fvp YG0��
zo�D��gRu�[��6�°��t}�R�D���Z�/x�3sJ,�L#|8��!*����+����Ч�cI�����~Z������vzx�j��]�����VYTٔ�B�7ܝs����b�w��}�S Η���&x���Wlϊ�яnW�J�(Yo �r�T�k�j��`B*j��qy���d�ww�힪=����/����$}!uoے9hC��,�|�&�ٔK�d����0�
K����=0���1�w��|8o��x��"�-�cٳ�%������?��xa�v�(p	�T��C��>*�ḡ0@�h.�?�1:��WP�����T�_w�5�(C�u��%8=D_XxJt�t�0����du��ë��ӊKh�ԣr :��]��lF��w�9/	nt�!����,�r(�h�$@��[����;'	��4sj�N*�(Ǯ#yF�]um1��)��&��	B��^��Dӆ#t<�XzS��Ա���7�mj����݋�!zP��#�a)eb<�ٝ��ʤP�nh���:�lagww��
1��r��L>��e9E-�|�>�í�R�UX�U	�f��_�z��3[�H���RѧT�Jx�v�A�װ&�۩���򨷗�[��N�8= �C�����4y���04�OR��P��!&��7Aְ��؂%�#g����t���������Y�E�GB0�����*Vm���o���J�@n����Kw3.�I���χF���A�\�����l/+�/�[?��.zT�Z�xx�ѣ}Wy�dy��.��Z�?��Xy���`�yA��T��m/B���gM{�98�e�h�RZ��O�8�}Հo������յ&��CS	Gr]f4�����!��iL�*>�  ���[!y����)�f�K"�į�1���: �1;�O^�+�LX.P�0�h��s��p)�W`�q��g�u>*ׄ�1�t�5�m~'��7T��]y��y�� \��~{�9�붲��(�H��T@�|�*�v�ĩJ�C��!7�%����N�Z��o[�߀�Z���
�:���sJ"�C�8�G�9�m:fZ��a|m�!?�X�8�*_^���Ү��7�D�����A�؈ml ��&u/�j��h�+��h^ҳ��� �i4�1z<?rV�3ʚ��C�-�����N(@:�]�����-��d�����WP����->[M �1��XU*��=�g��L�X�{��䣅��",s3i��fy?��vwmWz�C|�#8��ι�;3�G��N�d!É�LA���������o���rSL/I?�/Rk�Z�xE�}�)k+)�)�7-��w��ՠ��6����7������9��Q}G�������t���&B\���wS{	��$�lxY�h�Y���<���CX�h�%c1g��H�O�f��C{W�p��f'����� �:�^@�`�sY6�"������em	��/+Xm��|��&�+C�����4R��J�$wї�<��+��j�c�?{U��1�Gb��I�Ao��:��$��X�V�
��=p�IJ׾���O�p	�\�Y�7A�V\DW�'�c��� F|�&צhQ16Cpz��p᧸���=F�<�i]n	l҇<|��o�o��_�yv���U�����R�!�!eV4&�P��җ2�@�y  �p�ht���ĸ}�P^��Hk|��G¡dߵ����E��4�~D�7?���c�t�
���&�ZA�L���<�ē@���f���W�����y}B���+�1���)x��X��K�qB-O䍩]��Ǽ��@�b��������^ٖc��J�}H��r����(�_t�����д������'cB4q�O�z�f:�qq��H�65�E@�����4��7�iV�j�[���#S���鞀��[C�w�lo�ճ+�8	���#:���� �D��өG>��M-��l��{�:]ҕJs��DU\��an�*S*�^�� �E�����m^1����YS�������{�k���O�a����7`���΅���J�X:��\�;f��H_���X��w)�Bw��K�w����#���y%j�$:L��:����PH��`/E��yC?�F�,�@8	Ó���7�ՈٹaۺI[�d*k�J�w<�!��+�3���;Ha���+�#YH�T�ׂC�������acT��=��h�K��d����&O�JY0�z���b�J��Տ�&���2�Dt�f�-$rY�'
��I�1wt���Y����/�O�ޜ������wэ�4Y�m�m�y*֬��|������̛4w�h��HϾMt6�1�^���|80�/�Yn�@
qo��Ȱ>���<�{�x�^1,�����H�
���- R�k�4¿r\]����_�a�4�Dچ8'���6	��^K�eAD_B��=$��4BpG:��[2��'�E4n�f=oԾ[�N{S�,/���L�u�YVtOč�N�ï٣�!.Z�� �¬�5���ԝ50�w"iÿ�VC3��X�ܭ����,Y�?�&����+"�dㄣ���2Z��p�Z��Cʢ�x�<aP$�V�J�5 ��r��i;1?q.2?K��1dCK�]'��?/m0U�� g!<���'}ߦD�:��ct��MF(���������i9G�hǟ��pL���5"�rj��W��LG�(a�K�X#��B��XH�KN���!L;��̵"ݧe?3*��ʊ ML���G'G4f���Z�N���{1���>�հQ%I��F�}�7��D�k=��������V����	T4�<L���h�*4�ߠ��KZm�X��p�����c�"���;*ԡ��j ��a��-�KX�>���,Ņ�
�o�K�Nj$�F���	��jr\yn��g4�J�IԒ�,�軶�٨I �a�m��Wb���SYsMdB�.	�!� X����)�,΁��,+�Q	��F�Xyp� o_�&�8��ҩ�3�cs3\[9_��m�_"%/.ì^�@�v�Iob�G�����xX���X���̟< ��y�쾓zBV�H��jJ�Y�Z+VH�g�-���oRh�GY=��A�3H�p�^{f��I9p���!,&.��bر�}l��D�?s��)�_�Ogб�� �8a��
U��� �n��zF(��7��yU���kxm�(?r���^���C�q��I�4�9uz��7�g��\
���!��"|�րDҌ��*��Mɑ-��M�5Jv�FH�o�<g4b�6�}��c�eh����M�kn����׾<B����{؋Ui��r�i���F��~u�hv��Xc:aD�}���"}������V�:lK�.��@a�J�)���UN��'���a�g���"� ���I��hϗ{<N�������A�����m���󰅘\�1,rw��Y�&)~I�y�M`��t=0��_ſ/3��-������e��C�>�1����63�<��qSm���⧓j8FsL�@�Z���_���{�H�_\��/���o���,]��ы��y�y�*�kj�P�� 
Er���ɝ���F��M��}$�V�f-z3yG�dܺGoc"��S2	�}µp�*nI����"�@�&V��Д�w�ƺ����Γ�,F�^k��kIa��'������M?��I��r�9^�C}.Y]��9�ۢ �Qu.ؙ��٬F�s�������ψ��l�d9K��bi�L}��uG��[)��,3�����ى,����f^up�>�1�"4|Sdx���-�8�FL���u��[�,;�j�� 6�m�6��?6;��z�M�5s�ĵ�\�J�̗�W&����'�txqaI�Dj�����L�rM#��N7zeP��l`�)�� �,�TS����h ���ִB�ہ��*�X��2/)+4�h��}QG��H�Xӯ���.WM-�;W5�^p��;
��|�F��#V��!��EP졌_�A�M��^y�`$ip���-�~����^�m�P�۞V�THJ
A�c$���i��k7g!o�"��a�w]�k�,\Z�D�.��t�Tc�R��&/��)M(|�{t� ��R<��+h�pP�JQ�mg�.m��2������2�¡���ZW��
ϒ��b��nĶ/j1'�w���`E%旄:��ɫ-wino��(b�����,レ�+��L-�F�	I�9[���p��4��]Ǒ�W[7��~~��W֒��܋��%T�t�
�}�˕Iuiy��I.��d��5��*+ Tc�(�q����ΝH�:���ݽ��Æ�,ʴ��eSZ��7rQ���ķ�ƈ~l/Aq94v:$8VA��QԫZ��ɖu�2�vz.�z�����\u��䤀B/�}��@F��q���Eչئ5{|�7W�8&�B�۳j�G�:J�b����w�ir�[v��:L��ާ��t���@�&^୽��Xs���;��c��
P��w|�+};9�BM�"BS+���\��ąU7��������i	/���Ƿ1� Ց��Z�?�K�N� ��~�W��hS�����|-�3�,�<9�ѥ��y�0��PH�L2�k�h�Y�;���7��s-�հe��-���m�/4���V��ɬ!K����P�f�H��3�z����F{��D-=)�:���-%�gB�B�c���֫T(=��.q���C.�'��/@j�~��Ptpե�/:2^�ީJNv&�d�T������\;l�&�`!�ZU6`�z�&��w�H0��KC9��Ÿ�b{F�/����&o���p߀S��4���ý�_إ���ڳ�%�o�AO @vWl ��'��kL�\lj���"�Ҏ�`@ޥ��؞�Q���q�����-����<�}��B߬�-s��-����	ϵ��.�~��Uʷ�T˸u4�H���=�qS"�Ι5ʲ��O0�?а*F�.>����'��顈��(0Z���"�\��;D����o^��&M$)�S�m�O�A����AYI|m�9�rg�� (Q֍-�5�����"x���~!�c���WP�_+!�N�	�,�b��]��n����
� 1� �2>�C�<7MG�����I{�����c�y8ݗ�N�����zn�x�L����X5�����~��R��ԟ0��^�T��q���S�{�֊�u4sA��Ⴟ�E �s��5����O�F`��}�&z���� ;�Mg����°
�gS�b��EL�U���8K����c�d䗍)?D��1C���Ot����M�$��#�<���`
@X�7�=�zd��Y1R��X�����4�VVm7�;KVj���(,�JL� m�v�'�
Tg�A����M�J���z�w;�F@�|���@|m�8G�w�j����%��'h#f�����e�'��{H�k��`�2�����qx
��6�J�g���5�
�lCe�����a
�,�v2���L��6�u�ů^ �W3xd��PV�0�*��e�D�S~��7a�E��KM��ܙ��
;�>��!`��_�3�u�:�L�3I�^�˄�&�[������K	_2FFj�㢤`c�U��e ,�]��gl���6:��G�4;i�ތ��"0iL��ssmQ��|:�E���Ռy@�ꬑ���^җ��ҕ=��hI�I��)2��m�7x��1�YFл���T��5�P�=׍��8Jp1[ك��Jx^���M�R�A\{��P�0����B��s�����[�F��0@}^�5+�V�g��֍]����_k� *^��>mnD=��b�Ϳ���Ê�?��\9´���F�Ո��0�� ^���A>VѪ���l0����*���R�/*����f��r3}�o���i���|P�{<"�_x{�6�p"|�h�Q���T�p���^ׅ6��`���{�������7�X�?�&��ܖ�f;i��!�[M���5t�{�]z�G۷�]t󅼨I ��, E|��g�Y_|��u��g�Z�[s�z!׬)hA)�@
��~%���t�\�-�ij�ɦ+��������RQ�Xc6����M4l`*�?fM��Ǭ�C/�8�z[Ӹ̕1F���-eaO#cǇ��m$��Hz�����[��qd]��o�i�T"��9܋��̭�\g�)π�)�u�����&m��H��ܵ���V��ؤ"�����ct��9�M�L�z@F��Ɏ����/`�
��.�X)z���~�@��V�Ԇ/� ���C-!���5�������_c��͋Ѯu=������D�(��5yNʇ�=�N����G�����`hΩcFx�I����t�)4Ŗ�a=��W-.�Y��Q�={8=�+�������Е�������:�(�m����I"��Oh�O���R5�ק���go�-]=��Sjb�	��D��죴H=�P鈣��6����C�1�LN��XQN�ᇨG��>�4�)����0������F���ԇ(��'��l��.To�Q^�������YJd/�,d!�+F��`zU�6_�u���q�����(���.���V|�-֋rTX$���χ�u3�bRXÇ�R�[W�f�����5^�2UY7���g��������1�?�r���4ñ�^{��(Qg'�!��꡺'�X�� ��2�K�o�Wo�q��,��!o�F��ie�"G�/ơ�c�X��Ϊ?y�7�g�"���NSJ�z�a� Ym�$�\���|ܻ��Zc�`�* +�l��9�H((��œ,���y�+���T@pq_�f21Ct�*���7V~����mZU�
.Dw����@�N~V�l}VNl3_A�\����l���D�!V]�p<N� ��9<T�;5w��ֻ\Ϛ<Z�J�*LH-�W"r�W�h����M�g�P�P���!���G@r0�(����P�����|lw���Y������ls�Oa�%۔��|}��5��C3F��8�#͹������N�.l��U!� z�[x�~��V;a�:[E&��'�y".v�
�T�-���⑟��j�WF��xN��x�;e1�{�Z�i�W0p�&�d�V{Ӿ2p�XL+�AY��z'p�LQ�Î���:�wӠ��q>VH��UgYÀ9�V"|}�[�ot�?�+��&�!��Řz��-x��dL8��.��d闈�K?�:ĠO�L?�v�a�P�1lt4S0���8��gGXɞm~LH�N&�o�|(9���������uQ �����.R���!�Ýs��O0��Q���-��zc���P��"n^ƞ�1��s���q����|����DKu�
ւYA\pם��p�	:ڣ��giNK".��%����ȝ����-:�w�P��#s�4)p�4������{�g'X�k��إ�!�G\杞��6�� ����{�й����#�p�b����a�+��4�vK�[�Hs��a��N	���f�r#�cҞ�G��CV����E�y
����$+��W���� sz;�,�0p��إ��~�.[<���w��Ig¿��Mx�;wi}���k�6�1���g�G�t�o�2@�5im����*��GV5`N̊Uи�G���q:ٲ*�H�9�h`�C�����u`�	�6�N$�ł�ӆ���T6����C﫛c�Wτ@�T��-�n5}m}G�L��~����t0Q���ńF �?�mB�y���+���Z�!��t�XJ�ʯ�k���.��e|�`���{­;�a0��bA��<5�<$C�̻k�鱸����A�Yg���'����J{�i.�u���E�!�U����lD�:�z�[V�m�8�'��(�� �`���6��u����؝L�&�V���C"MjL�-̖��"���D}�;ɑ�'�����e��Y�A�v���	�xYt-�vmߣ�r|�� ���;�UN�ȫ�����v�5�u�����g���yS�"�_��f̆^>�DA@H�B�>�^	��]f�������fX�N�t���L����N�v�(9�2�4��J����*9����Y��_�/,�}����m��Ɛ5~�z��ڧɨ
Z|P+�F�u�y�7���_����~���o�7d������x��oq���M�l\�T�[JQ_s�*�����3����JQ9�F����r�1�q�_	�`%\��V�s���6�Ϸb�ͫe��I~��Q��q�ca�ˤ��.�8�&��I�ze��"��)*�pO}�B]���L�.b����=>x�Xw�d��H��1���P*	���F3�]�;��q�WV��Tu�r~������al�w	ņ�Y75��#[T�.B���B\���F�x���et���d�iT�T�,'�e��@��{���O�C}_�Ƥ�D�)w*�{��ҜX
��L�r?rKj���ً�sM=Ԋ���Q^��n-�0�<F��+���g��u�)�`�7��^�*���|Z#%��Ĥ��<��1�P��~�W��,=ri�>�����[9�P��^Qj!@x�Q
��S�����R%���f����n���gQB
�H��7�-��"��$���o�B��b��>Hrʎ�lݗ��J@���&�mz�|wwq	����$��!�\ʤ`NZ^�⍘�'�S.K��D��[u��]W�f�5�I#q�����CRR\f�Y2������8�>l���kbEg�aa����@{���ɿA�˂��M
M�����J�,���Ʀ/�Wz�HP��B�i���g6*���05�@���3q�F�0sN����euS_x;��N�ŧ�_q(�)E�CW8��{EF���Ci?��Q��t ������*zo��,J�$�{y	���MU�yV�"�9
����a&Hm��1�GN<P#�Vh��WG��&2zh�� ��=�����]����zP��s���- l����~٬��e��F�_t�I�2ͲT��
3p�@.N2Ԗ��R��rzJ����ޣt���9�YC���W3�����4��Ny�?��������6���v�Cn�f!�9ReT!�-����9��)B�4�7`@���nx��\�G�/��F��0�RDb�	�
D'��H*�	��hC=�B�/<�>X�F
չn>�e�AZ��,��q�R�.hIn�:w�U�'D�Ղ���D�~��6;c�-��\g�������籦ܝ��;෸�zu�ǉ���y��VN-#����7�Ѫ�.g�}��Gʧw����M�h*�K}��
|XC��\�KQc�e0�ro��[�L�hx�bn�~��¡g�9��b�~ ނ/E����7�"ݤ)E�$SK~f^��z��#Jk\Ճ�!��<���P�Bk�.�	bL���l��7o���۔��4Ey�b9���T�w9:P���]	i��#��L��0�(鳔��,Vrv�]�-Dњ)ۧ�=����H��zȿ�q;�#����{"�$Lbg˔]�}̢�:cw T��ǭ�\�E�4�9��Z)ie�7¸��K��OkBDچ1����f�}w���b���9���~�`�l��f��z�}�����~4�\V��S�FU��u���"'��%}+�ZUǨ��b/���tl(v�;��;� �8%��k�%Zs?&Q 6ӄ��-']��=��oa:Y9ս/���e��x�7���zUcK��%�n����"�D��+��g��^Z��GQ���d:4�r�>�~�k|��ȡ*�&/-^�k����B��|����8v�,��W�Ji��?��ѱ��������K�8�B.�%��W��D���� ����*]7�_'E�L�?�e����>�pt�r>=񜟬�l�XF���q��X��
��鿷a/#��N�;>U�Ob�fa�ޔ1�����SG�߿ ��yO�Jc`�Q����I������Jބ�2���1cT34$eC�W�L"�j`|�˱���C?S��E�Ö.;ּ-�zQ4g��{�q�x���O8��ۂ-:u�Z[����	9=M~ō׃��@ )#�}*a�R�|,�4�����Q���o���s�-����W8�Bn0��\�����x���h�^�Ȩ���o�(��������WE6WD�՞����q8��x��ǝС�
��
�zP���a���@��_LC�ݯ��2=7�|���'�-{����s� y�����AXw&a[�r[4P�X�
LD�(?���EF���B�3V�##uGq��\I9�S�&6@�,����K'�ī���X���N�i�q� �=g�*��iX�xH�we�_ �Y֣�S�ML�^��S��`�a]E�!��ێ��R8G+]�;���O��H$w"�^i��I
.�P�tT����(*.M39ϔH��$�����푆�e���8=�l0��)~��$�A�.���_hpm��X,�5��)��V�KM [L���OV�/7׏������d�����7�Qn�f����>�+��%���Vr�e��^t�f�-N�Rdn)�rG�	�u���92%���b@�F(\@}��&�Y�A��;+v����4�d:s�t��c���.��]��"q�X�X��uy��w�a˫��V�EMeȴ}�����ӝy/��sEm�G\B�)�,�q����̆F�\%�pYy����w���ANDV��#��A�t��;KJ�~;;N�v3E�x��3�����--ۓ5�U�d��܅)bX}r���a�A��fGј4�J|��3F�-���d��-�ֱ{�&gw�����y���g�2���k������ϲ�b��m�;�F_~j�"�V"�;�����5LLJ/����m�3��ᶼX��돃�Klo_��Ѣ��J�֭$�V��ѥ:1��*��3:�7�:oq��S�Cb�����h��al�F�+�I�_fe-8�+2!�m�z��L����O���ȏX157�F`���D�P6����@vZR8��c"6���p�����F�{����W�� �����>fh	�L�11U��rF�Q���H�R����"bN 4~Kqݔ����Nejس�-u*��Xw�l�b@=�PI�i����$I K$6�k'�L}��<7�J��iHj��~�؇��+�3>6Ӝ��<�䙁s�B�D��C�v�A�y���y��o#��w�z*<�S��J�}'s���w��#�۾��e.0 S	$���P��C��p��bZ)dG\;q�ˬ �Y�:��B���ȷ�NI�,/�t�mgDTd^�9�rf(�.8N*%�O!A�=3:�ZF9��@K6�ڵBW~�V���n
��c^��o�?
mK�e��[������MNB�V�6�05�+�m'�`��}����rq��&O�р�t�H��Ahj����S�`j�T���D��/C�Z�RCf�]�#�}�4�]�w��P�
(�A��T��[��\�;�2g�=����m�� ���I���F���Ӽ<����Fl��[ycH�Λ�D/%��-u�k:�pi���j�qi�9�>aZ4�ږ�ڌ�$դ��a����߯?[)�Ԗ�alݣH�������/��֏�uF��(��%��
o�u���}޿y5C�7'4�_3`�h��E�&�m�Ş���nD����%���w���PH'�#8���Ѫ�ii����q/]���(4�Xw>��@�wɺ^���W���9��^
� ot�J{8��t�XjJ�3�	�p}]>�K�=��/m�I�\�b!)!��2�(�8�a�9�>B5vn$pf"/Ժץj����e��k�]9���F��(j��_J�>!��ug�e��޼���A��č7��}e��^֒��(eJ#m�ӶNCҺl�nXN��\�M9ئ�t1���l�v���`��N��N�_xCOA5{Oe_/]�^<Kw�oux�Ⱦ�����}�/��|hL�p:9B�g�Th��C<j_r���4�:1�7V�k�\y�n�:<����l�� Kӵ��o�$@���k4t�ƙ*l1u�f�H�c6����������|���)�A��_֬J���{K��R����9���s�M|�91X����od�Ř�,�0q�)U����~<����Ns��wx��U��?��kZ_�O��Z���@7f���C0�7�@~]OE��ƻQ(�3� fr�_�3t@Vش���>�i\���P���﫸�W����|���7��J�s4�|�kE���sBO��E<-�\{�i�bť��	�I��&��WQ�'4.߸��Q.G됆C�D��|����mK*?��׃K:��
�T�UEA���!]����r�Z5���������>F�r�Ξ����[�(����hR����E���N0Y��: q@�v��9��@<*@�A��ߴ6~��S�}N)���`7�t�!�X��djFv�VQ�m�R:�u\�x����t�,/�c,�;�1Ŕ���:�p�6��9b�����lK�����a3��8%K�I���/�N(��}Y��6O
EӼf��A�ߤZɆ�N�����dQ~������V���eEz���X:�	�ns�ҕ-�߲�����R�	[:���,�π�p�R��߻�Z�,������ُ3����!�0����!K%�Ͼ����L�y�=	���k���qH���"�<9� �ih�� �
ۜ��&�,ĸ�e�q�u�2����I�����и��6R�X4Ci�gX"�5e��G�I����vo�J֙ai�ݬ�[��#���ր�3y�`S+�ʔ�=�ݒʈ��4H�<>H԰��J�5�Lrl�����u|V��ǔCF[��o�{G��\�h��vŽ݌�㞪45��"C2+��wp *��~D ����h%#�	<�,�Ͳ���tu2^<��W&�l[u��F7��Q���L�<6���NB�AN��rFB���/%]��������
S��pqn?���Z,�Qq#a/��k�<�U���q�ө$h�6�X=H.��$4���-	C[��jO�o��<��@�����֍�MlP��,+�Vժ�����)<��QC��?�#�ב���>L��-�[�
)�����m�ô��o��E����`ғ1�?DO�1#��C�y!�������op�vPNſ�P��l�
�n��A>V�}><w���>E����m��3Ye��vG�	��n��,�� ]���&�����5za��7S��s����\�a�n�v|�xs��$saS�ܜ�f��T�k��q�`�}[P=�@�����������Y@��>r�2����x�����I�ՒܘŲ��)�n��ǔ�=��;���ӡ�DPFD\e�gPpt&�3���{H^#uE� 0��\\6�l�ڄ�2,�k����kV�]DZ���*g7��XIep�Ȣw��8<HJ�������v�����& �����w���'=�Ϥ����&�9����b���,�'�ٚ|`_7ٵ�_�&i�淡O,��+����/2��J�'�O;��CI�کv��,�8b�+��ږ���/��9�a�'�	���ִji��H������++uOms�me�9#;����X,"�31�p@�ju8���g��wQ܀�A�u�o�V������-J
G�`/Z�գ����ǅ��9�ιu[��]�w�33\�=�@$&�60�N�T���:ۧ�?��y�u$��`��N�1B��H�׆�$ӌ]m�0�,�s��v�K{e������"��Lu
&
?�L�w�"�V�}qS���T�=*����i���N����ɅӦ7p\sy?��"�:>z�R"{D*������� ;�b	��;�_�D GSf.���aզ^0�yd�Js���L�S\�d�U�^�"�]Z���3;��	W��n���Ջ ev�
)�4����tׂ��o��P��OD��K-�k��8�p�.���MW���Ok�;�=�ORkM�"{��^�<J661�����w��ҷh'��J�\h�����(�m��ـ�g�J�f�����.�.�����,��֌E��ʧ6U>��Z�y�����4��"&v]z��>PdY�j3J��lkf�NqCZ}�'�Wn��R�:���D^���I���i.&殇�vW���\t�l�҅p�(��c<羠�_��"�Gd�5�y���%]OY���MMշ�}�b<��e�� �g8��@��$Q�{o��YJ��0@�6�;����I��9U�,ܹ�ʰ�Fv�|eoK%��:g�ڕ̬s���Y��l���.L��Bϣ�>����2��G�Sa%��	��<�2�T�ke'-Hr������6��)�kc3]xCl��2OD �FD-`)ӟMήť�+d��uB�oy�V4���2�����q)��>�a�WJ�=?����v[���%}��&́[>
	%>�R�s��?wB��Ҋr���=+{b���C�:�f�מZ;q�n\��A�v�KC���B��|S��*���鳀������S�5B]��O����Ȋ�}͂���,^��Բ���O�������:�
� ��؉Ч�Ҿ(*
=�!�t��lľKx��H���'�E�މ�Z� ��|+崌��lb��v�	צ*��$-�Njکa��\�0tiQu^�Q���A��n�W���h�Mr��'�Fg)+a�/���DtJz�D��w?_��E�������O?�|�v�{�!"��\�V�JZ��'Y�>@n��c��ƙ�`l@�J�--���o��o�=Bv��z�nC(5uD��N�[�����Y��.�69����8;H�/���d��?	�N,�	�9��~�p\�7�iL���PgƅhBfò/�6m���~�Q�E��P����?�R�<���`<�7�U�m�jV��Ѷ�Q�tpwY{��|�m�^�73�Gύ!Q� �wYA��� ��Ғ�ȡ'F�*U�����Fe�(f��0��ҋ6ɥ4й�+�ɭ�"��A������X��kE2���i�@*�����w��gy;l���?�Am�f���*W��\��̠6!T_����/�CMn�p���}l�<���!�}�:>|-FN�ZYFsp�x � ��8�/�L�m\���k��0�,1�������F|fW]I%&�ܓ��h�i �^3����[7� ����6kSj�%?ڵz�A��\ς a��7�~�v9�_��Z�����L ��<tvl�>Ԣ����e��!�~��=�BP샰�Y�gJ�ޜ0�����Y��u<�ơ�^��ER��x�C��a�ݰ��̐>U#��?����}Zz{s��i�k �V��5袑�4����`cJ7�����N�;z.{��w�j<�g���%I�S���b�?�r���/K{�Z������\r���A	?���2`o&�xt�c�5@ZD�g�����~q�Ѯ��Rx�ՠ�P�#2T�>�͡���4<������vc��,P�ׅm�9Q*����h�"��Z��i<����A%�]�@����������:"����{������dO�RW�JQ�;8Z��6�=�_Q�tם���2���Q<<$Po�|y ���{�e��䯗Kj��3_���(���,�A�W�1�r�33C/�CgR�p��`������;�����2Vo,�7���$� �6M1��s~����K�a��!���'��$s*����zV���i�P)��s�� ���<�D�nC�AR?AI&"�"�h�(�B5+��K_�r����#�IG�6@��BG��9*�J�"�l�=Hܬ���F�����	�.��d�&p�`=��i�.��p}_���}V�y�*bJIX���m��d����d�6�*I���`k'�P��>�g�n��^��A>n9Ǹ~ҁ�3[J��uCm�+XM_%�P\E �k�9üs�vv qP���`�_ώ�3w5�44�c,�^Jt��N�QԶ�I{MɼH�:��}E�}�����\�;��D@�C���~�h�JH�Bh��e�pV��{gAtU�cin��Ԑ
Xa��[�����Ȳv�-�B@���h�������B�I��_��<q��y�H24��
�� �p���M�
�{�(|=e�}*������V9��6RU-�J�p�?j[ܧ��	,@�b郠��+��8�N�����߼#���,h�mĄ�[Ov}�k�V�W�2�j���=O�
���J+������b\�i���YC7G���l��	��&���ܿQ���{���릛�82�$&l�s(�Vr �w�FE��9��ܾ�H�$J�!�[�5�BE\��G�A���w���$���8��C�dᤆ�sV�7p�T~���Ռ��Rx�o���ɞ�)�R�+]I�y^[�qS�������g�����1�F�%�+���'	����T9��l�������[�(�������
HE�=�H��n�.?��{c�M�v67�0��cWL�I��`�F��5=�qö���fp6�8ܜ��-�ńg���*��X�!#4@T5f��+�P�� ��6�?�i���yZ�0(������if9��D��=��V�ܦ2����;J��gY�N&�x���%:����E݊Y�8A�i�<�YI�u��9��ݲǿ%h`���M����Hآ���p�;/����jsk�J���,/[��?v��i��.6T �6��ug����� �7�P2�!�P�Q記ٮzH���
fa���2B�O9A�v��7�/G�;�?w�1�ڞ&P[<��(C	`���(6j����ï��+��B�)�F,kr����X� *P��7���uށ^� ׅF2�"~k8&T	uI;����j$\��f��q��cr�R��]��Xb�W�8��~\��l��1ykOpP>�TL�����\��^���C��oqO�h�|E�����+���5����������~��E	�5u��%o�f/v
T,�������(@�bK�m�)����-����&2图c�ӻ�<�ٯ�����ǖ�ؾ$iEFn�
�TՀs�߅�\�W.��п�O�4�Z��Vͨ�E�vS����Au$��p��j�*��J����I ~�?H���8e��zi��i �)=ǰ&8�5�h�����N�	����g.�_P9:IJVz��u���D�-���f�F�2Q�&���O�~�i��������:�J�ER�@8����ƴ<.��=�tÌ�dmtS�4_�
I׷���FMԢ]����ɎɹvJ�Q�ѷ��]Ax��j �o���
R��<�\*�v z�z���
^v&�\'���d�@&C J�Y�;P��)�)o%�w�v�������aN�nz#C�)'���Z��_���$r�-���1�!���s�4TU��I�hu�S�O|5Q-��$q/�C�)��i����\"����Q�/+�VX�G�_���S�W��J;��1�_x�Wx-�L���S=�~O�R�����_��>_1�9%��`g�o}{����%.-��5��8�)��Bɟ���ߓ��}Cz�/^B��(=~n�a|	)��`��)��.���¿���dl�&T�������ns�
�IE�ى�k�8�K��:�>�۞};�_�� J�����ml��g��`po�K�r�b����{X���������hs������!����h��wj-���c��:V�.@Ũ�bkr�
�`{����w�x�ҽ��U���x��E�s������@��tL<XM�M���i�\/��F۔[�U|/#컜'�:�Rt��RC�+�2��pt���-�����A`��Lh��^:�.���ǵ����ͭ|���'�5�[C��A�)	,��T�.��d�K��/��,��F�G}*��4�����.ZMt/�s�A�F�TT[���n=L�����(�x�}3�e��M����{��m���
)�U.�|[�cH�zSd,��୓���(��5�<�2��4ON9��6�(���h�,���߼S���G[����i��9dK����L���z5������v�ҭ���4�C՘��-(p	�(ĝPH��{"�������n����hZ�U�[C����V��Bϛމ��a��{�)F �njp)�}� ������������#
E�*�]�Q����$ڸ}*�����ҵ3��Wg?��^e�X�C��� �)v�Kl���S�`!Y��;8o'z�c<I�-��'�-�-��U�2��0�H�g@�r�Dj�f�L8Sn[�sy>�w��ϔ����}"���9�@�d�?ho�� %�F����mŝ���&
6P�o�6����Ώ�	��9�b/J/|n�DU�Mp���)22#�	x4r�x��x�"���J~c��������[Rz,4k~�DY�ü۔�r�7�t>;M��>� ���k!`i�r��bH�ob�U��Y���_gYDXfe�|��W�jc�渓�D��,�B�#�!�~l�<	(Y����Z?�
���y�/R�X���e� u�D'��_uq��M�[��L�ٜ�ٌID�m~�2��%٪�U��k$��J�*�4B$��K#��Y�2"�������7�;צ��g����VnU��S�IڃG�|o`�\`��fJ��M �߶�8@�������'r�הd_�Ŝ�WA1y��'����8R;�K�<��y�[$	x�zd,L1��~\���M[_,�I�!�O$s��֗Ɖ�"������y?wR�Jm�1fS:�	:ӕ���lw�&fß��!�Eֶ��ti ���ҥ$��U�ˋ(�#NlHK�_�Yϡk�&:�Z�Yp�~���J�֢��̏@���-C$�G�?�Z��H�.J����cCu�W����N?9���X����\l��Խ�7^ΐ�ʴ�:����G5C��lq���-��'�g�f�����b"�a_<
�f�������QFꉣ'����7g(��}����8�����G7���|ו��h����e7�^�_0kƋ~�.�����"���4�C�-�6�^��(�K�j���4� �X��k��&��&�(�O������3�KC(Ɲ��]���YP�eN���B+r�ұ�[ }L��Fg/j,��
]�g"><��W&i��N���X�!�)��]��>� b��[�y<�P�D3��C�����Q$���ޣ%EԢ��Q�»��k�|m����a�4�]�g��@�.IX���k�x��P��њd=隌��g�.�:s:*�5T��qo�q�̧�]7w�`��`G�������=Q��Lv}8�TbYE�.�T�����\z�pl����:�i��1	l�fXk�P�Ȍ'��Zxx- ����ɟF����5<�>Hެ�]b7�d2h��٢Y�����z�:�"���`V�]I|�+��A��V��9b�C�AY%�B(U�v��J��_�}�4�c<����nk�� ��2�D�:jdv�Xn���0�wDaQ4ն����Jo�|���H�"\�"t�F��I�y�������� E@8jH�.����i�\�&x��g�Zi�*�1ꍂ�Z�[��2��u>�j�9~;�`1ƪ6U��#�4���l6~�{�{h���'覺����]k����)���f@)�UK�h���x����%{S j��w�CcǱ�	��}%�DZB�Y�"pV�q�����p�����"	 �m����uy��2>~m�scf�+�_[t�!ר���>����X�X�ϫl 6�ߣQ����k�����sy ~�-�-t�%���T��jp��|j�}�0��MOz�N%f4}l=���)��O����oMՎ6c�C;�45h�Eu��a&�x��E'#N"P�~��	[�^��J��uˮ32ߒد��6�����2���?��f��E���vf^��$����&:��*����X��+_��C�5�5��(��#X��FN����d��Xeb��̗	�.���#�j.�,3�C����X��Tv�s
W"�J5���kE���L��*9d��m�G�����d��L�Ls���p;hJ?N��C�,i�X*����%9�n\9�Vȯ�a��X��DG�=ʹ��}Gݯ�S+[�s��.8i�WneK�5�K��}��e� $��t��皤~�������g�����N)sO�Vy۔S����bj�\�'j��(Ƒr|�}��o��Բ�Bn0;]�o��od�\�Uy�R}۸�b��k	�)��b��c,-�S�|_�y�0�rjg�~FaG�;	���+�	7����C�[.���_��s���5�ϯ��ÎנA���C@腮\��d�;JȚM�E$���4�����Fk3P"�n�T��=B��l�lG�/����9N����K[����j�}����h���Qd\� �C�7 4VȆH������t�F� ro�� �
.vQ3��B?.G�3&=��F�E�J�]@�޸a<��}��ಚ�5��/�
�t8)ӪK�W'�hL͝�p�A�O��j]�]m���Q���z�pN�۟��Wt3���?8*�JQa�"/ey�&P��r�Z�ФG�4��z����2Q�E���	ǌ<�^�����&�x�9��-��7D/��i�O�C�������	|=�/�-�ۦ�<����O���h��8���N�9�A���D'��f���Ij�Ŗ�)�<1��}�`�&dΘ��b(�)�$*�ņtp���/:M���Q?=!B/�-M�^~���)[e���d7��ʒuW����sX�u�׷�~�V�e_e+;v��ǠG2���!~1�u��G�A�r=\�,o�I$Է�0�ƻ��kz[Й��o�U����/���W/+�>����>���!;^.�RՒ7�fz���AQi]�.�#�'�    ��*,�g Ѻ���5WL��g�    YZ