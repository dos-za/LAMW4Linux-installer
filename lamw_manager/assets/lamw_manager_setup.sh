#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3613009939"
MD5="ee77db822dbcb1d5f1dd3c5a4ebe1d9b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21492"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Fri Nov 29 20:44:42 -03 2019
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
	echo OLDUSIZE=132
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
� j��]�<�v�6��+>J�'qZ��c;�]v�"ˎ�ҕ�$�$G�!�1Er	R����˞�c`!/vg ~�e;i�ݻ7�a��`0�7@����Ӏ���m�n>�n����A����Ɠ͝����fcs�����|"�!,�u�n�����觮;��b�0]sN���o=��.���Ns�i|�����~�OlW���L�j��SU������-ӢdF-����f���c�#�Z���l(ն���Ԧ���#�R�/���F�I��R݇���Л��f��#�P6l?D��%�,�*��� $ތ��;����Zǯ`zT'�3 hp�I.��i@f^@T�uH�]%����/�I�^�о�yvzh4����ph���jҀ��ݓ�utd��,h.��{������θ������꜌:��7��6�2~�>7T��B��������!��NC/�*��9��=#o��V���kŵ���T���a0����Zc]�u��ۜ�||C����gq-7��p��T�0 ��L���s5vF��((�����E�M#��l��G�D�$��Å���Sϝ��U$X�كU����3:='���>b�"�#����(��Ѡˆ�(����S}x�O�J��Ű����3�-����qb�k"����&,��*vM�"��s8��i]z���x����
����v-��	;<=�@�P7Ԅ�������N��ڸ�ծ�K�S����XLB�2���x���1~��ʛ�,�;� �
��@S�9��:������� �L*�jXK�RMgDn^�(�]�,:3#'�P ���0��l"�SK���8U*Y�kZ;k�slІv(f��s;�s����N	u�d�;��~5j��u:z�tGЖ�&�N��*��,[��\���2T�#��%��I�^W�jZ)�_%�"r����~\1_i,��#\$�(�R�$!�LM
�J��榰�n+o��]���R��'��P��ܧR�41X5�|�D��(s"�o�?f0��Q�r�Y��&�ɇ��IK|�������;'C��Cj����3��;[[k�?L������;ͯ����<�.�&E��lҮRi����hs��ʯ(��G�����6�]Lׂ�|j)D�1:��:N�K��*���:*@8��ܿ#�onnn����������JFϻCr�=�����w�u1b���{'���Ag�L��Q��"�0������xQa�ͣ���{2�gӅLb��,<˞ِ�@0���	%���z�,����f�DT'+���ȯ��T�!q�O4M���c/lL&w��2�̈�#$��Y�-���k:12�1�풳0�ٮ�'�궧��������V�|���#�/}�e<�=3&0^E���͙N#��P�L����~���:���~�}��_���ÿY�����Z����?�«6�lǢA��}��6{k��o>������?����7������g � a깡	��� �m��̩Kv� B���G����)�I�5h?���H˵϶��cW��44!F���?�<2�qgZ&q=�o�7�X�[~�{`�K��b����X�Rx�t�ocݹ�To�{h�p<�Gi%�f,�u��XfX�O�����X=�Dn��u�1 �L,�]z1�8��	/����aG�]�c��H�����̜*)9͌�'�F���s:8�B5���ҭ�
�D1N��ؤ�М3=���'�Ƹ�J� ����l�o����@w�	�PU	�}p��!D�է�y�s�i;�z��/;�a�wb�K�YzM�f\G[ ���[��؝��$˸�ag�栠hs7ZYWZ�rq �!(�\yQ3��x
������a��\t)y��x������FaP�a�%O-|N���|��cO=>w��ɍ��Ϳ���ݾ���/I�����+�	S�k�%ݕ0�@u��ٹ8��g���9��&cۈ+�j-7H%Q�ճ�r�E�j릺�\�[����"�R�oz��=U�wi�����+�px��G(�dq�����I�Ga�?�Z$+�f��M�5�)�x�v����[��Mu|���ۏ�L���'����{�.�̄����	���ɨuxÍcɌ7uy�ꠏ��oj��RA,�>���Յޔ`ã�X�K�A�DT�AO	�V��$g����$4��>���� ��ȋ ���pEy�Mm�sZ�B���f��+�EJ %�T��A�`��������GR[&���x�vF�	���f!. �s���0�izá l� ��i�h��˃��'*I��?�t_�3��*_n� ��$nIU���I�ıw:hwG%/r`��Vl4~����~�������O/w��,;O�F.^�`Ӟ�nL�E:A��� �2i�5Y}j�'��q��F%�j�p�V�d�%���Ǧ�R�W1�@���v�����$��ؿ
$��W@^����j�@:�l�:HT�˺�
�g;[��pCV���n�CL>���������Qw�@���qy*��$��c�f��db��r'3>�M�X.U?n���;��#9�sA�r�^4Ƿ��M�!�DT��[؆��4�x�y�0L�+[r���{���m�M��rp�:��h�N����8���0�IȚ�-Q}�����%�$.��
99�+f����-�)�ʗGb%v��l\�)�Iߜ��s*<�~�uz4�o����$a�]�^�K/IHj�0|S�}�n>z���2���*��}��_3b�&Өe�+�������vV����O����\�]`�W3����Iz\��K$����e��2{�P^���7w�Q��׉�Jx]�^�2�.)00�vh�sD�P�q%��w-�:��ڿQpȠ���?s��` ^K\�p��\,�3�� �	|t:����K�"j�'�P�U���i ��&�A��=��l�=��<�	��>?�$Q��|�|�!uM�����;��s�?��pFO��:ǆ�Fl�~OZ���ڶ^R��h��e�d�7���{�Cm������w�7T߉�W}�>$��Q*���q"?K�nj1�uބ40,�.���1C�xZ�Ǫ\C(�6��/���P�S1����yϘd%(�-*���'WF�7_}#�E��Q�ό�K��#DU.'�Kb�D�!`�3 [T������~�f<B��j� �Nb�P�6H �Mi��<�y�xzm%? �[���x7�9�������J��ֹ�;f�j��Z��N&��q�4���'As�-��<�7�p���@.��^N�V�G�(�Pݢ���*���A����F^��1�b9��Ï�?��1A�<�J�=P�7%��D�Ķ�TA���8��DGX�J�q�8�]j�x����3I��4��D+/<劻Qg�3��܃Y_3;� S\��\P\�0<�C�����L�-q�Ђ$õ�8Ǎ�)	}*Q%�TB�b}\�nYXt��^?���q"����ذh�1(	����d j13E< U��x��@ym�������@"���u����%���=ǝH��H�'P�?BxQ 	*����d��s���]����nK{�����b����{c�Ө�O��~&d�>��H�4d�r$w�(��4(ZjP~"��~ߊ��$9#��T
[��W:�Eyf��9���2��zH�;N�{RF(&�bܿ�g�"0� ���ǌ^q1J���yo&������*���7�"���HM ��̆"*���-�I#=q4��U|}[C��U�XY1���\���թ�(O!�Јk*��1�]�³ ,��3��ۉ�v�c��[��!����#�qRHYKE:U�3gͤiJu��7���x-kz9��2��ɣ�`�y9|�1Z\����`�	�H���|/	� Oy��6{�O��Ĝ7������}��F?qhz�`��9�⍒�f?�6XW�A�)��.;��s.��
oGLG޼+%���&vֆ�}t�jQ��M�-����P�r꡸�#�2=]H��Z���ug�.�*ʵ�K�i?���s�S3�Uo�b�p'����l��u.fL�O��`�޺�����\g�h,emF�� &>e+�xg�1��?s=G���0�Zi�'�����;�� 5iSc
!m�l4r�b1O���`d�"J��I.�����#�ڀ�_�i�T,��޽�R��b	Sӻ
'�Q�����Mq�����"�����-�%:3�"��L�޺�e+뻧\����ݻy���8#�=���Kq�<�W,��_���c��I�,�&ԍF��z���ch+�\nq%���N��CV��@_P��=¾�F��3|���e@��B�/��wb��I��^P��VZw��h1o�n[�����#�̀��ͤ�/����zb.��m���z{Z�"|D�sI���7�B��iH���4�Qi<1)��|�U��.c�I	�N�e��`"X�nC�QT��`@W�F>nD��횎13A�DӕO�V�o1� )s;Rpf�[���sy������ixmρ�{���"��q�1+�������P����=�/���?Q(�]�t�r ؜o	h)"!R��X�8��L=�¤�y%V��^����!j�{}���A@i�kOpg/Ϥ7�-��i^���^�w�Xʒv.C�߻y���C�x�KӉ�Q���ך�[��[�@����k�F����҄�w[�����;�'	�Na�{!;���n���A�Åx������<���txS��������Ψ��箷��n�i�\�슅t��m�E�8�Bh!�
v)� y�E����SGC�Җ������"�����(KgK|v�eb���{�H��l�F��Mf������KHE�Y@��']�(e���7�`��eM�����@��)m�c�8���tϱ�ywk�w�du�ce���E0����Vɑ�̲�, *�jy�USV�,a�{si&�+3e�b�/:vj��^�s�D�q��Fᾷ�5saALJ>n���u#7?wP�����D1Gڛ���
=��S:��C0�=��%KG��
�<9H�"���:�����$M%6����'� X
�)�� Urd~��'J` ��S	H6w.��]�/d�٪K `Zr�''�xK��B��Q&�����hRrB/��Y	c�eґ�*՘�� ����3��"JR�ǏB�Њ}���_0�K9$uƱ�	��B�U�a�`�g��j�H]"�6V�Ҿ8?�z�_��|� Bpm-0oK;�°D䇑��l�!\���ihlƉtRq@�,u�B9���(F#������:��I�jlK�"���;w���D��K.N~t�#���1ſ�g(����>������q����R�'�3t&o�]�YwZ��:�!X˜J�����8��%�Q%�CnG��$��֍H�w<jr�|�0ɼ�B�^�Zd�Y����bT�Ս�~]^����95��V���g� �	����Y���}[w�H���"rJ��$EJ��d���h��t;�T��V��d�I���U.�٧9��/�gf���FD^�	$HJ�]53�9�H ��Ź���{h���H���j�CVm�ӯ1�)�T�5� �����	��ռ��kkucFD��+���(�p�/[�o��]y?ݓ����X+�l��Geo��Ǧ�/�k��J]�IO�)�� �� y�`��Ԩ��*����â;>�+ꄎ�'$���X�U�,��2H��X�^�s�h1S����1��{�L��^���{�E��n[1��v��+�<�ɀ�p���L��[�'[�tTڳ�ںQ�N��|c�ʜ�F��UOE. R�6��n��sJ�+���X�ُ��J.Ѽ��kNe9�
o7���+n�:7����M�nD��sI(gTM�ш6�B[x0z�5�7ЮZD:Ɍ��ZC���k� Zk�{�m���\�ԓiR��2�F�D�ܘ�5�.Z����&�^2��Ar!]3<�	x5��р��w8�8b	��3�I_����.��Apq���N�w<^6�q���[�A��]膟��y������|��8}8�&���(��?B�x�]ڴ�iU,�8Ѿ�$��W=y�K���e<��d�6I�4�?"�wՏ=���n��>ʿ,������8�����j_E���ޓ̀F��~����`@_A@�O��&Ь��	!�M��&�(~2�q�� ��h�������`:߈J�W�a�o0pX�ݟ$�D����x}�b4"�@J�b\�W�7�4�h#C�[;�/ғ�UdI��?CDrc4�A㹥���-7�`�IL�5F1����9�҃mF{*-F�$��8�}`$��YK<D�_lC�ͫ�HP�y9W�s#�����4G@]T:+��	DT����T�%ɪ��������#.�X�E���T��,�.T��Uȧ�I�@�
�)M�Nz�`����
��!"3��'�@ߞ��@� Yl���y��Á�v{O��g$X�R��6��n���]K��Q\enhT�lclw=9�b#��q�]O/�a�J��W��ӦԄ"Z+wxN}n�o&�7���^�*i��I�L!3by�/O�0n�%5n8� ȓآ�ł�F�p��-�G7=���5���ȦK�� w:�9ŵ2��P���{_Uh&��ͯ&Н 10�1b���]�|k��~��l�5�X!`�S������3>�Z%%C��{�B�}t/��Kq�1t����O�nm�����adS�x6�Y8�`H��i!��{+B�|��3�Ɏ{D������"ә/��)���_-���qG�$~���bn7�XFa	sEs*3撹l�3Ħa� sH�	��'���^�S;��YŔ�&���h�י�|�������nqJ�ɹX��/h/��?��7�;�8�)A����ز;�|�U�g+���ҽ���<TL�~����0�gݶ�H�����[�ٽ�,NGy�#����8�G������(�m��⼯�Χ��2�7�n9����
_!��G)���j6��Lَ`�9SЖ�s5�������>p���n�rkW��y�Y\���Clq1Z���ui^ܴ�沽����vFx�R)nˁRʝ���䥻�c�b�s{0�t���;�']c�,j��fǬ@'���guk����@c�y;�&�X~�����pĽ�Drҵ�D�cU,�r64ͩ���-4�Xm��r@�o�&�j�,�>�]��c�D�|ߚ��W*�>{2��Du�Z�]'��������㿥˭k����j��j8P��+Z���Zy���yAQ�\ EŬ��@1 $'ȍ
\$�,��a>_:~+���V�C&���b(� �9J��JHǌ@�wH��5��dL��-����-+��8ߙW�i{i��AEG�>}��"�֗��ӊ�f�`�m�Xe��sqFdhcDx��q9[Yi��}�����X����ں'�~8 &�rOO^W��~A�|�"�Qz�_Q8F�C?�����xm)^�?s��_'���0N��_�+$|ኲ�
��o�|UV�J3?�[�H���E_tK��	�h5��ӂC^0W=/`\��m�I40��֑�|nbݬ�*�M<Bq�ZY���]���a���gd���F���t�gg2`�*�0/��њ[ZcTN�ܘ]�a��ʚ!_�0_�%���6�(�4�	i��m�?���ʏ��0
�hc�O6r���ϰ�t�x�i}E��̠qʛ�^��>jā�<,�oRb4������.���y�Yl��]8�������=�D�_j�����"#��l�r�k��kl47��_�e��%��<����m��0��,�oF��1��H��n�.6f�����B]��o��^*�_>���$��:oN��������}��N�]^�pF��)�T�9��*+g����Fs��B�﷏;{���:��H�uO_�F�m{_o���7ǻ'"K#M.�dU5�w=�LJ�i$l��tO��>�H����}t��;|�]E'�~�qˍ���%n	x��>�&�_���|����|z�G �8�UX����g<p�5'~�%C{��6�y� �L�C�J�Z��!�`�
'�r@t�19s�h��D�mr`���=��QXa����l�@���!� s2�ө�8E51M��xk�x���";p�l+�3�B?�������� �C����\%��Ë�#�V��!�2Xוv�T��&�|�;+�&*�卞�i4�}]8�_���k0|D?�\;px(r7�F������Ag�2f搹�f�]8<�f��(4+�	+�kF�P��AV�u��9�]}%}-���W��〗��2f|(a\�oI�D�� ��ь�L�e�%�0ভ��j���+8A�ph]����6�B��7x��Gku�F��|�D���ⴧZK�U� �T��u�ZUZ�_���z�}Zӡ�E
<��ElJ<rM���Cq��=��[��s����ꟶ\3��`�!��y��?0o8�58!> ��l�������e;)�	�6�N84�;�,��ʦ{��{r��鵏���R��P6��tr��A�톒�Ŷ g��{��Ѫ��0}*l7��zӹɄM�p�>xQ�� �JJ�@ZX��4*%���NicSI��n�%��3��N�2ʙ�E-EbA^�a��cT�SƤ���@�Ф/F�~���>E΄RiQ2��kS����Ξp{ºZ�ƶ��V0���)ߘpݷ*����X�`.��r�bꥨ��X���6R���p��`��$�׫���0^�G&]��i�;�M� &F����,�q�'9�w�^����ݼ�o���gN�WbR�T�����4u�)Q�dsb�y�ՙ�Y�F�.���X�?���sW�,���/P5)Z`�n��)�˴����5`�Ο���}[��P旞Hd�q!��B�Ju9���7L���d6]P¬k�#��:��fF�315��ϝ9)ݎ�$�͊�2�M"5n�������w�[��g���V']L�x���?��-��vε�Xŧ0X�a���iw1[荂5����瞛H��;
k�R�@țx:�&�7�!G�԰�Ddq��F�O��?��*�tL�ٜ}F�L����;p܂�]�Ր�^|ӄ�����D\h �!3��;N>�iFgA~�'��h���a*���AL��]��¯2�!�4g�j&���}c��-��4P�S�ʖ�0��h�#�i��O������n���!JF����[�����t�(�|����	����s['0Γ(��qƏ�~�Qq��KD������5z�F�� ,L#r����&ç�s�&�1ۆ�9����)q�b|�v�G�~�Q����""�`Ni���k>������_����aAub�����LY�b��"f��� ��	��P(��U�m*QtcO����g��ag�;
G̃E�?�AC�`Lq�Vo�8�ux]���)�(AW��M܃�����(�XN�ʆ�`���aǇA��XMT�]8ڤb�+�F��)��*.�b���N��8c��<�`���u]_�ssk?����Uܿ����D �O���?���U���������y�������-��������-���S���~^�X�F(wQ�
�3Ђ�h�'_)�{y�h���9��'��DGn��qs��_0�{h&Բc�~�i>������*�u�䑫˼���9����	�&&�򬱕U�.$TL��&��ч��C[����u�\�*-�	P�lg�r�k�z�]%Q��vw�����ܮ�>D41�R�V�����[<rs�dA�r�XP�DP�bZ�<�����7�ٸ��@i�B����������׼R#^>����W�PÑ��E�3�ђeqlR �L"���U�N�֋ifW*R�un 
�h�M�ds	���S�v���M�%R?�rڥ�9�O&%K3d��髃�ޛ�]�����ޖ'M#�f�_U!O�#Y��ыF����>�����~���J��<B����[?�4<���"i�VYeo�Y��5��s{q��cn��< �#�~!F��̩ѪZ5�*�|9�'�H���Bre(0R��LE%d��o��ƕ�h�0V,E\˼�P��f�d�-%�9~����Zꃭ��.�����K̸�w{�s|�>�����)n�	K�
���Y��4#�l��Va��k�[G�/���M'X�.UX��w,m%/_D1ɍ��w�5�%�m��k��`�9�q����N���upgj5� �����}�~8�������2�{���>3Z�$��*��N'�[���|f�]R����6~���n��}&��b�B��Mc��y�Fお�L	g3��[�`�+ǈ{��rAS������А�c��5��Io?r
y��>�@0�.������������ ���9�S��2�V�����r�Z���G����3�i��?�� ׼ǿ���F��wiY��2@�tp�h���;�"����sq��� ��7����(b�o��rn2��+[#�B�����!^�N	��7L�,��E�Q�:�F��Z�>�M��O�h<��G,��O�r�y�H�~�M����`(�y��FB��w=�%����Og�����dƔbr��J��{�*�P�%D� P�`�KST�T%�j���!s*u�Q��֮R=bjYr j�G�J�����$�L���-~O!�Ү@ZaÙ�_�߷�O�[I���Ed��q۹����Ċ*E���֤fͤF锥�2�'�#~��xw�j�8s�ǲJF��J��e��2�̺)�2����?�o
�2{���3T�b�*2E�\��U��5��)5:�=g� n�Hሄ/�����2�mI2��i�=jt!o[\��m�)�T��!���y�g�(��<���Z��p������d��+��V������^���}�׌��8iVxɰ����s���@H��.��lv?,�&�86������������ǩ$d�I��� .�X�Av�A���#?����O�3h���a�V��=��5��C:�vz6�4����̍ԛ+��YN��Z
���U�1|%�{66K�Tޖ��ff�v_u��.��q{��7���a���1q�qأ8*�����_�G/� �^尡�0����o:ǽW�;Z�oa��	��-��1�g[ԗ�*����,�)hj�G V�^�6����FK��}�VR_6A����{+E�6_ǖ�\�|�'��u0��/�O�%�A�k���%Dt�>�4��@3{ĭ
�e�~E�r��봻�z�����IN��F[S{���ܓY�1�)�R:�VGGˀ�3��&"(U���:S���s��Y�8��{�k6��(�(�J���Ҥr�����[JH3~Z�w�R��R�lsxjz~ҕ)��J.Ql���Ж�x4w�j�L6�dv�A";��@/�x��/b�8�~-�K�AD)e��3��ԓ/�̃�tN�M�k80D1<y-cbi�� ���֪����� �/��0K�,sQ��Y�z<A4#�pX�v�0/���r��Y��_Dl�h�����qFd�
b�`zC�����O�d:�p˯|T�5��,�-N�|?^�,f�1�r��ӧ�z|U0F�ؼ��.�y���u��W��u�V��}l�����$
.�����O�x[%���R	7�ؒn��8��E����|`�M��Jk�Z+�֨U�ь�-�	m�0�3�X�lb�ĥ	C	c/D��x�-%�/fp�� �
T�_����L�>���t��Zge�&~�GR���4#�:��M~�G�h�B�fj�� �y�-���+��<ɕ؀����sU7��	d�W���],��d�[S�3^i�&�f�46����m֠5Y�K6��|�Q!4��nA��ǃ����co�d����~M'ɚCѤ��	�!�<�O�?#�}3�3�h�͇�`��(:�)�P�w�0��e7� ��6Ps�8���T��R2j��8��=�(}����&쉕B�L�9��Lɖ�i:ۘ&˖
��)(��م%x )�����r���ʗ���ʺ�ovN�{q%-���;�mMGo� �}����`�2�"=�6m��X��lfe:�@
�y�Y��ǐ�k$��H� �9)����5ך�Ǯ-�R�a8���v��C��D �%�1���]�'���5�Ok�0�-�8�_nh�AЩ��NŜ;7��,�ے>Ni���/�g�H��H$��ι���y��+�K��;�8���j�=�v� ��P��S߾�"uýs���`ӛW~4�Qҿ���:��Uי+�UP\�@<¦�ȃ�p���$Gt��JD�c�ѻ)��t봜8~���[B�L�i���JMܘ��v�������WXχ�A��5���'����[��׸�Y{�rߛΉ[��b���x����/Ow��la��`�q��x����0NHαKp��\r75��`^FZ6/����� �E�ho�G�/h�4g�����{�X�v���AC�����1������!�����\����Q?R.�b�V�Xޖ7@�#?�*�ت�U.�9V>~+�́��ѺlȂ���e.N432���j�"&0�r|���~ft�V����~������&I^t�bQ�&�j����J%3U/����g�"�؟xA6#3�,��8sU���ilR[�.�-F~��K�=���KM��k����ݕ.�������?������X&M�'�Y G�K/ʒ1���0'�������ڪ��YV�(�D�l!�~:+f�A��{��;01�c��s+�ʪǅݜ�� T��)ˁgڃ��s2�O�*`"�u�e�qp\X=a1����䐕�Xc��7����^���H�/Bc�u���X雇U���|�|�F=�G*��y*K�Y#j��s!K;��Jl!@����XY( �,_T|���
a�0YƦó�LU�,�2�:bxyc5��Gi�fy��+�9�h��Q�`�Ԩ���������z��#L�]gih
3��9)*�y�17~���z˹@�\Ř0(V����1���Y���C����< �����/���P�Q���#�P���H�#B�@�j��O�]`<0�eeT��E�7��R�J�MmX��#"��	X6�H���{�ȆD�#/�5�#����1�cAX����O�n$ �&g{l	��']@o���[ϸp�]]07+Cs��pIX"ݮ-���ܲ1��|�jת����jge+���a�*3���3ÅN�N����������N�q4��S,N��$���~����j}���IB�tK��WKN÷�&�m��0iO�c%�������.A3Ԑ�&����Ф��K��E[t��"�VUaﲻCvEa��l{�e��+�.H|�Ž�R��־��c?]Z�����>ʍ�(��'H���Jf0%.u5n-vii#��Ƅ����N�s}q@~翼$�҇!>�\+�d��P��L[1�<��%��V�n�����W�2̩�*q�����d�Y��ĭ�n�����`���,�]���E���RRg�d�WX��:3���;B40�'S�"�V33:�=�8_b�0���h�[�����_�o � ���n��8�A?uǛ�]z^wr�_��Ax�f}����&��G.�����?Y���.P'S��:����2���v_��گN�����N��ex�3؞��Zl�9�ʿ��
و<^�XJ��M��Ωq}��rx�'�H|� B�":�ô�d�R%GL����k-��/���
7�6l�!��������>���Q��F$�a6B�PwW.�vl�B9��iY����Ccw
v�F�(o�"��ɾeYq���*�ss{����q	U錍,��9��u��m����Er��+�0�����Ow��L�ӆ��������7�������\�-��n��V�oEq��(7��x�5��-i�v}}]�
���ۓA��yT�Y��Ű?U^[��+E��
��*j�}%T8�|&������1�"�O�ֿb��	��p��s��7��/QE�{?�t���W��$e�Y��ʡ= p�g����M�h�+�V=o��0E �Bs�%��2��*#:�,�����Z�����ّj�8-0� �T�Yl�U��C)��A�Ϫ�Yѐ2���9���Q�߾�G�3��S�|X�Q���?����Or���O�������a��<y�cP֔�� ��$Ǝq�R.Hg��	�����ָ�r��`�R%Ҁf���C�SE#�i�=��vDq�XQ��������k�R?�� �J�9��⦊H�k�R?�x����j)� ��+�'�Y��jw�Q��PGk�ܥ�|���;�9d��������,G��x���~����,�ͬ�n�ם7���I}�--|���?ș�h/]Ǫpi�d^���{�c���`�yL�O&e[5
&M�ݳ�,9
���<Tw�q���Vzy���G)�5����:�GGT�Y�P������S��b�'��M�w�ͽx�}�������)�M�C. �^����1"�����o4$=5��SqY�=��^���,*��"����;\g�����Ť������Q*��~^Qc�G.�ւ ����~wrx�����������b<<:�Zg@��d�>��Z�զ�D�4�z��h>s,�)zq[ ��nQì�K�dw�A�M��;Iuscc�韞p���I}���e�\��xT��Ƴs=���"������I4�ó'�'����o�]3+��YE�Pn�zRk���qә9�]}0��\E�yc��L�e�0��#I�V٭��SL��{2�e�)D��@w�f�E,P٘nϲ�g���T7?ݞe���y&��:��On�*k�Θۛu����f��9�#av��:G}��S���D��~E�~��(H��0{4c(ud��7\ɻ�91��F=��DV e��o��P^p����ˈ���`����td����1��� �Ã��X�b����e�vӅ��(Qk�Er�Q���t)�bQtE�p<�����4%����|_�;��ݓξ��.gս	�U�qB�U��}�S�X�f�A��|..[+����9T#IZ|`����xѧ[U��ҞUM�݊�����%� ׼	FFF�:⏢K?����u�QREC�l������ڇ�]G�5���Ys1�5�(1�	���u�;�=*U�~��Z�{CU��&OJ�Q��(8�r��3c�S��2^� �.�<1�.���n���=ɾn�2���ކ�9���Z����9��{.D%8�I��Vj+t�{��s�y��1�)�p�K0ꕏ�R=L�ر}�Q��."ߟx�gH�
�ꢩ�Ļ����g�X�$�Z��Ґ�o�<�@�4�Q�����1n
#K�AS��=�k���Lb�8�T~��g5�YrӶ$aj��a��k��.}�P�%nQ���E�ʳWG�R~B�C%MIg"���:j���Ř�h% k=]=�\&O�Gǝ׻m�yve�)kM����-�6��P�
��η��hV�����K�	�6��I#%��y.�s&�?�aQ���=  3�T��n�����oT���CX�����j��������/�^�"\E����j�E�H@�޻����|�y��+��}��ܣ�8?����'�:���X��e��|4p�{4�W�Z���Fu�_��w~��f�~��c|8�^h�^�M���e�H�~H�D~���ڛ�w���	����4�H��s�Iah[��O�����+�@f#����D��!CP�0G^�䑁K����]�?�V	5�`k�x��H�q8w��w��م�L(9L���H����Їc�D����Ḋ�uEaU�츧�I�}����0�-]���\%��n�s�$�C{N���(��z�$��N�5/�Ń�4y8�ߡ^�ߑPF�����Y�S}�H"�՟jIP&.P3i+�==B2`�v����{�����E�W�ݜ�E]j��g�|�M[Jg(�U����uhT�MSjN���Z]�t�؊���7��
���p���r�ٕ��]�������ⷚ�}�YJ�e�� ��o���g���<[ɾ���h܃�B��!w�ݬm��p�d7'�����N��i���;�r�)"���6��u�DPg�c�#�n�����F�'��������D�?�A�06�f�ѣ�ȆA�X�]Z�6�5ʹ5+�ݫ��$2	/��(׾���3ߌ����1�Β�e��wWo=��L����s���m8ɼ���O1j�z�%���f�i3?����-{ ;?��?d-�>�f�&3�5��8��� c��_�}~u��MQ}'!�i'ʴ�����l�p��>! ���+/�=9f lm~k�4h�HCk���W�Ԩ��GE�������Q�/W!�f*.��tB��㹵:�����a�Pa:��`�E@F�쐯���Zɶ��V�����[j9~{�=�R�.���t�e�8�Xcm�`i�Z�����ƓZCV�w��c�qڗ�0�:Tݼ��{y�@7���|q�k�����iLV$���QI3��O��"�ǹD�<���뿳�L����y�g�E�vX���ɸ[��ǹ�����׵�E˯�������ki�5����`�����������L�ɪ����,q�
���=���c������s�+<��8\n���luDA��M�q��cX�-���h0ͽ�?�K�E�����D�N�g��)�u�8:Fh_�#��LZ&����);*�'�۟9�.�~�I�	���L=%�`�TnГ̝$m��9�3c�zj��nf����cz&�L���[Y��ӧ������zG1k�ݏS�NÁ�7���y�V�i��f1��܊���� Y�j5f���]�o4lQ��lr(&r�z=�><���p��.��jcy�"�`U�Xp��Di9��S�ɕ�E̫l�k�]��}�w�v�cS:���3*��;�&�fJ���y �*��ŝJ�att<� ���������)[E�lU$���~�v��Z:f�,�S}2�x"@TL��^N�C��48lP�����1��yo�L�f���ds!�$6)�|
�K��YZ���0������0lف�P3x;x:��p>��HأI�
�o�+)��)�����qB?m���5_�ҳ�T&�N�(����X�x�rU�!8�u�瓟y����ef�/�]-O-�m����6���L�b�Pt�>�~{�'' �=�OQN�U���K�o�}���Gʆr�՟JG�."�{���$T���@�z�2/�E>�?��F"�~�?����#r덼9񵙄���9�G�It���΁���a�}�MS!�`QxzLϢ�u�eu�ąD�=z��a,���1:w`�B�TU��=�����|ڼ��N�&���:(�;�-p`�mR���<�K��}���AB�}�}�1c$�{���������� #6�T��x�#��*�8�r�vl@۩�y��l~��Tİ$���.=Tm�s'Y�gK��������)6Q�^��P����g邹J�>�#��J�q�Xc�� p��9��D:?6/܇�/P��H���V���R/�����1-��Vō�0tX�Pf�l��1�So������n�O`����i�@!�6-AZ�v&��H�{��'R<)���8��7�U����*O��xw����H�nߛ�q7���E���I0�6��2@�B�����< �+��B�-DP*�tQ���4}mD��m\�m����D�%&s�7��׵=�KL��qhܲ��2M�z�"I.QG���F�F��S%��z�ŋ1�ik�����VfZ�M��T��ƶʈ�[$Y..�lf`����	S:��c%dvE���,V%�Gi�N�:�i�`�~�^�N����٭)/��e�=�(�시�2W����^.�Os]�E��Ucjڬ%�	�t�>����Co�_"�Е7F	LST{�� ��)��ʷȕ�zU{FAR�/��5��x	M|�	2|h2b%���Q$X�MV̕��m�X����w���Z}����c�~2�?�����/���� �����h�u��7`�3��xc��������@]�z�y>y���?za�����:��ki���E�\��$��F��c��=K�կ�2��	��=�ػȿH��Pu�eւ�}�/~<�{/j�9sZ����$�YROL�v<�d3���4���c8�/_T����+j�ܾ�a�y^�q:�� K4T
Q8b��z�Z-1���������T �$�_��z��,^v�:������������?���!-J,Y���4���Y��b8f4C���BYQ;f�6��aA�:QU��|�y2!�k/���H"��}���d�*UP��qs������fDQפ4ǹÜh�����d���6L�0:�e�a'ę�?-?�?B�J�rg�;��O7�K��+Ͽ����o�od��͍�%��י�3%�	�1������|k
�Ϙ�fu�=�d�g.#T�&��Y�э���:��젽�qLS�3�4	3�9e��uw��ٚ���P1�۳��������G�yx�?��s0'�hKdM�˥4�,�u���(̪t�Ug�3.s�pՠ�<��ǚ:�xN�����N���.5�1�vtVC�<����G�~4ރLpt���KGx&�Z7?RF��ăeHiӦ��YU7HR��'oX���RC��:��bB�˄�M���;��d���C�t7��8�<V�mӯ��˨*2�';	|�'3��x`�y�|��	�\�I�J}?K��0K��1䰙*F��_~y+��d�����]#qp�}�ETz*L��k�@߶X-��E,�Y�%�NcNq���@am(@(��7�a��#��3Kt���1���t�0/V��5�z���*ز�u�`k�Ś�l��G��]g��k�͆�����x�Q�0)]�3�e~�b��C3(<"c̳p�W��ɷ��N�ou@za��/��d�"�Zs���V��������)��>nd�7?�X�_G�+7M�j�q����Ɇ
��c		$��i8�-�y�-���4�� ��I_����-��<����a���C6��B�q�]�0%�iP)�8}�õ-9U����Y��|�IZOn5u(@ش�Y j����#�^���7`i���o1�}�	��~�Þpq�0j�S��0Wb�ބHv�E�z�É?F��g�����jn���K������N^ј"����mz�l���9�nӟ��5��*��U��w�����j�8�U�����=���lUl������b�ֻ��R�tw�y�����d,`8h���Js���9���������?�t��>����y��<���kv�{	���r>	�bj�sE���
^��s����#�\1���]��N�2�K� ��j��Mp0�:ƁMᄐe�V�_H�Ac� ���>2P�tĶ��C��jy�x�E�TP&��fE��x:�7 9��뱞� �6'c�`H"u��>:��/L�V�a�=#��$�t�%8���4(��B�'����΢Lb��F�u���7�4�-) �<��s|�阇]�@�'4!p 8��R�@�L�H@z)���M�KۊH}�E��e���r�8_�QZ�;Oc�$�����J_��!�$�w���)�S��A�T�r��A��_\r��vd��"G;��@uқ'ɍ=�I��'-�@>�%!0Ӓl<n�]�����h]�갶�N����Uמ^�n����?R(�R[/Z�j]	)Κ�l��G+�������A+ǰC<�H�i~�x�6LJbO�tI���(5ұ:�(�LjiI}�"I�dq� �+��������d�W�T�/��x�g����'�Y�V����3�Z��AM��	8�=>832P$ƪ`i�x��.��v��6K>���~�jo��#߻����g�>��� ��I�f��lfP��IG��Y�h�<k�N�Ӕ�D�hafh߻a�u�&�S�Am��/�6 =L݈����qKw�>�X�����X��� :���� /1|;�F#���<�����������'O�f��f��2��W�<|���<�l�����jc�?d��?����o���$`��,S�Ç���!��7�*R	A� S1a^��03�ep�gfJÃ�e�1�z)�U�;]�*��c�F�Ʀ�nU���Vw�)-_�+������
�u��J]�-^�绞�_�8�J�c�O����m�c4!;!��3�i��2fY��'AJ�A��i
�3f�!�E�4(#����s`�M	Y`�QT���y��L j�H-n��[+�}�"��٭Flv�ZǴ!̨��%I��7�e`b>��&E��,�f"K9Yq�?i�"�(2�Cp�&+v���1*�yChX��dv���K#;��YL�á�=�M�����0��3��g�f)_���)�{cQ�� u_=���}/s�7K�/5�ɓ���xk��ɜ���C�5Ft�ɉ�������Y������R��:��Ä�
M=l��:�#
T��<ğGx���D�|�V�7�����s��5��#(-��b��%7����( �oi]0#�[%�A!��A�8�����|�|�[��q�����w���?���h
A�A?�"nR�C�*���f��ʨFƣ������3 ��C�9��ъ��(#Tʳ�~�{(Z�*iY�J�ITn�4x_}V��S��0b��F���Ȥm4��F��R;�*�.�]�!��*��g���(��T.�I�L��ɢ]ŀdo���yy}�	��F�o/����?MR@���  �� ͍J��Jll�q8D�x�'f9�����c]�����7�$f�m�*�g����t�n�ꀊ�J�����Mb�iy���L?0TũnTѬO1�Aj����-�Q�?(*䄔�E���aη(��&f��A@zspZ���*��馞P���F�Lt'���f�؁n�$�����i3�GБ�s�\�,����2�guH_��!��ڠ���R�iC�Q����xu��3s�Vo�YZA�h���M��F�����,?����,?����,?����,?����,?����,?����,?����,?���#+h � 