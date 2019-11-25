#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1921334511"
MD5="dc5e1d65d8ffd9223f01bdf891d97e9e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20585"
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
	echo Date of packaging: Mon Nov 25 14:47:14 -03 2019
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
� ��]�<�v�6��+>J�'qZ��c;�]v�"ˎ�ҕ�$�$G�!�1Er	R����˞�c`!/vg ~�e;i�ݻ7�a��`0�7@����Ӏ���m�n>�n����A�����F�������llnn= ���'b���2]�������~�c..��5�4����֓����o�47�������7��v���Δ���?U�z��K0�2-JfԢ���yl�9<�<��,Ll���Rm{Q��.Nm�N)i{?�.��y�.iԟԟ(�}�K����o6�?Be���C��Q��Ү��B��H�S/����u�
��@u2:0���"0}�d�D�1\�4�Qr��L�"�T�����g��F#yl��Z{�&�����`�=�ZGG�
ɂ�"x�7�j�~:��/:�;�l��ɨ3�z����(kn�,�g��sCE�JQ �h�X�R���4�"�a���3�h�o���}�V\�J���ιJ��|�;����5�u\瞿����7D���z�r�KWH5s�o��[,<Wcg�o��b��a�N`[�)�4���v({�qM�J�+=\�z�>���
YE��z�=X�L�>��sk��!�,�<���	l��N�l�@�R��!�i8����dP_�l?ݢKݍ'���'�A�n�b*�b�T*�:>��c��֥�0 ��g��o� 
?l�2j����3duCMhQk	�ZNQ9A�4ͬ��\��t=E�ߐ*�/��$�,xȈ;���7X=����2������4E����S�x�/[�)���4������7�.�t�A��u����Ȣ33r�@Z��N�&>�D)k�S��u������=�mxa�bFx>�C>�N/�PwI����Q�W�� �[���Awm�o���	��Zβ�˅�(c@8"�]B/���uu/���r�U�*"w�NA�����R�:�Er��*�L1�Ԥ@��M�ln
+��Ƙ؅i�)�
>q���|�ya�}*�Lc�Uc���Iԩ�2�!��V�c��)'\���la�|Xߊ����������ph�s2�88�V=�?C�����6���|Z���<������s�mR�h�&�*�&����x�6�����Ry$����a���t-_ɧ�b@�[�������b~1��������;��&{����x�U��3��j���w��{�!�Q[�5�b��+i�N�����>�\�$�Eda^q����Ga���dϦ�$�>Yx�=�!'�`��qJ���|Y`5��̀��NV�1�_"W��C��h�mQ�^�2
�L�\�9eԙ3�GH<#��[�@�tbd�c:�%ga�]]O��mO�2E%��Y�[��+G�_���xD{f&L`��2��3�F<ӡ��:y����{��uM�[�8��j�����%���������%���WmَE�:;���?l�֊���������?����7������g � a깡	��� �m��̩Kv� B���G����)�I�5h?���H˵϶��cW��44!F���?�<2�qgZ&q=�o�7�X�[~�{`�K��b����X�Rx�t�ocݹ�To�{h�p<�Gi%�f,�u��XfX�O�����X=�Dn��u�1 �L,�]z1�8��	/����aG�]�c��H�����̜*)9͌�'�F���s:8�B5���ҭ�
�D1N��ؤ�М3=���'�Ƹ�J� ����l�o����@w�	�PU	�}p��!D�է�y�s�i;�z��/;�a�wb�K�YzM�f\G[ ���[��؝��$˸�ag�栠hs7ZYWZ�rq �!(�\yQ3��x
������a��\t)y��x������FaP�a�%O-|N���|��cO=>w��ɍ��Ϳ���ݾ���/I�����+�	S�k�%ݕ0�@u��ٹ8��g���9��&cۈ+�j-7H%Q�ճ�r�E�j릺�\�[����"�R�oz��=U�wi�����+�px��G(�dq�����I�Ga�?�Z$+�f��M�5�)�x�v����[��Mu|���ۏ�L���'����{�.�̄����	���ɨuxÍcɌ7uy�ꠏ��oj��RA,�>���Յޔ`ã�X�K�A�DT�AO	�V��$g����$4��>���� ��ȋ ���pEy�Mm�sZ�B���f��+�EJ %�T��A�`��������GR[&���x�vF�	���f!. �s���0�izá l� ��i�h��˃��'*I��?�t_�3��*_n� ��$nIU���I�ıw:hwG%/r`��Vl4~����~�������O/w��,;O�F.^�`Ӟ�nL�E:A��� �2i�5Y}j�'��q��F%�j�p�V�d�%���Ǧ�R�W1�@���v�����$��ؿ
$��W@^����j�@:�l�:HT�˺�
�g;[��pCV���n�CL>���������Qw�@���qy*��$��c�f��db��r'3>�M�X.U?n���;��#9�sA�r�^4Ƿ��M�!�DT��[؆��4�x�y�0L�+[r���{���m�M��rp�:��h�N����8���0�IȚ�-Q}�����%�$.��
99�+f����-�)�ʗGb%v��l\�)�Iߜ��s*<�~�uz4�o����$a�]�^�K/IHj�0|S�}�n>z���2���*��}��_3b�&Өe�+�������vV����O����\�]`�W3����Iz\��K$����e��2{�P^���7w�Q��׉�Jx]�^�2�.)00�vh�sD�P�q%��w-�:��ڿQpȠ���?s��` ^K\�p��\,�3�� �	|t:����K�"j�'�P�U���i ��&�A��=��l�=��<�	��>?�$Q��|�|�!uM�����;��s�?��pFO��:ǆ�Fl�~OZ���ڶ^R��h��e�d�7���{�Cm������w�7T߉�W}�>$��Q*���q"?K�nj1�uބ40,�.���1C�xZ�Ǫ\C(�6��/���P�S1����yϘd%(�-*���'WF�7_}#�E��Q�ό�K��#DU.'�Kb�D�!`�3 [T������~�f<B��j� �Nb�P�6H �Mi��<�y�xzm%? �[���x7�9�������J��ֹ�;f�j��Z��N&��q�4���'As�-��<�7�p���@.��^N�V�G�(�Pݢ���*���A����F^��1�b9��Ï�?��1A�<�J�=P�7%��D�Ķ�TA���8��DGX�J�q�8�]j�x����3I��4��D+/<劻Qg�3��܃Y_3;� S\��\P\�0<�C�����L�-q�Ђ$õ�8Ǎ�)	}*Q%�TB�b}\�nYXt��^?���q"����ذh�1(	����d j13E< U��x��@ym�������@"���u����%���=ǝH��H�'P�?BxQ 	*����d��s���]����nK{�����b����{c�Ө�O��~&d�>��H�4d�r$w�(��4(ZjP~"��~ߊ��$9#��T
[��W:�Eyf��9���2��zH�;N�{RF(&�bܿ�g�"0� ���ǌ^q1J���yo&������*���7�"���HM ��̆"*���-�I#=q4��U|}[C��U�XY1���\���թ�(O!�Јk*��1�]�³ ,��3��ۉ�v�c��[��!����#�qRHYKE:U�3gͤiJu��7���x-kz9��2��ɣ�`�y9|�1Z\����`�	�H���|/	� Oy��6{�O��Ĝ7������}��F?qhz�`��9�⍒�f?�6XW�A�)��.;��s.��
oGLG޼+%���&vֆ�}t�jQ��M�-����P�r꡸�#�2=]H��Z���ug�.�*ʵ�K�i?���s�S3�Uo�b�p'����l��u.fL�O��`�޺�����\g�h,emF�� &>e+�xg�1��?s=G���0�Zi�'�����;�� 5iSc
!m�l4r�b1O���`d�"J��I.�����#�ڀ�_�i�T,��޽�R��b	Sӻ
'�Q�����Mq�����"�����-�%:3�"��L�޺�e+뻧\����ݻy���8#�=���Kq�<�W,��_���c��I�,�&ԍF��z���ch+�\nq%���N��CV��@_P��=¾�F��3|���e@��B�/��wb��I��^P��VZw��h1o�n[�����#�̀��ͤ�/����zb.��m���z{Z�"|D�sI���7�B��iH���4�Qi<1)��|�U��.c�I	�N�e��`"X�nC�QT��`@W�F>nD��횎13A�DӕO�V�o1� )s;Rpf�[���sy������ixmρ�{���"��q�1+�������P����=�/���?Q(�]�t�r ؜o	h)"!R��X�8��L=�¤�y%V��^����!j�{}���A@i�kOpg/Ϥ7�-��i^���^�w�Xʒv.C�߻y���C�x�KӉ�Q���ך�[��[�@����k�F����҄�w[�����;�'	�Na�{!;���n���A�Åx������<���txS��������Ψ��箷��n�i�\�슅t��m�E�8�Bh!�
v)� y�E����SGC�Җ������"�����(KgK|v�eb���{�H��l�F��Mf������KHE�Y@��']�(e���7�`��eM�����@��)m�c�8���tϱ�ywk�w�du�ce���E0����Vɑ�̲�, *�jy�USV�,a�{si&�+3e�b�/:vj��^�s�D�q��Fᾷ�5saALJ>n���u#7?wP�����D1Gڛ���
=��S:��C0�=��%KG��
�<9H�"���:�����$M%6����'� X
�)�� Urd~��'J` ��S	H6w.��]�/d�٪K `Zr�''�xK��B��Q&�����hRrB/��Y	c�eґ�*՘�� ����3��"JR�ǏB�Њ}���_0�K9$uƱ�	��B�U�a�`�g��j�H]"�6V�Ҿ8?�z�_��|� Bpm-0oK;�°D䇑��l�!\���ihlƉtRq@�,u�B9���(F#������:��I�jlK�"���;w���D��K.N~t�#���1ſ�g(����>������q����R�'�3t&o�]�YwZ��:�!X˜J�����8��%�Q%�CnG��$��֍H�w<jr�|�0ɼ�B�^�Zd�Y����bT�Ս�~]^����95��V���g� �	����Y���}[sG��ye��Rc�Z @�bR�!�c� -ψ
Dh�mh��)Z���}:��2�0�h���̺tUw5 Ҵ��"B"P�KVUVV旧�ߡ�~�"�6�+�Y�nO����$S�B�l����&@OhWs�����Ō�R�W��7P2��^��_�7��~
<z'CN	������rA�J� �C�Ǧ�/�k��J=�IK.)�� �� �`0�n�ԍ\q�b+�cXt��P&�����^�c- W1p�9Z(�y�H��R9���g��L"x{Ec�;��D�^���{�I��n[1��f��'.<�ɀ�pk���L��[�'[�tTZ��ںQ�L�h|c�ʜ�F��U�"�X%4���%Ս���;���}m��K4/'6ĚSiο��������A���e3
��P�Q�:Ɯ�)U�u4��PWF�F��S��B7#�q��^��sp�DkM���R6��z2���V��,����´�ᦋ#���I���&r�\H�O��N��h��c�;D���$��/�~XMg�� 8;KM'�;^/���_a��W�A��]腟��z㘿����|��8}��&���(���v���&m��4�*�V�h_U�Aȫ�|�%D}�2��|2�s^�$��r��wڻ��}�e�/����ˢk�8�}�1�"�|���WQ���d#����(_�_�7�W`Py(�� ��~$&����i����'C�	�\W��6��;LG�Q	��0,�.���$��?��k��]�FDH)Q���2�&�&m�`H�h'���EzҾ�,��_���`H�Hf���3h<��R��fW�I�B)F]����"�Y
�bt��b�Bb`_�'������m�q�/�!���U$(뼜˵9�'�npb�#�]T:+��DT���nU�9]�*��	�����#��֋�nR�³0�P]sdV!��*�}*$7��:�5��'t*�+8���� ����xV�a�d����RfJ8�=q}�È��\��6n�A�֮���Q\enhT�lclo=9�b%��r�]~O�ڰX%Yɋ�kiS�B����<'>��7��� �ղJ��=CRTSȌX����y��[�dI��� ���hz��Q/�$q���Mo}pb�*�,��ܥ���uDN��TĬ���*4I��OhN�M���c �+�w1X{w��a�o�Y�
󼘸,�������*Y2��xF�*�G��(87C6J���t<��fX��Fj1�����Ӌ�W~� -�s~gEh�o�}�:�q�h77�R^^�a:32p-�r�ϫ�[N�(��O6��Y��f�(,a.�`NeF]2���g�84l`)<Aqb�����$�g���*vV1K��`�t4��L�|�������nqJ�əX��.h+��=���n�7�qt-R���A�8�ew��V�-g#���{7����y��Z�￥a�Ϻe/�����72;�[Y���6G�ɑaq$�f�ݍ�Q��~O�}_��5wy�m��rr�[��B��d�̎2���3e���ƙ��̞�Y���g~����cX��_Wu������R�b"v�b�������$C�s��]P5����'U�3̣��Hp�X�RnU�p�h�/ݾ�+��sJ7��)R~�%6�"ƹmv�
t"qa�o��kE�%G����%y~�
�3�7 � �#�e9�Ӑ��'B�l����iNe�U��Q�jc��c r|�U	W�g��޵0^?&/��C�����(xK%�fO��$���TbC�˄T����iu��,���r�Քȫ�p�7��z	��pu9A^�\ E�,{{�` HN��H�$�YL��|�t����q]Z�?��[z��D���X��TB�f�xB"/���K���*���_[[�"*��;�J#m/��!>���ا/eY��������:C�Pc�*�U��3�f�:F@�W\�ӕ������`ۗ����FͭW�\���l2M���u�����s�������e�cT�? �b��}��kK�����[�G~�`njB9M������+�"D��7�UYE{V��y��F�z^}�5ݲc$�F������y���t�M��ɷ��4�s�f-T�l���p��,��s]�v>�OP�������L��Iy��{?Zu�V��T��.�PSpe͐�Q�� �V��T��Ԅ��������ba���v�ST��Χt�\H�'�Nz]<ᴾ��qf�8�Kq\+^C�4�@vς�7(1*I�I�lJ��_�{�Yl��]8�������yȉH��o�F~�wyde�V��_��_}��$��{�^߸������v�⿭U�&����p�5�0I����n����(�s��!�`���+��}��K����岴�D5_��)��=x��e߷:;h���վ
�a�&��K����v�Y^>��շ��e�2|��i��5�[O��/� �����*x����s$����HVUc��eR�#a�oǻ���4�#͊fBp��{��.�Nn����ɇs<�y-�&(_��،�{��"�
�糪+g�������]2T�'_h��7��;��q������*ps�1H1����"F����S��|$�n�Uc����|��G�=`#D'�� ����Q�������o7 � �0�H[�{�"8k�'.�~��?p�W�9tp�x�BMSx�Bℇg�GUE�C#d���u�6�7�v|��+-1*��5��i4��^X������3��N�8<���� �����^���9dn����7� 烻����'E i�9!c9pM�ʫ���j0���<��D_I�KN���%28�%/:�JW��F����k��m(m�c	�l�͕�JY
d��8Ae��p���j�hK�B��7A����j#������VEeq�S�%7�ʅ���{`��V��?��Z�Vc�Wu�{�E č�W�%��f�ęF�ʇ=,�;��S����[�WMx-ȅia����N`NG�g3۪��u��#�A�Nr�E��kM�0�$5.R������{�N��W,U�e��J''�9�O�P�|��L�t��:��\p�Ч��py.L��L(:	��E�5��D���U�'@c�R����66��;�FZ�� 9sZ��}��YX�R$��з�7��JuJ�������t�Ÿ�^���O�4�TZ��o9h�q���'l���f���~�+*���fy]������e@�0�I-�-�"E$�2�@�����2�;'
�fHO"�z��}d���F���1U�c �I?I�Ϟ3q��s����p����Ms����1&��%&�IeCV<�MCǞ��mN?��ou�����*'�^y�� ���9:uŶ����+EL�N�2�r���0��X�����o�6 J�%ɂ�2�wTHZ�.�P���i�C��̦3J�u�fd������QJNL��1�sgN�B7�5��fYQ��ƑO���]����ۍ���7���F7�M˘�R���Zt3�[m��c�N&r�p�]��z�`��%�@ǹ�z�h�É�h���4'�Φ��M�a�!<5�3�nEܬ��H���M�d����9�g\���ɸ�-X��jI��W.���L��$$'tr����:M�-������:�9�xDr�
�s���g�����+H*u���R����|__C �ee�*t��Wْ��휠�ԗ�	�֐r�i ���v]3�Έ��{+m��kt71r?�H�q�Z11"����C�	��$
�~��#F[?�("��޹?"� ����=P�]FN�w����:�O��&"M:c:�=t�	�{���m�1���{?��*|u��s�0I��S��tΏ5�Ug%��S�܅氠�R��	�J{��d�GP�O�[/HȩB������U�-?�ucO����g���d�;
G̃E��#�����\�\qBtxU���)�(A���M܃�*g���(@O�J��`����ćA��XMT�]8ڤb�˟����Y��
.nw�����8c��<��^��뚾����~b�y�KVv�n�jY��?aVB���m�]���������X{�y�Y\���~���n���~A�:�y%}���EA���@s����|!��I䣂2	h��8�@����:��!2h~��Pӎi�ڭ���]:�[rp��q�KF�.�Y"c�3��&Ԛ��Ȳ�VV%:�P1�����FRm9��_�i<r�+�'@岝M�1_�>�Ixt��R~Ű�s��@�u�z��!��Y�������^��b��+%�+Ă"&�� �����4t��y��Ƌ���rH��t9C�!��6��������+tE����4��.����,�c��d��f���4�^L3�R�"/^���n�%Ә3�d=�nl7�o]UY"���G�]z�S�c���4C��F�����/b��zK^*gX�(w|U�<%�d��D/y?�c��D�������*���%!(2�fu��c����\a�|�f���lU��Ż	���g��#�#���EB���*Z5�*�|9�'�H���Br�+0��5M�%d�m��-�daҭX�����P=�f�d�k,%�9~u��?�I���D�Lo��
����"�b�q���Q���:����|������e��س(�i��Y�k��*�׺���_�9TE�N�d�����)�X�J^��dR<NH\r4�^]�������~���;>����S��:>�m�4��k���?���wLt��ދ�g��h5����*�:�t�n������J�����Q~���o��}&5�b�B��Mc:�y�z����LN	��f�7�2`��+ǈ[�sfS��ӓL�P����UԸI?q
y����@@�.����r������� y��)���2�V���<�%S�esS)��y+�G*���Alay�.>�� O�,�S��:�Ձ��=��7�8|��.Ҳz���8��	����8�>�pnP���.�@�co �d�l@.�~�/����[�v4�՗���t�pn�O�SB���8��+(A�-U*�it�u�!�zl~�z�!�b����/��3F2�3o:L��x���<�����%=�%|������E�����JU
�oS)l7�4�����*�8MQ�l�P�
P��Ts\��
:���
HnA�d��%�=R��l�L~2�&�d�{�P �o&B�*�
�9|G�K��7:s�i2U�(@����7���ܣ���XV�h�][[���(��d��$vďm�1Qg�bqg[�h�\�������H'm7����n��ކ`z����2Cܛ!v��!S$Ϲ@]|�Y<��R�ً0��)^�0�1�se�.�-I�"C�A���ɏ΅n�[z���X�J^��]\W����U����=dvȗX�IV+[Z�־(C�;D�3�_3���#�<Sf��2څ�gDS˝�DgO:���,�F�Z�ݝ�]y5#��7��9e�,�pK-pI,aЇ3n�Á��DaL}��'0��g�u��P���ߑ���b�9�{�s��@������UTL
ӌj[�,ǝݦ�Jnl���`�?f�=���Q����ff�"vw^����.�^���~o��0�����q�#.����_�G/^��r��t��Z�Z��7�N��޶V�;X�m�U���4������J� t;3�n�Z�ΏU����let���RqiY��ԌN�!�rzo� �ftl��L�?�e�(�QP|���Č?Ԍ����[B�����jehf�v���@�`gq[�wۭn�V%d|T�`r'֢Q��^A��CA9w��`�v
񔎨���2���� 
FU�H�v�nv�\�Dw�8�,�N^�M+r}J�(�>7�������j�!��T��B�Q8@\(5��)���������'])\Qr�b��ˋ�LE�ܥ��3A������� ���]�8�q��g^0D�q"�g�#�@5�(�&R��!�gF�s�'_�])!�i�G���p�w by-�qi7�� }�@Ds���{t�������K�:�I�*�W�C`�H���=j��c�>g�nn��"����SS�t'�}ny0�!Lώ�bԧh2qF8���?�xMy'Ky��=?�"��w�G�x��)�t.�H{�7�e4/�4�U�*�]�n�*q����}k�E���r�yy�^�o*�і�V*A�!\��,]'�ET=���F>�ͬ��p���j�Z�6��$��8���z��M쏘xoCUd(a셨�O���xh�[ƌ�e: ��|����{�7;ȓ�{;����k��P�Ï�J�B|6�땦�\C��ɯ���m�� �K@MC\ ?o�j-Q8|��'�Xp��=Wu�L����xy&���ѐ���̈58#Jc6��7;��mC�����fZ��������K�v/<�o�=8{�[�/p���h:IV��&�m�P����5}:�)���`胘�ό�-7�������B���wӷ�"��L�{,�VA��\��Ob��H�Q��A
�;㉀�x��'7aO��`jα�|�ز?�gO� ��$�d��y�����:��Ŷ�Qc�\�b9�;�|��4ft^�~����im�g�m�5E\��b&G$�#ܙ�f+�BR'�q�h+|��_� ,�MRP�+��w����x\"ّ�7����Pi�Q�q�Q}��)�z!��ax>���}I��Pq#��5?�z�<�X�9����t�3��F���a�R����oC���a[��)�]{S6,eg�m
	r������4@Ηҥ^읥k�6�̪�>�����?�߼���`M����,9��p��-���G�&�`'��VAq�	U�"�¡*.�L兹dc�M�
g�.�X+zh�,�-jN�mO��z���fӬ�n־�=�#�5c���`8H�wM$m����;9��5n��֢�g|�>r��˃8O��ydME�<������a�k|�zP�u������o�%O�Q#=�Ua�e�{�?���Xԋf�&zX��SsFK��{;���e��mw0.Z4���ۻ�lL5Jf�XO���4���]��^����Q��.��6���-o8�/p~�Um�J�z��!����0�\f˟�ˆ9��Z��64#C�
�6_#��]T�O:<��^�*Ӏ��j5�������B�Ss���i�6�n#5�R����g��|�g���O� �6�3�7X	��U��K�&���r�e�/8�T�U�����Pd����p���F��@�t��8/�`<�&C��yb�rD�4Ρ,��\s��,;��_�z���ϙeŋ�V�~�-$c�@��l�W�,��v&�j�=�n�_Y�S�͹�
<�IW��5h1'!��*�ƨ�<"�=�ǅE�C��N�5�+Uq�@Ћ(��o��5@z�x*�،���Ÿ������Hx �=3�(=/��*�ȖZ��qP�y��i�`Pb�
���^e%B��!�|Q�?��-Hl���dAϛ.�B�ET�Zv�h�˫�I_ܹ6˃�%����f�!%	fՔ�SS�4�����#Y��uD7_��,��a��1�!E!2��#ƀ���O� 1Yo)��Ý+T:���A�A:f�r^A�ͨ�R�qI1Q:�G��٥ b�9�b'
�O8 �Gd$
�	sDX�:WP�jz��Ӳ���7Nj�a��R�J�N5[�)"��,�Nq���{4��D�#/�5�#����1�ca$Xg�O�	����@{�64�ߑO���zo����<K��`nV�植ᜰ�P�Y[62m�ac6��TծU?�<��i���VĶ���\U�[j�f�埊N� �;�_9��y���Q�O.D���$2��Y�;?�5�3W�+��iMeM����oM��U	fҞNG?Jbw��5�Q^)]>���$-M�$��U��^"{M-�|�x�U	����6��������Ix<�/"� �qw�s��j
\��Xt�!\Z�g3r�x(�"'}l#i��[2}@q��~c�KK+6Bi%MH��=���|�/�G��/�	"�a��O6V���`�)�v������K��Yf����sbw�]�Xr���U�P����@�M7�����ج�Y�wi�.
�tKI��,�bM����(����ԼLՒ,G�L�jwp�����>P�@���PE�$N��~N/�����+�����_>v(,00�n�I����0��B����%4+�\v]0>� �ڲxS%\����n���:����2�ww^��Z�������v��%�h/fp<�˵8Rsp���n#�zŮa)i�7�R;�ƵYC�J�;1�
���!�ʐ8L�j�Xʃ��)�}�����6�A�ކ�4$}�C������=s'Wȣ�\�Dj#����R���ccJ��M��J0DP�*ʓ;T�G~��N�#˲gU�����w���`;�9B���BT:� �cN��e= s��,ռt��q�JxS̝"�3���_��W%�,L������Ǐ����F����ӧ����7��+��Է��qrO��8NSh֪�٦������^�^�� {�4��RV�ۧ
��BH���p\����5ʋ�* G��o�i{VV�����V�_2�w�C�`��>��+9m�H��a`��Ag�������t����)*�E`?W`|&�)2U�v�:��o��&�
���4�i�S�.)#�)ң'0�����Y��*�{M�W���18���_��ep�TDvM����1p>��fEC����sTn��Z�y-<��g��O\��&���6�O7���_7������w��zt�Sޔ�Ā��$Ɖq��`s�/��/���q��&��+��K�M�絇��������}agA'��&ԗ`s�?8�y�P����Y���a�]W�Qr�&��V�^-%I ���y����T�:��!����	��*uZ;c����r�������0�����/̺1'��N3+�������:j�G���o��1�~��:V	�KK$����
��'�4s���Mʶ�fL�(�'�Ir^��	o{����!�� ��2�'�R:�o�u��䡀����a�1!q������=��"�e#����;DZC�th�r��s D���t�ǈ�+�>�h(�jD�P�ꩅZ0Śkz�ݝ�Wj����C(�33<��|6�/�)lȋ�
8����X䁡����}G$9��º�88G�,� �^%_��GZ�|����~R�O���l� �&Րg��g��F/n�@!qr�9j�5�.���<�p]In�S�X__��n�#Eg��������Y[3�?;�sݬ-RA~L�FZ��E�>>{�{��k�6�2.�U0�V��'�z��:{��c�����U���
h�d"��XHu7A�Ԯ��\n<�d˼'s0uV�B�#�huVY�*eݭY�̱(��z�[�,07τ�RA�ɕe�[���"����lP?g�v��\e^��t*V��H�#�O��ّY��Y��G3�R�gH��� �������h�^����$��-����g��:|�U�i�Z��z;�m�j�K 4[��^��!�C%2m@/��,<n�p>%j���/�O;���~��7%U,��(Y�'^��� ���o4Z���^{���s��3�����7�G?�򈵢���~HBؿ�Ԫ-l�Z������e��hV��ȟ�sl�����a�����=5UM<n���S�n���=c#�k�]Wo�p�����E�TP#=[��
��½���'�����i��@�+A�0rLvB���t�N��K���_����P&L�Ӂ�{�(K�T�N9Q̙1�)�tS~�C͉��V��@/JO8Ϟd���t+�jf�Z�Z�}f%��!���$D�^��ezQ�=b�)�<�ߧ�Ėc��%���G��&u� Kڨ^��g��O<�3�A���hj-���Z��0�Y/�)���?;7��$ϸ��a�W��b�wr�B[�h���3L�j)I�$���I%�*�^}V��K�c*� 'L��t��VgO]t�c��jq�t�h�/R���:<����(nJZe�_�U����k�u�_����ht��s��=vگw~h�}vy�)iM����-�6�b�P�
��Ώ�kV��Ω&��	�$9��i�a�L�&"������p�P(��+����шm�7
���%�ik�]5Y�LS�[5��l/:�������C��?T$�}���`�X�ߴ`߷:;�{t�m�g�.��0*r��n�iO����_}��;�=�.-���z�2�/��;=O>�f�~��c|<��i�}/��k�<����8�߽�s~ѯȚ��8N�����N��tG�x�0y,��^r2y|Ƨ8j����[p���8�"&��s�����cR��;;YulNh)1����1���ʄ��Dׯ��9�d�r9&I4�l�+�_WVA�;*6�w��;N�2�]eH�_l�u2�v� �����;6��"?k�� N;��<o>h�@d*޿@�>�#!���{�Ae��um�H"�
!�� O\ fR�{|�d��mC3;�;���o�E~V�ݜ�E�k�sf/�C[rgȒ���ͲuhT�uCSjN���R]Vv.ۊ�科7��
���G��ב��f��91�����X�j�i�,&��"_ �74�|۳�b��-g�va�׍݃�B��!w�ݨn��p��n������dӡ��%4?�TSD�xg05~u�'@�\����_�nj�����F�'�vu-���DfTx@��/�F�ޣ����/i*���4��,��^�W|�C!u��L(�r��y>c��8�>n�'S��$	�_6,}�z��c�>�)������w�$�+H3��n�)���f�i3?�==��}�@j�~��?e-�>�f�*3�5���L�
��Z�s�/�_��~ST�Q�~�Ɖґ�jϤj+[!�5|OG�H'�,����N��1�[��R�=��~�`��5j���QQ-�Rґ.b8
��*$�L���Y݀N�t|<7W���2�2L��"���" mmv���ff�d��r+O[xv�-��=�i��R���?�{��dk�n,�\K���b�ZR����Qtl|2N��&X���w�����
��[��������Oc�"�(!�X �J��)�M8 J��(��h�@��/g;g�
�yC�f�ֳ�"D��T_�%/{��\�_�p������?��������_��_s��n� ����t���D,���οIŘ�����/�/�p�>ޥ�h��͊�T������p�U��۲���"�>Wbԡ�Y$���}�V�?6T��+� u�KX.�:��q�?�����`��.��S0i��*!'�(gC$l/r��"�*DE���֘
%���R�N!�7'H���9�6c�u
5Zi7������	�~�~+�}J�b�Iq�w䳸R�b�:\�zu��u���]��-�Y-�)ȢZ�23���f��Ҍ�@ZI#��1����u��C�&s� :��+etih�bD
�d��6��rD;Ï���,��3l�k1��}���tv��|:ܖ��;*��;1�fJ��Y �(��ŭs��t`% �����|�ˋS6�
�,K�
��d`�6u�Y���d���D�ј�K����R�j��&��)�7,]�cV���f��3�,��H�B*Il�.��L��YZ�џ0 ����0l�a/�f�v�tv�t�ˑ�����~��\��[ 
q{s����q�f�W|eJťm������^h�u�~M-O����X�x?��Lҙ\�`&~������Ga��l�k �
�	��!r��G�t��V���-����j�����M���%�JYW�z�4�A9��E�vO�Wm�03�$T��b'�z�/�E>�?�����~�?�28�#����9�ՙ���9�L�Kt�m�Ɂ �η�}�UCA%aQx{L�b�N/��V���Z��e,���1:��B�YU��3�����|�`�h	&B��9(��=�m. u�cR��ȼ�K��}d���Z�{�}`�1c��g�r�	������� %6��G�x�#@�*�v(e=��3�R�l����hÒH���h�P��֝d�-a3r  [���Diz�nqdN�D�2�s�4?|"��.-qýb^���-�K���f��ج,�r�j�E;����t�.���a���.�;׊x1��\/���}��ԛ���V�I��'p>�����4m�`\O�l+�Nw]$�=��)����8�἗�����O�>�xw����H(�nߛ�q7�P瘝�E$<�I0�M8���{A�Bt���#�׹�sWL�c[��T*n� 0P~i�ڈ[[�,�J�L5)�b��KL��_$0��lk>���b�e�;j�47��I��u��I�i�l=U,���Y����h�4ٽԺ����T���-&��Hn��,hXt��T�`3�$L�g���9�Ad/l�*�r��C��+ �w��a���ݘ�2�g y��̾ș.q���	`�KKt���\~Q�e���6k�D~�&�D��� ��)���s�b��Q¦)�ڽ|���2�CI�[�Jm��3� �J�b�*���M�$d��܈��3�FÎ"�"h�b�,�nK�(׏�����������1�?���z��ƿ����?_j��8�����i������ןӿ�����׳��k��_f�O\|䜠;^V���ѷ&$�3��*kM�Y���U nl.q�2Ոn���T�߲��^�1U5NT�$�(Q�����aw�똭9���;9{�%E'g���]���ߘ�9�["k^.��dA܀�7��eUw+ժ��	g�!�54�����]G�p���m���:;�X�@r@�&|����G����Z�G�p.�j���v�#��ͅhX���´����(	��J�#k����Ɔ��u2��?τ"�%��d���%�Z�����XǙA��:]z^1���"e*��c��̘2L[������y"'r�%�U��o��ꆁ�TG���r�L
#���߉�lR�W����Ȯ���Ζǻ
�
U-�Pв-V��Ve-A�|ɱ�S4B�a�<m�(x�kFv�BޛY�+M^:�S�"8�`�Wy���`Ӻ�%���kJ��"u��W=�|��)j�Gi3Q�Q�0)�vڲ<b1��]3(��Z�bt�/Zm�G�t�,4�ʀza���0���M�W���?�=�?���NU����:|A���������z���"�&�Y��C��!�7b�Y0Fx���ӄ��+v�{	���)|
�!ًT�������ԏ1��C+�����8��������������!���|����>������2�lA�MG5�#�r��GH�����|�L�(I��gJόm���腁�{�tR�/�� �h����\5���St�>���s��=�����ڱA����HJPqU�*���k����=�� ���y�����?���w�����y�FX�����@Hq�g,��ͳI���pa�����GC�0Mn1홨�|��G�D�W�f/9�k@<��@]�:���'	�{VDe�z���qgW�\up�AF���-���@)յ"��0��P%:k<�%��Y���8ԑ��d�-H��8�p�ȟ���<]b(4��R#��5BGuL���6h�IAQt���e0hW���Ցw.NF��E>�TV ������h]��[O(�B�X���g�2��()���|pfd t������]>����Y>�͒O'���/U�vw�:#:������n�n��d@���,���r��9I�h�8�m�gJ���ԌM�+=/����灍�`���k�N5JX����"�1dhq�&�l0��uLÚW��\��!5��c���b�`�=�SL��?2v�q�9�t"��hd�B�s�'���a��5׿8����i��o4�������ïƧ�dK�_gAW�<�i�_�ϓ�߸WH��"Y�����C#�7܊����I��c�gf��e5*�� J����2h�E�$o��4���}�}#�pi���n���9��Uk�-v=2'�|ot��4I����滕�.M�mΘ�ܥ�;# '�淈�e�0v>��c���mf��,^Cv��4���e(e�����:����,�)�$�E%�h���!�g�:�HF��e�l�����Mw+fл&E�ZǴ!$a}%��(H�Q�)�����6�[? 0sY��H~���G�E�1�;~��\��Q���B�ɢ�'�s�_�hة�8� ���C�t���yo�F�V�*-�bҳ�����CHDt���+(��������4��������2����VM=���>�#rT���|�F/�$�M�J-��w#����,�+)DPZ J�m����!K�'~��q��� �/HP�]�B���LX�D1J�aox�?�c��.�:-�Z��T�4�v:O��eF�N�����w_�m��]�y�{A����Y����T��ʿ�˻i��:��2���hd�H���jL��_z1��o��Z1�>�\����t���j�+	Ps8�P���*�*�2�0�D��!-v�`sѲ��,��_�n{L�'�^d�#Yt�G�{<A"�5A"#�8N�ktl���tHи��Q-A���w���8��p�f-��DL\z�	hł�:�\����D㛵����P�^I�'�t���߀0�J��h��V�&�U�����Z0"E�	zZ��U�R�������?�������s�����?�������h�[ h 