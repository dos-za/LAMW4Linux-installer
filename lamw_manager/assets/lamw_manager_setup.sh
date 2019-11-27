#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2015997461"
MD5="940b2e1dca7cf508c2f20edd47a3a15e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21126"
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
	echo Date of packaging: Tue Nov 26 22:08:16 -03 2019
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
� ���]�<�v�6��+>J��qZ��Nk��+˲�ƶt%9I7�ѡDHfL�\���z������Gȋ�� E�N�d��~X"0��u��������6~�?�^���ϓ����[;�{m}mcc�	�~�>̀�'���w�����S�sv9���9���d��6����������=���T��G���Lv�T�/��*�3מӀٖiQ2�L���3��Q�1摧gfbV�jӋFwIlSwLIӛ�t)�W��sw�Z}���T`�.Y_�׷�������q`�!B�)QeiW�͈o!�&$�ޱP�}�8y�s�:��@�Lr��O2����C��(9uv�~N*��������ّ��<6zG}C�=S�\���7l����cc�dAs���5m?뷆ݗ�7�f6W�t���a�M{�57a��~���PQ�R5g} V�G��:���w��*���%�[���@�ע��{�s�R)'����K jk�:nr�����[�Lle9�k��%�+��� ȷf��f���sʷFA1v�0t'�-�hЙh;�=]�!J%��|=]{�x��"�l9���&l����5���{Y���6G� g�mևv�@��͐�4����|�W2�/�ſ���nѹ�F�S]��� k�n�b*�b��Tu|�Cǜ2>�K/�a@:N����(�<�]˨m���=�!�5�E�% j9E��Ӭgm\�j7���)Z��T|,&�g��CF<�� ̘���	�MW��wD��g�)ʔ���N͓�lA��3�z�	�E5����v����"7�s@߮�����* ��v�wj6��%JY{�*���?-���96h�K;3���9�zEǄ�sr��w����y�8����h�~�ϧOp��r���^.L~@����ze��^��{5��ïW�ctBZ\?���4�R�.�K�T�d���A�&b%n�esSXI��7���L�M)U����f��=��S�d��t�O�NM�9���3���(H9ኬTd���r�VԤ�%O?���¡�NI���Z��*��������oc�y!��|���1����%ڤ�ќM�U*����ڔGh��+Je��8~�C��cӵ`|%�Z��oA��O�R�G��j�_G�_������[��Z{�������J/�}r�>n����s��1b��4;���^뀌��Q��"23������xQa�ͣ���{2�gӅLb���<˞ؐ�@0���%���z�,����f�DT'+���ȯ��T�!q�O4M���c�lL&w�3�2�L�L#$��I�����k:12�1���0�ٮ�'�궧��������N�|���#˯|�e<�=7&0^E�����#��P�L����~���:���~�=Z�i�y��߬�����X����?�«6�lǢA����6{k��o�<�����g������e����?� $�=74!�!D#���@��)ui��@�b����;�?':i4z�;[i�V���Wr�Jբ!�&�(���#�G&�8N�L�$�G�M��F�r�lsnS^�4g#^
��M�;W���qm'���4�یE���p���)��V��g��#��C]}�i˟C�^#0tB�ˮ{{|ر�FW�b(����GRf���������Z}-��w<��j���[�";�b��L�I.�9ez@
���õ�*a,�������0T=b���#ȡ�X��(C��I��'�"�^����Ή_�z�v�Ԉ�� ���4R͸�(��@.m=hI[w.	z�;=I�q���4�AAѦn�����_�� CP���fX��⏫ù)*Â?��R�:�=�F�=5Ï�����âs�2$� ��0{6��O�{|�
��-��=��%�{�?]�r	���W,�3�����J�+a:y���z��syn�ϑ۳PMƶW��Zn�J���g'嘋ՖM����D��Ez��3��<�{2.����
	!?�P��	�P���t����K����b��HV����6נ�`�E���B۷�g�9��QL��v7>2�:n����蜴�`�s�SX@:$��W����-7�%3��彪�>֧��%�K�t�T.oz[��6b�.��Q=%�[hʓ�9���
���C�C�8�T��h.V /^,L �b��e���4��8�=7�)���*v��@J�]�`m���£�8������L�ݳ��;j,`�;0T�B\@b�X%�~�/"*��u�}�����њ�W��W�*I���k���3��*_n� ��(nIU���I�ıs�k�G%/r`��Vl4~����~������v��,;O�F.ހ`�^tnM�EZA����2i�5Y}j7���I��V%�j�p�V�d�%���Ǧ�R�W1�@���v5�,��$��ؿ$��W@^����j�P:�l�:HT�˺���;[���CV���n?@L>�����Ⴔ�Qw�@-��� y*��$��c�f��db��r/3��M�T.U?m���{��#9�sA�|�A4Ƿ��M�!�DT��[؄��4������ϕ-�@��B�=��T����&]u9<n;h4��N�`�Q�΃�S�$d�͖��Djx��j���?�����3BR�rޖ�V��#	���Y6�T�Ťk�/�)��u�8;�7Jm�e��ۮE����$$�迭������\@�p����o_��׌��	�4j�����2���߭�������������3,�j�33���/I/�k�yc��?�ܣ��\f��k�!��.6��1�:qY	����_��%���m<s�hJ5�d���%�S���A�7
�u:�!�gN��k�K������`&���>��N����x�QD-�$ʼ���0d���2(=���p�m�G9�f� !����Ǖ�!*���;��	b�8��3��97	��'d�����?h�����=i��zE]�n���W�ӃN�g�;��umgg�z�����N4��;w���B�F�(�Gx�9�P�,}{]�)��&���`��p�����b<V�B��i�칇�����u��$A�]QIU?�2"g����,V��fxn,/Xj^! �r9�]�$by +�٢j�����C�4�)ҤVۇ�vk�*�A� !�hJS��1�S��+���,�GƻI͑��݇N-UZݵ.t�1C0W3���Zt2Y��ۤƄ=	�c�m9u���;�<ra�w�r���?�~@����U��,V��h�Q~k��\y=�x�唆+�<B�c��Y�J�>T�W%��D�Ķ�TA���8��DGX�J�q�8�]j�x����3I�ޮ��V"^x�w�Τg 5����숂�Mp�BsAqa���5�~03=���C��B�7��$��D��S	I��q��aY `]�9z��C��M�X�/Z�câ�Ơ$+�b����X+��}�JR�]��[;�5�[9��
���!&�KD�ӽ��H��H�'P>BxQ 	�+����d��s���]����nK{�����b����{c�Ө�O��~&d�>��H�4d�r$��(��4(ZjPV>cq��DÍ|	����h*�-Lȫ-�<3A�[M|�c=���x�=)#�F1�_�3w�p��a�cF���ډ��|0���Ef`{D\��{�_j$OG��aefU��ΥK��㤑�8�\�:���!�D���
@���ac.�����P���]hD�5�x옿�.c�Y�\ڿ�A���j�1���ύ�Y_��?n	c�R�R�N��Y3i�R�/�M���3^˒^N�����0�s^_E�W�&�%qB"�D�xw�K(�S�>���=���MUb��g�o���[r��84�d0���`�FIw��D�-��+� ��Z����)���]��#�co����@;kC��>�T��(w��AL�U(M9�H\�z��.�ye���Dm�o�T�Z��v��۴�\z���1�����{هp�����X�V6W̺3&���~0g��#���Y.��s|0��6�Vh��K�3Ƙ��9���N縟A-4q���Tz���e����1���6F69D���g�n�70�%U�$�MM�n�)~�BF��Q��4d*�s�^�X��u����]��Π}��ᦸA�M�
A��G��;����p�]R&^��岕�=P�`������Hmx�����쥸j��+���/߂��D�$[f�3�F�fl=�N�	�K.w���}'}�!��c~ �/(��a�`#Q�9����]�2 ca!˗r:�pJ�xfϨ�� +��<x��7g�-�.B��vf���f�Gދ�E=5g�ȶDMM�=.v>�ں����h���4$xfךȨ4����x>y�*�rx�������p0�^����(*���0��C#7���vMǘ��a��ڧF#۷�M��)�����-BH�9�<�h�r�������=a�qM����阌�}���
�U�_i�����>�k�(���.V:Y9 lη����F,o\�{ƞEaRǼ�|I���X��彮Xr�0�4~��'���g�[Ȗ}�4�ww�h/Z�),eN[W!��ݼ����!�|���DԨ���Mܭ��-_�V;��5i#щ|[iĖ���I��l��N���T�0�=���|wE��A�_�Ӡ��B<<h�_:]~�R@@:��m��}@'�{Q����SכQ~�Դ@�uv�B:���6�l����a!�X�A�<�"H����̩��Ii��I��tsC�j�|�%��%>;�2��H�P�Cc6g�?��&���`����%���, u��6O���x���J0�²&�'�@t�Dɔ��P��KQ��Xü�5��]���1��2�g�S�"�\�GT���^f^
P�{�<�"��+A�0�97�ȕO�k��3;��M��:��߸x~���p?X�9� &%�6���aG]�����&m�93 Q̑��� �B�㘎(��t�y�N�ґd��%OҪH%k�I~~�ïg�9IS��E�=��	' �B~JVWI����H��T�͝K`k7y�l��@��\�ɉ+��o�����C�I/���)����ˮpVc�t�N5fi�' ���_8��̸�������#��$�b�å�����RI�ql|����x���a�p|Q-�K���B^��V��kߐ�D� ���mn�����0r���<�Ks�@X�>��8��C*���[('��� �XKF�+;'������i����j���Ľ�Ν�:Q�芋���'W?���BS�{�x�B��
�to �G�%W�k�ΔZ<�x���3y��*/ͺ�:6�A�Z�TR-�~���D-a�*�r7��%�\�lDbո�Q��䋄I�M�r�R�"���*�Ť�
�n���Z���9̩a|��O�P>�b�p�oz�E��޷u��#i��W�INI�Hɗ�L�Ȗ�R�nG����T�'E��,�L���r{��>�ه}�9�0����6. �D��Jv�̒��"3q�@ �u	������I�a��q�D��N�*�SR��1j�A�������O�W�>0����1�֯�;�n�d��;�lI��/q�tO���c-������nԁ���B�䯾�*}��<XS:D"��h�^ ��Ԩ��
����ä;9�3�N�'$�W��8�Y��Ε�*+��R����f��L^p{ec�N�E�*���Q�t�j�nW1��n��+�p0`,�Z�8������ʙRe{ZVW7*�� �o,��Hkuݞ%�T�&�s����;oIwc�v�#V}�S���K4+'6ęS[ο���#i���� `SgCٌ���T�F���	KB9�j���i�(�Հ�xP#{�Ef���ʸ^]���>�qb�&����r��̐"��Aet�OdɍiaF�p�E����ٰ����H>�k�?�Z�E���/����#F,�<̒��:���q���w�����d(���:�Vn���6X�B7��_5$|����<
�o��t�:�������Z��o��f|M���`j%c�Nҍ���.aԑ-�W�L���p�?ДC���N��Pu�=�Q�bYt����?'�@� �a��*+��mDD���5�
�n�����O�����3	!�M����Y���=���f��߆�pH'�I_~#.�Â߀pX����P�Q����OL��2Jpv_��d��Р��vb-$/��UfI	^D�����g�xn�"n��L6�I�F�(F��T�"�Yz�%hO���Jb_�</��`F-�.k�Ǹ��d�&�uV���Èsu68��p�.*]��k"�`wj��d��j��Fj��ݑ�_������T0�(L/Դ�V��I�D��{]%M�Nz�����
��"3��î�=��tAr��Iu�){];%���<���Hp<��3m���1[��*�M�Fq�9��T�Ƹ�zr*�F"����^Hn�b�f%����M�JE�Q�<*��ܝ�"&�7ُ�^�:i��I�L!C��ė��B��ɑ7K ��]1oz9�F�v<'M�G?=���5����fJ�� w609�2��P������0L$	��&Н 10�1�����|����{x�k�2ќv��0���R{�|�|��%K��{�B�}t;EW��c�Fi7���lm����adS�x��3wz� ���/"�\6�V�1����8;i���[�ˋ,L���o\s�����j΍��؏�ɳ��gs��2
K�)2�C�1��M`��!7��@
OP��Vxr� M�e.1����V�o���x�����{z�w��U���r.����Ë'�O<ťǱ�y<ӊ��r�PC8��{K�T+�ϖ�/��J�~R;���P1���K�$�u�]"9�oA{��v��:r8�}�l�#��H9M�7zw�������A��5y�o��r���=�J_!��Gi��� 6��H��`�q��-��jZ������|�Yb��U�$�ήb��s��=����b4703%ЛҼ�i�\Ͳ�����vFxtr)n�ˁRʽ��u筃���c�b��`F�v�?�w�Ϧ�F8�8�͎Y�O.L������V3�Q���y;�&/�D~�����0�^V"����z(ͱ�x9	���^\�%�6�Z���V\m���kn�~L^�̀h���7���-�l�=�g�T��Q��ϭ�E����퓿���k����jJժ�՗��F���R~���yAQ�|	 E�,[k{�b XN�8O8$�Yl��|��~˗��.-�K����b(Q7�K
��NHǌH�wH��U�{�EL��-�����*��xݙU����4�����#����U���?��y�i3T0�6f�2��8#.hcLx��������זؾ��hq�|��zu͇@'��"���N�V^�|E�|��,��\G�x�&�G~���_�sm)^[�����q?��MM�)�����eYR�H��P�U�f��_�m�W/k�/��[�Frit�x�i�1̪�9���-����:������P�I�=(�����Y����	c�e��tW	����,����
����h�_ZT�R�>� �L�W5C�Fa��K����P�iP�6��~�������0
�h�O6r���ϱ�t�xμ�l�qf�8�MqR+�C��@q&Ϝ�7(1I�Y�n�E�/�5�.�N�Ν���V0��o&91闢|�w@��/Bye�ΐ�_3�_}��Q�����-�,��f�]��okպ���@��|Fc��v{$�8�@�ep.84��m�
�|��Cx��<}P/K3HV�u0޼һ��������=tjoq�o�^<B�O���ݓ��fy�<������/���'��G�jޭ��Zg�a#�v{_o�Ǉ��N�Ne�z�\��j��V��l�J��׳}]�F���fe3����i{���w-���u����+��z-}Q����U'��%A�5�|V]`�r��?���z�{�.�S,�n;�EpfJ<�+8*us�vz ��
��J�.�] �̩�e>��Ɂ�����vGa����v�>Fz�x��� O�>���6e�l୅��3[Gv`�l+�s_t�01���⛗���C����\!������V��1�
���:v�T��&Lvg��De����x2��.�/�ɠ+⑨|D?�\;�<�a��qs���pw�A3�d~��C׃�G���E�f�9!c9��H:��:��.؞Cm�K�����x����}$x)]%�I	tU����0� �Ќ�D�e��0XM�+�J(?�q��:��*�|���6�B��7x��Gse�ŀ�|�!�LEe1���R�v-H=Uaz`^2�u��O�V;����U�^���>	^�f�#�,�X>�z�c)m�T~ٮ�u�򇭟Vm$-�?�´0W�G�0'}���̶*�j]q�iP��"���1w¡a�ޙd�EV6������ݝ�����_�T92��*���`�vC��b[�3U�:M�h�s�@�>6���Yo:3��i��Ї`4
n�I'r/�V)t �B�����A�r�����d6H���:��(e&���2#t០R�&���(�&	.����R�L(�&��@[�6��[���I�'��Y�o��zÌJ��Ƅ�Y^�Oeπ�rЄ�|�TR��J藲RbYS �)�e��y�a���`��$j��a�\�G&]��4���bG����,�q﹔'9�w��0��
	�	�y��46���N�WrP�Td����4L�)Y�Z�$��^�l�,�1�K$�r���`��@9�t��e }�+TM�ر��e��-灴�����������6� %��D� �K)�V:�K	T|���d����f]�[�ױ�md�=�д�H?s�,t7^SKmVU�\�u�l^G?�6ޏw��L'L�N������+o[j�ݜkZ%g@��8+���-��*IKhl�c�&Q����R*�&��&� �����:,3YE��n����Ze4��/F6g��QtC~&�]8n���V��B��i ��:3�*ԕ������Ν��!�iGg��*����G,��`?�	�.�<ꅯ2n �2g�J.��}}��(�4P�W�ʕ�0��l�#�i� @��_D <�>��[�(�G���J����M��"�G&(k2F�A��t b��<ŝ0I�䉠�xAܒ�*�{ g��?q�^DhE��!�������Ir�Y��r�&�2[��9����[b�b|���O�}?����{d�KDD����fJ~���(�����.�ɂ�<�B�L�D�*�L[�b��"���hL��u�PXZ�Vշl�PD�M���aЁ���Q�LBX��&h�&�P2�J��^�7�� �`���vW���0u C�2�X�G��J�p�SZ=��@�Q��J��Tl{���h�xK𰂓�],���ɣ�GL6����������3zfn�'��\r��3�t��$�	��ϋ�A_%��䉇��>G������?�O���?����������7�|�@?oT�w+��,H���r�ٽ4�h���9��'��dG��N�9D�/�m4j�1�S��4�K�:�l��{�u���e�Ud�q�Q�+�Y�Pbyָʪ�.TL�����ч��z� |�N��u���Q���v6-Ǿ&0�`&��*��<	%���;�qٮ�""��ei��U��m������\)Y��\!1�D����<��a���d������#�2J�J�S�T^B2z芉k_	i��ϵB�k�5=Ԑ���]�?# #Y�&��$���]�����z1��Je���DA[�`<IX�&��ta��x���
��?=k�͜�'�F��������Q����x�F����I�
�eX�r�
�)1�%�Q?�%�ч�|����fi_�P=�z�^�VǇ!��'U�P$��(�୶��1��*V��^^�p̭Vg dq�4/�H3�9U�#ZA��Te�/}
F���0��B��ڬi+����)��k��o��[����TX�q-�'���� ɨ+ZJ�c��}���Kj9��&g��o��j�K"��{{�t��p�t��]M�6������"��0v3���ך�UZ�otoѾ�ch�6bɦT�ZSܱ��\��b������1����֫k�5�b5www�gǸ����Ԭ�A���b'����Z�h��󝐝�{��I�)�
n�E�O�������{<��.�G�!�6~�i�nV�}���na�}"&	m���^��6S@���P�Ͳz��R4b�34U<@�9�]iK=���Mz���9����a�50 ��Ф�/Tf̬�T�(GV.`=�>�C_����em7J�P;��՘<ܿC>N/�I���%D\�6mw�^�B�ӲڏU��� ���z���;D�=��쯍q���+`�A��H�Ht)bկ��jl2��3�`�C�ja"p��!^�N���'Y8Z��H8�Je8]�zz���61;a���v9��p���������7����E���D	�.�o�(�7/���1
W��̘RLn>���ذW���[AdK ��6�4E��*iVs�=���P�/�b��v�Z���SKj���~�,G��|���!.3�h��)��S�H+�`x����������d�vY��� jl;��أR��X֥6U[��l��h���X��0�䏝�Q͐dbNq,�q�\���8��\F�Y+�_�s���R���s��k�١��B�<Y��43'8�R��s&	�V��H����9��e�J�9' ��_ѣ���%)�6�N��R�y��(�+�%�8����n٪�)���e���іQ������AH�`�5#h�4+�d�����s���@H��.��lv?�K�K��\l�Q��{�R�#B�}��ǩ$�I�oA\`9U���Q���x'�Uw�?A�\��[�ז�[��	Z׾˗�Yk�M`�l���-He6�oR�d4��f9;�oj���f�c��U4S���.�Pu[�:�[�}Dl��{�{��m�N�vA��#X�ҋ:� �Us�)�
����K�h����64�փ���w�'�7;F�?/hNӟ�~Ac��\lQ_�dL�7����@����6��)��VGťe�v˩/��C|���LQ��׉�=���±� D�vC�I�[3AI3AP���"\	]���H���mZ�
�%�~�e�dww��[�<=C�����]A��AA9d�`Q;�YJ)�ttt� ���41@U��2�L�g���%���8���k���(�(�J�����r����_g�����́O�����.Pj��C Y�0��� OM��6��^�)��W��4��fNUc�I����V���	Hd���%G��FL�ʯE<c�F2�D�@�:�L�|&��|(�w��|���C$�'oUL,�pa@x�\�;=�}�C�=�ɒ��J�Uo�D3��i�7��� l�%�̟����r$��<wjj�gD�� 6��4�Y:��@s���^G�e,,��I�7�j��7?��~<[L?c�r����rr]@#�l-��hV&��$U�,�_���*yb}�����`|:�������O�xW%�1�R	7������uqB׋j���Lu�5���ܵV��j��hƋ���1m�@�467�$�y�F�P� ���2��@ˠd��&*��ՙ�����P&�>n������&JM.�IE�wwp�2��kcw�뿏���A� �LDMCp`�`��%���F<O��p�}"E�\�urv�����l.�FK?�~
�-�Y�a�î�ec2)fFh�F��(���M��
��������=���X�/p�G��p��i(��׽c)7�������hh%��0��y���+7��p��8:�)vp�w�06�e�P ��6Ps�8���T��R-��z�����xb���y���gNi=��Z�3K������d0X�Tx�N�@1��L�CH)��L���Q��G����{�wx
�+iq��1��y��	I��6����S�W�g�j�hl��)3x�ͬD�HA5�4*{\y�D� ='E��^�G���F���J��bη۫^��U/���Hk��q�@z����ey�NX��t��o����r�1�`r'#�>�W���mh��:�J�4�M�r}�>KEc��D��+w~��Pz�ti8xo���U��� �wSb���w/�H�� m�7E����ʏ{!J�7A4~�Ocx�u��n!���+�`,$Uq��.�! �@���AXXX0z?���i����SszK��{��1Z���0|��־�=�=�5������M�wC� mo�Ʒ�;E�q�9� s6^���n��/�F���{
��/k��볽}�0[Xp�Τ�K��ӆ�n��$��'8|g.���~0�
+���8}�m� �I=o�`��M�/h�4�ZRL<�;4	���v��X=hIr3�w�����¹�^��1����м4�-���<Rλ�6��ܖw����@˪�U^*1V>~[�%�i��sڐ!���i.O4S2���n�-"&XE}R�ݸU&�@?2�_3;7=�$���iK�黎��x���ZJ�b��^FK��^X�ܓpD#X`32S~�%�/�z=��_�2i�u�q�q�`�ReO���R�=i�'�{�E���rmx����z+�bǹ��A�<V�I�I8���˅�d0r=�I<2D�d�������cV}�L+.J�,��Y���Y?��i��Vٽ������q���~���n��W*MŔe���n�K�y�O�:`"�u�e�up�[=a1̻�������c��������^���ȯ�`��8.�~m��ҷ�"��ߕ��[���c�g䩬�f�9�y�υ,��/(��8 Q�=�^%����|Y�u�S**Hl��TA�M�gi�"��Ee,K:Z���j*hGi�f0��R2�h��Q�`��hi>S#G#�l�R�]G��9�.��v��9����'B�0��_�b��R.��?S1&����.e����k�#�a�uH�10D@ �9x �����8JH�ї	�+H���'�4+�V������3��G#"�����
U:�oj�j��L ��G:��{���ǈlH���0��fϟXT�����~�E ��d�@�kr�ǖ����h����k���s�%hN���B��ڲ�i���Χ�v���x�aΨvZ�"����p����;[;��\���k1�"���3�p���e7:���!�$���gE`vV��l+g$	!�-ə^O9�ޙд��¤;��-4N�-��t� ���LA;Ԑ�&����ФKK�Q���ʠ�y��H{����(
�ld�w^��nx��E�Gq?��������� ����|K��l�Q�C��E��I;�ݒL������.#�\��1�f��B'��>? ��_^D�Ò�m�.�d��P��L[1���k��Ya�`���%����,s*5K|票�)�{V�!�U�]��­�!��y��]����B)����Tȉ��fX��:�f��h`[O��E��fjt��q���a��=0�w4s-�����@�KA|��i��8�Q'uǛ�=zY^�r���Az�f}����&��G.�����?���
�.�'S��9:#̦r��{o�N��oN������.�K��A"`{�õ�Rs`���.#�x%na*�7uS;�Ƶi$��"����������YHfdu 3,�Qr�Ȏܿ��Jy���h`q�m���ɦ�}4X2��`n�c�:��F$�e6B�QwW*��\�B)�tiE	He�(@cw
v�F�(oq���޲q���*Zyg,��]l'�H��T�N��2ۘW�k97�ܶ1ͼ.�$�q2~#��v�����oU�IB}Z/�"��?}Z����7����o�������8Qܘ���M�)^g���rS�����T��� f{2�^�պp���0�O�k�|�,;T��qEG
F_	���ԕVڞ�U�U�	"؆�1?a�;:8>�=��E򀗨���NvZ?��7��$e�Y��������aS�C)��ʿ� F�*MH�0�u��tMi{UA��m�,�MQy,~2�H�a����:��B[ǅJEfgh"v��:H��V�T����Q�S�j��pUϔ��
x%_��Q��,����t��/��{����?O߇�5��91@�;��c\���Y�uB��� �"�9���$U<��T�4`X����TB�ߪsbϛ눸�F��������,��G�{o�K�p��j�� G��DJ_�����a���k��0$�Q�Lg����1�UOK�Rm�G�KO�d{�b�Hl���=<�����)�+pd��s��GHfq_hdUt�?�k�l�n��A�i���4��Y��������H����o�>��c�}�9۩Q�y�䟏����M8"՝`�=qԃ��tJ�%��ު�-`UG����>?��k�d�����D�YumC쟶r/^d_���;�t>�ҡ	�� ���0��Nӿ ªz-���&�@������:����ff����)��;T��<���p��/��e3�}�R���˲�E�Z��w�b������1�ˏ�+�F� ��W)����:��'��A8�v&Aur���&5@O���:�,n���r�-����Nv_X�ď�I*��������J��'��B����&�Q��_\����e�= 8��ϲq_<k?�ȵ�|c�Y�DM+�r�'гj�Z�����T��Lb6^��U���M���˼a:R]�EP&u[e7��1�2�d�˪W��c��N+��@mc�5�f_x�S��tk�a>��L�-ul��l��j�ʘ��u��O�f��9�#az�*�:G}��ԩ8�t"Վl?�"����$��	�=�BJ ]�����-?��z&���@�D���J�W@y��j·g.#�6��������RM��G�i��|�$R�04���M�'�D��;�5�iǣ��3F���.EWT'à�}�MSZ-���`��w�{`�w�Y�`�wUd��EUA��0�a��C����j�V���|l.��e�p��(EZ|Xn��a�E�n]YK{n=�5�e��5O�K�A�C���0�5�E�~<)�A'Lj�&Ѹ����*>W e��Տ����k[�]��1�Ma��܌Teb�����>�*�~���(z�0�M�J�)�,M�Qt1a��1b�S��2^� �Λ<9�>2���n���=˾n�*���ކ�9k��j��Y�x��{.D%�8���=-W��"��D���~_`dS��7ƨW!K0����1�z=�^��p@��dSk��*�e�#��2�r�x���+Kz�C�LiӔF5���~�hܐF�փ����~�)V%��q0�$�B%ԫ/��s��l�
����'G�V{��@L�c�B-�E5^��u+/��)�	-���4���H�t�qr��[cƣ� ��Q��y�uz<>�}���&�g�W���4L�l��mc ���W��;o�ѬR���&�Ku��!_�ƤQ�z�bu�`�_�#~�Ƣ���@�@f����n��r]�7*�%��!�iok�C5Y�LS�{5�K���HE�~���x��i0���� 8�Nv���Y|�}���G��~8i[b��O,u<*�ɍ��iMT!����q�1p_ak�.>��nx�����,V�<��ǋɥ�D���~�����ۏ�d���ƛ�����	����d��~�羗��6�~8� B�H&׬@��C(xxA�ƀ�AO (C3L�`$ԑ�%��{!��E��8�Ū���e�$�]h�]�z�ᩐJ��&�� {1��4� k�A<�`}YX=;�@X���'�+�ar[�h��+�J����tX��=8�{.x��Xk�� v;�ּl�t?�4���y�z}��R!�;.��F���(DA��TK�2q�jX([���1���v�y�zm�,�~]����.�Rӌ={�+n�J:C����o�����/4iL�95J�ku-Dәb+"n_���W`ݏ>��R_�0�җ���%n��5����R�,�����U~�Ϸ=,d��r��>�|���z�.����Fuu���rs�Mm���$��6=S����)�"� ���	��p��J}� <��4������ߠ�}�aU7�����7�6Ʀ٨�۔�a�"��!�AqnM#m�2���$2�/��(k_`��%��q�q��pl���q���һ��L~J����sg���0�+H3�a�f�vS]!�	�z�*�~2>]��[vWvFa���P�����6Mf
k��q2hH4Ɣ�y�����7E�����I2֦�T��+����� 锘\Q��10�`��[C�A�)��;���Qs�ϦGE�����	А��Q�/W��f�.N�tB�czn��n=N�l��(T���g?X|f���8⹲��+ٶ���3&��xKO�o�Z�Fjiԥ_���=�N�$@�&�����a7{�Z���ZW��]����|���0c�n����C��ՠ��r��A�&��4�|���PG�x""iT%B�s��1�v��q�Px�����ob�Sa(�:aޚ�i��VjNw2�V=��q����o�u���O�����������{��~?06�O$�3�3��U�W���,y�
��}���c�ڴ��
��SvUx���XnU��l�-�?O�M��m�qD��c��U0ͽ�J��K�y�����B�Զ��G��z�y&Fh_��I��MtTz�������E�����F`Rh@B�Қ�OI?��T�ӓ̝$m���Y��:=�Zi7�xw��)=�f&�����-G��sB��Ajs��������)}��@��h��E���?f��������� [T�Ua����2���آd�`(&r�z?�><���t�]%͕2�ܳQ��E����1��2��S��U�e̫Kl���]t�}�w�
vkbSz�%�ogu3e�a�< V4���N��0:&��V��I��A^���͢B6�
_�h?����M�@��6v>>� *6TP;��T���n��-��@T�˼�h&�%��PFF>��%�q!���OX~�fSL�
fWvXK��N'�.z���;�����fA��_�QɈ˃;F!���z���T�uK%Z���1���h�y��7W��Ӛ�x>��&�L.C4�x��zzlGq<��6`=���	t����A�� ��$�w ��e]P?�L@���f��P|��k�Z�r�A=�\E�uό�ْ�*RqV(��\���($���:�H������6�����񵅂����9�G�IvH��΁����a�}�MC#�`QxzLϢr�N��T���iz����(*X$[4:��^����Ω{�=Ç��ty���m`�uP6�w�[���ۤ"���>�+��}���AB�}�HBﻉ$�{������eqￓI:�m�WM�J+�v��\@[��y��bv��T�`)���]�z��~�N�t�Vh9��-ݿ3l�r���P����g�B�uJ�'�|�T���q�X�� pK璇9��D:>./܇�/P�7O���V��^�v�Q/BO>K'4A�ʵ"o���ê�2�&`]c�{��8�
y������M�z�6P
�G�V����.�bϒ�d��2�`�F���ƊrC�7D�Y6\w�N�]�B�hu�a���#��*E#R^Nz���$<2@�b���'#r�9 �/��B���P:{�h��_ھ62����6SM��D"�S9�	���ښ�%d
Ҹ4��^2����E�(�D�~e����Z�s�4�c��� G%��:���Թ��5���2��%���d�)�6��+�v��rƚ	�]�7"�ya���P�E���h8"��_��|�t�ݙ�2�]�s��쾨�.�b$d�{l{i��Xx�k�/� ���PӦM�Q8F�N��G�?" �b��+��z�P¢)��~�I��2䔤��r�1_��Q�T��1U��X���uRH6|l/�Z��@�aEQ`�Y1W��
���������Z7�$�/Z���d��uH.�.����[ �^M��~���?�5��3��t��������@-z�{9|�-�m�˰������5xC��Γ��
��uHA;�T�'V�{���_%e��0��*t��@����e��j��ԏ���UUoF�N'������7�L������	�eG��իJ�eM~E�X�{YЫz/k@o�#�"`��~�r��cg�{�f�;
_	�4�4ӠMoI5ogEA?eH|1z5�Lm�JVF�PH���Wu�	^֠�)�J�%?B.!��Qߓ����Tnۺ(�K��Ԉ�Ճ<]�tE���Y��x�.)}��$�͹����T��o*Tʒ:����.Ԃ���(V�C��/����E6T_�f� �$�e���6/87avy�m���c��d�{������WsR��__[�g�������s��!�������~kn/��fUb{r%�/|A�B�K{�J�'��U�{�ַ�p�`׳M5�u�q�1�,��ã��^˳[s1�<�����k�):�<��~¡~��7�^8ϕș�˥4�,�t��Y/̪u��U�s���OX5d=O�#뱡����u/uh���zs�G��,ўdu%f��G7~ҋ>�>z|���+�(�g�[�h�7r�%�a�������C�7����!����^�^B��?n(����!�K:9��4���q����6�f^I\AU�15ݓ�c3�5d�������y�r�)gU�շ�$�^dJ�D0��Wd�9TR�����G��'���$Ll��I���m��s*�4զ�Im�duXhW�Жl�SN�%�q���@aM(@$R!�
�m����)��APT��N<�E�hU�*�j��@�ι�L��8Sڭ���c����ڪL�kl�6/�&��]���OD�ಷ ��Ci�>�sy�³���ۣ/Ͷҥ�]�����&��Y���W�� �t����)����m�忧�6�������zz����-*�$�>لU=��'9Qc�b���a���v��pq*ӱ,�B���i�t+^��JE��t��hp�Xg����y%v�A/��)di�<����Q�iOѽ����$| N�M$$�W�� ����I�.ΩU/c�O7��R8�c,LV�L�PҜ�eGe�V�M��{�1����T�-�5z��\M���1#����s�{�A|��_�A3Lv����o����t�����N�z�&�-? <�T\�tev#.�`L�p8�/&W��"��wM�y P석�����C �dT��p��֦�%LPF�]LM�C����+78~GX0�ǂQ͗�H0���B)'�|��Ʈ�I�n1�gz�3.C�f��UCH�dҍEЅ��Ng����6�#��T5F�7M�fV	�]_��n߈�2 +8�7i�GI�O;��뫏�|P#
+������N� R<��J>�v�й�
G�HЋ%�F���0=�E�[w&�+S�2ZOK$uj����%�j w���V8��E\6��+���T�U�=��=���{p3���R�kE�a1���R���|"v΢]L0Ա��/$F�PA��`Ga�Lq��H�`�%(5���)�p�egD�D���&[܁�2����t-�bbuT���}@r}/�� 	9K���֍���B1+ԊU�}<"o50�DI�DV�g�L�@A�**�����������L�k�/X��fO`ݫ0ɮo�ƪU��dR'��މ�,��;K ����@�ƙR������E��ח�y��5����S��f�3�.�6�w�ԗ�Ӡf�+�w�˂�6��'��`�����g���H��o��s]a$b���Z�8=���������ןg���g��߯�y����E2�2�7EЕ�*?�ů����o�+ԕ�<E��Ǐ=��c�F�o�+ ��m@#�zf�5�*���<~�.�gW���V���۴Ɗ���:�S�F^å���v�|"ͩ�\����j%}�}�6�|olՙ��&�]ޯ滕.��1�y����8I5��
\�A^����º1�!C%�$�א|3M�e�Ԃ2�2�Za�_��һ����p�
n�Jr�0��r�/$:��R���η���Z	�	��5� 6:f�0��fj�LS����X�L[H�m@ l"�t��+���SF��2cJ��?p�\�iTD�Y$�L�z2=wa��E��[�Ɓ�|wCi� Mf�:p�����T*[�I')��@H���TP���֞g���6֟-�����?�죡�]�_&�U'��4|q��$�D�'_��~�|��{��U
#(-���Ǹ'Ʒð���JIq��(V�B��F&X�D	j�amxӁ�^|!�j'��;����+����B�l	�2�DP�m�no)�����4�\���5e���XeTR��:H���t�ŨB����v�{!���#�j�+)��R�F���ʋ
����"Q�x̪��u�Y�尣K������U���d{�d�����]�à�;��(�@M���.������6	�{o=�"�(�61��x9���$�!�E2�!��noR���)��Ԫ^�`h��F��	TJ�A��1��Ӓ:F�~�hi��捺�5��W3THXA
u	�'"&���G�=-�ԪE���r���g�Y|��g�Y|��g�Y|��g�Y|��g�Y|��g�Y|��g�Y|��g�Y|��g�Y|��g��~���,� � 