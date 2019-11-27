#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3254313481"
MD5="096a0bb057bb2cb9ed8b5c239ca443be"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21240"
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
	echo Date of packaging: Tue Nov 26 23:00:41 -03 2019
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
� ���]�<�v�6��+>J��qZ�����e�*�쨱-]IN�Mrt(�S$� e�^��?���bw�HQ��6ٽ{����|t]��?�y���ߍ�;�w�y����}�����h<�hlln>}Dv}�O�B3 �e���p�����uǜ_��k�h�/������o�6v������?�o����c��+U�s�J�̵4`�eZ�L�E�!���=rx�y�qә��B�u����=2��ԝP���~]J�%"��=�Qߪo)��GzcG��h�-�M�jxN�*K�JlF|3�7%!�N�������+������`����}���p�lDɩ�s��pR�W������c�40��5i�ŌN�����`�<>6�H4�[�~�P���A{�{�~�nes�O���h��_w�Ysf=k�*�U��F@��l �J���v@'�\��PŞ�7D�}��^��ZT�nw�U*���0��atDmcU�M��ۜ�|rK����fq-7��p��T�0 ��L���s5vN��((�����E�MC:�m����7D�$��ù���ϝ��U$��هU��s:� ����b�"�#s:��(��Ѡ��(����}x�O�Jf�Ű����3�-����qb�k"�d#�MXLeY�JEP��>t��Ӻ��$�����@���ZFmvxr��n�	-j-Q�)*'(����q�������h�[R�9����e�`�0c6��'�7]Y�w�A2���(3>uj��e2�A�&T�հ��&ڕ��֏ܼ�Q|�[tjFN�� H3�aީ�D§�(e�I�T�����r֞�ؠ/�P��v���/���.�Ag�;n�j���u�l�����-�M>�>�UR�Y�"{�0�e�G�K��z���ԴR�J\E�N�	!hq��b��XJQG�H�PR��IB"�����)��Ma%�V�;7m7�T�'NV����=/,�O��ib,�j,��>�:5Q�<D��*�`2;� �+�R�M ,����[Q�6�<��Y��mwF�Ԫ�W�g��w��W���������������<�.�&E��lҞRi����h3��ʯ(��G�����6�]Lׂ�|j)D�1:��:I�K��*���:*@8��ܿ'�olnn����U��3��j��w�s�&�Q[��9�`��+iuO;Gg��_�$�Edn^s����Ga���dϦ�$�>�{�=�!'�`��qcJ���|Y`9��̀��NV��_"W��C��h�mQǞ�2
�L�\��eԙ3�EH<#����@�tbd�c:�#�a�=]O��mO�2E%��Y�[��+G�_���xD{n&L`��2��3�D<ӡ��:y����{��uM�[�8��j�����%��������%���WmَE�:;���?l�����|�����b���on�����g � a⹡	��� �m��̨Kv� B���G����)�I��o=���Hӵ϶��cW��$4!F���?�<2�'qgZ&q=�k�7�X�[|�{`���b�9�X�Rx�t�kaݹ�To�{h�p4��i%�f,�u���XfX�O�����D=Gn��u�	 �L,�\z9�8��	/����aǶ]���H�Ǉ��̜()9�����F}#��<��j���[�";�b��̰I.�9cz@
�G[��ц*a,��γQ�9|n�z�ݱ�8�CU%���Q�<��V�LgE���q�9h��l���/�Ad�5i��qQl��\�~В��\�bwz�,���h������hi]i����$��4s�EͰ��)�W�sS T�~pѥ�u�{�{f��	�@�E<eH4'@�a�|�៎=����'7Z��{�6�"�K4v���$5�~�b�X�'L����tW�t�ե��f��ܞ�#���*��m=����� �DU��N�19����as=l��/��J�g��y�d\T!ߥB~z�,��	��������$5�C���k9��h��m�AM�F�p����o�jOns�㣘�ϝ^|d�}�9={=z�=is�`�&D��<�tH�/O�ͣ[nKf���{U}��~SKV�
b���\�,/��m�r]�B- �*zJX�Ԕ'9s�� ������p/���\�@^�X� ń�+�3lja������tg4;�_Z��-R)Yw���2��W<�4XN�?��2i��F�f��=4L�����P5q��c�ti���H��`���O�DkM_�^n�$�^�}�ym��T�|�1�R(�%U�Jv'A��Y���4�ȁC�ZQ���IB>�f�	K�^O�J���?���>��<��q�x�L{޽=4i��C@ˤ��d��ݜv�'��[��eC�[��%�����J�_�������b����/c�2�|f_yY�3��C�V�A�� QI�.�B3���n���CY�vK�� =0��%��׎�K�^F�]��~��hR��G�9�	���nʽ���6�c�T���C���:\D��d�͋���F��6�;�dQAVnaf���煃00}�l�:@��Y ����6���q�ht�E��<=�w;�X�
wd�'!kn�D�%jP�g�P����)��<</��җ�$��*_I����˲q�2�(&=sraΨ�������Qj[/���v-z�/�$a �� ��M�������ʄ�_�����_~͈�� L����+�]���]����<�z���q�w��_�t��X�%�p->o,��փ������Cym�#ă���F]<&^'.+�u�z��p��X���ۡ�g�aMB�ƕ,�ߵ��x>?h�F�!�nw8���	~��x-q	��rp1� �D�s �'���p~?/=�����C�W�V��ޚ\����(���$�Sr����<D%?���t��5Al��B�̢�MB��v�)Y�=�:�OC��X��4����m�����������A��3��tچ����G��Y�P}'�^���F�_!d�T�#��D(~����bJ�	i`4X�5\$/c�@��U��P,m��_"{��b��r��1�RPrWTR��O���o��F4����������G��\N*B��"��C��g@������l�4�x�4���!�����m� @H-��%y�����J~@�7���nRslkq��SK�Vw��w��՜�1�V�L��6i�1aO��~[N�y�!n<(�=ρ\��������P4B�.�E�!.�U*k�a����F^��1�b9���G�П| t��.��u���uE���Q$�-$U�,�!F$9��Ra\7�m��.^d.���L�7�x����r�ݨ3�HM�����Q��	.Vh.(.l���Ƃ���f�ǖ8xhB��ZH���Ք�>��u*!i�>�V7-�:�B�x���	�EK|lX���E^l2 ��E< U��XKj�����jG���q[ �[~u\�y!�$��3�t/p'�w$R�	ԇ��� ^@��n�5����.%~���t���^�zū+���'o����4j�x��	Y�y47���=8�vG&����O�X��;�p#_�$g�2�Ja��B�(��L�5�V_�A�r�)�cO��`��Q�����]f �{���+.F�v#�4�ͤ?b��Q״�&^D���1�cX�YWD%�{�Ҡ�8i�'�F=׹��ok�!��j�++�#ؘK7v|�:5�)daM%;�o�˘{�%��of{;���A�`x�s�6��<���1N
)+�H��q欙4M����z^��eE/'RT��{yT�9/���?F�+t��8!I�z����%�)���ƾ�S�*1�͓w���w߭��O�^2���V�x�$�{�O�����w{�e����F�Kd�.���ӱ7�F�e�����!Gn]�ZB�;xSb� &�*����z$.��LO҃��V~z�vܩ��{��r-�A{��m�O.�������}��@8����z,G+�+f]����|?����xy��,��=>IY�Q+4��O�ي��cL���C�a�{<Ƞ��8��tF*=�N�2HM�Ԙ��FH#��XLF��^��w��*v�˦�&q���֡#�W(�A2�w�A���źX�����iw�9�u4�pS� ��p��A�#D�{�|��L��)���j���(W0g�h�~^�6<Έ�rr�R\5O���{��o�f�� �c�-��9u#�Q36�'�ڊ%�;\�n������F��	?���z��o0����(�����.D�����K9�X8�R<��T�E}���]<Z̛��e���;3�oD3i��#�D�sjd[���ޞ�Qm_�I���P�n�<7�kMdTOL�}<�<C�E9����vR�:tYy8�V����xDl��ա���`n��cLM�0�t�S���[̆Hʌ��T܇���!��Bq4|�t�^�3�⾰����u�rLƊ�>���d��*ԯ4q�p�?��z�A�5�O��l+�� 6�[Z�H�Ti#�7.�=Ϣ0�c^�U���`k,f���~O�9tP?������3�d�>d��{{��m�������n�e��߃C>���t"jԁi��&��j��/P�x��������4f����}z6��'I�_�S��C�N��"e��/�i��p!�/��?O)  ��6E�>�����s������)�[jZ �:�f!�k�A�E�EQ{Ǝ�Z��]� @�k$���p���Ф�e�$lv����~5w>����~�X~$�(ҡ1���a���{0�mx�RQq����i�'J�i<���D%eaY���� l :P�dJ��X(N�(�s�Q����.Y]�EC�����@L��#�erd/�((�ʽZf��ԁ� K��\�I�ʌ�ٵ������Z��k���o\<���@��͜[���do�������JU��М�(�H{�_�V��qBǔxf��࿠`�H2�tC��'iU����$?����������"�>|�� K!?%��J����D�$�*���%���<��6[u	 �AK.���o	�7@��s�!�$�|��M�@N�eO8+a̱L:�^��2��� ���/�cf�[DIJ����AhZ����R���})���86>��\h�3�ðL�|Q-�K���R^��Vw�����D� ��	�ma�����0r���<�Ks�@X���8��C*���[('ٽ� ��HF�+;'������Y��;�j��Ľ�Ν�:Q�芋���GW?���RS�{�x�B��
�to �G�W�k�ΔZ<�x���3y��*�̺�:6�A�Z�TR-�~V��D-a�*�r7��%�\�jDbո�Q���˄I�M�r�RV"���*���
�n���Z���̩a|��O�P>1L��7�΢�m�ۺ�6�5�+�+� ;�<&)R�%��n٢ut[������HHFL< (Yq<�e�Κ�y�^�p�1�c�����I)�;g�\�	�u�m׾|�\*�P_��'l���x��U��k��2�(D�6�8���a�	�j�y��Zi�hR*�����q%� ��%��?ٕ�s���9%�Z�xg+=*{��<6U�x!�_#�UJ�&=��t�Df�A���Ԩ��*����â���2��w�$���k�������B�/�D2����0<�=-fj���W4洳��T��o��'[TWpۊ���+��p���­爃����O��)Uvfe�u�Z����Ơʜ�F��UOE.��bm���R�T7V�go��냕\�y9�!֜�r�j7����+n�:7����C�4�tu�9'�3�&�hDD��<�ǋ�h���nF2�Fm�����DkM��f)��H=��EJ/�jt�Od��iaZ�p�E����l��%��$����O�W�i���a����#��>|J�﫸֒��>..�_Ӊ����f0��WعQ�?hr�i�鿚7������S��(���4���E�O�Zǋo�Ҧ}MӨ�`iŉ�U%����{^B�-�	.'CX0��I��)��y罫~��w_v��Q��`Yt�'��?��X� ���P�**���lD���5��z�}�?���0gŷ��	�o��4Q_D񓡏�v��&~��	���#�f	��0,��u��IN�Y���.F#�8S�W�U�M$M&ŀ�x���B��|Ҿ�,)���`0$"�����9�[z)��r3��ĤYa�.}^�_��,=�ft��b�Bb`_J���gpFn�6k�����d��&�u^Ε�È3y783�p�.*����"*aw�w�d��Z�Fj�������zQ~�6,<
��-Gf�)k�+Ч��@r��I�,=�S]��<Dd8 ���ǳ�$�m�7/�r80S�i����8 �s�+��f��m��k����mW�#�J�m�Mד3P)6������B�6,VIV�b�zڔ�Dk�."ω���b�}�����nϐ�2�s|�y^h �V>ZR�c0�<��-�^,�h�'I�r�{t�[�X�
��l:w).r�c�S����/,������B3�$l��@w��@hhBĈ�^t��}|�����Ƿ�֬k��y^L\��s����k���>�h
��ѽ0
.��ǐ��ir>������YL���[���ņ�+��Hٜ�[����>c�Gs77�R^^da:�e��Z ��w�W�w�Q0��l�C��ۍ �QX�\��ʌ�dn��qh�f�y��ŉi�'���^�S;��YŔ�!���h�י���퓓��7�┎�s���_�^<�.=��8����V��Ӄ�qb���V霭d_�_r�n\?�W�P1��%���8�u�^"9�oC{o�vd�:�8�}�L�#��H:��7�w��������F�Ouwe�o��rr�;��B�g�RnG��lR���]�~�HA[f�լN[�3����&�cx��_�t��[����S��"v�b�;������$C�s�B�.f5����'M�3̣uf��v�ȥܩ��`�:�_�{?fV~o�n��c����Kl�E�s���ą)���_��*b�tT�1���P��� ?CDr
�p8�^�#9Im=�X���Ms*/�b�2Vc��㛭I�Z?�������1y�����k�@�+�M�=�g�D��Q���.RE�����N�oi���ڪ�o��2E��rsE��@�W+�V2/(��+ ���co/��Ӎ
\$\�,��a>_J��� }\K+��!�}Ko1�h�%	��Q%�kF ڀ'$���]��S�dK'moˊ�$���+MP�^}C|Pё�O_*����/?~Z���Bq��L7y.Έ���$��򸜭�����W۾���hq,}��Fm݅@?�&�rOO^W��~A�|�"�Qz�_Q8F�#?������ym)^�?s��_'���0N��_�+$|ኲ���7�F�*�h�J3?�[�H���E_tK�,���h5��ӂC^0=/`\��m�9i`�m�#K����YU�6�d���jeUzvQ]�9��ϸ����¦�>;�;xVY�q�Ώ����rJ���3W�����
0.iu�L�Q\@��AMHؼm,��.V~�}��9E��xʰ�+����I��3>�W48������5�Q�����Y0�&%F#	��4[ D��K~O0�mP�'<�A�w��&��|�@���Bydek֐�_2�_c������j,�,����]��o뵆��fA3�|�9�F��v{��x�1�?��\pi�<Xm�
�|C���R�=��A�,� Q͗�xs�o��^���v:{����վ
�a�.�2J�w��n�UY9��6�7��2�`���?����F��{��ovv���z|�~��;Yir	$�����eR�M#���O�U��s�4+�	�w�Oz�G���"��֯<n�1����#�k�So���8��W}��Χ�x��糪�:������dh`O��=o��)v�/�Q�[+�?�U��T�h�ylLΜ2Z�#`����'�;
+����y�FD���2'�<���STӔݰi���ǀ��*��n���8s� �c���˾z���p;�_�r�U�<��<bh�"� �u]i`�I��n2�����Yi5QY,o��L�1���Q�"��,�X��#���ځ����[+�G���L���f����SH��愌��5#a� ��"�ź���.��������+<���e/��'%�U�&JR$B��~�fe�[&-a�ݴ�ZY�"���s�����\���$��l�B�<Aޣ��f��_}�!�LEe�ZK�U� �T��u�	�*�|����Y��>��P�"���� 6%��T���P�a���֫��S��z����L$-�?�´0���'��#�ࣙmU�ٺ��Ҡl'E:������Axg��Y�t���NNڻ��Ng�oX��F�Nvsе�P�Tl��L�tO�:Z��#`ơO�����\n:7��i��/����r&�^�\X��D��w~N�4�T��iIz���i�SUF9����8Yp/�0� �1*�)cR��F��bh҉�~���>E΄RiQ2��kS������p{ºZ�ƶ��V0���)?�pݷ*���T,Z���Lj�X1�R�@B,c	|	l)C���I!���I�^��A�x}4?2�O#���o*61
�Ť�dA�gυ��ѹ���vH8N��K���A ||��$�~%�I�@,<�MS����mN��W��:S2����%b������O�r�t�m y�M����fe��2-灴������o�6� e���iA�;*�Z�.�P���i�8#�Mg�0���e���}#�왘��A��#'y���5��fYQ��ƑZe]}_��x7�r��n"XaJouC�ٴ��-��Cy�R�n�\��*>bu�0��aw1[荂5���Ǟ�H��'
k�R�@țx;�&�7�!G�԰�Ddq��F�O��?��*�tL�ٜ}F������p݂�]��p
���	�����D��@�;B
fB'w�|�ӌ΂;���h����GSS�y�bb]x��l��ʸ��Ҝ�ϪU8���u�J�����@�NQ�*[��6������qc?!���?�y�y�N��(��ro���;m�MG�"�:(k��L� �p;��ut�Daߏ�0~�h�9� n�w�hz�����=Њ�CN�&�R/��Mf�Z�D�t�pl&�x$յS�n��������(����;�:���9��L��X��WV���>E!]h��y��ҟN�*5왲��AE�>l�{AB�*�P*a��&T(��ƞS�������\w���v�DUĘ�ɹZ���	����t�M�E	�"���l�,�P�>TG�r�T6\�V'>)�c5Pqv�h��m�|T-�����E�[:yT∉��,b{�3�\��=7��{�,Y���Yx�I� ���Q	��O��A_$�����}��?��6��6ã��g����������,_0��+���.
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
<4v�`h��/B?��G�e#Κ]CQE;yg����qQ錃,s�9���������Er��+�0w��ΐOw��L�ӆ�g�������7�������\�-��n��V�oEq��=Q(n�H�:k06[�L����v\y!�'���>��D��a���*�W���q�VU� /�B�p�L������1%"�O�ֿb��	{���q�}��7��/QD�{�uv�o��+�N�2�,LQ���
����fS�K)����Uϛ�*L��Мu��?���t�ʈ���|��~b��>d?jv�Z�0N��x�����Ŗ�u�Z�94���q�|V}͊H�����*G�~�ZxYό��
x�Ú��/���l<�|����|��������?7l��'�|ʚ��1@�'�qb\!��Y�eB��� �"�5.���5���T�4�Y�����T@���{b�����8y�L�(au������k�R?�� �J�9��⦊H�k�?�x����j)���+�'�]�bw�Q��Gk�ܥ�����;�=b;/�ڇ'm>X����
,Y�����Y�gY���7�ݝ��=趴�[Z ^� g��t�`��%�y�}{�����0�~�̙m�(�s��%g�qx�G䡺�Ȏ��҃�C��=J�9�\��=>��ϒ�v�kJ�N	*�5���7��I7��Y��	�t��֧T:4A�\ ����$9�m��cDX����?j4$=EQ�P�iO-�W�u=�
f�H�ߢ�י�<��r1��)l�{�
8��W-��E�Z`侥)9�ߞú�0�D�,�"�x�F���O���&.�����֟z���(�9M���l4��t�^ܖ���[�5p)��>(�p?�NR����x���V"%>�������7��V�xv��][�]���t�r?��}x���d3�6�kf�5�`ʭ�@Oj�Z�u2n:3i�Չ�|檩�7fo��ɼ��c!�u�ER�Uvk�����́sYs
Qw4Н�Ye��lL�g��3�b���n�2���<~K��'�Y��og���:���gv�I���0�s�y��>T�ҩZ�T"َl?�"f���$��	�=�AJ �.�����6��F=��DV a�8oq'DP�q����eD�DT0���v�2�Hx��F%%����}5�X|���xYx�t�|2J�Z��_�v�?���FʪXd]Q O����M	0h�8ߗ���io�}`���Yuo��*2N���j�ҾOBؿ�Ъ-l�֠��|.����z����_��[k~�xѧ[U��ҞUM�݊�����K�A�y���0�u�E�~�)�EǏ��%,������*>U!e�յ?���kG�m��1�Ea���Ɖ�:���>�*�~��Z�{CU��&O	%�Q��T�O���3b�S:�2^���.�<1�.Nb8'=<�<{�}�reX7Ն�9���Z�������z.D%8�I��Vj+��=b�9�<���ٔc��%���`�&u��>U�Ƶ���'�Q�Q]4��x�q=�\�l�ː�[�_\��-�gB��4�Aޞ��;I�0�44���3L�f)I�$���I%�*�Q{V��%�1m+��Vv����N�@]t�c�B-q�jT����g��O%���G����D��Wt��|��Ř�h% k=]=�\&o�ǝ��Zx�]Ys�Z�0��q��h-Ծ�� ���aͪU~b�9�B���:�j���4�S�G��v��b"�'=,�6��' � x��*��V9\���FA��6p	k�ǚ{_M?�T����9ۋ�]����B��Pm���о��8�;�7��w;�=�=���}�g�.>1�a�(&7�2�=Q�X�GǳG�}��%8��hT��{��{ج�/�xL����a���)����I���^�^{s��_�5�q9�&�7z�:)m���)"��xz~��l��^�1 �7d�����ȋ��2p����K�G�*��bͱ��6RfΝ)�]�zv�)B��.�� {1��$��k�q8�b]QX=;�@ؤ߾��q
m��.J�b��yi7�9ك)�����<JQ,��TH ��lk����5h�p�C�>�#!���{�Au��u}�8E�?�� O\ f�V�{z�Ӏ}ӆfv��"-e߭���4�9��:�4��^�����ΐ%���[+iT�M�ٜ�祺��\���#o������o ח+�.���
���%\n_�Ռ�[��R�.+����U~�ͷ=,d��J��>�|���{�S�+rW���&�����$�Z���M�1z�`]b�SN5DdAvC���~s��݂����H�O�u��_o4x�	aW��ݙ���Ʀ٬6z��a�"V�%�Aqޚfښ�ݫ��p(d^�Q.}�5�G,�'އ-��1�Β�e�����a�?������mzN2�xi�S�ڬ�nIR���7�b�G"�ZݲҰ3��_�S֒�o�n2SXc���t� �S��~����4��NB��4N�i/U{!-2�*ᄡ>! �d��+/��3 �6�5d4���~�`��5j���QQ-�R�b8
��*䬙ʀ����P�8=�V��ќi��(T���g?X|f��1;�ke+�V�ma���-<��Z��uO��¨K�><=x��dk�m,�\K���b��xRk��P�(:6>�}9�C�ͻ����7
t��/�v�QT|>�Ɋd��S<b�0*	b��9�i�q;B��8�(<��ڿ���]`*E?D'�=;-B���J��N�ݲgp<ε�5����oc��Ӽ������ki�5����`�T��7��5�3��U����
,�y�[��>���Z�>����w��
?9�[%n�-�aK�.�a��q5Fj�E���mCs��P��h^��r��)����Q7ŵNG���Kqdҟ�I��9aG%�Dz��"G�e��!0�� �Yy���$,��z��9AҦ���93Vޠ�F�!�f��=�g��~?Q���<}J�X*Hm�w�����8��4\�zm�hu���m��ɭ�Y-��L�Z��̴�U�+�-J�M�DnZ�C�O����%��˸�Z��{&j��!X�-��&QZ�f��qr�{���Z|-v_�'���ؔw�b⎊�{'��D�L'�{�G �
�pq��bO@	@�k� ���┭�B�*_Ak?����-�@��>��?< *&TP/'�Tk�	�n����U㋼�h&�	3�`e���F�F>��%�q�,���O~�zSt�
>1l�a/�f�v�t-�|�KJأI�
�o�+	��-���=���(�"~�8@��k�2�g]�L[;�p�k�C�Zc�b�M��Cp��'?�I:��̄=^0�Z�Z �(��6���L�b�Pt�>�~{�'' �=�oQN�U���K�ov������X�?��6('����3[L�����3�yy,�i��i�a$��5��!�>"��ț_�Ixh��xTA�D��.�����A���_5�����.*�����n����r�G�����ELc�Fg�6�U���y�1|�O�7���v����a����6=&%�dE�=]��x�#�?��M,���Č7`��*j#��1ח���FFl������G\5U*�P��۱=l�~����=LcSц%^gw��j��;��3[�=��ַU�N������怒�g7>�p�mP�<����Z*qǽb^�U�-�K���n��ؼ,�r?C��"��SZ9u�.���a���.�;ת�C�5eM��>��ٛ���W�I��'p>����4m�`\�� �l;�uC$�=��)����8��7�U����*O��xw����H�nߛ�q7���E$��I0�M8��2@�B����#"r7x@nW�[hB�T��E!7��������Yp���jR��ٗ�̩k$0��k{>\��H�иe�;j�47׻I�p�:���$�D%[Og�i/�l���Jv/�n����u;{vc�e��-�[.."�>mf`���;	�yF�c%dNE~���X�� �Y;!눦%���Y{�:�5Lw�٭g^�˂{��4�/r��\0�s�{l{�DW,��u�uZV��i��H�'��Is�A��H�zc�!���!l��i��j/_9�9)�|_��Wuf$U)Q!殱��Jh�'���͍Xq�{ch4�(,��+����D��r���;��>�q���1�?�O���鿱�K�ϗ@���6|����F�if�o<^�?|��	d�šw��N	�e����܈�=��RK3�O/����'�0R�[U�YRW�F�|�'`.~&�й�=�.�/R�:��a� t_���ދcΜ�y��?Ib��/7�L<�#v>M8�����������"� �2oXs�ׁ<N��"`��|�"
G졵U�V�č��9	Y0�4h�)Ɇ�v��S$���ыye*� Y�4`�p�B����(�h�O��U�hUJ-�����oD}G4ް*��M뢴,iqS#�g^�t����z��
�ēvI���ęl-�Y|��� S�RJ��kRC�PJi���4� M_�ė�/���4�H�'A,m���a�kV��o�ϭ����ށ�{��\�_x��E�%�c}�����X_�_f��\<�'�Ɔ�Jc�v�ɸ=c.�U���%k<s�
5�/��2Ո$Ɨ��Ժ߰Ý��c�j���I�1�,ݽã��^�1[s9
f{v�k��.:?�O�t��.���� ��Y��r)M&���i5
�*٪j�Y��w�'\4d<O�#�&�4��u/uh�����Qc��'^]���`̣?��=>y�c�ȕ#�ɳ֭���gr�ɧa�TWNuV�A���ɾ'wHj������<&��kJ,��dH�XI%��f�48V:R�mӭ��eTS���Ɍ!ô�z>�gr@!�_sV�J|;��:�K��xI6s�
����/oE��l��0�=�k�i�n�-�#SIO��6uMh���B�������|ɱӘ�8h�x�m��& ���o�}of��� (2�M?����J���[5��@[ֵ.L��XS����c���q�S-��Л��X�6�u��j��/�##�������@��^����䛣���f[Ѓ^�k��]���҄�2kΒ������=�+}e�{¿��y���'K�����^��������5
��>ل���'>Qa�z,�!Bgy8<'4y�9/=(���t\ Q�0^�}�ߪ�NE��t��*p�Xw����y�v���0�()��
y�#����!��{1C
�E� <�}4���^���'��@4N�7aN�z�}���h�q��h��0�pg������qTfK5��|�uG1f���負%�D�!�\��w>f��?��q�~/%��t��X��h�����s��K����e�������C��v�c��B��Tf������e}>�d�Qs�+r���0��G�PC��#F�y@zF����w��Sa�ldr��*EX]q��w9a�P�C1������	���_졽�`�'E&uN��lk�>�h�fC��5DՉ���y8����_O�L�Ǆ�)��F�@�Ӹ&O�:I�������;�{�˹��G��E�N욀��u�u�� �˃a���3Qs9���D�:�f��"��H�H����O>S�M�Y��f�ig_�R����%����0!1�%�R[/�S��\0�L��ɘO�]��,b�XO�7��6�рt,=bΞQ0����y�$Є�g����8`D�'�Ц������ '��00f����|��;z}�|n���mh#z��bV�kz����V�>P%ei�gF
V���w:WO�b�o�j���'^S�E�����F½�����Q\@��/�	�S���6cF�~J ����@�ƙRw��9�;�q��6�y`��0B�k�k3a�p�m���!Cܜu�e���G&�A��݁[/㦗�|���;���ӱ:�D���� !�.1�0�nE#�"�l��}s}��O��_�擥��|>�j|O���u�c���2M���y��|�T	.��e���q>D5"|�E,��tO3mL��5�,�_�����T<ί(���%�[�Ă�.j����j������9��Mk��Z]�ӗ�w�����XK�4A�P���Vf�4]�9b�s��ό���ߣ�}ʸ�3�x�34��g�$&��5d_OS�l�YPf�,��UX�1/�@W�n�� �Ԕ8_ۢ�ls�����e����r�Z��7Ի�ݭ�]�wM
 ��i$̈�Z�@�i������x�Fzg23�����T���'�β�"cJ�{�?ۧ\�Ө���Hh���z2;wa��F�>[Q�͉|{E��tU�<]7��U�wC��E֘dl����Ĉ^8�q�|_���i���|�x����QB���N���*�YYޙ��q)�J-��w#����"�k��FPZ JS��pȒ���r�\y�=B�C11#�
[%NCy��A�8��7܋��|��q����=hôw_�m�?J��K&t���@7��u͐��%���l��Re<�FpaC�� �/��Ϸ�]�Y����u��glG�0�V�DB��WI��ğ�Ϫ���FL��h��������ب%X�\���>@6�b�W%����?�bOI�!��H��<��ĭ�� �ۣ��CM���.Ξ����N� ��,x4� ���{�Jl��q8D�x�'F9=����c�WW���Dc�����DT3��-'ğ�e��fQW	��Dj�%F��vZj&4qy��	��d6E�9�S�O`���&�n>0J�E���̯(5�8���Y����S�9<���XO�R��]��F�i���[D�6��H8�!����T�� �&�9Z3�Fe&��ꐾc,����^�A�}Չ�UC����$x��3s�Vor��Ѣjt^�-?����,?����,?����,?����,?����,?����,?����,?����,?����,?������J3V � 