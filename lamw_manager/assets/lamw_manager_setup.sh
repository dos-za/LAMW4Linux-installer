#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3412897447"
MD5="ead10b616910be58af2b65a3f0c5de57"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23356"
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
	echo Date of packaging: Tue Jul 27 23:02:50 -03 2021
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D�o_�r�5�]BmJ���M[�=�2�����K_*�r�I��ộ2Κச����I��ם3b,J���d(V5[ÞL_�7-�����.����!I��{� �~]�s�bmV�:��M��gKg�\�Zh�T =%�X��O����u���5�s�$�1����ʉ<�ӯ�j�72�O`�k��V��p�8�?�$����ew�?���֖��x͑�H����Qv�^�H�QL_K����$��p�מ��T�B�I��
޲��{>�{A�{���f���,n����Hs.�������L�H!t���Z��ډ�V���2�bMi; �`MD��k'\�������~򶨮9`h����4�!�"��۾��`�PWv4B �����la� ��#D%�v�6�Lv�ڳ.+\E�:Ah}��#�x��W�V��%Y|���к'�1xN�L�y���]:��E5t�E�i��:�^��C |أ��Q�|v@��u_q�)|2�PXE��+���Y� ��>l�GbT
�1E�&�N�����+Jv��6�qو��$NT֝�Έ��l��H$84{f6m���'u�'g̉l6��f���f|�~z���iy��-��hIy|�t�9(���,���yJ6�g�-g_yN��G�d�s�R�3X��"I%جt�V�U��f��Eo�����N���Ԥe ���q���!HG-c�%���ݒ�^"L�/��_����vZj�Q:ja�QN��.��Ew�t+�W	����k���p���z��
Gw�_sk�0�n�I��CYq���D߻}�F�����T��<���f����ͅC!��Մd�Y�)D�+�i�Y�H?�����v���}/�ł#3tf��p?�2e�G��!zM7��:xd	
Q�^U��f?��>m^�A{HFO��h�U�K]<��?G�pūl��Q���\��s��3:bܣ��V�^qJ�X+���;���Hg���P�����C��q"����.c�sމ�Q'G�^HP�0��2G=�dyo�)��u��_�����?�4��-f���b��O[_�E<9¸a��y��e���k�a�d��I)2�-�c'>}4k�6v�V��o��6� {�Q�#U9�s\��i�tY���V�!mP��d��Q>�.AU��k6��	ʍ2�ULO�����������]�)p)�����lS���.����qF��|����t��Ń:���4@���>A�ڴ*�~��Q�����]�)3����LMB{\ţ����/(�T�bO�I�-�v�+	T��H�:xJ~�(Y�=�2���bPw�m�a��	���m��^��,\��U͋^ ��Kb	���H��_��6ɐ����;s�O�4�U6��$�B`���Yܪ+��7�{��h�!��'�/QY�r����l����0�TVh����:�����2ǻ<�C�֯�vo� �"ք�ȍ�g��7��,e����9
����Z8ΐ�j�u<D�;�Ef��ڊ��1�2\�	����OSLR=a_
w�:f�C��]�n���s��U�c6e!�Dյǚ��p{����&H~����O;�c:�����=��A[BV���"��X�����o�9㗵%�9����[.
�t�k<��G���ßF�LkWL(�7_�:ڭ��%v?��d���	�e;r��H�&����Sb�*SS�:��tAE��r���Bs�
$0Wx�4�|Z��X��Ō�)DL��p�}�~I..�߷��wb*Y������*���x��"�dS~%1h��9�Aц�{Ľ��،��c� zHA���mi��UƷ>>��~��$�� ��`Hr�
�m��NQ���b�_R\���krp�J�yyu(ۻ1�@�㨅uL�\#"���0�!���85���tm������L��=�u����|Q���j]υGT���u1��d\�4�>_3Xp~�MޫZޘ|�F%�Z*N����TL��!yU�5���-ʮN���@�+և�k�ğ�k.�#g,�c�) �o4=��Yڳ���m��Zi���*Y�主]���d���9�=Zs�(/q���ڕFe	k���u^PW��1�n3h�X�L�)_ta���u��ӋG��y��C ��"(�$n��'pA�rv(l�i{�$B�����mf�SXT5J���e��W3!��T��w(�~���K!��
ܦ��i�@�|]�����$h[�ԝz����0���u�Ye��\J!��z���ܛ'�e��D�(���Vr �� ��Lʼo���l������|�Vb?zÚ�^+G��}��	v/�Cj��݁<wQ��{K�[(¸}3�ҟ�6{G��|9nYt�������G�Ⱦ&�����OI�LaA���ڈ��F�g�������͐�2Si��ox�<��S��J���W�?z}i��ܾ���~�A��\��C��4���@�O� >�d��A��xϡn9������Sy���n���[���P��D+J���pX��"�������_3�O�/Ѱ� �����Y>�V����̿�JK�ۀ�րh)��Q����x���\�{�Aj�����`&����p��9�D,�"SG���z���T��0=���2ds�15�¾F�[QLs�	O��K���|y4�m���xܐ�Sƀ2��	]�!���o�%`�=�g(��T��}2t�R.h��\dKA�")|��[_��5��iC
k	������ͧ�L��"���[�� E��E5�*�H�c/�y9HJ�j�D�E��+��RR�5��3��^�g���+g&@w��>c����]('@{(���,�p�ÚxR�6��µ���CG@%�R�:��C�W�5[��`	9�v��{���6�&|�Z�40����t@��=��`\'��#Ik��7�0&o�G��D�j�/'�nǨ�R ��r�~���%&KT�}�ˠ�������*�Wa,^a��=����њ�����h�桴�c�k8d&q�<�h����M5 �o��L�E>v�Rk�ّ*,	>&�yޫY�dT�V�Z�S�'��^��_�=`4.?��+V�!�� ���J;Fv���@�3�SKL�[c_��!̳��g���}��S���� �����t쓜����P��<N/	�fs�>�sQ�Z�=�������V��H�A�*s# �V�&���GtwB\�TN/���+�M�h��_�ظ�?"��;�І4���hW�V9��Ȧ�v|���Ȱ3���s&|��⍚"���p���[1j���io��N�Df_��2�+mrg�lE�r/tR4�J�S�Ҵ�T�=�9 Ҫ�:C^5��E2�M��V ���L_D�n፮+(��h`�HhA0��%��� Nd֬q(�ݚ�=��"���0�,��p[�>�K����,����̬�������=v�.�ߵ�Ơ�-�{��ni����f�N�#�����|���jB�8�sB<�vT�_���4MK6��@�����'�2G��1�V�3�J��\���B��Xq�
�{�
���������+|v��:E%׺�^�Ge�,��ؒ�҃��Q�fp	w��P�[b0�ҶHPtÉn���`�t�g���{c`(���צ��=Ce8,4����?Y��u��Ƨ���I(�@,DQ]Na_�_ a_�ݙ�Ţ�(��`n��S�Dt���΄	�'f�#u}9s��$F��$P�������ɉl��c2����^ø�=r�\m�\��O�}��G4��.F�j���V�M(�q��"�-�8$h�\l�(�W\p��h֘/��J+��s�k�mB2>�c�%?k�DI��~z�Ϊ��`�[>��UbY�z�N�Z�2�g35u3��k�m���2�ґ;�l�m�ns"Z)l{��e҄�/��>R�?/Kö){�yx�"���Z���uq_ʼO���z���F3�."m�
6��#&�"<�ۑ�@�����G�y��KvR��bg7q��~y$��)É7d��c�%�? �/mwM�}"��?X�ߟ��m�� k�a���U�L3b=�Tˎ���
�u b���\���h�8݊^���Z>��馈��R��@��k�q�.�VG{O@�lV�^�y��G�lt6�1��| 9�&:?,�;Ⱦ���RN�U&�a\"OGV|��~tw��_E�\�9���⼏RL�wH��w���;>�����wñ����������z��BSCN����D�d����ޗ�b�n�x|�ŉI��p�6�zt�csV��e�w���VhO)?�'$�E�O%�K��.���
�=(�a�WB�w�!�jg(٤�����f�z�M��Va�"�͋�t�?����C	���?���!�"�xc�I11BQc�W�	��rw��{�_�h@*��%�]�욢Š�2��b+���?2P5A���)#�"��|��D+E�+9�ΔF��6�eS���7!8��{�?q�uZ �38?=3�0Lۜ��K`z��
i��~-��#�c:�>��N�H3�k{QV�l�r�\V���rJ�ӡ鹊o�B<
j�aN�C��Yzf���PE�1Ѿ.���߱=T=����3и��l�������1�VS�+�~�����cs[o�H��[�� ����ڍ�$*:��t�D��}����RbÇm�X(�8o�"���,��d�8����/�����Y�[�Y����B�.I��|����ͿKi�]�G�r~��	(gKְ)�6}�w��2ϭ�2�[J�)ʮ)���o~ޝ���+��I�?p���$6.g��$y�F�Mգy�K���;i���������}��و��5d"�rzh�N���E�y����h�ب�D�w^(b�ܛ��6<8���D���� ci�d�F��u���}5�h��)sgg^�(3���
�H�k��<U��o:�9�p�]B��n�3Z�}�_W�϶⋒�>n����Zpa���V�Ou�����	4k��G`�H���&X����^1��LI^�z���	n��.~��.:�{o���$x��3F��Ӆ�/�����z��)L�-�.Q�V���;t�Pe�'�}�PX���{P?��^@���|�D��z�fy��r9�0�y4
���-f�z�\����voG�����-��4�$�N %$۾h����.�k��� ��q���Ω"��˙S[�OK�"7p�we��&�0���v�	����ŪPz�F�[���%�&�&�r<�oW�����WT��N�uK�9l-�r���ȴ@�<Y����e�����j�U��M4c� YMV瓴X#1�5�>��4>6�HD�3�x�W.ȳ�i`o°���A.ϣ�)��	�W����gl)���]M�<Ǚ��ڨ�4V�(L#ȕ�k�)?��M�g��!5P�ҙ���f�D�a{��0<�J`ڑA�7ژP0��'��';0Y�X��+�\��-&Ct��}�Ms����#g>e*<H��S���ؿ꓅I'^�t��"���5,��8}�R�Z[�n���*��'�K�*p<dj�"�QR)!��6l�(U���
��Ps��F�#�JJK�k[Fv	S"�M�KN�/�9B�w~�I�����]���pp�.�����CӮ`���
�ا0�Cg__�#�A*S7򇟈r�񮀲�j4��i��*�P����v�>W�d�	!�i�A��,?J�CG�Ad�n�:��0=㜪x�ɳ�!�ɷ#�il@�ѻ\n��b�U�9�1�⋽�_��OI2"j� ���3��cЦB��%��	hJp�;rF��J����ϔ�H�#nJ1o�V1�x�%��9��L����F��{Љ�I��O�w��tE������_t����K�1��͸e���q旹Engp�͓�v�0}�ʕ��p�'�m�Vb�"�I!A����=��t�N��':[!�\�@xR��>;���r�}�?�4�{'�b!���ٝ��S�d�9��*��8�2եx�w\���l]_#ȇɖ9rd�J����c��ݱ��ح����B���%��bTAGQCb?h�$>e~�ұÖ���c �QS��v�T]�V>���Μ��*�exMc��	;޻[��~�p�l*
?��H��ܫ�M�;}��B
�w�0;�x"�O�#�H���t	5���W��kW$l�^�R�#+��9�1<���ϑ�'l
�wZ ը��EG�mT|ʿ�k�v�w��~��C"B��mZ<.e&H��w�U3YV!mS�ڎ���'�`��~�@Gj�`Pd�K]�b���n�oWҹ����}���W9 $���M�á4��\,2��@) �OC)�2��� ���C>r�1��*8�r��_��<�׬���͹D���h�N���	��-#?�T-���V0������9���N��)�h}�u�D"!
%��qf"��#9O/ǔќ��.V��x�G���Ƙ}�R�M��_���ˠj���Uq�z�o)�����|�^ '��S>���P��lR�	Q��8)���z��(�/[W2G;���_l�?�o��,�c�'�ɸ�� "AJ���78���y->�U�¾���;7��P���v r8��)J��ʓ�/hf�M;5�<�2��%r�iAw�KŲQ�9�~��}r���PՖ���i l�tWR�頒��W�J_���?�Q[ҷ�����q��f�U0�I<�&���-��`	�ܮ߰�D�����NC,����J�Ե�����}�;�ߤ9��_�����uj�=�SS��d[�r��uj�N_5C��� LK���'���E6��e�]�e�[>j_
.W%�j�����$K�-���|&�vy�M�݆���ɷ�B���S�D}���EV�К1���Ʃ���wC?$Bz�����q*.�r�����B�V#���������\��nM%���~:7���bn���������`B)bď\߅#8�A�^3�T&�^��T�$�U�ķ#$�����=p��6Ш�l��;�T(v�,�ٿLSs)����\㈐ �������7��iȍ����Ren���_^�m)g1b^l��[�Xe�7��S��|��[ߏÐ�1[O	�UA`��z��)kK���?@��'(nS�9�4��nY�i�\��o��'%�N�H�͚d�^�Ⱥ���]�Dg�qt��~ϩA�m�e��oЭ[��H�����n[e�����?GU=-`4�Q��K�:7�Eu�`��:����r�_��.�Mx'A�&	7�[�����sCWcz�������G�U�f���WuUS�)'(���k=�(�,��W���ظ�T[g�R�����2Xu���v�ly~I���j�c)!*���D�%y��4z��w�����q�*�s^<��A����r����1�[����%]4n��$"?�B��0���0onz� ^4���%E&�V�Gt47_8�^��d>=�U�:@+�<>���s4<��z}&:�Y�V!�G�t@z�F�0�	��I�Mx�;'���]�?;��ۢEsF��Kl�gWc�ʋ���-�$���P��3S�|�`�#���l����1���٣���!�:25Pd'�%ץ?Q)��yâl�h�I�(����*�;��8�F� 3D 6��6G�����4�_=аæ)Z�]���S{p��'���U�{�-�(ۇi,�Y����u���	7%3�.�z�{0�������پ1�^ӍZH&:^ǯ�mZoT~ ��ײ�)��'�.:���|#����[i�>���ͻY�r9�`4_�L��i:V;%Z����n��˹g	�-���way7Q�� @����p�O����IU�N�V$��"�U�I��?XF�����K�7���m��v�"��������ρ*d����2voW44�0��dwǃ�=!)q�>`���Xָ6.��(�N��m���~RpTV �ney�b��i�7������*�쿸o������!�gP׾FG��|d-bH�3�{>p΋9KHZ���C;i�P&mCقc�ަjz��O�.�˚�ˀ֙�>������Lq�}�J/�)�դ���'v}�� �!5.�ʕm5/��k�p��^rm�"�X�1Bm+ޜ4��M��V�;%W�cK�mC�G�L��ɢ���x�4�%�w�(�k�$e[j�NV#L���b�C���<ā�R���6�r{��;@g;�a�z�]���Z�Fm~�1'$T@wD�O���I^R��T��@A�k�^�Zpb��S�8���n�+W�u*�k��n�|i�<��L$BY��vN�[�������Gk2V �R�
��3��b5_���W�Z�8���w7�!����C�bS*�	}����w53�Zɠ�˕�ǥ���v	��w����m�7�"�o������Th�V�J��P���K= R�
F�bM��s}IYP>&E 
��B��WNc�n�D�u�tz���x=!{���
8'ܬO�a����+� �
o4.YB�� ܕ��:��j�πkVj��e߅&��+�2s!$p0��iX�4�4�f*��!1	aq���,���j�� i8+��i��g���sJP�k���Q��&��6����L�0��LSIk��_*]7ED��#�a�����,;��:�=3�j��7�l��2/pXW��S���~��{�7�?�y����h�vp��A�ѳo"��B(<d��_J���iW��1����L�I���I�ܲiq���i<;���wU4E?�L^$�����:�Ӏ��-�9����@��腾>�d��eы��7Y)"(��%�^�������j1�T+�c]	T�� 7�	;��80�N�G�'�R=VV�k�ۅ\�-����r��l�`�ձ����E�}�}�6(1�y����;lH��������S��,^��:�J���c��Tn��q���i��*��_>�H\eo@�����2[��jb��p�=@<��/=��:2���<D�ݴ;+!7��Z����։�5��p|?�C��3�h�L	�6 i>렆�grk�#u1)��p�h(鰡5(4q�S_X�Z�5�}����";��f�UL�@xН$���G)�=�@Y�7�S�|�9 54J͍���>��A��CHH�ҦIb#���u���;�G:����������R� ����t�B�}��� ���\�:��l{%��|yx�cO�賋����,�B��d�vZ@�z�����3��Q��[}������xEt�ݖ2HM�x��+ ���g���� ��1X�;����u��}�{�Ծg`$�^�?9qP�cĬXG���%��V�M�)��(��c+��=���߉F��yJ���:���ƹ�lD�K+9����{�����r��ܥ��2ܽ��=�=����9�I(w��	�i�[�Z��M,CI���m��?
KR������(�b?-�m������5����"a���!���Uis���pH+�����2+���n�S��\T,����{$��yc.�X��ԅ�1���[Y��FL�s�����;:������lAX :$-wL�H��¹γ"�����n,�Qg�Đ�Q�������b�r�ָl!�����W �̇o�!�5�/���q;E�@�Z�e�[�3�@��{�_\��䀁��!! ��gB��*�yO��M<��B�R"~�g����Ȉu�1�DE�?� ���X��ti�Ҳ�ʣy9�����|�m���H�����4�X5��T.ؑX�e(��
5i.pBot�ZN��t|�TX���VQ���k`�
.6˚.WQ@�-V�M�pvD��t�|����\(�6Kz.>�p�?���d� �#����_X�;q�^��%�b���S��{�d��TZ���_/��F��/ȅV=�=�]"`⟪��>�ˠ���c��^�����b���aLL�Sk;��0/����3��B�J�|V��lqY����(����M~�SM]vrN�#�X�&�FYǒ��K?(�:i�M�
5b1���s�P�_�l�9B���6XQi�s�Q�n�aM��1�쑾kN���te)YU�k����5��ȵ.2��A����5BI��W]Z�L�P��r4bV7��{�s%�^Q����������G[3��]�S�5���I����h�yJғ1ʝ���-�7݆f��=O�Vrx�֍fn�]��d�C��ɚ�K(�)/V�0||%���������e.t@�J.`l$��S������PB��Վ\
D�xw�j����{�_�SV���${
5a9*����G�1!�l|
s�5M��I�6í�=yc���W�� 6�?�_[���kJ�iH�Ȥ���!êfx���ƨ��mj[k�pI��2C��V�O&�×=�}�܊;��+��m�<]�mC�[��4Sz%��� �6L�eA�dc�^�X�N~�3s��N�
Ê����z���IcTJC��)��M,�&RbY�F�ɗR[F� ��`�YOHM�	��G��j �Uؚj�����o�E�{�G	O�"(1N#�8�&X�H�"���~��HͲI�t�Gj������#_%i�zRIe�mJ��)<��
�l�g��Ҥ���S`���¿rdQ$�5I���Z���~�:A���<K����Qy��P9�o��7���"���%�-���Z4(=
�b�����<�js��<2�C��x3�z`.�%������=��.�<U<�� 0rhU�5��2�w�h��eu����'�?��_��M*�����8\��d�h�+�3�þ	�?���պ �x4�����ɽ�P<]�T�3K���۹��$��n.٢���w�Y��jz��8B#�{ ���p�j�`m�_�G=��X�����sp��Գ��0ߧ���b��������{f<h�j����4�y��Ctl����RT������f�S\��,���"�fg��u��{��UsI�qCd�.��gBU�S*T���~�C���ǐF�	�C����]�@2׏���O���ѡ�����O��	\�?��h���p9�i�>�T�$+:��@9��̙�A��</�"�Ns@9p�~w3c�]���j�-��QI�-�D��ؒ`|N�M�����=�=6d�M_��vM����"$,�'d8��-�3	�2�G�~	�I�^�0,R���R�m#*|�c������
�z*�����w��Bàl����{<~��KB�AU��ؤ�V�B���X+)�TI�v�3��t������ZG��H\ܝuLE6��r�3�	7���Z5�n4|]f��~���#�y�xP"�e�\� �0����m����B`[70`���Ì\�̙1s{�n���Ϸ+:���xs6$�߾x^�1TQ�xx���=�C���y��	Pٻ�O!����/.
��	���|�#�(��{��.fH���1��ј���A�?B�	���3�N7<�O\M܏�Y��-�?^�r��z�\��nT9�XS#�����0-���[�b�2\��������S��h��!c#F? ����o�!��[l��V�`�)r����{O��>�̾vU�W�p�y�js6�'J�Ma�lᇸy�J��!�[Z�J�eR-��$��d�MM��CH�xB�֫����h�a���P~���hG�̀�p:D�Z���S�4)yH~H�vnW��t��6S�{ ����1�i�-늭eF<j��+�v�YSk���b�Gg��H�u���X\�,k)Z�D�����z4�B��L�-Ǜ�j`��e����P穽f����QRg��d���]�c�=�8$$��Ģ��Z��O�GRgkBN���vK���l&����W¬��I�ߘ��ʹ�����r�MQ��S=䎓i<	��r2Q��U�+���SՅ*��G�᱑���5�#QVL+�9X�#�;6���-�W^7.�-��90�h=����)S���7M������Qd83��Us�BD�o�	(����l���8� ҏ��\���~�<1YY�{�mnt�)�	�K�9��Ů��f<8�nC�G=��^p�!��[�a�҂�\���u5�c#0��H�Ϫ+�l�c�K���'!��ԭ�&��aJ]�iV��C/\I���K;�5K�t��z'��d�(\�r\�1!�_�x$��{�4e���ȿ�Jͭ��Ƈ��N�EWM����rL�� �%^�.���sx�"�H���k"U�Q��V�rJ꒬�y�8���[����0a��uU���ޓ�L���������"$�G���M!���pi�q���	�4��Ѳ���4�ql���|3��7�L�dS`p~��	ljy�$�
r�������(�z�P��x29 ��f���01<���i�5�1q$h{Hƶ��6�h%˜�
���$���E�P�Ғd&��!��4�$,�w)�*�B3�Jt,�U��%�h��D0��.����z-kʸ1��PN�!����3e@�1��g�zyTK�xy�A�/}���	p�`g��n `0gQi��� μ��鰫����?�{��]�'�D���������m���<�ݷ�\j��i�u<\��Ɨ���3�Ӗ����ax��������Y��3"�ɞ6�D��IK���]s�m�
�È�����/v���p�|_�U(��w��#]FK)Z�'��Z�QOw�.��|��S-O$�=[ʀ	��� �����t4p�{FQy�!n�㾜6*9��������q]g�a�!�,y�h��)D�8
}�[h9��<7�Ef�b��o�PIf_}�N|m��/�qX�k=q�&ė˿�ei���Ƶ儢*�?������j��t�<(�w�S�	X)�y�h`�������w�,��Q�ռ1����͌,��b*ނ�Dh����4(��}�9w���B^[�C��l��q���.R�O�D#Wx� ��X=}B�و�B3��|���k|�_��Z&�Q]�I�
d�;�����F�{�պ3�����8Q`)X���ѝ����8�Ef�#�MS�_C�I�06���V*R�;ª�ȳ,O_�����a� v��RSj;O��+U�'3%�V�I�{c�oO��M�z�Ս{�լ_�/>���l��_���P���;�a��X8o��D]�G�Ę9/E�����q�F�Q�FMS\��ͻ���n�@����Pip��iQh���rE�)|�G�5�쮀��	���W��m���i��9+�}n��!Fn�\�[��)9�^��]eٙ�8g���vղApT���:{Ư�~X��)�1���r�齏+q5��k��m0��C��}V#�s&q�����L� ��w�舩Z-"y�L�6�_
� 'C�U��^��h��m���k-(��Q��}��n�����Z�a�KP k��5o�Kd<���rC�縕nT�Lf�Ph�����S�'/�r�d��P;փ���5ob��,'� І�s��ƍ��2AN(�;7������*�%x�>,�ێ-1�g�P_�����y)�����߇�^��Fq.[�=6g{�����^g�<V׋T�ٷ�x��q��P+4_��mw�}�]!�/�/����}���^��,��D�;}녇,���2�mEO(}�n��Y���.L�2s��Ubʽv��b:�
�&j�P#�мy9�=�v}��\z8w	'#YZm}������+qܻ~��m�L���k��ܝn��D�W��c�b�2�׊����RN��-�AD��AwJ�Tא!�R��]�'s����+a>.��\�Jo?��X��`���tdJ���Ƃ�m�L2Q��·������)mc���θ��d�.����Dx�ȴ�hݠ (K���?���he���
�;�w��SG��g~�^�u��RV��j�~�g�x5N���p5�u�V/���r��`Ls�$�h�h6glQ��2\�4�-9{�b_��C)學�qHi���P8=.����5E�;��Y�4`k�G=!������m-6���D<4i��6Yf������Z%6fE`v��eD���S��u�N���Ԣ�!�q.�M+����x	��n�H��B���V%�ˁ�D5��(<�%)+�����B�R��4�_߀��:���,$�36_�z�_YcH{n��֝������ ��:��=9�@���~"]P��$�ߡ>I����9���x5!!y ������
��ܰ��C����[
D4���y=�����!�xp��hI�W���+`c-l�L���;<lPԏ7�dO��,N�?9啽���nc�B�������4'�i��e�_�E7�w�TsV����윏�3��^V;���nW17��^����ϖ�ś�f���7�]^.}u+���c:��݄��buL�۾*�m@��������ШZ�:3n$�(�3���y�|�F�O^�Z#)��I2|ZI�Ej�_�j���9�lr.�2n��̑�����|@��#�����^V9�(1�*�*yܭ�����l� ؿ���Vf��E��1��-���_ʇ9� A�{�����@��m��C����A38��q@l8�\f���:K���+��'��N��%�:g��$�S����^tN0bm���j�R�Y�N+ۉ�-7����*dKs*�N�D��7��5T�B{��&��9{���a�p?��P�7��[j���Ʀ�w�d F�/�hV��}$����5��k�y(��uU�>W������t�wy�>vmG �7�W�>>Y( ������`�n�Z�z��i�������M*�g��OZ0r#X�4&}n����	gL�b	ԝ�HJ�lH.ԁw���S
�͍��oz--YC{9��/Vb�4dwX�{��@,�a���K�Q�B*��S�����l�ύ�W@t�) c�����	�o�1�X�uq����o$��ٰ�
�JބjoWS�=�]�v�tyRΩu�J��Y���˦�F�)�df����g�Z\�/ᾨ�oK� 1
�`�bJ1)�ƨdRKT����f�]\s��|�a:�x���]��l�4��ΌǸ+k t8��ү�������Z��J��r�w\�+N%;tmt(���D1{Oc$"�bd-�15s;-�����%�ާ��t��0�M'?U��\�*-�2ɤZׂ�"ūNŏ��DM%bl��Y���7�"�aƗA(����g[���^�3D�\����1��ce�u�@��ݗ��r���֚����[��꣸�:y��Z�U��Pσ���7T����W�d 	�g.e@G]٢�)��f���>���|�
̸(�G��k����p�o�Zy�2(j6"b�4�����)�*�ޖ�cᔝZin�tþG��d]G<�s d�C����=��ʫ� �������kp̃����+�7�U��5�+�a�O����HTɮU�������[���#�Xd�̐+��f ��qz�ܔs�ǲ����� ��_�����ޖ�m�d#��PzUam(�lQ��R���}�`k��b���5d�%�c���z��
hт��4l�/s2�(�B9BP@�Gvqm�l,ߦ=A� F�UD�2�F���ȑ|�!�v%��	h����"��WD$d}޴����>�[���Y����N٪
���7�F�JX�Z�iS��#�m���/P�8Rtg�`�c�����$���C��G�����B�tB��ֺ2�b�B@��W@6�����"Â����2�P�'��Y ��`��Ŷ>����~
�: ��k
�B}��lS�)�o���**�挎f�����T�l����dۺE93��v�����Y�����a�&�ݲ�Oq�����C�44��sC�W��i����>�[{����?6���z�nّ�"�M!�o����M�N�K_�.Nѐ�o�J�K�2N�:�ɱP�+����.��!�uǸ&�%R�~���<�Oq�G�j~Zg�����gp���.����% |5���J�4i�Ȑ�͵�NJlE���ff����cz>8�����,���~�,k�U�7p�v��;���O���Eq�����$*�qX�tF2�=��U� k��2�{P�c[s���Öe��7pr�����&�,_�>kJW��sL�W\������v2���UT�����[q)�����"���䩆6�0꫗��c9=�w�w }���|��L�o���u�G��C�j��v1E�l�0�DF�d���k�����q�>�f�
�Dڱf��9��X�����w�m�KsHRE�YC�7l�C�
%�kX���]�d�"B��!�>�m�F}�`��_��C䦎2ib�A�`�xn�X��(���cc}L
������S��/>�'�� -�oH�ʹ��X���5���|\
� �ײ�X�n�%�"�j?��l42�~ZZa:/uc�䭻	�}�f^�ݘ�I'�3UZ�� 7눈ʋ�K�Z�j$ՠu�����^�FXd��g��[fhI�ڥ�եt���T�<�3BP�^~�͏0�|���ﭬ��;hH���a�]e |l�&,�K�I�N�nEC��u,���~�a⯘��H�{��Wʨ�h<���(��^ 6����.�,�W�S�`��6cx����ȫ���O�7�e[��%�:� �mQJ�c&�`'�ÂG�4e�e@����U�t����"�µ=s=n_���.�z�����Ti��n?�i~1��u�9�P�//m�#�t!Sw�r@4I��1/���sG'�5f�=�K$4BL.����m�O��V�7�d�<+^�z��Y��ml���B�F�G��>�鬪���ظ�I��߄d$$6��Y�{f^^+�S�@Z�5�ML-��HC�H���FE���0B�~$*w���vO�y���h���u�V{��pǾo!`�����j�o�v���W�;3�%�-Sm��x������.����@O4�_M�u{g���浛0D�45���Ɯ���.�A'.��,ք�9��&���9?����
����&'�&�9[ 1����C.>Fm����:V��Iz��S��ٲC�pz��6���>1��R�866�;��0���vn)�*&8�nP�I_���,N+2փ�Hx5@D���1�9ec�:Bjs�c��L�´|<o7<5�X�bKz��9�;�h�3����9u��ƅ�hb��n-����Ϥ�����48�6|�|��
J��h��W�����+��X.��=�4$I
����Ε���M�+P`���=딵���b�dUز�p`b�lc˘ν�}��#��(q�Ԉ��1أ�'"HIW��&�֛y�N����]?��Kq~�@;?n��O������$�|f��]Q�i_�j@���2\�k��1}D���oT�&x9sUYC�'Y��X��&)C�
n��S���4Ϩ;�#PP�2X�Rj�ţ�������|-��PE%�=e_�l���zgIMϫ��[��UI���R/>�u�Ԗ��fκ��T��@U�
Y� �PB����_�ɨ�W1���z� y�m��Q��g���ާ;e�it5w��;UJY:|�5�;�F�K�٢�A��l�ü@��l�t�SW%��D��[VH�l��%��9f6bn������2��]7�g�E�h����FUҹ�����.}��@F��x
q�f���Lv0�t*��G��z]<�o�6Y��#�p�r-Y�@�jZ<�V�V��6��`�������S����U-�.V�+g�J�	�$^e��:����H��!��z���f��U��yVd�r�·L�֛���-�?r�DD���TD��M
2@O���	^��Q���h��d�d��M*���H���~���Z#�2A�舾�`7��w�'{�U��y����Z鯊L���òK���z$ސL�f^
�Wޱ���	h�pu��f��᳐�G�A���?i�p�׬����Jw$5w���&Ɨ\)�iQ5/���^����N��4�o{�U1�'|��[�8���ʥ������"��I~Y��ae�5^W��׬��ح���Rj=BEF��*-:M�eN�Q�˶��X�˚�<�1�i�E�u��&5>UK���/���6	�v#0��v��+����s��ӿ��L�3j/�td������	�Uj��s�ď�(��W�%��iC�4Ѥ6�(��SB���KX�<H�d��3����L���D�Y�|���V�R�W�Xx��������A���b[�����fu��9lRD�w�:@p�62^�<R%�����g}Z����rî��-�Z� ���?���#%n���%��P�iœ�B;��G���8g����;h�k�V�g���s��;~3������!h�(�����;� ����+�%]��{�4�\�j�����Pܬ�(&��67���i��pb82��n�PZ��M+��K�ؓ�W;�nK��< �-�*�88���%
��@4'F�t_��x�1qlm��\�ǡue,�b��|�/	��G��/���`Q�2c���=���/=j�Z���g��@���X��S�R�&�:��H�dT��y���D����џ땽�	Ќ^vq�A"_���VF�F��p��j�Q]3n#s����ql{��u�g�9Pl���4p���Շ'	gM��@�/�91�ً����`9�gSݳG��������/��,Q��vk8��Ǹ�G�U��[�9k���US���q�Rf�Q�d�UQ�s`��K�&�n3橼0�8��k��ZW�`9��|cK/t�ҝ���ݘ�-n6�(	�T�Ȍ������TD7*��ْ;�#��)r6���[��7[�b5
@b�e:C�֘�A�D�[��V9|*0�D��h^Z�<��~�I<�N�\mA�hF	�X�c!�v���+�m.X��?�V�R:"��DN�7��ӕ;e��]�J\&�"R4jE?��#�H�iB����C�#���+�4V�=�O̽�����[يVV�K��l�㈧8X�tH�"Qg.�wJF<1`�] BWS:�/�
-T���xr$��H3t�؊�������QquUr15���G��Qݡ8K��.�#�۸�IQ�Ⱥ�L���ٽ|�'%r���U�at�����iWRU�^8���AﰰԷ��:}��៪k�,\��Ct�H3hEE�����r��k�v�7��?���|��Ø�rF��C����Ԅ8:O�6kV����A�ۨ/����d���y��3O��^S�����?�k�Y)�p0Ta���L����gIP�Y�ix�'������59�z�0:�m�ZW�Q1�x�.�9�O��g�P��R4��^20:��Je� �E�<y�8r��M&��z>U��z�#	dZ�PsXz�H��4]��[]�a/邞�f�u sD��M��\�d���p�W�8{�. �Z��I��دb�/���'M�I��[��V�H�t�����!����������穥��l	iXH����Ѣ/��ފ��+�m�:	Ÿ���C���y3�9NK9��B�!8}��
R�o��+ۻU¬�x,�P��jp�2�m�#Hc���h�4�^��!�Y����E�}��^����~�(p�/�RQ���3�H
¶7��p!W���[0��a��[H��2���1B�������8���ӭ��@R0DA��+l����$�<ʘy֣�òl�3r�}bmc�����"����'�[~ge�Ar]=k+a�-
>7�*/��mr
�?��A�9gj�� ��tqa������,���Q���k&SҀx?3�u��y�����U{�@���Z2����I�.C��na�ec��d؃�&��2`/J��[���W�/�pC�MWN�Ǹ%�5B�~�[��o'�{��Gx�lT��\t��(N�-5$[�5�T����{�|��,4'�ս�˸�6/i��]���#F/�0��2��<1��Q�:�(�.	�.��Q����V�/r�ǃ��|��ѱ�<��U�ͱ���!�����+R���	���h��v�[`o{��J�Nz�$������o����8�E*j����PU�d�xO��2��mi4"�'7s��� �f�rJ�f)��3U��$E�,����ebN�֕
��__gW/��s5�O��I4���b��ܳ!��;�k
�^Gz���S	!�Il��^�u�;":��uڱQ�G�Y
GV�맲!R>���n_~W\17H�`�:vV�e��e�u�=�v5v���	Q�F�F^g&�S@LT�q��;��K?;��h�,�l�2������U��_-�-Rq���˅-�֓p��<DB9�5F�D�,=�5's��½�j��Ăѓ�������;8!�qpD�����enh#'K�c=���F*ƍZ`/3���կ7$����4p�GU�WW�����!~���'�uM�\b��$^�����Bhy���ȉ�1YΎ>�d���t�΋��P�q��}7,�X�g����9R��*�^F��#�=Uoͳl��ѕ>�K4�[䔱��ni�c�c�Ê���Vb��,��OWs�)aTC^9�1��6��yw�n��H�W����E3K7�]c9����1�.����a=����?z��h �}�T	����L������+v�;ԃ3�9��qm&��"�ea2C�=��-��LFAu�T��BM���)�bI:�����[Fdbj�?�7�O��Qc����],�2�A~8VcQc���&���֐O��S�W+�1Z��}��n����X)g�LkR�eL\�K�sO=I�Qc���4�W�M��E��N�E���B =�%Ɓ��}н=�Q�����}a>���cl�f|h�÷��f�t�HZ�-t��3ҕ�� ���j�}�(�&�$W���*yU#
[+�-2z��M,�� ��w1��+Pqj����L��\��K*s�S-�G��E��x�!�7hr�LP��J��{m�І�����3�&!�i�*�8w�@��GeݿI8c�L�Z�L��B2zm�B\�&�Zé�
1�r�:��	'�s��X�+�n[��ٙƛxF��y��u�����K9�:�Q�(�UVk�b5l�_7\��A�|k�h!�vp�?�4�0C��6���PK�7�K�To7��?�	o����I<��J�u�/�.����嶇c��=ЈTn���Bn�Q�#G� � ��)�e������̅ �H%6[ N��;԰�ѥL���@z)�֟_@:ퟛa�T.]��W*��\J W����HJ�X�~`���������b���Q@��k�RV���è����jn�9B����udr�Sz�q��WECg�\�A�#��_��nId{��\�E�����c5x0�U �#��⊚w$+>��* s���3�;�!��=^�Kj� 6���9��K2[��+˦���Ϸ1S�xĐ��ߙ� �_W���݋�t��)S|���.�"�n�P@���X�Z�=`;�(T���^�6�2,`��9ܨ����^�M<=5��h�"�>)��մ�LǞd�>���^���b�D�Ϥ�c7���w�Y5�-���lJ :���HOxnE5�.AR#scE-+ff��ge��w'�0$.�tF)��β�y�3V>ӭ�H�o[d�e��Oi=.%D	�h���b7�'�F۸Y[K3��G^*��%As�.����&e�_�N'�^���[�&,y�����*D�b[ر�/��8ȕ=,�RWJ3?�fi��W;�YWO�(��T��.W8��f��M	���\����,[�eS�-�=�ƺ��Z����YZ4rq�����t��K�-��R*���Q����l���A<��p�x��q����2�$w��(
�mjL����Y8�D��È?��K�|߆���Yy�ᩁ�?�ut�IL�	T�݂.B��I��)r���?Χ���z�%T��u��� ��2����?����YJ@�cX�!^���.�'�k�d2���sA+��A��7���9-�c(ԉ-ml�'���ҋ#�g��m���yj����*�Xw�>��1��Gn:��HBZyv�6��$�6�����,�yç�^J 6�ܻ>��X�Ej���8�Cb�yc > ��M����i6K{ʳ��4�g��%����2ot&z'�{�"Q�N^ە�$kV��Xr$g$��z�K�x�tGX�hWޢ�J{�x�)z�+�!�K��7��2����R$���a�Z���#Q��{�4A�\ꨨ���P�ڀk�Q5S����}��fk��������E�ui]JV�'�=�����b���gC�R�qe�� C�i���T�O�+�����Xن�>�|��Ԅ�b4�Y��y�>��Ί���J�����.��- ~X��=q�"43�@`�z�-�<k��!�w�1R�y;�"*U��B6[�(�)PJ�K�;Z��E�C��*<O�#�f@�=� ̓Mχ���M��q�o�p[�2U���swo� sQ��Ze�ù>C!bZR]��������Y��c�7��7��W�|�7a�3YOٔ�I�j��4tbI��93
�.	��u�?���k����).��8HN��u��p���K/_�ڤ0�"��=��	Lh�U )?`ذ���!���<3_�KӍ�!"e���Qe��sKA��O޶�`Yj����s��Y���,(6(�ú�ֳ�'�9��ZG؍Z�O�h#`[Sly�B������`g"Jf���Ү3���>�y&Ex�[���^d�(�c���_�<����g�w�h�jZ�c��U������L�{�ַG�o�{�L�`��ۜ0�4_������gh����xg�]�}�֎�M
=�y���p+�
p΅�"E;61^���lj�-;�)n����{�	K�/wF����>3�o�Y�'@�ŭE�U��l�<8�T�VQlB2�y7f5`���I�C��Ґ�-�����2��F�F��J��nz��2�/��   �/�p� ����?�����g�    YZ