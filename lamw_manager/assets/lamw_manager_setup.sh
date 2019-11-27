#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2057373809"
MD5="55558d73a6caf93468e60395a883f8b2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21242"
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
	echo Date of packaging: Tue Nov 26 23:02:35 -03 2019
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
� ;��]�<�v�6��+>J�'qZ���8�]v�"ˎ�ҕ�$�$G�!�1Er	R����˞�c`!/vg ~�e;i�ݻ7�a��`0�7@����Ӏ��'O���IC�N>�[Ov�n=��~����lln7�'��'b���2]�������~�c..��5�4����������o�l�< �����?�o�����)U�s�J�Ե�4`�eZ�̨E�!���=rx�y�Q�Y��B�������]2��ԝR��~]J�%"��]Ҩoշ��>��%͆�|�o6�?Be���C��Q��Ү��B��H�S/����u�
��@u2:0���"0}�d�D�1\�4�Qr��L�"�T�����g��F#yl��Z{�&�����`�=�ZGG�
ɂ�"x�7�j�~:��/:�;�l��ɨ3�z����(kn�,�g��sCE�JQ �h�X�R���4�"�a���3�h�o���}�V\�J���ιJ��|�;����5�u\瞿����7D���z�r�KWH5s�o��[,<Wcg�o��b��a�N`[�)�4���v({�qM�J�+=\�z�>���
YE��z�=X�L�>��sk��!�,�<���	l��N�l�@�R��!�i8����dP_�l?ݢKݍ'���'�A�n�b*�b�T*�:>��c��֥�0 ��g��o� 
?l�2j����3duCMhQk	�ZNQ9A�4ͬ��\��t=E�ߐ*�/��$�,xȈ;���7X=����2������4E����S�x�/[�)���4������7�.�t�A��u����Ȣ33r�@Z��N�&>�D)k�S��u������=�mxa�bFx>�C>�N/�PwI����Q�W�� �[���Awm�o���	��Zβ�˅�(c@8"�]B/���uu/���r�U�*"w�NA�����R�:�Er��*�L1�Ԥ@��M�ln
+��Ƙ؅i�)�
>q���|�ya�}*�Lc�Uc���Iԩ�2�!��V�c��)'\���la�|Xߊ����������ph�s2�88�V=�?C�����6���|Z����>�����s�mR�h�&�*�&����x�6�����Ry$����a���t-_ɧ�b@�[�������b~1��������;�����vA���ͯ�����W�d��;$ݣ�o��zǭQ#�_I�wr�=<t���*%�H/"�������<
��'x6]�$!�	�³�9	3���P�x,������oLDu�R�!��z�JUG�D��h�:��ư�Q�dr�0�)�Ό��<B���( ��#c��.9C���z2�n{��)*(Y�@�j�jo5�g�X9���7]�#�33a�U��0؜�4����[��0�ޛ>��hJ��ǁ�W��%�?/9�����ͧ_��_r��Xx�&��X4���/��fo�����W��������������_�{�䂄��&�>�#�hķȿ2�.x�AQl�"��˧D'�֠�|g[#-�
<��B�]�Z4��Єw���x���̟�i�i���H�M��hbYn���m.mʋ��bbc�K��A��u�Rq�)����8`���`����]n`y�a!?�����c�t�aD�?��� �V0��9v��8� c'd�캷Ǉ�ntI�!�"��?�2s���432��z#��tp4��j���[�";�b��̱I.�9gz@
��[�Ƹ�J� ����l�o����@w�	�PU	�}p��!D�է�y�s�i;�z��/;�a�wb�K�YzM�f\G� ��ﵤ�[��؝��$˸�ag�栠hs7ZYWZ�rq �!(�\yQ3��x
������a��\t)y��x������FaP�a�%O-|N���|��cO=>w��ɍ��Ϳ���ݾ���/I�����+�	S�k�%ݕ0�@u��ٹ8��g���9��&cۈ+�j-7H%Q�ճ�r�E�j릺�\�[����"�R�oz��=U�wi�����+�px��G(�dq�����I�Ga�?�Z$+�f��M�5�)�x�v����[��Mu|���ۏ�L���'����{�.�̄����	���ɨuxÍcɌ7uy�ꠏ��oj��RA,�>���Յޔ`ã�X�K�A�DT�AO	�V��$g����$4��>���� ��ȋ ���pEy�Mm�sZ�B���f��+�EJ %�T��A�`��������GR[&���x�vF�	���f!. �s���0�izá l� ��i�h��˃��-�$��t��ܙ��B�/7f W
e��*R��$H��;�;����9�f�^+
6?�Aȇ�l?a���YI�����;�G���s[#�A��i�{7&�"� ��]r h�����>����ut�a�l�b�T���W�c�Z���Z���~�\��BU��e�_���+ /��rf�z �
6�p$*	�e]hӳ��R}��!+�ni��&��D�����`E�˨�M���ϸ�<MJ���1G3�R2��M����&|,���}H�[��ȑ�칠y�}/����&rǐl"*��-l��a[<�p�ϕ-�@��B�=��T����&]u98j�zh4['��^w�Q�΃�S�$d�͖��Djx��j���?�����3BR�rޖ�V��#	���Y6�T�ŤoN��9w�s�:=�7Jm�E��ۮE/���$$�k���w7��\@�p�k��߾�˯1q�iԲ���ae����;���';������X��Lga���_�^ ������g=x@��̞8��v9B<��]l��c�u�^W�׿�K���x��4�j\�2�]K������o2��Fc�Ϝ�7���0�!�s�L4?�}���3�ң�Z�I<�y�i-`���uPz@}��.�x�r6�(AB8%�Ϗ+�CT�3�=AwH]Ħ��,�N-���$�l7�����g�_��αa���ߓ�h4����Ե���z�9��~����~�P;;;�p8���w�9�Uߺ	�+�l��b|�w����ҟ4���:oB�xI�˘!P<-�cU�!K�f��^z������\��gL����Te�+#rƛ���"`�o�g�������*����%�H"�����-���j�a[?M3!Mj�{ k'�F�r$R��4EI�<E<����-�zd��Ԝ�Z�}��R��]�\�3s�`z��@'���M`Lؓ�9�ߖSgo���C�s �|G/'j�����P��nQe��b��C� �o�Y
#�G`�o�����G�� t�]����������Hb[H��YxC�Hr�#,B�¸n�.�]��\��ə$Do�x����r�ݨ3�HM�����Q��	.Vh.(.l���Ƃ���f�ǖ8xhA��ZH���Ք�>��u*!i�>�V�,�:�B�x���	�EK|lX���SE^l2 ���"�*�g<Lj����wk����QG �{��`�B�I��g���N$�H����!���(����Vk2T�9]J�.Ka�|������WWH1�O�V��1�i��'�b?�v�h$n2k9�;p��L-5(?cq�oEÍ|	����h*�-Lȫ�<3A�[M|�c=���x�=)#�F1�_�3w�p��a�cF���ڋ�Ҽ7���Ef`{D\�қz�_j$�&��aefC��ޅK��㤑�8�\�*���!�D���
@���ac.�����X���]hD�5�x옿�.c�Y�\ؿ�A���j��1���ϭ��_�xv��8)���"�*ƙ�f�4��_֛�yYg��5��HQV��Qa0�����-��M�K0�D$������P��<zd�=���uUbΛ��n���� r��84�d0�ݍ`�FIw��D���+� ��Z���9���]��#�#o����@;kC��>�T��(w��AL�U(M9�P\�z��.�ye���D�3o�T�Z��v��۴�\x�9��)����7x1�p�����X�V6W�:3&�'�~0go�C���Y.��w�?��6�Vh���K�3Ƙ��9���^�h�A�4q��}�Tz���e����1���6F69D������~o02n%U�$�MM�n�~m@F��P��4d*�s�^�X��u����]��ި{��xᦸA�M�
A��G��[����p�]R&^o������S�`����ݼHmx�����쥸j��+���/߂��D�$[f��F�fl=�N�1�K.����}'}�!��S~ �/(��a�`#Q�����]�2 ca!˗r�;�pJ��xa/��� +���{��7g�-��C��vf���f���Gމ�E=1�ȶDMM�=-v>�ڹ����h���4$xaW�Ȩ4����x>y�*�rx���u���p0�^����(*���0��C#7���vMǘ��a��ʧF+۷�m��9�����BH�9�<�p�b�������=a�qM���혌�}���
�e�_j�����ރk�(���.V:Y9 lη����F,o��{��EaRǼ�|A���X��彾Xr� �4~��'���g�Ȗ}�4�vw_k/�;�	,eI;�!��ݼ��ￇ!�|���DԨ���kMܭ��-_�V���5i#щs|[i�ֻ��q��t�u����T�0�=���|wI��A�_�Ӡ��B<��_�z}~�R@@:��m��}@g�{Qg���s�[P~�Դ@�uv�B����6�l���La!�X�A���"H��g�©��Ii��I��tsC�r�|�%��%>;�2��H�=P�Cc6g�?��&���`����%���, uݓ.O���x���J0�²&�g�@t�Dɔ��P��KQ��X㼻5Ի]���1��2�g�S�"�\�GT���^fY
P�{�<�*��+A�0콹4�ȕ��k��;��u��9��߸x~���p�[皹� &%7���aG������&m��0 Q̑�� �B��N(��t�x�I�ґd��%OҪH%k�N~~�ïǀ9IS��E�=��	' �B~J66H����H��T�͝K`k�y�l��@�����ɉ+��o�����C�I/���)���Ћ�pVc�t�J5fm�' ���_8��̸�������#��$�b�å�����RI�ql|����xf��a����Z"R������/����ס!�!��\[����0,�a�81�y��n���C�q"ƇT<K�PN�����HF�+;�����N�y��O���Չ{��;�]u�`�%��?���UWʘ���3��TxJ��xD]s�Vh�L�œ���:�����ڬ� �cc��eN%���gmN�֨��!�#�]�N�F$V�;5�N�J�d��!w/e-�쎬RYMJ1���FA�.���Z�g+�T�YÄ[����޷u�mdk�W�W�Av$yLR��K$�ݲE;��H)I�������$x P��x��<�5�ҽ���c��f�]T�Rdw���-��ۮ}�v<=�J8�C�W�$�	۪�&^0dՆ=�㟲L5
Q�<�o�g��|B��w���V3��J��4wp�@Ʉ#�:�lI��Ov��x�'CN	��V*��JA��� ���MU!^��Hk�R�IO.)� ��u��c@e75�F��Jo��ǰ�:G?�L��!I��7�Z �b(�s�P�� �Lc�z9�a�@������9��2U�{団����ܶb0���*.<����p�9�`���-�-gJ��YYmݨV�ct�1�2'��us��S�&�Xet���9%Ս���[�����`%�h^Nl�5������#a����A���e3��P!�(]c�	匪ɂ:�Qh�F��F���Ed���̸Qۨ5�9���Z��A�Y�Fr>RO�q��ˠ]�|cZ��<�t�b$�?��{�h"��B�fx���pZ�G�e��� �%��� ����*dp�������t"�������vn���\�B~���c�������7Jq�pM2?kQ�������i_�4�8XZq�}UI!�z��E�x����em��h�!~D�y�{�ݗ�~�}�'X]��	��Oq8)��?Ծ�JG�'�Q��|����`@_�A�O��&�Y��'bB�|9M�Q�d��=���z���&B���H|�Y¿"~B�e�w���G{����ш&Δ(��}�~I��F1 )�4���8���"KJ�k�<����h,<c��^���̂�&1i�@ŨK���W�4K������ؗ������ۿ�Z�!���6ټ��e��s�>�0�L��Lsܢ�Jg�:��J؝��껤+Yu��8�Q��pw�"���^�_�M���BuˑY�|ʚ�
��p8��*u�kKO�TFWp.� ?�����b�'���̔p�{���?#����
����v�l�Z��wq�U�H�Rec���T��D2�-v�=���U�����6�&�Z����s�s{~��h�d>�{-����3$E3���_~�������x� O>`��.��I�\����'֬�*"��]����XG�je���"f�_���L$	��&Н 10�1b���]�|kzx?��m�5�Z!`�������3>�Z%%C��g�B�}t/��Kq�1d�t��O�nm����adS�x�ֳpz�!���/"�B6��V�6����X;���͍���Y��|�?�H9���Ղ�pL�'���,�v#�e�0�e0�2c.�[��3C�`)<Aqb����$����*vV1%~H04:��u&w�n��d��M�8���\�����OƟx�K�e7�;�8�)A����ز;�|�U:g+���ܽ���<TL�~����0�gݶ�H�����[�ٽ�,NGy�#����8�G������(�m��⾯Q�S�]��t���G�y��������Qf 5�T}�lW��9RЖ�c5��������	�b��5�$�֮bw����ݻ���b�6403���ܼд�Y�y{y�I��h�Y$�],r)w�c8X���ޏق��ۃ9��m��?)?�f��5;f�y"qa�o�W����;h�o#���+��р�0����H�CR[O�9V�/'`CӜʋ��B����X+� ��fk�����ka�~L^v��h���Z3P�Je�gO��"��nTbC�˄T��������[Z�<��*�[��LQ����\��%���õ���b�
 (*f���0��t���=��x�ϗ�o�"@��
�a��d��[%�<GI��~T	��6�	����&�l��*���_�۲"*��;�J���F�Ttd�ӗ�,�i}�ˏ�V�6C�Pc�*�M��3�f�6F0	��<.g++�������<�3ZK5�Q[w���ɴ�ӓ��g�_P/�������WA�����Obz���}^[�W�-�����p��	�.�Ӥ�W�
	_��,!B$򍽑��*ڳ����6ҫ�u���-K#�5ZM������E�/f[lN|[��R>7�n�C�M<Bq�ZY���]T��pNh�3n���F������d��UVa\��5��ƨ�R�1� �L��5C�fa��KZ.SlPphP�6o�~����s�adN� �:�2l�J�?�v�v����3��)5�q�x}�&��xL�I��H�>5� Q������bT����oG��$�I��(��P~�PYٚ5�엌���hn6r���K��y�oW)��z�a�Y�ߌ0_c��d���=l��"8\"V���;���!�Tx�|P.K+HT�e0ޜ����;�컝�:�wy���a�˧�R�]���nUV������hE�?������ux���랾�����]|����t�ND�F�\ɪj,�zF��l�H����}U�f��#͊f�����ѫo��:��+�[n&�/�H@�Z�ԛ�|1Nb�U����%^A`j������E��?��9�;�.�S,�A�pg���xT������cU�9���w�3����H�&�>�����
��G�v�cz�x��� O�>���4e7lୁ�1`<f�����p�4�\6�X�ಯ�7s@��嗦�r�$/&�Z����;�`]W�me��<hr:pwVZMT�=%�h�pT���#�`��~:�v y(r7�F������a{�B3�dn��C�� ǃG���E�f�9!c%p�H*����j�.�=�<�K��$��x���
�}$xً.c�I	t��������ߣC��IK��`7m�VV��= �\���8�k0��+n!�nC0[�P�O��h���&�W_e��SQY|��R�v-H>�az`]rB�J+�k�~V��Ok:ԽH��}b�(�M�G�)�9(z�c�m���?�T��^�z��5I��0-�å��y�	�����hf[�v@���}�4(�I�N��1wáaޙd�EV6�������no�����*F���@����tm7�,�b:S%ݓ��V%��q�Sas�9<���M&l��+���"�'����8�(t �B�䝟�)�6��;�FZ�� 9rZ�T�Q�,,j)N��0��7��Juʘ���p��t�Ÿ�ߠ��O�3�TZ�m9�ڔbnm��'ܞ��V���~�+*}�&\��ʆz*z4ˀ���%�Z.VL�5��X_�Fʐ�<|R�l0Bz�׫�p�0^͏L����dw��
�M�`1�'Y��s!nrt�@��7��t��il �q8	�_�AuR1��c��a�D5r����Δ��7�u������e0�S��?��b[�H^�E��f�Y�r�L�y �.��t�l|��۲�'@�+=qZ�ƅ��
�V���1T�}�a��!�Hf�%̺v�i��c��({&�ha�~��I^�vsMn�YVT&�q��VYWG��6ލ��o��V��[�t6-�}K��P޶Ԣ�9�j��O�X�0L$�p�]�z�`��%46Ǳ�&�h�É����*�&�Φ��M�a��:5,3YEܬ����(�J4��/F6�@�QpC~��g�6\�`}�j5�B/�j���3�.4򎐂���'�4���~�'��h��є�Tp����X�<ꅫ2�!�4g�j���}c��-��4P�S�ʖ�0��h�#�i��O�����`�n���!JF����[i;�N�w��H��'h #;��=Dl� �'Q���8�1��a�"�[�]�#�0�~��F�������a������i|�٧�s�&�1ۆ�9�Iu픸[1>x���|?��*|���""cNi`�9?�|�U����OQH�dAqb����J{�,b�GP���^�P��J�{(�Jتƶ	�(��'����3��p2��#��"��?�AC1&br�Vo`r���:{SlQ���`-��K2T/��Q���.�W�8��ÉD��XT�]8ڠb�+�D��)��*.�b���N��8b��<��^��7�u}E�ͭ�Ğ�KVv�~�j9��?aTB���2x���#����~_ ����l�������g����������,_0��+���.
RZ����Ev/O"��@7g������ȭ��1n�A�~̈́ZvL��o5�Gz�o���R\�1n��L]E��G�L�51�F�g���jt!�b2�7	�>��"��	�5�D�\�*-�	P�lg�rL5��=	�.�(�I(��Ρݑ����
�!��Y��[ZU��V���o��͕�	�bAAy�5�i�7�ʃ_�:��<@fC�%l��(�*]IeSyI�-&��R/�k�BW�W�PCJs��"��hɲ86)�M&�9��U��̭�̮T���܀ְ�x�4�6y��m�[7U�H����i�4sJ�LB�f�B�7�W�G�7�{|ŋ7R|�-o�F0,�
���B�2G��ˣ����1^}H������a���y���#S�:~�IxRE�j���*j�Y��5����B��cn�E�p�#��#�P�V��hU��Q�>}9�'�H��ڂ���P`$6k��*�L0)������RW2���dX�q-�/@��� �H-%�1~���o�Xꃣ�ƙ�M�^��3n�������}�Vq��n�'��$�
���Y��4#�l��Va���׺��h_�14C�N�d�����)�X�J^��b��^��w�5M,I��m��k�&1�j�ۻ��c���x2�i�������^?����~�Dg�x�L'��V3	���
���I��V�v�>�Yq��#~�Ep�_ni��es�I릘��<bӘ{���x��6S@���P���|�ҕ4����є� ��$w54��X�q�mRm�G>C^���^�@0�.������������ ���9����e��6�����Z�}�n���gӤ�^�D\����;T�B�Ҳze���8��/���c��w��{:VϹ�6�ub8/_��{���؀"V��^(�&35pek�C��b�����!�w�F�&q�V�"ΨZ�L�K_-����Pa�6��:���v����/��0q�����'_�"P�����(�ڛo����kJ
IfL)&7�����pV���[Bd �� �4E�sU¬�:@{2�q�RW�(n�: � �'�M-��Z�Q�`�q7	'�f���S{��+�VX��M�;��p�.��&S���P�s1�=
���U�fS��q͚I��)K�e�ObG���Qw�b�8s�ǲJF��J��e��2:̺)�2ݫ�w�?�<e�R��f�X3��|�Ԕ�L�.2ͬ	�@�щ�=�p#E
G$|a��<��ahK��' ���ѣFg򶅒��M��HS�����f��U�%#87��$�j��%�/���b�IV��Z��+o�{!5���FK�Y�%��fOg���B!�r�r���PlY6~ǱM`�����ˮ�j���rB�����K5��I8��'Q�W�1�	�`F��a����*�������i��#�an�)�-5Hen�ޤX�hP��r��o)���V���h�س�Y�@��DvP�03��ذ���}�mw�z���60�x�V�A�Ǵk���Q!�u�B��<��z�Æ���z�s����:��*~+��M�Ll��qw�E}���-0��̢�bN��Ī�+ܦ�:��H`�����n%�e�����JQ��ױ�=g-���. D�rC�.�'f��f���%�E�"�|�4��@3{�[�ʄ���J������5��Gc&wb�5ښ�+(6?((��j�8K)E�����3��&�	P@U%��:S�Y��f��,:�,�^t�&��%T	�_���!��3�����́��G� �]�� �C�Y�0�;����te
m��K/��2��.Um��	A���0��pd���%�|�C�"'ү�=b	T#&͉teꐓgF�sgO���2z�>ᚾ��p`�"1<y-cbi��� ���֪���� �/��0��,w8+OU�z=����u8,G�,�&�����xV7G㋈-�y���>=Έl_AlLoH��t\���M��!�籰��G�^3��μŧ=?����e9���SV�\�HW�ͣ�u��$=���*^�wk�mZ%n��q\���''Qpi��3�����B"m9j�nb�%���UqBۋ���9a�&kf���k�VkԪ�ь�-�	�@�4���1��B#a(a�hxO���d�Ra��2�U��t���Λ=�Iv�{{���Z�����J�B����J32�c���FA�V��d�l&��!8L?o��%Q8|��'��p��,z��9;����B4S�����?���d��W��î�ym�)�Gh�E�&+w����/DB�KH:��<��=�{�&[�/p���h:I�E���w,��\c�>�L�Ċ:3�3t���<��v���[f�w�0����I��Em��Z�uS7U(�����8��3�&P�^����u�4�sl-���-��t�1�-��)(��݃%x)��u��r���ʗ���ʺ{o�O`��BZ�7<��5E\���$�A�6'���S�W�g|���D[�3V�"�Y�n+��j^mV7y�1�p���?( zN�>�^w���Z��ص%Rb1�;�.��r�׀���u��a�@z7�T��8:a��Z2���g���#�F}vR1��x�΍ߦ��F�mI�s���_��R�D�j ����;>�ȽR�4�S����/�� �#n7���X����%�3�f ��޼�㡏���$��mU]g��VAq���"�BR�I����1�����3F�Xӭ�r��]jN������Xi����1���v���?b_3�.�����t{��
���h|�S�nW@_�0g�5�}o�'na6���S�]���^�<�����`��|�zP�M�����o�%O�Q3=�Ua�e�{�{?�q	,�E3x��=B~AK�9�l��ޡN�,$���Ń'7w{W��i�Ȭ���8)�E��Ҭ��8�+�[l������{��Y%ж�l�Ke����J�8s!�|�.� ��j��͌)+��|��	vQI��<�ό4n�i�Џ�����N�5IR�=k���4qV﶑[��L�ߋ�$���v��D��fx��Kb=������iۤ��]�[���/����N/5�6xlg�)��V��h�#t��[� ;��:o�cE�4a��g��/�\(K� #���#B�N#�Wӿ=�Vէ̲�E��%j?��1맻b6��*{�q�s=�T�[�WV�vsn��Pi2�,������ɘ�xcT���Y��qa�q��uQ��!+}��t�)n��z�"�Yp�N��ql��ʖ�b�o^VY��?��=��[��C�gg�,�fmrP�Y�iV_Pbq ��;����:@!/`���+(ET��(#�ɂ806]��e���e9��,�h���ɠ<J6˃�%����f��̚�35�4���z� Y��u�	_��,Maƿ!�#IQ�{��1`�a�'���������	�b�8�� ��ٽ\x�b$n�`\RL� �G�}	sAE%$����$Ɖ9"�4+�V��4��SYVF��ZDz��+e�T �Ԇ�>"2��e����g���G�lH�}�%���z�T������~�M ��d�@�kr�ǖ�Ў|��6z���W��s�24'm�%B��ڲ�i�-�)離v���x�fN�vV�"����p�2�;'03\���k1�#���3��٩m7����C*N"C�O��������	�X�ĄH�$kz��4|{kB�6J0��t:�P��L��Ju9�PCZ��I���C��J/���;Ҡ��[U	����.�}��6�;�/��t�_94���Q�/�!kj�{t=�#`ѥ�oy��0���PntE���<FҌeW2�)q��qk�KK+6B�nL8��=�Љ{�D_����D����l����`�)�v������K��Yf����sb��]�Tr��V��~(�{Vp q�����G�}l�����<w�R:xKI��,�_a]���t�/������LM�,G���d�p�|��Ì�'z�]�oi�Z�|M������Ǻ�*����q5{�,0���ܿ����N������M4O�\v]0>6 �xS%�	\�n���t��M�e���;��:�2zG�m���=أ�����/��H́U�nV��������]ޤ�vN��H���;1G����!���8L�jAf(�QrĐ��ܽ��J�ry�ؘ�݆�4$��c������=s'7���܈D<2�F��!���~�Y(g$�6�"+��/
<4v�`h��/B?��G�e#Κ]CQE;yg����qQ錃,s�9���������Er��+�0w��ΐOw��L�ӆ�g�������7�������X�-��n��V�oEq��=Q(n�H�:k06[�L����v\y!�'���>��D��a���*�W���q�VU� /�B�p�L������1%"�O�ֿb��	{���q�}��7��/QD�{�uv�o��+�N�2�,LQ���
����fS�K)����Uϛ�*L��Мu��?���t�ʈ���|��~b��>d?jv�Z�0N��x�����Ŗ�u�Z�94���q�|V}͊H�����*G�~�ZxYό��
x�Ú��/���l<�|���|���������?7l��'�|ʚ��1@�'�qb\!��Y�eB��� �"�5.���5���T�4�Y�����T@���{b�����8y�L�(au������k�R?�� �J�9��⦊H�k�?�x����j)���+�'�]�bw�Q��Gk�ܥ�����;�=b;/�ڇ'm>X����
,Y�����Y�gY���7�ݝ��=趴�[Z ^� g��t�`��%�y�}{�����0�~�̙m�(�s��%g�qx�G䡺�Ȏ��҃�C��=J�9�\��=>��ϒ�v�kJ�N	*�5���7��I7��Y��	�t��֧T:4A�\ ����$9�m��cDX����?j4$=EQ�P�iO-�W�u=�
f�H�ߢ�י�<��r1��)l�{�
8��W-��E�Z`侥)9�ߞú�0�D�,�"�x�F���O���&.�����֟z���(�9M���l4��t�^ܖ���[�5p)��>(�p?�NR����x���V"%>�������7��V�xv��][�]���t�r?��}x���d3�6�kf�5�`ʭ�@Oj�Z�u2n:3i�Չ�|檩�7fo��ɼ��c!�u�ER�Uvk�����́sYs
Qw4Н�Ye��lL�g��3�b���n�2���<~K��'�Y��og���:���gv�I���0�s�y��>T�ҩZ�T"َl?�"f���$��	�=�AJ �.�����6��F=��DV a�8oq'DP�q����eD�DT0���v�2�Hx��F%%����}5�X|���xYx�t�|2J�Z��_�v�?���FʪXd]Q O����M	0h�8ߗ���io�}`���Yuo��*2N���j�ҾOBؿ�Ъ-l�֠��|.����z����_��[k~�xѧ[U��ҞUM�݊�����K�A�y���0�u�E�~�)�EǏ��%,������*>U!e�յ?���kG�m��1�Ea���Ɖ�:���>�*�~��Z�{CU��&O	%�Q��T�O���3b�S:�2^���.�<1�.Nb8'=<�<{�}�reX7Ն�9���Z�������z.D%8�I��Vj+��=b�9�<���ٔc��%���`�&u��>U�Ƶ���'�Q�Q]4��x�q=�\�l�ː�[�_\��-�gB��4�Aޞ��;I�0�44���3L�f)I�$���I%�*�Q{V��%�1m+��Vv����N�@]t�c�B-q�jT����g��O%���G����D��Wt��|��Ř�h% k=]=�\&o�ǝ��Zx�]Ys�Z�0��q��h-Ծ�� ���aͪU~b�9�B���:�j���4�S�G��v��b"�'=,�6��' � x��*��V9\���FA��6p	k�ǚ{_M?�T����9ۋ�]����B��Pm���о��8�;�7��w;�=�=���}�g�.>1�a�(&7�2�=Q�X�GǳG�}��%8��hT��{��{ج�/�xL����a���)����I���^�^{s��_�5�q9�&�7z�:)m���)"��xz~��l��^�1 �7d�����ȋ��2p����K�G�*��bͱ��6RfΝ)�]�zv�)B��.�� {1��$��k�q8�b]QX=;�@ؤ߾��q
m��.J�b��yi7�9ك)�����<JQ,��TH ��lk����5h�p�C�>�#!���{�Au��u}�8E�?�� O\ f�V�{z�Ӏ}ӆfv��"-e߭���4�9��:�4��^�����ΐ%���[+iT�M�ٜ�祺��\���#o������o ח+�.���
���%\n_�Ռ�[��R�.+����U~�ͷ=,d��J��>�|���{�S�+rW���&�����$�Z���M�1z�`]b�SN5DdAvC���~s��݂����H�O�u��_o4x�	aW��ݙ���Ʀ٬6z��a�"V�%�Aqޚfښ�ݫ��p(d^�Q.}�5�G,�'އ-��1�Β�e�����a�?������mzN2�xi�S�ڬ�nIR���7�b�G"�ZݲҰ3��_�S֒�o�n2SXc���t� �S��~����4��NB��4N�i/U{!-2�*ᄡ>! �d��+/��3 �6�5d4���~�`��5j���QQ-�R�b8
��*䬙ʀ����P�8=�V��ќi��(T���g?X|f��1;�ke+�V�ma���-<��Z��uO��¨K�><=x��dk�m,�\K���b��xRk��P�(:6>�}9�C�ͻ����7
t��/�v�QT|>�Ɋd��S<b�0*	b��9�i�q;B��8�(<��ڿ���]`*E?D'�=;-B���J��N�ݲgp<ε�5����oc��Ӽ��������k��ם���~70n�k�g21&��/b��XB�
���}RG�h}�ˏ�����~rηJ�r[6Ö�]$¦��j�6�8"��1By/�*���q��RwѼt���?Q�S�W��n�k�8������Ȥ?��	:*<�sJ�����E��ˠ�C`R�AB��:SOI>X*��$�s��M�9�sf��AO��C��,�<{Lτ�	�~�~+�x��P�T��\�(fm���q
�i��>�<��<���l!&p�[ѳZ"b���Z��i�/�FW�[�,"���ܴ^�0�R��K��G�qk��1�L�<|�C�*[,8�M���͈�)����"��6ʵ�.Z��;N�ձ)���5�NƳ���N��~�< V���N��0::����M��A����)[E�lU$���~�v��[:f�,�S}2�x"@TL��^N�C��48lPݔ���1��yo�L�f���ds!�$6)�|
�K��YZ���0�����|bز�^B�����Z��З��G���!�hW��[ 
q{c�QE��q�ރ�|eJϺR��v2D��t�H/��:���U!��4�-�O~��t&�!�	{�`v�<� �Q&J�m֓;��@Ÿ��}��ON@|{�ߢ����'�	H�����j�_)ʱV*mPN va�3'f��BU!8+��g.��X������H�o�k��C|Dn��7'�6���54�2��]89����4 3��/�j*�,
o��]Tl��EY�*q!�;�B��?pE������m8�6U�9��c�p5�6o����	�bQe�xg!�lzLJ�Ɋ�{�d���G�$T�X�{?�#n�<[U�F`�c�/����؈P!o㡏�j�Tڡ�ӷcz�N�γd�{�Ʀ�K����C��;w��g�D{���o���b�륻�%�n|��.�۠�y�7A�T�{ż�<�[8���� ��yY�9�~�j�E"�8�r�]��E� ==�]:�"v�U�1�k�,���}��7�������O�|����i�@��6-AZ�v&��H�{�'R<)pS%p9#n,�4Ye�U�d���+̑ݾ7��n��UY+ҋHx1�`:ƛp�)d��!�=�#GD�n��ܮ
�ЄR����Bn@���k#2lo��*i3դP�%�/1�S�H`f\��|�.1 3���q˒wԖin�w/�X�u��I��J��*���,^��N[4��^j�LwS�v*��ƶʈ�[$�\\D}����)^�w��3�JȜ�� 2'/l�*�r�vB�MK���Bu�k��N�[ϼj��\�if_�H��`������r��Xx���/� ��S�f-��OХ���ʟ��1���%B]yC�(a��^�r�{r
RR��R[���(H�R�B�]c�=�дO21�������h�Q$X��W̕��m�X����w���Z}���g�c�~2��F������K�ϗ@���6|����F�if�o<]�?|��	d�šw��N	�e����܈�=��RK3�O/����'�0R�[U�YRW�F�|�'`.~&�й�=�.�/R�:��a� t_���ދcΜ�y��?Ib��/7�L<�#v>M8�����������"� �2oXs�ׁ<N��"`��|�"
G졵U�V�č��9	Y0�4h�)Ɇ�v��S$���ыye*� Y�4`�p�B����(�h�O��U�hUJ-�����oD}G4ް*��M뢴,iqS#�g^�t����z��
�ēvI���ęl-�Y|��� S�RJ��kRC�PJi���4� M_�ė�/���4�H�'A,m���a�kV��o�ϭ����ށ�{����������K����F#k���\�_f��\<�'�Ɔ�Jc�v�ɸ=c.�U���%k<s�
5�/��2Ո$Ɨ��Ժ߰Ý��c�j���I�1�,ݽã��^�1[s9
f{v�k��.:?�O�t��.���� ��Y��r)M&���i5
�*٪j�Y��w�'\4d<O�#�&�4��u/uh�����Qc��'^]���`̣?��=>y�c�ȕ#�ɳ֭���gr�ɧa�TWNuV�A���ɾ'wHj������<&��kJ,��dH�XI%��f�48V:R�mӭ��eTS���Ɍ!ô�z>�gr@!�_sV�J|;��:�K��xI6s�
����/oE��l��0�=�k�i�n�-�#SIO��6uMh���B�������|ɱӘ�8h�x�m��& ���o�}of��� (2�M?����J���[5��@[ֵ.L��XS����c���q�S-��Л��X�6�u��j��/�##�������@��^����䛣���f[Ѓ^�k��]���҄�2kΒ������=�+}e�{¿��y���ӧK�����^��������5
��>ل���'>Qa�z,�!Bgy8<'4y�9/=(���t\ Q�0^�}�ߪ�NE��t��*p�Xw����y�v���0�()��
y�#����!��{1C
�E� <�}4���^���'��@4N�7aN�z�}���h�q��h��0�pg������qTfK5��|�uG1f���負%�D�!�\��w>f��?��q�~/%��t��X��h�����s��K�������
�_���������)� �!�̮م�%����|z�/��8W��ax�Ρ��G�\���r����n���:��*=�U������r�8�����>b[Q!�����C{���O�L�:���}��,͆k��O!�p�-�ӿ�ҙ��	mS&i�āT�qM��u"�$��ڻ4$�w��$�s1�ޣ� ��5]������A��� ��g��r"��i��uN�.	E*͑&̑\�Yן$|�<+�(�z�͆�ξN�\u;�K<	_�aBbK(��^4�6��`ș$�-Ó1���X�Y�8`���oEm^��XzĜ=�`�:S��tI,�	(5�4�*Eq�8�$OH�M�iq���AN��a`�. &VG���4z�w>��� ��,��#��F��
ŬR+����y��}�&J�>�>'Ό�*���t����x�.�fɧO�����F_����{���-J㣸���_L
�[G1lƌ���@j�����3��pcsw8����}m$���6�a���X�f��S��SC��9���&�-Z�LP7�d���^�M/�Y'�c�w�쿧cu��oGBl]b<a�݊FF-D���������67�f��K���<|���<�l�����jc�?d������7�J�\$#�����<|�jD���X^�fژ��jFY�����C�x�_Q&W�Kҷ(��]�
�1}#�0髙��9Ks*����Z�/���q��):���i��%�~-߭�pi�Ns���>��(���G*� �q�g\��1fhL��PIL��k����@�:���LYU��@c^䁮R�lQ��)q�
4�E%��0O3C��:M),�岵��o�wo�[1�
X� j�H�	
�p�0��-6K����
df����d��O*�eEƔ���O�.�Qe��PY�dv���K��}�������n����y�n^#n���JE��1��R�-����p<�*
�����������ɒ��2�ߣ�V=���>�#
T���3s��R�Z|#<�F����E8��x���@��tO�%7����z{���$bbF�J���L_�Dq�po����0<z�z���{Іiﾐ��*I�L�pA?�"nRw�!w�KJi��:��2*�xD.��:_z1��o��Z1�������؎�a<�F��T{��(e�?�W�U����?��(����?3i#�Q?J�����}�l�Ť�J����Ş��C4����yT�[���G�ׇ� ��]�=�$��/�(4H��Y�(h�A�������8��p���O�rz
Aů�:�,�|����dkm��U�>�fH�[N�?]!�B]̢����PK�1��Lh��.��l*�Ts֧��hG�MD�|`���
9!�_Qj�/q�3���S�5���zsxZ����y;��%#��э�Ӽ�ٷ�>�m���(p*C�����;AFM�s�0f�/��L|��!}�X�}�5ܽj�:������&I�I�*��g����2G�E+��4�[~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~�������Ͻ� � 