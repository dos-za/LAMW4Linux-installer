#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1727575877"
MD5="bb971f043ed87d0799611db3bba9092f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23360"
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
	echo Date of packaging: Tue Jul 27 23:12:06 -03 2021
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
�7zXZ  �ִF !   �X����[ ] �}��1Dd]����P�t�D�o_~���f����n���q�����NZ��ʄ4���t�yW�J2�n�b#*�;�>x�?�q�]��PH-Gۯ�N:���j��r?紸vJ0�)Y�)�|��F�Oe��Y��mUx���]�;� ��O	<��R�J%6�=�o!E^�'>y �zE��*f	��9$4�+��tE��yo^���sҋT��z7X�V�+lsi�Ք�
�B�Hi�Ѥ�#遷ݫ,��/���[�!.n��ޤ�: 5eCb�s��B��<�p(��3^ۻu˂���F�d���e��u��eO�#rQW���Y�N񞴝]}2ri�vm��l��b����x�_{mQ0Q�)jEߐ�����Жok��51s�c6��5��`��� [F���lF��D��l�.2/�u�N����p+��r�*O6I9�����8�E�C�k����g�\X����� �y�
s}��[��s
z̍��	��q6�2�ȡ�검E�/T��}'�X����Z��x��M�E+�v�=��"�cgՉ/���(�m&��32Czi�Ğ��?9�����������fh'2se�c�ߧu��mB�Uh!�-a��j@z�B�8sQ��x����=�����`I����#%�.�s�dp�)u�DyI@�D�t@H؂:�$ΧMv �^�q��Fi���I�yT�}����|��4���'�t���x�n���E���Օ_���>��;�-�������?�+L�2oW����YJ���[9�����:v}yI..<L��%BD8�O��e��^ ,iU�3SY�^5~v�.�ٕM�}Q),���k�E��R\�x���Un���m�(�h���D|�,e�nVqp?�6�A���9�,�=�T�̿(gmn,�F��\�M2�E\��Z�,�YYvF��'?KK�{+��֍�^.��\�����(+��)xp!�-��Y�_Ux�[�s�~M�ۓ�W��iZ�QD����Z,��k:XC� g���UU�Z�փ@�"�^=W��L6:���U�D�	��}�q�.P�� 5�ʗjտ�
��Ya��y�D݇'��d=j0��ժN�VOq�6~M���Sǩ�r���=t ����a1��L�ǩ��v� ��O�ף�~$���LD �R�F���y]�hl��(��R��~���IN�ӄ��lxc�� ��!���|E��2�`Am�,��s��1y��ɔ�ig�㰣#iݞ�D���2y��en�DY���O����ط�uhH�eڭ����ay��-<����̮�{Yt�����SCel����a,ͽ���C4��_d8�W3��,�8����}?x��U$L�^�uA���k6��e!��mE�=л�Z.:"W������ X'�V�ع�qQT�u~%!px��s�g_i���䦼�h�aVס+�5���nś6'�b�eɔ��KiɃsD���KA�L�f;���i�a��9�"��ZC�+­��ň����ϓh:D�F�+)��q���.��L*f�Y|�����B�j�
-^~�M���DC2��\8.I�qUT�\ �z�2�cEO��a��u�\�b�F� [>DΕ&�np�wk�K*}�ŷ�j�Mk�lKsؠФ�w��8�e~?n?�*�,����n�]�c.�*s��N��
� 5($a���b�� ��9�.~��ȫSv����q�k�>v�sx@��v���\�Ą���cU��*��UU�'�1=��4��4�[Zi�fo�mo�>]���$�-��MuX�꿪�!�B�X8�\��q!31��l�6v;�<_k��v�>`��ί�h��-R�����o�α�����b7f���O�g1�c�&G�x�D��2�m�}�_U��W�`���W���T�&A	b��|*æ��!�d$vD�5:��V�I�Q���0C(���UP�P	��:: �_�0��8������ޣ�&�p��1�ZR�TSk��%7ffX1�+*�Z+���e��.֗��蠙���S�n�Y�&��#㯈�l	FB�c��KF��p؛��M;IG#�s)��qɵ?0J}��X��}_~/]0�3���/�6�H�����d]n�Q<�t����Ayoo
԰�.q��~���,~��U�&W�*"ST�j���z����!��њ2珎*>t�YtL�_����TT�s��_X%Lz���vs<�txy0���2I�Iw+=�B4�]Jl}
���-���k~����wӹN�}�l�7�b� ~������@�#*��67�~0�%0�w^c�����׷�$�MX�t=e���3
h'�?���g�j�����x�����ۤ�Z-�����?���ɢ%��]�^�Rh��CMl�"��U�#�J������8�~�PʠB4��[1�r��C_�����r�} Pd]T#"�p~~���M%��OJr�9�a��TO�!��K��e>�;q<����p8wp��dGxP_������N\Z�r�,�Of�v*�u���yn��4��,!�$ǹR�xf�F�J&:��f�EzGZw�/_����������)=��\�O#��������g+�|�������o���>0?��p1��V�`Ea�7�&��D��S�����nv�P��;̭@/���:t&��r��n�Wչd�Op�&��DY\�|���a�U��.�L��+��{닛={/ȲJJĜz�M����AQ*�����?�C��IH[w����Nd�yjS�t��ެ�V!t��׳�E o����Ƶ�>����B�P��p:B�W���;!r����u��m�_�r���b܍_��ٖ��B�0��ݶ��gDA��MG�=!}G�1�;�O߸���x��wi���J�E��.��0��r�%�^^�R��D�,^ՉAWT�rb,�Ch	N[sYp]K��o<��\�m]L���z�<�$`��Rߴ�I�J�u�T!1����� ���j(����@d=1�d⼞�oj���M���z2��3e�Ba�����;�@o{8�qX�Jw���$C�,] ��}�ؤ�R�<.&ͣ����N{!�0{7��6�n8�v��#y�^�P<��Lp�-g�'���
�����`;�v �?�(4<l�d�P�μ�:yG�3ٝ 6�q=����l�4�*L��L�@k4����q���_��.���w�V	]_>�#pAGBފ�l~�e#W�(v�
�DB
��q�z�
��1�Rۡ��L��y��� �u.M_6����3_M6\�����q����M�>�,�ݠ[\@6����>�Y�[8̼(�q��fA7R���.�9\�wx����Pg�蛩���㵢��1���Ϣ[�l$����Y�A,�.0Q�kc��?���֡-���B����m�Ņ�Y[��悂[�	oz6a�"<,)v�ʅ6[n6�rl]���������?i!������-����9b�Yo��&�VgD#��~��nߔ�����b��O�$z��������sQ��i�1C�,n�s���-�DM�����Y�z?Ec�e��

�w����(�ᯖށu�!A�Ҁ�V[�f�T��9�<W�y(0��-E�_�9#�����4�al��?��U�'I2p
|�k�Y����R��V�9yZ���^�
��0N�X����2g�
(� ���D��Z���4!ȇ��z�i��F+��I��f)K`pxӆG��^�7���sٲZ0����U�`�)G��u�('چ�i�ĸ>Q����";�VCb:�-a��i�ֻl�2/�����BK�a��?T�b"�n�瑄g7�$��t=�,4=�Z�r7�k�I��]N��{��M2z����0gr��AG۬jIA���~v"�rMd�O�Tv��(�@�ꑶ��S���[GI �x'�&sr��K!a�uy��Yk{۠i��o�¬M//1�G3e�v��1Þ-�*smJ���Xۏ�ø<��[��,ON�	���D*}��l��,h$�>""���\9�S��Wk� ݡ9��k���'i�e)�ҵ�,��\�� ��yl;�S+�eD�r~�u{r�2W�,����?k��T����{Z�5��N��[)���H���ɞr�Am�ha����f{���T��Lf5��H򨜷�)vN'W���2��s�,��o2����m{5�&���劒�,JvY^�'dE�oǦg��.���]6ɖu#L��oET[�O~8Q���kMR/M�[�ܙ^o  �����0E�w�!j5����z�]�t�i3p?��@�e0Qj��:�!Aku@����N�����*O�'�m���#�3JOjP��i��;X>U��QQ�οH/�����!@�*}a��? ��k�3�Vqjd,��|�za$v-����_:��������Wn�ML�x���O��bI�!t[+��p�KM�q�E��|1.s<��M#����U3v�k��Y�J�уV�����,?$*�c{�t�7-�OЂYa��ښ6�+�U�N���g��ұ��.�Ww.\A�1�(X��"NK�ؔz����"=����Kz�'�����pE���U��_�5�d�sk���Z�]�<]=0���*��������P�tɰ���h��\c\�4�7��N��d�Q�#���h~9�v��@<��:�=e��q"�.��P���mp0��{���Y���w����I���wD�������H��t[�Bʱ~�9�XJ�zԔA��1Q���u�^��R�#f�͇_i¬��C�� %H�G����ͨ<��/���7#�_��ȷ�G]�eX^k����F�>�o����ϛ�΁nev�I���E�A�Gn)W�8D��j��ּ�Ȋ7`î8ko�@S`t`2�%i�q�Z�H}
�n���T�M*\M����D/��0�C~/�&c�nt��mZ�"��k�fN�%��L�e���s�ԥE:�v�'����ۭ�R)����?@�ᴤd��M�-]��*�ƌfX�� sG�gv�\\��3e׵ힹ���nK�����3���A�vTs\O"u�$�+M�q(�hK��m�W.=C�<�S<_���g�l�7�fs���D��85ǅ*;���m��E]� �Dgs�3�J���uw��)� �S�~��w��$�@_�k���G�[�qv��^��ǌ�0H.KT�cA��m���
)%m��XZ���?�h�A�O�8l�<���{��)�C����)�,����b���(<���hG��.�3DȻ�F�䡸^��Vh*��Y�NT��>\�c�>�W.�`�#��c�i�[Q��}�[ gw�S�%jڼ	}�Q*Zi�dMz~5�Uc����3]��q�m�ZH��p�i����x]�.Qi�v*��3���۫ Yہ�} ���GL�^�i�5�juU�*ׁ�)��z��v=��,���[��)��I�h��� :AZ��YW��ZH��`���Z�>�,Q��4�E8]@y�ǚN�=q ��7��^�
g�����Pm}����F�Cb���A��#����Q�.������~���^��Y�6G��@i���nÓX��`5�&��_�o�HPh���l�l� hd%�
꽚
�5*q��7��l5���B��Ω��z'+��I�l���0�Q��Ɣ����JHfdp4�Ն��
4�L���VM��|��x��5���{9��ჰD�{�|���gs�%�W����Q��z���.ofJ�����4�����#�(���{���o�>��b�ydL�Q8Y�H���{�>�H�����h7e��4*�_#�/W`�l��-$\�0���F���/�!���6� ����|��c�p�X���S,%�&܊aEq����=��I�<�	>�y$�/�Ͷ���~=i�a���=8q�"�I���Fg�@X�EJ����;_i|�����d� w�D�q��&;*B�-�	^����D~n r���.�d�%�=L~
z�t�4�j�9d�aZo�T��,A_�;]ĭ��gq'�w5a}F�6}����&���{�b6Ӯ(b��XZt�:0�D���}�w�M��7)���>n�.��O˟�rѧ��0,-��6
��x@dH<�?ͪE�2'������4?��{?�\*X,�Uo�&��B�c��#���A�����Ș}�3��}�H�����R��~�7h�(�����kW
���6�h0�e���@F�,0̗3��ZC]UT��"3�&k4T��WYԋ�T��i��9�E�L��"2n�����G����Q�x�k�o�K�A�p�����&�nן�e�C��2l�){p�ή�����V�K�ޙc�J�@r��Mt��P>}�{*��Ͼ������A�?�0�S�aws�c.���(�y�QU�
�r&kY:A���Ԍ���^F�&��o��ҷ��X�{��(F���!�c�� ]F��j��}~��7� }%S�VHث��Y��b&����-��rS��Z'���<�l�ri��Pi�9WW�9��Yu��?��d3V�|��Р0��o2�+CԊ��e���,ĔT�d7U�չ?}�n��:���ٹ�^�O]����[)��
G�jA^o�*@�M�[�[_�/ش��f�(�|��2{��K��m�[v�o)�4C��XnJ�t��o�0s��@��0b�b/q댹���'����X�ð�?���|��]\d��&g�����O�S%���Pi�(NrH|jq�ɽb�%E�]:�ʑb���_�W�����y�F��TI]G0���W��=W���(n۲�؍-]��HK��%o�{�f����qu��ך��&�Λ�K���$����+�}c:Q��/�JM�����.A�����A�Z���Qt�����iYZ�h~멈��F��y�����Iq��Q=Ճq�\i�d@TZ�I��N-hj�ٟ��y|����O<9k�cF4����D�UI*��l��d��mxq���@�V�ov��d�%��AI����l�Qf���vk��#�y������t�\�F<�E�����m�	�������>��	jg�3����s�^2r�sO8��n���"�#fn�Ǡ=�G��r�̫-���A�S��o�v0��s�!8����D���gY9V�he8�6ǉ;~�*��7p��c+,C}��[_��|�ϫPX��$;��zjyY
�
W��m��D)��|^g���ؑ�	)J54��!?�,(��uY�wH�����7$i�1y�{G`D-4��=���~�Ypv<��)��
Q�-�Fxmh5x����.K����;:v�x˒��07��~h~��=F_�j�K(m-=�([�9N�~��aт+ �qY�$��
�5�9�S��7���s��\;]�����dp��/h�TZ�'ph�qII
㇂�� �?=3�;H��~ȸ�LQ�R�#E
|D�@�7��h7缬����V����J}g�V܃�/	ܗ�ъ ��ړ�Y/��!����K��T��i�1��q�`B�d7Qh{W
V�E|��B3t�eW-TV�W5ݣ�q�t�������� ��e*���k7�T݉�y%ʨؚ"�񎫆�J%>9�O3p���6g�urǜi�y<+5YB�hlϘ��_3��0�S&�7�a����|ߛ�Ks,�p��ĩ��[����*�D�GK�Zﮰ�f�U{'�T&l��1��u ������%�J�ܾ"�^��Gw?�%�el��ߌ��;2jb2�QՑ[:���-��,�-R�#$���Q=�6�b^�z�O���S:O�d]�:8J!�V<{�9vJ���M�s���#�d�^5�׆���q���d�0�(n9X����@4k�Iqɏ�e���fY�D���i���9�	%��p6πP���eaD������qFR/��Q�U���e��c
���`%��Bj��Q۹�yu��PyZ%�.��Ⴄk��2���4h'����ö�ya�\�mu��|�3������+�B4�^�V� ?2}� �s�7���¹+�hayK=�~�DxE:Y͹�d����94�*�;�|���A��ct��w�?��.�;ә���>�¿�9ŗ��#I�Ek齲[�|ÑL�&+�:� �.�u��jwo$�Y	��ݒ@}�J�*��Ҵ�Q���1��%�}�����U������X����/8��(���h�~j>���7��\��`F��ڠ6T�|��D�W�ݓ�^E��������.H�q����K�&"�0�g��d�jxfA��w|C�d��>^�2SO���aZ���p������~{��kG����Wc�S�����/A���d sI���!h�e���^���n�%��JIב�u����J��{�Y5��{�{3j"�d�WƢ)������T]s��g��JO3]�e�=j6��/.#�iZ����Bu0��gXOe�jR��S�A��C�,���6%3ߐ���Ujy����}�.���*�`��~���f�Wc�Ζ�q��?�/���h��9��x��-�H�j�E��]�ʴyJ�ac�VkNd��}�����1|Y�_��]�o0�`zVS��HKm��bO��Ư^�I�S��@��Z�k�<�V�cI��)�5^��\J�`�Mh=�NlUvW�Mk��A�J	r��F�����_����^�D�Vf�n�,��Z �x��v�ĕ���E3,6(si^�i�)�򶢈��Ϟ7K�4�]������#�M�-��lb��;��a=)W�%�_�dU>zD`.l`pL�0��k���%�[FZ�~��ں�)wL�����qy�N"�l��%�m�4lA,�ۏ>X_gTxx^1�]�M!Sف��u�i�XY�����(�j�����!g	3�B3a�]���Cn�;�ɽf�'��.m�˜DV�h����j�H�b����"�����,������#ps�2�[q�kx��1�VO^^�V��n�5b>�����s�bY�Wr�s��vz��mO�]x߮0�d{������Y���cC��2I�猩��1#�`�~E=t$�Vd��+|Ge,B`����gw���+6���B�q����'�2?:KW�75h��U���j������,�V��{d��KM������W�SQpm�H�^H��w����ـ��+j���"Y��eP��M��(ZR��m|U
�q�Y�K�w��T���I�~�����}x��Ӄ櫑738���*��L����3��C@I"T���]����ˢ��˟�uuÈ$@u��v8�����Pc4�h�|����&?:Z��[i�fkq�fc����@�Y���	*J�o����{�V.~b ��6��t�I-B��>�y���<�V�) ����˻�
Y
a��E��&�u��ky(��/&簮�^h��U���0Xe��T�=��}�К�_b�{�yS̢�i_a&��q>T��x�3F�i�1=�'�C��^�v4�����o]����$���=1
U�j���D��7`F�o��yj�Adu�*�Y��R���b����?h(���q�&�����b{�v�Eک&�R�?���3�tX*�<^�c�} �e8v�W%2��?_�v3�	J,�p�(ྻ/����;�I!d.�G�rĻrRza�Kѹ��Y^����lN�1Ռ�L�]�vAT3�d����)e��G�Q|砖g:l�;~�w�������G�!<F�2�Q|���`����sm�!4ˈeJj�Y����2���S��hL��L6�}dB�u�eu�F,�Z*f�ӥ��b���ڡ	}cT�w��������q�U�`%Y�_�B��/-����FfT���&<f��>��+��"��3P���I��Ǡe;�dC�~(����k7�γ�
#�]��[������v�M�W����t<#M��Hƍ�Q%Cb�⩩���4�E���:�`�
�
��f?��A�j�*�Xݨ��[ĉkhEt�۫��/��.��
|H����5	ڎ���i��bz}O|aCFn�E��Rd$�,{o��iE<6-� �0F�_x���v��Uon�)@����Q�q}�q�C]��Y� .Ͽ�_�	ŗf9T�\m	���h'���D�����bXuA�c���= �zG�)��zyci��Bf�Ɗv`.q�_����~j��@��1'Zĉ"���;��hO��*6��҄���e)�U��B��J���4tK��ny�l#�y$ݭn'q>q��P[SY��*�M��n�P>ᛨ�ѵ�'L4�[:0t;�u��^��	
�qUuv7��uN1]���`�q�P#Q�9�-���Fp�r�A�{ ���M]v���]�s�熅�FA�	LUQt��3s9��b���]�8��x�?����K�:�> �6��L͵Tb��`	f�A�Oy�:	�r��~O��k�E8o�%Я��<�Xz`KegL<����Q-�q)2�7}�V�� �ϒ��d_���%��]�H�h|�����}!�نH�L#�t�@�_�R��7)���Y���uy���4E`�E��9&��h��^��R�S���6�\�lg���aj��$�3��b�C�G4�oL���c���U�7gu�'������RO��6�K%�H��n�;;���C�Z�:`#��rt�6E�!^�s���b�3�?��^Ƞ����1h�Æo*�W����Ɣz�;HY+�T�\��L�-\fL�&5�����㏵~@���{D�9�¢Xu�2^N<f��x1Կ���=��&a��a$��p�T�����,���ۘ������q������q3����!���=�:S �K`{<��S�����^�����1@���J8�S "�U�/�� RFD�=ܶ{���3��yM�=Q(����)x�?������4�Y���PI���������-� ��>��;t
QYD��#����&ϫ�j�,#�����.�i��s?5�W@˽4Rz��v�����1������.r��[�133����@F�:(��{`J�3���t����	���M��}KI�������Źmg��e��Z*�tg��We7�>l��Ё)MsQ�\J(� � 03g��ꔶ���:!�r��b�A��]�y'.��4�C��C�Js@U��[���x���&@��?u���j�.4��v��Yq�*��@�a�|#��+� ��EU\��â.�<#�u_ךW��\�B#|q���Y���/��y8*fމ�`�R����ꌸ ��`v��ŭv
��_���ClD�'.mt0t%|O�����&�}®�˨�<�Sq�<G+r��x%��m�˹���N��� �	H(FN*h=kot���=Y�5^2Z(�k�_J��P���S��>��xhK����<�h0��������e��dP�c+�k��[�Ca���!>e��պ��Z�<4l�\33S̡����ӝ�І���c�����������QF*�,A[ߨ=�w峁5��_L�v���@�hsr�n)�|Ѻ�� ���B�s���X7�� �kP�%�>-��q���L���x,2@����dX�9�[�r�9�u�G�e��s��ް �$6�±�����MD���71�q�վ��1��,;����)��W+�z>��-�)�����~l��E�C�	��bT8 	�%�z�� �6�^��Z�"9�\3,8Ԡ�f�i�]��'',��QK�OަI���C$���2(E�l�8��Ym��Ĳ)����h$7Tz�=�U+�:ⅽ1<��&��R��9�ݼ���a���A�:f�M�F"g��U��/�	dMu�%�!����A]�/�ŏN��Ț��xw���Y� #��+�Ȣ�	�n���h*��n�YY��FT*딚b9�HG6���Y�;��[=X<�Mi�)B�nC�lTı���������1c��»��e�����_����f�g����mk�_wNv���ZA���W�זpwx�}�w�1�z~�Z�׳S�k-��2&I���\/��:*kB��8��� z��>z���j(~V�8����tS��
	!sexPn��vQ�xZ�G�&��-�]�Cp{����Fw�qt��h�){A!L'�838¡�XĿǠ._|Q�X�E�-$�t��y�iI�f��cE򦉀�NF��m�OG��|�o��u�p��:�-[����LltC��-f�����Ɯ���k'��F�n��Z捯�r_�3��Z��`5n@�SH�N0?�1�Mjx:͆_/O�0J�
�罸
�����ٮ�$�cE(�t�����%��o������/�d}<���wP@���:6Ч�o��=	�R�ø���[Q�C�i�j���l�'��|}�]]go�s�8s}!v�L��z���(�~�ZG�E�!O�	m�����3��uȶ�����h(�6z����jH��FTϛ
3��rⱸ8�cH~X� S�Sy^{M8���&�H���'��_XY"ն������A��ɬ蹭Za-\�FL�������2ݭ�%��ܶJ@~�g�(W�������p�8pEZ�7��?أ��`��#��dպbr8��!2K���)78-�^Q�X|�=6@j��fCk�}<�u�O6>�aKm���?}D#/��Ay��U�Q�r[)l�0rf>ˬ_�/�#�
f�<9u�j�y����D���F�/�~7F��@��PL�]g���6��t�V�q������*!�1�UK�bp�k�#D*��U�U���[������
x�'.����Z��J`�B'� �#�ۇ}���%��ԿlyR��12�q}G�C�4�}�]���%^�ף�������w�ϋ��ZG�o�3We����m��i�o���7����ʓ�漷a�=��l�n7e�6��͘9<N�崗ϗ:�v���[k��P-'A7j��7N�*�5���$
=���V��q&�|��ؐh��˪,����I�0��s���O��3GᠹY}�T�����<qjL�L��MӴer��F��/�f"����ru�zV��}����E��
eBJ�����2PQ.N�f�L0��l��p��y9����{��9$X�t�s�?�U�� G/=�;�8��̞�4�;?�?Y=S���hڦ��K��bH�N������gd>�v��7�&� V�	� �EԚn�F�An/ʇ��;ҤF4�?���K١�{�?���6��,�c���/�0�nЌ�s�5�^:k���U��O��TCX]�IHܙ8Tj�*J�މs��rG.�2N���A��6!����p O�tѪ�H������P>#_*
RM�TIA�Ь�O�<���W཈/6�����!���I�*��ļ����]̂�~8Y�9��q����g�E��>*bP�&<\G��/�JA�=�E�S�����>�ڈ�}L�A�Wh%oAh}I<�&g �Ф�H��7�m�T�l�G����`���4 ���*Ք��@�iBa�>�3X���Qy�Q����п�x�Ա���禆�"-�F��"�{ B(����+r��<6^I�&S��2�i =ZϹk��7�E���~jN�� �����̡e�WQ�Ǉ�X��:����|�D��O#��f߭�����x�)�l|J�
;GpΦf6'S�~Y���[�U['T	�;��U�PQf.1���Ω>�׃@�2]�ϒ3];���DK=�����R�*�Ƌ�|HT�+�m�'��"S~0y3���TB9GU<p�m��n�������yF�si(�! ��_��^���e�$_! ����۠ó҂Xb�>�-�����9���\���B��t�����R�;�a��k�G�>���h�Thq� ,L#(+u[�qqV�f�G�@���������ЄHl>��p�I�k�r��U�EJ���|�4�����e��=^jbB~|[[Y�v�ym������mMX�^Lv֬T���G�]y��1.���^��P��?b���
\�gQ�� �<õKrk��xv�1�#:!����G<#q�*�<C�T3��]
J-*b�1إU���X���g����];:�u��.C��qM��H��@|��]I�[F����Քj�>�yr؋�X;5��#X�����&�������f��"��	���#��?Ό����@��B3l���jcLQ�B��2z�����/:sn܈���X9lg1�'ɪhRB<Qtʖ"ss�0z%�v�$>"����R��m���`��`�I�C���da&v=`��lm�r�l�[�t�4^�N�G?�p*1H��M�92��ŵo8y�"�v���ɶ̃��r��rLɽr��s�%M�>(�(*g]�d�Ir��x����� 1�8	������sȔ�5����f�QҺ����J4��z8(�.36:�?}P�S�r�BM��:�9W]�Ul���E���n��UX8�|�͠D{����r�zr4u�v�
����(v4Ȗ)�����(�UϵR�N� u��v~�{<��ry���h���Q�]~�@��!90:y~S{���h���,���,�0�B�䖠�]��a�ā�r�����v0�Ƌ���4"VSzz�܇})?mTU���ϡ>e=+(���O���X/��aLfܩ����Ϟ����Ϫ��ftW����z�my�KRW����!�8,�`�xn:�[h�h��r��ֻ�}��b{z1[�ުL���  4�ę�Ywnmw���V�!c�cbDms�^���/LGsd�K�C���]������ �#�`I��bJ!`���J~pj��\:"J�[}��L������̢��S�5���Ȱ{�*�!i��}��o�p�zk3
��R#���ns�D)���� �v�3a{޴6��X9��)=�6N9��he&~���ʽ�V3��.xu�}�
o������5��ƕ��;�`���&�ݮ��8�E����;�G�u�@���|;&��l!׊F�C�?
��zh�#A]x�r8R��&T�+�л�B8v$��,���lmHb,�ʈ{X8M�؃�L��"X����h��F���٥*C�����Wyu��	`ljR�L��ug6&���6��׾�����e������^:���!e��?��&o]�I����]���'si)�:K�0zTj����N���ӣ�4�)D�#�}��$ȢI�HB�2�Љ=׫#�;Aww��{����qD]�I_9��̟����K�+��Qy�db��GmPr��LY�Jnw�ę��!QZ ����:����c��0FX�Q@�*2(�|�}�jw�[՗e�9p�#_��F��Vo�s��@<��h]�,�}�dP��|�.s�sn�9�"�c�n���$���O ��KOJ��{�b��7��=�X��5���w��X��93�k����,=�>�58���p��6�ut�F�] ��VP��@��D�1u���Gb��Z�#q	?�v;��k����=�˙^)8�fj��������\��������p>�d��0e�>��������qou�ŃFS[��m�D��2E�8��7
@]����������5�ł��v�Qʽ���i�!C�i�%���."����ea����䳯웸�K���A��/���%�t1�oa������BX�Q0�ʟ0I���AT�N��#��"H�G"�� ۃ{˾Pxȳ_�I��b�cg���M��W��`5���&gK�tJ��/�$뀴m��ϒ���Q*�P�܀c�/ͻ�����Gߝb�띇o����)�WY�jHf�3�v_{���J����)C{"���:��4ܤ��YN<���|�8t;���e_��7cI�饿�F��#��S��d�E��^d�'*7��C���rv��!�0��\Թ��.��h�wߢ7��5Ӆ�{����/e�Z��Ŕk
�e>�K���fc��%����sA�a�ȳC���|M���J�>fi6ފ�V|���y�d���Y��Iav؃L����.�DKZ������R^�'�Y�T��[T�KK��1��3 ����6gx.�-�b�te�:��Wk+�����;x1�:���^Ԕ칶�Sp,K{1�N�3��%�6V)������\Yh�6��[�PHl����-+��w$������9r�]����aN_󜪮\��_8M��7Ҋ�gW��9�:��9�35��p��>�֛|E �i#�V_���8C�W���,�����UVs�別�$�v�zh�ʏ"Y�D�Uq�W$�xxK���b-'OG����2����}�֥�(�y��Z/m�u7p�ֹ�Q��L�%i���dwS:���*��v~aP���&"ΤC2h{m=��ҩi�T�(GغڄA�Mg0��@�0�q2:	��!%�ll��b�đ�]���"�L��&>E[#j��Wtc�����r���<0+�d��=yC�Ǽ�0�����*��2AV1'��$'�����;8�n�L�[������v��k�*�(��d��Z!f��;mi=�*x$�=�K��W0X�d~������~�/6�g����-�<�� Y���o��s�|i?��m�TF ����L�;>){�ޞ؆`�FJoyo
P{K�}�t{Zs��V0"Κ|��V\GM�a/��*qj��\�(Q�'��Ү=�A`v�i�9�@Z>���a����S"XcAv�.m:C�`Zd�͍y˼t�G��A��`�fy=��X$M:���|�q�˖[�@��Fʬ�p��"7EsD�<r�/Bǈ�	$�*F�rd �l������8!��-�U��b	�b�e%�.�E$����J^��4�U��e6'�յz��n�(�Z��K.�߀.�	7��W̍�f�%�	�C1�4o����2!�0�q ��mud����g�s�c��p�6��Nv�!^UW��+\#M����� )�&��`g�x�ךϤ!��"��4��}K&3%�l<+�	`j�5��I�>a0�}��k~zh�h��9�s!~��E(�:��h�a�Y�+�W��{B4�%��^���8���v�ד��|Àr�f�����n���i��t�!�Ea�'�����B����aC\Z#�f�_P�k�c9�`�L��G'�y�Ӏ���ץA��yƲ�Y��mN���?�S��_�e�O�����5p�'��v�j���a	%xD�$�[�.z��㒣)#.#=�~i���4������3��ދ�.�dM��[2�����~#�)|�*�2'O��� ��_点��ww"���&�%<!-!:�����7��	6$�H�
h�H͍u�l�~�����Ұ�qZ��Nnj%S�f��/&M��O�w<�!��y�F��z%��##��P��Q�ߐ���ce���I�%���y�{/�]
�ז�i,�" fTv������ZP�<d������J���U��^ؚ�.o��k���]��:J��JU�9w����T`7t�N��+�F����h��}B���W�6;ʷ��'A��k`�z�YE���v69)�CR�΋�X��Kx��1��e�֞b����Jc�>��^]P@PpO��Q�l���(8L3�hpT�<kI+X[Et\�rB�z#(OӛX
8���+��^�SՇ��؍�P��q:��"����˘�A���}9ʼ��vW���-R�GS)��;�A��S��HվVg=���
.Ng�Iʣ-�l��xPwuV��HѪU����6�	�p;6^��'�+���	Eە�����a��ʣ�8�;@R�v�q����!��n���r � ��ʚ�/w�_��%��r)Q��W��Ҹ�گ���t%Ըmt�=�z��Ε&����Ϟ�#L�����@��|��r{	"�l,�,?a@�cbǡ�Y"�c���L+��m��R�4��l�ܑ�ZȼHqŞ���;�7F��K/	��gH����a������˙U���8@
Ւ+�T��� _v$��Ў�H�F	k %l8��F��s�2�V��6V�h��)����d��ޡ�X�!�Hb�k�d���ҲP�Ѣ��y�K1����Y	tZ��ӕ*t_���׳�	��.Z��G�	�k���|f�f��iX�`�(��,���)ʮ��,N+�����rv�;�]Ɇ���� ���4TO0}��p��H��	g��̼��+)���n#>NU��<�U�U"��b0�B�m%k��G��R枯3��t�K�G5v[,������	��,ي���l��� }ho��
��T�.���l��3^&��v2&Y�@�=� �4#�)qk+L�c��hr�b�̔bd��x�f�.�6�/I+��meե.5�A&�)u�M���}-�Q���*t���ڱML���!Mʛ��G:/�G�gi�P�g������,M�2�;������C�-Jt<��k�?�(ѪcZ�+C;V�P���$bi/�/���?��(-Q�3*��D2+��vwػb�k�Qa�׵\�����s;���}� �]}�;HK� �Rt�������~i�;�������sM�A�BY���q���Cv5!�L텇�z�/-$�#(	�)�D���H�e!� �hC��qhlX��Ў 6~_.�L���]�vit3<��,e�u��և4�:��Q��UihU��v6�0�Ы��ks�%���r��R�����O����q��7��!�8zUp�*����=Ʀ�By�����jHǃ\�l��)����n3/,�\�N}���5�Sl�[���6:������/���� �Q������$C�kuO~�K ��)>��j� ��)5;>��������(}��o�Ø9�0	���hA�V��*��k"����DT��[�XjR���IZ��#���6Q��1��S4M��NW2��i�UHw�f�p��i��G.+ͮ��M���`��ī��3�/!��>��ܨ��+?����r�`�:���f�5��zzɫ(�R�w��+~�=��ꗀ �w8�J�*�*�d��)լ�I:�67�>�vw�s�X����G�%��@�}�.�ƏSYy2�>R\)���ܢ���2ŝ�i}f֟7���@�-��	���A�.�	�����=���Y����{�F��]4.�hy��������P�zЫ&F��@��̥:݆ā��`�%�_T�\��}Ln��ҫ��J`�aC#|�a0�N��C�r,�+J��|��I��6��l�{v��$}��b��h%.�`�[�\W�W[��d�6U����XTᩆ�	$D5J��o2���n����l>%�@�U���RLʹhDg����5P�@����8B	��X�bt7F�FJ�9FU,�߅�~M�����s�1�h^�"�����4[~�6��@z�e|�%�;�)�vg��WsʻW���dj�O�]��sD?�{�[/5����<,�4���US��21�5v[� �Uv��ث�V��SW괘a^�X�b��f�j���|��[�ǖ��O�N<��-o�����~-�jxZ4��P�=dH
���T)'�i��#�2�F�GYS St4��eI���)?,Q�/����w�v��t�7�&8jDG�	
G�Z���P�փ�{0	��*�%���iɀ%�[V�T�Z���1��j^��f�m�wAQ[�w�f��z �
y&tOK�G!�~���I�O:�a���xm���v�t��O�2q��I+I�=����w��Hy�)l	u�WMb\��Y�-%|1Q�i����v�NW��,���zb��sZtD�$��sߨ��R5ꥭ_ק
��3�m��ﮪ ?�`�)$�4n�m���#��;JʨՃ��Γ�ő7��������P=@��Q<�Hl���zAT|�s���W<Q�/ʮ�	��=�B^E�-��&^/x����Q�r�}���q�yMK��d)a�"�~�o���N�!PD�u}#_@f��(3�5O>����pN�HKzBJ�\������Gt�+H"H�k�?������~:|����.Ћ���y��L���yg��'pw3�� �:����G4Z6�mi"�g2D���j(o��.�@���l��9��uX��(�W�;������U�2�E�]E�����m/�䞯�FZ������^I� 	��!09�U\p]�b��s�y���}[̭a8wy�P6:�Q��� �\�U"�5�Hg�60e���Y�Z��L��&Z1?�G+]8ko�Q�9	���NUo���DР��'�*�؂�m�0[�r�V�3>:�]�Ц�`,��kޣ���)�_d�걄��S㦕��=mt�-�� �M
Ik;�پ�0��zUp�B�F��S�/��q_߮�3����6`�!X��p�ޝ�� ֡zɡYR���<d{��4�-��̟-_�O�K�|K�́��M�T�g|be���j�|��G/E��?���uVHs`���o�H��IR�����~�꾦9I�2 ���+�"(� ��u3�dRC�ߕ����M��U�y�c9�5�
n�V�O��/��w� �}�r:-hSQab�#����{���^�d��xA�|hc�U�������t$���}�&�m��<T���r�T�Z�|��ޠ��o����-�����k�c�o��RNx�o!�����;��3�8;��Վ����<��&��	`nd�<�ʀ�p|�l-�?��KOSWB��x齃5��[;S�6��d¬��l ���q����&�G+\�="����^*�L�^ļm����;N&.4��KҖ����S���
��<�a�h���UK�,�Mt5�~ma?������L����a�ɢ��c�vY�����<�n��E}�Oc0r�5'��{�h<<����6�.-��3�K߰搗�Wa &=%[tZ-c�܁���\V�N���ΐ�p�ʑs��ܵdqΨ���]Q9�H'���wo���՟+D�6��do����V	�Fe�PK������q	�?��z�{F��p�8	`Q�7�7�� 0��B�5a3Ͳ�Y�BVm������4:�è�YH4�o��y-Xr2�N)��״��f(��n�}^x����?���/��>�׶�b@Gr�s ׊;�j~��T��YC%R��V��ɂyn1D-�l�)�,w�wO������ю�!"��߸]όP%ܴ��nqwr�B����	�Ս�t�A�ś/�h��1�5v��	����qq�J8���àZ��
+Z��	�;O�B�����%���m�+¾�T	���L��o�LpkBw���'�#�>Ӗ�*R��7����(e,���e�;>�޷�ҟ��kD8p
Je���_��]������;��	���`c��&Hx _�B�$!�yq[�J�����E�Tǵ�x�B�Fbꖣ���1	�&���8���/�U:�����!Wqj_�4���v�2��ӨA�\,���ݻX��iz+44=�����Y0�D�)�m�US�7�$dQ�Թ�e+RA��M��U�����-�Ϝ��F������vFk�픽�T}X����E_(�bSM�IV䝁��bB��Q]u�lǂLT�cT�O��խ0���G��y^�p�כ�:��U��ٕa:/���Y�>#&�_��~Q�`3Vv�H����X��,|����ca?��⌛�'��0�T�������CK�m�:�T��}ӈ�ϭ�vK����GuJ�M~Gkc�C�����M�B�+U�3@��]�b����;;2�.#� �M��:�y�t�����V��%���?Y��B����ZM[�Lp1t�ƕ��Ϊ����j�{z�P���U+\闼X�X�K� ���&��z�u��Fz�bp������ϊ7�R�
�*D���r������my,'9Kk"}��F��Pު< �*��U�y{�lM�k�"�rU����㢪�p�e�T���n-��VT"<dc]��kr�OT*3X����u�nܾ���4�M��[ی\-�R���&����(��QnعQb�l��Ռ��>�Q������/3/pIZ�$��W^��?p}~����ߖ��㎚�n%ӷ`�c���1���P���ъSo�~P�
���>�t��f�ܱ5d�7��rj�&iw1���'��l��e�s6"?�p;\�u�BMO�9�TJ�:�H�*��
��ݏ&�;�-\Dx:B#��uNGaN]��5S�4V�<W�[��yK�L�%��}h<�b�`���%�t��JD��dOl��c]��?2rٸ�;���$	�%Ҍ��I{���Y�\6K�����*��<�� �Ţ��d��s}�Iy8ن )��B��(���}�N�V���Sa�n�i���%��(�dS1 r$_�1ݺ��s�r�bJ�|,"ҫO�{%��f[ҧ��#�,���J��s�0��YB~&J��;3>�[��)]��f90d	DT-T�ފ���kxd�21����\>�jB:��Tqi��F��6��8��wQ��J�UUo̎Y�vF� ��n������oo�J'\(V�:|L��-��?&I�EA��� UJ���qZr����@m���}9�,�]�O�6!�8�ʒ�
@�X���ߎ�>m����M�}�^�mP?]����m-}q��B�V��E��w��APt[�MCȅ4��btЄ�������H�7W�&'E���U���U��uS^�l�}��/�\# ��)�l$���|�l�Z���
�P�;���cB�hw�A�_�lt߮f�~�
zC��t������@c�F�n�(cY����9W��S���Sř@�J��c_(L9����Z�Om���x��C��A5�M��,�,��xNX6Ɏ;�d:~��V�	���0���k:��)HP����EY�F0�x��h�)LU�v�����
?������'�6;3��IѦ,�����w��g[���,��  �I[��/ ����Y�a:��g�    YZ