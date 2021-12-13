#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1020101876"
MD5="d9784bc7325fbc145a08851a580e7d05"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23916"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 17:31:23 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����],] �}��1Dd]����P�t�D�"ێ�`�f��w��R_B?�k���zgza=��At��%�J`���%����Ş%��~�}�p�ɧ�>�� Q%p�����g���ԟ{�"�³�9��~���L���9���3�|_��:����nP߻w�"���ƀ���rr�DK��>�h1����jEu�
M=�����u��s��K�D�$6ԃuR�p�|@P~XR�,@\���Bn��L�
$Z�
dҀ���r=��6.dH���X��EY
��"���T%9���?�X�ݮ�S'e�S���8z@uҡ�l��,ًRYx�������lU��Gq� j?nV�8hp^�!�n��eǁ3w��RQ�&9�b�q..� ����:�ʕ:*�r�z�w��{.s�wl����>����m�rJa�����D��x3T��]8���X9�ە�b5��f���92��g9U����z�����2�����|;��]�ú#YlW8���|$�-z��1�du�p\�]ؙ�
e'�W��&�n��
��K����ϲ�1)�}S��9���ˣ2B8swc����k�gY��i@�����T.hz}|W����A�q���x��PI~��m\g0L#����A�;.�p7[Q�-ò�a@��iQ%���$(.-9}\K��Y�WʥU%�`�^e�|˴�ySXX��gD��<�{�r��z¸�c�i���g�ɼ?��V�UC4ml���۶є/����1f��m1;��� ��h�ݯ+�-0w��F�9î��{��#�jA�8([=y�4�yˡ(ф��x8��z�����9�d�!9���:����:Nжh5�\�n�5/F���CS8a|���l�p�F}{��k�ek}hzk���sB�2هߙ��kDb�^��3��d����n5�Y����������\��h&f�&K#Qe��U��|�E�����)�鳄��i�������&�85�e���^���At�W:N�����.�N���g��iWw�
�=O�-{�Bt���c��'�EЎrL4�F����7K��96�9��4���K�">�uQ�l��7y9������ݣ���6�������V|��_e�V���c������C���mn�c�1#r��� ��1�e��C��J��B�#��?�e����ݗ�?�a��%$X�&g�pܪ}F���ٻ������鶃����ذ�$.��E�[ߧ��Z��a�6w+�E������g;rkڟ���y>Xߩ�g��{v���/_����`]�KVϠU��U�?��R&R٩�%���!ʺ2���s[H�o!�?I[����,��kĲ�P�����+�.Rl�p�V]�g�v���2��������#����[$��]��.��+_���z6ym��ȵK�#�8�sQ�&+`��j��*�˚��`�~d��,M= (j�C��ݛg7�S�k:�TK�M�E�����3O�h��9+�ɓA.;uˑ�+5�*�-�-7u�hhI%��fޏ�0,�"�s�rQ? 8�Io�ɐmB�^�v��A��LP�u�����B[��.l�%E������q;�����}Z��Zpk�&���]��m����ZƢ��1��,1<�������&���T?��2ov��l�tw��^2$G?۲���P��Q��-�+)��T�������.:y�X�{����,!^z�yD~��+�cकAw�Sx��:BXD_�O3�&�3�4������]�s��#�f\�qQ��`h`�=�Yxsg�B�C�~r=�1�2]�t�ԓ��d���$������ˮK�ԉEH�Cq/����k�(x�ɐ�4q��(,�u�o��cD��zD�,�髮+�[��h|���>U�g�HۭII�}�I�P��w����Ϗ���0gc���������d�L��C�Je;C!N�n�>$VؕFƩ��+���>��<g3�{P��l�[&���A�A8]�e���Ha苯y;6O����'���e��"���S��O�Ճ�,����i���5S*�Nv�q):�q�x��蝯�y%j~�bg��W3�S��m9��/>��� �wb��#�`�x7Y1�fc�X%kF��.��Сx�<T�{8�� *�w�ڒ�y��y���[��(|$Uz��J�f-'�ͣCx��b���F�sBR��E�IǛ�/�ʶ7���E���G�/�Cn��E}�İ���\�r*�&pmIj��7����T����h¬�Y�!.��G���o�2ĸ�W��c�ӳ����"X��)��,�G��Uݒ��ѯ�d~��;�Ծ޻��S3^x�F�`E�yL%K(�$6��zE?=ai�,�P�B�bѱ>2S	�¾�^}m�M�e&A��i��	�9X/K<L����)��;� �J����I����k�����0�Ͼ����N5h�O��8|[+���/8!f҅q]=].�*��}m�n̋�h�K�S�=E-��K�dY�w�S!Fڵ#mW�d�w�H��	E����������jkO�� ��^�i}�Uz)��h�X��3�}V<k���.��flh�C�B}'h/�A����Ӝ��Ѝ�/��G���*�"N�NAA�
��Mj�:;����:������ �3V�R�2�ʳ�R�4d,��5��X2��{�	�m���O.��������_Ɣ?�I��D��:�IU=`��AS��o�����Ht�zH��- �k	���4_�`�(���pKtb�	��]z.�騷gE:�8���J|�գn�C���f��jnj��9�A�}��J���F�d�?�����;JM%��=�����뷂	��S;G`R�_�潋����B�E�3�s�5x�̷�-O�z�JB��L��!2h�װ��<���W���z�*��O��ͅ�A��ɡ�p�Tj��.��WT ��U{�67 븅}���Ր��l^��:�S&X(a�k��w+$�����l�ӯ��Xa�;�糷��8��<n.�c��r7g�����Mem!D�����uY0��� D�*�
B�s�'��\������?~՗b�g��ڸ�=6(��V��J��v��v��#�)�����uh�"��o���&��퐠G�l��؍j*Բ�	�UI(�{�bYE�bX�{�?
p���Vo�Bb��M�M�_�fO���fJy��lcXJD O��]W�ЙMH�{�זAI/���]�]���r`�u�^�"L�bUG��k/j��B>�X�u"���Q�$���f�俰���X�����A����T0�\6*a�V��bѐ�"����i	���t���*�Aԭ��Mey�� ��W��e*^ū=&�8ڃK�k+`��mv7��妑��{*0��:�:^.�5j6�Fd\�4&Ȑ��o���޴�P�Z#�5���+h�UK��]�����|�U���v�dXۿ���n�VCac^)o��������+�I���	���~oן���߭���CY��a��iLm���*I�诔��ʫ����_auZE��'?��
-w��%X��9��4�R�>-�ݙ��[��C�`9�q,��XP�d�ct��������N�b���9RRٹ�
�?�Y��1�R�
�n�'j2�Q�eLn�[+Q	�>��nӞ�x�>ǲ�UV���-1�ٓ��x� �5]��b}yq�ן���\5��ɖC�.�M+�lդ�o
�O��(2Wݎ�n�`�* �=�JmQ�6��Xf﵁���%Yu�� �Ee�%�8B=
�=4:1N<m�SO�_	ݬ�w
����x�R�.�@X0~'�@��Y��̣�,LW�J�B�7;)Q2:X4�p�'�]�Y����_��a����*7�=��Z ��1��a'�t֤�=��'�YLq�,	�F!��|2������GZ�㋲�XX����Xł�AwW�k]���*ƒWY��_Q��z�_ɡ�)����.K;A���y�o��e�b��|1/��d��pKu�c�����B���W����[rW�OminU_�v���pл&�ٸ�֌H@�ԉ��!�G+��0'y��k&�D���p\<�9[�bֺ��1B�3�#I$�L��v��D,�R�/��/)	��y��o۞V���)���m�}�T{j�+$�&���,�n-��{��|
	�L ϙ\���.ǿ*l#��p�2i�̗߫p��2�6u��bۮo5�
�gЭ�7n�.Ԟg���?��!����"ۏ�Zh��O�]]��O���dW��(�c���:/�ee%A��D��%;��'V\��]�Bv%��pR&�6+������d���Z|��~cʾ��Q�	wX���:�8�dP��k�u'���ܥo#�֎��B�\�J#�R�E���+g�A�o8����%7��09�ߗ/��K*�GU��Sd�QE�¦� f]���HR�?�]I����B?_�֢g���ᖝG<'�y�4.At��ojrD&�d>��	>,2�bɟ�*�?H��e2����>:�p���N������f���Rp�>b�̓֒�sI/�s�<���$��50X�h%�%b2�C`��ع��F	$W��L��bo�W3�oY�i��s�Nw=�Ħ������4���hu�C���>E�+-���,���/��[ڸ���nk�i�I�-U ��&�{A�w��WP�	������u˧�^�d��M{NLRU�B���S�~�K,�����n2f:��<�[�r�]O&��@F�N��Or0o����53��3gR@�95Y6���+>~-�!�w���K��G�9;`U�kެ���y��q;5�J�$M�;��lR쭏�▉0��;X�����q�,��vIb��
u�����p_��:�n��R���1��.��gN���ァY [����/��J��j �.\���K���"2�I��Tw|�l���Z�@���;�ۡjE0���o��h)Ql�Fy|���J4R�LD����6�8;��S�?Y6l��[R (Sc?"���ڤ$5��ZO �0旚h�|_q!$�-��n�k���C�
lkp{�RPd��ُ; v�a�:d������*i�/���3��l�7���� ���b����@K��Oiy�$⧍�X[��S�tmu3F�X�T���������&��Tb���/]޼��c@�Y��.�����ڪYU�M|s	�:�A�@R��c�nvE�
)%�Z!�Po�"�1�f5�P�v��w�@˳	Q`8�T*
�}�Q���,����3p�8�>��G\|��s�"�R����Ҵ�O�^%����|��o�[������UZ�)R��,�g���ږ%)��SD
����A���!�N^5�5��_�f��ӇĹU�jͱ�#PX���|�@��P�0��S"n�i�����,�\�qO�o��8���0	����P���&W�nY~���Q��dŠ N,l��$��������4�6~J��s��K��չe��ܥr�)�o����W' d�D��m|�S� ���2����V�M�3�7=e�h/r<t���[��"�SQ~]��r���}�-dE���:�U>��I��}/�)��O�bS��*�I%�${v�1��a��@�ǜ7z���l��!Mt�/<9-��˽��Q�6(��83����"
)�+�?ܘT8������};W�y�Hthɀ��,�z�y�@�U���40,�������qʺW% ���¤G;�ib������_qU�1�^�aٙݽK*�ZG�������QWW�c@iөA��O&��c�������m�'ڣh���Ӂ��6
���=v��(*������|�a8Cc�hh�*7l��>�D@2���Lz͂�R������N�O�A���_P ����׃���.��'"I�/J'wM)�4�����%!�O�/8�x�9��
U5«+��fv�5�甠'�kW)���)�K���z��M�Ξ��lz�7:<j��I�mZ�,��tk^�������4�X�V��j>��1�c/��P%2s��3�e)���B/�^E&���eW
����R�Ө��,�M^����$h�oz �HːQ�ڬ�Wa�4�R�	
�̟>UA�."���ܐ5;/"��u?\���7�����=���A7_,mm��c�����@�h�$(-C�h���ݩ��U�)�S�FoO�7�J���~U�b4�K���B��H��e2 FR8 ���3�N�3㐟����ţ�I��^16���@i�d;Z � v�6/9��YFǭ-鷀��wE���J`�eb/#צ�S�qk��ѯ8��n�O�U��b�V�R&~�����罽Q�������3��Y��M�pn�=�h��{�t���\��Uu�0�W�m��꭭�����E�'J o���Z�=8����3��pEe���$�Br�O_ӓ�O�ҁ��vH�136ؤ8)^>~/��TH͂�.����&@+�=��L�s��v�+���6<�W�T*��,��ѽ�Jδ?�N�v�k�����ѠmՐ2��N ��DN�� }��qY0 �P�=�����2�ȅ?��@���{Г�)�1�5��2��4� ;�Y�.�X�v���Ova�?`G�qy�	;f�[y�Urj� y/Ӎ��Q��,��;����������<����aOyR�p,0O�������7>��')�)�R���Qb0M����&^J�Zz?aB����C�h-�qs/�Rvw�gh�ԟ���Z��m2kvl
�-L�{uW��I������v*�zʳ�%=��������D�QS-S[W���nG8H!�O�]��ܗ��x��q�kJ׸,��e'��m���%��d=�Y؋C��	F�x�9���,��-,��P��]E�yͥ�B�V2%O�	%������I&�Bç��赮��a?�\D�oZ�C�4պ�k� BRy&�0$� �P�)��V+�� �j��כ��N:�N�Ap�fh�˅����<P��֔�����O�ȀU�k�2�����0_3SN[4N5@�"�x���rV;��0��Z�:�@#9��P�$L�2�] d�q�L�"�E�� ��!��.��L�.my5o2���`���-���\Q.�R�Dg&k����>?�r�T�m�U�{������q�<��aЙ?d��-�͵�1�e�q����k���`TU'�3Q�Uf�`;��C��CLNw�d��:_8�n�'�/������^ՙ�<�F�sL´ЂV� ���qܕV�T�|�ڤ��'K:�PL�=U_��N?"���/���MA<W�,:sln��hHx�3#�}T���$ӊԞ�NS%ėcj���o��/}����j�N��٤4�ˏ��Zı�bٱ���F�nTUCT�8�Q"NeF�<5S�M���n���l�+��0Z�̊��7���-�GG66�!��<)b����W0{�h��#�o�k��%W�p�x�  �����᩟P����i�^�� :�v�Ӧs��X8B��L ��Q�T�[�A�A�����EX�;�zՈ���CZ;=�A�_?=���4�H��~^�������"l���c+2,����֓^ }��Ό��*Dj$Lܦ�(~��	8y8����g� mie�J�@�w" r�f����4B��oP�G���E���ul}P��߰�(v�p�I�_�Z� G(i�t�*�[���<(�h4�GLF�����~��K~<��e�༽��
�����>�Ug,h�F�F9U*C(u�lG?����d�6^A1y�R���D��(S���Ϯ0u��W���l ��Ζ�ZO~�Y$��\FX*� 7��b0�c��O5�Mu$@T$ap�0�B�qka��.4}�-�S�~Q����0dq���ςǍ�B*D�X�#�Z2"p�Ee[d�琷zUm��|���A�1�jY&�?�.�a����ޖO%QI����a���&*�)���)�q�`���ž��Q�'!$�KT��k��& )n�;Z+]r&|c�w��sO�9eU��0]�#ٜ^��Ro��iY	��[D��#�8qi�ކ������(�Uh�z={ �BVM�p����Uv�GSݱ����]Y��0$�D���>l�l�?����H�����?R�렧V�M8R�g߂����ݛ^�<Èp�����΀!8c����Ր�!q�J*KY�>�z s������mo�l��v�\"����=����N���4^��j||�­<�g�E ��~��\j���F��ٻ��F��6��B&��R�����Ga�g��f7Y�ߩi�_0fj���o�����,X?O[��2��S�²�)�+�C�Y)<�	��F'p:���%G=�A����/�]��U��e�d�W�i�ʐx���t1_v�h��^p������+4�s��$`��2�m�a{K^�L@�7�jF ��$��@����>(.���e��ǿ*wn��������Y�\`ްw
�T���MG�_���as}�@�U��:x`[H���]W���E���]M�����U	6���H߆7e-��*σ?�k^� �s�Գ6G�~�!3�½y&8>��Cc�5�B�&�a��]�l��׉���H2>Q,��7��)XYN,���aUk��FA��d�6ڮ��Fs@�:��c/6�&Ԉ��ʚ{?l��b��y@�#�w����}��I�I��M� ���h��7�d�ND�yRG,[Ab��q��	ߋ��$��^sr�D�0��37���#�fl,��`��[.$M+�Ħ|־&K�n�8��k�s�kɸ+]�5)ڿM���ok#~�}ˡ��ǃ/�qX��ov{@����cq,�Z�p����\���p���wɖ�Q
�����xSѩ��k�@�����hH1���MG��_2zs����(��N^�(�lK��z'�˯�;UvEX
�ޗ�5����n����z,R>��{z���n-\(�ܜ�VoIݩ9(ߐ$���r�I�D�Ȳܞ\�?��2TZT������X:Y��P]��B�̦�r:��½W�*9�B-.A����?CX��&�Lu�:Dz���h
���ډ\Ѯ�챁3	`�or�j�9M���tKj#�xp�W '.�>iea�"��B��<kTdxɴ8#���kS�U�����O�k���k���U�?J2V�_N�e¼C�/���x;��}�58�^���)#�b����w"V��:�dI�-0U��+����Sȥ Ow���^��&چ(���q-�j��:��z¹hN6U�܏�c�o�Oơ����m֗ !N�6+��~��,NX�����v���`�� 7�9>Ц����L�4���m�*��@�͛�T�������r���.�x�p� ��YZ{c�i�
�{�v,��i�#P����T��-wn���;�9�GI������m���4f�Qq�w����ɓ�� '
�Rn�M~�СY���Z1Z��C�%׸Ow*%��1����?o�hPs/����g"h{Y�mn���(��oM�e�7�ZG!def��@zX�G�i��f�˧�H�|Dm�5M�y7�d�\��M
�r�<-��xl�Y=U��1�@ɭ GO���+�0[�G �a����&��m�X�I�O�߿K��*m;�_�/��P�����Y��4��sJ��ɂ@�O�S��T�Ji�����r蜵�4D�I<���zh�@tm��v�UiL���j6ȶ%_���p,����m�(p5<P�ڶ���d�F���\$�`#y[����&2��l+�g:�K���(gq�q'F�&CDӚ�������~���������3[I�
����ΐ��,��ɔ��"��s���0��'j�.zCulwN��xn@��m�th{f�:�P/���q�y�}�7��ÚJv��F<��+�닪>���`9�7'Ӓu��SS� \؛F֘1?�.w��I6].�[�vUW�3�>�}{!H�6_452?%��?�1"�O�m���ޱ������s��{�q
�Nŝ(Y���n5�5_h~ ��
����Ϧ&\E1j���u�F����bǖz^#���T��>P��B�t ���-���ov���:�di���-��8� ��H��'M~Q��<0b��F�n���z�9z���o��&@>�+&U��[z<Wۜq��a���l;~��$~8;���'n1�_�G�s$�p�J&��aBΧ�o��+�B�!���O�kL�щ;�(�;�i�ݞt���裼O��(��Y�sn8+��D����
�r�v�i^#	{�~�N��G�Kw%+�4).�JU���Pw��%�Wz�V�
���
RP,ZM�q3�-2�����(�ѿ����iv��	/�hR
�K��r��[�nK�/�9۽��K�r۝1V��Q�Z
�>�" ���Jm�
���+�8�U��2�ǅ�`Ml����6j/���D��WPg�bH��y���&;aLx0
�[��4'���ٱ҄�3� :�4�J�Ư���"��_�R�N��EY�N�G��,�VwP�"*���A|6m�Th�&?�0��!�c��������h�?���0�.#���n{� s$}����'� x�P0���R���L��8�j�=%���$��ʣp��R�&�3��w뀭Ĕ~n]�Jj�9����)�q����]�5�z%�W���K6���]^�0q79ҘѬBGc�_c�N��V���I��P������>:� ��#�d�2�9߻W��`��r�
p@�EL� ����@�������ｍ����l��c�eɋ�q.��K̓���A0�n�����O��9�\���l.N��퉭r��D2���� ]�<�y��e�nQN`��Oh�)�$
��s��>2��bh���� u09'�V��x���m��N��s�f�	�����/�;	£3�IE�E�>��A�RWF��v�%���W���:`d	��͟˰'����vE>�0�reG��焹D���ZP�IK����������I?6��q`�:�B4��(�e���B��n4T{�;-�I��eX���y��b���^��9�B�~�!VE;"���q!�`F���=��c����gW�2�oH�X&��p���H��R�Dݡ�v�T*+j_k�@�b�K�1����(7���hs��u<p�$�@'����@S*7@Y�BW��ʣW��+Ebclp̀�N���ETN��K�� w���9���F޳�V�6X�R4�G2N��Nz[G���a��&ʑ��x�����O��[@Ye`�kM<��{ݟ�o�m��@�0u+��\C�yg}*��E��x�����%��z���ҟ�r��	��\��{^D�1�^#���l��k�!n}���#�� ����,nΌo�����nf�O����.�שH;N�:�¬8f	w�ى����b�����!�����O�z�'Vיg:���2�K������i�����q���ӗg�j�X�H&KB�%]�{9B�#4�ۦT���u�ba�gS�8R�ή~�&r>�-��n�s~�<���w ��ơ��mAm���g_���Ƒ_멤r�8�a(
���A��9�����]��8���k?2po�n��y
���"X���k�j���v� l�Ax¼b� 	د>2m:f����-A���oG�3��#L�O,e!;΢۳o��XV�	����o�9O�@�i�& ��x͵���˅^`�������-��܄�b�d+��+&8�Y �đ�}�@�T�nf~�H˻���E��#._p�}|w�wB?K�_[)\������ʴy�o9��cWlW�*�A:Y�`�������%I ���r�eѾ�Zח��Y3 |GkN�(�ھ?�ne�*z&`��D+'��6k+~�EzF��:�c���y��Br2��1����{�Q�\-W�q5���滲�)�0q��2�A���=����|+k�:(��?,�Y�V+���0;�_KVqX2�,$!�kH �2�|���y�L�fmy��ڷ��p�����-�T'nO�z�@�;	�l�q�sM��;�&��o0EM�}]�L�yGɽz���X}����OQ>(��F�u)�-��6�n�� �"�܏r��U�||��ŏ,Fm�Iw׳��6�pp S-�s�T"To�K��G��6髝�D �G��'�K"�� ��5nJm��B��'��K[���!�!Tq�Wz!q��*��!z��礆B%��0�����ޙ���nM6�z�{��
=-@���ws�9>]���s%�K�͜�s�ߡ�e�J]��{�n'�ڐa�8��xU�fԑfVP��mVRp����ęD��9�C��a��/	����F�a`?��F��UMa��~$�����76�>��v_���B(��T>#��"�rа���!���8����i��8�4#ҿY�8��"�+�+��f��U p��>:��a�nK�� ��5ЖNs��|3z_j��}�J�Be�=z5"�2�>66�y�&F�Ѵ���yhq�w�v`�n�3�U����@Vp�>�Yy��f���c(n).� �B���!��q�����~���#(i��q��E����2�7��~�bP?��@�򣓲�%L,�YJ��@/ь��nJ܆5�n�17���qxL�A�7��j«ZBÄ��lv�5>}��g�+/����}ŕM�y�R/�� �[5���I+������"��Vr�Τ��㽳�7���4��z��eG�.���	��ͤ4��K[���N_�R�1"�ܘ$*�v�ЧN�vQ���ZHDC�r�CiwY�L�2��E�B����Ul2~i� �t?�S��$^9����HH8���A��&�rR"�@t��b{b�DML���*��*�;�@ݭֲo���m{�����n�Ӹ��WV|�6���s�=�g�n���])�@]؃6��.>j����S��v�t�r��M�B04�< �ϴ� ���w�Ȃ<
�Um�P�q²����	�~Y,0��z��(c��^Џ7�]Ʀ`L�v��*\�TT�7�P�=��~�$�d����r,�dvk�~,a������C����F+j����1�
'����/�2E�}�s�S�`S�2�fP�k���@4(J����kWo0��Y8칀�ooT	|#D]�G�8���T��j�t�������F
�a�(�n��5���s��x�(�y��_�ݢ�05��z`�n �:�y�!^��C��N���U�W����O�Y���M�f+;���ɟz��+W��Z%+m+����8��W&X��\�|hO)����5�%cKym��+�ƻ@�>�v㏾�8��k�n˄�Gu�ޮ1�F.^��#9�{:�/��A@�Vn���g:
Pz���_v�Q��s���RV�@�)r/}�L2���x�k��Ъ�4�r��1 �����+�4w���ۅ=9@o���h:�(ND��h��%�@e�<�J�q'�����@�2��9��s���2�[��_����{�_�(���S��8�C��?���4���v
�~�?0���G�.���%�����*z9KFD�gP���Af:tRe1��ԩt��^W�<��L�h������*Lԓ���v�����`�H}�$�A�yWk'K���V���#�x�(��}%lp� `<T<C�L+�K�Š5e0P��P�ca��t��e����av��=�5n9��]�P�;�d��8���D�Ćca9z7�fԼ����F(Z;���V2�L]ӡq��X��������L3�����g�}w����3��ʹ����c� Y��-��C�c�"3y���U�aW5������w�ȵ8��O�3X|�U��)c�Ћ�&u�͚���0��m�83cs����x5=ZVL|�+	��^�oo\?�{��K~y(9��BOKJ��]@,ylH��8~���Ch�%�%s���R���W��
U�e��UJy�;�|�X�#'!���bF㷭/JXþ �ӿ�)�d�1I�i�k��8,�l"��LO�1��J��s��5�Y�@�6��6\ �S���&���$n����B����wAE�cx�D.�~����^�Q�!C�n�b�,�>~���}�T���Cx�"���:���ڿRog� �"+�:�v�9��<��s6,�\9����)��v�O�F�U�;:����c����dl��rԎ'Y��^lĀ��O��Ie�,�
�G����������T�(��o��-�7����"h���,�[H��9L.v��t�\�c�`;�S���*�ݷ�v�^Q ��aZ��چ����R�p�sm�tu���'ȯ��!�H(�G/��a�5�L09����ۺ��n��V&�]�~�Mh*nM��&Em�RD���@������� �#h��3qP)�(��Ht��h����t;R��x�l��o�`[������𜜎����2�E���|I�V��=sC̏Й���%�9����Rd�N��rH��Bf�=����0c�H,Q���֥%CO3i�åz.�1���_����"�t�}��ɹ*q��>�����b1!'���P�r���cp�s�'T>OB�6!�9\,F{����(l����?ui;{���Q)�u��J4�, � ���BӣL��z6��x*\ʃ�/�����>����X	�z��[�Ɵ��&�p�
D�<*���[�ެS�4-���@;T���4�82�>��N?͆Ydj�3���K���
����Z�����wxd��Z�U��_������Wk�4 t�u�8�f/��Tzz�8�4#���M.n����Y-,��3n���i-��Bz#s�ߎ7%V�:�Bm�I|/�Ś���ذ�ͽh�d�sk��"؉s%r��]qa*��|���M�m��5�zXHo/�������s7�~����C�9����#��+�p��g�U�`��i}x�S�uL�����E�6K��)��_g�c�����E�/e�8����DZ�j��ꇲ�D�B�S�����b�����9y��r�$��/���s�ؠ�>��_�I����}W�hz�#�L>�=ט�p+��[��FQf(�/��[XW^�g�h�f+g��"�x\��QZ|+=�.�������Y qi���ٺ+ӝ@0�J�,&Y/{R�U�^��%�{�h������`'#�Xog�$��0տ
��%3.e�V�Q�fWH_��Q74`�ǵr��2؎|[@�_���U��<����*�&}s��ts��42*�q������������[���E&6�����cV��7Ւp���C-o�K��h~G&YH	���]k�Gr�A�5A��ӷ|�j�����96C����4�f��U*�%�#N��43x/	vt�/}c85��-��imhBJ�ۈ��osw�5l��mğ	�k����Ȋ x����!�z�ݷsWg�.�_���B}�������a<�g��!`;�P�S��Uo@��y2�۳e�e]˸͞��{p�Q!�Rd �|��ւ��c������r�M�ԏu2�I�Ej�J<-�q� 5��Z�.���̭��v%�<��m:=�ӗ���y��{x�zDR�NjjѨc,���
����T�i?B�'l!��'�.�o+�͸�	-��A(�*u����(4��1s�?�*��%e�nl.c!y��� Lo��Yiaψ�5�}�'��z���Z
�e� dܫ%>GM}`�]��	hԿ�W���G���d�����r,�"�����Џ(1� ���l����T,n7��?�f���l����U��PLLo/+�?�z��{���K��{�a���$����+�:���7Rw��Q�R�{�+�:���_9w�C�;B�?���,-J���"!�4%o��L|��V�^(0n�2�sh�̄����-l�E�HR�\Q�/�E�F�4�/lB��"��-�[���*f��<��A���jB�k�����E~*.�������è�����/��w�l��{13{��mo���PV�VP��[�V,w}��Ǟ�(��_�Ev��lZ�MVWi�Zv���=TZ�
��I�,(Hm����g�l�N�?l��ƞğ�p[/`x&r���Z�E���PSP��컓�����c�F�0q.���o�cҲȍ�W	 
��D��:b�!'Acr"r�G�kCߚ���e�8sevٌ�L-�n�u�>�PZ�z�	` �|�}kp��*�#�-��'�0��2D��5V#^RڿXS�2p}%S��Nm�����_�I]������ ��FU�3����n�%?�=�ϯ����VX۹�}X����7�u��n��[O���H�m�	�������(e�hf;F�����ꃏ"�^��j��1t@=��g!���K$�@����V�y׀�m�kK[M���=3����L��{w��1ɩ�-�NB�%S2�vsޠPY���N�s��Ս�	?K����x����i4�-s�j\�E�<����l����,n��	�c��m�e��6/o��9/|��̀��j4��µ��NԊ��7���ܭ�O�:�-5��� �z&��7�:��f����mg>�흖"�g�c�f<�g�w`!�_�pw��������'�p{T:���vTc��z�h����cO�Ӄx��د�M�FW�+�e�����G�F���e��4V�]��$��-��ZD�[���-	`Z���������IAT����V��jM��c뚎p�&�5��g�xv{l���#�$�h�aϖ�Ԫ.0j9�����1(f��OG�<GQ�N ��+5Å1�K���=_'����Dq�_`�T��  FӢ���՘-{��\$g}a{��L^��gI�y>�A���z�0�,Dj�=�j$�~3;k	�͈W&���&�
�ڥ����J�B.��̦��U6	9v	�'���>�A�.��Xe��<v�ԟ[��h�����7H2��o��]V��}�\LsN���k��T�HpIL�
L�o��l����*c�UZ�>C_+E/�}�Z>�f�i�w4��-�n������$�5���iLu��L��<8ɶ�(蹚H�'HI����K���!5d�c�����d/��,�g��ab�-A�|K[�>�R���p&�C������m���Pf<=S(X~K5���iw!����xb���V�2a��GP�k>�RӖB����q�D
[��
./]�����i���J����'����j4�F+��yΞٲ;T=�����KJ�+������������]G&� ,}3�ka�x�ƞz���������*o�맻��O��WuG�3v���	���g��y��%��8%��#_�q�9��;�c�������T6<?���+��S��(�3?L�#%� S}�������:+�.��ǿ��7�F�E���P,�O��ĳ����Z�q'���Y���O�zh��]���k�q��}�!g(ٷ��W�+�q��.0[b�x���+�H���Y���ָ��bT;o��J�_{%�:��.�n��5���*�?�
�j�Pe���H\��[�t��6����{��鿷�k)f�ؠkϏX�����)�Ij�r�y?Ŗ�"���.�S�++��̚_z�.˶[<3�lf�OZ@�18�{3/ni�!w��t/�r�Sf����A�q}�V���Y;f��uBIӉ��`}�s���Y�' sK]��i��e��������P�ྞ�=s���U@V�Pv��@�^��7+�ϗ[GT�[i��Ӽ�``�XXsɞ�s�NM�V��B��*d�Հ�3��^
�%E[?�Z�i���6c�F�:覝$�i��	���:�

Z��"@���&��+�55J$oO��Lzc9��@t��v�s�K!����$� ��Y@z�3z�­�Y��"uL����"9�k��㒟�<�!�.�S��#&j�4+���t+oa@Ш+ab�'��Ix��Ѱ�S��s�}�}0X�<��f�L��~��kj�������|���ȥw�'2no5�B�$$��&[}�Col�T����g����ڧ����Kk�Y��a��M-�sp������	2�TK�+�ُ��Q�۹�Y� G�����a*���
M�Ɗ�X;�\�n�D�bȨb�p;C�XHv��/Hƭp�U����8�R۱nh�\;&]��T��u-0�q>ִ�U���橼`D��(5úVg	{��qv��y�>WP�n�+���Y�AS�*K� ���t�u����Q���Uܙ�6_�0�˕��=c�C[.K�����9C�|C�~"J�%���?�ŲR�^�CTܾ� ��-�zB�w6[ϋ �5�xy
U�V=��KkaZ�������*�v�r��D�"#�'B���v~rC߰AS( ��$+�D�G�3��W�א{��$s,/ߙ��C�"<��jR� ��d�U����!�2c�S�C��0�$0�ǵ󩝞k�3�{���Cm�!��=�x{0Ʋ�+jþj/����Du�\@���M�/7��@-9A���g>r�Ҷ���|�~'�����D��>�ny2VG�7?�2	|�~�.|��z�W��Dg�$4&`��I����iÿݽ����TY�����u�B��
iП�BdS��(Қ�2p�)dM�>	��[3�M�ҍL��-�>��{��lu��ٺ�_��'�!�WT�l�3CB�������s��_v �M+�Y24c��8+q���˷:�n��9��h��*��QT�Npp%e�&l��-�%*�D�V*��* a'��� ��������5~vE*�u�nb���|�5�W1!<� Tg�����z&��+knF�T*޵��Mv���G��X:Y�j�	́��H [���������7��b���Q��nNh֘�DTGh5��,��h�wB�e��A>=h�����ƌO�	����NQB�����5���H%��7�~�t5��L��Vʧ���?F� }!��ے�I��Q1���x��� �ى�Vdyk�'�d|�^� .|��/Ú�,�����{f�O��g��>�E8~�ف�f�l]8�iU�� \{��Cqd7?����(�dՇ��}�~)���i1�L�I9:t�nt��m�k�J�\a=cA@�Y?�۷�kFɼ���C;��#���l2� �U�OL�l��2u�^:g�K�_&[7��=�B�Ϟ�U�;K���90���6)���qF�*;O@2}�W��*b-fBܨ�y�;�׀/:�Y7B� ��L<x|�A������{Fd��A�S7y�J6	k@t-�f���������.�����7�n[��O�ѥR �e��i��{vˆ[`g3�x_�%�p���'�I�:�9#/�շ�1�t�������֎i�0[�S��irW��X���\�%.5�Ζ�.��F���St�艻������ �#vC��3�ODh�(֣�֭�"��M��"��Qk��3��	�A��i%w��,jy������F�vv�Gc���MG%�:�˥���dԡH��^2\�e��6óA��L>����p'pI6n� ��@XE��'W��P,b.���=a0��qy�]���Q[��|Y�a~s���y	>��Ҿ����/�ԍ:��jy���	�c>/e7�lpZT5s��Hg^��'Y�s	J�̅\t]��`������ͬb�B{J�_+��L�c_�Y�\���<7Qܶ�yPc��D0;��.̼;~��s�w�8�;��H����a���Ug������$�'&�݇�@Jt��K ���
 �g�;X��e�P�l`�'5���!�V�C竢�j֌�O���t�L7oܗ��A,�:ݷ�v���ݮҗ��;����ɞ���N�-�[��N����c�5����J��n�A��P�o�0��Á����F n6��k������z�l�(j��,G�5L	�Z�#��"^}v.4�K�����[.Y�ް� iZ�y6�A%�>]�(̟��&b0��!���Q��"3���ñh��8���UJ�]�׸z$������^���L�Rw��5�y��g�}�� �n�ɕA;����+ِߥ+mc[Y�� �����p��j���R�`�NnB��պ:��ԥ2���+6 �x%LG\٧�w�H���%;��6C2����\���]�w�S\
�B���v d=ݘ90����F�(ï�?���2��4�a��x���69�� ��Ԓm5�:?Z��>��md��$���!��pK�,���?�����#.9s���F�/�"��X��͘/"�����[;��O묒|�g}�~�����<XGō�<�6Õ*X�n�؁�V5?��P����A>�h��KM!�a�^���'�����?�G���[-~�7?�U"G�e▢�js�C:�hݾk_;�I����4O�v�?�6C`� ?vl�u����p��v �7����a}	=��)�׮��O�9̢)��=�C���_!�p�;I.�2i���wY`�Z�E�����K�w=#-eht���VP�-)5�2}L�{���~�o�LaA�(: &�yw��)-�q_ε��&�G.bi
��Rѷ���)�~��]�}q�ϴ�۲&|����%�r��>2	�r�풆p���v[}�K�mX�Ͳ0v�WjwM,-����dU1�7b�"ν��V̻��}O^�g���z݌�և�����U"9�ܓ�#�.Dn]�5�42N��u>�+�ng�e�*���#����'���7(��s��U��p�h#�lp�F��n<�u�s��t�2��~@Ӑ����qf'��$�)��4�H�Dx��;���KTk��3��,cV��T#�!��p��}��6�l-Е�W�>=ޝ,|/y��:�������^�LZ��o�����~�j��"h/��]Pa�k� �-����i�wS��'�G)�Ǵ/0�_}ʳ���t�>��DK��(�t\5����~dS�Ӌ�eZ��M*�T�FQ�7Jt�RVHP'������y\r�C�a8����5,��� ��FP�zޱM��ց�o?��>�n��Y�	E�˰�
ؙ��]�	3&�BUa�@�}���̰�6ht��ý#,�u�{o�PP��;�7�ޙ�<� �&�9<^��".+A�Coh-Z���Bu�g�)�	P�P�� �[�2����Gf��Ja��~�����M�lx4&�j�-ыk@�wm8$
��抬��y��B�E�g���b|�2���u��X�K"j5%��%%5~@�ӎ�B��wZ�m�Z���k�]� ������l~��zf��lȭO���i���%S �E7C���p�GR!n�0=	��ЉK+g���m��g����:"�y�*u%��!uW�x'i~!.v��%E�gO�!�-��@����N&_��۲���K��Ѣ�����-M�O���lK0��z��4�'�íl�44�r��x�h<@}�F����M !��籪������6�r��t�rF����P�c�R��s� 	�?rT��g��R���^�g�r�}���v#����>�	Q�$���p�=.s�*������[6&Y���g�N�v�v��m-�M�\B�*�?W��n�ǌ��7�C�܋�R�R!��P��2�g�`�(�������ڜ�y��W݂��H��>��tJ\�;���ۙ��-V8�FqA����7��x�&�E:�`�J3��q�H��IX�+���L�Z,��1܈s�6E�|�y���ۨ��H%�Ĵ�?�Raw��P[\�����~�C���'FL���Ͱ�N�-]Bס�BK�M	�c慦���I�X��ˁ�]*�)���(�k��xJ��1�q0f�ԣL�h��*���7yZ&ּ9D"޺寍�������.˅Cg/GpC����"k�����1�> U����-zI�Q,��� '��j�x[�6U��>$"Ӂ�A���ҩ�~;ub�-Q��]��=�t�*��r��!z��/��y6�
\�Z��H��Ma��&P%��"��+  ����L*
J�X��ûkEt��0�י֐y�p���_-ZoJ�D����x���Fn?��\ ����-�Rc����21����Ǯ�����kB��	��'�бb��1�p��|��C����x��SbC|K�iif30�1u�_V޾%����P����e�G���y�jL���Yr{�)�Nwǋ�4]iD��������3�P�N�u}�sά�sp ��ʝfۈ�S�@]���p��%�����Y��:���	���ބ�Ktw%h����y#��|	-��yEH{1Ii��!�K+b+l�y_p+���"et��x�]��D�z��~}�JOSST���Y/rS��@�O1�{��4�o�ⵄ�۟���EWy	X�Ly���l�����+\�����1�5�6\w��qbTY���6ã���ZIQ��i����+���o.nn����
�3)o�oS�)��d~ʇO�Z��ʀ��u	u��NN�g�8X����͜��,˖Uoܿ���5o��D`��b��gp:v�=۲9y���t�Iq���T*p+&C�f���kV�>)E�M	����֝ރ��#�����Iog��'ҹ�Rf3�l�]�Xb����ܹ��a��$*!���[�zg�%�^�JJfd�Q��L�b#��}Y Ѹ�-S�Y�Rd%!b^%�ȥni�����rt��籗(VY|5_B1M��<����MI[?�~@l����r������`�����W|e��?�̐������qSނ:2�.��4�G���-��M#���e��=$Q�n�c�q��4<"Nx-_}���@"�0���yF��_�� �����4�{%�;*:�r>8�.�:�ɂ���u��2KH��6^�D����ch�r��u�5VD[��Vc�� Od�~s6��j���C���.uF���M��Re4'22<d�ڳ�L�H��~o|>3����ν
M�z�
,��('�߀��J#���-����(�Q����rl���,9f^춒'SsJ��{���!ݰ׼�I��M^�|�R
�}�<nꎌ�CZ��Ib��\Weç�X�)5��ai�T��)�g��Y���ћA�� �������4y ]}@���1��\GXZ&�v�I�
X�m�\�wЍ���`�\䪷B�"Df���;@ȭ�g
���`^){�B��jCW,ӳ����'gx��&5��\�tc�
�7X�k��ڞ����6Y��Y�X�q�i�>sP���*�ZpX�h��*K���jވ�s��.O ����	,��,���E3̧��8�Sޘ���O-0oef���O:^ޣ�tlq�C��w��X�㍍&���uu���U��@'�Q��f�hGT���yE	�B
��e���o�^�  ;����� Ⱥ���f�h��g�    YZ