#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1103655806"
MD5="bb99d212a89d09ece86e3913d2e80e09"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22960"
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
	echo Date of packaging: Wed Jun 23 08:27:02 -03 2021
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
�7zXZ  �ִF !   �X����Yp] �}��1Dd]����P�t�D�r��a���K��8�C.or�I����qy�"1��1W?�
��y&B[�T����H�(�ô3��xgk�,�g�Z�.c�R37�dO��tŚb7��?�a�W��e%�뎱e75TN����ڜ�8g�ʣ=�I����K����4#Hox�pB��beK�N�ɰ7�N��y��0������C�[��k���:k@�ao��9߀K�ff�*��*c�nͤ�m�(��>�p^?�����Ĩ˲CH���{�u��u�u�#/#��	L�H�����e*ɰ����}�J�`��D�~;��op��g������C�i�k��(���̌���w��	x��aQ��m��x�0Q{�j]������wl#������?��IOg4����x��xq����BәD�>Wݕ��b�?�j���:
)� �&�Ed*�a��1Ҧ��rh���?��U=���|H���܌�b��l\��jap�8I�z�ŭ�G������W
a���E�Kp\�;ɝ�G�����^C�� �3��Ҳ��{��ߨQ�ϊA/�9���_��s�"bv��X&s����F����`ŗ�1L��<.i�s�6m5�Z��-��ZPp@�&�=����=6d@ �W��=�}��Z��w��-��*�8�l\�_��)��h�f3��oHR�������O~�q}
�;�Km��<�#���1���O,&S��=t�����l�A�ӑz�1�g�Q��xVD	0"�A���qY�=u��	?�LJ��$��%�:��3C;�%,��TM����Yh�[���G�BC�Y�$��>�K}��@Z�b���	�T���1q5?x+��B��5�8�"�$k��^���<PJ��	x�B�HI%��m1�_��3ūH<{U<��}����s"�?K���5�rG}��/����{�4�Þ�_5���l�NLܾ]���Kok,��x	ٵYvS.
�wL�z��� ܵs��Oײ+�)�|f��"�h��@�8�t;�ǫs��sr!�֚K�Ųy�p V+��<�G�a�"��|l(6�vg�k����\�.d�b��7d�Ϝ�]������瀼��:x�,5AU!b����=�l�b����"��	����O��,�UZH`#���)jGdA�3�S�F��	�W/�QH��. �nS׏m�Y�k������ד	��
���;Ϛ@�UzA#ă�ǔ)�gm�P�7�]}��^:�!��C/|���Pj�]��D�����'	����1��N��D\}��/6cl��MT[�sV}����ToL�
;<*۪�}��
!� �&�}v�In��i��y��{&�n(ǆ����$�< ş<
�@��@e��)����c���_.��^*�|���;�ݘ����+������5�i?�/��\M���mt2�[��zͅ
^(ݟ]W�h+V�ZI���E������D�(�d�?^�ey���ɜ�l�C�1��ee�p=�>�����ߣ������ٖ�o�
�1�f�`R*ߓ��g*	�?�8ĦSY��6Т3��*�f	0�I@I{F��5922���O��)0��[Q�>�:��V��G��gYk�$�{ѷuȒءL��l] ��BHNd���jPy�	B�f0�R�Ŏ`#+��E�g��X��*C��JlT7�ݡ_ A2��k}Q���Ǉ�����1�����G\k��KO��sl�Fb�+	oq��n<����p��"Q��������*U2(g���H���ܨ*��'8���N��S�z=��}�r����BA��6*^����.3q�q�V�"W0��ZEvh���F]�P��v�
mCV��(�0�:|D��t�<n�a�*�(;Tc$v�2I�+�5Q���~�bI�_=�a��5*¨=8�=�D��c9��z�5�Q#8�k��cj&�
ۃH�֥LS����8|�N����C)&V_h���K�+�4�����j��,o/;Z�_�:T6����F,��rs,/ Q|�=߃��ıh�Dk�Rk]9�d-|e�)�m�P�ry���顛���q%����~g���0�,i�#9�ZbV��i���V[�Kax<�^�G�����������M;S��s%~��P	8�HoH���R�8�S����Bd��p�����ӥoFG�P�ZJ�	�_s��<�4
FyT���x�Q���u/�lԌ�dm��9An��\�/R�����.Ⱥl6��M�U������qЄ
�zGs�O6����IL����L�������ܺ�	}���+�`�u�%���!+H�4lT��L���Y�'�y��k�00�f��šG�����C�xN�2��%Ib\��_&"Hѣ���LE�3���`���ϊ�s���L�=Β�\����?o�(�nj���1��}��'*�&�ڱ,��g��g=prA�`~`��+!�ɔ���L���hZr�S}m�%7�*,��;55FDy&Qwc9�PA�ri!0I�����<��j�	���Β��a<JX���T���?������Q���,�ұ\��=�
�=�s6��R���7�;'Z�Ej�L�zV}H��GԿ�Q��*����08���R������L���x�_u���&�>P^�-���n�ͦ�t����r~T��w9�����@k��:���ר������C+��8��X����:ȧ�p6/�2&�ǈ���- �|�i<6w��cw �ehW�5ٮ��:w��Ouh�[��6���!��3��6���R�bv�Ih_7�=O/��A�j2WҨ�,�36'��'x��Y�1&�	�,�Tq���:�S�n�x����/��1��R���8e�>��3�/�U3�I�`u�6,��<��v�$@F%�.��މ��[��Q|�� �����
����`nd�2m��4�g�(��W�}���I]��	T���MSّ��c_���n���|s�8���9L�(a��6�� 	bb3-ٓ���K3f���7h5��&��?�JAu�bd\^$��W�D]l�A$���K���[��P��YIc\� �]�(@ȂPFAoo:�m�7Nч�܍����r`>�#�Bq�N�<�Qlկ'/�Z�C���X��ǒ��8Ç�[�_���lW��6��`t��8>�/��}v=�����K��ҡ��-i�k�|B��op�'�<`Ǌ8'�aP��w!��]^���b��B�u������[�y7�!�7@ $��3�z��*��!P-Eh-04;��%����$.���!d�+oxr��ƢұsY��>���=:�o@�qDp���-u�ش�K,D�Z��e"WE��&�d � �v-e��I����0��Bzz9���F�Ϥ��r�7��$�"�a�7D�)��E�"��:/Gl�d��_ݔZ��V,�g�	����o�\���j�"}w�s<Wc��^}8piA�����D��1�����t*�	�*9YI<WIO1,�%�8Q��	�l)�����C�"�k�d�I�_�b
&nk<�s�NbNua�t6=p�Ԡ��qL@m�1�?�ߡ����2Gن��D����"�ʨKt)�'P 0B���!m8����TW��li�RCI3�1�dJ��*�K�K���ʗhC�;��-i�"Z��:R�ϖ�2�Ҹ�S�����D�<7���W��@��i���W�Ox������%���+d
����M�J��*�,mȒP0(v���ͷ��2��+�W=�-W��eI �!�%�|[+O��&%4�T�Y�J�h�<qhZQ��N�BL��%ծ�A�
���5�Ը�a2�c2��s#���n�	K�*�����G1�w|e� ���^����X�Su���l�$n_�go���{"-��V����J?x@�� ��N6�����ڳq T�N(73j�^w�ÐWR��#�RX����
��`'8��M;�H����q{_g{��"1ª��U\:΀h��`��>X�eM�.S�E��@��������m&����U�M�d$�6�Łu�˺x5o�#F�X��H��9�!8�sI���O\y���C����+�У�A��W�p`FF��pjE]�˔ND���N�R�{�w7��G.Go誇��2��#�e�x$��݊c���BNA�Q�����8�@����K�pF{�=�"L�keN� �����Ι�+9	y(&V��P�z�`��es]�K�S�,Sgȣ�7 &��4����U���a�&���m-�@Gc#Z�����s�D�،߾J��VF=K������Տ��kf�fM���I��I�t��D��CIs��}�.���Q
7�M��#�脺�.��
?-�d�)Ar���.����	u�K�d/�'��
\Y�esQ=��7?F9e蚬�;���)�x�_�ۻ��&'e@�ҁ
vo	LD��j0s
�5`eL�L�$�<dOC"^�����Qz�Q�iӌU��x]�K�\�.o\p,���3,?`��S&ҏ��|.ǚ��÷��ep��&,
8U��H�:�[v�|��U.��՞�p�R5:5��؆k��Ka_�;=��c����nj���U���0�y�B�C���=��0y$JQ��w]��؋�Ė.Q�TY+O������0N�+�H�؝��̻[�T�W����4L�B�j�R���n�q�&�L�Q�ս�Et�a�+(+��Kk�3)�ԙq�f�na3��y,&�J�'�=�^$r��D_�?N0 k���M�{���8լ=NF�L�	���F�>`��	�L�EVH�������S�Z�*�-2-�&g��7���KS�	e�YtT�/d����(��!ۺ�-�����N�����v�P:~�5�=#M&+��8��8����Hj@�$X1��H�|L=������g��p6I����g�dF�\/�wi��y����֊L���p�{��	D��qJ�3��V�ƊK����q&V7��	�}�y�>J����	ۿH�#9r����i� #uĢs`�ڢI�Ο �B���Ey�X���9�`�k}&>u�4J���B�z\���tA���wW�OIi\s��g~��ql�̝n�F}/�٧�B%@�﮷�0���k��?3��=\:�u$[�?���p����q#�պ�B\�\���c�!PB��3��^4���ٴ($�'Lsi̪eo,����%ľ&�q�I�*�)�&�}/���(�ms{ )���B�q ��69���5B�z��U	�Ŋ��+�0�[m�{�C؟W��#-�w&��B�n��!:�Tcs��ِХl�_��3O��P��moc}h�_�N�(6�T��aS�smٳ�9Ht��cz�ݒ�:3�,ɂe����Z?$ް�tO�|3���.'�V�7}��Ģ�t���|�-=9q��3f��-�z�6X>�Ы���Ə�NlH��}!5Ƶ/p&޲���~��cޤɾ�Q������X� �$��sg�F��������Y���ٟ�>�p��"/
�#9������'�F�`�F��A��h��D����g��.{J�Ij�٬���6,qo S�c�P�C�� 9T�.S|������ɤ��Y�<����-����=(e��1����z]Zf�xN�sF�D��e��K��K>��s�rjoU���C��>=���t3;��'�HĕT>�qg(�?i܎~��=�%.��O.�>�h�ඖ9`�%�����̂�V��cQ�.��x�V%��0���_�k�C�İ��Θ�<��J��t@鄘��q88�� MH�Ű��8$qK<t�������Ѩ�p�E/07!���Hw�VN���=B�VigG<y�:2��M��65�?ǵO?Bd����݆B��;����ɑC&��Z�'��u�1��������\��B��Z�*���BgD`g-`�/R��z����H��i;�H�(�(���i�qU8�ݹ� }�+8uXNq��Je�*�_
�Y4�=�.�x��0-��ާ�?\����CAM_��5Y :�K�	%I��|���0<7s:5�����]� �n�kLs��^��0cE�]4f�@v8��Z�V�ō�����	��*H)\6��d*:C�?ȫ�,��QUl啒����?a�����*���On,;�x�D�Ӽ�f��P�>I����N/$-��6O�3��z���֋%������Ļ����8�	/�Hc"h�ڪ~Ges/Y_�@��� ��'&Զ�s�t.�EPs:�z���{�#
�qrB��v9�jm���`��'j�m������j�x�*ؗs�Rn�ҵ:Op�p�_�����q���E�1|B0t7��X��i"�T�-3�㔮�a/��\�Y�F��Y)����J-�(b�?2pv��եput�K�Su�XF�������&�h8�z��[��3�r�(S�D��L��1��&:�e�%fĨr�'�kHG�?�P���it�h�+�}0�q	L�ҩy�8��W�.9KCYZ/!�c�q�%	!�o�?��S��tJU��vHн� g�R�!k�D�<����f$��LW�ێ�j����!��*��7#��;؁w�C��4��aU���K����W����߲:��S�Xfӣ��"h��Qj|����vJ��4�wT��ķ|ֺ�����Llg��D.?�_%ƅde{�Z�$&�� ����n�iTd�a/�}�8ò�\��=f��ܡ�Ԗ��ZC-���Ў׹�2r�*�%W�X�n��uA�}a~��l�&�%H^�J싴�S��P�<��!�,l?��uK1�x1�����e������S��\���r`��)�S�>�	��nH�Eaa S�L!�51���V_(�,pZ�C�gw��W&g�fy���GN'�\���_�)(�j.�������p|Uŏq�+��&K�9?����<����H�Q#���R���F�G�zT�^B�.���-�M9�QL���( ��UAG��*&��c똌lO�w�RYX�M�ݮi�ɓ
�R�k���6h�4�<M��<o*�&�h�h��G�F4�Q�6  x���/��L� L�J`��2a����0A%rXЍm1j�QcG�̺�Q�yF-5�u�r��Di�K�{����f���F��� �@w��)�V��av���7#:�;��fW?"pJA:]�I��2���x�;�L����q.�>Ϲ?�C�� q��D��h�$=cMq����%�u��|��=z�}3�6�`P���&�C�<A �/�d��	$ڄ?��4KK�^,������Ƣ����A1��*R��)(�==��!Ǝ�~��$u��T[�Y���/�O����[��?e%uu���.��I�4cp�Mn��S�f��s1��7�*��0����ю����?��>�Ѻ1����V����1��Њ���uM���g8���"����%+�ه�L�}�t�Ȏ���}&B��*;"�jo/�s%�k��|c+s�����v�����jǶ�Z�_�}��
�f
��d%h9&p�`���@�QcH�78�-m���e�G���2"�NHNI�V�$]��R-T7u��޸�:���qH����O%��5[�\��9$QMpp��ZP�cL��In�k�vٚ��^ށ\����ʝ=X�ǟj��8cz��/_;�r���,.L<;okĈ~�6V5�C��3�%��!+��+AY��m�q0��,<��&�l��p�Ls8Z��|���J��Mz�3��֡+F�l�<�ɔˤg����
�ˤ���`b��Y�P��'���ɾ#����8G��N�������� va�6�����@���З��=�9C&�y���z����]XP6(�߶.%�2o6�
MM���x�P]�@����{��"˨kK2E�k�O)C�_[ϭm[P��(�T;+���1g���WL1�LB��LV
���Zw�=��������������D!���>Ǚ;h�6���b ٺ��8������pO����Fuֶ̒��\��L籡�����]�/+&�b����3d\Ǆ�rC�C�R�=��?�h�\�C0&�M��%|8C���&Z�|�APKS��{}F�5Ϙm�:�ig��Q�tO���W���;�T�����>�B.��V�گL�i5a %���-���S�Iw-���u��r1��L�g��Ͽ��I�u	*��qy����DLv`0�K@wC&�u_	X�.y%߻��Ԧp4A�| ~r}�ad�M,��	��B��xO�S��X��3����	�R�%? ����O�:��2}X��a�ɣ�½j��V�q�6��aۢ�w4�kٚSM�~�������'(.�q�bW{���Eӌ��[��cB���8n�����W�8���&���4Y���&s�֞��S�?ʬv��5�v�(Q�*x�ڬ5vr%�\�<r��'�Zh4�N�N��f�m������]u��ʔ��$Gi�J��)�6��Jj� ڔIm��#&F���0�9�^��O�hi ?�+����o�_�Gy�=2F�
~aA�d��1���!��_�\d�ז�6�R��g��2�@zJ� +r��iX��#dﾔ����)&)���E����j	�Ѕ$DM��;��I�	V��;q���ng��Σ�P�F�//�A$�U9�YT�����M��.Ї�q%,�a��M�C_�?�#6�B�����3�Pk*�ηAu��uF�f���Uj�����S ��ݻ;Z�&򕈮VU@?/��`*���{N���n�B��m>�$7�s��r�ʅ<�W�����<ΞcWZi�����2â.�+�?���Ja|��Q���(�xl�)��y2�kܒ���:�>u�֤�O���H}	S`�z?$G_���y �����Q�O�Հ�?��2� s�8���&�,f��~�0���Ӥ�"o�����nC��4'(��W9V��;�C�[��w����99�;0j�J�jr�g�{��6�9����?kǓ#�E-�^e$!LN�B8_5F��u�����@�g�V�D��+ɭ����T�O�q�Ө���Nh�v<_�UgY�`Q�C�A�;yM���D|FxuΝt�Y���>*]���M7�k���[Z���Q����T��d{�r�[���[�W̉��;GLEۓ�A����+$ �^���\�j-3������2垆 0������U�t��t҅s�V�E��'��9�߮��[F=H����1����r�)rx�� �_��G�~$���QN]��P?�*�m��a��r����:o�VÁ||���/T�!*8�2o����9� ���U��t��K�8y=����v��2ض���$��R���Z4y�7äX��(���r2(���ƹ�gS��͘��Jr	���Rm�����8�q�"qpI5L��1��NV8S�KӆO�럴�VU�ex�4��f;�E���	/�-�ӗ�{��� �z�I����A*~�Y�p��&P�'w�lq۞F�p ������Q>UL7���dC�P5J�`�-57%Tt�n�F�ձB�zV�	�y�+�4pU�~s��B�Y'��&:�5�8zy�����-tiԘm�^}�U)��Ċ��캇;DT�,~hrl���z�R-�`����9ܚd����^&��c��@S��_�-���Ro|hD-攐��jm�DG�R܌r������wo���ԝF����?�J\��y���C���,�D����v����4��Eo��0F��C�2C�yv���N7�a���;�K�:	;Ԇ�~<:��u����ֲ��S��u�9��*�����W[x�L�r��Zm�o�7"��6���jj��5ʎ�g�WwQkᬆ	�G��5��7FLR�:C-�r�݂�q�n)�G�����:�&��q��Q"��L	h=	pa�0	��6�t����D��.wa�5{�裍3*;��^���WB���:�s'u��Z��񀠦%oLDJ`�Sy�<�R�rV��ɲ^DɅ�8�(;��L�u���@�/˝��~��e�@%�8�Jk);��Xb9��~��X�n]����>��o�X�(��{�����}A��l�#�l����lM�j�C�]�"n�x�#�������7в�&�Xr�Kk2��ۃۅ	�iS���w���&5$dz�-u�-���M�ف�ϖK�s��b�j���(��U��1d,��(ܙ�Ql�-	I�����k>��r~����jAMr�D�E�vl��FJ��6�w9�.�Js%�]���E}'�lQ����5(�W��]���DR	�Nv�-�����Fܴ�G����ٔ���KW��-�,6�)��rּmr��n�8_Z1g�C'Ǌ�!�
��)��C�{�u�D-��fe�"mIY��x:~Y�Ԅ g�4)AE������fz[N6n��k�J'��X���:7/S��!0��b�����hu�����zB��s7T(����ޒ|��*���4�-w��� ̪���ɞ�lH�c�����t7���@7'��1����5�}-j�ߩh�.C�?7GX"���t�H@�P�H��ۂ�\��`�����6�©ׄ�������s��X���#����Ģ�ҟ�l����K<�{?e%fѥ��� 1#i�E?��{h��t?��Z�;���W�X�Ei��Йt����Q�̄�C��;���J�&���깄�%Q& h��*o��%��!�����W�q+�\��"W�=��ʖG�3�<\<�%&-�����##�GJ�~E9W��%�Ri+��`�tPc��aB��}3�������-���ۖ2��/?1oɾ�J.~����X$'Ӌ�x�z�1�(�s
�}6oܤ�M�R��L�WWt�_�	�Q��c�ʏ�==#w�YgH
Q
���v�K������ݙo���G��+������(
��^Ә����_�?��~�������尀������S�pMt�3�O�ds�aNUٜ��Q�A0*�����Q��rO@'i�e���fy��}A��'�_?S��ْyu-��)Ljp�IaV�>3�io��ߘ�*�<_f�g�@�-�?�, �i�H5��C�f�p)nԓ08��s�v���!��ܤ6��N�_#���C��-P���G}�=��Y�w��r���a"(ג�*��f.���2��d���~�S�HU�uam�\��ǊW�
V���^t��nW�\,c<�oF�B���ߖ���Ĵ����?~,�풟@�(��`��$�˥g��Ȭ�ȣ�en�ې��&��kлW��/���B�w�)�`+ۢb2/Q��bE���4 �0DqZg(Ak�_�z���,T4:5�7�^ʚ�Ef1 �h3�����U�n?`(��/n�n���(�d�KL>�,��ɤ�����J��H�f;}H���1B�Y���[�>��pҁ�d���~F�,5 ��<��94�[�cUb{	�W��:�0�w�?o��cqP���Y���e�^�3ޭ�Ӯ�Y �ݼ��*!ˡ0�c-��?�_��	.T�� ���ܿ5(��ǢV�� 
!��Оw�3�������r/���d�A�y����Ta���Wۊ��x���V£�s���r��`�^s̬�Q.\�t��/\�on���d$�Nsb��3-^٫��[7p��f�I�/;�1�r̐�
sb��3-
�v%��{�3� #���.���v�'�;C��>��py�y���vC�`�$afI��}�@<��w�H�ƋfD�������T.�5Tz�Jr80E�.��x1��fmb�~e�t�����$��?w�b��70�����B/���ݝ�t���]|� �c ҵ�����:��)�l8����;ќa�㋑MȔ쥫�� :�To�\��,��T�;�4@�U�R��q��zX[��L�3D�%�kC�Ѡ�gr���o~�3�2�ֈ�(��aP���&m�Wjֽ[��o��!N�qX0'�U8�K�0z%7��__��kC3e�A�<�'���#{��	��q&�M����:�"�Yn�l����y�B��!R�x�/��wu���������$�O^�p���ȟ߳�NII��3!Q�}ɭ�f��r��J
;�0Z���/C^G�.�P�Eګ��N��]�_��-��°�Ჟ�Nd`r� � �nB\�]��U]E�����i0g+�8�Q4-*N8\����ִ�Z���!�p��ZأȔ�ī�j#f[6���$����ď��D�I������#]���8����Ŷ�^$����Z�^0W�e�UV���B- 䕉���HDy�sA��=.ۛn�s(�;%�+ƟP�f���m\G,`�V���c�c���>���j����<�v�!=W֌x|��ez�)4�ϟS�r�r[\�b�"���Bi�Zd��hYf��Uk�������E-_m*!�J���
b:���J������n�s���}������W�X�R_U��E�r����<}#%��yI��`2�m�>��?�9��$[�%��q�_	D�  TV3�c�8�gj�m�>i�*&�*bg!����K�4��V�c��8Z��Z��(���z0)�o���0N�	��6��#�g$P�x�y:��v�K�s���}gl����)�C�%�J.ܩ��02.�JzTԹ��a#>��B��}�!�'��o�Q�J�`÷X]S
ATB?��>�4���-,�>oZ��h���8t�|g�Z�/�٥(ZPn���N�������=f�U8�a�n��
��JB�1����3�}=���T�u��% "f�� �m�yY#�54�VV�ލ������$����jn'��^p�-p�'�9�̩�)�m�ҕ8u�v yrtIR�>������x�����Ej�7zS ��%oO�#V����fP��o���Gp/jF3{��D�JsSp���8�@�E�vʹ�.��!�6��)�RjWҒ�t�B�YdX�D0��¡)�]�	�Ͱ�f��Yk�Pq"c���3����Y"J�=�~��{4Nϒ�����s&p0:gM�[V�A�`��}Y-���CݭY�ů�]���N
#H��3�ؑW3I�?��CEP��)T���Q_���� W�o͒C�;���k��T&Դ�?�{tH|��9o$��*�%�N�H�Z�S#�LR���� ����y���O����G��"�^׹q�"+NA��G���N�i��گ�z!���TR��S^S��o�
s@K_��'̽kr��B4O˄w��4I�ք[.�_W�=��� M��GC��ܫ�K�s�T2��C\�NL��ǿ]
�'>*�Y!����2�X��f�sM :��X���\9A����¦���}�|_E��!�`��O����AM�{W�'�,�.�\�I)�iANN��#���]�P~��&e�&�V�m>p�P��}*�+�L���|�	�M~0{��%�^�	�R$�9�P�g��e.���g����M��v��R�AC�{�A���.Yv��$��1�;ot B�㘉7�,D�1<2i�,G�{7�&J�fy���<��$I���z9�8��\ M���f�����}�A�AA:�m��@�Z���K !�Fr��p��d[BA�؞��r�S��̽]FI�~Y�=�U���s�������F!��M�*�y�I?y���J}k+2�e������m�=d�w �W��C�����+m�F��t ;��~�����B�F54Ռ��fA�7�ؕ��$Viz ?)�y��0�dIu�.��A��w*�zw.�=�W�oYz�nN`,��o���b4�8����w�]�65f��S����{�)2پ˝AxZ �k1"�1S��:=����9^-f#D�R����ak�n�e0��&A����\m�D��'#�o����C/��Oh
r{I=?*o�q�/H�:����6����9��"i3��+�*���S�d����,��pAa�Ϭj������Z�; T�f��=�Y']#�*��NK)�����M�p�l���}%�8��B1^ut:t���ݥ��d��X^�y�" �/�>y�.:���oəW��~�Y?�//�:w��3�����kro�e���fO�Uo�ձ�=7_'y��&�ie��T*M�O���Wf�}��'�/rQ�VH��&9���1� 3�_6���buRr��O�na��Գ\�Ѹ
϶�"/��^`�Y�4;�Jx�`Ӯ���0�HA8]]%�Or�z�~�ۄ23����J�F[^��_�;\�q��z	��D�RZ�?�W=��%R�H�Qy{q ������K)���E�WVh6Vy���*T'K�V8k3h��˥q���(�����ǧ�u��x��}�A����Qug���燨ŉ�`w&2JtH�a�*p\T��4K,�]�~pӗY6<�M�N�goɩ��2�k�U#5o��k��h򶡍n�g�4�ٮ�5^ٹ��W>
3��}��p@9摧�8;b�8ni���l�W��aV��q\�K/�o��b��/��֨����;O�7D��S�}�8@vE�&� �J�q��^G���(J|���ho��0
ǳѽ���BG���9�/v\ �K��2)��W�g_��^��$x�Ch_�iЄ#2B)d:�(}�Qrb��e}�W3��U �xn���s����"	'\_��������k�V(�7�������jML���Q���Y{�-ŭ�9Y~K"&��Sz�-e�e�A��4E�����$�(IO+������ 6���ϳ�mVH+�Ԕ��,3�Ak����e��7u����g��V`
_E/�0�� f�~��ĜT� /E��){�Bi=C>[8x�7��h��G�����F���24�j:\�ZUM�@&�;��v�G��`��А�2��,a�$yM�m%L����洏��������1M�Ő5Z^8v�yv �Wx5�:��C92�O��x+ݐ40��+��5*bV>s�z�c[n�:�����bP���+�X!�r� o������H��SB���vy�u
1FҊr1PLLZ��L��~y�U�s�n@�a=�
�����;�3��Q�b ք.��z�O�4�N�o��Q��^?Յ�xԑ����%+�f�]��4���A�m� Ā�-i5��SE�E��Կ*�u�JLq`��m�*{�^>#�u�֟�J,lmQ�q?�ԛ�wy����������������2�gr-Fط��7y�r2���,ݠ��\�ڍ- f_3�c#��Eu]!������V�B�yZq�}VŮ��baQ��&�Q����Y��~�dc����u�4���Ib�f��<hJ��Z��N�"����L� ��ʑ�$Le�{��A�/0������H>)��h����|t^5���>�ΫO*�?
W�S%��m(`oq�	7�U��"���)�7	�U�DtA�,.̘��P<t�ap�јA�C�X#��tu!�ɩ�D�ܳ�} ;!Α�l�އ�Źb!{`�=5�QO�-�t��`2X ���ES�F�Qa*�Ծ���6��HE�C '��ȃ�k�,}�%��M U�AL�]�%�����%��c5M�Z�Fu�G��	��_`��,猔�If��;�<�P�����uU��=����^�����
�V-��h���ʭ�ǷQg@�Ʒ"���"a����D2��z�l�q��^����Jm�3t�PF��Z����Xmw?����v�+���eP���ux/e<�ލ�[�ߏ6gYqD�� ���BT����lk�8���B1���@Yf僖����7\�C}���g��o-�;��	��m�m<�����*r���ܒ�$)t���
:z��=�Wm3va8_Mt� 5�c�E����B_�:
�Q �m9�����W�������UU3L�6S���b5&��X��qN�b���ħ��p]�Ѫ��X��N���-����,���F-uWI�7�*R�ϑ�h6�� '-.�A�^G���@�7,��\H|�ʛ�,N>���6����1i�A=�X �p���|�ꥅ�Î@�
����w"H2w][��w����=�4�KP1��D k�(>�ʀ�7,{�nXC�y���Gs,V�.x�H#�b��n �̛���:P�lȗ�!�30��Q]{�c4s%|1�}�|��5'N=���"��J�/�����c:�&�d**4����P�S�{+�O[p�����bU�[?���� �_�I~�9�۵��q�������Wq�V�̾��i��HXt�.q�0I���
�,�(n��:����⮳�����]�ⰵ� m���N���l��~�A'�4�.*���"�Ы+E������_���Ǥ`ĕ`���W��t����Ä��a���j�� �YG��e�𭸳?ۻ���7�R+����[P������ED׿�^(>B�� �7�5 J�l.�|A��JOv�馛�[��LU���}ׁн;�e6�\��Ak/|߸�9Z��)(�%l���ޤ��d
���L��7|$	���h<�
\��}��,�~H�h�Ǜ��W#ѴoƗ�("dcwEIł�.�G-+�I������]��z���CJ)�By#@1=�������n�������"֙��Ug�	�9��� 0�U��&�S�2�����ް�T�ϼ���'��d���|��%4���nb��J]@w���4�X���ua�Plp0,GӨ��HL�Q��PO�ˡH?ʺ��I�of��u�jM�+G��dӬ�,�7�.�$��
�^���D�,���|8�kײȯU����$/�M�m��e�\b�:��+Ƹ1#��q>��S{��3�|���6vc!X�U�u�?���4�ۋ�v^�𸴩h�&�� �}�q�Uh&X!}�@P_)0X��X���E�9F���P2��tL�ֵS� O<�8,f�c����^�djr�?�OK��q}�/��CZ|���ΝB�/*�Bh�o�-���.�![����Fsr��K�F;aD;��juDf��-�j?�MX��1�p�·93|�����n�ƒ�#%m��nc1#4��@�Y#�Im���zPX��x��`\����g�7�b% ����um�{z/LH,�~*��˸_P���n�����5wY�Z|�;��I�ˠ��La~��鵉G@�Z� �616~'��mk"��3z��vg��5zچ�zƎ�SS�3�[��Z�"�=�+���2�6�%��K����]�}}D́鯅�m^H���ԾZ�s!���n���}�Z�T��[�d��q���S����-�\~Z�>S���{E����̶g[mJ�����h���2�
]�O,�Hi�� p��8K�fӱ�7;q3 �y�
��-�@i��Ӱ���k���<�1���H�n7F������,�9r�̗{��Я[���ݭv��<�$��UD�)IdH9�]��m��}&��Bt�ZLy�K'7�O�Me'��vp1!J�-ho����q��
�����P��y�D�"5e2�����������b�d����|�`��\.��0廀���N�jԄ�o��ڬ(=	i�]J��� MA�>����mZ�I�f��3��>LLt�|4����J����e*� ��'.5�u��n��8+H�xh?��D�ܩKV�LznZ/ƅDT�T�e��k���������s��Q�V[��	hF�\��H���L�m+E�ϳ�x���i�ş����l$�P9�m�q��XJͦ��вI�_ouaR�hT .ۡ}t�k�dW��qV4��2(�.zLN��EÍ�ɒ�L^̢8H4�
��>��#�\N�ف�|�0��͹�3�T�|�(! 4�&�}\�h����J�ӆ��nS��\���wLS����9�p�����X��Fa��~ƹq�=@b�^?��Q����EG���;�ZІxYUXo>�`��#<$z�s:��A��?Ǻa[����]�!<�*&f�{6B'�t�qB�����c�����J;Xߵ��L��-��=�����U�,�y��8� Nv����&C�~����0�E���\V>�$���P��Y��O�W�Rj�2z�\,f	�W���^_�x��{"=y��e��5$�i��@���u�M~��i����Y{��A�i��@�Ff�C�@N�5m�\���	dѺ����usD*����_
�gGG����Ŕw#�:E�������g�sm_��:DFqK$�%C6�宺m�X�Q�����U³q������$Rv���$��M���8n�<&,��+��ho��V��~��9�հ��R�HGM�9&�Hd�0Fs�`4Z���9(�n
z8.���v�&���Wc]��9A{�ͼ@����V�¯޻}ej�]�]����s5_�'k��<D��+ \SiO�t��hȽ&Gmd(��ZJ�Fd�ۋilb{��y~�%O��T�-�-���L��6����[��6,*)�����E��=�e܃Ŏcz^��\@�$_ˑF	�fXX�E�aJx'����l'(�ӄ�-ć����2�p&d�h]�(�b������(��&hީl�[���Ѽڝ��W �;�Mi.Zb�x4�v_+:<�;�gۻ�C�5<����P�T���ʑ�J,I��B�;��7�/B�a<!S�k
	.���Cii'���o�|?�;3��z���Gܜ�D]�$�hr��8kq����t� ݽ+qC�>Ѻ��U�D�A��uË�w�P��-W�Pϫ�v�7��(����?�<��M�������k����Mo�/�"4.X��>/<����W���΄I��r ��[5��]��"d��x���eb�#���2 '�C��q�_�F���d���=NW��,�,����N#�#��*e�@�\�]YR#C��Ľ<���7��àÚv)���F�-
