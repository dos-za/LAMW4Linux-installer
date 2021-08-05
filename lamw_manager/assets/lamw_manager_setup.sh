#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3012940917"
MD5="cafd9fc3587871c9b07256f465718e4f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23640"
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
	echo Date of packaging: Thu Aug  5 04:15:01 -03 2021
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
�7zXZ  �ִF !   �X����\] �}��1Dd]����P�t�D����*���hv&KГA�f͸){�+D��Ϛ`��q��+��N �|���Ϸ�o$4ޭ��v��ED'ȨV�H�h���\~E�WR!��>&J��	�a�_}Y�zn=�Ҽ7Y�w����UK���`�?í!'�{�����͝~���3���RA����܃�֞E�K���.�Jo��u��{(L�ͨ���ʴ5��Y;o�v�y�@����%q�(㧙�ȳ^}��EV�MH�/t3��5$F[����槬��_�|��W�&�P*���d��b�ز���F	�o��[�gi�Nz%mA�?��T�
5\�fo @�_�?q2`nː�*�T�B$��o�����f���/ȆB�w[�_'[���ױ�[5�!�J�^�HF<iT��{�"�N����7�T�̶6�ܹN%�h������'�x߃=��2F~8&��ۺcu�'�t�f�WL��~��u�S�<�W_9�7�Ra,��Ge���s�x( a}�V�J�9o�К.��'n��۱G��6���W�a��z �ļ�;�w�M�gC�`��
f�r����7�Ց�����0�]�‥�������GȽ������X�I���1B�d�ݚԡ��C���]W$��g �o���#�H������M���(+���Ł�����# ��R�.������F�lkE��F��堉j��#�z���ͬ�fUƕ�i��@b�鯻�b��V QZ1��Z����=���	a�L��cEoVn8F�-E�t���}���������L�:�a��rB�ƍ�4a� Ƹ��z�g����V#��@a�"���i��,��<�s��@�h�bR�ʅ����"Sp���`�}2T��Y�e�u�����$��h�v<Dh2Wwem����`���B`)�#�O�2����rX��7Us��O��0��Fч��tO�~ڿ�� �nd�Yv���H�&�Biqoȥ�'ly|�J'�j�食X���
X{�UC��Ϊ�5����1�o���L�]�Zi��F����ul�-�*��oj���y��C!�k����SU���з~R�|�$+V����Z� ��=�ݔ̋� ݡcC�N$~7"�Q��j0�#�k�?���j�'|nQ+ߖz�x�(B�ʤ�MI����Rg��a��P����QǍ�^�\m3�<��
:)�j��n���9E��q#6@�i�V�W�cӠ"�;�h��l�R!��Jy �q�v�������o,X�ࠅ2!E$����CE �*3��������63���Z�T|`Q�R�K
<��5r����L!w��`�6�l�-!�v�Q�/��_D`hs����X����g3e0?�m��q��ݴ;�?���h}즠��ҧ��54��L�^���'�M��7<�:.���*R{�[�2q->���#�_J�����47� �(�m�B��zC٥�I�f_z%���<�i�r�����7a���fD�Y��V�=�l�.�`Fk!�uD2�!�R�;7%T�cJU8�&֫�r��x��?��ހ>���KGB�7��T��?FB��%^3�QU��e�[���p�}����#���?�S��]���b��=�ɳĳNdto~`F�[I3���ϖ�s��A@�LM��G�)�q��Hn0[K��j��h5EPo4����8+}��7�������s���wx�x�oLa��d��,ҋ{������ʆX��N��y�g��f���K~���'-��$����:�˦��̐ivk�qq�S�ar� ᷥK~ۭRO�m*���g��+�v���;$�3TG�'�D��17��1��rM�Ɍ�z�8~\�x�Kv�ϵ��r0�w&���B�Ļ�R5Fb�-�ː#i��:^�^�"Zԩ�b$_�T��T��p4��/*o�u�^@6b��������gp+Aρa@�!��9&�8�,Y�����D��<;D�h6�i�R����aA3�w K]$Sj�`�c���vh�� 2�����϶�J�A���b!L� �d����ߏA98�G�0Y}�ӯ� ���V<�d���H�/��ԸEA����`������#�(k�;������;s�*	&���6� Vd�i�)�T�ժN�@��L�������uQO���]�,yݲ~��uc��n�Rb�,�o�*��/6䆢gR���@0�z����5��5|$}M���*a\ݕ,��1���|�i���@�m��-�P�g7�|m�È��a�1�o�<�Q�{�K�7�RP��=C�S�̵�!d�P8̴�E�w����F;������@l�Z����u3��N��W&��$�����උЭ#B��
�Ri�94������:C��R���ZGI��s�y�f��}�ǁn���}8t�w鮩x�%%�mc�3Ө9$YT�z�61�+CLp��̳ĖX���hEo�Xi`�$�W�N��l�>�=+�Z��r����gO�qħXn����殪M��?�5���3�Q���ośb=F���`[~���ժg����!gY�a�l��G:�����DE��8woI;����/0�P��&+�)(�Dw\��|�̙!����`!�(@wc�b�4�<H�!�	t@�be��>���5�yQ'#���Mh�dO�� |�w�v���9a}�s���D�y8�#*��O����i&��5j�/\�5}�|t_-��$Ә=x��O93��e�9k.�e�����(@#)�!���ӨB%F��\���àLc���w�7�L�{B: �%TU����Ps���b��䃁��F�\v��1����4�A�)ܑn.�K�xۨ0���;O^|*?hI*C���U
�V�%���W`����zB�x�yq�:/@[��ٸd�s-	� q�Z��-��
�j�b]��^��zu������X(�)a>�C������â��G1�n3����R���p�,�ۊ)��m���;����U��L�s85FX���׏�ba_�B�[.u�՟v��D0=�xI� 4I��o����w0�(���R���=���X��6���]��zɒ�U���g�����N�x1�L#��R������J��K"����)�ݑ�����ajT0n!�c�髩4r�<�T�u�=�
� ��XR��>q�%H�@0��(y�%����S;t�Ót�^A!��l� _�`����6�S\r�!aU'��<T����"��߀Ԏ��X0Śű5"V��rT�s �x=��4܄�&@�^/pth���}«e(�8�l��� ��D(�j������.lU��wq����3��htzv�4y�zGz��"L���6bۓ ��!���j�ב�s��s��)���Ǣ�U6jv`N��`XHt��JW��G-��=ل{�n�?L�����������Z)�����8����K�i�KE+���Q��veO�5���{d(�PC���*�q�Z���מ~�̖6+ө�ׁ�?�wڬٗ��������h��
wm�m��Ih�C�����i��!eRU,��~���m���0|��ϊf���t�#D1 ���1¦�R�1aZ�������&�����؀�U$�u�0�!$
�ʇùrd�O�%��$Ć��~���9�h�6L�ÎU�����jxѶ�MVr�ɫBbPܪ]�ϓ*����JVM���l�V�1׌T��l^��]�3�����pD�hPU(Z��_5�'�	<r���:��{�v^ދ��bV���:��j>���I,�)�ذ=c;���btۋ�W�l �Ռ*I���K�xR	�hR��{6'���_�{�˽��=V��3�����Ӻ	$$�w�E�L��)��u�&����.� ��>�>�a�)_���}j�=�T.s�T��,8�lT�@Ga�,o�p������"=N����H��j�t����z'�q}�z�`2�Zl���'��}�ta�u9���lX9�G`*<�itW�Gz6K^�w1>1WǤ�����������C�ٗ�4e�%�o�(p-]���i��){1t
$Js����B��<� םw�}�Noq�q���}2��]��u� G��c�G�N/E�d�iȎq�;̥.�$��A�t��A!����F�OTV=4Δ��Aw�Ϙy�2sF�n�&oȼ���E#[L�*�JD�Q[��4Ō����h�J�:=pA���dh� ��5�ؾC����綛�@��i�E����}��|Ч��JIz=l�����.���� �^NJ���C�VN�_���i��^f���Wr��r�\��n�R2:T;е}�^0 ������� �$f�6��{�P������>��q�~��7�:]S2��W���`���<݈Er�>�f�|��7c*���S��v^&�LF6/4�~,�8t�-R��-����x��F	�����WkZ\5�<��8�� �/ &-���s9%n�a�r��Ye�k`Þ�<-Z�`�I�.�jzr��,Dz$ß9�?Ow�E�eSYu,)��hb��m��c��J�+��6���`ˊ��-�P䁿ōf%YdP��6r���Z�W�:��_���,�9�? %jJĩ��԰�ٟ:��J9�w�vEc{�d�B>����
�|����nn"Q��!�d�7�"��ٖ�s�oo���;-�N��OR�V�qX=\��z��$$������3�)�ŗOS�4��1b����2)?��0\e�O��<]=&/u�5x�ϳ�tq5'[�(�KX�BwOP�s������Mk�[*��"Sub�+����Y襳Z>���u�7�.�qAŉܯ�
�����z,_7}x��A�l��I,�+C:�\�oA�Ħ�k�`�Ѿ<!j�N_獎�k�K$�2��`g�c�?Μȡ&�m�/�S�F����،C5�	/�a\�*L�I�yF�=2���]�1E7r-�=Ll�YϮ*Sn���0'�ϑJs^n�+�Ȉ4~�./�wʹ��2t��:jb`���� �AS����j0�K`�`*̜�!�6�^�}A���30@CO��l�7�c}����F]\w��;��_�C���k1���79�,0?�X8?p˾wCb�hڴ'L�S��aKݖBv"��sJ<��t��� ��dJ<:��v��Z^u��ޮ4���4IZ�Z4u�<���T�6�Y��i:]��F�
����jJ�~���i�Z�%��(2�F؈�N��3N��|��GD�.�8 ���[��'��bޱt{B{H+v�E���ðBt��'E��\O�j�sEFo���RV�5��^g��A����vct�"�:W�n��"���⦑Iãg�4����/8ձ`f�X=I(ԇ�e+��0�MN���R� �g�j?���G�P	��4��U�Q;_.d�>y^l����)�r��/�qܭ��H�ȕb�Dv���ڼ���<���vi����{L��&�kųwH�����:v"5��Ǧ\��_�W�Ӆ]f��Ո��]?�k-ۨ�Q�r�³o�l�(�D��iǛ� ��o4r�*��C��P%	�)����Pz8A<���s]��l؍%/+��/tu闭EJ�Y����(�1�#sl�"#���P}��L+��ؔI�*��iד���eP-�p|^�"һ?
�PM��j�r��J�>/6.�M�
��Q�)��n�#���:�2���G@^{�()�?�tl�8pj�(�D�4<|�����Y}��(`��Rxs	����ؾ�9++�i�Z�A��j��LO`k�%���ې�""�����(��yc�ߵ*��t�F�ݞ��?٭�<3m�aye��J�ǰr:得�����*
��|�� ���E�Aq�1�/�n�r8�2�'"�8ʞ��,9�ۉ1g�K�ǣ����O}PM@ ��c�qѫ|+��pK���R���e��ϩ+D4 .Ύ��V0?26�oI_��*���e?��-��3mQ�n�ҝ'!b�vs/�c�|\C	sB�����/�}2�)�1\�ȕ���C,M���$^BPt�c�V��0�ccd� d��)W0�����l���X=CoG<���l�ab+C������e6�Z�/�'����q"]�=���pO�����f�{Z^�[A��Җ���3�(�lnG��09eq��e��[��S$t]���7�i}2���AaZ���(f�?	 � ���5M��$�r%'�Hu�EPNn���e㳭��(q~��*�	�� B�@(V���i�RVJ��8�-.}�/�)��:�|ׂc#e��,7{��g7P�*-��#�{����w+E�0��Y��uI.�[��L���+�|?�%�wܳ׸~��!q�I����Bwљ�G�ox�-��!R�=��T��O��Q��OoAV��eL�=�}�\��8�zS�[@��*�u��,��O�_���c��|1��3�K�.}�+%�����Xu�{5'<Ƨ;����&�V��]��A�)�?��N�+�b�M���B�d�k�m�3&X^�m�����0��~��=l�8�1�H)ؚ-%M��w� �3�?�9ϠU$f'`M��ӊۃ���j�4\�7�>3MY�p���"akrRjɟ��o�2�k]���Ht�I}E�z�ȱ���+4!�]��J)�)�7��C�F��;�!���w�f��wz;<{�������%���8�`�D2\�C*!��B�I�m^s'`����@�B$����c�L���w��T_��o�/�(��S/E9��TThc�w�UL,8G�ma���|BWv4s���t0�Ow��C�C0�tDBk���-�׭������y��������[9ew�Xx�G���BO3<��,k_�5تF����9��B�BO'�Oo#]��sD�4�p�p����䈫�*5jfz�Fm]�1��b-��K�s�)�*:&�8d�'�~�u��mz���ݕ�F' �@�j��GF��>��lt�~�x��딒�Rb�ͽ��;�H�$�Z|�.��uV[b�����_3��fg�>�ƞ?��5uzDV�0Ң�'��|{��Tx事��,>�ח%z���k:�eG7>iR"���v��rd�5=�Ix�����V�PF`$��=�@
�@I��܊�P!	���=�����V��`���fR��΢ַ���!T�ǚWk��;�%|$Дj��%!�H�^9����Ո���~�����S�hD��o+Y��U{RR�����/�6��@��9���C�I))��A����QM�e��HL>Uؾ��=X����+�O::ڹǨ�u�p���%�?�����%�[��W������%�rl��-D��Y ����3M 3k�$�@[��G��`� ����d0�%��5�Eg���J@����L~ {�	 ]��:#�4���c��,���eRa�>=>Yl�T��&e�k	
�C�n|�UH��^�M��uM�E�ՙ���v�m��Ø��t*�U�e���V.�[hs��eU[�pW�0��ғ���l�p����y>Ƭ�W}�@��!`�\v�o�� ����n�1��K-}Y���\"x��]
�&^��q�(�p�a.��M�m���y��a4��(�������x��M\n;{(;�Q�7�
�:��֊�Y��lt-�e�n?��C��:�_�736�(SAL$.�U�Qw�[M����od���OSa~�&U�f-��+��z�V�Mn�u�O5������iZ��3�)w��/�Zǵ�O,J��>J�ꤎ�x��[+�jJا$����n���a��e�u�@�ݱ�03�<{�`U�9��Y��-�wR(�����@mH]��U��OL,���?��&_-5�
���(��H�]p�4�i�8�j$��Mt����������Ys��7����8����D6�����,�
�sH+�����ui�3���k��c!w����u���L������K��G#��D��J��{0|��ʊVfҶ�D��|W�̹՗����# ��T*+s��}Q���m�A�s���a#Z S昭QR�d	�r�r~8�[�+�u)!�
�"^�)���,�r��ߊ�㳷����?w�"�c(O:A����,`p�y����Y�u�㾍��\{,�	Ksi+�ރ@���tNż^m�.����F#��_/�%���F���Uv?���q��Ȁ����U�u�9���SV���"W�D��o��2�|\���xL���f���]�ց�C�|���$t�0�GχPPNmRr\je繲"���G3v�/���� .�ʰ_�F7�)�s*N� �͆E���C(Ϊ���,`rT)Z�/�+^��+B��~"���<���M2���d+]'d�In
 �8Vw�R������%l��D�_DX�/)�`����8�4A(g� �G���!fS'/�V�g���*] 0��6��Y�p_T���� �b=M���ΛftX�TK%�6� &W��?��z�QZ�ffѺ���A"�Xn.G���/��B���z�U�Ӝ�;�Yw+H ��p�<i9���w ��z�8�^4�1z��7 \݌� �-�_m99	��p�iy<r�M���M�Ǚ��P�\��&��f�8�PR�<�}ی�� ݅�dl.�F듨L�I꒵��s�x��g�ǻ�w�yN�|f��]  ��m!?�����Ys>>%@�����:I��[�\m��]�+s�X���y�K��A�$��}��ڵ-�*��_�cx �y��2U�sǬ��	�ews��I����*�۞B"�x�+ǲ��/΀�%�1)Ce��/g.�*i��rCa�A�_�UE�B�B'�<�:�0"6^]�pE,�2�@�E��7�*2�dJ�B�ඹV�<��:���EÙe��՚:���~P0��;#Ch��SA�^�.��:�Q"d"�ǈ�]d���,tב*<�u|��?!���$��h���-t��e���!AsA�����KN�;`���͚dv
+|�q*�փFsV�!��]�_/��ex��I(e�U�i��|�x*��<T�M�w,G����W�7���%���0 ��H�Ϩy
�Ͷ�YE�]���:��I�Y,���i<%�S�o���!�Q����n����eJa�ng?�������gM������=�17@{�'<���d�z�Mh�jHk����w���%�z�pU�W���������xF��`5��=�8�WJ����yX��=4{C<n,��Zx>��5�S��� �63�6^���4�EØNޚ�1�l$�͑�!�?�D��Ʒ�R��풿0���'��a�������j�}�T�30J������<�n
PzJ��ު=�	�{UZ3�IE���Os���9��=.�/��R�.|FVcÏ#�x�<צ�؁4������FE���t��4�\.�	��HJ<"��P%"��U�D��$�����F�s|T�'r����_;g�^��1h�"�C�����*�6I_A��N�@�!Uǎ�;�����ƨyF��D���Zx'+�X��z��M�3��B�W��c޵5�yݐ��ie�w9��\��X�HoUC���W)��'�uY}#�lRm�;��<
Z�D�
�w��25�wy�\�"��jЅTG�)%YY;�D��|O�F�-ڄ���w�b�؎�)��m��v�Nx�z �y|-�NE��xPO��ŌTrc��G�������а�#e��T��A�> ��ҽ"w�`1;��@���l�(j�~��=KuLX�hug���hm����-��ޘ�K�sEk�h-��:�(ﴩ�!�DẄ́O�FtN�ѧ����
�4
���s��)A[�}��pѸ��F���_`��D_I����\������bJ]Y����V��Ѭd�z F�&�(��$ta������Y]B ��`xZ�4B<������b��>�$�rBUO���pE�JV��^ �̵����Q3�ߵ�,^bQ+���Mpe����G��8$쭹2e�h��v7�֧l��p����1}�fq=��
��}R*�O�w���#�o�>�6;D��NY�'���ڇZwH��b�O|>ʼ�Zt�~����&�І�5n[��eO�6t��a�H敥)��i�ɦ�xm�)|�N�T�h�weh4��wÜ}{�MP=��p��#	M��;����m[�N��Ӳiù:�?�r�U��2wם���i�E�O��?���;��A�<epK����>�},ț�=8ߤWX�ґ�c��k3���3���*��D?r����y�:�&���>l��;�h����b!/�N�G���A/H_l�OZ�B3��)�b��z�K���al�O�<zA�I���sޏs8Q�9�Jǐ}�y��O���c�rk�0�yM�A� ɂ�,���̯���3���8�̴�\hd��2���W���ؒ���.�3�޵�M���� �Z8{���>����"��
'����)[�	��_�&��b�����D�J!��e2��7R_���  ��h��DT:>�p��J�Xz�So��n,m� p�(�U%&�`1ҵ p`����Oc��P��_�%����v��J�����P�:)��0s>��},Q)�[�����/^�f���N��ΝUs��uU�9�**q�����i�$߮�V����B�i�z�w#e���|��s �߉���%����it6WQ�!���E ��jݯ3["�x���-I�w(k��t���^�B�㳥���Պ��3}�)(�UC�a�$*�~��Bx�N���C�2VɉET�z�l���/f��bE���&�r�������JF���޾r��.w?�_�|��NN�E�3��(�~r,��q浀\��lt�=���i0 ��2���Y�{�q(Z��(��6o�{,�;:��!+�!�M��.h��.oaMC����ј%VQs�}�ezDf�E?G׾�5���<Us!2�^h�zV����y"J��:=6���a^F���P��&E��s��#�/~6`b��
ob-���։w�⠺oY��+��O(l�����k~}�X�c�/f�ܟ"��wn&|�%��]�D_{!FO���:��)]W��̶��`�(��-;~^�F��_ H;���֋�A�o!�S
�K�,�)���^��sΤH�1F���t�O#�Hl�)�re��-�O^��G���+A����BT)��]~)Z�[�.ȧY���{����)���'d}���~|�	�Eeӛ�L�\��2}�(�z�^U}�2�{����G���#��7H7������Y�;q��qfW(!r�{� ��h�l�ܝ��ҕ�}�"{<��MV�`,�\�C���#�UQ;��2h�#�3?�NB
�eĭM`�	P���^Ց���a�8'/%O����j펭8�h���)�1�!}t����s܅��3Fl��L�%l؁$�(:\S_SqѺ�:J�r�uG��ԯg��M��^�Al\~AI�	z=�Pé�ѭE���U�lm��H�H�?=6�Ǎ�tLr+E�����~�f�i�7��2��݅�=����=���8@��=��z9';@�V�S�Ҡ��4�բTF����u ���_���Q5��	���DCi�!si���J˝*�֙��d�kecl+:y0�����r|J�')!���-U�6�:En)ǹ���/����WyK��U!��f��n�>�V�;��$^���\�������"��,f��Ǖ ���r�ɽ�D��a���I��u�d!*?ɢ�f4x/�ϑ��ňp#�����-h�W,�	�6ƃ��zHۢ�i��ץ`�qل̀-���\w�=�+$���3�@�.�ˬm���UZ���Oa��{"���%�����c{#E�j���(���a�r�rvi����mu�y�, D��v-�l��6φQ(Ϋs�Ҁ��{�q[���a�ș�rI<��	�7�Z�<΍����Ib��M=z��m/�����ΕYF��Ti����*vFx�j�h���A��\����f�|���D��l9d}�G�c��o����v�Ђ~o��r���E���dF"ki��<�g��?H{=�߰0��TM��IjA9��o�jj���9��ǁ���}�$5a0g!U
*XU����tT�U���-�Q��!����77�t(E��OR����V��l���x����x	�d�]�瘴}t��b OC�",<���p!��w��C
�C���
9�C.nJ�f@˦>/X��Bɥ��5��f̸��*-�g���$����~[���x՟�r拆#�S�Ԍ�Eb�:��8�8���8C������+yG��T#>�'�&�2�G2/ԿN��_��
�.��	S ?���}�h����I���e�jp�kcX�(Cjz��	�ߣ�b^���fb_E��Nl��p�ߑ��i�͎OćIm�$��Z�v��oև[�����r|�He�;`I�L��_:{f����t˫��A��b�Q�DD���'�
5���Pf_�ϓ�����T-"�SMCg�P�� �Lz�A�Ͱ��{I��%ֶ�{�Z4����
ǧ�!��!�R�NBE��`|�������\�O_��)�!�
!p>��B�j��#x�J��$�zރ'B��6�UI'���㜾p��D��P �_� Iۀ��ɵn#��p4kž��^��>��T���O�?�HL�#\�p�"�(pt���!"q�g�=�Uu�b��UE
B�F�8��EihLj`ܟ1*e�$؋F��\��uE�k��-���̑�d1Ĺ��F�.����1vz]
�E��w������X�!x\\xؑ�-��c��4�~��3�B�Õ}q�N�lχ�9�?A~;Y������c�=�r.O�f5Z��;D�HT�m����Ď�O'�]���s���ds��+Z>䞵d�
��ɔ��@�SV����p��Y��9���Zu�(;�kI,kY���$f)���x�liWO�9*��U�r=�,:� -��|�,��+_�QC�k���X�es�A�im�(D�+l�:���֥%R�D�;���a�
��
2���(��g��Y�D�0F�v.�����M8QM���zrWW�h��v�$���\5�	D��[�v	SK۟�B�@O�lmG��`�{���gH;?)���xԖ�P pl�P��69����0�]��jRD�%{s���K�l/��T{7�:ց��a�S���W�'�>[B�ġn����N�5�I�N۫%,h���q3�Uxm����e
�"�u�������c��"-/V�Om��[��1p��񰛁G뢆�0�Ixi@$X��BK�=+c�x)ˆ*��>�]Oe�����p=vz��?O��ħx�d�OT���f�1lH�p��sv8D�3�J�IY��mھ�U��)����\!ND�g�Hg� H�1:���9��s�C�8h��3�^�s�}L�`fu��*���Nxe�Tk�͓�t�R�(��)�p�7;1e`�E֭[���c�W<�t?��ƛ��WZ�?����W�%:��)t��j.P���(��|��X��s�֌3�.iog�m�d���m<����5���{�'�"P�Űrx�WJb-~n�#go*��z��ݠ�lKp&��4�U��ѕ;Tԥwr����"$��+k�4�q�9��ւ[�*#�̟�EW�d�~DC��Wg�3]{ɑ��	-�~H��Ys�e�8�,��BŁN.���uS/ۇ�\�U�|b���bT�Z�(1u�Qc ܼ���'g�/����E\2�.���C�tRL'ow;(��Fk���\+�-m�"�\���fޛC<�O�65X�3Q����m�O�0s%9tZ#���Բ�����g���R��0{C�Nx�
T,F&LZ�Bu&:л��ܫ1���W��h��h�x�̓�g��F���u�z���U9�rx��@�g[�/�������aK�ss�A$���b�P{���w�.���)'�y�w�T�	jfK�a9��鮸VS��|��y���3`�b��-��-�C��Ĝ�� T�;���\�<��F�i��Pm��߅)|/�*3M�#�fK����C����k��T0�uG��F�2/{���^���]�Z�If?Il��}c2A{m|Vn�������s�L'bd��Gv��|d�[�Wp�ɘ/�֭��@����}���1}a\���L��s[@������+}��^J8�e���_-Q�7����a9�.����Z�*�B0���@P�-7���o$v��O�a�N��o?3��{8`�lLܾ�1�`�Ba��M��ů_�L�����L����8�B(������b�$�a�T���)�]�gp�`�8"��R�V=[�'rԆ�)�&����7>Қ�}c�剱�p�B4��3O'4C�
���i�`��8XG��W���io
�d��\�&�-$��?/@�z-\�%�(bX����a	�1/6ɐ�>�<�� h�)�3/���+�ШC�2&�4��7��Z���bO6�
=�f|�r�h��Oh���y����V�=f���j֮(vU�g&Ơ��2���W7�m�����x�a��d��k��,ZU��ga<��j̗iq���]%0P��}�evtp��ڶP����DO�j�C�
�y��˛V�T��ݍ���^
;~�붅���q�g�����
�d�^�BW���J�b�{�VT���de�(�+�)��[w���1�u�~��+깄w���톓?�qdFK��}�������a�_�Q_	��* �1����$��h����CD�Cs;^o��
�:П�:�(q/���7�֤��J#� �:�U@;6���!	� [7v����K��D�Tt>
n��#o��UX-_��(`�&fL�g�ctȋ� �c�u����6��ͲA�Ml|�x���k���	Khg���n	O����~[�@h��\Վ���p�]P�(�u�x��R�V9��?�8)���aN��uOɽ�@�*�r��C�҃��I�n�)Q�[�P���˶zY㐄v|GHxݏz.D��'�D�lV��v�F��f.�VCZ��|���rV��W���-��>��~M�uC��Ի�,޹˩@h,���9�U�,�W|E�k��r��KA��g`.&�N�Q��ΐ8.KW�q�
0&8��g�$�2�h7�;�)�f�_������_������Vzz�l���m�I�!�l%�J���Y1�6��Fܝ-M(��R�~���m�*v�Si��|�q \���Qr��<�WBm�Ԛ�~ZEg��*��'�6Q�X�������Vw���ۺ+�D�O��݆i��,���k��ɢ�0��R�|�� <��,iO\}�5�rwicz��HO����2�T�<1���?�f銶�$'Ib�OsE�D�:�OHY?��8٣�癑������w �g�#�����@ѩ�C�wN�bj�\FI�@k����m����:�����@�h  ��s	���oM6}��T�G�,�x�D����������?4����m'�#��(OBb-
)�b�`#��3:��=�|�zPnF�R��=8�� ��j�[�����7>cg$��t-V��L��=6�d�����9Uh�
��E@����IJ��#���eM�&�2U�
BY�+�e4����H}�.���I����W�E��=�5ҏ��f>��N�������u�_������##Cj�����&��Щ5�M5x�I�G(g�_3��X�|�?�3�Aґ���,�Ư����Y��J���;|���"Qt�0��:A��F���s-Ԡ����.�i�����a�`.���zoTq2:�
�Qt��:�W� ��c�,�������F��
�lz 9A(�=+M{�Q=��dNS�&�<9�P"w%[�n��U{P}��z�Yq��=�Pݦ���?��!EI�����b��:ys�������pE�U��y�c���Mr��!- ������K�h�=�-�N�����E^�\�\/��7���^y���@�r��1�{�9`v]��GTu��B2���f��M�1ܹ�+�l�t�c1�BL�\~�ڦs����$��(+'��&��� �����)C4a`��5�ũI����A�%�te�h�W��� �tkh�2��P���mCg����J�}�&.dIV�*�^KDf+ݱ5�C	����
�MΊ�'(����FI�����$4GBW�ǭh:x{�&�%���_�v?GZg��	�EC ����:���A����R&� �'$�"\���W.3b2�F�}��~���|8V�v�@�9kd 5=Z��Z��w]ך: �"g;�/�<��!�XT)5��g��y�����/�����N��)%�t\�EB�����_8��	�����|w��'Z}(Ή��G�|�{J�"q��8&k
"����;���m����]�a
����8(@@�f�V�``ߎQ���Zꪙ;6��8����F4�X؍�:R����ジ>/�� n�
�o!�syvl֬�K���s�|����6�r�CF+�[�p��.��p������h:�b�^�nKgκ�88�P|_��E�"xTh_z ����V�I��Цg����|y�O�[�!)�C��R=����*���5�{�DeKv���˻}�\���b���9�~z������S���cU�c����Y��t���Q��['��І��#**	�]�U�0�p�7(���	�ɵ���Hn-+���G7%��9Y�w %ufC�w2�$�ez�@��̷B�dd��K�9�>�H��Lo�r|�-�^��Զ{�o�[f7��ǽ��9=}��,f;���'�h>�<%S�KPTg�>8�E� 6Q�?��Vr���r��Aji*�A�ۭ�����V�XǷ"Ü���JV\�-P&�起��뼁���~i~5�+3^-��P1�Q5�^��������?w;����۩u���q�����ޯ ����g�P��xŬ�����M-�ދ�V�X}/�~�[����p�Y״&���M�3��rP�y�ND$[�0ވ�E����W�=���|����������n�A�`�YFe���sZ�Ř��ϟq��-5g^�.�B�Ke]-�	2Ǉ#	������u��a��o��O�v|-Ņ�n���#��z��l}i��,2I ��})k[�{{0���*7/s����a�����.��\����@���b��]��V6���tb��>b��Y��K��mP99 N�ʫ��b�Ҩ��敧��no=��x7��� �]�_���w�e��8^�t8�$)nO��d�8ɨ���WA��@�%'~���.�Td��dQ�|�g�*S�t��4�(���+��(��/��i�|�����������%������H�}j��Z?ͅr4�a��s�'���B�Vb��؟�m���V���\"�RJ �Є��\��S#�Mm2����}>t�\LѪa�kS���GHdRj{�#c�h� 67�uI&)�wX���-}a����Cí}�*�K�ߊ�A��v]����.����̔�E��j�l~��&��$��K��C(�h�}�7��1�H��M!@$[�Q?�)����S��QԙBl�/�-İ�[�f"��^�n�k��Ro��x��z(8(����sx2�m;^:��qÚ-��fX�'H ��9��9��h�'�`�0�@X���%��\����Yf�q�������p�9���AA.x����wE�l#���a�[��>>��E���U��bnsbJ߫���p�ǹ6���s�1%�� �*��z����W�4Y���*`z�T���A+M�{�cx� yP�R7�Q�l�4aտ��:���.��?�����H`�{F�̉�c�����ʳ���1+�*1�D��� t��"~�R������a��M�cJ��#Ⱦ�n;���-��V����|�l�8�8WNr��01І��?��C�N��W���,��~����u ��ܲ�v"������*� Q�V�ʙ�����H�b�!c����bA@�K�x7_��D8����W�:vah+���Ѳ���m��|m�4�j�Ļdɻ��Qw��O��͉d]��~R�~�{�q�+�[^�uwh`���A��#���{�<��Ǣ��������s��:L���8��JĚM����
���:�H[��(�r3�N0G9��Q7�#3yiR�D��� ��\�3]PhQ��B�%�N�f���O���G�%Z*4V�q[���ZB�"B}Q�"���%U��q���ݑ�f�Ƥ����eo�"g�;4�$�@-�w�~QI�h_��7�s��^�i� 8DԷ1&/t۱�PЍ:�ݺ{<E1�]�ϑ_�V�����u��xH>8����p)c�+c`��GeK8��I�+W�"���l۶�� =�h�.3��qh=>	��/m!�����;s�b�!��#���ܝ�/�7�@'�NV�ꦸb����a��g�'}���^��n���{�P�!��N�6���)�-�K�����,�nr��u���C����<�9�"��,X9�%FDNgo,���ڵ1���B��F+Yk�NI��[\���2��� ������X���������S���E�CA_	��K8h�n�H[R�������¼�T�ʍ	SJ�#r����滑/a9��ȼ�o��e@ໂSS�5ӼϜ	%����+DH��� ��D�T#�xj|�O{���l^E٪�ⷔ7]���ҕF�<ҹ�~��SmW<��A���;V{7�wj8g�uՌ��n^`C��@���c��F,��(�;�8G��E����-�>3	$Y;��AuX�H�w )�֙�򴢕,�8"6��S�v`cA���!��2km�� �"��/{t©h�N�?�[��a��f��a�
q0	���R��@1�s��t�������gBy�̧��$���J���d%��,+V�Lv��?�W9Gc�{Hz�3.kP�5J��p61�e�A��
j���f��:: ��	yE!��ƺ1��%JȖ���q)��}gH[�$K��TɬǞS�p~�!s�?7:�by�^	[6��W����}WRr~�]onv+�����=�:�:��i��&1ܓ@����q���RPO�6(�j.�B�H��sz��j�`�Q��7�<�keԽ�^���w�[����>mix�L���#�-��n�Y����.�����á�!X;��׶&^�jft/��2~�W�&Zv���I2�%��eB�-�C���6�����v��(�>э&�<n�I:��h�i�����F2!����5��4�}�l�B2f[w	610�l�ͱ�DcMq�H@�L��e�U�5�"|p*�8c�4|o��B�.���k��={>�3�J��M��"�bfn0B�+qG�]��4�yp��%�o�������g�� �X�u_�Pۚ9�XE�V5�봄�� ^X-�_	���J�'9Ag�<�ݐ5hKM���U��ph��l�R)0��Z�����l��!�b��Tﯖ�;`���y/h���4Gˈ�i1��2ͨn�a?����_���CCwE��<��'?%�l���UN��?�)�"?�*�6���mh!�q�ޖ���+�j��ýo�ɛ1C4���K6z�Y�uB�)DwL<8� �Л�A����:-�'�t.�b��R�����+��N�$X�,@~9`)}8�/��WӆpO	KX#�O�������?o���&���Um���ri��;�)��.`����E-6h�vV�.�#��IO%%�⿾Qw�F�ā�?�ʡ��s�H�A������G��갅���$lU��]�!Fy����-2m��"��7%�5����n�z�� ����e�f��b�3��C�2��[����}Lr6���^孓�=<�^c�Ҋ����D��Zd������~G��Х
��i;�V\ ��n��]��C��T�	�%����; 1-U��!����r<��.JA-߸�pd��FkQX�َ���µ�>�r�&n��J,~�	��t�2��;���`�Q�9�D����mñ4���Q�f6o��&6��m,l�I��Gi;�Gu�]����>���������)�	�Ù��Ɯrb�e�IA�t�,����Gʤm�Mw1v[��,�&`g�F�}W���2B��n<������ǭ���7}��]���>�s~d����� WC�Q��h���D �9x|�gv~����3u�f���� U�Rw���u�!kAƭ��~�� ;��-�cH�-�������>�(]��W�4�=�����ڹ��tU�5�ӑs��=����؎+�Ս�<��Z]�f�h>J���N���*���V�s��z
�\#��#�5c����_Eoa>������34:\
�<�Nq����Ҋ���J!���X���:�r��=��}���h�s��ᭆ���J�vm�M��]�����8���՝pA�Q��!@��T�z)�p��
���&�~�(�*�wE���J�NὩ����|o�Տ�V�C��޲M���̒]��S$}0�0�V�k1�������p6=]F�(6��9�� ��z�/l�$�wٺ
����C��:�sg}�d��i�|�%`L
zo�&T�f٢�L�F(12�x���@)���{�'���6e�l�(�w���4�8�pZ&��|gg\㼷G4�Y� O����A�����u�|LM>�W2W1!%;K�%)"��1�L��gS��������Q���'ѳ+��E��i��?���b�)�M]V6L9!��`�WN������{kKa)덊w�PM4��s�a -�&��d��J١8s��ǿd��pt��*�����6<:��1�kJ�Ɖ���'W����AKʋ���	�?��:�$���N\}�M7O���ٛ�-ܫ�����m�H�x���Qew
V6�(HNu�G"'��HN��*�0��:���#���{E���5�?�یF`=H�w7˒5�e}�"fg�l��'vT
#���,\+� �A��SZ�G��k(s/[����g�?w�¤p[���o�e�-#�R��^����` ��1V��<ŭT&[�|s�� �g ��P�}D��P?/����n�6�H�!E0V|�����R,��8^>�n��Т�C��5yr#\u\�G��S&��\�2��NӬ�pPMo�ˈ+X4EY��Kg�1Ls�E�i��rdۺ��w��<Q�����m��)4��cE��[*"Ǵ,?唀o�9:�Dc�h��0�M�2�Ϧ�B�o���b��71"$��XhՕ�i�*>�ؓ"Z1�NY�˺��%�����1�l`sA�"q>��b<����m c�7��>��x��oK_�N��=�!��{b�:��U�?v��j�9�ظ�;tҪ�NDd#6NPiω����潓u:Nq�&����.�f��ˬqJh%�	��y�F�Ϯ�%A��LI7���>O��ԉ��,�˽t]��f_��K���i+��|�%��i�����tζ��f��9�)Y{�dG�����Zs�����BUI$iʸ�i��<�b�Q�\�|>����$` g���1��s�܆D����ON�u:	�ɤ�F���+�c�*o�>���&�g���(2Ŗ�/u��!�dkR��\u�+��{��I������U�D�U��m�KX0����;%���� $'�C:���RC����!?��``&�!S�f��`k��:���uD�,��φ�IM�ډkS:F1T�+�����g��7���z��`D������L:2�1_��)kY��]�L}�>���E$��LQf`k/�����_+uZn��g�y1(1�0�W0Q�P���ź����a���tF!$� {������K�"����
�Jm$ϵK��B?h��z�� �.w��1ƛ���z�I-!��ly�t�m�	��%��B����EP]�����ش�h޻� �[���t��I���uv%CD�1=��Sx*(��m%@=��#C��*�[�!Iy�2�z�>�L9��x�އ]��]���!�rÌ��bڤ��ڙL� Kq��%�I:D�D���h|�7����s ��-uk7�M.��i1��G�	�|M����4DT��U�ʍ����q���
5�]�8��Z��o�lՋ31\���4߉/D�I���@ݮ��N��ȷ�b�����kZG�S����9r�'��m�W����o�,�z!����(�P@�;��C��q�BE������
��� �-^����`�Zu�^�NZ��������^;nñ�r�qts������<j+�I0�X͈@����%�c!�@U��a5�2D�_1���2H�7�sG.���Zb��r���S��cp~�C�t��h�~s�v�MD�'�9p�5K�Q5�tA���rJ�No�C����N����8���.���`�vX�r�FC-�℟�	���1>�T���Uv�fm�L�`[�>�`5k�f���3Nm�{v�;iS��|R�ʘ4��U����������b�Q���O�b��U$���E��k��	r��6��L1�'�.�&0�x�^ _�3�D���T��c�&������L�]R�e+Q�8E������7�����h�T]x��>�/�^���O����v�n�z"�r��#���{ݏ{	�w�{�U���ƞ�ᔭ�\���9�^�V�p��}k�r�vDn^�5����t���
�k����u�T��T�K���`��Ƕ.r;�4n6�T���,����4�Q�3
{Rt7)���΂�V�/A�j��g Z���<�ފ����Z�&c릲Co�H�(���/��^Q��-HdS�5Q\1%#�Y�0���S���غ�J���㑠Q���umyH�����U�<3�!�'�/RF )9�nٍ午�'�շ���"%�P�=��5�簫�L2�{��3X���0gW��E�����@��v\�aw�*L,��C�~�zϜ�,��!x��.,?�{MsX`�M�w5l[�á�[�g���߹�\ W���v1���+n�4t0�f6Lu%�l6���j=���CZ�k8| ��kQ�n�X�M�ٌfz��5��Phhq&-�d��h�}��3��?�zE���V%��D8�T^�o>�$��e2bQ�_ti���25g  L_"�'�� ����c��n��g�    YZ