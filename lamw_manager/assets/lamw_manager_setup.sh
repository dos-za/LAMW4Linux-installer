#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="932091888"
MD5="53fe4187e7a6b3bcf166eeb9fd6653a5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22944"
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
	echo Date of packaging: Wed Jun 23 13:29:03 -03 2021
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
�7zXZ  �ִF !   �X����Y^] �}��1Dd]����P�t�D�r���?���4��sG���]�?������"��Izi�1�Ԉ�Qd�I�`U�+�$VHx*I8t�Dcr-A�^�%]SSO��/Ҿ�������� ٚ��%��!|ᒸ����%<;���uD���W� an���f�� ����Q JE��:쀛�)��Fr��hP���F�퍃�-�XF�9�v/l) ;p�D�n����o8�"��w�أ��ʇ��+Q����/����E��7ĩ��嵜�|z�˹~���{	6�_k�dn��nv0!�J*�����O��y�#3Z%;4� @��5Ź����T �h5���ɫ����SS��=_?�AAa�
�ˤ�' <�I�j$*P��^�A�0{�,�gCY�-8\��A\���(���2�f���1�������{����$Pa��rO�%e<��T<�3d��˘�?�&�}8/��BP�-w��Pfv�9�_�z�83σ,8t��|��~2�`�0Q���aA�R@ @!��!��󚊓�:v����Z��&f"Y3Z�1��G3Ր.�$S�����&�iSr�TE�J�EG*�Y����v���;���#��,�,v3�K���˪���R+2����?���*�(��?l�]OM� ���6)�M�:aaN#�����EqM¦�Tw����,\�8̖@��A
'7K�z��W�o���������Imt���+L� ���H������vC�l
����"�t�(��yz��A�Z�����8N�9�hDv�4<,�����C��q��n]�6�����+=a�;��̗��9��dW�\t.J��8�r�LZa��d�V%HW���\�x����[(+l�]s��u���c��a��{^��w��§V�貊�.A:�NGw��}������<�H��U,��m���-L<Un?~��y�Z!ަo(�����F���&���7������)�4D�Hݿ�aR��r��%��BF!tr��4(4�Zӂ�����D�h*�us�9����U.�Ee޲��WYU�$ĸ��@����69�T��}*~xӵӯO�M&<�2����ّ�G�a�>���D|k�w�
qasis?"{�y5oaQ�iY���٭�c��A�C���MʨF�͝���.I͍U��8�H[���.6�D�ꆨ�+�S���2]ik7���zE83����%)Gh��Nh��m��{�[��A�\V������k��^�	D�e�������A�Ȳ���\R���y��5�'�@�YR��ĳho!Aq�!{�1�!������!p�_��Þ�W�#���R�>�܀6_GY����āt�q`c�f�F^�?�E���f\T�����������v���N����\���R�aCW��9]NePC	�C���2��+��z��y��v�|-5B>y�S%Y��L��0��>�Ug������E}����T��N�0�0�enp��;
@`Ync��ɳ)��%[S�V�_��׸J|�D�X���=�'ў�J���L�.a��f�;����z�:6�`T���4�d��zy�1J�k�j"�'��@0�Ǫ��?�)����G,�
'ߪ�.�6��S|xQHS����F�/J2Ŏ��}�1���W�K��>�O��~]�O��m(o[�'��"�y׉�q��U0����z.�	�A��7t8.����85f!9�Ǣ�>#Q��B9�A�����][����k���uv��4�
H�Uɳ��(/��|`<�1��a'�� ���5lz��d`�qA�Az�,��wg�~14��<���9����C�=q\�~־�O3M���!��pz�[�^�hlv�2�y�K��d�v���	��;��vL$�-bЏ�N���\E�gZ`uϾ�/⫭��� ��5t�ut���(I��$kᦔ̆��M��]}徿o,;�L���;�����[��傧U��ɤ����T�1!�}�>n���E$]'���=~>�O4��L����s g8D�Y�F��L��6Ϳj,��Iλ�w�Od24����Q����}�A~Ц�㍮����O��lc �鱀�˒����qʻV����v�Y�5V����Xox&�)\�{P��ڣ`_�Õ�Wf��[���_����o������V���%���i�Ե�c�S�D�,]�����H	V���)�D��q��@]�pV3܈EP�6���W��Oa}^!wm�l���i�aT�D�[S8[
����"��%�`��=��H�d@�$�f��w����ժYkٖX����MD	nd�
�����<6�,*<����q|�H]�h�ݨr�aZ�G�e�R��4���>#`j�_��"�����ιFy��8�p�Td�$�A��sJ����Mm�)mh�,�2m�򳄵1]0�Vh $��b�L��'��O2_��|���T�yJݶ[y��l�]{~}�.k2�a����>G���ɞK�S	�7���<Z�L\�l\D[zg�z�������(�_��J�᫗���b��w0�y�+��ze]��SL0�͍ف%cp�ի~�A�&�Di-��E�.�.�R��K�E���{_�o��u�(���g7�P�α%�Èƻ�
���}$y�z�H�b�r�Iv~�"�poW� �eLđ5,�v�i��x������8}q}
�!W'7�6iL�-���:)��'�$|�uұ҂7J���[^���
��!�v#ˑ"u
���O�[��5�~32����ii���^�C��ĀӵL��rh���:W�i⛏��=1`�E-&H�Mt���(e���H�h(B��bqYB���+w6��"�2��*%�~^ρ�D�4��]�r�w����j�ć�����uw~��+�����ߠ���9�w9�M%沈�2��^n ����H_�_��Q�Ր/��TYP�mfE�A_�����euޠ�������� � �1�}N=X���_�(ǎ/�����;9��)�|tX���k�6X�Z^���֙���t�"���Kuqp�������N�۴�34�|sǽ����;q�/�O�mҌ�G�Pd������c�&�P�<�U2E�7��O<8�O\HE���J���r��i��R��9s.����R����s�y���TK�r���s5r䩴��ߗe����aص�jL3M��yUcM	���:��T��'-������3D�����y�Zf/G��:�&N�nu�����Q~�	h\��A���`��ฤjbL���H��^&���d�u����9�Ǜ���k�B��S�n���~(~�M���7��f�N�m�QZF㖳�����#'�0��`� v&�����>��J
Ad��M���Y3d��Ȼ����Fe���n�.��.��ثXZ��y�"&H".���-���D�4�;q�n�-0����@J�����G���c�<Sh�^w��a�*�~�����Ā�_�=N˙Q�J�&?۬�y�sK�uf����h-����%���t�-o�eQ�K_�����ݽ��d`�783?��RMW�N���_9ǌ��Q��K�a�{��������K���*Q�2����q��[fѻj� �����2�$?�7Q8~�gM��/���R�̜�kE׹�����,7֎����,TF-/4b#ٗ��O[gdKz�mٚ藤�."���5&w����u� eX\� 8��.�$�Q�>��*����v�5�*8��2lj�cy�"U
�hэE59P�t<�b�,���X̚��y y�-�"&o�OO��z�)p!/9r��D�e��א�,!.9���CT�N�3���&X>���5��|w)�e�#��L���n�<ǰD�shO�C�=L�c��
y���.�x'Ǣ:q���Mr"�<�2�VV�[]�7H���-Il�u1~u��W�������=gP ɀ6xծfi�?N�)z�P�b>��M�_����d�`����4#�%�w�D�oraIf޿4��;#����wSu;)��uZ��6|M����E#�Sk�� ��π;y�M"Qw���3=q���p]�&m`v=˕����5�ڒ�z�=�N�1���Rֶ�i#f��X7�T�<A�n�]����M����!sq�[l�K�;�tW�v�QbW�fݵ���&��wv�ꢧa��Ӕt�-�aT[~%S�r���A����`� �������q�3��E��R��\`jy--�G��~��o�yh�"�/4]���G֩�bZ��N�>����� ,�<y�a��x~�	�Y�I��6�z`���
�pb׭�N^��"�B8�Vd&®%��c=�v����[Es�ݹk.���l�R���u����ϳ�r�+M<�op.Yw��:��Y�
Q:�0(1��'2]SEm�n�/x�M4)[�bN��lNſ������=%�P�r�As�GV�h���~����](x�u��5c�~���3 �0��SB��A���+�p|	d$���Qg�Ƨ�ȏ;gd웛�b6�;�؈Gz�4P��C�b!���0�8����
5�eZ���dD���,s%R����S�.R@����4x�ÿ�sn}(=UC����1��O\�i�P$���x������U�b1��-���~[��cn�����yQ��Χ/�&P�2��W��!va#0�ZZKLC�)�rdW�jE �*_��-�#�~t�
97U!U�u��|R�#\p�,����sB4�韫`�'�x'V aPр���Y/!謿�nJ_+�-X����=�h�B��+J� �Ζ�1�nc���O��}��~\�l@z#财�� '�k{�x�ب�_�)Z�B@QW��36e6�&�`@�?B��x@�uc������o��_t=,svm��N��aǻ/��j�0�U�}A�>��s 	}��F	�0ڧ��b˂ݩG�f�eۥ��!�|�ߤe�\��{NZbK{�K@&:��r���k#i�pU�b?Z�;\!��FJ6R��5�M|U�������QW\�e㥹R�)k��2lk��w�~�˫���ɔ��Z���P�k	T��)���hGPժOkG�Hܘ��5Q��<�k���r,�����ӓ�[P3�
��H�uߕ�)Z@E���=dE-�1�3̣!�����&+zMaW~�%�\wMpnܻ���qs�kiE���n���*Oҕ�㿇�)'�\�h��fS$���1���_�`��1%ֹurc���z����,�4̓�,�cܝs�u��^@L�����	����zk����rRac�[��Z>�Á���r���/�������3!�_�8�Y�}˘=��ZU�����m;^Gޒ}R�B��n��w7�ӑ�9}���c��a�x]=C;�?~0 2B혥����Qkzb%k8��\	������ 
=���b �q7��¬��e�����H�"��J��l��e�!�<澖ɸO�G6_: V1�E���zeP@��zM���씒sz�3��#�Ac��
&3��qO��n
!{�����xL����V��G�zX~7���!��v۽\�ǚh�5ّ��Dw	���%�����' �O�g�\�Q�t�z(����{��"�"γ':�U�/Z��y�G��r�k�8�g�a�N.��0?�t�S�|����^+l}��򼍯p��羲�Z��(�Z7��y���p0@�s��bT�=d;�)�MK�i�Q���P�Ywc����$N?��Na��i#�������9h�rq{��Ȏ@�h�22릍�|@uX�bƼ(5���Vt��7-�t��+��H*��5u"_Zc>�h�v����2�/�� �ɼc��t0R�k	���X+E^�p�B�w���Ϥ�43L��F�R}����gaq��X��:�"�����9�n �̡+�`��g��Re<�r���,�i���Z0e�*����3�� ��'~��]�,�5ǧ�'�˰h�8�����0��#R9ذ���B�_jln���&��;�O!td`
�Y���}[�h.�i�@���/{.��P}3�����SF/y��^� �짩\�y�<x�:��H|�p�4�ͨ4�=-&:8���4�V�O'���x��y���C �!h)��Q�=����$��`��B3 Ƣ6�$.���������yJ�]�[{�]»����ΰ�&H��>���i�"d�Pfv:��P��~��G
"���ą�*ZJ��.����6;N�)0����Wh���ʨA�5��)9��e4��pr�1�&��[U��P+j���Z�=0� /иHyf$OH���#�o1�k#uF�6$k�0����6_r���j�˯f�� ./��V��Gق.C����$H��ex=�z_�]<*4�d��C��^���(�P��ʴzȺ�lFfV�Z"!����-��~�cX!^�I�i�0��ta��-yM�Y׌"���fo�!���Ѡ�䛻����
��R�h�V��ّVb��,'�6\e-S|pb�Bw��������!aiB������)��Pb�}�$z7�b$��d���(��xN�����(����?�\�뫏��q6l¢Ep�a(��ӰU���(�*�U�Ag�ѽ,�C�6��P �3&l4bvb%@y5�����`3&v�u2b���vp�~����v}��h��|.vp�v4(��@1�F�8A-���Jl���{����ح� ގC!5�������|[��o����*����vVp���[�@Wx����/��A�M�+�]������h�W喢)p�8�G���Lڻ�������.$�M�Tl�3y.NIP�T�0pH��c��/��pԿ�Vr�{(☰,-&��_v����n^���j�v!l��Fc�D��7�P-�7�P���
� |Aw��s�zZ���#�ß��Ac���H�}H�b�� j\�"��P��t�J�?&iO���Q�!!8H�@�����ƒ�>���(��s�GH⽨�6%��]l�r-Q%�I�tb��+�����`�s��P��g3�`��4���"���TU����8�)�]&��uki3:�z��k!��Fr�
�Y�"�(J;<ʓ<�d��/ ��:c��r�|̈�����3M|�#;!`�?�=.~^k5M�(� �����7��3٦^o�O���R��g(�E��e����?0N��7�R��!�@׮��CcR�4��S��.`%��������0�z�� ئ�I��V�8�-U���,gn�gcK��� p"�.�,��<��I�+���R�:k4��/-�wwDl�G o����-*A�A�P�I&Dy!�y���5��@I��?�ׇ�j5�'Ʌߤ6�YH�Xy|����l�u�[^���<}����dmT�#��\f�D�w�U�#/BW��V9`n�0)&cD�M���nZБ�T8)X��s|�����Ch�V�kI�1���:I�O�s.��cċ���tD�p}-�^��҅�ƽ=�[0*4:煋�n0~i?�"�_.��F;�8�"v�o=w�w��t�G�C7�� w���a\���P��5��m5�啫�[�Į� 5�*Li�r�E�WUi�r��COns7�������U~��tV=�
벢��
�Ud�4%��:���͒ޞT�
��7��0E>I1 y0[��3�8��+�:*�~�g��,�m�@��+��B���(����2RR[�z6
���9U���ٟ~�F����/��v��-<���MS�Ϟ#�F�ړ-�d��@�RН_��7d��$�AZ4�Z;*�47?k^BțsI0��d)�LF7��GB�t|J��z],=2��s�"'X��t?�8�.-��<~��~2Ü��*ԥ�,�*�X���3�O%bK�\r�Cf��yE\%�"!T��Lv��7���|�r��EuG6�g���Cvn� )l��9�Vmy���M�L\t]J�j;��}�H�V"���rI��H�,��P��a�4	��'k�3�q.J����mSm�G}�p�O5RؐSt��-̩�k3´D�&����P�����.�r/�=�̟�pP��V�� �Z㴻n<��FG'�p �%�|��j�3�+
V�+r�Jφ7�b܌����s��󢹜	�@��ΗI�\����G"�ʮ`��o�:!��*�b�8ĥ�t}䧀BGet�Hz6��J��*���[���%h�ǫ7=\��q
X����oӹ�/G�"U��5�����Z��se����*�0S���q��e�k���)�����&����\�OӨ��-��Pk8�ʣe�O����{<.b������r>�����O��; a�&� ]CW�f��=���=/y�&���
��s��P}�ٽ�Z�4��T����5����a�*�kV����5I�J:�^��O�>
[0<ZXZ�.�6��q#w�4;NE�QДO*ǈ,G��j&Íy~�Z��*N9����6���g�T���I���yG_�찌[1�<h8��F��p/䆭[��dS[� V�����Ϩ��i�%/�NFR6�i���U�780Dx�NJ�R�[(!_/��s�'�8�#�?.�W[^��+��l��Y���+P��S�o���U�Q�?�b�A�}�D=�n�|zNho;�e����������MF��ǆ�o0��z�R>��q-WN`�`���Fج��L�Ji$Ȝ2��t�o�M�8���6����7h�b]�M ǁ�F������9l�ejN-�m���	i�%�ĩ�����g��ʞ����/�uU�kf��E�
Z����̆\�P�W2�/�eE�M�\]p6%ğ��/����n�^"�9_�?�)��R�v�4�*A����7Fa�~���%�H'�%QЛ��T]4�JFa}��%)ׅ*&��5��Qpr��;��e�27ZM>ײ�9=����"���NFs��:O!p��x����-����29��gH��U�F�� K��G�-:������Z���?�D����k!�O��q^s�[�5�&ى�������}�#)�1�RO�J�F�mBڽK��ܦo��ݧ_�5������?��j��@����������[�+�r��x��k��j|�c����& ��K����#�����w�h���s�,����`*c�8�c��\�ب¯;���pϚ�@��Ѥ�aJ��|����!�9�`I��U׀}�����
X��1�Z��Q�*
�le͜�]-��������s�vy�$��6��[�l����/��1�u��B�U6f�����KX4���i�EY)�����
Ic��)�*
Յ5���3�� �z�]����,u���&���3%�%ޯ���S=�]N�y:���N�κʈ�>I2"L�/��S-��4>u˳��*����� ���&�G��PCz�-�u�tg����0�W���S|�긱'�fY���9�O�j�3�����'������S5��.����Wb�8֮�p��[��)�����-c���!�������`�����g�� ",!�z���m���P��[�����gQpw0ɾDv̜��	oB��{]���:���iBF
��/�t�c1F�=���z���n@����tDsj�� **YF��n.��G[a�u_az���t�9�������^3��@.���5�l�/,��#�V)��y1���?y����/
Éx�!f�3�����8e;�U�����P�u,y�c�����W��ߙ��h�;Eh��@��C�2�C`jݳ�p��X�l�<[�	��*~.���Ak�)�N�}�K��X�T�����3J��]~V0�o�*��^7Iro�����
źc��1�1];y�B	U�Qȃ��(5�0|�{�(Y��r�HC�X�B�Ʀ�L� ��V�s̟���"������aR�k��f&~�	{�Ί����e63�BQL�cR`Og�s׼�%���H��`j����*X�Q�H�����Yyי��U��ij���K�R{���ȋ1�|6��^LZ�E�=�>��ׯ�F9�Dl� �^��?R�*ES�a|�ih|p���W�vt�+� +W�g{`~l�]���^�)�hv7>"�n�F34����R���#��EH��D�ZM����?/�s	���߬3x����X]W��I�y���x�v�Xk�1Si*s�Ϋ��'�e�������w2Ԣ�F߀C(����J/�o��T�k�r�cQb)�5��!�<����\S�v��T"���ӧ@K�Z�b��ͺ���J��c�&�s0!����hp��'Sё�2�9�%jKUv60�*DQ�5$Ǹk�ͅkzB�"��06#B0��2�Ϳ��s�ߜ�:?N��3%>���<
Ⱦ@�/���A�C��O��s'�@���>C#��ǂ,�^�e���R4n��(W�"����$@5Fdx�ơb�3�,e9Z��P�*Xb��qȋu�7�/v*vqQ�Y� ����x!�y*�%m��T�쐛n����-0�-8[98}7ƾ�#R��ϫInP��s�,�H��(a��-9��ү#����DUd�K�L��a¤�%h
��<7�o9��D��	4lh�$�9�Zm3�����`�&rb�*5
�r�kz��2_��N~�e��7�H
��A87zp..��k�f�(S,US�
�]-�W ��BI�a��M����U��8��8�n�5		�	ȕ��֪t��\�_�R�(R�azVN��hjMD#�^>QvrP3���D���{ԍv��"[i�Y䮒}e6K��� ��C�'e?f���� ��Ϡ��q�!�zyòf��N�v��,&7/�:ӷA:yC�^&oZ\�L�ImK�(Y�,�|�$��1�=�	�C#G-�⢥��h>��L<��^=h
�!��:?�9�$�j��1�3��?b����\$��HB�f,TY��^�]���:+�T�Tm���4���?�D����ؘ�ctq����p@N��#�HI@�~]��*�<�w؈�h���>o8���"�M�0fB9 v<}��<5����9+���rc��]ׅ�+�6�[Y�3I6����W��*����7_5�;p�*ە綳!�*�JQ����
c�T��S�]�3C��sb��F�9 0��f�
ُ��Ķ��g��H���MM쓾\�j�&^ƌ�8�݄g��uh:�M�aL�"mǬ���XNʨc
h���.~�Nt:�S�޵;����U�~�+��e�轐HY��)��h.���-.�||W��=8�r��w�߱��_C,_��=�g� 1���T!���C��k��
_I,E,�X��QٸZ�]m�;�s�q�-�"�ù��{��h�F�d����mr��z�.c@��G���}S��5^����0���i��p�_���S��5qS�[�#/��d�v�Q�j��r�h>yh��-<>�Q3��G�SJ}.���ѿciiN�l���� z��t9"�lqW� �ޑ��3�Y��P��VIqqu�"�u~��z�g�1�W�?%{��&�"�����\̆7e;�p���^�a:�P,��o�j��	4I�	C��z�{�Z�J7(�T�6=���f��� ��.7]D�� �.g��4*	t�l.�IF��ʁyz�w��(yI%��,�=/�G2/���ꖍ�����⯧?�:�r��Qc�{Ɛ�~\�ص&f�T�za���pQ2C��s����?%Qt�*�ް��O�(ç���?
˰I�j �@����"R��:U71�}~j�#I�����Rԯ�=��a]��!`��rh��|�9��Y�=,fb��V{�9P��s�d��	#��K��2��A/�&�> ,QP�_%`+��$K��E���א�����(��S��;����{k㆜j�B�=� h��~���i�����><fS��@V����y}��u-�Ev�!X�/b���&yh��0���!�|O�8�W�ٌV�����=O�����?P�Kf���h���2�1���n��e����k�9&��t�������\2t���m�0$�������<�L~1׀\�*A�2Rލ�m�_w����������/t
K���ș�H��4HĻ8B�i����.'XLmHe1hɢC.疋Ήt���������@SJ�q��>���´'�kD�O7�+,*�bZ�@-���ǋ�9��A��|/��mv���S��g��
�e_<��#�Խ��Ă�'��~.=����9Z��=3�� {�[���������	��8��l7@� dzn�ƹKIY�-V�;�q�o�^_!;�]#�����������(�d�L�&��J}�?��.�,�.��x��n����ћ�z�wg���o˭�$?;s���1r�K̲���0g�d��M��5:6���C��.ROsB״X�w2u+��b����De��܁�� @w�>��bv�qBӎ����3�WQ֪&wN�BN�����}T�7��<��_��@�P:�F��m�)�'��{u�|	����_�8�J�D�+g����@�ܱS!��b�����̡����~�(p�T7�_��HLu��#Z�M�r����*$���/��;T�sW�ۦ�U/��I�����(�b��S**�q��,"~M�U����Lz����s:2���HD��9֖�O3L�c�%pwN#�lv8[�,ǘ�x"�z����]��ɍ7P C����7�]�b��+�XD�梱w��^�^{1͘qp�Lgi�z�0Ɵ��a���4}���|Lb�������-�~�g�M(R�[r�f@yH�q���]�S�"�,��c�FD���z���W�\ҾЧ'+OP�+�� pc�T�T��%��{����#��<����-��l���i���� �4,%Ʒj��,�B�ξK�Ђ<��:J� 	��ՆB�\v�/F�dC�[P-��
�~����avΤ�Kh}��E�X*�1�����ӎ���c� �.}�@ھ�2�ت'�ZH���N�#T�����	����%��?@��)��^1տ�P�®R�� #��+0v����{��QaZ�l@e,gU=b����C?.��K?,~h+t�ظ�c��4��-#�F���FZw�f�Y���v�����SDG	��q��%����Qo����\1�d4$5zx	�tDeg� �0)HK�\8
��B�"X�:4�ݭ�,gsK]��n3l��\�?�� �sT��\W@ꙋK8�S�%kS�~"$���>� �_0;,�H��t��IC�R;��V�b��u��N)�!̝_P�13�0
T��}�����O ����гz�]�g8��z'iH��_�����v=_o�!N40r2�1����+So�E� 2c	Va�b�'��O|S���W��v�b���; ��iJy=mI���K`����fg��+�H��iՒ�َ6������V�vHIX�+K��� �8�%���tQ`pUD#��Ҝ���7�ݐh%����Q�����ņ̲Z(r<l6B��М
P ��2~�][�;��D|�x*�� �?�8�����Ń�p��`�P:]~ٽ��m1L�7�!�R������≸VL���M�H�	W*T����\+�3��F�~��M��ԥɱpѲ'mEn�<���'�9x0ir�h�H��X&� T�ї�w���	L��]�#��85��0&��S��
��4�hߪ���C$����bN&'q+UF���α#�~�ބ7���ts�2�H?����W���z����
_s��x�Sg�`.D/��	�o�DT{{H��,܃���1ќ�w$	��4��I�W�K����J���M�����
��r���%}�Dw.\.E� �y��Q��C�d�.)�Q0 [~�⇱��ECě}UI�/����К��^�� �ĵ���7-�NDȣ��T��ͭ#9��?��vi�PT���4�u��tUiiu����������5�	�������v T}C!p��m�cS�6y=Γ�]l|gV�֦�6��
�l�PB��� ��BK1�s�9��)���~` AS�6`/4_*B��`��V�=��::���eFU*~�YhCj`������]��K�àDSN���3��ن8޻�(.��њ���F��a����� �~��9�<����]�s�����P���,H�3u=���ֹx�͙�j|1�.�}$����gH�V���C=G�V�!��X�q��j�?��x��e"��=3�H�����
XfhK�oZ�R2%�:^v������x��s�#���$.�{e��ANg�ھ�{�>c�D���!DJ�"��2�z7R�&X�;s��j�Z�ڔ?lg�չ��]��!�������A�X�k	7NM�/�Yg���)�ba�Huk���EV�*�����V�ݡf�?�9��T+,N8�	]���#�`�*��̞��KO�
��6���J�l]e��m\7���˧�5(�!��3���Cl��U�����>�n�e�,d]A��z>ZX� ��B�1�)������!0Mq޲��b��7M���%M8�k�Da�雀�s̷�D]��<��^�;�G�5^���b�g�b���,{�L��s֯���+W\-u<G_����2�&������iiw� cN(@O�����0�U�n�6��<4�������v��������-�'QA6?z�o�ߦ�mP�" &�eM]r�)b��+r�6|:0U[z��Cė�P����೶��oֈ�>i�D�:hVծ���	�)�����j�v^��2w�Gm�q�*Z싖x<���~�>���vi.Vx��;��]xOd���܋��s��ԋ�z �H�h�����)�8d�sa����Ft>X~���r�sUo��J��[<�B���a�ÍV��a���vK@��}(<�Mn�~�]Z�G��;7�O$�j�p�w7�@`H�������ҏ (�3�sO��oLb־-[I��<tv�u�HS�Ҁ�ʤ	�c���|��[�Y�R*$�Q�6#��N��۲Zn_.���ƪ�I,��x������#j٨�I)sV%���}��*�(��8�:�s*��8/ju[�$ʞ0|7��RĽ��7�M����j�?�zQE�D�˗���d�J����ď��`;jbe��i���6�I6�!����֠�߮� �Q�<�gUfL�_�EKx$E��Ċ�g�4Q���-yD�W���ܲU:�@FE�Ԋ��$�1�;(�i��r;溮3�;瀈�A�KV#�
y�aU� ��S�Ueq�ц��=N��|��噤۩A�����#�杇�����Z���-����kQ��إ��:�S��#q׃����B���{X�kt5�x���2
��x+h��FA�|�zFg��u�0�q��m9H���%o��u�P�	��\p)��	c����yo������ZT+��"�^�j���x-��_�����9��\��3�sTA�&���P�E�5�e�s�T|��/�)ogI��W���
�c \��LÐ�ߵ�^Jӽ\�K�m����'%KMH�6�����9(oŧh��P��Q�!�Zgt��8�� ?�[�U�^�֭*���������P�bY�˪����k�Us���H�G0LX	&N}�4>)!���,�\��&�=�N�>���jn,T>:��!�*�C�h(�'�f���SoD�c#�1K��5/��
ǲ�TWJ`vd���|;x�$N�M��kx�D&�7[uI>/ⷁ{sbt�Gz��޲FV��%��S,�4�K}>M��Y�/F��h�ֽ~4i�\��/焟��*p�0����%?���n���=`N�Fk�bP��Rp'iF��T\M�s,��A��@�>$3�����lÖ7n$۸����~��s'hEP�A���ۋ#��U��s��^E�V�C�Y�6�j ��y��N;�J^97@�t=o޷�,��	�1���>R�_)��L{_��e��f̫^6��R.67C�"Tr#e��`�$��is������g9��|If�� �it3�+��fRP�wo]����!\r���w�P�R��s�akz�ڻ����`�2��8��f̄^�	�g�ݪ�8�Cv���od��2�=E�i0xFv]�Rt7o$�g]m��t�n�U�����22PN��	l�����
G����Y�F�bF$�)*�C��ym�Gd�K�|�R5sԋ'��������8$z���oj泹9V�u�>9@Jr��%�'�u�������Oj���]�nf-H����,Wy�fy�!�o��@<��.��tmқV}L�X�T�eͲ��4�>`Y����;�3h7_S��B�>e�ǰO"P8����KT_�5�l���r�W�L�I<���\�$�Δ��sg������䎳6�%t*8j��E��)��픠��Ϛ��g��S^�C�	梤c�Hc�>r�"�>�>Vw�i���o�����T��F�E�s=?qǬC��0���(�(��aǘ�ܘ<k;Nf�+b����M�\]���BH��2ݣ,����u���g�&z!�92�Џ˳�|�L}�/�\8�� �����;��޲ru���z!�k�<f�OX�����_�E��Aӷ��Drg¢�q?��K�Q������,��~`J�H�)/D|��8���#����v���ī�˰��0��=��v�\6��U��3�T�b֩�B)3���N�@�
�wg6	��Gx�ѣ0��#����d
�q��pT-[��'G�E�Ɓ�ԩb}�U�}�Þ�I+T/)��D���Ԗ��4n6+�:��矑��w��3��?+�䅻�Y"�n�tk՗P��L�yp޾�.s�-���lB�0����M���ե�����م�͹�v0����������6�u<S��_9kU(��ұ�����]��k#ֲ�N��ڳ��+�GѦq���C}K�(�9���Ȩ�����?�Y��0��d	vT�h�8��&nO�~�[My=��+m<�ք������_���~\�
��c����x{W����!U�;��zg]����yz�����@)�,�H�jj\�|rI��%�m�6=����V��!����n�I�֕����#s��une]��B�oÓ�v���A6:F�C�,�6��dN�����itˑ2��ž��nڱY=2�`�gSړ�Q���Nϓ\춷�����a���_��0!E-�@Z� 0f(j�|�'�뛬���T`�@�P�-�ڞ����m������ �1F�?��R���eY���ҬR�'��x�E�/��V��&�a�M���kK��m���k�:�dv�$i���Y61��n�$^�p�R-�{:D� �c��bھ�}*��s��a�5��S�����2�o��P`鵤I��\N�ԅNB��HW
Jd����o$*�t�L��m&k�tܮ~x�諀�ʙ���a�q��a�������kLlQ�a%4jj����x�B�;w��k���t��{Z��E�Uҙ
��ՓӆR_��~dD���c�����6C$Xd�������� k�:t؆b#'���6��q�#��EX\������@�����u$,v���w�?39k��UB�nZ�y�`~t�U*���ٚ���+�����|I��ן��q������g5q���,'����Sr�W�u�}��C�؛�s}�P�!e ��k�3Ae-�k�S�N2���h��y-�=m0�����W�}�X�|�|�kMaX;w}��ﬅ��--�Mf�]�����&�nq��*
P�_M����&���鷁^7�4���Ϥ�E�h��dU��e�!�W}Nr˙䰴�r��l�}jD�ZV���k���gԓk�͐�ra=y&��iQ��.�����"K��+\��u��?|f��{\o�Ȍ1��8I�Re�b5B�JŽ,�N҇��Ut�rw3��ӂ��Q |�	�C�g������Sy��+�6OZ(M���[��!��w�,����7i������|���na�]�X��qϗ�~e�`��mh_"�ڳ�ofB���׺��&PJTl���P�q�g�y�a�9�`�K��2K���R!�v�/��?W�]�$	*��\ �2b���7�Q��
ur����3��������k�^x�\7Pj���4/���(�P��IOV]�;����,��\�J��ƨ,d`��e��l�{�I��P\�1aU{�lS>��W�@Ƥ$v����8^����i�֜;7���vBO."G��H��/��E�ZT���n���x�A�=M+#'ڼ�Q�x�&Q+\y����
�7�Y���~^y�H��6AI�-	�o�:����p�\�y�3D7�q�Y��y'�,@Rxv '.���Eл1�~1S ��ی>|g(R|�(F���:&�����0j7u//Q�q��"�ͺ���?P�-j^-�c��0�ĕ�+���D���#��7f�r������V&ʱ1�em��Z=.XTe������V��gD=A�����I|�FY+����R�JUY���@��?��]=c�⵸�ΒR<����8� *�9����ScX�=ź�@ ;��ZJ�%��8Uɥˍu���$�u���+�,�]�^�k�O�L�wL5�K����y�)�L�6��X�"�J#x�F^g�.�Bo���ߵ%��IN��'���6z{�X�p�=d!�0�
��.ŲW̑g.X:i� ��X29��F���سr=v�o�Yvӽ�ə;z ��{��\�j�[�0�KQ��sG���h��{�z�M��*�u��߿|e�r�o���*ઞaZz�X�Ҝ��O<uW�9,���|��i?}W)ϩ��s�o�b�l�%v��d�zo�MPt���|)Ag���e�'ܶe��j�������?��:e�81s��]�t�h<(��+Xا:�o�!4ة���6Ó�m�_ʰHܯX�T{[�A����,o����Ud��A��t��UwNf]�j�l[:�L�<I�5� ��$_�!�1|��S�5�yT%,qW�0^�8������2B�!�b�!�&�1=�$�6�ߺ��i�0��-1�l!��D�o�ݨ�X��i�hpM���^�0���y��|T���a<���J��
�e���d"�B��l��`.)^;|x( �nv��/ȞM�#ib˯U~w���e{�'p7� WM���j�Ö���$��E"I�rK��Q�bvu�U�f���qm�xfrYf�m�ߍq��`����QI2�/ ���jĹ�v�"|�y0�����dCw?�\!I���������VA��7vJ��h�`���0 ZflG�'ܱ�x5< .y3�M��}v$�P�!dIAxgz�Q>��M�jB�>���B����v�a���YlPV����Z�	T{���K��'d�mU嫤�cUrj��l b�'����p��cit9��uYN{4��|rK��H�le?��W��R o����1#m-o3dr���S����e L�+�{1�eR���s8H!%��u1�c��q��wک�I�W�z�E�H�k��7�>��m;s��=~O��G��g�k���w�:}p�[��n���&�nܠS��rO���' ��E�\��(h��6�%Ό�F�u��Km��A�.�?����nM�j�O�$d��	(`���S����٧��E�Џ&�T�-F�6Xd�Q�a��L�ǈ�E�Q@uh$'U��\���
JGM����Զx,
�E���5j���=��ɒip`[�����A0fg��}»��hE��cBɲ��pP������;Ȫ�dՓ_a�L��~ykD�����6Is�Yh͵u�����wĀ}�M{�$ !g�YI��Ue�3�>ρ�\XS'��T�_��XΡe}8�2I�v�L�*k�3<e�X��f�=q��0�/'+:(�wO�wۻ�#b ķ���/�
�����\�^X�zx7��`�G��ټa	�?�hC�L
����Q{�-����N��9��G�d�t���}��n���}�ܾ
�8y�^����#���NP����-���?��x�4e8�ޱ�BRn�5D�3�<�h�B��p��jE%PR�'�Q�J�|���z��m�!��,�9���P���b)���J��K+l
7yNI<%�����-k7�c��<��
�dz�V�k�͹
0㭤�ss��Yσ���7}�ԗ9�F$[�6����=�����9[�����l�Q��v����|:@#���o�>P�9?Ţ/�a�]yɧ���Ba�خ,�DqH��`d�u�/t�?���e�� [�WFh�-]�/T�ѵ��HӠ=iN �{s�[,�чPE�����H� �z�����P�I���D�`ԙimlr��v$*��֛*��B^�^���J���	ф�H5;����c ���GC��t�K�B��s�6-�*�BI�wm���;��=\G�
׍4��U֔Ȋ��a���Ba�2���{@~�����'�~�NI�QXX�G�<��?\��p�ɽƯ Lr���W~\���t��Fҿu�R����n�b��1��;C��8�7�S�� 9���"+#og� Opŕ:p1���JJ:��Gj��vH�a���v�+[�5T1��a��>��칀q���'�A��pAC��G���R9��̑+�!��0cm��U&�2���\�JW*�W��x���� �8���>�k�]=U�� �O� ӗZj�:�"y�!x�c`ѿ1�(�rjM���I��Z�،����P�a/��}t"^��X��z���<����G���:��&S����!��=H�O	�
�uVXk�d^�l�LҞ0i�� =48qh��e`��Xg%T9�w��m��\Y��D�ǭ�%є����s'��m��\BW8x`��pmŤp��;�HɫYW�Й
O�ժ�QU���f��Rj�N��V�+�$��4�{O/�n�?��:�Zs����Xe2Qf��8�� ��̨GIs1��9��Ai�P2�`w�\l�R8ǔ����޹`-���d̒肨���*��� ~�R�tpR��vƊh9���R���V��⃑�xHp����Au���[j1��˺j���k�pG��*G���#�R���j���Pb�+=;�B�i�c��W��Z�BR^_?���(½�itX�����KD>���n���[A,-�k�id�K�����vr��*aP]C���"���e#{'�����O�w��=)��_o�0���9C6*�tp�>�Y�c���f��D ���|o�(0��PyMxwմe��]�=L��/�G����H8��Ta���<�l�u`I�]�v��Y���Oc�EVu���J�:~$jf���m�c/I�E���C��S3Y�6��m��Q-�;��5�[�O���&�2�<O�B?ϫ�g��β��H�mՍ\�fȆ�y?�½V�;�u��U�9����O8E��n���5���]�~���S���wk?�C���^��S��=�^�;F�7��٘�-��I���1s�^��������i ������m����Ů���ĥf���7d��[x��9y#��)��8޽ov�D��R*Y V�u�Dxn�҆)�٩~|1/zp���{�߭Y���x�C�"���g�OV_�bp�r� s��f.�.{�c��ɵ۽�Ĝ�8nsAa���h�3Y3��� �`��ļ��BYV���,�m�m���V��'1{�躭�U��nkf�}�����y�-���K}�f��"��]Z��\�V4cI-u�Y  �'{E���B,�+o�G��l������-<4en�,}��3���|�D���2)�U����p���ˏZ��U�GV&w��$�(�B�w~I�) ��w@X�2���h �Iiլ��_
�Z&���Ց��@�/(�Ox��i? �X5;vEy,�BK�{N	bXd�l�L�RE̠�<�ηRh���gR�\	����k
:�v�����
�h�*��6_��J�����w��/'4�&������Q~�%�[��^Gz��Gye,A���FSk�6 ��Kl��W��o߸��8���fx���A!U?\ %P3�d��--hL�K"�u�p�_L�f
3�ʲ��r�:)�@P�S��K���_4��7�A!,�!�^�(�@i ���dكRˤ&+qslMȼy-$�xs�77�0T&6��zS5�$ʝe���&o?����������b�����~��`E�%�"�b�������8�u
��yx�y�������OY��&NNB�6S=��:��c����P�6 �sJ%�fS���FA�~�:�0��
W�����b�m�p�k.��M�7�q�ƙwa����A�i��܅�^Dkfҥ�A��t4�Rj�&�C.No��A��fm��j���Y���v���6�����a�WI��'����L�hr���*��`����MS�Bk���r��r��w�j�H�:_��A?2��
Mȋ��0^���ҧŔX ����X]:�I��#v������d�!Cn�Sw�3 �P2H���-�;��/�A��B~��O~yQ�-�:�����YB��5    k@`��^�2 ����ދL��g�    YZ