��h��A�B0�5\���?�R.�s@R��3�=��v��lAQ�I=VA��`�j�4���������sx�w(��\�`���q�7��iG��s��-�u�I�7�� ��͟SЌ�?�r&��2���b��Ī^ɻ���݆F%%�Z�WZi@����l��o�a͑z%x<��p�ZQ#�^�!d 9jlP��Y(���
�K,D]�Z=��-~��V�42�r��U�J!%�n�,��c�{xz����s�d�4,�[ �/с�U��se@4�{�� �o��&��o��[��S/�s�ℵ 'ϰ��l[�/�7�ْSP���t8q�^G	��$����fi2W.(f!���^8��lTYz�2�6�p�br��r��du�g������T#E��z X���^�'ͥ��������2��g�"�� N���¨#=P8#r9�Eaf�n�]��5��9��.%�/?h#,�+�1�WR��\�S���s�aF���D9cC��M�9=zO~�$3N��?�l�q���i�GO	��ɿ����WԬϻ�1��;&N�<j�B��j%��/��sG�z,"}t�I
9�)��h§�ԍb�����*�i���.�A�=��2&dR"hN�a��A��^g�QJf������L"����8C{
��*��ic�b���8>ˀe�_,_�3�_��8���[V�bpG_⚳�}K~��O f|ȢbG��%cB�V��b�-`���s=yGB]zҐo0!`^�w���*�Q����-Y���
���Bg���_5h�1�k�#��<��r��in�#�8�#�q�����.)��|��T�������k.s5;�.�8&Ŋz��˦1$�7��_���AyR

�s�K-RqQdV��n=�$!��M5=��s�;���?P&7�����9dnc略ݱ��|���}���#Ʌ|�E�f?����T� ni�����*�5�q=�Dx��k�"[Ѻ����S��f.D���7E�ȷ�_��pX�^�F�����g�J�X<d�8z/��T)g����}
dg�k���oO�>GY3C�.�P�;vt��s�7�uRi���_�kC��!���^E\�O�wU j��4���x��|�� ��W��\��Qk�2z�F�����H^�v2���$&^�BpMR��J`qcM��ɶ{���r��Pe���v�D�~����wV�.���-�8ۄ^v�#�F���#���_�c<������/xig����^ao��.Dɦ�B#����P�;�̄ӧWK���y�]�Q�J, PL��0'�8]�f�K���ν����k�/)ˊ�:�	�}w�W\E'�K� sM�h�I����z
�s�hG/��Υ6д2|���}�!��!�"�у���?�iT˷Z���g�TH������{1������jq,9�}��-� �ʊ$��XB��^�S4�Iݯ�}��;���C�ZAks櫯�@n!��Q�2�1��NW���f�/N2w���R������Mx.�(~�	��6�|���Q^��# d|]i�r�'jEJ[�	UɲGb�1�Y>7+�~^��"�q6���Ʉ`�5��#�i�����/������<���o�d��V�.�4�Ł�K�-f�� y�A��{Hm:BE>�>���+���"^� �B�b��tJX��	���Ê���aH�9�v��2�A��~��BE��Q�
��kL�or�`nUj�����F8�[b���-�k��o /z��Kx�!*�6��>1%�{Iė��{��_� �����@I�5�����;N���[���0P�'�96J@1��ADކ����`�%�-5��l�)G�?A�L�D�D�����j�d�Ţ���J����+ub	�������b��<� D�Pk>��W�����?�h=����J�ײ��y��ne����a>���¤u�@c�{cӚ�p*��X�xQ�O�+hVܶN����s���`M�h�C��촗�e��Ä�L�?�{�e��.����QQc-��������+�������$��zh�~���|ƽ��_f��-��@܌ۤ����H���M�|lP��
�bfA�z��}c_[Uh�j6��M��7��	$7�L;'���pz�k)x��.��(��F#.��e(w�댲�d֟{kJ���r^����+^-f?��0Y���
�����}�v�ǳE�EC�:�͙J����Qչ�����Q��r�H���������f��7\e�e�z���r�3��lg�g)|�k�^p5Ŗ�)#B�&a|R����n�/E���<�J��b�F��v�<�UE�t��v���L=[t��l~s�O��%�V��xS�WkɖN�k��+f�;<K��b�S,�����̽3�Z�l�8�#���I��q�5�Y��$��7s�:>�ΆX?݆U��Rf�]}2!ɍo~^�6��k�9'����L���m~�.2�Q�,j;����X"ܜ�I�(�g<��v>��1�G˞�#[���6>�׬�̱��L`�"��i�'^	D�|�i��m�xrh�;\��b4@�`�6����
�j��
MѦ�:��,ݦ��4n�u�JQ�\��� �=Jݱ���-����Q��
�C����@0����������(-{��<m�����hp�OH%A�ya�ӨJ|��S�i�4LaX��z�d�6��V�EV%��ٞ��JswwJN��d�XH�]�V��[jդ�b?���ΰ���>h�y|C�1��i��!	34)��z�v����5���8���E[&�-�.G��B��o�4��A?B���5�)�����YF���������r����o&���r=T?��Ѻ�r�T/ �ϛ���6'ɩT/d���ҥe�O���yW�3�z	��z�����մ�S��)#�
��ܓ���	q>Ӕ�,]QP�W]�R����Y��(�ڬ�t��E�u%�5=us����UX��<�W�BP:���e�ˏ�2��+��a�b;�e���a�5e8�~�ʮM{�t��TU��8��h��$�'5���U6���`W���'�����:���tA:¸N4U]9�,n�2GSr����"-��m)���$����Rtye��.\����0�����n���kT'ee����rIpp(�V�B�.�td�X�m��J�cv,���Yy�x����aO��S���Y�/���UP�ۧf���LB3*ZX�K|���
�T�<j#����F�޴�V����N=U�\��",�8�#���_�$�����J���@ ܐ�q_'O`NvHb.v�E�VT�n_�$YL!�8w7>�]O��6
!�[}��G����q�?��RJ4�K�p��%`U�a2a2!a_%�~ ��l,+��z�s�Hš���tV��( :���bt�U�&D����F��7I����KZ���
�Z�����K`�>�4 խf���Q��%j���E%͢,�T�ku_7�Bj�w~��"��8C��w�nC��j�8��ӳ���_5>�u$��QP��(�/���+݋�Z���u�D$%��[lmԽZ��b[�g�M���ə�b���i�Qޕ�i  �V%B��� �����LW��g�    YZ