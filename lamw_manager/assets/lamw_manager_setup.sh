#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="128861844"
MD5="b60a50d8a005ad77417f256538241dc7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25908"
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
	echo Date of packaging: Thu Feb 10 16:34:35 -03 2022
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
�7zXZ  �ִF !   �X���d�] �}��1Dd]����P�t�D��f*�N������d�7��F)d��}�>�����(����%8�% r��<xo|z�̭N.�bu	����K&�Z�J*0�2��:��_�n��mĔ@ 1�>���Ek<l8
�bS����`��z�	� ��/>��f�&�����'{�Cq�� _��[g:&+�*+P*���O4H�'$���1����-~�O�y�ŵZ�y�
3"ϔ��	s��}f��]��G�N@���ys��8*�t�᱁��ٱ6�����I����ڼV�Q��|\�Y3�|�d�Ե�.��tDި]q�+�ĕ�����fT#A��g
����gE�o�����E��5pC��kR�U� �2|NS��5M�L'�ŀ�T#�nG��r��a-�E�Nk[VYX�o��v�9�(�G[����h���cA�m�����-���r��4�kpDi2,�墖c�B����;/.D����7�uy� �-��T�Ȓ��0z0�&?��۝��b��_��(g:�_���1H�)���T�~C�D6�UWW@�����-��������N����M����lRs�â��A�����iz�~�L,���Y��R��%��/��a^Pyt�x�xX���6O�Sn�������k��6��*τ��'���-���\	�e�ֹ�A���L[am	;�1�Q���;_�����ݤ�����ZRIͣ���N5�wƆ�?���gh���������>�4��	`�<����fi>I���e[�]��A���q">�eQ�Le`�0X /���z:�D@c,c�]�ù24�+�%B�N�����tH�h���� ^���̀���FY> �F���R'�X��Q7��@��EV�
�S'�m�إ%���p8��[/�X˷��udk�l�FE�ӣ��r�Èd��D�A���7�C����'@� �� {#�m�됣C�{��I'7�mR��Ȍ�A�&^�`z���
d�_|���b3��q��()K��ec��d�$k��۾�씹��?J&n2�y8b-�p�~���S�[��Fk&
�B͌��������?�ˡ �Y���� �ңU�k+m�6z?��>�2<��b�So?CT����ԯi�á��q/�!in��C⦸/=,���v�ؼg��lr"m����	.��$o�����!�I�,TZ�U�E��sR&�莌c�S�H~�-�X�zc�u�0��d�1ı�ˍN�Ssw� Nn�9+��'y�Ij�^��_e��r�1��ylqX��L]qY�uV�i�O2=�Ё��C~tذ�]jx�-Y;�y�����1x~Q�@�?#����#i��>�¨!,ETv�J���
b)�3�W�b✦�� I1z���c�Pڪ$h-�?�א-��eGZԈ��n�Ϣ��f���
�uX���V�s����ߣ�>�.�Fb��WO�W?*�+h.o���SІ�j��t#ʋ�b�1! �]�##�Ț6I�����V��m����ܪ5�­�rɕ�k��{���kOn����	��&�!����=�0w�����vy?���	8f����$E$�/Z�bߛjW�P������I�� :ܶ,�&?y����YR�Z�3�����v3��"�V���g�J��ng�l���c)�r$J*Ө�kR���?�]@r�`�M��f! F�~�[�O9���a7��b��̯��o�����_����,�y B)�I�/w[�,F��u�+8N�0] ���s���)Х����Gg^F:�� �& �-"�`�^�� �x�߂v,�r?�|Ź�����,��(���QY���
sH$2���yj��Id;��A���2�]\��k�c�^��O���Fz�����ZM�e_�R�ju�h���M�Ѡ�a�Y1D�U�g�^�s%�Q9L���[�D�$_�s�1q�Ϳ����L߭�����ȥ8��*$T+D��*O#1v|<DFB�-9#hc�4v|��X�+J%ҶD�������'-\��#aI,�"_ �r����d�XC��'Ċaؓ]�Xp{79/�+o���(I̱�@�	YS�mŚ5U,�£�K �sj�ZO1U��V����L���	��ȁ��p�xVU���H���C#W��&�a����D=��;Q�/���v�� �6���x-����4�B�i���l��*G��3����;�!,|x>:�@d�w2���p[��29�Jf/Q:�ёŀe��T~��p�0"��k�Ⱥz.^��}]��b֑6Y����a�^��r`z�8�2י�����Βl��S5��eo���g�0F��XY�)6��~�!���L������ΘF���Dw�9�$;��O÷kd��Y���jPL�ʬ�J��q���OsIs�1�jC	�E��?�☂��0ϲ�:��J�l� �?!��>]��<��b��ͥ� �x�]>�˸-[!^^;%Z���.Ý��1� �{���A����C�	�\���������(�ܚH���ц ��^��C��h������XbtO8��rNϧko�A8���AA։b�q���Z�y��<��
�������t2*l�/.<�;�*��F)	����Bv��z�˲����_Q5܌����P+Y�U��.@(��"�+�:6�H���fgrg��r?��)A��my���7��$q����vWn������fL&hD�;C������R��a�V����u<�4Y���,b�js�$.^��m�(:J-�s��-&������8��9�[��5/w�x��CFcW�
��Rr��;WO4�^[��d�0 �KF��xF����z@�2yI!�˰����*�#���a�}�w[	�7�(_�ږ��_y\�C�COID�з���7�#�D�hsI��RuҴu�E�r��t���~��K<k�������|XM?��/R�kL�_�����q!p�ϡɹXD�rK�y���-I�w��?+��ߩlB��=th���V���yF���w���� �O�C��RD�O�k�}+���y�����/�53��*��t]�Z��vP�?廅h�u��!6%FM��2���+7��A� �*�
�nt�[�G-I�R��B�߃ZK�Т�R���.e&��D��b[�#��O�=�Z���dR��
�QGS����l�/%��Wh����sN��
u�aYL*�������~���3!�_A*C�P��&0xS#��y��
�yd�����]�Z�9���W��i�n�M2<Q��\[�׏���^��������r��Q��;Ss]�1?ְl�,�Cw�$����t���٪�i�_�������^A;5�fc��h��-��z���:�Q*5���R�5,v�>�_h=�+���x�ZD��u�mp�]_T���%F��\W3����X�]�E�K��OߊTvAbP�3�E�	�d��^�INu��&�E��J�2�>;}�D�~ڒUs�cdcǝ?��G$K����=uOIy�H���|¼�pvٖ"��H�2�Q�忳��ք ��F�Z�����&����@zÔ�+�=��~���#[}!�-�!� ke��N��MJ�2�2Y�r��6L�����~�u�?ɩ�%�up�7���ڹ��_}��_�rX+Up2B~X��	���0��D���C%�ZdJ�#M.98mF��0����=�2 ���l�K�7���!����ԇ}6���w���(��ڃ�u�2�ddh�wY߿u6��P��Kɫ�l ��k���LRӄ �jT�"����\b��"�]��6�6z���L�.�F�_@
>�k�:!uv��`��/.<�3΂�J��x�@^ߙh��>">)m��8F�;�����F���>)c�ls?���_�w��lko����n���h3�y��߽@����tY���2}���)�L����kDy6o#6>��f�2��)��c��
4t_����޺�T{�v�=��Pϥ4F%�6�񟣟��(u����ٰ�9��<6��7E�#���mя_��	���	l�S�3f�ǵO&<�+g�q����~$��B����ߘ#1��'�YV�Y��T��A`����q?����p8�Ĵ�iv�`I���P�!s֏39Y�I�p�ٸm���H�� Py!������z�0�;{\GG���w`���;ʟ�w4��~:��0��LE}|	R��k�zs� e���*��er���K�/�cw�
ǥ��$�6���.�v'}���S62V?i��ú��Y�r��ʓ�4$A`{���7��,_��K������2��ܢ��؈
.��t�}B]+����*��݌*�TiԨ�48�>.�%'��9��F�t�kc��_W�5��^���{E�PZ�kN�7�2C�^Ϲ�y�r�JJZ��Yg݊�U�1���#��Tx����Ό	gS����fc��a�s�`,⽳}�A��73��:�)���S
��,B~@��=^�2ee4=�x�n<��n�#Ǒx�@�Q����gy����Y{-[Nmx�v�ؽ3�iuf����|s|d�X��[I�W�<�����G��cp^�slzp��>̬��k	�{����%����\��zg,eߧ0��Tl�ӥM�"���n>�����2wR��1W�s�$߅�كz���:=�s�'�sP��
Ȯ��L����/6��sB��Fn'}�W���F���FBA})G�̭��K^O��ӒP�dӼw<����������m��Ə�Q��4���GO_��t���C"�][QXNm
[_?c2Ql�*-���	>W1�Z)=�{:�:�ZtW�.�UV��Vp��N&ʰ*?t3�t��۷GO���O��~B=%�J����5N��i���L�v�SUή��;h�B���]�O��W� ɨ���1�ّ�(Fʤ��+�}}]��9�>x�����(�^���hDA��cN�`���Ր	+I(f �$T�d�܎u��=>�$����lbq�Cq���$0ϟ��xC������^I�-"��B[�Gs�A��v)�.eOZN&�ŞGP�9F� ��26>8_VS�7��a˱��bq������@
&J�;;qV�PzYhQ����T�P���=��?����ˡHʛn@�2��4(KU�����S���7��i����,�F	ec��АTܡ�ˮ��dwLM\�SF��Ȋ��e�(_�:��X�2�4C����A�ʛ �MJ�y"Z�g�Ѫh�G�l*�e��(�(M	��D ��#����
42�^P+��'F?4;���P��ú����ܪ�C{R�7!eb�J�oդ48D�3�,��MfHx��=�VM����-$7=�r|�5�ƽ�=ў�҅L�IL��1�W�3��GU�_��|�U0,h���!����vp	���S-�V�c�ذB!PYdDt�O�$�z�W��E���P<	���qQ^��5K�8J�H�;��,x���s��;i�cl��
 �y� ������obO݅\	=��_�xY�D	������A�n}�<	=|8��>I�M�ݪ�h����{��OVŸ��	#�w�ɒGP@;�A�I����ݪe�	��r�T׊=����tk�F#?鲫��H`&��D�K>���������Tγ�?<Rw�5�'�O�����~k�d��ū�ޘ F �/�?5<�o�}E)�������� �Q2j�O���`��読{8�9����of���=J��<�Y���%��d
Hv�tWn�ݧP�:6=T,�cS�h�z�ɹ:���C{b,?��Q�h,��ϴ�^���T�!��+�� ht�PS�p&%�&��oG���2Qq�3۰I�E�YS����;iL�cȽ���l�����X�eד���+%�!stu:�R&��h��C�1���W s����d�ad�|f�#�)��q�3N�.�|">7c��h�!t��ۆ�G���zx&�ߙ���^�B�í	a�r�׾��3�<��2 �P�W�m�Y���L�-o�����F����?< :�W*de��mՉ�j:��=x��N0�ǶmI�{���#g[F�K0R�'ԥ3q7�y����m�:�R��b=杉�)V���vH{Ld�G#��s֝I/`�lW�%��Rԁޫ]6m�F���4��y�e;�bm֖�)$-�o�=�8�� u���%�i�����c�<<���x���aW��O���Y�+V]��'�"1���c�� �4\� ��T!�]���6�V^�E�=�F���d�3��κ�"�Y�!.0Xp�ڛ�WQfiPf�S�k@{c'����s����]�2]�ך�E���������W�YM�'�c�ϖ#�8���������"vv���}49|\��!6�U�V'����#�ֿ�\ξ����B؏&�*�O������7����k�ӽ�Ƣ$�C�u�1e�`�A�H�t������'���a�]jc��?�%�6? >�K�q���l��Y�R�|4(j��3�q8
]��[��г1�����*Y3���TʁN�2�1��G�C1� ���Z��ֶ� @sDx�jd�'�2;�U�_���_��<��BJ`d
u��!���1I�N����;�C>^O�D-m&�R)�R32%�U��؀�L֞c��r����r�;z�x�=��qk�dL�����7U�~�������
F��x2'�e"MxJ�O�8�-��A��hNa1�mg	�����~{�:��D�Y}�����E
��%Q"%������e�O:'�}C��Ҙ�!>-o�ڢ_P<>+���y��/L^�]!I�4CrD�PksW� ���C�-��!��Ƴ� @��,i/�^�ߢ�)�\�w���S�Yn�U��  �*c͑�a�ʀ��i�ʉ2�E����L|tʼ�)�2�"qx)=���F��ɉ�5-����פ�r���FbH��$`'���;xXe&������b�r~W)�-�!�>A +�l��5������Qs���i-D����m2 ��jP]�U`�g�c�|��"�q��7���uv.����G�}#C�1&���٧X��۹��\`|�Z`�p�[��E�i��'�q,^���ޥ����������2�����������pR�f:-��Q��Q�5�@�cH�7ȻN�m���D��5H������`��������%>Qf��EP�wj��aGs��g�����Ebj��r7i�AN�G��x�v��S���/�̀�-�Ȥ�T`S�˙�qd���K��������uu �{l�eT9'�a��%$������Z�������M� �-�:b�֐U��h�f��|H?��!(a�|�R��YH6'�؎�b�LFϧd�)�ڛc�;��c���yD{�: s��a �di�A9(b�A�o�3�)(��ߥ܆��R	u=�(/h-�*���!�۴�_��Ď�0���نQ�]RB�U���rjKJޜĲ�z�#�mt��^�ʲ��ar�7~�I���sE�+��(|M)M���QB��D@ъ��j�7K �6t�}o��G.d���_�7�m�34����z�h�����t�w|cʡ��#k�q�V��e�r�
K0�P��%��5^~��d��"���ݧn7�9�~����5 ���HX����s�4ex�,*D���gĹ]!�t�M�"�e�T{X?l�_��o"|߷�U�s���CR�C(�>��5y8��s��_5�o�E�� �%����o��Oa�����;if�h��
 �]��{}}ph�8�^�ES���@==��x�?zH^�1D.8V��t�鷛(F�bԾ2��Fc#<����&�[�[��u�ĭ
�[�j�ܡƔ��8��b����������i����=�$=_93��\�H�d�|6i�zȔ�@�E��cH&������/� �$OfA�aq>�V� s2�1���dcw;dA��������@��j���1�|٤R��,ZF�Ax�,�m��y�"0���r\���|h��������Tr2���b!+�5�+8Q��n;u��s����̘�=Ǧ�\�Q��ٗZ�;��XyS�\ĲS8��IżX������i��3G���c���+mdbB��#n4r�&I���` Y
@��g;"���Lv��'�Rыe|#(<kܩ�+�N����[U������	PSߕ7�=p�&��.�-�s�.�rw�F� �f2-r�Rk�?��g��r�~��k��0d\��C\��'�h�2�P��Z���
�,9^y�KM:�y�	��l��&�*1�� �Л���a9��� �~��?�GH*l�5'C�-��g��pR��o��r,|K�������D�SY��ʥ"�o�NN���V�u~��&&U�x�V�0ˎc�p	��b�s�#���++J�ڲ�M����hR��uw�l�S�wm?���痿�����ۜ�ϸ��g�B̀z����O3"mq����=�m�<�2�����gqyN�`���m'�<C��,�ئgB���|��]�< ���M݆���y�'m�����xR!՜�-�	��J*�)7��}��'�Cވ,��i}�M�-�|ܐ.�r�%y5n:��sPQzDa�f�"f���?��̓|i��t����R�>m�\B�.��P�]#,�M��ߏ�y�	�mV'�+߹�jw_O P6T�ɣ���ݖ��|?�}�������,

