#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="371978385"
MD5="0aacd874203ffa377e4ef4b71f3a62c7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24180"
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
	echo Date of packaging: Tue Oct 26 00:45:12 -03 2021
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
�7zXZ  �ִF !   �X����^1] �}��1Dd]����P�t�D��Rk�ÙH�\�Ɔʬ�^�B*>F;2D� ��T����He}�����t,��$<bl�5���#�x[��v�m������]���4�e+�����lW�=�Sּ����M�����X��֬S���.E�w���j�Cz��Gl削
Gm��y/����2��c��56c`�	v�`X����q��_]1/a.����n�v����oU8���O̈~kR/�L߶���ٓ`�}�X)`c|�2G�\����}B!(�e7ƢaVhՖ8��aZ�j�pZ�@�j��ᨊw����Zj��_��B9���:������.eٿ��~�#ۀ�ƻïbE �O�`���G|�壊|��\��ٺ�1��*��x���pi�]D>�@���T5� v���� �F�H��Љ�,�]?��_]�b�N����>���K ����{�2����~di8�[tF-g���#���}u����iܔS~vW<��H��8h3��[}����o�q~�"9��V6q���m�9�D�I@[��D����
�g�"�l�I���=�&B;ʸ��ñ]T��ޫ�~�e��x��e�#�����c1Ezq�W�+L*��g�O� ���y��/�2�+ٶvQaH�d�w�Dᮺ6�$8}��o��p�L�+Cb����W�i �22d+���ּȨ�����VN��1����tr�B�(R�_Tҝ:�&C��n�Ig���� ,�n�AS����4{N|v�mHAa<�Jn�2����s /���5_#�H5A�U�H�L%	M'�<<?d�E�~���E�v�Yˍ�b���Gy.4�,��VQ$V��9�4E�YПyQ
�ӷ��MI�����̞z{C'1!�����+˒H��,��dn��ӗ��r�lҐh�q�84	_�Ki���)PnV�X��0I&�0X�	óz*z����R�bu>YJ������M3Z�ֈ�"1TX�?8
��[�(�#(>n���-���i��7���c�~D�������{�}+��69��g��d���>����+�x��V��6n��i,���Cl,���o݆z�(:�ʶ��Y�dA�0=���h������Ɂ�m$���O�kI���Y>������%�V�����w���{Kc����EJ=��ޖy��dIEi��E��b�(��a������mHu��o�y�>�3u
���o�^*�䷱�E) �+�m u��*��5N��f���(��Ue�ǚ!C{�����m��b��E{�YYOoy�����c��ǲ:����X6M�>��v����N�wW:�/�]�D6c��u{���e1�dA!f(Y��ES놈�lnBK�F�·�Ӱ-�j+�ik��y�üR�C�3���~UPJ�+i@�� �%��u��7�Q���b�ɰ�'$H�p�XZ�� Z�!��1��.����O�Y(r�q8�[W���$si
-y����,xE\�b%�Sc�a��qv}(z-�kԋ.��) FQ�J��2{���`X��LL�o@���{��)9/��Yn4�����"�?��e�>�/ĻʼP�{~b��ؙ�Hj#����3��C#^C�m���߃��^0��֓ p0���[J�*؊+ﾄ�ha,|1W
���yČa��c��x��>+f�É���EǦ�6��ˑ&!��c !X�ڞ��L�ȟ�:�������d@�׏7�b�y!D|�$���T2���"�ϰۭ�gL֟bd����68�M<��C<�E���Y��Z/���i:����Ar�+x�a�8�����ˏ��6Z�0���J�K�������H����^�P/o^�dQ����~L4���ꀶ�b�<:B�m(@���<�x 1P���ٴ�]ǋ0�P���~C!�s	:�\����^H�<��P[��x�e��u���FB�wUm!�B3��1���SNj�I��'H?�/<���_I��f�h�fX�Kއ�V�V�?նu�^����G���B^�N0��m6�W��xjN)h?(��R6F���<�++����Q]�7Ru��Ĳ�� v�S�y���z��� ��VH����X���ky�)�{>��8GZ����&�[RY62}<F��Ɨ�v\Q��n|������[����B�YH��6ϐN���:����7Q��{��E�i�����ۗ��qo�%)H0���;A`@*�v��b��:Q��s��:ZRgA?O�?�)��k�8o��>����C?AP��0mZe��>2FB��<TCE&�OP��R+�&>C$;LsOhY����:�Ɍ�i�n/�A�����,�>Yc�S	��KjI���3G���əV�j�Ѡ�g�1'�"`�6#�������IP�B��@��)�tR�4�c�m�7�������|�oP4�j*G�5��⏞�i5�#����g�#� �10�(a�8����gV�#���p��E)��X�������'�x^�̂b��I��྆����Y"�+�qjAFP�Z$o;�_8�� �hޠ�}���q��+���̭H������=��}.�F��O�n�J.��q�6)z�:�k��hs�"�+CE��KY�o�̣-����>���O��!N|,��}�3�_,��J.� �!���)P�7�Y�7��)�]�K8�|r�I]'��*�����,�9��o�ٳ�{p�ƺ���Z���{���m=9����t2��Ň==��}VfVP�6z0�=���q�����@ku�o�zKk�3�s��j�2{�M=�|(�TN���zpzf�ec{�g�$�����|c�P�̢O�d�3�٠x����A��y(,�Jr�|��АE\_���vТ�]z�9���H	���xYN�2}Pr���Qcky��BC�/Bm������**�'E��#Zx) ^�c�V��1Ȯf�P-����C~YIjwukpF�C� Yn�T%ş�>���eD����nI�fo���Y�G]E��
�n3�K'�q�~h���qk �(ۿg}1�{c�4X���������(�'<e*O�:��-��k�2i�M����A�l�jR�rm�ȿ2@��@�cI8�k�*�]V��O�r��f"�b.��"��x(ĬSB'�dt�s[\�衕&�%WI<4����0�����twt4B�N�E�*�K���
9WD+>�1`��B#��t�ա�#�L �`[p�u���P],�ꎲ�f�_���b��4��y�E����b���-b�aY�9����
�"��qf.��A���;� d���"��f�+�t M�r�t�Z���k��h��/#0���x�?����<�m��S^p�E�t^����E���3���
�^���1���W�PW���E���y�C�����a �<mg��LI�~s悕�h�v���l���������0���-��j�X�E:S3.r�>���I��;�.͊�� �[�x�_8�P�3���j%�21���z- �z�bw*�*�ؓ��n��AΨ�E�;88�	'vu}�UXmGq���Ysډ���-�\`bH�Iˎ�4&�w��(^,S���t�ʫ��K6s
��2��9(SU�Zv���~N���8$N�"���������.
1s�#�}��!���?a�?f ^�sL���
E�Ϊ�%i��s���h�.��F�\����+�Y,ϑ����t�I�(�@�-��r�K��h�ceOL�y��S׷h�r�r@�OɑI���w�H���驱[���2?�hG�� ��6�����av�>)nȤ�>׹�;�<��t� 5�� FV�E�zu���k��lq���RnY�Ĵ����mD��	�>3n�2��)AU^���n����H�Vh�JZ.���$=mPǷ��>+.�C4Ā�ǁ���#S-{��'�r1#�H�S\,{���t��D捼�@����<z<���X*�*xwW�lg�ߩW�E��&a1ک9sU%.��������3,��H��c�d�*ՠ�'a`�.p��WSXӟ�%L���pw���i�Z�	gkﺰ8�ѵ|(D��<��@�2Q�� �Z�>eP�c��tP�¨a9�{_� ��Oh$c�����GAV�E���6��Y�>P΋V��I�M5��E��)�%hEU	������Ȃ�m�rҚh����E!"^��/��RÀf�u��f�.�=�L&�gpEµ떔��h�ܗ�k��n������]w>%�z�ufyk4,|(�K.GxbZ�廰�[j�3Dȃf�8�Wdb��P�(�&Ii�r	���*�R��p�3��~��@a]�n��퓨��+i�J�}:�����r	�j)�63KK]S� ����k(��X���[��5V�d�"_\��o�Z�A;?�Q�/_ҙ)7	�f9s(�"�5g����1�	�^1�SL>!��Gf6+�^a�̌0PACUQK��Y�Ay'5\��g�9�Zjt�u�����'1l(#��P��6��	vi��W){/�'Z�i*v� w@����'�;���|����k/�������n[�cM3=��	.���1��u�{�p�@ ��d����c'���;E�i�[b�+R�vVL�;7ːv����&��o�zfR1��p��Jr~�M7����	�h[�-�\�if3;%����}R4�꽇#g�>Ř���aʜ�1M�꬗��b�'�� _�7��*��uu�]`�"u�e92���l�f ���K���z���KϽf���R�!�Q���ܺK��Cq+��p`ϔ7��`���A[2��k
)&{-� AVr����[YZ&�4^���OT�k�3���«L���~8�W����}���>d�ۯ�!��AK7��ǝG�����	��}�Y���*�7	���J\��٥?<M�%v��$�V'a���x�'��"�0�X�'-N�k�m{���7<k�ah�V�߶�r4�.|���v܌�l����]��P�/,�t<eά�*�[7/���O��ҥ*���@Ү	T�MT�Lu��dPa��8��g�Wg(�'���u�a����ki�3�����@I� ����m:��e՗`����y����T��4��I���f�7�A������?k������:�A������f@;���='jWfh0�=�f���cZ��.��_�7E,3��[�F�9��i�{hWJ���ͣ����5�9��%H�NA=�/k7���#���p{Z��(����Gpi`��7�|D1'�J�7�3tL���]���I����[��{�A�S���4X�~L�X(���ѡE��{b_��H��lG��+�$���.���H*�ӝ���a�y���!��F��zi��8!y^a�k���^������27�v����1���r��4�����{t�mAE����Cz�3��1م�6����gSK2��W程����Ul��]ލЪ���~���T�8��c���ƪ���Jų+մ F�T���}s�e~��O>�|b��Vy��w�U���㵔"��"N�l��R�؝YC�0�9?���ՙ �+���1z�G���)�O�y?�J_�b
����㥪=����K�XC)v���2Z��݂�i��:d��pF�eQ�Z)������շp�{�Q��KS�yHꪯ��PK���n� nqﯤ��{F~��^��h[�'Qb����)���+���g��E1�����;���U���N�A�9��{��Ip�LP3OwǊ#R�Q�fԺ�#�rei��>�`�9���\�\s�㲽�91��"פ�$�H����̙W2�͒��_좃L���F`�����@I͗�D/��q̹����lF��&l�ʟ��fu������u��ˤ�y>�HHjg��&s=?�Sչ�%3��`T���R�����|Q������t}׿n=c�cD�O`E)�>�//]�:K�M+n�A�F���"���ˡinPϨ+�p�G1�S�r��U��?�?��ɢ�ۍ�R���+3Q�d��Z��dλ�PGe9D}X�"#�Y���
&[c��3}�̀���3��ء�8���q��2�ď �� ����g%^��%@�1�qa����\`�):��C.ѶGN�|}	�D�J�����g�(:�7/9�ט����{щ�L(Xދ �pS�t��w[Œ��1_�?�ê��nq,X�bJ�P�Q�$�8�a����������
�܎2���_�O�˵�I KlĞk6���d��m��n!f�ÿD�o #�92Eȴ|��M�+c0E�v�h8ilR5����O�	>:0�A��ڤ*/�9���;C�k��_���� i	O���\O8��0=���f�n|j� [J�_d�@F����|_u�������D�e�[L�5ϑ�m���3tS,�"jp�������qM7o�H�x�Mx�:t�,�^�1����掀�����4BG��]��q	���3a��{I��*c�&�	9�� ��S�I(�[���A}��%�Ȋ�mMM���J��΁9w�ej)wZ���Ө�z��h5�D9�A�{�+"����;�{��8��F+�]hc��L��k���+�S�8>DԬ��//��:�A��n�t�`y�mF�H����R�鴕�%֣�0HyN�#B@|羃�GD��zIE�5���P��pҒ-�����HL����+t�&��$���%�|�ٰ�ċQ�k�਻z������	���hcr��5~b}�(����1�=sZ��yZ��L�n���:��t����=7�B���Y�^_��ܵ%h�?p���x��K���!-+<A�wr�6n�\�L���af2E~|���������v����V���&����7�u	L�CB���[�L4:k�+����=�^]2;䐤�G��dfq���jc̖���\,;e�"����U���)�����P/���2��8�o�&h6�!���h˃V}(b�o��$	�c�_+[`����=rtiO����+���"oǌ�ο�����*Cj{�����.������uj:RMd���g�ZBպ���r�?7�ci��B[��6���-.��|Z�(�&��dDohSM�RR2��W{�,��GN��:*MEd�ͣ�6�b$$�;_t������#l��!f��)�)��E��0���!��mp#���6@��hl��^uvR����w{�2,_�s�Q���C���ݣ]G�.[gDN��B��x�c@���2��~���S�z^���C�voAɤ�������T�s�?�����~F����6I��Q6n�*[fՖ� r�i������[�D�]ka#�T���G�"K@��F����؝�!�@c�6��b1����gD^�(g�'h���E�=#y�f�^%��������P��8?VP�6�� 	�$�<f�7Y?��K���Jmv^������m?H�:Lh�c�.+,m�s�nc�c��lC���/�`i�Ѳ��	���y�Шh���tH��9	5����K��O������O~ĤY�SQ7��'Q�v$%R&.�'�1|���'v`�)��T	� �}���B�w� +a�9�;�[����$���-ؿs��_d�����P
�,�U�7���IwJ8��G$�C>^�U���+ͦ��3�������L'nQ���V��vP-���*F�O�RI�]B{?�� ��qW���:�}�V�u�F�ˬ���@�b^]��	6�W�L��&�L�µpR*/���Xu�.��~��ۅOZ��n�5�B�B2�i,�Y������T?��W �*D�`������O�s�LT2%ocn+�c�A��=Z�¡���Ň��>Zj��I�,�d@ּ��#���>���hb�\���$.������~5f�Ӛ�Nt,��9C}�<��	C�� �JRDE��<������_\`/Ќ�U���h�0����./���ɾ~�%�oZh������v�݆ȸ�Ϟ�����g�`��S��w���N�������[2m���������DjH�ш�?�w�`@�@s9E����/��ZΠ�Q�����${ˤ \�kS?����q�"����*���y{)Q/�����a��|h
d[�}�ΒA֕��ȯ|�������{�d7]���߆��CqЙ].>�	.�)�]��G��oMv�p���X�J��	�RF���L9A�����Ү²-�t1���F��\�L�>���8��Z$�a/YQeA��'�.ŷoN_���f���A���-?#���,M"�|����rFUa1���� zo��7׼�·�n�`F�,"���_Yb�lj��7]ʽ=X�LC3�����x{���J� �zUß?8�[��Ƈ��& n<�5p�Tx�`ʞ�ٝxǍf���u˴ݵ�o�I���u�Q �c����dUޤ��x�`$d�9`~L�|jB_��m���_��7�i����b}��{��0�[��4����E�v��9K�CH�e�7���X�{����ɩa�N��Ȉ�����4
Ve�8I!��$]t�Qiȩ��G�,���4#��%�y�*��,�fu�gP�O�YEr�mg���m`�����u#�7#'ȥ?d�����AtlG��9�h}���spV�7�O�_�s1�/�g(�u����vM5Z��,��s�*?j.1I8�q�\< ������cL"S2�<��LAO�9�o��/�W���w�9`sRmʐ�$��*
u��%T�h0������W�f.A-�zo�b���Mx�e�%�$��_�m@w���
l�>�xk�Ǿ����s��kt
�-w���E�����0=.;�A6y��,��)@UG���Ҁ,��Y�"���"f�:mo�m����h����q�K"�鴿'Re2.����U�$���<�w�(g���o�Z!! ������S	-���X��G��hC�;�T����?[�踮nNO��
D���3���:��#�����V~�.Gi�̛�T�����v&��p�E�	G!��i�W����pHA�u���-^�=�H��h��-��~��	Uc�z�� �
׶*� ���K�[��e�g�b�}z�yMl��<��@
�b'rէ��AX�2b"Tn0Fy�F���$�MLyT&�(roIa%�#�W�����dP4�i�� ��u�n��FN�� �Ð.����ʶs� }�� �������i&u�FVՈ@v_��+���0�󇴶���%т�{\@���M�����T��3���i�o�[�C/F�	S��a3=Eaf��+��H���WD�o�������Nɸ<��e;�P�}U�0�r��X��4��PfTߢ�ʠmc�TY�T�Gb�c���I��NC,�s�����!x�.Cau��3�{�ȳ�md��l5�����f� ��'��|ۯ%A>ɲgR�X+���둥�Am�-�,��;\;��owCY��A����%;	�z��}�׭Su��-�����`&��
�*��p�E+j;��a��ߚp����S�8�!�ጚ�;������F�IG��8�ۚ:+\���=�v���aXE)�^�ok��nBYXS�q�����A����1�tQ���ih���\̓=Q�\L>nm6��>��U���x�B�wew��/��~PF�}���}b����V�Ghd����i
�.:U$ȃJ��@���UsT#���9׷!���`��� ����F������f1��U�l�]�����L}'W5=_���_�
E�m|�S�x�@Е���"Œ�#
o��OƆ?paǁ�u�1�����\f,��zT+���c@��MjjK�_r�t]��w~��31Zd�� ��!'rw�G�B�������(�
T�f�9C�F,v!E��}���=F�4���I�0Jwfy, �H���"���,ǹR�o��b��=�NXy�p�ܩ�r( B�?��#(H����T�ƍ�_�m���y0	�)͔���s�s@4�":$�^hGۙ�'�o��X�zҙ�]ۇ�J�*V²�lt�3�(1�ǜ7�I�LD=��������S���U�`G��xx%ū�q�oa��� 볠t�_)-u��{�X�tۓ���;D�٬�<鍼1z�5���qњ���x�a��C:s��[�1�J����|�8b�&$#��;��CZ�]y1���G<��,H��{%L��# �g�(�ǃ�:T��k(�*�oR)$..��O�eՌ��5�?�A�:�I|��tl#I7�c^���A,aNN�����}��Ю4���J(��= �ݲ'�;�pu�! w'%w����s�� b��]-�JC��U�F#����c�����L��ԛMJX�>�3?f@ׄ�l�y������!��map�U��2���������c5>OS�ڴm(:�����	�EӒt�k�0n62g��mx��@ĴYCﻱ q�`�������X�<���(dN+�lbA�Cr՟���O�6���[1A�v�����y@`���/2q|�`�T�9:��u�Q�3��z|G�Z�����t�1&1��Q=��)f�c�40*��$^��
���Gp���I�5�$��;+)/�p2;פ�.�؊h��ǰ�L�P������#9����N�w�q׾��A)]�a.4�����3��(� �*O��_��9���Y��eN*��p���)*�L����\�$C�A���lˣp.�|�*�@�s�����?��T�:�I�J]��-��C�o9=��/z���������o�m���=,X���ҼX �E=Yd �U���]bo��Z���1ly�X�R�>��?�-	j���rҤ��Ut� a�%ɭ��|��G�N{�:u��*y�|���Ǭ��ߍ������;�D��*�<��(S��s�9�!.a`�w?��-��_��5Ų���6�%F:#��~�WxW�P���v��XY>����bMgE�d��[7��S��9ͧŐELFAE���T�
_d�L �X���J�y��.��*��oC��n�;}�ަ��S�[Yuh�=����~�7\�Z��� �,��.R�����=�{׋*'V�U������	�A��[Ԃ)nM'�O ��?gi��sm�{��p;em�>S|B�j�Xt�z��rϦ�G���3G	�m���[�G���	:�1�V�Ю���ږ a<n�/���AiN�B���Շ�BI5�dF �-E���ĉg�,(뇛f@5��4%������x���V�� ���7����Y��¿�ڪ��V�:V$|�k���MW?��Kik�
ȿNc���s1	�X���Bԍ��MZ��h���~���k�8=�l���e��,��A�{չ�#/��;u:�p`V�v�)��^u��ՙͳ��M�cY�_#/ic�:������c�J�le����-����%o(~�_ޏz �,�Ra������b�9̘�r�dQ��>$w�ڝBQ��{]���P��MK?K�n��a�úo��/�{�4&�x�	�)��uI�L`vǂxf��DP����Wa:Yq���܈��r>�2�ykZ!s5[~���X��LD�����j��B�V�S�1�fF\ь=�3�>�0������P��m�jrY-�{�}�r��}]��"��G��U���:m���Q�f<?s�@O��.�ś��:+�������{k2=n��v'���Q��%����>2��xc!��<6�$������ �:w'L|�/,λ�@����KF�����|	v��U�Z|4s���m�6�s5;�ّ���7_����x짮�֭�[���/��tp��i3���I��y<��{I&c8'���3�Cx��ҧ��1 ��/���7q)dA�ez��|��8c�a)R�.���$��*5|a��G�qA����@��\g��v
5���\N,8�a%X<��k�D=�3;CG���B�Xx��u�ޏ�;���{�e��|��:�T�s�#����na���쵠sn1�L8�ܹ�Yig����9;�ƺ/�K�Q;S�p�"���S���]f�2t�Kd�ҟ�a.zڍ��C�Bf�x;�U9do� ��V�`��}^G���Y⩧6�_M��-��M�U�ʾ9�Y��/P<���W���zyw�_�,s4e�^oLҖ�s��>X��]i}� G>n�¬}It����	_��A�US<�����7���ܽ`l2�	�����1/�vc/>�5�+�^�"jf�|�����1%�����E[u�n�ަ#�T��S��}K��9~! �ܢ>�-����_��:f��}������ CX����N*����l���5�N���,����k��3�N |@�e���ãF_�p7���ž"�n�9�~�'o�N�P'����������������#ga2��Ԍ�;}�a�?��z%@4����6E.AZv��v��fژ}cy��AՃb' Hqȱ{�hz˒�/��H������C*�y	e	%�@�u���
�]y�z���!GeA�銮�ݞ覭^W���F<)=}��w�c��5i�K�< �#�6��#����A���H^��d���s����%�ݹ�n�k��R���]���=�ˤ�`��bn���8�^����*�I@*��])�f[�z1i���6��6��?Z�n.�Cnɭ������(��9�{�մ�)���D�mc���X�D���Hw�7q6���NG�����i5%c�v���LU�rE�rl0�@9(�ug�h�>���{��b���qv������?��!�x�S֦<���l��P��(h\(Hd��s���[$s,��� �9;���f����t�_�|4�~�yr�-�ư��2�U]�ή"ASM=Ď�Q�!���>���������;H?5�l�h�P;h������s�*��U6ζ����Ǡ�����6�/�%.�abk��{�Զ?m�vL2�C����A%��IJ\%�;���$b&�^�zU;��\�2`�p'�E�E�S��$�G�%4�����#=S��)P����~7�=�v�H������ҟ3�.ۿFu�T�Q��lY���q�N!�{�K�^?
�XRo'�$/��!�������$^:��uf}�a�������X����͡Cr�Җ����z��Є������W��=[{�4��2E.oڏ�7�;�wAGq�\�����cJ�����Yl��P�Tʡ��E"i03%-�+d&>�C��Z��8����m��G�÷����+ �)�+��9ⱐ��ovQ �� x��	�O~�(W��`>�ǁ�1.n���e�U������K�n�ES��.a����nT?�S�-d��\ �v�;'fCς܉���{Mޯ�
F�^�,��я(���q1zM؁5{H�nH���wi�&�� }�Ғo=�o��W��� ��46�T�vgC�S�R���{�Y��P��^��KYp	����T��3�Nܠ{q��9_Mc2O˖ۭ�A�¢�|�a��G"/���@�����y'�ڒ7��ۉӪ]=b�T���y�a�����Ӧ�V��yPMz�P�<�����E7a)�;vĩEj����<�����v�ܞ�O{����N2�JW�;�_�(`�,� K�?M�S�� �zK�Ϲi	�>��R�u��S�+?�PjhB���P�q������>�'.�~S��eP	Ɂ�p��俔sj P�@�X,��Fq���ix5`���_�d�c�j� �����*Dح��'�3h3��)�*�7ӡ��#��|���9�A擎�J�5���e�1?F�9���t��q-��3E��^ԉ�m�����RN~�H��300)�2mB^�`ߧ��}�� t�T�������������Z����|�*-�l������ܢ�*Xg��_NA��I��'P��f��UB��&ep0���Yh�o���Խ��Q�c���og�0� �1�4��N?}׬��9��{ �&��B
q����S)�|�qjfF�P�2�^<4E�%c�nD�q��a(���)(|��-�Ѫ"W)?����P1��G�\� q����*m���f+����p�Z�.�qo���ig�IfF	����"�<�gU<�;e7����E�r,�0p�b�Z~�H���&F�)����d�(��[��m|塏�b}����̮fJ ��7N������4�?,c�q��a|�����-�UBVhSRT��\ᗻ�a�P�|��F��l��MwQ�ľz�b-�C]�|D���j*ڟ�DJ��{`�T�A�VC�6�]��8ܴ�Y�����u��q�o��_am���w�՟�Xv��f��߃ �a"��W;Ǖ�jyz����R��ŊI����z�Gtj#:�Y_=2x?އ5�d>���w�)TZ��y^�5@��j]8U1b��Ї���8�7� ��8����w�DsX:���:�؇������!��f�$����OI����DڎW���\/�o~��Y�eT���GiF�m��.1}5��Y@΍z�G�]+�ŀ	�8G=� �Ve\R�4�{��ʣ�p�� ⛪Mͳt�R���l�_��y��j�4�$6��\��������gk�=j���%��K���GB�7��tg�}�"99�3�O�֛���8����_z��E�!�J���Ȝ�TO�"K�J�+��6Y��2>2�	�M���V�$��B1XޛX_�j��}d��,r�o|6�H��hhwS�����&������yZ�T"5�2a�ݷ��`�/�ކ���8WM?6	�ٖݥ���p�'u�%��z̄��8:R1������u����E&����+��C�0G&�:���a���a���^��l�� s�iQm2�1	ɆJ����u嶈K<�����2�~ ����Ģ�{.�m-9W��+B�ǥ���H=�p���-�2�*�G�髧p0�T���� �xCA>m[�B�wz�z�3��Lʎ�E{��mT.en������R����4b(?=p磊]rՒ���e�qJ�,$�1�*&�4B����ҁ]����;&9U�ӪU7�z�Œ�/e�@���2�	��=vI��C �!M?���1�f@��&�X�ML�U5�`��s��7 <R��9�gl��K&.S�L��+RA��8�4O�9��a�=/�5p����˾Ɵ�V�%�\P>�����5A�g�L���yS%v� ���8�z������3��]���.�O$���b.?Q�V:�FD��ؒ�e�	�)��>`X9�˙u�Ϋ�Ru��� �%��]��&_�wH����A��*"Qn.��Q�Y��
��lt9
^(��{���-��.�nG��]�%�u=8ű��;�}rň+\�G��(�tO�6:z"�v�&�e�#-�Hw�l.��Sm�j��]0������M �tZ�X6w���i��6zѪ��v	,���4��9��6"/���z�\(�II�h�C*��t���[7�!��}������.F�0��H���L�ԏ��psk�ȪKK�(]�v�&G�Z�T>>�
��/Y�a�挝�b��?�G(�F�n ;.7���Ȇ�#���s#��Z�%�����隤�g����žF{�M������}7�n���g�$u	l4O�����H]��]�X���U�/:����@u"��3�b��w.��TدY,Ϲq32�ف �� #��/Je��{��#������?ڧ;vJ�Db�
�����X�a(>	���_f.�u�Nde����Ĉ��}�5ّ�A���i�����N�J��(3�����7�I��2 �<Omէ��a@���R4����t�ʢ|� *�����(:��B��ؘ�i����gp �O��Z���ގ���̌�EX��[���ڄXvU��R���~	J��w×���	�v? 1��-���)B��#-�+H�7����蒕C&()��S��cC1!�B���=+�rb)$�b��Nz�n�|YБZI}�6x9�a)H^��$�i$QGPW�&q|Ê�қ�j^k}�7){�Q|�+�/���c<C���oL�B���GU�CD��/�\�o8�&�[ɱ3�������E�6"6�g��[�R.)��y��ϓ`�C/�)�`q%��|a� �q��AW}XM�uz�p�d^��KH����/�D-�f���MJ�nM�p��ޜ�H����QJeꊶI�F'��˒D�,�7_��K;F�m�cym5R�캈�sj�����D?:a��t9Y]���H������G���1��3��W����.�*�a�`�k�1�z�T����=�]-�AfX�[���0�n�v�m�H|���1ټ<������g@���PR-�����J�}.����D ���0t5�O����� &W�	z�%)$)߬\�a����F4儶��S?��~�24S�q�u�k��%��d|�,]~Ot��Y��U���0�^7GC�8d��\a�ZG�K��@J� ��M��D�3B���.�ھW����7ꏔ�5��ǊK؈�Z���y����s�s��8�9r�� D� �:������-'�x�-��?��}X�',l�,5�	q�ź��o�/5�v�a)�%����G)5FiB0"	�<A�·�0Y�4
D}��8��,|n�7l�����x�e��K������4�'E��"C���aVc�>ʁ�VLh��uM�B3�+>�:4Ӯx�<�sX���)M�ʇ0{D;R������E��H�{ϳ^4[%��<7�d=��फ:��d[T��x̀�8�bwt�\����! --�TN�m�;���Xgg��>�̽|�<�?��(EG�y	����C4�:4r����z�����i�,쥝�N�g������X�y�Zb���j� �[���_�Xh&���q�]�Hn��U����@��f�V���̛F�Y}��"$�0��ø��顿 ���g�U�:i܊�l5S%��m3��\4 gw�8��V�+���9k�&�~��]a1�M�9ѫ0�ϔ�eQ�1[ ��]ә:`f�W�P�q��J��(ç�ފ58���18��r|fRTv�����P���z���U��1���sn잻��fJ���eb� �R_s	+>��G�T�l��ھӗ�R�N&'�땐�m÷5/�ZԈ7\��dcbu���.�TAO�~�9D�#���) BlJ�-Q5�w�1�]2�
����oetE{���솟���xm�G��>�w8��F��ʦ��JOf�����`��c�u�aJ��
ÛF�;�+�&5kعR��Rm|��E��<s)��+��-QrV������W+�5��@ε�~Pۿ2��og A��t�x���D�[L<W��c4X�)��H�Xq��4��ǖ�Dc$x�8�9�c< �XP����;|ϴ#ut5�C��|wNկ��ٔz��!��+q�}����!{l�o�n`�qn�<rL��h(��b�w�y!�10#V�Ia�#�]�ɭ��Z7��zmj�_P{ۥY�A@G
=�j�@Q���ܓt��v�����2,I]���^C����/v��"ϯ����&<n/�ʷܛ�=
����@,�2O��*�I#iJ�T��&�R�K��sˤJi��,A\���젱|c�ܷ䚋���h�8KC�w��f���]��lv<��B��NBI)Ϯ1��5&�)/�1��Jb����<(�њ�P�aB�o;ģ���x���\g�?�_�3c���V���G�c]���O��V�
�rZ/�R6(��BV�u�ￊ͈d�?�4�x��AX)��PW�^
h2�ȶ�������v��'���AI����I����;�)��(Ub´s�cө�����>�4��(��|c����<ނ?e$,	l�gT� m���A�4�y�Ο F��SO+'*�ɧYԍ:Ϛ��m��eI��fBoHw?�G_����ŏ�˓��m����N.-"����OgCI�Ə����'rn��)]��u!"�����w��O���c�b�Å �	z�e6|
�"�R6�4i!����ɗ�eTX�,�����l��f�ēþT�[{K.�=ڏ�� ؤ%�K�m����~�P'�5�a�q�5Ck���%�mЇu�
�B����T~�uvV8<�SU�8a���	��tQPY��`$�F>%~���'�5�"S�H)�׉��Z���L�������.���q�ܤ>ﵐQ�����1B���-}��.��ʟ$L̢���)���3ڼ\w�8?	��k��i�i3X��J�M�>8��� ���Z�F"%VbC�Z�\��P�J���
A�s t�L���G�"]�[!n�Z(@pNȍ��x��f��A�s����;����
�'�{Ecۢ�[��Z=5A�?<G��f�FN�� ���Ӡ4��O�eS���_t��b�Kh����l��9���ꭴ��"���&���\D����J��%1��5- ��&��qWՓ�B���[s�m�6T��J��a��A̞����u�r�vdy�c�t���5��H����X����T�y�w�"��0�=����e�~�������+�+$�,;W���� 4�H M�2�J4�ُ�B�?�CT=Dy%��}TFr�S�Ꝁk�r�8"+e��;�Y%��jF�sx�M��7�C�'+DKNy��^mԨ����^>�|/_P�؂���0�[�$���'n���pe8Oe����^��M��R�"|FV-f+߮��Ͻ��А�Y����ƚŰ��#V��p�`�~�~��g��3�9"w�nw'Q�Ug��	n��71�R����U/QB���?o}�[��Q��Ŧ��M��'%��WЦ�ʶ�R�j[ۄ5)6�I�H���%Xr!b�N؛gև�^��Hg �
�u,�!�|S;����1}��	�ypl��	���p�#w�:.�wGNܷhR�m���Ջc^��^c�����v�^�{|;�\p�J�"��0K�?XX�uj� �(�[�z�I��0�r�8��.B�&LN�QO��1K��tƝ^Jm�@���	��J����n��͊�]����F�9'ᲣJ�;�VE��B�rC!l!��לiv�r>	=��\Ͳ� ��_d�}�z4�M�ݡ��G �a���Z?��C�?<��S��	�!7�� ��2VS�o#6�EVHɠ��~��'��ܮ4胩ޭ/�z2���ww��XGR#����E?yOJTq<�J��v��H+eZ���l����|9�	��sAc��b���t����{	F3H�����W��¡7_^��h;��j۔r*�O&�65ZNMlEP	���C���E�c͛�Uy��k:n�
��0|�f�����#��N�צ���jGd\�s2X=�h�!v����pܶ3�Zy��)�+J����B�~���m��K'��ƨ�p86[<�*�%���ϤyVV��F������^�מ<��#�?S��H�1�V&-�ZG�4����	��$+ޗ��1>G��EM@�?�`�������px �������aDCkҰ�Ưv�2�����θ������>��k�Ȩ~d%7<@|�|��-��y����f��Y;}N7�7�s�~�g�6�`�b�i?!�?���i���*b&Zk#�	�1��ȓ���'$.�D[xhI��XT�*�Q��ƸZ����D&l�Y_�^�@�6��|dy�]�o��	j��!��C>l�w%���<gt��|M\�C�#�����x�I�8�{�S
�*�"1���^�6V�zj�	�ڣ8��J�[�F����*2���墱�lϵG���%E�	OJľ�*Q�Ҏ�	�*R7�(�w>8_�Pn8��ꕩ �ֶߘ��Gr4G�������Z2�`~��=��&�]c;�%D�Y}��CErv���g7��)D}:������x0w�N��L%l	���>E���e�VD�a�̟�I�ϋ�0�j��m����T�#�,�<��ӥ)�ZX_�0#ޞ�^���9N%N��!�<���'�0�]"����P��������[X����K���������Z]��<ߙц��_��˳X�4�s팲�)��b�h����~�en73�Q�R\ u��jd���g�A xC��t1Hw̃��+]�#����s���6g�a�!���������m��A�=GF�ʹ����qg������z����]�h��������أy�SO�mL4a ��5�'��fJ��O�`����)�PLu�6�����Ǹ:߮u��U8i/�(5�K<�����4]!β�V����֭x���T- k�h	1�ˤ�d�8o^n���A�:��s�vZ���߻�E�N�±������z~�ؖ��}�{�L�.YI+�sVHb��'�0'/b]p�g$�>zl�/i��߁X� ��΁��uT,��@^7���z��t,���H"���r�a�f�tvsK��5����8�Ք�1�=�L��	����>UC@7�ܳ���L��;�we�k0HJ-�$79���kO���N�Loe�	�!�p�Tv�19����6�81��*z�F�۶E�h3�|Xs��q,.P<kC��h�%������SU�����(���N�7j�5��O��}��C��⮶ZZ8.��4Ҡ%,Y���|{';"��:/��;��K�9<sAu�� ����zL�]EX5CQ�"�M}��`D��Z���h���L�;��9�c+��o64�T[WH�`�'�}Q�S�C�0.E�ve�m/݁q����;M��O��3J:s�wc6ւ�r@@����3��z\)�ʻ]�X�{�G�ORm��ń�����o�;�k����@3�t������*��l��z B �tK���E�� ��4�zW�`t��)���Y�h������ݦ£|#��T����b+x|g�U��� w�k�� |�lJ�ac��8���
��La�E��Wޣ#d�귕�C&ΣE�f�g�˭mV�q@jc��)K��gNlw[�f�u����j��{��Xf�N\�8|A�%�Jp��� ����by�Ih��H~w�W�m�F��G�%�ｔ���E�cX�"���d˵�D)_�h�*�����	e�fJSA�R�%9�÷���羰V3"�~��i��Q�e��E`��x��b��Q���k�������h��z�eZ����D�kk���0��[QnO�q�� �lx�o����d���f8A �`����,�/h�^�D�i�#�1���2�b��-nT��F�t�)zL{��O���Ղ�5O�C��o�%�3�x�1�`�ޣg6+)�'g� �u-�o���o�H�D��Je�cH;���*�IX�ظ�8��0i�Vf��x���E��B�~�K�8�F�i�rh+ߟ��n���ԦH"f1Ĕ�Ae=G��Ӷ� �*��*��ѥ�h�(`��D�\*~�k�gD�{��������͏{'��ag�����Q;��D'���Q$R)C�]g%󨽔I��߱�v*��i�͵���Zr�o����QtH�)+��x=�3k�J0G�U�l�W����C��9|��ke�"rU6��<�Tm�^J3��c����3�`щG�;�(m���9����G��sF����{�t��j�ҧ�� ʇT�E�GaX��ǺDM�v�H� � �+ڌ�]o�NZ�,���y�o�r�&�@����變6jY�nu�S�	\�GpF�}�.<|E�ug�=�����J���U6<��_#]�4I"$�h ���}@��:pܿ�#�w`Y~>����؆y�q���q�����`*����^M'FI	s퀜�U�����fՊ�phee�3NǨӺHz��iI�H��%�`�ƿ&��e�yU�h��E�B��3#�B���v�ki�o�
��g�}>��:�R��X�D(��LN7?b��A>=^i6k�=�ېwv�Y �����.I�S�Tvح�Ѭ��';t��)���<t����f;55��ŋ2��9uY*�&T��*�y��Q�?����H}.�el�I�{"��/��YiJdPH��DD�T�]u��ņ����˷�(e�K.q۴#"��e=����v��U�E�y��n]��-l%MZ"���*��V��$A��W 6Xb*@�v7���-��
�ʻ�٥i�A���>a)����GӮ:!XA"	���P%�8�@�B�V��|��1{ѿ�5�S���$�s�&����Zrjͅ'�������G��r��W*Ǒዎ���&�:��$$�v'��;��&4�S�Z=�<m6O^��%�xV�1�B]��N��d`���`����V��W�J�6g�����13��&5ԕ�'�x�V���6�s7=�G�� H��L"��+������
1y�<�R�ԓq0YP�T���h2n���@x�4^ޢyNG�x&���T+
��V:��ü����������U���oi4�J\�R�/%	ռŌ��Ooo�<Ss�{#��1��	o�������!`锟-��w�����5sf�>%lȊ�
�(!t��a	ёlAB�q�\}�1i�@5�I��T�nA��n�4�npVr~�K ��|]�˹�P���ӈ�)Q#�f����G1��QR��KsE�~�Dɠ���h��BF��y@T�����3�h}���$�����>LL�Fy������yѵCUBq�H�"�TG�v*�`.��h��&�}����@�c�$j�Z3|����rp�c��s��Ĳ����Z�֍�ҥ�Y('.8��Ww�b\�(�i�$�'��J��R�g�]�:#��  /�p#%Hs��olq��.�n�D�J&�cP�� �U�}Q*�U�yG�H��?�E�)�?q�?�k�!���(l���$��}�NѦŀ�� ����s��L=e���p�	䩐�%�U��'fy蝭2�)\bg�=��6���a����v��vC�t�|g�,V��(�R����}��Ѫ��*�`�DB�Y���{���2�r�����R����M�`���;�<.�>�8�Y�O]�iS���d�E�ҁ�ݾ�Z�"��#|���JLa���zq�����9J@�S)0���#˷R��$�7]�YPg�����K���}7���r*�c͂n�}���W&��L{�>�Oh�5ȵ�e\�Fӈ$<г�x�� ��Izzv%�K-�yld�Z �����HM���?>E�x��p���h [����L�泈"y��N�{=�-�{ng��vQW�$��z-�3��č��%ᓮ�ju�+욯P��C�lo���=�r|m5�P�r�q�K1ߦ��O"j&��9�V)�g��5�_�V�ɂ�@��~Ͻ��VY���&�	��ȕ�0��6˨����6U����i�bP�� �	�B�d�4Yq�z��PW|5���K���Q���`��.6����;֧N-B��r�m��G��r�﫡&\��1઻����f�;�s@��1{��p%���]c0!��'/�*�[�dv���e��u��\�Hh,��a�Yy�VZwQ��Q�)��᧔Ѐ� ��䠶¨���>�*(>����C�mvfu��� 
����+�S�)�! 	�YNEoheb$E�
��Ϥ	��\�U��� uD� ��֐+e9��q     �]��͇ ͼ������g�    YZ