#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1043691754"
MD5="f53bd3c33078a7dfe69ed13356b19dc9"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="27316"
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
	echo Uncompressed size: 44 KB
	echo Compression: xz
	echo Date of packaging: Thu Jul 16 03:05:24 -03 2020
	echo Built with Makeself version 2.3.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--xz\" \\
    \"--copy\" \\
    \"--target\" \\
    \"$HOME/lamw_manager\" \\
    \"/home/danny/Dev/LAMW4Linux-installer/lamw_manager/assets\" \\
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
	echo OLDUSIZE=44
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
	MS_Printf "About to extract 44 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 44; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (44 KB)" >&2
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
�7zXZ  �ִF !   �X����jt] �}��JF���.���_j��8.&N}����aT�"�0�-J��fg�`m�O6j�[����Q]���vՅN����Y�җ>ć�6G����J=�UQ�M|��N�=�oH!,���)���7���e�
���L}��k`)��= ��x�TH�4o~L*������=J����9t�*$�ه��;�F�ځ�R�)��W�ރKC
�+r�{�J4�Iߤ�>�4��{��T�:@<���ݼKv�-��2�2���;7���Av@���Mb��K��Y���bV-�U6��Nm��7�ѧ��$�]u/b�L�5C��`�O�.5R��ćKI�\3����f���V�ܒ5����S�/�
�`)�$���oz�m��:��JC����2�W�ϋ�1�<���:���r���O���?�������0T��rd��[�G���Ix����Ӈ��"ơü!�d�7?�O~��*W���x�⭤��(:�L'�C:鲧o.�bfY�n���r�V�؟Il�oĉ��G"2d�جAPOu�V�����̛�yߔ!Ī���6��K��=����O-�5�#�Yr:B�gl�s�y�=�3��]y�7b:�׼���Y�:jH��i��;ȺxA�ޘ��z's���_��X��L�јo�J)<�\9�ªY?{A��-.rr�s�T��r);'kb���'u�������T��2��n��7p%d�p�1~38l,��Ѻ�f~,��=�5��_�$��NYCr|��L4�m}P~�U|y�)�hނ݇g{#����q/H,�i��<R�I���[�?����:�W��������;����o@sA�)�uN�y����ةj[�q�$p�o�-CgL.�
-]�*��o�Ok~��
���k`�*P�k��*�9�y����R��W�� �H�y]��������70L�}c�t� o�&�qK���� �!c�c��Z�N�'_ɸ��8����xM/ga&tm7���	�U
g���^~���k&��\���>��{\�Y���{��V:FUM!�#H�O��kLd��d�r@���}q�x� $4�N�-!����G|���b��6U,�B�����J���}�X�GPmg��/Pvb�c� $������&s�j��?c.�^�<�/>�C#�c\�_\�cklg 9�ʁ�$�<fNc�7�{�C9������<�tm��)x)��C0����*�b� >ȿ��_�!E��?�̎h=?��v�d�y��'�ʙ;ri�� H� +A��!2��"o�q��V�D��Y�X�qsp<m ����Nnξr���h����ɟ S���Ć�~@iٮ�R�7�r]���&Ǒ w���A�h.��8 ����3kc�ݠ�-G��]^�.w�;��\fG�K����|�1�n! cC�%���8?�	���&�sL7NC��^M��Ψ)_U�:�y����U�4n0�xT�
�g7��ߢu�A����C� �^ݽ��8"ۀ؎�֣`�{Z�1O8�@p��ރ��F�Sq��'�������҉�}a9 �Ҙ�r�[�k�U���Κ%�Y����D�<J�2Nʹ*	��g���l�f���+:�^'d)V���m�	�; �Y��;��Dq<�oy-.<�gf2��| ����{��(���缊 �p�n�6Jr���	�P5�E�cV0 F2r�2CsgS��8�'`4]1ں��B���[�>�8�{DSgpr��E�7�V�Q\�1C�$��@��E5w�P�Mou;:�!�0);������xd�s4���f����[Y���D7�aT�P�sn�{�H7u,G�9��َ��%7��^��;[�8:�H�'oX���?b��;��&�~j��X���F��G薣J���$"jh�j�p�-�mʆ鋓�_�)�(O0(��^�۳'��9��;bүt�gЛ�q��<W��@g?f�j��@x�^�����'�v�:4NـkFR3����=��
�,=#�
��
�w��|���c�rȿz���V��x#�|��Gm�$�����jQ(��Kl3���)�L�B&�A.-�R}K�ۙn͇��7���؞`� ��#ࣱ��;�U��˘�>�@$됮%Xn)o�Ø%9
�]��ΓaxxNq��ī!�o��b��]�ь���b����^k6�cUM�y˴�,�U�a2����/H���r��w��0�O��&��uk��k��Jdd���'�#}�!��$U���� �`�YA�a6���?<�.�>�� +p��+�4ێs�7�u�2C����SD��j��߅���q�"WCo.�<dm��`�v%��������4B�TJL�r^��py���5?�I�+���L�6r)eۓ%խCs^��rv�Ig6�^��<�8����z��踴3�����I�S���\��/9�����/���6n����8�%*Vz�i��N�H|ٖk�/�u�U���M`|�k���+�cn�]���vtn|��V��♱;\]��+\�:��-n	~}pn� X��n3ir ����}��Z%� ��,�BI	�*τ��;+�W ��@�2Ѹ�)a�CԳ�CA�S�`O��%u^�K�ИϞ��W
U�o��<4CiZ�w�S��>�3�t����Ț�s$x�}�ث�.�\̵���9j����$�fF�n��kf��ǥ�??+��#�$˅R=�����	�k�`��;db�1�\ �^>�<fʴ�>���jJx��c�a8�����@+}��T/񿚐�>!f2�hڸ(����m�AU�Զ�(��5�b��'�iZĄ�g���
�7���+�{x��:���{nJ�L(흷`�z|=��� rr���}�}��Zo���0�]�If�lRȞA�{�i��r;�`�	�Ϗ�s�i��5���bDe�=[�u�i,�O�0E^>�2�D���ͭ�3s��(l�Y�s+n�O�z����h��˪O]�0I�a������#��!?�}�9T���B�P_baJ7,e�Z��:+�~S@\�����A 䣍�9~4�2 F~	��e���}����eZ�a�:^�]"/�}SӚ�?NCW�wP��a���0��]�m�@<;ҦI�_I�������}W����*��(D		y�N6пp��)io� �|�V��|.����9� �����R�͗=�-�����d�BF�1@�8i;���宨�ey. �H�����7~�.h�)�A���h�;�8h�F��~���e�f�����9֭�7��!G�b�t��E��m	�����=`ঐZ��c�A���L�����y�*�qs���T�J|H� :�.W�Ӗ����_+�GfW���?��W��H;T8���b�wk�(��QM=eT���AU����#PY(`��k�3�7�����uO��J��<���H�a��7EH��|͎ ���}E�=b�fO�h�ϗx�����c�ɠ�K��qz;�����7�Rl�)#�hhNfK3	�Y�L�R<n{������Z!"��7�֤;��4z�Z�����R��4(q@��˾���\��q��gh�*f�o/Q�"]�_��"~�g��XN��ɰݛ�Z9If��������B�km���}�y��>pE�A��e	Dk#�h���T�B��+jм�n�qa�,Q�OHo�����a��v��U	�s?K�{Kn�]�hrL�/��J7֟��{)iA�7�R�w�ސ�M�9��L	��#����Y���a$�PZ�
 ����#& ���)Л�آ�[�|}�� ���S��?����_��e��t�;�騵�ݿ)+�h��Q_�����o�K`���7�tI�h*���_����Pl��d�@+��|��Rڽ�]��6�e�{�&D����{��$݆* &Gu�l�u,����>j�~vB���eyuʋ�e:`gT߄�ʘc7�ב}�	?�7�F1jԊ7���DI��[�������>C��$�Y+ű׽�	\��ڼ�K��Ci����o�0�5�3_{5�}z��)��$�5{�3I��"?����6���+������J����V*�{��$���2g�#~N#�������u��(��@��V3h��4�5�fU�	v��PA˘�'��6��gPH2��%���5�L'f��͖��=N5S����g����L>gn|,VƎU��9�x�1y�<��k��Z��h���t��^�����>GΒ,2�#�}�Ta����)�O�}@�dj3�Sʚ����8>�u���9�:n�F�(nPp�G�2��`=���O,�7��$y�)�~��p��Rm�OYq��pG]�@|l��ʻo0���L���z�#Ʈ��C_���/#y_Fݑi T�t��O�j�[���rYqUȝDUU�U�\�H[�w�(Lօ5�l��K*���k_�8�^��Œ~]v��X��Ղo$g-�ZT�>���i�c��;<�LU�܈F�̢`�S��k�� ��a���<�v�03K�B�	��s��.���@@�������$@K��iJ@���l��Mvi`��Z�vO��H/u0@��M�v��o�/@���B�C�f��C��j�x	F����x��V�;0Iw�C�Ⱦ��1�&��o�GwY�K��k*BH��8͐q��r�:9(��s��S�?�X׀��5���ZƪA� �]O�����ς��4Z�oD]PX�r�$�i&�y1�++;��������G��\��B�@��b�������#���a��wg�`W�drȊ��wE�rx�^���iv3�5�,x�N���"��ɀ
 �
���ߜ��ꯠQj��Uy��=Ŀ�l yZ�s ���|����n�� ,?$Grx/-��w��K��/[���I�x��Q�Y�0X���A`$��M�G�����V���InI�wg���%ڌ����˽�l��"%�p0�5\�'sx\����	1������y��k{�a��"���U�����A��TQ��6��`,����4��oAc�\�az3�MXNFc)�0���ma�	��vwp�,��K�0�KU���,����ge(���MnE��4g����N�8�qϞI���E�sfO/���t#P4�[QgpqK�(r�X�E��F{21��bkǦz���v(}���/rKG��Q9��:OVZ[	�#LrT.��W�Au�\�S� �e���,� :"2�I,M��C�������Cޘx�4qW۰�<�����3b
=����g�Nō�\�k�M��=K�v��� �ݽwhsM�@/����֝}�kF0���?R��ӈ�Ff�oc�2�����	�����lS�20x��f�n��0p�59,��!�[��RV�ǰZ��7@��i��8N^��T�T3�t
��}�o����^�ƹ<�Z͌!�${S�z�ʠx���ߎ4�!�Ŵ��Z��9�ve�J0/iT1�<I�2pa��ͻ�{i$|� !�l[��b�`}��)�O��
��1�O�ՙ����d,:f�S�}}3(�HI���*��[�l�K׈{S�nx�S�㉬��6�&@��4�H�g���X����3��tZX.ҤXr<�7��	�0q�>�V*��|���..�(v���P�
<��)K]Ȑz���,Q.�9�hx8.S���cfxd�ܖ��}}s/�qn��2�7�9��2��Sz|�/1˜&U�fK������rܜ����Jw�:�[�D�Z]}����*�6b�NN?J̥�����3��H��;�z{o7W�-�u�N��P�񦕗�5�}U���Q�E��1��B���P�S�F��1G��~�8���-fJ1�2po�������yCv�|��x_Mc�7�.V�9@�)�m㷬TH�C4���%��	\�_�e�{�����i�'m/2��]�oO�}t��|/��V�i!�~p������=�����(�D���S
�!��)���^�vxj�˝���H�6��7J?;���C*B����#֥�U�>?ƾ)*��h�7E�(d��A���H�2̽���lT�q׹*��~+�y$w��T�yPl��y�ϏJ���v���D/q�V��V�5���9�6dg�"�mOR����o�-��QHzi3$W�(*Z1#�I��ao3�]-�CN��M��u��[�2����8�$�5ts�k�;J�d|]Ԥ���3�"�#Pƕ�?aZ�N9N����?��YA��XT`D����;�4%��١L|@��`+�b""]����^>�4���NX���V�e���w#��嘭��?y��8$�$R����'I��x�L>�|o���])�10Kj���z1���:)�W��"�W�Ώ�a��"��QP�i��	��2�����IݵK��q�l��Vb�F�B�� ����c�E�r��p���>g��5Z�}�6�����-"�{$��X:<S����$pB��U��CU���o`�t�!�jX�� ��(H�e��ax�Af��������z;;�o�|��u Q��SRrx��Z�?�WrO=�3�K��0�&T���˅�����7ߧ��."g��g�~�z�r�P���
NRK����X�;��OW��Dc΃�������:I'��T���rJ�����.>5^u�U+TM�YjшH˳���H���̜��R�\S���}�Ȭ����p�W<�k:��V����M����c�ܘ]?�|�ߠv!"8(�N���\��~�]��}�����N�ϸ&i��2*��!A!�B�m�P�(�_�b�C,9P_2U4,�J�p_�b7��9�NR�Ř��'�!#�}�/'��??����r��^SH"���sU�I��ˌ�?�
7�I%����
`��4f��q�2A%�����+��s�W��
��(��]�i���=鋿��4�4?�*��uN� �䌤�8���4J���-���7�	�Z�z���<:$���6���ƾe�!�Ќ4�HyS*z0p�;�L���?�p�>�h���Ur��]� [�m�9[�����5�t���3�\b�jmmb�A_`Q�t���?DU�C$O}' X�� ����[զ��[�#zی/��A,�l�=u�q�����t�`K�+/�Z�h���ybK�*�Q���ƤU�L{�����x�c6-K&��L�7_k�
���n�\�<W��W������䴗���OS�C���0Tk��C�K-bl�;��9*�9"8=��5yd��R�w���X����Q��F|m4�\g�C��G��T��p����0i��QL��"�T�����^F��_�Y�3��6�6�OI^)Kӧ~�]bJ�~g�x%.��ҫ�<�N"�$�	��GP�Ħ�P,�(\m�3]T��T��\Nn�LD�}!~t�?�	�E�"d�f����W�_2��q��k��q����2Tt��3.)���gI�Oi��:&_��J�u*P�$��ht�@���׼LI0�	��}2��K�;_nY��Qe��jNSjg�z��p�h>1 �5(	��5���T��rc��|�Jm +���ʏ��v���2���;^���\���i�R{��|7���d䚲ÕV�I������!)�N�<�<U���mO�"��$I��L���jk�zG�Hi�8s�hf�;O#q`����+��������9 �I�G���f��u�s�|�b���q�̟{��+e�dU��{&�L���؃/����rױ��h�I��#H�mg�q9�� ���r>���M����>\��)���lao�c4�'*0-L�ظ�G���;ϐ����HGZ8���(���3��r{�����"ȏ�g5�DW&8�ޣaR��mP%�JW����l����E�ܱ��������23����	D͍I�TJ]:�c>7��>�&��f"��C'��7��ڜ�u��O�_�u�p6�*F�ɚrp��o9YNͿØ�QX#E	i=��'����ٟ'>��o6��z���}|/<�ɑg6L!E�1� �4L3��wc����j���\R�1��p�S��N�׋"D� OS=�H�+���7C��d<<2��0�Z��Q���_�<�32�%Įp�
�O�af�S��K"[�DG�T@��_�(#���=}�
�H�|V�ϛ�Jn�Z�;-�i;Xжc���Q����I-�#te���qM�_&�[��}��nեQ��f9Z<�'���� z,�8|D�L�"+8~Sk�.:�[!]&�57~���*|ĉB�J������ʝu�+z⍸�S�܅ܳ0��?��Ý�p��%l!�m �˿��M��1S{�W�����5x1��^Qf�T��B=N)KO��H�.�ȡE�S�J̳��:�(3�q���D�6��8�L��2�������]��g��{���NN'�e�_��l����	���Q��X_�J���qm`��I�粒e��T�o���ĦT��b� $�n��lk�M�eظZ,2 �5)���P�V�����q#��:d���!5��zB��A�
��N��GG�����n�9M��*q:���)e����K���M?DɊ��<y(�I����Y[Bf�
�s�i��"q�����U����R�r���U�ޮ:��,�� #�7�^���F�pǲ�`E;��[�^���@I7Ba��ّ����"Z���Q��Z;f&���Z��������A���2)��y��@�	�A(�$*����$/�Q��Y�$w��M�Q^���%��0���x����T��,��5
�\!�����Ѧ�y��f��Á1{��h��1������?V`Jn�B�"�,!�o���j1��ɳ���)��d�t�	,�c�� �J��{[-"��H[������H�E�EM�C�/��hr��K#Tu��r�+2\�U �6q��2��j���9(�T����2�\�-)^Rh�I
N�b��
PN���5�u�a��F��5cF���p�تs:� ��۹#r)���ȷ�M��b�!��G��:ED<:����0L �W�	00[��P��L����|���eM_,H�;_Sɡ�>t�Bgw�~	K*kITO��+���{�H��Ž)-s ���[�o�_9�8���P� ��2��萒���m�=^�=#uvǎ ���5m��*���g�Ǿn$
j���?���2�tGv>;=�x~�վ6B^��w4_���;߈5���IW�E*��߮�a��x�F�����bX~h�$���9C�w�i%kT6�ڤӈ�����.�B�"� $����0G$�B��gI<9�D�~��ʘ���5
k�'��(�}�c�sC� ��y�}�L32M@�(�0�����#�)���+ ���{���j�pÞPT0�a���c����;��e^#QNG	�f�aЙ�H7��z�G�"2<����2����\������.��(e�'s�>��f:Te�M�&�78z���r��r�S�[F��ڟ�(u[�w.p�j ��5�=L���r$k�{s�e�m��NojK�m�)6����=������X��B�0�͆Ʃ�N9S�=?�d����S�̯�*B6�%I1�|<֋uf��3:���#�](Qc*X��:f4�-�3����B�:�)k6�h���q�t�&?�=N���qj<@�1�V�N�g��Z�/!��px��p��\�)���3G�:>X
A��AG�-�ė�F�e?U#�88c������-�,qki�+�vH��$J�g'�gX��r�$4�_����|1��jҹ��q{����l޷������(��v;�#y����V��XT��/��??l��ٿ滴}Ag�3~Mю^ł� ���!ZgX�a�ç��+)^�x�H��eD3t�[N���I��s��n�c~7,��i��\�}Z��6��:}��� �8g����N��QX�8?��
�c.�E�zjF��@���m���ã� o�/��b�u1������0���@E���6�p��JT�0�`"
�	ލ����G�?x���� :�P����c����E�J �
%��(�̽�dӌ}]���߫�)m���l�s��9f�%._������\IEN?<�����j{�KW��|�X2�u�[}(^��?Ǎ�f����~{�<9G�c����y+�d"��������[��v��˧5;��MW#S~~M-�_���$��}�[G�[��[x�?z?:\#?s��R�V���Ra����o�e3��̈́a�z�U!�,F�`3�{B��3�=�m��Z����P���l��ڸ!Ja��{i���{�$�I����W�S���6���|�R5��V�(�
��- ���3e�{˥H�(��=��"�����c�=R���٤������QK�8�3W����Ѻ�O�趖WU�;
hJ��Ob>%Zk�L���ՅL,ဩ��T�#��}\cz��0�Rʢ�b<�`[�Z����tb5l��#D���:E��qh�.K��"4^�2�Hͺ�w�p�{��� ������ʼ�;C���N�p�g9`_TH�4fl�Ҍ��K��~�M�kz���uy��3���j��� mdֹrK�i�����,_�ռj����z��,��Y�:��(k9P.�!c�(�gj���U��-�W�1�d+�/�e���E�.AM�dݺHp��o]E2����J�Ζ�L���IO>B�Xe�Ѱ���M�ӷ��`.����
z�4X�6����z�3���C:��7����Y��N������}�é�C?�C���uJ� @�����|��ȁ�6=���u���������=�bJ���1���)�0S�N"�±^yl%�� �f���Rx�Yo9���Ay�� ����}ԇ�y�!(L�"�렠��]��dv�𿁎�n慖 ->���QC�l��5�����s" #1��>!K�7�m!8�4b�.üf���}uCc�f���&�-VrK�oWL��i�OX�~g ���uյ��&��FR���2�T�\�wd��P����)h(yt�	vVJ��</���K�/���SE�� ,B��x�n��jΒ7�}!4'�Z�Ks�����en�ߺ/U2�s�>$UU��醤	�вģ��/"���A[<|2�=����W��\Xq�)���1��i�#�guA�:�WP����@ ґlp�#��U߻^�}�`��_5� ��g� 1u� D&������w0�a2�!r$ف	�1�|���!0��nur*Z�����@;;����X}� �Z$ٷ�s7�x�бG�u�)�kY��Ƒ D���C�l�0wI!��;B �Ub0���&��Y��\�Q*:YS)"%�=w�����ld��*�~6~J��@��
��<B¸{�ciM
x�'�dw563��� ,�9%9����1�3�]~�AG��g絓��K��y�>�zY1�� PF�}Ϝ��T��FD����6����OZ	�<���M��_���'�쓃�m�Ha��]��.��W��6<�8���/
��#���L��O<�vNa�=�L�iP�(��sλ���:�^��
84��{t��v< ����NV��yYL�
qpRn������ާ_�Op�^���WI�Z.�@��ܱ�VN'6�G��Za�Bl�i��¼���"�6���X�l�8���Q��:���	�$����p�x��#ip�K��WG���ln9�XBV�X�R�ݽ)�M$X����1�~�#����A:{1+o�z8m�n�t8�^>g�d���!&�[J�����,<���X��&��W�0{a�����@�y�Cw�֨lSܔ���8���mE�}ٿ���	Ψ5O�8g`Z<��ެ�l�.�:�w6e/~�;qVi�����&�|$�P=6���8"$��.(�)--�υ�e&�	�OX&���8y��8J��)����tzӨߣ���xTOuW/JG���5]���j3������K�����<��<�B��k�j�	�~l�;���-:P�l�,�p��8)荭o�rK��^(R+ڣ~Pa��p�����L����\}w��3	�[��E�a.	q�Щ���+YZd��*%�"8É�C!`�xďD������5m���xۘwNq3��jFH���{��4I�{i]�?���'�����f��$���.�%jfn =yK)k��(RDp�u��g2�YzV]�]��{��gL�dϒ���v�����u�w���HX��˱�+6�C|�/@,�'	�2詺	"fX�[��f=?:�9���q�Lp>��1���q|�H � L	��}�Xb�G��������A���x��k��,В$��)ۦ�zW�/�����?�q'
����2��͒�Z�͉�X���fN�݈��b>���`�t�`HEj�I`u��zoR�c�-��#{	�S_`��� Q4����)�#zu��,_��-*AI���H���9���oĸD/�]��`W��DF�k�Ug�g��NMQ�����rD�فˡ!��n���vF���-�ׇo.�v�m._�H0Cr�D��K��c�kݺA�W�c{#<g��Oy��/Pɕ~*6ٰ�f�5���K�2P]v	61p�`��V���F�_L���e��x�-r!�o6��@����3a=�G'z�2NDtps��ZNn�.��-�c�\���F,�,Cޝ������5�O}N�C~kڕaБA֖~wy�#��u���xuA�����3Ts�f/x�PI�5W=�¸8�9f���gk:[P^-&��۲��[8l:�a.(!V?S���`w&eL���Z��e��r>a�~��=c��#�48�k���*U��]J�)-���'U_f��M�Q��Ʃ�ؔ�]���y K�$_+g���0�/@�vY�c4Q�Y�v�B�� R�Y�$��� �w�A˨����k#wt�7(��9��g!�n��-�v��S�ݸ%��E�(v����aںO���`�$ kS��=�s{;R��_y��8��dd��=�%�nht�/�w	r����₝�bX,YKX���g�E�S�ݞ�%�G�q3YD�Y���p��ħ��=�شDr{"t���i?���!3�^�0�^�FN��cҒ(,l<]�g��t�L��⇥�g���*m�I�&�|;�A��U �|!����ݖ8x;�J�� t1/�m �)�%G�s����A����$2|�
?�:җK+���������MP�'m�(���*����if�]�n�Z�/s�hZ�J�SԸ`���[7*bܪlx�l��k�y��r�����^Q�8V��H�PFGo�V9=�����+C!�^$�A�58Y)���:˲��FS��ІA'��x��:#=_���癗��z��iܳL%E�8�E���#���$��W5@J�(u>��
�H{T+dOѴ���x���Zm��ݿ��3ӏ5�?%���=�.%�Ǯ^u�;!�o�.(?�`�rҬ�0���kzFA�~V�;h��$]<͗�a{D��b��T���t��)�D��#�nz��8�$I�m��mV���'�@:�tA�O+���R�����	T�ҧh(Ƿ��Wm��y�Wi솳VW��2�ƓhuvՓ�~�A9��|z�h�'�~�D���!W!4-�vv�R���2r^S�7��PO���5����R�!���O�Γ{:�> �/�@R�X��|>R���h�$��������,SF*6O���(���� �V�*WwZ�V�$'�g� ��x��`v.jNy�S5
�y��S���i��@M���[��]&�pNfM��j�4�TLD|�񡁫�������-�|�e^�W�X9H�m�����@\��Y�UQX���Բ�}�0 �T/=lu�侔#�)y � ������]*��)i��2��$�ff��!
�~8�*_f�c���tW`ʺ{i�s��FrMɩ~����:-��u�82y��~�k��}�b'ۍ�c���E�ϱT�M|�ySr��q[EY���Ft}	_ۅ@����)*gpU$��Gt�X>6)�WE'��b�"���Z:<��9e�VS~�$<��7Z�h�vƶ<n��~ ���:�5s�:keȗ3�C"���P���xl�Z��8s��Y`)E�v�Q�9����|��d�Q�-2�Ȼ�1�����pJ��U��Z��� �OQ=�zz��{�Bqbo�-�i����N����Ӯi��*��*��[����'o�@Y��:��*�&}t��٤Sj��&���]�
 &ρS�F� m& ���WK��d͋�A�!�Rw�6����S��ܗ�BP�zA�w3��U�U\~��Hޞ��E����S�}��ZI���@x��|s��Yu�AU�a�n�։�P����!����^>�{t���]���%$�~�_b�*��F�	){��T���Y�_�x�,�I��j1i)��xH��j��W�J� ���?�4����ϊ�#IlZN�:���O������S��A��� �F��r_j\�tV|ѐA�4��N�<Ed[�i/�DK
>z[ӧ8|c�0�vh �/YN�CS�R��}���jDqTn~��C����K���PN�G���ld�WK����O�L8�A�|�0��6�E�at&p��#��^�J��;G�B@�-vR;�u=n��W爀8�}�ݪ��?e�]�V���l�
q��� �x���$�YBx�4��LQ��������P��E�{0MI� _�CE�n4�9%8�cB�8#J�����\��`��!C�k.���p�̞r���r�ӓ�o��K���j��������M��͘���J�UN�2�5:d1N���M�Y�Q�0���D�#�ӈ?�^�n}`�L��]X)Z��-��Z4�����@�����)�SG׬��$P�l�|��3ʸ�{�����__���N�ts��K�rY7��Ił�$vAk�C���~��
�V<�S�����>7}YD�m�N�P����E�7^I?A݇������-H
�X�#��Ѵ@���1>��-�!���"�XFf��������f,f�n>:�,�e�U������%W턣�D��6Z�O�@���h6I�Ya�^�;�*1����.�� A���������rZ}{�I�J���������(ԋ�GV��p>��ec���o4�,��"#Ğ��_��jkꛩ5*�[s��� �NBW&N��3�KŶ�eK�q?n ��䗥�t��Wp7-m98��L�_Z�Q!x�hd���doʺcu���I}��g�0�W�L���Z�nST�vW�j�sq�w!t8�K P�C-����=�eA])�޲�ٯj���֨E`�dg������o��E��Į؛T>SkVKF����Pk�#��0P1�b��H����aJ���z�g$}�H�ԷyC�ST��es67O|���^j7��P�7���'�G-0P�'�S0b��W�J[��S�Z��qw�P���*�!��Z�Tp�%Ib<^"Ed��Y^���h�Q�;�*���dh/)�2���۫�?����U��
o��4� ]+�ujƦ߾f�S��u=��1j��Zt�=(���e�uOs��~�N�NP��O�+�g};͂�c=���<���0��"��rd.1u��G�ځ�C����r"<��^��F���MVQ\�d=c!�࿶L($_��<�3����L%�]�KY�C�t`/q�S�
�k�'�$���W�E�:z�g�?A�l��T��Ks�3J�,���-wĉ9�Q*N�ktE�B�.q<s�����r�N�"A���Hf��;�)���W�fZ*\�lx<��]X�@�1������J���ӸdL��@_�*vKc� A���#��u\���Sg_�	�|�.@ ��p�%x1�h!J��x��7;��\�����ƅޣ���L�r!}�kk�2�Ӓ�Q-;޼G�Ƒ�����lh3��A`	�wXZG��{6��N�ݢ=ܦ[�¤.pD��;�z����F����;xx��Gu���'t�ߟPl�+8�o�6���5~���Ғ ��\=5d)��鴕	tz8����ֳ��{י�MZ��lz[� �J ����!)N��&�dsn���Ŏ�3�j�J�\��%}X�[�Q�@8_���ɕ�q�xŴ��
:�P`P�+݃1�ư�I������_�,�vI?�MD��K�yh���Ŧ��uu���͑.EeR@���6��\^�r���9�����-HW_�]>cO�
��'S�0f�T����ÃHeH�u��z�ݖs��eiAY/:�VE��K�$���߫�-�ȧW��2��C2�+ި�]����[�M���<wMpVj������{��71�������sDd�IM�ɂb������t�a��(�]1���������w7?����ԅ�\������)�9�d.00i�1��������$V���٬�]�?k��|��/"Tl�I��ʃ-���')��!��ɬ��/���%͂�2=}��X��'&u[xV���^3��K��ҨK]7(�P��.����&hM	9zY�7��<`�ˀ9���;��{�׎O)�dXL�Ձ1=-�i\"�u$��'���ϟ��Wr$k���=�Xք�x�_��B|�h��Fgf��
X0�)|��*kU������v]��AB�$�o?O{x-�;�W��c3��y��03Va�9]#��a���:;�!�Lݺ^1r�Sg�)�u�~���T�{�xr��x}pֈ4m�����h�_U^}>J+�_�
6�������w���������� ��:>e�r#��dt�fo��� >VgN�PjR�NƷ=Ͳ�ڑJ��볥��)�B�[�P���jS���$��`~حޘ���_�kUd8��F�&:�ڸP'�P��h����T?� ��a��FV�U�Ì�˹iֳ������K���r*s�]�[���TX�6���U�u����'1P�W�I3hJH�]j������:����Ii�K@�� ;ѱ^j��	V��&�������X/�;�W�D�ɍlc���#��t�������tUn����C��跞�g�W���U��5�c�A�
p�8�J���B�Q�zɧ�d���9_�)"m�+|G�z$}��>�b�]3�n����G���3a�f�O�;�ǥ�rǿK�]��J�������,f�.��
0`�� �8�}`��fY�~�p�mZ�F�r@h�#&�D�HP�j��C��Q4bg@��iz!Lc
|@G鄰�i�����U�	�R��d��ۣ��tb��_ޥ_2��[�����jz�Z��'�9�LXW߫{�/����[�����n������5=�n6��hiOXF����h0����M���NN���f���_M����3ʇf4CJ�m���Jd��C9�͑�DHӐ�K_��xB~+�<�{ɶΫ�� ^�7��ʝ���4�R}�yc��F@$��z6��0�hU8�1�X�s���P�m�"����}�R����y�~ѣ,�\E�`��mxl�c�(Ù1K{Yq�7;=�j1��D#Ә���(m$���ϋ��P�����
ѳ�R��0��G�����d.>at.�֘�&L�+ɾmY�j}��me���!���r%�. �ʊ���PZ+Vf���U���u����.g�.���9��}�M�^4 �?�Yu0�A�tgT���ȎJ�W��_4�N�?m�BN?��O���:j#��g��;�a��Ʊ:�����?ȯ�Q�ʢ��p��<'Q(iv�)"�O�\�{К9&� �D��>h;���Z��xcChW��ߑ��V����-�����.E��{���|�e��q���2ՠT�S��
�v
����&?�`����Y����X`�B��@2)���: م셍Й�~���_}fL��@[�E^�g��g?�?;����gq�7َ��#�
�lG��w<��n<�ꕣ��xL~�lY6WBi�A�����F��^4BN�M�re�xM����5��r��[4�1]t[~~@2m#z�����Jh\��3~K���-�tz�a@�6�*�y�Ȉ�_���D_����R�Pd����2U�)\��t��C�wU�=���i�ߟ@g\�c���WG&�Fy_���Թ�,r���@���/��߲�ԃ{�8�]�ۊ ��?�����`x��쿘-ָ̈��6��w�ְ�cg�MD�	�z���z[�PoC�g#W忹<�#�Չ�#ĵ��6�O\��������O`_��7���0�Uq���}}ݡ�*���(^9!�}�N���zťs'�l��T��)����7�(Ǩ�X�m��F�"o*D��:a ��-����aU��Ô��W2�k�s-u'�W~��@�m��i^�m
N��&����]�4"y$0b��)W��?�}�U�ؽ[�1�PE&z�Ќi6+�;U'/p%�C]}�?:�n��`�:�af�T��/I�~����c-e&�x"I�pB�uVy�|�"+�pS��~{E�jw��tm����?=��hJ���y�b��	���6�\�[cN���U1��������:��^A	BE��e<�!��i��L4�����h����l��.г����A�_�_��`=b,��fa�a���γ��4^U����A�L��uCF����뗱�>D�P����ed�;S�O3l�	�O�����@J�'cq#�e=�=��@o��p�J�Fy�C�Ƈ����꾮Cq��)��ϑ��:��'�P`�Ǩ����:c���<���7��_]h�]#�}u5E�9O�31㫕z(/ � #X(�CJ�=-��H��+�%�Y$a�U{�ʀ�ɰ_����9㔣�G�����$�*U�f��0mb3c��B�?ıOb��j��f�A���Z�t1���@D��u$�����򡶯�al�5��Pٱ�����������AG\+�(��P����������-�����*��|&4j���dF֚g��U1�v'�����;t�UpnH�'ŹF�$��"�9������M��[,*�U@�Z�$yx;;M�Ȼ��QӋA�æ���ɔ��K�����P'���zB ��С��ٗyp#�����[���^���x1�g�2.���/��<�X��f�̌�p��=R^xQ_)O[���cW �l�~])B�s �,�N/�׳�A�8Z�t���:�PVQ�d��]���
�
� P�kڼ$B��#+�+�$�`ҁ���Rn�����y	r�8����w	��@̀ݧ���:��M�\k����/�ii���O�����D��S�p0mȨ��i�B��"���#5��%����k�M}��h�U?��(�I@��҆��h��ؽ�	C�������U�J�Ti)���?j���J3���b泗U�x�1��ȫ�,DR`�$O��ޛ��=˪������$��~�6�6�%�|�3�AX~ũF7�+�y�y�!�C��[əq �������!ih���O��è-ێؖ�RnEHB�.�W�a'Vs���O �7w[�Ϥ>����tl!B�������~K�VXꃔ ��3y��bv��+G[`󵌣ɽ9��qBUռN�R�E��"t�������)�n��9�z �#��-�O�A�Nf51�gG�~�8��� u���\�^�\#��V�q��>"�~���d�N|�J��׻%	�
��p�������y ݯxF�	X$�u����X��
K�AnWZЗ?�͡k;Êt�fΫ^��A���L��+����ʰ>���Ӳq�%���;#z.44~�t��$]���{.�08{�w,��U�{0���?��J�ExoI�I�QQ�b����F�מ����%*�՟�Z�=эn�О��t:�3�.�i�(�+��e�����(��k�;)���M7n�t)^8��$<̥]O3���
�8~�FZ�����Rݩ���G#�{g���� ���'�~>P�yQrH���"��_�b7�	0<�~�!P$���Ø��e���bD��;����w��n�JK} 0	�w�,�� &�-�MBD̥)���NP'CI:p���t/�?�G�c���2ܶ4J��M:DyO�i�1ذO�7K����� �.��ϐ�H�B&݁>�-�ye�}��v�e,����M��M?&�b��%2](�ꭔ�� �'�X�R��������<1L1�>��|V	����1����!f'V�����w]g�IqS��Z$��M�p?���h��z��s�gI���?y�x}J���?A���Kl�m�(���,�f~�5v��ԭ�n07B�#�7�"-S�E���LB�6�ɲ����^o��b�N�K�0Vÿb��^����Հ�L�6�� ��1��
M��j�����ݫ�v�R�?��}ـ�a?��nx�u�p�ų^�uL�0*ĭ�+'��;�"}�v���EQʙ�`�Wt��g�
}���J�7�@6d���5k���BW�����жAtk���:�0�-�+�|��:�x�I��;�L���F��� �;�5��r\V6��/+���q����U-#��91�t�8��蔆>�U��hf�0_	��Q59�X�"0wJM���GH��!�)H��j�X��S\xh0xT�:�钵�pt�hʻr�l���!=e�u�`u���Ūq{��B��-3)�2���O�q�平����\=v���a��쥕��k��i�A@�j��Y6z�	mD��Ad��kP����t���t�N'P�5 ��ے����A �N�C�Sf4j����_�RQ��oz�	`�@%}�A�B��Ȟ�\	���XFK��϶�8���锟�¿�ű��X�2%���*�x��^B�SV�8����J@���
/y!�� ފ�����HF��v����a��97N�\������B�YٚoϪ��7��tZ-̍o�C�{�0$�}P�1��u����&�M�"��s˙�q�P,���ݶN��Y�^5�\mT��;���7�B_"��L:�癨�����WlF�%[q�X�{9��o��_�f��qu��L��gd{�d�Iù��3��|�A����{ӵ���>����~�Sz�$I�� TB�y;=�Љ���w��A��a9W�nC�tؒ��sp�¢�E�Gz���"���a�ӹ��7ã��C��Ԙ���p񷠼�ŬarJ��qP�4��9����i�c�d���f�9?3w�)�+��K����ݳ,���[���.k%��0��Ʀ*���+�t�^�8�/L���_��~�<��q��ra���b� ���ʝxJ��Ѥ�xB6I(�h�jj >�ª\xR��}����X��a�w�V0��؍B��۶X����_\���4T�t�r�ٰ͍�x�,��F����q
87  �`C���a��ez�T|��3�l$.��T.��X�K���$���IȤJ9S�n�&��Xg�X2���iNfSB��Tlֿɠ1��,\�|�K���j'��x��qp6�n���N|x��BŤ%�_N�I������?�$��u�ў��	�"�B\.��e6˪_�����c�?�� ��g��:�̟�7ٟմ�=���Z�	�.K�FCf���3h���hR��r�̥�z�=��g9=����sF���e�<U�ԍ,�l�ٸ�g����dj�^��G���E�?U�܂��"�����X�Q(�q�Z������aU_B�PwR��͡��Fm�w�ZG��@�)��XZ��"��{8�vOY�}�a�j���[(��D�����ᝉb+s��K�hR�����{����뼳���m'�%�H���JJ'#��߁\� ��ҍ�f:*��|���A�6^�ʇ�����u�;����3��\����"����wy��0w2��IRp�{���4f�h��r�s�=)H$,"wm����Bw':�y8��d�B]��ڬ2Щ=��yJa�g/НٰW�$;���ۛ��Г(U<�ӝ[��p�&�D{o��N>�Y���~��Ƽ1E��	�7���=1�7�PN�J�~�$$��aS'wO2qg�-X���J]�4��ަ�3y�mE���g8�ok��i���@ģ�1��(�j��ql����D�BA��DX#r�V_q��➊L��9zj)7tSYL����j3�I�Lņ���m�(��a�Ӿ���� ��<y��!͓�]C����9�K�<ù A��	�,܎�(J��g�
h��6<�ࢁ��4���&�
�X#��k��=4�-`ؠ6�g���e+�]8�g��ވ&��`g�����
u�/����[��\�4H��mq�qlƪ��r ��>��N�T�����`>�әkp�?JW�o���+�D[Nf3D�c;QK�-ځ�	�Y�}P*�ؖ�֯�a4�6o�iA��}R��w�	� �f=g��j��{}+(����R�l(�'G��	�#����}����p��u sЛۗ]���Чc�;�IXm��J'I).1 ��l�n�~�6S[�g�b��Bw�-���3�o�[��OG-�YoevAZUq�H�t��??GWm��
�n��Xu�U/}�`��i!��c�$�C�t�&��3����Vf�8����������n�Х�+?=����~�m"=�Nj�@�Z���4AyM-P��-���4LB<:,#U�%�� @N�n�(�M
����}��^`�9����� ����u�6ZT�mAn� I폡%�Ss��l�XI�Σ-ps����*�������6E���3)��UIb��C[0�2��xh�O���r���sw����:7J��h?�&��ha#GG<G-���	G�`JqS���x���R �ŝ�7�^8��<=�����Y�������׏DD��$_X����Ά?�2d$Z�=�Ƣ�cVd/��Ei�TFS�pH���֮�}���i�d��w'U�����+�db��*v��|m$�V���l�;�OT�7��K~�������Ǽâa
8�rQlߜhb�������'&��Ͻ=]�*�*��}���!������4��EH�=DI ��0�PV��K�%�<^	ٯ3�@6��`zp���+@a����NLu��C����<F�G�l%L�	�g���2�?waZ�b"��1�0�X�S�,E*s�
ҳ�p����@�'�8v�`��vG��s��iK'n&NY�ұ�f���>��1{0�C%3�}Xp�e1hN���a�3���ξ$�i�#�|�W�F\��#�{��G,"<�~73%xl�~�p�S��tB�V��(�1a&��9�g�Y�.�����t���zpn�I�_}����St�t��\E�K,�g���?!�S�b�[E�����6�j�M�vA�}rb�`��>�?[��W�������'2-��#��TTS��T4m�=�����\�|�u�p^��^W���'���┎}#󿹇JEq�v�`H��֯yߏ��*�6_(���D�-i�>p
���L� �T��{��U!frJ��9AƉ����������h�_3��zGc⫠�L���$j螢ZX� ��0�h���1 ���mb��c2�h��QO���$�T\�>�5%,�5M2lM5�7��F8���$�v7��W�童i95��H�pIF�lE'��NU~�"H� �ƿic�N��pKf�_Wn{�v, �&b�E���R$�A��J�hR�S]iM�B�UM@mo��&���lEֻ�Sa֣hө�,��J�A���P��BL�eHѠ��rG>�_J������lgX��R���R�JxX��`0W���^m�^����9��4��t\;��:-hJ.p�ͫR3xת�,!u}�<���!��P�E�0�-��S�w~I\ ��ru�s3wǔX+�U�\#��O,���s���X8�\��+����Ā���}�
ZClFr��Y�	���u<ߒ�5� �$�jeP��j[�f`+l��wA��h
n�?F<�L_���e-H�Gt`��z��*���/;Z0�)�ǆ��U�3���EZ4Q�Əq�d@��Y��3<]ou�}�0��Gȴ�Z����"Z� ZG9�����?�3<��WCy��2����5�3n�L�����a �"�-M�Z�&N��iq�uO�vx���IW�Z^^D�^��_O�3�lT��	�xسl�/�"$��I�խ�w�H)�b�/�?�G�����׶Ĺ����C����������ݩ���ki�$�y�;�]�NȊ=��~�o&O!	���-p �~��yu����q�_��{��������Jl&�z�}b�
�����E�y,���;��J�6���避Cj�{e#��K���B�YU47#L#^�PQ����T�=�$F���:+���K"xR=��?�xܧ�{	���w�p���cX�=�T"��:�s����u�C��b��;]�L B[I���1qUxSd��h�G5 >��=��<[�W�)�KW%�(�a�����Ϗ+�΀�kDP���!�o$ïL����O9�4��7���]��>Ĳ5��)f�Z��,�㻳�ᯂh$���x�h]�b]���. ����A�HK4�x�i�M^/���س��CL�<���������Sa�"����˦�L�oB���s����NQ8Tr7�#X!<^�eq:mr?���xN4�w����>��;.��g����kK��[l�9<M��*�$A:�@���y�H�n7"�5zK+iV����j_�%�S��s�f$Oi�5m����mH��(����{1��Q��8 m�.�әz"I��|G�m53�S�]�h�������8؋����8�Sȧ�T˦�Ig�( �F2�>����;(# �rn0�?��Va缎�vx�q�{��(1r�	|�m��Y����P5J���'iϗJnnɡ��z�1oi��y���7���'f׆�7=ba���,�j�~W�'��p�O��s/������{�x3��v���R'��ש��	�c�$@,&EB��J�J �Ԃ��������1.�c�.�]+腖ת�����雦0B��Zqq^P1�@[��	����3U��7�*�|�j����y���z���M����+�վ�P���[�Sk�A�n?�|�Q|�N������ꊭɦ�~O^�-����@= ґ���@�"CH�J�ds��`�,�tb�0.�q���������vQ֑HZG�%��`�,i,�'H�������֭�I]m^�w��>Q��Z�+�.M�O��'�7Ό%2=k�fE�/�q�a�TW�j�`)��	%5{Wo�*h��'Haw^ �
]6S�{ -�{���M�w#�wi�Ѡĸ:/@�W����^0���d���x��c�}k5<�Ic�����}an�k!$��㾏$��3~���
�[�7k�hܓ���>Qp(ީKy��0�q+��G��a�f��ؑ��6~�}�A��`9��S���U��E홋�@��4�&���|�}��>[��g���D�T�4��F��E�^=Sj�~t,���fB�ɒke��ՙ]�KE}%dWP�W-$'�%h�{�Q%���P����nSr3��t����Vx%,��I�d������q���;OI������"��8]V�+�|��^ۇ������C���̙m����A�?�D�ZE�0]�t�X�I�?��I�[�ʕ&������a���`��!�4��s����z����}�i�C5Ag��:/�(6Ͱ�Ʌ�}F j�w���+~��>qD��"��2fiG����PQ�=��U�WI[�6�0�3���W��j�e,���G�4o�L��8y�-5p?�|��mb�ДSeĜU˥�I8H��j�ql0�Zb��"�B�R��.w���0ŏ�}n�d4|&]���^���T�^��̍�R��Ű�αRV��:�D��޿�2'�k��0s�7�RyW�Q��]b��@����PV���t�X��Qp�a��D%/p�PJ�^��/d���(4���ׇ�EqP�XPb=�WMK�N7�Q<+���-�]nV�m�%=�^��Y��p�TR�j9�R;�N4�<ğP�&P�О}Ǿ�d��y���h}Aɦ&��|�AW�s���ݺ5�5��3"Q܎��Owy�'K����*���kC�}�󦷓Z�k��f�0H���c�u�|�e�Sy�(�Ŧ���^ŕ�C�/L�db�q���t�߷Qt�Z�����Y�[�������A�mi�@�Z������21=�n`�����'�ȉ3'��k;)�%wR.�6WL�u���)%�9F;{� ����kJ��g�@T���?�<���h xd@���T����h�	?�x�rt2�<'�#��ΐ�(酶�Y?� w� �Q���F�+�N��ge�,�_���e0�/�!*����K�v�z�D���#S��d�t���s�+ܨ�v�>i��T����hWt-��¡TU��Ѭ(��:]�o\T~_�/YX!π@$Z�6j���O�}wbG0�O��z�X�E��mk��{7��D�b�D�z�q�{��2�A@��x�����%cY�MEa�gߺ#_�'Do�� QgO({���X�zS̖���z�I�(�b�V��[��A�G�V��UR΍C
�Z�y��%��[�O}���Zn�O�ݕ?s�,�����Ё�%��ׯyf�{��!+�j*��M�Kh3�9�+�����茑k'�J1b���Tk�Vħ��X�4h�Ky�A���J���MQG�c�(7r�nF��$"���@��[b��3R���8��.������W�"�t���ڳC��O?���@W��!+�By�5��w�*P�&p�z  ٠c��Q�^ ����0�[��g�    YZ