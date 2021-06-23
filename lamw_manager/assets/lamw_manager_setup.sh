#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2546842271"
MD5="4b424c1c08d9b2a90debaa62e84ce8fc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22924"
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
	echo Date of packaging: Wed Jun 23 09:07:10 -03 2021
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
�7zXZ  �ִF !   �X����YK] �}��1Dd]����P�t�D�r���i��`�T��r�)Fs<T�^6;���M����O��O�0�az�t�������-�Z"�zqϐ�7�@w����91c��nMh�r;���G<jbJ��f�д��2�?�m�	4��{��愋k�y�o��G1����J?�m��������&��(�Q+�r3.�S������j��<w��.]5/\?Y���Ǟ� v�S�U���h��0�m��ٝDc"!(1OA-��a_���_�ܫ�F��|��=���v]�9�_����лu��&+�N�vF�[�m����t���el?|���m���%B��y'ɶ�㋹PgK]����S���Cأ����~�֡h]4wKM~vX���J�`�l%
�S�Т����Oߕ�ܸ�vQ,�Ӹ��T�r��xl��ͤ��6: ^�JF�3�_CA�4u�&�����$�7�H�: P,�rT�Z���BY����+pr��6�?6��.f���$I�@�(wѾMG�dM�JT���y��X�6C��j<.m|f�(�'�� z}f=�����?#�+w�cU"��CzF_����;�,kL�X���b��Гb$�v�K��3�@�l��Yx���FۛN��hY����D}Ϥ=�v�&����u�.�ե�|���(�Lǝ7~��/[v2��LBO�g4}w�P�=t)aLS�[�gv�'���H#�X�3/� vB�F��]��c�<��)MҚ8j�DP��`��̼����:��1"U��4���̅���	jA5j���?�6s�!N͏��um7K�m��-Y����[Hҗ��'�g��}me1�UH݊�pW�<X�'��!��Κ��т��Z�®��(.M�sk�-\+Y-Nk�Q�eLW���<.����h� �}�?���t�i�/+�{
��-�z���S�h^�^���Y�����z�͡nRr�P	͝�yGV���ϒ�ý��PP�*�Ow�	�]SoS��4�d�V{nC�+���q��a�үU\}Ev�n�&vy7jn�Ut�{#�r����������4���'M��8	�I.�J��������5z��]�^�Y���w����x2�?��H�����G@ɜѰk,�^�Oy��
/��NH Wd¡�<���O;Lo߆��r���L��~
2����إ�zo'y�+9�b3ύN9u2}[d5�/e�5T{e�+��c4wv�����MI�k�<�߭	?�� ���)ǘaol�cRw�A=FdH�ꠎ��`���D,8����g-Z,xZ�Oe�tEp#�Кϋ!�$�C�U[A�� 7��m3]��Iϐ��	Q��q&��lh>�ɜo�7$�^
vTL��\�ύI�z'�-�,���p�?9�����`p�45c
hB���9iۥ��V�U��
��?҃Q�v쮪ީ���`d�^��S��n�I�r"U�j�iݿ����lD�N. ���N����g�R$q3g�1Mʑ��l�IH����Sn8�h�B��8l�tb�!�*����9��3w\5�y?��[�*Gu��._�_���� ��ũ��4
J��r�6�鮅3�����qbr���U��!����lI����B}$#�� ��#��o3����:�ܰ��IUح���V�L�#�X.p��i
��$�d]I!�0ש����������҉�6i�V�x��Y�Ǿ�3`Dv�b��"��`�nx��WJ�6����j>+�z	�� ������rN1�bW/�G�c��+�0�p�x���O��{z*�|h����i�>��
�a��=�K�]~LF����lx`oס��n�k�����?�e�8a0E��M��ic�1�![+����j�=�N��"�a���X�Z"�@�mn[�'p!V�<A�	�C�����þ��h�"G��Wa*�v�Py����Z�O���y��^�p�3]ۯ7��"��~҉���>m�A7���P�.���g��/��ۛª�H��{��ѽU91F����yܼ����p�l��X��m	�[f0&��L��:k*<���ꈡ��|�����p*5��#�瘈=I�3&�B��0�?��
੨�@|�`��:J��`����ǜ�N���n�!Z���@����ĩ���]~	�<S]	{��t�/�S0e@�.{fr��ˢ1*[�nb���3�/@2����w���?�.�v�[tؠK��&V��h%���Eai�/�'qռ��9ܻ];oꟵ�dWjE���X�>(����[�9g���<����efq����A��L��� �~��r��$D4���Mj`J��^R�G�$���g$�~�q�����}'���jkEQ�R�%������V�����5��:]�ֱ��*:1t,A6��D�m���Y8q\Ur5Eg�;�|��
�'kQ7����)����&��uM�ي�a6�ݹ[s S�z��5���Y%��M��7����WŐ�x>�O���K��k�۴�h����e.��2d���6�F���I��h1Z�z)���<�%�|@I 2Ǘ���J��r�oN������݂��5!b�]=
�G�`1�	38��&����A��@�CsO�����+f�w����-�������Q�΃՗�s@�;q�q��������,�ӱɪbu֋���1�[����Zqˤ.o��Oȩ�R�Ty�n��W�5v��CtY�R7�T�+��w��m��,b�V-r)v�ä��f�D�������;M��P�$~|8�G^���p��`�-�}��EQhp���t3���:��&c��srh=x`�v�8��(�r3i��/T��T;I��-����l!eY�;.�a�j*N�*��@l�?��*hFX��<�ƛH��R3��{_3��N�_����Hɉ�>��[��G�n�V�<�\pDX�ޥ�*[ҋ\�/�~�q�����B]S(��������?Y�4���}^�`�)�������Z왐Ѕ>�^&�`��X��qN�� �ߓ�d�
���Za���{P�+�NZ��Y���ו��I�R��s�H.�,�Ȟ���e���������AG�M+;��y�g�?��fC�X����q�5W�%�Mń=2,�XWHNIu1���3�!L�CRT�m^p����(�D��ՆO<��1�����h��W^I��y�B�o���m��wH�� ��?�?콞rB>�Y �h=��]`��[��v\B�|�[���.5g�1��^%J��q�ČK>� s��/4MS:���6UI{8�u�ӉA��|��2%>��4��xʹ݆|�9n�W���Wy���⎖g���i��v��c���s�)�q�Z��ד�����Ȉ�=�����d�vJ��;�����&v�`�4).�$^������|�kVWM=����	�a�����w<u7NCw����t*�f�w����}\W��<[�ﭴ�4�b��h�,��Sbr�a9�I���4���`B��Zt���':0��6����;����^:f�5��:Z,ˀ�!�9`ݬ~�X�-1n�H��Ǆl�_@�(�2�w�6ժN3�y�m7*[�"��ΐ��]084k�mߔ�e��ق@����f-~,�`��t��y�M�q 8�^Q���.�\~1�+t=��S�v�.�U�b��g{ ���@(�8Gp&s�ܿ�F�n�p�*�n=��6O�^+�H�|�=�H�8�G#}/Y�g������O=4�YMN���-֗qJd���Ű�z����a���pot��Pʰs��vw\�OsZ��ؗHN��}��s�j���`9����J��r�]a!�4BP7�-ܺ��Ls�4*D���*���Ԫ]Y��-�����ԱX����G����w�F�_��n��������Qg�oPȢ�#���\&���]���o��Pp���|K�vůw�^���ø��a�Ȏ��V��$��_{;8HNpT8EpQF��^4
7~F"l�]aR�}����e����ُ˱�yːލR�ZB�/�Y���#QZ�q� d��o=��X����� �Η���4�Q��	55�L�##;QF�m.",ψ�ǿZ�B�XS=\�(|�j�{pV��F���l����a�9啈���v%�&�"�9ϋ��ךc�MX�F/d�œa5h�z%2�4M��1�Ʒ�Y6K���%�K3���:�$e�Db̋3]2��|I��9M墩ѣwE���*;�B�͸�[衴,�5� �Ǩ4$������$���$���r���C1EC0EW��jg�����hm�(�]kw�8q������I߱�ppL���I�Tׁ�'�_ L Z��G���b� \�Z��*�����k}G/˜���O�B$Tԟ�a>SS��4wC���P"Âخc��޹��U��SQ8�A�,�����mw�숁��w�>@ɚ��N�:�4��*/�Q��Y _
aS�S� �Q�p�!��X�e�X1�p_���/�!Q��3,.Xvc4f����J-����Y��+��3�@�����&8���jh:<DS�0ϕ����=ɔ��s����nhx>~Jc��}�
�i0��3��Lm2��5L�����~�
��n��=���6|/R��`��M��.��ez� ��Sv����OU4�$����{�t�xR d�1N{��+E�z����?t ~�X� Q�T�_1�`����U���񉍲�8��ɊTZ�3��>������{��a!׵�6e��ָ��;VzHh���M���ү��`����a�pk$����U@V<ӏK�[y����wQgň_�5���숓@��̀��+SH�(�T�\�~�C�=F��<$H3�3�<��Y��[r�ɞRQ�d��"7=t�Q����H�f��S�Z^Z��0��xh?�?�y~Zc����� [p�^0��w�R:����7��*�����U�~)L��)pe�1��w]ɹ������P�:]#�<���G^jA�.����a��_�є7���\̓�����&�n�X�rK��"<.������� E��/�S���$|����r��HrlN�j [:T��� Ȅs����w�%C��nE��Q�X&ͩ�����f��#��E�7�a�o6� ,��,f7��VC��}6R��O��v]\)���T�V���ꢟ���n��@'P�V��詇�yn^|���=
t��b��(.?� n21
м��oPv�^g�S5��=�{�
��O��TQ��{�Lu,	���z�O�^
���e	>n��]�^:����vkb�����Qt>�Ws�9Z�@`�+_1p�����P�e&Xţ���QL\Q�R�l���?�r@]��86��f�� �̓&�V�6�{y�0�����/|%�gz^ԅJV�[�9�Xz;;��.FgK��)�o�q0ZT�j�''cyj�9v�*RwaZ+_�Rle��f񆌣��ɷ�nOʈ]�Mp�%�BǸA��x� v��퍒�/a�C,�d#���\��|��յI#�OО�u �pV��C�xiI
�䦹�&桦iܞ2Ʃ1�`����#���Ӄ�b�H���0�y�qp���^
�����°��֦����}�K���|Y��]Z �#�5��֟r��ܮ�o��JnT��	��%䤹��+e�o��t[����jj���L�����S;�O�o��F�(��b*�x���\�ܣjTyx��s'��7��$��5q���.p�)���ͦ���K�#��a�F�xaB�6��\sf�cX1�0!. DQ)R0Goʗ]=�y�p|���\c�܉$T&,��eې�1��F:M*��Tu�Q�Q1?���紉���<� �/�N����k�4��}�l�+6n�����e��M\k�ۄ��K�c�fںv+v���襉/j���>�����h~((�ǯ��-4�	R�%zӪ�V��P������p��P16b��9���� �p��_0}�t�z3�A��K�?[N1,^	��K����y���(�Ɉ���a�Uտ.��gS�c%�{�PQ"-[�ѭ�T��0�����w�3������;����
���A���e��EB{�f)��Z2k	�;TCWv� �̇�pÈ)a�Q�xɭiƥ���ǿ %�*��۰�y�W��<1��^��c< ����f��B%8I/�a��,�Z��21?��9
p_���-1D�q�u������2�X�"J�q��	��gJ̕3�긚oH�`��πe)�V��$�B�i�C�$�g�8Qӏ�6�s�
���s������&8�ݙ�>�Q���a�Su��C_-u�ݾt@��lp#8��Yab��$_Km@ymk��WF�zA�������"2�ڟ�s�A�?���.�/Jƛ�)G��O	<ӯ�� �V�F��dt�l*��UR�!�S�D�p��>��:�g�G7��v/���j'a�d2U;��]�bP�e' �b�ep�X��q����Tn%�������WP����ǃ��{���g�lc:����(�G�x��,� �S'Ņ�d�[5_s��x^Zf����
ڥ�D:�!��7�^�Sh�Yp��D�MxfEj��:�	�
�y ��a��kQ��6U�O�P�Ȓ��;�u��"[�P|������!H\�v^]�v�g�K+�>���e�no�ڡ�=J	�>	�W�(�'S穔o��	�lPy~����	�誢�4�AW n��˲V)4�6$�t�kLw��S�����|1{@�jG���e�/�\$��v��/Bbq�����E���W�|'gꪙ;�e�	�6I%�V=〆`�B��bMuxt7�q�����+pъr'�c�B~��]U'{�	�{�UR��$�=�$(�� �%�i��y4�ʉ;I"�<��`*��f�m��E������A~�U����I�l��;`(�'\9b�	ˍ�E�w*�3�X��p�Ge���-�WA�}�R�R�"��x(�,�<Z*/��3�S˛�l���H�|�.�=�JKEf.XR�Ĭ83K����U���y�ݿ i�:�Z���mnߤ=��u%}�H�'+Ì�4����r�i�p�����A�P`lq���K77m��l 1��8��I���Qj�j��7C���A��X��J@!�k?��fk�7f[��w5�A<�ya�!&o����7��q�;�{�=�Ot��V�Dab�R�5�(���?Z!ܰ���P���)�f�uY�(8��"������A�Q����Vv����ꨞ��>bڈ0��ษ��B�#n�l��/U�'���j�|:��T�wV����ߜ *�儢Ǽ����)
8 �i���qH�E���?�00�d�hC%�1Ս�oT����;�R��\/�RSY��$�hU��P��v�m���L<������׫���'+c]_�ϲ9���486{�KV��$�K"��lT2^z����,kFA�/wN�������"��M.z��`����4d���#�C�o���P��k2fav%�0}/�~�.u���w���c��Ǫ�N�׻PԼ��]wU��Õwpۂkg:E�L5)���=)�F8��@ ��KP}��n�v�Ej���k����_�8G�+)�V-M;+�<5�/��p���t�Mq;��h��HЋZ:����b[j��$E�W�o��k��xT%�ғ�3�p�yY0<�5�v�3�+���\D���E��Zg+.3Zo��$�
^)���+�
ep��p>�Nkx):���_&B���e]����[ɩ~������R�������;�*%�]�kl���6�QJ���O3� �Kw[b�"Ĵ��,�8�>@��2��x�F����s��#=�i���nb.p�3�D{�����m#��jH�s {�-v�!��f�ړڌ>כji�R�kL��>Lu`X��Kq/��X��4j��GF���8F�zDc�������Bt,�`�;(�y�yO���n�?��u��y?����ʒ��A��dOΝ�b���m�d��nԓ�7���hk���Z��i����"(/��!�8���9y�m��yb�	�>;����%�h��*��p;��2j!(R<R/[� ��&���\��HS��v�A3M��)����?�qۗ����d�?�+��6HBs�E��Uͽ�Reɕ<�����h�,��i��Bߊ����J�)TB�o��hm��bO�J{�R�wK����U<���]}������Sc��a��]Q���*�1:�ye�,k]|��k�'Q$N����`����F^oS(���\��( Kܫx)��� t��w��_~�@�%�B����&r�z�"�,v�R��o�.��P�c�5=yM��1�����[�u�UVk9������p��8���^}@BX�^X�^Vma
�߈��h��]@
��i!sEF�5�|�K\bT�x�;³���g�.�=�68|���0G#�l�Ng5Lj�l��W �22<w Cr? R^���|�	ͨ�)�#0�-/v����K�mNgKv�_)2�q��JD�ʾ�\�Ep���L@c�_)�ZI% v|�T�C��ڇBY������5�	1T ��(�N٤W0FC��F�f��aR���^��>�p���72+�Bb�h�����Qba�H�#s$�6`�Z�Q���Cy=:��P{�y�Oh�=~�D0;�!���AiŻY����b�[�`���X��QZ%Wk�(5SW���.q�'=�8j́q�Z��������}����
R�?!JJF�IT,Y3ko�s}���Co/7�(����cXlbD0��,��3�p[����I�ɔ���Xk���$~i�ꬽ������L9���-F�u� ��OF�R�,㕞5������ |߬7+[H�xw���"��`GM�U8���]xi��j�{��(G����Sp�F��O���?IB���{KF~��?(N�����NT��ٹ7G����dB>)TrY{b_.@�G/�Z�l���۞�eK��m�0NW:2A`ހ[5�<N|]���\tj ��0k�pժ z�k�R�r>���Bխ��Á�_�Ї��t4&��G����	�� (���z���'�}&�ȵsI��;[Q��aж��]�zQ?�l�rg��9i;�x0L�������dYG�����zq��'9!��w���n�|\F+��Z/��$f�dm�0dT�\!-%�_r�6%@�Ky��^������'�a�H,{����kn�|2Ot�8�Z;C��m���]�[�K�Lo	߹�x�Ѵ�5ǯ�0��(߹�|ѱ�q�x�����L�d���7K�>ڌ���,`�\�n��ȁ	
��v�` K�!���Y?cc�XE���R6�O��"g��d���FP�n���F �.���Rۂ�z�Z�׵���n��Ʀ�)�r>�>�__Υi���ġ��-ӣ�Z���BpI��EH3��������d,N�wQ���4YA�3M����~(�<�n
|�+Rl��h�,y�M��Y��t�q�o�蘒���p{kբ���,X|!Y�s��ׂ�4J�q$], �>�G��z��௧�	�-gap�e5Mng�G�\��
�+S
:�Q�����[h-�	���$J��^Oã4���nQ�`����dc=��-�.�3��s��&̑_�H�F
	�}1�I��JD��~P冞�N_؈��P�W�X����Ƙ���_�����������P�^��+i?�~W)6�UŒ�ip���Q��Fo�
<&=�9�n��`5��
Q��,a~v�(��Ɲ�)��ƕVl�?F����X)66��?�Kn+��'�(85�N��2���ZU}�	5䲠b��?�깠�{>�BLYY��|�u��� Q���he��uyt�IFk&�ı�ԅ�}�Fu�Ј�O��y�R�[���f/���7<�2�QS��
C��Q3G��z��� �t09/��H���	:S���J�K$�0����}P}�,����q�������Qx��?�8g���#�ن��hw}b�9ө��9׃�0w|634*@�h�0�,�V��{e���R�{]E�)����l��G� �s�=z��֛�H�⸄n���tS�W&���_��!�J`s���Bfr$�]�\��^�������]R���=�=<��`�������)0`7~�K�ަ6�p��[&V���s�nZ�9���0ݍ�9 ��F���*�?�O�鄮��3l$1
Sʆtk(�;�,�љ�h����s���Yc��X���e���E�~��/�N����!ֳ��$���xS"�|����4�/��E�yQ�zjߊ��ʧ�B$����ѫ�@&�	����5����I���/��@�9�)�*���W�h��3���������!'z�Y���UJ���uF��+H�'�K�l��F��>��AL�ν����K�N�鏋�{�4le���ġ4Qs)�MI�ڇ��;,r�;q�8���7���FNE�y��^�w.�BBa����	�NN���� D�HƜ+��������K�L�=m�2�j�R��

�>��NT��� Q#Ę�~�>ư���^ h�	\��Zx��������Ә��n�8�ÝLmQ�l*��[i�R�[X��c�����6��ƥ\E������x�	M)�>}�z*�^2N��'6������@ɦ� X��Z��a���@�kI�`�!�V�JUX�3��3�f[� �3�<�2b�kIn� 9����V@M|vc���g�R�%�����B��}�v`�[��[�\QH�4�{�h\;2����pŨ�j�U����	�`͹��)����NE��:.��@~j)���QvF�Q�>���{�A��C(�notZ��0H�y��@GMD���)�z>1�e�v�%leh�m�D�],�a���^��?��5�Z�Pk�?
ҍ�o?�P~�^��ш�5r��(��~�@Z�F��/�� 
>�����-�@Z�D�c�6p`h:a� >M@�v���ۋd�{?�ʖm��q�a??���+�w9�⃉�Da��S�35�0����kV����կ�������3-��.�m:/�__:M�P��E�kʾ$ˡM�p�������I�:��{�tsfK��X򩆹��qB�޲�pH|�^^��F�?�{���ъۃ���'�i]W�	��O�j2!˝�/?2�I��}���§l�`B�yeP�N�w�U���obK���P����M�\S�8��]O��u.�z��[ྉr%��0"v��XLg4����>@�G7��v¸����n-� 6�*�G�T6� 7���,�|�mGV��'ի��*�6���ܽ@��V��GSG:A�bJ��4����WY�71���rt:��c�l�V-����%A�K�k���GM�LeNG'�? u���D!��jIzla�!�G��<���kB�Zh�h���l~2yV�r��4�����@��^T�v	B�y�ڞ���&J�gX4��VA�nM}�yw���N8���ɳ�� ��\V��m�
�Zckf֚k�yꗾ����|b�#!�:�����׽�x�ֆE�ʡ�[}`�Ef��N���D*[�ys�����c�g�C���)V����>���쬥�����������������%�q�)��$���gٶ���.���RBQ|�������v�f�p5���0J�9F�2M@��	S+�z<a�CS\�e����SP�0Ϥ_�p,-+��Nn�pHdL��m��u�#"w^��6�YU뎐Պg�k��!yg$�i	o�:mn;x�j
Oy��;:���\�Ě�	ݹ�����jk?~a5<y���oA�DH�=.k��
$�9$�h�CTݎ�G���.Rk��Gh$�$�K!t猅X�n��<9�o��$V��Nv��N��d#�f���{�}�ܾ+�S�S.O���R)o9���T��cD.�_ܺ��S�(Ox��Q��O�Ii�z5E�е��4~���*��-�4��z,R��a�*�)Fv�#� ���Q�F���� L��s�\�hK���˨v���^���Q����V�����h�4�4����{�;�:��K�B�lB�0��oh�����3�9O$��ؓ���4�wZ�C@)�������5����%����]�g�F�CFOT��=oT�*ͤ�����5��c|e׿�ek2��(�}��)Ъ.���LNІ
�I��G��
��-��
��� �\b��$��,uÄ����}8��M�ss.����!��N�Q댈����n�p�.ΗΑ:�P�qY��'#�����䠭;mg�s��8w�������9\�W1�6#n���CS� ē@L������jp����<̫vU�jN{BՌ��10��e�t-�eI,���(v�άlDx_�����	z�kY��N7R�S��{��YU�LYR�ÿ��8��A�x��cG21�ڻ����k�Rm��.��[��g�BO�e����^覉0���QY�ٔ��&��U��p�a4��N/�4s�m߾we�/(��΄���p�{��8<�Јt���	��Qk�������;_��6�?��se�X^�|:V&Բ�#+�2P���<���V�y;_���;q�6fV32��~K#}��/�?Ǿ�[��}��Gp�����t�j�zQ}xC�Lf�����e��ts9��%��lp�������w�V$�X>c�ym��Nz�9�*�t׮�Ǒ��F{Mj&�݂ă���윥{q�'�³����Rs�����\��<��#� ���c�W5DI�4����L�5*m��:迂��J$�La�)LD/To� 	�F���[��e�C����*��gZ���!�m��m8ʴA�.W|V���y(�5p(Cal3�m�H	TG(�r�\��Wu.k����h��0�1V�`pO�Q�WPpt�yᅓL�uzKL���ɠ��{�����Ƨ�RQSҙ�R|��@
�g+�p6\�5�	՜����) �j��=��?% �����`k'Ǽ湄���pC�l�?�2ԢG��D��X<�w�}dBl�:�~',檨��R��g�5�)_@��Z���x��~�f�a�NW'M�^�N������[��;w���e�yN��2u��0��|����3�^޵u��^�>Xc���e�y�W��`Ə�]�����d�O�Z����!0ɚ�)u��wQ�I*�1_2��v�ؤ���v����{kI�Ӻ�~S7=*���ҁT	�@1P�F�Aո<C�@����^�g��ߖ��2���v�m���Ț��2/s㟉x%RF�hl��~͔D���d�H	L+P*�2������*�	ҳ w�|qE�.�����k�Y�D���'����T�-M��q�F���Չ���$���]�G[�77��&�Y�j���XDxZ��l�~�]�FK���ڷm�����?��s�^����w�(�F�Mmc�9V.��}Eݕ9`	Y=ڬ�z*�̻=��h�[�����h5��9P�P�X�J���ڶ���[2ƾ[A)a��AQb��ޏ\)�^�q��,��s�nDԳ�W.�C5�Nyj	� ������$��u�'�����u���gRأGm^�ګ�P��e�8�%�����X5���X?�ED���4vA����qL���+�W���Aww��40AE�cEAW�!���c�yx�|�O��c	����M�H��b��_�P�G\_>��b�e�u@���B>��=0�ڥI�<Ҕ:�_ t	������"�ylbu!�"��-?KR��z�8��O��#�P�(��l�d9k�N+�c�|sQ�W����%;YW�ߨ_*���sZ��Op9A�Eӡ&qqN�;�ѧ�C0=�>K�׉�ejm 	m�Wp�^f�~�'��M�U���ۡY�q��bff��Z��Un�2u~�0-*�j4A��/妵�u�̓�/3v�f�-����?*F��zf���B�W��x%����n&�n�DtZX63	
�Rn�٪J�&�����
q�3�@����yp	lP�+�W����ťH&�t�T#�OJ��Y8���~0�ȭEbá���o���~@
�!sMr�c�t�B%,MĽ�f3 ��L����Ң�VՇ�<�DƤ�<(�J��	��g���<g7l�>sDK��P����4����E�]��g����zQ(eJ����=��"�^��r���Q��X]Rl~i�*A�p%�ʛ��ܺ�\�Tk�&�·s����<ظx;���6�b$����h���P2Vx8l�T ��.Mׂ�N��㈘G9@��I��� (נx����SrT`yi}Ȳ�\ő�ĘZ��ϿM��<~u�!��x&՞������+v�|LR����1��V�����~(t^Ѽv�aQ�[�1Ї{�q���X��گb�ͺ�:{��o�A9�Q��_Du�,4v�i�4���,�t�U�ݫ��.�)�-.�}n�7Г������#co;(��+���bltX#�Ww_�>WJ�7�w��YC�# ��C�PUօ<�	8�Z[<��Ơ�- �V�4�o���o0,g�z�N�r�W�߇���?����������o�
����d�A�[���q�UlVs�OE��FtI*��k���3g�6Y�!��ު4��V��}��F�G$��$��N"�x�$�V���39�%.į�h�b�Ő��1e?����T3�a��3�d����i�oe��DK��|��[Mn����슲Ac��_���E�h�l�7ֹl��_����?y����ihA��:���2�\QuE�Gm�9�
u���� ���d?�ܰ�7�����T�ڦ̮����;w�����_I����Nf,$r�>�gE3v`m���9m2�?�p�Oec��_�������1��xmV ��@���7UO�6��\oh�e���Q����{�ElPemј��c�1 ��r��l�7�u��]l�s%t:kre4��V0��� "R�T�,%v�,B3�gm�NW]Ř]�=��ɜAB�+�/w�GU~&"���� q�j��	Ҹ�!ޣ��<-�}�E�k�rs����#�b���F����;���[�i� uC���#�WdjSZ dݎLi \�8V��R�����o6�2�*Jl���j��7�n�[��<��r�K_w?����i��S��4]��/�yehRN� 1=ǘ��^kUm�}��|[��N����6�v�j	�n6����g�ʋC\"����f�'ֱg�6r)W|�jy�k�._NN��N��ĝQ���i��:��w��oP�͌җf(h�z������A�R�5a�*ھw��x��
,��2�Ҫ�������������Ak�*٤�=tA:�k�0g����ʤc^�Ц����%$J�/x�G�k��k���˼a4ݠ�o�ӳA"�*��v_	�]O9(3�C�u�X,/���S����z y��:���%^�)e^�ۀ~�E��R�f:����c�<�-t;Y�K�7��6��1��T&�veސ����)S#��-/�e�vK�����;@�K�R�Y!&�U!(FaŶ-����2sFQ��o������]ʶP�h�#�	që5D���O�����=����@���*>�~r)����P�]itW7�
*�/��,H$ո2�2�����+xA~rN�����YJ�nUZ��{�ҭ���P���8>j	�/�@SH�~�#y����NЉ5�"�P���[G� ���Py� xAe����;6�}`��P��D��4����:�D"�QX��E���Q�e?�zx5ʜ��UK�%P`H)�6e#i0w�M��'�ľr
^E�`�\�	�}}(D��e�]�}vb�R�,�Ty�W���,Sp	���tɺ��N'X��G�b��u��Dn����S4�R�Y�_P2wS3�$�@	G(�����/��p�I?��|C� �%�]��rDݛC)�km{��T_�����y���W�-#�Ř��2�h�&8L��jX+\<L4c�<�H�ʽF�2�J7��S����d�f���0d
�K1b��;� �TO�X,�h��Ol6��@~�:R�)	@���y�Ǘ��Ȇ�}<�>~V��K�T��I:�}��Շ��E�c���k���B�C�J�`ά�����r�EK���\_�%h���1�*?Z���-�����ʩ^E[Û��1Z�a-'���'|�bp%5�}��y���o�1O�e JbP6bsn�)9���!`�����]����m�CB`�`����Jl�jn���X�]��r!��?͛���a����5Z���4�$��E�\4HB�瘆-Te�w�I��'Ŕq�x�|B	!����W(F�.v�1��<;�DԣS���R_�h�t8�ui�"�Qt�|�`�q=`Mb\L*4���B����U����.��߇_^�G����8d����fا��.]�~$�̬h��53�3����o��+f���rM�7��c�G�T�_�-�)�?e��$S�\*���&;H�"�+	�À�����GU����ƻ��`�w(���<(��}�;��D��Ʒ��('44�6����M������o2�d9ؾ�ڜ7�:X'c0,Xe�6��_���уB� �:��4�:�jy��S+ND�:1խ|E��G؎~��d����	�i�uW���&��/]�D�ã\Ӳt�L�0<�mI��Jut�S5[`A9���R�Eb�P�1 �`�n��&�i�|y�s[\	���k�J(�ނO�䧪��hJH��>?��?~�}٨�2�n*�h�3�g�D�?z2H��2��"X��ڜ����Q���
g��XX=ӑ��5~AI�}6�p2�g�Cȉ�c���] n�I}o>���7��E�8�VJ�!�ΎAX� ��f�
��`����ҐaP/���/= 2�(��+�sA��@�
�mV�^��Aoj7��p 4�$��s6�s���j�݌ �9�/;��z� �{��0>@"�0�9�+��f��<cG��&zY�M�-����KR���ĝ�@������bMGx���r�Aԣ�ρ���a�*\��2h���O�p{�/�O��IBN�Q�~�+Iߩ��d�0x��!�(�)h��uN{� v��Y��&�*d1�X1�zl���))��j1fX�6E���Y��\f����>Y#h������Z�B�ꖋ��:���������p�=���H��� ���4��p�!�'�����*d�VW"b���ճ��cI�Me�e}�Z�`��E���!H���06dͧ���eenEW>�E��,p�U����E�Q���(�߽��#C=�T��}�=Tʥ!�{�!��R]�=���D� j�u쓕c��Fy�;��|$�Dxgl��.Ɇ[�����$����*gs%�ܲ�� rYc��H61mN�a����r>s|��4��&�N�O�Y��N��>�,�Hi8-Yط����׋������;�\`G�&��
H��$���9n��Z�%|��uuc�Z!S���p�դ�+�H1���g�ދ�n�u�[!ʚla`H<�q؀�<���4�fk�dDBN^�\mL�Kn���E$��G R435*h#��7�8����k��)q�+�u�S�RD6C�:�~�޴�_%iq�󷙙q������G�� rvm�/���!8���if�iSdu���k�"�����K�KX����:��lZ���w��Ge���ɂ��Y+�"C$=��y& ����I�+܇��[��crK�*X{��Ϻ���BV�y�bZ
g�N�1o��P�����rw�N!2�AT�n��\�(ig�� Ө��d�u]�Vޯ8N]��L�ٯ(��-�i��m3sj	���=|_� �L�CT3�1�WTP����"R�V'�d��	����T��M�dqRoѢ�O�\
��0|�Ӯ��*%+ � �f�"k���ZV��r�]Bb�'.T0f����-J�2K������9Ն����E��B�v�	Y#���yw�̕h[��ʺ{1 �*0F1��8q"�b�x�އ�AkJ�e쇺#yPD�X�K� y�^ѐj�Z���Q���pH�6��Ɓf�=BTn�?;P+� 8� Z��T�12���ʯ��W�������q5m�"Uw���_�B��߻�bE�]�v+��9�m�\��ڔ���H����D����F�H�j!����j���J�p?�Rs���S�UW��|�ڏgg�%,�F�}���(�|�� �t��֝��1G6��]�Q�X� N'\�h�~��p�~jٯa6��j�;�´N7MxLG���u�cu R���E��1e!��Pj�ܢ�j�P�ٍg�L�Z:��TK0�\Av0�
H�}z1NxzO�"�rKͳt���:fVd˕�p�.t���[�WJ"<��I��F�yf�~�"�p�'<(D@]�����OK��!���91��y����0�S2�ق$*ɩ�?{��K �/�c����k�=���_oQʼ ]��2S"����^Բ�.�o���p�I�������ҧ"D���xK&Ӌg�2���]�5dy�u���^ڬ`���Eoe�ܰ�s:����h�"��m���*K�)�k(�E�]۟ـ^�(Q�	9]���s{�>�<�s�s��:v�:LV_��V��{�nϠ�Z% ��:C�������ˆP�C�BF�ER1c��Դ���
���74"{߷����N
���`����*�Y3k�{����Ly4�V�j����t��O���x��$1�[=VIe��'/:� =-�6u�%�`�N)��f�a"H��{(N;�]}c��5��;�J)-����Ӡ�d��^l�����x!V?<Өq���;����̒�`���
�0<��t1� ���R��P*氇�!\�E-(���ϰ�^��d1�o�_
@ձ뒌�B�����A]��f�L�Y_M)���&���mf��i����Z�y�B	���.R:c|7,�������xHQ�a��0+��]t���������;�$����;�ݿ�D�#��Z�NjZg]�肄5��9n��T�_��͌��]���m��/��C��k΀�H�6r�	��q��ٹ\�7���%aLX�s�p|a����z3j;�t����Ct	��JAϫ�Ms�J�Y��?�,�B�~�MR�͐3�F��1x+�}	0?oc7ż�R���:d���������� mб���lC�Cb'|[rM���!�䑫299k�{ej`� /�S�?G$<;u*��yE��*�95�x/u�]���d�_��/ À���Z
o��6�a��'��Z|n�g���[�[�͐��	��U�+�W=I�_YA;F����s�_й�T����Rۦ�����RMPV�nC��ED��p<�����S��$���A����"�q�v��;LV�>2�#
�.��h7�)��d�V�������b��5�y��׵���SB�`�����%�D���1i	���k�/������llH��n� �Va�bZk!���p$��B���;8E%�´{��7�������f�M�������%�W`�b'�UJ67*M����,���[��e�P{YϨ>�&:�:q��:cuM�>�|�k8���������՚��1	3�Ҕ���TT����<��w�"��X���T#��1� M&�VϘ�8��<�4�M�r�c	I�g��(N�x���ՑD�+{���B�>�~_����c�����p�+��R�!��K�p��=�m{WV���aDJD��э_DJS���Z<���;����A�=�wc��d�N8�Ǉ>7*j��ȇ�ܒ�tG"��*���~���w*8O�@�rȺz�=�'�C���k�d��n٭rҘO$�i����>�����4S<����l=ɰ9A���2����oeY�>Y[�����/�J�(�5Z	$&W��*�QL�A@C&��~t�p9^���(���dl0l��/eD��
�<!={���1�>��[��//�q>0�ñ{�_U�a�P@E��SB�6a1��ؙ[����q.��Ax,�)�����
�����C�bY3?�i���SL	��t2�����`S��=���WJ/Eg<�
�!���L�ZKC�5���j|ڿ���I�J�8d3�v2{�Q>dǪ�:�U���,��ٞ-׆C�Ͱ|��K͝��V��u��1�n�Ј��Oю<JkŲ�mY)o���3�bv����W�/�A~���p�j�p��`�}Y�m��m|V�CU	܂i�n��2�Q����k5z����[%����$C�m,��w�x��aGĠCb62h(��J�(NM��Cw)~����*N����Ǆ�F��f�V���x���]��D�B��y@�e�vc�<+6���y�wD�&��H��Q7r~!V�X����Q��R�QA�B��+�9'3��p �`��x}�f��d���U;�`��X���˝Dv�ò�%}΄�t�-�|��$�nӓ������b|(�
Q��H�6�_E��ia��ʳ��α�l����@Y@�*WA�x=�N�6_�Z�V���u��&e$[�}���h<��C�=ȿp�9��sx@�C�A&Q��o���v�ٷ���X�$eWi���B2�
�THm���ch�w����L�W8%�.�.׬sd��i]f�������DG�aغ�%��� "^y��rW�Z��h���4sYf����ε֗~*8��2�0x�:$��^�G�k����xY���,�Mz�=W����E���y湂Y{G1>Cz�X�+J��I��d��T�@�('��.3ps�(�>S:胧d�~\4��ת`��ro?<$�b�O>�oi7�\���.e���㫘P���W$Pw�W��
r�=��ʥ�Wv� Yݥ_2`�<�9�J/p�4/�e'Ū�c-��i�bK�̊mdu�D���O�~9?̝����٭f� �ñ�S
������W�����(^�٫�'a�!l<���8�� ?�J�a��g�dao�
'���9��Z�&H����q/�/���� }�Z�-�����<��9L��P^�DW|O�;r��p�t�/��5^�� �g߀@�(am�s},
��m�M� B��Y�*8�W �4h?]\�'eO+�[KZ����M��8�+���d�5o���OV�!�F=:+�&��B�$iw��3�jz+r#У�㗬�0z%��:)u�8,)B���^�׸lP
�p���(Ԥ5��:��*���b�A��Tn�w.���JJ㡰S��T�yh;^��_��=�-�t�D4�Z6%�?G"w8���NɁ�谽�ț��F��6�R��3���Xޢ���^o��Ղ(Ů��=k8�Du�%F���[�
��a�;���v��հR�8:t#�F�r���5��gS�����}z�:��RJJB�|�U��<i.lT�
�7]�n����i����>p�ޢ�ٙJ1E&���p�q�eP�Z,�\���j�}A˂ ,��=ɚ���K�ԥ7�Gݨ��2e}�[�ƽ�c�����T>��[Y�4�W��?1���f�s��# �������*1�~p�s|h`�)������h�iN�Z. 'CX�
�O��G�?"=��Q�w��+9�St��˷v�q��+�D~�_��'e�,�ʑ��̦o+���M1 ��5J
�3Sq=�U���9;�i���bP���8)wO�hx�Ԙz��Gګ��yQ�^�p��]6ܤ�K�G&��E�]c�}s��u�:�����v�5��](�B�䞞A��#���^k,���)i��'ߌ�%o�O�ƁSJ��n��D�^VF-܌�H���#���߀�%�N������X�l�+f�Π�R�ȴ������-��Rnw�s�BR`�=$\ ����M2��A��+��i@pI�_T'p,f�"�_��m|�<��A֌"O",G�Z�D!3��ꂘ���rit�~q�}	�sH��=Q�J\�oݦ������i)6�ҀR�ٕVc��� ���2�c��ؑ��s_m�z��mgE�Ie�'�#K�<�q�T-斈/n^r�L�[�B#������\Q��ܧԊ���da���ٵ��L=yE��d�+E|�6�'���e��i@+C�x��~舸6`��fb0�aK�'�5<��V[�6��Xp�~��HƵ��m�)H��\�#��N������>��x�M;���E���},����hMR9vg��.,���&����$
�Sát�e���Ŵ�uD��Q���#&c��4 2��%����@�m𴇟Ga�!�K�)��8,�>�Q�iJy��o��Y�"r�p��D�
OϦ��{xC{.A@v7� �^�����~��
���[��;Q�r>j�:�D4�7���ㆠ���4�S|%64ّ'폝Q�b��׹М�{��6���CQid]1���E_z�_g��6�?M�r*ǑdkE{>�]@;�w��_Ny����))9ae��V4��5��܈��O�����Pc�qXA  K���O� ��������g�    YZ