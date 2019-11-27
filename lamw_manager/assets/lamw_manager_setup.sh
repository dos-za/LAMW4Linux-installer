#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2286902667"
MD5="ced00b3d49e61bbfcd3afe8c79688270"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21238"
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
	echo Date of packaging: Tue Nov 26 22:48:37 -03 2019
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
� ���]�<�v�6��+>J��qZ���8�]v�"ˎ��Jr�n��C��̘"�)��z�e�������3 ?@���������D`0�������ـϳ�O������|5���<�z��l��ۛ���G_���yd��{}�}��G?u�1痣��3�K�{k�ia�7w�6������?�o����c��+U�s�J�̵4`�eZ�L�E�!���=rx�y�qә��B�u����]2��ԝP���~]J�%"��]�Qߪo)�}�Kz㩾���Z(��"��U�v�،�foJB�x���͓W0=���9�	48�$����4 S/ *��:��.��Sg���B�|h�o??;46��f�p`��'jҀ���G����y|l,�,h.��������g���w�~�nes�O���h��_w�Ysf=o^*�U��F@��l �J���v@'�\��PŞ�7D�}��^���ZT�nw�U*���0��atDmcU�M��ۜ�|rK����fq-7��p��T�0 ��L���s5vN��((�����E�MC:�l����7D�$��ù���ϝ��U$��كU��s:� ����b�"�#s:��(��Ѡ��(����}x�O�Jf�Ű����3�-����qb�k"�d#�MXLeY�JEP��>p��Ӻ��$�����@���ZFmvxr��n�	-j-Q�)*'(����q�������h�[R�9����e�`�0c6��'�7]Y�w�A2���(3>uj���e2�A�&T�հ��&ڕ��֏ܼ�Q|�[tjFN�� H3�aީ�D§�(e�I�T�����r֞�ؠGv(f��;�s��Nud�3�75j��y6|��w�Ж�&�N��*��,[��\���2T�#��%��I�^W�jZ)�_%�"r'���~\1_i,��#\$W(�R�$!�LM
�J��榰�n+o������R��'��P���ܧR�41X5�|�D��(s"�o�?f0��Q�r�Y��&�ɇ��IK}�������;#��Cj�ë�3��;��+���g���ٳ�������.�&E��lҮRi����h3��ʯ(��G�����6�]Lׂ�|j)D�1:��:I�K��*���:*@8��ܿ'�olnn����������J�/:r�9n����{�v0b������ó~{����Q��"27������xQa�ͣ���{2�gӅLb���=˞ڐ�@0���1%���z�,����f�DT'+���ȯ��T�!q�O4M���c�mL&w�s�2�L��"$��i�����k:12�1���0�ٮ�'�궧��������V�|���#˯|�e<�=7&0^E���͙L"��P�L����~���:���~�}��_���ÿY���x����%���WmَE�:;���?l������������?����7�V������3�\�0��Єԇpd�����w@fԥ;H !��_ģ�f�d����^�lk��Z�g[_ȱ+U��t���|��X���8�3-����M,�->�=�ͅMy�Ҝ�m,x)<@:走�\Q*�7�=�Y8����l3ѺK�u,3,�p�z^X}���#7�Hㇺ� �
&�?G.�E`䄌�]����cۍ��	�P����GRfN���FF�V}����s�?�B5���­O
�D1N�fؤ�М1=�ģ���hC�0��q�����0T=b���cȡ�X��0C��I�O��"�~�����Ή_���N�Ԉ�� ���4R͸�(��@.m?hI�w.	z�;=I�q���4�AA�fn�����_�� CP���fX��⏫ù)*Â?��R�:�=�Ɓ=3������â�2$� ��0{>��OǞx|�
��-��=S��%�{�˃?^�r	�W�W,������J�+a:9Bui�n�ٹ<�'������&c[�+�j-7H%Q�峓r�E�j��z�\[����"�R�oz��=U�wi����^(�px��G(�dq�a��􈤆|���؟c-�m�����5�)�h�v����[��mu|���Ӌ�L��;�g�G/�'m.�܄����	����yxˍcɌ�uy�ꠏ��oj��RA,�>�˛�ޖ`ã�X�K�A�DT�AO	떚�$g����$4����գ ��ȋ ���pEy�M-�s��\���f��K�EJ %�T��A&`��������GR[&���h�����	���f!. �}��� �i���� l� ��Y�h��˃��-�$���:�ܙ��B�/7f W
e��*R��$H��=�ڂ���9�b�^+
6?�Aȇ�l?a���	YI���'W;�G���s[#o@��i/��&�"� ��]r h�����>���n��y|�a�l�b�T���W�c�Z���Z���~�ZLWBU��e�_���+ /��rf�z �
6�p$*	�e]h���R}x�!+�ni��&��D�����`I�˨�K�V��x�<MJ���1G3�R2��M����&|,���}H�=[��ȑ�칠y�� ����&rǐl"*��-l��a[<��p�ϕ-�@��B�=��T����&]u98n��h4����ng�Q�΃�S�$d�͖��Djx��j���?�����%3BR�rޖ�V��#	��zY6�TŤgN.�w�}�<;�7Jm�(I�mעW��K����x߻ۏ^k.�L8����o_��׌��	�4j�����2��������ӝ�������s,�j�37���/I/�k�yc��?�ܧ��\f��k�!��.6��1�:qY	����_��%���m<s�hJ5�d���%]P���A�7
�w���gN��k�K�����0��p��G����L��(��ze^E`Z	�2xkr�P�c��6ޣ��2J�N����J������G�R��i�?�3�.87	���dmp�|��`�>15bc�{��7������B�O/ۧ�����w��o����<��g=C��hxշ�!���RQ����s��Y�ӆSZ�MH����" 	x3�'�x��5�bi���58�����I�������,~reD�x��7�Y�����X]�Լ<B@T�rR�$I�� V>�E�8]<�`�G�i�c�I�v`�$�Un�Bjє�(�c�����V�b�y\��w��c[���Z���k]�c�`��L����d�x�I�	{4���r���q�~w�y����Dm�����
u�-�qY�RY�������0�z&����>z������&v	��s�~�+JV/�"�m!��f�q0"ɉ���
�ql��v�"s&g���x��D��+�F�I�@jrf}�숂LLp�BsAqa���5��73=���C��B�7��$��D��S	I��q��iY `=�9z��C��M�X�/Z�câ�Ơ$�(�b�����(��}�ZR�]��[;�7���9�����!&�KD�;�{�;��3 �O�>|� � 0P�w[��,P��t)�,���ݖ�:�+^]!�<?y[%��H�Q�����L��}ȣ��iȬ�H��Q�;2!hP�Ԡ�}"��~߉��$9#��T
[��W��Eyf��9���2��zH�;N�{RF(&�bܿ�g�"0� ���ǌ^q1J���yo&������*���7�"���H���̺"*��K�M�I#=q4��u|}[C��U�XY1���\���թ�(O!�Јk*��1�]�ܳ ,��3��ۉ�v�c�㟛�������-�qRHYIE:U�3gͤiJu��7���x-+z9��2��ˣ�`�y9|�1Z\����`�	�H���|/	� Oy��66��j7U�9o���ݳ��nȍ~�� ����w�r��%!��~��<6����S,k]v�7rg\"�w	ގ���YG4J.�M�9r��R�����[1)W�4��Cq�G�ez��䕵����N�]�SU�k1�-�n�~r��7'4f�n�h �p;����l��u!fL�O��`�޺�����\g�x$emF�� &>f+�xg�1��?s=���� �Zj‧�����;�� 5iSc
!m�l4r�b1�z�nh�!J��I.�����c�Z��_�i�T,��޽�R��b	Sӻ
��a���� �Mq�����"������%:3�"��L�޺�e+�{�\������y���8#�=���Kq�<�W,��_���c��I�,�&�ԍF��z���h+�\�p%���N��CV'�@_P��=¾�F��s|���e@��B�/�<tb�H�ܞS��VZwy�h1o�n[�]���#�̀��ͤ�/����zjΩ�m���z{R�"|D�}E'��7�B��iH���5�Qi<1)��|�U��.c�I	�L�e��`"X�nC�QT��`@W�F>nH��횎15A�DӵO�f�o1Z )3;Rpf�[���sy���h����g��=a�qM���嘌�}���
�U�_i�����ރk�(���.V:Y9 lη����F,o\�{&�EaRǼ�<��`k,f���^O�9tP?������3�d�>d�׻������v
KY��UH�{7����A�!oxi:5��4��Zwk5|����=|M�Ht��V��nkt�>=u��$�/�)�s�!d'�]��q��v�4�s���ۃ�a����A
H�7�MQ��4}/�:~}�zs�ȵήYH��f�mQԞ�#,��`�"��ZI|�<�;u44)m�:	��n.b�_͝��Dq��g�_&�	y �th��l�G��dv��{^��TT���s��RvO�}#QI FYX��!�4 ��(���<�{)J�k�w��z�KV�<F�P��,*P�k��j���,J��r���Y&1u`%���7f�2�qv-��b�c�V���ڧ�@��o50�{�B3�Ĥ���[?�����Rդ-4�$�9����U�}��1%���9/�/(X:��7�P���AZ�d�7��ou��0'i*����_?��R�O��:��c��?<Q� ���J@��s	l�&O}!��V]� cВ�=9q�[��:'��2���<E�"�Sz��Js,��W�Ƭ���/@0�����Q���(~d��V�s��p��y_�!�3��O�?/��0� >_TK�@�!����������:0�3:�kk�y[��5�%"?�'f3���-�p@Cc3N������g���Iv/>@16����	�~��h���Si5du���NqW�(Xt��im��Pu��)�=P<C!�L�wM�7��#�+ǵBgJ-�\<��Й��w�Wf�h렇`-s*��G?+�p���F�|�A�p.pZ5"�j���u�e�$�&^�)+�ewd��rR�QW7
�uu-�C���0>[��Z(���&���^g����m�mٚ��e�I�)��t�lю:�-RJ�meqA$$#&	 ��8��2Og�üt�y8����{�U@��ٝ3C�e���k_�}.�p�����I��UYM�`Ȫ{�5�?e�j�dx����0���~5�<]m�4f4)�|Ei�ก�	G uxْ~�����9�HO���c�T������AЇ��B�����*�D��\R:A"�� yǀ�njԍ\q��V�A�a�u�~@�P�;B�zao�� \�P�Q�d���A"��j�r�Þ�35x��+s��ge����7Gݓ-��+�m�`���U8\x��c��s��L��[�'[Δ*;��ںQ�N��|cPeNZ���*��"LR�6��n��sJ�+���X�ُ��J.Ѽ��kNe9�
��G�h�7��C��fT�BQ�:Ɯ�U�u4���V���E��4U��B7#�q��Qk�spM��&Ճl����|��L�"��A5��'2�ƴ0�y���HN6����DɅt���'ث����0ƿ�A�K�>%��U�k�����D|��e3��+�ܨ�4�܅4��_��\����)��o�����d~֢�'����7tiӾ�iTq���D���B^��=/!ꋖ���!,���$�?ДC�����U?��/���(�N�,����ǟ�p,R�{�}���{O6�|E��
�����ʟBYM����OĄ�7�r��/�����z;��F�M���Nӑ�F��E����:��$	'�,���c�M
�)Q���*�&�&�b@R<�ij!yq>i_E�����y0ɍ�Xx��-���m���MbҬ�0�Q�>/��i�l3:Si1r!1�/%�I�38#����C���m�yu	�:/�J}�aę�����E���gu��;�;�wIW��f�qF� 5~��E�gk�(�t�
�م�#�
��5��S�p �	T����Щ���\"2 ~���Y]��ŶO��H9�)����]F����i���6��ڵT���6��̑F��6Ʀ����d�[��{z!f�$+y1|=mJM��r������1Ѿ�|d�ZVIS�gH�f
��9��</4�q+-���1@�|�M/\4ꅓ$n��=��N�YUD6���ӱ��)��p�@E���ZU��H6WM�;b` 44!b�/���>>���~���DkֵB�</&.K���g|�JJ�|�4�B��^���c�F�49�����T��,����g��bC�Õ_D��l��m�m`��vܣ��o)//�0��2p-�r�;ϫ�;�(��O6��Y��F�(,a.�`e�\2���g�84l3�<Rx��ĴÓ�Ir/r��T�bJ��`ht4��L�|������nqJ�ɹX��/h/��?���n�w�qt+R���A�8�ewJ�T�t�V�/�/�{7���+y��z���a�Ϻm/������r;�{Y���>G�ˑ�q$�f�ݏ�Q��~O�}_�Χ��2�7�n9����
_!�3�G)��� j6��Hٮ`�s��-��jV������z�1<�үk�Iʭ]���)fq�w���hmh`f��׹y�i�������&���:�Hp�X�R�T�p�h�/ݽ�+��sJ7��1R~�%6�"ƹkv�
�D�����nm1w:*�~�F(��V��!�9`8q/ˑ�����s��^N���9�W��F���V�����$\����{��x������ڇߵf���ʦϞ̳E"QݨĆ�g�	�"�w�yg��`ytmUҷXM��ZJ����K ����k+��� PT̊��`ʉ�F.�.	z��0�/���E�>���Ð�ɾ��J4y�������5#m�yAwM�.�h�)T������eET�w�&(m/��!>���ا/Y���?�Xm�
V�8ƌU��<g��m�`^sy\�VVZ���+�m_y�g�8�>jn�����`�i��'����?��^>���(=o���(�	�������������[����w�ȯ�M]�I���pEYB�H�{#_�U�g����-m�W��/��[�Fbk��x�i�!/���0.^̶؜40��֑�|n`ݬ�*L�x2���C��*=�������g��	Jw� a�Y��ɀ<��¸|�Gkni�Q9�rcv���+k�|��|��:\�
�(.��Р&�l޶�X+?��Ȝ�A�u<e�ȕ�I��$����+g�Sj��z���Md�a�,�x����}j�- �t��%�'��6�؅�?��
� ��IN��sQ�����g�<��5k��/�����l��5��?��o��߮R���Z�����a��F#�b�=`{<ؘ�Dp.�4D�6
uw���Cx��|��\�V����`�9�7�G/w��w;�=tj��j_��0B�O���vg�ݪ���o��ъ
~��i��W��n#}�=}	�7;��zS=>l��읈,�4��U�X���2)٦�p�������9G�̈́�;�'���W�v�ur�W��L�_⑀���7A�b��櫾���K���Ԍ�YU�Ջ��Ys�w�]24��Xh��7��;���ԭ���ƪps*�4�<6&gN-��M�}Tߓ�����P�<`#"�����A�N}�)��i�n�4�[�c�x�lفK7�Xi��l�����e_=o����/M9�*I^L1�
ew����4��$�D7x��t���,�7zJ���u�~N�F����tr�@�P�n���ǭ�ã����f&��J3��ԃ��v��)$� �JsB�J���0T qy��b]p{y@�D_I^K������H�]ƌ��*%)��T�G3�2�-�����n�Z��v�{@���TQq�`��W�B݆`�P��� ��Z]�M����Q�����S����*Z�|*�����V�V>��z��^g��t�{�o��xQ ��\S*s�P(��ǂ�|�Uީ�}�����k&��raZ�K��X�����̶*�l]q�iP��"�pic�C� �3�b��l���{''���N���7,U�e��J'�9��n(Y*��t�J�'i�J�0�Ч��psx.7��L�4	W�E�NR9y/p.�Q� ��J�;?�Sm*�wލ�$�Ar�ԩ*��YX�R�,��ao ���1)}e#�@14�ċq�?�AOw�"gB��(�rе)���HGO�=a]�Jc[�V+VT��L��[��T�h*�-XÇK&�\��z)j !������!�y���`��$r�W�a�>��t�����7��b�O� Ƴ�B���܁z}o;$'��%~��  >>�pp���b Ǧ��L�j�6'��+�[�)��ot�1_y��`��@9:wŶ�����&E��M�2�r���@Z]�G����Nݷe�O�2Wz� ��N�tQ�c���pô�C��̦3J�u�v�2U����Q�LL�� �ܑ������j���Ld�H�����/
hm�n9�~7�0���!�lZ�������m�E�s��h��:a�H᰻�-�F�qKhl�c�M$��ć�5C)T �M��M��Ð�ujXf"���Y]#�'��Ph�h:&_�l΁>��
��ҏ��m�n����j8�^|�r��tg�]h �!3��;N>�iFg���O����£)���<�1�.<vy6�We\CRi��g�*�����:b%�[VQi�B�(T�-ia��	F�AӸ��@����<�<`'�C���k���v��6�#F���5N� &Fv��{��::O����q?b���E�ػ�G4=`f��?p��hE��!'�w����&�O��"M:c8��s�	���)q�b|�v�G�~�U��N�DDƜ���s~����+�����.4ɂ�<�B�O'D��LY�b��"f�� ��	��P(��U�m*QtcO����g���d�;
G̃E����*bL��\������uu:��آ]��Z6q�d�^�� c9]*��qJ������8�p�AŶW>*��S��U\��"�-�<*q�Dcy����o������[��=������,<�$r I¨��ѧe�/�G̉����@���O���?�76���e��;�l����|�@?�d�w#��(H�h�r4�/ٽ<�|4P�sݜ}�HV�#��[Ǹ9D�/�=4j�1�S��4饣�%�JqǸy��2u?Gv40a��$A�5���х�����$44��rxh�B'׬=r��|�'@岝M�1�Z�$��H��'� �;�vG"�#�+0ȇ�&fY�niU9[�>j��#7WJ$,W�EL��,����+~i��� �5���rH��t%�M�9$������JHQ� |�
]M_�C)�=���gd�%��ؤ@6�D�|�W�sx2�^L3�R�"/sVX�n�%Әs��=�nl�o�TY"���'�]��)y2	aX�!��H_�ޜ��/�H����i��4+P��
y��/�^4�~��x�!1�o�����U���GP�8L���e�&�IE<I���*���fU�4�ؚ��e
���y�)�@��B�$C�[:�U�jFU���@��#}�j&�+C��جe
�h2��$B\�&Ki\Ɉ �a�Rĵ�+� ��6$#U�����;���Mb9��&gR�7�{5�K̸����I�s�s��][�ES���[��+,�g1vӌ���Z�Us_��:�}a��m:��u��R���ci+y�"�I�Fx1�߅�4�$5�Q[����`s�q�n��N�qwk���j�A��l�?<��z�h����-�e����3�3Z�$��*��'��[���xf�]R����1~���n��}&��b�B��Mc:�y�Fお�L	��fB�*���IW҈{��rFS������А�c��5��I���y��s�{	 ���hR�
3f��
j�#�簟b�C���ڤ�vĖNȓj�j�9<�E>��YL��ym@q�{�ko��P5
5�K��=����o���k��#�!���X=���׉�|�f�<�b/`�X��x�������M}���BG�澆�ޝ}o��Y8Zq�8�ju2�.}�<��>�C��O�h<��G,��O��i?c$g�����G@�g^�˟|!J�@u^򮇣�jo����[D�))$�1�������b�Y�J#Tn	�- Ԯ8���U	��� �i�ƅJ]a�����4�6�,w j�G�J�����$�Lp�F[\O!�Ү@Za�7���|��}��J�L�.
 3@����0�(Ԧ&VT)�Mն�5k&5J�,9��?��c�G�!��L�)�*MZ+u��5���0���t�����`S��Ku�7�!b�Lv��!SS�3Y��4�&x5�F'��Lb��)���1���_���-I�@�<;G����JR�6�"M%�⪛�Wy����0ϓ��ek��|��_�A&Y�lk5[{�������f-��f���6�=�t�V
	�4˝"��f�C�e���6��:*�{/��~D��o��q�	Yb��[X,ՠ'� D����DaL^u��'p�چ��6�ު��Gк�._lH��v��������� ��q�z�b%�AU6�ig�� ��[�Wb��fi|���A����#b��ޫ�a���uv��x��Z}Ӯ9{G�Pց
-�%����U�.sX����Λv���`W��-���6�2���4������J��d;3�n�9��#�~�p����n#����N��ԗM�C|��{+E�6_ǖ���|�'��e0��/�ܞ�	J�	��� aK���}��@����nUp(�+n+��~{�ۮ���!�܉��hkj�������{2K0���,��::ZZ���n��&@U��2�L�f��%���8��{�5�PR�P%Pn|i�r��������[JH3~[�w�RTg)��pxjz~Е)��J.Ql�Th�T<��T�u&&6�dv;��~[ �`<B��1�`�H���%P��4'�	��CN��ϝ=�"��<�M��k�^#Á!z���䵌���.h/Z�nܣ+�p����,^���<U	���xkF��,M�0/���|��Y��/"�`��SS��8#�}�q0�!���q��C4��8"����+�{ͬ&;����<^hZ̾c�9��ӧOY�sU@#]6��e4/��ܶ��x�ޭQ�i�����q�~g��D���>Ϩ����
��娕J�i�Ŗdp�GW�	m/j�䄑�������VX�Q��F3^|$�'t��g�X?lbĄ��������e<E�����J�;��tTW�ӕ�;o��'�9���h��2C�?�+)Qw�+�ȸ�1v���!Z��A������00��	ږD��cx���l��NG�蹪���߇��\L�.�nf�d�[��3^i�&�f��mH���mњ��%Tn
�U/!-� ��x�?��r��l��=ڏ��$YS4M��ޱ�r��k�t�s01+b�D̼��і���p���ftFRl��f�u3��"�n&A6�m��jq�M�T��Rn��~�����x�@�{]���'��dj̱��fJ��O���d0X�T�z�X��fw��!�dF�	&��v_+_�#��*���;<�݋iq���6��q����qڜ��*6L_���6m��X��fe��@
�y�Y���p�j$��H� �9	��zݍ��k��cזH��0��`X��ˡ_J"��a&�1���S�'���5Ok�@��[���_�4��I����;7~�jZ�%}��M�b�>KYm��Db:�w���| �J��p�N�����l��� �w3b�z�ۗT$n�f�4��! �bz�ʏ�>r��^�<R�1Tu���[��#l�<IU\&9�g�Ɛ#�s6���bYL�N˱�w�9�ZF�Nc��Vj��4߷۵ov���}͸��z>��]+@�{��=�N�E\}�[�������i����(v@�O�w�˺z��to_ ����3��-^��Am7=�S�s��5�<F��<�W����K�E����$����M���-��PK��{�:���ж{����]m6�="�n���EH��`�K���lԯ��n�M�{,o����g�@۪�U.�9V>~+�̅��ѺlȂ���e.n432���j�"&0�E%}R�p?3ҸU�C?2�_`s;7;�$IE��-���Ym��Fjl�r3U/��T�3C���'^����,�����SW��m��Zw9n1��Tړ*;��tO�ౝ��8�[���н_Zo��8/�h<�!�a҄yb�rD��r�,�\s��:��^M��@[U�2ˊ%B���,[HƬ���4FP��Y�����XS}n�_Y�S�͹�
B�ɘ�xfg0�bNB&c>�QLD�Rfǅ��C�Ee�����ͧ���?�E�h�g5��:�"4ƱY�+[^���yYe�o�����Goa�3z$"	�����䛵�A�~.di�Y}A�-�����+� ���勊���QAb� �&���ty�)�*��PƲ��/o�&�6�(�,֗�
|�:��{�S0kjTZ���҈���d�Z�&|���44���h�$EA0��#ƀ���Ϟ�b��r.��;W0&������2f�r�5����a�qI110�G �9x ��%�-!q�� �c$
W�'成2����Z)��lLeY�?k��7����R|SV#��� x��>������-�!������B
�=dPq�#HC ����6�Ó�	H���[C;�I�����3.\iW���М�1��E�k�f�-�l̦���ڵ�g�yg�9��Yي�6�#�}��ʌ�l���p�S�S����D�W����g��q4��S,N��8�}?I��Z_|�&�bE"ݒ��Ւ���	u�(�L����BI�n3��3(��4Cii�'	�+MZ*�D��^�H�.�S�nU%�.{�d�QF����L�Ӂ�ЄGq?��������؏�E�V��Ex6è��C��E�c�I3�]��Ĺ�ƭ�.-����1�f��B'�9}q@~��yN��|��V�#���ۙ�bv3x�/�Jf���ӂ7(ω�/we�S�U�Z����d�Y��ĭ�n��m��Yγ����\J��-%uf�@V|�u-��3ө�0�#X�z25-�53���É�9N3��vq���kY�>�5��^
���&����S�q�|�ѳ�@�s����;5�ӿ��7y�<=r�u��؀4���M�`�&p���ڞ.��7��qp���j路������
^�`��b�3�\�#5V�7�Y�6"�W���vy���95��"!+��>����D�?���B�0-����G�C":r�Z+��m�cc��v�Ӑl��G�sFN�̝tܨ��r#��0�g�(�+�	;6f���ڤ��$�2�(��؝���;�[��p�Y��8kvE�s6��C�Ix,D�3��1��Z�2wl�2�K�q'�DX��)b;C>���F0I(O��%���Ǐ����f.�O���m��v[���x?}+���Bq�@��Ys���ؒfj��׵����=d��G��%�]�S�U	�R����ް��y�B���gR���gu�)A���C�O����;����Q$x�"*|������}K__�w�1ga�*����U��}�5��*\JѼW��z�$@?Pa�@l��K���e��UFt^�#��k�X�!�Q�#�:�qZ����T�G�,��ժ�Ρ�؍�� ��kVDR�?_<G�V9j������zf��T�;�da��f������r�_��w��ܰ����1(k:�� ��$Ɖq�\.pg�	��ʂ��ָ�r��b�^R%Ҁf���C�SE#�i�=��#�"���3����l��G'{��K�p��*��8L���*"��9J���a��ګ��0$��P�Lw����1�5Gq�B��Gp��rgg��l�����k���`9��+�du�{��GHfq�idet�v��vwNv�������ni�x���Y���u����H�����WH���c�}2g�U�`Ή�{��%�����7�!;�J"���(����pQG����>K
ص�)>8%�(�xR[�d�'�܋g�\'| �^Z�R��Ir��s��p��^�aU����	А�E��BY�=��^���,*��"�|��;\g�����Ť������Q*�~^Q��#Ak�������~{rt�����������b<:>�Zg@��d�>��Z�զ�X�4�z��h>s,�)zq[ ��nQd���T������M��;Iuscc���O�[����>S���~��d<�ZQ�ٹ��vm�v�c�����$��ٓޓ�\��7殙�OԬ"�)�z=�5j�ɸ�̤iW'f󙫦jޘ�s&�2o�����qI�V٭��SL��{2�e�)D��@w�f�E[��1ݞe�����n~�=�0s�L�-ul���fU־�1�7�(2g���&�s�G���U�u��P�K�j�3P�d;��4���2�7P� �'`�h)ud�to��w�s�~M0�7Y����ŝU@yƩ�÷g�-Q�L���m�T3 ��c����Ã��X�b����e�qӅ��(Qk�E|�q���t)�b�uE�p<����84%����|_ڇ���������gս	��8!֊�K�>	a�C����Z�v�P>�V��Gs�6(IR|�n��a�E�nUYK{j<T5�w+��k��/��M022�]��?�󗰈�*Rg��T��5�W�>��:��9�͚#ļ��c�O�'��t�;�T����zj��Ua<%��SDY�RQp>�bΈQO��x��hNd�İ�8��������I�u˕a�Tn���j��'V����\�L&!�{Z���"�������~�cdS�ኗ`�+��z�Աc�hT��."ߟx�gHD�Gu��z�]��lsaĳQ,Co�qipϷH�	A l�Ҩy{:�$�����x��4z�0Ś�$5�X"&��_��F�Y�r�Ǵ� N�Z�9�v{;�u]й�
��-�QO_�V��:>��ZX)nJ:�_�U�s��kcƣ� ��ht��s��=wگ�~h�}ve�)kM����-�6��P�
�t�Gp�5�V���T���ꄫ��c�HN�w�K�9���xğ����p� �n�\�[�p����b��%�ek�}5Y�LS�wj��l/w.�"���C��?TS@�޻b�X�ߴ`��t�p��:�����V���������˜�Db=������C�Q�W��_&�a�R���1	>�O/��}/�¦�k�2l�o?$q"�{�{���~Uք���p�l����0�-w䏧������ ����g|x��ƀ�ސ!(�f��#/b���9wop�.�E��x��5�<O�H�q8w��w��م�L9L���H����Їc�D���Ḋ�uEaU�츧a�~��G�)�a�[�(��-�J����d���;{p�wl�(E��S!�v��y�.�נi�ù�������0B��������I��A��TJ�<q�h�I[���1N�M���ދ�X�}�.����.�\Ӝ3{�ڒ;C����oU��Q�/4iLgsj������s�VD�>��1�W`�>����\_�0�З�+��p�}U�V3�oY#K������@V�-7��l���g+�W���5���O!�p�]m7k�(#\3���lj��G7��t��u�O9����_�	�u.DPw�c�#�?5�Is ����&��]]{[tg"�<�{�f���Q~܆��X���m�yk�ikVpw��+>���9Hx!lG���<��f�x��
�4{8KB��}���z�-��zד�s���m8ɼ���O1j�z�%UHi�޴����Oj5t�H�����OYK�O�ٺ�La��::ӱ�@cL�������o��;	�O�8Q��T텴�d����t�l�t���`�zr� ,���֐i�lJCk���W�Ԩ��GE�t�JIh�Q�(�����f*.��tB����Z��z\Fs�a�Pa:��`�E@F�숯���Zɶ��V�����[j9~s�=�R�.�����e��]����M�4s-Y�nΊ�Z�I�!+C]����l���0L�U7�����^�(���b���ڵGQi��4&+���N�¨$���瀧	����\��Hj���w��0��0o���n+՗;w˞��8����7�������O����O��_K��9�_w6 Ӧ��l��i,`x����Ę�����/W`	�+ܢO�I�ע�Y/?��SvWx��q8�*q�m�[Rw����1�P�,���h�0`�{�U�J�E�����D�N�g\���)�u�8:Fh_�#��LZ&����	;*�'�۟9�.�~�I�	���L=%�`�TnГ��	�6��ϙ��=5Zi7�xw��1=f&�����,G��SB�RAjs����Ն��)|��B��h�<@���o����MnE�j��Mo`Z�j5f���]�o4lQ��lr(&r�z�|J}xtO/�N]ƭ�
��3Q��E��l��6��r 6#����+ߋ�W�(��h��"�8�VǦt�wT��;�&�f:9��=� XU@��;����xJ �7][�6��l�U��
Z��/�=>n���O�ɤ�� Q1��z9!�Z��M@uS�o8hǬ_�E3qO�Y+�ͅ4�ؤ0�)�/��3fiE�~��kכ�[T��a�{	5����h	�C_R�MJV��x3�]I�/n�(d��A�G!���z^�)=�Je����c\�"���oZT���X�x?��Lҙ\�`&�������Fa�(�	XO��fㆢ3���C<9��1~�r�.���x& ]���G�~�l(�Z��t�A9��E�uϜ��b
U��8P�����c�O�Nk#x����G�	���Fޜ��L�C����
�$:�v��@܆� �pƾ���~�(�=�wQ�u�eu�ąD�=z��e,b4:��B�TU��3�����xڼ��N�&��E�㝅�8��1)I'+2�钵�{��a�P�ob��� f���lUQ�����,�72b#.@����>⪩Ri�RNߎ�a;�;�v���a��6,	�:��FU���I����!緾��w�M����6�4<��Y��`n����'�`�R�;��b��n�\r?70t�H���e����u�<���ʩ�v�����w��عV��X:�i(�h6��1����>��BNzl?���_䯧i�ڴieۙH�"�\�H�X��L��Q䌸���d�MVy�WĻc&Ʈ0G"pt��ď�I�vWe�H/"��tH2��o7��B�b� ܏���r�b(�BJ��.
�嗦��Ȱ�̂���T�B= �Ⱦ�dN]#��mp]���Ā�@7��-K�Q[���޽Hb�K�Q�&Q&*�z�X8[O�x1f;m�pT�{�u3-�M�۩س�(#fo��rqYY�i3ۦxe�I��3R�+!s*�Ȝ��Ū���"�	YG4-l����	�a�;�n=�2�]�sm��}�#]����c��%�b�m����вjLM��D"?A�N��*F@�s����!t�a��MST{�� ��)HI�[�Jm��3� �J�
1w���XTB�>��4|hnĊ��C�aG�`4^1Wg�%b=���^��#��k�A؏럵�9�/������c����/5���W�Im4�2��͍����?�x���2�?Ƞ�C�8�'/�j˞�����{^�7��fp�^T���O<�a��=��ܳ��~����O�\�L��s�{�]�_��u(��
jA辐?�׽5Ɯ9���}��,(&�;^n��x�G�|�p$��1\yǗ/���u�Eb�eް�<�y���E���E��Ck�:�V��/�s�`�iЖS�A�,+�H�ϣ��T�A�di4�����T�ρQzр���y��Ѫ�Z�c!d	��� ���h�aU$s��Ei%X��FTϼ��:�+�����'풔7P+�3�Z�	��jU}��J����פ�2p���6#[i����/i_dC�h���O�X�4c����&�.�ߖ�[��0������t������/�/9������Fs��}��?s�̟�
+����7&����hV�v�����e�*Ԅ�tF�T#�_��S�~�wڎi�y��&a�x��t����{]�l�y�h(x�����K�):���H?��?��s0'�gKdM�˥4�,�t���(̪d��Ug�3~��pѐ�<厌ǚ8�xNֽ���n����G�u֞xu�f�1�n�h��s����"W��'�Z�>RFo���2$��iS]9�YUyB�7$���!����N�^L���?�)����!%c%�Z�����X�Hi�M��W�QUdLMzr|�'3��X��y�x���\�Y�+��,Nw�.���%��*(��/��	~d�I����Ȯ���Ͷ|�L%=���5a�m[���"�bZ�%�Nc>����P�H��7�a��"���%�ʃ��7�p:N�+Q�o=��{lY׺D05�bMi�V䣎�î��MO��VCo�^cQ�LTx�=LJ�]����X��7����=�{y�3���ӓo�:N�mu@za��wa2�KBˬ9K��+��?�`������	���m���'�%��e����{Cu|����Xs�l�jY���0P=� ���<���<�ND:. �(P/r�>݊oUr�"�z�AV��D,�;L�?��`���xz�rn�<��{�Q��Oѽ�!��"| ��>�HH\/~gؓ�u 'ݛ0'V��>]Ks4��8H~4�X�\�3�BI���8*����T>޺�3[�NtY�S��ǐQ.��;
3L�JθP���{:�e,P`4��~O�����%����e�������C��v�c��B��Tf������e}>�d�Qs�+r���0��G�PC��#F�y@zF����w��Sa�ldr��*EX]q��w9a�P�C1������	���_졽�`�'E&uN��lk�>�h�fC��5DՉ���y8����_O�L�Ǆ�)��F�@�Ӹ&O�:I�������;�{�˹��G��E�N욀��u�u�� �˃a���3Qs9���D�:�f��"��H�H����O>S�M�Y��f�ig_�R����%����0!1�%�R[/�S��\0�L��ɘO�]��,b�XO�7��6�рt,=bΞQ0����y�$Є�g����8`D�'�Ц������ '��00f����|��;z}�|n���mh#z��bV�kz����V�>P%ei�gF
V���w:WO�b�o�j���'^S�E�����F½�����Q\@��/�	�S���6cF�~J ����@�ƙRw��9�;�q��6�y`��0B�k�k3a�p�m���!Cܜu�e���G&�A��݁[/㦗�|���;���ӱ:�D���� !�.1�0�nE#�"�l��}s}��O��_͍����|>�j|O���u�c���2M���y��|�T	.��e���q>D5"|�E,��tO3mL��5�,�_�����T<ί(���%�[�Ă�.j����j������9��Mk��Z]�ӗ�w�����XK�4A�P���Vf�4]�9b�s��ό���ߣ�}ʸ�3�x�34��g�$&��5d_OS�l�YPf�,��UX�1/�@W�n�� �Ԕ8_ۢ�ls�����e����r�Z��7Ի�ݭ�]�wM
 ��i$̈�Z�@�i������x�Fzg23�����T���'�β�"cJ�{�?ۧ\�Ө���Hh���z2;wa��F�>[Q�͉|{E��tU�<]7��U�wC��E֘dl����Ĉ^8�q�|_���i�����K�����Z}4�p*��ԏ(Pq�����7�KapTj���>_��p^�e4��Q��=�C��L�����������T�*q�3}ŉ?���^T����\�����A���Bns�Q�P$]2��]� ��Iݭk��%/)�f��ʨ(�e�0��LH|����u�j��B������>c;���H�%R�J�@�%�4x_}V��Sg�0b��F���̤m4��F�(�:��.�Z�!��*���_�i{J�$F�{��QE< n��x�E^j�DFvq��7�p��t�� �&f�� �����KVb����!b �?1��Y(p�����7�&���M^W%���!un9!�t�(u50��Jp�&RC-1Ĵ�R3��˻L?0$��(R�Y�b|�7u�Q�?(*�d~E�y��Μo��O�JԤ����i],��z*��R�P��G7
L�Nf�"�ȶ�FF���8�ߟF0�z�5��y�	�0*3�}V��uc��p���n�N$��$U'���6��k�z����P��� n�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~���g�Y~�~�/�Ii � 