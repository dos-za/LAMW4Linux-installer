#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3713781597"
MD5="d718bec3ec53f6ef82f0baf424342dd1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26628"
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
	echo Date of packaging: Sat Feb 19 15:23:27 -03 2022
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
�7zXZ  �ִF !   �X���g�] �}��1Dd]����P�t�D��� U�F�9������@ʤ�ܱQΊ���S⌕�"���ބ:��&X�q� .�HY�ڌ�نq�����99G=�1�r!� �����%G��C��ƥ`ENeb�1���h�qM&L5Q�iI/�p�ynS�&-�Ba�.ٵaӆO����	Q�~��[�K�Z��V�Q�Y���E�XӅ)�q$R�����1��.��Ia����e�Jwל`Z���ՠ>���o{1�ó
���t0�S�O��Ҽ�f�&��d����ǩ��ȼ�����Da�9ꯢ3�񟪀px�~��~�G�l2�n>��,	2.'R"��>�:OW=7jv��-����>{ߝSY�0&���Muyu� ���[�M���~�t�bz�3�,h��Y@P���JU�2)�N�Xu��$б�u��wH���Z�q*�x]�H���4�E�q��%�@����²�)ER�\]�w<,�����P��c��b>�����C���>��|ʧ���v�qlA���i3�����XW�O�Q4�}YkU��)g�Oo�[�isZ�'��C��-/���y��t�k�̹�bAH����9��[d���%��������$�D���H�flSUq7 k�y-#g"�r�j0��RmUBghDgD��
��Ȁ���]�!R�����o3:R*�v|�9�j�i���2�F���ɉ��,YT��� �XLe�y��!OW*[� �o%01.�iֽ�?%�Ǧ�f�L����Aë�<q���-�:{��>�6� [ٙ�6���yp�tNS�����j���Ee���w���ݐ��GJm��&CfՒ7����ɉb]i�k�� ^�s��߹-�L�m����ol:��ˀ��E�*�)`���VM��$�<�'�*�S���߄�zTI�A�hV|��>���r�)zvT�7�a/Ycx�AJc�N����O���qh�xQ�8ӿ�B?/	F���o��@�z�t���'-߉H�"�d�q�%�3h�4�e�d�Q�:Ƒ�+ >����=����|�#P�
�xw��v��i���(��!��8OWv�q�)�T��<��֐0�v��eH\��qCXtSM,��a�,�D�+!U���Q�;�l;�_	>7*�W5�M7�Q�L�w9Q<'STz$ͩ�:�6N�:�k��t�Q�o:�ŋD_n�
�1�.�~DݵD��WP��G1���#�TɀG*>9��Yfl��A�Ӈ���(�#��@_/��5��$�M���(��|�"����~'%��z`�-�щ4���!�J���P?wWEi{�8��:/��G����}ʿf��?C���n�wcD�������aUS�y�9����g�jE�Jvh�Q��V4�K�a��,�9"=��n~��%�������e@��1f��5��f�\G'(�+��,�^ϸ������z6$��wY��]��v�|�Sw��^D�V��5dڔ��i���_�JҺ�:O���*�j�:Sj�>����-r1-涃�1��X j�P��5��c�[J��cBF�~�(֞lI.&��
�Q���1`��d�b��h����{�x��
I�����-�7>V�0�`D�'j��QYwTQ�g�˹�Z�/k��'�����㧹�N���<o�[��k�;Ĥ�0l8�ixRJ֨1ܕ�'U/�qF�"`�m��� �Ķ?Z�yi�[ʮ��z~S��Q���?�!A!jH�g���6����ɞ�k�RU��j3h���sw3��:z��x��04L�p��%����tX�V����޴�Zؠ#`���u0�ˑ��9� {�0�xKJ�⏉�������S�E�� 7���yP1�Ye?`%�Vw+M�x���l�r{���s9��n��"�q#����H�n/������J^��@��7��+��ܠ����s���A�I��Y��r >�b���
���1A,�ٵJ&����[r�
\N�VU�vm��g��D�/�/��)ƌ���vP�e��A5U�כ_��H��HM^Cռy��7������LIz��� �\O�H���
Pr���������mx�����q����w
���iVw�u�`�;��?NTX�$>���0�0%�����S�9r�߻��b�VX/�����FgQ���z��d����ybK|�_�I�nx��R��ӘW&o�~�wV�ie򘎬���Π�x�$ �l�LwH�hM�)��Am~��Ec�	�uE>e�NmJ3"���;�~�"�9���b�(�L��[�`���:�╟��2a �F[��L�Z�������Ygt�a}�,���ߦ)0.]R�@4_2�	�Y6��SZ3rtPKbୃYWX�2��/�Ċ"@��s�q'}��?��O����Q^L֊�4�j��xg��8U�ˉVL{fK:'���!k��<_c8`S����Zw���f�Μ[���j�q;T�M	�Mn#%�Ҝ�p&--=��&%*��!
��FG����ad6i;֚�T���`�%�m������c'�g����/:�nSP����!.�`:�/ ����6�O��[	�Q�����cfh�=Y��p|��}QO��8���pc�B�������U�
�a�?d�L�=�z�]t�8N���yHlΘ؉3��d۽ǘ����:�"2J���L���(Sd�%�� �1�lU�PRܘh[��QD&|���0`*�aQUxA(�u��BY����gEm�>��5�?�z��������!Z��zS؂<�I){�z�]�N�w�J��'ѿ���-u���m.Oቺ����v5h�va�&z)#*]��!Nǻ}=c�uR��<��Q��3f���T���N�� �s@9��}&��/����2�,E���-�{�}�sC�b�$;�b-���Gz�0I�ݯ��)�������}�;.��}P�Ѓ�����`����v�-е�1ݼ�ZZ�/y���Cv]I������d�M-)�Y���t
�Y|����Կ��.��B�#�I��RJ��T�J�߃�ޠ~4����b�*	�=N㽴�)��x�m�UQ�ϝ����w"�VR��C��S���QҔ�����T���:H]�O�)�r_?�|�.V�5���ڱ���N���G�ڝ�љ�.�$��<Vl�����O��ݙ�ǯ1�{d����u
S+��L��nk=T��]�7o	�d�������5�4�;Z�@��1���\È��� ��+�lo��w� ��o"
M�^��Iϒꖻ�����W���&�r�2��y�O���s/�UY|>6��Ko_�2�oT�'vF�G��������}z:#"�0�r{>�W�/�iq��9�G�/�a��x�5�b��n��|�n�)���0�,T�KC�����fb?|:Ԧ-�g#����O����{D�M@;)��F�Q�����q�qRxN��Q��tVbѤP�Oq[�Y�I����@{�h��J�t������+A�.�ZN}���c������kN�+�)��*�R�pwh��X�Q����9��W~�dWYz0�jJƆ� ���/��oԡ��>j#j���D�%
l�1uchȕ|X-w�w��������k�Z��3�=���i��p�m\�ꧾ�7R���V����K�=MFXp(w��R#�XB�X{��\��P��)x���=�'���*ܔ�K�s��Sc�%���z�,�ʻϻ���$o�{g��w(��*�����by'ZĶk���9@&h �=�����:eu&�"�{^�hlf����:��������B� #ֳ�B�q�p��c��i�bn}��;S
���&�Z�ҏ�h�?09��>�3m��@�ډ�b܎�r�~1F`{ͬnKl,����/<�Zf,������C�MC���d��qO��(��`�A)��h2K�?&{��w�p(IoՎ�}eEz�]H���v��/W�Kő�Z�V|@$}̖���-tn����&��]���G�����m�,%��W��8κM�6�ӆ��wx4"+��6�|��.�U#�1�8���)��j����c�G�@����Ui����Q���z�v�Zw�"������y�k�xS1���Q�>.K
�V�4�K�s��SYa��W��Z��N3.�6���G30�����x�j�!븕8]Bǝ���y>?��x�`�N7�s$Q4o���+�k��{]�B���/16��z�ʛ�5>�(x�D3��FX _[�3�,S�V$�H��N�ŵy[�YE���Q�!֔ߧ�Wj�rW�L�����G36<��`�'G�Di�c��D�]}'ז,��"&O�˚����Cb.<E�0wBd�H��ct\`��bt|w��=�_��F5N����T�p)ܡ��I+c���SIޣ��5E��!ݟ�H�7\�>�<7��风��z��a���E'ë%�i �˼�cX�2�Yq�S.��ЋT�Am�����p��n��dx�^T� LTHQ�]\�H�P=1k�ֆpYڬ�˂��ܵ7(�m�H�ZVa�[�
Y �;qQ��{>�*>���ajc��v�`�F��ԇ�m�F�n�ؐe�ԨFhEC�F"ߋ',�0@Nq�zzP���:��CX��]�=i�����L%��p(����2+�:��K������򤞙�V&��VBi���	��p���mc$ �-��J�7��J=:c��,��՜��W�G	f���B_Q��4|;��!=��Q/����QK���
|�mתx�{�Z}׬Q�
�aoa���si	��e��ۥ̣h�����	t���U�B���!�y3�������c�<hY���q4aQ8���'��'�p�G(g�r��m)��V�ܭ_#K�B,��@Bǵ�M�����S�n�{��J�'q�2>�a�n���gvMW���+?�T�,�B S�=�D�m���'�� �4�n�0b'�vJnH�Y��<d*v�8��X�<"�|�%(�IsDf�_q+
�#P�o�DT�N��h���
NV��Dl#i�`{�ϼ�6bl�O���;Gp�-��:q5�6� ���8/⥀� 1��&l��P����q���g�4KZ� �ב����`���N+�C ӮLK{�RYLǽ�?�_ܞQ/*��\�Fx`�iR��0T:b���_������Qz��L��*������]
Ց�!Jh�n�h����Q�5^K�]���z?�N��Z<%3�>��A}��4���'Z+J~�<�����E n�����h��6H1�~)�t��t�' �g#�=��8f��f����2�ﱻ����g٭*(Qi+��q��Z[����W�Ũ�v����X�6n�ȰU�r�\�E�x��K��M�]���.y@}�	�˃=�i0j�����F��̖!�*����"b�1�c�T�VÈ�牗~�rR܂��oQ��5���)�,5qC��(��t���f��a�Ю,��.�<*tI�����Kd�����W0=('˙ S�M2���T2��J��=S��T7ox���O�c�+��E�̆i��MH$�lBMل���s
�r իmfq{�Q!��-�)�~��-����3���Ґs�qk5c�E�YB"�$��tSu��Y�)�l��f˫���ͲA������^�DLF��F�6M�۹O�z��J��Y��J��/I�=yp���qpYu���.I�-�_X��o�=߭,��cG�OѴ{B���mL[]�B'�h����~�ϟ��1�[}�o��P+�u��8	�P[�2@f�m��G�������9�T�?�O�@Q���>
wt ��C�x5��:F�ɛV��P����%�<��`T��jX+
�6��C�.��u���y��7u#W�i#[�*�7��p,�(����j9@v. ��d(� �P��2������Ń��R�B����qS� j���ŧ�a>a��~w�O�D��WI,]3C������M��`��J���A�_����,����_�!զ+��W�?�^&��9�����P�N�$�_������:"Ơb�4��[P���������0ɴz�BV �SY��a�����V���G=S�-n�o�/�Z�7���h�
9�ȶO�(���:��ֲ�Z�1(h��pS�ZP���wY�C;Hj�/j��&3{�7��!(�͈?�%�n�9�R��%l
6�h��+$w�$6�b!e��H�g U,&������Y���Ww�A�]WY�9���~ĳO2��|��>�qW�-^bgY���[����dx��q!X@�=��P��$�+�7H}�;�����eQvPI�RLy��Ƭ�>
P�5��U��n�2�����#�那2��y~�^w�B�{;�u*�WxI*Tx�L��Mi"��qÿ��M�X-�%��ǣ����������[لIې{��\�cuiv��%���
�8p�첅���p���V{#~0�����iT��V�(R|�tt���.(�֯�{��(���5�Y/��hv<:D���ƃ���Z�Xz���ec��>=d�.�x���<����O�^�.�\�VY��*���(��� +��rQa4����:���L���fg��m1���Щ>�Ɉ�>a傁����2u���֗�8�2>F�kR���&Z���eOjҗA|^[#��q���#!:�g"�в�s�of��Q�\�QԆ�
c��`����N��S
��<KP���m�/h��h��)�%lo�x���	z��[�Hp���y�X��F��i%��\=1������Z$0�\D��PA8F�K����^rv@#�Y��\���~���׈6����q�G��aWtM���H����_�^_��\�#�;���G�� z=�d�y�����D�A&k��1�%�׃�ᡠ8�_��ٔ!`�fh�w#�viB�v��p����D`y_�B�>Vn�&i'6���"SI���
���3�l�fY��6�!�C?�ǈ����h�-�Aj�{��<�ưةMF[���YĖ��	I+�}���g�a�O�<Cg?M��*ڞ����IW�:�ϹbݕQe�]��h�SU�59L=~y�/����[9J� ��.�\��|�t; �(%i�r�f�*#�gؤ�QW�e�f��-u���z��>{Dxޙ��g]�R��T��޹2\�y3yks�L�Vk;N�H�y�i�s��hw�� .v�|��V��^��Յ���RG�,�J��:x�2���c�q-	d�ĝE�7Y�K�s�QH����t��r�C�
���q�x<>�U��h�6��gsh��R_��Qc��l<�%긥�{6]R@n&�zDf;F�M�	.r 2��\gs��1��cEsH�>0pv:�d��Rz

�K��ns�P'��՜���ibN:�e�Jɧq�D�)v ��������c,�8���偔��[���0�)�8Q�*n�O)�V��Z���]Ч��-�m1o\*Br�0ה#ۉ�V;݆���D����p?�p�$%��(�Y�6Z{������s�G.'m�|ˤ�ayb��Zn.�<e��|0�뇼�@���s��~?��ĘeCc����e�������W���Z��2���D�,�S������8�T{b'M���RGmO�?�;�ȹ��"��9〔��`i
��݈y�6Fv�\��TF/�X��9	ƌ�~��u��S�4�BkE%��f^�e������^��*�Jӻ(b��f��
u�K��-dK�ٗJ^>������x	�����=C�Jk3/-lXfh~ſS7"�%}FIB���Α�6B�x� ��L�Q��7B#�vTE@<�9�/ɞ�rx\p^@lځlC;��%t�H�`S.�x�X�#��3����N�4"4[���'�� ?i����W�`��/9�!��(A\��@P0r��L�"�s)�?�L�F��_c���"X�H��3$��?n�(�Q����c;�^73��Cb|�@|���|��[����7���dVC5l������S�I��,QP���1��/w(N4K��Ue�r.j�q�Jb�s�.j�I[� ���Z�#s\ˀ_��}��q�v'C�n�p9�u�q�2�&��Z��5<���=[W̠pYvT.}��jm�4�.�~O��|͗�`wl#��y�A�Uw"v�1ˇ�E����*�;���E?]���pKcD}���F
V	�ach��#��� �7�l�s-g�޲�+Y(n��!���G�v������CHmBmmH�rZ�^n"���Ф�ޭ�/ܚ��.߸�O��l������y�0���Cɡb'Ա��i�o;��� �10�<çp!j���L6�B�p]�<#��s���O��7�c�0R�r��Y~����TB����[>��ڎ��75�u�R~�@~pN璮\�ev������	�R�,��!�?�,,����督I"�L� $G��;�Z�R��G�ٷj!\���&��<���i�*qfȮ->9�̥J��rK��uΓռ���KU
$��6_�>��Z��z�	�f����:M��z;ˠY�\D��~��ص���3?`9	ٜ[^kcŋ"!���e��h�8ڊM�0�4���� wv�wBL�_�=(ԥ%�9;���d��L�i�.{II�p�(��1�/�xa�]�O!\��9˫�:� �s!��
`����ӣzRJ��B�m�1S�P��kU�W�+���s��(>����!X��)�^�u?��G3�n"tu?^��8�b�1�edGI��%��Վ���b!�:H�U��:��� ��eXL!)����$=���Xd��>�e�3�����F�x��s�h5�#?{�atM�X���}�/�z�zB��2���sm�s��R��qj�ɢu��8��;4Q�m�����sb�֦�1�p޷�?���!h�(��c�F�s��/��y+B]ӝ�t����@t�ʆ��ݾ0C���������i����}�?���"���>hiN&�s<�9�FޔC�־9+,v�z_3�Z{s���9��F���?��h�C������O2�3���gpK�c�5���;2o� �ŋM�I�R��{�?��1����fA&�urE��%����Z���MAG�t�v��"_D_�~R�Ŗa��+\�]����f��4̃���c"d�Xr�vZ�uzVף��7paiU]���z�مS��r�;O9����=��A�k���P�4HSa-�6�hX�!��}F�o�	Q;F�[c>��[�"|g�#ȯw:Gw���<�&�d��z&�V��*Y���_�c}B�Yœ�&������ޛR�'�s3�i���s,h�N�e�\!�PC�@P�_�~J]s��:AV��_�#�=V[����N�2�����L9�����0���/��K1�D&��C�	H����ݠ�p��%�@m����v���ׄ�_�Ks��fB3��e��Vݵ�_��T9�R}7鹾& �G�����.õE���e�"pq�w2�w0i�uN�dHJR[�GC�Ȁ����VeH��)�6&W�Z�]V���Y�np%�VʋeL���eV~Kn ��Y�1-��C��+Wܠ¬5��2	�����ԿD�wÜ�/�~U��ZP�2�u�n!1��a�T�O^�hL�(��&Wb��x�M�Vi]� �}��}��6et�.j�������U�0?�/��Wt�M�)�qX�ko��%K�V����/��k�0���<�r�*hkH	����5�g�l)�	��壿T�ٛ�ts�x��ԑ;w`����(7ߝ7�k�����8���V�S�	���b���M�wR� �S�Y���y'��U�Z�m��w�aŢ����e5JUYkH̯0.��Xq@�a1��g'�cF
Vb��8��O>�������;�L�,��})A�=cP���Z�z����=hK��k"�M�R�m�7I.I�y_d���^��-����߯^���>*G{<R��Ё����V�y��*��X�k�{
l}�N��M�#��Q��C�f�s~rcM����
O�_r���SI,�o���[������������T/5_�a��`�}4L��P7�f��w��հl�����g}~R�@�} ���}�!T���X�1��,��2�<;lg����o@�$-ʟ�{2��CøCAT[X-.��c�x���L���B�n��Q�L:����̀�$�1�l4���u�c�k-�.Z���؁���J�y�Mpc�r7\HAB�3]���ƞ' L��4_s����$�}��3c=}9�L�9-�[��<�s����5z0�(U� �D�r���ǁQ��>WJ��>#@n�6_ �%?&�>@ �N/�����E9ØQU�G���yL���l����f��kU�X1A�.�R�:(b<�
0(gC�R_Q"�������Yy�J���sx_���O�v=�V��v��R~̕]����	����E�K��MLD׵-	V�҆Pw� �E 8�_��};_���3�|M��ncOUp�@�}G�&=o��a����V3��	JZ��?���lz���p���=_�c=B�z��(F)@������(� y���om��Y >�*��)��9'���(~�10Ei賓E�!1���jW���������Ť��o1w*�-���1}>�5����.�ͤ�(����.έu��ww�p��W�ׄ���,o�H�W��~�'�����W��?W��B7����ɝctO#T��6�b��Z�C|�R��gU�%��Lsd�L���qϨNSZS)׾�S֨�HX]��TA0��)�ԌA.��6_�@�����3�y��a0��D���Lc� �0������1�d�
��,8� НE]t��X,1r��+[�C!/ܴǡ�*�.���Gl�<2��6zB=�µ1ɼs�+q!�Ib{z�K4�jWQҿ�\U��5�M)s�m&=N)�(���9��r�[jC�ff�:�0�"`����|�ց�������_-�X�H�2�`1���U�H^�Us����g�����B�[�Un������9�3Ѭ�r��!��+jv��:<�a��y����pc"j �������O�����Q�I'�����%&}Z��E-M9]�SYT��4��DL�p'�x6�f扜3�8��wͦ���嚑j�آ�M�'!��B�;S��s�[���ι;�@���[����eL��\R
���<#O+��0�`z��g�wۍZ5�YG()��7�(]SP��ĨAL
����`���G���l��[-�y�C)�7^�%�?�eFt3X�ط��񌑿A�݄!�a�\DSv�]�!�^q�E�� 2I8��A��Ҹ�1��>�
�W����̖7sNT 2��.Wb���f��]��+RU<��sב�Ef,+
Kw�D,�
s�tl[	�:Z��m��hm�.�0u79���ajḟe�T(��%g*�������/�dO'��Z+�H_&�rP?�����@̎CXY��9��w3J�"S,���Wڲ��(����d$�d�5�����i�+FW,(Q۫�7��nrKn��&�_uҚ\�(U��n�M��� bL�O���i,
@d\a�� �f��xq��;l�*vD ޥ�4+�m��&+�����=�~q7d�[3�Ź5Tq������ua�L �7N��=]SL񷽸�5�@6'�A	V��ݜ)�荷Y��u㏅:N��(Xdo��m;��G5�eR��v��P�_��[�Z�������%��@6��Ɖ�j��CV�)�7}�?��1�"#]H�|�\�ts5	Dd�_�?��`ґ�cQA�*�c�\|��c���c�!OH�v�Q%+qd7�@ٌUB�}dZ��k�HW�"��9�G���b�s�+��=� MMl�,��������X��D�)�p?�Ƒ����@����x눂���%uN�����������/���1��a��ͯw�)<cZ2��wh3���NŰ}Rƙ'���f'y����U��dnq_:Q����M<����"(�NT-�{h?�DL�P�N���w��궛A�!����Z�iF��P���9�\`9�������%����L�[a<6�НT�t>��F�y��ĵ�-���i��������Pk����&^�V-�lAJ���W���6
�d��Ps������e44]��MB��N �5@L�Rx��q�T�!/��Vс!��_�Z/��
��)�Ym��LY{�>+��<�٫#:�>���nm�,���$ [��3u���2�f���wNëi�2u�:�]�>����(�g�ȿݾ-ޗhy3�D,bs��a��a'#/�;b�"��3�"��Q�$�N�|Y<,��	S�H�z(K��_p��w!hF�R�ٕ��F��������!X��u��}�!��1�U�p�D�1��fL["7��$���I�Vn!��+�E�5A>jQ�^���%-8I�|�>d�*�Y���z���u�3�7��y ���|X-w\K9ȗ`Ow�ّ�u�J�W�)�͡W��7��Ǟ����ذx�*j+�<������͍p�DE��v�B��"�1ܦ����i&3����-=[��U1G�2BU\Hu����'z�Y��Dt'N�u]��'��Ϲ?�|C�Q��IR1�[�OS��-?&aʢ��v�/vJ�����/��ӈ�3�f���T��'|�K���/��N��]^E��:��m�L�%��O�,����/J�/�,�K4n��k`1�4[F�w-(�Ӯ��H!I���ץ��BP}�r�7���ˍ'f9���#��Lh�BV%F�i�q����x��(�<�T�(���7�8�9��/Ѥ
�q��%���n�+�s���˨����Q���ۣVK%6��v�Z;�Neč]Zg��{ݼ�,�ǁJ�X�����M	b%`���+F�eGl�X�b �Jݰ��H#�ۃr�4Z*y�����
M�R��[TM��s�u�M[� 켗��%M��eM�Kw�P*����f=�6�Q����N��|{jwt2�؅m�Ri��9+K�v2�u�N/#�b��آ=e���J1�'�ث�����N�A���dl ����B��j�x<=>���k�"�m��=�ô��-�$l�o�ih1=A1�e��^��0av-@|�Ĭ�I:��V=������%��_ �+���p�~ܚ^ �.:�n~sW&��c�}N%�Q^o��l����9Ƅ�Ċd����Z�Ճ������:�_�K`���=Rr&f��?���H߿��'V�`��(>�ʮ����ԯ�b�j)��M���-6�U+<�>@W.�e𼬎s������`�	�!9C�Pv�S#�E�����5V�_�iL� �r��ȱCU�~L�]K�d�?F�k���\����K���	f7��Ą7�����H2�^/ث�d#�ƴ��p!Y��Dl�oz�X�j�z�ԍ3E���
��Jf²wj��HC$����P��E5`&���'������]R�cI��I��O1T��Ҧ�d.�v�M�r�=�y��oH_-3�; �;�L��d���b��P�1Ia�f(#���xaC�h�w��1�%n#p�7򚵃oP�S]�"78j�ɇ�Û��x�@��e�AMk�ꣷ��^^L#��FΘ� ���	iB:R����}���*_6Y�?C���(q�s�	_������)c<0�y��Ro�&�2��N�L����|O�E)R�������\kkf��eA�����S�S�Q��P:�ȳ&O�PW����Co>�����5��	��-پ��N���s�=-N�Y������:!����by��xC��BԊ}G��<y���7o��
2���-o87W��t����s�U^�6��r�PhԈ&����'��IER�C%5Lm�_} �o`����?Z&_��xr�X@����{Qgo�c����{}�d��,���	�9�㰤n͆"NAb��m��}��{�a�h,�`0&{Q5 ��|N�P*R�VJZk>Lm�[y�H+��7 ��cS8B�Ħ���q��(�n���]��|�TǋG�?��ec�E�N�!G�B������b��C�[ʴs�ao�^��M��т1�����<7�7Z-��!��]R��*^�w��"����R�aȱ��Y�<<��׌�Ԍ���.�Yo6�����g+�����O��J�{�G�ŧq����z�Ts�p�.KO���"��ΐ9����=�q��v�S�F;��d�h�A��;��o- ����c��'�KMm���3��q�Cl�M��'Q�d��J�U1�073�#�m�ET�l�GXw��}G���ҷ#Ҋ)7����J�����%����"J�(o�bE���ܱe�-�τF�Q��M���8\'����q����.��L����{���J�~k�T\����G�*0��:��_c��D�fjE{s�8�Ɍ�*���Oz����e7q�Y=�A��H�F����!��?�&��@�)�RX�M~�UU�_o}R���	F[o\��ܯK+0O&� �%�%�.u��WLR��65y=8,�͒�p1�n�,���;��n�t�*5ZU�Z$�ɇP�3_�U/tu�����4�%}%&����T��	���ݘ_�)�Z^C[���D�R���ݳR)׋zk��;�RԐ[f�4�mdy�Z��B`\��M	@�֮D\t�O]�3���)�!�h|�o
D�bE��w��2QEtG��u�����!_B��8�$�*���%�հ.oO�=/.|I�c����e�#�_xG��F-Q@sq������߾�^���tQ)����(}�%�&���Jf:P\Ww�ØK����)
HB�㇠�07ȿBi_�S�Ο㿔�k>h?)�����E�YR=u6R&_����$,�da�9�.�}��iJg@}��!D��#D�c��7L/��u~3,�u�����pNuKΒnU����!�б)�ƽ2�?2���U����H�G����k`\DIB ,�=
7�]��C�`��$��_�na�l I�=HU@�ߝ�-dx�"3��.���Q:��2�f$=�ǻu6��՞fѝ�V�BЙ��沏��p|�z�Q6���~���������f�v�: pJ�Y9�DhY��(~i�C�/mrj SGd���Ŧg�������X-����Y�ʄ���?l�W;��M��^�Ƶ��Z �@N./45(��P]�B�O)6�S��>��`W�yi�O��%�a�h���Q���c�wҢ�Б�!�వ���F%;O�B+o�M�ؓ��oE��6��`���X�z����b��M�ܡk���j�dm�is��G{����QMcxߕ�R�BPs�!�Vn3l�c�4�u�&;V�@��Ғ0Sy���?�w1� �q�}���(�z[>t<$!��|��IB�DB��e�X5���S�� �����h�.���$�SX���bL�CV>�x�aL�-.���DwU�O˽LB�] 2�f���z4��� K���g�<� 9?��d�L�3i"��͗Ъ��t
�	�7�xX�\��ƃ����CiE�}n�)ɜ6�_ZZ ��h���au�g��awx�{/�9��Q���\��b��������~���3�h�;�V����xd����s)N��p���'79
��<q�aL{��Z$PDI��0b�AUS���`od��{{�&z5Z|Y���T)b���m;���܌h)����>b*�i��I�M�rL(�  ���  h�4����%�<Qm`��� |�vļ�C!��U2����љ�&�H��@�H{B���<����]HT���W��%�83��#��V��nQ�����į�S��ӡ��d�{�P�{=2�����Ч�CG@�4��&&P���udi�&�2&����ޢħ<�K�Tw!^G`z�����	|���w�/�C=��&PN��>�Q*&����r%r���/�^6�O�]ׂu���dy�3�A*���Q��|�F���q����?���y�o��q��
�@[PT��� j�&��qJ��wUږ@鰂&Q�����$�#�={~.Hd~3O[S�mS���EvY�ͷ��n�Nf��~�&�ƛ�R�G��[�Gq�j�I!�p�Q�c�^�Q�r�+s׻"&�/Y��El�-������`3gەC�P6@2	f�Wz��Ԍ�����Z�M�-@�@s���B�L�:��h"r�1���~+������xr΅����By��8��N�0�d�E�w-r
U E��!��%�JR� ���)j-��-�]+�y�P�ֽ�Ew!��+�6��
���9tF9�>1���q�K"�#���O�_N������ÿ�Ut��i�V�^g�Î'�/b�}���O;�r���Q��Ɵ�$���қk�,Pޓ���C�&rl���d������u"��}���B�^�W'�kE����6��1�ˍ���4��޽��I;��R�'�0cPt�#	�T8Z=����>N��.�ô�x�6�]���Qf����X�I&+��k���D�K�x�d�JB�\c:������V���V�埫���/���e��|�TLaC�	��w&=(�T1%� �LM۫d��C?� �T�����~y\9c��H��ӂ��!�'7�ݬG\�.�N��V��:8p��-|m^��on��GU|�4�ai��+T���X�<P2��ϑ�*A�M���M��O��  ��<�xy�{��W�
�%Ie�fH�u��5�Ќ�\Q����3Ɔ�\-0�f��~b�G�jNHZu3����蕲�e��E�J�_��@u�$��H���\}o����,7�e"��@���:�N����>��ڢ�гC���7��4��@��4*01�[��l�տ q_.k �*�	 �
�dL
}l��`
�j�~ ��%o3)|0_��4A�u� h��Mσ����U�����x��
�L���{Xu ����w�N��}-G�7�(���~��4u�����^���ܲN$5�Ld�v��ؤ��t/fM�q���yԤȓr%!��*������H+��R�8"y�l؛�ڗ����hoH����}��CR%����g>xG|�Y��$Z)�vE�>اSc���,�0ˣH���'c��!/��F�"���Y2g	(��4��Тz�M�>wϓ3���0�#ǭ�9D�N�����s#��p�,��	��OR�|I�?�,Iշ`�["�[�x2�e��-(+h�m�1\�KƲ�5�[�9�}4q'$/P�=8�7�m�-���Jur��~��#�*}V�fI�]���V2�������Q�܌U%�W�q���ynhk�\4�ޙ�T��os�e���h2=o���N  Y��<�8ё(�{~�E����<j?+&�$�l�h5g�^rv�ZWZ!�1l B4 q$o�� ���|�|X@]��5�So�h���	�g����(�/!AF+p�n����g� Y�+��#�5�����X�@!��dC�G��e]��} �ib���pj�a,m��l�[$��.)%�����eœ���q��������2wڑ��;t�ݨvr��:�2��>�bJ c^�~�5!�)�80�{7��+1�I"~	�	���BN�T��Q�ǟ� c/�L)�IZIt��/8!���4T��J�K;�ZL�m�p�B�ȊZ�9��}�'��3��T4w�5\wF�x���,�	Γz�t���u�[M 1��@�ճ�v�|�\nw͍'��ߒ3�$q���L"F(\��j=���3v�};��
XX��R�k%�1H	8�vm��ǧz�Վ���C����$#q�b�ݣ�g���8�6
A��\ܟ���v�(�0��HE�W��'O?�o�7�R�C0lʎ�f�nw�@R����T��O���)���{x-;�<U�#�����y���c�2���#z�F�6��6�G\%�!���x�g��t�0��@���rD'�Ԯ�6E*���R�Ey�j�\'�����҅zc��t�U��0ơ婹)|�Ux�INПH�|���U����g�ޙjm��][����p#3��`��W��ׅA[�0��s����V�����׭3��ѷ
1��(_Ts��.��f���)�gH�VD��.�&6D�c����ؓ���'��8��K�t���3.�"���o�_�`��%�0��2�3G8�����o,e��S��*�Б���A�
��ʊՊ��-�gi�7��[�ӥ[h�7�}��f�c�h�Ĥ�+N�\��M�d	rdP5D�����8|�8��ؒX�u�
v��A�Ƥӛ��K�YE��'��s�y�`D����:��ĥ򁦘-�j��͵��aHM�O�u����}�� V��蘎��r�i���TJ�S@0.��St{����&�$�UPj GφL��1t�G�T�!�*��IY�����d,!��*��[`�I��&v��!ӚR���}|�ؚ[eȝ�����tB������r+�٪�α[+c9�&?�\fl�B�(��B&h����أ�!�,i=��	W@��b�v�W��bSh��Y��f���p���h�T�T*�?	0�3-n�M�p���	.���?���W��8U � �Fy�$�'!e��-������.������Sq51�E�LQq�[�W��8�l!��{C�� Y�8�a�q�š�^|&�uz��QU��&a��� ��A
����O��G��P���R̎��at�}�Tb^��0���ҙY��a�L����`oh`G��?b̡C��

ݭ�1�"s�Rr�H��.��z�)�\
�7��z�+�u?�����:^�7�ԩ����#��X�C��ƴ�o�^����F��t<�91�r��B>x��3 m�Gp�%ty������2:j�J������M{��n����h� ��648�U{3�-��;E\�"o�g��|!�(
�E5O~�5�D�>�^��	���5�7��,_'����I�w&�9Cq"�?�R�J&Ɓ �z��D6�Q�O��Ro^���b,@<^�f�j6=F'����Ԇ3�w+,�<�B��$W��]vNBҍn1��<�ۜ¢�>�\oZ�^K���������{s��%�V��%Q�S��!3���#�:'���ʅqB�J�����A}�B��J����L?�<ծ�f/5���d��|ds��{��K����c�?@�!�i�<�m�Òk���.��t�D�{Q�����p�����T��E_�[A�Zy�g����H䨽Y�E%S �gt	�|��t�l��E�"��v7G������堣�����\51M}�=okG�G��O%���"����`���ӝ�B晗 s�b/���
sz$���O���K�eoD� �7�KK �����P�G��aǾ����mA�N�����5a{��j	@V����$�w��� �\X�����o��"���E�a�0?��X��\�ᵷ�|\���g���$
�J���j�z��`�� �I-Bfl(;cύ��޵�$m������qi��`y;2�<v<���Z���R>�=ͳ.X�e&R��Z�u��C�W-9d�%.� �4�M�u]s���(��$��i��tg�ic"K3�)�k��20��q�)!�cƜ_SL��)&t[��7�O�~lj^�F�L�'=��f���o���񸲮w�e9\�k܄��[����4��rI@��y���Q��-���
;Z�rbJǇH�kM�P������P`�#P�I1jN6�Y�����aP<�;H����|I6~�%g���·�هg�s��G��]8Lm��$D ��kK��i �f+�zf�
׎9��h�\�MO	f��b9�?�����?��g*xԊ��O�c��<�r��(��6t*��ur��#*�BJ�ѷ������I��O[�Ø�Շl�%��f��͐�Im'ܜ���5x*�~�5��#j��݉�v�)z��G�,���st�T _�7��xg���z��X��)yZ���d۳t�ZT����z�\Z:�~��8��?�Ox��ie�2�Cʹ4T��W��G�q� �U@�B��Aɵ�_9��^ڰ'��n�ly2*C�����%����]�(��6��W���}�>�t3�9PH�U�O�k/i1����xh4���\=��w��,���A�r��d�Q�}�V9y楱��)3��S	�ĺ���
�ak^�ut��lPW�I4�RSj�֔#8�C���r,س�9`��32���H��*���(�]��� *�_�1-���'�_���#2�_�������]���Y��N�R�K��%�bx m�w�:�Źp ��3��+R2�0B����N��
�R��~ߤ���F����~�AWwЪ��s��źlW,oK(�݇T�6��Nf�3��%J�Ώ�%R�(�y�4)��K��t��o�c�������=oPw�}�]�e�PK�V���P_f�d*�H
V]�J�;.�d�_� Bz�+79&4�����>7��{�J�"�|�D�iL�i!��l4N�a��y/L��a܄r��2�����$T�rV\�у%�!4�	���4u��@�;���O�(3�!��Ջ�cwfV͙��'8:��	��K��𘖈�T_w��fMzTݼ�bf6Y4��SF�����a�(D�FvVȼO��3����G�;�.:��#��tX��2cmP���\c\ŮҨ|nm{a
�I~�UK�E�C��M���*�MlXΆBo�I���n�K�VΣ�;/xB��h�������5a�VoA�cG��wU�<��Х.%��YIa�o�y�Z�{=y�f�ȷ!��vd���~��m�A� 9\�z�=|>;��Z*Bm'����"�	X�(yV�@8H�Ҕ� �;e��3*6hH/��ժ{�����>�(��:o�nYeS�c�_/ҷ�����Tw�sV��ԪM?:�L�3�)C~ŋ�	;��T��A)8��4e1>� �"
'��2�N�pv8
��E�EY�o�d��p�w�eP��ʋ���P��������n P'O�x{?W2=�m��@aE�(Ge�h{�Xŉb ��1׼`�	|��'L����Z>|�\���	1���+;k�O1&��iܯ!1b?!��c�Q��u�`z��ѩ�ѫ#?{��!�ll���l/)H��#6��RnO��u���@F��ȡ�L�0��"Y����.�!�
� 8�RH):'+��?��9����e%9E'��6���5�nI�ʧ�2�>p�����K��]�N!T'#�4�� ���������:h���Uh���;��̛n�a �~H䒿ʅ�3�$I�*�R���5���ߙ�in���xa��=-M�����$�����ˀ�ґ� �2Wu�>�Z��q,V]�����i�zZ��|%'TQ��ǵv�}�.��_����6@"Y]DH�z��t���Eb���E. $���I�H�V�J\�"_�[�2Nf_&���Ts��v��B�_��f��z-����͈{9��}0Dhg��dѕ�IRH��;��r���R�^Q���l$Y����9�VZ/]�o��U/��e؀�݅��.�X���+��Qh�H����7"��!C��P��$0U�|U��]��At���H!k���a�;-X]y>�N9��z�Z%I�2\�e���Bʑ�6!I��DA��������<��P���3(�
��sx��Y��L��$i����N[ec�%2Aȕ��hq�i�V�n�ҝ���J!��R3�-��ĈS���O�n�#l�!Ө����bP�D͋�q�a䝟�Eq��#�3�S ��L�����R�6����e��c�a��'7�!A*��x�b-g�i<9s��x�ߦ�9-�
د)���n_X�.`�¢����TDA�"t��YNͬ���lM�6QP<P@���Ѐ��j����aa���x"w�ܓ���ב�f���Vp]��ې`�2~��*[��r���#�P3�Ȕ�X�{7D#!𣈧��s�Q�i�۬��q���9g���D{�
��D��~ɬ�א\�y�D�}wrߏJV&�`/؁�_����C��o��$����Iv�t��ӥ�b�3�7���o�
wDcSV����7&��;hn��D6��f�(�<"e
-*�|��J_N���0y��t�h%34[������E{9����bi%k%�2z��n�i�	�7t˿[4��;=Cg�Ӂ&؈��Xu����c�9��Մ��T@��Ix��j�3��Zݱ�NM��?�j(���)��v?��K�>G����n��ɐ�·�����
�V�қ�2��)��0G>f��F���3���9	��8�rȥ�-��/�:K�@��&6-��su��n�3��}]�jRGh�x<n���f����l�?�fZ���R�(3��+�Bf�Y����o�j���Z8Pg��9��@�2?|b�>>�,��;��9T}�ňZ?@�b�+n-F�	������m�E�0�n�~!���C�Vq��0�ԙ*MX������pÙ�:��#tC�ȋV�r�����Pװ���ͣY�U�ƾ�޺���j�@���\�3�8TX�,�CU<���ޘ�[���6g5�5`�����c ݷ����d#N�$������
1j$Q���YG-Q%�mR��R�~�?]��4dH��Jv�ڊz]�v$�x��H��n3�k��@��9�����ە�+��Fp_�|H�����o4&tp�mV^h�?h=�߭_R���ݎnA3U=䵵R%Q#n�+�����{O��	���q݀��r�{�ք>c�P��|�⒯0-x�N&����,%�2���aHa��@i�!ܣ����|�	�4z��BjlMZm�;�tG�9�J��1�K�0��R&��M�!�=�W=.`V)��D��{yv�y%���)�����)b�NX�PU�ι� �����>T���/~�ӛ!*_�T*��9�3N=�ͣ	E�j�7�S3��_��c�B4�ܭ�$b�Z��VrXrbrЅ��<��w�P�_
�6s4�Q��eG�Q>k2�:wS�r�R䐡�����O`<0aОİѝ�5}H��/@�\ۙyfI�l�8`���,��!���x��'E���X-@ێ~q���S
���{X���:�ץ�Z=e� ��c,�A�r	����1C�XGh��5Fˀ8#����m� �I㶑��zL:�<8ӥv5��S�\�<N  V^���s����V��L]�¥�cou++#�V�3)-q����@m�b1g
�\4����<Ɩɱy%�o��Wc�^��B���߿#j;�s�q��N�z,�;`��$�Ϟr����]�w�v�C�Od��-�j
�r?���S�=v8V֨���X�>3��g��fb+b���:�S�qJ����	,�`�Acq5��2�w�kT�0 �9�����3My��^+��ݮ%�}1�Q��,���[�������������24P�����L$�7�\��!E���՞�|y� t��p��<��-�<�g��غ)��	\%��g��KY��mn��k�5�u􀉹�@���0Igh��T�ę��XV����_�!�-���(���Y��T�AFD��7�:H0	��f�AFի�$H��iN����(�֥���n�o��{�/�Dѳ���|Pۿ78��ƚ`E~	Qa��I�q���1���be�܃�U�T=��3 ��{���c�J¦A��L�d�>��W��=��
REQ\�t��Pܬ_t�PJ� ���n�Ih-�g��/��}"F�Ǒs=�5g������Z�,MKy	]z�*#=i-D��7�����)" �
�fP����j(��Kǋ��`�yK�α�j��Ù%h�UX�k~i$*< �9�Fr�NM�&�{:�}�����iW7p����ض�B:�#�'/}���`�𫀧����������xQ͗�TU��3�Ж4]v௜�������l��5��������߸2�l����y+ه?$T�mԼ�5���g���$2�jb�}�A�h���ܻ�%�;c
�/�����!�"���l�6��Z%v�1p�>6��+�E�9&��)�`N��m�	R)ʀ���$σ�4uro��	�=��>�kk9<�#*( ��Q��9	�5',�����������6�N������4"F�2�As��M� ���ZV�����x��O���T�*�g��������N;�Z`3��b�T$���<��G'����5\g/gU� ��P�~.�'��ߓ�}NM|?)`D�&��	b��w�&��Č�l����:4I!^9����4��锲SM���Ԁ	`g�\��ku���N�K�(%M�U�9<q�ǎ��e�:[��wM����E�� �� U���C��/�A��z���>�j�DI�f���7�>�L��:������!�x��=�r0���Ή�bk�/����TL'�F���F�\�C^M_���A5F_>�`�"l�>-��}�~��%H��b���{�7צ��Z�h�ZW�{�8�X���:$2s1�b����w�� D��l��Nn��n�LZ�P���v5�
����n�κI��E� !��l�7C*dPR�7��;�{�+�G #���T��#(�Y%z��hu��uuP�>���X�g����`2�){<e:�M,�m��� KyP_�/�U��e��K$�4@r~�he!$��(�W�Wo��v�{�8Lu��$�M ��]ʵ���������]d|ek�<�x1�E(�?ȣ�'���~�1����z�Э qn���(^�|���f���"��!|�*�x��jN�ch�7���,D~?֣����=gѬSa3�` P��xn��8��v�@�Lv�.�p�;���v�v.�ޡ���8���2:���U���o�a��,K�_��>�:|���?�Y�fš:����s��֦Y�<n�Qt�MP����S��R�\�/6ש��=�Je�Z�7Zb�+1c�ڒ�  "�d��RäB��oDg�݅�49�����͹�����T m9ȫ[	a�P�pC~�1|�-����َ��<�=9|<�s_?����ݑ������8���o9�oFI��_	Ȫ�Ҿc+ޘSDy+#}��@�E�{A�̼�yEw�@�!N+NY���cj,q��zS�KQOǙK��������b������Ɠ�tг� ��]��v�p�Ɖ�7=��D�� ��)h"��l��y50ѧ԰���S�j�)�.���F!��l%��WN�$%#+���J;XCa⩐F�X2n���8K[J�C+����#]�i��L���0U)���1�����8Ӗ�3�i�,�_g�D`�-�^�ʄı�w�&����-�D1.~0b��v�����zf��W����E��̌_|}d��0�̷/�]K+5Q1���������B�Mu��O�z1z�����]���&�a��dV�,�tB4o3ۿkbh��.	����'X���b<�k-�qv��)�=����O1�)�u������Թ��������Q ��t���Dq��G�^Ƈ��� �|*}��6���v���uf�/��D�h���|�V�G^ڃlعy�=ý�yD��
z�2KWÀJ)J�Oۢ3������� nͮ��yDo_��U�%ɉ�얋Í��*�k̈́%jX;ʑ}6����E��	�S7����}�K���	yۥg.$R�qɫ�}���_'���@����V���x�l�Q<ù�H"�:Vi�*K��s7��8 o�A�j�{ Z;il�g�D�J^��'�a֙-�).��p?�ة���e��R��Uiظ���v�@�X����QE�0|�Y���*��U�&��D�f����D^�	����~W��^_��M�&-Yn.�d2bM�w���b�tP�T���/~����H���9��-���R+7��v��䗧3m�c��-O�����_!=ʒ��7�lT5��|��郤���.2���Ճ;�h�~��eU+�K	w��     ���h� �����ڣ ��g�    YZ