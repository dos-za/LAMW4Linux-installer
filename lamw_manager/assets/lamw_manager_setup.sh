#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2440022435"
MD5="0eb2473520b41f6d8336257b561a1b73"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20450"
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
	echo Date of packaging: Sun Nov 24 18:37:12 -03 2019
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
� ��]�<�v�6��+>J�'qZ��c;�]v�"ˎ�ҕ�$�$G�!�1Er	R����˞�c`!/vg ~�e;i�ݻ7�a��`0�7@����Ӏ���m�n>�n����A������ӭFڛ��͝d���D,4BX��^�wW���O]w���xa������z��]��͝��������S�F�خ>1ٙR�>���TO]{If[�EɌZ40?���#��ǘG����-4�P�m/
�%éM�)%mo�GХT_""��%������#vI��7���F�Gh�l�~�P�3JTY�Ub3�AH�	�w���_���NFg &�� �\��Ӏ̼��8��f� JN���_��
��=�}�����h$�����Pk�դ3>>��'�Q���X!Y�\o�CM�O��q�E�u����9u�Qo�y�e�m�e��5|n�(W)
���! +�C
����^pU�;ls@{F������׊kQɻ=�9W�����`~��5�ƺ����9;���(3[Y��Znp	�
�a. �z���j��QP��7��	l�2�Ft��e�6��RIx��_�Cק�;^!�H�X����	�gtzN c�} ĞE�Gt1��Q8�)�A��(P*S3$:��<�"�����a�o��g�[t�����T��D�1H#�MXLeU�JEP��>p�9�Ӻ��$�����M@���ZFmvxz��n�	-j-Q�)*'(����q��]㗮�h�R�����e�`�0c6��'�7]Y�w�A2���(s>uj��e2�A��&TVհ��&ڥ��6�ܼ�Q|�YtfFN�� H+�aީ�D§�(e�q�T�����v־�ؠ/�P���v�����%��.�~w�?j�j���u�t��7莠-�M>�>�UR�Y�"{�0�e�G�K��z���ԴR�J\E�N�	!hq��b��XJQG�H�QR��IB"�����)��Ma%�V��0m7�T�'NV���</,�O��ib,�j,��>�:5Q�<D��*�`2;� �+�R�M ,����[Q�6�<��Y��mwN��Ԫ���g��w������O����;������<�.�&E��lҮRi����hs��ʯ(��G�����6�]Lׂ�|j)D�1:��:N�K��*���:*@8��ܿ#�onnn����������JFϻCr�=�����w�u1b���{'���Ag�L��Q��"�0������xQa�ͣ���{2�gӅLb��,<˞ِ�@0���	%���z�,����f�DT'+���ȯ��T�!q�O4M���c/lL&w��2�̈�#$��Y�-���k:12�1�풳0�ٮ�'�궧��������V�|���#�/}�e<�=3&0^E���͙N#��P�L����~���:���~�}��_���ÿY�����Z����?�«6�lǢA��}��6{k��o>������?����7������g � a깡	��� �m��̩Kv� B���G����)�I�5h?���H˵϶��cW��44!F���?�<2�qgZ&q=�o�7�X�[~�{`�K��b����X�Rx�t�ocݹ�To�{h�p<�Gi%�f,�u��XfX�O�����X=�Dn��u�1 �L,�]z1�8��	/����aG�]�c��H�����̜*)9͌�'�F���s:8�B5���ҭ�
�D1N��ؤ�М3=���'�Ƹ�J� ����l�o����@w�	�PU	�}p��!D�է�y�s�i;�z��/;�a�wb�K�YzM�f\G[ ���[��؝��$˸�ag�栠hs7ZYWZ�rq �!(�\yQ3��x
������a��\t)y��x������FaP�a�%O-|N���|��cO=>w��ɍ��Ϳ���ݾ���/I�����+�	S�k�%ݕ0�@u��ٹ8��g���9��&cۈ+�j-7H%Q�ճ�r�E�j릺�\�[����"�R�oz��=U�wi�����+�px��G(�dq�����I�Ga�?�Z$+�f��M�5�)�x�v����[��Mu|���ۏ�L���'����{�.�̄����	���ɨuxÍcɌ7uy�ꠏ��oj��RA,�>���Յޔ`ã�X�K�A�DT�AO	�V��$g����$4��>���� ��ȋ ���pEy�Mm�sZ�B���f��+�EJ %�T��A�`��������GR[&���x�vF�	���f!. �s���0�izá l� ��i�h��˃��'*I��?�t_�3��*_n� ��$nIU���I�ıw:hwG%/r`��Vl4~����~�������O/w��,;O�F.^�`Ӟ�nL�E:A��� �2i�5Y}j�'��q��F%�j�p�V�d�%���Ǧ�R�W1�@���v�����$��ؿ
$��W@^����j�@:�l�:HT�˺�
�g;[��pCV���n�CL>���������Qw�@���qy*��$��c�f��db��r'3>�M�X.U?n���;��#9�sA�r�^4Ƿ��M�!�DT��[؆��4�x�y�0L�+[r���{���m�M��rp�:��h�N����8���0�IȚ�-Q}�����%�$.��
99�+f����-�)�ʗGb%v��l\�)�Iߜ��s*<�~�uz4�o����$a�]�^�K/IHj�0|S�}�n>z���2���*��}��_3b�&Өe�+�������vV�����k���o�w��_�t�X�%�p->o,��{փ�����Cym�#ă���F]<&^'.+�u�z��p��X���ۡ�g�aMC�ƕ,�ߵ�K�x>?h�F�!�^o4���	~��x-q	��rp�8�D�s �'���p~?/=�����C�W����ޚ\����(g�$�Sr����<D%?���t��5AlZ��B�ԢK�MB��v�y8<}6�u8�����=i�F�k�zI]�n���������g�;��w�������i�P}'�^������B�F�(�Gx�9�P�,}��Ŕ�y��h��k�H^���i1�r�X�4��D��CN���?��=c���䶨�*��\�3�|��h+G}3<3�,5/�U��T�.�E��<��πlQ5NWc��1h��iR��X;�5B�� A��Z4�)J��)�鵕���o�#�ݤ�������*��Z��!���ch�:�,^�m� c����:�xCܸ_�z��0�;z9Q[�u?�h�B]t�*C\�TjQ~k��Ry=�x�圆?z������P�(]�@-��P��^E�BR���`D�a*�u��v���E�L�$!z�x��D��+�F�I�@jrf}�숂LMp�BsAqa���5��73=���C��B�7��$��D��S	I��q��eY `}�9z��C��M�X�/Z�câ�Ơ$�*�b����h�T�>�aR�]��[;���:9��C�W��BL�>sL�w"yg@"%�@��A<�E$`���Z�Y�J��R�wY
K�-�u�W��B�y~�J썑N�&?�������G#qӐYˑ܁�lwdBРh�Ay����}+n�K��\FS)laB^]���	��@�j��@#�!]�8�s�I��0�q������|�3z��(�^�潙�G,2�# �����ԋH�R#y4|+3��d�.\�'���Ѩ�:W��m1$�W-T be� ws�ƎOT�Ƣ<��B#"���c��-vς�����bo'V�ݏ�nN���ǳ��0�I!e-�T1Μ5��)����T��:㵬��D�ʰz'�
�!<�����hq�nB^�'$"IT�w7�$��<��#�h��?ծ�s�<~w�g��0��ġA�%���n� �7JB���$�`ul\q��Xֺ�o�ιD��(�1y�h�\���Yr��ѥ�D��7%�bR�2@iȩ�⒏���t!=�+k�'jםy����(�b�[,ݦ���ΙoNi��W���!�Ý.��p���bֹ�1�?���9{���wh�rq��������B���d��Xz��1ƴ?��A0��zG�j����Kg���/�ԤM�y(l��1���!��d<<��{��q�(�b'�ljhwk��k:0"|�"�!S�0�{��J�_��%LM�*��F݃_�C7��o
W�>B�޺�ȗ�̄��2�z뮗���rs�w��Ej����,'g/�U��_���.�l6� :&ٲ0�\P7"5cs��w򎡭Xr�ŕ��;�{iX��|AA���C9�R�h�=��B�Y��s߉�S�'�{Au_�Xi��ޣż9�mQvz>��3�f_4��<�N�.ꉹ�F�%jj��i�����%���@E�i �3��DF��Ĥ����3TY��k0��-'%�;E�����`��]�GQA��^�]���k:��MW>5Zپ�lh���y�`Hu�=�moB�!���{��]�=.�	��k��W�m�d���c�NNVH/C�Rw��S�0`��dX�D���v��!��`s�%����H�6by�<�3�,
�:�X�z��b��-���:�C��#8�=���<��@��C�y���Z{���N`)Kڹ)��]��=1��/M'�F��_k�n��o��ھ��I�N���J��m��;'���s�$��:�y����KR6����}��~g�b����t���MmST�:Kߋ:��_��ނ򻥦r��+҅��yd[�g����*إ�A_?NMJ[�N�f�����,Q�-��ᗉ�GB�"�9��7���ކ�/!g�;�ty����~�HT�Q�5y�>��%J��}����^��=��ݭ�����Q4��?˟
���>�Z%G�2�R����ܫ�aVILX	��a�ͥ�D��x�]�}�\�ةծ{���/�������:�̅1)��A��vԍ���A�j���io�r�*�>N��L����,Iƛn(P�� ��T�����:�z��4��X�ڃ��p`)�dc�Tɑ���(q����O% �ܹ�v�����f�.D�	h������-A�]�;�?D�D���?��I�	��g%�9�IGޫTc�f|� ���ž;�(I�?2MB+�9\Z
���/����'؟�Wa�yV�	��/�%B u��X�K������������-��
��F����pi�K8���'�a|H����q�$���d��s�|�$�'���-�f��N����)��.�8=|��Տd��R��(��~���P�7��#�+ǵBgJ-�\<��Й��w��f�h렇`-s*��G?k�p���F�|�A�p.pZ7"�j���u�U�$�&^�{)k�ewd��jR�QW7
�uy%�C���0>[��Z(�͂&���^g������6�,�ye��Tc�Z @�Ң�J�d�y����t �@�*��(Ѳ��L�þ��>�>��؞KfVfU Ҵ��CDH�~9�y��9�Q�p�_͓	�Y^��@T����?%�j8F�6�8�����	�j�泵~1#����r��L8���-��-������ɐSBp��rp�ZУRЏz��.$�54Z�є� KJ'8��C4}'`��T���
�V�A�aѵ���2����$���g�������R�/��b+�����Ԙ�B�W6洽/JT��寏:'ϩ~�v�ioV?��'�¯�3��~a�\9�Qٙ��ՍJe6B�kT���n����H��(�����n��ξǪ�~��Ws��Ć8sj�����y$�V_��(�QPU�
����1aN(�TM���B]�ǋ�O-2݌T���f�.�	8��w�5�;ȶH�H�#�d��*�E>��7����M5Fr�g�^w:��A�!]c|�#��pZ�}�2H��3b	��`���WIo\��/�{?��H�&�;^/Ѩ�_a��W�~��.��O�U�Q������q(��7�i�g5N~� Ԏ��Ф��������J��W��?�'﹄�'[�	.'X0��ɔ�*���ݫ^��Pu��Q��`Yt�M��?&�LA8,�Á�UV:|<يhd�+���+��}�
*�BY�Y��GbB蛊�M�Y�d�=����f�M��������FT�_���@�e��?��'�*�:�a�!RJ���J�ɤӉ1b0�x�i��"=_e�t�?��Q@�Hf��³h<��R��g�ĤY#��/}A�_��,l:Si1��ؗ�K�3��QۿK[�!���:ټ��e]�s��@1�L��luܢ�J����*؝ڭ껤+Ye�Z?�Y��pw�C�o�zY��M*Xz�jj��+�sV�W�O�}�M�Nz��	���
��"3�Nþy<��4Ar��Iq�)};%������a�8�-��L�w� fk7R%���(�274:U�1�����J��HF��-��ImX������)U)�6�]F����[���Mv��jY'M͞!)�)dF,����P�/r���b 9y_,�^.�x�O�I���Oo}pb�+�,��ܥ�ȝ�LDN���TĬ���*I��	4'@��&D�������}6� ~��m�9�Z!a��������36�F%+�|�T�B���8�.��ǒ��ir>�Y��t�H-� x�ֳtz�!���/��t��c�]��8';����[�ˋ4L�F��%R~�y��Az�	F���V8����b�%,d�̨K���̐����c �'(NL;<\�$�"���A��+f�	�JGs�����i�����������m삖�����1�q��yc��"%��.������J>����l��Y w�'��Z9S�]���4H�Y��%���6��FfGn�#��Q���69�,����|{��17�Z�����.��]N��e^i+��F�Q��(3��N�9S�+د�)h�����ig{w�� <�B,��n����T�v�b�;�[�@�ֆf�z���/풪��W��R��0�N�"��r9�K�U���u�t�~����,(�n���I�ٔ����1+Љ)����n���5h߷�!J��H�gHo@^#�e9��1=[O�:V�/'aCӜڊ�XC���&X+c 2�ٺ������w-�׏�K���u�ms
�Jɶ�Sy��H�T*q���eB���]o��������4�)�W�A_?n���Z���j&��� ��Y���� ��$7*p�,pI0�؆��|���^Dh㺲�?,��[z��D�1�XQ�tB�fD�xB"/诫�+���:�ҩ_�۪"*���E�ɑv�F�Tvdҗ�*B}��>�:u�
V�<ƬUf�<g��u��?�<.�+����ѕŶ���#j+5�^�����a�i��'o*��?��^����?V^�FWQ<�
���$��}�-ūc��3��n<ksS��iJ�k~��/}Y�!����a��*ڳ��/j�6Rԋ�싩�#�5:U�´�1̢�%����-��&��:Ҕ�M���P�I&(����5eY����	�|�m��t�	�6����,�����˷a�*g�T�_���૚!_�0_�%�_�6�(84�	i[7m�?���J��v�ST�qΧr�ZH�g�Nz]<cZ_5�83h��8���Oq ;�g��[��$ܤi� �C�/�=�.�N�.����V0��r"��j������MFY٪�����Wol=�������}�����*�ۨ�m�7����k�0�,����n�F"�(�s��!`���+��Bv��{��A�,� Y͗�x�Jo��^��ow�{h���j_��M>���o[��V��z~_��lW�����vk���6 n3�뜾����]�����������&W@��G\�*��mY	w�z���J�iV6���0xu��Y�"��$�����{`�D./�C궫^��'zĈ�,��G��5��Y�����o�{���}1D��hDA�(�"tj�M�FlsK� b-|��`_���K`�����?�N��/�z��tK�9�+���5��?��<��)"���V�c�IĈ�+��q`3S�r*K䕑��x�4 ��F}1�E]`��r���!������ã�֪c��!�ˍ|=�E8����	f�愌�ȷ=Th���i��`=up�Ⱦ���|��+<�q�KA|�JW��F�<��8�=����채�v��Zy���:�e����/���%2�5ќ��
�o�<Asm�E�_}�D0��b�ӭ%O�ڋ�
U�sV�����	��jg����nB��x'��ˬ�G���m�{,����O;��nT���ú�p��0-��e�Q�	�����y6��J;�ZW�>B T�$$,��<h��$iR��K�x�䤵��i�w���ʙ�l4Q��d7�JVΒ����IZG��&�T�VSgy��dR�H�X@�8��H%r/��	ҟ�B���/�16��;w#-�l��9#u��P�,,j)�e��០R�&��b�!��	n���h��GK(��@X��XX���Is$��Y�o��zÊJC���u�,o�P�3S�h�Z�U*���#t����K��x	l[)Ǽ�0Q�l0Cf���@8h�G��IW�8�D\G{&��^�O��ų�Bް�܁z�`;$'h~%�� 0=�1��{�z�xƀkǹi��O������
x��%�cj}Hz��#���Ol��ܗ�
@rԗ(2�-�}*�˔�ek��К���K��F��+��(�c$�iF\H��E]J����0�8#��d�0����2}&�u3����k�Μ�nFkj�Ͳ�*��#�^{�g������ۯ'|�n&������ߕ,��fF��X%�0X��x���Gi�`���J�8��� ��N���>!b��l6��I83���1&=�ț��"��}�\�ĳޢ�q���+���09���Z�"	���Å�ӝ�v���C�����ɴb�����/é�:�9uDr�
����>ų.X���$Uj�=Q��ąx�on �Ɗ�NzE.�\I=��vN�����)ǐ~�y���q_D����{+� ��f�uf���I�t��l[J�x'��]�?_��!�Ox+l�K�7~P�	�R?��Y�@!#�ɔ�Ƌ��R/�G	م{���)9(�YUe���#�a������#M
g,�8LR��R�2���V�R�����(�a�ST�����] d�P��>V�z<�ėU�� �(���C+���X�9�g�$󅹍�� .p���5�3���|������������|ܸ��}���n�K�nI�K:zy�|}[��eA��K�p�b�|!�ޥI����M��5$p6�d$;rc�e����ֻ�&�tcڦv�i>z��{����{�����e�;7�q4���"��I���*�
��40�2<��k���x�:W��(N��e;��c���>�I���w%?�r��cw$���5|�ha���-�*goi�G�wXd�JɂD�
q�HI�,�t$����Z㗆	����zn	�b�J)�*]Me y����'����G��}��
[��i��#͖�Er21�eqLR �L"���U��,��̯T���v��~�3����Z�M7��η���������� i�%]�E�!�^O���oO�x��%&�V7���Ȏ�*���H�x��a�Sg	f�˿��a�&����(��fU��7��.IB*J OJ�5Q^�O�_�
p��u�n��Rh�>��M��H��h>��"è�!RA��Te�/=
Fz����\A�x�iD���(i #���J�b�ū[�q+�P�f�D�S %�9~�.�o��ꃣ����%1@�Ļ�Q	� �쟴ڇ;'{߶�o,��0�?WC�*rk�'C�6�t�YX�E�F7�	;��H�	�lr�:�5�K[��KO��ĥFC3�Ս�=b�h�Z���c��Zx:5�#���ϣ ��Q;���?�~#dg�^�>3�`N���\}V����3�y��ϬhEɬ�b8�/��{Us�)��[��YB>���hϽJ�w7.�YV�'5Fl�x�̦�	G�'�,A�k���T� }����jo��
 �:�V�
�2���
�}�%+簧b8���6ߐ-0rAN����t�B�귑0�"���%�VG��c`.���qzQ�
3ax�y^���@��.��1���wiY݇ʃ�l��p�6az*!gOG:�����E�hz�a�L�H�ɥ�/���d���r��#�2"����sFh���4��JJ�x;��d_�z����N=�8a����G��$��O��3A�`6�zC�,Hv9�����L�uq������}s���u- $}�4�oS)l3�4��V���C'p���l��/��b	��P�/�C4;�!"�ѓ�G���H��òY�0�٨3O&�J�%�Kş�+�V�������ow���/��t� ��B�X�,��G25��K1������-�����b���$����P�d�"����p�\�������H'mg���e���&I���w[�Ίr��9k����^��$��\{�p=�V��7c�2X)R i�a�g�U�f�+I�fC2;E�-ݖχ���Z�Jݘ���TIS �N�-���x�E�d��������d�	��a��e�2�e�C��HX?G �V�@�:{�ɝ��sy.�4�(���{�Ǿe;ؔs`���Z��V�-ays�بb����p���:���f�m6��\K��N*�k�m�}���(.+,*�@���uL��
F�,�����m</��Y��f�=٥�>�T#Uu3ԁ��{�[��VF��sЂ�^+�A�G	m��q��}8�B��<ұ��aӥk=�9�y�jw_�뼠M��h���u�E}���p��ܢ����S���*�xV��L[	�Vͱ[Mm�$b(�{3E{��G<s�oé)�DY�6��E��33�33�:��"\	���*���]��
.%�(�m���o�tZ�*���r�P;�����
���ʹ�gzk�S<�tD�y�-Hgw7MDP0�Z��5�����%���qn�w1��#�I�(߾��\����j�!���B`��p�G(5�g,`0�;�6Ԧ��']�[Qj�b��3��Le�¥j�3I� �r��iv�M��D�'ۋ ���d��<�#1�j$QM���CϜ�RO��;Z����~�|����!��7�w�qm����
D4��� xK_9��}A��y�f��<U	����X7Җ�e�/ ��� ����,��ύ�E,��*�tjj��C������$��q\���Mf���XX~���74j���<��y�Y̿����ӧ�Ҿ*#�n�X8�ѢL���9Tū�v��I��=�.�T
MO���~��<Se/�7���(��3l���^'tET���Q/ns+�.]k��Z�V��f���7��aC=w���&	�B>Ρ�,�0
ƨ,�̐�e�,��c�������G䃝�{ȓ�w�w[nn��@Ր0�+��#\���������$U{c�D�41�&������$�<�';mɢ窮���~�.ds15����SX�6gE�&�s�
�6d���Ilޠ5D�C����Ԩj۔^k���]���`ڣ�Q0h�5���0�g��C٤��K�!����F?E+�s3�qt��<��f9����j��a-�(/Ĳ:�\���~V(�T���x��3�(�7�r��I!��[�kƕ��;{J�&Q%����۽��mX���<���G��w������=�҄�y}�ɺ�Cg�A�AK���ym��L�xHr'�3��V��0&�Q45V��տ�AX�������-�����|�"ّ2��9�����j���w%�"5tY�T/���AX�K�lր��	��]�ԕ�1_��Y2�/�@��cLʦb�E񮟛�-M�V�]I��kuA�Mٰ��1�)H$��������9_J��<�V������"���u#�5�#L+~��yI���w��ʌs��Y�j��x�-�CM������[�E6#������L2�f=/�rSt����Lջ�%�^�%�E��C���V��K�V�����7�ǿǾ�V,����t{7D���l|��j��o�q`��<��։_����|<9��Ț�xu��/QT?�ƙ�x���P�u}�ם���̥N�a#=Ua����p���t�d�`�K�*�i�`�$�y�whX��ucѢ�.���fc�\
��z^�I=����ym�H��ut�-��45嶼e�X45�4��V�>�J������ �\f˟�ˆ�$�V/sy��!et��}@�.��'��׺�,h�*ba���W(yj�ݢ~7M����m��V�6S��"ZQ*���IŰ�fx��K"A�\�~꛿�m�X�>c��~��JgV�!���R�P��G���0����J,�cǹ������r�V�I8�Ce�CY2*��8�t#��&�&��XU�3ˊ��n9�~�-$c�@��l�qS�,��v&���x6}�~�va7�+p�����N�ߧ�<��o��) b_�C�uq\Z�a]1�w���%�\c�k��nLQ$|#l�>��$����e��u���eU$���2da���_/ �� �*�)�� j���!e=CqJl�M}�{���E�4�',_V|�x[�W,U�?��Yj�Ȫ|�C��mxy}7嘀=`�X_r+Y3�:�H0�ƴ�����6]�z��#�]�����9)
����� f.D?��T�����PM*Lk��=���˹�,��b��b�I��@�2bAx�K���	��?:�ʄ��%A����T�D��ރ`�K��Q���uݎ1�L�vR���Z6d[�<���/���-�1����)�)�珬Q�@�p�]!�	6�Ó"�ϴe�|�4��$�nv7�3���K�%hN�����ڲ�i���v�����fΨv^�"���(����}['���ut�[�ߑ��ʩ��l	�6�J=�7�6���Ȍ�g5���ΈϬ4+W$1!��ʙ^/9�ݙ�ԫ�̤;���3M�m��tFy�`tymw:F��I����o���B��"v�2�)�]V'��2{��3R��D���쾚�O��GMC����T�M5��>��Xt�A\Z�g�rx<��`�G7�����������ߘ�2�ʍP�T�hf/4T_@�˃�{��� r/�dk}���f�2lgڊ����_���2[�7(ω�-we�b�U�;T�C�ݳ��5�n��mw�Y������\J� ��zsY '�Ć�DԛP�ݓ���y��%9��������-N�ל�qq���lI�>�5��^
�����+b�G��8_>�(,��x��`YU	i}��-���KV"��`|4B��c��*`e�A�L]�KtF�M�2���^�tw^�@݃��\�K��A"�x�˵<Rs����n#�z%�a)�7�R��ƍyC(J��vb�p��cܟǈ@C�0#�}b%�$�Dv���V��mD#��m����˟v�!�HB?x�Ӓ������9'/{N�NBVأ��d"�,�
;D�^���s1����%}%B(#�� �ɱ *�#?�E����Hsl�Y�n(�hg^�q�����L��R�:��s^���<@s��<սt���k�/wʸΘN�����J0Y(k�����������������=��=��M�������(~L�S��'O�%���w�\��}��z]cֵ����և{V��n*\[�l�e��Q�;�h�AA��P�N=���Y[Z|�ve�WaTa�?:8n����BC �w���������t����)*�"��+0>D0t�*paG�i����k���\�4�)�W��X����O��Ϣ����C?�����1�>��>Vc��*U���M�����9p���EC*���sTn��Z�y-�G�3g��ޅ�&���6���9���{�o���㿞��)kJ�Kb�:O�ĸB8��˸|K�d��Bk\ySI�x)J/�
����y�I����VwXĸ7�q���q¤Fl��G'{o���p��ji�h<�.�a���=-�i�;���)I8 ��+���=��"�ӷ)�7tG�T�������=;��Z�'-�,O�p�GVϼ����2�ͬ�n��ݷ�ݝ����4���G��S�1"}�)4�i�d"�k�ƱX�V�>�O��6e;�-6M������x�!���w7E�@`�Gq���?��[��,�S�gӇr��N	�KԟT7���I'�,���@���ҡ	j�%8ܛ���nӿ!®���
�Jb�(��B�C���kn�Y�3�e�?�Ś�������Ť�j�p!/R*�~Z�c�ǁ��#����|srt��c������2x�C����	�N�rhn5�!�ø��zA�]H��B�hZ2~�s��d0
���,��.�S���8�X5���3ρxc���-�rx;zh0���?�Űv%[�T�677���	[�(a[jꆖG�:&c׌����\7k�R�J�Q�gٸ�Ϟt�l��FfI�ͬ���<���I�^��^�Bj�v��l<��J��4�f2�y� ,���{�L�V�o�6�b�U���u�,��JZ�W�B�޻=�\Bx�_S�w{�M��L�-�)���.�j��X:�uY��f��9�d~�*�:G}��ҩ8M<t"Վl?�"�GfM6
dM4��J�!�.���9m?'!p��\@����wB|}��eU�;@��ia��{�-�j��4t��a�B@��J"����,<�:p�Y%����<��?��)Z�t����=������
�jq�/�����I��J�f����gB�I����1���a��S����j�v;\��6W9z�3�୑���n��a�ES|]YK{j�8n�3 R���y5��	� �5D�E$���=
�z��E4��{���HY�k{��O�gB��qӬ��XT�ad�܄T����vkg�J�{�YO5��.L� ���Y��8:�1Q,�1�)�t�`s�͉���V���;JO8Ϟd����Z᧊v�Z�Z�~%޿��A�%(�t�'b��Jo��Gb|?���9:h�n�Ө�
P=�4L�!��Q�U/�0��g@�
A5���4�Lj��g�X8��j���b�o�<��B���N3�tީ1nH�V+�aԻ�0ź�$=�X"N&��_��z�Y�r�x����0��}��tw��6br�����A_�B�x}|��'Tn?�ܔ��KE�O7����o|tI�
��������rz�n���s�˫�^�h�w6n�1��R�+h�;�֬R�Ω&�����	��/�R�z�<����sN/&2�C�XTu0yO����~4�0ر��F9�$��5�cͿ�&˟i*�U����� i*=	ѯ�U/zM����&0��v�m���۝�����ݵ�
C,i�G��'*O�y��x�p�p�D���J?�~��r�6+�.�������Q<n�_�F.��4��4������s��WQ5�q9�M7�o�{)�p����dv~��i1އ��8j���a0*�l�PW�܃�����tj`_*�˧m#%�`�B#*����B
9l���L�Cb��C�n�5�h<�`}YX�j�@ؤ����+Ts+i���wO&ҭou�$�����=2M����TH ��jk��K��D!2.��g��R!�;Σ�V��I"��8,�� O\ yJM�sz�d �nA3۝;F˲o�E>+�n.��5-8�W�࡭�3d�����sht��ISjN��Bc�v!ۊ@��q0��
���G��7����)s\��#�r��8ְsh:�ɻ�2��@M?�����g�٨}���uk��S��3rWۭ������$�ڸ��M�1z��^�SN=E��wSVG�h���nA0�5�����z������d�®n�ݙ��
�.�=ڪԻ��a�"V�.�A�|nM#m�*��8�6_H�]�����K�G���s~!��*Φc��K�ƾ2�!6�w�����ǓLW�f>M�8�\�P�	�z�*�~��z�C���ҙ���o��j����mj�֘��=i4�s��������=E���ŏ�d�������*����-�)6+�
�>ã�`����4��4���F��F-Y>k6��&%(#A���(�BQ�L����N���|mq�q- �:8�tPZ.��,��G�V�g�J�-"��������Ή�Z����ӃW�vv�&�N��̵d	�48+6��'պ��e�Fg��/��)֡����īk�w��-�m?�S�g	)�L�S�G"�:+Q"44
�N2e�h*�
 ��@����C�]`*������N��B�Rs��޼���j����ߖ-Η���o>~���o�����-�����A��d��DBT9����9i�}}o~a�O�G����/��֍y��
��5�+<��y|�P� \�,]b��`<�$�C�3�LuL��f��$��T�>��/��$,��z��%�9�x�S�3�s3�k���S4iڀ��"'�*gC9.�^A{5H��.JB�� we�T��̣ $m�ጓ.Di�B��Cڭ,$�=�0�����Z�B�b�vR������Mg�+ 7�n?D��>Z�=�>[�j�ͬ~�b�,�ժ��J�vQ���w�4bSF&�o�@O���i)�&�ˤ�VF��6�$F���J^�c)-�Z~|��l/}�]`�|�]�C�,G��k��c�?!��Z�e����)q��d��A@�7�.��2�6��
E��6��w=/*�yYa��'�y���i�y��>�&���'`Ȇ���p�j݀���.���`$*�Eޒ:�OH�e�)�(-����Ѐ�&8!��(�X�fSL�&Wv�K��N'�D��	��6U��:т=�yMG)0nr�ؠX�%Eh9��W��*])��N�B��N��T�`�S�k�x�E�ֺ��O\0��r����Kf������S�a`;� �;��E^Oz� ֢��_s�������q���_������umtn�*C+��]D�_xUg��EB)�T8o�`3k�KqH�gu��=�_�O? ȓ)�1�ǁ�{�����x�9�S��LvG�¹��&����}�UCc_aQx�OEr�N��ҏˈ�4��}S�Dl�٨'
�:� ���E���l�p.��6��.G�����!��NUd�Qc��>��D���9P$!0��D��U�B�?�������!� ڟt2qP�J���C�\(�)"C��bqS�o�])���]�z��~�N���V8(9ĆmݿSl�2���j��4��o!�:%���A��++l�Ỷ��C`��i��ܿ�&����B�oP�����Y��ޥZA<��·o�	-�s��}���n�/��^���<���.��b^zh?����կ�i%��p�>��ț2�]-�O�x,S��K`|E��(7DyK��d��qw����)l�N/��Ig�Z\�(2�IB{1�`6�{�4�3)A�O.܏<�����}9�`o)�ҩ��Ic��xٶ�����U��c դ�>�!r/1��|0��. ���@vrB�`�[��%��-��\o_$1�+�Q�!�Qr�T3p��f���v�` e�R�fZ��:�S�g׷ _��"��Ⲡa1�f�S1$Ѣ�0�3z;�VB�T��&^�bu��e懔W�N�o��	~ ���ݘ�2xv� ��}Q3]b�HȞ!���`�]����вJBM��D�p��D��DW�.9
/\�*�F	��tS��']�!�J*��W�U�IuJ|���E~�E�'�$Ç�F����4v���se1��|9@�a�����O�Kj�i��y���?������K�?����?��������o�;|���܀�μ�nn<���"���#���baUO��!A�	�U���Rԟ��P%�����R��x�^��8�9hy�.͙N:g��(Kg��踳���֜Ǟ���ٿ?�xŲ������]���ߘCx�$W"g.��d� n��[�̊��ەn�Y�Y�|3�Vxzò���N�W���V�u{��YH��=��{�|4�އb����"��U?z��Y��e(�<L��ʩΊ�!(��2W߱tl�_/3^Br�Bj�}��r���P
���C�L=E��8�5_���+WPU��Frr6�YS�iT$�<<�gjB!ןrj��7O�q�Z�4`,�W�fS��~��{������⡱=�k$f� V�S�x[�P�KG]�t���P��,�B'ɚ��8M��2�@���<G!]2����]c��Co<�+!��Jf~�[5po���ε�쬶8Sڭ���c���X��p�2f����Dq@@�ä$�hl�H$.x-�L
�*��H�\�h���|}����<k}
莻�{7��Up�����/������)?9@haR�� �����֓�w������l �6Ӂ@��#�7b5�]4B����gS1
?��0��>�����AO��H1��ݰ���� �<4�x1y魼H��xt���]���������b�T��!��z���*��uࠝ
��0#�cyF�0#sB�f�>w�g=���3�g&���𥅴	{�lRM޽�A��,��j�yLf}`��C��qwN��oft���nĪ���Tͬ8����ؓ�zk����p4	G���^_ 3���������n�R )�K���Ť7|��T8���Jʍě�#��z�&O��L�Wa��:-�
��+ދSW���脓)јxVDe�zi��i{��\up�AF���[P3���R�E�e�š*�"�x�J��Y��/��L��M�2ZPZ		p�� �r0�t��0�J�d
��}
͖*ڠI$N$E�1����Š]�oQ&VGט��#�0R=X��g�;?�ucFo=�P��b�l��m�	5QR!M_�yp�d @��r��>�zZ��}�|P�#�Ix3�/U������������n�o��K2��dj7��vSEߜ$p�i�͉v�3�n�C�3�����3s�haf� ���Ԡ��I����c�&��˖���Ĵ�Yp���݁���gR�>&X�-���ӑ>�dh��b�ZO_��.����V-48�|�?9�K�������ͧO3����^��E>~5:O&���&�V_�@a~E>O��^�D��d��>���Q��p+�֥/&q�ȏ-��#fVeԨ>>T���e���"Iަ�i���}��4F��Ҩ���:�Hsj���#Z�fd6N��ޘ*B%�@w	(_�w+3]��۞1��K�wF N\ͯ��>Ha�b�+�9!,��w�Q�D�|��7������e����"o����
p��2�/����aN3G�/$|������z�[����V��`vM�捎CH��4J>�	P����vS�k����m��~@� �t� ����S���2c:w���&��Q��.B�ɢ�'�s�_�h���8x�o��!_:�SǢ���Uz�Je��>	���F��cHD���L*(��������4��������2���)�>�z8���,��QY"JJ�q�D �$�9*���x�Ð���x0@�B�E�4ض�(l<��I���|%�8B|
�X���m�����7�Ļ8�p"��bWk��z-�r*ZR;����eƵvkg��d�T��]�E-xI��㋋�Aש½%���w�
su�ΨG&��a���jB��_	����]�U�'K����H��Ju�"�D����ʳ
���=�"Q�x̢�l.[6zW%������*��DO��Ȣ�!��`�'<�x��Aj�DVvy�$���<Q鐠q� &ѣ("Z���9�ޛ�&֑��hؒL`J�ĥǛ���,xb�?�����L��h���*@	=�1��䟎�1��FGK�4m���1����Br�\p�'P�F$�Aє��������X�(5�P���^?��s�����?�������s������>��!$� h 