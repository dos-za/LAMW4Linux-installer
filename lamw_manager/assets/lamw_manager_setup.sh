#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1498050723"
MD5="e35feaff014b5148317eaec28062b3d4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23252"
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
	echo Date of packaging: Wed Aug  4 04:54:31 -03 2021
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
�7zXZ  �ִF !   �X����Z�] �}��1Dd]����P�t�D���D��@�#�����:u����3M�u��}��h���x��Ͱ�5�+��q�`9$f.������}r��L�%���Ъ��3��:�F(��Q׈�̲QW+��V(�������z���8�7�!��e���JG��JC�CPv�����e�Wd54�t�w��(���i�mSl��C*�@Q�.
>�@t����Gg6$�f���A�J�2K��[�>��}�k:Xx�]J�d����0�������R���h��� }l���`�͐�@��:�sΠ�g@��;K��X[j�io���r�WO��v�24�5@H�RDZ	�~�֍j�e�q���Q�ϻxܶ��\Kq��pQ���b�2�񽨭t�-�%h�x+n{��)���:H����Į�~�J�p�=��y��8Z�r��}��G����0��ߺ�&�i";���7��F�0�-�f�}).�3������Vm��i�;�
2G=�_FHM�adu٬����ӱn+���Je�W�}��Q��x�a��ȧ���3i�z��޿��,����9�vϜm#/&����v7���?�^V���E�z{�K��2}�+ꛧJ��"��m�&����B
@j�!�K�-{MУA}*���v�)RWʚ�O�ג�iL���cr�j��2�Wĩ߆�O�f!���#]�&�x�'f��u�:��\촐N�YJ�c�#Q@ֱ���n��Ej��^�1��H2��2k�F����Y��$����`]�=����ď�i)���^��[��7�u��Dxl3j�c&��j@�!Hq<[t?M|`M�6{e
 ��E=M�M����6�h,�����o ��U�M\i����	'TLqR�s��X�g����������}���"��E��MI��%`Ԓ�Cx�iA��혊�6I�Á �jS�w��D��Ɲ�?����ι�I~�l���H�x�׽.�i�쨻J���W��8����6wm�3\�m���/�ӲB�WƜ+��b3ĲTN}T;*I�����P�V�׻�J'P3�]�$����� ����ՌBg�SuXF�@��yRw�:��gW��u-k�&y0��|z�2/�0�d�Ѫ��d*��YrD�������S,�;�F���J1�F�S����'���*r�S�i
4�ok�Śӭ��<�^��R9D-9�%%�5�V�����ń�̲L��`��LD���[�d%�������������R�o�L��TY�1d����m��%[�ï3��%���Te�x�A�`Z-TQEi�	�U�#F�'��>P��eL&7��9}���Ȋ���������x2ǿ�ݱ�@bR�����O9x��N���P�~�3�/�(^��y����8�j���DS�2!��,=��h6�q@�X��In���R���g�����0����\fe�lܺ6R��DBqx��vZ>���^��ٔ"
Lߚ��[@���Z��ѩ�%у�fo�G~�x,�/Z� "������]V���D}v�� �F�j�we�.����PC�dQI���+\��[v�c�n�4�5���{�{�qwv�������$�x��QW3����i!a�?<��pK�x�n��R�i,��Tڇ�]�_��;��ݜ�X)�|v?	�D�m�Zn��#8k!v?*�4���n=8�A����$O�hK����7������jyK����ğ�t�1s���M,>/�T�{.e=D��
���N]\��j�z$T��ht�ͭOti^�Uq�¡�%�`�3@U*�ˁ�O|�[k�H�,׵*4B5΃�e�~I%�5p�I
15^N�|	̓�2�㎧��os�
�QAŮS�H���n�~���/����^Z)4�e	$"��n�(�KC粁��w�H�g��%���*�]�����D+@�W7$�%��ڟo���d��S_��(2Qa�?�mgm���ӡɿ�Ʀ���CVp�U/���-�c�wm,�����_aܓ���q�2_oD|�A�����=Vl�@{xAd8�~��{�w����
�Do���m�Z��?5۴ܰ��Q+V��E2n�&}0y��+<���E[�y���e�,N���K����@�iI��i��\<=���?I��Q���Kac�.X��L��>�V�'���Xg�(�X�V�!�E"݋��=�>�����'>�ӈP���k�Ӵk_�
W {��W��t6�Db=�%���dcGu�D�9!&\j�J�I��<X�q)���\ƆDio��djلR���L
I
�r��0�HKnO�Ǽ�l���Zo~e�u|�m���Ӥ��?آ���C���[	)�bΤ�#�[�1�?#F�[m�EL������,0�2N������XO�Mlp]0��tTk��͑񴤩�hB�]�!�p� �e�Mp��'qG*��,��_�m*E ���2_�Hr���OI�Km�\VK�/����ώ�b�q��+�;�kZ�Xw�;��5�h�a�_�����S��O.��`b�
�Ȃ�~�5�����Մ���G� �|��V$�G��b�����p�!Uͦ�v!L?d}�J���"�:Uĝ�	1B�zn�hf�Q����U~��a5�E��X����Q�z�Zܷ�u-�ڹ���&�c���frV�߭�q�{�Z��E���e?s����B��j��:��'k��)��s��ӵ�p��эNr{&�h�,z@�`�c3m2�k$��Ϻ{E�x��7�v��_�d~ZV���s�������(?��G�ۭ�%��:���>��b�t)�)��̒NY�o�<r��7���6�|	�J�^g)�k�5��V���;z�ǥY+�ؔ��k��zJ������h%s���7-����i	��d���O��%ssº6җ�%J�5���l-ޑ���{Њ�ฺ��kE-�������d�Dꐲ���s2��>�&Y
+��/v2j�d!����'�ֳQ�d�UڦL�nm��;lB4�CLЍ���bh�37>�CNZR�Ї��0V��x�U'4S��T�%� ����L�V7���ʸ`�������B��-�clpvDc0H*���	����A�2d�o�����C)-q��ҹ`@���W�[U�%O�*Ƿ�������r����^̍��:T�[�Õ夫����cF�q���ΜEN?��g��c̒a���WybV�y�V7�In*p�}y���m8���~����E���G�]���f�+������ @	s5i�E�!�2��,�o�F>�4n�b�R"��BQ$��/�?���e����w�U�,!)2��4^{"�(�~s�*x�%޹ %I���N��$��#8Y�2���cI�Z��B)V	�"c2�a�&�}W��p����v���Tm��P[1 ��Y��/UyY+Z�0.k+���������l@�cr���ݸ��؏�'Xq�Oo��B�f�B��;XB���My��ac�pq.��N)��[�v~���Jl[.�Z�4�Ió�Xb��,����6�~�]��Sцw] ��� 7j|�`:޸�C�D$��͟k< N�;Ԑ_%�q�X��|���cE,�)���	+ V��3Uٰ��.A�R��i��9R�� ����y���Y}25����ehŻ��������h�)��8��=<�U,M���%.9��KI[X}Yy��\	�!�톪���L��w������ ���,԰�a�{��!�5�A<��_�,����-���i��Tt��t��j�&���d9��E}�V_�,��_$:w��[M�'�2��=�e����V��J�LO�p�^l��dK����\¢�~악��B~:|2�N'�x-�YZ��Vp�!��x�����z�C�����"��t�L���j K	6{��-��
F�fD��� ݈����"a�*�Ճ�Jֳ�E�;��y�k�d�	��d#LxBƢ1��rX�+
�3�v�ގm�L�Kn��WitC�Y�ۼo��xaw���A��)h��M����0����7;�`F�e�B�Z����<����;Xc���%Ǜ0�-=���֍n��&��<Z��e�k^t��	�o`�����e�c۔�Z¨uS��c-��d���S�������r~��7�|�{�`��M�zV0��fx�[(6U��h{S5.�Ƣ�����v �h��|���,�y��ܙ��3�[\��@�9_c���#[���i%���cW����9���S+?�VB���|i��Y1��խ�w�a֤�rV��.=�KZ�r���j%�'^��޷4�F=�&�r�?��
�ާ�dt�;.0�9�Z�SԾ8������u
L���R�n@�ބ>vf@�o�նF�����ca.��]��e�I�C��p�髋5FA�����������pu�;
82H���R;�g��MR%C�CK9�>D�n ^�:n���FC}N��9�*p�t*�dG[�~�#@=���9�mȕp%�i����~�o�ޑ��?8h̾�<�׭�7���>�K�U
֘����P��\�%N��k�}�;��R����<_���Y۔�7���M~{copB`��{5c��Va(q�����_*eΌ,w=n�y���|(N$k4á
{�<��Ep��|���)c	����V�s6��,�k��9�D��
���q9�;Ce���kH<��=C���S���3	ɿ��U�`�vr �c�����-:=l2��o�Gk��{Z��_��g���.�pjˣa��ņS�f��T{�����h�~���6Ȗ'hF��<r�F����[�넒�m)��]���~\BDG��f�$ޯ3����h9h/�r)�2���4t
Q'Ѻ��W_1ȍ�Ҏ�����Fb�s�[3�сؐ���S4����	p�����/Tvr��'P�A0\����!�*a��W�6�R�s�׶�_(?���4Z ����2L�"��s�š�q
�w��2{g�A�������%\���m�P���1)�� *����:Y�l+�"<�L���E��L��	{n��,���4�0���gi6�K�j$����q+Ys�����Ճe�����?s�K�B�p;~�I�Es��e��y���T5�E�C�H��r��a�j��+�X�:p/�4�� .��j۲:R���d��t�؅l\���	ɓцa��e&�&p��o>?>>�y�O��S�}�vڲ��S<��ȣ�V����g�	���?�-���F0�gE�`���n^���p���.�I j�R/����;8�U�Y�L�H���ҷ�Ɵ����udlC�"�BTFƣ9a�Bl^���s�v��=� �?u�'DɃz�ї����V%и��2S �S�����i}����\��ql+Wr�rC�������$��}���3��}�oc�����~��άA��oE(���T�W���q�i'�����`7��'b?��#5����اfwT�(�J��6$|������ޭs�"X̥���z'l�WE�o�J������3姶򫄀�"9�3dnW�gU�~�bUl�gm��*w�4~�$�r�� �8��!S_�I�_֍�A�?�GQ"�Rn����C:�W�ylZL�z�GH4�M�?H݆g׼����!f[F�H�Z���� ��<vj=�l����P��6n�\�41�2ـ�g����\�Ryo�����3Y�!���%6���=��W��	S�FLz��Y����@�½eRy ���D9�u��@�j\�U���w��TU�=e�
O��%�B�s��@�L�Ga��`]��Z�ethGx��+�Ch坵2���Ce��?�Ѽ���=���7 �-���Y�oq,fٕx��ia*&��{K�#��j��U`���g�j�S�������~�z9~,	�����|���n�G4�!����<��'��)Հ�����x\@�Kr�����-�H
�=21��W8��Cu)T���i�d;����վy$G0��<��
�[d�U��N�>�!����_���p�8������Ϻk�����fkf �]�Ze|T,!?�ߘ�b�yY��H:K�^���jf�C����}5f�w����f����%�Q��x�.�hɿm�^ۺO�8�ǘ�W�IZ��:��ϻ m�*��>�gD�h�2�����W��m�X`� ���:w��W�l�H��C?��xO#�d'���eU���ba���i����Z-�rc��XuU/���}�(%Xm�-��}U�tky���_�#�g�g��H�Vpm�-�^Ttd�����PW88l���?7C�vf��V�_���#�6fa2�[�J��[��W"���m��o?<���]Ρ
�2�TiPyS̊ 
�V�B��!��A5��bPM��
R�qF�A��q�\�XԼqIoi�D�]�,Ժ�.�˘����{��.I�����d����خ�(,���se�"���'�ߌ��R��y���4V<��eP�W�z�xs=��U��b�=&u�ĸ���^�"O����v�y���]�\|�j����Ṙq;�O	��ûp���	B����HBCHa�ɠ���]�ރ~�+]i�P�ʂ$�>��.�PW�19�`���wy���؀j���ߊ��ݮN��F����?|�="4V�B-nԾ@��{(7Hs��Kn�k��.Y����c�� ���*�y����]���n��}�}9�h�F�����+���!�"��au~�ϓ�7�J�t4�ھ�dx��p�r�G*
 )��YD�Ye��D��<&�Pt�F�cBvs�@ū���Ž{�ls}j%��곻�b" !�6�ы)�9�EfI�:3���*�5J�H#����3��d Qꓥ�)ܺ�fE�$J+ڽ2�����Dε��m�2�M�$���?��{�Ѽ�6���-��neD "=��bk?n���25r?�xR����Ay�\*b[��g (�����ecuu�5=oЏ#�xmY^�S������ɼ�fT��.�%�-�
1����d�$;��F8j��W\5ic.����g��5K�+�&����b�*JvH)�VɎ�r���K�?kO��ϟ������(4ΐa��2�o��+�;J�Ϊ���r��^��W�N�±)`�#�Z!���A������	���q��G�����˺6��|# h.���ج��Y���g���(v}���x;H�ٯ��^z󱵥�5���M3,Ν��c'�>�yM�;�R��SQD���b�k= �1��l-;�"�a�Á$Ӆ�z6`��g!���e(-q��\�.��Ki/Z�4�pG����ut�����8�mvR_TD�V��7�aQè��y&�h:��[���rYGR�'�J�rS����z���΅#��HL�g��%�#�[|8�ì�tX��8�;���:��F<`�Ԯ5�$���GM���]�C;��8�R���&�K����0���N���,�L��P�{Tr��Id她-�I�;��BŸs�x*��?��)"{^�'�y�tD��K&��]([�*����C]Ȣ�;����k�o������Y��[��lbg ���1%+��ֲ���[���(WĜ�?��#,�F�'��I"�� ��!�mޱg����V��q�退�������{���Z� ��=�����*hM�J��Ȁ?��Q� ����;���6�E���5JJ���~=�wG1��u)kjaYOC��<:@����[:��TٍK���>�ia�(��]Az!�岫:t�_�n ���k���
=;s�R��|�	ՇQ_~Ç +mO8�%2֮/(ͳr��Fr	�q�8=�Nc�ж��~�8I~�#����[R�<"���^z�!qAڟ�GZUS]�r�h��!�>yϧ�f^Z�m�����<�c��l�4�]J������_\A?4�aۅ�ӓ �Q)�|dd�fz�[*D@D����U����FM=Pk����~�ʳ�^Ѷ��k|:g<�ܮ�ɺC�N�k;��V���࿶Zm,��[�R>��i�9N�~ ~k��=��ޠ�пӴ��m���7��H��.��$%�,.h�fw3u�=0�iJ�oׁñ��@��AO��t3nSU�瘛�;���٬�1���@wERjߥ6&w ��b0/"��,���ͩ3�ՆMM��[<�D���ΉrH�HO�%�o�edϷ�����E���DW0�xO�������`k�Ms��p �G�x;a����@-�G�(�2K���1��01��a���t��ѯ�1@�a�Y��=F!�7H.³ɾ��s�ý�O�Br2W&	�bꦗ��
�/hQ�շ�%�`u�ڣ�G	5&$�3�衍ceDZ��9]U��ULqAȢ�o$IN�����xe@�s�I�	&���0K$�ދ��]>�}�R�SI�J /��A�RƳ��ά�m����/9�O���!��E�F4�L���?�������M���{�r�_�)\G�ͤ�FQ>�#!�n@̾��[?8#�ા��"�<�I��ܿ/�# �R�:���?=�YY����T���ܴ_�K&��'~�̤!�j�5�m�~���I)i��;72lH�}	9U�������d����>�j����F.۽��*��s읞&���j�U��+�_�_[���*����5Ѣ�)1և�
W߱�~�}\��M�p��ԋ�/���M�.��^�L�B��g����R
�r�|�W&j�m&N�n�����b�n�6�]�B�6ݜ(���x��_dqxJ�;z��\�<M�8mZ�|��+��e�Ȱ��nZ��"_=i��i]m��@B���Hт~�/��K:x��2˲$�v�`V^<�Y��w���jtd�{k��\�D��Ue�ޖ���Cz������������޵�;�-�39�x�k�>YbF�V���~�C�U�QH�&v��{�-���[}n8xl7 ,�<A��|�>g^�S ��� ��''3��7c�_��$CE�si?���M��E���󘍙�֠��G��,�yM����`<��N��ҨJ�	8�Ŋ�1���2��&�����/�	�@������!D ��{��a�$}3�p{;6���v��꿋1���T��F[���"Yϊ�$��$�+�=��S�<	,�;|)��h�sM��
���p��2���}k�jװ'���{z�ӈ��n�������I�����! N=�;X��zu;����1}���y�9R��a��xZL@c=ֻp��^����K߰�-�[�����-%k?�A��[d�����s��CK ��W <�P��)*2��y�������[�MD�8����Í`���R��R�4��~��i$�$<�A�'��=�����$o7:�~p�8�iZ�����F�_��2�^	"�TBd��cA��y�@�z�K��l�ߡr�y�RPk���Mϗ�#�(�t8��fc/tg�-�3�"O-�Z�O6":q�!��T3�Cqv�k��C`E	�5���z�F��J��	���Ж{�b&%�d��pK�'�ꈐ�ʌ�>&&���s"�Y�ȱ�G&l6�dNSs[��?��͖p{���p��G6c�m_����5��~��ɨ����X.35?����9W�}!
SIK��4s5^���/�-�?�`�v�t֕g��{$D���9-����RT�:� �m@�Ou����d��g��1y�9ց!���.QWN�}�����&�;���i�$��b:<+�g�e�1�*U	7gOK���؎��"�dTWv���9Gs�2g���@�U�~���mIX��K��f�}g���4�؟T._�!n��,�l#0-���Y��g�2S+�+ڥf����*���Z$"#��DC�e>����3�����ʻ��ڃ ���r�`�Jlr��z4���.���(9��b�E��ޑUlq��6D8}�s{�Ul�"S��@�7{��//��w��Ixw�9v �BR�<+'"���@8��n����X烠18$���i����u�������>�x�aS���'I��=q�}8[DT�Z�x�y��m4�a2?ƥ�
�~�%RCpZ�B#7�@f%RR}3\�-����o�����v`$��ƫ/�[�K�/��&��R�UQ��]M%�Z�x�Y;G�����ON�W!P�,� y]�蕌ީ�J����<܉-��ݚ��[�H)���`9�A2w2�> ���G@�θ��s�R��]��"�� P�!��Ka�K!?<���V�R�T��D��j��]d���c)��E�q��T���t��(�4*����$��132_;����d�V���Wۃ<|^my�b0Q}r�:�
��q������,���+`�bwۓ�ñ�p����z]2χ�sR,�4U&Ϗ���s��}&�Rqnq�HTX�<����oñ=�De�A�eʡ��5��ԏN3�lO]��7��$A���4\�0�SA[q'q�x(������#�!(��c ���ɜ_�^���#�p��S����O&�������K�_�`�nydA��^7�Ɖ�ڏ#�ç,����u�|`���CY����Q�o�_#н�R���4K��V�2���\�c�	d�䚬'L�S�6F��"���35wzW�ų��������.z���(P�ȗQ��(M
|�s~C[�ݏ>=������jJ�D:T�G�"y��h�.R�9�y���lL���5R�����b�5zfy������8�Ȭ��_t#2ƴ�A��Cz�|X�RK��i6���j�Ȟ�a�{BmM��w\�C/>��6�U��`4��[4��`�i��ؤ�l#E!�/D���/�aL!�e��b����ӓdoG��1��TpV��U�nx;�I<�HJ�U8�*�F��b����N����L���|����aP��ɶ�I�	V'>�R�� Z�ԕ�hE��� z�\6J6]޽�f(Wl�b:ĭ냢�V���6�B���u��8��C4��p�H�Qa���R|�>C�8�G������P�F:����a�����{j0pu�i���m�YA�a�6I��4\q�ưR�[p�-�r����4�x�`	�ɘ���g}��P0ػGn-�#���I�1�Uȥ9����7���]�#��m�aVAN�`n2���c�9�?���)��'�k�͟�U-��6Si�u��%N�.7/˯%��Z7%�KE8�d�=��m�O�U�W)�d(�ϒ���^�����AJcJ��ٗ��VmU���v#=e`iRy��z�ei��z����B�%����0��@~緿�`�2@���h���t��@�t%�h��ƹ[�^v熟�$�^�X��^
<J!m3�>;�`)2>�H�dC�B>건ڨ��_V��j9H]��eW��3pb1��c:tX��FE'���o�ƛ�?r�S��Լ���D4)��<zQ����`�����jt���P["����!�܂e`��P���![7{�]�ף�[#�I)�����{�6J-�g��$}e;���71P�N�T�o�+�*'�2$�0x2��󁥹:5�|�]jc%�a�uCW�U�J�Z�D�y��J�.�9Z�����_��]ާ]m�98,a�O9�|���ᬀ������H�£�e�B_=��2�3%��D�?	ݐҀr�c���q�)T�0���s;ϛ�PFJ����y5�Mc�i c��	q��x���8�/,�5�%?w^&/�&d�Z�6�~UT�j��vt�և�b������9ܮ���yw�Q�-8�9�j��NM�5f�	1JǙ���nþz��q�䧢��������d�O�Y'"ZM�I�s���yP`5?Ưp/����a��}�8.w���0��v<�@u�:v����Ǭ]{�@��!;�ˈ�]`DlL4�'R��V�?�������N��Y�Lՠ�{�t�D>�)��|�
2�U�Lz�/�_�G�U�g���p5��:`mBvȂ��O0:�tt@���#�{C�.Y�RwO���A'�.#a꼻��o�D�˼���X�[?�x�9�3&�Ȳ�êK�1���O_R� �S|Nw��<P`ۦ�G�V� ��ߡ�����V9%:�8��|�&;�q��g���g=�&�U�%���Y�^��\�SK��$�5+�]������*h!#��h�a���Q�s�J�.�
�+%-�Q�����V����Y����&��$�sh��Q��9�m��;�t`�#8��%�;��d]n�-��~�R\U�
¦���U�՚�?�
U����Ȓ)����?��N�'��_Wr�"�����iw+���>д�+��ʖD#m����w8d���92�����t�/ހ.Olgݶ7�g:���B<B�N�%JRa�ƺA'P�����WK>�!��'�	��w�C��]�"3�!�7Қ���])Wf)�#�� +Zd 6�l<N�Г����	���1�_ -�+Ó͵&�3�{��zo�R30�>KzT/���%#��z�~���  ldzV�]Aƾ�%-��u��ԏ�׼OT��&pn�Av��H�g��/k�e�x
1�q�Qou�0rK�Y|�)�?r��g⹞rNyJ^VQG=s'�+q柑�?�U�e�$���!�R�w��y � ��UE�s��gȧ�56����ۦ�xG��;y��_�t�IM�����sg��~�l\Y0�_+ɿ��f�,,z6yE�`>h^��fog�1L	NH_���O@9���z���q�6�i|��8�c���y���p`)�#8q.Pbih�ݹ�&����-���B�� ��#:��T=D<�s�`~2)���F�D�b������=�&e�,�H�h��!�������O8lٱ��C"�8�o9�աR�2O4���#dU�e�q���Q95���yB������ϝ�9�,��,����.���HF�\`���9<�˙o&X|g��&����G&R��s*�]����<.��k��~P�t�ĕ��T�Y??��}-�d��j�, P�)�߭H�0��{����s�	������]��_�cǈ�x�p�$�s����K
�>�3ꖵ��N"���� <��O����W�<~��&���zw�t	��J�=Eϧ��\�ŋ^�y;�>�l��~bDĮ�:���T�?M�z{$��M�D��'�A�ZTm>�~O�s�"}�����-�F�@�I��d8T��ۦ� �V�g�x�e�H�oᝍ�M���k������r�>����8&7�Y�)�*���h)K�f��Ř|�5wL�����0�*5�̡�G�O�l[�O
Ms���f��Nl��b5����	�"�/���	��<F����hyvb�b[�By�F/+n�7+o���9���_�|�S% l>���T��F��c�4ln9k�֙�<ɽ��5��X�ݽ*�q�����i*?�j�xfŰ27���q-��ʲ�*� �rtԣ�Q|��N�:N��<�&b�g�M�n���8-�7q"^�/AC���&G�$�s���3�x��&ͧ�D!7��]*>�c!~�G �}��t�^<a
�2�V:�y���}���	��W	�l � ��6�����+�
 �DAZ��89�;tI��f��V���I�x(kh�r���wTl����\��}^2\5�.���_�/�E2�Wl�kTE� ��,�Ź�R$O�1�4�1�_�5��p]���U��]kF�4�A��/�4�:Bmt�����f�Q������������c��XغN�����%a�1e��H|C�P&��$S�i4�֖�)Ƈpn*�PʙSsdD�3�G5�u	�G���2s��(�J{�)Z�!K���WY���<8Sl�⢸AG����>
I��}6s����i�AC������J؆�_$��iήa^��M�<��d�?��z��*�l	bO��ED;��`��B�K�YqB�L�+@&f�|&l���/���y����A�҉O͙}��s��+C�t�З�J�~O�$N_X{P�(��V���K�^q��i�Li/Ą�M�<����"�9�nq�3N��]�+�� �Zg���{ecW��M�jI��e'c�9��R�t�\LB�զ�K�,�ߗS8�!h�s�'#>�B��M�Qa[`�BJ�aeQ�o�p2P���¼&�O���C2w�*���E]9�A��<5xzB?��a��|�1C�@��r�|)���Jz)�&�5�yٍ��|(�4��ߒ�dЏ����5���uP�|TG���O2�L�|������>�O�� L�E�h�rKA��C�ʶ��oئqCQ���{`x�G�#ȇ!�lJn��#�D�J���
>X�S�w1���NP�^�7����no�*vf�R��@�+�]č��e뱼�=��Q7|�}ͥ���ҹ^�����i<�ĶUJ&j��	M�5�5d�2_v6W-7G�ʘ��0�iS֪�h�M͛c��V׺�V���d����f.JGFˇMJ/�5X�b�������4���f�>��6n�;c��z�4���Y� �ܭ�i?�>��>��o����K�y�	%�Id(��p���cJν~������k�ud17���LXN��րŕ�+2q(�\2���/�+��"Vr����~�V���O0
���酬	����Ll������l�.���au��͕C)�(@{_�^��!/tp�q�ǋ��m99�&�L�B�Ô'�# �}�������ڵ$��}�����q`0΀jds)���_��^�J�a�R(�eK0�XD�M��:���FQ+��]��!bCPi��ڥ ��ea.9�v�n�5��.�)�:��Y�D����"2��>{�#օ����j�W-0�T蕌,�N�ٷ^H�r)�8k�,�U�
�3�H+d��d�٦�j�q?�E'N�d�M�֑#D|��
�kDV����d�DG�Ѐ�|�wψ�[�X�W2qUdD�q�!~L���i�:76�2|6�L����Q��! ���p�*�P��}�Q�χ�ꬵ*�ˍ8;�/%a0�[�M�y=i_r���P�7�dM�`b0F�yK����Q�bb�J������?b���!�w���i��ו��ԑ�X��Wt��>����s"�z���9�t>W�2�h^���u�I�I���)݉��;��j;}��;�-\5G�SI�Z��^hR^'O��7�q �ޥ��܋�8�8B�F-<�_��.=��濻m�w%�z�ds��~vc*�ޭ���p�!(䭉K@���LA�)~���<ؙ���T����=�6�db�6�����cx[��H�"���o�I�v�����i���e�ǿ��c!�w���ޓ�����j2��)��F���@9d�`t�rn�=���e�����"-C��^�n����kM�@s��J�`"10��f`�Rn�V�M�e���.p���v�b
]��)�
д�+�Ӵ��A�� V�� ~���{u׉cϾ��9�B��s�4��t��\fy�5�i=~�A�*(#��nn�_��5��X���Vq�GM��� Rګ�σk��vu����rm�3=:K���}����6�C��f�x�I_Ɲ+ͥ�l�u���n�o��pc��#�j��k�*����d���ΔB&ض��3�[�4`114�p�*�(�ݶ�^�tB�r*������1��a���x��W'�*��&�"����V���Z��]�0챭���A}��i��͕g�d�+�=�0H͡�������f�5�e��z4�b�L��+�g���k���\i�8m�E��7:�_����ed�^b�To��=�#4�5uJ���z�T4(Hݤ�4;:����4zh?��`����QӄȌ� �ٺ�G��M���-�	��_,��l=����0mv3|0ͥ�)zbw&����d+<$5w��X'�{�����$&aD�[� ��x�L�FJ*"I��W�^�$���e�S-�e����,?���|�|x�h�>��yv�5ۂ��L��ؽ�k}�;N^�����ʉU�R�g��/�>]q�W,I����l�v�����9wKv�D�5���Ό�;����ӰR�'PM��%�t�h�(V�_�I�U��h?�hl��na���ϰn�m>2��	��-�y��ǘ]cR6��ϯ���"���y��K�ǲe�f�������i�J��P�6��9��h��\�˳}ʝabfe�ab�`�o�6"��z�ÔG�Y^�N
s��hP��՘��:pg�9���ξ��1�o^1�kn�3 �~Mr�����Aոh� ���B �X7���=���i$v��5݊�D$'7�(���+����w�*���<�ػ�����ki�d�(��<�,��I-*�.�VO<�%䠔H:آ-gó6í�wb��0n4p��bBi9���wR�����X�@�)&�LK�BP7N���%j�Ѣ�R��9��1�=K���i��|�0������p(�!��q��k[#���[f�m��'>�c�/��ƽ������Ih�1�o��{K�!D�ߎ���tFI���=t���0�|�����l���i�Oʣz:M�Sl�5�� ��-�L�n��5R���{��>T�U��)CN�D7�I��q]*�qJ���(K��0�u_M�)d&/��]�>f�CG�1�{i� �;YArK���ؤ�4wվ�>C従��Mx1Ɔ�R��e����un��=�E�E�mg��&�j]MzQ�N�\F���٤r����W��e��� 0QDN��!���
���y�x���vBLLr�+5�~�(L�N�}����Iu:#�̘�@�]�<�+Ti�z�J(�s��I+E�C�����1s��&Vj�q]��e�J��lI:�E����O�؉N��$����wT�`�)[߾H��͂�r�uc���JA�8�H;[���˗�h]��@؍��?��½]��x�l����*تO�-�L�n�wI%��1�G��N��7����G��>�C��0k������F��8��3�4?O��7T��%eR���tNUT'σ=��q�M��VeP	�EFR�r�ں#q]%eh)q��@Z��`|A�[d��\�c�UT�� �Ȃ����y�u�p�Wn���u��:h��f2��t輙!|N��D�j�j��)$��d	^uAaCuy���wxeͩ?�_-aE�ߕ5������7�z���h�"���J�������*Ze��X|����솶�w�8��_�J�wP�$�J(/�kOi�ڲg��-��骹��§G�x��*�u7h�#jHR��x�]�E�����g��� �A��i�W��� ���{���HR�TU����4>����kی1����}�ߵO n��W�L�-��u���Ul�W��B#H��	j�t�b�D�5�%d�jK�����*,8w3���ĭ�~�U�Jo���L�u-#����P��b[�n�1!��ڕ�s�Z� ���x���xS��]6c%����K*/
�x~.TG���?x�}5h�k^$�h�g0�m _:�9� �1"���,d*T�������:�j�5j����L�����V�>�s�w�r� ���Ņ<��r��n��I;���(��6'm�j��&���R�e��=(�&�Ō�Ù���M���:P��#�ʚ���ɞ�ο_��l_s����C�n�e��U��~6!j��G� �����ә6�O�w0��I+O�H80+@Ƹ�]���XY�%��gb�f:Rs�Q���jiw������� �Pf����cr|�q>
'�T��H=r�`Y<�~<Ȗ�2����?����.�=��*���jP=u� �68bX/��mp��ֽ��8≝�5����Z��N��ρ�oG��k#7�g��+,���:��(��0��U*�D|T)�t���J�ZxҀ��&՝��ިY%�:���y�271����i��2��-eވ�Dd�͡���Ǩ����q�\NϪ���r�t~E�F���C9���kN�ko�T���^���'ZQ$�i#J+ ��:[¥,����w�gXD�@�1"�L�kAR�o߀�r|���b,@��X��v'-KuP\��E��VK���0N�%j��x��E�����|��F�Si�!�a�'�%n:h�{�>��\x?��.X,Y[C엗J��E��@�\=s��*-70f�[cp?�#�i���Zu�U����:=9�׳�v���tӇM���
����`���34B�����8fy��W�Q�
�=ע��UOQK|fS&��|P�a7i��Y��_���S�����*�h����ah��=3% WD���������3�6�Sm���f�.��Y���S��+YK��)�-��6�B��I�ˊ�A��\��
��1�A�.�J"��~�lv�VB�z�]<�E�ϱ�pөe]ަ�w�&���#(7��I�<���!�\9�m�R�"*����x�ƑT���Y�������	(�M1(�7�vg�����Jx�nP��ɍH辷��
����ocEa8�P��\xD�6�1��e��%�l�_Pl>������Ada�<EVp��w�&Y�+ �l�B0����k�����2@�E�!��Z�׍w�\q�2z�%�� �Z������#�KddbKt�lƪ49�K}| mpa䱇ūeПH���Sހ��A��(���@�f���Tj�.(��Ȕ����w��Ea��S��tojd����Y �pj�0�;��fŭ����f%R�N�����a16�5�'��P�-�LmP7���n0�ɱ"��ˆ�Xt���]���f:�Ŝ�[��k�W	" Cd)U2Ǹ @���Z\�;
�hpk�C5<��(>���۫(�$ <T߉�>���;�.(� ����R���`f��˟�w��,�oX\��~eÞr`�4��:�����ꆙ�
\-je������Ʒv/��-*�{�����'Q̡?Z8�H��S{��ڦk�*(����o�;�P@��V�{U	�5��,�At��D��S�p�˨ɜ{x��!�}�ߒ���+���(�Ě1?&w���zudf]"����A�U1��G�N��?bP���^�ŌR����G��c��1�Qa����.�Q�M"�	����(�L9����R�$�>�.wa+����1��T���N1�*�$�Z���D��{+)d���n�7��P"�4kb�`�&���a��Wi�6ޠBn���MW�l"Xc��V�	���Ζ�#]�6c:5����=��5A� ��)��Tn~�^ �ΰ=���w���9f���D��Y�s�;#~�u\B��5g�>�k���#�����Ff/��K�k������'{��2�c�\k��Gߛ�#� �&���%�L 4�et�?�,�Q�F�ij���1��T�m�{��abj��|>�2�sGQ1��������G̊��Nz�܄?E����<�i����fs;��=}��q2m����8��9{+j:� \��`���R#G-��I�UEE�o>k���$�HZ?䖆�FH��n=��ڕ᎚ �h��n="��6��C�Qy���,ii\b?����M���l�r�m紑"X�#�J$�]s��h����q����MT0�!�A�y��m�p`�U�Y��䑤�	`�!ݖ.���]�+�^,�5eq���� �J۟�E�)7��t�H�B�RR͊7�d�"Ŕx�u��R=َw�FW����2h ��o���Y_g�J	r�b�x�T��<Ϭ^�ܚ԰���O�x�c��!c1�Ql%p.�u"sQd�<�~��Y�QiI��`]#V�诸s�s���M��_����I,��{/����m-/�dz��xv2K��7'��|?D�z��2�b��%J�
�:����L@c߳����3��\M]c�<�6e�soC�ܵ0W��&�*
���Z��[���Νڼ�#DQ��݂�FcV`��d:+�,����ږ��U��(\Y.6����XT����L��`�3J�)��*�+�-��V^���{��U[��@��H ���_ �)[����:'���V��kXwZ�zLpqg���N���ݍ]��?�	/鎬�����L{)Tߣ���3����Z��k���&]�j���Ġ[:Aʱxn-m���.jQ��jQ�գw�E��P��{��9h���qf��b��ZT��C�ڻs�H-0�J��ET�M~\��l��-�N&¾F�
M����;�:Ŗ��L��e��y2���b�'�8��)Z���Bh��8պ���)���ZZ�����.Gɫ�q���){ΰ��l�痑�5�r��1?&�J1���U� ��S�|�y�[��v��R�:����2�!�������:|�ט(,�H`� #G䆢�����d�����>�,d���@t&�7���0���@s���0����!��!	A��Bm�<ߊ�n�v&��gp]0��Hg�݊|�"]i@0���B���H�@ࡵ�ڈ��~�ja�f�^0#��J��&��DL��,����M�7�Q�O�Վ_��.Vժ�L~pER�{!�)���� ��:�Z�C6�X,5jz -�>!p���+rabuؿ�,��9�L4��EHr�b�3nqn�:���&g�_B�3�`��[UcE��l#�ɉ�M���>\���ڪ�~�G"uv���S,����Ӌ�3�Qތ('�ގ8ĵ�`�4�7�>����e���4��gF�ɖ�E��Ex8���EL�`���R:�'&Cu�/[j����#����X���L���z�¿5y�,[�F,��2r5�h����i����f�l�bn R�!�5����iqO�2�z¤�W�+�$���0z����i"�jf����(�1��x�?�gL�� ��P��Z�6\tn�[0��@�lB����7�ʃ�nL�*�6s�xn5�5�2���բ�o�Oˆ�F�4���y���Нˆ+�['>0$���a�a#X�����UÇT�>��{5�v?H��8r_*�
�[��ԄW�1����'c#L�Y������4X�d�#��ga2�ٚu�B��}�M�8�h�X֠e�m�a�� ���?̬_(��V�,*�������&^�G	��ǌZ���Wq]�Y��3�]�Wj���i0p�D�,��R(+�a�PBq/WbͰ������Y��$\�.�(n|���x}�m�xv��M��;^�'H�ë�^wJO9Y=[��	��e��1����1D��&x;�P�&��P��hݿ��1��p<ŗ���VC�jx��}^5��"�u$9]��ͼ5/��������lA���ʮj@������v�
u_�N�&����kwL�g��v��ߊ�~,$�tt��Zv�i���9�E�[�-����2��>N�)HLH�|d7��`�/�ܸ.�J�"A�FȂ	��h��ȃ
���; �Y'��;�4 �m�|�D� �� ��\FfdQ
k�UZ�8�S�E�Rw�C���ґ֦�`���o��(�� �v��#F6���o�ȉ*&�s>��9��Z��~i9tț�?�{�~r:�<���>�V���}�ć�l{s Ѷ��6��!�}�)���J�Q0v�c�'iS��c�	���?�
>�<,�UzI��9MX$D&��?��;bA1�+�W\yry.����n�f��ٖc%�a̼��>�G��l�����X��]o�?	l1����>(�:�pv&�� ��<��fh��u>L:�Pa��M�h��msWi��r`Cs��j%��O�,�B�bi@���P�ɞ�#��y�<��h�{��&yu����7βF����V���$d�3��:��|9�{̅��a! �S��d�t��eO�Ʂt#���G���J�-oL��4k��U�[�]�b�t�п�Z�*�l�����n"�W5��dB	t�'�^<�s�B�����J��9��g��p��j7�UK(��t�w���������ℜ� ��(G��������viX���rg���__��BT���3��5�k�y���(f��,��Bu~p�~�=	�R
�.M4��|� {˞�!�^0�!�,[��h�BZߗ��5�.���(	��G!~%���B�ˬW}QC��\Ur�)�Q�?���o�qU���rs�`�׳����$�$�U�e��2|')>�>�}�9���f4?�UC-X�y["8�y�>�i�Q��-f$͵n�"o� �?�������1�����S�[)O�ߋ���ۚ1i���os�B��}�$�8���2�����)n�Ϡ�F��_ԓp�j����w�;��mG��ݞ��u�~�y!��Cry�M�➓S�]n&�o_8���X��p�Z�"��Q�e��;]@Y��#=��=�����s\\�nĚ�$�ҏ|٪�Y�,�?��b��K��/�'%^�w��]�ө!�>ރ���3��D���3�V͞�w�?z4I<��H:`�0!��������G�&�UM
�Ak�b֒����mT��O����p�#�?�Z��mgX�W�9��K0{�,����"���e!}��&&o|wg�˻�Ѕxb 
�\v�~.�q�*co,��:ã6a0����E7�0�Dk��*�]� �o=�0�z)�������'X,�ݼ)m(z�2�Z�l��p9�ٙ��Y�a���WP��\�g�JM�2�؄�1E�*%7�[PZ�5��9��L��ȝ���<���YUd�@�!�8[�,6m�V����0�Ⱦ�3��g>��T�j� ��{�Ĩ�$��GS\�`0     φ����	� �����o粱�g�    YZ