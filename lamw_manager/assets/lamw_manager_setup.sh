#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2225077773"
MD5="2542895992c3bf99958dc93ebb8e0482"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20553"
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
	echo Date of packaging: Tue Nov 26 10:38:03 -03 2019
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
� �*�]�<�v�8�y�M�O�tS�|K�=�YE�ulK+�Iz�J�d��!H�n��_���|�|B~l� ^@���twfv6z�D�P(��u���i����~7��4���󨹵��lssg��֣F�������<����f@�#�t��;����?��뎹�/Lל������[�;�����l>"����������'&;W����*�3�^ҀٖiQ2�L���3��Q�1�'-gab6�jۋF��pjSwJI�[�t)�W��s�H��U�R�0b�4zsG�l4�ʦ��5:�D��]%6#��ě�z�^@��q��5Lρ�dt`0�e`�>����c�i����ٹ�E8��+��:�ώ�F����TMp1㓣��{:������E�vo�1Դ�l��_v�t��\��Qg0�Ɲ7�Q�܆Y��[���r��@�1�0:�R=�@��i��E��6T�g�-�`�j��z�����ǝs�J9�8�w]Qk���=���Oo�2���,����0�j� ߚ��Xx���)���!|�<Н��(S�iD���P�d�(��Wz���<t}�3����� ���[��}N�0�`�B�YdydA���1t�ځ�25C��p��/����<����~"�E��9NLu����4�݄�TVŮ�Tu|�Cǜ3>�K/�a@:Ϡ��T~ڮe�6a����ꆚТ����r��i�Y׹�~�z�V�%U _ �I�Y&�v8 3f�o�zByӕe|�Q!�h�2��sP���_� S���iBeUk�o�]��l����ŷ�Egf�
���杚M$|j�R֞�J%�|��kg�{����Ō�|a�|N��^�)��t����/F-�A޴�F/z��ڲ����\%��e+���Pƀ*pD���^�!����~@M+����UD���׏+�+��u���%U*�$$b��I�X��b��V�m�1��vSJ|�du�����T*�&����Se�C�����&�3
RN�"+��8���5icɣ����?x��v�dqpH�zx��������os�Y!��z���5����%ڤ�ќM�S*M����� m�#4Y��2�H?��sÆ���Z0��O-ŀȷ F��'	x)�W��b�_G� ����������n6����g�_��ы�v�;�!j띴F]��~!���a��l�9 ��|�#��,�knc �"^B�c�(,���L��t!���' ϲg6�$�0>nB�㱰�/����0��J1� <��A�*UyH�M�-���BF�ɝ�¼��:3b��gdx0� �N��AtLg{�<}���ɰ���_���d�9�y��� �!b���+�t�h�̈́	�WQfv�`s�ӈg:8S'�4�ðxo��΢)y�v_������/V�o6w������O��M"۱hPg�_0����^���Ͼ�����Ϭ�7�ͭu����?� $L=74!�!D#���@��9ui��@�b���58Y>#:i����i�V���r�Jբ!��&�(���#�Gf�4N�L�$�G�m��F�rˏ���Ҧ�Xi.&6� ��Xw�(Ǜ��,πF�IZ	��hݥ����S8`=/�>U�&�F��C]}
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
�)�xr��Cg��U^�u�ul����̩�Z���ÉZ�U�9�n�K¹�i݈Īqǣ&��W	�̛x!����E�ݑU*�I)F\�(��յ�QK�S��l�j�|6b�p������m�mɚ��+J�Ij� ��IAH�d�y��<#*M�I��q��hY�_���>��L�����63��U�� H��s��@�/YUYY�_��S�����U?I�`�����R��_e�S��F!J�������'�����gk�bFD��+���(�p�/[ү��]z?��!���X�e�d��G%o�!�cSU��5�Z�Ѥ� ��Np��U�\0e7U�F��B���1,���(�|OHR/썱��
8�-��<H$�X���S�3Pc�
���1ǝ]V���}/{�=ڤZ���L{�b��d�\����`���-�-g:*�YYmݨT�c4�1FeNZ���*�P��T���[�qΒ��r��V}�6X�%��bͩ4�_���PZ}�� �P犲Uy�Ћ(]c�	唪I�:�Q���xQ#}�Ed���̸^]���9����&}�b)��H=��EJ+�Jt�Od��iaZ�p�E����٤�KF9H.�k��?�^�E4�_�1�"�X�?�p��ߗq?�&�3�}���������`�ǯ�s�����.��O�U�q�����?F���R�>�@���j�ȃP;^|C�6�k�FK+N��*� �UO>���hOp>9�N�U9ď�;�]�c������G�w�eѵ��>��c��pX>�C�t��{����W������+0�<�j ͊o?B�d�4Q_D񓡏�v���~��	���#񍨄E��u��IN�Y���.F#"
��(��}�~I��6b0�x�i��"=i_E�t���`0�A$3Fc�4�[z)��t3��ĤY��.}^�_��,l1:Si1r!1�/K���gpFn�6m�����d��*�u^���ňy781�p�.*��Nj"*awj��d��j��fj����[�E�K7�`�Y�]��92���Y�^�>���G�����:����CDf��O��~<��0A���	q�)�3%������a�X��@O��� fk�Rſ��(�274*U�1�����J��HF��.��AmX������)U!���]D�������Mf��jY%M͞!)�)dF,����P�-����` y�[4�XpѨN����覷>8�fT�t�R\��:"�xV���� *b���O��$�`�	4'@��&D���1����;@��Ƿ��k��y^L\��s����k�,�}<#P
��{a����!���t:pm3,�S#�����[���ņ�+�h��9��"�ɷ�>c��G���o)//�0��?�H9���Ղ�-'pL�'��,�f3�e�0�e0�2�.�[��3C6
0����81��dpA�ܳ\bj;��%~H0T:�au&w�n��hg�M�8���L�oc��Oƞx�I�e7��8�)A����ز;K�T+tΖ��g�ܽ�Nj�<TL�v����0�gݲ�H��[���٭�,FGy�#��Ȱ8�G�����(km��⾯��皻<�6�v9���-�
[!�w��RfG�	�tR���]�~�LA[f�լN[�3�����1,�ү��JʍM�ng)f1�s���hmh`f��׹y��.�������*���JY$�],r)��c8X��nߏق��ڃ9��m��?)?�f��6;f:��0ŷ?{ԍ�"撣����`��<?`���S �����iH����U���	��4���*��(a�1��1 9�٪������|�Z���\�!Z{������i�'�l�HTW*����eB���m�:M�G�f9��jJ��j8P���Z���R~���� /F� ��b����@0 $'ȍ
\$\�,��a>_:~�gڸ.-��L�-��P�A�s,Ix�O*!]3�<!�tW��%��`
��t�䯭-Y����y�����F�Ttd�ӗ�,�i}�����V���U(�1c��*��q�@# �+.����Jm}|i���ϿA�ci��֫k.� �� 6��{|��������9_�������2��1���IL1p�>�嵥xu\c�ĭ]�#�F075��&ſ�WH��e	"������=+���fi#E=����n�1[�U��Oy�\���r�b��&����ZG��u��@6�d���jyEZv�.�sB;�q�'(�U��Mgmv&v�����K���Y*�g`�)��f��(�W�qI��e����
jBZ��M[`��u���cn;��)*�X�S��\.$�l'�.�pZ_��83h��8���Oq ;�g����$�i� �K�/�=�,�N�.����Vp��<�D����7� #����<��U���/�����ب����������L��֪u�͂�f��s�$�����p7`c�ι��y�������>w��{��rYZA��/������l��[�4j��j_��0B�O���vg��,/����[�Ѳr���wx�ĭ�q��p������~��9Y�ir	$������2)ن�����]U�FΑfE3!�ux��=x�]Y'�v�q͍���9	����z�/�IlF����O�xҌ�YU�����Yu��.*ؓ/�A�pg��˸W������c�9���;��ɘSz�|$l�c�����
��G��<`#"��x��� O�6����Te7t ���0�3[yv��8V�'.�~�ك?p�W�9 pn��KSN�B���g�G�B�C�d���u�6�2�L|�9+�&*�啞�i4�s]������3��N�8<�a� �����^���9dn������ �{����E�f�9!c9pMOʁ���j�.�>�<��D_I^K����%��8�%/:�JW��F�<��A�Tc(m�c	[�͕�J���8Ae��ph]DqI4j�B�� ��\Y��W_eQ���8�֒�v�-H�J7=�.�@�J˟�k�vR��ϫ:ԽH��}b�ȁ��\�T���x��n�W��U��Z����&��?�´0��G�'��#�೙mU�ٺ��Ҡl'y:������AXg��i�tww���۽V���+�*f���D������n(Y>lr�J�Gi�r.�q�Sas�:<���M&t��)���"��TR"���*���P)y��tJ�r��w#-Io��9-u��Q�,,j)�e�F��?F�:%LJ_�8PtM:�b��O����'ϙP*-J���4mJ1����fOXW�\�R��
����	�}���BE�`L�2�k�pɤ��S��bK �K`�H���3�'�{�
������>2��O#���n*61
�Ť��A�gϙ��ѹ���vH8N��K���A |�pp���b 禡�L�j�6'��W��:S2�ct�A����e0�S��?��b[�H^�E����Y�r�L�yZ]�G����Vݷe�? %��dAg�;*$�tQ�b���x�4�!�Hf�%̺z3�L�c��(}&�����3'y��њ�j���Ld�H�We�9��F@k���������
Sz��Φe�o)�emK-��q�6V�1V'9@8�.:b�Q�J�*���s�`4��DA`�P
yog�ă�&�0�h����"nVW������Z%����=�s��(��)?��q�[����*�Ћ�0\�?ݙhyGH�L�䎓��u��Yp?�mu�s����0��� &օ�.Ϻz�OW�T���Y�������X	��*T����%-�`#�9AO;�7��!=�� ����(�f��=p-�V�ο��n:b�i>�AY�`ba�۹����I��8�G��~�Qq��sD������5z�z�� ,L#�R/��uf�Z�MD�t�tl*�x��kg��c����2~�U��I���1�4���k<���J��ߧ(��aAqb����*�Li�b��"f���^����r�[(,-a��[&T(��ƞtS�������\w���v�DU�1ĹR����2{SlQ���`5��K2T΂��Q���ΕW�<��É�����8�p�IŶ�?)�N���\��"�-�<�q�Dcy��~�7�5}E�ͭ�Ğ������,<�$2 I¬�<���/��G����~_���㧍����Ǎ����{���������թ|AG?���wÕ�(H9�h�r4��/�ٽ4�|TP�s͜}�HV�#7�[Ǹ:D�/�=Tj�1�S��4�KG}K���:�q���e�Ud�q��p��Z�lY��ʪDg*&s{���hC��-r}@��:�G�s�O���\��i9�3��=	�.�X��vw����\��>D41�R�V������[,rs�dA�r�XPĄS`�bZ�u������7��x��@��B�.���<������|R#^�>�p���W�PÑ��E�3�ђeqlR �L"���U����֋ifW*R�en�
k�M�ds���Ӎ��*K�~���K/sJ�LB�f�B��Ө��ޛ���E�_oɛ��K�厯*��đ,���E#�'�W�����_X�qx�x��Ԭ�_�l�T�C���+����ڬ׀�*[�w{��}n�Y����S#�P�V��h��Q�N��q�OUm!���͚����	��2��7�[J�o�0�V,E\�D��^j3@2�������$����h�y����~���3����=jw�[G;߷�_4��p�ߔü�r�ze7M�:�p�YX�A�Z���;�jh�	��s�:�5�K[��^Lrc���"�"�����Zu�6g4������!�nm<����	x�m���}_�L��_��c����^�>Ӈ`F����}V�����v3�]��gV�%�o����M�u�l�3�����Gl�a�S����frH�v6*�Y��G]9F���3�� ��d���4K=���M����S�˝�~�% ��uQ��-fԬ�T�GVNa?�>�@�����c� �-��'����4<�A>��YT��iu@���=��7�8|�.Ҳz����8��/���s��8D�=�pn��~��� ��7�����cկ��rn2��+[#�B�n�#ps[C|ޝ}o��Y8Zq�8�Je2��}�<��<�C��OX�?��G,��O��i?c$g?���� �g^��C��HGu^r��Y�go����[D�*)$�1�������b�Y�J#Tn	�- Ԯ8��e�U	��� �iHƅJ]�������DO�Z�;�Σf9��'�nN&���-�N!��Ү@Z��7����oq�.��&S���9P�s1�=
���eU��S��q͚J��)K�e�ObG������q���e��&������et�uS�e�W���m�2{���3D�b�*2E���E��5��)5:��gn�Hሄ-�����2�mI2��i�-jt&oK<��k?)�T��!���y�g���<���Z��p������d�����V������N���}����v�,��F�������A!�r�r���PlY6~Ǳ�VGyw�eWޏ���?N9!�O�x�����$���?�(�ɪ��n0�n<_jot��#h]�-_lH��v��������� ��r��I��Q�*�帳�T�ō�2��+w�L�'c�4�����A����#b��Ϋ�~�݅�����x��R}Ӯ9{�G�P�a��K����UT�.sX�^k��������*~+��M�L�7݂Ƹ��آ��U��lgf�AS+����2�i����6X*.-�c��ڲ	:�PN��Eی�-�|�'��e0��/�ܞ�qJ�q��� aK���}�PA����nUp(�+n+��n��mתO��L��Z4��+(V?((����Nq���:Z� ���4@��*Ae֘�͎�k���Ǚ���[�	%E�G	U���&�3��<:C�7��j��>
���<��t3�������+Uh#J.Ql�|�Ж���T�u&�n2�����+�K0�!����E0N�]{��F�DJ@�:$�̨|.�䋼+��7�#���t�CC!��O,�p�C�h���!p��t�!���x�R���T%�W�a�i�òp���y�d���s�����,bzk^85�O�3"�W����8.�@}�&��g��XX~�����j���8���x!��}�(qȉ�O��J�`���yca]F�2I�m�P���5�&�7ֻ8.`ٷ��Q���������B"m9j�nb�%���eqB[D����|`�K��J��Z-�֨Um�+>[�:la�g��~�����G/T��^����ZJ�?*��!\�����Q��8��z��<I밷�������JU.���,ķ;�^iJ�5������(Qk����4���&�[��W��}�?�G��`�sU���	x���g���M,���ɌX��3�4f��]��
�6����m֠5X�K:�\|�Q!4��^A����N�`ڃ�7l���h?���dU��h��vߐk^ӧ㟂��X�>����8�r����n1��H�-�j�]7�-���$�Ƣ��\�Ϻ�6U(�����8��3�(���qs��J!��[kfɖ�i:ۘ&˖
���(��ށ%�)��u��r���ʗ���º;ov��`��BZ�7<�q��ۚ"��|A�� ���bÔ�)���8H�U:c/r���)��Fe���W<#��G@�IЧ��ݨ�ڨ>vm��X�����0<�U�$i(1�H*=QG'��|ZK��o����rC��N�T�0�(޹s����-��6�.��%��$�V�9�w���| �J�Rw���5\}fU�q�A`�fĊߩo^R���N�9S�o� 0���+?���_yA�H������*(.@ �SWd�X8T�e�!�0��l9":ac����b�vZ��M��+�e�n5W�l�*nL�}�Y�f����׌���� ��5���'����[��׸�Y�F��M��-�F��|<9��5��xgW ����3��-^��Am�=�S�s��5�<F��<�W����K�E���H`Q/���|��j"�-�&��������ݣ�x����n�j�1��uc=��BR�v�yiV[xR�F�J��۰���� �h�iV	��*]����oK�8s!-�.� ��j��͌)+��|��	vQ9>��p;3zq�L�vd����vnv
��$�gmQ�&�j��6Rc+����{,ɇ{fr;��"�`3<S~�%��\�~�꿴mR[�.�-����J}R�����	<�j�;�]`�!�����?�����k�X*M�'�Y G�K+ʒQ���0������7�ڪ��YV�(�D�g�B2j�tW̦1�Ze��?nw`b�����f��U:�ݜ���U��)ˁgZ���s2��o��a"�u�c�qq\X<a\1����䐖�Xc��W�����H�FxV�׉�2�M�_��Z����*���4�g>Z���#aH��,�%߬5Oع�����%6 �_��UV�
y�_�C)���FA�1Lā���,4SDU.ˡ�e��6����t���4`�<X_b+�9�hF�Q�`V�hi1U#K#�����j]G����R���sR��?b�9o��	���r�4ܹ�1�P���(cv/�^���+6��y B�m!���9F"�0��0G����o�Jq�����c*��(�y�7c�_)S���:����A�,�}���?�?�gC��������{��ű� ,�3�'��O�n$ �&g[l	��'Y@o���[˘p�]]07+As��pNX"ݬ-��ܰ1�~�jת���a�jge+b��t�a�*ӿ�q3ÄNE�X���ί�����Nm㨸�'_��Rq���,؝�����IL�4K��WKN÷�&�u�3iO�c%�����(��.A�Ր�&{��bפKK/�����T�>E���B�eg��>��H����$<��\��8���PdM�}��~,���--³J5|<�]��;6��4}�-�Δ8�U�1ۥ��47&���^h�=���w��s��}����ե?/�aʰ�i+f7����d��*8-x����rW�:�\%��QT?��=+8��V�M��£�.6��y��]����B)�RRg&d�WX��:3���;�50�'S�"�Q3�;��8���a��=�.�7Ts-����߀�KA|y����8�A?5Ǘ�
�[�/�� �S�6�k�|���#�]�πHݟ,�T	m���-t��0������ݝW;G�֫#(��w�݆+xɃ=ڋ��r-��X�_�f�ۈ�^�kXJ��M��Ωqm��Rx��N̑��A��s��,$ӲZ���(9bJDGn_ka�|���`lP���a;I��m48g�d���IǕ��/W"A�����T`'�ؘ�RF"h�.���E������ �ޑ��E臓�Ȳl�Y�k(�h睳1��Nt='���8�2ǘSpjY�ܱ1K�.]$�a��n	s����|K��*�$�<m��.��>~\����7r�֞���������Oߊ���=Q(n�H�:�06g�RM���z\z!�'���Ө6��D��n*��
�W���q�V�� /�B�p�L>i��YYeJDП"���������N�p����"QD�������;��
���9ST8�� ���L�v]ӿ����{�ߊ�M���Vhƺd�]RF:^�GG�e>A[?�f�U�����!��cp�N�->�b��P����H��H�b�|Vy͊������(G�v�ZxYό��
��aMF���lԟn<��>^������[����?�.|tʚR���֓�81.���,�2.�RYA���^N�*^�K�D�4P^{hz*���=���}��Q�<`&V�к��q��h�5Z��o��_%��Ipv]A��UG���MVQ{��t���%ʓ�.�?S1���(NY��5�n�S�v�ƶXk��N{���'ˑ�8^�%����t;BR���fVz��a�Mo�u�BۃnSs߻�9��9�-�u����H&�m{���σi�>�>��m�(�4QrO���0��#�P��Ɓ?dCX�A�Q�O�tV�.��R�'�C��5%Àc��b�'յ�{��E<�F�7�= w���R��9� �u� �d�鞏aUF�|	А�Ԉ��N��^5��,ʙ�"��}��;\gfx�o�l�_�S���(pX?-���#Ak����Hrv�;:8�u�qp�LYTA�J�����&.�����ڟz���(�9M������t�^ܦ���[�0k�R*�mmP`�*~ܜ��������'ܬDJ|R�)4Y;U1��fTv��Y[�^���t�r?��}|���d#�6���mfe5�`ʭ�@O��j�u2f:3Ǵ�f㙫H5�����D�ӱ��n�"�]+���x�ɖyO����:��;��ꬲhT:�[�t��c�?��O�f)�cn�	���m����ڷ2��fE��3�٠~ζH�ݹʼ�Q*|�T�v*�lG��F�#�v	�vf�f�����Ar1=�����]�x3�H�(�[�	�	(�8Uu���cD�DT0��v��2�Hx���GJ��!�C%�X@�|�,<n�p>%j���/�O;���~�f#%U,��(�'^��� ��4Z���^{���s��3�����7��*RN������~HBؿ�Ԫ-l�Z������e��h��ȟ��[k~�xѦ[UV�Ҟ��&��h��)}	7�Uo��������hҏ7E���q�G�"J*�H���sRV�^]������pt�4kn 敠F9&;!U�`�N��ڥR�ޯ�S�|o�
���@�=E��F*
N��(����N��9��DOL��Dl 礇'�gO��MW�p��p3g�vR��>�߿�Q��d�����2=����~���S�lʂ1\��z壳T�:vlmT/�ճ��'�ҠBPM4��x�q-�\��˔�[ퟝ���g\��ԫA^���;9��di4�z��X���fK�ɤ���P�>�R�%�1u+��Vv��^����:��L���F5>���*�^K�	5�7%�����������>�QK �z4�|�L�;��;?4�>��ꔴ�azk�n�Z�}�q�Gp�5�T���T��ʄ?�Ǥ��z�4
�s&g�CzXTu8�@ �����[�p����l��4�5���,~��x���{���E��~���x�*о��~0�q,u�o�?��[��=����3�
Cq��F_�'J�yo�x�h��p�������~��<� ����I��tz��� 
�����~L�D~��Z��E�"k�s�|8M��o�:)m���)"��xzz��l�}��^��!�7d�����ȋ��2p����s�G�*���bձ��6RbΝ)�]�zv!�	!�	�^�s����pL�h�5�8W���(���wT l��޽w�B&�����؜�d"�J?G;@bo[;p�wl�(E��R!�v��y�.|Рi�¹�r}�GB!���N��F���$�D�?�� O\ fRW�{|�d��mC3;�;���o�E~V�ݜ�E�k�sf/�C[rgȒ���ͲuhT�USjN���R]�t.ۊ�ۧ�7��
���G��ב��f��91�����XMپi�,%�R�?_ i�7�|۳�B��-g�va�׍݃�B��!w�ݨn��p��n������dӡ��%v<�TSDdg05~u�'@�\�����^JZj�����F�'�vu-���D�?x@��7�F�ޣ����/i���4��,��^�W|�C!u��L�r��y>c��8�>n�'S��$	�_6,}�z��`�>��������w�$�+H3��f�)���f�i3?����,{ ;?�埲�|�x�u���sut�c)�ʘ�9ϯNS�)��(d?N�D��R�gR#��N��#d��l�w�C|'G�����o��ih?p��
���`�\����i)� 1
�Bq�j����n@'T:>��+�[��hv��C����Y�d��Z�̬�l[Xn�iϮ�����#-�P�R���{/۝�b�=�m���k�zcpV�U�O�uY�5���O�i_���Pu���O��Z�n y���jWy���iLZ$���RI3���	����T�������l�S�+�!a^��i��V�/wR�=��q���ao�e��돟��7����������ZL#���q��X��X�?��1i}}_��%^^�}�K��x-Z���0�O�]��g��|��-�e3tI�E2 lz8�ĨC�3�HÕ���B�a��W�>�.��.�\�'*tJ=��Mq���1B3�R���`�4AG��N�QΆHk^��;�=&U@�$4+�1J����R�B2oN����s<g�J�j��nd�� �1�	5��D�V�#��P����\��gm���q
�i��>�<P�<���l!&p�[ֳZ<bS�E�ZefZa��*ѥ�a��Fd�C1�����)���-��9}t7W��s�D�È�Uɢ�	l��@l�/O�'W��Wg�(�b�h��"�8��VǦt�	wT|�w2�M�͔8?�=� XQ@������xJ �7][�6��l�Y��
Z��.�=<l���ϵɤ�� Q1��z9!�Z��M@uS�ohǬ��E3~O�Y+�΅T�� 7�)�/��3fiEF°kכ�kTp°e��������	��ӡ/G��MJV��x3�]I�/n�(d��A�G!���Z^�)-�J���"
Ǹ�;Dz�5�):޴<�Nc����'^0Igr����fW�Ss`�a��M�z2�7(7䝡�����	�o��[��5A���3�R��V�6����k�Pih�r���9>�	U���Q�����c�O������_���#`����z#o�m&�jh�Q9eb�pr nÃ�f8c_|�P?X�ӻ�غӋ��U�B�8eB��?pE� cc�N�m8�6U�9����p5�6k����	�byʺ��Br����C'+2�钵�{����P���b��A�q�٪�6����p�?H��� ��6����J�J};6�����<�A6���o*ڰ$���.=Tm�u'YzfK��������16Q�^�[PҰ�ưw��:%���A�KK�p��c��p㒻���D:?6+<��ߡZg��)�$�K��h���KǴ@�ε"^���ê�2�*`ms8���q�r�c�	�?�,=M(׆�I+��xr]��`���D��"�`��"g��e�+o�򓬻"�31v�9����&~�M"Ի*iEz� ϦC�L�xN�1�2���~���u���@��"(��[�(��_��6"��0��6SM
��X"��9�	�l��ښ�%&dҸ4nY��2����E+�D�~je%[Og�i/�l���Jv/�n����u;{v}�e��-�[..�lf`���;	S:��c%dNE~��[�J���,���vD�����]{�:�_�n?f7��j��\�4�/r�K\0�s�{l{i��Xx���/� ��S�f-��OФ�h�A��?E���B��6J�4�C����^��b(�|_��Wuf$U)�A�]e�=�i�d�����w��h�Q$X��W̕��m�X����w���jm����Z���d���'���߿�|�����G����O���Ͽ���%�}m��}�]���|��?q�s�j�xY10f�Gߚ�Ϙ�Ϫ�5=g�g.#T����)�T#�1���S�~��[{m�T�8QI�0�<DY�;��ݝ�c��4r4�����%���u��O8t�gc�d�sl��ix��&�q�� _V�UݭT�N*'�̇p��O�WF�v1�I���c�����Pc�UH���a0���>k=¹@�^���-�ԣ7�aR�Ӧ�r���$R+e��!�[�*��Ɍ�<�PW�X���JƖTrh��G�cg�f�t�y��2����HN��z2c�0m�����牜P����V]�^~�R�0Е�h��8^�I�b�����;��=�M��
q���5�` �ْ�xW�P��E]
Z��j�Ъ,��%Ț/9vs��F�0l����(o|��n[�{3Kt���K��~8�!b�
V~��jཁ
6�k]"�m��4[+�Q� ���p�͵�Л��x�6�u��h��-�##��5�2)Ph�E,F�p���v|��A��B��(�����Ѵ|�q������#�?�͏����[�X��m�o����/��g�u80Ԁ�Rz#�P��c��L�i8M�ؿbg���>�§���H�q.I1��m��N��#�<�x>y�,=��(���o��n>��_>��Kχ�y���)��:�k(��ڄqT=R8���
z�dN�.^���Ǯ����T�z����&{�^H���O'���yb�fi��U�I]<E�߃l�;�z��S:���Īi��W��8����ؓ�| `+��7�o8���lW��>���h��������]0�GzƂ}�<��GP��
�qF/��x|�1����ў���G�x�NK$}uj����é��թ��u���gET6��)wv�Q�U�d��_߂����R]+"���U���3["���}�s�#=�_	$Z�:	1p�ሑ4��y��Phl	�F2Nk��՘bK%m�$'����dq��`.Ю20��#�R��.���|�>� `�㝟Ѻ6���P(f�Z������ke5QR&,+w����@�����ٻ|Z�}�|P�%�Nx=�_�^��=��s������x���/Ȁ���YNG��}s��Ѧq�'�6ϔ�ß��rp^t<3��-���yװ�j��0)��Ejc���nM~�`��똆5�0;�-��3�hCj>�����x��{<V��( md�(@��s�DD��Ȩ��O�/��Ò�k�q�������?����<|���4�l���,�J}�2M���y���
)^$#�����<|�bd��[�0^|>�|�C|L��1�,�F����C)x�_Q��(��mr��r7�O�Oc�.��Yۭ�4��j�Ѣ���Gf�䡟 TP�&	�����|�2ӥɺ����g�������Χ��c̐��͌� ��k�N���@�>���,bU]X�AyC�T6_T��4��w�ľ�$�43��LX��HQ~�,��P�!޿�n��O zפh^�6�$�O�ĳ@� �);j6E�����`�Fz�f"K���?�� �(2�Cp��v���1*�yCh<Y�dv����;���?t����1ףּ׈�*�w@��EVLzv�����8�q��wx���7֞f�?7 �=��E��	�>�z8��}�G�*f%)�8�^ >I��Z|#<�F����Y8�W(R���@����C�\O����J!��_����l�8e��
�b�l����c�f��]�uZ�t˩(iH�t���ʌj�vk{�dﾐ�R�������ó��@ש��!���w�
�urSeT#���p�՘���b�?�:��bd!|<���k�;��(W��p�@%�?>T�U�e�a���C.Z���e�eY�/�d���(��DO��ȢG>�舏4 ��x�D^j�DFvq����Y?Q鐠q &f��  Z
�`s�$˱q����Z�	L����x���u��V����7km�7P	(�&��(O��
#>�at�DO�F]�Mګ�',�G�`D>(�R���#���-�+������?�������s�����?������?���w�� h 