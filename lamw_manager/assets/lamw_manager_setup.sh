#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3370265660"
MD5="9ace486c0c77890791752db0a0f0609f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24092"
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
	echo Date of packaging: Mon Oct 25 20:55:49 -03 2021
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
�7zXZ  �ִF !   �X����]�] �}��1Dd]����P�t�D��R��*lǻ�6�;�dW�A���9o7���*��I(I���f������@�U]��H��!��ӤbQ���M.BR;5����8�k9EOp���A�����N��Ց�Y��>�Xޟ��@��%+��1�n�g���B8��o�u7���
ɂM�,In��;���O=R7��5�'m�K��]���8�XpΔ���ʽJn��w��Hm���L�|3�/�|��N�f!c������'�i������I�;��e5
b���Q*�LeB�#�d�hE��ƗؤtJ�������5�;&T�[�f���OE8錋S�e�D<����\."in�p��O���K���=�3���1�i�['^P5G�h�6�M���Tt���U-RV����oAOx�A�m=\-�>� R"�/3�F
 ���C48���$:����
���N
��<0��+t6�j��"�6C)��o��@F����@���P��bc��ė��u �6�Htk��H�᫞�:�{*�#������N����mC����w!�9�K��̯
:��4C���>�?&Jz���H��6�M����'�����<j6�F�5Rտ�4(�
y��/�D:����#�h�qѥ���i�X����R���b�K������w>�9R���M�h��P�tcU��"��Oc� r��~� ]12%��vր��{��|�t�	�D�$_�3�X�����0!��R���IZ�i�(�Vo�8�r�܏�UT��I��/5��镪PW�./ L�2gӄ�Y�P��<�灌�-�$u�C�9�>69d�5�;�J�\��P�����?/
��Dۯ����A��W��/�es��"ʑ�12�R.���G����N}�e����뵸{��E������.�rnd�N��7@KO�5LN�㨯��-��e�,���C����7�NnvD��1���n���62��	p=,-�+gj��Ug�_��"^�r�}�V�&k����$�Z��s����nj�Z8s<C�-2qT��5�AB�Y�8��xN7����\�B���b�Dޛ�Z]-O7���0B�.q�����!�e*q�JV�Q��hY�T�E���<���7�/w���d?6�<oG��P};��'�bIs�C�70�[�>��Y�7����T��~���0E��v�w�ܺ�?��CM�����.:�xx TV�f_�z�%����!
 ]6��{A��O5��n�1����cF�#
�T��O��V�M9��87����1�< ��.�Zq�4� �G�SZ#Mͻ�N��A��]���������˹�/�v8�4��Wf�tp��r����~ģJ�ii�޺9أJCv~�2��B���V8�ѪB��>'���ц����[{�Vv
�&0�Ù�\Zt��c֘���BC�w�&QD�����*x��.��|*���?:��w��̖�N��b�riCB�/=��~V�z3�>��f�W��*Z�G��;����k�GÈ��ޕ�p\�X��si���Q �Z���I�	��C�R'�vl�57���D/�^�4$����8%T�,a�`A2����6�K����;_��fǹQ��[�����]bє���X�T��Fv� �U^���2��l_Ʈs�+��=^���*2��R��3S������8���w�I8R� �X�0Y,�9�v>�|bv1޹�g�j ��b#��8V�d�k��Ũ�ie�6��(9�{$+�o��g��V�1B�cZ"��IEv}�N\/8'�!}����8;@038�����:�l�����J`w�ѐN<�s�)��� �L�~E��*�Hњ�DZ��q2c:
��� 0��$�G�y5y�ȂH���5P���V�����f�p�����;,kʐ�ae���^��\�A�>poFV���Եx�K�ס|λn1�_+��En��P���CY�����^0��0
�;{'#
�Ů���lQ��|nD�7��&�rSX����j�S�!�I"��6	�r����l1���k�L�S��8�Lg!5��^����y<9�܀GH4�����,�[�ay]!A˸�eTĶ�k�{*!
�y+�KrFpwC��ύe>���p�m�����2�b�+�+�{�dw�CF �?�\M4���Tɛi��'Vb�������¹ݼkś6��^�����U����R�؍L��o�g�B!;���R��M�=�:\��c6�pF��]����G!��q6�Y��;�����{��ۉ7$��pZ���[$8�'�|IA���2� �,n��b# ���.����
,�
��$����I28x����DҤ�oa�g���"�M�a�˸r+L�V���Vln�2��?�xi��ζ�d��� ��G
����@���[���i/��y-E!�y-VcN�js�fQ]g�|7�B�l0�./�L\�L>�8�0V���L�'�ȉC����u�B�F�3�h�<�?�K"4�fN%Jy�9s��sB/S?3G�^zK�.Đ� |׹�����N�?���L�6?x���'� ���x��}>�{��+M�|� �Ǿȯ�I�БU飻�V4�jp���
��8fۂ�Յ#`Hֱ��.��H\���]�%E&5���R��I�q��[b�4��[y��c! �4�rh��SmQ9̩V���S=)��!���h]T�,m}(-Cy��C� �DYPs�q#	,�B6D�[��)���A�򣡧7�Q
���JšN�ˣ1�'�#��x�g���؜WV.tW��� ����Q�-��V��}���~sV���Һp@�"I�g�q�[~�)�`�`>�\)��L&�aX�mDw�X��v~ ��"��K!v)���}e��j�V���mȹ�ٔ�g�T�(>tS�kJ:��民�����FP�g��#"�n:� Ɨ<&�̘L{W6�Y��jeF'[1��/ �B�*�o�H�߷b�|t��/,Y�K('���bG]U�@֬�ts�����[�2���t��'���%�A���C ���/��a�Ć�s��,d�ю��ꔁgƷśE�οr�"���ˠP�*m+"���'S��>h���76[��l�}.��sfe���؊�ԕFC�<�0��]l��W�Ǘ݌K.�pVz��X
Q�������/��O���@@���N��1B/��8�����$+N�(�x��酧�R�(:����ӶNR3pM���I0��>Z�̍��N�f� +1W9�������*[�mZ��+�W�*��=(�RA`$,A��J�bH�j�2V;���ر @`���U�a��]v�#B���q����[9hշV���l{0t~��js�=�f���51@��=�YE����x=���g�RU��X�̳-�vhv:̨<W+���~Wۇp��Zȅ/��$��kEU����
)%S+�0�_I����Ֆ�`�+��C�_��Vh�n��?�[��WfxM��V>��Y�UL{y�S��>�X\3K�=$T�}iA�~8�+��nj,a�U��kK4�����|x}7٣Ȧ�?�/�*�f�~���7�q�4�̝'3jP?��j���A*��G�n#q	�y��#B^�U�U�I�0��BTc���As�ᛓ؀{�˨ǚ�^u<��C�7�:�%��u}@���+��JAO��2^�!{r]3i�J	Q*Ib����ߵ���u(c���s�+�E�m܇��yyw��v}z;T�i���_�Y�E�a�ҳA�ܐ��F��^�i#�#����oǺ�,���?�slϧ�Ҹ`����`�/f÷�B���"�hQ�(��I��-�T�2����OL�s�u�H9m��yX�;Q<�~45��ڍ�kQcÉ�]��h��E��b�ֿCu+2}z*d�l|a"C�����X	?'ب�y���Ī���Q��%��>�>���C|1���A ���<XS	�t]�}*Dz����J��-0~�x��e�1k��-J�ZU�,��!hIm�]'z���^@��E��hD�ؿ�O;v\���.��ǪzFJ�O���E&��<�����y�[��9��=�u	��>�KW��+.�?dth7���%���CL��w�8$�W䐜�O�R2����MD�`���ק�l�r�/�����b9������ E�Fݓ�U�9�pJ}U������x7^�j-��o_c&�\DZ�(��sOJު�h3�\l�����F�-� �p���b7t�^ kЭ�X����,������Bs�n�wDΞ]wj����4��d��?mC�T�qzQS!��V?!�����FXuc�ڈEŇ��]��x5���h�P�|�
�����v�`��b�I3j؛���t+�C��S�
�}����E��%�r�,��SI��ׯ���&�#�*뇎#-@�»Q��;f���.�q�ܶ=8A���8x�pS�z��%z�g�a�]U���tޏ�� 4��BSr^�-뒢�.�h
���5޾c,B��G?Vy�)~3�$���]r��V����,��Lͤ0pa�gK�͋��Zp�v����I��.�r������D�[(�)��@�A�������+q�	��^���q���D3���.�]R7ck<ũ�5;���٪��æh�W~1�oo�ݺ�*G}�c���$�C�W� �y�([ge���iE�z��;�� ��x����1X�(���+��.�
�l�k��Ӫ6�5Aѫ�϶2���NSޅ�$�֢Ɗm��O{��h7�
��E����
(/��*E~�
EA��#�j\P��(I�m7�Mj�gF�p���$wrW:nO�n���cw�������fM,�ZN*��(��߲��}�����-&a��^��zw��j:[�)Y\�g �$�8����N��m|PK5-����Ҿޥg�L��茺�b�g"R��HD�E���mc��w����C;*��9t�ryX�@yo��v&_����*H^��h�R��
�2�p*�#��sp�ʄs���t�ް�_q����X��hZ�@������:f�X.Lo��EP�2���x�|�bO�OީG.�r������sJ��D���Y���
��R#��|�Z��Cr���������*�T�t��,��۽������/����g��X��	f\�����bҦ��}���Kj��9�:�*�;]ˇ������_����������Z�߇
s���k1\1q��0;'7��_њ��߼u�x����՛$�dY�Z��+���hӌN-����s�O%ZS�1���4�?���a�W~]D;�y��>�C�RIzji��b��'�?�]�<e}��gI��s):1���k��wΥL
�\��齬8���n�������k�/��{��c����7oB�1�l�X�#���;]_C$���=s�Nn@C*�֑��\~fwl�,���o�.���%��WB���s�Z�S���*�ck���������'&ڡ�o�-��M��6�1�j5<���?����ծh�Q��%<_�����׹����[�� +���i�-Du�Mjsh"�:��3�<B�����Jg�Mm�{�����J(�s��?@G�����c0<XK9NF��(]�Bk@�?��[G��(���(�F�3#��рK6C=�(Y��z��<�m��Yq�~��?8
i��eFo~�`�6+�YG�����RҔPɫ�i��0��H#Ah�)v��;n9��xhU0�u+�;�IM���5wjٙȝk�J AR���B_л���Z��hӸ�D>��Ը�:�(m7�A�
�e�F��x��9��C�����.Xk�J]7�V����84��*p���5F{�����$�K9���ig�^�%�Y"n�EL��l�9����	���^�>M� pt_��p��!t�+)��q�ΒʷL���΋��"c�do�t�(�(���X�m˨@�Z��������{���T�5�[=tZC�Z:�����\B%sV�u����nwпƐ���C
�ծ,�aD�)1�U����ϞQ����UՑ������
��LRO��*ԥ�E�k��3��A�S�Cҿ��u�	!:�0/?-���׃^�����[j�	%xG 
��j�ɃC�.�|� ����u����/�ꑂ�%������>���BS�^��s�؆l��ϒ/����,�4��T��s�t��a��@�� �<�m��0����@p�aɥڴ��=�[����d�h�_�#��B�9"��{a�g=��Or���*_�Z!�f!2����z�����z�gtMN40>��w�Y'@f0�&]�'U�A���S`�9ʰ��T��0b^����y�) ���f�2���b��[����'��R.A"���`�$/E����J&�_";u�(gysp���T��AZ��l�C�z%�f8����\�37������KoVǼ(�I����eSyG�r�~;X:_g5D~�8�a���V^�e�х�elg��Z^��~}6��oí�,&K1%�qUu8��A����'vz9=a��D*���|�%��(�)���Ă9�#���b��XwNXQ���}�m��o�^-�L�z�k����9�-�-8��*��F�������׽C���j���O)�;BIs\^k������5���q,�q�WTBGS�(/���@q���M�u�-`=]�ʒ�_7� 4u�AS������T����E�T��kn�Ķ�BwV�1��A.���(����m*��(�/�T��b�gQ�0�l
�5�̕2X�a�?k ��T�j����t���S�����Z����a^ʋ|�Rv��3�>�����o4Uyu�o<�M3��@�bc�J���k�1N�]p��F�n	d�cR��ރ*���>Ch�z�YuX��߸�G��y��k�p�:�$���Cպ��3�J�G�wU�e�r�3uC"%���I�ƶ�d=��{퐋�Zc=/%/�
n���D�dp��?tP�AP��5��S��w����.�q��9ʖm
X��ƜV�A5�h�����U�7{a�K'v�BB�i;A�v����>mpb�H+-��0��s������3��a�9�]F�S��B�+|��+�F�Q��p���6c��)����Z��rNX�jv���4��V�`[�X�8��6ګ �K'�=<�����t�[#d����a�RS�����vk����g�2�-7���$�?�/��:7��S�9��U����Ssu)�o�D(Z궆<���~�}f!KBs��v�m��:�k�U���x$����#�-h*�?&�ľ�zByD���Rّ��{����)�2#$�6������ԋ<�$�� ���Ys�r��u��FШ�H���EJ���K�d�+W�������0����S��.8��=|D�K�� �.�w����(���gf������a<�Yh�H��\�]���M��^{��\�%2,�b�aӂו��-��>1TB1����+Z�c��J\葖�X���Hb [@x��'��AP�hu�ӳ��.(w��>�<�l�����eY�d��T�{2�5<P��<
�/;�E?om���-ڈ:U*6g��[��u �{K�X�e��E��!���
�AS����ϓ)��be����"4�b܀���3M6p	�!��q%��1�VH�@�*�a�W͟U��F�����J�3׊�B����D�q'��y�x���2)���o G;2c�K�˭t����Y#�1����Kx��H �}Q|aS�6�����#���>�Ȥ����é*�r�:�o����7�m7�.�z�j$���4N5�p�ŀ������|��u>wĲ"r�2t�1)�b��Q"����Y�xg'`5���A���ou�'�S�ɟX��%$j��վ۬�
ε�0��˹<�"35�I�{u���lu�]�J��ݳ E�@q����#�_}��	��6����kd�	V���g�[{��:G��vۡ:{B�����<htgW&ׄ#?�Ε"��+�O��dK�F7�7U=�_M�Z�}�PD�T�	�u����*ěX���O�����mt]D\E���[38��4D�KsE�o{$�
�W�_s�ؤ��ۢ���m�W��2��|��@�Z����P�R+*��ѣ������6��%U��"f��Z��hA�k��Uб�y���+sX{�+��^6��VF"k�n���|Q�坾~��r!cY�c��������|ܗ�	W�2��d��e����4hRˤ.��!�KX���	����2�X>�ڌ#dwst
�ێk�"�����׶]���s���%XrP�5 �����9"�����}y�,�+����_i�5@Hgo��cGd�z]�P�915Z(�k؆\֧�WB�C� xl5��	�W'���5��<�lQ@���,2pԼ?��Q���n@r)��*�3CN�t���7��`I�w���$�	v���ڡ��.����t�0F�]�|�w�"��th"3�lj@vW/����t' �5���k_�Ҙ@myAw�ڧ�,��r�<�Ux�L��tT�-��4Q�^�Ī�Hy���j��^�tG��h@����b|�J8���b��������;�C"�Ő�	�D�j5��O�R�E�GG� ��?\qi���`-�X]�]�/G�cz/_ޱjK�^,�Mo�-���^~K�V��%�W���#�h������7�Qh��\��٩�!��A���b��*)��7UrpDm-�R�F��}fœ���￹����|[��m����K���R�2o��jj��C��;��t��	.J��Z����YQj����&��_zJս�m�Цe#P��R��]���[c��=��Y��Eł���$h�M�m ��KsN�s�o����������pm��!-
o���!~��U�sGv�
��ď�j-��7.��H��Z��s=���}�av�}x˓5�>RǦ;��c��C��ǚ�lr����,��%��E���ė=��,�znj�ŋ;��8>E�qF&�����F�G��FQkl�ĮF<����k�C=�T��L��b��LPs;k6��Ӊ�59��/�Ld�Yzq�^�b����1�9���`�rI�EO����n��iЫZ����F�4��|�R�1�Z,a��Gd5��ղ�)�|���8��f�զFG��T�7+Y1�6�Z^䇀���@V��R�eG�]����R� 44 ĺ��G��o��J[8�Q��B��8-='xr(	Ӿa�7q��) 䡷���g��j󝳋@iX�t���s<5���5\܂d!��?��p�0�&��a�
�(�œ�t�OF����������"X}�z�B2)��
����0��v��w��e���������W�
{v�Y=��S�h�F��2���oU�r����:�4Mz�`��8�nz5�!�R��H� ��ڍ��$�$\��)+��a��`�5t��S��{q2��ێ�� ˔�!�0�I�L����m�k$]T��d�$�I��[Hn�p�J��6	��]� �[!w��#hz�����4_��Cbީ�ua��ˌc)E�sE�$���7'JӜ1o�G��l��>�+����Ҭ�w��4�K���,��	P6�ֶ\�l�v̭�����S\�<Ӗa�\��O�%V����)��6�4��&4���d��t�T������}xz�qL�������Y���B7���pe�P鿛�
�NOs���w�n���7	1<r�;�Z�c0�%�0U�+�p���y�Mx끙������ְӋ,r%|���c�bqt��7:;g�]��R@F+��� P�Kf�lP�nl�:�3&[��LC��5���#w˱E��a�M5y�E��38q5���A_g�}��4��	`d?����{����LOu��X�������_e�x�u<�q[���l���������ӓ_k,7V��KԐeĳyW}������lTu��L��&dˊKG��h��O������ci�$��l��{ځfI�� ���>R=cێ�{Ha�E40:Fؕ'\�Q{Y�;�����$K*�E�sIU�u�Ъ]lz�2zp�S��S��t�D����ğw�J7���g�B��f~(=�_��'�;�gj��Yg��H�|�.W��yŔ,x�Q30�s�<��	������T��Rp�{�<��:�� `Ac=2p3QR�!~�@^�[�Z�K�(�*�l���
֡�����ژ��[~�;/��OmXP��^ugN���ǡ�Ƥݺ׎�@��	�]L��{�$�@��R��̼vѻ7��8��TҌ���wg*��vV�91L���� �	���� 	/ґ���_�ئؼ&���Ak���;^W���Krul�B��B�����,�5;�S�[�	�^0�ɂ=i��
B!��Gu1�����-ZՕ���>MK��l$ o1��4�O�܆?5���zۆ��X!���#���>NI5�e���kO�y6Jt>�w�G����T}�����C��px�M�I�o4�aY�j��Vֲ"�س�f�
�٠L�+������Jp���`۹Щ�&���������OE�m�n�w����o���7ZҒ;Ju��Ȱhe�
O�bP>A-(;�ɇ�q�_ͻjֽ���ڒ6\�g^@�C����w���F陃��%�1#/V���?�������$�G1�\&Cw�l"+�O�9�vǥu�>���GL�L]��x�]u⸷0�n��A�od�c�h|c$K� +���������������Jx8�} z.*z]Lo�愁�M�Q�2!�N�����$Duf����2lg�Ěm�G�2���Q�<+W-����~n����o*0uH��m���C���l�����5r��ۚ�F��J1����M<�w&`'F�j�n�X94�AcLfŧ�y�T����C��q���4A���A��Т9�)�U{P�R�KL�Y��%�d4��ì4��:��@���Ȏ�G~�nxdx|�ߩY=�bL�}�T�lk�u�;�|���`��e�ׄ5�8��(<"�T�V���!���3�C1i�,��X�ҙO�1�Β)n݉VA���=mV�����6��Yw���j����t���O;���O�dC�u�?ڿߣ��K�	}�A\d3����Tm�����Z�/�B"��E�3�.op6RvV�ʄ�4���Ox��̕L�j>���dbSJI{�r<MO��ʑԘy��3��ra�I�T�+�c6p�����י+�HP�j���F[9K�~?�T����V��zh�������ԥ_;�O|�f�FwW��>'C�i�6�η
_����R�,�F,M�H�i�f����>��"�0(�5���,�$|0�ݚ0��4�-&�t���B��^�]��V�ɔ~]��\R���|�u\�Ȟ�DG����G�X�#����6`�q��p�-?(��٘���)�'C9�y�����$��o�� رA2@݉�N�����1�T_��3銽�?��˕ǿ0[eG��������q��7���m9_�����۸'�6aC �T���VC�7�W.�c�q>] i��2��ٌ���"^����U���]�K�>i@�-������ȧd�����7�3����ٗ_u�Loծ�
۫'}�0����a�}o���}bo=y��9Ɨ���",�����o2�a@�C��c��R4�q,.lΛo��}��)�長\�c8�K@�����O*�������(�vVms�?e�N��1�Xjp� 
M����:���vT״��.��~�Ȧ�Am��];D/���S�O����6�țX���;�"x������g�)�S�8>"����E�b�Mw�%:�^����JH9��Mο����'(�f��:gCު?b�X� �B%�b�1��IΕ���t�S�2!J0	���t�@��M�Ūm7
���R?����V�k3������|��Jij3���@!CA�k�= /VG�4�~���L:&�ĕl���R�Kt��l����삏��+���/@�F�|o~�yT�^���\����cF`�M{�n_o���4�ѵ�7��-e����f��2�����'�)�g�^	�y��;	��S��� �!7b�b����1�M��VuM�[T�� ��WYv@ ��\�p�y�bCǟ���Ӛr�1&O�HJ�.�=Sfi�
E�tJ�#$�_@u�|樟�Y,���?�@7����-�l��D}D0`��'6Nӿp�8�$��-2T��hO��GxVD�*����?Q�k8�Yߴ��"��D�0ܶ��@gۋ&�K�b�wK�O�^����1�mn��s�G	-R�ć�PZ�����Q��uōXj?D� �B>Acuزfiަ���b�?�ӄ-e~�,�7��J��x?ø�G��0�׷o,��b5��eFI�Ky��X#Au�]�}o���y*;|�T�[A(BD�P�h����m39��Է��o�����z����ŻH��������Q-)V�c��}�o�i�E��
��<<+:S�w�H�Ц������6J;ۨ/�w3��B2F뾤*��L%;׎�J	Pn�)67W�x�K3 =K5�ZU%��	��s����EH���)Φ`����d�~+��X֝�[DҤ֛��U�S�Hh{���g��z��=ؘǹ�e/M^-���ؚ��i]�)`��7��}i��N���i�N����7���p��m��ԑx��������y�4�$�������庵��SpK_��ح��hu8_\��7�hU!h8P!nT�N ��l>ڬ���^xH ��AmG����'p���Б1�i��ы����0��hV3�Oc�A�w-��Iz��4	
Ѧ��y;��A9;%~Y����-8`C�dx��w
2��[ӭQ͵O����⑰�n��W�kd��3�u�X<�#��L2��}棗��4�D#έ81��k9,[ď�z]	C�M��窲N�c�o�ݮ��!�"�>�٭�B��2������ؖ���R��n0��8���\E�y�8cNX����]`񒦈_F-�^;�x	�Ǫέ�P|�Xuik�ES�л�@��3���'$��Q��	�f�#Q�C�������˾V�5@��(|���]���j�<��ekwn�!���L��:֣���J��h�/+���_q����Bл-�G��@G'�?���=�7z��җ�"�1!��U�Ъ����q������:3�߀���ܔ�zED �O��@�6��?���P�����76��S�pndi�U�݉T�5<�"�=��u�;��x�<gSx�P�bX�G��2�˓���B��40G͙�7�5:X���k��K���~9�Ҝ�1ϞW60�G􀂈[0�@�9�� �����J�!�� @0����-�w@����a�J�F���9�)��:�QIƲ�g��\�ߖ�ET��̦iHfS�o����d��>>��q����Z�r�Z��}���|eG��`b�����:��oǯ�3�&Pn�G@3'��o"~��+R0�(d�
���}H�|�\k�n@Z[�Hx�6�i��P,���?��a[�5P[�0Pܤ۷���tD2PT�O,gb�	��xH�޶��F��]6N�1e�Ĩ���&R�"���p�����(#ѿ� L�vK9�-G�e/NJ�G�׊7*��ЇDp�j�^���M$��P�<��e���4y���l:�{ЧG��<���qv~I�e2% 2.ك�dg�[uaD��� r�A���$i���ܦh�����(��Z�+�o�6���=�j����/�R~a�#,Q��屑Y��AK�:�I�ª��.^X�fJ�w����]���6�e�|��)u�bˎ���]&�[%�&c*�ļ�F;�y?�l�~�ٷtZ�*�Ptui��L	��O���A�'1/N����2���!Q"�r�,���<ď���	�S,��Kq��U����ӓ/9�CBz��֬�����/��g!�qȜ:���t�uw��ϩ��(\���I�wmi��w�
��:]�ش��{�m�Z�Bp|�r/K�'.�m{�@�z5���l��z.·������5@!NN�Iħgs�n��xK��'a1�)��y!&
���n�$�]Ε�﷜>e�*���\�d��Q������u�%l"#~a��'q����E8^���9�娝i�V56KX,R�|i��LhBO{���3z5).!���.���t��������J���?�ͮ����=9�|/����gU3ܙP$�����!�~�5�]@����>/�?m��E��ۤc��4Ц1I��ָ�|;� ͣ4·����˨Y��?f]C�aI��=���;��[V͠�b��\�G����9����ܷ�:MV��09�w�$]�RI�?�e߄mM�^T�v��E���e����/"p��"�@W��B���K�� �U*;��V����p{�j�:�뫡,"���iJx����
ȓ1<n*[ ~�N��f�y���BԴ�������-	i�^�]�;��,� �bſ��!�e�@AX�Z�lJ,���I.ک}d��Nv�Ĉ���کX���ɴ�(e[蜂��pB�${h�x������f�wj�|���k��k��YE�#�y�G��(��76�
J/c��s|��`oa֗L!V��m-�2�a�w�u�����(Ƽ?��f���d��E"��(rٿ�8v�!q�Ѓ�	%�)�+,��ݕe#�RԎB�?ҁ"�Y����+��9;yl�A����16!�ފ.�q�șd����
��#�#��b�VS���S����)V�4�idZ��bb���ҫ�k�Ԁ}��K�5��h�$����>i����Rt�����4�`�7�H7G���&�:P��NX>n�Ou��d.7�Z����h��7Iq��Q���%t.@"����|�cݟ�MO)}�_���Ʀ��R�����u6���.�e%������3c�`��b���v�WFw��s=�����`箓��w|���=�}eY$�y�_|M���1�C˚T:Lnlk2c��j�	���d:I�����_��H����`Ʈt����O��1]��fC?<�i�(*�6e�'A�e#�0�d�yn��`�u��Tt&�s���{�l-����8�Hkz6�kZ���쿁�����DC�(U�C�x�w[�̣�}Rz�bӞ�{^bv�ԻM��g¡>$3�&�o��Rb��9`��ꄒ����fJ�!�X��<�v�	�����ZI"��7Z8�8g�U�ȘhC��!�ÅE[���K\���K�����8���z�`H��5�c�[�V���
��
L�	�n��֦*�|��yv8�aZc�:� ��w�g�ԎK�_�,{7(K�+S����pr�	���\�1w.�����
,I�������\� �w�k��� ��`�XG�KZ M����?��<刽�5f�]J4\ՃS����~_��2աu�3Y����f͢��:Ba����-6b��V2�yǇ�m4;��cldj�kW�*xU(�g 6��4D~9jjf�H��9MQb��:�ѻ����{����$�Շ¡�x��@�@|�_d@|��w��e��M��n^�4�j L����V�W���A�D�9MV6�������P��� �rSC��c�x�ʐ�E�
nvg��)�L�P|��������U�|J
���QvR|%�.�;[��.I� �Z�r�^k2[�5������\>�X�AA�B� � �I�o��e>Y�M��iLF]�xe���
,F΋�)�?y��o���ލ�2r$��|h��h���g���;�+��a^���#�a~Qs�k�u�[��Dx2Z) k�aF��m.8���U+��C<G�
�*��;�}�2�Cg���8PѡJe��	����	,������&n�>�N	�6E��z#'�6>U}EG*}w�g�j�:p�mW��(�H׉Z��o�S��-�J��t	 �SQ��j���pm���|�)3��}!�M��ԝ���o`�h�5�B7O;Hm`+���
���W�^r ����K��3<���5�+������-MR��z����X30�Ql���Iz�k�
<Ud� �ȷI�� ��%<�Ie��}��~7�Tٿ5	KD��ְ�h�������uX�M(��v����Ij6�	H���}�p�HDcl��R�1,��T��A'���%R�R��xY���4��V}ݒ:X� QJ͸;c�1±9�/�B(�Bi@	f�l$��%�~3�j�ZNU��f�g�!Jy�LBT��f�>b��&��K=k
I�1+G"/�Rv��]r0ƶC��\� [�ނǟ��Sx��x�n�.?N	�!!�|��m0�K�S���d�*D��joc����.�5��ٴ4���m#_8����w�`�]��hr* )k����,��O[�����«3׶�o���n�m{�H�G���C b�M������I>�V�_�R۪���0�*��]<a�[{M-]�6ა�[
=^9Ne��^ �,��9p�<C�uV�Fܪ�9w-��<�p%�� #)��{.���b��R����X�q���Ӭ+�#@B�څ۲Oׄ4�t�;z�H�*��	�2a�ٟ� ��Qo��c�:,�ԣ�=�o�`5��f�^jAZ;~>W������@Q��6�����q����q������[��	$1�w���c)$c�� y��^�b�S�D���뻻P(����Ȱ"�6���O�|.��.����aO�VsV�`C
Fd;H��$E�%Gn5����m�!m��0���]��ܻV���:���q���Շ�O����^'���P�Zn�G���W�t�����q��к�o�E�)�Rl�����/��p-�o��yQ�
ȸW�w�= ��8A�BN�cQ)Xl�Zdڨ�� x����ϛ��o����`���+{4��l�'�L~�P�-:/������.�����`B��eT��x'�*c��>���ܒY^ze鸗6���0����L�Iv��� B%����c�����uG�c�K��G���g2�A�QN���T�>�I���H� �;��p;��9�A��`)�E���+��\�FS�D�����[�I�P��z��W���n|:-���6���N��
`�m�P�f�0���TSZs�K�*�*bT^��?��J�!o���r��V)��d��[�b2s�T�k�Ցr�����@��É�'�C��	���V0��L�d����z���-`�Ȗ0	�^A:͢��+�[����:���[mf}��6jQSO���7���[����nD��h*�3@��@��>�{�w�W��̐J� �;��!I{%�� v@&�D5 �%�����o�y��E_���)��3��7#�x��7�mV>�K�{�*��ߝR_���\"/>:6�(��йJq�N�K�/��F�F��'�&�X�X�O����WCΚ�l[i1UF�I񢌬�=[�3�[7��C�,e	Z]�'�R;�%�;u���˸q�C�-_V-CU��U��>M٫P���8�"��G:�w'<�ֵ�J��@dD{#�*<��.�����
T�i Q/�<��Ǒ��Tuų��L�\�U��HA��$M@١������V�t��2�G����i$����f�(q*�Rҧ@�eG����u���1�h����ǎ�N(����e�#��Ҁ3`�?��AP�CԶ�����ꊟ>��ȿ^���"i�k��.�i@v~��јHg�#��t��4z&P�L�������3nkW4ob��C��;`�6۸3�+�UR}"@+�/H3yz�h�AT�=f�$疁��Q�O�zJ��Rz,�4SNţo�ͤ]��2�`<�A3ɐ�s�����al��vF(3^�iZ�����8��#�h]��q��������1��i@e�!z� ڻ�2K9��Rӿ��\?�+�A��7g�%���iG�����+��{�p�yH�]4Q Jo����W.w�D�5\ ��Ul�j��,T��c�6�i�	p�?���J�K���Va>ˬvm����m�\V��`G:z؉�:}��1(�6HHX�Dk$�Y^���b6��!�\;UB��S
�,U��)[� �Z��w�)Z�M��ŷ��K�>���+gkK,��_�K�̥g��>��� �xm�K���oL�F��4d��v��f�����R�֙�_��6�׼�̖G<^?XH&	�U0�Zw��������k�7@�c�Z����hq����������+3M������/���tB!�A��3i
o��:�yȔ:��8�l;��&y����m� ��9�+��
��t�(<D���k�HE�C�n-%���li����k�k�%��$����;eV��pԄ�Ԟ	���L��r�)5\�HX:9	�ǚ|wS��x�}�E��-���XND4���ߗ����p[Ugd�p�}��	�L��|�Q+Š]7HO+�c;s��>�����Ƈ��Ut ��l�*`Gg���=��i������9!��6ş8�7!h]���&K����4w%�2��V���s��H3g�lPj%�K�Q���í��Q���G*��F���}\`iES_frc�(��b�Z�K��O�Dq��I5�U����6,M= Y�����L�"�g%eD{5���8*�U��P���i������۱�$f+�l�Y[����W?��p�"��q�㉮ϻ��t�İ��`H�Fk6���G�ѳ�l�^ul�c�s�7>��ߛ�r�p������A�P������Y2�{�����Ma?�ٟ�3�B�ruD�w�?.� =VG#�*d��%X���^�ƹ��11ov]a�٭�I^�~�GDh�r_i���\��ٳ�������ը��a��h�}�Z��͏�b��!�][�S%�ܥd�hBuU��Q�Ӱ�P�k�\��ÿ�w�|�'G;��~5����+|��E;ᯬ��y�"gI�+jЖS@@4�P���2��Tњ[Ӎ���)�4����UGE�X�*M�h�8�𣗩h#�6��C;.��/0�����]fʇ������q�?�{d�����F��Gg�b#�40	���n�Ev�������w�q"�ϑ}ѬQZ�Sj�p�� %]���i�����6�&�66��l ���y�RϮM���RF����_���{ݤ!څ�$�<b)�pc�HI��j�sN��5%�W�g��_.�|��>.$��*&�2mF5�6j��sXp?�=wiQ^��y�l{����)�`�5�U۫��pz}�E!��`��O��*]�{ީE�&�W!k״(��c� CƑ�{��(����)ҡ�a����A��8�8��n�zq�)����ڞ8օ���3��P�/�m�$���(��[r�,iQ#�~u(6L@Mm2#�[h���q����#[ƀHn'܆�ϰ}B�LL�r���Cw�W~�"ҷ~عZ�#�2�;Ν�d�yk7�=0J�~��R2!��j:"}��,��5��P}xb��#�oT�l�����:���A�>��'�y:�����|�����b������~Q�M��0z�X��;(���EBxg���HP�,Y�������wf��{6p/�"V��` �<xc�v�ejz�ao����x]w����EN��Zuq�e܉����\'A>g�+��!ק`F$YF�!��5���-��]��꧰�a�fh0˃i�Zf�,H� zZ[r
;�l�(���&�ip�Ee���?p����G^^�mXR8��q7���Mϟ����|2 ��K�87x�Cy���[N%�h���d����KY��l`r�-]�P�k�`g=|YP||؆���� 
E+Sm�lG�4�����3�6ح�&�`lƦ�#q�N�=��`��`]�V\[ �iaa�№����u'�t����Wzp����N�б��p%�ĝ4Ɇ⭤�?��5�i��ϊC�j5� �sq�pm���q���JL��%�q��k7%\)��,~���&Rrr�%��!�:�T"48���KՓN���C��/:
���)���(D�mCD?%d���)R'�IPR?)�G���ɩ��_A���:�~��b&~��A�[�֕o�|�YJ,1Z�/��g�����* jC�Qj'������J4��9Ķ��%�C���
؂K�l�2����<�d8�
��FڛWc B�C�`%�D>H��1�Ckw#8م�V��tc���G9�x���+��ҩ>�ӠyQ��j��I�ư��+ǆ"�+}����A8W�v�Tf��N.�ɠ�9r}��) ��H!�q;;��h�E����� WN����W�`!�	��\'�|�='��Y�}H �vÙ5�V��
f;��=	f��#UrQ)���ެ�z�&�/v��l�����Tr��h������fB�mE3sIV����9��ﴋ��f b���mA���ڨ�B����h�'┼���W1�ft��l|˷2�M+%�I�h����^�����l��9�U�+�f^���[��D��$�G
	'7C����&�1t��8�=#B(m�e���/�y���qҒ�����m-�ݥǵ�
� �,Х�Kp0�:���*N���MH�hA04Kv����u1�Ot�k�v{��5��m0�9�5L^2q*R߰�j�����0"�A��?Y�A�ǎ�?�J)_V���{(��D6n]"v�^`��}ιx|e.ߛt��d/�#j��`ğ���1:� �vT2��M��Ͳ��l�0l�/O�dU��U7�HI���u��,a#�V�A�h����m�<K�T�����ח4�hU��Sy*/���;�(��w����Z+����s�	��f,j/8�FPY�k��1J�~QP��.&�J�4?�H��ʃ���tmh��V7�O �,5����{浗�N�����pP�t�agx{@>ׄ�x�.�\�4��Y[p���9�z%�Y�^�����J��]&��܌����qI?J�+�r`��8�Ȕo��r�O?ʁ[Yl.����Yk���D�4�=?GF>	�t�6�Mw]tD�=1�ψ���9좌\��ϤC����{�U�X4�uP�U�$�0P�$� 2�DD��NvK�'����A��t��)���`��4�k��b��+�Q�}�Jn��^����W(�Z�,#$D��L�z���&���M{t���S�֮;"�8̚��2#��8u���AS,/����hO3�wH��lD�(y�;a�o}1���-���`I,]ᛆ]>/�4mWӉ�M@��)(�e
8�Q�J���j�{�2���u#x�}�&�4=F�e�Af�ƒ���q��W���Hї(ڔ{����P��; ��w��+Ƭ~���m�̭D25o��xtIj��71�/A�l��|w�^j_n�et�8n�T9]���$Ζݐ3p��b��qB5E։$n�p�˦��ձ�ZÛIE>f�t4����i4�(2w�"T�e♕"�/�������c��c+ݣ��L��Ok[�i��͠�W@�$�bx��gGP��t`E/�H2�7�l����r������%�p�M4w�=�V'2U�]�bEF����]^Ʋ���x|�}^����VF>�w�UjKQ��2|�R�<
Z��6�;�e` b!�ɺ�9\����=�_���`^,W����5@�/M��[w���ǔzķ���*���RL�:F�`�$$&S�I�������~�2���(6���ڟAWc�Z��)�W3��v��x�a��`f�Zb^	"�%���i4}�a��@���@��~����E=��X����.9z�<�n�C����@{o�H�h�.�<�\���Ԍ\����g�]$ġW��3h��<��M��A'Ɗ�3>$�	5�RCH�n�~2��2��y�Z@S�z6Ҟ�f��fX��1.i��!'i���[G����@z�-:�jh��'u2vhƇ+Ӧ�W2���pҕ��r�7��4�~���<��8Z�Z�3L`�,�/�#O� �%F���:0�zSJ�"��q�5w (}�`,^���4���v��l���Y�x��LT�0���d���#�
#���@u�"�i���G���r�Q�4	�[e�@���}Y��.��6�	�<XT��(E|/��N���j�:��T�T�tg��Wg6�<�6z����Dgc;�Ůy=�`�~>'���9
��� a�1��2�o��R���ݗ��Z?	��,m��׭�+z����}���m�GP�ך9_1X�5i���"�v���L�u�Jj�y+���Ec��_��,|��`�8'8]��)��&^^i���Q���<��MY�I�	M{ڎr�����t�q,Rp��U�DD�4I�/���� �T��n��<��@Iyj�ߩ���D?�o�; ���-��@!NHt�.�#h91g;��w�]=�iI��n��G.�s@ޞ.*�g �J��Xi>>kQ=`���B28/���{��a�=/D�n��4�4���*0u��E��kA'#&�Ó3A���w�� �Ve���ҿmi�ʢt��Fm���� >���b.��xR{"#qgH^U�F�!�I���%���
M�����$���+��ǚ*<�]�;�ob�O��K~�w����
hH�ZÑ"u#5]�Oͪ�e����:���pDېq��'�TSi
+&]F�7A7:�3J� ��Vj"k����F���'x���߿�v9a%T���e7^��d�������Sp�����1�Gأ��KFQ/�����U�W�TQ�X��d��Aq5^Z^�M��j}��ꇠ@�5m]!:4�|��o<Qg�'d]��V�G�Am�a#�3������.6�U�\^������W�3�"�ã80M�κ�����ϏM�}���H�(�\�O�"뼭K����nUal/q�a9FR�u���pk������E��U4���
�0���|^�\E�\}��v2��EPQ�&sχq�&���h\\˵�:�,�yvH&s�VI�t�ͳ��Z��(4x�_��U���`�ʃ���z�Ta�O�������Y���3��������)5N�"��H=澛nOE�[�"�N#�3W�P���汗 Ju�d��d�#͊É	6�I�h;�Y�Q�P#�V#�F���zH[��A@�o�\�&���*.�[�����k��J,��(�6�G��\m2���N�2�,a���O�V�(R4��������t�S�yA����[�M���C���S��wu��9����.现���7��Z�&jp�����L�c� ��6�D�S��i� �G� ��A�e+E���n�}��(���Ĭ�������Z�u@u�h&�<��EY���:e9�C�$
m�]*v.���Um�/�f�LC6�f[Ha�="�fz�Y�v:I{:Gda0*��%��`�Ef{aQ��k���z�nQ�[-��-f$�hl�7�:�=�Ɏ��{	Es��ɻ^��\	�m��,_����c�[�[�9���
��2������Sg0P(1��)���󭑸�
x��ݴ�����&8Pې�08( ՙ��|�&�X1]�;?p�� ��\	�	V�j��z�K���d�]�0l��@q    @򃱷� �����)�k��g�    YZ