#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1211113531"
MD5="e233b098cb5396407c915196af10c6a2"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20732"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Sun Jul 19 02:33:48 -03 2020
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 160; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j��~7��K���.�"ۆ_N	 v���,*C�������@�����r�������e��/ҕGγ��͒�ɠ���C��V�8 ����k��'c�B��y�1y��|��AY��d��z_�I�<W��K�0ۋ2�!sR��'ō�\-J+�"�����o��"�:c? �ɞ��۶� ]��)^��#$W�`%a���?� �S� g�=E�2�	^tn�ݐp�gc��c��s2�Ӂ~c�@kC ���B����眤�v|����,����(�![�N�Z ,���)b/(f��iPWf�Tߺ�F���Ć�E��
y��O�epK#h�@��K��΋��?+vr���{�=a�ٛ���7l��Ԇ�N�t��_�s���K���xi�\�ˑ�/d�A�����wk�q��D?_�I:�����59"p ���C7��2w��ъs+^=��h�}p����뤅���\m��Пr\V+�U���Y5/��$�?K��o j<���p�j�
@�?K�\��ǥZ�-�Ƌ�[�g�_R&���W � �Bֳc�!�彌9D�J����* -���F(MF)s���!�ދ�oNI�u�{:Mɥ�:/z;�|j3�]�E��j�|n�vR;Љ��~Z8y���$�e�N�� �˱�rBCD�R��+P��`Y�FTtM���QP�s1�������XPh��ì�?5щ)-y�Z��0S�1g�)�3�t�Y���[����)�@�'I�!��~��|�R��B���*���<�܍9�Tr�%�Xz�S�V�~B�7-ӒJ��㟏
�`5/y�	<x�ҽ��o�O�k�d%Pp��_9�H��V�3��d�j���bb������3�F��5����O���-�מb�=~�,Q^-�ﯸ͙�IbF}�(��`B P���
ߐ� pe�-�V���< }�tM�s� 3ɻ��**��m��f!�1���z.<���^������Sʓ��Y?ݣs�����}iΑ������tj�m�H�쓹|���G�+P��5�g)%M���*���j������)�A�Bzԑ2�3	��w�'�u=���g08E�̞��!�}����8c�+�l��%�]RpB,���^���S�vѐ���c m<�R����z���A(��)�AP|�&m��C�����CH�|��t���W��f$2�8,�m�*��m�n�K	�[�V:ɨg����S���o>Li@ߘ5[�b�(���ԥ�����s����F6��3�4�S\G��_�滕���/lNRdL�C��k��޾�`P��$Q��!�x�_,��E8����j�b�k�]ۤV���nV��(�����gw��u&�~?4��u����}[�qд�mu�ݳ�/K�{�{[7B��a��iڐ��O�
v%1�[IxPI(�S~J8�}ɬ���Aq-y�ʅ����j�@Ak��n�l|r]j�.�1��<�uk4AN�z�6iЕ�"X��Vt��Fٸ+2�*RӚgǮ���X�(��PY�s�P.�g����_��@�r\!{�(T�����ۂ�:����;��O�T8+�F$��vI<3ri�pY�����ޛQQhz���:��jkUPހ7�R!�����Bd��Q ���^����XR�݁�	��ۑMN+m��F��b���)�F�7�tH�kxN]�k�N_���?�SqS�W��Qa^t�t�"��vۻ(#�6#�T�R060�cBƐ���R��6��F�K�:)C +��'Sb��8}i�&'*�eu%��©����x�uC��x�=�(_�]�o%�C���i��^��R���=�)�����4��'V�R��6�?�*(bnn�����������p�Xa�
�HL�k�ִ��� Ε��CP�4q�^�.ӫ>���	9x��Q�tg���M�%�v��j�x����  �!� <�^�Q-�����4��L;�xB�� X���ϼ*���
�q3l�Yo��!DF�n��
x�)Oq�X2��u45�Ҕt��׫z@X��aUa�F���Z�chC���:8E��AyM�7zK��j��<��J���7!E��Θ�yDV����}�u�J�=\�E��1QTo'
a4�Ӯ� :��a���0_���_� �,-�m�����r̎a^�f����� ���a�\�U�Y ̀��D����@����a���룁
|=3 ���G��D�&?E�4P|������[	�����3�=��<Z)-`q���m���J5�ӊ��[��k��S��G�N��"?���
j&y�]�V�?4W���D��0�{�4�EB��fKCå�O=�h�����U�>����@���W�J�e��E�wC�dk*�}b�pU�z�a�?�$�թ>z{2�o0��G; ���fs��ԋ>8���YOS_p1��\����W:ǭv�n&��d�~�Y)�( �M�y�˯� 崇��$|�����֌�K����Xc��I�I"Pm��/��E�U�7�S���S�u�Pvh����I�|�mP�wÚ�?��#�&�:+$�ls,o
�����O�M�OJ�P�O�v非��g�u�2��y�lO%rǬ��"�,����
�*0i�2Hҏ�nVmy��$�����F�eM��S�`���"�qBş�C�&h�	��1�-���q���'Bq�ӝ��sv0�n�S��X$󙖤�xfښNE�J�7C��A�Ir=������"lm>㦏�uK���G����؁SmzT�,	�zL�T]`O4p������7��bgU E�"�
��>�m�L���.b*�IHB_��6�-,���{JG�����Wr:%�i�Q�زY��OfG�ia����\�+�X��6t���5p��)��m����{�`���Uc��~�Cx:yT� ��@�ƌ̔L{Љ�	���=t��#7ę�5*�����|.)�~��N����J)t��U�_�{�ॣWN�/��]q�A0�U���� �`.=
���9�e�"�d�B�bF��Α��{Hy���t�+-%�@�2t��<�'6~޽xC�VysḴ���>��|L-�Ήn����?i�OGW ���^�����{�5Wy3֬�M��.7�0��t�0�!Jܹx��!�����bI�n����X_B�R|<���`������HXLbw�9�.]PGL�>��ȡP�esͽ������/>�����d6'�Q��+D,��'��7?��r΢�V�ꙶ�9p����Y�*��Ɍ����H��e$+�oz�Y�"�ŁO)�$��&����:!�.��ń����1E/W:e���ىǰ���bo·�|܉r9�g�~����&h�#>�ht�l��a%�N�ng�d1��%	k[N3Jc��D��^�^��U����2˕tͰU�\'����=�o����߉׬���D#G8_<����.$���Kl��(XA��'x\�GMe.$E�+�F*��k�H��?s ����aN��e�C���t]_��6GEf͟�dѝ;A���N�Q�W?����p�q
GJ��ZZ3I5J�+%����"$��@僊޳���$Ub"�.>� Ǐ�n����_0�U
b��t+ʨʛǁ���7�-=�9���`���+����3z�ԟI]R��X���/��n����	�`�<ث``�;c|wq%��T��¹z��C^��:9,�O����
�Խ\(����\��A��I�u.֞��]0��{�+��]�*.�b�
�+�@��됩�.j�⡫t��H�^�����R?O��_�|*J��|Bz������˱7�
�,�;P]oݶE��9�7ȥ:��b=�z�mI�e���X����
�����k\|s�ی�?]�v���Ͱ�o�k�]48,5
(�0v��oڢ$֮���,�9|�^�RR 5\�*����S�sT\��)+:�ʼ˥�Z ơl�R3���D�6tm"�+r\���$��(��}6��Be�KF��)�ٗ3�ek������S�u��s���.Ŋ�@��|"0"B��~">-�.��YT	�R�£��b��݉�e�6.o����e�0�����.ٜ��i'޾u'�(�4(A��ybb3�F�j�+����q�Xۚ/i/v��JL;<���H�Y�O�����H�dF��4xe�o"���cau�$,�H����N����Zc��E����	�fK��0�K�'�z��V=[���R~N
��z�kh��w4J�D�p��rBYɪ�ci��Q�`��kp#�7.�Z��m�����պ2.u<�1*k��I���
���&�-)���T����H�R�6-�n!2�L�ؒm�a���7T!��J�w�K[ a�7C@�W�.{N���lvz�|��9�ϱ�)@j-n�|���<V����&� �r���#�3��j��o���8Mג���]�F<C���-}�Rw~��p8o���}ݲ�9q��+ޢ�+��D�񷵐���VP1���,|SI�������T�����]0�j/p�b03�#����,T����[k4������Uag&�_���/(��~M{�/7B}��*�f��/�+������3d��Y�M����iVt��Yhs�w=�o��nd�\��[���>/�g9�x/�j����^�Gj�ȗ�@߆���@��m���$�yl�`:_��M]�S�U���毻i��T��(cz5�{־¯����J� C��Q�8�����D.W&m&;���%є9�(*�)��W|��mE�sA���j�ɰvq��S�	��gf�jn�X�*\2�1KЀl���JIv�������&Է����z�9��L��wx�'G�DPƼ�`u7��yL�ހS3�Qb���7b6��`%h���#�;lƝ�fm�U�p#��A�R9��y8(�N��x����!x� !������NČ~^!�udL�F�Q���`؏Sw,]8A��.�!ĺQ,'�\:�ƥ"�d�P6wJcZ S�~�IY��%H��fH5�;��ΓN�lS��m�^(�zO4I�����V����F�r�GY?ȵ�^��x�� 7e�A�񩑯�3L�0��]!�FP��E��r�j���P�()�^<�P��q
��]�a<Mw�Ȟ�*�ȏjĭ�5�G��g��A:��e���;�F���6�@�+�sʎZ�zNK��%Ҁh��T k�x^��Z v����A���B=<,��kΜ�@5������#Ð�ڃ���a�h��*q��ż�V'� �Oq��V��<��(�
�������9�5m7�R�����T���B!
]U0���Wݧ����hg-ٓ��q�l�`�*��I�]�z0���qm�i*Z���:��f���z�oiGQZ�F����3��<ؿ�	�G�ϰJax�,_��~��O�u�������H��>\Kps�X�t���1,dF}�*Vs��co��Z%NN�:�fYf��6m+�Y�u���p?d�7[�e^�I�03��s������4�+pzi���C|sM�!��f�ї"�-�ν�gr������pW���iF!�َ��(K��4�p˞���CR��0��9����bXϋT"�e]��ut�R�`�*\wg�̆�;��m)���ӱ|�I~�|C@���ڽɣq_�wP����yO�Wmn�J�n:��Tޙ4���Vg{��7X=��p��3��b/g�� ��q`E���Z7�)�.V�M�AC��$�w���@�t`�p�5~��P��1LSl����DW��N��V�@!�K����`S������fW&�%Q��>L��m"�	��-=j��Z|S�=t
�S��)��a����?�w�m_�e�Ӕ[�a���y��Av����>M��e3����B�*���l>�Q�7�SF���Y�	����c�}�&3�HH]ZR+�)�vn�Q4���f���+�+��j ��s�ᔤ3����o
4��qZA�)۰��;G�ܰo
���R ��?�U`1(��ݕ��<�y��C��<k�Z?7f,	�����ږ7��������X�OP�jr]���@S2S�9&�W5����@dZM���D�[������I �e���3�<b1���XD?����/��m*d�ݣ�;���@[��|�w�O�������Z��Q7*���\zJ^���2樭�<�95��22N��)�(O_�ˠ��,!l��|D����
%�iq�|� �nι�A��F���R��j\�q�M�/q��j� I���2��ƪ9K���{��P�r� ������lP�&��l�LS�k��j탥K��/���V�:G5,��k5�G��V�§��4n}���o6f���?}Y{/�|@�'/��r]g{�~Z��,W���&S�g3d��D3E����xݏ��cکμh�(4^51� 8�ٰY�)�X�^mdv�:����3��aɢ����d�k�����3��F�`ԵU0�t��頠#�_R���'������~��K@��.e���z��N�;N���$���=����o޿���C�j�)ި���Xߩ3g8������Z��vڿ~��T�Jsh����o�D\����'�my�lq���oI�6��go�n[7Ӈ�W*��7X�[3�a]2(�Uy@�k�h� -�6���8T�� :��u�S��gɖ��s��iz����z�����Ґ�Q�h�Y{�����[�-PT6=1��U��
p���N}'�� p��Z/ǽq>���@��PA������G�+L�Nl�P�����1Θ��_��P�:EF�!O�K�AP���M��7b����0J.T��ũw�*I	؆��&_�K�8��=QZ�k�&'��p�|l��J٫K��3Y�`4� ��Qj�wˊ'
�W��JƧ�n���R�k��$�_�s�b�1Z���	��o7�f�37{!��8�L5%ݾ�P3�bD,�(b&����ul�J�_� ʶ���/У-�$��x�@���e�IJ>���Ӊ�4���R���b	�>5D�紎^��[�W����P���a"'�ݣ��=e����|��`�T�e�ނRHΑ���pv�(G�ѿw����v~Q���\8�+�ƈ�7)�-�̎?��;� � �X�����"�Fg�mz�DU��#�XTaCWJ�X3��������@t4�g}g7	5��C1,�)	��4V2)�̶Z�6�l�0��-�Q��}0W���,�Y �2����(�#��=|��������Y�X��A�O*���3ˀ擟��P_�v�4�k�ss���.O�s�f���W 9��g.�@�U�yH�;Pzޅ��?�L�I	���@��]���T�dIb��O/����<K'M�����~��a^,N@ᒳ�+��������d������[6�X� �,��?ń��:ʜ�b���"���cK�y^���h<��
�rpR�Y#5�OOX�K������A��)���׎��D�����$�/�mT�;���G��E�0&�VS�:��:���K�5.48�~�`�j�w[ySx�
�M$/B&�#�񮠢ß�k�Wg��D)�) �#�f���c�=����_VȻ�Q��Q�S���]���A��  ��@�z�:8���f�9�	�A ��H�}8ࢽݐ'r8�]��Z�7�
���s�82���~��ū�����?f�R�b���CC����*�
��r����ҷ$�KE��29��������@�$���)�A��1���3z7� I���i'��n���a�Xئ
� 斞m�<�vB=�
.���� gݡ��־pg���t������Ͼ-Q����#����f��
�?>�h�O���@�.5��������j;@�R4�M��D&J�Z�V��ѱ�n�-�WJlx&�r�-*�q�\���f��}�S9�0������N���"�z���XJ�̜��uAz�U�I;[u��gҏ��b�?��9��Xg��ߓ��K��O�;�CP���`` ��J����O��cRy���j����Դ$^�ɿ�,��W�W�=��0I�$�Ji�l(_�/*}W�@[]��-2)�v)�P�o�B����Rl��@��B���K�F��NtY��{�ñ]D���Td >qX�՞�~�6QJ�:�Vˮ��Q�
�k�����H�6�G�,N����	����NDZ?b߅kL����V��Y�i���O����4���je�acl���.�����C	Yi�v��ɱ�i�J�-�#�v�io"~`�����@���� 5����)�:���J�^�j�PK~� ��ݪ�ĄAW�����~�[��TH����q��|R�0k^�>o�@l�� &�q�p9����ԉ��v�͖Ů����`G�1��8� kA��{]��^�hb^G��9ۧL#E{�:��%؎Z]����<�b�ŷ���'w�BL9���=x�5U����Ws0���䧔�a���ׯqU�Y��[���{���NmU�
�'@�S���.�g].�`�oH�mm��n���H�3�.�'�o^��R�6i$پ��ٗ�!���b��d�L�����Tsu2f`�̱J����;���
mt5��rBD�M&ۯo���h��ګ�&��R�7=h,��7��>����z@����H6%S5��|ej�����a
D���P��St�Bv].�FL+0|��Syt3{�B\ �)��H�tߴ��2����9Ǧ ]dl^��L)���ZFsn!�}	��ߡB�f�/E�fBE�C�4?lůtN��������UN>2p0�7�&�ːD{��E�G"/$==�f��U=���@1ɻ�5�:X8A�u;(�h�SCo�w�T�x�(�|��p�"j������0�7�3����+����_�}ɄSm&BlKAr\�!���������%�#c��w�l-0��DS�ſV��7�%���1��bk�w�w%��r(t�?��v�K��t�]9}B�6��N2�;﷝1�vq\��G��Fʙ23*i����-"��0�5�Ju�TM�Z<[�r�
d�1�^�=��3&=W��Iu1��k��
9888D�u�٦�U�\�o���PW+A)��#�#�ޕ1��7�F�tj�a�p2�ہ��l����I������+��t��A��9Gy��T�&ei����^�V_CY�]d������&>"v&�f��=@W�K�\��~�y�w�"e@��7��+��Q;���>T;H�� �vdQ6�����1�����&hZ$��,�k���%�́D�0�>Z�_OH�'a�BR���i�F|���xΕD�J�%=�E��zu���zl���	���i��[�z(��\�i��a˫��;��YPy�cק:O��p{;_���, +�M�SV<�� w��a�P�*!ܻ��"��E;}���N�Hx���h���x	Q��4��<�M�2jC��Ɲ�{ٓv9��v~�]����h{���_c4�b�FF#�_�F��wjk�k�'<�j�vv�4���N8F���-0Z@z@M����=*2����!����̥�,�����mbR���h�T���B��^��KaY����#M�?4��Sk�,-YrՁ�ûg\������6��=�)��$�}�:�J��&CM���n��4	���x�W�al�+�~�Έ�ZI�)��B�J���<D�}���[�١��ʐ�0�Ur���[5�T
Yթ�\U�����/���l�$��Lf�Ix'�n	h^�tB�'x}�J)���ˤ�s�S�3��1ƃVr+ T��m�,=��tKn���LѶr5����=��%2Bg~��A0�c�p�7;�g͔������(q~ɓύw�(^�k?Q@��$�ux�ߩ�M��`�Xͤ����R@�-�qL����y�oo>��>[;�����B��hK��6���c��+4���^AG^"g��ā��j鵦���X�{B\8��['/q��Oh�k�|�]�9_��d�
��Z-P5��/�d�����~ܵ���P
��VULu�힇<��ڽerf�B��@x��i�%x� ��d]4_��FWRq��
�	#Gg�*��x¤[�2���a�w�Y.�����f5�9PK]��%�����1���j]3V�75%aM0c�7 ~��¢x�����]S���Z��pV�#1���)e\p���Z�4��{�'%W�\�j�,S�!@�n6~�n��㋨�3��t�/�p\�۪���y�L6�x�=��o!���R������4��4�߼���զ�}����e��^�4���/���������S�fY�c���e�́�R ;��a�#���n�&�{�����X/Ha�l�[�]��C�v��dTQ��޾����pJg����a�I��T������o�E���8�L�|R?�ܳ�c7/��.�_M)�ʣT)qE������,T�ݜ�ɰѫ�ֺ��~��5���W��%���?���>��2$��d��QI]~�C��8���P�\g̨K�f���n�-���t���R�-t0}�h���[���(�0ϖ�g0g�>>��L�Ӝ_$p��p"�+���T�|[�z����u������2|�~d���;���@&�QG��lܓGts��� �S���w� X���Y��L�91+����S��%ɝ�RD:�ŏ/����_������5n�� c/���U]�S��S>�h�P��[�x6��]}��l������zᶞ�1#�4d:����Q���{���|B0Q��H��2���j�g0���Uo�9m�ƨ#O� ?�U�0Xl�e:�9)
ڥn&�IxS��Y�LK�m��-M;� o9�Ψ����Μ+��/c�������C��_���50��f�1V��t}��Hty���ӈ6�����o�d�y%.�
��q��<1EP06�3�u���+��uu�p{`
*�R�~j`(N{D8�l�T��UGqGo�
����'��q�<�����f����Thd|O_`0�m>JY-� ��>ѯ6����'R�`0"�7����o�8� ����~�U�Kq��蟡�:Si"�5�S]��
�l�;+Hz	�W��t�jD��������P��pGݻʺrw�x樦�|�����#�c�u~u��$����oߠޫ�J�A}�l	M�t�:{&��a4�ϖUc�Q��/�Q�D�Qw�e~ě)�^;�����]���xv� &sLn�ˣX��d�o	/��1��|l��Em�>T`��@�u`���ab�y���kI��yc����ΥYR�q�K���zn�R����쭦�8�;�}����:��4��k�8'1�V��+c��T[��̀��iC�"�;���~�+;.���"��d]�6)^����o�Y�S_yc��s؝}�x�F�����Y�p%ДpM)޼w����Ԗ�-ۈR�\�q��zL+l���M���W�+�R�4����^���i��7ă�cش�Zö�~����C�ujlA�^
�5d��2��>'{K����D��Y�?��qm�c���ÀON�R�A��b|�P��/Ҭ�Ďi�e"�e�C#��	� �3�>�':V���������8�d�����i�vPi�����}�~E����щ��:҂���̆k�_����e���F�]��d�m�Mu(�c)QdF�+H�iu�z���`z�ne� b�������A��r_�?Vw��\q����R05��U��0_F�4���<���Ti��^ne���^�7ټ�k�p/��\���K.�:���u,@-LVȮ獏V����x'���e������8$�%�s�J�9r ���ilqajI�I6��d9U��Q��:�<W(�Uڻ��$�u��y�a.�m��Ft Z��aX�+�o�� #H	���-[Nf��<�6��2��/�'�E�эwA���q�_bko}qO�Y��������v���k����棎d��Gh�S�ǌQ�v�(ƨ�1�X�H��������m�#07�z.�a��]7�� �c��)Q��1�ӥu�h������#Y�kJ���?vzuT��y��x`�+3[/A���`pl�|񘑭_���<i��C.VL*m8ĵ(u�ai��y �%%�+�'	
QK�����f��1��	�8���S�0��ė���[�8��p�d��T�%Y�"��j�)�n�9�	��j4F&�]�K����m��Ԃ��.�^sұd����T-f-�U	jg�(���4�����=
���&@;�#��� ��۞����H ����eS��c)��i�P��wE-��A�/V�!��W`A>�u�V�ff��4���|�"�1��̪K�x�y�6I�镁Af��U�F�^�?2�n?H ����Y���8�s���X��6�s-��3�ڥ��Q��F^�����K$��':��Ѱi�Iܿ��ޜ��l���G���݇�q4$Ke�^y�ky8 ��ضY�8�|��^��GFl���g%0,�����\�RC�֒?mQ�#ar���j�/��X��Wl8�������z5���5K����q@Vp,;�U�D����~-Q��~���~/������ɷX����+"�e�D��7�ۍO���Q2�}xc�';��v!i�Rѵ泡�:�h����þ�!���?�C����� S���z*�������נ���&��o���L��C�8�s�#&e�	Q�@
�ך���7�9Qd�T��#��e:�\_q��M���֧t����W@�x��T��zз\��q�&��������m�i���`��쾍�;s�i��D�s_=	�k�OJ���礙U�C~F+5.JR���K=���%|ճUh��%đ���t1�����rݱ�|υ`,��{�e�1t���K��z��2Y	M�e������a��~���(�{��#��`�Xp���я�Z]�Q� >ˣ��;��$sR"�@{6-���8�j��c���ݥ��,x��0GW��Y���~��u|5�f��Ϳ��Z��Q�����N�y�C�Q��I�֜q���J�!�.q�Xj�R��E�
�Y���!S!g@�Y<��!���"��_������q�=1w����M���� ;'|J��'�K��>��e��\w���;�uJ�8󒥫D{�2��z(�(*uy��ؾ0��ݚ��8���r�YD�jQC��!�<��}X��@7:d���\}�0�CN��ޱnЃ3���-��ސ��]t,D�=+��E��{�s��hI�/���yq��7�����&L��0��Ķ���(��p�5��|s��d�sh���'����?�(h���������Yu���G`ݛ��h���K5����~_���\Q� �	�T}Դ�c�����+��Q�w�}��/���4���N�[������(n��Zf�L�J+|Z��g9�+.a`,Ea��I��*�ă��v1�y_Nq�O#�R:m(�퀻5�`��*�O'Y���g�5w�^0�Y�{(�}6��;��ܷT�����v��-O�P"[�@np�B���ws��S�|F}KH���zGR/������)=���s{�k���5��beӐ[(}��hn#,��}7G�W*�h�5M�||���=�۫����j�-;��� +<�@)Ʌ��܍��,v����r����TuZ���l�c��z����Tv���K��Q�k�*'�Q-v���U#��p-��?�a!�O��ޯ��P8���R2�����zu�eXD�a����}:�E�J��{�+P�R�(y�mwf�q����g�v�~Gb��oY���E� J�᪳W5(��.'Cd���]�Mցs 1R��MD#��pՠFR��:�32K�ph��,�ərc��7�����Wy&�f
�V	mw�i�H/"���=S0K�����:����V-��p���
�z���j��W�!G�m9��~!��ֵ�u��$][e����?B�PYuZ�� T�-�(��(T�ĕ�VP��5fgX�`��:£c����5��&�����+G!U�%Ƞ�3(���:q�{����:V�a��m,G�՞Z�zn#.��
(	׋�5ж9���)/ؾ#�m^�w���bP�5�s캄�t=��_����_W]J{H"�"���1��W�	�(u��\J̫����Έ��{�g��S/����Ω2��j����^C+=h� E֎|q!9���ݥ��[�D�w.��8� <v��Y����Gw�N:���Vm�yZYW��
�q~��ǀ�h�M�ǥ�YX��<���N�+����
�����#[j��j����<�Bg
v�*K����[��Q/��U*�3�&��^V��G*��qO��qԺ�0����2v8���3ɚ���|�ՃT�d1��M�z����Cwj�@��ߩ	q?y�p1�ȳfd��D ֱ@�Ԥp��l��;U�_�F��#G&�:�I�e�O��w�4��;,s/*�'Gn��Z #��ྶ��u˙�(w��Mp�Wc���e~b0s�a�~'`a�UU)�A��Z"Gv������2j�X݇0kn�4F��x��/��-+�``v]��?��{�� $g*���l{]Yެ�^>���/��^<����c�߻|�a{��lw��钐�h��藅��燸u��jc2�QA-,W�����V�1S��lu*!Lb5�2dd����.��{�+J�U�'���4��Ĵ�����y^.*Yȏ���k��HbA�F\��t�����4���B{j�SPRJ��f���P}^�Gk'�����/-�q����t��҆�rg�
c
�ǺV�d}ېۥ
���0Ő�Ð�T"����#"�;���mwb��0(s��;����W���>��I
���
,��β������B_��8�'�	 ��#�,e���~>7[ZzG5w��7�����p�����3B���A>p����@�QdD���P9�>#�C��%�T�3�n�c`�c�^/��Fahj����p6�Q��n�2� ��:�&�۞��~.��]�&A�NFd	��醣*�Z#���b�Χ�`<���N��2; ˔�����v��Pj& k��W��q�����	|��#�[�*�}zP�שۼ�%wl_�{ʀp��]"pG���m�I���wV��H���Xl-�s :�3�����)�fxj+����g%� ��p]�Y�^"5�+&O(oH�9���i�!���]�4-Q���п���Ui�ץ�J�Of�V����3�J���ȧ;���}o:��W� ����M��ĺ��ȓ)@��H��-Kg�C0pHLU�t�_N��7Y'�z?�h��9j���e����uA1Њ��4 nLK�ő�����G9���ɤ�eY���(���?'ip[�b�}��[H���A{��im�����A��߁��v�ư�A8��B��$��.�w�QO��%~�g�I�P#����>�8�5�I�g��[Yi@
|�?۠���R�G̗��H���7��Jck�u��NΙNO���Y�4M�W
��h�`���H�^������]H�),✖�g���U�$�q�.�)[3�Y�Ƥй%��n�J~�x�ukG�ZA�_���n.~�����t�Ur�i���y����0s;�$�aa��>���I,�B�����i���|��@�h�'S-gI(H�}
���,I�6k=m��H�8���|0�_�����ʥn�e�T��*̀>��Mʮ�
,⑀E�?2ǣ�t�qA��ʋ��`,KgJ�Mn�W�`�`��٩��y�)T���h�XF��E��z��Z��և%�Fb/SR.&��!�Aa0��S�HrjY���=��?�IL4��,�#&d��jS������ψ;������Q�~u�;���U+���.P-�ȶ��)�CF��K�F\��- ���s�T@p�GX_ N�4sN�1�Ge��~�	鉗X|?����Y-��aV��$���VK��
$�{R{�8t2f�\��y~�a��Lx���JO*ɕ��I&%[��w��
\��Sp~`��Rh~�4�+��� ݆�1 �HY75��1Q��k�C^Iv��qY��W7���G�A)�/�!٬I@L�k����Ne�(�	��`�L�ucr��,��H�s;Z�)��eCa��Wg���l)eKB�O�'��s�V�W�=z�#3���=�V=SiV_`$�|���Z�t�K2�=2�3e�I$J��"�I��"�*؃y�%1xj"���3�BgĤ�?>�貚}�4���\T�I�n� ��uF�� .R"����ߋ����<jKH�*�+��f��]�0����m��-�c�����kA�v;`nbN{_TnQ��Z�X�/h�;�B�8�*Q�z
������<�Q�_ci�4��:[��N?�5�j�;�.����yN�B��N��7���ƺ�0��]��*�aӇ��m��<�r�z�y�+��)S��ui#��	Ch�Av�dTu®泇}1���u+��V��Lz�Q	���A���ud;?�3�;�����O) ��/�����O_�BWJ��ܯ���h��K�f䴎� J7�X}��Bhn����������:mS����b��pڬE�kE$މ&��Ku������b�m�v*1-��T���}�nٿ��֛ ?m����1!�ז�J���c�jZhw0j��:J��
戴�!X�aW��G�Q^J,{U�nYF��%pby�n*~/<¬�3�g*�z�q�_���5]\s��Jz�Dm�bG���6�ӌ/�i����n�6İ�>���`�0�O��.@G�B��bI����L)�Z�t����x�ײ�y�� �0&hX���ON�Û�/�G�P���h2��;��0ʓ�x2�?:'�� �+m��٬j��o��'��lԛ������	&�nE��5I���X�-�(�*zs|�ߩ&�A��`���{�����~Z�V�z�Aà����^+,}`+\) �Wb̶��b2�ƏPp�\���N3\��vޙ���3��e3���]5�!��J4��c}���=�(��LY��^6�6["�	M�	�2Jf�������#���a���{�
2��线t[� �@/�e�O��sȔ�X���]�a���w��񝙃
���/ńh�c�1Cb�1y{���/Ir� ��w�s��E{��M�V,ʕHU�Y۪U�����ɜl���fMcFl���C���Rk�.�E�$�(�N�UPs�5Bq�����6X��n�> v���^������L-?��-��У ��>X����QJ�����U�~��x�W~�1�����V;�&e�_S�}~YX#v���\>Z8���3#2��*�U[�Ve������w_��@X�ei�uZi���w�lv�ӺЯPG�I��!6'���ü�����/�>�0���MF��A�WF�?�p����6�R�S���Uo�e2�̀�B<�[TĈ�֍�'pF\5��l���K9�	�P���������/5� PX��D5ҍ�з �������"�翔���<��8�~)d��c�)pR�͒�+���r*�i�������g�_��r���m��5�\V��Y���@�!va�1��|�{T�c�l�����#L�f�*�K�j�is��Wڞ7{���%��e߼�0e��j3��&���M����E�R\�fV9 bN}�˓0 �(��H%�������2����?�J�UZH3c��;\��_�+���oE��wR{���ĵ'�H�v�>�U��J	��ϻ{��DTY��E[�NH��l�	Ⱥe�A�sc�X�?��X��;��̖f5�4d�DY��[HU�0{O��.)� ��U�Pbh����=1�bI(`� ���������7y���J�|�:E$W"�A9���,� ���A�Al� �Cj�t�Of�kY���ŋ�=�
ƋA�X��Q��B�B 3��{ц��3p�g�A��>��xHa���Y-R�*G�)��(�+ώ����MF��"6��u�E����މ����$!�}l\q����p,�^����b�8���zP�tn��a1��u���[�	��i^��
�|ʁ�6��w�Z�]z�Ȧ�<�1
:vB�hK�4q�����;�������1�瘂&�K�뎯[ޓ������ͬ�1�ލd��9��X"-��I���]h|�
12%���:�_u�I�Sb�j��cQX��*�
T���\xϪ�L�K7%��`��n�J�@�?!��0̈Wy��a��sV>,�Hj���J(����+����ʲ�t����k_eE��V��&_�����R�={	u
0!�1	�m)���}� ��?gQ�ө�]�.U4�[�_46�b]��,l���L�Ѳ5��w*='��2�U7�D�- ��}��E��h����؊�v�j�-p��(�"�:�[}�]apA�����9dc��X�����2�`KNV8M=�4�(y���g��$K�uC�B�BW�����
ݞ� �
�E�x�G�E�1�A#?<9�
U�����Fߧ$s��J������9s;�j���n7�����`'n'V+�A'j/�Qօ4�=��e�A��u�����U����=��<"S'~�K��X��=%��m�����K�Hz�ƛ��v�t����X��/G,�A�T����eu@�:N�)����fEV�� Ic?4d��1o% ,lPjuS�zIrc�l�]��n!� ,� A�l�g,�j6���|
�~j�<�%�j^�$}���I�n�ye[S�kbմ���6c��q����]o��5-��U�z;W,�U��jE>�:xQ��49ws����n�4+�%V��c*�L�z��53eЦ6	:4CKM��`q/�pOy����i��գ�5�a���c�Z��!�_����ł-��<R`B�Vy
��`���דig�Xc��������kij �d��~����	� ����B\$���)�M$�(����g���G��m�ǌ�,x����
V$~��Õê�C1���A�6υ��j!�f�������U�@�!��-ZEY
�M�[�N��G*o���S���L�7�͡LzqC�Ct\��5a�*ny��IeEh�@�-W0W10���s�^ipO�1Q�2�(��'�0D�)�[|C�.YB.����y�^���i�2�,����&�6�O�h�҆^��|��^����/�(F��,0�� �((���3b���Y��� ����q�.gWZoN�H�j�!
Tá�|wXy)c�g�L�i�k�v�?��:�g 0Hf`2�_� V�A��T��p�\O� J�2�1��������B3��[2�v����'�ţ��?u������-@��xx��i;��N�u��B1:ݬ�@��K����l�~�7J]�z���4�a��lAHƒ鎁
M�K_�{C�Q��zJ��c�iN$��W�׿$r�~��4˹1:�Wn�I��{|gM3���s���w�Dd�p���nVhq�eƖD혌L"k���^$�3U�fǞ0�1���`e���+ɯ|jѯ��'3��%ۨe�{�V�PCR&��x}���m���T���>+&���Tl-R�`��O�I%&���V��CIDUh��ƺ�$���K��
]�Ny�"�.'��*�kĘ�j��jG�v�H�+���?H=ęX� ���q7��9���Y����N/��k�4���`.Tl�c@�0,��F.�Ԋzue2�C�>���0
fs��k@iA��36����_j��x�>��4U��[�U�A����)L�p$a8dR[S ��ꔁ�K�խ��~|���K����)�pp����r�\:�s�Y덆�C���Jy��u=��j�Yd{���@fT"'m�A!�,��3|�s�������a��� �!sb��n�o��%�p-He��	�R�<�m��'>�]�O���WB��S��B���&��R^"�M�w����̩�z&s_c~��q�I�x&�A��!��1Mm���w����!��]�Y�2�*�>V��~��g7G��0#0ID�65\&@� ��o�"��6ߪ;�*��1R������U;�2��3)�2Zo��������v�s	�qV����nln�%��>�{���$���
�	|��G��)7��zS�<��æ.i�tO�S-�FW��+�����w�����o�X�HU����)�{C�Z��]�@IIA�W�A<��,)i@�&��M�f����_I6Z���j�L�^�#�x���F�~���3��     )��B�� ա��^�ұ�g�    YZ