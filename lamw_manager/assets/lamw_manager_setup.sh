#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="145541452"
MD5="2d25d778fa3a167b43e8c82df2ff39c1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20708"
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
	echo Date of packaging: Tue Nov  3 01:52:02 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��1Dd]����P�t�A�e���t'���������mNH��v]@k)�{ ��e�L��qi+�WR�N�	t��C~������*A;�^�TV�ܜ09�`�P:B��$�9$3͝+�P{:�t�$)�T��b�i�j�E���1D���QORj�7ښV��[�����6~澝�$e	&Z�&�m��{��~TR?��H����7l��_��
Ϸi������M��4�!�t>����iw&��׻���5���/�b��ˣ���QFC1��i�NU�Xʦ �m2E�?�f�U��IsF��+��$�m����|'U�@���Lj]h3RמuB��
�ۭS�B��" %"�+�7^t��0[z����3Bɛ�6��ǅw;1/�������m�^�ju	����k�[�WX�+���oc<�O��]z���M���pA�z��}����Y�6�H�m�l�b[�<0&��Z1fQT���t���x�K9�cmXw/�)9���n*� ��,U_3�'Ǖ�6��Yw#�ua�Hܜx�����t%�_����.BT�*�_t���D��_�6(:-�����A������/�O�����|�~M$3PE)g��t�g�P�����Jq-�/��KO�m{�F>�A	.�/��f��´9j��-���ߩm�U w*֫���>am���U���0@�"IΐG�۷U;f��MLg���z��	��
 dàֻ�L�N3$��+��� �+JE�	��c|�5����E�
