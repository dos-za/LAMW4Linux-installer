#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3084583045"
MD5="5551516dd0aedfc4f9fb8984bd3e571e"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20652"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 156 KB
	echo Compression: xz
	echo Date of packaging: Thu Jul 16 23:55:16 -03 2020
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDUSIZE=156
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 156 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 156; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (156 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
�7zXZ  �ִF !   �X���Pj] �}��JF���.���_j��j�'{��Ye}]3Ő��p��I6ix�lr�ަ��F]�\�&+՚��X���s�{� �	�>ȀGZ���~i���)O�L1��*_67�8ը��9���u���,��s��Nب���(e�����`C@�r_�%����OF�p����-���0d�é@�p�>�L%��'�[u��ub�2ҹ�^�5����:���v�ǅ��,s�/;�\��{|�th�m��U��T��lF�i��jI�R�����`��&�J}�-d�\�{���?��EZk���ô�pꝋ�+�Ę�+�~�q7�s��H�b �ASx��g�l��s�X�Q��z����! ��mzx����� bl귏I>����pu�<V7��Y)��iG�[(��>9�[�:R��*^��|���c381�q��[r���L���,)�-�F���!MO����������[}f�v����oI5��r�[�\yĆ��~�w`�A�+l��:�K��Rۄ��G�W����rG�ɮ���i�Ԃ����ݚt=��[�[@oZ*&_ �LTSBY�d��@+rmS.�sp�is^Ԗ�/�6è����]�jxS�m���AFH��?�O�9�գ��7k�D&�P�}]%҈�R���@<&5˯�1�O���ځOR"B�[v�9�c��'F�i�U&)�2�Ɂ�|oeϔ1�B�z��s���9n�ø�cP�K��@m��E5�B3!w������`�j�D��1�E�1o���[�WOS9kA7uڧ,�6�#op��3\���1�i�M�Y�L��k�-���n�Q]�A���Z�A
�~��D�P�3S&$A&�؞�-�6đ������8��p�y[,���퀪N߀VՂu�,L�������}=�8Ѐ*�ԫ��'Ze����Ce>���Ʌ"ƯP�f�������X��9$�����3Š��TE��
�}�s(��2��{pm�M.$}܅j�t<?��|�Z�L�p6	UC( RQv�j���eɰ�6�j�z������.D��Oލ�{���G������X����=��Dl֪R��
h]��py����~)������Z���b���'{���毼���=�ѶuΓ����\������dQ%l�����3���%`���h���f���7���A �~1n^���s9Jb�*b�M�8��3�����䃥�9^�'���IVl�{}O��HՊ���n#��� �Wv�%��q i����s�L��i����5�ks������ŏ�Yۇ��w���㕧]��g�L> @Х
�W�-tU� �P\�k�g_�hk1JR��~ƴ��HSgn ��a<6��h�?��Q�X���V$N7�i�.���8^EH&z4f<("ۈ���Y8�sV�|�ݠ"�<��P���oJ�(�MIH'��%`��.�}��Ð�`J�r+�]���2[�0>N��
�R�k��Zc�{���/����vH	+Mq�"
(;p��Ѣb����5�{BTU��7Wp��潨�/���b^�W�y���d�w��:Mpzj!׷h��u��咲m(����|���'�)'�pì5����3�\����:u~�P-BǸ����Ǽ�p���6۰;�h4���ե>CW������A&���g�B@|u���0��6�2���eXI4&�U����$�ȸ6з�/'�3��4t,#�ω��mQ��=~�yO���8�	� ��QQ�t#���&�M^(�!�>j�3Wx�}�dT�(!\���d��f$w����#-B�`��j �'�I�f�2|K�y�Lp�S����t{UxS��h�=Hw__�@�f!D �o�np5ez����ޕ[���+g���Z��Ʊ���\\���Z(�5P)��$.�v��(�&�4�ւ����'vʍ~=���,(���Bl�F��o�C3��k��<��Bi?�;�Y����c-���6?+��M��Q�.XA���[�v<�� lu��H�l�����xxs?��4�N��&��% .�e���J�)x�g3ҏ�dr	��{�I�%�z΀�b�XR�Է�#x\$�б�z��@�|�r����٩��ɤ��p"}]��MƊe�㛢��)
���P����%V;��ɝInZj�Ư�)����9~\GO`��H�,[�(aoA�X=�Pw�DB@!��͍ʥ%�Y�>��M��"-���S���^�5�?1K������k��l�J�Tv��/�h�u�M��9)%a�X���7�m̘	sUt�q��'�N��������P�|Hﬥ� ����y���t�',��j�}�=��/f�2�3c�����tz~B��fE����&�yz��,s{�\���QH�I�b�u�|ͨ��kӑ�fY+	A�<��C�˳44~�a6��T�5���r�v��j.��+;��4!V�|bZ5�ȑ�[<l��n3r2�e<��r0
ȁ}���v<�YcK2*1��/�F�"��ȢN��Hy���)em���劚���of��g�IE�V��ѮjQc��C�����q�V�A}�=�M�̵ �t�]��!5��=1\���N	��ap��U�;:�'��b�@�\���~�M:޿�LdEb��3DZ�ޫ�	�8��@��
�M W�h[����{7�e���\CM�������R�U�gB�b�_�[��E$�/��U���r}K� ���O-�^�p�� �.���c�:��  N���-%�;��yq+ 1����M���3`u��j���x��pG�B�E��2��3�c���;jS��=�-]|p�e\�5T#���3^5�ǓT��� @ar`����d�k��=�R�?�j�Z�����1��~3���z7�zsS;ܗ%����A����	�q{oǫiK�DJ8i�FZ9�,�H���D��_$ޑ`5R�t��#���U�}���.�Aw�un�l�����d�q�/X�ն�ٴN�:0A��0��{&�,���)}�<s��G����`�/���p�Z�` O;��� t��.�H�	
<)�ΒN���AbM59EAC�6g���z�ʣ	�g(<�q�$ws�m`w�?�� �ivh�m�'s����8O�
ާ�cu�[�$�7�@�ǀ�7I�;�'.��<��L!����٫� l�_y� �f7�\����2�8��A㰾W�k���+�t=ʴ��tec�'�_��Y���&�^�r�$	8\8`�tn*P�uQ�L�a�f���q��T�"|��o@������n�7��X�{Qh%t�W�b�"�ݚ2���ls8?�� �n3�)���\�S�'����!�4)�aV΁b����z��C��J���+�ż�&���.����Q���Ei�c��t����o�E��#Ú��>.�I4�	Y(w�_L�w1��&y������k�H�E<�.��Sױ�~p��l �e��	o�P��}t0	t�׌ܽ+L�j�m1�7�	B�'��x�o�F9{{%���l�0h�=y�f�U�����ZS��*����y���i��hb�ӫ)C:Z�|�S��]ŵ�wC"�~�Y�)|ZS<v��!m5�bp�E~*��­!Ӥ>�7�u��F����d<�j�BV._}�it�Ή4���Q��ms��R-�T�!�e�SON0	�$.s��n��y="����e��[�f~a�iJ�h�gXY���2�8�cq�Xi���i/7Kr���������M�\W�R٬�M60_UՆ��FΌAQ�vF�I�Y�o��hk	q)C��J�g�#����Lr@|�$� �?��Rkl�r�@�\���$o�"*jYT_�7{�Ձ�jy�6�ǹ������n�֕z������dhh�b��i b��6������l�`Ú3���`��u���G�*�ͽDGy-ݿ�y��L����S�۱hW����S�x�+dM������@�8v�8��Y6_���{2�o��wPY�vY4�Z�c����̰R����a/�NaS� ~Xۚ/��`HA�t�/'�������h��:�G���
�7�S���f�n�v_����JSq���:�,���f��Qx�!� �vv�����9ѯ_|U���M帣�h�zPuo���i���:icڞ<�����7+cƤk���8���m�h��}���\�T�3�Y�#����NM���؅~�*JǾ�oFg�"�"��a���x��	��@��Pu/hg�D=;C<��;�3� bP�t��Ȋc	��4:5tא���c�;73��W�U��~��H�	��EǸ�Z7�'Y��9�P��j���3�!wC��Sht�§l|��7�dpn�_�=�5���F#�jیQ���Hb��|ݘ�����\����Y�O5[���^�a�c�$��Ԁ�8��L~�f2�r�����y�L�ܘoL6(r�uq�Va�TW�@1�y�W�ܥ4��Y�ЎH����u����D�=2)�#jΚϜA�S
@6��1���%�ʐ�0Ą�9j,��A�e6��n{�D=(�c�p^�?�j�J>�+��aF�B�q����z�n����<��{u3
\zf�m�/^c�n%�A�r��X<
��%e�>vhK5� �/�����.�����N�8�YF�̚��o�+����+�R��u���dgXh�%��yz�[�i�k}������ِr�W{���i��;PǤ�#,<tjg��E��4�d�hA�I�:��*aű��������hz��H���S����%���v��#
�XcQ���yX�렖Țm�9����G/����}�HK�yWb���d.�b%���L?�>nύ��1��)��u���c{���k2��..]�@�x�9�K�����盍�i9�Z�n���D��%�jp&I�u޵NX	Zf m�
��W3��>xe}��J8j�Ż�'tm�j�nu
�N�n;�;�J�����c1@�],��5r'{އ$�Y���_A�0hL��5���Խ�2�E*�l���>D�����M�ԙL�Y\)�6�(;�@R8 �4�����<RYo���k鲯<�i��+��_�O������y��s'tT�`��8'Jbk�F�(z��"L"x�m��H�c�t��(H�R��������
��ܧ�Ir'�֊E<\5���w�u�xS��oTF��켜%�C5P�G;������������'�����:#VZ3��tvH����σ4X�A�q?�㋮,����Z��R�̛!�+�r����+��Y(��h�U*�!j��,��.��z��/b-��.V���e�~���JUi�E�|�iٽ���n��U�=A��ڻ䄶EV-Ib�i�2���4+�sg8$ܞD�o���{�<��R���_�Q�4Ά����˦�3�Aj�)��`��]���~��ǭ�6�q�zDY�7���{w��A�q� yn��2/'��d��*��V#�m��ɼ֩�M��gC&n:t0���0ܑ�����v ����H�����.�Z���N��ߞK9q��a`�i���]�m9pm��3��+򋎇�KG�
�bSks��x�����|��).X���I���pg.D�E��J[�f�lT����8�:�j�G?�
�����,7��Aqa�t����Q�Ţ��U>�sZk���c��ee~b�c�T����R)����㳆Č�:f��S�ЩPc��O�X��5�E��H��aYIBN�d�#PF�b)�łp!���zОj|��	�ub�Lަ���e5�Y�OmJ��KI1����L�`�tƹBI/\Q��ɕ���X�_�Ԙ���%��Z�NL�sx��-g��dE�-�]�N×�OԶ8r�� �c8_j��5����W����U^k���NJ[x��@�S�b��L�.*���s�q!p1r?��� Uv�jrݘ��D6�D�#��|�-���+� |�@�Da�c&�K�e��=[#�7������1�&8�眗��pהn XXG��) B𫍓.fLdH��_a��J*�*1l U�-�0:W,�O��j��1\��ӊ�U�ˆ�l5<���Ho|�e��z��t��x��=�������eZ:�/�zĀ!.�E5�~#�J��j7���5D�=�ߍ�{� )��uM�}r��,U�&<l�e��{���l���D���-���]|�6�,���0�h�#;�:�_��R��nyM9��fZ>�P�MH`Uhg���y���+{䕃��=-�{� P�1��.["J�tU�˒,l�|�m���QF�Ԗ�hD�G:��!o��N"KA�V<TU��Q(�ş!49V��±��T"�D������a���m�֋2�Y'�N,��W���ȏ�2�H�+`G&��(��|⥅���/e��tx
��� ����,�_Z�KGt [�����anz�I����@�Ӑҩa��b�Z�6@~!CP:��*��
����7���x�D����9$���+�<���W�{�_���ݒ�FA��.f�
���R!��a��)�}����N��9�Udk�������q��u`���۷�N���z� o-l?�V΀�T�M�JU����1M��mA�X�9�}S)�#�.��U�EpҖV�|�"Ό�M��O �a�8���!��¡�r;�[���� 3R3���%�Ю����L 	̔5ܴd��!�{��ք�Vg%���M��%PΓn����ɌL�����G�U)�{���ȋ}�8�lW���}�<O��Zඃ2Q�����l�����\o�Zy>��:��;@"��0,9�A��S|)Q9u-~�i�	7Ҥm�[�%vJE�E#Gi�Ywo�)vw(mS"���	lTEW��� *��VQ�F&�"2"���?��	+�p���փ�E��f�:괙~��S��s��aM�g�ݢ7��e[��2;;�	-���J�Q?�n�vА"e��A�Z�S����A?�I!bu���|9ց�Ou�&ԣ���5�t�f���et)G����0� �@�}A���঍��3x ���6d\�5�Ā��������}a�C�f0S��s���e[Y5�S����!@O�x�-lv�>�%TB�%_�S�m��
W�5D�����XU���hP!���MA��YQN���It/e��3J��|7����@}��W�t�w���g���g,�3�,��n�� �"�5��_�����7\\?����Sm>�����%vL&�
�m����*)rGy+��*�������$O��A����e�5'| K�4đt�d�s�!���D�2y�O�$ȳ�V@v�)ҭG��8��O��z��e�nx�L4��y���ܞa\�o���zm��bu�9S_�����`�x��d?c�Ә��i�&B>>���cE,��BN��P�����d��O����N���>�9l�&(?���f[� X�m��]I����;�1	���b7]�6�a�;���[�#�5M4�j�r>��O�lƋ�*��"x���&M�o-��&؛Y�YE�� �ȧ),8Y���(r�~���m�Q���mW�@m	�-�h��yx��Wm�T`'P���'q�7���!|�<�܁�N��P�n�7,�z�xz����aŖ�]�.�G5D��xS*����(��y�B��!e�O#tӉ�����ۓ���5��|��Q��Z��܎C����#����&)�B�9�3�m����f^p�9�g��W��Q~f����ރ��� =QO�����Ź�b�'��M�����ri�O�/¼�A��@_ʄ��ߢ1�b34��K'ʷe���x%�{���g����q(F2�Կ�O|��ސ<M�R�`l��\�d�M����N%0ו推�������^_<}����B rz�(qQ�?���
)�)�xd4���F��7y�x4օz�i$������h��X/N�hjs!�'#\��UZx�?q,�8F��Qw�
xP!����5lul�-���s��xk?���cڻ� (&JD�3���6r�{gMHu�`�)F)��ʫ�:��MS�K�;�(����B�m&��m
4�A)���E7*�j��Ll���8:��́�b{���YY�Gi��cj���Ƿ(�ѳ}���(�{w=Q��Zb[�%d���m�d�v��Fm��z�o�xՊ~&C�|��T'B�;{�r&�6���K���mt��6ǰ���>�Q���Y�u��Wv��+K%�C7�۾W��q��?�$�9��8�#�i*G��i	�A��d��F���RLs��{kW:��?�kt�*���/�� %�<FPW8�c�^ ���јd�s�绦���4��w�t����m���jٻ���c�'j�2w�zgK�-��A�����e��q�;?�6Qѕ=Ae����� 1Qp�,�|�,��}k���fۥ;����B�G\�x�{�5� ]�l\���*�J}�K����.�G�0�b\F&���_����R��0�vQ�T�J��A������ՙ����+\����R�/a����1�QA/,�a3����h�u1M��)Oʉ�T��a� E�a��0�f���b�Ɂ ��-����鴹N4�3���5��H����k i�L�+�j�)����� *�O���C�Չ�B� N�>I�~�k�	���e��l��� Aޖ�@>n�����E�6�L����ڠ�lsc�c +�:Y�@S���=;/<�����qGR�]�F)7қ^���d?d�8�7�zb���	���L s�hmdч/ ���h �tq�׾����G0c/�L#Z-�����Z���˙K����˭����+H��(�d�oy��̃��R֫Kp
�A dp�����n6�^�c�	y�7�\�3
Ŭ}mC��A�6�R�䚰�Θ��/��l�S�ty�X�OI4Y�+k��B�]4���Ӟ��1�:�'5G�Cؔ|`�]!f�S%q#��x�V\-�5�'0�|�����=(:pP
<�u��cq��ܷ��%��8]��|�~6�����E�<o��.��D�|��+��.�g��,V����4nĽXlM�d��j|��2< �A/讥�#ܕ��T/��G�y�v�*݉4pβ��lt�)B��mf����-�?/�A�&�t�sw�Y- �n�k�Pȶ�i_ ]�LL�ղ��=h���ڮ5�T�aK��5(�5Ż�e{��첱�[6�Ku��t,��/�ݲwx���4������q�)#��F�_�I�if�Rˮ�n-����GF�p��x֐�[f�k��3ɁE�%[� z�J�*C/�Q��i&O��$��l#:�qj�/!�%V�'+	"��W�A4�<���_��	�iC�`��,��4�j��iř%�Y�[���	#���H�@;r�Bp=��|ɏI��h��<�Y�A�Ko����L��o;@���Y:��uV��������2	�d�2!@bq�R�A��3�AT��r��|�n�0,��4�Y�[$�a*!хe�~Ay�ǯ�q"���e��q�q0�G��0�U�Q��nt�n��9w��Z�XFI«dRFt�YP5)?	�d�<�%m[��d4w)_��Xl����t���.W�e�.��Sʙ�UQ���X%%P���Tx�픓J�H'(�=b�JĻ�);����;
#i>ւ4����ٹ^}k��oU5�B%�������Jo���9����^�4�L�2��Y�~�E�O{��мv���Q�$Υ��nKW�+� ��=�ʝ����WZ��!C7�j��g(���d���a����Cߐ����#��E��k$ᅴZW�&?�h�ct��rdfx���`0�J���pf�jR��Fv:?� 6D���sw�Y*��R�P�Y+r�j�B��B�F��"MӁ�S��<���4�ip�Y`@�+}���!&�݊��_
���ad�����;�ԕ��kr�/�hڐ���<I6���3A�+u��1ŀ/�o�?ܩp��q���D�U�W<(�'T�z����9<��@�w����i��E�΋ܷ��6�Z��Y���Z^���g�ʮ:�����T�̤�*9{����2Q���R5[�T͘�#R�X�z��,W�e7��� o�/yF�l�∷���l�I��������+ݕ����f���8�(GM�����2E�eK�`��b텨�_���:Z�f�t�5I������:�<��2{�.��f����6�ܹ����m6��TN��]����ڈ�L��aF._zX���� �c�Y�O�Qt-��F�:zb��*���N#���U��~#�6�g�OJF��'/�@4{�����=l+CbΚ�<^	�k�_�#�T��Ϡ\�QO�����Qt�.�hb+&kn��hF0mb��W�rh�G'�����,I��f_�'�h��YI�C�FL�k� ��Mx��}P��Tr��X����?��8Y��^XY�繬Ƣ Ȯ��C�� j��5\�H�TN�+b Tu�mc��:M�d}���ȸ�H����3��a�홈�>x���P��l�:> &���ZL��W��oU�O+��� 	�M0���/�ӄ���C��V`N��8dtB��9��3�p^��z��Vy�]wq�b�Ps��c��W��h�o;N���Ujb
���.�B���2l�v���:;�u�>�I!�6�Mt���l�%H j�:W"h�٪ap��~U�f��#��Q�FÂ4{R�� ��t�B
�����j�RNq ��I�Q��Е%f0fn�pI׉9[˖��q�����d��\=7|GJgJ�n����(���{P�w��ξ��;�<��8�d)u�y����������@
��h��c�:B�������|Q�A�k�	��#v���:���v4!�����/u^��OQ���c���%:��m�x7���2h��;��"�w����PT�S��'WkI��&X��G�vaR�/�T}<O���]�>��A��'�h2�'���%�a}��A�<�z_
Ϙ���1�2��R����3V�����4�6Uk��%�M�t���2W3U�oR>.cƔ,u�L�U/��9��?�'&��r����w�o����h5x?S�;Cg��e�a},����_k���X��s�:	�!Vhg�����W�%�]3H\,7t3�cD LU�_=ݏ�5��)b�,
r���P���X{�0��'�NH����A6~.�w_��c#�wBD�+�d2���r��������Æ�������C��·Q��zeE̾��$7/�b�й���O"Q�0M���,)=5��A�?�&[��[F��֦��H�H<�p�	�4�l��sdx���v�bn+�'s�$F�թ��ww7R��)��3VDW�ژȨLA\��z��IUK(
b�0,ik

W!�M1���m��|�����JŢu��K�_�	��-���\��pb�z8R�o����s�����>%w��ڇ���(	������{�&Xi�'ui�� e�|{{
y�'3�ƫ�{PĲ�%������d��z���&a+m
x�h�0p�>��[P���G&�cj0JBV��$����h���%��3�p*l�ǚ���7� n)��J��3�E��&��\�F��G��ǖ�Psgm���(dך+��7\�A�c)W�ٽ^�F5Zz��$fa�����lYUR2�8�X40�-����ɻ;�T!���>O�Ԯ�<І'm�^���_�Y��ͳ�)E�c�g�z
	6��A
N��pm~X���_e��z��A��ԏ�u��SA��އ9H H�#(f����,Y����q�X],�/���1��j��a�p��΃�T�j�����"͏>�[7�zp�'�q��.)FH�7�|
�����U����U����*������"������I�˱�<��f�"ۜu_r�� V#K�B�\�\b��E�"҈����4w��<���ި 2���4�X6f��{�2F
��b��
���	�VK��K�`@ϴ7S�`���t��>��5��'�� ���碋@a������v�},W
Ef"��Oյ>}�Gn��TCR�]�#�P!l>1������pV��)3��2h2P�d[-�t�U4gπ^�T\EXg��FI�s-c�3���e3-�ȣ��j6$��~���4�V��T�+Y���3���ӑMCΡ>F�טٞ�sg+�p��y%�u���~���ۃc���Sh�C�����`��U�'�q�74Y,'I�qD{��
��c��g/?�I��?)��߿o���k�+�)�cz6=�T�S{^���.���@Uն0�P����ys0p(1Ϯ3��/�ⵚC�3�p���m{ �yX�wlzɮma�q)܃w=�/�z2��f�c����`��/�ʿ`f@�h�y?��;t̃��s��h������'�����B�,��mG�[��͂b����;M�W"ʄ��h����8��/5�c�.�s�67��A$z�-�-b��N�ϻfPn�)�:�r8�dd����o�s�O�0�UPG�@*��\�$k��{W3�ٌ���M8���Cr�M�o���w��Ȏ�j����*�Q�8���O��jF�@�w:�)W��B�kл*�,��Ns�:3@��X-1�<�sΫ�����CͲYU�gԷ���/M?m�* f�)4�A h����2��}z+!�(<�pV��R��@�b����]��3�V��V��8�T�F�sTG���$//�1�Zd�ݥ2�Q��+u=��L�D��K�q��!��"
�JS%�q#��ť]7p�1t�-9F>�'��f�F�4:ٹ�N���S��2��J=�h��T�c����3��S��j��њ�U=8r��WWQ4��34���yE�cxͪr�, SD"���*�0�u�����V�p����^�
m���~?��g9�I���/R��Բ��;`�A��H�"�`y�-CK�����N��n��\)�:�|��y�W�(�|��Q�c�%PU��$t��#YS|�T�O?#�s
�Z�j{ox��;1����ϴeP�����/#*�'h"Lk�(�����K^�&�lÈ�jͥ?<	��a�kt���W���A�8�m���jP$hr��ݛ
�
�C�nU��,���e*�7ňr�t�n�]���#�:�9ދf�	�:�-ym~��Qzfl�nc	Q�tb����}���E�C�?2���Y!j�~:� I���R+"_���3g�Y+�
�y�b�_���C�l�Kݬ}!���ў=-O4+0~���V]; π����VJ��p	��1\^�R�P��b}K �9"j���%�V_�Ay��7ݖ_y{�E�&v�+[PQ��GW��pw�p��xb�����?4��@��<�<�A��m)���"�r�������ŀ�֘*u�b(:N��˓5#R�|K��h�k��TT7Ƞ���l���|�H�4�5�1VJI��cㄽ*דOi�1�sw#���s{T��v���eʜ�'s��7���1H쁑��o [a�fE�S���X?K�Qb��|���,�Z<jM ��^�����W~d�t�W����8�iY�wvLV�'>�K�qu�۝�����J��H ˕}��h�t����ڳ�!8]ݿ�~ Xp�7��D&uyxݟkě���4�^�^��Ja�x��Ҍ2�qe�z�OaUN"� M���dH�i�~�_��R���^�e�0�c+�+ocz�E�7ѧV����a
Q���ɲ�_'.bwj���_l����y/ �s�������/'RK4�e�����~�h����-.�s��S�"a�	��`]FKk´Z���7����F2��"�ȭ����4�	��.�OK:'��u٠UF�Z���\*�&���jS�� (����W|8�a~�T��vG�"��N��� �MG��Sރ3H'�����Wa�wB�/�ix �j��D��k(�����LfoHW�6�J2����K*��Yjp�V#�*��$:���uAUUXA2C�;<����?p�$�;�<�������Ѹ��y����]�-%����es����x��#�����\D���v�0���G��	] ��1�\l��]�V�Å1��,��~������F�����2�7Cz������Tg�V0q�\l	G�s�i*bz��yޞ�P=~K���O�J���
@ت *x�m���{;��P��;��[�4[Ks�k�2O���|X�oWN�5n�Ɖ��p�����«��.�I���:XÐK�B+"{%��M���j�#�Yfw�d������p��� �:� Z/���������llc�NS�V`Ԣ��es��-���ul��<	 i��4��<��YS������WbМm=��x3W)�!�@�c ���N�jÍӓ�<I�_]#TuS˘��Β�3��[/�j��!A��|�"f��$�ڼ��f�ƴ>EC�/Ek��F�c�?)�oVh�顏��_(��<"�W�&/M`g)7��q)
��\bY�
�eY�6W`y�,�8.+�L#[���1n�(��J�i�H*cm��uH�Ҥ�ߡO
]>�X��w��I.���CE�=q�2dL�5y�pXy�9���t��4��;B?�XtFsȩG1w�F��a�4ؕ�j� -E� D���8�f�R��@��W���u��`����Qr�`f4���yo��9�$e����OH�}B!���W�ҫ�l6���l� �[E� @����=�Y?�>�HF!a��Xh��BW׬�$l�8���xy�����1���A�/�O��bp���sݙb�>1�!�Dy�M����o���(�7��?_���G��dB�9t�0B��]��� ����п^7��/���(����{V���pҧ�&
/�G,0vgI���A��	T��gX��Iw-�2�Vv&2�y�k�� �4N՞�^x�xj�����������B����,�Ĳ -jz���m�9�-� Cʋ3��;*� �j�U~�	�T
Y�s!���'�������WTĸ�L�O��W��e0�1����9�N	֞[%�=o�1�np!d�%U�� �X��5'#ق�r
����mY� z��hB�����}�͌!��I5j��T�ٴ⸭=��9+-L�Ѿ�=�����'�����X�DQ�x`*8ϩa��M�.pP�(7�5�����K�*ZL�e�7�S`hd�����	�M�'Q����n���ti@<亙�r��z��b��z��.,
#E0�����Z���XZn+Tb��)�[��GJ*�I�&��0��m\��]��׫�}��[��x` �����C���k��"xâ�>�pM���?d-�U�������?�<�=�$k����ߦ�k�R�N�]������p����Hv����ŷ��8�����¹�+���A��li����v�j����	6�������2��v>�4��w6���NC%�����,i��>������^�!6mj�HY�4���ʀ�o���V�>�^���
�.рȋ�;$�m G�$���^3�*�;���![G��	β�� 2�4�W�يN��7,�s�'���(�s�Gt\��T���u��͇+��EU���o?G�P�tG�c�lc��-��Q
^�~b2H��(v"�=�M�0lLX���pĊ��IH�	�<�.H}�ąhYu�C��{�k�_�A� ���YCMR������ǐ��b�6L�%ů��5�+IxO�eS��L3�X�B�}�F�_1��é�E<Hϖ��G?7��������I&F�V������$��AZ�*]���rbಪF���g�!���j�C7)Q�Ƌ�hY���!��M�&Ց��g�+S�|�<*z�u��S�?�˕��b�X{�����#,;MM�����/?��	`Iy�.����2ׂrzK�X���AM�G�c�s�v\3���2'6��J�p�\��O[RsW Z�P�tҦ|5�����|�G�NN��G�.(�͟�gXp	��-c,^���H'n��:�������^�<�l�\�a!%:�'��T*��%�%߿�{;+�����)�Ze 	�޴�(��Imm08���S�;)F�#�ExN�C���K��-1N���a�˦�H cq�9W�憍0+@M��e�tຳ(��su>���Sn������'��w5s�@q!	=�ZՎ�ի�q��&����;mI�D|c��y��W��;3cj�SA;5�i]�����	��c�ځ��WV���r��䤾��W&���M}��-)@�O'�B�*����v�C�M"��c��^(�sgi(|Vw��bѫ'��{�?g�t~�$V�6i�>������]�4�G$�g��U�t�I����1.��#�z����y���pGw֬^v<q�҅�=��t���l�+�um�+a�ϱ6W�+N*P��e}���I�Z�SKx@�4�{��4^� eWb��������ڐ�uH���ܚ�E�9�+Wm8x��a�J��K`�qN�.�|��~_�<C�q�S���tk;t��l�6/��X�ɛ%�Q&���@����5Οm⠹j��:��a��E`��9�����I�2ʉ�ڙX!�k+���1qx�x�Q�br��j�5��(n�����#erj�Iԩ{���x�흲�C�����Ps]>��L�����>�0j��Q?����J�$���%@B))Dɚ҂���C�r�gE͖�s
�$�w�T���:��}g܈�׸��&V��5aܔ���5��qh�Cm'G>D�Cz!*n;~�\����8�Ux�6����$@+Q����;�3hRU�y)���iG�*wf:�7w��䌅="�����5*YrK@�趬x���6��Ij�7b#>���vv��o�Ѽ2�b��փܡ�W�z~0��e�^W$��΋�
�Is0%���)����p�cr5���^d~�ӧ���;l�#��ۑW�2����ʁ3�Z8a�� p�t{*���7Cg�J_t����K��y�IcG2ܐ	��gb���v��F�L,������V��B!����|��네�}����������Bq�cM�젛���9�'��W���R�?���;K{ǻSP|���%g��AM��{X������A�DÊ8���P9��f��rև�ZCh�5C��v��YA�������o������(���.��P����P��MحT�Iy@�r��C�SUÛ�RO)�mx�9�n�X���mӘ�A��/c��xз&�'(���O�1����T��_S�'���D{�۱i�s�V�r�t�cG�W�\AKU�r�)~�t��zċH�^�mh�j��z�*^ٖ�;�<8��İ$H��D`�i��dT�򜴙�6[,H�P�O	⹢�����="g M3t�$2 ��g�<���\_�Ų_�7¸�b}��ЄdW�������(e����=B��ٿt��4���A/����#�+Hy�2��(�aE7$��A<*���&��v���ɏv�
O:*�:����� ��;�G>5��F�`>��!�5@��[s��MYZs��6M�W�`ϖ�R;^0�+I'��[�5��CGf��]h�|�c�>���?cPl�١�N�{o҂��N	�^h��n�a�}�I9���o�f�Օ;�O�1�mr~���b��J��ut�t����ʅ���!���}*���w'�<$�;�i���S�Jʖ�����;?��Z�g���/Ui���4��yS(��o�]�&����:��%f�**n>A���C�`)�\@��I@ S0�T����N#D���q�]����\���˔��bT��j:~�/���g��53�[�M&��:�qCqع|�a�J�'�=���,��)X�=C�؎��Խf)�{�K�O�f�+��E}9�i%�ái	G���
�ڍaHd~.N�.w��dZh�PS����Ue�,>��ͣL�Y�1���ɠ���7���1M9E�&�������)/'��^I�67_�:?�i1' _6�	��BS(�D��U=��H�JV���l��Y�FD�mA�G���Xv����ji�AX��̽򕈌��p)_|�v[����T�/�3Y��?[Ӆ��]p��;c��Jr)�7�Y����ڻ�a)\#��)Hv��{EP�s���rB�r��/�[�)1o�oVPfAxX
��)6�E̓�؏�D�����v�O���j��������Hs'V�7c|h��;˒}����Q���01�c	Iׄ<�l�F��H2f��Ѯ �qe��֫��ս����/t��;6uT���ބX��c�ϋV�`q��'����v��q����L�U�>�"d8qf5�~WV0��c[icC�z�"`!�^�/�OzN�ڭ4�%���8Zio1��q�&�u��
����{�q��qxð�����r�K�b��M�y#��~t/��k��[��F�XQ���ҹ<\�1�pA�{���v������&��o�ȹ����Շ����|���.����!5;���o���f{��co��kv���,U�yXY=��X9���˭_դ o�8���bn	�@���xN�b'��A>�}��¾yyC�Ш�ϼ���U�ohh����q�'gB�xX����sW�sv��<�}V⠴2Y]��5����
���7�+��v����W$Fۦ�&�ą&��\B���F��id"���?��G#ڨ�\�\5�N���d0w�M��`��YZ�X�-ˢg��LI&�����ӆk$6w�Y,�S�i�+�<k���  ]xn�o��R����:3�ؓg֋��K�e����G�T������'�9\�e��[��kS[Z���+�A'F�\�E��}ɜ'�Nz�r���ͅN��ۏ�pH��#PP�W����R͎1����e�4x}���[p�ҫIVݤM|�=����X���hZ���q\��Ŗ�4O��t�OrE��y�"���R��8�;N�"�ة")�� �����ɨ�����=�F��\�l��T9�I-���TP�
MnM����aLZ0�(�����eb���� _>�u��Gq�q��,å,���m�L���:�T��}kz�U&_9g��F��:�>d-I�ѱ�r޺�����G3	�f��fZ�N ��֦�^��3��>zc�w��@l�1V�A���DdY@���DS��Xn�� F�N&��mfM�b�x��>�Vs����������7sa0!_"��0o�0�J#��8��M���X�fQ���dYs�.[''�*���'q�I�qw=9�b'���C��ִ��}������q�u	n��*���� ���M��������j��^ٝ"����"V��]��=��o���c�^���O w���YW���@���"rI+Ն ]�\e	�Ӳ�M�g?���<�f�=�S;ן�,�h� WH)��8�`�LQ�ݳS$hg�<��=N+�7�xd��}J��җ���f=v+��1,�K$�����@�����]�6a�d��*��*|�SP̐N�P	�BU�T+��5*�>�,�5���"m~p�cg�k�1}�a|Z)��~�a��u�� \���-Qđ��)M�1����#����nt�=�3n��I�Be#U6��;������S���NP=�&}�a(��݅���T(M��D}R��Ƀ�ݩ�4Ʊ��qE�\8���M�]��x�UL�0��	�L�P:����I��~.�(��m�ǋAb�-{��k�,.|��5#2����;�>W�(ʭtw��ς;�a:!LV�:^�^��¥jd��x��/@����%t��ۮ 7in9O��8p�C�?6�-E54�kaQ�����ץ��rY�1�'��%��{����y��isQ��~���I��*w}�w�!����'Q�
\(�㊕wH�y̌�L$�����rb��;$V�LkM��63 �V�A��$+�>=\W���S���UBO!li
E��u_�V��6H�3���R>��BCo����9�	s�&�����^�y��$��<�,�_7��/�c��ȴ����BڴD�Ŵ�i���?j����?��H@D�&�4ѶhF����y ����@A�����8�E,~ޑP���Qj?�w�>��g¤3��E�������)f,�N���Bz�娵*h5�"���uX�uG�@��EM*C���.@sT��?��W�i�M���偄��2f��o�   ^U�U[ �����X��g�    YZ