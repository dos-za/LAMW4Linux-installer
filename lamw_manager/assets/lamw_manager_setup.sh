#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2004484781"
MD5="043fc97d8451b19cd4a45002449f212d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22956"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Sun Jun 20 14:48:31 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
�7zXZ  �ִF !   �X����Yj] �}��1Dd]����P�t�D�r�:���!~oH��Ċ�lwޤ;�B�}������A�ʥ��X'w��sW� ��
�X�:�s��A�#�����t�Wyl@x�3|����*��!�C�<�6B�۪T:}O b׀���( u���񦥁��,���=G����g@�Lx }���y���̻��9�?V7��S4�C�EP�q^�؝qQø�@�/f�y�3�q�H$|#�
��z�*
�L,#�Hz��0R��?���Fr7]��tخ=C5��1��ު�B�b���0�`�v���1Bs��8����r�==T�i�[
�P��2���%�0� .7v̽�����곾��E�4��d˻J� \H�ʞ�EK�ª
E ��4�N�-f�9x�S Z<$���K)Ա}�Ns{%�6�}�Iܲ��V7"�P�w)T� �W�PVUA��Z���t�ڑ�Wn�,�ͯ�ic��'�̯H��ǑW�!���I��t�vi:.����6���F[)�>�>���]�֢o7)��~�>C&K#^f5��"�@��+_��u�A��s��%�0±�P��{��\G�V�*=Db�?�D��Q��������	ryJ�oD�s4$��YN���żZ���a�F~��3刓p��+��R��Aٱ�=Ѧ��	M{� �m������nĕ�q���̣��+}&�t6��V�h&"]����
ֆ3�����Q�A����"S���6�Y4�"�W�pCt_�uz�1��t��>�*�h��2����l���I�Y�2L��ڀ�dLe����'���|#��H쏲x��������$���`�n���#�Q����)�':#��9F��I�d"�f��wТ^��c��z����D)��mc[��N���G}�R��Li� 7�w5��8���i��lpk滵��������;�ꩅ�Tm�z����jˡa�h����`ݘ��Ij;��7�2A�kL�C4��X�֝& ��2��=�0_�W��En��,�TR'����đa��ƥ��$���o�D�|=�b�k���mYD9�b]�D�<�5���i[�F�8*��3
�t�|����"�hR>e}�=-���Fҽ�X�A����R���� Aw�kC���TC�-^
(���k���9����
�O�:&@��8�m��KD[7L�5������1A�eL��#���\�	�&�j*���,g�J������'�jS�v�u�nZ��W���e/z ��{��I ��4$�cDn&h���S��u�f���(j�S��l�U"b9�'�%���@vԯ�Ou��0�����T&���p��o��*�P�����<|͎��ii��p�	��<��+˹d{��R; ]Ա��M��dDz��H�m�騦�P�&^OCĹ�t�dc�(�,Q
������wX�ͺY;��+=�OUʩ��ՙX������hB��$U��e�E=�	�ڷ�ą�k�>7Q<�j��MH��>�>�L ���Mβ��N'�y>�����	���J�����^�9jA���d����WG ���c�WO�e�ޣU,����@�͎��4{Su�YDo�8�O�ʌ���m���5�.201��MaIY�����u�z�%w�c��Lq��n�OL���"���_��̉����Ч�s��&���n��LB��'���Ƿ���m+���]�P���,����`�
�:ŋ@���-�J�C���Z{�L�
�%��/���#s<%9!��,�q��Fq����1*�W��S��k�Yb�!٦��1��b����$3�e+&����n�ѩ�G�(�_��������T�#��k��	��t���
t�.����c�>w��f��l.d����-��AmZ��ba	o�G�o�ώ�eR���%k/|�ޢ����"Y祈k>�\��a��n�Uޢ\���9��#N�ì�1��F���2����	⇤4
��u��[N1�eI ��u�=,�a��A�'0����1 aբ�㝋��Ʃ�� ��y5wiB��� h"�DtV /��8b��$c��$�����|�%{�K��Mq�`��Z��aC)�$,yFB/.�������p�ׇ���z��y��a)K(Q��:%�]
H羷��Y�M�����~��`��]@��!(��-�%b�#�n��/6[��ٜB������3$��V`���r=|��{ l�s{w/�#���dc)\x2ǌ�+��V��(��|��_mv��R;f��z��>@��n~�Z<����-�#z�(�K���Y�j�|��t%Hr��h���A�bc��Z�N��k��_���ߕ����eD_z��e	_�I��r��Bkh����-��4`��-#qeI\����M��,�B�gF�1P�-9l�+�lŕT�:	m�����Mv�/�+�f�����T��x�p$��:$Iz�w��W�$���R�Nsn�ǨH���@�H"���_�_�N`	���5u)�B�?���@{�3��Сԋ���_} ����m�P�p�e�̓�Ӵԣ�N�i|��l�  ���j1�*_�j6ǑtC���b����5�v|�5ck_,4���s�nv�yϚ��(zRwQ��
2��L����c�]R��^���HT4=d��$K͋Mip'[P�u��9j�&,��^���T2#}�ۆC"1~'�ۦ=F�+��NVJuD��\��
s!�݀�$t�R���q=�����A���>��{A:y.N% M���9�.W�W\�Ofe�p��SW�ѳ�WI����g�	�t[F���w�Bu(k��0�wY�1�V�`Y�|A�A�I3�H/�EϬF�Ӛ��"��Q�(��k���pѰ��5a����}�ؿ���5�P�G���Q��Uv�c ��[�*=��+j&x��:�e�{�mg_̀$[kp��@��_�g���
���Fv%��O�����p,-�[�����\]p'?�	Jm�`/.�/Y!��f��.%̲,�f�^=�~˦���T��l���qK�L�@��m��!��~�5�si �<�޾Z>�v�(��^�,~Ht��]�<r��ufP�W�h�ZʫN|"������qm��K�˺���r�ZJ�>���PZ�ˎ��M���P�VHR65�~br��-񗧟2V���k�nvC�pja�@:�¦��K���C��K�8�/���Am�R��[B�b U�Nۖ#�J�>������p��6��EQ�\�^'�̹�t�9�l[������
��������9�IRS!%�P����%�!��/,��ʳ��^M���7Fc���d�[�ᾟ�*)�Dc/�ٳ)޿{�h��p�/��.��Зx��^4f4�v�m��(��\P6ED��(2�PxC<���S)��ָ�(��-�F��T_-�ݼ�sÎ��=���П�dU�NB�7��d�>�[+j;�Z�O)	'��;�ڧ��?&������E����:����O}C}�9�` u���Oh�5NQ0,K�� V��t��� �-ᣠ�F��ڤ-^F�J�E\m,�P��opp=%3O�*��<46��e��7ߢ���%4Z���5JM��7�H�{���U�N�'�������[������.�
7��={zڅ�8���jO�8萿QD�(��m�Z�z8�o2N�5�������pt����s:�X{5����oK�c��WA&k#����!_eE0Y�����of�MȄ����cPН�-�&��-�f����Bpky#�ew�?���6�B���5�!���o�8�(��q�mE��ˀ����(�JF�s˼�b\uԸ�>�e'*�sH~�h�]�pXM�8j(��̩2�eo9���D�\��5��U��Í� ����@��+���ʹ$�Y��@�y��)0K��.�j q����V�nSS=^����ʊ��]n�A�� I
N�2fA�?�ߥ�L�i�9�\�"~�@�rŘ_�V3]�h	F�!|$�!���`H(���\T� ߼�� �xq%#�D#Q�xT��A��"HA�B�DFʆ9==Li��a��@�0�,�����H.�#��i�W���bjX�9Zا�n�4@��ə����T;�˫W%��e��t����y�JV$�lM�nY!������@ǐ�|q�|櫫R��L��.X�q���@Ģ�Q�mz�z2ߔE�l:�K�Y�'P�(xώl��k,ݓF��65D�qO��j7����V����w�.u�E��5���z%zf5�xeg \���+|��Ȕ�~�	��1&K�&��.�f;��J���me�hp���^,.���׺�����ʜ�s�^}���<(P���s�h3ds�9��;_�'wm^�]���}LG����0�7mOb�z��	�Q`n��d����d-�*�zzlC�8��/T��ǲ:[���c��^�?۶���X �8��uVD~}ESL!��TPഭ:F/̅�3,���J���5,$d
�Z�a���O�T�g�����ek��8�A��nW�TlB5<�<���a��u)��v��Ԑ3B�!���c��l֋�������բ�5����c3S�s�6��c9{4/�ׁ�.���0��w�ES�7�,��-cf.
*���\y�>�o8ĳ.�+�D�nύW�8�̐�#��:T�tz��V��ǫ:��y �1R4w�1��W��&�:)�r`������������Å(�x�n��@N_�8r u��Vم��X
ym� .f�Q����m��gl���������73��C������d�nW-V�J�<��妟]�bE�o&���z�����^/�����T�#�B��-���K���n��O��W�hr	��'�q,N�V'6�c����q�7��S��rx��;�G� h9|�Q�Q�$���?�`�5#�]��
ᓇ�㔨G��t�bg�v�X�a���6���/�D�����4c��~����O��TQ�)�/1�2�|e��?���t��'�D�o�%��K�u�+/��8['q�)?��o�1�|�b�Y˵�O�4�.eȝ㞃�2SM�;&�j�y7�]e/0��x������ �>y@�1���ơ+��[�# �o�B�L1�/��u�����ػW�z�f����ć����6��� ��K���,XRӭ��p�&��)@{#>��6�s�%�6�+�[ŋ��N"�1�DC�����U��I���_&�7�_t���o�V�#`5�����g�!G��;�y�OAd�� ��o7��X,�a%Jk�4�/L$��^�&f�+�.�ˆ��Z������&��3/�vp&��E�j:)M�w�M�dM�jY�	ҸQ��iN�%*��+Y�Fܴ���1k~ �θ���K�L�!��l� l���^�u��9�M��))��;����o �x՚?�Xqu��N�Y`cSQMϠ�y�K�u���Wh����!��C9�B	��2]��δ�%Ğ�E�r�v`\'e����./���O12���fō<�SyL�qj�= ��`��y������^�ͻ��Q�m�s�[���7��3��|b�������7ɷ#�M��<�Ֆ�n9G!s���PK��#j@2��CkV龌N�p��v����R)��f�36�I�~&�^3�mk(�A���iX4\�)gY�`<�������q(�TY��s�q���ФGIGOt�G;��-J ��f�c9M3{�sj�c��K@
�D�gR.ᨊXJ�������g�.:�j�0YR��ϒ~��<�p��#�ğ��/��R�,,j�|G�0c�B�󝤒ak-�������<䟢8*�zV�`��� ]'ى��{Ȓ���'�ߠ�O��f�ʻ�\��;'�O'�k��w���ѭ6�O&���e���;y�����f�A)�P���3�E�5�ͽ�?(H.È�ӑz���9���y�7�҈��$�u{MDu�˟m3�
`�R�4Q_'��4���s��47�յH�*�'�YHfH��=�z�e���>��գ����c`/�O~@x���`'���G'+���X\���R{�L���;�/�ly#]�(p��_s��rȀ�u"�j�A��I��w��>?g�@�m����Dn�%=�{Vro�����y@�リ���{�v_Q"��G2؊����nٿ�`���7IW�%�2�C�>L]sv�!S��}G/��J� f�#��d�@
N8ԡL�z��)|;3���'q�s!���G�+pD*.i�;q ��".�^���<f�T��3����c�x͍��]ƻQ�d��Im&�����_����=�;�����RF����1���!|����"g�h��;��N�hY���\�ǉ���������Z�4�k7��@:w1�<����e���7Pi��� _��� H�I���?����U_s���s��A���Ȟ
@Jqt�Z�l��f�6p��l����
\��t(��������D5P�i���J\�e#{fp�v.���٠,NP�;��h�j��v��n��a��[�;j�g?�9�hI�i"}3�_�qY��\�����9�: �Ds}^:��5���4{)�3Į�����_l��hgf���F��)v@�<,�M��_��7$���Ѵؚ���)�D[�맚_4J%MReJ�B�q���vX�6�N#'k����3��׆\���p3��~f��"��PbޥgԘU�d�m�{/?dW�ʲ�o����b�#���U\�}�y��)� ?��Ih3��H;��e�!~����dcf�R�GOI\��'��v�
���X�Ռ$�_++*�8��͆*Gϛ�0Bn�y����Ʀ����l^���ž�����Ҹ��ɿ��炽��5����1-T��?�f�C�(q`�}��I��G�r+��C���λ�#�`7\K[�����!g����'��Bv����(��
����i�c닸%��O��l>�p��|`�����'\h�i�{.�Gg|��d��z�����=�O�_ҙ��f���K[��N��־v0�Z����E�ej��o|��9*<t݅��TA��o�,���{�S\蔂`Ϭ�����z{�PGj��c����P���}ȱ�f�ac]��D����0��u?��{�|\���<��u6)��d�[W��8�3Di;Z4Fv_����t�J��#�>OV�f"�,>��-�bS��w&ttz���o����+9id�o��y3��$����ќ(�!g��\�}�:V��_X�Y���z�l-1�yz�%�Ò�Z���VLq�[y�B���UV�`��JZ�'XYX�1��%����?_Z��%�;�+�ǡ'��Dl�$�B{���<���\�I���`�� ����~8KX���ˈy*6��&O���41�"u�6�p�T���5ά����()����v��hM?�͊�ⷞ�f�q��8	X`#�Vͣ����R���oqn�W
�P��+��]x�G*��=���^���'`�p"�Q�Z5�o�sݐ�۝Jӈ��sƽ�I� �0������}�?*\������ݎ�"�؆�D]�]��*����݂�h�]����m^Lͱ�o�������֋�uwM�Z�N��0���Ij�o���7���J"p�����[�W���
�%Za���k�z���oך��hF�/�t��{(K�7�rV���T������B?/�
�t�F9b�KO�O�D��7���P0���`)�����o��+���zJx4z���$d���4��'Q��H��'WZ~h*KD��6v���P3���Hx��'<T�.>�xO�C��M0XI[��E|Nm��0�9�^��垭}���)�P����)QL�Z�L��-7j0$6s��-��L8)�>9�Y�z�6{�RIm�����Hh����!��G�:�	K��B�>�/C�+<<�u�{�/��0�)���l�@�4�T���|�[�vl����U\u�9Ms�e|,���B1ar;Ѣ]Um�\UTg��JÆ������F/KqzIM|�� "���o��G�f<��CU
V��qC�ob���}�ڔ��A(b�A,�2h����6��d�Ԭi��N0z���˭�}�. ą�*D�D�2�E�4BMД �R�W�_��s��=߻���v&l_O�l�5�e.�`Qt�����=����Q�w�^R#/ߛYe�D����F�`;Z�ٌ����U�)@�-dpb!	��Y�u��Ob�X�|��=&��T��?+�φ8�V�?���r�/�u9�V��!���-�#����nf,֋�E 	����̫�Ho�>��{��GX�Mq��W�
`OU��!��)C�|Lr�S��p�W��n�PbX�@�LJPd�"��h����G=��9�^v@'p����+�{hw]Af"�z=xFxr����tk�/e�$(~�������%`�2��=��|�Y"|M�}H���Q�~��1���8O��1
B}�{D�i���;Yğ+ �>�z@���m5�j�-\][ ;a�>����7�]�n���:� ����Tye�MV�pH�Z��m���ޛ��˺��>ֿ6��J�_a��E��P��$�/#>��+q�|�m1�?mvh�n�鞞�c���qCIP���wD9� ��:9�~\g�	�O�W��(������v�Qǫ��v[��{j!I�4�X�$�FSm.�?�Y�$9�^L��6lhۧ�$JX5�Ο��ϯ�G�����C�]��\�Y��9rm%�S ���P�O�BC6SL\g�OrQ�ўb�Q�[N�G/�.��჊	��cj&#Jɕ�fY�5�kw��/;a�!1��9�<t&�]����w�=���<s;�2���g,�����5��-�-L���&e�O��R5�s}��{��m+�X�L�kW��Q����zB��I���s��An�q� �y��IF>Lׅ��;R5D ks򛲋�8/�h���Ul��m0�ϓ�e�m���H�H��oh�ޔ9�~ΔR���s������y��7~V���Sm����R	�s�d���BF\<d�q����]��K�[���ۑ�#�3)Mp��g����8��*�7���@؞��GȤA�ڭ��tB$�:У�����(Y��w�D�՘ntw깯\YvF�� `��~{S�ݘ*�D�L��^ME��|��P��z�n�<��eD�z�AF'U��b��74��(64r ���tWt���H�;����D +V�@��L� ���r�OZH}�q~I.�S��y9�x��S�	
y��^�`�(���5Px���.����z���\�	��e�VJ�M_m�8nY��!v�b��(,�����
t�o;�g�`+PObҙs��!K&���&V��>k
�$�B+�	ߍ����j�����aZ��N��C����_�����q:B�;v���@Y}j�B�C���_Ϭ�u+�`׌���=\��	kO{�r���m�Js��$ӮS�&�;)���7s�[�X�NIUox��M��N��O���! �Ь�OѮ>�'~��ՑS�_��~&W3T�%P����E��v9��F`YiI�-��-S���p*��F3��il�W-l���{h�2��o�u/�/d������q{M�R�i�ĸ�8y�:�����������.�)���tO �-����0p����^k+�O�JL}����2�����p!�����/�R32q�B岗#&���J�:a���� 2��M��y/��]��U�0�,��� ο��YԼ�'�j�9b+$�I� 'Տ;G	I�g��xq�쪚������I话�p�KKg��M~�1�l�V$5v�}����/��㰊��܊? +)��!�Z�����Aɰvd=���x����,
F<��b��P��"��m��Jl����v��6��_w��>�k2���{����N H�l��L���엄�$���%��@0s��m��Sĵ}��!2.b�s�j��-rϭ���^�4)~�����9�,�J�G���R�6+&>�
e�(H
LN��簴�����[X�^ǆK'����Z0�-��]��q�K��@Մ�@��jt @��㘆� ���h�x���B�>#�`T�"�4ِ�H>fZm��^��?��"��9H�n{�U�J���v@���SK�B$r��?�5ބ���{�Ne�"��(�����"�n��������n� |���	�8���,X�P
ׅ�5U�́�UY@P��_�}	Ol�pP����u�xp��~j��_���O��O \��p�ؒ�޵�F�XtW��%t��?����V�3��	17xP�ҏ�i�d�-JA�'2��\gx`شnK�,��G�o��	g�tV���J�z��=�����E���G��U��Zį螴w���	��$'�m���m��@��-��Z��
 Vޜ�d�}q�.�8|gUv�߳ؼ�Ї.�^��H;"p2�������3b��xv�(�#����0d*X뗠���1?�T+�X~����Ue>?Y�)��n���	�Ǟ݌N� ��T�=�y�bOhOG�T:�W��:A�$�j��tq�:Y����M�S;�vP��ڥ��i�҅q���Ug�:��O{�^C9Ti���U^�c8Z��%O"��B}�=�$�;JLc����/�1�����F�b�ԗ9#q�шEO͛�M�,,��b�;���WT��ں,�!��	�^�k�{���
QN����\��\5e��G^���a������:�������|4��8�.z�k��C3�*<n,|�ǌ�%CR�^#q���O�O1��٨�B��q����e�M�zP	��}�<����8��55����#�/H������"`�ա��?��X�Wک,��w@X���]ތz��c�@B��Ɣ�t�vq�h+���b��������0^Q�_��!��?��;���AWJ�>uN�pr���^J\1�2�fJ�]x�e�a�A�5�&�t��i��K&7W�1e7�ҁ����D�D<�������M8Ţ�'��qv�0��,YK��}�D����+�iFj[s�fC���5�GQ!�I��Y�?�`Ui��M]���«Cnu�1VCH7jzs��N�@c����s�=�A�61@��1��t�]�C�����q;h��)� _-�f�>�XK��}j���yхI>�e���4�#|�7gR5ط��J}&ޝ���<�̩�-��P&�y@�������m�a\�~Y����b�ҹ
����d}ߧ����LG(N��̞��Q6�m�P���E��N�++.젔���\���g��ʜ?ϸ��'Y@&��h���O���=r5��=�bLq����~��o�z�~�p�w�lۅd;����1uKMF��K�Do�אiѶJ5@�G����u�L��!ߴ��1!�"��i�J�DR>���:bm������5���|{|�?�UEypś<b��yG�O�F@��&�4�B�p���%!O��Hr&��6�2���p���Q�E��UŴWM���O��%t"]^y=Y�.nh<<�<�#�r�m>��V7H�^��Q��0�7��'P��c ���7��	�+��D���:#g}��6�Hq}ټ�XB�KN�!�&�����T��ҳم6:'&n��h���(Vn����}3�v��3ư*�ض�r�t�ߪ�iB��.�1j��c�I�[n�VMq�sj�IgS2.���f�*
}
$����o3��r�^.ḑ�^��b�Y ��
'��6�Q2͠#�5hyp��z
�͗ �r�:�J.VB�
���V�39-beoR�9Df-��xh���	�!�ta������Ը����5��1#�����2�C>���5���a�D�.��pR��J��Jpe�h��@�R�{��L�O'2��%�����}ḷ�OS@�C��~i��V�j�q�P�� MH���p})w�q�Sɔ%e�����:�@{i����),�-�4g���/a¸�2��q���(�gD�me|kY�?.X�6�1�)G�ꈚm.�V� �g�"�;���W�pQH��TZUg��Qӳ#�����ш�XJ���;��!�d�,Ҏ�n;����k��Bf�]30�a2�"�?�*�nq ���Y��p�2D�LY���e1�Q�oN%�a����DY�\bS��Y/�"fk*e���f!x]�����ME��R`�#��vƃ���?�i���.lZ�[��q��1�"Xt�g*����!½�)KӢ��DN_��*Z}x���'�p
��f��3�p���I�}�~��E�N�}�데��}ߛ����2���<�GYl��t]DG¹�	o�[~B�Ʃ�5n�<9��ŋ^D��&T��X��cq>��)dC M��b~��r]���) ^�5���(z�-pF�^2kL88��yG?V��{���D!�E_�6|J<���c�f&�$�b�j��"Q.�S=����Vޛ��cϑ&�C�[ދ�L�i�׆p*�����ky<Xm�h�r�vtg��e�#O�r�m|�%���,��[u!o�h��6����J{ǑcQ��B��A68.��Q�e�Z�����޷�f@_�� �}4+��va�Y[�\Е~�}{B�s
)ZHC�1N�!�M"�M��Ay̨#��\�� �Ð�a���>,ˈQ���B�_������X�X;��Xcܧ
<�=)�m��7
QUZ�Nho���&\>�dbՆ��G�9��?4�����#�GE��W�MU�	��n��_R��i�#T���;PN �����T���j��3>���;i��*�XE�W[�>�c}끺5)ŔH��I�g�R����kϒy7*8ǹ��<����m�>�X�+<	���8��	�|ED��.��ͮ&M�!�fNF ��7MI��px@r��o�
����(�ҷÎ�ɱ���C&���h�<�O�P-p2+U�+�D=�I��)|�
KР��竜�[Z�HE��`��N�Խ;����q�5�*ZZ�N�EU��J�L���I�}KQ}e��jʕ���2ۇן�pW��eW
`
�4�%����R��.S�S#2LqO��VK�Jվ���!�&�� ��v�ZD�
�X��'K��gK����������b���WK���hi�OK~��W������j������o����Q�N�4�����8��gx������!�"�J�³�\�C�6��k\#��F|�����\��i4={�%���V#��1!����f��5��X�*)�_m�]y�.m/ݎ'p;�����iK"��
��Z�F��.嬋tԹ�<HnC	f�x+��b(��>P�	�{�d�����y��$��&r����ް�a�!$p�1���ODG��Up�E]ht?��� �_,�2��U��>?	��q�HpuJFP�<����x��4p��)[��z�G? J)ѝh���e�~��+��ʐb��� }\�λ�۵ݙc��%��m;N[�`��)�?�n��]�#�}��<{a���I>�8�g�У�`i���5Z_nµL�Z��a�֍��p�z����i�"?�jdJ�T+�%&�w����h��i�L8R��? ��!�x��ti�� �u��_��v��I��02�F仟��4�G��@��3�(�x?ʱP�Ciӳ�%k��/��!��Q�^@�EF
���� �d�|��W�#橜'H�׶"��!��._�%�*R ����x���W,]R����O���o!�BH����W�0s���}�d���0���@q���9�@Y��2v��������Tm?�<"��$�pK"y�����w�*�����g]4Q3�<+S�X��4�'���v��|��͍�tGY�@��Q>H�`����Tv��5��bUU���X�I�M2S��X	��'�L�Z�ڝtZ���+�Kfi ����y'(�ڌ��w�ul�T�����BB�fC�.Q�Vة|}��4���W�������1����h����A���ҥ�8U ��Q����A�<y.1���ci	!8��5��E�.�e'E��*�Iٮ�'b����G��f�|Ey2>w�y[Ĭ>��k[9����j=��KW�J���E�*�PO��IW�5zd�p��%[����bz8����_�_��+WU l����I�TtP1�b��P?׽f su�5&,���:��D�]�!��˦�25��Ç�mV��}e�p�M��l˙�*��50�V~�:T���7soS�d4yN G5�nwِ;<���V`������s��!a���bBPDf��#��C�X��{��w#�FҊ��z+�Z�Zh^z�>,�9��wo-p_QAz2�H�/0^��|�N�2C���E�xmئ s��!��R�ڴ�,Z�'N(a�B:� �����$ׁA�lA���]���ySZ�5��.懬׳���KyÌ���[*�k��8��=Mo�z#E��"�+��cEN���i���T��M&�������EP����-�^����Y��4b���g���|�[�<5+^�f���c7sX�ު^�x	�R"�D���ᎣG�Q���N����G�/E�`N��8�>���}�<�j���l%*�	��:y�JP!T%�כ���W����?KEP�_�G_<U�t�9��7xؚ�-J�X�K�#@enŭYy�&g
B���b�A���%�e������e� T9**~�:]\������E�^�ʲ�=�N5(<ѩU�ʞ���b��5w��Y�#�\��ST�qi��{4畅�i-h�ě��.��jf�T�����w(�MY�����/�QNׁ�������<O��_9�!�����υ���rŕ����`Q�Y��Ǯ��,t�s3��i{WlP��7LB�jqƭK"c´>X�[��J�����n��r� $	���=������?T�F�k�1��8lf0��P�Ji�Ž�n���1y*܃���˸d�9"} �5�9�%� *�La#"޻r��
��B�̟��@
��,	��%Z�H�^����5�m!�q����+��j���p���,�;}U����8����'<گ�?���T!jC��d�Ύ�~'i���L�s�!U�y�Z�2>���[�!K
��Y�a�_����)+k��Y��w��!VԸҤ[k���i�����H9B9~��&���%,��pd���h���	C�0[A�A��pd���š ���5��_,�YƋ@.�%�RD��-���|��g��&��!/��B���Č�hь.+Q�q.����WW�~�p��Ր���:��bo��1SHܷp����?�l"Z�f�KU�:�:)�i�]�@��c�Էf�q����a?�; C�7��{��%��]M��i	4�Y*R/�dޥ��M���� Mg����p�w�2���Z��ˠ�,��Vȇ/cY���?U�0�vl(��9��.\���{�ρ�4ut���t?	{RT��LhR�����ZY��޺��<G�좽�Top=�x�ll���aə	���Д�OʥٰɩTrJ�/�ԩ��$���E��pH1����[:�->�s��Lu���ӈ(�μ�w�e�U,8��f��%�Z�G��b�Ԛ�&m��	��#t���^o�e�SP�<=��b�Ҏ�.��4���R�]�`�Es~��{�
�"xQ��.O�ők$3�	�9��cYT�uǊGޠl:ߨ@�ʹ�Y$X?�I�@ܸ0Q��aҦ�xD�N˓��[o��I�&��L�˭~�oYH��V��+��̣��HBU�'ei40����N�M������ �Q>�nG�5�v>h��9c�Xv��n�Z�͸�R�
^F�4(�����Mî����N�2��dH���=�M1-�G�O��E]���_��Ȣ�rK��� [2�K������wK����<�im[�}�u
�u����-��|�-���I}��]"=o�M�ў$"|��FZ������H,����Y��v�V���v/ȱ��W�H_l��Ï���G���M��e�g9����z�c����H?�4:�z�;��Г\K�1w�+(n d���d71i1Ex{���ܷK0g�d�i��Cφ{v�I�cV�w'��W����YedĭVԔ>�����b��U8j��[.���J����|��I�n�T}U:��n"��+�&;s:�IE�YT��vb���?�g*�� R��`��g!�����#��,%�-����O�a�����k�W%��ǽ���>K�5LU^L����� ���#�O7Gf��G.�B��&��+����G')y��(��F�%LO�p ���S҅�^��?0��-]������W	�֭��}���2�f����,���h�� �ʳq,o��ʱ��3� �#�cn)/Jq
� ��cț.��T �=�Ğ4��v�-gEe<�^Nx����-�H򿍐1�)y��@ɱ�x�����w��~bI>�)�F�R*�G�Y�8S�_FO]t9���x�[�"cM�_�{�)r���)���C�i�c��6�1,@̶$�9�w��Bn�[��n�D��vR
��T��Ә� iM{b�p!L:�]"[2�<�h�a�v�m��\@����O����A()I'����=T��ļz��^|D��ȕ��L�Yr􀍳q�긜�r���]��sQc�K�[�%�n�*�cAp�j�z�Ϥ�A(1�d�*7A�mZ�bd�x�;�ϐ'�,"���$9��|�2څ�o�g0rGm��+v|`��D�c�g�%�9�k{�;��@��T"���}�&� 4o��ѫ&�@�Jn�rW>�/�R O���I&*5P�]~y~Ԗ5�� �;�0��B<K��6�w�
�(]�,��'Z#5�o6�ͼ@��ÕkN�మO����gp�[������&�I��O����[��Yc_�s`C��')j�?���qs%�O�Jw�f��Jy��!�e�b&h��o?��`�v���@u�@����m��s���8�S�0D���s���X%��6�Y��a��tBho�ǁ�$�~�X/ණ�3����V���Q�U_� ���i��m�����5�t�z�� ᮐpj�r�]�+*$�mlW�2�j��H /�qIs�T|�u�N?Αju��e�tT�(9Zc���b���W��zj�+p�·h�%M��;s�� K��W��<�r9�O��Z��9�)?Y9oPz�����1���_�U�(`��_j(��^��r��6.�� ��lr�t1zVD�q��kQkÿi����3�J�
��T����(���\[+[É�S���q�:���c��G��C!��Zs�,�wW�WR���p����E_t*�A0�U+���v_-�lE-XI�� ��Y��N�� ����K��T��#��;��y�=Mm�5�߾k$r��b~�b���\{߇'aP���q�<�5��
3�u��]����x"�h���]i:�}�M��:�)P�����G�Z����/�=-���9(y"YS_�˙Dkf����JU'g`����y����YE�:F=ն�����a��8j+���Ah�@��U���j	�G�h�I���ک��l�"h�$��Cl�bu�	�E�6k����!���(A��:S+gx�-"M�;eox��{�J��3��RPH���H�C���K���{Dm�ff)��x�[qۅ��n&/5:jX�����XK�s��&��ڜ����R4�KO��K�ʩ�_�q/���fr��	A���� =�XsCDB�*EQq��q}Z��� $����"��%�xq��j�'
�'�����i(㌝�pg�k��T|�<;t�b�qoc�՗H|ԙ���<"��	�>���詡zl�ǧm���d [<�E�'Z0!�'�D�Y����4�W���f%U�{R��lI�k,æ�6�IwiVWԲQ��Lb���W�^��$��j��ϛ�/�UUZ86����>橑\�մ)�l Bm��h =!(��!R�nKM/ԏ�`�6~$���t�G��O��YUm/��8Fy�>����J+x&�)'����f�A6���r�����G�v�3�<W�d��cHz���̪������/vy)�̌ ��(���N���{t]����i��dk?�	.��7,���������i���F��Pp�V���Xxc��!&F��0��	��Z�:��9�@��|1�� A�J�*�g]�.���`F}��qJ^9yI_/;��3�Yz���y�w���Az(���Qr���[8���{�[�2�N���m���tB� y^��V�U����{�
iMMO��2k������-� �^|!��Ui�Ê���u�cX`������|��DŷS�8[�� ��pw*��3��O�GJ��� WZ�����%1�8r�5��y�e�HFi@���X>t���шW_%�ٲ�'��8@~?���M��Z�ϔ7KS�#�������%=����Wb�r>{�Ȍ��no�D��uLs�>qkbk�؊���Aˍ���;F�����@ �'�� ��"$�o �eV0�旉"��oD}L�v�C��B1����"���`��T�d�����iT����'Y>z���~_��7�6#�0_�z�V=Bc�q�����3��3,HNx�U3� ��{�"f����H[��6�۫k\�(������-�/��^HN������8���w(�\�/�ԇ�Z��ƀ�ƪ�W���8�|ka���C :>S7^����&Q�$��=�A�G����)�
U5 C��SB�n�>���dHn�{,G����A�b���淲o?��3ǘ�O����T4�:������V�A����b,�
�6j�|z�.1nq�}�*��#Ͷ�ȹ��#���?���O����'��@Xr��8��pK�ꁫ�J�y9��d���;�e�3��]Ռ{�}y�٭��x�'Aب��}u����������.���U
�Z�=I��x��"�:F�@z�����g�q\j�N���k-�|���ِ5�4�p�&��G�UN�/�7��'�
3R����f��:�y.������kc�5닟����ց�1 ����@�?j��-�%�;%6V�\�����SƖ��������`��*�F��N�{�z_ G�ɔ���_�w��u*u����kL<���!����rg<�݊�"/���ǙS�O�s݉Z	����I�U�����K3r晳��Cb>����#<��D��Y�q���Ow�2����Cb�#����8��M��D&��+_L�b�L��g$�᩻ޢ�ǧey����(M�V�|�t[�YV�<p��R�g�P��Y�M�H]�SA��<Ğ�*��},�X���=�#-e�M(�R�����H�)2�hаii����^���E�fk@�^��k���a!*2�w�^�����Zv���u0�(e����/+����D~T[�&��$_��T�QDz����Ɨ���cV>| �Od�� �~����rx�0���Ӊ�ߌ�'R�r� #�Ŏ��%أ�u�]({章�u^Gk�`��͝]k�F�;��nJ�v�?��ݛN��}r��d��Q�������"�y]i�"�E��?��g�o�EpB4b�Fx	����;v$3��#�b27�@�WO�V&�n}1SB�(T#3l.��R�vX��|/��5�&�:w�إ�w�S��^���o�1�� z�rnݰ��*M�Tѹ9���:�/1h�h��`��D!<�_d^���ʮ{�X!R}U�����2�x��u��.�'�
�/�=����iF�n�q(���؋v v�˥�U8'*9�� Z3u��PX7]'�)d� ɣ�`��+_��![��R��k�F!ه�~*O� V�W����f�ݷ�&&$�k�"D��8�������gL�ށ��LuK������쾇��mD*�߉����>8�h����ƥ��K��2�F��1�@��Ȭ+^/��L}2OOY'ukCh�28^]M���J� m�[���J��R��VQ���L��K8� �nm�L��@�����m�f!��|��+Y�?ϴ����Ċ�g���L��WY�ߤ��Rtt��öܕ�um1.�ax����{Ѕ�=�Ϋ�B�oo��2`*��і�D�TjL�x���A�p#֠��,��!�ĉ_Z�6����(���S���Г���X��m�p�����=ҝ!�X_���! �D�ނ��@k�5O��OLa]����]r<���.��O#�8KO\�w��`c8�=ga�n�xU$l�:`�/~�^�k(�tаh��� ����/�/<6��5���SjB�~J�O3m��o��$�7�?⃙�+4e��_Z �`��6���gۤDUv@��[v�#(���UF��_,�1cڳ�O۳�_�I��(��S���
~�ڼ�U� ��fP��rjB�=��^E�ԁAѪ_-��{��k�2l��0�9�o�4�h�)��K̆���w	�����z��.�+U4�n+��� �)ݡ;�j#��FTuW%ׅ��b�ҳ��*�Z[�� j>��7��-�ƽU1s݇�z�d���C�� ���e>9�����r[�B=.��r�
�45d�n1�`-���5��	D����:�R��g��+E\!��)�ӐM#�6�����le�T��"-�#��ZJ���k���Ҁ�΂h���;(Z1I/�2Q��YW%��2������������v�ؚ�oh�is?rN1�D�,1������`A����NTʓ({l�ѱ��.Q�<cGV���v m���uݦ�SV&?bhz��0����_"�����Zs]>ǌ�
�-DJ�����@J���O<B��+t픛�ێ�@���I�ѦF�Q��3�_EA./���u$'@z�y�:��� 8���FP-x'�͡&����o��vt�:"n,�<�M��eiX*X�v�R&%_��-�w�BH�@ K' k<�/��[�M��$����D�' ����A�B]�]Cy��
��>!H����D�3���o	�9J
��JqJR��Pq8\k
����MAA)��p���Z^P�����/[�m}����'ʇ�Ү��M��&8m(�>p�q8����V!���h���~	p�#c4N�{�>������NC:N�m���ƃ��:�@�%4O�kc%/��X��S�cs;��҈�ݳxYp����E���V�y�z�_ �甎�s��Tu���"R�������;]l�h�BG�&NV��)��Dt����z��� �X�8��2Ġ'�v;V�!
.���^#5Jw��7�Z�Dvg9�榶Z�&�᫏���0�3���;�[�@�%RN= ������1�ٺ���)���'M�*k�#5Ӛ��.9ٺ��&%�c/�TzH�XC�?h�0��၍\����*����೛TD�K��mt�{ތ����N:��ì\nR_j�Nz �g�0ߪD��-��{Dc�z}:U�YS�`��#���T��㳙�F4���H����yt����[	���(�	&�%����ǽ���s����5��*���>S�)��`��4 E[�*�9���O
?	��"��-��`��]kW�O��]��!�u���T�!w#�ӧ8����9gbؐL3{>���]������8��E� 
T��b�-����V�f(7�4O�H����SӒ0E*O��H4�6Vo!qj�����^�=�3������l�~��5��֥���,�`�z]�,<���ǥ �`-��3 )$\�$�ǈk��C<�$�ч�
��a���7�m�!�����7=�Ď�ω�gD��jG%p���ϧ"+P9��M��^�n��	u��	���2oQ�d�B�C�S"��T)-�YZ�GM.d'�I1��/�Л�ݐ�>F��u9�
N���cl�����2�~��I�\N�f�IO�͒Ǝd���.���נ�����,�ѝD��Hz�D�d}=e�,@�x"�E���w�.d�%\/�Q���hƖ@��w��%�I��o �)�5�����j��:�n0;��s�J��Ĩ4n!hoA��&V��s}�{c1�"�`?���P�b �q{Z���Jw����_�� Vp��/kg\�h��{p'6�_ ��è����6X�ۈL�PRW���$����=�(N �˰H�<��T�B��+�|
	�o������U���(U��W4���&�p��8�����Pg�b����U��zAy�Q��͒k����ư�R�Rه>]M/+%ʩ����9G���=��S���A�n@�r����e�$�Q�7�Ƨ4�1�!l���#�ô!�_��0�Z���-q�,��W�N�y�)��v�c5��d�����pI�3/��Qj���Rh.�t    -��UB�� �����o�P��g�    YZ