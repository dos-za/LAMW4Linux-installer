#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2926504036"
MD5="432d6d362f3e8b871529c983eaee3363"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22896"
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
	echo Date of packaging: Sun Jun 20 01:33:20 -03 2021
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
�7zXZ  �ִF !   �X����Y-] �}��1Dd]����P�t�D�r�o-a�V��L��щZ���B��<,'yQb�袍����T8�aϜ�lkOV�,�V4B�2s�PgR}���s�]w���	�&���G��Ϯv\����g���Z��c����BD�5+� �DE/S�ߟ�0JFt���Ֆ>�|Y���)yr� ��������<޻�b��7��f�˜���Cr�{��Xh�b�6js�ސ3\�V`(u��ɔ'�}���X�����4LA�G��ST")�����X��j�اڦa� .��(8��|����Ӭ���nȅ�TZ
�w�G��D�V4�`�߹��qjd~��]5bǭ�&�E��ڽ1�T*�L���.|Q�Z��/s�O̢@�W��=��-'�ռ�N���V#(J��W�B�7�t���U9'�g���+9��ߛ&�����9���@���陵���y&��)��X%&��T��N;��_��i�q['��a9�^b4�MK�W_�S���O���a,�x���d'�(��� u��&�J�j�l�L�&d$W���_
�u{���#9!�q�i��R5ڀ��j�!�i#��p7|��H��	t�ŏ`��)�G\F�񠝑�H�\g52T�dT�k�t1�r��u�{����\�~%'���ѫ,�0����]�����z*��L���_�J���+uf��9��M�@�,o�	0��w#�n�t��}�K����VȎQ��o�eN%k��#8*J
>�,"���o�.��H?���d�K��#�h�,s����Ⱦd���-`�O-�\;s�)Z�!&߫�3�"�z���Y ������k�e>�h��<���A�5� qݡz��z#���o��j�M���$;C���`��*4�N�ˁ#���w���B��%·`��Eh�Pj(��̫��f��*��Sb��/e�NlC$_�I_ߍ���R[�nG��eܰ=��}X[-4sh���"�&O)뷾.4x)*U�,Y��]{p��.^2<�����@�?3>&�))�������7�&��I�'� �\�6e�T>1F��P)l'�׼�)@�X+Ok�0�̬Q�� z�U3v��3�G�?��)"�BE���|w�9V����Fw(W�J�?G��j���ҁ��a�&+PH���C��`�f->�?ؚ�W_i~���=>2�)o?�HF��z��A���'���d�m���B�`i��/$��6UiZ�=�i:I����o:Ǟ�hQ
�So��f��|] Ǜ�}��:��',+U��*��7YZ��s��dS��C�2C�՚2y�0�Ԥ+<�������}�'>�
�G@�~��������#�)��G8��E��4O��B�?t�2�	��h>O2e��9k�n���>I��GH�d�?�s�<�A�[	�����*H�|/�	��"�X��T�JxxE�[r`��fK!*�y� �F��������gC��@���9j���p�����?wX��c�K�6�A
B����XU�M�� �V��WG̊!I����n�TҢ�:�$7J��Q �8'���!ʨ��1ը�G��<<�q��Y4:B���kj��t<x�':���g��qO���Z�mmI���W<���=xࡪzxӘ��`(�Ѫy �.Y�vϛ5�ͣ�s>����T�V���uؙ�.	2�|e��
8!J�`.��'J�E�v������3��G�����0����bף�fU�5� G}�&y�	
��G�����w������8��9V�`�|��������|�+:�:��VD����(�љ�)N���+zJ�䜬/�Re�y��c�����ߦ~�IT�
��އ%���O��9�@{��_�W1�J��e���ަ�*ؽM�YJ��-�i�3cG�?l��c�bl��z�ӱA5<{8���۵#.�w�~FQ��\F� W&��Ql_.�:��U�������ۄ��e>�`�g���Qe]|+8#�s0}�zO�p�� �J�e�Z��iD�2��Ҕ0"r�6��^�3Y����nP
�hQ���D��&��U�o�5}�`�/6�(zX��ǥE?��-݌֤j�:P"p`��ϥ�˘�^m������&�l���$�i8api�R;�q��+�#a�e���$9�k��K��f8�^2^���OI�s�����3My�U����B��^.:=fφ�5����*�~<}�����X����@����!uf��g�^6�����6�	�咭-*0u���$}j	W�g�{��iJﴉ":8��0ϔ����G?k�Z�C^���r���5b&�>����8�C8�M��g
�3P��Z����ĕ�l!��o��N)�ʜ6wg7M��c�$^
�Y��[��ш�,m;����RgL��!}��4�<y64n�3}�
mn̹pj���U�&\�!������(t�=��ώ���y�#����M��O����<��y����Es���@-��C/���d�U�r�^��9��JK��B|L���Y?����HՁ�V�9΅n �etj�m�&�����A��#WcGr������-�{�H��{�ccשlS��.N��Ƭ�ڔ&���ذm�Yn��A��K ��ʢ�]�=�w���j�X�"�y� ���{\AC�Gj�L���|��|��_�(��ٱ>pvQ�yVWm�k�{���#/����aSPR��3��3=K��?�"#�3oAK�j��vWQ���R2)ϓ!�֕fd���U�pSjnP�����](X�,&(�xc���p/v8k�[����3~�>�̛��e�1�<�S��>�Bp�[/��i����&�&���� �/9ͬ�|6�F�kQ��4�(]�H���pTf�&Q�Bl�����f��M�͟G��73�ߤw����ſ�~�,��\)�谚���~�Gn�R����#�88+�p��vtf9�3��X�rz�؆�W/��Czڸ �������Y<XqO���6v�#�V�׳���rn� a���R����xzo�>,�g��`�d��D?��������Z�<�`�YH.���&�m3�y�W{��OH�'7O�@s)%��j ,�6L��MfxwnNA�c@��]ds,�\�#���L���C���d@H1����T�}~�R�c�&懒SP�A o=��h����V;�^~nVi}k>��F�o&A�hYy=��8��������qF�,��N�i�v�m�zl�Q��H�3�,)ؖF��#��4xi�Γ��������E�o_.J*+���h&ޚN3ҹ��b�[��qkl��4#�+���� d.[�8>��;�o@i��ڽ��ؒ!����+p�{t4�`F��^�GgF�k����\*��q�9y�C����#Nؕ����(<�����u��d��7�K�"gIY��ȱ}#���8~S!8W<#J��!�OǪ�B�����o��uV�+_D-���z�˶�G�&��b&��`5�4u�pT�Sm�Pj`�����w�ܧ��商-*Tt��Uga�S�}:ο@;�s��7�VN�U=����K$s#n��H�c��JA�D���8%q�f�	�,����a )�ݑ�D�H�[_!뽴��w��<2��xY���%:�"}R��?U��R:�CW�ߓq��c��_�����ZtZ�Xj:�f�� ѾF��"�8�C�?N��#j�R�5�=,��#KLP5�d���-����,�Ֆ�?q���/��@Fv��M�1�'�"��^� +��1'g^ࠛ�YHE�k���2u�N��%/�Y�	�u,-��W�����o�"����R�rwof�/����s�)(��K$ώ�W/7t��g%hL'�`�� ������&Q�'	��h���>��̼7&�-,��G��,!�L����t�#Ҋ��D�g副%�N+��{WV6�hӡ�������.ң.\8�G���&�QڛB�������CS-�fʐΡQ��p���ȉ@��}��rQ�:���:ЫތC�������N@�<��RS^��B2�ON���tI�4�����x���,߸��ʐV�/��cs��bLXHl�Q� 6�z���,��u��v]��9*�v��� ���:*E�
�A�Hf(���?'/��C�����K���2�4���kst}z��Z���F8ٽ9 �Ś�Ƴ���S�N�n�s�h�"kE�cw�A�~^.%��'�E�U'��i�n=Vfn�߇5��c�^t�it�
!����Zn�z�e��;�!(b��I_�J=�#X�`ި-�p�9���ئ+�w�#2�#�Y$�/������>N��c&a����2��؍W33X�J:���-�>;R���`.Q�&rV�yk��?fe� ����\���sg��W��I��I��p�Q�������oo�9u�lR��)������\F��M�.�+���,h�h~b@��}��S�.��$ ��w3�}���(����e��\^���q6���f�6I��ϳ0(-Q�
�>wr����F�D�Z
��kS`P��7�g������o�P�t��|�9��Y�6i��Q;��-ס5�w�Eb�rEi� nq��h�d��:��Iywu`� ��p#�AfM؆�rh���<�9z;�K���e'�⇜��1�(~��ț�%���"��C�.���d�5#a��x#7�9|�M-�b��Έ��w_��yLxK��`%J���N��.�)c��������+*��g�.���@��v��Ρ8��vA�5HOz�B��-�c�M(�~.�9ayT�����R�JљJ}��n�'��$����G"{���^�u߳Ϟ�/QL>P%9E�m�nc��wU�rܥ:����ߟ�SWz�8��naM?�cM�^e��A�e�f�s!ǕVKHRrʌ�[7��O��'��K9R�c������@_>o���4
Y�ODX��p�l�܋x��G�b��P�G&�
�U�i���݄�<��V��c���F��c	b��)�W�f�t��+Wd�8l8L��q�v��&�%�	+�6���کG�7j�����'A����"� �S�@.��m)W�JQ��������#�z��?����ƃ��N��E�g�����f\#�&4�������g��{l<�bֺ��A�r�bN�u�~� ^O�:��>W� �˿0l64��T���,��~�yp��H~�-ф�~��Ǻ�Z��WȠP"yf\an\K/���W%�<sȼ�@���_�}�Oo��i��ؼa�obE�����;����G��|�
�e0P���*�Y޵��^kMg�w�G7Vby/S��"��{|�7�<jW��[/�ہ��D`bR���������4;ċ���/>�g��3@���V��:#��z��0�N1�g�`�!���L�"��S��C��� >�B�`_�[7�;`�3(��}��4�4cw�$���7�w����Ŀ�nt�4��\G-Xe�8�q&��L�9�iy�YT�4�5 r$�<;�_�ϊ�eE� ��,S���:�d}�I.��'��`%�s�i��V�� )�A(��]�U��y�I�%k/�[<d'IU�*u�ہ0�n�#� `�4���, 1�{��w�fЮ  �Q�PR.���lF��h�߇����H��g[2�����`X7��r��-�׷KYh7�7B�
I6���~�b"-�j�R�D��B�� 5ˈǝxZڦv@�k�
�Hm�J6���H��S:�����K�䀒�_Ks'��lɝ?�bE�s���v������O"����E��6\�}�8w��ƭ�b���N�
�qhf	��.,Fe�˺�[W���{�y	ɿ��s��]2A��r"]E��'{엞い(	Ycǲ+�8��[���2�����Y�ư�u׺'��Y�>EVRmϰ�;�����L��o���Z~lD�z�T@�s���>���#1�ª��M�=�8֐y�m��N�� ��d\��k�[����@��2vrA�V2P�^X͔�=�-JI����x���a�sYcr}���ܳ']����M����H�o�J�)RQR>�(�t>i��WkG2�jl���]j���`��.�.�B>���4�(p%���%+	2#��ݗ��>OkR��J���Ӥu�9�Љ�x��R�w�[���x.��(���L.	�����#�1Yay��GEZ���JY�ͤ����#�'G�.��}�%Җ����ؐ��V�K7ń �`gDmf��~�<�)��C/F��e;���"4ㇽ^�vJ騧�Ng��@���K��k����s��:w�5�#���0���Ra�[�֦l�N,���B���� $l� ��%��	|��y��������l'� �
9�Н,)�7��&�v}�H�]"L@��_��U�c ����Q� J�3Ss��9�>�#o�sEj6��K��Y7�2�7���~B�I��t��If��ca�G��������yն�᠗�����	ٲ�d�ֶ#���>+ދ�#A.�&1d���>\e���:��\׻�mTɚ�Y�F,��핖`E�J�υ\]��,tKWX�K&X�&�\��H@�F:hK��v����I��#<pb;�A٬Zi�tYV�^�e<�k[& ���,9%̈-��έ�/��'��Kwe �@��p�/��T�\�������*����ߠ.��j$�X�y �R+��mt&s��o�����*}�EsF���s]�[p��tţ�9���e^ݼ�PE�&,M�xrT,����X�8	�b2^Ui�G���<�  .���E1��(
uӯ&�p�&�u5�E�z�_�Fo)
��̳���vK8K"���GyDiDcO���A�� A�)?�q���}:���\&�����m�eɆ���P���՞x���0�U4��N�dN���
�����/uQ�_W���G+mN^)c8��)�Z%y�FQH�y)RY���Ъ���� 4<�9��fev���X }��G�����3統�
pˍ2��M`�.T�B�s	���m������S����̙15l{�~�WM��݇ƹ^2��v#�ƉMIT�.k��.���M��ʘZ�s|?uF���uũ|�Q(�f1��)��ض���"�2`�q�׈BK!j/��V�����xf��Zѱ����'� ���5Z}�׭S}����!�b!Fs��)��Rwn�6K�ŏ�}/�В����8;Ͼ��J�L|�A�\樻�7O#��۱��o{�̳]gra�dkMV�������ƚ��y<)��n�,�"�#���=M_u��j��0��O����{g��̶�}��DB|q�U�Ny�b^ҿ2���	^�7\��e0�-���g�:��U8�	#?>zf���!�),�ŲWX�y]��|`�v���$��L���	�̀�9ef2: �������˘���������R�7�����3�m�a
ր�\[�g܋��c���wz��� /�=94햊
�uJ�NH�߳	ц���F)2���v{��PZ��1�̅*FtH�j��q���"?e����X�G����@�ZqUoЋ���G��Aw��Ah�1�
tz~���^��忤�J�~r[�ԫ�L%�Cw0M�i�M>��GC'$C�<@#�bQU.��y�������K�(^��53�O!���������ţ��#���Dy�8o��m���������s^g(�{��l5P��@ԛ��z�f�ո�f���_���� Ҋʢ���7�*��C�O�9�r���}ׂg!�
]��2Lř���*p��p1vz-��.�����K�b�;t����,}�3?�@�����:�X�i�[=*�`
 F
��tU�,��^\� /M���Wa�H������_�����2�aݝ����F�G����S�L-�JWq����p?b�H�?��,�)�Q�h�Fo�$�LK(h� �6v�v帅&�J��k���P* G717����$��'�u�C-%�
?��-l�Rs|	iԫ�e��>2�ql9p�����7{ͯD��ȫ/�p4��ʴ���^�H*>z=�;���H�D�ApT��T����A�+�[���)����J�'o�<ȕ���AF -��N�gY���ؙ���,�{�z&�W�H�/���S&���KcC�*����kDٱ�V)�kXh�bMU�7h,�m��2��.�3�h��g�ZM��ן��g2$5�����S����L�ӎ�����!O��e��9[钤���z�Ԉ��߿��>ؖ���Ji�������P�7�O2�k��'';�k%(��6Dn��8��|�.��&L6_(��>+�7��~�П��7�JȺ��aG}�6�=HmZ|�d�:���R�}7��	�����jKU0���b@�����SU;�d�p��Ƈ!��6+�Nm�������:[S���X>�4tn,�������JNݦQ�j���a�ؖ�s�po�K������ �BFG�|&%��.9��|�"z��X���}������Đ��aK��w�5Ј���i5����E�
���r�����d��>�+]�_���~������aB��j���֡/[��a�&�ȸ���{�h�HP�٥�`�����X�T	z�Y#D�#��#��g,�����<>��`����Gw֖��G?=�&���g�������O��y2���ת���[/�M���D����a8�6�ߟ��^f���h-��Q�s(��2���<Ǝ���~����h���r���
6���\!m�@#7!-ب��=��)r=��,����w�&x�W��4����V�;�����|g��z�e�6�3,2�!ڡV<�Cn�>��,���*�#��չAx�J�-ǧ�����u
�|�~4��v�'$�!�0`��u�F�|�a�j>�u$�j{c����J�;�rc�� ��J)��̯R�:��n�ؽ`��Yj��d�O��ɴ|�r˥�B��<w�$��dB�6�7�B`�0��\~F,���ﱃ���bM�A�'����&&`"[�J�w�g�fA�I�Ut1E�Z�=���j�3U��K���&^NEB��(�����&TO���}̳��{�H-��������Ǿh�P4��L��{� �v��M�2J�C�&��vIl7d2�1qy(���1�>r�`�Pk�f�����U��i��r\t"�N��x��,�a��4��BNu������`t��8�ј��ߺWQq�AS�-siAپM��{vT:���&��[�w;�5�����L�5�aF�L��U�7b@�[} dUb���>+�����O��]�ch����&!�P���` ���S�&��5�Z�Q ���&��#LJ��rdۊ3W���P��� #Ŋ1i���'0Z�s,f�� ��"�:�����`�_͒R�Nǂd]0�*��p����䫬�c���1��a?�!�%�Cì�	�T�/>3k>BXc�/J�B/��j�+��2��=��#��_~��9ƚ݁����z��^�g�y�ݏ�´?�.����X�Pj��-�4'[Vg|�Eڨr�2X�����HƯ �����H�r�(���J��y>L��{/���G�_t��K�&y䂾�i]xJ��\��E�$a~�*���i�/֫yV�8Ǩ�4���ǿx���F�=):	ߥJa�'�G�L'V�u��F�ŝЪ���d#	9����!-e�0g@�>������'i�h���Z��o�O�\]������e飆�d�ɴJ[kz�,��wl�G��w�xqZ��~��5�n��Ll�n�T�08��4�����W�r�ا�_� ŏ�@���x��&��U���ܢ���E5��;�38�X,+_|4�Y��+���'kVqK�U�S��z*C)^7�ٛ�U�M`�mڿ��*�>�k������w\"���f+�#�QKl���ɵm�g�<n�9�Xdq���5g���� ��ٗgR�Aq�f�LS���-�i���;�3�k2;��K�]��2~��%$�:���e��έ�������N���$>�{5���q*�k���m6����:�'���N��; �AU�: U�s&� �0� �1]u�1T���
[�҅'�q8aI��f����7�ʒ#@OI{V5�%�J�x��R��lR5D+��93 Z	8�!#��(z���s8*-r3@�[�O���w8y��Mi�� ���X��/�x��;�;�Q�/p: ��'>>�y2r�a�qn�N�]|!�>P�Q�7 z����x��1(�u�λ�XIx#�ډ3�����������r��@�B�G��>�L2������%�,�\�v�����s(�������{�7�~M����%ַv9�P:�A9ۗ}"I餔J,b%�Y�MznvF��J��yж`QB�ۣ�<�H�g�:-Y\mExN��^N�^xa􅲟����� <���\�J�Ih6�!M�^�e�	��c����C3X��Wں"�>�8*�	��n2�lnwY<�H{��{�����t]���F�������s'�u�S	��|����*ߐ���H�;I�QZޯ�6Q?�{_��hq��C�{��_�h�w��AŅ_@eo�q;G1t�]8rY�g���x�
�x��4"�S�K1���r?bפ� ��y��1�83���֐��O���/b���į}Y(`�;�OѪ����S;ʺ��r,�U�uѢ#��Nx�X��E|�g��$|na�RJ�1�;�����=�#��l��H��ܻ6Zf��Ts%����Y	�{��¬��R�L�qF�ڱ�^
�P�b�������;����g�bLy]���	����L?��[���g8b�9���<����|���	7^�io	�6��}��+lt.I������(#�Qo7�v\�U��G'�^&vx��Bc�fKI�^�򬸆�98�� }�:��	;��񶲰$�&�ܓ��S�D �Z�E�$>EM�|���~|�����M�NT�2����b@\5��_Q��K羺<�&�+���'�1�0HU�B� Nz AV��ʼ�,��Y��b"y�|�������^t�����\yt�����Bb� ��c� r��5���N�N�ܬO(��9O�ش��r���/g3׫��<�>�w�� A��H������ UE������.�y�Q�޷{]{�xR���a��J��T\N����Pwq�5��˜I�F]w:pg��Z�Ÿ�Qm�ƓE��*kZ�ru�,�y��sy�M�WS��=�"d;T,��9�<<:=-��dc~�Α'�6N�(8Y�z��YC`V�)��IW����=>:�B[�/�7$=�S�L��F�p�淳�,j��}�o���s|���~F����߳�9���.�]��K����,�gQ.�*�}Z�L��zg���,�"�PJg���'�P @�|��.��S�I�#�*�y���چF�G�bȼ��}��q^�ckMi���d�����#��+w&�33��BIP�*s{���~��"��� �5�k'�vR�&�zO�y�u�ao�H�TĨAvJ��Kᭋp� ��2U�]W���5��%���'^D���ri����r�Z�Q��T�r+�s��j�A-�t<ؙg2ڋTA�a�7^b�Rω����a.c���ؐl�Ž�Br�҆ȱ�*3@P����]��}���F�8Yځl�����=F����jсI� (+m
�|���6����'�yRd���e�X}I���Zt]ąק�n�n��*C��3^���p>b��v  ��c�q<V�F�z�3��A<����Y
�j�蓮7q� �2�� -=���U l�-�������L��^��#�-�-��EZ�@�M�t�N�㇙9�G�?���ŕj�]1���r�������Y};R>"�5�^���p���ǜ�9��c�8O)`[!d�Vv��6�Q�N��������c��,�j���KI���|�zy��$V�qC}ta�E2mP�g{��%���S���6�+�풢pۧơ�;��~;]�d���_�w�U�]��EM�j�@h����U�[�b���W�^�6���Hʘ�XB�@$w>hЮ�E��RTl�k��C��O��'(�'���u�P���I��P��R�3�MX��.N�Z;%�P[�t�d5����T9�/�Z�+^�:Rc���Kf� =��߁�.�˲�&"���YWZަ�$W�,e�������=a�u�.��>:k)� �n �z���@
�U��˻��9x_!��(��R�� ��h�����S�MA��&�m�h}YKF�íY���E��������Zf�W�����,1;=1�+v���=��\$�[iZ�P>Κ��mv �ApL"R�0a����h�@���˖}Ssk���l�!E�o=0c�ϲ��,�����hSy$��=Ne������%JO�si��֝�K�����"�@��m2aghoï�\n1����Y�R�^�^~D�o��b� ���`m��!Wпn��A��]ㅯ��F�̡󊧒8�=h ?������n`-�����U�pg$2Ғ6-2�U//������ʹ�2�d��E�v.��Y���#���_?���$�C�_�b����Kg����<�������H�+{�K�!?]�絑܇�=�t�GNk��>�fޫ�&�c{m�7^.E<�Q6H%>!^�+y_q�\��&�|�⢻��v�c*n̫��p�^E;M�r"8o1�
x�?�#3��R�A���kI ��z��&������~II�1���r�r����_�T�T+L�_Gf�>��癐'��]�c��:�a�v��i�&��'��7��.y�8�g����&��
�V֜�əq�Ud��s>#�����by��? N�s��nv�I@U�#"u�a����*3�&H��h�a|�M��:y���Ы�����7�BN×%}�n�1�v<��ȡ�ٵn�5`�_����#���6O!��C�c�w��2��-��l�S��q��H���'���%�����3>��T|��ޜ�DJrv�+�Q%Ɵb�4p�Ǖrd����{f�B3H+�S���	?S4N�2M%���a������ڌ���_��|������3�`���<���ʆU'z�qW���cQ�,�Kiև�mA f���;-_3퐑������2���A7�g��:e�R���H�S������󓳡�6������E���t�Jm*\Q )�6�ń���Ǵ��"�S�	��uͽ�Z�ɟ�Qps���XM��{�E�B܀a�	TSP��t3����=)�}k��V}?-�n�c)��E�ؠ+��a�[K�,�Ȥ\q����d%�FE8�P	$-��a'�[�s�(�ѩc@k� lef���k���\�8�8�o*��f�]�6>~�b8xzra�����JM.�� N̢��N@�JP���T�+���ݞ.`9�-@ɝ:���2R�b}R%\̑�z�gzÁ�Hm�y�[��sW;��H��GFp~�^Ϋ���S��a��A��t���'�"Q�HwB�>,�N�sێQ��� j���214J���vWTs0IF��m�l�X�B�U`=<��"�0m�Y�rn�D`y�سPQ~��S��<u��/�Ƌ��?����0�O��ӎ�e�OR���ѵ4��;�w���B�#Khݑ��:.nTl��mzc=`(�Wk+���=�Orq�>��z!jy��p@�V��0���$�e�,$i*U��4ö��2��NB�ֽAق�OX=!O��ƭP�J�
�V�V�q���C�Q+c�K���&�y%3h�P�����Y�`�;�#z�����H2���vgW~�^*�:� ��>1���N����-~�W�'|ă���&�)����_��^W�
hy���5�*1�n��]z���ao'�9�N��;�쑻�;NGb�D9k��3�cv����A���P"������<D��^R��q�fI Y\_�Vc:��ڼ����+�_%�a�xs��X��M�v�_Z�)�c��>���=�-���3�-ju�dq��WDj�r���H�Ά<��Bke����$���w���Tp��9׻P77���7�J���v�)��^M=t�K?� ,D�����Y|g�%��IԆk�����g+�3�?����^� e�3���6k�B�z�F�`���H�oAjÊ��&�a&�[d_��L�δ�}���a�n��+$(i��9��&�K�|���6��e��Ch�����\q�z8b	�FX��5I�#։���.��mJny[��Z���S���܆��[�T;{�*4�&�Onx�l��k7)�U%���·A�dN̠T�������m}X�j*��X����9�/���LR��n��k�a�]~��]��Y��5ﺎ
k�F�xn������A���{].!D$t�探�&�80Jtf��uj�)�/�l���ZJ~8�h�i�2�^����+�H��힮�rN�J2��(�2�s�4a6;g4���4��z����ɩ�so�7�F(���Mܮ�!�_���yO#P����GHy���29�j�%N��*3�RqWݢ�6��j���A|?��*ۀ�j�����'˯q�#_�U�8�E��Bڂ1b�I��o�q�1�U��j<m�m��tr,B	��'E�c?1ǫ,�m*=�x��I<�첢F�9��l��� er�mӄ����/+�F�����<��#:�0-]�H)���K�N�@Kڧ�Z�B�1�9�(ЕZ���d੤���Ϝ_�k<�|�Ys�猳hp����J*8dSSz��󁖮ְ-3Sp�W(��W���q�/{�T�a9P�ӑ!�Y�@�$2s��p�0-,f�@q�����0�s��W>�Z�bOv�V�Z&Zy�o~r���~V�I�� ���ZKyt�;˛�I�����Dd��yH�b��UQ��v��i���n� \�m�+YINz@y�I�M���� ,W��g+�Q�����h�+Yy�5弌��]�T���`䳍�b�}� ���Q��HHS�<בR��g��C�2
xz$>��p�t�xm�@��#7Fا��؊�opTA�!3������W��H�af
�|��b{�=2ebM���Sx.�����XUl�yW��a+��%Y��\q2�n �/�����j�宼]wQݓc:|��|b��{&���AR3��X/�6����y�q:��_B��=�K�]�����;���ғ�v��0�HI���\���u�C$M#V��o�Q�	�,S'�"�wa��W�I'Һ��D3��H�i_��RO9���rC���Ǡg!"�� �j��o�zRU��%��]dL�R�\L�?'�����WNq��,�9��ӷ}��q�
syՌ��ˆ͸[*����z' �')|�H����M�4e��t��I0��))ޔ?���t\��H�#D�X���q�W)�m��)A�A� Z[�����[*���<;��/����}�(32�J�M=Q
8�Dn��_�hn���z�uU�Ig���=�ݹ[�/�w��������+U�׽I,�g�cf���=7p4����:�C��x�ٰ܉�"�m�i���hėu�0
�r��-��}0٪
�����6�� ��y<����u���iۘ��ߗ���/f�t&�C���f�d�|�$��/U���!"�+��p[,9�	!3��iY~��R��܇�L"�	~����ĤsĮv�g-o2ŝ�岈�hB2?mn�?Z쪿�|#����zq�sBc��i+fg���/��,7�	V��]�i�R��=�D���}r <�Ao<,_�96����k$���G�dg�x�y)�^���2H�s�\�ﾹ���Eu��;�y/���O�~w.�,(�w�Y
�/]NڹPc���
�P��>t<�-3Ѽ)$�����I�9�����t�	s��6�LR�������첗��AK��N�=o�-&NB�-Z9,k��3Y��Jg�%k-�6|���)�� �^�g�3/�S%��XD�d�9y��w���+۳1��й�C�[��q>���2&e��Sܱ�_��ǅ��~�������(Y�?��G�92m\��B
'��g��e���תh���#Ѿ�(��M.�pu��qVv��A(���dq\���4~��������S,��k��W0��I��\��$g�@�J�W����VJ�Q �joڪY��@�[�<�:c^�lY�w���a�N}v��K�*��hg��m�#��4H���j���@��\���_�r�T��\4���@W3ʘv\�]�"��}0�Bҕ����*5�r�G���؞�7[S���+��݇`~Ί�r]�;=���&��|W��Ki�l�^,+�=k�)�Q%�~_,�dYj�p�Z��G���y�΁��Dwɜ������M!{�u�%�;I5�iH�ȯᛲ`��pWաhft�w�,�+��P�m�]���F���M��+�O��o�]���f�0��� �F�I%{b֞���E�->�=��v�ũ���L�
^�E���/z����6U6��+S,�^`m��|�;��Ms��]D�	������[i?��_��=�#�����Q.\;�r1�^m�W
j'�`D'��b�����Nin0������cZ<�#v�������A�&�y�-d����碻=�tN=RbFDƓ��O���ow�iY'@��1��jT؋^vga[Z��8S�ȏ������T�O�U��£�
�CnK}���R��ev�ꭢ�]����n��t�eٷ�Kۄ���] ��w�� �=�Ma�ES�]u�7��<�k�FUw�ݻ�.J%�_n����,4���Fr��/
�=4��I�~�IK���~�����\�-{ Z�B�߹� �L�zx��8�E���Yi�P��m�v�V�����@�?D\�y�C�qI!y���E>���ȱ�����C��	�){Np=�/&�w��ub��7A�[<+ i���M[%"���ռpF�婵���q���v�m��2�w�X�N�D����&�'� ���"PN�C��{X(�Y~m%2�K�⮤����+i�E/MH#Gk]���-�����o�����uƐ�����W��7e���}���d���sv:ن�9�Fi@�S�O˰������#�<l�G8�ó|����y �>�(�Q:���l��B�)��Q�q��T�A>2��x �"���B��:�m�!�+�L�溿#�x��4s��~�U�o1u�;#2�ڪ6��� ���G�]��'�|&\G�&\�&�z�l���Q�b�`+��"��\4����3M�X�~yC�������O���U`�!tb��Z(cDQ���N��^����M�_nR��35=���T����a*"z�>
�
��X�ȍ-KS ���J�mmux \k~�bp��[�;.i���rL�:�ީdcwf~�T����Q|�}K1[��h�@��^9S$Q�i�B��3?�2Ō����'��bW��'��V���q���5,7��N����z����:s;nK=��f�P4O�s�$c�fD��[��,�U�?-}V:�|�F%�Oױ�����#
���2��֬��Ftl	Aو��<�.����ʮ�F�C�p��I���p�U����T%����W_�۝Pc���D��>ҍ�l�������6A�|X�������s�����#$����6��ĺ��M�К�Xn������X�0��Tmw!�!2�	�Asa�񄳿��F�{ �CM��੒�W����[��
��|쏿v�7�[�ƥ��X�w��I ��7ȓ��Pn���]^<h�e`�W��x�z���V�B\UIz'(w��1�x����x��v!^O<Yw�59�V��
���	�J���q�<����1��o�5P�A�������t.lo]L��c'9�1Iq�.5��}�E�/������� =�l.���P�6+[Q��)4$�[�9?=��+WI�§�F^�'�ɲC��v�����j� ���.�M%P�'�PI�L�JGL9���l���z��O(�����)�⌖�|f�OQ(��-��9�C�pĸ�˫Pj��������9�-+� ��|�TJ(�P]�@B�6��5z��@x�qv�;���a���j���{|��M���;E���A��UnO8��~��`!�ĠEi>�����^����t�$$L	���!aB�� �b�P��if�����h�X���Gk�h���Z���x:��Qb.�q���������j�:����ڌc��� A���*���5�!���A7V��I3��3�i"=Q��{,�g�E$�����5�5Y�n�w��%� ���ժɄ$��+X*( ��P�W���Ùd��Q��.�ۄ�g�8I�����m
�L����r�� �p�#��T�m>�H���݈?���$�+�Y���@o�WUR"9�ҩ�\~����o.�z���0A�x�$���+�-{�|CbeiE=|�u��Z��a�ڎEDM���O��'5@<�ho�Ǣz��zH�%�6@)��7`F����Aݒ�ۃ4���E ;��)J�TIu�ȁ�Lu��m�h�T���:�a`��[����i$sMs2U��Pn���Җ��>*ݠ:a�$��l��s "�αo�dG�'(S&�����Y��ԧ�O�g� ��-N{e��dW����t	�#���x��P_����c���V��T����RA�஺|�Q�`��q�?ʁ��;gl#B���t�LB��d)~�X�dJ�U��vc��xr�S٫?���es�����>�ǶukPQ�br��g<>';��ы	;��YP[��@�K�����[扵��Zq'�S�WM���Z�>�(w�����/�i�r\�hC@�h�ɀ�.ˡ��Z�a������,P䰂��I:˛Ց�ʇ�.FF��ǘ��3��K��p������6�I�.�Kc�3}|P�v���u�
�؃���"�򀒴Xyˏ^4h�n���޲�u&&
���}�p(,����z����A�"��XD��7��|!�b��6C.�3q-��5۲�e���J bFj��v�)޺T�}�(K�+f���!�9�}���Ib�+�>S���R�U�1-"���K6`g���R���7��}a`#�Q\G/�mqATIx5s��^6�F��ۙkOC�kW���k[�$t�2`y8H��Ɉa�oe�?"��m��V�l0i�%�y��.�E��s�*���b+�5T�)�x�:xhVP/����&��g5�f3�!�t������G.���7M���Ƚ�Iw���	�(����.�AP��1���Q�;KlM�|���-F� $Q�V��Ezd�M$�_��z[͖LvenT�1��ܲUU~i+d
���ii�h�(7Xq����	��[_+{��*,`���(�_���jP��O�r0
�ľ��!�ndj鸫x���.$��}��p�b�n\ۗ[e0�	����n�D��,��D��b��Z�����ۻc�{���W:�=c~T��SY�>�*=����:�Z�$����O�_�6������us����Na�uS^2��/Q����Ck�Dp'r}?���2�~"����5z@����غDX�����Qy\���D�qZ��'������퍤��I�s�[g���;?CI���E��J�Ԣ1��$���O�b	�t邏������g�Tk�P& �I5ޡ[B����˷���/�H�Q�?�(�
�x�9,�g吏4p�B���ޥ�l�Qױ�4`�b�9$���d�,��_����\lz(�����,ų���t>�Zf&��g������Юx�'�����o[�<0�O &��@���.nN59�Q1s<z6�s�ōzWK� ����g2!��En|�.K�-Z�F:�a.����q�V�oM��6��%���m\�]8����]{�h.a��WIѓE�Be]����(g��X?ا�8��|^ɛ��@q4zw�{��H�<���1�[��U�,�}�ݓ� ���+����/�����{�ry/�t\/��4XY���WѰl"�����F0g���&��CX��V����i��Mh?�<���������
��L
�ǃ�'�&�=�^�HD��h�h��.D��YoڠN�l��t��DJ���%��#�T��FĤ�;�pa9R/N�Bh�&܏A&�.��[���G@��|��G�َ�����j�?ݲԲ�g�p\X���?'3f;�Й�م�U�ٙ$�IJ���^��h���S ������3>�����C�&/��z�]1�"vS+g�=�vT��u'�	{	E��T[��{8��(��ߍ���|��#G0}Y�<H�p@��t���c���� 7O��R���BʸCnT�h���N�\@]���QF]cГ)'�����Y^TQw�|�Xo�8��ԁ�[/� E��(�c2O:���Z�aL@�zX,+��Q���?�*����N�.̀=�k#rr�`Y��T�R3yY�/m�KxQ�0�n����!��b����P熓�*9�S�ȡ1��*-�TƑ��Fl��z]t���~�W;8;p�R���a�SE��0]E�*;�Ή;���5	YOCWN��[�]|���yE��{�[R�~u��w�h���L�o����h�rF\��QW��=�z���.d�iI�+���s^���Pu �9{y�G�ёӄ�0z!L��C��%u����E��J���l=,Ai3���]?(�-���?�v�X�d�/d��lϴ1�M� ���"g�S�T/��O����K��ӷ�cs×�8E,(r���4"Ĝ���yKG���L<2QB=W\d�1e���'�g(CT��MFS�$91���޽�}i����"�5�4��칽�Q�"�T�+�B�=����-�+��1.�J�R���F!�P���CS������%RŴ]0�{��ff8�,�x`~wP��	�V�v��2j� � ``4��JNm��~���ކ9\+H,�)��%c��bUl��m���.�X(x�j6P��Շc�'-Ik����Ă���|Rdv2��8�u��HU���J�ѫ��w�zM1�f�狪�f�7�2L���ӚE�S���c�Bj4a�xsL��������b4��n��c�A�;&��=�z��zW���&M��奏�^��<
{PD&�]i��Ҋܼ��o�O�#Dt��B�o�Y�"�t�����v�������`,��SpS=H�?�Y}�s�R��5�$�;�}
?�oDvȳܟ��R�lZ2�P7"��sw��Z	UY�a4xP
�r�%�����#�� �3�L:�_���k��/����:����P��s>ǭ���P���'^�^����BǣhYo���)��$U��1'���B�\Q�ׁ��>��./zK� 7��i�51û�j�����oo���q=�3ӚJ$����ɗq3re���a��S��H�?DR��˖#�(]�K�:��s���$h�SM��-ȅ����s`i��9Y}�&e�� �揓��\��g&}'7%ݶZec��t
�ܸ�+��)4�-��in�)t3H�>/>�F�A�$��Zz���yb'ʶlj���]WS[<Ķ�'>����R�[7�*D��B>Cpp
*J��C��� �b�c�"u�
�ʣ�˱��F�6��F�qS���)?�cy ��TY��#�A�ƞ6�#djZ3}��uθ눷�	/4�;p�y�V�"�w�p���d�G��g����D����Y�կ=:����M"o-�4�>[yN��L�<����ƃ�������^&X����KEq�p0��^T�4����$��M�����l��k�D8�}�jZ[�;����X8j�6�i:�f�$�ztc�k�������W�z�$��]�t���s��"^����3�!��d�0Dk�%VB�c�+T�~�#��M�&�^��q�'�����r���5�f�y3=��·�d�ڼM �6�,�{~�"�H��3��EGl��`u��!n�P-�UKsR��"5�t�	�����)�Z\��Z �����I��O�Md=T~�m����ߖ���������w�w�")�k�<���1t��rFp�-EKu͆�Lj�@6�����\���\�Uӿ��B��-m��}�q������ZtZ@��k�73��m8e�}Q�e;B��fy+޻�W��.��^�֏bL=��j�C����}�#".[����93�,Ko�,���>	�����9Ǥ���z�蕅% y�b!�[�D���8h�)/}\*?P�w�`8+��]�W�����%uD_�4�n��Aݐ�����H*^��t�&�+��A߬������&;�	=��P�9��H��     ��n�� ɲ��������g�    YZ