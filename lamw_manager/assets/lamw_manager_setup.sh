#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="848073589"
MD5="c37b86336fddd945e19dd9e9a7a58486"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26580"
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
	echo Date of packaging: Sun Feb 13 01:32:42 -03 2022
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
�7zXZ  �ִF !   �X���g�] �}��1Dd]����P�t�D���~���Y
��%���.��&��4�3ġ�� Z�|l�<����L��94�x��!XY;��h�%�o"pj�5�E]������x�d�xʀ�#>
멥kv ک��c�#� �)��|n`�bȹ�VĊ����?�1�C�൞��������>��Bpf͢�R�Qi �gSj�G0�=s��"+Ag J~��?p�bx>� jÎ�8�;^jާ��#V��V��o�2'�t�RAR)7qEҘ�iݲ)o�ퟤ~�&X4��W[��?N����,�W8���6�g�@ ���X�y�4��Wxw�V��_���{�׉q��TE����D��3L��X�)|^���<T���FtdVu�Uh����|���0'Q����fԅ�.@L��Q5�M�XL�=a�-�EWϼ���b�G��H���El�J7��?�|!�(�$�?؂X[����V��b�B
F%R�G̜�q�0�y	�:�ei�� �.�;\�/�gUB�)����TW�#q��#�EY>�\X�����y��P2y)���"�.�:��
焅�8��Y�_����V�s5:�5�98�LH��\�f\��r�r��,�èָu�u��f�?�-ԊE��ue�)2d�v��[x�eP,�"��v)W|Nz���a�2b��@�w[�؜�A��-aq���U��ZGs��へhZ.���K��nCԋ��iʺY����"U��6[�i�K��YM h���#�ӓ�� Ͻ�g�O]N�߫��ɽհ �ߤd�18觬7�{�^�G������������oa��<�A�p�߷���0�������パ�6�I�{�f��xk������(�ݚe2-�IRO��#2�h0���,������J���$$˾���[�6������2���/�{Ob �H����"�q���<k��~	��j��u�S�ݚD��I���*�W�;���5�ḻ��ڳ`�G���uӲ�:T�2t�=0T�8K�~�*#��b#��.�`�t岍�֊߯�
'�?Н��KW8oa���Rቴ&�V@z�O𼎢=J<�t2�����W�r rx�]K
"����e��
�'
Q�mY�m��ݡǧ�{����*�E�ѯ�7���A�[!n	�*����܅�%N���ҹ@��p�+ �䧂l/>u<Pj���v۝�N(P!����:�2�Z�y�I1��j�qS��.�\�Kʅ�CFw~"
֔����������ТdX�F7��xޅ�Q��GP^�8ϲ�V�ʗ�(J��vX��a�����\��P]�k����ʰ��Y���2�p�4���<�Ǫ7�.-�}�=���g�1m�|���0?Be޶�1�����f���}�J��3/���iQ�p�d��I�J�e���6S���.���m�u23y�U�P�k�P|���%�ύ�YǘbJ��d�"S���k|g�:xӦ�j�����X�� �"=L=�������Lg�:y�]��[��'�P�|�nM�L�S�s{��'�˽��0�q��ʥ\�yg^��i����Xe.�ec	���Sİ���H������v���&���di"�6X]��RM�ez:��Us�k�9w�\+*�0/s2:{o�݁�9*l32>�n��ޔ�,
�pqWs&U���S�?C�[�mB�����ɩ;mW�Ӽ���H��G|��~��dHd��J�<�4�h�Y�ՠ�AG���Sr���O�޼g�ݠ_W����;x~ԯ��gpca&�n@�5Nڏ�RO�^u�ALFW���a9���m�h��sm��|��\��@�N\_��?�N��g�|�3�c���(���O�W��Hb̦ޢ�`-�Ҽ	���ݦ��?D�Z�j�L�DA�LA6�#�s�+�Ƶ���m����oJ��6
u�/+!L�N��!�-�Ԯ�	�i������r�hv��m�u��%o�@)��\���gB�.���*��/�X�|a��}��sV���p��Q�|K�Rh��,T���[��;���=-�^vI1��+��RT6o*]���,*�V����bW��#m�]��w�㸨���1���|�s���PQ�<j��c�h1@T�3����?����	��}"����x։�p�D�t��a]�w���	F:��Trr��i�X��/w90��9`����ᔑym�&0�z=�JOUl0$
B� ���]y��6��+6��2��oe�}Z3������VHH��u?Lө5�nM7o.�C�廉 ";�]G�c~�2!q��ΔI�w�t�qk�kU��@�Z�����BE�GX��}���_n�1��E�s��p������{O��8
n°E8�҂�s�����]0��ƥ����\��sl���M�9mA���j�u.�rVIɍ��8g��+x7�1��v|�`h�C�Y��"ތ�:(�|;�#��}����_��/����$O�w� V����q�n��:>���ۀǄ�.�A�Js�E�`뵘q|�su��Vϯ�������\�9��+D�}��@u��q}��u��K	�%S��H��!1�|燆����3ύ[�M���m,�w�&#n��5a�<�u�D�����L`�
�����>K��VI�O�)��v�Q��~(��>�B�ɸ���g����5tY�m���h������QҾ�V��9�9��6'��[)��>�8��?>/�������N����~�}oal�֬�~Ҥ���P:77l�G ��H��]ث�}s�č��F�  �O��~��׏�-�F�ُ`=�-[�ʗ�0�~3�*�$�<�\po�	큩ܧ���25ڌ���Pz9Y�_������rؙ�e������[�"d����p'�4��Hv��ZI�!k���aT&`�H�3��)s}pMe�Xg0޸����1��6�&-�l^\�5���7�L�c�pc0cQM��d�����|+T�6I7�9 ������� ���Nr"Y5���٣�s�R��(���8\#;<)Gm2���M�1�a`hӱs��4��x���~jX@s6��r��1��QKit�D9u������1�O�쯅4t�~���o��h4Cr��iX���x�-�5��ex���˺H��Ǝi#�tl�i������ ���M'���������ߊ5��j��,�1U��#��d�B�H�_��t�-����{����b�s~�7r�yՓ�,�#='�`l�(n1�y*��Sk���*_��v͌���`��b����9}G�U3�c�GD�Wo�0L��zp�c�A�0�z��z�6�~���wDZm��IeY{釵NU7��eֶ��ﻻ�.=.:�Z=�i(Y	k�!��9I��Ϯ~� �n���K
�7�|���2I����G�>���˿�UrK�I7�q����䇚-��eۡu���!�`�U�.94���,@h��ѡ*��l�x����w_%<�tt�4
1Đ�Ι`���hm�FRS��4xT��ܨ���uE^ ��I:��P!⿝LIoN)������x��.|�Q����vy�X�X�
�S,�w�8�
��xp������x0�Z8��|�	B�j ���X�H�I�}�M����\b��__�W��O"��'��*�˭�է{5C�X���Ȉ��G���k�"���B��Y/826�ڲTZ�DPR~#R��D'���	0]�(Z�x�����t�k�͚|� 0�X�'2�⊽}�ĥ6�de�O��j��!>�v|�7��~�������˽^;M��L͇�)h\
�&�+�v1�� �ȷe)d���~�pu`��*�\l��ZB��2w��3*P��ǭ�Jܦ�L�7�cث� ����N��u\0�0�ї���C
1���.���f�P�����
��9m=�Ȕ3�Ak���+��b�з�B���]%���ӏXsN�?n:�u��������s�Elh�x�"��e8��o�_@���dN|����1�i}x��<��d�
L�ׇy����n�(��
�A(%�Q����5� �B^�I��G�s9�^��L�`�v����J8/����]�"T�B@�p,*�zS����\͈u�U0NG�̘ &|x���aGX ���tż�U�V���?�2������ߘ�L������z#�ǀ�9A_��t�٭e����ub��e�N�;�P_l�Y8�n�o�hpra��$5\�:�Y�?�x��F@��o�7�
���j����W�|�4~(������_ǓOS;Y�Hm\�����U�>�_%�����0d��(��o��T��	��lqei��w���3f׀q��9o��[�x�"yZhకm3zp�����
�wl����dDVˌd6I&6p�:UH�G5���p+�	^�
�@��t�XL�/���mdR7�љ���}g'i���J�+��kׂ� T��O��f�6BV���g�2Y�7����!b�Y;���r,��n�U�(+�?]�
ۂk��'���r���͗.���[-��7B�2�r��N��({]�ڠ����N�͘%��z��0�y�P�]+�tZom�V^��#��)�리%&����=�dZ�-*�:a��������-��Z������'S������u°�O�X��F�S+�5�c7�8Gד�e^���UuG����p�c��܄������0���VSG�+��<�Oܧ�{��M7M)*�������'m߽$���	�U�E���_C|��lh��a�=7䰉"�qHƄ�"�S*Uʖ�I�a������P9$l��ۏ�ܙ)�?E�v��o\q8Ґ<qSR��᳐`���ے�]�"iwF��o諱5����v�q� ��4����?��?�c��� B�A2c�k�������΅�:�E3�E��a��dQr��%�6��#4�[����%�Sj,���FP��Fv�t6G�qE�dn OBS�A�k0��l�ՕOXY��zd�h75�>U����B��x��������|�鹁Fj�K�i�Ll�l�[n"�:0�+Wpx��������	@"���*��$~u�TTq:�h��' ��:�M�׹�h~���HʅR����暠�9tm7>��gQ�ٶ�����0��z>k��W�!2�Z,���XfV�5UW3KI����=�C}L�n>�q��Odl�ɿ���j��@�mY}Sps8��9)[F��p�$w�i��Mb54c8ʝ.%cVLQb���nu���}��d���r+�
�b>�N���:��5��<�t[&�K- �����F>*^�W1�u� ���ZEh��Y�6%�O!~(3�Y%�=T�uU�m��Պ�VS 8�pQ��(���,�p��x;	]����co��n��x�|,���Z}�<`�z�PZ�Zc�97Bb�`O�C��y �J�`-�9��7�광"~]����s7Ta�~ly��ص�ݛ�ף���N�����1肘Ju�B���}J����s�Ow��j���<��g_�arC��T2%�{Ef����h�D�˱z����{J��ř��ժ^swB�@%5<)ӧ�䇌��{���Lx�c�U��m��������ѡ���3�OC�a>3��)�|.�K�~I7�a0�����T�����<df>s�����TB��-�4�l�t��%���~��t�$���[s�ݸ�S�J"��������YT����������G!�H�.�[	1{�H7r��S���i�R��9�>,��f/�l�}"��E�tȑ�W�mC�ʢ`���y ���MmN@8��@}�[��PIJ�����hēϵ_��`3Q�Ȏw��*^��?�L_�e�ӏ4鷈��?�gR�8������.&E�1D�l6g"��t���F~��Zi�+������a� T��7DQ��UAv�ŷ$w�0y��Y��s<j�9��G�E����R�}3>�� d;��������̔��z�i5�H�@ڔ��8�A���W��ڽiLt�,�Y\�R!�����IE�� .�W�"'C��ׯ�U�
vc_�#�����'sī���� w��|��b��W4K:s�$Z����Vw���`�j&%�dT��AL�8<BD����R޸��YMee��Ⴊ��<����-j�<�S�_=A� o�|�%�~%1��.�Ce�&�Q�X�n����Ŝ	��8�� kL�����[I� ��/ol;�(�f�f ���(s�GK#R���@��B~9G�oqt�u�ѻ��U�$%&D &���̕��
J�O����\��#*n�2�t6t5[_�:�a��aw;Ɠ=Kj9<' �����<���y�J�����a���/�J�ٍj;z8}��j[U�AH�B���BF��� �"� d��Q�Q�맀���pT�_�H ���3���c5�y��3��St�UUZ��0�����'������Rx�v�o��˪�&�{N!��4��>速������UjBM�.XͧZ낷���0��gXy�O��$�:~�V��s�+��dM��L�d{ �dJ@R���Z��Լ��[��£>&�bzO�;��yEÌ��Gd�~jA���ɼ�d_��, C��v~����-R�S�a��K���}I�=p��y���/Y�a����rS�ĥ̴�s"�	�x�� ��P���"2pz/'�p �C�*��e�W����)�0mow�}{��żu�-U���
���s�ӕ4J��+�.��l��,�>{'W���κ�cjѼm�g���$��
����	~�-�&�lVJ�v6lT/�7����}�� �n��@=PA[�����Q������(� !��*���y�L9�8 ���咯���GT�,!��	�k� N��bM<#�[����iЃOn�s��f���l��+���E$��d�/1�#��p�k��<L��gh�T�X�l�U�M>��R8uؙ�dbo�����n��]�뒏���~��w������:�&�S84�3��<up|��uCW��}?�F�微��J�����&'-��a���������'m�q��Z���GBL?iI�M�lKa�8apU�(��]��?o�|<�p��m�7�Ğt�	Ј�c�W2�jjp�n[zF��<ޓ}���	���d$Z.����T6H��k�5�K�Փ�<���-��b7<��0�n�nH�B����X�X VA�I���B�#�G��B@�v�άCoI��_K����|㘇�����-`���g��������a�bhڸG�;&�h��E��߫���S�ōfc�b��KkLT�og�8B_��9`�>>bFW�U�c��ϡU��dp=�VA��O��?h,�N7"��sc��h�"u�]w�g�а�V#�g|6���Z���(�!m͙$��E+�Vt�2�mψ�sl������v*�q�i��2���t�c~�#T��Xx�m��3��C�<��kq#����6 4����PK�yg�CR�ͨ_��~�Q�kݓ[cq'��JKؖN�����FO�p|<P�������H�%ݝ����;�㯵��4np"�*{8���<�W�"xY W�S$�ݔK���^h@��
2��g�پw�V4�Ɋ�U���OC�LOZ��(Gq�AG�'�j:��q�YE��vA+�Շs��c���J):#��.lϹ��o�:TY:��Z�t�l�
�����\^i]���Ǧ���� ��f j��=�y���
���aJX�[��h���Ȗ�~L���'削�պ��˖���f�|�sE�4RQ]�[[wә����Şuuf;���З�ѕ���H�:�i�зợ�:�Z��T�2N�P��y9�``��؁�6ř���/�8#��[2����C�#�ʻ�q*,.Θ���(K�0G�#+g�,�����\+�.=ݚX�������a��Qr��ׯ���@|z.��;�_��(9�hns��EڞnB��� �lx�=o��#��[%��_5�<VI;{y���1�X��y�s�eC���u=�OӁ��F
]Â,�����G�Q��"��[\�toȪ<�utDd�� �����=��`d,�69�=��L��V���l���㿈�_���������l�����+�s�)]	|�]?���s�[a�}� �^�t�K[m#2��ru�70�Bϵ��2Nӆ�씻�4^1����]�N��=~��*	3r�s�j�|5��i��(��[�T���T�����?A58g�PB�b6�1dH�����T�9y��߉��}�	w{4oU�1��u�r�U�����Qډ�	����ֶ�X�8RTX���-��a�>�Z��vǒ��C�4�W�S[ 	��`����T'�VSA�&83�L;�)9�ο�"a�4�x��m��dYP���za�᢭�w���h�sf4 �	6Ǘ9��ޜk�Єz�~-6j�հ�Q��2�v��F'V�I�/Ͳ����N�����w˺n Q6
���τ$4��|�τ,���d��Df�^����9�>��+�t
�1?h����1_Q�g��xھ���"��3`j�c���M�ru�C�-��lΡb>�ؙ���1Gk�h�{D�|��e��t��F��:�cYp��퇶���D�i�C%�t$��,zP/���2p>����FǊ�,݈��O���·5m<^gS��M����Ӕ����EF$~`~�g	���aWnS�b�H?�V),!O��^m�J-�A��@�o��sw}�N�����s)��_VP�]��d�$�å�C�ZHGk-�`�Y�4.�FvEP���#0ݛ^H]A�p����d����i�6� ���=/]��U�S{���b6�I_��ˎ�t�Y& ��"v�Py*ÁE�e�D]�5�&G"���{��~����������׊� ��c�X�-s�7�-U��V�O�(�"�?��tb�t��QW��盩�Q��������W����@�-v(U�t�n������8D�<���gII��7W��I�~+�9���&?G�6dM�"����tf����-)5��]ع�`��^��;�#�m�m8叀��	�V�L�&l�窥��&�R�n��tB"��i�!��,���!29ґ�!�AK2��>E2d����KY��d.�?��_�S<,�����+�BZ�#��xy�z���RBWEy-��<bn�*  (���#�7=��3r���Ļ�<����-��?b�2��u��	E�O&�F��Tp�G�,��}�a����j��J՚:��--�E�1d��5¿���xسs:�t���'3�HM���x(n?d[�a�'O�EZ���x��B���˵L��7b���/��%�xE۔{�lox��afAj����o��3i�'T�.^֮������V�h�>�_)�C�J�S�i�t=��?���d!��<�{��啠5/�>;�:�Q]�#^$4�6S��r��}hY"Y�d�����$qK��c�g_�[^�L����@J��5+�q���>D��Sh�9��7�Mm��5k���c;@�+z?����8	|���E��!u����v�O���TQ��9�K��d\S�Xe����m���+	��pf�[�i��q�U弝ȝM�6�
��zWb�(
�1�J�K���>�4/��Q�H��aE��'�B�q�
�ԺĨ���7�h�}��xe����Qv)8ɱ�YDz�Ԃ�'��"H�b��K��#�9/�{��.����S.�[Ne��BU�F�����1�GQ�`Ox�nl֒�	�i��y�{�)�14@G��T�."�G�`WJ֤@��:{
����4Y��IE �g��C/f�J��	p�X�� ��uR�N�Y�y����$�"w��J��ClțU�X�>|/D;n����=;ꡑ7IH�ѫ�k���������W���e���^ [d��ۆ��tȮ�x@��g�sW1������hpy�nx֊הɓ0+ܺ����Fʝ�Y���B�g���lW�4a*����m󺠍~MB�x���ӏ�����P1�˸FHq��CE}bvT������ܼ�@���L �r��<��u�^X�W�E2�J=Zs	�AU���$}t�X5��\� 9Łh��.؀���ӝT�X���-�Ȩ��Ja�z����6�Bޏ;�>��i�u�]�������z�Ɨr^�������!��[}���#j�v<vM�.�y8r�zeT�WZ�����(:�
����討�4��i�Xe��(�ϛ�&��N�/���VR�ٔA>���Jv|Y*����"�^���be��ԁ�Ě>�tE�!��x|��	ė	}�榺ήA�]>��	���� 5o^�x���2�ƨ��m��e��o�RUw"d�+ 0���e��ڔ������=�T���=�z�Wbϒy;L��z9�B�"x��m|���*4t�L/��x��{xs�r[^�v`��9H�ZX�^���mU�Ȯ�0F� �,I�c�P@�Z�1R�|xSw[jB�"�=LEKL	a�!-o P����c,�.�������_�gb -ʬ�d��ϵ���k�`�.��E� �	���ݭX�����6M���&�P1�]q��UM�F4G9�����ޫ���z��ˏsbiY%#�FR�`�$���f!������(�[S�g�"�Ԅ��GW&��jZ�z��+��4i@���C��'��v����0<$��c���w�9X?��;.�D<���	y�T�u΋��s���wT�t�K� �����*[��|�bV��w��+0>�w�Hx=S��	2�%���m�y��V�������6���-���y��bqNjҊ�8x�����C�8����ʇgމ�U!]�e����U-iIj��U�.֙�Ė��-���U�nd�n~݉t;�޹�z��N���b,O^��IeI�KǨ���d<4�m~Nmu��en?�����Dm��#t5��S/�Y���"<�"��K�N����v_�ܟ��y����u.M��|���<�*V󪃮��FΕ�H�DF5\"��<𖐡:-רG�%4���@ъ=�*�;]ܕ_��qp+牕��^�l�*�ge�����B��2��*�r�[4�)J�
�{�<�-����z�oaۺ��ް:�����F�mu��O�w�1�v�`��a���_%Yp��=
�QY���i�D��,Ƣ"ʸ'(E!],4�Fz���!�_ט�~(��ٜ<q}@�Hw��.Z�ɱ�$�s�@�_�~�x8��]A��׸�P�w5}��U�)qR�����r��Dw�5�.AI��͹hNx�1���2�V��).���{�a&���ܐ�ZQ���2I�=bJ�~'ף�K���VCz�GmUV٧��oK��0=�A��`E�}���ƿs�����:W��Y$A�]���o)�����-�9C�~�U���xRi��d�{����oje�ˇ4o)ӊ��x��L�R�Vソ�S��8Qs��5�z�f�H���΁��O�J�\@%�=��$�\;��=w�����B�P���/]L@�`��M	���b�N A=H/�ѷXn���х$�u���%"�u��NN��ݪ�7��kU�����^�*a��
Z��T�A��V�����^<�i18>AKWR@�1��?�v05��ᒖ�\�n�0�"f�ch=<�Q6m�Xr�E�ʕU-��I*�%meL�p҈�� s��8�޵��xb�����Ul���ӯ��c�
�D54��#�]�CW�S�kT���$Z����k��io�J���svH�M�v�)&cS&��S�Y,�q�H�r�6����k�o��7O坧����*�!3X&��f�����}��cό�.�{��/\�<A-���F�F����/Z��E�Z���ʿ�XA�A7�'d���Z�C0�\n)\�d�x��:��}ڋ�^��!b����Dp�q�DI�\Wi��}U�44�a+�e|YƊ���~F�A��2Uco:� U,�#"tir[rw�\��V��M�pQ���C^Is<�����oJ4y��ȂPB[�7��./��䨙��'&=ܻPe!���W�>go��@����?p�!��d� 9'~x�( '�0�U(�_� �u�����v�-Y5�OB�;K��A�)x ^`'R���� �II���O�)�O4l=�^��0a�.i�	���:��;��weN�A��Ty���`׸)��V&���9�ߝ���b�J�I�#�$�3��9�@I��Q���Q^�gG1���N��0��`��uE���\
į`Y&O�*	|!�R�*N�MH����^�v�G�s�l�H�-,�h$d_��[:����цj�'v;�Ö\�M.��2>�G��޼�&Xٰ@�VSΌ���?�L�� |���d���
�G�?�S~�F�S>��w$�h��ǅ����ᵋ��{'q��j�~2G���亓��2fN�����h]��/e�V�|��m0S��B�C�>O�	3�A����_�ݥ@���o��=�U���t���SO��4s��=Šk�9�����1��!k��=�`����G�g�O�`W�SM�Ahv|�}�N��%�F�PzWJ���/��Yx��l?��#��`��UQ�+�v�ŉ��X
&�Wq^{��٬�C!Jo�Z�Q\����������0T��ߩ�t�U�{"o����JV�`ρm|���Hp�VCbQ@�;�g��J��$��Y��ΰ���� �6N�9i7qW��������������+BԖ&#fƭ��#GW�S~~�OE4��9[�QT?{�p�8�t��j�e=K��	x�t���
Lr��C]o���Z�sD � �F�['��ۉ��+� ��)L�L�,<{<�B�D�Ik������|_�.뜾�ҩ	:U�f�.~�5<N��'�����<�P��ARߐ5��E���^�ڐ�L^�B6V~�SO��^_�H`��[�YC��3�)YT8�� '�흔b�,��Ry9r�r�	�C�\�b�xVP�D��ѸҝɓM6�jM������J���b�z|Ӛg22��x���@`� �Au@�D�����I�o
��<t�����(��������3Mn�N:�l�'��H"���z�\�AD�JL��
 P�6���Bʖ]�WL�m�
�21��v,�6d|(�U���������s8�wQ�5z����1�&��Ϛ<o���C�~<�ΐ�ZD�Ƙ���v���k˷?�:�$���1���Ɨ�ڬ�;��p�+����2��wJne�C+J���aД�M������`�E�2w5w��(�/�j����.F9���'IYY9�o�� Q>���\�̹\0�Z��s<�	���C܍�4���X�L���ʴh�mN�*K@�2\�n1��wj�W��LUG��K�5�
��m��Z}ZE������u���QS��Ĭf���J�\��M�np1��My���<��26��?݆':/���X����y��g��}`�f�����
Θv�����/Dڕ��~e�o�צuv���ܠ���~8���/�W�G���IR�����B��vC��{\B.�R�^;��b���5:ln���S����d9�w��(+i˓�b�s�j`�1��"Ј��VK��cY�")郏"��bq�O���w�<�@�M>_B�:VH�f�Ј�0�0*搉���a�t2Д�����)=�9(�>��i�}ʊ��P�����0��)�����
��[���
�5Э�s�>x-��\�����ͮ	�k�_l5�0�+¿����r<E���j��"�`����h�=��u�����10�&��>ѿ�o1�c3��[P$\\�e�=7)�0�6 d�@��Ӈ}ϣx��0Q���씥W�>���(�$F�Q��a�������8>�Sr2��~��.�@\=�$�Yv�O��X���PO�~ɻ��\�Y>kM���~�@[��[�0"=|J"i����FE��!���4kJ�F��[�>F����g�z�D�(��N��=K�;��>�ɻ�E��:�᤺�'ʪp�4A$oN�v��}@ۈ�hx=5`8/�Ov���1R�U��̉�*�T��z1���
!�m���:[.ҴPй�#���a��� �V���*o="C��f�Ӕ<��jT���V~�����	(6b��
�*wײ��hp�蕳��B�D���j�[�{|4j�[/�D���͒�{Km��g$�o�4��g�y��عs��!z(@}�m�7�[�]�ъ_�~;ű۳��E�����T��?v8��n?���]���(J��!)U=jl�=N f�~'�u!�G&}D�!����f<D���ǀ���8'ya?�<l��
�+��k�>��S�\��G�<�v�6�g�7c"Bx����D��I���S�N��!���ՍĐ��R���8V�ӣ�Do�8)w>E��y&~{��	<K�!�hj�<���c
�7D����`u'S\���*��O5"X�a*�."������?���b<ö�y4�3�o��V<|�������r�� &�k�}���{3��z^��Ĝ�A4*��'��q�JI��4~����d�Ƞ٠��t�`Yo X��7Dߑ��R�I�g�)�N�!J�qF:(yЃfu����-r�����%XD�  k����#�~���!����q�^v�|��<��-���V��u%��ɢȌ�*jE,&EB=X�8U��d{F�jB]���-ȕA�ۭI�;;��T12Aޚ}-���.B����,��fX$Z���2,�A
Y/	@��Z��&�dZVo���j�Udj�|��.������wތ�J��{ݿiX������9q}e5G�N��W�[���g���]t	0��EǣY�����M胺�lx��bA��Z�(���+t�q��f���]�?1&��3j������#[��˝ϖi��ݟ!�9q!V���u�hco�x���J	Ϥr�(w�n�܏t���O4�I}�u
dj	�R�Z)�i���pA�:!%1x`��K��婙U��p�c�}U�Z-I'CI�~�X*���c�5��V�y���iM1�!��n>4Y�~P�2"^u-K��O��{*�+�OjI�#�t��������o�)�v�*>���=~/JD+��c[w����܍��=�������=g����7���A��}~���}������4��4�ssW�e�0ƪ�.y����y3O�A�������lG�0�|��� |�>R�w;e��'�7�8�k��K��3�?gw`�K�UA��gC���d�ed./>\Ś�]������� :��̀����,������_�d]r-�՝���H���a�c�܇�b�U5��Ε}��F�4P�#��@i\���(���^K��1��E����jɚx�ߩ{������ȣ�|���a��P�R������Yk$8'@����%�ҝ�N�}�Z�0���"Zx��i|/�[@�B<�N���I
����Kk&[!���#�_q��,�wGearl�ݣ�J�*YS��P�m-q��kR�ت���ʻ>��	��g���N�",rS��J؍���?�uYP�S��<u�>��)��A	��&e��XxMK^��a��ڡ2��X��9V�s��TI!	����o����a�c��y�� (~���ɪ6P�d&��#i,6�8�F7�/����u*�T���qC�<�|���n�[}Q15S�Js�O�i(ע�n�؜î�qu�iq�jY���Ba��W�ȇ=3��\0+��s�����lJc���,5��u���ʦNzo��.A(�=L��ɨ�AG����9��?|Ч�}=���p���s`��Go m����+��K} �ܻ�-��{�Ъ�M3IP0+1�)�'����$�g���D�iD$�yo�P����J4���=�Z��q07����G���xp8�ַ�C# u��}�~�_L��W��Zd;o� CC�Sǁu6��8����O����.M�m#��U�O�}M��t�o�b�4L:5L�nΘ��#��׊)���ѽ���U'L�pÕ��Lqr!�0��.ݼ����Ey;��,t\> S�ĥs��5��my�yk%; و�$��eGili>?��t<��i�J�
��c6�|qmW���#�ZW~����M��YZ"�Р��5ġN����V�:�1 ��-'��I �i��iO=I��nN+�O�k�Ԡ���k,���E�,��9.(���<Oa���h�vj1�?=����ûNW�JeS�S�z����E���ڸ�.�0e3
�4gw7��tL)������o��S�&2B�`7� ���G�U����B��v1�j&���B��#C#���u	;����YLG��?;po�_���D���˝k��0{ӶZ�g��N2��Ar"8�ow�~Ί}8o�=y�7�����U\t�q��Q8��`bˑ�oʗ��]P.�h�ITb1L�\W�K
��+�s-�)��C(oQ)���eQ]�h���"WU�>)���w~��82��� Pf����&��a�E)��EW�m4�zf�ϻ�~�5^��5�Ǣ�n��~�?�'8�$OUuiD���}�T%�^����s�T�и�+13t�6F�v�}�Û�
#��;�p�Ⱦ�T�*o6nv��!r�z~э���}���TlI��4�]6_<�W�T=�[]y����/[�6���=��-[�D��,f�퐚Р��Dv9�2.���"b�(��~�s�|�E��}@���P�<�����?�;�kҿ:Z.t�[��B*d�V��Þ��e���cR�U��� �� ��2����q��M��&b�Y���T�PzC E��^T�%}~����<N���+��N��x7��$��m�
�m�Ll�ɭ�+6Vi����:��NV��E�o@N�ȅŌ.G�(��c��������A%;�������(XZ*_���-����(f c]
��7=��3�@I삐�<(�Y��UZ��80����D+��^M�����.&�-9Gdj�]��9�J&��V��q�X�|�&C?��O�
׊�&�UA�s��}�RMv���8#Il����"Ы��r�C�:�n����{[bU}�1'�n��]�ߊ3%`�Zew�	'�)�r���j$��(l����{E��0�':��r\g ���?��13��62:�Suܚʵv��m�M���7*^��w�n���<oMj����B� wԳ���Z��f���bf5��/�`�޽4��/<6_���@g̨Y]�����?����-0�I��U�aď��"�@9�6����a�Z�NA+�Z�J�~����a��w�tϵ����XS���{���54�Ћ���<@��!�xC�C��}�6w�H�FRq�J��S����dh����Fﾶ��n����"�|�Y`?�M!6Pm# �%_�*ɺk�F�F���D��B֥u�Q�3K���YhnP��)������l�[*�E�b�9t��aFNJU��N��Ql7~J�qUy��^��GU'hКs� ��#�O��>�"�(J7�h	{��d�ȥ���؛	�-L|	\�<�k@T�=6��waՙ��`����Fڙ�k�7�U�w��l���:z��� kq"\n�?��'F�7�M���Oa��kd�܃�h[|˷��5�t��)���Ǽ���U
?��ΥJ�A~�J��N�7�?�E���	h�\
���u/��<�{WC�Qp(�ۤ��5���I����<K�����W���P�|
��$�8�}�)ʭac�v:�J��bʓ���߼A���
��?�'U�G���k�Ȫ���<<4���a�b�9Au���r^Xo���@��A�� �O?.���gn�0n����8����9Ӣ���Մ�@���]2��׺(����>�SO{�~׽+��E8g� ฅǟ��ut��s]i�@A�7����Y{U1-1����O�L;��yUȵPFm ���}�a]n+��O�$��W؉$$���y�S���̓12���9�/ S"]CsLR
'uOq�S=�zލ&���a82B�o%)�n��H�� �9%N�BA|T5[ն�t5�Od� ��k�`��^�(��k+�iI��>�;��"��TxM6���͖�����9�l�����D�$�r(�p<�몴�*gch@����R�q �q��kٛ'��z����=܄�TLʻ��@�&0�O�Hp7�N⅙��T��	CS����V䓍�	�Pp�QS<�X� T$�a�'��#@)=�s��,Y�3����d���R�0T"	�F]�t��m/����6������5�O��7Z�(��G����~�4�+��2Џ-x\	�*�CU���5���2i+����?��6����p�4�G�pz@�~���}���i�&����U���ɐ�ٗb7h�&��@}D��7ey!�+]�Hë�� �t�_�VC?s��'���_���{cj�	}	�-���#�?G�S]Q�M�v��=d���*A�=�9�@� 2�Նo�8��<q&��S�0���?I�����9{|��|�����#m�
rR��"̐d�'�����{f%���� �6K���]%̖��6D�	��B�����_����{Qh�W���~!�@�9_����϶�[��^[þ*Cx�!�yD�� ���隼�j�h�Re��D �ꓢ�b��Ğ:+<��Hړ(���-�N��ld�3o�=`<a��4��,�ɀi.�G�����2����F<w�O�P�U�]��_$�>��`��k7WDE���
y���� C${W����qjJ�;� ���y��Y�Т�;V��1+��Ll~T%Ijvx�>���@�����6�n�������_Q�J�L�4M�=��j�E�$`�N�T��~N���N_����K2:穇�_��g!���0]���%��<�E8�:��A��=�,q�|,��o�
���w?[����j�]A8��K���/GI��kp0����N��x-o�:s(��� wA%	 "�e����IͥC
}bl��ؖp��� ���a�M��Zر�/Tڟ��c�I�8����%j�w4�*��1��t�B�.^d%�W�b((��Sa��x�"���'��/W��i�\��L<"�Qu�������3�
\du��$Q�^-=ĻR-HI B����N���(Z�� c̮K��;r��!�r�_L���𷎧����W�?������R����l�(UE�?��)�1�W�|�������p���Z�E�w�:ݝ�����>\��:"����|����=L����kO6�����M����!�	���l�w�������b���9i�ǔE����!c��Ў	�!؈<~�sP氷��푇�b���a>c@VE� �e�>�,5�H��e�R2r�b@����~F��+�Нl��N���v`�"�vD��]Wз���'���Ӷ�rm5�;q��{T�JJ��,��m;<�"j.�#bL�is��JD�}}���0j�4�U���'=6>eU�&�p6�޽��4]����P9�:�w��9�9�I馾f���5)k��j���#�"jݴll����S,kK��gkx����!�'�j�Eb��I�_-U�hb�Mg�W,/k�(�87���	Ak�Q" �O�]t�jǷ@�{�x>~^u���`�`�b�Y�yߚE�@��U��
�'�;���y�i���s��m���i�kRW��D���ݏh�*����;m�]>���]���u�*�Hs�R\"��7)�տM�vH,�/ږ��
fxB�����̉��hx��_&B��x��U����y�!<��� ��B�t�R�3+P
Q$�*a^(Kܳ1F�z#���P���y�B�����7�t��������݈ˢ����"�Y��ԩ��Ѳ]EH4$�(3�s����?,4�v!�=SsO<6?�P!�ً�mEB������w�ff�-���
�>�bI\�t��z�V�;���S�ELq��z��J{&�(�꾧k�a
B�E�[��1���p%��s�]�) z��z�<7IQ���2'6H�%u�Ӎ���� ڝ)�x� Y���~�RJ��6*�#1�a���SM�,eb �
���A?znd|��z�w��s��7�4)�3�3�h����E������~Gw�}xs��K��X��1j�o����frvͺgD2��������괦�%Y3��E�� �V8���*�����d���bR-r0�|Ȼ��#5��Mm7�ݧ�"�Q�����(3{ܕ�U��sN��-�g�o�-�5�΍p�[����ɪ�(�*��a���	Ւso�����)�3q���OgC��Fz�\uY��d��ٔ?W(���E�����I��Ĭ����-BS]����CJ���pm_�E�t��1�b)�G����ˤ{����~/�Q��~��r��T4^#D�Q��uܣ0�����.���5oD&\m����W��0"mI����d"-���Su�+��#�[/Z�[9C�J�ys�/<�&���霵}j=�Y��QA����aT�1�����\����w�I� t37�F�w�V͍/�6l�5]�vn��yi���Ft'���Ġ7n=���{��^�B^ܑ��D�j��.l;�=����V;����=�ym`�}�`2R¼׬��%3(u�90��;�cܘ�6X�tg��b�]�W��nf������a����]��OW�J����ϳ3�xDٕ	"0y�>)�=
3���~4�����h����x�<�'ϟ��#��t(fE�+�ʉ8m�\�܉>n}�?z�Bd�����7���4^+��_��e�Z]���@�9���N�M�؄�)�����6��t٧��Zq�&��>!�ҏ�UN�|'}�߯[\R�gH�*�Y���q7�!��Z��\�D]IɅ��5����Q6��� �I����(@2`�������@"��^�d>�:��/Vµ}�
 �އ�y��U���^ŷ�]|�ʴ�0٫����ċe4<�7;ED���tKola[���*ҹ�47�ٷ6I&1���΍�+�樍�@����ߍ�^���1�i	�����T�HK�g0�x\��v�NhR�1��x��;�GH6!U�����C���k���Ya�r�K�.|��ņ�7J�L�|� O������T1w�q��5��(�D��m�pU�J���~�nA
�y��PR��i��(��C�!xV����@ kOJ�;8���ݟ��LW�s ����X�D7G�\���h��T��ôSN����1e\���.����>�ŉ�BEbA;�&|m�Dl:Ɏ�S��
9�_�V��C�ͽ(px��,�����6����/e��`����$�������v��ģ$%g�R�B'�
�%CÚ��s�b{�4���A�L�nD�� W%A�/!3�F��������cMػ��i�í��X��;�pj��>�Cp�0GPR����)�p��U��}���#��k�Ȁ.�7Ɩr�+T3�:A�*���h�6�T��5�#�9u{������f$�bB������R�4�Adp�����Zn%��jC�C����0P#��c?�<-��?���&�1v�l��{;��v���:����-`լy�cI�Z��+�����o��+�_8�zŌ�$Ն�#b���+�[n��"��!�kٽ��>�;l5s�H���X˜O����w����R�;���.��[�~LR��F�I�$n�!�#��w����<��d�Ʃarǯ��O `�M] �O��Ptt/w�C�<G�OVy?���֋2�6]+�WoԾ��Z��J��M�.��*{V����
�$��	G��vU�{<|���@_��<ԏ�D�<8��KM�_�ύƅ����N�.v�z�Ca�(it
�iu9
������� ��?�ne�Wb~��߾�"�o�7}��8Aq�
� ��k[��^�1�b]Sٴ#���D���������B#�����;��}Z��:���Cai��0���M�v��`��@�����L�u����#�')Q'�y��= �뗝	D�c�[:�DD4ݑv�������؝�(��3:����e0}"霯�[�=v�kwD��3��a*���j.�ٝȏ�N�I��O��ړD;+g_�X�m}�L�d���X,-"2�\�,��r�6gf""��㧔���h�=�'e;a��o���.p�@"���2�����B�	��%D^�k:�NV�S�ݩ���-�g5FḄ��|l�@�v<��D��[��5�����Ƶ�;c�,,��˴ᰰ�a�tM��� ۖ�$��m���EsDof��?�Xv��+ln�2�+����s{Z�����y쁏�bY:gV;z���@j���ܛ�� L��(���pg��~���0\�).�z+ H/N>ZbFŹ�B#]t��R�A*���ąL;F|zHl���J�?Hk9�ߜ�lQ�5�����}b]���P��+��݋��vV�	*�ɡ6��h��U C2��֫�>�:{V�A���� qx��Ͼ�bk�����d���Aҹe���t'�*e�I��]:�{�-ퟯ�ޕ�I��Y(C�%�}��MT�q�.5+�O$l�yw��0$1�?x��0�\�6�˽jH<M5\��O��"U�!?l���T���g���cٿjc�&_�� ���_�1��rk�ʂp��fj��lɮ'��$R���Z���6)D���˶E��^봙���8����
�s4[��ymɉ�#�C�-��ރB�P�<gy��X�\�h7@��y�ם���r[?Z�%@_�W�u<�M1p�X��Ky_y��&�d�NAl�*�Q��qh�u~�2��K�k 1o6��-�@cV��;^�}�0k���EG�����Mɵ�5[vrae��	he����zC�ܖo'�[;,�Tʷ�f[&z1�xT�p6R�y�q�C5L���B�]G�P�F��Ptw�h9
lgG	j$�W!f��D-8k�=I�k�B�&>�1`��-�F�u�sk>�2������xS�] ����j�K0�;K�Ta����н��@�,�C���o	�ϻ��a1r��[?a��*O����X�79|ak��+����
��׭�`[e6��*�v����	�y��s�����?L2��O��`����G������_3�|��v�|zᢿ^9���Ff��C;��x3�,]p
���4j7Qx�?N�5�Չ_M��#%I��>�g.�ҥ�B��Č���]kc���\��X������C3���y��Pr�� $5����F���X�3����:I�Zn@��j�p�A7WA~
~�!3��a�7����̭����r���~|A��NJ�-g�+m؋ʢ�l-�)Α���p���7�7?x��,�I���"��Ka&;FҶI�`2kk�SH2y�/R�E��Fk�z�9I�5	7�q�1X��A�'���Ǆ�@Ǝl>��bk�2���ڈ5��G1��6H���m]��J�hkb��pTbu���?x�|��_/)��������V�1�Ieo¦�7r�[g}i��C?$
T���'�O������ �WYS��}��<h�I�.��eY�_q��<oz?��7UQ���-�5/�B>�s�~�[ޡi |]_}ɟ�1XF+��NzG>̯6!��/��賯��gh2N����)
��� {9�Y4l��"�� �-0j.�x�ӳ? ���-��*;
�f�h
By���몠#(#^ǟ�b韉$�(�ϫ6Hq�����&�-WN"hP�o��.^�#=��������6�F���*�gA�!�'�l�c{$�Ca�O��:�uk��0�9�c$87d,�~?�V#��y�l��n��FnU�hr���'3�S�X�T�q���P�r�ԗɡ��v�Oo��:5E�-�T��j0&�+���L��*��gH ����	Nb��A*_וT"��ڼ
�ǽ�"t:�z֓M���l�����c�Ƈl1z���{8/���AA��Gp��<S��&�3�b`t
)�L-tl�$GHREdY*���u�w�Ih��"��<� �6�<�@����W�	�W�D�8w(%6[�]��6dz�S�{�Ŀ?��z�=I4��B)�?���d�Dg��VB�Eű�*�[D��S���n~�:"��E� @�!߅=��.��#���^邡�L��Ԡ,�K~����e>g+��v/�xq}�*��؆?�\{�[��1��,��(��f�j�O!<�/�����HD��Զ�?�F�]U����=��h١	Q�'��n�0�	G�\�~}&�a�hq$:}v�k:U�lR���v)��l��}0��pF��w�2Æ��Ŝ6�K˞?�I%�V�p6c������`�*������K�Ox����'_^��q��?��w�\.�OA��sJ��B��r�ߤ+��Ц_A�ۯ�J9���	#;����2A�����O��i�=R�c�T��l�6���)��d�l��2��]*,q��E_k{�$����S��ؗ1�ڌ�&�$V7�Y$)�&� ˧����ÿ��N{h��i�����+���yXr]�nA���r�qG}T� ���� ��,�x�MX�I\e�m�	V�.[���7�>��pڈ�yk'[=$��0��E�j�՜q�9� b�Q���� ͓��2(�0���L'e��Jj;��rD�j?��dP�XWm��J����i��f�4��D�[	O� ��nR��
���pU�����_��c�<�>��4�Kݍ��c�2���!�p��ϙ�N��)����M��@��lp�2I`ȯV�����~�Y�S1<����9~} 	�k%4����ᰣ3o�jt��[�ou�v�������jk-�B��༲�Q6�����e����
�K:�����Fk�}�X�?QRΈ}�P,tgG˵�'��>���+cG���R��i�Q9�_]ӄ��؎T`���xM��\^�A���w�?h|O��ͱ�����&`-�;J�V�x0��͡=8<����$����q���:�Û�Lk�CF�UN��!o�����u?���E9̭.��Cs*?�u>��EU������H����I���=j�R�;'h�im�?��*�s�F��\O���6`9Ƴ�` U*Rt�R*=�i�U�g�H��:$Η�|�aV�^]:t�^g5L~�����'V��J"��\�&ĳ���JÏϘ:��w�&�f�{-�Hr:���'=x} (�K���,���s��[�-I���\�P���biXIY�������z�c��)����ᆨ��r�	/$:<���G��O��^}��1��K�� S{���}�l��ߑAo>��<��A���(`���E���5�4���'#hz���1A"����T�r��&�T��TXJ}��%���X�~q�J����m\�-c��ɱ0���s@v���4�/B�ZZ:Ee�/_%�_�%����*+��������߸���g��F���92{�1`TNt�쭟5yz���9"����%�J�>lM�a��\	�S�뎫?��
64&����S� �I�ʫ=K��8XoK�s�M����0����
H��9������]UA}Mp5��"�4�8%���0��0�k� K���3�ķ4�J��;-΅Q\�&"*r6�X���W�J�ꧾ�oex��9s���O=
XM+�9
+1G�����܊�pp7U�^k�:��>���5�@GBE�F�_�ȳc�2�pBp�"�#R��� @`ݔ �wLǙ�<Ui�y��igB���9i`e�졽g�/��d	�w�q�V:��DM\ҢQs�5!�KV�=/٭��r��O@ؠ��z��=�Đ�̌Z�C�H&T�n"8����3z
�4zKn�{����4w����ä��O�f��9�Fa�[R1�g�$"rFB �>s"k�۬���ϩFh�,����n�D!��2��[�j&v^��� ��*3�*�0�TG��Q�k��>��ؕ�s��}
2~|[���D�3W{��2c�"����>��X��*]�8��*�
�Rl��t0�����xɈ֠�������6��b4��h�v�D�w��'�FBT]�2p;��B�eE�  �8ߗ{�� ����!vIf��g�    YZ