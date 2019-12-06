#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="431127743"
MD5="0368aa0f4c851e90e24a19b7a349e104"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20204"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec  6 18:03:11 -03 2019
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���N�] �}��JF���.���_jg\`�:T��&<f+',�g��*�K<�V��ǰ�>�sQ#MF{��C����@h�],�����o��"`U�χ�?�dq�v��"�H����`��<��.F�Y-���#NSt���VHV�_W���q�	���N���qv��&ʚ6k��������b�e�+�.��FY�f����8��� F���t�F)�8�o�G�VpiO/)��a� N���U��g��v�T��1����&ª�ش�F���_��x���ߜ�'�Ƿf��9�h7���Yf�Y��)Z��6�gU53�jz����%j����f6��1���|�a:U��z��Μ�z@�,{���f�cb�?�_3��ʴ�id:�1���+J�4� �Ŝj�7yv�&��aV���] a�.J�	�_��Z}@��_�[�cZ�w�d�pP�C�����%�Ȅ�7J�9��	��M�ؼ�_؄���%�t���W�� =A��������I�t�s
�F��Q:!K)��jJ�~v�p���Ea�(ޝ��h�������A~���P�M�Im���U�0X�;����w�U�ZxA��M���_�4:(��S��O��y�j.	���}�!z�~�~~�$
�>�݃��;��U�,+�v��'��9���Ƃ��{�ڡ%gqR]��Q�yԲ�g�GA���;��e�c$�]g��Tn����J�SP���PVL��t���Q+��TĒCV���I	1��sb2���vO�_td �P��W�n~�P�U4=h�"��g �������x
�(�$��OIs�}YGa9�H�lLSB+ ���)~)"btn�5K$e��p+�j���-FNW�oS���̢d���R�Xp	~�FȲ6�^�����_d������{�����E��A{̷�������z�b����I{OH�Y'
Or�r$)?�[z)qt��Xd�1�A�j��:e{�F9�r��\C�^HG,f��2�����y�M��]��A�iߚ���a��'��b>'�Z4VU�0�k�q'х�'�.Ĭ4�2f.}�[=k�J,�[&�!��|FE�ϧ�Y���tgHj���j�<���|��Il��a���s��e��c�*} �|\�4�j��L�ڲO�Ė<�ۺ��rc�r��m��`6a�n@,)��a=��%ӖX>/�H�{��,��2�0I)0���َ9�,�@B����ޟ��Ic��'kW�x	�O��!P�Gǚ>�0����C~�k�ļ⇂X�v�fW�|R�-������V��C�:�����z�F��xVI��s�̨�>f�_�t)s����a�C����������!XH5��6r��XDy�}�d��WF�&N�&����%�9�q����Q�^r����=�ТO�rrQ��xP�����Evهe��M�Y]��]�g[��hs}�㧃�v�M���k~W�����hڣ��:z��zd�����S� *�mm4�t'ctZJ�M#x�#ޭ`�����zϱ��Ah�l��g�7/t t ��B��q�s�;~XǏ�������ܤ^[?���p¼�8�%Қr�A�N��ؕ`����B�O�(�)gB-6a��8g%®���,8K�K!�N-����#s�h���a��t<���C��,��L�z�g⁘����"��,�M�a;Q�O�b��3ZO\�@�{�5�體ʵ���d�O���Z%��lN9�����NW�j�B���G������^��F�|�aoc�_3�Y\%|_��KB�ނ�D�9	@�蚖F-��+μ3�R���H␾�6�"%e�Һ ���;��%wՋ�����$Zx�՜�;J��ۿ���S	���i���v�tA7	�?������M)�d��E��W�����.�Pх^Ь��á�x�&4�����J��9Z��3�k��`�����(HC����t`��S3(@�8?���!�P���G����*��s�Y���8�Ws��bB��CRؤ�|D:bT,��9b��W�B��0�y?�A�
�w�D����/�]!Be$�����m��w�7��������tC�DZ&=��)? t���R�wu8��nZ&�w0l�h��f�2e.EK�vewZ-��d�1�>�S�%]�Z��UdT!�G'�Ӛ&�$f��6c\�c>�|���L5�&s�)��h�d��;:���Y{UK�QyH{���5���k��ip&�!Up���k�{�3�2��wZA5����{(��䬋��i�v��OɃplN�{�aXH4���Ǭ&��7��1���X�<+G�[L��@8ԱY\X�E��q֐����E*z��&�b�b[fS����6��|)�*Z=���(����F����o��Ep8��`Ћ�ʣd:��������)�^�')˟����"�������6�D�_��RG�ׂ�k��`, ����/}5��	9yJ��)����\S�����K�Z���k��khIB���~�~��:j�m����p�z���0%׉�����&@�~�4���qSV������%��@Y�'䏓Ц�.�JJ��;r��X����^��-��&�e���Ɔ.+i����fC�i��I�'�ײ�~�����\���khH��u�N�U�%�� 
��1�+��YQ^^� ��W����#��E�lw�s/������2�mA'�-YT3{v8���O�M��=�g��
�=[�%{[g�����+�%T�K�qd ����5&�c���1�j���W��t���IՅ��F��C}���QE3,��hM�=9[':���?B[��d���t)e��~���n�v�1& z
b7I��9�]��OnN&[HE����YB3��V�I��V�����HS����3�$�̤�J����u�,��:��(�M{�YG��3�tc�������?�-շ1�W���S{�pQ����~�O(8E�I;1RrY�46[�d"�p�����sHݓ���-��'\�!������rV��F�=��	^\d��j!S`�,�]�	&7T�%�k�O��_��}~MҎ��7s��s���!DoU��(�,��<M��s��Sė�s"0E9�D-B�2H*5Թf��	��=%kܠ[���1l��(�`da84��p}_D���lY��Q	E.�r�\���.���n��?^�<p{��g$E�F�S SC}z��6�*�`|�8�qc�I�ҕ C�������)hh�~�u<��#�:d4���fSLw�~�x�Q�c�t�:��#e{��4�x��+����mB� tg��`]e�p�Z�w$<����y����!_A�����2�M{<NT����8��(��LA	�Ec�G�}�ʙ���2�|�y}���0�r�!Ҝqwda7�ȋnct��u6%�k���exe0��~�S��� �ܓ7u����$��P�?������O
�i Yd�������BK�7!�q�CJU�Wx�3�|���"������E)%���3��q���������T���0�X�R����í����3��A�j��9Оn]�[����H�@�; �}��Ƒ@�XFss��e��Ϳi�bW�6��`.��˱��25���'�?�l'�^ي
���������Tݔ�4�O�������hJW�����X�{�$�pƜ�\�L;�O��A;�^ɋ�N�L͋u��wc�fIK3�ܛg�)��G�5�}\�y�V����8��ڤ�j
|�v���rL�^®��I��C0�ܔwM�|�a�@$� �1Ȥpp�"���k-��eѡ�7�۫?�ί1$�<����?�=*!oƙ
cɠ��$��*Ɨ��B�;�O���tĭ��*o�-�Vt�.�i�F��3�
;K	@ �#b�8M���IhۭY�Ρ.V#�W�&�KZ��l�O�����4~*l�S�a	�ZպAjy}1�ZOt�6-̣n��(��Z��\aU=H�zcL�k��/�d��p�gf���*�3d� �+��u�H���U�n�n�_N^���9�;�[F$׀����}�DgD5�W�q0��6�����q��������~h����V�Y�΁T���F�85��m6y*xʹ�.�D��	P���[�9�GL�t�������T:����[X�I̘��wK;-5á��q]�~�C��bn�0�|;.Ʈ�F�҉q
������)�9#y&��OV���K�c��K���4��l̒Dڐ�~�-���$%���Wn�vC���D���جT��n1i#�DQg6~�4���A���kem`�
1��b�.߉��S�%���իh��
o�Ԯ�5&.�-�2d���mK�N@���7���O;�Aƽ\�]գ0�8�����bt;���<����b襫21e�����++�f�2�bv?��8�-�~5�����Q1," k���>�3¬紧����Z�'��o�6�����.T3��:I��������!�0^��xDv ݢ�j������C��J�{Ꮉ$��j���Mg�r:���[�5��g´��d\Ǧ�����l�TZg&{RI��n�8�[Z&l`���o�Ni�����oD!J�;��+����y���1�8�&��w��C�0��b��@�2գTv��]j'檁��9�i����Fˉ�),:r���W�	��m��s7�kϒX�Ѳ�#:b�l E2kC ��4邯l����T��]���`�`㌮3vǄ�M�0��*��L0���|)keԓ�ݳ�!��	`F07i(g�a-��ȕ�.�C���.�usbx�/%�E��A;Ct�lg���{rJ:;�5)��?,V��(Q���:)�P�ᔼC�Gy3�綢C�~˝;���1=f%�w�ɀ.�c�1{���'C��%��K9�%��k�q�usy��`���
��o��I�%ڨ�ȢMq���ŏ��q�!c_B���٘���!n���>��Ev�&�ٍ�޴��7���ԱrA支�s�c���L� 5[Uk��}28�;ϟ�l�1��=,��L��Uoa���������u����s��P���fT�(
��!Q͝�V�?;8�$�|�Q�"�~{^�~�y̖L��\�0IoLrcSHC�8Aˇ�=�%7�N�b��r��d*7�-
ʵ���i����w�!
��:著p���|b��#M7��y��I*L���'�Z`����@�����ا��3�r �@�pm0G>�a��H�MK�/:ܮ��_!+����qI[�"��#0�k��	�g��ڙ	�S�U���Q[��W��L��9A�00�	27:�M�&������Z�x�ω�ג
�fM'g���DRT֏�	��v��"�!��D]�M�oR�����%�q\}G*����/S���t�geP��zQ�rCz�Bn^ïJ��|%y�
��u�g��B� ;�[��H���x,g�Q�\�S'/��}�i�������u?R�VL�l�=Q��UjX�=3���grh���3�$�Dp����6^4*v���M'��Il�vu_�^���=cV����&����P�8DG����W��~�՜�}��.J�#)�6-5�)�2��B�~�Y(+b!qCY��;� ��%3�� "�d|j:��z:S��rN]P�ƻg�[ԓ���G�8 <���O�}�.�7�Qbƅ��`�Ҧϊp篯.Op��鎦�xp"�]�PGZ���5��L��`	�phf��v��J؂���
� ��`�g"�dLe�v�gvV���"J��hc�8r����J�������˕�y!���'�'+�OP�)��\;+s��M���%����q�� �8���:h�<"�忸Ԣ�>��c�_�W4j�Qyl��x�����8AMO�'s�"l��������sL��T?����8y���s3��Z~�FB��P5>ǳZ�|�^� #�.��u�A�<�lʟ�%�]E;�(  Z�	*^�i��31�K!e j�[����I�2��ir��^�ۼ�ꚭ#��bE���G����N�T؃��?T���ǳqx�^>S�q3��b�Z�P��v�%M�	�����甜�/J6�q���&K�����u"Ťc\��գc���O܍@���R�p�����N�N��n	��f>l?S�R\}�Q3���\V��9�t���M=�������^.�$���c�0�lј����k_P�(#�Ύ�0Fbm" �(�N�q��WN��#�N� `6]R9�e�:���4^�f�����!3��j����ޖ�*��X�"}82^����Ղ�ᙱ/�)^V8��is�a
~�җ�m\�]z�ċ�+��9�[I��1ɩ��<F�N��M��0�?���n[��p#$E5w~\B{�0���/ؘt�7c�j6kB�Y���#:��䕺�P*tƤ��
c�����c�P�7�JKd��p�1ʉ��=���ݴN��<h![��(�ޠ��Jmྛ������zW�<���.���y+���Z��m�&�杸���+gM�m�91u�C����i��JF�� �W ���2`��@2��eu��0����:h�6��~i'��/"v}o�ݨ���cr&MZ׿��X�b�NL1���'���d���M�	25�k����4�ކ��}�����p���/��~�,�!��k��l!x�����.M�������b�/�J'ZM�����Hh��К�~�q]ӕ�]ay�n��2�2�e����og��T�H&Ǡ�"f�R2�<�\�gܦ�$��S�7X��a�>!	f=���_a�GT,�m���_�+�Ƽ$�R���ށ+��l�g�V�P���X�~$4z�TK9��Y�ëg�TZH�#�%�=�� ����2`O�?L6?�W�-e�[�򔞻5�5|`*�S�� xþ��?^�A����I����ꇵ!�	��j���%��Ls��L��/o�8��ES��a�q��yaS�����ɿ��"�=%~@�Q���;��I7"a7�I�Fyr��Gf+L��s;`_S���B J�����1S4�O��y`E��|}M�M������~��n�U�`�A�f<V����ʝ���%g���o�/rU�]�W�z����sT\?�=�Vo�ҡ�����7�r�@��ql�nb��P["\�^W��}����,R�e<�aQ�Ƚjk�2�_�D��M�b�_�DX�K�KÊB�hx�;m]~��x�@��
�&jP���a��.��m�۪jhZ�奡�1��=g_�(܎xjX����#���M����d��H���y~=� \1=#z�Χ֭b,h�d0E(�ە����E�ĕ�ª����9N����\�ߋ���9:"�ӊR)ْG�x��DB�C.�g�� ����{��?T�_��	!���]�#�9���%0����]���,��y�s��X)]���ҔB�
�:ƻ�4�x�&�%�~c�$~�}�td ����
l��|n�<�]�L0��
4�܌|�7�Y����n�7��Uη�|��IX�5���z���V��%�5�:+?$�n2R��4-��s���ѹB�ieU�~' �&�)@�E\=� I�~�s^���*�g(����W����B�St�"otIAS|-�k�����igR����@.����C�&s��+�g���mT����"���� ��o+68�$"��qV��kX>����I	7;����x�
�øif�:a-s�bA��&c�Y��l)mE�E�-�w���щ|W�1/���+��}�ȧr��t���N�|��� 4p��3}�Q:�G�Eg�M��8��'�p�7k�d��:К��*������=;+D˧��EL���f��Z�}D#
J(�;K�Y�+����VP/\qm�x�lG�]������r�ʫ��e�/z���R�OSl)D���K� �.�@>�\�H�NG�*[N���V�N���\F�li����:Xf� _��J�R��Tf�m�c�&Ygګ"t��N��v/�~��Qv�h2��=`wKֺo�26}~Z��JDV'��	%����_u�����h b�$6�r�u��mt;�o���Y-cS��Y��D�-l���7c�7��/�I�F!�r	��*'�J˒���Dg�
a�jY4���*~;��ۤ��eA�r8��εJ���2{Q��^s�!M�fj�L��]�o0��2#��w6�J�MQ�jF#2< ��fo᪺�Od����>��wa�V�����~JГ�"����ĝ���8���\e^ �:u�U�w+���{���d�V�,D�À6���xȅV�O|h�Ϯ�bJ��^g�e�7�Ւ�'>9fiP-�tb��+ʤ6w�m��w�дg���Q44,��$a��L�@l|��%mЁ�!-�!>�����n��-�ݦ��A=���]3j��&��`y9%��l�t���_��y�g�z9��gF�'_�ᯣ�y��-;������A._�7�����y����7���'0q�	͠��Ve*{������;̙�&>���d���fm���Q���4��ā������'�����o	��bt@�cج���pbA8�\9���Φ�DA=rS\4*�������Q�[�y��=� @��	ב+b�t� Z�s�ΜL��l~�-��	"ko��" ��i��ԡΈZ�*�?[��Nn_���9I�Z���r8^k�u]N>7�:2�|�N�K��S��|�@[�eCKV
������`^����������� ��T���f'Bq������M�E�׊��tS�z�)Z��^HgU������y+���r4G�m���ɡ�E�U�ޅ&��XJQu$��2�=�����	����H`=�<�9o���ԓ5�>'�`HE*ڻ�~��gw�\�Q� �X�s%J��OH�6�_S��Uz�ѯ�7���^"�/1ݟ��d�+�n.V���R�V���`�cӃ�:�E�4�swxn>n�2ry��M����zaJN���=��6B�i��=	#�t��$.�Y�lo�K��߄�����_��de�v� c�"~�{��$�k�3Q�ŀ})��'+Rі���dKĳ���|��B����8�ThƔkvR�c�]/�y�N������鲴�ܘ�O�7�;"m{�-��m*�Ѵ]8�`qm�,�R-���H_r���uL�k��u?�s*I���gG>��Ǥ�aN��v���|��H����#���S0��@�E�YV��+�e��V�1d,��:l�z��9�S��<pE�y�~8����8�9�/]�V��R1-L���#*�f`)��73�ĵ6��z&n�rZ���3;nI��[7���p�`�S�X1>���-
������(2�(?������ �7Iu˶%n��@��>V����˷�F�T}
�����i�])�-eT��AsA!ts�	H{?�Yhi�8���)8LV��ܜ���x\R�=3�z.�1�xM|:}�~|8F�v���U,�g#������`y0me}{4,F/��s$��*a@��l�]OC��Q�󯺢(������b<�ŏ�� �̚O'�z#�y��f�j�w-yT�$���Bk~1����+;����yڍ&Dt�{���J�v�>m�-<��]���>�S�N�Bc�v/��x�L��S�Vݒog�DiM�b�x��%Y��$�c4��x�ӕk����*CÃ~����g�L�f��9��f[*�/=���r��;5��Ԯ_]�ly,�Pͩ�>^/�ֻ�B�S��vRoB�_N+�gMh����`�!8���Rop��y�/���lfA~�U�W�뢶q�1N�n�r�*
�#%�3�r5`#XНto��]��`��+�>K}+�ߓǚ�rm���c�2�! �K�����1�*	����F<#�U ������K����}ˌ�,�P��(rF��%�n�A|���˩��q?�4?<H�]7�*6�����6����gH�'���!�����l��l���,�^���Sxb�]�ճ$��l�~,��!		��O.��^�HB0V+}���\�� �$�� ���HE��!��vGt�t�r��Ӟ6iI��^���r��U ���v,ސz�u=E��!�n�
�īh7��vrm����6���SPI�G��/���8�V��Yˡ��`Ŏ��\�D�.k�X7���'P����q��Ԩ���ԴB7�Ca�bf��]��i�&��[
�i^!+�P�	\��'Q�P�?�Ұ[(����e�Ή#�V]VǊ�RMr1_�<ߛ�vAs|ݑ�lyhڱ��<�����Gў���1����'"Q�7R����i+��
�ӫ�Kt�-?�c��E��H����e�N]\�i���؇���|�!���@XeI��yU��E��� V���P��=sᅞSU���)[�)���Zu{B��������2zCQ��˷�wba�8���q��g��3Q��"���"�/��q����9k>��܀�u��r�ߝ�P�K�3"��uZR��k3��mc�li���,9@Y�+^/����Ę�n�9@��H�+l��>��� �4�S���E�f���T�s��ǵ�\O���J�X�qr}��9D�u�)u��0Ǯ�	i��+�K�#�.��B$!Rf��7�e I�Z��U�uR<������W����Re�V�;&�o��i��_�!@%��~��b.���s�o��eZ[[o�"�ktY#�����E��ѴM�/+����R�v��5��o���܉u|�-͐��FY�w��G�W�F��<*�uz��_����ӧ;Σm(d*��
�^�����������jB�G��mv���G ��]��mS�y����E�
���'�\�	��U	���ܸ�n��iIp�%WO�
���3_	K=�?�$nb|U�<�����9����ӫ!�s����������8��*��z�.8i��5������A��� �������a,�g�/�TP	�����ib��\V��̀���M_�C�D"t���^��R2�T�$.�qL����Z��F"1F߱��Bj��bd��뾂q�6ot��w$����Yh?�'+t��
�1<�T����K�9>�� ��;����0�C����Ȉ��y��$�j7���aZNUc��,�[�uH�M9�<�:N�ظ��vJ��]���m�YW$!�g�m��;�Q,"�5k+��b�d����N���Y���������#�orIL����%L?����+r!�~�[� � ��	Y]�@�v���Xr�b���a����k%D�����i5�~T���P��~��� ���B�ӥ�����,�uUa;�IKy+}�7|y�#���q���6B���k�Dm�=t�A>�N�b��,g��z�Ӑ�k�.?�����t�=9R~�y�J7#)������0'"�.W(���	���L0a8����rO��#�L��P�d�Q�"b3�FY��ԅ,X6Fw��;>'D���ˇ�*�ݨ��I_&��_�#��!����5M����G@'t(�������������� ���>*]z>�&��N�JW�xi=�TPB����)���a3t�c �𶁄��i-� YьD	2��k#��Z6w�Bl'�ZF�n���0�D<x�����:�]L�� 䭼G����X�$���o�Y�3H��AӟN˶E���ěAH�Y��m�ǲ׹Q�AF��AY���&c>qYi%!�Q����߅ı4;��9�5Z ��l��cc���BƨH��ρ��~���z������3��M�լ"n�F�}�M�p����{�a�^�0��d��7�!'HYg�⨥?��~�t)Gz����GZ�l���G�2��*N�.>w;�ݖ)��5�tR@݅�����F�yg'���UJ�'v¹���-��jx &YY5�x����"���v���yK��6=U�"����~�~��gS�ҙ!��Ⱏ���Ϭb�|cY�v6��;@�P��⑂4N���᳛R�L3���"�A�ت�����X�O�hw0ÿ_����JŅ�Z��N�kW-�D�'b_666�#�B����D `�x�� /rĹ�-5 z�b6�z���r��*���3�Z�B2�jI	��'Anס?]^�H�ᶻ;�1�\��K5`��տ��"�$����	F�Q]���X�%e͐,�
��ɨc�c��� ���Q@!2�����B��c���g������1ٟ��ұ#���<�A�Ru=�Oޜ8��}�����* �s��>8���a�M;�Jx;��%��2�D�׃���ȭ-ȗgr�v!�ɹO�<��̸�s�X?�B���Uf��\?O��7{+��Ѻ��ҀqhqK�Se�-��S1�%�uy�����ݿ��y>�v�aU��{m�/ ����G6Y�~8%��]�69��]n��_�'0%�)_��-��x�`���!ĕ����m9�w]đ����5���hh�zld��	(�����g�=c}s,��|��f!dʘ����f���6��9����"��~�P�*����$��fFJ'��Y�r�wx@����7�(щ'߃��{a^R��'����%뒳?�?B�%�J"?6l���+��p�DI��M��Al����G�xa���P�[�es���5 ���^l�����E��M������6X/n�ݯ�c�v(�~<�������a J��ރ�b/������w[���w5D�Ѥ[.��d�r����@��7U�a�1d���F}e6���X����`�`t�����h��wӧ�E	Q���:�W'�ȴ3=$����mH�{n	�t�" �6�39�U��T[t��u!���q=:��S���蜒�;�����9�1�6)?ۍ��R"�+cZ>`�ĜCg�C]vx�N���6��@�Ю�o�ˊ�$���� ���a����r��x8$���1��Р�}�j< ��z�;P�#Z�\S�%9!/���ptn
��%"��L�Z �<�5J1A��0\+����B��u`z��޺��ܝ��XSiGj�j����L�富_� �4$�S��EnWa{�DB,�s��G-�1 
ki��xz���HHّqK��ޖI�M�CkMC~hߧsԙ�Fw�\B,d]�WL�� "��X	�=ߓ'(�f��5�j�h]A�Y�	@FD�0�趫�BV�N���� �o�.�ߐ�� ZME�W<�/0�\�3��.*��C��&��eKh�C�`��p�^�K�>��q_��yk����u|9�����ս�1�xLj9��M�i�\�n�Uf���@"HsqW�ڽ��<�/����o;�����p8F��;�"PaOkҤ��ҳi��p42�D����!��v�MjPb�yb*��])�<�èE�js����~XH:�UT#�xc�?U�l���I���[�}�� r�l�t�Kf�Mv�0��_2sim~��ң��.�;�ڒ/��C���C���Oʳ��|�t';�Y'}�yF�����;�*7 ��ӓsSt+N��oAP7&�RO"�����B|�T[�U�M����G�mS�^~C��ƐK�a<�Wut��üT�_��������n7%� �S�e��,Ә�Y�x��5���8d�����Cu�6\�Йs\"z�fXA������'R�=���b3�W��N�S ��� c��š�����ӻ�޸�.�׋
7������3��Q�#w��]��i���vz=�0�
����� �Ԙ�Cԇ�;���q�J+X����đ��_�R�N:h�V��	b�wG�z|���ʥ�|ݥ��S�,�C�%�Ftt��V��2��Aj�tn�f�/�ɷ�z#�Q���{&�if�G�7By�)��T%� 2<��	.���xP�	4�{�S�c��E��<V�-�����1�n:��R��(0<шy���
�����R�%|P]�^� ͈5�X\cbw ���-�@��GO��/����J�榙���'D>�b�Y�L��ik��b��@�9ƳǤ�/��+�	��x�N��u��˭?�/����S��iS��Q<�k�����f��ϘP����XGWT��8Q�wa�i1Jp���>�a�wJ2p�'q�j���� �<L}Ҽͽ�-l�O���p3�vW���Ǫv�i���M+��w�SW-�t"`�F��v��Je�2~ϕ~[�?�Y$	)���8�l��_�-��gk� �iI�Z(y8i`PB�D]��YE�Up��f�%�ҟfSsJ�w���;���PW�'g�x���#�au'6;�'u�"�w���a��_}U����DV�H��Qzy�%ڶ Y� ���NSo�%��.�5����b��ܸ�߿��en��,�l��a�f��W��S޶^��<=��L(���rY���/�0-�m�2��^j����e0D��w�CCW��;�H(p��E�����7w ���R��ͻ35��k�}���䱆����H�U��iD�G����%�V^h�2q�Pl�Y�z��r:vF����LT����B�5Pf��B�=�ebٞ=S�j���6�R��TW\G�IV��z���wqmSw�h(�u����h��E�����F�D�vd^+^��׹0�vP�~?��9kI&��v�=��Q�	|�)h!߂��������w��'��7��"v�8����g�A\Џdj����)eQ~�o��_�2�3��ta�����)q���ݣjW6��R(������N�B�;�rѩJ�HX͐ �~�͘���_�0���9���G	�d�<4R􊕴ͯ��)N��o3�CU�L���xź9����}�$0�|O8]�j& �j�?�Ǜ��bNV��+�?v�!y�B�����&�����T�2ȷ��w�rP�)���ɖ���n��r=E߁&�s��wdi��wS�=���F�MV�3�	�	̊|��^[��D����	�aFu��Dq�.+/��%���k�� aǳ�_��?�z� P�Y�uY!����堗ѹ���F~��$݅�]��uZ ^�}�C�������H �����u�����[O�\Lˠl�gJ��(?�N1BO�+�5��֨�ӢH9� w>;�xh�]��(5�t�\:���ʡ�R������^�A"�3��p�m'r�]C�t����wݑ5Ā��v������c�ɼ�v��ʁJ&���"�#�rt���n���[��W: ��g�4�ߚ6�C�P���:�m��a|��M�yy�8w�Xg���E*�FQl�������A�Hn���l��r��&w+z�J��v�Gu�c9��3�	�tb�,��P�!���z.+3�C �\�!����6��.�b�AA��I��~B>�IH�k8r�u�>���(
HT� ��Ζ>�@)�;5~Ћ\Z|��6��iw��d��b-���Gd��~��%_R?�ji���2U x���bЩk��&N��yܗ버BR��5R���������:à��y��g�K6�]���̿�.Ez�t'q/YH`�r,�ȥu�brz߲A'��P��:l7m˖q���z|M?uN���Js�_f�~���bq+���އZ!	���~�ߐ�� ����i�⓻� 앓Y��C�(�m��c1fЃ��J(��<��3���>��`�]ڼ��p��O���y)ɒ6s{��Bl�|'���u�0����%m����ԖB��n�u+�O2k��v��.�DS�QI�w8Ѡ�}���_ge�j�b��>�0��#�n�[�9.&���ۥ�Ӓ@����������kK�7�@v� 抲���ݜ=���M�ԥ��l�G/�1'���F.�O����B���U�4�����c�8��
 Q��!Hk��նk/�3p��%�YYg�L@��Ι��Wt���6�2.A�Ѐ7����n}����x��C�
Z�l����t����i�g�Gk��>:屎��W�He�������w�C�\���І�_9'5�u$`�軕����v�X�p��C�;1B�ecHbj��+(lY�Ӱ����(�֘Uf�6x��&���'ۏd�g;c��]���W�Oڥ�$t�㊷Jy���:�?��8�Q��[�Pi�f���Bq�4��2�X�t�%�z���O���y7��	Ey?/^���$��c��Җ�\��́��]T�4�'�;��>���zt�UpE60G1��83�^�VwR'v�k	�������� ����a��1d�	���Kd��cJ`	_$3qE&u�M-f�4�"�F�p��1!o-���ra(��9��AY*s�x�Rܐ�"l�}{0KN+~ ��M��Ēs�@hg��V'�%��)]���V�(3j�=m�i��+�)���м�RZF
����f4���r�X=;����5qd{n�'��V�9O�3��%���SW��ѱ�g`�w����E���mt�?��ֿ���{�(�?�D�_���-�mOۘ��]�W*UͰ���k@4��2���"��Qdl�<�:3Y+���
O!�d3��j�0�L�0ё��n��M�>����N%C
K��r��A�VDj�/#��ױB0jR�7�r��j2�)�jF>�	�˷����Fi�}�as;�k~�).=;1��8�%�LOiyf�8\7�0n��x�b�.'�v'e��i�o$������B�be=�D�+p48�P	�J����C<�O˄j4�dKF����Su"�#���U��8�3Rۖ�P��q��u ,2���?#h��P����r�]�@�%]�!a�y;��H�_�}�5�_(Q�F�#o�� 0���x{~2bT����"k��M��o��6�OZZ��u���#�+���t*3l�\V�̩/7�u[����x�R.tR?�n��A{�`�>E�3� Zp��,hz ���U��Bí��ԧ��D�AXI�e���~xm~��9���JY��X�r�� ^3A%�o'�JX��f����@W#�jZ�dDO%"^��K���~�)�Ky��b�-��V��`�oB��c�H}�O���6�P��(�U���l�>u�u&�/�[ɨ���1OrF��uW�@/!�xP�rAo�����e%y|�?��r�v9c���@C��`Z*�e	[����7�o�������P�{��)�[	���3R��DiьoΝr[��#�,V��Ն��M����[M+V�ޝԐ7H8�׳ص4#5��A��������r���4�cג��V-��;����g�<���T�ahU��W(w��A�^g����v��Z���op&�#� |�F�􏼑s'.�m�ę��O�@ ���3T�=�p�C��v ��������mE|$r���դ��l����cm��b�%��"ؒW��3�.�c�V&�:�@Rr��<�i|M��97�P�,�#E�r�At's\��pPm��5?�T֎�&X=�>�]�ݑ4����O-��[�P�GZ�*��}}[�8�!6�=�9�8��@Y<��������W��:|�6FF9�N�x�qK2�8⬑���Mv����� e~��f�t+�uC6��g������Pn��r>����cW ��U[^�J[x)k�Q{g�T���Ư0W�|��e��Bb�Y��hm��QcӚ̤aL����@�nW�V�(l�#����nLU$�2bMwU��9ON>��Sch]I�1T�Ĭ@������A �{�G
a���D `�y�> ��T���[�Hh�V]�S��C��C���z#��o[�+�"?��^�2m�T���Q�j]�7�$���)�8=qeP��g��
P��G_ф[{בL4������ED���܌�R/�E�Y-� <N�nx?<���~�� ��C/rn�zk�Q����!>#�_���|��>hª��[}��Z��EP::�{�7�rԩ��NΪ0o5���pO��1���	a�d�T(@'~��15!T�-�1�Y�� ��#=��ۊnw�i�LA~���g��"&5nA�	E��>�$S��f����h�y�ԍ�E��%$t��(?��ME�X�f8�pK��#�NQ�h
(<��ޟhB���UVF<7�S�,-Pܝ�;��[�f{Y�`@QĊ�����!
+O�����崕�=����HҶ���zU�n�z��cVd�o	D�rsA��;T�=���9�������n|�_��P�cՈo�֛.���I�`�d�%����<_l�ٵ�`<�6�VYG��us 6����1�(z��k|� D3R�o���[m���߇ig�p*�L%�we�����>#jL�	�i���k�I�cHī�����4� ;ؤAD�c��	������B(�k�^���i��n�����Ɉnk�)�5�p3�����`��#I���S�.m��=ԍ���y6��J���U _Ž�ø�%�%uІ�LjT�y���a3k=�Φ���y�%w|0�B���UxLo�cEQ~��Vk.���3K ��֡�w,�U�4��\�V���Mw(�������'s��Oѻm��;�z�K8A3bDm��F��ʩ���z�=�դ\�sryK%��Ф�R��tw�;�2��"0"y/����YQw����g�T�%�#}�f�\�<����L++m�r���� ���w�[.qLw^U��JC�p�'������!4��U9a��7 �L���kjټ�SLL���l�{�����Pp���a�������8�Ϫu��ffo=����S?II0�AH�-�Т��BWʜ݅��b�A5|���C{�J
�9�-n��ƻ���1S�bT,�B��mg�nXT�|�ʧ�ݠ��/`[�1�_�΅W���[6q(�ڪ����g��MY�[3��Q-2x3�?|�6V�:i�1`j"��J���W�H�(���0VU���0
��bt��^�6�yF(a����{_zNC
e�8_���r�'`����C��QƤ�VL�|�@��-�*�QE��!�L^���KO].����b���_�`����w3��}������Pw� ��a�[�R���Ӡ���ktw����p�ū�{f�����d�)EA@&'�ܑ?6c�B�N��x�5�I����΍!�Qwk����Q������6���������G���
��b��t>�\�Ea�ý�DH��j齱]!���1�Ph�N�Za� ��v�]ym�.c
�%��i�@�@j�-�+��G���1���r���]�b΋Gr�r}�횊�{5Afgn�������c���n��r���vށO���V���>Jg��W�u�v[����c�Q$���b�	��?��Q��L����T��ɝ�a���`5He���_�1�7&�M0��F)�%�k~�o��EI��s̉����v��q|6d����o�d�oB����%2��w���m�g�y�*�;82��	?��?a&z�=�#-���0�eA��<B�o�F߫ �7�g$��]�h?Y��9W�q�������M�vqb�3�.���gT�i�������H�� <�W�7�P��h��Š�!��E/bC�/ͫ�B��D�l��ڡۮua()��7r2�{g����چ�'Ȳ���|��T�D�f�Q|h���UI�NvJFkc˦<n$�X�1J�M_��|:��m��2<�f�^���a$�^��/\�NO�7�R0o�JnM`�4�/ۋ����?\��]A �z�d6�|F ȝ���Ε	��g�    YZ