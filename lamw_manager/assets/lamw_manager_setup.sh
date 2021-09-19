#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2534970342"
MD5="0fbbbb9872cdcd6783dbcd51e7067e33"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23812"
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
	echo Date of packaging: Sun Sep 19 00:08:22 -03 2021
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
�7zXZ  �ִF !   �X����\�] �}��1Dd]����P�t�D���4��,k1�l�dq$Tx惔�d�2Wt!!�c�ѫH`a�> o	u����T�Ϟ5r�-�z��1q�N|��B��3k�0�D���G2���}�ٹ)�Xr���sjr�4V]��ƁNk��BOH�����u�.���M�Bky�*��1���b|���>4�<Y"���.��b�vjR[�YB�}�� Ő2��8�>K{�X��z�ޢ a�*	�	1
�i۱�E���!ɤ�`Y�(#������;W>��_lU@�|�KH�g�F+����92YT?�M�D�m8ǈ4CKrSKN�'v�O��+�J8O��'�8{U�[&�)V�|X�h����U�n��t�֏N�H�t��'�n$?�ϝ~���pD� T�'��{ ���K-1E���d>mH��H� �@kÁ" Q\WY�cs��v�V�y�Z	L��r�]JS�/է��.C~�Қ����RAZn�U�H".�:�3_6�n�=e?�{��XA:����YQ��m����9^$���t�?�0v�`�ו�-K9ʜ���A��!B�]�U��^��z�?e(*Qx�.�`5�3ʒ�oX�88߃ib=� �`&�Bb���KtnuX�PMB��6-��-�)FPw윯�����eR��Ýcp����y��v�}�u@M?�#��x���8@�t���Q��x��
;Y�8*��6զpx�:H�������!�Pi��f�#�6@#>B�I�<�;x��UC����;�>���(������~���(4��8�M����1<�l��Ƽ��\k	�o��t㜔h��x�f��)H�{Z�W#�I\�2��oȂ��n�)>�@?:�$_Q��3�ɳ�����{d�7��aC���,���+ra�p)*���#r�1����Ŀ��e�@Î���w�(����U��JՃEIO	�k�oIp}��Íd.��6b�� �V�V�����1B	xߔEsݒ��pOc)����q�a��������z}��ۋ��z!�Z���X�߼j���^�XQj�H�za��N��O�^v�T���V�z��d�c�=`<���`�N���#�`���'�~a��H��۩�ӆ:���x�%����x_q$�w���;�8w��	A��+p�.~�_:���;����/�.p��_���N�X4��p`~�VtJi�M~j�f!Xb��x�9i�XN��4��]�y�mp��*b��  w����C2��ǁJ,� NUA��2�&<Q�KZu�ޡ�O�����Nb�|���{/��5�O���ɀ�z�ހ�<͸�õx�8h�N��d>�<��=�M�jk�J�a��9䑳i��׊p��)�4��+}�h��y��pq��+��@s���F���163I�Ix����]=ĜKĚ�C�$}���#䢭T�ʛ���Q}�[!��6�o�N�f���g�Y�ˑ��x��<ݹK�׫�����8�yĒ�gBeX���Hг��G.1	�i��\�q��e/&!IvF��G��h�ԇi�DQ;�B��=CE���/�^��r�d��S��r�����N���w����#|B��a�m���n?�g�o�d�����d�I�{d
&��Ǟooұ�Ih��i��d�8$��a��)	o��jé�D�i���bucP���F��v`�猘�S(~��N^-�aGa"j"ew�`�cš�2����܇��
�s�D:0֩| $�EM�u�|[�1�\��ƺF�%⌆�v�р���lD�ペ��ؙ ����7�]<-D�N���ҁۤ��'�u�-��	�׹q�tH�sjt�ݭ�^�~J	>�\���8-��� ���;���7H)�8��{6+h�����f��!=�v�G�,�Ӎ���"}ɰ	X����X�>G�)��<���2�YU����1��t�;I�l�\�`mൂ�{��AA.��d��X�[o���ڿ�e�ߏ�ww���c��<�m�׸� ՙ�1�,�7(�\E��׆�ɡ�Ü���Go
J5�F`~�ǒ6I�_�L	M�ZI��Ζ��D�0yAcɼ��q{�RJ�|�%i�P�J��1N3m�|@�2��2�*�2����&�	���T'�V�����o[��6)���-��%�3fLF1aλ����M�3~7�8�5���.��@L�v��;�Q���G�e���͊�#��#����,r��b��?\�@�|��z� ���fdۍ2���hd� �}�TAJJy�}d�+S?�MS�8����� t�L8VdcP ������!�W`�H����hc�'��?8�6c�ol}m��ڞ'Ƚ�7p�K]�
m �7T�W;��۠�h�;�VoQI2sB�86 ��Օ�*�E,�~�q�9�t�-㶃W��w_ƨ4�;���L����ͣ����(5V&#���O&�Vd����W��/�E^�q`~���k��P�"^�Vv�
�����g�$�����nd�� _Sz5a�Z���z�ӌ0�f�"d���Y�֤����<p�Tˀ%�e�+;����Sw⬇O�j'�}ρq�[�rz�����LA��v͝i&Aʆ$V�|��S�#q�*�`�&�8;��b�+x�������dH�l&�*�StG��M�^�k�����B0	ۥ'�4�Ej�G��(������gJ;`�x��ә�oS�;�O�Q�<��A��k��Yr�$��K5���x�P�2�y�����c0��_7'%1c�)�m���<�P���| �G5�}}^1��-e��U}R3qՃZ��o��/�<���s�5�H�a@71��@$�	�I����WhY�����!)3L�<Sa0��Ӣ����H�#WIX��h���5��A�cC��O @ě����R,¥T�CO�U.�V����.X��HȒJz���i������m	�,c�rTMD��fy/At�WާI�\�P1�DEJ�m@٦��S�����*Ѩ�.�L��{-d�`��D�|.ե9�0GQ�
�gy�Ծ'MdevN�E��`�a�He@=�i��2�K��}ʁA\�ȹ�$�QO�m��h�E�x��?��!;�p���G\X0��~1I�Hv������k�1�Ch�ł��q��
K�+~�:?Vm+m%�}Jl��P��J+��"S�5�OKXd=-o0���!x��.�T��O?�l�Ҹ��k��i��^�]���1��nֻ��6!��>_lf�$]M�`i|�cd����V�wf��KsVu���-�ۋ�e��̪�m:[�VMo���L�]�9�ER�#$b <��mH=d:!�a̠U�����m�'�� [X!lD"��ɒ��<?��8.p�h�z/}h��OSI��=wn�m����շ�ڳ���֢]%1�zhXǥn�}�/�m��S����<f{��'q�	�ɱ�X���^�Y"��>��-�!nn�` ov�Ӱ�;Xׅ5'�}j�H�*��_�݄�a����v+��%�]� �{Ǎk���^[�8���N\�E	M;��/~'�|��W��������{ p?4�߼!4w�8@���[	U�\���J�*k���l��ĲEU,[���#�$x7��1�<!���0�<��p�^-��!��qk��/Б��9�����]��J�/�'j�q�)�z��p)�B��¥�����ߏ�𠖩D4���Ƶ>�'n>)����A�۔c�4u�����Q=U��>�uDYT�>�P� _�N=���>�J���N�Me4.��[�Tv1ӓ��$`B�-��z2����8Y2b��z{�v��Cȋ�D|�"���O^�ԟ�3l�|�_SPg�o����ѓ���پ˛�F_��F��G�oر��~�3LG�PS���s՘�vm��<�F�\�x%v؄kc3�����4z��//Ӱ?5����_l^cbGN�|��G� ���Pv$&��̫l�BP��`�e�c2S�g�퍢����Ihٸ.*,R�*������.7�9�^�Gq/+1O)\Җ/Ҫ�,�kX�1K��d����Ȉ�N�����)��-���ݹQ��<����q,O}�J5~N�����4u%�%x(�H+�<f��-�(HB�����L�����)Х��3�f&m]:�Hc9N8��-q"� ���y�3��G�iŇ��{i�����<����Ձj}��r���(�#��v�X`I�o 塺��]��KNB��Ra�\��CJ,�@�8��׉D�WKŋ�Y䦣����p��Ǐh-�Ga	�y@��:hv_:��K���uj����&�1Y�I>�e��ϗ�Jb�V��N2����4n�5���-�d���tb�3U��1��=��9����Zo��u,�����x����� _P[UW�ac3����ci�\���$Gq�q�ŵ|ޞ�Z�p�a,����@{4�(���:��&#J }��Pj�'vw�z��z[��ۺ�W��'��dU�hT���z�UFb�v��3��U�lԤ7��ŧ<�W��*����^70��Ii�h��F8J���5�':���J�k�����m��,�G��%?c��5D�H��u!�̘� 	6�gڈ&�dj8��fէ��?[&:��m�������\�PEZ�71'�}~%j
H��o	���D��^�����%���/� �1Qr$����X8@��&���x�="�Y����i<�$:<�9K�>A
��D�J�$�Lc��nx�y+*���u���^��1�9�؆���~�T�!����$�Ƙ��-�8�_�t|2����`JӚȶҧ^f����%�,#��2�u�mߑ ���ǠWߘ�
�i��Զ��E>�����Zf
\킨i!m���B�:�(��uH�N��%4����J��/�P��|�5T�Ӗ� �\�t%�Om��\r0[��d3M�-6�V�s��SAVG{w�M��H*���?"-��0a�Q��9��5#å����ӯw])�.W�Z��{+�0��6��:�ϞR���o�_>9
6�̿��97?���Z�Ph�΁Y�H+4���|��^i?�M��9*�S�ƽz�@�1��S�wo�V����������1B*���U�pfF��8Kgg�U31�zk�����f���m5�b���)�d9S����qb�1[`YZζ�yV)��x��>��u�$x��9�.��t�^J�f�;M��s��__����Ӱ#s�G��&�|?U��M�s�sg�/��܊@�K\�!���x����twh7�@A�#�'��x ��Ѝ�ϹF�)X��ڢP�\����J�zmAVo�r;�?=t�wP[5�B[ɔ0hs�Y�����s����!�4?�����|}|ؖM^>��nټ겸0���()�THC�,S�~�c���d�Us�Ezv��?�N����������@�Ҹ���6�����*���I����;�Թ��o6��d^��Cb�9�E��j�����9�4��v�[q��6}�Bn~N���>��t�~��A�;ݚb�  ��Q1���q���a�`�|�5~� =8&feo|�xP��-.�|U����I�Y�@��V.4�E�f��E�'i�B$�7�T>���� j(������� h�G�6t/Q�ǮȜK�I9)�ժ�j^���/ĥ����L'Ms�	?�0��[��1qv!R�!����J�n&4Bo՝���5`5���Y̒$�~l\�J_
�Zo$n$��G.w֫���6���!l�?
{�)0��z����T���e4l���SL"5�����y��C/r�F�j��nď�� ��_����}���Z�O�u�7�@�N�mBe�LE�c6�/s��9���8aZ����"�"����a {I�@,3���+�6�.+�?�⫐��#���g�v�O�:΁��w��:��HHؘ���W�xYL�W��Q��G���,D5�S3-_Q��0F�l�L.|OvͲ�IV�\OI�4+�D^�;��Y�'[o�SFkB9�Z�����#�`�S�[|	�{d�;46��5MɍX&�t�m�܈�p�N�S�X(k� �ǼZW��Xz�lϲ�bl�M�=�4��~����c�7���"蹰��F�ל��
�@��V���Y$Y��ė[���|R�g��L93[�&�f`���8�35F!)���@�_�#�$�Һjt�����֗��Y�����Y#��1k&��7��lA��Έ�������a�s�W��C!�r��׉[����T\<^��|]j�+�C�ǻȇn����s#�:���vR vu?�{��)��@x��!�`[���ц����˕c���S'e�+<�Uy5cƟ�P�^5	��l��3��ϸ�+��&�xlh �Ht=ڑ�����3������bl�Ύ��F���䭺��ßQe����
�+�Dg�2����)3��u�FR�)���M�"�!��{��av�	/��Z���5Z��{J5�q<��=W�1���N����[�uC�Q�@I������\�7��V�%3�h~�|���*��ۥ�'�����4o{|�C }�j_9ƫc9��o";p_Gg�By ��Xtě�O���\�'jwfX������S0Nd��UC��;C7�[#���q�Ξ
Wbv����5;�+����Ե���/��� ]}�����;U�}��d������{w4�����\�߽��9&��^Os��$"h�#���/ �X��kkV6;�$�%R�N�߶߇ �$�9!t��{9�qp t�x:ς(Ʈcs��8��0�@�}+ub�>g~��c���}G{\��̴v��+�rVU�4FA]�'�w�l5�b,���٥���B�� it�R�J�6����|Tv�+5 ُ�Z9ԧd%�,�����3R0�J�
���v�%"�Z�8%;x�Vx��>F�S��5Nw��� �Z���u	fe������:)|�����?u����n^s������c᳻�~�}7��`ۚ�P������Q������\W��Y���iU	���p�L_ ��(W~�)_K?��:�8�TM<����{;}�B�+�qy�_��qXIS���#+F"�:��z��k��8ZL�o���6a`�������*mP�/��jV�t
����V�'���ܥ`�������	��xX_h�� �]��?n���� ���2���;,�q�����[Zf����
���wA2<�̒wܔ�W�.A���%(�s�tCw`��)2�Šо5`����x�]W�̇|�����VO�>�Q�>;��?�D�A�.���y�B���F���Vb�ҤE��`h���v��F�O��̵��wѰ.�z�V�7��XȏT(Li^Q��!���;W�M0�H�K��)����P�'�F'E	*�K���o+ܷLP_��#<�[i����RCHٓ�JI���s��ć%�Vu�KJ�4ԙ>|�2�Ny�,m�
�J����.�I�˩�e4Afi�o����#��g&Mo sU $�H^��Â�=9�w|"����O*���1����b�Pp���_�gOՄ�uD8��;Οj|jI������dq���#����RC�^t'������}��CO�H�? ���&�<��HٺY�ތ9g�*��n�ne��W积9xpF�V6�o/�M�c��{f���V���?�Uy�u�Қ�&���f_�⏕���@�R��xS��o^��D)��}�HL�(��A7%X���l����ܟۍ�%��̰b|�R��r��l1A�#�D�.�QRr=�+�::��ϺT�Nh�s`ϋI,"��m�;kL��Y���>��W�3Cy��,'�����C2{p��nߖ�M���/�;]��\��]��RZ�R��]Xr�Rݳ�i���k�4e���|���� ��ZR�dmw@�#GpȨȖ2�P�9��M��M��5�`Y�.�76��n�w��!��o�t9���j^�S�X ��L�����	����Ǜ�zi����E��d�?j�\��3'�C �s����@�.�G�8	����+���j��0����Q��c��ku��m��T�D�-����()k��)b��ʼZ�y��eE	��+�����B�P*�͘�EH��xPs\ɯ�1?D�A����_}bV�1�<����x�y��<��_�A�X;5�.��S��!�H������d}]Y��=dhv�w�{����L�t�,��u��FE��^�%�|����[��b]p�ţO�ٰi1מ��u!�����}R�`f� �Z� y�;z� ?�I�9f7�g�����%�S ��Կ��~����ډ�#��A����3�t�/��g6:�1S���@�z�zn�9����k���eXQƐ&`�-N/)6��2�a���/z}�i�a�:�b�6����dCs���/�*T��|E�*��%v���^,�~ rV����۷[\�X�|>���}���F�iTMǋ���׵���u`K�Hriۙ�+hF�U�+��3�b���t����V�e�����Z�F���T>������P���*[�|�} ���Kh�y4u(E4#�s���"����s����y�4F�:��n�^��k���WE�4{�Ui\��]��R�;��^01F:Y0V��q,�`��|���w��ƪ��;z�p��CL�pѺ���c����Ѭ�8� �Fds�"�ǿ�F�{� �O�D�k�z�yna!d�%�����
LZ6�' D<E�����/w���z5���@rG�������
�N"?+��l �~:w݆�4�3��1�Q�;��C��m�~`߾��7��4XV�D��S�!d�#x��#@3�Y�[e`��A���u͟�������!�J��gړ��QN. B��qf��o���hI@$%�옰���\�uA���h���T����w��%8�v���"�J��9�56�l3����g�D��'&�$:���x�hN%̟u�ad�Y�ά0����f�D����և�}�T.���0;�j)y�D���_W&�@�D[����$MDh��Sۿ��X=��fň��P�wnKH$��������l�M!oWx9V�^�!}���2cf�N��b&e��PU�k\���j���Σ"��Ir�`�*#�`�9B��-����
�7�N�[6;8���Y�*rST&i���Շp�,���˜��� =s|Z���}?-���b��{�z��P?>,#v��"��*�?Z�BnD��>��QH�՜����q���>����۹%��xyˀ��f��<�1Z�5Kɰ���eoѲ7��Y��eHF�~3Fp��%D� V�=ծLª�����*q����l ��ҝ� u��ܪ���b�`4���(���o�����U��;/R��t���΋Gq"�Ym��ꮖ4��y	����Q�>�y��N$���͡�r��l�_&/~��,���x�V]D��+Y#?���Kx�F��a�^A�=햡ZR�\�ڰ����=
�D���� 0�i��>ˍ*����ʕ'��۫��n������lt��T��Q���KĐ`��9+�z����,\xS #c�㇂9$�]�ԀpY�ș�P����Ԟ�tv���BXp	_B�U�製�"�WKE�9@��.�%�&��R����I8���z���7)%+�2�"�G�*?��F��G�ҟ��Ct��D�i��I�\��U�z�GG �u�i�|�FsG�~&�n�a��q��CLD���L>����&4��:x��pېv�d����ʰ	+�������WO{��J:����l蒖��d4�[�g؅��#�Hm�"?o��6��9B�) ��]/�}����n�5�.|8ߋx��3]w�l�3.2�P���2��s�8��$���t樆e�_�����!�PT���B���HS�����{Y l�9f�3�WM��x9?G&����P��p�E��D���f�����#^+w��Y�/+hAht9[��rی�ޖ~kuZߧ���P����a�H�s-Ÿe�'Xy�� �i��	�m1�F�� �����hbA��NJz����*��˞��#v?C��}W5Ьp�����[vI�Y�=.������ی�_
a�
���-��۬o=Lt�!%�dS��`��1,���Cz	%�$��坎�����{6 ^��`��І���Z��3�0��������:X�d�-5A�,��<�70���	H�
��9F�3���QVE�L��f��z�h������e�sۉMZ�C
�[ؽ�/-�h��w�f�����b2ո��[�`t�\���k7P�_sM�U݊Ĉ�!9�+��P�b��8���r;;�����6	W8��<"�ӓ��P��y7�x`��:�"�^ǔY̲'��75�ծ�4���#�|Xf���2�}�ʁ�e�v�Y� ���e���!ɝ��ޮ���WRVw9FBZ>[���|2�8^vܦ@�^��.2���u�K�k���>zָÒ��;��b
C4Y��Z��WD�g�XB+��k � �q)�4�P����]>�u?Fs"3w���Ք��i��u��#��yp��ˬ��H ge���SM�D����&��k���j�^s%�Y��#��Z��e��"�\��=��ʲS��ҽ>���f]�쥈	F�����BO�ޤVG����R��"�queq���En��-��:C�)N�����=Z���3�]�oȎc��z�Z�P� �AR�.J��m��Y	�O����d����@^k���;�ZVP����m�مA���2�I�������<��G(�7�C(y�)jle2TE�2�Wx�c��F��U\�~(��.���)�@<ѫ"�I���}���n�B��co�r��c�i<F��#2�M�;B%�l���Etۃ�����j\4`�Z�@*ç�<"0�Մe�nN�����w���.�evu��/c{�5�Q��B�:r^K�~�|�Bs؞}C),U�q���@����
���)�L�B7���H�����m����>��z�ت���%t�(��.�l&C8�`yϱ����6�P�EW�5�E��
�P�wt���q�z"�nW�Z2N#d�բ8���;�,��e��a�< ��@��G����	���/+��K��PW�q8Ά�
��GN���ک���?���M449Z����ܶX�
���ZM6f��k#
���YD�1h�d�2��9�ĕF��c��X/�� +CA#0I6�<;O�y+�P��`En�qʰ�-7Z��!�k	m��>��;�6���%�������ZI��щ��0���4���ʴ
t^�]�KԹ8C����h�0,�?��1���^L��N�ʪ�m�S�X��֢L?�;�~/�/��{��X�ʊ��r1Q����
/�֥���g������F|���i*�������5���fKהGX̮**���V;^�����l_^� hy,E���L-B=vq�ñΔEQ[srzY���Mђǫ�;8�(%�/}���&)��Y�H�,/�1��|rr�<����ŕ5�O#g���JH��Y,��]��:37/�۟�V�1��G��������u$%�(m떁��nVI�й�UeXj�Z�vn���呵Y�2�\��u~~� H�R����-��ۢ�fI���M��<l[���X'*��x�7�a�?����!�{����$�/{��f?`w��>��tx�����{ ��ݎqF��+��������3��.S�Fu;����YD&��U���EA����J*5�A�,Vf-�r��N72���B�P��A/�Ejh���ɡ�iϿ��]"��D"�Յ���0�1�or!��oD�F�D�\n'YMJ�] .�wxU����1lt�/@�BO�	~'����j�+t:c���(�3SR�xWl�O\"
|جքB�������"�㙨G�ׅP��b[\O��+�I����.�Ql�G����%P:/��"�Ds���k��84�-̔�t�T��4�Lj��UR��b:��ܦ�,�#�S&����Ӕ:̛`�2$��K�1A�ƕ*��5T4tdH�v"8*R^�$� �c v�l���C��e�=V���q��()驯�)u��YնY��4N9���c�H����ct�L��m�x��(�`ì/��t���?����ށc��N)��ufv*�%>���7�Ŧ3��,#� ��1��]�9ď����{?azga���o??}�=Sb z�@������-�!$�k����&%;;�f�/���;��^��
�ŉ���+�N+K���v�ʏ�# -[9�`�ĭc�a�.�����Ӏŗ�!/ ��g���'��rO��f&���}�P��;���1�k��OOL�x��kQv��m.�x�B�;Kc����e͇d�R=@{8��#��+-��2�2�:�\��(̼$�@�Øla8נ ����-��I�W�*��$�JnjH�w���+~������i.��(��pEӵ�b�W��`���6�IS �n6�3V�� N�5�L<N�2R{T)Ou�RxV�'��3K3���|����Y�l�B��Lq������+a?A-U��	�ڑ�1��J�q���	��9����>���-G�1���}Q^�y�E�F�6���Qf)ס��X�,�OG����Py��m����X,�soa�'����fS�ۧH�٦�Ͽ�47����A��=f�{p�| o�eM
P�xl���p�xW�A����k��7�b�&�����ehc�=�76U�t��7z���4��;|tz�z�ٕ�ያ����bCDz�6��*��_X.��x�bA�~w��>��(G�KTD�h��~D�z��+���!.e=����C��f�Җ'=Ձf�mZ���9e~� ����U�_����?�%�;�4xm����k��V���d�Q��GXoKg#:���Rf��ɻ
]f��uZ�q��F(5�������:f�G �$��]�}���r<4�\��3O�L��% �?�E�|�J�Tg�d
�+�*4��]X����̷V�]�P������T�h'd�#4pc��V6�
���)�8�q�pWU�yNS_��==O�?O��!�.�0�a��&��k�J������}�[7�?�r�4�伂��\^��LK[<1��dV<QB��)���=�ݫ9�Y@#*���z�l��+X����3�h��>A\�G�!�2;���_/��ɋ�5�>ɂ�;G�n�u�%F0o^�����ȷ��Fg��p��t	���t:�t>p���W+E"-�xf�ƥ�Ν�#'���i%�V����cŇ��K[!ܿ��������?)�s[�}����zNfm��.\�y�,J�3^��v#�f\Py������c�MB�W���^����o9�[ƺ0潷�/��Z�?G��T�9�
:���h4da��z3�>����-X�m.�R���1�I�o^�� $dY:�z����Y�d��P^�$D�k,�rXr �'�\�No�0�㩜�(�n�f>�gdj�'�������E�g���D�UWJ�XebR�t?�({��ܣ�9p���8����t7��7&c�x�)�;�W C堆���R|$��>��\����[1*}��boJ��-�M\z�䈿ǈ\�}e����eC��g��Pf�i���AƘQw�\
���$�7����C�jE��U��K��㲼'�x��t�x��Re�B���\���;�iN�+W��_���t�ח}5Z8�@8;F����W�aU��o��o_���D��>ɦ��F�
�W�9^Qw�#-b@UV�Q%�����@�.�-�d�O^���'�ᕗ���x�ӥ��0�uEZHĒ��-o8��*���3�~��o��18�q��?�5�|�i!yk������{VɢMi�����6�^!Q;���Yof�z�]����t�V4�1�j�ǧ�0,�ۓǙ��Y��( �r&��W@ �v,��9�?v	W��d��A�a�2�>Erd������������i:3��A���z�J��ǞeWk��گ���)ҷO\(�^WpV�G�w�5Av��EO/���	5� p`�ל��A�=��������O6���y�5�����lFƮ>u��v�M�s�B&�Ş�0*\��������9*���<Ώ�8i��cӋ��R1��O�&n�"8�mBsj���������ۺU�����O�н�S���H�v�c�up8uH����2���uP�c��l'�@�b��߰c��s�.�-'�N��,��}�D��ﷳ+�#�'-"]P��y��ͺ� ���B:�Q.4:�<3�{k�<W�b�K��`�7l;�2X?�	��h4��T�n�e�:m�f������ G
�\��v��ä_�쮭َ���O�e����"�^�
���M�!�
G~��g��)��i��ۊ�~%#�92�O�%��<��^��ĀV�����H�lۯ�B!����f�ƃ��'����� Ͼ��߄ ��h��"�F��eFF���;�	�H��8DFe�]�٘��< ��ߦ(�,�%I��Z�eh�|/�P����#�UĤ�c'6�NV�	�<PE9����%��V���	�{ziO
����q0��m買ߪ,���I���I<���TS�b��W���D�ωZ;��c$�O[54�ŗ�{��8��YEko�P�c)-_�N\I����C�k��H�g���t$dc��c02�M�^�#����s+@���G��-�{3�\�tn�g9�*��*�j�1�����<|7k�_�Ƭ�~�.�|�xY�WyGռM�i���y�$����'}�a��Yݪ�I2�^�I��u]�;c-i��w¹n�(hm!_����O�֣d�ŗ���l0��6�Y���&�l��AЍ�6M����6��![xMS�V��.�e�|X۝�V��_�&`�k�>h�DWO���g^j����s�V��8��8J������@IC����4Pa��D�蛭�g7�8�7�yv�[����;x$o����T�Ӟ����S9�x�C��]}�I��n��Zp�y�U�Q�>6� �X�@��Q���f��g���� �����`���B n��嘝u�V�>�o��k�z�/��,������]t�������h�7J�ؐY�����OiN�%R��jy�����U�1JOJT�q�`��(�K1�Gɯ���%--�y����;��K��xԗMߧN���o�
��2G�5;8;A0�VF�#�ö�{ڿ�,�� �4c7�&�о�7�����EA88L�q`�@�O�C��^rH|r���5[0k��I=�bv6�[[u�+dB�8r]�7􎟪+{M�(EN�qs�:��������Df���m�]��s#� ��Z�%yBTynmەԳ[�ț$(����5�&����(r�ԭ�[��Ʃx��0�6��ʔp\��p�cMp��?g���N�b�3��� ���_ʫ�>����<���O/�n�<B�`9���]i�2��{���6�/�=6�Y)��ⱀ�/i�Z(��n��֮�O��<�@R��h��K�p���b��P�1z6�Kڷ⧱X��fZU?PG�C�|^��p�q�ƛ��� G1'�InӤ���4v�:�N�����䚤J�\���
zu9��C��{ѐ"fS����ϋPy�n).�-��.G��B_�{1bu��b�C�}SҡVYlGC)�7��d 8/�ϲ����q:Of�bʮ%��w��,_ֳB<k���R2	f�5]�	]�s��m�����"<j"aQMEm5k���Q�f�x���ܫ�g�ꏌo���'9�h���x7y�'�Hy�.��ܵϢλ5�q#^�Zn�Q�54h��� P������L���*���D6j�W�Q���'�L�����R���D���KS�NȞ�p��	���D�9f�.<�-|���Ժ�H�Y���Ee�e&?!��y��xl|!�G(��qc9x����F��7��x���L�/�xq���%��������IxZ�A�������ף	xK�ƸL�g��h�Aew��g�-@�fv�Ls,�w��grq��NвB$[X��ؾ������BMn�g�ž��`��GA��fy��x�[�Ĳ�)q��'j��r6J�%@��~�����S'�4U�[0��M.�p`��k��ۻ&�EJ��b�[=drn���4X�y9;~<��X��j�a��R+�G�����{��s%of�#��pt���3��B�v�ݙK�#'i��#I}��	#�IF��g#���z��{@:H�"�^�[Yt�8�!�f�uϞ�/݁�	3��㼼�R��#?;��en�o�C�5���ݺ���Xa����(�6�/B�q�E(�ܣ��@a-�G� ��/	�ܤv��Gd\�����r���Y1Z9��J+׍k;���%
s"���7WC����Mżx��s4D�+�PTX�U	�x�l:W��8���*��X8�rci�!T����)��D�a�U�-9k�?ث���Z=H�j�p� 6��|$���|@fǌ�[�fU�Ѱ���"�Ɏ�B$b�uR�"7�?�l�Ҁ �=�y��V��t���Dz֛�G 9,3���~��V������8���A�o 0����I����c�K0[������?G�Gb��n	�[2+8���,qy�N�U�U�Qow U!{����>;>�6�Y�W=���~���P�+G��p8j�<o3i��&#*���%��['tRq�W*�a�q��`�G�i>g�e�����U<�<��,��e�ʥ�_�b�i	���jU����]��������]�]�R�0��U��;)�d01.�R��/��)%�U�p+g֢�~b���XE5�_�0�ގ��{�3��/-g�9�Nx��Gс�0$A��qc��?x��.�zf;8�BÐ���㱂Ԭd`3'�kkFm��+1����ڴvQ;/���|�
緂j�ο�_E��!�&K%'ǟ�ѯ��L+u� �d��F�`� ����fw΃AX��?FnC�Ǭ�-��� �q:�ԅ�I�~tQ��0�$���b��N�m,��Į�) �[ʹ-�+��$C�{#�D��7�g6[�
��p�h�K+�9�k#����nr4t*�V��鏠 ,oS��^5�6!�7s�CX@��� ��g��5L~o׽T|cAtm��O��^L��Y��1�����1���M��
t�bp���]~�B+i;��]��d��K'ܧ����CH��l��HO謖��0��S/)�����7~��	$6mNMzND�F��M[�O�7pl~uli���5o�����r��cT"��d~1#Q,Ɏ.QM��li%�Q�yMA �^�͛�@P��?�U����
�U���MI��T��7�"c+q�b6�4N���0K"Qk �	@�R劽�6'�d��!H�h�o[�^��r W�i(�uuԙ)�qFBj�s�؏t0��:7�V)��<���̘K鳣 0PUP�`T�%{"|�F��m���<g78	`��0z_׳"���t[y��eV��������:+�6�tڝ�9��6�	y�~ډ�%l�<����]|x*�n������;p�?"v��x�(�N7�@E(��,�(�1�
l�g��E�\����$a�w��Sۄ>I�·� _T6�?f�"�^Ly�J�+�2mF%d�J�O�%v�B��;�߸ӻ�#_ ����t;m�C>�
ٕ
��2�T=cw�
M@�A�>�)�T����\��Jz���sβ`fs:�
�D���ƫ���%[�w*��R�,_��P�*�ԗ��Uf����\_ݶ�H���c�C��ATҀ=��at�j�ۇ�u�@p8M�N��I�T�	B��^2(f��q��C.W�ذ����b  �B�s����$����kN�U�7��6<"��F܉0Vv7M�N�A�4f���]9a�^$�SCgSP�u=,�s����D��%���6ヵ�`a9bo�l�3�6�^�9�j{)p�'�����7�g��e�`���^f���ɿe�~��Z��<�J�L}���'9��huQx=�Ζq b�fբT9�m\�<��_6uFE�14��������=?r���3��.���#;yȇ���.�I���_5��v*�J�h�z�+iV "%���mD���y�+1�/I.ګd���
aih����L�yc�y��
飯1�;E\�F�4xG��77*��y�����ʢ���"�a�{_L�.���CCp�����@���K�����}7 �����C3Z�p.�X.�� ��r&��(����k�ڿ���lJJ^��8_[/���p(\��9��Lr_�%i-�qӑ(�\� g]m�򋯚���ݿ�hT�1��������S�G�k��E
��O�0��i�
Gu�:�|bjjGh��Ժ�{�x�����z��X���&��?]6���D���s�]$���[�{��
�
TΤ���0̉ڈ�x�cǐ��c�{|��<��l6��2ji�e��^�+�ﲸM�L�9�^���װH�X�F��G���_����Җ��Z���k�>�7w�DyhLi�PI���n�ǾlXb�z�J�fw�N���JA�2S�����N�`�^Ǆ>�í5�:We,"?(e��pέĮ�f,�Es�`
�j��Φٝ0"�;C\QK�K��Z~�Y�kE�X�~�l��Rl�W�{��gy-G��p�\��3���76��	.�ʞ��C!��O`�@����Iw\ ���iUJ�[Bf�"7�ك�i3��0�$��|
g2  O�:�ĻDٵ5���!�~D�}2P��#>l���&E�oa��۴3����G��ɘ�K|��)��:�<D�AON2a`�����j>x��\�1��1���U��S�}�ݯ��Oi��?�T!0����U�i���zi.��%PKM&�G[�u󸲮�B��:��J#�����	N[
��ʪS�I��R�}�ĕp]�����piE�)�����A��)�̇8�=E��>�NW�iZB��VV�<��"K(���,)�8��@�Y�,�E���ȝ-�{�pfY�E��3#�"9nK���u�ĕ�m�Z��'QO��2���+��0B�@4I�.����(���C׏ͽ֔����ZA;i�,ꊘ!�$K�x�{�bzm��o�Nha!a���X�Q�(�B��YÅ���&ۖؓ#ke^�{X+r��ae@�����"j�{��?�K�
qz6�Q�I��|9og]�;�'�c���U��2خľ]
czU))���q$�a��M�r�ɮ;�4E������kc]`~��A�iR]���O�Lw�ݹ��x�g�*�0�ݯ,���t��~��k��>�b�r��S��W��$�&��ٯߍrF������/m��5����lαE�J�U;Tc0���B-�=06�ؒR��y�x�-N�y��z�vH��i�H%[dK}'�	K��VF�����A�oMz<v�u	�V�g�B������"7q:�ʝ9'��L}T�8��wy��j`��%P@?�D�Ziˠ��J��6�S�lמ}��E�'��J{�S%�¹����o� �*��.\n���k/�8�?�c�-�h�)z�7k0N���Ǐ���&����|Ǵ�����t,�6�|:��j�������km�.e-��Rƶ�8�(��	��d�b%���i�,��J��B�1��'������p��[nK+MzL��U�rL����Ż*���S�r��X�.����S��84�����-���"�m�J����4�x�����*�;ڇx�oHb�m"����:�E�M����S��'0�9����\������Fm1<��
,A���0��~}�c�?��:,��$�s�އU�(�K,��&W�<�:�����C�P:__�Vޑy������o���`�Io8��.�T�D����@����9B,:2%P��kMBG�jC�e|#ta���MH����L�%���>���O�젏���&���G���,��S��ؒ��GLS5�L��&�������bDQ8#]�eN"�p���g�O���SO�I�qi�ȇ�밮����s��"FT�d�b��C4 ��N�n,�'!&�\��*^�����h�fA&�fM(�<�\�F���bC
"a%�cH_���'
޹����]�I~�	�!H�:���C
i\��,k���%^�z�mף6�U:J�1⸖I��OBQ�go�P��
��j�k�Ѽ�r���cjL��H�J��ꦋ���U��Bt���Ji꒎x���A@߼c�C���Y���+�����a��"��O��"�h��r�{����䰘��]a )S�V\�C{ޫ�~�����s��ӛn��]�~'��%���j����p4�l�C�S�{� }����p$D"q|�k&��u����ې�ET9�\D����(���Q���[9���XJe�'��j��:�.V��89E5��͹'.�UU�Iay|�Sk�@�K�)v3�h�U��Q	 �>�jƌ���82g��ȺE~�zw������~��H�o-�]��o�Mݐ��W��*��GK��T��B��>�#���W�j_!���<�G��'���K6�*x�9�0��Ɠ<��"����׭k���;�w�Xi�:�}ċ�Q*U��1I#+�w�Z�;-R����'*��l ��Y/q5�#2�C�X���`���qNך:K%����-mR�R���ʝ�.�`���1�l�z�W�V��LɌ�P�+p����H���h�XO��W�hhC w�T	_u�����m|�Ź ��G�+��Jr�V�|Xk�&�;f�lo��V(wc�}#v"y��2:k3F�ң�Ãs3@�9�����S/r_�I5�W^���dHHl@�K&�@����-8����T�Y&��i�M_��覩�XU�"�E�%e��&=�x�TC(�RD���1�S8�+��?� ds@���Ċ��]��^n��z���ɈY���R#�,��a�%�};��o!B��E!��T/{�l�Xe�?����/�8^��"`|������)�ܱ-S����g7�8���H���Y�	���P��+���V��!���A��8 'jt�0Y�D*}1۠N�5"��e	w�I�k,eZ�L��r֭��X�|���g��*���Wh��9���fĭ�9�61\t�NS�z��~b�!�7u�&���S�f_^9�D6vHշ�����I%��k��%7j�:�����n͡��8�,�|�7�t�B"�Q^�,5*=z�BHYUQ�h�m����L��-�Ō>��N[
���A��*��5]��O��Ly�m7ˍ��d�[7�����P
�P���{Ѳ��}�����VK�~�(+���)�.8�(M�����c��V��8�_%��5
�i�eFU��8m�t�����C��z�gD�Wl9ї�6��@!r? l��&��+��Y���s\~YR�Ӟw@(nmD������J�����V�H2bHwr�j����)�h�K>���� }��E�s�ʽ9���n2�9�͔UH� ��zt$s)���ְ���J��MtT��,������s�3�� �!��6�6�FD�f�i� �	Bͻ�R;/*�@���傜��M��%�������f�1Zӈ(e@W\�������\ W���+��4S�V_B@�H��	l s;�}�{��������JƊ؝_��GllR#���)2�$��x*��i��q�8a�sNKk�'�,I5�1uu��]�$.:��t%�)^�z[�Yh}�82���ޕ�����.�E�
WA�x:��g@��ɋ.�Iet�ab�c��J��9 �&p����Nt[�)D�NTν;ވ�T��{�5�<��[��.��ظ�n�^�S����ރ���qă㤪"{�Um�Skb���\��qo�*�#����� G޴���� J���Jo�l�3V���}bֲ��#���px�*EZ�g�ʀ�����ؿ�d��U�0O��럠��9*����<�+wK��$�.z���V�m8�>o��n�3͡�"����l8l ���rSך�>����Cz�鉣��}�Go���\�k�$��/�0j\�� ���M_�@��h�F�&�n�"����Ģ
����c1�����4@��qc�re��J�׳f��a���n��L���*�U�U���ـ��\��I�OIz�{��ge6��X 5���T�.�
vbفu���R$��@(�,�䔚O�41	���Wa1����0)��6	K����9�Q���7�8�T���=�����v�<��3�*�1�q*ym����u�;���M��N�����[g�k��5��\^m��lF��H6g%�&θ�f%嬋��7j�g,q�4�A1Ub(���*>!
&/���D���ýL�M����`�б���!ކ>x�$\���K(��A�[�����t%��~�E}5Q�[H�90��9Ѯ�����gA�>�"q��Ve��ϟގ�L���Gw���4��?V���7ڹ�$OM
Kֆ��#'CYUCđGܣ7a. [�������t��x���~vO¶l���'��|��~m��C�Ǎ�N�y ��ҩ��\�(��i]Cj�-Î�����#��x2�UfyY��t�n���%_7Lmj�ȋ�M��m��	�`gq�8��)�g�K݊zD֠E��bQ�E���>�L&?��d<��P��8 j�o���=�
��V]��]�X�n�la�z-��
[W	9r�eXIO��1p��.B$�:������q�wk�N�l�V��l��=��[����R��q����k'�`������:��^��6�,g&�S�̛c)���-]�h�A��]�p9:ZEؔSo�`R琤Z�V��#O8�� 5�p�2�<���è	�/�n�w�Q�A\:1��+Lπʽ\�<_����Зt��{��J`���Z>�`��>H�OXo�'IC��2�����<�����q�j!�-ϭOP�!q��򛢽=]c�'�&Ы���&�*��چ�J��}6+2��T|�ߨ�h�t^nF]�"�G�� ے�憙�qI�0�!���xݜ-�1C,���&��=ʽ=�N���ʍ��^�J���+l�-�� �K����?ܞ�NKj��g\��p$T~���fh"��G����c��#9����fï��������ⓔ �� ���J����ו�0��{��ےx���M<P�Y�9{7�I��%#Sdh�3�\ ��Z�l}����a����8kF����P�B�� Sg�Ů���܂K��i��*3�i����Ʌz���6T~�eL�V`S�?������˻{�@I   5
pW�^N ޹��������g�    YZ