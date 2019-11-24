#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2873157905"
MD5="8ebc4da5f1c60dfe672406d34c72d2d9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20446"
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
	echo Uncompressed size: 124 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 18:17:08 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=124
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 124 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 124; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (124 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� T��]�<�v�8�y�M�O�tS�|K�=�YE�ulK+�Iz�J�d��!H�n��_���|�|B~l� ^@���twfv6z�D�P(��u���i����~7��4���󨹵���󬹳����lln�<";���'b���2]�������~�c..��5�4�������Na�7w7�������?�o�����+U��T��k/i�l˴(�Q��C��z�(��ȓ��0��J��E�{d8��;���-����+D�{�Qߪo)��G����o6�?Be���C��S��Ү��B��H�S/����u���@u2:0���20}�d�D�1\�4�Qr��\�"�T�����gGF#yl���Z{�&�����`�=�Z���
ɂ�"x�7�j�~6��/;o:�l���3�z�Λ�(kn�,���CE�JQ �h�X�Q���4��"�a���3�h�o����V\�J���ιJ��|�;����5�u�䞿��ɧ�D���z�r�KWH5s�o��[,<Wc�o��b��a�N`[�)�4���v({�qC�J�+=\�z�>���
YE��z�}X�-L�>��k��!�,�<���	l����l�@�R��!�i8����odP_�l?ݢKݍ'���g�A�n�b*�b�T*�:>��c��֥��0 ��g��o� 
?m�2j����sduCMhQk	�ZNQ9A�4ͬ��\��t=E�ߒ*�/��$�,xȈ;���7X=����2������4E���9�S��/[�)���4������7Ѯ�t�A��u����Ģ33r�@Z��N�&>�D)kOS��u��絳�=�mxi�bFx��C>�A��PwI���q��� oZg��Awm�o���	��Zβ�˅�(c@8"�]B����uu?���r�u�*"w�NA�����R�:�Er��*�L1�Ԥ@��M�ln
+��Ƙ؅i�)�
>q���|�ya�}*�Lc�Uc���Iԩ�2�!��V�c��)'\���la�|Xߊ����������ph�s2�88�V=�
���w{{m������o=�}�5����%ڤ�ќM�S*M����� m�#4Y��2�H?��sÆ���Z0��O-ŀȷ F��'	x)�W��b�_G� ��������y��n6����g�_��ы�v�;�!j띴F]��~!���a��l�9 ��|�#��,�knc �"^B�c�(,���L��t!���' ϲg6�$�0>nB�㱰�/����0��J1� <��A�*UyH�M�-���BF�ɝ�¼��:3b��gdx0� �N��AtLg{�<}���ɰ���_���d�9�y��� �!b���+�t�h�̈́	�WQfv�`s�ӈg:8S'�4�ðxo��΢)y�v_������/V�o6w������O��M"۱hPg�_0����^���Ͼ�����Ϭ�7�ͭu����?� $L=74!�!D#���@��9ui��@�b���58Y>#:i����i�V���r�Jբ!��&�(���#�Gf�4N�L�$�G�m��F�rˏ���Ҧ�Xi.&6� ��Xw�(Ǜ��,πF�IZ	��hݥ����S8`=/�>U�&�F��C]}
�i˟c�^�#0vB�ˮ��|ر�FW�b(����#)3�JJN3#c�ި7�x��cX��&[��Y@!��(Ʃ{��t��s�ԡ�x�5n���	��������腡�tǞ�@U��ڇG	�@4NZ}:�Q:ǝְc�wN��3v{�F����פ�j�uD��;ri�AKھsIЋ��	H���vǠi
�6w��u��*���̕5�J��\�M�P�!�E��ױ�7	�~�hf ]�! т ��ً��8���sW��hAn����8.��݋_��r�ԐK����b�1U�6�W�]	��KT�Λ���s{z��^\��h2���R��r�TbU]=;)�\䨶n�����e :\�(�+U���	ܓqQ�|�VH�酲
�'Hx�N��N_�Ԑ�p�s��@��m��\����W�j7+m߾Ӟ��P�G11�_����t��{z�f��w����M�Nay, �0_��ZG��8��x[����X�����.���S��Y]�m	6<ڈ��Z@DU���n�)Or�j�+@Bc��^PY?
��X��x�0�	W�����8�,�)���ivn��P�[�R��Jkd
��x�i���$�e�G��Qgd�`{���j�;�*��~Q���7
��P����֞�:��RI"|�A������.T�rcp�P&qK�"��N�$���A�#8*ix�k�赢`���|���������t�}z��}d�y:�5�p����w{h.�	/�#���I����S�9�NZǷ*Vˆ�+�J%K,|5=6��j���:M�׫�l-T%Y_��U �̾�.gV����`��A���]օV0=��.Շ����v�z`��K$?�/W�����j����SѤ$�s4,%+ܔ{��GۄO�R�ӶI�g�p9��=4/�Ds|�w�D��MDY��m�9Lc�������%� ^h��Q��J�ޖڤ�.�ǭ��a�f��`���c9*�y�q
#�����՗�AO�]BM�x�琓� �bFHJ_�ے�ª|y$!VbW?�ƕʐ�����9���t[g�#�F�m�Lv۵�������v� ÷5�����ך(������5#&n�0�Z6��߭|w�w{w������z���q�w��_�t��X�%�p->o,��փ�����Cym�#ă���F]<&^'.+�u�z��p��X���ۡ�g�aMC�ƕ,�ߵ�K�x>?h�F�!�^o4���	~��x-q	Ã�rp�� �D�s �'���p~?/=�����C�W����ޚ\����(g�$�Sr����<D%?���t��5AlZ�C�̢K�MB��v�y<<{>�e8�����=i�F��zE]�n��O�:���O�w�;�jcww������N4��;�1!���RQ����s��Y�NS�)��&���`��p�����b<V�B��i�쥇���ǿ�u��$+A�]QIU?�2"g����,V��fxn�/Xj^! �r9�]�$by +�٢j��ư�c�4�	ҤV���vk�*�A� !�hJS��1�S��+���"�GƻI͉��݇N-UZݵ.t�1C0W���Zt2Y��ۤƄ=	�c�m9u���;�<ra�w�r���?�~@����U��,V�<�������0�z&���9���g�	B��%P��Z���(Y� �$���
��7���$':�"T*��Ʊ�R�ŋ���IB���'Z�x�)W܍:������������b����j,(<�`fzl���$���9n\MI�S�*Q����ju˲@���s,����Ώ�� _��ǆEˍAI0U��&P���(��}���k��w�v4hwr�����6/���}���D�΀DJ<����x��H�PY�m�&�@��ӥ����w[��\�xu����m��#�FM~/�!k�!�F�!��#�G��Ȅ�A�R���31��N4�ȗ ����R����/�#0t́��ė�<F�C��q��ؓ2B!0a��5>s� �?f�Q��,�3�Xd�G@T�5-�����F�d�Vf6Q��]�4h9N鉣Q�u����bH��Z� �ʊA�6�ҍ��N�Ey
مFDXS�ǎ�k�2�aɥ����N��{3����%���a��B�Z*ҩb�9k&MS��e����u�kY�ˉ�a�^Cx������
݄�#NHD���n�{I yʓ'��ط�T��J�y������w�@n����f���,�(	�^��h�ձq�ĞbY�2�C��;���K��v�t�ͻ�Qr�obgmȑ�'��V�ޔ�"�I�� �i ��K>B/�Ӆ� ������]w��ឪ�\�q�^�t���K/�`�9�1s_�/�w2��K����YbƤ�4���{^ޡ9��q���R�f�
b��Q�b�w����3��s��3��&xz ��J�S�R�65桰���F#�(�����F�����䲩�Iܫ=������5�p��L��|��k+5~�.�05��p�u!�7�)\!(B�{��!_�3.�G��띻^������;ڻ���3�߲���W�S���޹��[��<6��d��lrA݈`Ԍ͡���;��b��W�����=�Q`u�d���#�a`� J9������Qd,,d�R�C'N�/��}Q`�u�����E�E��<�����L:���{�����ٖ������.�GT;Wt�;z-����/��Z���r�'�PeQ���2�����]V&���6t1E{tuh��F4Xخ�34L4]��he����2籃!��a��Ui8��G�^��u�����/�>�)�_����"�O`;9Y!�
�+M�!��O����aM���>��J� +������""Uڈ卋|�Գ(L��b�/�5�������@�Ə��w��Lzٲ�������AG;��,i�*���������0Đ�7�2��u`|�������j�&m$:q�o+M�z�5>霞����I��������H�8��K;`�9\�����Q����A
H�7�MQ��,}/�:~}�z�ȵήYH��mQԞ�#,��`�"�ZI|�<\8u44)m�:	��n.b�_-�O�Dq��g�_&�	y �th��l�'��dv��{^��TT���{��RvO�}#QI FYX��!�, ��(���=�{)J�k�w��z�KVW<F�P��,*P�k��j���,K��r���Y%1u`%��}0�f�2�Iv-��r�c�V���;�?C��o50��B3Ĥ���[?�����Rդ-4$�9����U�}��	%���9/�/)X:��7�P���AZ�d�7��ou��0'i*����_�	������R%��ǿ{����?��ds���M��B���&�%�r⊷� tA�9�e���x�&E ���/��0�X&y�S�Y��	���`���13�-�$%�q�� 4	���pi)���CRg�b.4^��aX&|�����%Blc%/���7�eh�g"t ����kKD~9N�f¥�[ ,ᐆ�f�H��!�R�-���~|�b4����	�~�h��Ǝ��!�:q�q���N,������'W?���JS�{�x�B��
�c�� ��k��
�)�xr��Cg��U^�u�ul����̩�Z���ÉZ�U�9�n�K¹�i݈Īqǣ&��W	�̛x!����E�ݑU*�I)F\�(��յ�QK�S��l�j�|6b�p��:�������#Y�E��1I�  uR�%B2Ǽ@ڞ1�&�I����R���;'�a_fb�>�l3�.]�]�4���!"$u��[VV��3�����U?Iq¶�+�Y�iO����"S�"�l�����0�Ю��ӟ�ՋMJ%_Q/wp�@Ʉ#�ox��~�����1��9%�Z�z��%=�x~8� �MU!^��Hk�zD��\R:A"��0�d@e7S�F��F��K�1,���(�~MHR�썱��
8�/��"L%�X�]�3�3Pc����1'�=V���}�~y�;ޤZ���L{�b��`�X��q0S�wK�d˙Qe{VV[7j���o��Ikt�\%*r�$k���z������8��>���/�ˉ��T��o�u�P(���jp�sEٜ��<T�E���	�
JդA��(�Հ��{�������"���Hf\��כ✀\{�Z���l����|��L�"��A->/&2�Ƭ0�y���H��l2解�$��Z���W�i1���0��C?�%��� ����*D��?�����<�5���x�l��~��_�����?�W��	�����7JqpMs?�q�B�x�Mڴ�YU,�$վ�$~ī���%��2��b2�sQ����r��wֿ$}d�/����ˢk�8�}�!��"᰼��WQ���l#$��W������}�
*��Z0gŷ�	�o2r��/���0�z;��z�M�`B��t$��,�_��!�λ?I���#�����xD�gJ���ʾ���D���v�ZH^�O�W�%#�up�C""�1Ϙㅥ���m7�`�JL�5J1���e��R��3�#���8�~g`��oӖx���A>��"AY��\n�Q�8�w�SS���Y�A �v�q��.�JVۨ7Oi��������^��t�
�م�#�
��W��S�З�>�d���Й���\"2 A����ɢ�'����fJ8�=q}�È��\��6n�A�׮�J~�Q^e�4*U�1�����J��HN��.��1۰X%Y)��YS�B����� >��7���Mf��jY%�̞!)�)�(V����Tƭ~����` yr�-�^,�xԏ&i�v�{t�[�X�
��l:w).r'c�S<+��_h �1���
ME�@���� BC"F�����=�� ~���D{ֵB�</&.������l�J��>��
����(/��ǐ��ir6�\���U�H-�$x�ֳpz�!���/#�B:��V�6�� �g����i��[���4LgF�R�y��Az�����F04���b�%�e̡̩K�����m��@OP��vx2� I�y!1����U�?$*Ͱ:�;_�s|�{�W��q
&�w�Z��'gO<äǲ�y]���r�PC0Nmٝ�b�:g���C��M��j*�Ѹ��oe��n�K$��-h�̎�VG���͑irdXI����F�cn��6��Sq�ר��.ϳ�[Nn#tǼ�V���죔�Qn 5�T}�lW�_9RЖ�c5���������p��몮�rkS��Y�YL���Blq1Z��d�un^���Y�y{y�I��h�Y$�],r)w�c�/Z�Kw��l�ʯ����Ͷ,���t���q���<��0�?{ԭ�"�NG����%yA�J�3�7 ��#��9�����'B�j����YNe�U��Q�j��c r|�U	W���޵0^?&���C�����(xK�fO��$���TbC�˄T�{;����5+X]��,���W���7��z	��xu9A^�\ E�,{{�` ���nT�"Y���g1��2�-��h㺴�20ٷ�C����X��UB�f��xB"/���K6�`
��t�䯭-Y����y�	J�K�o�*:2�KU������O�V���U(�1c��*��q�@#���\WЕ������`ۗ_�	5����۬��pD>l2m���m���W�˗|!�K/;�0�ƨ�H�'	����r�ז��q��S�q����4�r���_!�+W�%D�D��7
TYe{V��e��F�z�}�5��4[�U�+�
�x�\���r�b��椁����4���-Ta�$�!�s�ꊴ,��s]�v>�OP�������L��iu��� ^u�V��Ti�.�PSpe͐�U���V��T���Ԅ���۶���ba���v�ST����t�\:�O����x����ǙC�/�I�|}�&��xL�A�QI�>5� Qzd�R��b�T��ɟ�oG��$�I�[Q��;���oByde�V�����_���t���������\����m��4��,�o���1��H��n��.w6f��.���\]��op^ʽ_>(��$��<oN������=��vw��{��7�0���Sz�����鴫˧�wͭ��hY����v�y�ĭgq���p����*���{,�4��HVUc��eR�#���N�TY8G�̈́`'����;�#���0�kK��_�C���`06�����c�`H1�n��T>�����Rz�|"_�a� �������'���c
B@���3�m�6b���k�k����V�������(H4;�G.��e� �-@�P�h�W�F��|򄡶&{�x��[���&#��@@�Ӂ���,��XQ)��c8o��y4�,�Y�a�t
�@�Gm�s������Ag�B3�dn�U��g�ǃ{����D�Ye9!c5tMʱ��`j>(���<8�D_I�J~�����H��_$���*%�C`�G�G��
�-�����.�^����TG���TU�WW�DDq�E4��B��7A����j��_|�#�Ee�ZK�ԕ*��,�NhUi�#|m4N�iU��)�N9�Y�e�*�om�c�~��~ܮ�m��ǭ�WM�+�?�´0��'��#��磙oU�ٺ���l'y �R��̓�AXM�&i���v��;;��nw��X��F�N~s�_��d��,�3U�;��hWA�$C�J���Թ<sn2�k$L,�^{78I�L����J��D��w~N�4�T��YIz���i��'�JnaQKq��^�������T0)}e#��e��Kp�?�A�<ZB��(:�r��(��Z�FO�#a]�jsK�V+VT�O+\���
=��e@ְ��I-�"E$\2�@ȗ���2�;�"���D��*����K�tx����Lҫ=���ًgϹ�aѹ��vH8N��J���A`z�0p���d��Ǧ��?�j�6'��+�[�)1�1�և�������3 �?��b[�H��
E���O�Y�
�L�v �.���t�t|��۲�'@�?F� ͈s��N�lQW���pô�C��̦3J�u�v�2{&�u#�􌘢�A��#'y���5���YQ��Ƒ���3�}Q@k��hp�����`���Ag�rV���������U�Ur��FQ*	�������-�8�=W]��y '
^F�O��x;���7	�G��0Ƅ�q���+"�����$����=�s �8��!���q�[����:N�W_��\�?ݙh�""'#tr'�`�����/�T[͂�:�r�
���O�u�>��.X��5$�j�V���x���!�Ʋ�J:e.�lIK=ˈvN�������cH?�,���;�o�Wď\˽�O�/^O��܎�V I�ta��l����П�~��'�%n�K�׾�F	�R�/qT�DHˣ3e�����TCvf��7^��#�j���/-a]Mz�졩�9�YR8�`��A�y��ME���*+��*�7��M��KNQa?�W��0�!C�<�P����_V!��3FZ$T#�DNc�����8k�4��[���.Yy�{�����_�����"�_�מ����O[���������0��|AG/o��oÕ�(H9|�5g)���g��]��*����\gHF�#��[����Cs��z�D�vL��n1�G�����k%��cp���L�x��G�}&�Z�<=ɲ�VV->�P!�[��FBl����/�D�B�-�	P�|g�rLq��=	�~�]*�P�ݝC�C�׏�+�CD�,E������^��b�Y(%U(Ă"%�� ӑ��o"k�_Z:��<@^��K�9�RU���@�L��C�OT��AQ��}��
[M_�B	)�-{��4d�%��d@&�D�|�W�}p<�^L3�R��(����^�ӄ�d=�ml�o]UU"����'=zRrK��,C��E�ߝ��/b��tK�hgH� w|T�<�d�wX/y?pq`����/�Vi��xGy�03��x�(l��L�@���+���O�_�p��U����Bh�}.�Y��8��Qx!	D�QGC��ͨJ���q�GUm�Dr�+(ϴM�M&��DȐKy�o)�Y2��eaҭT�����P��D�S %�1~s�wH����D�L�-����B��{ǝ�������Km6�����2+`�Y4�4�ټ��viEƄ����O��=�N�d�����)�N�J^�p]Q ��b���f������k&1�jt:;��#��:x�������	�B���8���|�Dg�}��`F���X}Q��U�!���.��3/K�B�o���M�_�l��Ғ��6M��)��G�U/�Ы��ćmWe��qO҈��p�R:���l������� {���g�����k� ���C=B�Tʔӭ�VP��y���&�}��.sm���0�C�V��L�,��~�B&Sȉ:�0�PX����@_`�[���Y����'�	���gu�V"m��׾�q�(5\fe�K���qȏď5'�#�c�d�¹1zb�h^��{��X��'J���ɉ�����h3W_>b+�1���>lN	�?L�<@��	`�V�L�@��?��1��'l6�y(v�$H���`$a>�����  �/��!���u��^�q����H{���J�G
<J4�>e8�pz��'Z�6H����,E��yB��:DMRq�RW��(��:$A�'�q���Z�ɠ����{i4��(ԕ��^h�d]��B�����z�[��,��] `Oȥ�K`�QfLM��R4m�-��הI�C$�"y(?�$����
>��$�])M����5���-;��lK�t����fC���{�}�!X��~h�c�� �eo
l��Hx5�F��Wa�#)2�a�a��.�U<[��U�0c���F:�%��ᅟkY*yE�q]M���:��G2<�k.�%kTu��b?������L����6�<��-���V�����
����cO�L6�˱MK�����랼�\�;n��qc0|�_K��iK�D�1�y_�� D?B8�Q��QB�^G�'p��w�u�������W�>a����b_:�u����5�����_�UL�E�,'ݽ�B�mmV�sY���=���}T�B���fB	����:=�nw{����j�p��<�Q�|�7P����~�XE@�閉��ol��t�o�w����u^�&\�߷ݒƸ��ز��W��fgf�-1�V�k\��e��Y�,m$�T\Y�i��Y�y��|��3xg3:��s�]��K)���
{f�[f�;GQ4]R�-!pB�*4�O�Y��B����t;{��^�Q'�t�`r�֢Q��^A��{I9��.oP; �(j����$���,M��*	j������5Ktg�qf��A��9�$�h_���!��ѹ�~K��v�%
��G�(5�w+`0���mn�MM/��6�����wm����KU[gbB��[�c�|��W%��]מ{���%�4�`OX
ՈIAs"�@�:��Q���S,��a�]�?A�E�}��!�t֤].B���w0�ҕ�!D_P��Y�r���[��x�F�Ѱ,��c��ē7��ų���lA7�����0d�J��`zCԞ��bԇh2qD8���W?�xM�&?����<^hZ̾�T8����Y�{UB#�en-��h^&iRl%U�*�[�n�*qO�������q^����w������"m9j�����9@��UyB[D��jy�0�mf���k��VkԪ�ќ]��)�@�4��$1��Z�P�؋P;6�"C�Ѳ�;��t�
WyP�_�����"O�}��=��|�^c�� A�WR�"\�4-�:M�z�G]ޘnBj�����&��G�7��}��<���]���n���~��Es15������&gDi�&�f��mH���:l�Z��#MO��U�-��Y?^z�{x1��-�_���t��*�&�m�H����5}:�1��1t"��st���<��j��[f����|��+<���*]Ps5���Y��Rn��~���x�@Y��@T�g��bj̱�|�ز?�g�ff�A��j���n��v.J�u�1�Kl�>9��rvva�@i��:�D]y�im�g�m�5E\��b&�;�rǸ3��V:�0>M�a�������B7HA5��jܡn��%�dG����ލ[O��SזH���G�?�_D��0��%a50����n����qȽ:���d �-�@s�@��̦b��D��_�5��ے>����7��2vFۦ ���]�x�����R��ǹ�t��XQ�G\X�´�w�ۗT�z|����8Cx����%\{a�D������*).Dt�(Xf�WJ��2Ɋ�+v1�Ɛ��36�T]N�,V�*�Y�;Ԝ=4�����Я��+�=��ݮ}�{�{�n������϶wM$m����;��`��� k��3�����?)Ɠ7Y�P�Ov�lji���8���ş>�v�G�k�u'.a�[s��`��΃yUiټ�^�>H��q}�/������
jZ͡�`1�wt��q�mw0.Z4���ۻ�lL%Kf�Xς����^x^���g�~]t�mYmKy[�qTX�-�8��V��R��㷥a���V?Z��Er�Y���mhF��Pm�A����OFnF�u�i���U ����N�_�ĩ9s���4qV﶑[��L���pI�0C�&^��㙊,����SW��m��Zw9/��S*�*=�L5Q�����p���F��6^*�>v��u8ސ�Њ�<	�9�@��P���F���G��ƈ⮦z���O�eŋ~8�~�/$g�@��|�SS�,��v�z�=�nf_Y�[�͹�J�eV�hӴ��>-�4bґ!��@���0�⸰høb��X��!���t,�A����H�F`P>�׉�]��dA�*[L��*K~���\gA�����#�bD��Ϥ=��Mj�0�!e=MqJl�}8��߫��[�l�/*�
�R������,��=��Yh���\V��ʓ�6�����D�]`�<X_b+8�fNuRN����bjL�F�7X��#�պ���t�e�L�.Ds$)
�y�0̜7����V
�!ܹB5�0��!���cv��3��Ȋ+E�@�y�j��
�Y_�܊��s��A���H$�-	N��L�Z]I�RT��=0�mɲ2��ܬ�1����R^i35Xã��`j�gC<������]����B
�=bPq��� �
ޏ�	���X4U�����0t�,���_���Ҳ�.��U�9Yc8',�}nז�\[n٘y?U�k����1sZ�����m�G��0W���8��a��3���D�WA=�f<��qT���In�8�}?I��Z#>q�Y�"�	��V��j�i��ք�^�`&��t`�4q��\�9��r
��s�4������\Zz��5ElKe0�SĻ�J tevwHg��ˉԿ��y�F'~p�Є� Gq/�J��&���8��E�ĕEx6C!��C���pc�I�Aے�!�s]�[�]ZZ�Jj��ᥖ�s&��(�ο='�܇�>�X]�=��9�ۙ�bv3x���J晭�ӂ7�ȉ�/we�b�U�ZT�C�޳��k4�fo/=��c�.9�g�ߕ��(��A,%uf�@VЈ5�k�3)�4�#XS�2SK�53]n�É�[��s9���~Kي8}�k�8����2kx|�إ���u[ĂEU%��m�`͝�.�Y����X�O�ś*��M4u3��.��7������f���������t�
^�`���3�\�#����W�Y�6"�W���vy�/�sj\�EBV��؉D�q�Ǹ?G9C�0-�nb��#�Dt�Vʗ����7�64t>4��~�>��C���XOK��?B��99�s�pr�=�˕LD��VBa(۫��";6f���ڤ��$�2�8�P��<	�B=�c���i��:��E���s6�mۉ��I	Qꌃ.w�9%��� -+�T��Et%�ዯp��ΘOd�ϊ�W'�,=������OK����F��Os������e�~V?>�S��'�%�� x�)5�����W�q�;�^?�>\�=t�S���DX��k�ި��y�gB��w��/k��*SҔp/�8�b�
����Q�s��W��(����7�ݝ�w��~�K�,MQ�(/x��� 0���T��;jQ��5ϛ�hn+�6��l�	]!���ĉH����}��~b�6�=f�k�Z�������7�v�-��U�&�sh*�{$�G�����������*G�q�ZxYό��
�`M��g�m���׍�o��=�_�5��b�ZO�ĸB����|��f�Bk\zSI�xG����AS�y롅�����WZĸ��v�I����aBA	6ǃ��ݷp��N~��w�����c�Q��6w�U�^-%�
 yp��w�v��L��:�� $��*	���t�w��v�������q��#/��KVG��暤A����n��λ����6�i�ښ��M�/(h�h��c����Dr��t�� -V�%�§�'sf[�/木���iz]1�x�0��!��0����G�R:�o�
��������@��#%À�b�g���w�+D��G���}��i�ҡ	��+�m�&��N۽#®�(�h��**���]S�@����,ʙ�"���RN\gfx�q�|2X�S؀)pX?.+Za�����}ESr��:><�u���@�,�!ԃ^uP�sxt��S�[�)�8G8��ܵ �QopP$>� ���_ul�7.
���>�z���(�\�I��Yo�^8 ��M��)��QԐ�T��Z�Õ-�aOmc}}���q){�,��i�L�����q�ř��vm��cM���$��ų���B��J鮙�uڬ"���d=�7�M��LͤiO'f녫VBѬ�s&Y4�B�k�Ǌ�v���r�9&[�=�ʳ�b'i�I��ʢU��}�fYO0Ǣ	�+o�2���<~�L�'���o��:�fv�E��m2�s�y��>��ҩY->T"َ|?�"fG�-8J�-6�� ����az9=����$ nܛ��Ab[q��N��qE���{�=�M\3]w�#S��8�v��\Wx_K���� /O�F�Z+w�+b���`��OE��1�ޓ�7�>��,�"����98��w���v6�>|5$5�D+���4��K���6�M�}�p��^��ˎfoP���K`��懍-�UeM,��j�qˎ���/q�׽	���)�@0Yf��(ܣ�瑰������T��u���?��::b ��Z ļ��!�O�:'��t;�{T����z�q�Ua #��SDY�Rqx6�bΈQO��a ��hN�Ű�8��������Y>��J�n��`�l4N��'V���8"��M#?J�r}��$�OXt?O��:he�n�i�>� �:v�&��W��y����Mm��E��7F<���2��P��s~��9B�,s�Q���NҸ%�]����������Hb�8�T~���uʹ�8��p����a�����ۈ�},Z&�mG��"�#؛��?����⦤Y]*j>�d��_�u�%=�k�Z�GW�=����Q��v��6^��W���4Lom��m�0h���=@w~�X�Z���pN��r��k��?YHr���8�/`�L�'"������p�`,C�nj��Ʊ�m�7��Ŵ�;^�<���j�����wj�o�^�$�E�'!���j��`�������Ʊ���|˾������s�o�}��p1Đ�AP�kqt�N{��_tj�g���GKx��٬���{g�{ج�/�xL�g�s-p��qԒ�`�\D�,�C��򻗾�b..5Y��i��}�p������(Og�%ӳ+.�f#�}���G���!Cx�1�^�䕁s��.�9݄�/�U��‶�
���L,����L9L,��H_ ff��C�n�5�8װ��(��66�T l��}���j��u�����'iW�:ޅ)���.��PM�א�LH ��lk��K���ٚ.�� �ߑF������Q�cc8EP�II�'.�<3���;9�i���@3��{F����E~V�ݜ�E�k�sf/�C[rgȒU��ͪ�4���ʥ�l���Bc�v.ۊ��g�7��
�����ב�+f�)�14�����X��mu\&�Ҟ�X �G��b��ni�_,��`�k6�݃�B�=�p�ݨo��p��n����d�ҡ���%�?�TCD�z�04A}�0׹A�-u�!����Z��	���g�vu-���DvXx@��%T�٧����Oij��ִ��,��^�g|�C!m��\h�r��y>b��8�>l�"S��4��_>,{��#������Uw:���&�(^A��$��T�|����fU��H��j��T��������ě�k��X��;+pT{��?�}~u�vOY}��a��Jɚ�=���l����3 �d��+/�3<�� lu~kH�h6��5����+ 
jԂ�sͦ�Z���Ce$(p8�U�Y3��<gu:��qzn��o=.�9Ӱ���0�V���s��Թ�!_+����o+�<m��u��r��w��:c*��d�u��_����S�4-Y@-Ί�z�Y�)+÷Fѱ��8��A�b�n�������Q�'8��xqS�k�\a�4!%���1�Bg%L�BJ�Д#�D�r&��G��?���c*����F�N��B�R}�����j����߆i����n�?}�*�o<�?��������6��ȭ\�Xeu�N*�U�Y����x�?�9�#}���͊�X�����������t`�f���d@�Ѹ��=��"y�1/����p,�����h^�0p���Щ�Y�a/��OG���A�q��I���`iT5"�1x�#�"��Wafj�묲�T(	p��*M
�=
BҖ�a���S��rH�������&���3�[��@�s�SN��#�յ�n�,`�����y��� ��w�BL�3��gu�h�Ӣ^�33��ug��ʌ�`xI#��Q��b�m�)3gӍ"�D|��W�����Ĉ�[Ţ�|,�嘅�[_�'[��r��(�b�k��#CR��Z�qu�5 BT�prF~��lr��d��0A��.G�ҡ7��
E��m�(��,+d�*�H���	�{t���=dQ�����3�7d�j�R8J���Λ~�Öy8f��hX�s/��2X��b��F�2iل�Ϙ�9Bo����'�-;�%���N ��I	��6Y��I�@A�qMG)0nb�}�pS8ѐ���Lid�T���4�8<]�2���N�ͭ�-��/�?�I|V��D_0�Z����8�R�a`�� �3�r%ENP���!��@����:yklR!��1��� *��7��*�P�#v�~U�d��K�)T�M	��ֳVxi,h��Y����{�������{����&�^����<���87��ѣ�;����h)(,,
/���@lܙC]�qQ�@�//%�Y1�R��;pR!���s�	0KɼZ�X�������a" Y^�r��z����t�"S�"{����'z�Uρ,	���ƈ0OV���?gF��A:��(���0@ BU*�O
��!�le ���=���v%��gw��j��;ɲ[¢ �T�N�������ȫ���x�6)i�|"�/-q��rN�U�-L�����F0���ll�r�j�E�zg��r�]�����|�M:�"v��/�PV58f���}�᳷���������t��'��y�@���,���V�]�H���'R<)pS%p�E�93��Xu�U��}���+̑P5��7	�^�Z\E+ҋIB{>�`:�{p�ɷ�� D��#�<����a {M(���9)/��V"���
�z���1D�%&s�F�نk�5�N�H~�߲��e���݋$Fx�:����D%[Og�iX�l���P~/�n����u;{vs˂���-�[.."�>mf�@�#�;	�yFog�Jȝ�� 2'/l�*�>��C�+-��'�7�� �;�n=�r�v�L3�"G���"w�m�,��r=�E���jڬ%)��\}T�zn8C��qp�X[W�6J�4����o�	�
9)�|_��Wuf�$U)��]e�=uh�db>67b��Ѱ�H��G�X(���ҵ�$�������� i��u����O����|��?�Ӈ���5�p�7~O������������9�}m���]o>}x��,���#���b`Տ�4!A^0�U���5_��P%����(S���x�N��%;���8�.ͩJ�F9�.���=8<����5g��� a��N�_sY��y�{�	�.���o���p�-�5/��� n��;��ʲ�ەj�i픳�������.$F8�_QW�v;�ޛ�.5�1�<P�G9��c���0|���'8�\6�+R^��z��b4,C��a�LVNu֔A�퓹
��;Dǆ
�:9z1��3��vM���)[RɡE��"���r�V���
�2����HN��z2c�0m�������P����ڣ����z���#���%��*(��O?}'|�d���F<4�Gv��,���d8�V(T��Qׄ�m�ZT�j��Љi͗;I���F�0ly  _jHo|�Ȱ^H|sKt���� ����+��U�z���*ش�u�`g�Ś�l��G�����UO4/0Co�j�q�Lx�=LJ�]��FOX���7ʤ@�"�����V���]'ͳ�S@?�7�|�p��������翇���mL� ���ψ��������=��}&�?Ȯ��C��!�7b�]8F���EӔ��kvx)���)|�!�����	��,��0��C3���W���$���ū��7�͗�§C���0|%O�8E��ee��A�2;�G
?��B���	�����O(K��gJόm���蕁�	{�tRO._6 �h����\5�<&S,8�Ή��픎r~�k��j�')A%u=� Nk�!�7��'� �
��M�'��/;_5���D�������o;;%@H��.�����`���p���J*P�m�h(����=��S�x��J$�j�����Ϯ̮.0�LR�c�E�,��Km*�t�t*���2j�?�a6��(��V6!7��dp����^�q�,R�g�JO�WtU�$�� ��ܣ#��b�����J��8��"d�-�s��8��F���x9P�U|cv1�:�Ƨ�%0rq ��
 �>O��6���B1+ԊU�}|D�*�M���2a��ǉ3#��פO����������,����#�����.�GwSA��ߐ������t��즺�nʘѷ�Hm��>жq��]�P�ؔ;K����y����оw۩6�
'�}��14�\�_6��:�eÀ��w.�?ې�O�!�b�@/�O���q���h=}�N�Ȣ:�q��s���}s�����ϟ���V������|?�b|�L���ut����&�e�<���{�	/������q?F12|íXX���ā�!>�xf��Y�ѠB�	���<ϯ(��_I�6�Os��ڧ��b�.��Y۝�,��j�Ѣ���G���_썮"TR�&	�����b�råɺ������������Οq�#ǘ!1�&G%1I�!?�z�a�̂r3e����yQ�D�d�eX��4�/�ؗ�d��<�1>�4e�(�T��VKf�!޿�n��O zפh^�FB�gQ�Y K��5��^�`�n0k#��3�Ȳ��D���'dEƌ���`�r=N�2��#��dQ֓ٹK�/_4��88�o��!^:�SǼ�^#n�����Y}������# $"��x&5���u`��Z{������=���G���꣡�S�N���%�"%g�+�I��R�o���(�z<����E
1���`ۂb��h�қI�vw])�8D|2☭��lV��|�^z�2έ��|�˵NK��m95%i��3��B�q��������w_�m��]�e�{E����y8���L��ʿ)ʻi��:��2*�xD.R�"�r��^��[�V�,�ӓK�_�m�P��Ju�"�D��}�E�W�F�(Z<��l.Z6:�%��_��Ş��I�Y�8@�|b����0�P$2���$�A����J��=����O�R���{7]N�#=��hؒL`H��eǛ��P,x��?�����&߬�M�@%���FD�<�'d�����$zjn4ժѤ�jB����'P�(r����Ȑ�g��X�,5o�8_ك~������y�<|>��������y���}�?q'> h 