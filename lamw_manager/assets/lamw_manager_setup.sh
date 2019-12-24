#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1113448579"
MD5="b69768293699e30f34c5ac3672f0154b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20356"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec 24 00:12:04 -03 2019
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���OD] �}��JF���.���_j� h%3!�F��C�Y��"V�p��	�GӉAt2�K�VMGw��|������l~��x��	�� �B��!������,�d��b2tlbWK`���ߍ/~�fF3�������`�w�p���ں�'��$�����)�������g0��0��e�Bj�3�X:СS29;&�"������ޱ��>DS:���9	:��[v��D�Q�c'��UM�M'`����1�J�bhwpD�X#���]I���
����R	M�����:a"������1n>�IFe�U̝l��.I՝C�$FxӇ��/
Fm��=��Y������Ĝp�â#⨋�F�7��yDf�3�9Ğ��_?˭�0�	��E�����昁��%J\�&2�f3&f��(C���]c��a��Hi���l;f���h/�סX_9��;S�?횺��)����`dH�t�O�0�mU|�J�z��xx��7uZʭK
�},��A�����E�.Z��p�<1��-0�#c����=Ja��O�']� ���lsgcB-DD�1E[b*�bH�T3n�tGC�ʓ��,�4�RA]�p�M>r��cվ}���&	�� �e�3ڞX(h�)���N�ݖjժ�`r��9ծ?i}��K2��j�l	��<��ʏ3y����4f�H6�%�P? 7��!�Oe/�S5��7!|?�UZ����m�u�d��paL�{�>L�>�D�b�2W�8�<��]�[��)��7*e��0= ��%��J-�@͵ O��	ƕ)a�kqi�l��I�
�T�r
���6;]f��t�VZ0�Bb���n-�$�EO��;%�tS2�W}��S��Q�qF�L�^��{��2���܏ �OzCx��HM�S*�Л3){�s8�^OL<�Q5O��u���=�a����
~p9�����M 9�&�4p�]�uF2v�ԟt�dLh�BԸ:8=bf��R��(����Az�+�A!��������"=y?I���I�?Z�ui�ql
��FѫqNuEل�'C�V\�W��S}�`;�Q������QM87-�q����5��sY:���s�ô�u��\� W4������ƻm��y��g6��;M��ב]�N4u�p"���ɻ~k�� J�����gY��]ؗ���\D�����k��)���6��F��^���Š�����a�2���k2��&8��]4��,O�CR�����7ȿn��'����8�忉�Z���os¿�#w&׺eO$\|^�IH��������XB	L0;q��6����K���&Rِ��2r�ǛQ-��JmoҪ��/C�G�������sQ4�M�۷��k����s�!a�`��ӄ�Ӂ������R� ��+�:eS܅�B@�j؀� ��d������7R�H���B�"S��v���	=��Fu�@�^v���B~;�$[w-H^� :��Ԅ�u���A�|�*Y�m�8Ě���a���|r�&�XA|��On�z17���>�o�B*�0 ���\��T��Έ	�����>�	y�5M��[]��Ѣsɇ$�Ve	.���#DV]��a�qEt��?F���hYt-�eD6b����^+-�y�W��JkLč�/ø59����ӭ�/U��p�Fg����;�
���[��D�����M�;(�U�"x�&�Ur��\i'�vV�1��\W��q�Ch)uh����+��y.�F���Gה�6��iH N�V��]_;����U
w�d�qLHp� �����h�� ��*���b��Bn�F�t��aU�T�������ط`�Zcm4�k��_jZ!.HA��uJ����&Ŀ�� ���W2wi����ɬIbk�:O+?�	=�� �)��<�b��xv��l�Y��(t/���D��`08��װsU�ÿ�?9�aw'%acm �����RDq��`&�aԠ+�;Y��b�P�0?6}]B ��N�Aom7������P/�J6P�_�M�do������<LBKB��]ѷ��_��G8���@�4rR�X�*������ݛ"��a9\I��Gڬ�y�����oc�.�F�EqӤ�P�]W�]Qi*��V��^+�� 7�)^��U(�D�#��V�6����f>��;g:���Ԝ*�XaŬ��8F�gF�%(�0wo/Ლ0d�CP�*�ٞ�TG+���wsF����V�$�\Roo�W;e���$ �SYI8�;�*�r�\Z�}� 5���1�G�@�I��ho��P��o/v��o�s$컊�����djO9f[x�J�;On|P�l��*�8��q�"��=]
�3݃��O���T�:} q�sx���Ҟ�F��M�g��Z��Vؓ��;�ؾJԵ��O�p�
rF���!$9
�?�H�_H�(5�L�#{tT��D:��:y:�F�QMp�` S:�|mZ����D�S��El8��f�z=%�b���xBM�Ҩ5���ηԡ�*��EWHs_�Ͳ��-W7�ֲ�n�H�K��G�t5[@�wY+�����b̕gKU
_��u�q'� �J�KQ`ZݧJ�|y�nD��Ƣė�	sJ�Ci1��Q� ��1܆%|�'{CC�S9���kl��G���5�!���,���S�7�x�h�G�̅�[e�\�q�P���}���s^�#�|��
+�>tG�}g�gb_(^��4-�MiK<?{�����;2�IS;F������b�<+���Ҹ�v�3� *2�Ce��ǵ!�W�cS�sX �:���]Ҝe�k�5�V��=�&��M��H�,=�%ą�+<c��w�O��6������ݷ���'ܙ����g�iH�������1�N��1 ���QJ�sRQR"�4�O���薳b��2G�[�G�B�̤#�a�nGȼ���P(_����X�)MC��9h�Rs�����ݎ�-�q���w�����H�J�b�{�&���>��0�t$�b\��/=��;�[4�.㏆M#�|�H���'����FI��
{��֐&����<~�V�vՃ,� ����Z�P��������!0��Ċôv*OM|�e�8��)5�v����ʲM~���sq��3b�ۑI��Һ�-�����/vk������Q�-�
Q�9ȾzH��0���oH(YLȷ�� 8�|�����fш\̊�j�ZgU�@�7��egɥwDKd:�����j�w�p����7�t6mz��e�@�T�Xs�N� �csN�`h����C��L'AZ3~�x��,X5Ct�RK�k/����ؼ+f�2C����X�%����n�Bx:@����~�5��^¤HJ���!�6�
D]��蝴ȸKJ��6,ŒX��)� IԵ�愶,~
�7�/�#Q=�_c���%dPc�0�ޡ�4�y��ֱ�����Y*
5���J"Zi��:�JF���!����1r��:a����f���Nl��j�.�_�5n&�M��Z�E��Gp{�dIP�yu�����+���ث�=6fc��H.�2�y��(scq	�I�x�r�we=i�}#�?�]фᎌ`�C6d|T��ǹf�|iGH���W�AR���Hs�o��2ƑT�������mQ 5���i�*�����/�Os���D$.��a�Z��C� W�q,����od��
���B8�:�'� G,�}&�*�ʙ�
-n^0�3�=�	��nr֨Z��[�UހPoo��^���Kl
 �� �=���,l#��GX>~�<���O���v-���v/{@'J>ҡk�>yj�T���gAB��^���Oe��)AA}��o��=8�8�ңn==Oi��}!^�a_�H�E�����E�-��vb񖯜Qa���o����*����|�u5�bZ��,ˑ@�q1������Nc�q��˾��		#Z+YyA���!�������s��3}���hp]䑩�<��hx���E�|���u�#� w^��[���4�2��
=�T��Y�PI�TA��:�Ǟ'�ڻ�Z?���뙮0�z��ب�/�<Zk'B�A�h�Ep�IG�U42Y$ 3]��*�"������(��MU ��98s�N�ЪRF�N�'k�m��� :
���N�P�����g'FǇ��VLo�g���&X�}k�<Q��o�Wi}[B֫f��7J'�����P�~<���
+;�>�ۙ�����\2����> LX��]���NjE�8�_Z11����\��4v@ξ��K2
d�_S�& ��ڔ-`���a��{t7.�#у	8�fH��P�I�#�-&����I�9<���X-�xv� !c�{8;���«P���4k�OfQD{�ϡ�,�z�en�4Ł�@�>���<��hܾ�A�DF7�[rQ%\0}��65���p��)�L�{͇ĺ�g2���*�kmBG�A����'��L�3b1��R�~�8�M�^-"6�jV�_��~A��mn��,�	�Y��yg�k��#t �����,�lq�RmG��^�9�
��*�&��g.�M(Q ��u=8�R��u���y�%�w�-���[y��Z���������t�.j�e��*u6ӡ!67�?��Q]yBB��Ls��̶�m������k�|Bn�~i��$G�TS�*���rW?�%�;d#�z
�HO.�_�!�Rt}�mVi8�)kJ���G��qVթ�"�P{�3�kR�LP�7�o�[l0Xaw�ڠ:;�S��R��7 �5��;��R$JڇC&����Q��R˧�!uU����C[�%.�Gq2��_��&)�㇆��?����o��C�����FP�aB$Z��������cw,�hM���>b���ɡ=V�Տl ��mr(�|m��G�vv�ڻ3GKw9	W���"v]�ê@J�n.�����`3��'�d���h|Z7�)��/C�J�h;'\�ff�@Z��W��kD!��k��J2l�F�Q��j����5�.͜c��a��
z0�CZb��5ԁ�#�l~c�<k���gj��e���WD�zgYțw��ը��I!��3��i/��H@��0�H�N�A�Z�M�`vQ��=����.h���G�F:�Y�e2�-O�%{��]\J�D�W?>U����G�L�C�p�v6T7�|:� <	\���I�ޠ��k���� ��s�2>�R�����4a��zbi||V;+�s���I��7�r�8{� Ғ-B�{ҁ����%:�rr��������`�F�oC)�bM��!�G�>k�U/!�O���H�SN�D�x-�� �ᒵ�>���ݚ��dMq��D���q�Æ̍�����1�U�~�v鰿m�=0͟Ķ�0|�
P�|��M�<i�?ZǼtN�m�!���cm��w�kn����Hh��	�S���-3�%f�%��6���W`%dk��4�1-�&�yq7Y����0Vm�zB3`靕�̮:���V<��޾�+E���|�_����yώl��W��N��0��r,w��K\��lP��<�T�C5i���|��5<���2�7��]��WK�F&��	�RC�.�-ɞ�a���c}����0{��|8{�p� tWWN�3�)���:w�X	+���,hl�3�p�i����J���P��1����~ʛ�F�0��z�,z�G���q�+V���`�'�J݌��س`�_(ۚF-�䘿A��M!�V�>\�X���*��!`�f�S�؁}2�5�����.�j����uJ��_����@WʹeG2&.`}�#&Ēdɿ񹂯�%�ߪ+����I�(&� �ΌMv�(ᕤM�`�)9����C}�=k^�3=�#����A5���z����jS�3#��֑��C�Rn�P�VJ�#{:��F�c�r����L�Nę���U�cJ1�4��É��s_�����(�TʜZ�o �d�T�<��F�#���Tr��ZRb�93�N1M�G�S�l yr�r���N[#�D\�c?�}�F�by��|f���_�q�p�����A�8��p���s,@��O�,w%�H�c�<�5��l��DU�rG[��!�'��$G�m9��+GCMI�!�:׈$��~�pÉه+�B�c2��䴦�#�ݍ���5'�t�S�ע�>�<�lf�P�R���hyepY�2��Y�u}r@��cc�5�Lw�p B�k~�&�|v���qt�5? �x2FO���z@���\I�S2ʣ��/,}��OR�d�:Á�����ɧ��Ucm��͌�\M�D#A�����!go�~���r����PыE %JW@~����]���` �K�N���P�^�])�]ǰ�]�\�NT��-=2g�Lȅ��ʉ�R8^�唛S�B5�~̬�����bY�[v=iY;=W�q�s��6�}^��謮��"aC\zwF���;*��wB�_,�W0�y?�����^�<�����A�gR�n����`K�lQ�H�����(a���-ç�^t��z�
�t�! ��l+:	�S��!v$%�6��Ϲc,ug��p
)M�ϸx?�pl�B����}鸨5-����JJ�ȡ��w�'�f%�%��7u��TBج��	�O�A��������@���r�X��)S�$GbFd�6x9��{&1�� ��M���o�\u�������
���W�`��:Ni�e5}�5���g�Hc)��K����\�&��hPbp�2b��1�|�?R�t��q�Z��`�K(e:B���J��)!��L�y�lʄ3:3t�j���
]n���.�Dm3�!mk�T�ܛ�b�A>��3��{�� eR��>i����>��)"�Aʋ��j�һ���%�s'/�����J���j���B2�&Ё ���r�5��r+�|����é����u�x��˭%y2�d�'q<_��?LH7{���\�PI�h�K�2�J�H�]��������gϴ:'�Y��x+a�ߗR0���W�=�ع�꜏U!�֪��ɔ��e[��'~�	��d���i%γ�%~��Ȏ�-J>׳{Z �{���� wi��TH��@�G����@"���Ywa>�޿.�9q�zu����>�+|�Lp%Y�h�,�gq�$|�����r�w!I/@6~�@d�a`t�}]4�uc({!Al�A��[�nʤ$q&Ʋ�0�y�1L�E�����Q��o����Ʌ����qsƛ�-H���Ƈ�Ԯ签����B��en���na<)6s�s7Y�pV�!k&�+�&��r��t��	�ál��Zh��I�K�a�u骒�3�edf���yJ���Ó��6���5�W(�FS�w�nJ�r!��@�����{�tf�Md��(׌�B6;`�m��I�Ӷ�i ��2X#�2���ٱ��h"�ѥ�t|�Qs��ydg��Q�  �a����I�]&�
oz�2Ʃ^���
�A��ha�r�`�Fj~�Y�P�8査Yԫ�Y�p��8}˃争V"v���Rˇpe�n! HK�|ͮ�ýS�q�Q�"�R'�x**Q��o[��sJ'�qr;6�DƜ?Z��<��3%�T9��b ���@ǔ��E����U����T�K�^���ij�G�_ȾBfa�UB� i�i��:�q���j�Y�kߓ�U1P�U�}��&�g({e�GTXs�(7�ҋ2W�f�FV8�z~Vsc<JNpP�����Z���!��Q,��G�-�c��"��q�����C�'�G��q4����(�c[�ܮ�%���c��T�\����,e^�D�Y�������1�Pe��jC��[�>iNQ��}��/?�m�\X�rO/W:DQ�t�Co��=����A;��G޲�6ڀ1".�Z�$���΢���fG�IR��dމ_[s�� ��Պ�lc
����<�Sq����\q�⛢�t�v�c�/��U wT��R��Wp῱�З�"Q<\AM�4ȖZ?�2�3τ5�=�ԲJųL&��&�	�!��8��E�V��SE���ʑ�����}�yv�&���R
�;�r`���ǸM7�� 4���d��8�������.�Չ`�q�v���~G�w�%)[�� ե���ѵuX%6�j~L!Bt�lT@�Ύ���@|��j|k�����(ȱ2A�|����&Ǎx��a3�w9,�V� ,m뢝���u�q�6���!J+"¦�xo��P	:�+�&�b<���˙e��^*�q�?��fA_qt^2�ϱ�7�Hd'���F�Go7h�i��]���xU~�#`j4��S�#lw��Fԏi�l��$�
0��t(��0�_eS���9�$b�����z��q[�q؎x����튚'��J��0,.��A�� ��D�i���u�ʕ��6�@>u��u8��e;���Qev��(��9`�� �=І&Ƈ�ױ%��r�6BS_���0��s���t�}߻���zg��8����]X�-���L�?R��@�=�x$e��� ���&���^��q�b��谊p�n�_x`:X`�.�ئ��<�n$�x�ږ���%���.3�2�B^�k22�F�z=�^wAFA��3 ����
#;e��h8�Y�<�t�G	�:C��-"5��Dę��Fю��ĉ�9�E�,&��z�x0����-*�ڢ/� �ܴ����Z�S jiit�?�B�Ș����RսD�h��^PbS���da�2��F�4#3	�(�v���1g��!
F��z.3�#+0sit�k�AP1Vmj�V��b��\k-��J$2�q��������gM���?�"�U4
�uo�mt�䣲r�v~b�ס�������ꖤS�����9&�s�'	\����%٧x�����Mˮ��aA7��-H$}K�h���جV�]���*����3�7�ü7��#�z�҂��>ّ�x�:pf��O����mU�����pI~�Ej�2����
5F���6x�׈���Y�l�5�>dpi���0��Pfmuq�i;����8����t,�S����.���"�]�{��O{l˫̙��%���%���K�O�S�	ܥx��J{O�<�]�p`zG��"f;*`Q��0�� ��?�Ǻ��:rB\����m�Ќ%{��M�.+�o��@������,�p�aTJ~�p�my����_S��l�X>G��e�@�����M����7�R�P��gm<� ������牖��Ց���I�֑��Lb�8�h"k��{�mVz�Ąi��ǐ��&�ɇ|3��4kfl�\�F A\t�<(+\�����>4���>s���������!�r���ת��ED�?�V�w����8��z빼ͩ
.�S���q�"����Y�S��tf�9ԙb���������=�8�����!C��:�>��3s��{ŰVhS�EA�6"��i�N
"f���pU	"�цtz.z�\�z%���6w�W{�kY��@���Ua�?�ņ%�fR���:�~@�����-s9�����\,�{��u�Zʅ�(�ym;����}�e�m�_}G%�q��Q�+^����]��=�jP�N��x�1�[b�(ě�Ko(h"�Z�Kea���(dr3N�VU���5�b+O"���pTd�Zrh(�5O]&m�g�M"%�oCW7�yIt�X ���������.�VB�Q�T}��̳�|��叙Y��^�%�;��:��@���6e�n�Y��d9�-�yL�41ޮ�P�<#Q�f�F|L��w������@��%�-[�0=ٖ��䛁���N�e`fx�QIv�i��N�cY�h�e³bk��E�K��P�e%�+�"�U%Ș�f�Ҽ��9�5�O�d�B���������~ �^E����@�ܻȈ4��G_l8N�ɦ$_M�e�[h��@xV%��`�C)�jk��-2T-i��$�3)!V1���w5H�@7�H|8;;T��b��@�������>��~"��Fy�[钦���K��Kt(��u�"^C:�,hjW�2	b�n��LK%��ae"Bu0��3�D,���.�N�9�Y.��t?KS=�o���if��(]B��u��+�5!}{�4V盈Ժ)(�%�S:뱅��R�R' �b�^�HYW�>3��R+�W���~
����i�0��Ah^�I�����"�[>���[�|��\!pO���"�g����s zMp����zQ0HXR���U�Fg����c;�ޙ�T�q�Ψ�±��o�[�B%yET׈yǄ򡢙V��[5���k�mۖE�`�D�ϜL��G�+��ZT8i�WgN4QO���!�/�-}Z�4�I�<%���s$V�8�}���)L�����T�#�4�|*�\Y@���v�v�������b���:�)���;�^�װ�4��HU0�N\T��~�(6����v��� ,;��J�A��9���ta��tk����Q�9��c�$�3ނ�]-H� n�qY3fV���Cqv@0��u]�����<Z�/{��-t���k��M-'8��n܄��s�n���tj�8��>�����M�Sxy��Ңfb�)}i�����8Ӑ�p�ʲ�!�T�5�W�>C߁�Q}8Ԩ�6Js� {Dq�#�����XɊNX��:�|Я�8t-�q)����6�w%��Ii���LZ7��Ub+�1�+)�2�Ճ������u9�v��	�}xя`�|ݨ���ό�f���x8�v�]��UC_�M}7�'~��ۺ�v����ɔ��S�g�RiAִ���$��cn�ٯ��Tc\�u'禎�Ð�-�Z��$�*�`�8�N�+R�[~|ie��,�wm{5������f�õ�R�~��p= ӄ��B�r�]-C��bÄvo\�~(��:/��l�lT涍ʛ�et�-΃U��:��{N{��C��"�?5f�'e(���p�瘿��A:nG��c���k�m��z�vaIs���2��,!��6����y���N��Uw@P�ݧ��1q7\N�T���7ϖ�fZ�"�i��l��w����m|q�
�H��'����jcE��R��nT+�eC�y��VF�D�r�X�^m��p��3�u�H��!]�,f(������6���^lEt��J�C��dg����I��K�s�L�1J^�@��\�v���a���!Qm���#E:1Ŕ���9�ޕ^RwXQ����<`��c9�D;�sxոw�B���'\w꞊�S����-�:��:��c=�"d�4����1N�y��c����ݰ�n�ph�w|�4xpe�&L�?���E��eq�'&no�(f�c�LK�X���8n��x^J���u�5!�����t�}��k�)�	a�0] jdbi����M�6^[.�~��[{ɞ���/)��u�Gs�}� ��l�;-�l���4��E��5
��E��`�Y���T��1�'5���L��W��B�����bFz&��0��Җ;���e�9���?TI�U��O�b�I���T��ǽg1;8��9�� 鮩�Y�������p�~}��R2�̫�����b�K�)q����0�2�.�I��a�3��MU�=-F(���<�km��b;t������Ff�Ù�9)��+���/����d_{�1T�m㲊�sm��@w�)h��l	�� �t��MM+�s��S��Ǿ�:㩐L�]i(#"�@�|X�D]O�o$�{�]��s�Z��U.�B_�h(%�*F�=��:��v�#$�2���]�c�4��F�T�I|�_������o�7�T���su9N�����$΄r����B�Z��q�L�m�'0ʭ����Z~'q��՞��KwPc��P@�1O���R��������:ac�bC��iX3i�y�W����AJD�zD�,u>�j%4mzW�V+[x��s�^;ĸ�f�'���Xd���/�ފ-Fn����
��W���Sa�e&�T��j��ʥ~�OnT�8����ۣ�������23R�@�^m�w�g�+_���L&�rM4�BRm�p���u�]b���Q����S���Ȑ�R�B�l�94�\����\��km�aE��^����x��"��R�|�٩�6�|��!�f\��>���Ń;c�y�A;�~�!�yY�)zi�Ϭr!�-v�P��bg��{��9���|P!�fo)����+$[RTn�f���U�q�z�}c�N)*���UM�.rI��=\xě�{�Ei����� ���?�x��QN`hu:�V� l�͍��/�\O�l_��~��y.��uޠ���5g�Q��>�(��􁓦���ظ���8ҍѪϨ��9����)���#����8�T�_z�C^�|�T�;��UR�Y�b2;������,�xr�G�r[6��a0 B�N�č�5��N��*�/��+��?i;/�w��4e���h1�[�e�d�V���(l��rtS�R�WML^
q���Jb��$��n�k���7���@n��( ���/\�ߝ�c%*̀ͥ����O�L��rTA��ބ���#>KdP�|`̃y?G��O�g���rn�E؆��z�u���|a��6EHԑ�Q�r�ɸgR�̤��ךV3�#���ʲ��\L���c�P��Ȟ�ɍh��M��dO+V���k�s��Qh�5mn��8-�l�T0��Y�#�����D\H�l��!ȗW6d���s. �q?��_����i��8K��~j�~9�S��y� �H��rpD�H�r6!�'�dKE|ڏ7{���"i��S՗�7���"��gw^��渮]ȵc'�j�e���A:|�c/S�/m!RP�w@���̢v��C#?F��:E\up�K;J�_|Z��x����uԬP2<���y�u�eG@m�te%�2`��#�*q�4�WXڮ��3�з�@c4��x<��S�N�t}FD�5O�$h�$��=%jT��"�����O����꟫
4�kp��Ы|~RT��1�S-�EG!�:�8oc.����m2�Ǣ��,�����(ʁ/�E5��/W�C㓄�_U��]��/�F܌��Z���l�V{C>(T�U��"�Jݞ<t~�>��l�W�oD�)��9#�j�dIw{L��T(�I�˂Jw˰z<��������Yܼ`�avb	��c���v�f� '/+\�}�vV�?9Z��m��syx����7�<
���~|�(zr�=���ҏ��	�k��&o���=�6�7S�u�dF4�5I�h�fX� �Rg6PZF:�9�d��q����E������n=�nC��O(<�X�.]�?n���C�O]�1�ϫt��V��
�'�h Z)�,�՝}KW�����NJ��$��|mx,iV9�xA�����f�������u�-�Є60��(5 ���oD��r*��V<|z�VG��c*���MG��Q4.�7�i/���] �� �&Q�f�<Ԝy��¯�%*`�Үk��M�@�ry�>�˗�a��$����FU"����Rs�O�+Yop��M.��0�`�˟*ex#r&+\9J��g�M���t���eHT���͉�bj}�^�^ �P�C��.�\B��OȜ��]-ھ�d�WO3�8ש�`v�Jd����q�1,9��M�?�=m��&�8�2P��-(y����e�x�I}���cj|	7����ß���1yG�#��p���߾��D�+ ��x�]�jK���H=0>ׅ�%��@�mO����e��DrS=5߃W����{�j#�]E9%>S`�
���.�t������~���|}���G+�q�WJ�g�D�M�L���ه\�"��9g�}���s����ϫ=��z,�Ox�j+r)����+=F �GG�dO]��im���/���P�.HI�L+��A����H,B�QH�Lk��<�kz&}�NC���u1X�i7}����[���i�C�A8� �Qm/�D�v��s�WZ�BC,���
#�Н�X�#��}�B�<�
�`�h�E��K��&�p��2��{� o`�W�����V�&�y�ur���TYt֭_0 �����]�bb���rT�$�wɑ{It
̮;��W�n�����N�A��� W���~�$_:?Cŀ	�@/][��z�{�H���#ID�~�2����9��h�ׁׅ�&�fr����-�jk>�<H�$�{@�v`Z�t����8p�5�d��毪���/˝Q�$ �ݴ��̔�s%u4v�v���T.��u������/�A�b�
h���S�yu��hǖ(�rn�������Vu��Ei%U��gp"�a���vF@F����D�V��j�(,��i��֏�'ń��۸M��x�O ��� ���������A�!}��R��KG��:��ۭh�M^"V�n�	���Fg��2��ƈ�Ca�I��3�G�`j[1_UrT|;�#�x��6��D��������.�ar[O����ۉ�ޯ����r�v\64����Ē%b�����X��[�m��$5�Q�����E��>+
_�
X����E���bIEo~���]�P�?�>5b�e�1��$9+�4d�����a����L-�Of���X�h��t�/��� �#ҝ����ۤ�_��!�&.p�@r����m"dU��3;mw�;��-��r��Le���W.^�U�K��f�i�{�[��3WƑ��6>;t�m�e��(Qd�y�;��,����O����S����g�T3x�DW�)꜑T�(���(��1\E)��Ucv����$��{WW�&urk�C?�0���o"�^k*�O�뇻�����=y��-�P.�7�K����I�xx��pe|��p��sT�w��͔�p��Ch�&!	�'�aD�e�l� g��^<2μ4�� ��(炛��Z����'C`@աc��sB��$>)Aia2�h�9\S��MO�Y�(��dC� ��Cw�O���ڔ�K�^׆�#H���m9Ta�a�s�ɲ8��}p,l�V놗�N`'��V]�y��p{lG�ϒ7p9�o)��8E�w-�3D�*�c�Z��>:����6�p�`Q����y+�ʯ�#��s��O��$\��3��t�k����&�^=h�� 2�[F�����#����u����jq���R�x��E��=+���bt"6�T�<f�n@x+o��fȏ�+�#�%3k�b�iy���,璒R��Ep&۷� ���uW֜Vi���3	o�D����9؅�P����5a�~c�Q�(�gxo� a��Lh#�U�,!;�	��R������6}ի���ǘ�^�����e���B�����Ę2Pu{h�c���#.U`IEfIcg\��.vg��C�E�����5`L��uyB���	~(UΜ�EI��nQ�_��9�R��PH��Wf j���VCnU��d���2AX5M.)�������9Д��kb��M���PY���]�b�N������Bhg[�L� �������Y��*5?�����檽�ƾ�� �jH�*�5�p��-ڿ�,G����n�q�`�yI������z����nj�CX63��n%�k��k��Uo����>�����$6Δ������vE���9���Lº��q�u`?��.��U�?�� 	A�ʅ�3�U"��ONP�ٖ>82�k��t�7�D�(�H2l#��;���t������N���rw��n2�mw;��_(����I�=m�8VV��N����e$>N�NǗ��Y�EMu�xh`��+����§V4��N�lfH���u��{1�[��I
xPJ=�bm���DWZ�)1r��G��'����y-3ݿ�[���x�>X ��l����D��3��,��y\v� �>�9��ƒ��w7���=�wap�	�ˉ�^��j6�v���)RX��Q�d!�V���P�V�֭�oe!�̖?Vc��ٹ�V|���`c��g��z�'�2��xӪr��j�E���7�O&1�����@��=�l��5�I���p�ԩo���@f�D�6�z0�U��ѓ�IՆ��D�r9d��j���o�Y	У�+w�bm*FMa��iY�����8�Iŗ�oqf�����{�7�5���N���w�0-���eP9"ߓ(�~SJ I�I!��|}��I�����e�S��W<�*'Jz��� �=23v8���?���Ғ_��ҩ�x�;	�<���D[��]�e_��r<�Z�.0����	�k�i�T(SØx��`|ϑ�Q�K�!��q�����n��a��o���_��q;vO��&�}���E�\�΅Ӆ�:�{9�1� ��C�F��@�[��,��z����)�q}����J/�m���w߾CB��*�S���tSӫ@ъ�ޚ��D���p�I��CiTh��?�m��B�iJ��Qrw5f��x�����p�a1P�)�Ȭ��X- �R�<�iL�O~������u:��UYF������w��%M�d\���c��z��K2C�E����-rO[	��T�ʤ�I�������/�e/�8@�f���o���� �n`�(��-n�4Жw�'6P��B���C� e"z�E��/_B��6`��Tu0^ߵ��6�H��JD���6�έ����D�p�ǯ�iVFb-*������M�/ki^��y��%���i�'+%yo�gE8R�!w;�Y �[`��Z��Zb�M�G�4g3��ţyB[�ƣ�{L4�<���_����X�Ė��p�A7V�VoQ���ё����)-x�����1��� �H�����C���j(n���DV^����$"{]�8d�G�;�;�d��w��������RS" ��v6�1҄S������D�z�>p#�P�u�H��u��ȕ�gx��(�jL��	b��#%��/�;k���;�S�@%��@��	�������I�7��Oj�����L���V�N�!thv{{����}۞�m���ů�a3�����*C������1�A����T�i�oIιN� �������e7���S;�w��ҩ��o#��޺�)`d�W���%(�rk7%?�cJ����`NRX��uDǵ���I�ǋ���7��
����^�	>����O�+���晱.
�W�^�L#�|��:���sS�=��� � �_mV�6�~+��қ�8��W��k=ʖP�v�q=+�^��7I�45�?�{��皹;I.<����1:ȁ��k�'A��'Vu�ĝ���H�֩\�="x�U%����j,�#���ëG���ˍ���uw����4ż���.��a���,�G�щķg�G�����P���ؘo?j�7Hu�L��KޣQ�m�V �yBP�� ��q��<�r�T"�w�ы��=�A�^)h������p��Nd]q�W�Bډc�W�4��� 0t�~B��}J���}C�z<Xy�i�ڨ�W�ǌ���r��<�ƻ��m�B�
�24�SN���+�}�BI�����<�V����}�I}b~ş�:A��mZ˯"l��`�(���haqu���7�s��U=鰃4�ې�PB����A`O�e�$��38���^g�����|T��x��cF�J�< Z<�$��D�mڿ��]D��C^g�xvM[��/�^�~�����a��t���>\��E.PV8e���<���JM��g>�S���М�%��}�N%	_������Z(\`��GC5��-���W����lY;e�|�.�����܂r�,0��ȿ?������b�[v�c:&W�R�T(�	��S���)p������ZP��댚p�tD��Fް�I6���^� ��P⨖K˕F�l��3X�]9Ox�|ņ�,�M���ǮH��b�a���F��J6��u��$u*4q�悾�D_������i��z�X���������9)W�T�|q����=f���p~�Mf4]�[��IȹS�&=U�Aw2����Qk�����OeH��m��f�}�UK4S���|D�9��}�.�U��附�f�f�.����1��Q���eٰ�Ɵ��9Z�m���W4�v�TI�o���*t�߽�[��~�W�qY��9��w��D|�� ���G�S>�-�����8�
)�P��P�pG<ѓVH�X��3^e~j�kM��0K�p���SX��&��[Ħ���\�K���ɢ�a��-��t˖iU�ᐑ� ���$P$E��h����oȠ�t��Ix�^�Ѝ�v��cy���W��|]�g�a���	�ۡg$D!2u�` q�j>BR�z�6
)w�G��6�h��O�	���4=�Uu\V�J�2��M94���Ť����r�Ω�
�+@t�j�kC��Tq����ig`������~/S��P�I��On�:���ZUg�w�$��v;�9�u�H*~�	BN�Mw{�_��e��w:�p�K����o����(�R��#�U*���\���w".��++`Zfg���,{�,�ߊ���g��}�	��ۖ�3y?�6b�1'"�ڰ4B ;�Dl��0 �IC��P`>��^��t�o��Zw^�z&�WW<�����%�0�3d��%-أ��sq.��2:��qY҈�XF5G���X��u�q�.*�\�#C��l�x���{Ԫ�3SX$L�z�;��\���X���Oy��H]Vi�N�@i$�������Y�]3�����P�P�Ǘ��hY~YQ�����
�sgA$qt��CE}���{�RKղ���@��t	�+h��m��o�-/�З�{�$.Ÿ�p��=�5�/�ce1P���A~>�(��n������_�c�̷٠� ������ћ�$=(d�+�!��~��i4���e�)�y�Dr�AFU�~���w�B�s۝*@��V��d-���>��y_��8[���8ѽd�^D��M��b��[�Q�I"u;5��R���Y�[Ii�'�B���\���O?s8��첥��W��~;��]Gcl<��j�SV��� 	�`D,w��ȍo�iªC)DFaW�+<���������L�$��Ѩ �^Fy�J�CXXhg��u�A���۩>�-��}h�ݸ�,N>��g��k"Nw�]*q���CGS��8Ѣ�=pK���-���>3�\u�e��LsNp[�M'?��l�ʎ�H��#�@x Z�:'�G^x�:��+�b���3��q�%�Ϋ��];-�.��	N�C��ɆmD+��t��0t[n��+�A��
�s����5�㸤팾��&�����q����'�ɣ~�Z�	p: b��m�`�:W�����?���ohM�E��-�?O���eÕ�~�J*M"5ͥʂ}N�[(%K��yl�q�&��h�h���e��աz�q}F�m�{�ژ�\e���=�i����<Gb,����;�M�E�8$.�� T��o?BX����Ǡ�,�>�_�%!*)V��e.0�/䇯Ne;#5��\�v��J�_��vJ��ڵ1��A��9�"i�'�,n�Tf憭F/�ߊ�){=qPK��1C�G�$���y�3��7VE!�\{՘�������Xr���.�m�!�l�Ǎ��)�]�u�#�VwZ,��1v��o��eD�}V�6	w{�:��R�$�@�`� 2�t�O@ )qe�xl�\
s	C5��MX�J�-j���.�m81Ç,�(eU��<9}N&�ie}ۺe�B�o���������/]8�	�_|x���.z�6��6�,�Ss$�=�08�8���!���`�1Gn���Jjz�y�
���1��Y`.|~���T"l�i6t�{F�����zE�Sy��h0�� B^s��mt[`"yK_t,�yn�S.I�
G���y,h�:���"y*�+�	�����^�l����cL�g�O�Xf^����߉j�'˖��k%`G@T� kv; }���O*�?����nkN  �� �� ����3ʥ��g�    YZ