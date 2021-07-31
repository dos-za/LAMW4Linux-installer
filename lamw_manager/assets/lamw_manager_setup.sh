#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2250037098"
MD5="3de3d60e619ef07bfd4cafe6ba5f043c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23412"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Sat Jul 31 19:56:01 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����[1] �}��1Dd]����P�t�D�`�+rco�+���(}��P"�/po�	���y:�f��M����V�G7�Vz�DL"�ʵ$5�������jA2�f������2�`q��)K��j��U�\k�?��J��4a�iG�!-Yc#+S�D���#�ϓZA0�<%`q�\��.�Y�}It���6�q^��<ç��YbK�:iQ�z*��? ְDM�Y��f�?W���:gp�VH��@���t�����b��E]Y!����fg��g��)��:��_Q��Ƽ�S�'=���I�v-��V�b@k�������l�A�<
/f:�p �Fh��ʰA�������SPS+!"��o.�����N:w�
�	P��>�.�Ml]m`��f������QL�^uj��%��oq	,���[��3P��*z��(k��K�]x�@���B�U�Y)-�k���V�ƀ\�Y1.E�p,7�u�������(T㢰��^�䑾O�x���+|����5��G|�D�l���l�#/P�@�i/�J?�n&�߭��V!�����{���=sW�(�{
�W&��"�\Ϫ�Y��XZ��Ǣ��
�<b���0�jI�V{�Y��l:�8}�� ^uy9���S���A2�^z�Af�5�xL]��"�p݂M~y�p���	��8��6Ԇ!�Af��B=bbm���P�3���8���E���zbV�<�����7$��a�S�g �TX�X=�\���	?�1��:���|���%7�C-�PqE��6����Ֆ�8u���D�W��r ��ƹ�G2>ПM�r�vPQSħ��V
�1�a���r���]d��#w7Mf��
h1J��G��0d�#���S\l:~����'-u0��$!an�z� H��޽xՒ�t�)\�/�034�՝2kd]¦Gf?Īzyw��:z����k���/?[&Mc*���<��%�$�0����&� L{�|e�~QZ���B66ǚQ��<:\V_���mT����d`���Bp�����-�����c̓[�		
(���PR��'��Aը�5a>�VϾ5}��!肁�جo.)BU��=){�1�>{Rw�w?����8>�l�*>}4�t�Fj`��&/�	� ��rd��r��Bk��������=f�:�4!sK�!3�,�Z�co2����>5�Gk����~�5��dz�7��]�<�������L�p�m���؋ٻw�=¤<~^�V\��.��S׵�͚Q��Hln��L���?^Śt��9��"x�c�����)��'�$�k���,?�=�XK]M�����7>�;%�+y4�_��c}��z[�>q�k!�sn�_����P�`T��MC�ʡ�PX,!ת�K���e��L��1�3�{�@!���Zz6	/���x��l�=����Z	��`�˚�mx�L�ű����)ބ�f��3p�2{�t�)`v���G�@BP�����.��I���Z��1�=���'6��I�.�ϛX�>�i|��f�(��;�
�.'��M=��[�glZ��$�
S|QGC#�J��e˾�b%�J�d���4�>M��٫���b�����!�������b�W�A�Ă5 m.�ϙcS>� ���B��S���T�3��>^a8<q���D�7���AN�|�����ܤ�8_��4�TK�"��^,��G����h3!�D7�� �{V�6CVcfƼ��2�u A�Hs�8A�Pa (�7@V�ߨ^�jkŬ��@��~� ��u�W��T�i�Ё�	�B ���"��iwQS��*D@lU�~)�ʏj��Q9!W/UU]�`������m��t;������Yq�V*���LD	�L�c�1J��/����3^\1�w��`��GߨV�!���'T1o7�K�i���Z�K-�{%w{�v��H�H���.^W�8�AGb��# �[XV)�'�3��O��u�/�|�Q�����<�1�wG�_d��.<�b�9P#��T���v��<�7�0nM�l&>p�u��t�ȸPcv��yt�3�P���t�J�|�״�p꼋�0��1D�Ĵ6�s���XxQ��\"v�;H�����[���\��˔Y}�EK�QaI=�o��M7�~t_��G���u��J�͝E�������orq�yP��3LP`Xb�|���_!X��Mc�hV�o��V�ª�F
��s���@�6_0�-҇��L�1��1����u2V�� 4�C�7�Ia{�!���1��H��c,Ɖ�w&���S���M���T�4!��C��8*S�,�Pf��U}���B�J�Ѯ������]U�B�3����>2*r �|�벰!�G���HT���# �ø�s�{�R�'.X������pu|���ի5Y�*���DM��]�r�;kҞȪ:;�F&�+ň���K�vr$�Dv���$X,��9����%˻��l.�?'j������g6� ���3���U�Q�kS���F�5�)��=c�堹#�Nd���"�D�k�)��ir��)f����o��cհtI>_�Uq"���I�u������16�:��d�O���Oc��v"kO�K��cH��:b�Ta�`��<�n��x�> ���K���sHB�a�l��N�N��G>w�Ѻ��ȉ�|pe�U=?�/�Opwg�x�6��o�R/�P0fb�ɥ��mɍ���,��(��?^�d�L^8B�>eB[��3K3J��N��6I�ZԴ"��p���P��q��a��.����"���y��s�=�b�:��%0�^�U?(#��*��vɐ�Ӕ��ҔE�/�5��Z*�Eg�ȷ��Gh2����&g t�Ѻ�n��#1���-v�����4s5�F�QN���()�n%�>X�0�n�� 9{��
��v#F\�t���hp�ӅtR��E����`�g�t�QD/}���gmˢj�1�0��OO�@8��HƟnG��&��:̊��U\l�O;��t"G{X�&��1�p/��C�N�7	���������eÙz�����G�`�5�Ν��A� ��vW:�"#qǘ�ϳ!r!R2q�%ap5'��O	5e�2�v�
��Oem����m�ǏMkx��.���1v�\v�K�dց�*�B�,�9J�k�G� Q��s���ܘ�z��j��44����۶�#�t�R'���s^�{|�8ը�[�_����P��&��pc@ԣ���_��8���p]H�G�[�<\"�9�R�n��4�;Jm麏 x�x>��n� p�gɲ֊�t}A��虘�!�p�*��!ob���O<l�E��Yq3�G	/�s1�����W+�&��$��9| ��B
Y*�ʒ�U��:��r/���:���bHd�]����أH&H4ue�,���2� �	��	�9�Jq�ػ��bQfa��L�D'��X�)q�bZ������Ebw��2l����c�6�4�d[M�E�D��ņ��_*�}FsŹP�i���-�P6���j�~���@��� �!���[��wpJ8�r6ұ���N�H�|������/t�:<�����sЃ���&�h+s���4!�7���2�8��[��ʠ
�v tP^9B%/k�%@\�n5��`*0�:���B�B���n�;�$?�x�,Zj������]b��.��si2�vX��X�Q���o80hK�)�`��vYq�.����WVޤ���VCn^2��1U)yA
���±��������ڏD����	�3;0|N����~�߀Z(�a�M�U�ߊe�Br�Ԅ�/\�q�%y;Eĺ��*#�`�H�� �"�hMƽI��ʟ��.�ka�w-H=��MUAu[<���h�yI�$
��8��U^�N �~�D�p��	zk��Î��\����B�z*m`O#E=���K$^D$o<��i����L�<PRq�A�n���+})-Fd5T�ϥl:	=�����D.32�c��l�I)��|BC*�1���o?b�j���%���G5
���Ah�Ä��l� Y�r+b��7#�Z�v&\m��|W���PfⅫ��]�� �1֏�ݲ8!_���34E)N� t���y��.\wQ�cԖ&�#��I���e�G%� �'�J�fT4{���s�Ň?�Z|ܬ����@�A�2����:<=��A��?4�}��l]��]��� .TD<uX�#fM����?űpù���m�c=��T��_ȆMiF!���Ta\���j�ϵ�ʿģ�)J���xkۙ���T�g1���}�1佛yަ�6B�֬G�_�{6�ةx�5R�YƋK���^W�V*�����iV>*k1Kck�ȿ/�]���B̕P�{��o��m��ԿB�sv�f�E��bgsҬ�1ET��g��X�(�,v�	�L�8v��J���Gm�Sɤs���ŗ\�hx��{߱߁Y���V�;��ڻS����ڮ��D3Nk� ^Rt\�HM�P�$b/�eo���W�r�O>S����T��w�������I!}ѨΑ/U9s��.�8`肄~A:��.�)5�|+���[/AT�Љ36XW��g�ل�zg"�S��>� ��k�g�L��-S�n��i�� 9"���E�3��BT�:ۓ�$��`��Ԝ�WV�Q�93��h�HC�e=t�b���6{��hO1��n�ڢ֣˷�^��b]R�O�!��~�}�h�������2g,�p(�o�A��I%{
]�f���m����T��6�x�y�PS&d;Q������u�!Fc� &L]���HHQ].v`�������iܑ3�D�%��鋚�:���A��.�~��7�YT��(,Z��t�q��{}m(9��qYD�g|P�`�"w.R���d_J�T��e4X�Z��ta=R�e�L������$���1n�E�5Q��@ӳ�/O�D0Y��ET��������Ɠ�磠�gф�,�xw���>vҳ6�$��t2���7�[�nAcK��w�O�9Z�E������d�A��B�䃃���F5���+�^�K�yDx�J��5r����5�Bq��K	������2�+��:�+%��,8��U���ol�*1���b9_n���s"��q���K`&�z7-��ˁ�3�<nR���Ч9>.�0�+=Q8-�4�80����'V Дi�'���+��O�kc��qc���Y�Pi�u➥P�X�<��b�meCc�뉽�IzөF,�o�'��I��T.3��1���C U	3�!�j6� �%�w����Ln��R7N%����⺣�b.��d��ϧn�zd�s����2N�a'�;R��>����^\,��l�J����T�wo��X���@z��3 �<{i��dĮ���t$��@"���e�g�=�	���γ[RK������Zۣ��Y�����q�����qFA�� LY� ���{�>�v�;�h�Ź��<s�ڨ�̑�S��*4����*���o[�ƠۊE������E%~|��45$p�顼���{���p���cE��T���0��լ��e����rvM��E4B��Vq��O7*l��\-�Y��d�3ÅgR�j������l}j����^Zg���=[��2U�}bH�I���6c�f{0���Y��R|��ԟ�Y~s���q��D*�t������I�Y���o�n�+{D�9�m���b:Wk0D�/�l��Kf��$�[����ɤD������Hq��Jy����~+��WV���)VT��Ȅe�=�]YA�@W���g�q���2�")61��V��z��Q*�*�"A�Y�I2N8Lnțl��/6�N*�����=�2;:�0�=�o;(����k��a���$�i���R���x�������/�J��wO��G#���̎RV�_ ��-?lV�p=o���\��WR#��jq�&��Hk�h����;s���i9�PQ鼈��`�͘ 0jۘ��m7�|�����hKĕ¬�'�n���N
@U�s�Z��!�c�ן<�4��C>�ߣ8�1�X����>h@���&�ӑ!���_v���䪼S��D�����2����sy�5q�?��Y���jȊ��a܊��P�{G$�v�Ms@�'��ɻЂṴC�Jņj�Ć6[����7?�o���� �~�b�����L�<�#0�&=J��p�7I;�TuyǵW��ՄS6���T1�ȽiJKe�H����_d5^:�4�xU�q��+ aIR8��$��T�Y@�Š/U-��/���ȟ3��(m���k�S1cF��K�=ّ���[�����9���k���mq��M7��%mY�º��ɖr/��;�}ǫ5�/����\D��(���檪QŹ�[ӂ��C5������gf?1�Uŋ3�&�]՛Ҝu\w����v�z�re�j6�����Sҭ3��W>�J����Y*v:&��!�ʷ-v�89���]��$�0E� 553�.� �f.���;ŏ>�P)�S���fJi<#m �y|�1�+���D�5��������Ӧ�`���^��Z�� ⠺��ęp�R��դ�`Z�!mk� ���@��E}�9ec,5(��Z�ť'��	�٣��'d�5� �D��}V�+XϦ�5 �л��k�.�[�5����	��(�~�`�'/�����gg8Kp�v�\��3m�ԏ��I!���`�с��9ۄ����61���H�"͢����a�C[� �A�� ������4ʎk#�+�������k���Cp':N�|�-�8�U<�=��j(� J������m��.Y�Mq&@���x�e21�zx�}��/�A��OX�!	{O<_�����g���$��#b�N�"*���UC�p5���{i�KJ�7��m��t��9r�Q�NLƹ)��i�$���Aw4ݱ�?1Uo5�b�0��m�A.%P�N���3;���0X��:�0�ƞ�Dc��K���v�Q:u�#{�8�a'�"x0�4UM�KY�GZ�i �}�Q��=�d�sN� bhX�T�d�E��������w��ۼ���祖�$���g2�����=f�������O�}{�8gCI5�LK�60���?���K�1�ȕ��Y���ˈL��r
����]�<�4�斝��k���y�F x�$��8�f��F�g�S�n,ܣ�7�Q@�n?�Qh��X��t���E��}ʂ������+IX�`C\ft�P�Ƌ�(��с�֟��r�D��]�TQF󄨽�G���_`�'.��&�(�{5w>���F�!g:e��|Q�����Zs�p����9�+�ܶ���N�E��l��+�@vi�m�z��X�@�y�a/�Ϥ�5�;����)�Zdq�&��*�iw���|ha�����c�lAk�y4��X$�ghD��| %z������W���Z��U,�D�+�1cC�l.,%�T\vuE�]�<�B<��P�N����e;�U��ݤ��>���3۹�����ǻ��"(�`��i��fu���B��+��<���s!B��MY�����T�d4�4���V��:��6����#��!79���74���,T���-�����$z��Z�mUg�#6P�b��{k2o�h���
�0qS��	�o��\��'JI�@�ZR�9� R8�Z�����bi?i����?�᫗E�����2�mס
R^,�!Ȍ���#xzY?�;w���W	�&�4�l]3�)F]�����j��>�/�X8�luGz��C�J:���l_�Ӱv�!(PsɄ'�7-���nL{%yx'%15	y��ɷ<�<�O���'w�d�e�~<��(�E|LDK�k.�T��T���}� ٔ����V�š�`y�d6;�8&�BQapXܒ�Ry�?��+E�σ�qYfY�K� F�-�����'�f>���@�N�;C*��ms�(hm9iR:��� �L�70b����kf+���y���vK�z�;���+Lm���c.��WF�'S(t��.�>w����A��w[��Elr��Q�s��zO�;�*�,ΪΤ��K5� F�����t���oN� �����W��J�	��ү���a�0U�^��D��s�Ng"�ri�ztW�vrD�=8(8�����Jݙf��n]�KT�SV�[Q������8��ĉx�~�ٸ& ���Y�����7)�^V��'#��F��$wm[
���y����Ys/ۃ7+���a/z&�#}�� >��Qc�%�e [{K�� N�kϗm�>䘇������޹G��*ۏ!_�:v�c���v<��g��\�R4S��j3���e�7��h�3�En>�M�U��ל���B��fM�C����(����w(z�ǁ��$%}�`�4�(��R��]��d�����#d	?�i����D"�k
*?�G��I�L�c����s8
c��-��"���\~-o���e�y��2%7���QI?(R8$`��Ί�&�OX{}����2n�_�dS��u�٠-���Ƈ�IO��(��{Ug��ڜ�#�;���U�0D��K�N��l

���/�~�o��><��X�=�%�93|^H�7i����+�ps�q�����ʘ����Q��XrE�&�0�>f3�2�<�k����#+r�����P]�mK�"�G��NSN�,������u�L&��1�d���Lb��SW�c�L��)��)C6y��A�P�5���Ju#��P��R��(�T�q��_�\ǠM�v�����fX)AU���Ahfz���Y4w�UYC��oz& ���L�.9F���X��W����q��Yӭ�Г��&�5
R:+&���6&��ܜ[�Co���̏� �V,qYI=�[�KT�o,Y����ބ��ʹe�_^���� ��D	\N�b� |��2�,��*М�"7�����evz����I'۲��$mI��GMʺ�L�A�h�����=e���ƫ ���v���_U"�Bo���L�6!�sA���}I�x$�����v=)�W�9�H֬\��8�:���Ry�1V�ɓv(FC��S����y�
x�r���w �f	e�ɞ޴`����h�fA>MV���G(�᭒l7��Q���b�\��5]��vQ#X7=m=0���s�y���J`�n�!k��Je̤_i��n|�;�� \����h�Ȅa43B$��0�3q��m� �a�h�T�i�������|�@x�	
b�1��-d�7� y'5���#ϨN�{�Ď�2�����Pq˃�>�8�����wM�m�B����xF(4J�����B#�0#�zn���;�Y�)\��� ���|E$��%�^������}�.=f��y]�>O�'�yn�ZR��]3�z�L� j;4[%;	��0.��2
�C)�c��B�1���"�d��|#h���}I�� �%�>��	�}	2.��9MՔ�
�z�Lt�񥚏��
���َ��2�*ǒS�(s��C#��t�OVԲ��y���m6�1b��SD aҖ�.�i�[i��n�JR�Q�{�4q��������Z���X-_���6cz�ʦZ�8(c�G��YdY�ċ�q�tDK����B�dG�kJD���kW%k0��*��C3G\�!��9��}�WǞ,��c�Ŧ��� �8@JƱ���>��z����J����L5n��-M1��@�t����=~��6�������7L��G���L&JD:f�F�~���F9G�fp�))���#�B#N&���,PK.�C(ͥ�0g$f�`�O�=>����4�'���~��%�[Р ������Oc�ʏ�������q
	q֬�%$R���S8�P�:P�/*|U��,w�b� (8�ى�x?Y�iVe�܉3m|�x��)Tņ�#Z�$�z_w�#�u`b��,+�:h#��<nn����jXsO?�6-�e`q��W�uJ�cպ������9M�F*�`��wb
��Z��>Y�&�O;==BҮٖ{���F����8X���<�n؋b?�=3����ud�p��N��%��&�F��~��� �{=�����8v�R�8���:h��\����+L����%ѡR>Ʒ�����'��-q��R�x�6��#�i�����O�+}�?��-��.B~���R��\�{S��Q��rs1������,+gr��-��߮�b;GC���xk��N�h*��(K�4����Ȇ}/ڼ���l�����NE��1}u��qFӝA���٬iF�x(�\��}��m,�:�^�#Ճ�'wY��O�(�KLp�c�:ս�S�EdN�Bv�i5��sKD����k�����ujy
g�~X0-�ae���&�w	�Z�h�n����Ќ�/=����;K��%*��Wg�\�������NO3F�5"Kft�pW��4�4����7f������Swp����ó��|OM2�p��+C�(�>�m�S��W�P��~���v=�	�3��J�:i���(#��Q7���zCGE�����|3���u�h �~U��"Ҕ{��,AI��~	C��k;G�pD0D�®��[�Ϙ=�w#��Z�Z���h�Y����\�N�/Ś�i�>1�ċ5��ø�k0�6,n#?/V���^-�$����o�|��j�d~���8��d�,�k�g/P�%�Q�}����[i�l���g���sŗo�����s�_	�c��-�2��
�8�.ck �Bq��o�|MFiY,�9J�E�يr�4OD�Ntط���U�����Y�E��%9ÿ�>�ǗJm1}'Y=<��{�Ą�F��ҷlY�-�cޣ�p�H�_�4�˯��,Q-�m���j�� R��W�G��� �_���f��rʱ�5RW�Q"@��9�{`��/ A��j���b�a���CE5Gc@�����?�τ��l�H�tBľ1���x�3hSV�ֱ&M��o޸_���/�b`��46�M���m�r�F#��M��#�֨�Y�𩠭i�, fG�X�Q�͋o{3�r�-���s>d�_pV <0n.J�x��"vn����!�ZT^�_�fNIN$K�������'�~����dB����y����G5)�����E�7���o�3*������I]d�0�pm���\H�M�*Q"ڑ�B�U�UT��xd#f[0N_�(!W�Q%��ţ�K0Q�{��zn\��a�T����ۀkFi�2�ZPp����1_O�Ȫt��D�!�0�i����N�#,6j_L��f^*�
'a��bz���c��]Gڕ�7AZ�#�Uvl������ǘ.��o \�ɿ��zn|��I�����a?86�n�ṷ�3 ��Vl���|ի%Mt�k'o{V�ga
��)��G�b�,�O���z�[ >=���3������U
N� �Í�n%��֡x��q�":Y�����&��z�����33�R�u�{��A�p�����qo[��[Ɔ��`3J�U������}|��~O4N���.&�ݓ�fvkZ˶jG���|��QM��RA� }r��$�ۅO�Zh���6��O�u�G�0�ډu�T��ʝ��GJ-r��x�2����[�a���{Ox6���䯒��Wpl0��X�b����
)9v�Dm��S�k�F�t�ΥO�j[���ս�G��M�diC6ЅΤ����OH�d.t`�T?0�N+���X��) �j���H�%Q�e�����>����k�6/��RF�Κ<�Ŏ�����@ѷz��/���>��{��	��������)�<^-�
� EK��vW�u�	����сZ\�"#���뼛)�|S|7h�j��S!9�~k�w1!�<��z����R�484���寊1�]g�:@|�w�䋝m޵�z�p�vB���I���y��P�a����૨L��B�o�PȺ}Yy�a���	�gƴ �cK��Ӎ�a$��`x�@|ǡ���s�ϴ�4F��t9���� ��ţ!�i��v�p`�Z�C�������~38<��r�vo�<Ia�{�8��mFD�����/�pB�a<AE`����;j���	ǆ�
�eZ֨v��C.8Ab�W�o3��2��Z����N��7��&Lxm/N[��*M(���a�
g�����'��<c�"��zcCe����F��U�N�M@w ������lB��ӡ9�nS��U�ϜܸJ[��c�Ыĉ�+pI��Ņ�օ�Tw����1X�8\Ie� ����~���cn+��GX�����y-`i�Yǈs���)��B:k�
�}_&�O�6��ּ���=�w�vY��yW}6Xr_�9s�!E�"K��ޑM}���^z�k�ƯD����ӽw?TV0��@�1����1�'(v�4�F��e%B�H�0�\���!� �'^!B���f7c�>�F��Nc��3,�'�RJS<�S&=�<B+�*Q	24ǰ'R��2��^*��F>������� �D��?��qNhaD�nc*t��	<<'��1FU��Vh$<�dQ k���RlsI��T&~;�\�1���Qq�eО;��>Vޥa�N�n�}�׍�k���ǸW!�ǚ��S��ĄJ�%k?�p�G�F�A�Ё5��|���&��'�� ?��A`�-�+��
ϒ��䎳���j�)mRU�*�}Q	���@)�߁�z,����C��{5:��z� ֚��)�,����X'�7��<���;�%e�����w��X���9r�����<!B�ND�C\61!���j"8���RX��=��K�ʐ��S��5r{�C�\���u�+���
�q-�/�&�SSK�Y*��9S��P�쎮o�vg<q����jb�PcM��愉*��Ԡ󾺚uGȄ�+�L��D4n����|xLAy��)�̱Ou��[�x+��̰���Q����g�3_�M�[54d���㯰<��	���޴&�chg���%�R�|L�u�(&�&-';G`y�pE�I�n�j�
C;&�YоLd�����'o�N�>�x�2�%d_����(ٝ�|�u�X���~�2L�o����ჯ��y6��jZ��#����-^*����ǵ��4�����PT
i�2i���k�(t��%��v1 � >�k�o}w�P(�/�#5/�	b�Q���p�H�W|c�Q��a>���,M��Ǵ� ���̶{"�m��\��Kt ���U�I�w)Y����=�3:��1���旹� ��߷0��V'tB�7�^��w���8TM��r( ��;����W y�y ��R�T���B;9M@�iq	��_���2�F�!��(l�0Y_�m	6���Q�k>���c��[���`����-����"��BH#9�8�T��.��I|)�&	����~{�&�:�YQ��~i¿rv�Ϩ���ˍ����i:Doѯ9� ���v�;
!C��X�Pg��		\���NܯK��#02Ɂʟ)�Q��?P��z� �����EM�E�s8��F!�{َ�F�(ˮ��UTV���M+��h?r�k/�c����Vק"zx���V뼞��k�k�c�1�dZ
$l�i&�hw-��Kf�t�	Y$I��
6v	I�K�=.��$@�%�����0㑴���s��</C��:��z�A`��ߑ�ߛ.ն�BF��?�P�nc@���m���zf�%kdcE��e�W��/����ge�*j���U�Q�@$l�f�R=7~4F����jg;: f���{Nn���Zl�W%�lnۼJ��B(��E�ָ���۾ZO���2g/!$��I���Fԯ�by��W�.ǡ1��9E��G�͓93�7���^`�'~�G�c�-��
��N�@d�}�Lr��K�o��k>��@�q)����-�Z�p����������n�_|��-�I���0ܛ��e$��B�}[�Ȟ-T��W�2;�.�Dh@�տf�r3	�O�VS�cع�f��1d$��-�X׬�?�ȘJĈ�Q�T�3eQ��-�)Ur+9����..E�:�ΘC]Gqͣ�k��*Sjo���0󱆇��N6Ғ����p�z�4Y�I`���<_����ы�(����D$��2r�'��Ȑ$�&PFg%�,�{�OU�p�l�-�,ʥ�i�)`�{=Lx�=�[�耈���XB��h���z��*g�\C�ki��HU}<}�@h�����^=�y���׼u�s�}�gv�o�P8���!�&3,ø�$�I^�4]<hR\Z�Gm�T�+��买f�����R��VH�.����M��jW)s��i���箫�x{�1<�]��狀|CmL���%�S>����(
:O��Ɉ��_~�7�,��~�<��:)SR'#�H�$�<;��s�.�L��)�;򱩵�p.Q!H��Q�,؟�I0����qw�^��o����~���ejDUJz����m���I,�0��q��J�򥠈q�G�PI(�je�?� ��5XU}~���zV�;<�N�:c�K!����8\ۢ���L����pB��ke�WWzYvF��e��է��X�Ey��[���ȢXhW<��p�~SZA�ь��*`QL��=����1%}��;c��sy]I�VO�\R�g�{&{VՑ:�+�mi����G�`y�S�Ep\���!ŋL(�s���j��hk4-��(i�������9���r]�2���&&2{��J;��9]�.ʘzv��;|B(+�\M��a0�+_���Zb�f����um��*���_"*�vz��q�a'"n�����51^�K����u���T�.�6o^���V���������=�#*!��_��A�$�Ҵ��&��e|�Y鶸�i�}w��a�V������}I��ؼa���5Q��9$64�5����D�:�t$�̲��P��{�^(0[U�oH��ZD�s�a�p��M�)4 Ǹ2���/��=FЄp�kFE+�(���FL��b��Lb#�U8au��'Pޟ�ˉg���H� �]�i�6�m9tJ��uR0C\p�2G��`Aմ�&��f���E-��L4Ǐ�s��]F{�m������,�'���v4OL�c%,d{;Ng�'w�Ǵ�wy���9+�.Z2 ߶7��d�a�L�����zX���)H�Kf� v|HY-�c��~��ȥ�Y�^���t�u̾�Y��	��0�H���>�x0��4]����K�d�Rxw�K�����:�T$z{�Y��H�Ne�N詭������eQ���b13B�:��j��G��zt_�A�Q�v�ۖ������wV��@�K�*������6�6ٓ$<�>r��E���3�VqW����d�R�m<�)�6�I�Ԇ���|���q��PA/�؟�z4ԟpQm4���$!rZ �2�fјa`��~
�G��+]�,+)�`��4ʳ�i���L�^k���ܾ3)b?dx��T	�mN ����;�Vg�EӅ!!�v�ot��|�z���v׊����!/s����$�)�:8��"1�g�6����.Ox<�5	*�y�����G�g�*	gc��k�ݸ����V0����}��f�0:m��7݀����<ɮ!����\�?�_��8���p�g5_6p���~�}������ �E��=-&��{	8h�3�0f���T�&Mή�D� �Gj�ĭ�g.�l�L�2���x�n1�b�B�
����t��''��WD�������e5���c !+��Y�Evv�Y�&����I������ܮ���aK�x�;���gGjjL�}��z|��9]W��9��ɌdM�1����o�ցĊ=N�'�0��[��wۗ��"��)�b�O�w�0���1�Z6� �߫��$%"*���s����9�����}H��OS~!���YI�lC/��'����L�n�@X�'sa|�\�4:��s�Rs����?�D.]wf��~1,�	G�+`��~��L �I:�;:_Z[��MN�4�r�������)�+0���."Ƣr�ū��։�gPu��e��w`)a�^���ʥ�܁�U����r��m8����t��""�%ϥEP�EK��}���|}!J��U-+e[�Q�H<�ƻ��u�����;k$[u-車��"EZ̧�4_��{C6����)|��NÝu|{��=�[��蛤�uM@Iu��"���50�tIU㿴;���g	��[��+5����Y��X{���!%�ax��i(ap��!+i8���]�"ssT�l���C��;�=�����ⵒGiȰj��wnet����U��22A����k-$�M����W�	h������>�q�*�\�� �|ћ����@qs*�v�t�����!�\�t_|8wh�$�A��K��TKM�:��=n��t�S̩:q<"�
{y��Sj�s.��$8l8հ��q���W�Fm<���{h�L���Dڌ��y�*��%̒v1�|��#��������*��������_-��5�u�\���Gc��i#�2�)��c3�_���^����J�6�-ǒ��*��Z3ȇwX}�Å��%��V��4Sl)��=ֈ���WĶWK��4SM(���}���~�������y�ܗ�,:�a����x�Qs��˗G��
�Oع�.X����>��a{�����GK��܋p&-�g~$a�J� �6M�+o%S�*[J�C�A�&f�!=�@zSM�v,@��7m���s^��=��!�r��l���>�D���<����^I�Vھ9/���bR	������Vt������ͨ0�m���n�c������Ke�j�V@��rx�
A��!b~�k�N����X�Y��L�2������P6q<Bs���2[�΍��q��#���b~�i����?�b��!j���-�6p�2Y4L�$�1WMH���~��4�vq�Q�:��z�|xg1�7�@��am�P��˥��t߰}ģ?2�c��Dp%y�x.�ݞ��K`�.b�U�D��̮UԐ���}j��#ȑƝ�>��ŇꇛE�c�r��8ZAS�f\��ߍq���QOAO�u~�Ry�u���1�bא�������8X��=�y������Dz�]뀇�Af��ޕ���R��h���wF�ɖ��Y���~A@���#=P�ճ��tNS��(K��E�T����v|O�8����
Xs��R�x����gW�k��:�l.�q���8<O-*��~<�����\�%_�-.�@W�5��ex�D4�N9<�
��}��OB��_�.��U�ݮ;6�i���Ӻ`6� S��OfBˡ��Yeg�sk�~8rL�@EGC̍4��D��eg�n�j��!
qP�f��M�vb#�F�A�`�M�	+D�N�@�ѻ�s�����f�����P���/z�g�X*>����񞖴p�о=�C�Cl]�7��쉏�!��E��Y��+>���b��i�-�뇈��2����H�O�v`��Z{V���d_�ƭYu��l���+�z�8�m|\5�c�f�͹��%���eC��Ɵ�(-]�A,&�@�ʒ��r#����
I��Q���Q�CY�SQ��v����r��u�T��}25�J�o��1�X�܀ed�,k�iY�ͧa��Jb��M�0�By8�����;<��OՓc� c1�߅D0��X����.~��xQL��v�\iÚ��Cl����x�I�=�".��|�x�$�ۆ旸������D���P�3o���5P2du)��E���ġ��'M��C���DU���`5JH�4�梉��+c�F��>3"�
?+n���@�܊�����(�zAjq�2 ��!mO�|�n�s���nR��8�Kd�%�o�5Q��)�ZЧ����� ���;1	�j:�s�<��RR����k�����1������V��9-H�j8S����������V�*жW|*�������E�d�Ƨl�����|�T���n.C�#�C��@5����̈^h���'����b��&2������btz4���b�J�qY�
�`c䧤^&k��~�uK��g\���r֡T�B��Yc�h=�aD����װ�X�_���*���,�*����*�ȴ���"|./H�+��zW2AD�piDm F�>[��Va�q[��	tZu�NP�}���@y�Wѿ�j�'�J.�jD9��TI�9b�G�^Bg'����x7�y��k��f��|�_��1҈� z<=m�!Ԫ���c͛�A�<��<6I�4�2g�a}oPg=�� �JSS<�����P�p�yiS<�h�iǆf-��z�� ��������l���Zt(��"��-�{!�s(�
aL,��B�^�d8�0
ęK�H���l�n=�,�]Sd����9��^�t���P(qg0*-�C|@(茳3gA N���0��4Y�(˺�Y_�ɘ�T��:4����O1��[�״�ܶW�}�E@�~p�<ӿV}����LӾH���Ԛ\|�q��'B�=w7�a6 B5��.p�]�߇���q����:� �7��4�1��l)�D�h֯���z1��|+�5a�@�#[��fj�G��^����K��)<������j�'�^��zT���]��	��Di��O{n  ��1��]�Q
A�2��ܣž�fW�"�� �l���S�m���1]�:1�쪭O�z�ܕY�OY������6���X�'B��e;^W��~)��FV�S�*R��<;�q�}[����� ������Ĥ�Ԧ�-�TB�v�e����m�Q��T�˴"�����掠�`E�'w%�+ࡲ��r<�.���?� �����*`ʥ�s����Tg�1��R�(����hX���<j��]���6�yu�.*N� B�_��M_��]�%k�8T�L��m�|��9̶���h�k_'���G���~��]w�D�Df���α��o�ҳ� �񜓗,�����/�t��"�(4p�b��<�G͟��h�%lr>��,7�ʸb5n�r����x������Ǎ��a�_�� a�EeΆ�Y��BSUEnrZ����X�ť�L����I�iͣ�I	�Q����|� ;O�"x¦���m����¯��ތ�e���&{k%�P�&��x� !�4	iY*[DV"�L��R|�Y�8�'����,`5��a�J���\9֫<�c�`��֎��̛�r�b�4���8��o9	s�z�qAqo�h�oŽ1��Q �����P_�u��H��M��3��1�h�D�s:��@��$���5_�eC�����Ga�K�18���N�T $Z0r��F��10$b�y� �6�&.��GN>�����:�?��+�"b��g�[	��Z^m�]~����}u^���#o�:h�'�f�;�Ԅ֡s|&^�����ϋ��%��*�#�_��y�Fv\��}���"�eL�EoM��✫�n�FA��U���i�+:4;ͮ3v����-�n�^�%Z|��^L9�@;I@5�z��A����È8��7����L|�5"�1��'��c*(qJT�J`�����J]�/��m+Z��	a�N�5J������:�v#f��NW�9��6�ת3$���uJ�%/��bc�Ъn~,���5��׮f��t�"zL:A+�#�rN�:�@�+�;��)��rg);h�r^/��'zv�kX�J;�?��V$����՛�Ӡ;��s��'���m�#�ծ����#��SP�%�Gz���s0.Tj_j'P����'�P�k`�+A���r� E!C�};��ܲv�XJƮ�6�`��8�E����<���q��Ɖ\i�g`�\4kɘfK�s�b��N���+�zG�h{ۈM��i���WC(ɡ��JTx�>���F���$�za��T �
�6Xq�w������.>�<����c���y��)�e褹�-G��[?cz�Zo�<��L�FH(��'���׶\(@�3��.ݛ�����4��M\?eCN�d�,��[�"bP����^�q�qKG��W�ŝ$����>��6n�D�St[��~n��}��eiW�XʄW��8$"�js����>�m;;����� /�ze�(.x���#?:{�d��M0Q��%�a]!�|,���ުh�>�K/e�ќ+ο.����f�b�dG�$�g� �\����ۙ�!>�eu����T;9R����/r'��y��b�F^3f��%��J9{I`0FW�А��|}ov�=�Q�{O��~�v<�?D�@���o��6��C��,�R���������<"x��p|��F=�mk�R:t�A(kn6�e�F��Ύ���h��s���\3�s��'��9�[K��o�}�+-���rF�xOFBO9Ze�;;`]i��Z�f�]E�����F�|u�'%��LgH�r׍�:и6�˰=�$%��4[��r�t�Ķ�/��"�1]ʤ���S����"�4@�?�M��B���3��h�������3�o��n��\�\��P���[(K?��i*�*GUvk��XL�Ρ��
���<w<�Y�3��,�jh�KfX�R��-.�Ԭa���T���T&�x����ڽֿ)~��"^�j��/a_��eX�K�0�{|B�]B���󠇝50���g�*�o-P!|�U�(W���w������S�����|z
*��qAf�q�����>���s~��Ճ�+k��;=�c��?�;l� n����j��}.C��"qͻ�;)J��L\߉pv�W����f�8�(�;�{ń����o���N��X�y�&A�Y��h����5�ㅹo���g�lM"�z�Y���]J�V.�	�RVp�C�߹�]�|o�]ЧU��ap���gWB#�S�X5�K^u	�2�R��� %��|w�~�C�ub�ƭ�뚕��ܼ����~|�]�;\�#9v[�:�/�P:�g��b�?"��n�3�� �W� ��]��"f���%��<�)��L�Nj��={H%S2ˀ!42#��xh5���C���.0�M��.����J~n�g~eØ/�4����߄@]��<��G�����o�s^Q�l���
k|{�{�Dq��&[2����a0�/�q'�vq9)�
b����,�'����m��n�N�T��iUA�n.؊�R�݅��h
��n�0o4o��|	��@�*����0���uDuH�ʿ��s����-2���h��}���l�=�9��7��\r錬��`�W�V�"ѶÙ`�ȑ	��e�O$��_����ȏ�?��f�ۼĂ>p+^"��X��n����+Dl�cV�s�F�6Fe��,����>A��r���`�\��XܒE	L�rͶH.ί��@��d�����')�;��U;�x�4g��]��~�C.Vr&#�;�ͳh^� N��ʔ���2�s(���'���$KJ�M&�C�ˊo�+��-�C�j$�������l�t���߹9mm������璑�^��@�w:=�� �cAY�Il�&��@�=h��6Ȳ�=w�2,�z�`�c/������;�ܶxaI�����Z%O����hd���ޛF�}.ˈ��LM�pm���(N���$��J�'G~e�m�sa2���X��!�aw���ʿ�f����z�sk��BҕO�
�WՎ�.�+W^�� /M5Tk3���]���䳻S�����uJxR�
Hl�����u�W��hXj��Xt�̬+��0��w������t��L�rn�f��:��e�Sbd�H�EA�-FG��]�BY be�0����Y�u�B)���㫣��f{��!۴��7}�����9�r�Z���T�}!_�X��hK��۾�Թe�_�u���+�<o�����T��wL�Ȓ�ŲW�m�2�8��@�/��Z�ܝs!ak��A���c�C�v⮳ٺ�b�:�B���S��K�)Ke�;MF��31,��f����j���>�+k�����R�r��i��x�{_�殱�s�!�;�͆B�yKi����v��_j)�N/�v�KN�a�@⭓֋��O��������D��Eȣ&������CGyi9&k�Nf0v'
�x�Akg��;{�i)��Qj�)��6e����+���-Ȧ����Hi}��pL�hASx��`0B��U�Y���n
j�Yph�+�d�x���|�H˷,۫ग� ��W���-64\b+�\�5�ԕ��P�F�v�!t���]�KLИ�`TLg����:�~��P��t�%�w��W���������6�(qP�F�����UG4TH�[���Ư��L���Ɓ��+	J���l�U$=��^�`��,_VN#t�곜:wf'�kޏ���,Y�p�i�h���=�1R����33"Z�h���b����}畔�m���p���nG{�癳�����W	�a���3�%���{E��V9�Y��G[:'gx):.ˑjӲ�F���(=YPo�����q6�pl wٓd+;��^pة�+DP�_�7J��s�ѐ��S��0�n	u��&��s�'�B2s�u��(��a`�����>�QF�m�j �@-���[,�a�9�ȳ0ҕE��R
�gl�Z&��,�:��$�� 9�bP)WQ`��좸{j�M��>RNZ�@4�Z~p�S�׵��W��$�������Od
)+Q�>r�.���NS��y���ٙ[�1�V��M���y�W���%q�K�ޔRl3U]�7��
�I8�?z��Z8�;��L�M�4�M�*�zs�H,AZS�S���E�=KE$�M{h�g��!>bm�Dl�KJu^(��S���A�4(� Sr��$�>���"�=��笑�X�bK"_j�
P t(��z�FM��B���3��ظ=>��N��     zm�'�� Ͷ������g�    YZ