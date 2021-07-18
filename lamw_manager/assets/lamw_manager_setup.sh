#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2748216711"
MD5="c980890c1d5fe5f52fa146d960701d5a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22640"
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
	echo Date of packaging: Sun Jul 18 02:52:59 -03 2021
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
�7zXZ  �ִF !   �X���X.] �}��1Dd]����P�t�FЯS�uS90�S6S�`�F�Ym��P�ûP_1�}U4��Y�6�u�Y�|���ZnV7,6x�Ϻ�ˈH:10V��-�S�]�a%x�,��>���"��.������Bq₀��=���u���W��S�`ep,����ǉ�%\�4o��5�g�������o�V6���eeJ�<��=���@�dR�oA��l��_<�W�Kr��1U#�����pf�ԯ[��ۯ��D��pp��.�U|Slt�g��#V)�z<����	e��I>Y���J�1�����b�EL�<J���qǯ
�t�`F���p��޷�S.�5�M""l�кB8�gΒ�qHN�_�M*�ȸaϣ�t���ʃN���C�t����"��������������>���L�U�;�c!G!��w��k^�Y����(��_hl�M�z� p�Q����|�1a��>݇��M�G�B)\v�:u�ۯ�i��n��A��@b�OB<ѹn��,�j_P�E%������(�Q�ɝ�J���>�?�����z�#c �� ��(]^��td`bu�����^z-��.�*ENhx�vh���.�C�����(�:y �#Q�r�q��Hl?1��*wY;��%���-����`i]6�_��K�T�vX��j*�5�����3c�����q{�R�U\����8�71~�Lׅm��g������E�uY��4@���ps\`o?yL�N�Q��ݿUm~��_�'Qn�{�"V�?����w�[R?�7�V���_��v�~�<�Iq�Q�g3G��E-V�+�O�'#��ѯ�M��}��39�����嗀W�
�I��o��3f  B|���&P �+�^�:�K[	M�g4C����mJ/���EDP�[� ��t�1���5��u��{{�)N�a w��j"��)�'>�~j�rL�b��C�4����/�b�� CVl x3�
ZO3��Q��5�!�۵	��W<�u���P������j`]0�m'���zH�*Y���xd=�d@�[�M{�a�5)��b����\,gLc$���|9��kg��"�6�+Es�2���>��ӧ�1�>6��yB\$`ǘ�ͅ�S�i6k{�����$`��Pd�@�bK�$<h^`6G4IR�9����^>}�̢��EqȬ�̶�o�k�F����I�(F���t@�&8˛��ه�Գ�b�b�	ˢ�EI�R2�A�L�QmY(������c}|H�vc���4��^�1���	�ʁ� ��}n�;=������X��1,�>3�T�}���ωB�.��b�i���{�3����P�tO��q���$�e"K�M]h�᪄oq\�l_���}����6���V����z����?�k�u�[�8F0,�'vgM(�A��V�:�貭^���Ye'=0+�<m ˖j~	�{��� @��;(�*3�j���=��P֒z��Ԋǎ��v$�#�!H�^�d��l_��q2w����,�`!��
�mWQ�٦cu��4q$�t�evha�Z)C*?�hp���K�i�)��;�.G����_bF4EC���NZ�`��X����ȫ�1C�z��Ӎ�7P}[m� ��li<��ؖ���3�~MlaY�(a�w�Kc�T<���;�L�At�7/�����~���)6H���V˓X��C6h�yL�Yn����=�@@�]�낃�ấ�b�K���\zmg���cJ�m������Ev��`���ʾ|����a�q��J�1{�+Dm"��	�
�gĈ�f���7�L�������Oz�I���#I�j���0F�|˪���n�j�>c�(5qD��2���U�&8������"��:9�3�<���wv�������=�;��I��(�r��奷��� 0������;��8�گ)���.�y�C�e��45���6�SE��^��fL:� N�kُ�!���Q���5�c'�K6���`�;n�a7�w�h����B�� ���|_�6(�a���_y!)�R���趈���#�ju�}I�}磅��~�T����������/�
��|������tb��dC�p�	��T[
+xr���چ�i�497�h�u��&�@��h�K���_����Iu�y9��L}]�̚��r�;nŖ}����e>��5n�P1���M�U`�r�Ձ]��ů��Z:�
��}P�(w�j����{P9�2�W�z�4:��F!Ĭ6?FάqDd�Hz����Mr�w�n�I�D�1:$�����uS��Ԣ��HK ��KF�ְ����I	��Pæ���r�
U={��2�BSs;��c16��EY&swT�I��7���Q+NF�ꍄ�x=f(�)lw�xJo7R�p��IwY���F�$հ�����>�ni�\���y?wȂ���6����F�w
{(=sg���=�,z�L7���M��5��=���6O��;���$�l��#�	�=5"o4���0��1�w�<T�����u��]�����dmxV�������w��2;T���������d/v����xPd�7�s#[3�&HR�GM�� �?���ta�6��� zl�S(9��pg�"���$c���/��ZBK�|���I�twbZX	�鵊G��`:�#�
Ѳ�����֟�k!ܯ���߶,���{�~�c�-�mŀY7����<E�@�b���<���3��������Q���LU0�b_r~�[厼O�o<�ו�Y�ܯ�����P�S�:6۫��e]�Ōi�9=����ddj�]Z���@G!�k�u�0Bi��e�	߿c�!e�߯�3B7���0H��>����^R��d {Z���˼]�����ɺ`��z��$���YIM�n�̄1B�w+�>~�
M�\u�H����쇗�:���㏦<�5��P���Q ���/�H�˰�q�ސ����$����&�ٶ1Q�Y���f��P�.�|h���w�Hc{u:]�A��,V2��M�� ,}�R��<Ÿ�� �HKO��0�c�b��^���j�C��);��0��/w����Q?��F;>UՕY���b��L�.��d�}Y07�v�9��J50� j"�Ա^��
���g¦�f��4�H���0�.B*��e��!@V��|�	��>�w?{�K�*B�d��:����mF��3�2���M=�-�n�R�n`��E�l9�7���Ӿ�E��qi�A	�S�G!.�Y&�p{iPC|�-��2�����pW�U�� GHi�\�x�pV�v�8��̔��]�+���@����'�#��U3'@L�-v����קU{T���&~��W8��X�2P�!�K1O���@�n�e�t;Ԙi�m6���w��w���I�B��~�P�g��'G	�	�_#)���<5��a�emWr��/����Y4���h�>�q���3��~Xփ��FlU�x�l�jP�)w�؂ngzY��+Dӆ�	*�E&�|^�A�]`,��)�z8Q?S���#�<u=Q�|��k��&�u��� @Z$u��~��$Rq��k���Nq��ٳ���r���wbW�/硡�>|h{4xF��>j����S�>h�$z.���F.XVN��洁HR`�mNC�W��O������>�#
������� ��cƅVpkB��v�,6�/*�NGu<�/�z�W�i�~p�����3�����/g�R����it@�5L���9�3Hc�N�t����z�a��ky�lR���.d�Tu2�uM_���C���~��D<�����N(Ծh��d�rӚ	]bb��4^�u*n�'�Z��/xKVx�-	��Y?*��Roݙ�54��#S�p\�(�b��w���3�E�b�o���B)b �'gƌHID=�#���ߤ~P+�u�e9~��Ŀ�:V|�h3���ǚ��|e"�O��Oia\�ex=+��6~���NJMh}���Ԟ����q���V$g�	��թ}�����N���oXϟ�?.d�Y�јi��0&��,�0�Y.�42�lUS���Me+�lgL6˴s�Q[]��;烗f��NVq��la=��I<p��:�b�5��P�<��-��ҭ኎͎pe31���z�b�'T����lxp���N�@�l��w��Z�TB�o�S��X4�l(r��Zp�A�9�� S��iݤ�w�@��f]#����W��*�ӷ���́޳�eR�k�3uO`��:�\"�r���l����s��_ ��Җ,�b�c�`���)&�gX����|=���'���438�@�������s7}��Ѣ��5�h��Z����ԯ�^�1%�I$�f�O4����O�$������R;��*� �U�P�R ǁm3�~�4�ZabG��8E�'	�>ʵs%�����K�f�����R r���4����p�R]ú�r���IC���{��)�Db��h��ԝtټ�6�LQ���������{����$ ��۔�ޒf��Dl�y�:q-@�ޣ�4kEk�����W-�A������C���}�=joE�R��%BV�DԊ����5)L�BV%z;������t{ ���������p��~�\�m<���X����:�m��͵�!:��<�X����
%����fID���B�Ղ~n�CB˹`���^����q����P���R�]��2� st6N�9���.{���s���)O�lO��7����m��ͪC	!��V�ə��	�W;�`��%3�w�����g���{Ǳ���(߄�g�+Q�˱>��;Z�q3�
߉D����h�O���w��nm���Hקç�:h=�Ĺ���u�����r|���s�S��J�@����� Q@�l}��}�%%���'#ρ�-�z:;��y�HТ:�z�r��H��ɮ���y6F�.j9=9��į�/����G@􄃶�nD�ѱ@a>�~1*E
��~�ˮ�Rj쎦�4k��!0�q�c��)�;��=��L���Sv�nܭY�U����m�A%�6Hxò�-��IV=P�}�{�=A`ɒ&]?��ݗZM@�7O��r���X��S�=%�K(��~}���_Τ�����r�6(��1&�r}%N�s'��U��:J���S����z'�B�ʔ����������f����p�ld����
�o���lg�yC�F�i�W���ߝ�?ı������e��[8PHt��C��R����b�����9m��m}� �l�}SRQZ�?M��'�~n7�����N�*XJ�� �Wy֩�����ǭ��lƊ�Ud�ͫ��m�5�g5�8�i)*��*���d� �t��L�*�}���blQ�
�-t�4Ǌ��Q�PuZz'S�iN��yS�6+¡�Hꐜᙃ9 �B2�J��٤�G/��q��.���6���
ԧÚm4�����+�@�Q��q6vT��]�p,��m��W�E��J��y�ٶE qQ�Zج����bW�FU@@��'�b��*��;ao+�C��j���7�
�7y�I�Ĩ	���~�Y��[4��ݩ��<��O�2,nӸ����׽����}9<"2!�<B�� �=�7pe�}ɋ��z���T=�6�)H�K�a���Í��)*����'ܩt1��5V�t5�Q|�G`��s������|�hɥ�/&7��˵�Q�%M�u5���AL?~F�H|���10�2�_��L��ǵ<��G~P��ϴ���O��suz��>'�䙒zc� K&�� AiT�y&c��s���>�5����T�sKi盳=�P��_��k���q*b�S���V��/�R�=�o�.!����K;��㣷M��h�v�݄�a���jrq�'O�P�gu$R�7v�n�@���<���]܅1jtt�]�];(G����f\���_+��c�˯�&�Zs�����x���&�Kb
mnN�	RjT������Cߤ���R-���\�L��ݿКCU��/�p/��D�D0͉dP8ފ�p1Sq�O?��6,� �@�Gя��~fX�.6��ᯄLJF9nW���:n�"���ѭ9���v+@��+9Ah��
qMr0�D4��\H^m+������[��������[��qe�J%I-�A}I��6 ��4� ]D��q��g�Ƽ�O�j�Z�����6�-7J����4�z2,yY�(��3���r1:�s9�V�Sұ�2�,e	t����,�Wv��8�	�d��� �ѭ}��0�_�x��)��k����	�z�\Q��75��t��H8�5���}����p�G�.~h����m>�X��Z�Z�}l��?�Z�f΂��7��H���A#<��D�]����?G����R�gPA�Ņa���e�S�H���~�LU�D"؁c��%�X5�D���v����r�v^^����eL�|	�JTlr�`�ņ`� �{��WDHR�.(��/!'�3�=��>���yG~�������-A��j�:�L�����5Q�t��Kd�"�eL�֊��OֺO&6���۵��AvT�4C�ҎF�t1GKz2�H��j�A�\�X��M������I�#)��
uC�D�$[ܬf����\&�#0����]TB>��L�)CVG������k�z@iVR��
'�t��Oz>~y�Q�-}}�W�!ݥ��(�).
�"�*�	�M-���99�Ix��_��n$-K�ۿke	�=��������]��Ѹ(r��/Y���͂��m��u��4�8�_�c:����|Lj�۞;[D�p2��d5ͮ]~��sɿW/�0s��[�7 ��?ٟp�
�e�h^[I�Se���44y�T�w_�9�/�7�qo[�R-va$8�ao'Wwf�(P��~P��[�0_>J�T[�� Y�v���}�c��z[�ѩ*E�D��i�E�+���D��;S�ϏC���i��Ƀ��W��Q�(�3=�(M��\������bft�/���F�=;9�t��5�-�>X����HZ��ܔ��!��U�`�W��+���r6alM0��8��y������
B�4!@9�V���)��>�x�hހ�����Y���>�߳%��;��}�
O��d���
�nB�@c~��E˯ɮ���b�6r�n#���=�ˁ�"٧��ַ� �-ba*���J4¤�Q$�ރ}�(x��1�P���O	�%$�A��j Gς��d�N���_�f�Ԏ'����Qњ!k������]���8TiH�����s�9-��ⳳ����o�k(RM�A#��=��fΐ"���j9�B���BJUTu���(B�>�pqz�.���;�x��K���!U]��Q�������gq���K�BI�H��w��0濂��wp:��a����Z�>�t���ٹ13"���&҅G7��t7cDKP��^(Ċ�<��������_o���U&����(1DM��~
��z�4�*�r���)%2l�>.���=�>�I⪕ ���9���r������N�(��cS�:����A���Q���*�z�&��d��;E��7$��Gqy��{�R՟�ӧ}���\k���칢h޽�����N�B��l+sO]'@W���9�~��"N������o�юlH�5��s��J*Q��&Z�p��^e���x������k X�	���J�4�jw��N"��YԈK9��b�]����+�	���|ZX��rw�Y��-s�&�4_*��3$�4J!	v�b����.:@�d��G<��&�k�v��'�b���f ��~G�#��)9&��B<5d�k���,��bH��B �LFڃ0������H*��ƹ.x	em����H߇N�&���ki�\�cU�^՞��qz�7�Np�;�B�u���cl�-�3_7�qKa�0(~<�'U��l+E��r6��K�Mr������Q'm��P����>�g`��2/;�C}�	Da�\�����,��RS��X��~�6����5,=0¥��Y 
=� u������6�}sY(�O@N%�\�y�	?�����[!�g��zeb5�LSX��k�����rq$A�+���l�$��,���UI����������T���d����I��f�V��R��b*�]��t�mp�^�2��	ӟ)��X_�ͅ@���oY9@����݇���ٍ@5FW�c��Q{:���
B��Կ]&{o��ʸf��w�OF�k���,�H�Ǔ�F^�	��/[���5#�,�	5��L{�mL����ݴ����	Qվ���ل�C̺��S��ć��)m�K�.���8>�Ū����\��+av2S̷��^������\�.'����������!���]Щk��u���|����zw�[Ɠ�|�ܔ�;���VI��cs?(����8�k����tU]�ژ�_�rt�v������C�1��`!�Ԝ䠈����M�a�eٟ&&v��%�����������K�����t�%��J�!��	&�6�
�dT�<��Q�",!R�W`7�g��s_����k�c���g
����p�̪�u&Y7�&�������ڸT k$�=�9u���%�`�p<��� �<��X���$mZS �G6�`����+8�J�oԑ��	��
�v�9�H�U�#̕�<ʷ�,&4$�4v�.��D+�	8P�����d�8�#�0�R����ˢ�L�h�h��8�	��~]�a���5J٪t�����@>�f��p���x�b �;���8��{ ����x�4�j��>M#�������g��/��k	�B� a�K���<0<J���/4�mi������d/j�ݓ-s�;�S3��ѣ1��="BPJ=���V�� Z��0��}�[e�q�ڄE�g)߼�Q8][�S �� �;����^�����X�iЎR4u^7�P����M0���U�w8�"%�f��gQ�Z�	.�f���e�7\��&�F,�ZU��C��:�ȜE�=g&`h��ݑ����s'���X�q���NӇ��^߉άo��M���PE�B��\w�D}����e�!/i���|<�h�)y�E2�bYl3�p���˿
���q@$�rM�A'i����]����t!|�_!��ە���{"u�0cǓ��wu��o�X��1}�j[��lX>���X�p�럴�ÉČh���fN11��p�凴\�� ml���/��rS���9��s��n�E��J#���E�����`�%�XյN��(�D��T}#�DMm�%�"a.�t"}e��{��~��`kv��2Bn�������Bv��� #r����WeI��63��x>9ᠡ^[0�j;�j �.b�N���� :�=i�k��ҳ�Z6ͣJ]c.L}�W�#s�*L���{hfB�p�o�^���"Y���jlp~�I~���z�E\�,���H�iЉ�4s��!¾u���j<�&<��O8�u|`�\A���I��g�O��>O.aZ*��r�4(����������dP���wmY@�aӍ��J1�ٖ��� yl=�'F�[k�Ԇȟ�T�bh����<E:IIYU�}D��M�c������!�u(�+3M����o�G~�Q�&����&M�H��ЍV�' p.�kx�~�u�+���R���'.�I�j��2ҵ΍6���˗���H�aW�A�u!�$ŉ:��~��{�w��q#ߙ����h�&u~���°w��;x���=�n����#l�瑪L��a����Nl�.�q
|~b\����a� �6ͧ�T$���؊��gTШ��-T)��Y�]���W���Ŋ�FК%�+dW�_)w��o���s郜���a�'��W����2�N�'f�-�6�3%����q޴;�Հ4oD�̼o	�ݍ6wCл{�2�T�
���_r	90,�����qbl�6{�7-G�[�Y����F�O�#5�W�sW��i�C���=��E���M�My5KǵY��IT����H0�Q��\^�9�u���������u�1^��㑳�HF�+�mo�Ϊ�*i�V�D�H0�XQ��u��y����ajvz�؄:i��4��m����u�� �ZFk�n�o=,"˶�W �zKJ�.Kvđ�	�|��	�P�8^�p��BfwK�J�t�Ŏ;ONG�+��Uk�	��U'֙cϭ��bѹ}�U�E���N2�(p)'I.7ӥ���g-`R��R�ϻ��]�Qx�|�z��-���5'{�&<��k�D�a���4a)܅}A�"!�Z��6ԏ��5f�9%���݂��E�Kը��P��v��z�ؕ!��;�����8��nF�w��*>>���~Kv��"�}u5 �"��^i�Y?��I�;f�ѷ��h�Ҿ}�^_�~\�M�yn��qsQҺ*��i{X��D�y}~�
^Ekθ��g��B���]�����P�?!�J����b�O�=W_���b������x�T"Q%D>K�Ղ��q�\����0aW�U�[�J$(B��}�ց��2k]T�}�J��t���*A@uD�5�O�-��L3$ʚ���&z|����͊ӚK`ݴ�i�\.�!4��4�{oX����K�,�H��V��� ���8�LW�9n�|o��bCO�RzCل˓t|7C�]�O2!�}X������UA�j`�wɚ^3E	ϽkA�e4����بp�̀���kh��N���F��gK�%�n^�Y1���i���x��������P/�~�7���>������/���8���T9��8��5էG�9�~����3k�6I\�Ď���� @@���ՄF WП+t7c2�Y���ŝE�B_�8���v}
�Uw,e�+�/(�������k�W���#|�N����U_��-0�v��*�G-D��wō���ܪg97c�_] IRRC���R�㌴I���o���*�J��Ɖ�)J̳��J�%1mQq�z;�/zgo�
݆u��V���wb9��l7����m��U��M�Q�G��B\��;nL�G�|����rE�=
��i�[�!н)��R��
�B�M���@� ��;���&�Rf��oI�(�C>l��EѦ�;n�c=���e�y~S�F���� >.�1�$���O��*�1��=���La�ܐ̮׺����1)E_���1@��GyqK�܄GZ� 1�����
+��������ɳƄ�;�0ͺ� ��' �0w_ϐ62�|�"_묃�M�G�=3��v'�; ��~(X,�:��O�q�E'b!��~'�㢡���ʨ������:ic�JF��v��R�|���j��-a�A�*�:b-Z��pVK��Y�*�DJT�U�����l��R3��쫂{�K4�qQ����F�vu���<>I_:2�4���^�5	�V�Q�1�Ffb|�[��p2��?�rh���n�Q�p�00|'��PD��O���&�<r�.0�\C�tDcX%%#!g��z-�_FGM���iQp/�؏<������y�GSݤ c�u������Ùa�X��^|�Z�G4b�H��b*^H�]ZZ�$`^m���l<��ߏ��M��s��˪�^�s�����HN���o����ĢUگ��.�L�t�y�;��Ns����i��X�&����d�b�=o�`ж��zM�3Z�	��z��˒����_�?�s޿0Q��T0�kaK�Q�y�E���{ԅy%M	�SB hTed��}�2qdl�C�K!�}n����w}�k�i�s�v�|���6��~P���qvm����<���"R�P�N�ҿЬ�t�t'�b\4�^�GɐT�8}�6��w�g|u�	�����:WpR�jB�?&GJ�?>����u�6e:i�⸇ݼIOGQ5����C�X��O��q��\vr��9o�*��SL�>9�l� ���N'�?^;����K�e���zP�Z�13��=�Kԇ��7!�2| 5���j�G9�ԗ�������i���j֋Yt�a�̶%�ڡ7���;GǱ��nU�����������裢WZKJ�*��� ��_6G ĭ��W��ƍ���&��"<�\	7���+��UxPV�i���6~��e�����cJ�I�,y���x5u6r���+�5����#p�W�ͪ�9�E�n�V��A�j'祿K���^:����15Jl݌��R����sT���t+�������Ǖд���s�@�9�U��ˉ���)�=�8�^�78�:���RQ4��n]��
5Y�����cY|[|�^��˅��S������=���Б��
*\�9�U[�`h�Z̮u���e��鹓-4�2O�ܤ��=�Y�Q�� �b��KA����QC��CNiL:<���^�X�$�=��g M_|�,$�b���ω�$�b�~�dj
1��z���[��_PC��1�a�q��n<�JSl�:o��D��H�哝ؙ�7�RBIA6��C4�Iѐ
v�� ��kW��!2qN�j�pZo����we��3�`aR�ִ���Y��.#΃���|b=Sd��^�Fo�+v]�mK��gҚ��,����M���w����v��!IP�a,�3G�
��N0�E�f���u��o�;.�hr���&7MY�-�̞�O�pB�Հ�٪;n�D��4���^�G���S���2��J��&�Go������U|L�X�|��!� �ECVn
{�R1e|�on�g�g��~z���D�D�8~d��ڈ�͚��aT۫/���n=�JTPJ��6}|^�w��=SLW�����G:��Le��Yj��fnJbv��gy�'���TJ!�{���:K�`����7�DA^Wu_�g�Q���"��ϖ�'i�x� ž�@7΅C�zp1>����[��(A�m�����9K��k&Bsr;$N%ռ�'����g\�+�`�W8�L� `ġ���]褛�-0]*~g�|_�Fp<E�?�TTՓv`7o�?�(g��[.�[��로K��\5c8�1�(ؓ!���≥�XF/��M:��!,d9\�`cI>��!�d��A�w�����@c�-��d��0��q��K$AT1ցh_d�A%R�7��m�	�qM���4�%^C��ˢ�����`j��fD��k��)�kJ�B;3`+SR5�^��
��siLd���
4��w�>�(�@0m���m%M෌]���lm�70ݶ����`� M+�O��;�hx����8n��ދ�:WD��T�k�Z����<C��E��6%��O���8M�uP���;���5� ���d���[��;�^+ ;
n�_X�~�����Ȣ�Z'ID0��C��^S	�((+&��Ք��m�,���p(hxÀ�t��-�S�2����׌��������� (4���J����^��wj��*�Ѝľ`o�E�)A��!��n;;!�>̨�!�P�Ӱ�-�K�֪m Ǜ�u�Ͳ�^B���{Ӱ���| ~j瀮2�kAK������ޖ�bPYp��ݢܦ�<s�Q��T*�/��%��U-}�#C4Kz����=�0EDLN=�t�D�kNԘ�t.�}��n�XKouV�|��+�?vd~�����F��?u{ף�D����C>��8�<��L�V�ж؂q�
Xn��F0�_K�~=qV�rO�AH��%7��?�op���uN�F#j��S����
�����\2��=!�	L(�ϳS��s��C��)���F2�E��r�*���'vw� �J����Z#,e�<E�߷ da��o�?�M9YZ�S��"������@|�/h��������C�o��((� �
 �EK9��^�_����$��9�,v�8߭b�p����h��r)����$l%���ج�6�);n��P�.�Z(�� @0����e���8ʋ�I2סYE��W�?
q�8<@�^ځ ��`���9iw�j~�W�s`��ЎJ�BN�2��8�me�J�H��\>vbu>M��Ų5��dG��Q�s�a�t��D�T��R��2�!s裸�����|Ɣm����@j�Ovy�mX�!@EӋf%4���(���O�|P��oN�\��?\�h^-[5�5��x��),�.�����g��pߎ�j���T��D���U���c4�Q+w��W퓪�eXA��wr�4����(9*�0�|�:_7��wn��ίT�� k��y\�W�
�6����-U�>xT��_uana��H6����c<�x��x۬rh����%��%�lB��7� c�У�x�}%���K@��gu 2/j�.��J�;w�&���a��!�x�m����i[/I
�	 ����C�9��1.d��:��6s�������|>�Z�&㢋�K�́�bd�?����A�:P�J'�PB��;웴�\���n���[�.�%����z��s%4c7���B�䒏"Lr��g���!���@�U��xh
�l�
�{H䊕s�@�~�^�V;Yf���RR別� A.IJ���{3�r���.*Q:e�8sJp[;\h�
�p�	'��)FD0��0-6�2F\ƅ�N�kr$�C��������'`h˴������P(��V�&�>Z^�R撊F`��5�N/N�&���8h�"��2�Wp��<�g�6l�6�^��v^���c�Qű��^qcǵ)��[�`�PB*�Qɣ��Td�
K�x�!ߋ����ʮ��nt� �M�L��Oӱ�8�Q�Q�l��*A0wq�w=O%g�.�Gp淡��|Ia�5�q���Վ&��l8���U�6�l1��w�\u���_�����wz�{��ös��Ƙ^-��"��B_��[�0�z���T�W;�>�U�٦�s�!b��(o�)q�Hݔ��M��w���x������ܫyW��
�=����f�̺����~�	|�B=E��������s�D~�&@�H[�bR�g��z ����i��]M���*�y��E����Ύ3Y7^��{;ݽN���B�[�,mxGM��+���L~]]��k�� �h�lM��wұ�Hкg�~#׎W��Ә��ؔi�8�ƌ(�_JƴF��'f���ѣo,ߺt������I�IĤ��P#���*́D=?;g���kZ�(��9i�k!=C��|��>v�߆�W3'���D&�g5�T��"����Xkg�b)Bش[�ńCw��|�,�m�	(s�<Kj��h�)�C`�k�4���z�Db$�ұڳq$�dŔ�5փ@_+��}7�Ȕqb΃����²����c�$�F��e�Э�����k����a@B��3W��{�9|_ ����|��N7�>�˒��p���
�'xs����J���Bd�a.�#�O��`[*V����o4��b�/��Z�|鿋���_Z>�#^Z�}�׼�M�Y�
���%X		���=&�e��Ȱh��?E�e�ؓa�~�����W���7��I�I��� yPc���P��W�s�xF ^p���Ê�ӂ!���Z ��/���,T�[���c%�N��1X$��y�G0c�u��_D��`Y��W��S	�7N��	��1�����ʓ �����(���"JP}��U�4�Y� ������ĆCN������j��8�訢��UwlU!�����*���F�L���`W����6�~��@Ǹ�6a�Hb��'2��������^�~=&�AL��:� �#g�����,�lA�.)��+������2����"�3r]!�uRI��-Nv���N1)���j�1rg�ʰ�.�)��%���{�]���Z=ʡ�6����F�Ɂ��k��U�/�@�
4����߬��"\v�+;����9V���
�غ,��*�*��G���y�N�#����h��^/��(K�K�g���#us���@^�)7����b�󈷅~�qu��x����k��cr$��=Q���&S(N����e��2�ߦJ�6�R.5c)��&Qd�i�La�'����LR!�j�󯊍�)���7�R�Ol�$�C:wډ� �M4����$��7=�Jx0�[GJ��g��3����������0;ٛJOs���H���y�{8ú�=o
L%��X�-0ٖ�|2J��E�L�2KO�L�nM�"�������|ɧ,o\y0c�h^O8�ʭ��L� Xc'�<�3��1{�\�����>�Y�f��u�5�t��Y�
�1�aO*�O/�8�����U�v{%!��@g��0�P���Iཇ~&�3r�;�@�a_. >��A�B�����G紘�ψ�b1�7`_{ͥ*�a�n)
:FN�#�C0h6��y5� �am�`�ݒ%GW����r���%�pԗL����J�r���<�!��p�}H�"�j8�|�k�1�����n�?�}"�:%3,	UV����{���åh�b2�������S���0��U ���%h��o�n��jШ��������R��e?�����d��j���%�;O�\�`t�Y�\dJ�!��]Q^�_j�ע�A����x���z�p�X�^l ��.6-��/�4} ��q瑗��o�C�i�'�Y,$�1ܪԠ�������6XG�O�H$˶i�,s���M�"�y)���[*���J�8j��7�0���T#����)@�l�� �ӗg�ݫ�û���4��U�=¡����E�r]e�d�А�㸛��[6���Ӝ��d�v�s{��."������h��ڈ��#���ښ(G��*�"uI�]�e��k�W��H�Ӱ�U�q��o�����[Kc�Ӕ�e�}���W�0:Wφ@	J�;��]��.��^�[����6�T�p۰��_�����d�j-�i��YC�c��+]7��ۡR� ;��
ư��M�$��d�6�As��F?Y{2]f�0L�P�#�7m��X�m������4�-^`3���⛰�e�F8y︬��l�(��豀��^�@����ZL��8�_�}Rn(��<�y�z��D0����j�A$`��]��#�A��΁��E��Y�ڨ�DxW)ҁ?((�*OO��P4�#b:��-6مǊ��vWHҸ�K6E��#N0Ї��C�e�]}�A�k ��k��6&C`�X3��?�z�#�=�R��M�����ͽq�O�f�S�3�D��@�ҥc�]�|<wK�˪6`Qw�;q6�LY�M�}^��)�v�ܭ�������7ft� #��W-���N��a(�r����ª�C�<%a�)�R��Y�uX6�/;l�[�������@�*��@��CYO��J'�3D/��;_{Š�������=�E)��5C�>�L�88�����ͪ(�z%�K�I�:9wx���Z1���dI�e��p����Q�R�r����nx�?�5�d�z8���%d�n�b�`�}�گo�q�&��j>�J!�,�O����+'��)������y�%>���`w���#���r� ���+q�ʴxu�'��E�!���Z��M�R]��0������7�)���G�Z,:k���5�����֫ϼ�H��D˜$.>�%�����p���$z����gE	��pk�������b��>f���	��d�K~�<��#��Y�F�����úl��<���0F�n˟jRm#�C��SپFr�S
�1ʀIZ���d!�,��T��.g^u��C0��>��-��.t�;Da?ɶ��r��W;��ll��ː�)G�����<��Z����2ˌ�r�����S��~ݠ3; ;�7�R4�$^�f��{g�2��sV-5#b���E2�tK�_Y����P��'`Y���gH V�SS"J�+6W�m��r؍U���6�e�!G��ٟ�h�I���?��{�]x>�]�*xM���KU�F�����c6��'O�U�H���P'Z�_p,�ʅ�M7��3���Y*A1ln�]�B^�7����b�M^�e:���C~)��2�։�����:���o�F�Z��T��fk�p��gj�ҚR�+����X�m��=�0&��H�=`�$�w��ן�VJc���m-[f<{m�����,F�S��(w��TA�5�.�l����d�`+=U?��_2�ˠ��Ý�y
j�4�<-�.�=a��o����g]�V����(���t����hx�!�� |}q��@������8��Hl�y6�f��%��y���?�s���k�r��?���R�4�(P�v�<��O�YX���$w@�$	���P��i�Nby�f��B�h<Z��nĒ�ק��B	�'L?�w,�`�x�W�3�/�v�f�ڊ���a��$��Y��?�:�=���ML�߀�ߕ�I���Ks����Ԕ��靜t%uJ`	�C�#�uOo"~]�����`z�A���a3���U�N������{.�i$�������t��T�!u�6���VM��K��s����c�4�Υe����8Ꜻ���#��7��i(fu�<$��L��j�������vF���o�����Qۨ{U2YXg�X�����+n�S\	䍴71����}QC�ko&����l�X֑��5��n��|#۸I˼�;��sB�2�����FZJ��9�R+O�G���w��M�΍d���G+#)�Z}�hDi��H�g��jlԎR��q�$��Y�F���nܺ'~u��kC�O�q���]������q�٧(_������@�"���h�ϸ}%S4�K�<�[	�k��{1z�y�Kd�[�y�9� ���픲P�C�zߣ�[�[:�FB�TCbq��2�ƧO�"�h��)�.��Ei�Z����r�(����}0+��N"�.q��r9������(�Y׮*���8-����HD�(�9`&���uH2>� ����~�"3 ·I���K����,�tl�+=I1���f�-%7�OK˳�.k������̖BM+��i�鿏!��Z5�r*����鶸���iL����#c�����s�a$�Qॳ�߬�*�}s�n"R�5,P4�	؜?<}H���Q�;���ĵ�3zЙGS�/��ך�A2�-J�W+�%�<G��1����Gqrƍ�6��j��2D^ԉ�52��I/ֱ�*ߖc�}�vg�5)�Mp�§�^RHE�)V~�'?�"�FS�BD[pz[�Š�ʊ؈���.�>�G^E׀ TUev	���RA%����\����#ơ�k��W/1	4~o[�xݨ5V�����@j���۟�]�?\�;�g�dU'2�5�n"\8D�Evyݸa|ȹ�犜W%�%!4j%��ϚnW�Wڑ1�1���I@Z˓��@)Fm�N�q3/3�NwqԢ�p�5�"��7��{��$�g��8U��>���I':F�^��_1d��Ȑ�@��q���l}�ۯnX~�7�ȉ6o��.��K�F�JnZ����I��;Edtgl�f�!�-��M>�o��5�#���냊�f7�����(%:J
o�F ��!1��
拦�Nj��]��l�Dؚ)�?�*x���]�J�G��{��g���J���ؠ���.�yk{����Т�f����:B�)�=�-��+Е팥yE�G���X=�D3djl��VLQp���F�/�L�8��з�wu���q�k����q�)R#�H#���7��m��u񻶜����?�һ	4]/\� S�5ic7�X>�����V��A�e�{Y�@��d]*�1��:�h%q��O����9m��!�x:F��k/6���0���Fr��%��(z�[�h����{���@��kwk�G��%b�e���1KN`�k��NP����?�W(g��?�b��F��w,ZB���`ɛ�[���%M���C��4��e���!���G	/�r��������\d�X�����?X�8�|O������,ꀗ��Z�hp|�˟��(T]z�ؽ�!Zqw�|_˽�1�,�"D<�f�/��e����]_� w���㠨�����_���0Bl��u[�`��ٔ5L�w�X��(�[*����ɇ��3�s`?���Q}rE,�V����lZ®�:��.'b������Xפ�������^&��춂���OLx�J㈔�~yƮ��v*&*�#�������{�&=��f +�yf�\��C�\��g#�\e������$;��Ơ���FiP7�E�1���y�ΐ�Bي����N%��U<Ti'�fik�ѡoE��!*�:7��c�~s�}n�Ǘ�*���Y�bh3`/_��w�7�����C��k)���P��Ґ?$ ��
̴���"�(Zs�ϮU:��c֒7γ�Ng}�;��ݴM��:��^�.��.7�=��F����&�ׅ���)�������(=}q�����<�'V�3φ2# ca�����Q�ݛ]nEk@��!V� nS;��Q&�ׁ���u�����tk�È�~K�a
5L�cw���t���ma`�sj�Ih	2���N���q�yb6�Mlvĵo�t�`1zIy���jW���Ts���sf�k�6�������8Q덟�h*�
�X>���Q��1G�}�`~��� �C>Ly
`Bf�J������ٙ0C!���!s��8c�f�ҪRB�_<,�&`u���>�RӲ���_�Jª� C۵�[&�
�%��*�*��<̒#��}�Ɣۿ�����
�@[��l�Fi�D���l����0?n�읿��_�&@=Zg�{��䨦L�46�,�`Qù��BMQc�r_�m�ʝ
�2=a�RT��ߢ-]�j�OJ�$�'�-�B�q��x��G)�&:R_����>(	Iy�
�Fi_��Gg;j�m?5_h3���o$����Dpe�m�N1*�'��r')2T��O�|�H�Y�~}�B_��X�g��R$���� �����}�����v(���TU��u��+D�E6f�>��&:�X�5�=�7��Mm�S���8�g��Z@�K bW D%;�8�*<���*���A �<���x�MwwX�l,%��F�it!�RʾѮj�X����v�B��I��)�M��g�*������z�*U�	<f0/����/�<����R)��H}t���t&	7(K�h��T%p.�h����]j<���Q0bҡt%��d�)�ng�Xa{Xc��~�Hƀ�Z��ʍs�Y<_.�_�|b��hERN�ԃ�݇3�><S�Mt�����q��Z��5� Ԓ������rm�O<�l����io�J����#��2�ЗW�#��NZFm�eh�,��x�4��T"�t
)�9�&����K��Gl�iS5�U^ԅ�6_z���$H� 8^.�V1�X#��!훇�v�b�/Ȓ�[d~�o<��pAk�Y"d�l��ױ�J�>��� ��ϸ��G>��*�I��< ���:P�*\P��AH�y&�1�p�X���q)[�>��$��n���+��F1�DFREځ14l�2��~zy�����)G��+d���w��9�ƻ{+�E8�9�����?�Db���7�g#_b�atr�3T^�5�ox����F�����w$��q�]r���To��D�4�W���1��S��z6���m�,]�O�d��IG��������]���~��F<h��󊩦����~��&��&2��$�����*�{�	���N�P
�ew�ELo%��?N����wF����(��OC�Υ���ő�t[��4�<��7��@mFϢ�4[F������ b�B�6�:ʦ]�"k$ _�t���v� 0pEU��>J��n((_�<K��tzx���~��?ʏ���@)e(�ە-�Hl��S[�i/؈�?@�d���rA
gF�#��p��>�&@\o�S}��1���Y�We������t4Fד$��!o�9^��Nݐ`9M�ؤ���{zG��5��O�L��+$�P���CFjߑf�yZ�"�ea_�=a���]Қ���������Y�<��������p,�T �;�$3;���A|��9�P��hvg��b��S��b��O��y��%�����H�N�.���K%�Q�:���=K~��Ք�j2c���dā/&U��[#J�Vnu���lK�b�	9����c�<��8���'!��<��QDYV6h��&�����F5^M<:z�jY��L!bf2b˄:�N�.���͏���F�>_���̮��ْ۞r�	���)jz���e�;C!���6��C�TQ�/Λ�K �,+K(���%;�!��    '�d���� ʰ��vٷǱ�g�    YZ