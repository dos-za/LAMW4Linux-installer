#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3204322400"
MD5="182416c928e3837242b300bf6999afed"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25408"
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
	echo Uncompressed size: 184 KB
	echo Compression: xz
	echo Date of packaging: Sat Dec 11 09:22:08 -03 2021
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
	echo OLDUSIZE=184
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
	MS_Printf "About to extract 184 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 184; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (184 KB)" >&2
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
�7zXZ  �ִF !   �X���b�] �}��1Dd]����P�t�D�"ڭM����)0C��n��Pq:$��Y]0f�-���-o�����I��!v"L�+4 l�ҥ��o���ծ����l�"%,�5�f���]��l�u��U��nT�}���C���FcN-	�ݘ 4w��g�U<W_ȑ�������S�GFԐ3�#�;F� � �c<�T����g+��{=��}�f�.w����9��t7�[��"՗3.�	;�*q�=�L��V�E��`���ݛ}D�H����܎A��y�N�'�	k@���G��Ob��|v������*��j������.��M?wVSu�m�KZ`,��;p�nw@���Z�"~!��m��<����0��U1�� ��:^���w�Ի����lޛR}E1Ke�.Z�3�iE��x���=�F�Cit�SC�^U�:�v�BM>~�^�Z?<n��(:<�]w�S���B��K�,���[W��y���{۩��،@�7��\�m݂�����Zz�li�{ٛw��|���f@�u_�y��0�U)�h!*�Ëc�u�L�փ�f��F�>ϽP��E�I��+��V�<�Q�Q��X���k<e�5���->�D	��M�$�Fx:���UsV*�K�
������&z|dJ]=%���]1R��j�B9�t/߇�R~��Ug���("�ۈ��=��!��ӵ`gI���#��y��h1�^�F�J���Ŧq<�m0�T*��ZO�����ޑ�"Lm:Z���%zT�O9�X�?L�k����b�̈Y�ippy�S�gN�?�<4�@KQM�����m�eX	�[]�"0*b�ޏ��a�e��7�a�5�>/��/�d��R����y�����M=
��b*�v���6�/�
!��^`�녠q�xC�Q�k�8�i��"�&�zϿ��V.X��0�wr�fL��>m
�v=�Gb���M)�XP�@��G�z9���xf�C�����"]%W���G@j�*� ������x���m^�[�^p����X*���%�X�!��}\�G��g����_���Z�EnB�|pW�Z0���-�� UxJ������>�Z��^ϰ�=���g,��pR'�я��c��k�- �0���N���-'�ܺ>�*o(P%m��|*�y�<���^{#���c_>��Xīl+��)�}��P8��N�C�"�J�W�����"�ת\K~2X��J'�4�J�@�x�?1�	U&��þ�� 5��
������[��d�u�n2|T�R��s�o���s�,B�*��&#D�8f����-�Ԕ�����Ŏ���B�u�_֯�T$�"�=��JB#�Ǿ+�C�n�\JI���2܋����]�T�����nmY^��U�ats�,�w�[|�/������ջ��C�!C�j5=�9,i�9�n��UŬ���Q?:]F��?h1Q�mn4JD� ��{��4�j/�R~
�e+�(�}�6���ԮO���T@|��ϛey)&�;Z��MQS|{�ь@�:	m��e��ד:B	�an����7�l� UhW-t�w�ҧc>�>v6����_~�P�݋t"U3-}ݥ�e|g}��o��K8�+��4e�r�S%+bE��q�^ ������R��>K?��M�*a-i�>�w���8�>�Ş7�R�\ǲv)SUq�8�g:1M�Y�b����o'Z��Lz?���O��Z�%HaP2k��J����ZP������z��� �	�.���Q�1e��0{G5n���=%�E�oSP��͸V-�S
�{B��F�լK��r��V��L^z2+V,�@J�����o�}'�]����Ry��@��jW��� �o������Ќg�Rt~.\[$�rN1���u��=g��@���&#����8�5�n8�V����<�ck���H��q��x9���_I
ك�'�յ̢\�ɾ�́�|c���o��e���/��N�V��� �/�im�!DIԦ�B�z�C�20�/k��k��H���ώ&�n���
�|�D�taxI�z�g:5��u�_���C~�r������g���XXFc��U�S+�N����f��C��*������v��YC��3[P��z�?{�9��Ѫd���=�+����"�0촮�R�(��K&���ӕD��~�c��,?�`���u�Mi��"V�{c���ɲ��ϸ;�(�(��r-�n�o�[iC[�I���� Y�^����r��>n��������୽��<y�?������N��/�;(P��dT`N��T�rN#(�UX#�>�,tiW���z�L�l.b�"#}�����3�0Db+�:n��]Έ������Y!P'ޖ��F��p(ٵ��}��|\B���Nlnza������{'nRM�8�++���Z�������4�9�D��H�O�RO��׉��nI}R��0����S���=q�cP��<�tp��>�ד8C�Mނ׏�F�`�f[�^�G�;]v���q�R��W�ɜt������J!��:<x�/�fL�Hz)�M ���}�`��aP�S�8��n�1�$4�I((��"Zr���?�X��`��!p�c�[s S�qY߆����z���N��J��_�5�fb�
���TOM`���^Ej�%G�ʉ�=�B~���1���ǁO�٪�l0�ʋ��Þ�� ��h R�C����Q�'kX�ƫ/�Ϧ�V���� ,v������1C���ϡ5�k[�r#yh�6#�њ֎w���{o/����8#���x9:��g��_I_W�껊%t�h�#8���gd�s�P2��q.Q� Oǥ@r3��o�J8�sw�5'�r���Dj͒�j������+�
/dL_�0�LCeS�qs�;�L����{���92D\�>h}�����rt�e\��E�o�� �T&���i}�Cb^���*�!d;��$�e��c �����bR��"��h_)P~��8�2*�����*H���eo��GHo�2����U�i�~R������?�_f���ɦ�(Z�с#�ӽ��b�lH�1�[3�Wp�����������6}}�,�a$��Ʋtb!_(��o�,��������\;�Q�trr���*��o�j�ߋ��M]��~k ���E��t�?���1�\��&�l�a��A	�
ʾf �ڞ����36��H���u�hbKs����͝����薔8��<�M� �`(}�gXN��i�sTdY�����9/7l��xp~R�N�uZnW�wV�C����7�fa\�5I�忐�m�ys�$��ˬZ���I-�
$V:�n��En�.Ks&z9���*�yp-KL��"�ʣ��a:�pc�e)Pui[���9;�,�3���H�^�(�Xﴑ��(���~��(���!X��-9� �ǧ�����`���6�;��{R;0 &*z�X]��bم�O��Z�W��?z��یt���zCz���0pI�C���ՅC�t�HQp��e�؊sa�>�,�TL�G��|��
u���(��� ]�*а����e�%�Ӭb>n��A��-�!#B��B1� ��"�ރ����.}��z	�(����u_z S��-��B���l5��
\����D�S!�fM�C��y�o����k�I��[�=t��>��"�Oo%	���t,f!"���[�$2BwsO�AJ����SU��dY�7YvG�6����4l6�G텲�ӷ����X[��!���.Rj�@"0�^����r�¼��� %��aT{d�(�����J��n��Ҵ3�q?q�����4��d�ꨉ�	u�uX�~WXZe�T��{�*�vL��E��GP��7 �u��a�@�\v�|4�Lk��F�E�H
�N���QlQ�5$�,DIkԈ��mnا|3���cē�j�/$x�L1u^O�����{6UH$�W:�n�UѦ)5bұ3��2pPPRM�0� 7+���[�=_PvL�x
��]s��s�\�y	(��l.�]Z/V���x��T���)��"B�����ðƪ�s:��ǎ���}Q�/e�����KGEA@"[Eh�N�[S��]О���ð��$�)�tm�챽M�k�}��՜���P�ka�D�S�C�8zG%�6+�5���V<���&v[�p�k�M��i�����[�F��z+Ub�Ҏ�G�Z�seف��@>�M�"�}I�-ˆ���P�=ʩ��9o���г,B����%C�	���ߏL}����Wa��6 '}��vY�q���Z�w��z�3�9�7MM���sx��G�����/�2aw&����E��n���NvHظ��;���ԙd�Y�	�鵂�2Z���U�4.���O�?��{mDi������x{�jS��^�[H��Iw z�^1�^ڊ=����j�z&؛��6g�}ˣ�c��h��D�oY�?�ɍ�
��S��kf�g��sP�K�F�]yNj����;�\�&m�xy�˝řh�oD�d���	��'���4��^N@l�Rnc`��K�$�Ȑ��"���ߟ\�7�!
�^�o8��ø��[���.}�*��淟�܆��#�S��qT~7�>�RU1��u%0 6�R��AvB9�mX��M��� <&�ڱ�=��pҬ�!gT]_�ymS ���IW�S��T�M�0�MG�x���-���%k��Ij�����]I/
:��+R��a����~�&�(C�H���XJ��d��nW��ȃ(n��f��^�_�ޒ0�i��u��_�E��	ૢ�r�lԣ��1E}d7�L��$�s��V0�<j�'��Av i�;�ތ�\��@�5P��Oڋ�����X���O]0�a�/�'*���f{w���$���$�o�*㹸!�<r���
h��.a�C.�enfS��;k߈ɲ�CFZ��ɰ���2��Kȗ%��b$KK�a0,$�R�-]{�H�
8� J������W��fw�K�_�v��Euv�Itu�<;c>+ZA�!�z� Ɲ,�R���V׆����&�r��{������4�PNΓ�u���f�R~	�ib�f�*�O;�Zi=mF��� D��˵���붌�
j��i͎�v��V���2�ӱ1PM�C6�m7���(�@9��\��J�����rz[�6~�j�2�%þ1�Bب}D�/�:����Z�k�ΘQ����@�ڀ���t�3�l�a,�k)��ʂ��%��5#�U�!r��mm<��0����a��p��.jk~3����ja�.~��4���D!H��b2C����x��tn�ۙ�]��3��x�?Y-�� [��}��f8qo#P�j��-=�/��wҼQҗ��ǻ�e��r��Eh�#��Z��B0K䕻Q�}��S��V�\�T ���sU�:���ĭI���\)��Y�v�ʏM`Z��]
���.�V5d�E�-/(
�<*���6V���7��4���]�����x*ˀ�Z��%g:4�ڃ2�
����
�E��w�O0���qS��{��Z:F�B!�A���=U.M��sV�nE7���s��	�$Y�1}�j.Կ��n�AI��O���X1�r3�<�I)*\6嫃�.�AJYz9$H�yl�!�-�t!�G�q�Bh��OQ�H�A��x��YW�v;�@�H�T��/�J��j�6B��h�Z�8�'���G�x�M1�}�Xw�nṽat�~45����b��pv�m�S��4�Tvѹ�9�Qg���0�$��l���H<�v	�0�#�:�F�
b�$�@ϡ��_��mۯ	p�b��tZ`ߤSB�f�����DM���|FL1c����c���mMkU���N��!�S$QS�)�� T��^f������L�˸ ���w��0��.�w��?�IyQ����T9j�����������9� ��iZs��\Ə��m��;�ʙ8������1ccn}]B#�M�-O{��x�|z'83)p�9�!�3r%bϠg��=�P��|� L6쬸�s�XP��*���?w&�mmri�σA�'K�ueI<辉�����ܸ�̍���Y��G�:�@�^�Q� j����^T��d��$�#o�u�CW4E1���R�Ż��ނ�.7�<���N�Q��?��@=�� �Ç��E��o���7���k�bjx����Y7��<HD��XF.���y2<��04�pF�%����zk(2SU��k�����&�1hU O�:\���ϴ�s��C�ͩ��ef�e1�����Wn�j8�2FBO8Ţ����-���p���	��IG����������}q�(c�{���y�ɼH�_n�o�Q�/�b��_|��l6��xN���h�ef�g��cӾh`�,r5̙������:>N��;���m�s����4
0^A�NhԔh���*��w�Rـ&�R������Cq�L��{Su��u �C}���l�A}J�&����˛mw�+h����M	;�S���Q��iͳ��,�_�!Jiֆu���/��:'�Ձ6޾r�m}���qAAg�Nj�U��m�*�ا߿Q��=�xCk���&x=�P�
�|��'�ƨ��,$���Z�-j�0��н��w16<x�Ȳ�!E<�� �a=7���⇶n�2�e�\ Yr����1XR.��s����y���-��c�i��jɞf%����`��:=s�A��i�?,ʖ����'�h��J:�0�4};ve��Wr�	tp�; &�����1l�zUm>i��B�,5e�t�N�vZpaD��M�͝�r�e�	�p�,�����o�L�}Ɣ�3t���F���dm���Q�5��wS�������)_�����wq���Q�t^1���?�	S�<5��p�;\K��7u�M�]����[�}V�ze%�;�>��^�0�~���i��VU����uD0k�Hn���fu�;6i��'|�D6^;�>�ǤQE�V�u!���q���<5�����zB�$d�W(~+���f��|�����ړ2G��m� ��?3�V�t'��|���sV��	ƅț/�{�"ľ����/�2�of�E������+sSf C����L��bi��:��A��>ng+Br�`��g��:��X@����q������vq��/e0��2�k[�o���<"ꢲPtE�r挌.�D�L��&h�*���2�Fh����_4�_�2m-�<z��i��bN#������L'��-G���[��e֐� ���	8��<
E��$����X�$֕M�=�-
�mn��U����h�_k���gU�f�
x��i2𱉕��n����x~�-�~d����IV�"�/�&qu�f�x��Q��/ _�t�CP�����cq;\���G=F���x�����I�6ن!��-z�Dvpza��8�Ff�b晛Ƃ�$;;s�S�R�o%!����J�/�ij{���H� ����~��OȰ�h źS����s�Cy�	��X�G=��s�HARM������l��m�s���-����h,s���w{����n�p��zop��@'*���THwڕ��:�'ˋ$�*s��"3Pt�M����i��>@��DbOaFPd�.;��򦪾��i����U`g��4�Zv+^� X�agt�Q*��V����kR�ANQ�xB�܈,�~���8NU'�w\N�E�6���f&(&��v.�!{J������J'�K��]�A�eU���C�Ǿ3��E�gD$�G����$��Q�K�íUx87"����Q���0�1��I�Z�����y 5��	
d��q샐�;��4J�\q����#p#8J�
����#��t��m��]���YO��?���lN�©�@h���ߘN�/`�Bb[`FWO�\�v��SyK��ೡ�%^5ϓ;ďp��v����W$s��r�Ӟ��E�����A�A�|p�����w�r�I�w�7ԥM��z� ���]�nMp ʻ*Ħ�s��Ɨ'B�g����?�jQ|=�����j]�tX�E�l"�%�.��(�pO���#���rB;����]�CHŒ�Tew1��V��M�8���z�W1�O4�����o=��V�9�y���n$<��2����';��1 ���G�&��@	��E�Kbg��@)sɫ�N_�&M�Me3}�{����|~s��,��5<��!�V�n=~�|A�:?2$���Y������M�⇲�����6eс#��c�CTX���P�䛲�.}5O�F��� U��V�S#�O���Z�/d�L���V�ő5��V�>�pZ��blᄴ��Ff(��P�����^��k:~��g��CM�/j.ŋ��(g�^�x'7D�P)vH���>F��ˆ�Mw
�F7e�/9H5���ҧxP�Lz#W.�R�:�a�(�s�۔�̲t����<��nkw*ZHb�"�x�J��o���?L7�X��({�TV�ՙ����X�&�oF�VЀ�0{~�h����ǆ8�HO�a�C>)3��oh���y~,[�v���k��|������Q�����3��`���� w�m���������9L��Y�"1����-�b�"�_A>�ҡc�[S
N�� W|��/p,`��Dl%6�*�&�̼+@��E����k����+���U��sx\C���^�!�C�s�|�,fIU�l�>hE�Gj�զ�F�1��'�{Ԩ��ԡo�+n~#�b�����Z"<���Sû�ɝļ��JUz�^:�$��[���h���A�zo�4�Y�\3|�.�4�pvM2|Yw��:�k�a���ue@�)sruM���g�O����/-�b6ѫ��x��P�@�9i�����}��2�n�h5����)d���
֐1���Ȼ\�$e��1ݣ��T�ѹ,�R�B��4�E�Wj�Ǥ	�i��c�y��r�����`�M��&�[����ݡWD0�Y}(
��+��J�[X�r�>D�ï_V5�Fz�P��StJ�_�
�l����x�/Ӿ.�2�$&/�����������`t��ɟ�c�4�jE�jRרA/롳"2�ݩ'@�wR��g���,���l�)G\k�غ����(R�*Â@��PF3F7��Y��U;Bg��}���������
M�Z��b,�p{\��ٳw��>cS~��Ƨ�L��/�[m�J��w[#�ْ@%��c�7� \�Yk�-ﵿl��U� �G�pO?u��N����`�n�'�ذ
�ꮭ��&l�8����l2p���`܆g�:�/?��Vf'���y��2��s� j�o�BuJ�!�%c����
z��Y:�9x����C�U_IA��ye��p`�$�(ꬕ>^6ۃʇ�_�d���W�s� ѯ�&}O �|�I�<�S�"3�/����?�G
nEi\����BA� ��?&l��h�訫�J��<tU�\#6�f��E�(R}M�]�_���0���_uH����c��z敌�)����Fy��� ���劏�e�4(����-��`�/L �لtӍ��uRچ�6-\iP�M(�[j���E��4!�� �m�.hx���"Q(ў�!i4N}��t4f�n�\2�>h�0�(��I����D`���)�^�y+��H|�����3z�̼��5��L<���Ua�b���< �=�T�Lf�ng^� ��µXy{zF&�g� �م0�cL*�8&���?��
~PK����0�b)�5��A���!�yU��&V�:Z�Q�,�bW�2��=�>#ۮ���4�V�v^�U�Ҭ�l�a{�FW�낛	�*�vN>��C��D�}Z�Y�#=,9Dɀ$��Ƕӻ��F����P�c�T�SdM_����2��9������Ul��PAI�����=��ߍHϭM��
8��)�[����*�����1����m�1���;�O�a���@����-%�dЯ��r��V��(�EQ�r(<b�\=����IO/;�JQ��c$F�>[�Zh���$nط*�S�����F��s�.���K��5��G��_��|S̆Y��=����������?��i�z=����F>��e��-W�p���ݱ%5�Z�O����_E�8���E<Ȧ�+��/tH�׸�s�)�É�%�s�if� "|r�B*�+K�g!��o���xK�f!�s����T�S�c�,<��O��@F�f���]���X ��&~�r�����T�c��������m�6v�h&'(!�e�,�ӆ�ٔ=�Z	���PX��t�T^{D^+���P}�_��|/����.��v8�6P��g�)����O3 �M�#@�����{c�|�db�L�ST/�uZ�KFvX&}!-bRmZ�HM �2�ӄ[��q%K�Ll� A�Ûh@�꼉���[�Z��`PR!��Q�5)��Nkw.�r�i0Pl�@1�5z0%'��%�O�K߻�並��|C>D�!�Q���4Mzi^��җ��f��j��B����ԗ�;y�.�(����|�'3�oQ��	9�r���=����6�@�2g���k:ȼ���E󉪆N�B���*��Q1hd�!\9u�L|����-��
F�{-:N��
��̦)L*���s�)'�

�=���@sj�űٵ�~m��a� ��)�E|g���H���{}Utiqoغ�A�T«{~�M�2�ۦ�2J��4�+�Sw���և����T�~aCNQ9iॷ;B�~��mJwgi�,��`,<����u,M�cq��R�_%w�G�458��k��w}�]��G7���ݰ6y�����k�J���P*���u�l~���I��I������i�j���|\,�&��4i���./����F�|����Q&�H�/����w���;}~�%�+�Zo�\L4ҞF�*�~^��j��r{u{6�P\Z�c�]vx���+�f��\�R(�*��40��
5Ш�=e�ed�n�����[	�͗�t����0ס�>}�jx�V���5���0�����+�/ȿ zG��n{a���%;�h���z�r[7��6��P������ ��(f�=;��m�8^�Ɏ��8��9����&ԻQ�T��
��D$�MN)E�?�I0w�쎮���ws�3g4Q���:q��jc<�z�����G�E���-�E�%�Y���6��!Ή�����]���_
"1/��*
F�q��s/Dp������'4Ob�z�[Y���(��ȳ�R�m���qd�`����R�&�DG�"-r�{�}�3&O9�BFd��b#J�bM���\��龶-^E���lC�C� � U�S�f�FO�>��e�]�?���3�U��Z� �Ҁ8�n�XgH��j�0E*�^9:�Җ���%6��;*M�w���=�"�3�����)���\�L�(��Y�-vS��{�����^f����s�ŗ���zYr�=J6��q �[ͻ�UZ�r "%����{.��n�:m+��Ự���C�0�'����6��<������<Pnw(f�F'�W� ��������~)-�-���e�5����RΰVƉ����i���]�!���7��wZ�/~�p���ik���<���̥����Y]Bw�9y����^_��+B^�ҪvĺLP��<+/�T�1�E��)h|9̹�}iLw���;�RVm���,��ck�s��!G=��9���Fm4�ޕ�'�/������(��JB3m��*Gg����<�L�x�;Z"�)�S�|!$�?��bf��V���}�=�F&�$Quҷ�:m�#�<�A���M�Mh���l���J����;|3��u����V���_(�7�+���d���������dɑ����}76Jk��4���1nGb��N��i��*@`��s����OH����m'ݓ��\q���"�K#p�F�2�i����͛�'<n4��J�m��fy��M����9(Hr��
98i���1�s���vO�cH0[�m�i���n�!i%�Lkn�B���d�Ɛ�0t���F���H����<'Nv:�n�u��ÿΗ2/jh��p��l��v=І��(�푌 G�OL�jG�D���-M��Kc� �<�S��u�Zl���{1�zS"֜����@���������s^��Y�Cǡ��[��>��J�B����R6FF|nqBN\��ȅ���i��l���*��/�yrPf��{��O�Uz����s�/�J�R�d�� g�ge��d�i�>���h��������k,�pi���N(�l-�ܴ��B�:owYFZ�&��A����o�S�tcy�?Cv����b~溰�ҤnDyƓ��o��Z�$7��qS
����Ä�@��Z�5qA+W/����	��b��,�j���;�1�G��Ko�����G%#ȱ�ZF�ɱ���2T�˱��V�E��\�n�r�c��|Eo����/6ʹ��0[2&���r�-oo���>b�>t<�	箾�ɱn��rm�e�X�Xt��%�0�������EǸ�Z��������#�+m��N�h4I��CKh������]'QZ�m�P��G�V/��Ţ��@��W����1�j0���Z�8��\�����f)��ec���&�gK��#?V���v�e�o� ]��5ǍW�y@D@�=_��.i�tU�l�1Ѵj�ˆ{L��>�B@-���z!Z�Ϯ�����[1������r�%�	g;��R*k �����*8��8���_ќ��~��+;�nD���I���Ֆ[�@��Za��Iwۺ\���ɋ2����~ϳ���F���/.��ׁL�h܈M��H2F{�9��oHMD\��)Y�t�ІA�
��K��V߹���R���`�C���W	h���r�������8����e���p]w��L>�O'q0����rĸ,�V�]��RC��$I�T��pĔ|�}F�d a�3��P����9�{��J>�����g&Zʳ�C�J���O~e��6��p(�Q�1�|�>��E�e��\`�.�X����U]S�*tV��X���&��AܼN
�K
%��� �'�|}�:�7��VH�o���[��f��P��@GS�Fb)-��Z���o�WY��I䯐�����#����쑕6z0��U@�c�HQҺ3I�:��J��E9G`'{"��!�R��Q̞�L��/�`}_����M�r�Q1��sym��a�IQ�A��ԲE�@u���cZ�6fiZq}#��jQ,9���!(빗��jB�p69���l�M�1�G@759"V�$�*OF�T��S�T�R�j�J����)���]�.j�c�R� �����4��+��
'%F�t��.hfÇ�*�������b�W���2
�@W��~!�W��_z�4�r%`U�Y�����#)j �V�U�S�$�����!'m��F��6qT����>��lf��{gʂ�!��6�$�Q�-���C��G����j;���b��hft!:*��,e���x2�VR�F�_��C������8	Wk��4b�Dt0I=���l��h!���O��O�1�U4�������[�w8?"xv��~��0�yj�1$�����#{zl]:����A�YvQKpW�V���V��Z��b�H���0���=y�==k���y&�{d�鑪��c�ֈ�A�FK�	�$#��⃞��t�'{���4����D����/���W�������p�� >ѭyޠ�FN�!	n�R�N�8���֤1hhl�
�N��)��u%�=���+e��745�����!�7{�b�i�����4�"o,B��$6�u��IZ��*&�����b���!�	d����oGrqEr��Yf���AK��������y��s����d��RU4k��N�qKu��}u��J\�����52�(�ϟ�V��"�z~��ϪA�.�Uy�Eo��c���<�Ɇ��!<�*�f'C���^o�%*o�BǱѪq�]�I�H��)	;�^�W3n��>��ҧ�E�����_e�bS���:w��گ~�k-(�R�mʈ�&˰�?�� ����X�f�C�  ��չ#���rp�	���1���CU������։mqvFO��\C��l�Ǹ^uQ�kf?T�ʢSL�w�s����aR[ �$�܏�6���x�xnP/ȱM[���a?�z3N}��뀁r{vs���H���k�,��3=g���KL;�T��hR�b˱b7:+�vұ�&�\yZЦR2�Ǩ�  ���azZ�]�9r1B�������⿳V~���K\;�x�'�{fJ7��n�~S�H��	��k�J�:*�9���!��KT���#o{ ���>��E�2P��;V�5��>K���,�}��^A�ˌ�_�xDu;ڑȜf�C�3���pF|$�i6.U�.b"��;.v�k��z6[���*�U|� PBڍ����ez����o�͘��Α�"��}d7��薇�=��2�?v,(�"�xY*�Hdj&+��W�86�е�&�yS�2MW���dF��.!��u$5�,d�y�4�n�����:�f���Bջ^g�ʭ�V�M ���I�zN�l��l���8f>�}��F��X.4����0VU�P���i��+ɴ�j�\�q�	���X���hmj�`U5��"��<��y=�u��#�H�L��w�D�SS��l��-��r�a��Lb���!�܇mNm��߻�\4�����k��I�O��ۓKL5C����qK��/�A�Lp+C�Ȗ�h��s\n�Υ�Ro	<L=#f��J;�]����8�4�b��ݪ�����\Ŗ���v��%���3	Z�X�'�"�Ǌ9��� ���}��0���_y���o[C=e�5�P`����T�y�n�a�y��B<U���"1���I>&� _��{$�2F�|v��q����P.���
��s9��(��HK�V@���칁�0���0'�s�+U�w��U����a�˕4�������	���EMl,��~Ƿ�E�� ʄ�(��{�����1������Z\��u��Q	�*��o�P"��H�N9�n���d5T�Q��TkM�xu����5i�l�gW*��`��GT�<�̄��JF�� -�i(nAC�z��.����LZ�P�x,Ō�x�*J�gFU�����pLB��╼�F��,k���H�Z$�̥��!�B��X����T�����#6G�rrsz.���?%l��U�P�t�������ƫ�$�BJH�}���&o?+��e%n���H<)��=��5$�X�E��j����}'�:0�����xGmz���|�U�~���e�] �F-M��dE@h�����϶��T��kg8�MR+V�^�� ̔�޶D����G偾�P�lLB���}�$jL��ЇQe(��2�/p��|[��2�\�ar��w'L꺟����`�f7p�̶��0��M*s�z�ؚx�Ҏ�e7a(�7�)��An�?Y�j�7�R�j�	I��ݺ4g;\Ie֛�k�x�Z��A.�Ȏ�p(���(���}���6��ۙ�� �Hdչo]�4*��h��}�'~q��F�k	�����C��5&�0�D�[�u�Z�v�Q����"j���g^0����awg|L�	��}���I�b���}�c.���&f�d� �0[�5����>1��a�JS_��rw����E
 ���H��i�NFX����;ޣ�r�ON��2�1�dA�Jcz���2݈<�Soǜ5�� �0L��VF���@c��~��>��6h���lJ{otz�nI<�ex�Ez�8�TnM-+i���{�c ,���/�����fSl
"��=�d�,WR�?�}����b��?P�C�HV�SyF��:������(�'�6�3���ؠ� (�Ӳ���@��!n����9��Jh�z��9&�f<�;E';1i*�K{��?&i{|Ar���Ŵ)�2�:)�ڷU��[�eMm�,�V�AJ�!5��D(<�Q�sg��`:�{N�Qjc��yJ�cgw'��!V�N�d�;��B��$UL.-���*2����p8�]P�Qr��}zhh��⤽d�{��P{Yx�����/F�F�w��r�J��JV[(g���'c/(_o���x��A���E8�������%�䛙����Ĭ>�v(ZGP]�.'�tD�[*�W`�ˑ��X���̣�p,f��ϹYH;���?m%T�cAd ���|:oۭ9�4d-���*�냗d�TF:J,8%�w	�KO�
��1\��X�˪}\R_޺|l�����bvc�������{�4���/�n�S�}���F�1��+$fiQ����"/@u��o���i���$�Rw	]u���.XC��E�,�/F�@ݘ�Sf�2��(��� f��>��uv�*� �}�`���f2�4�����(Q�h~ɨ��WD��Jr�-�
�2�Sw��/�GH�;� ^��m����KI�X��i�H��ˋ�lbő}kb�)��7��'UJ�����Ȇ���=�"s_E�.�8�U ��y��r�v��҂�5GWɨ2�g���x8�}BR�;���W6c�mo��C�rE��B0��r~5I`-HM�R��L\���KDZ*�3n&)�P������k��ۭO�x��-s@�fq_Č���}"@�{v�V9 8�B�� �
��b$��,a���{4n�̈�g;'���S�|k���CՅ�Q�� �k��xik�����"�
���I��Y�n+��p��������>�1���A�����N�2�
O5m��m&��hǌ�"��^�9=k�h��ޛe9���Qi2�/�������j���励.�Uv�O�Y�h�	Y��[8*X����,0vEKHb�����S��,#LuŠ<���+����f�F�)- !I�PS���AB	���dކ6=��0_��A�DvP����m|�E���6��]:���'�8֥��X�3�!FS.�0��>3�<Bh}��ꃶ�n%d��u���J�7����#�!��b-޿�J)�|ð>	ݮ��������G��F�e�͆��K
�yI��
�;��˚��
��fJ�q����/1��[�Lq�����mX�Ĭ 
<��U�;�qI��)5�"�C T!�3�������x�K���ګ�#ch��u>
ul'�/�z�v��J�C�w��uJ J�D0����|�<��'�Uԉt�u,�����i*@w����L��`Pq��:�Ǧ�E�8ݞQ�"�d�=!j|΍�XL��2�3����6��JXiP�3�~��R8�dR'{)L^��{L������<����b�V	j��#֬��a�� e�'��A�$C[Ombma�,iL�&����|�9����lu��˳'T��R�5K�ƷFf*X���1�����@c��!{~�偷֘���q�a9[�+��=��]uҭ~W�ab��!g'�NV*Wl���-��Ӯ���*
]�+�]U?�����B�I���(�Et�8-�"hۊ�0qA�G[	-	܊��FRO\�n�g͟���$[�j~-�?@��i{i ��wғ̎�p^#߁�r��������9+�������l�D���P���>��E)=EP�z�����DL�^�h�EtH���^��?��rB8Z�����*v#8�C'rE����~�^i��^l�s��DL�SĄ�ӛ�T�����:�|��l����걸]�I=����|cz�K�����E|=gXcG)�#)� o����1t_�X�QgL�#��	3��q.�UD�1,�4��lrr$�q1����<�rYZnd���i���;c������!������o��D��/8R@\7��B�V0�FhK����4C~��tTSz��uꠔZ�O`��zL>�W�2�I�4\���혅XVv��m�0��'� �,
ډ�ɵV�<���.6^J%\��q[4E	�;�OnDu<K�l"�p�����2�}����-�y���P%�8aa�,#@��TV�e)�`鳵^;��E�� ��4M%s���x$��3&PX�	u9:�~�Ziò��t�����
�KeH�EF��
�7IO@����7ڠ��	wϺ=z'(W��Գ�(�)8�O�8l�c䛘�,ZhmO�nsj w���H>_��F t,��l4�ma��YP!Q� h^q]I"��A"XZ[ �b��M�|��_~Yde�Ù���j v�V�X-e�`P��/ߤ�mw�o�Eo4P�@����`��z�o���I;��-^�b���T�Fd�\�a�r,��7��v ����~&�!ht�o����s���j�v�1B�).�#��)�:�����s�zꉙ�ƫ�g�p���ODZc4�P���^iO"�A��ǔu��;Q��z���.J���^D��>��'�)��l�sS�_^}<v�}1+~l
+�1����*[���[U��)�2xo�_�"���qW���� �%TG5��K���1b�F_F���7�;�d��S�����xqJ�_�E�M�
r�v�Q,u	���~��p�||i�FR�@n�Y��X]1��!P�GLV�4��~m�FIV���2(_�LWذ�q��S1N��EL΋�)T�|�fg��x�˯Ml���f��n��QzK�@���ч�G�e�����S��r�"��������fэ֤������ᭀ*$�M$6'��lr� <MoG�W�C��:��b����v�t��M=OQ`7wȅy�1ֶ���V�d-w�v�JIj��������IC���|,�:�Y�UV��b��znh,tX6{�6o9J��֬��Q��=;�;	S��
mO�v�h��q����2��w����o�s�2��INI�K}T���9nY�&	0�E��������阦�-}��c˄\{Wx�<��̣��ݪt�ʹͿ�����!CϤ������	і飻�Z��?�4��o�������/N�bU/��(���1iV<�>�037,�f:��V�B��{e�a��ؤ��;��\�r��uM�Qy��к��o�0�e��{�}���P f�T�N@���Մ.\�̷QD>lyQo�� ����`�t�J����/�����B���yIGV-����Hb{>��i�4�Ѧ9y�>�������.�9!�ˆ�TN��B|^9E�p�=�}k�i"���W�;����`�j��n��+���^��^:��y�$��/$�zT���d�[�X��.�|Ё������!�U�^��4s2�Dr6eWܝ�߈uԖ�Z�ò�aރ��\T�H��ġ/�3#N|���F�"�<�N��ޠ_�}�����X
�@����F��+�>�����؝��[Cy�cs��EW���3�����>�p��nh�b�1�{7k5!���ύp)u���Q��=�m�����X�a�S�-�)܀?���0����=�7�,�_�0�\;�	<�/n��q��퍱��u ��Z���x�F��L�y�x�M@ y����2x�DX8+J4`w��Y�_J��9y6$Jah�2++}����c;��PZ��k���`^�:|eJQB�1��M3��AhҜy����S�V S�o�w�q ���F���Y�"k+nT��9�mל����_J��j+Y��u�/
���G.�"Ƽ��Yg
-9���7���C��P�=Z�r\G��t���L�D<�٠�nb����B7��G��N��-H�1�_ ��+q��U���:c�_e��6?bE���;Ä+=K�������vj/��vf�����?A����A����1R"���h�;!��i�:|PF3���N�����[b9�8�}�S����oN� ��l�_�	W��j�·�4Jx���%��f���x^�] ܀����t�/J�d�/�W6��5�H�t<M�[Q��ׇ?0�f��l���Tm��k,�{��h�L/��ʻ���5�~!R�[T���-!�`���?)�\�+L���q50!Ҟu�9ޥ������j�|�.sR���.�{"b�|7�x��j5F������~,'�VUx[�fL2���C�U��@<zy���C"��C=*f?T���6"6o�����0��k���J����i����Mx�]ҙEN��x�e/���wUq�(A�l!�!���Ќ.�,����C����B�s�a�����l�\��'� �5fs�<�oU�݃q������!U�HaG|V�4e\��ޱ"[i��ɲ�/�&Ƿ�`�1��~zԞ����W��
t�f=5�ent�6C�:X�"�����D���w�R|%L����5��J�'aY�7d7���}������u���~2��3�E�so���}�t����R.g���0r�df}>I� �_���'�г�/��4����E�i���6	X�񦻲A+�$%k�@VH��v&�܈?6��|������3�¯F,�IO�����e���i��ӫ�P,@�|��ݹi��h�rȁG�5��%��!z�1�K7'�d���)���6��ˋ�(esѬ&GT{�rG���N�Ę�0�g���)�FDz0��?߬���{�蹨��ӿ�d�'��Ք�]P�l�.?����@��;q����۪�2��ʍ�Z+�{���0o<dg����U���8�����a}�!!�C���!�1Ӑ�w�J���DZ���8�;V�Px�e�=3<���"�K�o�����8;E3<oNk�X�4��׌��TH{��w�q�W��-o�N`r�	,8��p'�.�ԑл�0��⭀�t}r]x_tVZ�B	�D#Y��	{<�D.��k�v2�l���u�5����#;?��C]��s�ZZ�r�ɾx+qFњwZ��Y�Lp�D�L��f�0��.�_4'U��<��z�͓�0��ߒ��^;��|՜�>ɑX��ő�²�>8�},�EƎv�qݴ'��sa�Y��?��/T�\p"�
k���N�DH-�`��M�2T���1|�<�QYq\W�|y�;d9�[jE��c
x��! ����gd��o)�f�}����u+��`5�R ��#*^"`G;
�&X���k��Ĉ��7]�+5sCoڐ���\B���Iآ�~Ƹ^�����L%*���a���A���?(N>��!�˄�#��*~�pQ��9���@Q��̥cJ��屚���� ��+���U�(M�`+Y�&����	Mb�$-�#A�2KgqR�!���`x��r0�%���I����G_�]��e��.�;4j��r˘U`��$�2�����A�Z�7!O�	sH�cp�,�S#���>���u�V
I��~�'�F�p8lC���t(D�8͵8UJ�b%��vgл}�=��XX�����Q6>^_�	���]�x���U(T+e%ē
*|���PɃ9 �VK�g��|�Q���]�Z�~\���2�Nkg�ϟ��Ds�4�d�c�#жA����`r9��`�U�C�?��0��͍��D�t&v�kl��Y%�5F	�!.��:^�kX19�� E![�p5u��M�E�(JCe�(+>�Ψݵ�*��ػ���Eپ�J/�å=�u�����mF{�<}�%߾�����a`.%��ƐB;�x���Iƺ��$���y�ud���o��Ovq�����P������?A��_�!e�<��gZ�,`�f�W�^�������A���4�|�:���H�E�U��p_�
�Α����zz�C�8�=����}�k�ε�nxо'�=ܠ<�db�����+Ë߱�SXU�/�d�,?�{m����">P+k��>r�����Q
�I���)�����N\E�/	��i@�緎��E�x]���[�g�9�2S�!�D![����#�mZ�T�\n�z�{+����U'��z�r����d�ch���(��EfI{� ]1m/Y���/�;���T��>u'8g�D֪��9�6*�-K�a�*;ns�E)�3:E�?;������^��T�NV� }FR���'^M�_DZh��&X#a���ǿN��ڈ&�X��ٹ�����>b���� �'�g^�"[�lq����"��4`m�DP�yI ��`@;�pi�Q�yL�1��	����`�\K�E�k3=��@Y�ĳۦj�m��{:嶹{��R*Qn���R��[6H q�E�3�/�J�
~1�Ξ�����$���^U>Bx>	���#���Tӄ�%�Ub_>�Ocn,�
+�%�!�h�r�t)�<��/�
d��O7��"am�@֐��X���ʥ��^�k��JC��a>u>`K'uxc"���6���#0�/Ռ�@R�� v�*���T����0*����~�cG��em��M��B�_Ȏ,��ٖ�ؖvEKa�1e������O�(&r���ܨV4{)�Q��n��9����{��5��.W�2n������2>ݺ'![��̘��᥸�M�CZ{��������cx ��;pS�
��s4*���g��P�<���99+�
N� �F4w?���L��a}&M�7 �K#��F���0��Ž�Q* PT�e���/G���kNP�~ܝ&��R�.�6ȥ`+Ib�g� �z_b�4%lY4�z�严t�G��"
�o�����*jv�T��b�w�����[�=^[�L��gr4�*�� 8���2m�2*:g��lqx�����0����R.N���ܩ#�,ȫ�ή�க��!٦wfYq��u������kǤ�i�v����BҨ����n޿���o=�T�����7¿a�
j�ʞ5��ǭ���ŝ����I2	���o:������fpc�\d:nT~;��6G�'����G�����q��!f=5Φn���q����g�8���W�M���q:yB�� �N����,���_�śN�<��.���(�XY��;Vt���1��гAm����/(("��c�	����;�\~��}�-a�$	�5�3�#��~���\�$oi�������* ����c��]*�����_=����_������~s�.�_C��������f��X�w�K�bK�a�-�Tη�D[��E�	��G2^���	4�|��9�(��r��z8e�V��!WRB���񋊟'��C	ԋR-6�پ1�.ǶS����!@ǚ8�k֡��z�^ Z�0�/�
��ڐ[?�-����[���X���`,N�'{A��O��z�i��C��qI]�t%�cn
�"b6�t|�����Zj�_��&��F%&Sj�ԨP9�.�S� Q�!�^͝�^�'�J� Ov�����+~��T~��m�{�	�Ûɩ%��o�:ey�փ�����K8��Ӳa�yP���.�Q�����R_�«G0h�rd���`֣�
;�L~��2}&��sɆ��h*q� <=���~Z�̋sby	qeN.��Yq�Y��B�a�zaJ�#ʇsg"���J�45������R�{����@������^��s����^dKR�:�,{�U8J�]@Lɠ�=�~w�'V!�3�4��U��(�������L����)��g��7�I�*��/�zu�yW����{�fa?��w�'�B������Ld�m!8��q3�	�C�q\NB�5�{�Cot���M匓��6Ic�l�XS��3f�K��elo��ϴ�]l7o��0�{Y�n,��e�-_���g��qŜ�����6 �P���O���M&YD�l	��4Q�0J�S��}Q0+�¨�8{⡥5��<�C�THc�0����'��B�f����av8\�W��P��A�R^}�����?�Z��~�rS##�z�y����d�fJEsi �HvT��\dJ�T�-i&�\i��cQ}4�P8ׁV;�S.�>|�Nş�17$d��j�K�����^���J��C��8�UŞ��T��B��w$��t
i侺��[�*%=���F��#R�?�\mm6�B[{��vԀ�έ� ��ٱW��ke +��o��K)��u/1j'�%C�~5s}���U��S�¿��̦��}�&�Z!=�;ڲ7�vc<E<�k5���D"�����r�O��,���6�?���ڋ[8H�l��?-\���k(����5�����GK�'a懫�~�/�˨?k�b��dӯp�B�~E1�3IQL$�*��
�YJ�ǿn?Q麩>�F�=�&P`���·���B�H�]���?)��}Q��ݧ���H�oG��W�jo������SPAgw��擑��`�{��Nr11��83��~ �!rOP�d9ٵ��y����l�f����$��La|)ክ)@}f� ��7Lk0�'��se	Y��ץ�6�������W��X����%k�-B��iv��ßt��=0�>��ܽ��d�D'^߿��觥�S��n!1ں	�\�!S�-�Gy�\І�u�56�8xCkn��z>��[�!f����ͫx��Μ�Wx ʔ�2b��EQ{���(���;,?܀�,Gz�N���n�Y�'q�û��f����i�1�9�*��´�6�X�>���o� 4�.�\j�E)1E:�˓Y>Ԯn�R�))����0F��B[ ��F�T#-#H��"�� S��[ұ2��/��Y��U��5@�т�ol��Va�S�� ��3�b@C8�)�ު���̗�|��u3)5��[0m�daRot*6v>\�W����ŉ���F�e�2	�E:�>�.MT��4U!����l�H?������ ��ī���f�A�R{��zq��^^���8U�,�?�0�!�ꬮ��ErR+E����z��Q�9��^�%j�Q�E��ٙ���i��g�fsS�.Y��;��g�(��A%�s�=V�6���p�8����-oJ��*DZ�sq�8e�h4W�F��o^I*S��ESfHwaմ��,Y��r'�2�5/    �Ĵ�n� ������z���g�    YZ