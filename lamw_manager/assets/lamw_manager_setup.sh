#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3891924326"
MD5="70eacbf7b1caeeaeac4c4eca956a4d7c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21216"
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
	echo Date of packaging: Thu May  6 22:22:39 -03 2021
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
�7zXZ  �ִF !   �X���R�] �}��1Dd]����P�t�D�l;��La����l\�$�x��
�\=��r9t�qj�Ri��e�46����p�W�K��b?fƅ�D���Q#��'�n���w��s�V�z�5
~�����|��>[v��А�c�<��n86W��Ԁ��ƕ����n�8g<k�u.���;ؕ!�
HY5Ȥa<�T�T _�q���U|��~���	�S��Q�9�nU<��t���t�w�Mxt�v�df|�]����d{�0(S�R��1�)-ʃOdFGC��\�T.;�"�kD�h.
(9;{;5z�y�AW���K~�[�Q$L�w6a̸)�"@Ch�K�M��6]�zY��6�� ��\�Ē��\ߺ��~e���1����i�2�������s�!_`��.�uؓ��z��jpO���L�چ��e���j�j�T�N'��+��	�?$n";���i�҂\�"R����2�F��L&���sV�>���HT)��s��|Cv��i�[v��XL��B�0�������W��I�z��U@A��mB�|�I<��2��c��?bE�J�&"1�l�tR�Ó���1+�zU0��'��@�:��4:wڂ ��Ү/�+ԗ�Iw�О�7��"&���ոa�0?c�){�M��̒�9B�8a	M0H�6fQ�Å\PE��^"� �N�_�/MAI#]�_��P�c:�%݄%_$��h���/'�pm@�T����Z9ڣ@(�r�8g����D����/������<@x�Kw1Sۂ�U_�/�&F���U���&��i7EW��K����&CV5`oY|�k�-(\��'Bx1^�ʶ�Lh�E����+lg�4a��d���Q��a���A�.X�*a���=�'�����<Ղ�cSQb)v�2.�������z��:��A�坢�z!,����j�a�&M�e��<���^��l��H2fGvjI�J��<���u�ꘁ���L��dIl3#�HgR[4|sG_0�vin��
���X��V��nT�s����;�p.ӂ�E;�z�6^,��@��|!\��F�7�נ�Jr�����x�zVn��Sݻv|t��l��Q���Ta,�cn^����cf�q��s�!4���@6 ����N�Z�Xp���*�&�i;��x�޲0���
�u<lC�rk�״�7�%�Sζ��P=��p9�`�:�6��>� ?l�
0�괳眑�v���%�����_��,�@8�Z�:��\����>j�h����5�HHD�I�y�]����=?͠�@�;$��+y��YJ��^��5G;z �Уװ<��8��o�街s�Eb��<����Wb8�c�� α����RHv�b��|4q}��S0�����nx�>]8 ��&jcP
pe�lLf���|�M��i�
zk��F��{�q�ZS��C7�B[������Oz�o�m����E����m�pge���O�;)}@?���j�]Or�$)waz4�k��"<���1#b��㍤ۉ�l!��CoN2_��_mT�{3U��B��/�`"��9�d)��7yl���3K�P���fA��ӗ��V>�(m�6i=������aRb"E2�O���t0W2�ĨgE�g�E�E5�F���,^��0��`��1�K:xs~H��ʊ����+��l�C��� ˮ|�ӝ�;��]�)E1��A�>Z�B�՜r�em^�b���ER�_�2������Y␉k$ڄ��~ ��vB#��[5�@4�ZK��B��YA�� Ҝߎz�;���Z,p B��fܶO;Q�X�jV��Z��=���Y�=�����*�a|x7�zyrGB���**nim_*�$ P5ڂ�*�<��QNa��;�
�n��� �o���F�%��'�w=J�᮱]S�n��`��,OǳT��Rr=�A��x*��eP�l|�+L�nP=6u~���\N���t̋}��O�d�"�i��&����,��Y���{�}�����N�gޤK OM}�>X1p�LeEdY��'�ro���ٜ���)��5��l����������K�"R�v0L;>��yRm?�^�Q|h�J��>��ı6��^��4�;#.��� ��eM�l6����4�8$%��	]�Ss��D+�	�>2���ΑX���T��bL�>�33��v����:���3�4�M3��Ŷe��������f4�]�)wL���=�CDT]wN4�a������}�+��uǒ ~k���G�z��=�)��
�����.��WGV��I<�|�u8��}+�~u�����2������(��H�]�d��Vk&eMJ��h�<#�|+��ZA��Q�{���U�f�`��9��Ts.7@�!���p)�x\��,z�?Q:�lqn��d���=���&�b )q�\Ģ�����&v�`��E[z6�P�RL�:y�0y(�����w˖�}�6�S��`���YQ���Ք�H&F�~�m��j��cZ��e��^LͿPfqU�-X���(-8�fyK���zӈI�y�A���@0�M�5�����Fa�w~dixU�n�C��Rf�t1G�}���9�B@ތ�:l���o��ǩA�Ŏ�®�ǉq��eҷ���3K�.���t���H:�H��H.��dJ5+ix�/WWE	�*)�k���Y���S�vm��g�~�R���g�b)ئy�U�N[��>�L(� ��ǚ��X<��&�z�O:�^]�H�ao0�̅4�tӕ߆1�]��:G�Xn�rn�.2���o;]�4��m�� �p^�X���#�&�oM��2�}�I#�<�|-w��r��|�3i�}�C�
��I�{��m�`�c�<ap�$aQ����E�˦8�R�,�i�[�W=z�vr�����v�Sf(�Ǒ�ih4ĝ�^(|ٽ�:��*9�籾Bzx&v�%�`�\6D���$m5����&�d�_T�#��`9!�
;���߭8!��إ}�w�脺�ZS����~�I����'eV<@M�0����t��	P�f�W�H�H+Ly��Q �B���Z��}�=h�������@>g�Ļ�^�	^n����>VЏ����(�^��´v����Kb�̉5c�����
y���K���w	-�Hج1`�`[=�dMt��7nFBj�Ơ���kZwzbh��o��j��_a��.� z�q�D`�'ze��������Oѫ����޾�����;���6�]A.)#p:����g]����I�#�����r��	9̠�Tk�?#��m��|]����� L)��������Jg�O��$o:̶��s�	��ط���@h.O. &��W�de=9�L.���\�DZ��X4>{�����iӸ��M�y��b*����6'�g��VV�!:�"�»��=x�WyȔ�C�AxO�UCU�z*�u��y5�]C��S�Y�K�5M�es:�eI6��.T���3�%��m�}~�*w�V��*��WJKs=�z�������w��8+Z^�C
��ꓤ,�T��F���d&(��P�@3i�ZߎQxp6~K�A�f]��}��D%�G��q�u��yT�}<����LC��1s�9�>6�Q#}p�w쵈���̀�{3�ԋ=��d�%m�&��Rd�@��3��Mt4Wz��n�w;�c�}=�rD8��G|��_��	�E��A/����[��7v{������<*f���Z����m�ӆs(�2&J�� �`l�4��mX���Y�ð���v�J���X�k��*�*uCQ�ra��a��:dDv�\�O8䬊�fx颉�y��f�C{|����*��JJ��hu5IgD%}��(�,�����}K�MrӯM�҈!�H�AI#����R�
���0���Yl�G8{�b')���:�?�K[���~=��)�IJ�-֤GJ?���j�h�LC�^#�1!>T tr}�r��ǹ��r��$
Џ���1n�}�p��F*�ho�L���`�R���AO&b=���g�WQͽ Z��'1^�gxm��V+عr
��8��f� �2�0i�w���5��1�-O �c�.]oAю��+�U'E(vy��Λ�3ȓm_s�	��Ľd�$��a`��g�d<�LL�!�odo97�^�U�Cl��rC����I��s���R����#Y�& ��h!j�co��ְ���!w}�����	%XÀ�Vl�w��۶"��"�{ܬ*a�����$|�嗾���b��T�g3���q��Θdk.{�դ#�7l��΃!E�с&8P*�L���bͨ���P�u2-�p�~�����U[�B|�Ok���Te�6�Jl�(�]���H	 �Z�����tK��J�Ww�@"����$�HN���)��EE	�tM0�!D]"~�d��8�p��R5%�#Vz̡c)I�����}+- ���e5U���=_�̰���T����3t?qp�&YK��O���Rn��F9t}�q8 �&+�Kg��~N&k�ގ7��<�2���ĺ��D����Jqq�%�7lj�W����K����:<o,�$7%�RDG8m���o��MT�=6���\~��g2�A���MF�ē���L�3�W\��v1��03ر��#�S[h|l,J�4�&b�-��jx}H0�3��b8ۗ��92�V�F���O�a�Y 4�:�)b�<�#�X�PK�zs��ŗ��Z(BG�'k�3+���I�C�Y���z���?+6ls�z�͉)r{F��Q�g���r����f!9�6�e!�B�f�������.�r����`�[�ڢ)%�r��ɽb�6��%�s�'�;�}l��ɀW��`V�)j�M�<�)����9=_l�T�i��p>��sM�ƿ��
3'�3�"�~�_�$ ^w)3���{!�ڼ=%��#��k�kpŒ#Ԇ�	�j��k������Nb����E1x	��;�~��M۬M#b�tYص7��Rw�^=�W�O�T�F���eZ�[eM���
�[�{��&���ɰ�"�#v�!���	�"%[���O8A����+9�%�	� �酯u:�ʱ5�A�v�z�Q൬�n��(=�;�eT�f�^�m=��WCZ�^2o`�m�I_�UMU!�N�NCf��9��tv�EJ���v&���t�}���� �����)�W.�+bg�|R��:��禾a�R�^Wr�[25F���4��������Q�i�t%��W�1t��un~�M��9Esf�vW���f�&Y����,�nN9����� �)�Ty�+�h;�ɍY��ĳ��L�z�Rr�CX��<�Y�� ��z�+K~51I�>�^!�[)r�̆��{�x���G�$ޣ%%�Zy*J�A_o���$M��a�����w�H�HI�~گ�"���\3���^������W�/����ԉ�0>~_
5����)O(�����m�W�D�0��^�sYɯj@��e�t��dK�I
[�Q{�=���*=b&�o���h	�?�ʍ:�K.�,�cLd�o<JѼ��y���)��u��X���N���pʨH��1����$t�!�e��P��zw}����9G��X�1.E�.��?!HQ%C�P��h8���?]�Ny=!���(fۣ���Z@��!�V�š�g/n�cưi���Q���V�(���+���V��c��4U������fj��C�ǘ����Q�`�hi0�O�����4�\H��q,I��D����`�V�W�g��9�3�%{z�1�F����=���`EPa4W��r�9��"Z��43Z�)׉vX�b�1W�3׼�	�U��5?��H$Ez���{#�A�PE���@��I�I$E��vqKH&��B^Ƈ<o�y�Ŏr��o�П����&V̻i�2���F�:ɿn%�\���Ǟb���Y�L����Lr��)�j���SM�>5�`:.��/��c(!��(�[l�\�F4��|��e����`�$���oq��Q���_���ܼ3� �s�))t*k/`[�%y�@��G9�>uDNp�b}������ǳ�c2��!���B��r�%�u�ʖ6WX�0цO`������;d��^�+�m����k�b�@�����'�� ���9W3Q-A�Gی����OD�%���0��\�yhv�����D���S�T��3��<��(w��O�kL�;���4�-��#�x/����me����X�˻rB
3�X�Ft�?�p-3��XRϤ�3�:��d��h	~�K� �U���Z��ɉ{�y|�ݲ�SّCqg�N(��F�����Abv]N���Z��2F�#�P�9�ݼ,λNZyJp��������B��wi�����Zw3�ѝ��Lث�H�o.?p�\�"P}�oC�\�,I_�Aɔ<PI�[��0i�R+�T}	��״>�1�m5�@m;n������j=�Z��2�*'pИ����q[���#���J��!}].qo�ia.G̢ԑx���V�j/	�O>��@f>M�������qY�-��c��a���q�o�B{jS��#l�������d�*@���i8��iJ����0��������{�C��E����T�w���Q��MZX~}�c3#�`��,��¬8���XrT]�����~�4^7��~P�CQҘ܍���gJ���zQ#�+�R|f�x�'��B�W�|o�鮓���Z'F�l�7�&���ģm��_�o�U�g/c��wX�q͒!�yd�����*����25��+o
�ݘ�~����e��XQ.����v*_�l�0'?�ߏZE�g����Z�w%!��Y/j_q�;@6�A�ysf|XȮ	bB>v��β�ͤΰj��C���\[��C�N���7���Gɱ	���d�H69P�:��R��j�zVd�J��߈�&/�uY-� n���bs�%�3�=� ��p���mSB�E����1�$Cp��7��;��Z��oU[���x��s�?�a�o��X�V>iU��`Pan1�Aic1�K��;3��{f��A�*lřd�&���۲p������`���q戓XX�����Tz{�;J,U@\�����fTT�a}�Z���c���{V��7r(��,��NJݼ�@8�˟<��w��w{/T�O\
o�\�
�iodʁ����	��Z����b��L�pI����/bNT 3R�A��������F��7�$D����I�S�Ϝ���������;��c<���e+;���3ӊO/���CJH��,�f�n	����޶#�$u���Z۩�߼�c��bߤÉ7o2�oU�@���7Ź���"�&d�+���JA��-h]�7��P�?���� )	)+e����n�[d�B�{�-c�d��+D��v(��~Oi�7�#�qR��;��4����U����j�
����6��n�RiL��2����{�u�������]p�?�K��%�!�J�J��ً��=�1BHR���vR�&����'����#��?�Q�nf�̄���T`�4j�btJ4O�؜�{�ì�}��/�f(�d�N`�r��g�6���2=�A}m��tTJ$	7>˕��~$����z���ۏ2��zɢ%�.�����S�M?���ep?�3gnϺ���r�ת8������nY�E��\�}���eS��TS��;4=��Sq���ؑ�V����3-j��d:�cbm$r�Ga.�]+�0�@���z���e���UR�Mb���@���:3	�~��&df�:f�w:��m\��r��dW��c�s8~���A�U��2�\!=�_2/��|��5��9n�:�5��^[!֏�u�^���3!�}�`k2(�P����u����<x�����?8�e�l�q�{��AIC�;�j�1z�0~*4S9`�ES���E�ƒ/=vb�Ǆ(���JO'�&1�N:G��j�w"Hv
�cp8{���@l��u��Nh�����^p�X9��Ra�N8S�>ιl�WW����geU������6 �g�Xs-kbt~�Q��LE�Y郩�DJ���W}�xQ]6q�U0�2?���j���O=Q3�3���U���/���u�W��ֆ]h�E���OS�#��k%���G��=���(����I�{��I��ftt����vI\(���� �-PXK��)�*Z~U53��̱w+r��*J�/x�L��;��;nqo���eކ�O�����/߲�#�[`1�v׆��U�OlӋx���1na���ѷ|�g�i�L��X���+����:%���Kj�@��I?�=f	����r���5,����ʲ�M�o�{���q����t6���ak�֏��B���L��5	��J̹��_�U}k��yݙߜ��u@���+����m``8���P[`��W�㈛PY�M��������Ӊ4B�9�Z�W��?�k�;���5ή:�g�p~�S�
����3?��<# �PQ�ZqH毩H�����f=�G��k�Y#�I�	� ��w��ؚ��G�&͌�yI!���9,�1��XwQ���wta![���[�������_ڥ�Kx����Bu8�3CcX8A�e(O�j���l�';K!3��{��%����)bKf��Fq���AO4r&m�Z0�v�+�;t�ͳ��㹧���e�C����F�)AP�z 1ꊂ3��?F<�T{��Řc=,�c��u��z-c�t	^�!��n�㋽ȰD���(U������=�`���ˈ���]8J��_�Fʳ��O,��-.�=@d����>^κ.��-���;)j���ӎp�d�[���j
sH0���萂�?4�������3s�Z���[wn�0o�g٠ۄ��?j ��+���*���م�@��. �?���b�}/N�q?Њt�þ��}k���E�ƈ���:�����"�Z�-&��NA���1z�5��6Q\:�JO���=�	������˽��ܨ��IJc��w�`}5�-,��-54ՍP��~�+%d�_�#��<�G�Eq��Yk3t�������yH}=�	�C�Y7'�Rs��ؑc(-sܾR�t �-�l'ϭ��<�ywio�j�l��R7]�Ƃm�ē���������KC��'���s���Ф}\�o�l鵄����H�,�H+b�$2�u�� 4��|槐[��R+|�6�(��"�*��%��y^c�UϏ�~	��|����x<j�Ac����lGB��̤Ai��O�cKvc�Q:������ �E˓�3
�b4n�eɃY��֑L�;��0�|[�jF�pA�DG�}Yג�a����[�hL*� �Qe]eȿ��9��I0�,F6[������D��<�"��-�v��4�tl�q\ce���HZc��uy��U�r���C�����ܛ�B�tO��ca��@s�9iwcILId�B�N$w�﨨I��#E$s{%�9N�o�p����b5�gv�#��E������ǟ�G{��9��_Q�Ǆ�<�Q��c��\�>i�"��,��u��<��ٮp"	�ݺ�w�]�N'��X�-m���2�*�pJC���Z�|ONE5�������l'�u�w�AXJ����H~z��P+��x��I�S�}�YbYu�v���P�,����UE�ݣ�O�.�:�:9�Gq��]''���E�����=:��|�@��q�~&*a�)�[�t�z�zY��~_<:���� "���T�R�٠i\�d��1���w�`�=�E��8x�2�^=;���ױ��-fY1���'V50����l� �{TՃ��vQ�b<P������]�Z	��4=��8<�׃^>�� ��Q�&!�!�L7�Y??<�Y�<���m���V��9^���֕	k�!Q;���G���(�����Xs���e�;�ڷ�0��F�f�s0S�P�~L�0ra����	Ϗ)�Yy.�Tl�2c�,̸�54��K�bf�A��B;����E�VM��,z�d!��J����>�d�N���Iq�>o%3�<g��q�O�1 r{1����:v���'���N���ƅ��j��>)ҙ��b�g&.%N�0�[)7��4����vּ.��@�Hc�[[��03B��EQ�)wk�d��[��]���%����>��R7�G�3�����K{�u�D��n�>��
�Q��mjB�(֪T��m���df��Qm�_U�hb�:u�j�B^$$�@A�m�(�D�%��>�Ȩ����Ǔ*�����8s�\=@�j���tS���@�,���ղ�I&P6�ҟAu���0�'�<H�Q�D�i��v?�[�n�bω�ڞ��#(V��/C�Tv�h�ޓ��!�E�8�v@�R����U�A<��Jc��0o#��g�J��ǁB7�����+�{��T��J8���["�d:I���^�p�
#�'������~mYN������G��y�iϫ�[����R�ÿ1��iQ9��*��[����4f�:ØU	0�edЦ���V�!�O��a�:�!��>�s7�Z�����N�s!c2C�Lo�(��6FUQ��jRՙ�p�7:io,���'P*Ky�=h�u��wB�<�y�̎�h����d�^)_;L�|��=J���J!!��[,�Sa?�5q�ЛP�\}Ǽ��-�
Zl���_���x9O�>��ش�\3ɣ���_U�7���������~�I�0�7�����("��Aq3�w��4i:-j�.��md�t��*��"#���I�� H�kQ06F�ʀ�CY�98��.�n17��,3�8S�Ȼ��.2y���� VK�a|���W��}��~���_�����OHA��� C��Vm���+�l$����_��=!�"��4c�����]"?����Z�܄�S�	{��I~�h��"��o�h7�������]"��~�ݩ�����$���HHq[�Eo�;I�X�85������Ϊ�W:�'�4 캸�������M��H%j/K� �n��di\겾9���r�����j$��_��K����}<��n0��.�sڮ]r=t�h]T$��1tFe@��tT�/������G���?��a���MQ,�gۮ|O%Ekd>S%��{_�
W�ık��c��c�F�pL�}=9�쟃l��z�7'�L��I�g�(�����w�ǎ#�J��>�T����"�)װ:�W2�@���0 ���ǧ��2���Y�O�DjD��Q�}��8�.C�v'��"%�
[�3�2����yR�H �Ko|o�߂9�����'���`g��%7:h�H}Vj���k�*Ot�����D]��rŃ3�]/�h�\��M�5����2OrcOI?���{�܆C��`�@���j��`8��iI��n��/5��6B�M`E?�z�胅�����>��NMO �ZG�lr��kS�����$5^��,��z��I�ơ*���.i��=\ÿ"1@G p�Y�V5*W���[��O�^~�޹���Yo�E�J5��K>*~�	��?�fe�+�4Se��`�2W��j�%�Ɯ���X�+�[݂�(j�rB��}��֨����}��ߜ�2��f7ѕ�|�V�x���S��z��ey�7�{K2w�ܶ:gj�G��1�:��|���/9d��5\L,��׋[�v�_� �M�k��l$kJ����܀�e��jT^�g����N�U��,4P�T>=m}�|��d�:����=��m�Qi��kx��_�Ga|�,L�32���:��+��S�$Y�~I��kDu��j:�o���4rA��.ݻ�r��b��'���(�N2~�rL� �ޞCq��IXM0�L����ԚGm�uA)�ӫus͂*?G�|s�O�D�ױ졘��1}������&�0gk�'8�
p�.���5����W;E�����sMYQ�ۦ��}�Y$�(ґ2e�_D&v��;d�f�����	CI��wƴ������<{��\��%߬�ީ�"�Q:%�f�� �G���{�]�.j(�EVP�<������� X;����d��0�U���w��l1Ӆ����U�狛�.��̻�� �kͫe�R��s0��ɝ"~��͡!�����xq�[GsD'��ʇ�h��ڳy=h�ňT��)mLT'Xi7�*�`���\Ƌ�c+[�6�^��T���V�ڎ�e�����T�[�~Rn3�H���)���	o�g�PL�j��9�iv����<��ְ�9�۹g��>8x?�xA���K�4r>V�|�d�ß�<F;�����j*Jk��XԮ�A%hmd�j�����6�^g�}�f�T��qrFnp��� y�P׾P��� �j�����X�[�p�-z�K������+��z��*A��_m���n~y4v$.9]ɼ�vLs�=v�3�ּg�P�uk�;)����uP������
Θ���\7�TamC�a�Ӄ�$���9��z�,~��:�/]F��+s�S���v��k��G0>�b�Q�����Q^BZ'�T�Ɣ+���{�d�)�8y�M����ONi:�:��@�%�����ӱKe����T{�m��2�u}��$;SI�K��j�~�!��5�� ��Mbo����y��|2P��|��C��oO�ԉ;N?�<�E2��P��@���7B�R�:�-�C���J��Y�k��LW`�qS��F֍�BI���N��\�&LH�.�/��
�l�yR���T�PX'�-��!��ZsH3��"����!^��9�h_���uy���TL�F�٨zu�U�}���-C9%7�9Z/"����_�k�a��������d���f�$~|@+���&Y䶸C�H�e�̩}�^�l3���Sq�d�6B�v&�uέ�����XL�����!��*��|ǂ [�ڔ�fwddEQߏh�eތ�?��X�ް��0�>7���� 4�A�O��J�#x���P��7y=�j�h��%��(%�X�0����t]݅D�j��83gwU�����+D^��t���$����a���V狌t#�����C�ys���H���u�������(6}�/��,���;9�\cn�K�աi��\]#&� �Q"�ƍ��8���+�ݩ���~O~� �,T����
j��jc60+���j���|�G�h�e%F����ǂ;(jّ藳���+�L�"��{�#hG:J@U�9�E,y�+�@�x/�hJ�2����96����<Y�C	I�n!io�p"�7)�UGz>�^ʁ�\zjX�Cg��J��@I�E��jLH�io=!�I�"#2�>�����W(ka^��0ɝ"�}h@ˊ�˵��WIB;~0q���r�ze7�ڥ���FLBc2�����v3&�r-X��{���r�-?���v{$^�Su�ڬcNa�M�d��L���)Z!Y<9W\.k��is�ID��ӵ���#���7q�����cZ���_��(<�G�0�w�N�iԚ��Fb����h)��'�t�ء��:�H8>d����2��Z��ۀ�U1Z	1�T��жzU�ʶr?�E�052��i�)����,��M�
�q��H��ҫ�m��K���@����e�)�ͅ�IYՒs��]o�>�$oaɷ�T?3�+����^a@ܽ�K��\���x����;�cN�<�	e��)N[trqp23�2����~��a͍��iyp���d�:�~]�(l�����	uo�:�?�G��S�Ts�ٰ�~� ��Eg�@Mޢ9��G7�?��[�c��H�<=����rB��qp���K��1�D"ۻ������4�1�ԖV@Z�<{t��L�<>�J�>f���^�Qy��\�����fu���y�A�a��q�����.�߫��Ն_�����B5��5��M��/����4��"�1!��#�up\M0Zt������5��%��Z�H�;��X��.�g�Ƅ��Q����T��q%z3�Y&��)p�W2�F]���PP��\z�/δ���I��g���@ί��k� �b�N{m�9����[��2��#O�����v!%�,;��+Y�{�<{�l��1H�d i���+x�l��c�����. L�9���h;��`� F5f�7#K����Е�n�t��LJ��%�c%�r
�Y|]�՞X�H��s��LӅ!
�����+�L�m/��7����/��ף�I���h�� ftVN����X20���3"k~h�	ro��Ll�i��҈�Wi��-�I����q�"ܭ�֪*�ZD��3��g-���B����G�����CG"��tJkD�|�㡢G����X��֎[S�������
�)&m�.bg��!:U:���)\U��w/*w�a�>�@$���ݩ|���YLo��AJ�O)�-��MJ�E���Ҙvu�@��q�U���݊�eJDC���L9<����U���Q�@���*.^�1�%�O�P`�9v ��)�S[M�!?�/�q�S��+)2�+�uG.)��m��D~�e�6���7����h�0p4Әi�N��k�6f��MM���1����I�R��w%�>N68*.O����cI0���)�8 �)���;h�z�7�)7J����_/��L1��mآ��@Qbv��i��{	�
����H(.���~p�7��ZP��zazp���ڔN��C��������^��(j�Sx��0���ꔥ��
4-�������4�<	�L�h�kb��e��=�p�
���#�$�73�jq�*d�7��������@P��\�]:����	H �k0п��@��a3�]��o�IQ\�����MfI���;S��7z�5�`�˂z���w`j��E�WA�o�`�(�^^C��wC���#QJ?lb H����Vw3�8�"�tRY̋Q��v�CD􉺒�e��{ccKg'�k1�XDevB2�z�Yl���Wλ:/o���L6��|�Oh[�z�$S����L��z	ȁKo�R���$7"�cC���� � '�䞸��}-�8sd�a��!���{J�H��SV�K�/g�G�^N�����A���k�������F���fF�"r�^��:Y�F��D�^L??����F��
W�d5j�J�I�7 ��Ȇ���Q��;+~jUc�7�J-+Dͱ	� �'~�rp��G�z8}@6M�Ym�_��z�b��g��i"܏��Ag//��i����xo�A���x��fb+����\�\fQ;n's�oQ���F!�G�"�=����\ �L����|�z@\�1 �Drl���� 9�R�g^-�ᯈ�iQ*l�]I�5�m��s����R h�J��+��$�6���?��,Z"(��g/4����=�Pg�+�Y��%��:���ޫ6�����pP�h�������wU4�K�(_ei�-ae�I�A��!	~�oO����O��	@`0�6��.�[`<�]�QWgXs��xXl9ͽ8�`�S`���cA�aѺ�}o/@ݺ�L������9wU�g;k��"�H�=zhW ��	?-�4L8�ҩ�2�����񍙋q�w����YT�e�.�w�]UQ���j�+"�Rv�I�s�"����R�J�s�0ƜA�C�>2����AzoK�<>���ng0��������?\���-���������.G�v#ۍ<��D��;ޣq������:��/n7E ,.�s}��!�1�\�,G$G(��j�l˼e&�.M�t>���C���D����l��8\�i���b���`4�駥䧕����L�wO]�����XI����ZR�MKĚ���B�LIY�m��I��LsB�Y
"U8�N�L�b{.�;Z����p�����i�O)E�՟E�m��Z����FD��9���pR
�<c	��u>����cY_U��"��g�����&�P�p���'$�Z
�� �x)8�Ś�x~��+c��Q���Nāo)�d�۠!��Ϸ������fWu��Hw5�J��2��������#��Q[���҄��U�K�[+?@��u��˞�O=$O.b��h�Q�o�ڑn��RjԈ���,��􆤗�bB*mNB�J�S�:�$�S��Є{BW�N��17e����+H�A��=?-=4�]rBF3^���!�e�
�~�f��E�T%J2�Պ�J[����<��fdr��լR�U]��>��z7�$�&�$��uB*��&��<��yY��8 �3{ЍŞ�F>ahz&7X
ܶ�ec��?r};ɠO�D���>��� o��O�#e��u��Q�usC3U�$9�ðSz�#�ﶻ ��$��^N�X3��r��^_��:�_��������[�h��qd��J���XX*2�	]B�oJQ����c �e7q:�Jw7[�Bjq:�n���Q`�e����]ݱ^�'�\�����me�����7. l�>�hGf�W[���q�N�D�lh\�A$0��cf�>�(��y9��ZK�z�@��$ں�ϴ��B��s������ǥ���)ɻ��5���+u ���q
3JP��<�a;ZZ��J;kM�u�c ���X��:}�A��?����j?t��G�����:ԭ� �H���.��
��$�2C���<�(T��IMA8���a.絵^�6�퀄H�?��m���O8������v�������D�v�=F)P���_MC�V��2�ǞB�;�g�e��L��|0�Q�yD�#�D�DL���$;>�����b k��t=ʦ1�Pu,5LÃ*bX1���VHN4SDZ�ƧF=[��Tl	ǗQ>`�5�^�hڮ���m�)�SZ�R�w)%����Q��|�IyY!�0�nu�%KS[���H���/B��yx�6p>gv�]�'���WJ�)&��Q�_�ۤ#<�P��2�#��b�˸膺L��~� b����͇�|�1N^H��q��'�+-�/'��l2��~����AK:`���U~Z�XVt��q�ج=az�X:b@�}��A�ffVWوɎ8���.:cֳ�5#���P�;d�΋DQV�$�ܢD^M,F��s�r��n���Z!N��="��1��]��	�c�$}�V�pћ/�^B.OF�a�-��H{��l�$<��|x�W�@�gQ~��	�cvVY~q��J�0��X~�41v2v�rn'��t�э��V�Z|X�񀒣�_BJ��1o���t���[^��M<�!��W��D�}{�@s.��.�b:5K`��7��e��hh�>��MOJ���>���'��:������2ӎg���B��_�U�9��>s<RM��d\La@>0��X����4�$ր��M�SQ�s�4*露$�.���-r��X<��Em��
l��:�����nS/��ek�nR$)����1�v�m-/���uX�¨}e�8^	
Fy����I�-�$D}����BxZ9�n��s��/�L��Y>Y]͚_-�|����8YV
/�Qj�p&I���ґ�d��89��r|^(rCx�ز�Ɨ�m�fX`EMv�<[�:��q��$2�Y���D�x������_�݄e�H�\��t돱�
��nQ��vq����;������Mx�z�R�w�-��,\��T88��9E<�	�$�oD���V^ǄH�!�\>	X� _��]�Z�v��̚���.�˟��?mj��*׵�-�h��_���]a�Nn4i'J1�6`���������6頎�D}]��FǢٺJ9%�Q�\�׳d磦�W��z���<����5r��-!�CπI��@�G�c	7JT��؜
�����Jc�CO)=m�@���r�����(=��-f%=hj�V�}ɴ�ٍ�̒�̏�2����
5FāS;�@�ċs�y0�ʣ�P��i�I�3&ɽZK�WssV�0�J�+���rHE�@KRM�#�h!�j%��!y�ǡ$�]k��V��e�NdQ�CV�Q��v����"�`&�0�4~|U�.�Ny�y�m�3�����s*7[TԷ oe= ��
��g;Jς�͞�}��*�㛟�����^	l�)��L�l!��81@�:p'�����������`w�H�_�)ۮ*�QC�ĽNO�}�����[����@��1�
�v3j ����� &E�o޷�(o-6h&1�ͦжb^�hH��2N����w��E�n���69��a��L�o��)���Q6�E%�~,�Z8�O�1�X*���t����^�$�G�>��z�-�Rq��B@�������`�:�H�cH����%�n��/hF�u�t�&7�G�qP�{��$c �ڵUK�R�����7�ݑG]DE����+�W�:��A&XX'�ݱ��L�O�`V�Z���~MJ����H��$�ݶWA��$��p�VM{?vc�{��:#���έfk��v��8�<b:9Њ>H(�6��"���JG����d�ܧ����LW�gv]+�BD�
���X��
�6�Y�T�N��þ��`0&^����K���">r[���)��܆M�dF
5`f����v*ԧ�����9���<���,�wx	�Ւ�y%5Q����j��y��\�^KJ7���znҚ~yԸ�},
-��{����?]�!9���Y�����(��X1����UZ.��a�nN�5'%^ևo��B��L����^;4#�x	�*�M�pE�+�]2�I�������L�#�AS�Z�IT��v�	D��T_��N�4�7��V[��s�]OXj�V=�œ	��Wx.+�r�.��7�	p#���<�h�,I!ئ!��X�Қ;�7o�>�RYEiΞ6�*v�Z�' gs��+TP����2�ŋ�m�<=�s�xa�ds��]yy�7�p&m���MGil�|su�~��ok k�6]���Zf����������|�LoBns������X-��8a�O�ҫ��	E����T���&fq3�'��	Ca;�M�O;�}>�J�U���_�x~,P�E��3ۛ͛��7����i5�@j�� {ߣ�&qV��6f�6)�1�P���Bt����N����r�"�>�d��K3�S����m>Y��F
e	%��V��E
���7t�=�:��a�:��EJ��l��sz{h�AE���>��,����m��|�LOAB��A��*~��^]i�9_���/]r��M8�ѹ8(�މժ�Ƃf��Ճ,�7�!�i�ӵj��'�9��S��q�JY��}
���|�� T��X���+A���\ �?BQ���ng�q
XQ8FeI����"���R���!R&��� ���]��b(	�"7?B���vcZQ��S�+�>>�ث�Ვ�G�`���=%��|��2X��o5�P���+p�,dZ*U�R)k�����=%�)�(҉�dZm���&HH�g���K2]�ߥN��hrW�ߡ�d�)�={��ܪv�F�S9�z��21 B��
�nv�b�G��2�āѫ�����r�s�fCv�Wj����������(p��P��P��1�G�6���̶ U[W�R3�&O_R��X�5+ҫN�/�P�E��F'��x)�wB�U���}@�䄌�-u�݁{��>����Q��(���D#RM�hp���7��!��B.��vM��_q4%���ND�g�����$���q%Q�4��s�^��?�z�j;
py�(��&ٸ�\"`d����[b�'�g<YQ�̕���^ ��Q�fg�wS��a�*�a���4�eT��C�I���I�1�%0f���@���˵���6�bSi����C��T��$�g��u$rt�,��)όM̄$B�dnȕ`�r���YA.lG�7�C6f��5Xc�$T��i� ����
r��(�$����ERw򕓥�:B*z��}$ﳒ'�z�\��v";��ㄭk��ݸj���"����2癘�^luw��h]ӫ�;��J�v�H6*I^��nVZ�z�3�פ��"Ke����>j�|��]]������B���4d�ҡϩ#��������<�˂=>�1 �����*��)����R���(�V�_&��5�"�L�n��ק�3=~��a��\����ߦ�:1�h������Xkࡋ��$+�(��z���)����5�v#�q�� B#��JG~)L\�;�Q�����a����	5�� &����Q�W��u��M��N��������H�z�>�b ��e���ٻ�a
}�kK?���T��0�\�<�p�ۀr�����Ø#�D��2+H�a��WK-2����4��$��tcBy��0hp���a	zAd�T�7!�f���X&Z��T}�U��z5O
�0��*q��-
��RF%��NȽ	����*JVU*2�+��E�8�����
��'��G�JX�����qt��� ���F��%�Z��Wex0�&�a~R6�S�-<����6�����P���R8�Y���,{e�Ml�b��CZ�1Ha9w8X1v"��\-W]�͠��6�θ��.	[l�Á��lIEKU�'��P�zo�{d�P��e�CK�.k��^y_٥��j���ٌ�YVu�����T�g�N=��@D ��Ư��Ϸ�0/�-B����4"�ۭ��A	�.Ǝ�>b�����s_`玟��2�U��|X�y�E���q@�-�ڰ���0�ĽF�M�;u.�V��_[��!eK�ݶ
�m����\�SR	)�C����,Sa�-�>�|�+��.>x'vp���T�3Β�^���	Ai{G���/����k�'�Q������:ʌ
0�|AMH[)�HB�'  =ʀ�D��C�Z*���
��(��7�    ڼ�AHw^� �������g�    YZ