�X^��=^j[cc�y�E����K���O��&�����:>�]�Kn��b�����ia�_X=�P��q{�C��`���0e�~Z���ӗ/)���gi��?�.!����`�(y�^����'��k�`6�ϫ�8�5�:G�Kk�'&��qg�Z�",uk��y�!�w���$w��#^(�~@�O�(d�f*��XM�}��������1Ƽ���qő��Dxn���% Ղ�r1����̧��g�b��e�1n���r8R�����قwH�:�U��3�ъ*���?��/jZ}i|A�$>��\�}���"Bړ/C/���vC�0c&�&�`���RWGm6�I�d) ^�Bp��	�wo�1Eb���c_PJ:����M��V��82Ϳ����f�5c���{/����D���ᓰ��M��jM-����3�h�f"�G��CI�Ȳ>�q���.t�􋰢IJJ/���-Qo٫�t�tǩ���Āv�T*�fM���@eX���'�2ax믖1n�v��ą~3Ǯ�S�<��@�p1������1^+����	큍�SY�i�0��s������&���:�g�y�,���.⸌�4�E�M67�v�X`�W�����Ln��yVu/��m����K��!L9���"�b��
�_���a'��NI�����Mgv�*
������ۚ��4����'-�$h�U���b���B�w����NN��B��q��qi�-s!g,��Xkژ�-?�}G�q|�ch��j��rv2���6 �����7�9��S���3<l>L}<���I�l8�Uc��&i�N��O���rpC��6�.%ų���?���o�:BQ�#H����Bu�K�)|���F�EV�2Yd�a���sc�3�@B;[�"�R7��١�'�����Pbf�y�C��`}��� �k���H �,bB�5���6l�W�(0��!ᣋʾ�
CS��dmS\�N�z^v�����u�V�c#�c��d%PtĶ��s��Ǉ/7g�D�(n����Krת���ŵ���I��#XWo-�Zf�?��R`1f�Dm?dh�L'�A���Ɗj��3�|�j%�@��s�(���$E6�H�N1>�U&���d�"
I�Y�[�D�C�Pc*&*[i������z�"�a=
o	�g����vsc6����r�'���r��Q]i9�3|p�D����vrOX��"��,����P�C(��!�٘����`<���v��H������#i*,+�#b�a(�<�6���\p����X�v$a�i��!������Hy�a�WK`��T��eltW�#Ѝ��q�*1��s�X�ۢԃB59�RT;���h��NUa��i�=8}�h�$Z�p׏�o�l���z�xE1g�t��C}�̚��/����m�G5�ńƥ�)ձ�I}�>!8U$��H����D���@w�~���e}�.��y�����sc��yy�p"���AK����X�xS?#KTM0/��.�4��ɲ�##�2D���SR�����^�>,!�E�f9����V6� �?����'���C}��O���coc�'�-�^g\�C[��_Sq܂�Qn�Ջ�+3��.Ypƥ�JΤ��=j�V������N���݇5�ߖ-����k0TR�L�_:- T 
�Y�T�$� {�*����t*Eyb�� ��q�����L�h)�ts�}�ƻ�;|^��`��f�
���?KؽQ?��I�P���C!�z��D�67����u�0z��C4�G!$H
�(�U��� ^�ɶ�+.�Rj�&9��L`MⱫb��#`V�TW���(�c�`wmE9+Ϙ�D|�I�L-P�Ԍ�u�J{o�:��@��@��o& 3D�������$��$��w麧qgzc�>�]�aI{�5)�d2s#��߷���`�����)/��p2���oC�ˑ�0`Ԗ �Bp��TKD��� ��8[G�K�<v��F'2�L�T��!��e�OwN(8կ�o�@�I*���"����bcg�؝8���m)�o�	|��l�iry�~w����Q{�#��c��y~�8�ҜXpB�,�e�<�7諹	��w,�Ʒ�aXަ1����C�^K-灪L�)j��co�=���dY��(���P'��o��e5�^^{�k���}|�����	�¼�&�q{�=Gh�����
H~8�~���c�esl���Z�s=�&���zk2gZ�P�xĄD�c��Lr��x�PT�~b���Go�^�jgA��A�-�6��	�f2%�����4�d�ׄ����1��P�|(����R�8����C�䶎()8��x65-��N1��J?�r?�,D�c��Îjs<Ǟ��7����]4�o?���\�S���;5p�z�S
#T'��V<)zM���Zغ�
s�9(ts����FM�.S���#h��1���NlR���l&bh��D�R���))6B�B_ ̶����s��ڬh!Z���Hj�
��f��;�ѕb�����n�}b�w��p�"��Sl��^ы���H�>=��Ć����Ҝ#ߏq����>����+"V6�l�L�Xt�Q1Ec�I��Uð���v���>�ն�2~!�2��6�\�ך|L��>)�Sk��9�;u�$M��Lhe�ǖ��s���V�	`1�� �Eh�E������Pi8��m���+�x߉��r�.�jL��������"�j�nCV4�'�����=��.+������1MJu��P8��%ˁ���~(���J"��K�Y(��D��]���N��#�4�
ޥ���zG)N�����FB��
�K�,p
�@�Nޚ�tD��W8���W�K�ܼ��q�]m)�$�`�!�L�s��@{c�"e��`q��=�F���"~�k~i��q�v�o"�ҙ�0=�=�/�	n�d>���\�E����VUy�UR�="�,��>y�к%_�\b+��{���#�����W���h���i�B�"+��Z��\(�~�D��0s��1��h=l~�'N:۽�E9�S5|hjq&���U��.Q1���g��
9u>���4��z}<�q�t�@�L�[埆�tWP��%3%h+F�f�Ĥ��Q���c��}Q����yk�]��4�)�����0$(Y��2O�KB��;0�Ph"��+�
�7 XVT(�FAE+QZA>b��8�utE�Iz���Ե�N�!�'���,��aV<z	`@`<#!�0�B�~��4����bƣ(v��j�ضw����M"p|Rd�#}�]����ұ�CԳ�g]�9j����5�RM�2HɅ-+[Uﯙ�c�P�'� m�N`$c3ؔ,Rj�84}�L �{KH��m� �;���N��v\J�T��8���M-%���4�"n�7��K��ơ{]��b�4��D৷3c��?�|���R���Ŧ�o��vy��� B#h����^��W��v�_�±����U~j�����ɼ�#�Qd�/�]OvXo?J��U��u)r!-4!,�m����i�\�К�b��l��0/��k�(穽��|��o(l�\\�V>��p�f��l����t�_�_~�f�n�T�j5`mceش.�-�i�d��R�n��F���jd��n�#&�e�	^���;�C3풊ef�_"J�Ė�uJ���,����fs2�N���2[�H����Rң�C?� �D�d���pr-L���m������+�Z�h�Z��4�q��fTb{%<���'�0&?c  �'���4�ic�<�_�F*8mV'����ð�[u������s02����L���������G~��Xp�,´�^��d��8*��_��èd� ��HP��K�����?9�u^�!�]�=�}�RX�$,0wJ+[A���Qde�M����� �;)�$����⮌H���7��ƺ��9ׅ�E��́XT��ϳ�{��5�7���'DO�8Fjk�ѹ΄�UϽ���,&�[焪�h\'�����M�
zg.r]�b�`^�9k΍ԮR��ѱC4_a�,ΤJ�S�_�і��*\(��evS�C�:�c���,n7����2�;�j7a�H����a����ڔ�˴I
�FCO�����D�<�H�6�-����K�/r�p���N���n���$Q� �S��s�3iȚD��Ț�OH��(B�qhV�8x,���m_��	�)�yh�fltG
ɨ.�N�����i�o�,�՘��[K�����ni#`��ii��&�穴#[s�Ȑ:���?�DJkWH6a:`�l�l���#��g�`~�d���G3�W�B��b��%qI�&CaR�ވ�I�g	�M��jЍq�W�(��ɹ�I�F����&sv������T���@�P���Y@c�[(�]Ƣ��+�^�1M�	~~���c�� B�-�%�(
͍�U��3�W��Пe���������At5h\T�n/%6�/�5EN�����KZ�j��y�A^:yO���"T���X�|�n�Y�����>�T�OW����Aa<,�� �����{�'x�5�T�x'�����t���h��")ͫ�ݜ��#=s �ꈊ���sK�S�L��JE1�']1�����<�6��ޮ8Z���ekف�M����^�cG��l}�R����U?�Erf2U$�����7	�|����(q�4�ь���I	��'x
Rk���Y
���A��OI���� l0�����|umB6Z�wJ3���kN�}ZU�f�'d�ޢ�l���6\*v���������n��JnprD�����-��q9����:��r��v���Ӊ�/q�b��$�x^�Q?:�2��%z�sp��dݞЀ]���܁���1��(Q�7�sA����ʬU��V
���qy�-#�ڧJEC�%�O��[���s��Pˮ���Y��������ӭh+̹/~A6�@�ٞ5��iA���"g�N��m���8����W�s=W��8�)~����0�Z�EN�s>֝�&��(��W�&��b�袀z�:�pc)u�:� �&�L�v�ʑ?�r]ܲ ���^k
%C�< a4�Ä߇9;�&���Z�nyʶ��F��TD�����LH��;"���+��/⁽!��S������Yˆ���fk��rcS�)p��3d}>m���4�U� �`�g��	���f[���I !=Z,/J�fC(Y^��L��f/�ճl�3�<G�_z};	y��<�@�C6I��n�^��;���L�z����X�Ŕ�dvl�Y�U���p��\f�.�P�ۉl�e����P�]"C�tk���s��E��㽞�ˏ����M�^7��M��q�5}2$8�E�<�����Y�u�]�����ϒ�δDp�UY攪j�n���
XDh��/RC�7���/9�s��+zc�Ƞ[K�`8e���a`"ybf�Ǫ�5���� |�Bn>�f#UqR�dx#�(2ԇ��A4�Ҭ	.��D%Ύ@��q�$Sp,l�pP���J��'��^�|��؁X&v*K"y�o�ˡ�t���{�Pj��Te�#W#w*�6�裂p�W���(�	.����ͩ��hZ�x� �(��㊍��hgQY:~t�ND�x$��u����X2X��%m�&��ſ��oo�S�*s�g���)��F~�q�$�[��,Ǭ���Tr��;Q�1��p	#,���J9�2BU�
��1�"�j��9ײG�z��築�փD�lL�k��O�-���Gn��8��ioїP"+3��v�v��RD�,Q�I(�y��_��cؾ�v�K)�ҶV�W�|��ʭ�C����4�6�}m����`���$�K�O��3�ז�2����
� �Ӹ�@�]A��_Ģ@bLCP� �pWi�~�t��W��|Y��f�܅)��PRf\$�].�j�^�F$��V\y��kW*�m�HuZ�+$~r���߻��}�:�+���p�벉ḷq'�b�-��u���3���~�prXK��m�U�����^�E+3�����6=|r4N��1�j@e��G5]O��[0!���5�r��������[t�T�ֶ�fӜ,;J��W[t��kl9��o`��gH�JZ�"h=�敯u���64�@^L̶����o���"�X�N'�)����`�N�j���#��XR�ϳ�<�%|����#UA�h>~1�/�bQA�J�|L�K��J��ieu�:�	�3�;ـ�X.�}���ڋ]8�k@Q�'�ć�X���]�{�����js�cΝD@؊%?���9�$ȵ	G�৐�J��YS2����lW���6
�}�bm~���Vz�|�����삹�܎� oQ>x{%��)���#�C4�\D="�>Ø?�����{�Ae���Y������_&1��D_�s���&D�|�ǖ\��+��.4`�E����,�;f�)`V�	vėI����߸E6�,~#�����%���oN��S���x8̓�iC��X����"��̶5֪S")8����H�ԙcb<a{��G�O�i��A��
�ȨVD�Z��V����唑���Lwl���$��-ܥ���/�h�dߚ��'�\�.��Dw�M4o赍��K��W��E��V�F���Kʇ�@���sG�m�\��bz�]��l-'����D����9.���z}wl-d�Pq�a1Ӱ5�Tq��Զ$�z�)�x'��!#;b{D�L�uf����~���F lP���j��~WLX��N��O�k��;4�!.���]4:��h���}�������EYF�
��2L�p/3�h�cЛ�/ O���is���K�1Bx᫭OƸ��M�/f(��^n�a�����6b��H�9l���k����Y�����V�7R]FywGt�M0��X��p��g8�����q���|���Z�Y��Fj��/�Gr����ny}�`I6E;�3	�z�񯋱Q�Ƹ�\�"�6�K���g�:�t�:E�0�*_ID>�x�Zr8��}�$\�6��a*�M���e����oj���k�	3�����Uw�L�Ə` fV��������_B�0M�*a�wW��k��<GOr/�r��:�qj�b0��͇�ǀ�����jԧ�g�&+:��SQ�5qM}��i@�����a*0r���	�J��C�L�I���J�����D���˻%q��(�	��^"~��X>�9�?��<-��X�[!@�+�_�~�S������"�~��@�ll�S�J��l�PbvJ<N�y�n�t��0O+�ӱف.���� �%hyY�ՠ���Cy�s�'�$Q�1F��Zg��Z���H��&��H��υ�l76@45�-��=����Yӭ�����>��l��<���F����(�����P5F������NP3R"�4���!C�=��}�c���BKԾ����j3�8	+T�u��"^:�_U��:c�ۚ�_ܔ�m���9�6P�)XU5RC�[�ߊX%�!�:42�]�Z�#ҹ�	w[&���{�؀y�z�ɜT��ZS�G��&��#��m�YD�^nx<����)�d�H^��lC}���w+�4��hW���3�jz��ԍ~|�:���5��dˬ�����G֏�I���l�}�Tw>�|��v9(@��� ���iqp:�do�$���I+�a���}�>_�V���h@�sF&nqib��ؘN�F�򥿔�I��>�ޝ�a��@�K��%��9�r�>�p��|'�`�}�䐵 끴tm&?��:ȶ0�[���z
j�Az�ELaxX�s1�H��
3cd���Ch�J�b��E�鬱��(��H8|��?�f���3��4�JҔ�x������Q*7�͜����Ř��f�ׯ��x�B��
��ԛ�R~/ߕyx|� A. ���v�@�m_��������k�wKhAk�h@K���?|V�+̯��Ԯn�k���^��,�0*�T��a!��(>�%P//�r4��jk��ߟ�j��%鉖�<����dh��u9��MͿ�8���S6�(ݜ)�*��*Yf�@����̴�X� ����ᬯ����-�U�:nd�[��Ŕb����4#���Z�T�q4�j���$��h�2�D�Y&����q��~��6Z��M?64���o�����5�?��g�}Nί��#$#�V̒�|�g�߫&�����a��S�ٲ�JA,�E�i��t͚�����'Ȅ<������k4DɤƬ���"�����a�>g��k{{j��2�,��i36��hr�[�K0��������:A}��q (�1��?��2i�o�3���
1���_�v��"K�%�����������/�s �c�%�UӃzA�|��-˸h/�`$�G�;��|��6�sثQ%2�I�0Ugu��bkN����<�6�7:4!*���-��u����L��W��t�2��OM���(pB������@�����u�b~�_����Wz����hE�[,JaO��y������jUJDq�o�>-���zؾQ �I�qxw�J��e��o�jt!=�;gȑ;� �Z����!�h":En�F�޽7�A�_�PjA�%Hh�[�lL8vx�Y���/��9�E5��aZ��Fm�k�0y$Y�ˣ1`ZZ������*�jyw�-֫={�������v|a������"��E/�A��s��h[����W�������"�o�GkZv���D{��A�O�����Ã�-�w&7QS������V仝,��T<�)H
��"�Y�j��k���Xv�b��wu�?e�q{�^���Z]"�#_�?�B�^Td�x���!������I'%d��eS[Th��k�Aݏ*W����r<��*�R�����͟p7P��81��ɧ�,S)8���b��*�}}1���A6�c�ǝ��w��Q�,�
�F�!�ȖLZ�ɽ�����|1�>I~p�q�[}��̃���O�M�;���l� �@�g�Qu�q$9J{��wJS�XM#�{�e�����o�~����I��[̞�?f��$�L�oIg��Vsq/��R�y�Q��) �Q ��贝ɕ�W���E�����V|vb2��<�Dp�1��Kmۀ�=W�� ��'F9NX*h�9�`!nA�%D�RO>��^�p����A��6�>V�67h*�����`B	7�5k���}��v���bP�|Ă�"�!�(d_19҃		Ō
\INP���6����N��K�XK<�D���O��$	�W(�=m6�X� ��mo0ɔҰ���$�^�q�f䗠�e����j�����j���#��(�]�s`�4�5A��y��&T�`[�]+�q��0w�4%�9�G���������-�{c{�A�C��X�[�e�̏��H,���H�O�M�82b���,I%�T������7h�����x�!��[G���(7�5���|��8	��_�T�](A�z	Lt,�
��hd��
�BUO~R�����
eN��]9�Wa-7�{z�!r(�����yFp˘�k0�;~]h�雰e��S���͙^ odW5�l��#��/
2��4^z)!m��/P��厜�X����gb��jן�M����p�区�x@��t�xWJG�-����~>��!�M��W�*�h�ل�E�įH������ �>L,̲��v�G�?��2E�%�!�~��~Q�mA�NǛ;�4d�n�5AN��$�ʀɼ�sދ��h����
��F�a\�]�,"�0�����~̐����y��?�5\�A��>\�����Vt4�KK�0S����}Gkа���1wnR�L��ɻ�yX]�j���gX4�	�mDш���S��F�`�|ۥ�F��u�P�[Ӣ&$�hQ{���-��+���| ��B��\i �Qkh܆�(r�7")G����{[����y'�����X��PF:����YE��ܰ�����&��� �c�F��C��	\ae���9�zgdVh�Z*�k՝y"������Z�j\f�׍fZp`D"����Y��#���A�R�S�G����گ��ZE�7���mF'��6e`�&H�9t�i���`�В�I��%��إVؕ���*.�=�S˃k�~Ex��-�&��<��n �	��?u� ��Ԩ�ڴ���֮��8.�m�_�#b�����TZ)`%7uwNB ���u�E�ԅ�ɯk�a�Li� -A³���y��� 
���u��Y2�Ycḏ�&f8�N&#)�q$��%y���d�eƯ��K����M�����P`���zU��NF8��]HC�)�=�;r��2�|ީ+�H�M^�ۏ2} ���,�E����>_>�B>�yaǣ��B�Jl�4�
��E�O���;�[`���z��<E��Uۉש*g�c�[�I(�`��Mɓ�9���u|���!��4��q]��b���k�$}�b�"��B��zS��/:������N��=/C"$'��ȝ�ο� �_�o�nŴ&�CI�o.������&������Ȼ�=��&�Ώɓ3�"���1SD��޸��e�h���(�D�L�zxT��t�[bbJ�-����X�}*ĺNVB���"��b.���߃1G��y���v%찍g�a�4D�x��ZQ��z\r-r�'`F5kDn��9�:�B��u�1l�"AU����oR~����]$ r�~1F]��P���Z�E�Z�"�ULv�OU��c�ͯT m
��z����QYC�+w{5K����`q�܀qY0@ȈV8�'4���2M'R�o���V�C�\��eU��ᄷ���R��*���qg�-9y�%E��&��C;�7�-��U��}�
xo��$��'�������x���c+�ʙ���OSNz���t,��6<�#'�i�����w��'9�2��m�1�eG�-�N���f�nԱ�m����'_�38%C��7c{�(�e�֠��㦓#;?���,���3M@xt�';^ �'�4v�5�n�����ʗG(��� 'pz<���oHꮪ���J`�Z~
z�k�н�,�P!	ݹ��z���%��_��Y�ɤF<C`��w���s�-Ciܢ�=�a�Q���N�,�w�B�� �m����(;�����Ύl$�Ucü���
d��(�j.��~L�[?7��$>Ybt
���zS��<����3�U_�Y�+�+S�l;�IbO�<Oq-�5��wyl�J��+Vԫ����{ ��������,���˲ Wiv1\>��a\��|ﬡ�<ڦ���ٔY��[8��sU�?W*L���7�X��A	��(lu�|"]z�p��e�e9\�[Fb:�:�r��T${K#��^�{�D����g��z�PVp�P�$w���	�כ�t�K�qc%��*#|�Pa�v����vi�H(0��o��:�+V��E��W������Up��d,N��E��������K����
]��Cn.��R�)Zч ���۽{�g}8��n&�M`��$��B������-dh��27��B.n[���/�_����k\٫O�O>+#:v){A���L��,�H�]�r�<̘LJ���8j㼧c��E0 ��0J��z�EV��ܶ��
/��D�0� �h�}�"F�>���mg�[��W���b�ߞCXZĄ��z��b�ˉ{��U�R��=6G���rN�0��1�+�a�<� ��(G��wjJ"%}�ɜR��E��f�D����+�l���AF�%��A7��u�h�,�
�1��j����{D_��w����_A��MN�u50�W���� ��IYoQ��M=�Ǵq|pfe������p�3��k��o�J�
7��x]� �sȄG�Iš0L��3�](���p�F�y�O?��;,Xw*��?ZiP��s�J�3��d�����Yq<��Þq���6>4
up �,y�qW\H|}�/	D�7�?*�
S����Kp��9�}��^}���ɞ[���eS;��,[������	3VA��N���uc]%#)�`G�N�a,6�p�2��/�P����@ͅ6���-�4�cԡ��s�la����GL���̓�6��ޣ��A���,�y} a��C�x��9v� ��l(��f���V;���b��u#am���F��_G^:.��Z�	B����`e�^�p��_�+L������F�����o����w��V�p'�r����@�HWE#�i��:-��V����>K/�M�B�H?�2�T�b��BK��kw�n�7寮�̿���,�p�*�ڮt/a���a��ƹ�M|Õ{�p�}�eG�z��}%�$�t��W�S3�%��i��}��)_�ci;�5�Q���(R��*��D�d3ϣ�IW��XƍW����d74��u�Az��S7��#'%|�O�0��{����L/֯�2쑾`TYP������ � ���"�>���V�̈́�Z��X�Q��#9|�y��w��ωo�M[W5+I�#R3 �w��B�^Q
3߅Ƙ��O ��H�w3�Y�[%Z��|�����ꌟd����0{��-n!�M�Ң@��+Z���g,7�Q�`���o�d:�� I�KoUB���&�J�-�媿]9T��7��N� %"&iS����^����[�ܐ|�����f��K�F��D{~�.�m��GÊ�+�P-`<��=�M��u���R�3�m��D�s�m�
)V��"N��=ԫ��ƭD&�:1�o�I`�����<j�sE���/�Q6k -c�DF)?�˒��!��uk)�`�k@K�/��*��7�fPגdYz���2�
���3����8�Ջ?]R۠�hQORS{{Bޯ�� >t��~�C���?E�렊&����%�	! ��E�{6#��$}��\�-�^ԥ��L�;�D;7���w����Fz�̑ �aԪ�3ށ��P/ $�Ϲ	xe=���^���fՂ��`��`m#��!�LE�ǨEq"n�����YGث�z�|�F����qe�|GJ�&��k�~�V��;�Dؓ1�p�]�ƿ�kX
N*4e֩E�Ρ�� C�j�O�+}�t J�0R�������%c@5�Ʉ�⇵�M*L���.�����a]���i����*�O=Ό��e���XG��><2}e��hJ�.e�v�>¬|�������'�̤oݾ���ջ�}�`�����p�\������0O*�i�ϝ�Iw��v޵�"�(�c�b����Y��M��˾��>~,ц馜�Uyؗ7�a�]/A^��~�o�@�-���|���T*:"(A��O�R �m Z��i�^�՝�"�2ߥ�@��I��r]��Q΋.T�\ZK�-p��V.u��3ԭ�ͬ����m/��������y�_���Ȑk�����^�d^c��d?F����.;[ϭ�����?��dwO§s0onm?��Z뻓���IRG[W�V}j{]�+s�_�L��5���C�գ���U6泬���Ŝ���|��zf��(�ChO<2O9�X�$��y{��Msz�M����ŖS܂|�,h4XQ���,�
f��B.��ú����.a��)�ӓ�}@��?�^�M�j���CXX���Ts�5���"��EI%�k���0 �5�ذ���-4�_g��c^�	��;EH��A��8�f`��K�s� �~�����T2F]2��2�	�������a��c��Gk�*�wUt+Y��?��m4���L��%�w���7�N������M��	�1�OƽVs��#e��V
�Ǭ�0U���zp�\ؘ�d[K�K���Ʃƿ>DH=�X<�$}t�v(�����Z\*��Ag��E*`�Ԟq��͋��A�es���
� �E�¯�O��*��m����˸1�i��a4{�!H�~��p���<��Kj�����l��Nc���#��C΂��S��jW�K2W�V�µc��T�3��	'���G�C
r?��x+B���g���Z�VB�~ƽr��9�g`�MW9��u�h~ݨ��r���c:Ϧ-,�2y;�A���/7I��|q��[փ.$� G��y�V��B��U�wO��0Q�����O(FɄ,˧91���h�k��^3x,v�z�������SZϟ�y?��?�1�����Ŷy���f)!K��w�`�t�Z�����H��# �lx?'��]Z�[Wh�!��<��Vk��T���~���dKԷ�>w^�����~k�p���N�*�(Y^�̌}s�zE�:�{X��@�?��b;�s2�ڔ�V���,� ��QP$��m��Er���l%1>�yX �ڶ��Q�\��L�n�&�!���z�
n-+@Ávk}(�*2���J.��ѥs�Lgr����0��۹�������Fɷ5��^�K�%.�_�Zk��1�q׭}���;ݢnaC��\Ɯ�z�+���ϑ���=�j�.�  ��ǌ�B��l�r�q�a��йD�7X�'�^M��C:܌)__J,2���.�vf!Q`=nZ�gs�-�3U�V���������B�h=�i]*�`�<���-T�����<C�27��"�4�� i�vG��1`�?�,��%�'���ֿix�/�-�Ϭ����7zfxM��Z�u8X����7:�8G�݁	ĵ�\�Wl��4��N!�8�*����7��vb�j�@��|@�a�$~��9e_̥8���ڸ[���a�oݟ���f�W|��\g+�KU-^��$��� p��s��s��ˢ2H��ԉ��;t�ʻS�y�}�Og����S�X+Ǧ��QN���4�x"S\�����6�#H�4G̓���0�aK��p4� �F��Lˑ��/�ƕH}��dm�Y(�w�U�&����Ӟ�>�����YDR�C����d.��<��M)[5B���3�,�ڡ��@Ufi*�X�gN��נɸ# ��"�vK�b�_,1��^�i�s��J�i��\1��.0���;����GkD��p*Nւ`�GQ����I9�m��T|�&�#i���e��0@?Z\�k�*��qqH$j�.��<���tg@h@�ٶE'��_h.5���y˱#����<X3��˘�Ť=aÅ܃WT����n:H�UQ�i�1�����f>=����m����ᐏ��h22�y�<q�B'n��C1#A�ۜ��P���7G�2�YǺ�����:� Ʊ��B�g�Q�-ڙݝ@�%%tL���v1P�!��%�՜P�[�34�!uv�䊶-�v0��\�]�Jk�S�=�h��*��N�;�J^��Ϥ���2l������74�A�T���R͌VI9���Y�83�VAT4�	��������)��_�-<�Z�"��M��HCw�ѱ��}.��o������K<�$@K�����#��B�%z�U�3&Di�V����%��ѼA�	��''k��'[�+�U��:�F����zQ6��ǫ��\?A��${8շ��4=6�S�+��)Q��k��4e(��b�:O!?y�f�����׷8N%A�
�ܺ���H[�^:[�P$���qE
0N ��b˗Q#K�j$��x�����$�����^��G��l���y��l�u!y�ŹNC(4�3U�F�iqC����mҴ#["�0+��%Eո��'$>h��#a.O8D��'9�H@	X�z���T0+4LZ&>�~'^�tNI9X�K���U��IL���b�S���s~�����Gc��)"�|��|�~Ҵc��Еb�y���YP�*;�hyqWi3�M{P~fU�ՇrSA��{�=�6�a����oS)i��
�����P�	y�@5B>���O:��}���y�=Y�*�+-=$�2�7�N�I�m�(�[�G����b����p$��S�_�v��Z�%�b��q�����j'J)6�f@�D�D���1��3��Ɖ��V>)|�Y���a�%P�V�4.��ni¥���/�!@��4��u��:�,ݡ�.�+����ע�+��\6��˚^�pz�L�f�!]'����~��Ny�
֎/&ހR\C�CE�њ�B��d���q��(⃩�=4:gq5��Ƕ�>+p"�)��e����Sq�)���\6rq���:"u��V1L@�%^F�~@~��I65bzm�8H��#3Gz`��Q�w�1ޫ�}ƘZ�`�瓆S�L*�{w���/���L��u���<�y;����돟���Ҭ���A�,T��*< m��Uأ�͡_�r��������9G���h�Y�3�E T��_>�`�Y�� ����a�?=Ȇ���.� 1( F̜�%c�����c���l��z�B|&�[�e�z� �d���V���3���P���HS���>/{�|�`��<�'�܋4���3��|ﺭٔߣV�01�п.�Ͼ/tz�� ��O��r�~�Z;�@�g6��M����d�ԯb�; '�ބ�]ш$�@H�|6�)� �ٌCn�Y��&�h�P�ι?U�a��(�/��!l
������N̂�G�c��o0�%�I�u�L��$ζ�<�;�ӆK���N�c�|�F�1��mx1p�U��:��.�?Sn�^@T�\�lt����jB��5�u��^�c��~c��7emI��3�d��{.e\yP\���D�*��C$�M�I�O<>��j��Z    -Y`+�-@ �����/Yb��g�    YZ