��c��-{�n䝛g
Ǥ���5n���=y���y䳷u��WM�'t ���l���=ag�a59jK�:T,�	Cv���)������+�&��d53L���i<���,�e��(cqӣ�|T��T��@�ȕ�"�X:�E��D�<���2!�"���+R�wV��Z����~6��*dj����SXFs.,ѷ4���Є#Gif�7���$"��}�3�N�W!�t)��9���
�Wq��\o�)����LU ��xm�.1+g�BWhI��7�/���7�9��s�΀�=�K�mX�]s��3u�� ��,�?T[��*>����H'�T�3��G�`2�y����(�	�n�pQT�e�n�,��Xt'�メP�M��u�vjd���������`+����Q��˨u�,�F�ZI�:@�ʅW[IZ΋��A��=��/��%>�?�w��^jc���j��PaL�� g��f�wi'fZC;��.�0o�3�z���r�O=�����E\�t��Q�_v��!�mu��!np} C��)s��\u���8?�,��m��(.@�
��af�Eۡ��Q|
#�n�!�bd�كٛ9����	�"�Uc.m���:�n�=c�Ž�`�ׯ��!G��Q,�av_� �� �쥝p�����f��kŷ��$?%��sٖ�b��v��餝�u՜M��=��rL-��F`�ab�����?6͊�,8�F���;�h�?��������j�[�A�^�os��=g��ƣ��1'8l��:�ݎ4��y�A��T��Rn�G��.���)���zU��][M!H�w�+i��5��	tjo5��&+�m����_qj�{!��w� ���C�w��.��w�⢼�-�ǳ�{4��j|���1��f�[�؎��z�*������s}�q-9ɭ�u��4$�ޫ�U
�/�DBvvg�Vڃw�fh�J_ׂT�D��C2�5���P�3�f���koY�m�K_��Z�dP�/�h�dkE�)�x�ñ��Nw��Zl*gi&�A����j���`��2� �Hx2w&V|Hu��Et��N��^�zm�Ψ:|"D�ተ�r�w\�ћ+-õ���q��k���ɉ��e��%|�$j���<����p
0vr��k�r��>PB�/���Ц��8�i}��zrց�L�H�`�Ey�fs��+��`������JW��"������`@J����{� tQ��n���C��DD�*���.�-��F#����ȊVꄝ$H�~A��ƾΈ͸\|)>,���7�����a��^������T>�v����F\��:�
��=]7E�(a?������.8�,����-��`���;�<���v1"���W�����Չ���*�@Cޢc�6�ON�1#c�R�X�����"g-�f��E�wͶZ�΄������)�����Xq��=�6��������x�����<�q"�Ba�H�.����p$�w��'ljݶ�͎�ۢ��0WC��3�Q�)`���/��#���̶�kȊܧ �	�7Яdc�]��4lK>:t.��*W�����	"7b.\��^�t�qfم�����&�v Į8�J,���1<M4Ӟ�sO�M�{�@�����Ls�B�S`��xY^���ՙ�A��~"�)�W5uX��������;���u4��tj�H����}�@�_{mC���H�/0.M:��Ǌ��v��'�:������=�cj�z���:N���� P��͟�B2
č��Q�r�����ؽ�fs�C��_�T�vM��k�	o2H�f�϶�d��a��=׹����#.�ʠ���P12� t����f�*�x�$�h	���n��I�O�ʼq6}��i�]����b��q�呁7{N��`�9��� �$��	����O�t9���w��I�5�b��J�q��YK���\	���������z��V�� ��
~���o晭%1�U�!YU�: l��g��G��!��,����PO��@z��������H�����nR4�Q/82��c��`\��"ƭf���_:���t�U�b�����=��#㗱�+}	}}��6̰��m����a��`A��2���zf/�Mp����&����׷�YĆJo��nS艸I ��C�x������A9��$�?EW��bQc�3�T�7G�e?�t3��٬����?p2@��D��w����Cq���Ѝ7!�#����mw2�VR��� �]#@��$�l0#��zO��D9	��28慾��S�I3�c!9v�b��fO4�n��+^�.�R(�h5)���OۀM��+�c�ZF��E�s���+i<�.T�����Dk�6�#�l��?z�$���q��N8��~�[V**�CQ�qz�b!\�L��F(�r�V���vD��z 0��''���Y+6Qo>�l��q7��%%ݏ���u�����"��?��q�ׄ������wV �NQ�hga�1�x�0��L�KzH�NcN�=d��6�T_��~� ���	��G1K�u�(52>�Hmp��鿧��?0�W~�nz�ʚ������J�#����S�Đ_��,8��Ե��tj��Q�����睲�ܲ���W�$�2ݾ�&hۗ_*�$�|��i^�uG<1��|�73�Ύ��GM��{i.Y�_jjPz����P��c��$�h���;�G�HN�e�/"`� ��f����<9gv������jCL#3� ��m*��ܞGje���ʹ���,E��>ߒ^��Tpr�x����H�x�?|�]���YMQ2���R��� ����a�!Ch"����O��o��K��ܜ����RO\������a��&��\9�r�d�╞]�B�XI�sn���(��{y���g�:�q���4ӢvUþ2���������<�f^N�����j/�<?R�(S:��0��AW��5�k �}g9�YX�Y|+� D>���^�u[x`hY[���u9�+�8̄��U�ٝͪD<oE�Z��Z�{����-0a�v�������Jq�sIr��#���U�
-r�:҈U/J�<j����-��B�[���{�.�w����wE//�_��@�o>#3��8*8�w�l�*b�E$��	���{��f��6[�n='��S.l_���l��W!��V���$�{�Z� ����4L�AQ(���~�z�2��(2�̻��&����͆�I����.*�]��mO{E�Uq���D2lc�j�ü�̋|��VR�)��������:�h��V���� ���	��sâ�վX
���6��
��Y����ņ�7��.����Kk�E��fK�5L��J��|�"_���H\�>��$�_.�v��wܹ9Iz�ŏ-Ӻ�r���F?C}��4��/R���]�:�,�F��P?斊ޮ2MVH���t�����z�I0�a)Ϭ����&�re2_����r�� \H4�4�^􏓭Y7�oG����4��v�ǔ�U@L��-sWe�1i��5��d�nU�x���k�J>z������0��7Ӄ9��]xC*����x��1�^�h�+��j-hU�Q���	�*O�CA��e����ml��_��*�������[ {��M?z.e�[�{yM�7�)�a`_�Ve����&����}e�+0�|\��1�����T���%n���w���WB���ʦbTG5��	{.�.	���n@--ir�B	�COl���MA��?S�yG��Y(��h��o4p
�C���:�&����'ۈ�r�����ܣ�V����mZ�K3")�WXM��ء�������a�H_�S)m܇�N�Ǣ�x��5}�,kS�]�[[]���m:�5i�>H�ԛR�F�Iv�Ƨ�#�����QY�'�d�Jv���޳��;7�T%l(�`�;`*"�TEc�2l�qrj��!��&�&�_ 3s��:�8q}�*�U��*�k]���vh�\ Ps�A~�k�]�X�6u?%��.�4\,=�^����h���h�����܊��Kq����W%$�D���g1��%ez`ѷ�PJK�)��,N=-3(�<�n��H����J�Ȑbp<�oi˘0�����\�?��<����&^&'���)-���N��;X#��"�O�9��l�=e�&�Im�y0�G��(PC7~������P��EW\d[���V��k\JI�����V��+/���Y�'!�¹u�-j�|�2R��6�i	#C�w����T�Z����E��<-����ZƎ�� �h>�N��S�#q��r(Ĳ�q�E��^�� j-)-]��_��V�� }���!���fx��f��G�A "1��D��?�Ld���{�k�M�7��=(��fFz��.��'�	E ��@�� s����r����BG�0�r����qҥ�-�ƅ{�&����xet�	�B�U��vf{?�,����{�_Wf��^�wg�T�~�1��C�3���6�<srE��H�9G��<�w�����I�p�ԋ[��A<[��M"�*F&#����$VF�T�(��'~�Sg��y��Y^wd'(������+�-4��k�b�`i|I�W���bр
�9u�=V�h"���D�Rj���v򴛻L�jL��AR1�D�g������#��y���s��]a�#e�G��r����(H��I����PrgOSw,_��"�_��_qȳF�ٌ�i͎������ ��&wܗi��}���R��S��Z��g�(��Y@���wH��񻬿.�����@����blHúl�6�1�w��������(\ Y�5�vO�8��i�v8?��ֲ���__$=�^f	ד�;Sh&09��
�UR�g���|��اB�T;׉ ��R?�,/ #>5���l\i�̧�	`X�jU���Ӷ>��lL�C�r Q-�4|e_*!�1ڞ��p��%�H�=�B�����z�'�r����Ma�Q9��$[���Ŷ��r�<���!��4n����� 	����xt���R�6���Ikk�<��\�l���GQt7��^+!�>k������a�9����]o��wp��1f��VԔ�4�lV䋯��Cz����@�0�yE���N��k��'��5��''1�*���EP��4�>j�
�e��Ӟ���/y�K���ۅ�ߥ��FEpz?0ڃ9�y
QB�L3[�* ��r�~�d|=���&������N)+���Y_&�ə���c.3�zqY�)Os�
��q�����8Y!d�O�9Fj/�{��U��q�6.0�tv��Ƈ+Q��{e&״��f�Ϸ��
����5T2m�(r_y��%�$�\�p;��)�)���>�����X����+�a{���k�C^6��c����x�Q�9��E����f3D���ƅ1ɒ�ˋo�Հe�s�;!Q>t��sc��"{1����q%�.�ky��_��)��2�"ϫ�ض�Ik6e��t�:�N$ľ幖៼�"(F����'i�K��{c�e��dyph��I�$�Ѻ���K�(0���%$T�R,+V�]����i)�#���7�F�s	j�o�����"��p%g���ٚ��Ц�|qXy`��MҲ�$��U]I��U����\o�������r {qC^Ն�y�����Az�8��s ?��~��B�ԧ���<x�2����T�'u���C���ô�O>�(���&����`2?р7�-�F�hc�B/d�SP�m*�n���na��Y8�h,N�x�a)�Q��*�u$7{�;�E��9y�)�g�x��-5�E����_��k3��Kz?��E�v���E\ k+'���b�<�]&� t����aQ��y=�c��g��H�y�(h�H��=QEg|��X
��Hl&����SNt�͒d-�U}m#-��ǜ�����u$�Ȑ�y���`$y7�0d2D�SQ��9PT3��9��7�G��~5'|��h?�`� �M�N�?��<�>�$@���pw	=M�.jKJ��Ԋj��TC�>ض�Y3�r��s	�f�NjUr�}]�I4�qH�Gт��!��g���!O(������B�P`�	B�RN�to�*[��.���|6s��-x�� C��o?-��Nqp�A�Dax?��h�R�������  Y�C,�+���E�yo���~i�x�Y|�ื��zNd�e���R�!�o�'1l��$G���n#�P����O.Ԝ&4��*#��}�'��$�����F��Xہ��g=5�C D���`lK2B������ꖝJ�cupih�E�AT�d�%��Ւ���1k��X�n��C�l�7OAB@ݙ�S�Ǫ�:��3(��IC~M�e�BޕE�sC�2�;��L��k��/.�}r3�2"���v4#﬎��+��Jj��3�YwX�v-�"}�O�\��g�o�Cxr�h8$��QI<>��y�	2K���~)C��F��s����t�ێ1-FOMF�᳌Ë��A�rT*bz�5��_�4����V�ɽ���V�_\;��Kr��*)�zq����a�B��e_��e��g.�l�����~��ɥ65%�`o<�M�ėH�n�y���I�Xvr�� c�5֧Im:S��F��y�{���[9����Zn5� �6�("^��Z��|��1#�:*��=��v^B3#��
�/����������<���w�~�S�k!���'�V��8���Z>�=+f8����=�L*5��� I�S&�#�e��ѯ����
�o��0�9c�u�=�*�<�2���rF�$�b��u��W���᭎��.s>�RX$�EuA�6�7�Ą_>��y�6�QHt"����cɣRc��3��X�(�$�v*��?�ufIP.Rf�pZ7{a��Dq�����1n*f��4��o����k��JTh��>�W��Rd�0Qy=��΋�RT�3��ƭn*Y�w�{L��Y�x�E�EX�2���_����9l��-�6t�����Č��1'䲲������@fC���wDח�K���@6�|��ھ�K.��&l'��a�:Є���Dk���ߤ��Bo�hBJ�8�����~��J�Dc}ŖI��YœF{�F"X�n�-wlݶG�l�HS�9����'���"#8����r
����V�O�:��c�5��	#lF%��rT��7����&�B1�� [�u��[ C��L�\b�!�"�2c0���*N�}r2ߚ��艂v($C&��=�^4ݡ�5*���v%iXh�ڜşf���aH
�z������x��:�:�3��5	<%t��!Й��*��u�Ǎ ���_��=�fR�GT#5��zW����3���lh��Lاg�o�%�X�:t-b��l��LZ��� ��& HG"�:�P��^�Z#�6 V������=p�GKwwyF2U��{,�L�6�C�������ܶa�������R����g>��0X4!�SZK��VfD$b1Hd4���+�/���_�4lK� p�j2�>l�#�nci�y��� '��cT�E�w��e�~��b�REz1���x8@�<�S����C�PO �<�*(a�8
za[���^f;�wtĸzEz��~rc�"N�b���Қ2�g�o� ���-$�棯\�݂	R�?	'��{��՞�;q�R��t��{y�Я$��ѡ������pX`�̤��jz�����8�u����Uu}�߂�SSi�?;����
��&�778�//J�΃G�"�q\D���y���US�]�TIH����,D���'�!ps��|�
�u�ZϙW�QN�A=���;���}d$s�&��x��\���6���O���q�f��T��tƓ¯��Vo/�u��3F�:.��1V_Yq��'�P��C\7c������슓9�� 
8X��Œ�*�u�yp�O���[\����x�q��Ѧ���LX^ݬ�"H������G��$����<ͭ	q��b[_c�y�6[c&A{��?7���C�]�J��Z�Y��E��Z��&�c����&{}%n�-�Tc���q\ ��b�b}z|P_��2*)�S�`���2@Q3I��:��%.;�J(|���	�]�Nzc�+�,���������iNV��"j6K�7O�Qr��Nc��łM���2=�y����0 Ak<Wy��v�/��L���p}=L�MC�z�����L4l�B~������J�gy"�F��J��?~Z�-�P�[+�&՛˞���) �Tִ�*S޿����HW7��.{N��p��c�p����}$����lc9]b��μ��T&��+�W�<��v��ao�������]*�2#�c�Q	��ق�	Ɣ)fL��30m�v������-��{��վ�G�������[R���U��(��5�KҲ�OHM��-[7�Hqt�����.�����ki]�'��B�i	�D�i�0ohX���
�RD�!�ˉ���k��瘁̅�"���bR�Y/���r(���򎾴Ue���إz�3��NX
F���53�\�V��MB�ylSY�5"_���<p�Pc�nҵ;<r����d��uGIL)BB�OA}� v��΄��$"qu�4���M�9i>�m�JU���?��*�vJ^�&�=��}���JM�a��[wWG�2/���wݻ�-�'�@�"2GW��l!����&�Bʘ����ڢ���maU�<d��ހfS���,��8��$������>;f�-��9P�`!�qFOmST4-b��2���)x�V����*~�n��U�=��|�;��Vj*mk��y��v�e�l�X^� QYWa�����Z*�w�^*Лk釻T�e�*�2����+ P펴�+*��tn���N�L*1}U��8)��v	g�h��n�ǿj��(5l�j@T��`7�|�	����(
������y0�����w(�V'�w,r,Dx2�F`�(�H�*�m�-��b(&p̻84�Z����8ꍟ�KԱ-3ك��Z�NR�d��h�𴖩�+��L0�	<q�9��@���B6��n0�Z�Ecln�R�r{���yX�a^�}�D^"o�/�<�6N�R�t���i p�Y�KLI��jt٫�e�jk>>أ��b��ã����>7؀�(%c�9O�+U��1<.߹:��������-������J�����u�jS��b�?�/�׼�Mk��x�� <��u۲0P����Q�$��ܓA��_l��D��;���"&;DM(=�*�2��e�8�z<��I1����w}`~�^F�+Y��ӈQ�_/���E�Q6��`ƕ�Y$(��염$-���h;hk��W,3T��H+��1c �jǪ�(D�j��t�A��?��d� ˼�^݊'6gd���q����%h��
��n�v�y��[���r�l $���v�9$��5@���S��ݞ"����-$x��I��hCƨ����h;�X������h���
9L&W�����$'�r���S��g�,�?!�|s��l��� � 1�;��_�{�Si��{(�:#h���o���E���*[7o�CG�Nyԏ$*��C�u3I��r��Uŵ�nJ�����(LbO�7~V��5-b���td��q� �f�ҁZ�������䌫���5�N� �\z�D�r99NofR��}#����ߜ��G"&|M	�I������u{ȴ/�y�w����	;5��\Ɏ�~t��Q���p�&g�Sz�F���0~ ��ή�w�2��
G�K"uR���[�C�=��E�`���JR��6X7sR�Uʆs����!z�1���;A��R'�͍�SX�ݚ�K������)26��E ��*-��m������B�������ĝu��d�(h��t٢Fp�ak�u��ߠ��R����љ16p�3KEH<����]5�=W�!z��f���g#[yn��t���L)���#?ƕ�NRp�ƺ�f�"�h)�0��Itg�[��+���>ڃFg>9���v�OTӌ�w��8�	Gks�W�;��tK+�����18�Ⱥ7�-*X :� ���P�R���o�m��L���nz|5������ G���;�LSO�2(o��o����%H��=y������,�����ٟ��i���T�g�ڠ���~���<_K���wZQj�{���9:�ӂg�o�5��./V@�F`��~�������9�Ư���׽;�-����mHS8�/���N���E���������4�q,s��++N���3���t5SwY���\>Mh�L�z1�U{������=b�#��ZA�"�{/1�G��r��?�)Q{c�k��<��|i"8��ޟ`���Jݯ�zm<u��bV��Or���?w�����=��Z����]����?�2�Z�;�č��lv`�� ����wY;=�o��}�B����P�,����'�:����s�3Ѻ|��OHQ�&�g��W ��w�`��j�&F�Sm&ʹ��xh/_�q����2Q�h1��7�`٪��,(A!���o�V:����zL4�|)::t��"�����B�LT-��4�����D�Dzn�d�-�� ���R���^np·x&��K���Kh֨X�c,bð4�N�.ڎb7��S��-l��J�����=�)��O�rߍ\b�T� IcQ�\��u9�k�Y!���uY�A�������m�×�+��6��$m�۪W�X�gB
��V�.�h��%T+YQ�{y���Ib���ߪ����XӬH�:��wߒT�Y�@�o�Z��\?�	�!"�8���,�n>��႘+�6�-�$r��}J|$���HZ��y��M��-A��OE���j�?}~6����"0Z��ݮ ���'PӰ��	-�J,Q��&�-֮a=�Z�q�ڟ-�����2�W};��Ǒo:��!��C�KF�v'���ߦ��,���Jo"�c�f��Kb�X� m�����@"E����p %��(�g
��ڥo>7V$��rJ>�ʭ �C���̑�ة.?��#��|j%y�>�����y�^��Z����AA�=��3*�T�:ye�{D�h�0	��M�{PLd�m�K� ��B�ZD��L�l�C н��f�s�ZS�ԛ%��?m�~�Ge�nȭ6)����Ԓa��8����%���Y�����]�Y����d���؝Ǣ��KRE��ll��EY?��%���'J���M�%�MJ����?!���֞�=^�d��͔F���}���Y��b���3���.&���N��0�g�J�{'�R�r�o�ٺ:ZeZ�w��P���ei��v����a�������$��˽0�1��G�ň5���-z�I��z^h�tR��|ԕ*
\~���L9���29�'E�ii� ���>�ZI,k�\A!_?7�XE<$��V<�����Sr������斓���4�魜y5�s��K��ԍ��8"�7���d�ʮ�����9n��o P�{�<���@�w�e$�o�Y02�WE._�ٖ��E/���L�jȊ�D7QH���de0%IRK����Q}�:>~+0o�m5Saۢ���|1�T��~R/sԧ�ǈ�����ن��&ݫ��&|��?������R�3�"��q2-�%�����D���j�hZA7��������q��}y�q��d�������'X���1��w<�O�e��ɠ5�:�P�E�[x�0_� �7��jf�}+I��Վi�Q�K��ȭ3���>y��*�.�ԘG�W��;gz��(����E)��d9N�
t���o�$�|w{�ה�V�O�k6�;�޶XA��H��k�Ў������d�ؒEX����L�W�
���5/F��ϯ29�z���N��mp�f�`��� D0Fރ�����b����'`�)�C��}6{>��%\3g<�����d���R.v0���<Hcm8�X>�,UH�3�o���[p	�6�mSN�{
s��6L�V}>W���1���].�U�),�S�162���Ef������Qϖ�9���h�-��SD̽V&}No,���17��?5۱�f�P�Nw�'��d�2�p��Y�s��U;g�rv�������E8��z����
ҡ�x
Ic0��u�312�{&|�w��[]����]��-an�S��P\�I�����m��F�O�lKS��K��s�P� ������-�ղ���>�Ɏ���h1����h?��I��Rr;�;Bߨ;���BкC�C�����|���T��ZZY�|�y�a`_JpmS��j!�o,��]�����{��/_?�2�G>gp(;���]�a���7%�3�H�o]���J��8�����h��ұrn*UG)��y�@�����7(�؄�g��Z� ��.GQ�o]4�RD�;h���Y �e,ϐ���2Iܴ���֟# U�8G��U�k�����w�93�~�/�}{�-���h[ `��F�&)	�+�ٹWz���8&]Í��!���r_��a�6h�*�Dbm�k9U����]�a9�ڛ�CJ�y8h�I�A:cqgwI)��b��V\N�w*�����m���ʭ���-��&������jPth�y�*�y���a���쾮.�_"٤��g+
n`�x+�sѱ���% �ti�@�T �|kS���Yg���7N�ON�&�-C)����b�-��qߺ"
'8^��먿���ܻ�|�����I��>�pv�R��~�A5`�s�!���s�R�wu�Z�|^Xe;���B�����-^��:ӚD��������V�E9��֢JD}p> s����{坔�j�ǭ*���Is�{�T���⺶�a�� T
�t,�~M�3�nC0n���N���G��a�ұS�r�D�
>���ڣ�*W���$t��$�3���Ғ��~���������n\�����bR�w�N�UX�����9}����>�����R�IzD��<�5��+�I��!Ζ	�3$R�@]7Bõ�������������8�j�� �)�o�w��A���HR��h�U�A*<���JA��\�Ӊ:z��%u�)���C�f���e&�XB����-�S4CÌ�\�%��;��ŗ�&�?���Ȝ�q��d�LƐh�P�D��TP��ey�Z�[��f������-KT��Ԇ�%
-V�R;��$x�8-�`�/�sU1dm��@Z�S� %,~� �3.��y�,��_ht���AB�΢lI�Nˋ�\4�ƻ�%c�^�:5P���YE��5d�$=��Y|�g����{~pϩV��P�/�ګ�����+`.�� r�2j��D�Y����J��&��ɋ"룉������ŋT2��f|�� R�z��	���[
�*���_}b��9��7���ʯ�O��>��Ԧ�����������ح����G�N'd�z!lp-�S���Bo؜������S�=Ue���	F��L����]_mZ4���f���k��с�T�U���=�����ݶj1G����Up�k3��u��~���`��r"�w��-=~ۗ��>i{����[hw�|���}�T�J�?&ێ�J8��N��}a{:i���䡱����4XW ��ǰ��/3u��D� a%m��Pq"r\�n�/劔c��V9ќ�ѧ$���edtGi�q���H&x<f��'���F�'r����*8-���@����J��f�@d�~�� ���
�'I���,GE���ru��ɯ�U�Fb���LBĞ`����0�{��Q����ý?'\�~�M6hrlߙ���o�Ofu�z�v��s��[��\at�)�4`�Ǳ�V�h�+� ��Rg�ѐ��}�K����q���W��ۅV��������pMe�F��5��h�+��^��N�H):"!%UA-�l`9�YΖ��N��->bJ`�E��,���ʀY(�<��^6�Y��E]��.�&~e]�na�����&6u�F�A2�-j�Q^���xfJ���� ��X!�l����lYD�Y�3hP3�s���ôkv�X,@�+B�roGz"P�N�)�@)a%}N?�h��v�	o1�B�_T��,�W ���0��4��P��c��$ʏ�`����nlX�@�Cp��G~-���Q�V6	�o->#~�U�eԕnԖ!@JM��+��ӂ0��R"����	��d�*;=�Z�>yоL/F��:�X�p���;��}3��b��x8��!1t|�0�눟��v�r^����I�^c
���'Q��uJ�������|E$��������
�le��/j�^�Ӎ�<��cX{�1�It�=�Ƀ�w_e��R:�0�;�i���A���� ��~���D��V�+Vf�v[��V��sj��� ��T�Nkz|�� �d�2�BO����`��
V�(�/z�uY���hi�9�y�D~0h]_��
~:�D݅f��>� ꧜�qm�*ً�}2`p���a�V#]�#/�����O١��up���q%Y��J���)�"�q�ĿF|����W��Ul����u�����Y�/�\���aۨ0\� �R�D$<����0j"��B>�{P8��>סU�!�Të��/��5���5����s�)����<0,W�
�a���+_���a�y�>�?����ȓ������?�6+�����f0�t9�%����p��+ N�9WG��c�����R���6e�0����U�"�T����	;�
�_����E��Նtsh������VQc�,�"�|���"";�����6�ڐ1-I��ӛ�:`�V
�.\���1el�p���JQ�g��:*<�����-�#7��D��A�{ơ�<^@����C�~��c��ooڠ�Sg�oF�^�D�8�;EP�m��+ƍ�����&.�Ģ���?�Q��5����t���9���p�X/����*���k���0�t�EOSC�]����|�͵��ׄ����ՓT����@�x�n�e���M2�;���8}�������Y�`��M++*��< �aTǚ��P_��(z���n��쾎�N��@zO-��.=`u>�����mA�tV����1eꥺ���F��
Z�Z���#C��%	�:�����ˊ�8g�8o|�p����1-�\� �pғ3���\1�����x���h��5A��$��v*�������Wn�W�QX.'
�z%�	�0�#�Z���dG�x���t�Z7|z�u��N뭩���({��[��tI��g��C��:NW��H�\��HA�&��w���"���{�ݘ�zKٯ�:X
����e��N�8�h=﵏5GZ�>T�;�c���9	fͥ���!�$_Cv������$=	D�;�� #�T���,1��F�6cL��by��iRs���:ɹ�T�s�m������:ш�X)��\��87	,��)�Bl�	B���K�`\��Ƿ[T�����|���aE �#� �1��p��E��Z�Ѳ�hCFH"/�N����wQ`�螱"��WJ�فꀜ���\e���&�f�s'���nR�Nl�s�:o�#�	�A��"��ds>�*.pd@O�ܜ^�W����#UvH���%�>��+M�``��'�ƹ��n
��{��������tL���jH�wp�}xl�^�1an*��dR�� c-�	�њ�*+7X#�˴�-�d����/*�	�ᣴ'w��h�䨗�Ғ�!�w�e���"FK-�ӫ)���J�I�n�t&���b�r���h�܃��c��*�5����05K��`=e�_|�����}e䐬��}%Ds����UY�W���֋�ӯ��af����5�eQjO��K�D�j6	�EsI���U�� �3i�l�v,���w"�]nR� k`�@�<��Ȝ�lJeN����'��Xz�ڥM�=���g(Oy:�&���q9�N�Cv6<�$���Afg�ٶ��~�͟���p<���e,��R�Pe��4$�O�� /��Ph�㙜�)���N��2J-x<t��{� �7hKά�n�����UeC��俛�$۵̑,����¿Ρc��<j)
�7
'ݯ��3n���ْ��a��8`�^���.�u��T�| ���������ď3ֲ�C��ŒQ�����Aq/5�8A�vF
M9����Ip�:׮��+
�bV���Us�H~h\`�����n.�oc~�a-dvC�<��vʔ���[����5�!���~��z��C��)�q}��:E���#/b\{���6-�٤2'Da���'��`�fi�6$@,u���=���Ҳ�h�}�.�Z�pE����� b�(�6�R~��l��le&]��BJ[��� �ƅ(���n�1
�fi����`�t��9�Y��P�J-z7&���|�i~J��b�����s�\5�̮>z(S%�D�`F��'m� ������БM�4
��	���N8� _�&.?�	9B�;���&���3}���s�H_3�u��� 41͑�Dӡ�}�ӌ�0*�X��n]|׏5���Z������6O�̱�h1���kX�'8���5�fL~�X�o�Wj��nU����i���=%/�4�_�/l5�C��Q8����m��a��X�J͝��d���>Ҋe�]Rg��m���V鿉yl���q��	G�&��&=`�[wB��}�d�W���F�t��GI���!~����ߚ���S'��] �{���P�{QCA߈��U�o�z��+�W��^���ʄu�=��_���ꄃȋN��pNsj��`z�l��w_�>r�^R��8�S�ӊ���ỡ��Ò�;�6�V{�UtB�1H�jB�5T���3z0�������_�=����7g�t�wP������0x�$- �E{Jr��E�wN����2�����Ӷ�%���� u��G�= ��;:�
jw�.p���d��{1H�#���⪠71�*�+��`��2&�ݠm}hu����h ^�8v/Q?v�gj��q^T4�j�\���.����C�^����0�
���$�2@+�B����#h4^��m�
�nL���x��q���}Y	���7���cϪ���*�\�.T�#��S1B��ߢ���m�ZH��|>��Z��l�F��^��5(�ڭ񾚝��;h�*C�s ��Tx̮ �{m�b!�͡ul�Ԁ�@%
���l9��o	&�\�T�#�^D����QP�A*��<�M[������E�ݧ���A=�4q �����`$;�I����&��p�����<Ax�'�>��\�/��Ն;��~㊟�B3/�e׭×�h�Փ@,Ⱦ�]4���y�{��a.�����5��!��T@�ٓ:r���ذ��W���N�h��o�3)ٸ���DL����^��� y*�K��=|�,��6����1G�l �2Mİ����o,/�Ɠ�T:#w��(���(���IS��FL(��p�mֺ���^�l�D/�oD����d�P{1��D��/�h�
Է�,��L��[�~���hҍ?��6�KZ�؏ݦ��oI��9������
(b�<�A�	}�\� L	.�W��W����#����=a0$lp�soL.w�b2?�����eh%l��Fʮy��9�&y����)�3��Z��ڣ\��ݿ##M@�BK���K�zem����7@7�ȉ8��j�90�^}e��O�Z4 �L�Е���78�
W����X�Yю8bB��\kKnQ�~�5�D����&Ms���_p�&��x��eVG1r,��Ӄ�(@�(�T�����t�Y�1b�8�a4��*�Q�8��ʱ#2�Ϟm6���S�I�������ϔ���0��U01���z�'xb2�!}������R���p�]���
�eZ����^����:j�mn5���&u%RW��Ep�"#���rh�ces Aȶ����?&Qd�Є���F���p_8���R
�4	�d�ʻ��@T$��~W�r*��nг�Lem�}5k��Ŵo����3H=6zq�I��I�![�|���Q��pa���0��x�ZZ7���ԟ�Hh����=�Et��[k���w�S�����<����șR�s�����g9(�����6!��C@h��cl�x�#DS��h?婛����=%\t�X�ri(�D����f0_��2�F�����0������G�ViV��Qdѐ��C;!VR�?g4�)C���r����Q��N�dՊ��{ ;*g6��__��:� ��H"C��eN���\ؕ�E����{��8��1��[�"!Mf��W�O��F�$2��jUd�����,EN#��R(
��aA܇Ÿ��K��Ë�mf�%�m b���ͯ�/�D���:0`fo������	]�����7�0�d`�m�V�켩iٗ��B�s^��;4��c�s��	�Q�B�X���]7vB��Y$cj�-4 a�KvV��T'�%��XG��;zJ;���`,vת?�"�����]=��\�t5@�DJC��_��X<PeS�1�Wyn��T��;g�̴����!(����?�J���>�ͫ��O�?5O�s���>h�I��3���kl�_��h�.�hɰ�7��Ņpys�c��;2�E�����a��\.uБն���[;��)�$NdG�Жt�]Q���=Χ"�q��>l����5��E!�1��I4L��	\P��=�&MBoֻ���Ӳ�M�Y�$�_ɭ�;��y���u�0����8�;���M#��ǻb�����w<���a�=��G�q�ᗉ��} ���(��F��\�X&�^���k7g&�JW�J��e��O�T��:���H %^��[y��i9��=?R�Y	^�
k��_���F-e,s:Z3����P,�N�镠��}�;���Q�m��y$��I*jf�A�Ȇ�h��[ �{����H���k̶gC���.���VN��]:�<�9�q��9�hٚ��k��`k&��L�L� �uH����.2�.a���5(-�/|L#�dL^"��(j�)S�eY�3����G��-N��m���7�-�wA�.�q�O��곜�fSBo�-�qZ
�W*ߧ_T7k�ŏ5�VF�A&NϒL��:�0e�ХiI*@��ɺi�)���wb(1
Gw0+�֖_��>{B؛2�;��ot�N��[�N�ƅ�q��̆b��WA�Ҵ�g��G9���
Qs�d>X�<����t���8zu��h�X����+�,%���&�1�,����%�â�Zz��I�}?ut�A�t�j��KJ��"���N��`���I�Y~,�VXb�uD*|����u���A�-��28��KiRsʂzo�!��uy�i��ޙ1eNѥ]�]o6��rɂ�&�d%�Kf������2u9�ȉu��Q��w�3�k��D������O4�j'�=�P�,�w�+{��p���S�tY�l��q4eS,���ĶW1~�{F�vn�:A-�Wf-cC��   ���`oh� �����u?���g�    YZ