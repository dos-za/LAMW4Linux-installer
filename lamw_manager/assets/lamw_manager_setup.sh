#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3869161366"
MD5="1ab163e61673f21e8b73fb50d7ddf8bf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22484"
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
	echo Date of packaging: Thu Jul 29 14:07:22 -03 2021
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
�7zXZ  �ִF !   �X���W�] �}��1Dd]����P�t�D���E��q�]v�2/*�����ϥ�ݑg%G��G�l����Կ�'8����2��#�Wiw�8�$�x7��h�H��p@-_�ة���X�A-p�ϭ�\�c�=��_u+
y�rXWb��������I��	��t]K��/mr�PO<(*n��%�Ek�/g&��8�D'e|�zF�u��*]\�~K�Ƅ�|E7Jan���zWJ��Q/����h�S���M��$,2is��|��?l�Sy�W'֥��١�NB=��7�"3�;���&+X5�{׿P�{/�ퟙ�=�I�m����](Z��r�+�T�C�V4�7�����䈡0iG�3��Gߨ��]�
����S���7��1e�G�Y���<q æ���[��3t�IU�3��;�=�P��D�#�#	��+���,gz��*� ڣIފB�X2]^����f�[�&��X�y~pg,DQ){�>I���X:w��)����H��U*��|1�J�A8���П-Vb(�>�.���)�#>���w�֓Rߧc(����X�sH���%!�Ĩ�e��գ}m�v1{�㏬jՑd}p����i�t���\Q��KSɼyԸ=����p8�	����5��l�3��ܶ�4@aS�|�?,B�aX$l�Fm+��u����\OHc*������O���n)��C�vMj�|>�F��0��|�n��L��\��`��1Q�foC�J����� KQ�MY$�:q�y�P?M�K���c]�|��q9��'�e5gOX�R+*����L�CH�W��1L�&�8��Vj���ޚ����|�-�:�Dq�O���Yz�"zB��oT;�v��)f��h�����Ƣ�}Q;��9N-��U�TP�A��h	樰�>*��_�y�\b'���N�k�cT6���G�d7,P<��I5ա1���#�W�v�,k:�����|���'���¥N��iG��k��uiCYrd��X��gN�B���1�d���&�t���Vf}t"�py㎉��Ğw�~[��l�洢Q�5��sFm���G}EM%�h�"���Җ�(�,�2�J�8w��(c�5�ayn�M�k�J��gҍB��W{1�U�,
��v�y���@�������y��@ʮ��p%�5���}���	�Nb�s/����&�#�R���J*u�>:�)���L�ru
������a����s���
��O�
Y��z���q�Xb���	���%e��24ϵb4Ex�Z�Ah�!{���zR�x���G�e:\P N#�,�d��nG׉�w���B�/�a��>% '�j����/��������*r8sb�x��9��7�n���_�}ܞuG�:N��%.�[����Ԏ�7g��6���+��d��a5��'Wj�`�*�0�h>�tH&ѷfˑd.�rK���M��ޣO���d�$ݿ�� ��P���.fEa)��:��߹Z�^W]e��"YE�}ͼ�]��h������b��Za.@o]�ZDm��B�z˪eN�ڇf�w����V_��,�����G	]a����<�3�n�����=�!X���vY�3Pi�|l���Bט>#9A���R��s~����E,1g�Y�˴��/#�4��gT�11�a�MT�b�Ak*Q�-��7m!>"�i���4�i�Փʀ�N���K%c=�J\1;bܿ�2A���P��@޵��Ĭ��S�I�x��a{���6��V�u�ˤ<$W�RY�<������6�'�w��m�	��&$��P����˶Iiz~#� �7sE'��B	�K�LJ����?=%d)��h�"���e�s ��*���~���p�®'��Y����Pp��"e��x�����:�,<��D� ���c��h��kT�.��]�3�=���A��q����)���߂8Kw�/���I����j�?WK�ZY������:��tQ%�b����2���|��F:��ۙx�X]I�Xcl�Ǩ�ŧ�$�߷������U��	�KmAB\�l,|�C�QP.�W�7���"�ӱ$��z��g����9�bH<�)G���9JO���(Eu��f�VZ����	���3qAT��Jҹg����e�6h:�ۡ�����G" z�`%�Q�^�;m:��j�
�J+#H��<�]o$����Q��V{�� `�]7'����,P+e��BKy
��O�J�Z����凴��q��O�1%����<���w�\�W���ނ�]�cQV%����Y���J���D��͛�J�G�@]&�!��"�����9��ݠ5���I�v��a$s�\�Zs(p��Z����1yɹ��c+td��(�~<W5���峙Y���2���0�;��M��{b³Χ���<a߉�=-��<�E��1Lv�'����6�*�_�H�Z�d��J��W��İ����h��i�e�g�&E�5�?��~��V׈ZB#g��ĝ���Ѡ�	@$�� �����w��͵'��n=4�U�AQ�c�;�����?D��n�����r�9�mLTe`̉�cxK�a�pB�L΅`E�� �QtCb��\�W��5�3���û�=�ϻ_��̷��v�/�2~["�5��Y�Xhx���:�#�Gz^����"���sv�Ԧ���Z�\BF�J�_,T�M���C��v\�\o��d\S]�|��UV���_��(s��Q3o�A�a��wV�*ɘ0�w��3��?_ڛ��,��	� �)��KK1���_����f,�_���7����K E�������Q�ػ2���VG����pk����P�y�R��[��Z��:zX���]h1��?�a�}�n:i	���(�6.w����]k��~j���=�'�8o�DR����o��1N(l�_���p<��tvX�.�X��:dU.���_VsqC������t��Ô/�bL�enVf���Zv?�\�$��e\w'.��kW?<�J1O��+��Zm̰�i
�0�8%.B�V�3�+X�j���M�t�;@;��j��IĂ&�M��7�Z�<�/��2��J�d*��6�Y��� M�8h��0����kت6X���a44.Q�H�����  ���zɺ����D�����~Q<i-��Z��6[o~>�s!��թ<�ࡋP4�-�Z?��ГF�U%�qFML�����lG$�Fd$��̦��B�u�%�Z����t)45���/>��}�NjF�}�2�J2�uX2�uQIL�b�9\|�*�C���T�u��Ջ��A�2F�:/{��$�t��*�;�Q&~����]��)�h��M��3��0+�M��3�p�ͦ�I�'���go�=�����~�KJ;��d���2�CE8AJc�#*Ȃy[�}l�/_L��`�#��d,O>w��5z��	㠓˶h�@�
 �#�0n2��^},yQ��(bs8��7��� U�z�b�U¼���{��{�R3L������S�e�HC\���w���m�7��i�HD�˞I��p|8�>���^eYJд6��4�y0٥�����S����z��]h$@֟G��|�!���p	V�Q���8�u�	Z�A��-���vC� ���G����#t��+��I���c��HMC��{=og ujZ��٭���2h��d�/B#�s�P�'٭������m ������exꮜ�3r�L��x�z��غ0��rG=�������kG����7+LQ&m�ZE_���B�`uN�G��^����OC�vAX�:������
3��
�1MT}��|�xZ3��^��t�Ă��Z����묃��-f�o�)ֲ��{��D����B(��U�j��]+��Qgz�Z��R�T��K��� ���!D�	ѦC�:"�/�]ד�o}�X��L��P5ϸ>�r����"����\�x�/���T+I��8�R#x�|�D�&lw0��xtr�s{�h6���w2D�9.ý[=�l�ʟ�D��u}�K��@�� �&IK�[�P�8Ҟ��8V��{��!e28N.�%��BU�m�Dt\cZD�b����Q�wL�Zӛ9�"��6j�A6�%��6�D������t ���>U�=�,�{��L��p%�yS�A�U@���o/�0�h-��s�:AqW��1v5��0��({c���,M�Fk u�߿|L���U)6�����ʅZ�w�w�Q�Z��5�@ճ��\�2�[&�r+|W�խ[Iw�����h"b(SIE��ҹ�%x��$i�t�����,���a��4����m��-��~�g��ߊ�{/��g�������c�e:Ґ�}��bO����v�^��_���u������:�24� �`j�p�^[��k3�ؐ���&<��P��/���jy�������{e�� ��ʂL�q�]��# ;v�I3I�Q}����lE��$�[0��6�W�j�	�����8��m��A�Ṛ����+�ڛ��T�w�5�I���X�VӎTg)�>��j(�A�=NI�˄�|Z%����.,�K���n�����VsX�Ԕ�t;�$P�M��a�I��q�������?��h���0���V�BFJ�������֏�����ů�x �ym�b$*[�� ��f��1a��)
���[�h���22� \:L3�ͺĽ��ӷ߷\f}�*�W..F���- �/�5�e�1x�c�H�;T8�:�3�4��4��`��(gI-^|p� hA��ך��p��̚2ɒ�V�m0�2�U�B��� ��9óK���"#L:�Z��	��X�g����7�B�E����q��0��2���7�2��@�`���_�_��e� '���Ha����{��1������N��!�����3#?I��^�O���M�{�`��<��E�a�~�2̧S9_g�S�íҳ!.����3�#E;򮀵j��	��G{ͨ?�(��̑Yw�&"B�����یۼ���p�_��Z����t�r)�'P�y��XS�d�ܪ��E�iB��ޜ�I��T�����q�e���d^psyē�*'�Q�D�s�I�fB���7#��e�=���e�
��G�X�&jǘa�W��H>���_��XlXM�U���o���JmǺ���f�zhw<��)�%��PM᭽�`��$�@�H�(�@����7E�쎹p샰Q���㿒-^�c~�E���r-�gL�w_�릡i���.ە�'z�|��Ӱ�*|���Mq^��<��Iڭ�� !mT�${�5�ߓS "��4�����l��`�Om��pwA?�z̬�o����b�m����\���2�%3�o�I-�5�=d���h�1���9���fc�26����Y���މ����Zw�ll�q�R������R;^T��#�h6��K�jJ�t�PH%7��bY����/�����O�]�7�����\��3�8���ʅxU:��^�xt�T�q��s�Lٽ7�C�=V�QX?����l��U)SJ�\� o3�3B/Q�����a��gn&z����Im��͇�x��s��omq���e���$����T�Wl(t��P� ���k�'��
nx��8(�R� ��``�&G����V+����O\���hB���7��D˓Gs8�9X9�)�{�;�������C�D/}���!G"���ϺuX��5/Ѡ~%XE�~��N;��R	��e�vT�[ �S���p�3�Md�o-~]���m�n4z��F�t7�s�tbNL(4&@٩��#m��RD
�a����+����!�x�ɍ��=6�7٭+���]D��k|7�Ul�T��zf;�'`|�9�cc�-�W)c:���y�(��s�`���Q���(Zb=ORc��I�h]Y��F1��+?D�9��iC,��� /�֫A�懨G���26m�&Uհ�
���V��hx"�I(�!|��u��!�m
��Jn��q��H(m���uYk���[���&�	p�����fa�P�Y�`��䨠(NHc�U��28N3{��2+�O���B�S��⾔ۨ�0�i1��|�Bnz�EO��K�q�ċ�(��Z���n�Z�B�e����?�%�ϩ���c���/��m�����o�1��yy�:�)��9�4��|n�2�GH .�X��1�;	1e~���g��]���M�Rٛ'q��{Ȏ��  z"66 oF��ԛH�;28u|����_�T��N�ݘ�r �~`���j7y��oا×��;�yv���^#�{���-�����C��� ������;P�vS��Q�f廤����_FΟ��@��K<�ƅ/�̋�ctq�F�l���:���jo�tSlǢ�%��˃ k	P^<���E�)=>b3 I�%x{V	H��{$}]����ѩ��tawJ��6H�
R��?�X��ӹ,u�)Vۚ�$��Q4���!yU'_��J�S�D��Ws<8wf�U*j_kf1���΢�`�d����|���ܙR3��[��tH�\���?��*�C����^Ј�
����`l�Ӫ�Z'�s>q���	�]!(���BҨ��U�"��/��|�۸&_۞
���L��G�[�)Gf���!ƳT���0Vߏ�̼&�g�s\����z~�Le���DC��]n�O����[��>����� ��N��C��$�y"^��ٓ�������+��+��6��V'�z�����G�޺�b{�t��"_e�����̡�2A?��ڻ�]s��o����8��Ո*e�@���j*��i}]^���qo_��l �C��]���ii�l	~灆[���]�&h	a����Od�Z�w���	ˢ�9n�ȯ#K!H9�*�{���n���@�>mj�򄰝^�)4��xU�� ��8iw���/�0�"�3�b��Z��c9�Q��H1��_	���cm8��m*L�D�_�mq̙ոf�����W��T�����Jb� ��EkN�&cs�2��qڸ+qw�����9XH
�QZ*~���+p�B�4�͔�MBpJ���S��6�RtS�
o�M�>xt�	����!	(��gw��J+,��b�V�3�=��A���]���L]�ѝ���W��o�Ŗ�'��G ��� ����-�^�E��}06@:�yްd���t�-�D��Q����:gǶڬ_�GY�BL����I�&?�t��=�ˈ�@9�:
�l�e���E��3V��Ə,����Xƭ`�V���=�-��o��������bцQ���������#kS:!(�8�;�6�T?�Y<s8I+X� �ps��٧9�e��qP��ӧtJ:�ތǛԞ�Z⛀��&0�����-����O�p���y.�@��O�9��P ��\������d�_�� �}�?X诧[kQ����mќ���_Ժn��J6:ǋֿ�ҫ��XO�6��yJ����}�u���\	��1{v7���Z�`��waTo!�C�!{dG;�U��)�0R �Y2�$2�O�K{Gm�V��d�@86L���k.�rh���	�m)��J�곯��:Q�!�#���[��~]ڲ���!�<D����B%�._+i���x��R���Xf���t�S��7'�[g@º,�!�o�$:N-_m�J�AݶG��C��ԗ�o��<���,�&��!��)���?��w4�*A���=@��{uj#_�!x�߭o\���5�
����!����=4s��vs�׸h;�����z᣺�9L|B�5JAW{��r {;��t���
B*!�%�$�;O�5�k�_���mHJ�=��� ��1�\k��a��wd�\U�u�Ew<^���M��╍�<�۝�������%jg�TR�β��^h���Bֺ��\�
�\̂6��q ���T��p_��/帒<.��>���V�úGu��W�n�U�qP��OB��
Sڛ*d^��e�S��{X��!��'Hzx%����`E�䊄{����y�*4�d��M�_��}X;�F�l���,urI��A����*�{p1���Ǭ�$AP��)�]���b[���qUU�6�6d'ܗ,W%��,�Ff��t��I!r��P�P"�'�&��A�h�7ȾT(��ܯ���|�@�B��?D�E@.���t���d�3�Y�?��zI��1~j*SF,V�D>O��YHˬ��Ho���ИU��e��TׁQl0��@���v�v� �\��۸}v�Xޜ�|$_�7B��'��K�p��;[���dP&*��{�h���z���)�����������o"T0@ʲ�"���'MᎱF�jY�u�ng/�4�X8Ӕ� 5PE����
�N�S�)uX���Dx��)�H����Z�uE&��M�ɛs�;��C];9i=#ǈ���ő��\��H�L�]l�#�D߽����?�\RK\jR��/F�È^�F��8��i�-z�������&�)�3|D������S�B��7g �J>2�t�.���+Ί����\@����?Z"o�~�h5�����O�:���#��F��Xo;.�8�qD�M�������m� �@M��8pi�w��b�ϭ�h3�3�L��ͪ���	����:���ݎ�3n�w�@k�D�~�J��"�)l�3��v��gz�px��5��\2W�¦�P=��@5/�g����O0-g1;p�`WC�^<�;iɖ0մ^��t�!����U���{�T������!��-�;�����UO�U���2ڟ��������MvZ�n���y!�n������eG�/���]��(�S~�l�5	m��5Խ�NN^��2�-��;�����+����Q�ԙƇ鹽R�]kљ�ⓄNS��"t噲��Ƴ�o�s:&�d<f	7�qK��&�tlW`��f�×��/<�=5IXu�"������D���C�cV��(B�V�_�~<w �a���8���ڄ0�g��Ɨ_��a�$�I�z�}�	i����!l�w���������C,�jň�qd?��fFN�C2�a�������cR9�����͋��趪�s�zg�n�T` +����0��H�̍UÏH��a��%�0S}P��q2k?aS _�y͋�L4�RFC.�c�yY���<u�EƼ�=��]�<U�S�ry;�6D����3P0jE�o��!��R ��kԀss�����u���-��AYҁ���W���J0�=]4!����6�!ފ.��G��YT�s����0�B�ֽ���u&WSZژ�:%�uRܰ�>� �c`	8��0����ۛ�#p�]��ӂn�\F��)�Z������7 =�W=�{�Q�V�%�,=���;=%�իrH�Y�P�GA;EĨ��?M�z���Aq2v+���>�Yr��s�O--�ߣ&�o�Z�~�w�-�d7��l�9I#b�19	:b5��-m�3Q'ؗI�|��B�����H�@��D��h���M�Ix0{\|1��2�/f�XƘy��B�?`��M�� ����6�~�}��w�/�ߧ-�zg�άQ�>(��x� �<�Yd~�������s�!|��_� ����->��%<͉=�������R8_:�ʪ�w��a~w��>eT��`Ѝ��6��e���kg�i|���P?_��`����S��TT����� kLD��]�nWυ ��ZK6��"U#��	W�ԱGFj���u�'��䵔5e���`����B�B:��ܟvl��>�ǥ�~)��yʸ�Լ�lzS�񂶉�M|EI�Y�Zuf\]���[��y�#��/�)�f}�#��4[�c�j���@��X$D%3`��O�k��с��	�$U�ƾ���o&%)	DQ�ą���\!KYA�9 zn���^�/�rG㲈y�~A�EL������L�Q:Ǜ���׎����KDO4����3qT�/�D75�}���ߗ���H����2���Mh@�GP�)����4K����瀕0��
BK�_0ȹUX)\�6	�V�uR���n��4��KD}݂^'�;a�OA��V�D&��u��h�f&VP�4J���ۯ<���mR@�aP��1��M�[�R]*B��?+��8Gs�ܴ�n�io8y���2p�2T�(w��/ט�Q��s�X�Uݓ<��e�v/��L;�mL֋Þ[�Ȼ^0{�=���WG�%��<<�h92��G����&`m� �&��̬4[(��ë�C���������-#�-t�1�ߣ�)Xz��S�nǤ�iG�hn����?=O)[�yx�,c2�?���v#"cϺ���/��ʭ�ߒ80��Q�o��������k��-��	�gW�[Gߙ��>Tlx�Ӂ( �����Zy����aN���&��0]�fI�?�%���<@�I���p�Z_����d�������J9�s.�JZ���"����iv֋!fy4P�Y̋7U���"z�p��oce#�������i�:�3���(�m�U��:��,�H��:(�K����=�`~�m��	��/�@ߚ�9�Ns�y���Ǥ��$r�yg���&��h���{����fH��ru��&T�E�X�Mc�K�d(��v?�'��s� �Z�7�wb%�W�i����U���o�����u|Y����q�Ag��SULxlB!�z��}��y�m΃�� ���)AQ��m� �J/���ĞZ����A"Q�`��(^��fAv����T��� ���ī��|�t�u���	���o�!�u�':֊%�d����������f�x�9N"�X1��@Z<�n��(o���reY�vþ���[�籐<�����; �G��^6"B�i1f��.�>�e.J���!Hs-�����`�a�trϸt�e��߫G���k;^-#��tgn��GB S(��1
Y�uVzI#��PTL�O��H���M ��2�yw_:��=T&$<qw�R��A����VoɄ6��KN��}�`�ȃ�Y��=��̣w�
^;V����`�ɫ��RH���ן��	��|ѥ_T1�QG+�-խw)5�r�f@�ٺ� �s����+vn6_�4W�����!ڏzX�0u�4�5I%�ܢ�>��X4��-:_�����4�ɞ���k�k|nj:��~��MMa��?�z���,��B��S�b�<��:z��^��ͰF�h�{���?-)4�2p�d��O�ﰭ� �7E�[DB�#�n�v����&�a�l0\�_��>�E3��+ًo߸�k�۩�ix�%@����d�����}*�f=_O�	{Y���D8�C���:�?(�a1�~Z؊'��.�R���%o/=<ع��rhh�������nF(�uؾ`�F�k���T'$�Y��
 Λ���!�i�a�#z����A�1��\#��H��"�������� F�p�!�Y�0� �O7?� "u�b�+myK�}���2.�����\���Z��\��0�:�bTvҰ�&����f�6A��-s<ȹ�+��䦿~�{�LR@���}q(Fn�MF�Il�e�(�l��e��T1��w����c�z6���x�\zH@����)���L`!w���Є}徺/qŲ�D�[�w	X!��S�$���^R�$@�<��Je=�e�*Io\C��j_�L��ze1V�N�2&���wL%��7U�ss��1��׍c������3Sǎ����.<l�n��
�/_����Q��r�q<�R�'}�7��`���d�J���ȳE��B
�$�^��X3��)�<���E�R6�K9/�[*�Cv)T�Д���KGǒp�Qs��ϓ�ׅ�5�k�}fڑ�����Ѥ�H�"�qrS^o�P�ԁ�r�	V��\*d���͇�f��<!&d�<+�M�`�8��� ����������J���v�!WYLΩ)DϖΕ�ڭ*�#%|K/��m����voj��|ps����2����A���Q�sI"sg�D#Zu��MX�ҊIR��Cѩvɼ��vi�tzT%�����M8/�LJ����� ��~:�n��S`��S�XTxu��D�>���p�hh$.D�'G��5�v̒)����`*��9�j�>Ю�ԗq$��ma��Wm�������2L{b�������EP�y}Aԟ�J4-}i�,��QSq�^h�П&���K��2R,��$��w'�c&[�y
YxtO��	�qO��Z/��t�yI̓��G��L�kp��?�:i���b����3�i[���P�:�@��,ִE��V�U8�`������X_�<V�2�EF���4����b���y�� -lى�b`9�\��N;ƻk�����r������&k�\����&��r��U��o���;��}=��D�X���`$M�3C�������m��E��*��m��-5h i�/��i���]$epTN��[����R}7[�GjO� #+[.�lF���z��(�p��A>f����D!O�v�:?:���h乏a���F紣o�=Sd���Ʒv�y��/Y�0������Ԯ�a����X�mw0!0��Ho����&��,��T��t���l�*���o+��� �}��vt����:�Y?�}z��MC&y(ߢ�,=�9XC�����U���@t�B�Ӎ���qw�S�ݶ�<��ƒڡUP��1aH2r{c��
F�m�=��ڡ��+�����ӳZ��&v8cq�r
W��떉�ڞ ��=��(_'��-|���ޢ�ר^,��P�R�ă�g�F�V��r%�:�3j��	��}�D0_�K���u,<��kVw�9�~0L�(= v�u����d��С�T#'0�����]���R �Y(�Y��~[�5�v}�iU�|��z+w�jN��l�����E'�p��������@K���S˓PW/u�z�5;�hY���۷�I�^��妇ȭ���<��"��� �R�>ȷ{�3�~t?��A�Cd��&,B��7hu��3���} R"G91Ѝn�)��p�	9��ꃴ�e�$�9e^�u�R�*�ʂ����VEmm%�*)��˯qG�7�)�"+�	��ZQ�xؙّ�ɽr۷�����Gf�ٯ�T�4�hx�Έ��P�،�/V��ȷ�?�]L�j8CĞ��v�K�y���d ���O;��^�n������.e�1Dy��� \���BdX�u��П�T�%��Q�t鹧��mk��yS��D�lͶ�d"2�T�3x�$�H�a]�V�w�!3�Ӓ�94U	@���v��p;\�G���e�Iҝr�L�|>��!r8���uj� ���$�+Ps��op:����z}S����x���b�o�$���T�Y�KԆH��!DQ��?uͿDU�P(��g�'@N&!gȑ�MQZ��>Z���o�oL\\�E"EC��{�<Ҫ���9���Hw̄ �W&q���[?m���>�Aښe��6��^�T�T{�#�&���mGƹr�zw�q���O`n;��N���o^�Z
��|��Y�e�x�Q��ӛ[�I~��tȽ���ꃸj���N�j�����i{[n}�R�.&D��U����*W�X%��ź^sØvr�����l%%O"�s4`�-5=���'J�H�MY+[t�7�@���YV�8y�+��b��\�=;_���c�C����/
���ݜ7E-���϶�_�
֬S��*�r��|"���R�U ?ƙ�T�;yu��Qu��(�?§B]�����"�NRL�M���y@��Z�2�|��/�h���3%�.Hc�gt�$wLَS�եQ�P�wԷ`�-��x��1�<�k�?���8Ԃ�<ɩ������������-�8���V��� ��R>�KY��I�
�>�s;���Hb�v�%[�|��	����޺���uJ`�%n��l'�$�%3�p �9m��v�3 E�cB;ǜ��R}���&��4n��cZ�p���p�+![4�Iv��,�i.(��w���Z3�UdR����T�����kV+v'+�^N�q �F��\˽��n+5�QP�A������9ƀ�<���A	%_�D����IV�\
�wVG��%IS���w��VF���P�,���iS5����U�Bv/��-�R��4Xh61�{���@���߁YCjf�o-i}���})����39C� z�c[J�X���<�443׋׆`� �%#۶yc�n�o:� ��$PЙ��[SJ�$Zޭ���4`��z1а�g.g�{���8~��0�����������v*�\��rY�z�/���6A��=�ڱ)Ng&��Z�}����}�W���>��)D��9��B�KR��{�uk���\��A�rd?�l�̬�t�	�0q�X��6�&��w���/����Z?�u)��\�g�'��p���9��ak;�ߤn<+�K�&y'��掩��ǿ\�</3�`��i���L�z@�MF�H��`|unq����wE��WiαU��h6�����4�'��\L6����O���6� �����߉��x���L���+�ͼ�n�V8�z�/}�;�J�	�J/~}K{]%^�kW�c���*�#����/eW�I<�2�,q��t�є�Qm��*����(��P�V}�G\C�q��_��Nn�zg�&�בHK#�I;O��.u��^�Hv�C7�f�k�8l6\���^�n�&�[�=ǂ�S���g�&��z#�J\uI�����=���'	mp����7��8�j?� Y0�g�0T�I��=%�X�h8q��:X�WS�q2����0�uB%�+��p4�:��Q�^��<K�,��l�84*��o����"st���].^�v���mكȖ�?�I��`���U>/�a:�1<��WS��� Ƒ����������l~��4У ������h﷮8���4s�MNQ<-m�Ӌ���h����霪�n0����''�ٛ���'vu�D!HA;%_Q�����̴ؒyg]G��znXs���5(��qSEDP:��J���ћ���̨ꁓ�R?c�8n4"ǈ�e��ǘ�
l�n�?�ܑ�-���:T�u�D����*���(�]-�g~��E ��_<&�t�tUա8J䂌�N�a�"-�ne�/:����K��!a�N�|g���m.���bLPcp�(p3�C���!��6C\�+�Oɥ�5���_0��V��z�c�l�b�����*Z�ͻ�{^���;0�혶�P�4�@j?�C<�N���.�*y}V�6�B��jl� ��4��,n��l 7����p�a��bW�1�S�/kj�xH��q@m����M+��'�o��	m׶/ڈ9����%���O�>xJC=�&���=��@�y�! e�c�cnw0�Q��?�ع�LN�&��5
��n�6�gg0'a*��a��<��Hj���t�}�t��mvaJ�q6�����?��nh���S��8!b�&#7U�hB�XU>E$��l��@�����V&ZP��0j�֦�j� 4C1�t����S�`����Z<F`�u|by{�C�����]���ȧ)4�"k琄����є�sy���L���TH�/��}Bيϭ�����6�c(�+��"��hU�ɡnE�����������+�P���$.§�Ǩt���X"����-�a�BK��/�*�1�П ���v��	rm1��&@ �]$1��P��o���ãp�W�� ���X�!�yi��ڝ<�@�ݣ��|�6��e����uܬ�ar/ؿ��:��}}������\��ИG�v���v L��<�Q3e�p�(W�G��51��-n9�S]Ν��^��+�L]�]�U[�vC�P��n-:��	5�,4n(7yˆ,�Z�S��!�E
��L�>���㬳E�3rt_���5�ֆCZ�d*�΅��g=�d�,[�n�
��_$@���xw6���L�_x��|�����-j^k�9��� �f�����$vA��7��Jh���O�!���@n��z/�����9���t�%# �fTN|ՓF�y�ʻuQ���#�ƀiy"�$�-;gQn�귅�x�L� Ę�+|�kE��hI���u���/��BMV�s)4 �$t��9�x:��EhKE5ʫ�ՠ��#3�(�s�5\��e�4���!�� �Kպ�Q�\�;*D�g�&<3B�f�ї���`�����^�yc���N*�<_����L�p�_ �����}��d|r��Y�iOT���jP�΅�,�Z�Pb<�G>�N2I�B��1:�ۺ�,v�<E���p�.W��t���5�|_
�M�����_���a�{�[����o�3L��W$�|Ƌ���Q�6�Xxȏ�M��\6��p Z� ������ۉ��Ȯ��$�� �,�o��{˧3��7�B*��wg�`�gڼA�<�>�ؿ��pY�j���������jz~��(�P�#��uj�4�������%�9s��^�Fcpŋsf��(������C"��)}���T�!��,Z�� :F,%L��v%�%[p&�34lN��ݖ�u]�ƴ�y�!}�w����|�B�u��?�D�4h��m��0��ʎ�a��=�Ո�x�jp��|�(���E���Ǧ2� �/�uX�0���N������8#w���?�=�Q�([��J��m��00\VY�����|.�"�y��VaH��dar 7cX���"����d$Ъ���4�\)L��i:�[�����$MU'�p�s�Rv�L�(B7��q��}��=��6�btKMy3X=�I��Iv��t�K�Q�2@Ő__���"L��.QJ�"���~#AU�7�@p���!.ru�S�9^X�IA�l���g��F�s��>�oBXT`3p)��7FD��!7�>��'�?�? D�2��oe%��#���$�c��i�'�P�T� �;I�-H����g��&w2=|��O��^�GRR��2�ɫaJV��w�?a�s�ƀ��b�r/��
�g��"��$��$@W�8�I!~����X�ҽ���D��+~�+0AK�P��ԥ�/�L�=�S��8�G��P�����lk�t�=g�`6�kUҶ���ʜL���Ü9��qͩt���
��1������O��Hɓwkn�x�K���"��{@��P��d���?Zɹ��X�m���V)c׍?���pQ�9L��6��tJWu"V$<�x$5�l�J�+P����H��e�}�@P���9���
to��9�=q���W�"�B$����M6�&���I`h���ш���O�^�V�@��M@~n�\a?��<�@�-x��K}�[m$�{~��5�>�%����`�䝈���r$�CǦ�o%3�^ �����^9TH��|u���ԑ�2
���8ؾ�T��$�G9T�_��E9�;�Q�9ꨀ�VL��*�x$�v��y�!���_�����S.
���:k���c�������:w�:[Qw�;~��_u���W��K L`���Nr�� �d�vх�_��M+h���ˠW7DGG(uH.��O5�%Z�ֽ��ޭ+���S�)�m��{(qz�<j�k�	l(�m#߰��m?t�<�وqq�Ԅ~�x�(c�Tto�A��cq��G����Wh{$�>�^Q�'���lH�n%��~{��͑;�S�!�*�+WMr;�'�� ���8Q�Ql��>:������T��n�!�C;ʮb���>�)]��n�����(H"a���w<���1�����ܱ%^&U�9/�yW��x�#�K����̔��iZ��.��V�)۪_h�`��-f���J�����je璶-��qy�x�7�%n��_�Y5���&�?e�����ƧO�)�H����zkG�L�L�"Yl�b:<:���<U�h��.������3�Cr�=ڀK��W&S������2V��a�Q��@$w-䌳n[��j�2�
���`95�Gڹē/�T��~Vp�z4�g�9��J	�
�BΡ(�-�ֺ�F�k#���*��+�{f%]V���4��*�YK��W[��=�q�hԿ�1"V�z�����n=JNM�~@6�g�Ŕ��h����H~MV�p<����a��g��$DNi䖯��<���䙯���6v���{V�p�'���>����[�Ԑ� �Hk�]Vm�=��lG�>M��� ��UT
�⿍�x9�q��M��fq�	윋t��	�	D��Q�[* �c���mmZA�ז��Uvs�F���������x5�������L�(R�v����A� /x{�LsF_i�/��=�DB�!i�2wĸ��Wb/�C�Z93%!]c�#3�}�����W���S:P���.���㽡�C��oY5��Y���V����=�cҜW?�R^$~]�0R� Q囬]�`���]�(�B���d��"�v��:Z~�����}�C�����p�R�̮�jw�a�2д�8�U�Hy���oƒ�o�B\�2z�f�䯔/|����h\�֨�#����q��Z���m�;��l|��b��hC���yo�qǌ����n���������yn��M"*�a4L!����������v���]��  gZ�����]t� �W;�&��H+�2.t]$4�7��긊iK<�>���>*�d
�bN-��T�@��#�L.��o�I5���q\��� I?Y���r�]�)���oK�� V�{>׊��C� �;amYP�xQ�ЗJ����2�nĔ+>EY��:@?��K!��c"`�ω]y����75CB���i�~`ҙ] U�t�i���/w0�Bܼ�^٭+����w�k[2˴�� r(����]��WV�g����,VY��L��D�,��@¿���f���������EE���C�[uԺ���&NAV����N����E���3QZ���~a�
��P����4��b���k	$Eq��vR
j�
�*���`Z`G���V�A�1��4=6��0 �8m��M�Y/-�F��QF7껕���u�M
}<9�B�ۯ�I�g�=N�Y�w�#!qk�XU�.��,�.����� C�Ey홦�h&
���7�CT0��/,W��C}�~5Ĝ��tz?��H^D���Sf)�e��_���+
H�X�R��~"P��.A,�z��v�1��;sv�U����ڻ��\]b�>�D��iqb%˾蝠�U�/Q-#�[;����pr ���9�8���AB���Q61���|P I�ŷQ�V��@)�$���Q��o
,��7>2�����Ʒ|���<F��վ��Ԯ�(�z�N�H(���y�[ 'E�h$�_R�h�Q�@0�V�d��-���$�藟�%�Wd�n��ny���Hv��v�SJ��v8=�3\ ��|�53��)�!v�]�q���	r������A^�@(���%�QR]!}�3o%�pDM���Q
��T��~�r���q�=�c'��ޣm��m�{sF��ޟ�0���,�������HXQ����������6��S?Aȵ���P/2�|�������R#�����������4V��㒓��X����ӟ�0�����v1�����S��k��Ʀ v O-G,��T$ �_�������N�<DAVj%1v����.�Ԝǩ��f�SH(�3�ɟi�c����\a�O�O�yg�ϼ\䰙Ň|W�!��Tu B+d2Lg�<K��C"]p]��ޫІ��Jт
p�cJ�{�h�.���ʕUhjx��}����zb�]�!b���"0�1��4�Qi[[��%m�	 ����婼���5w��H�|W���%�+5���S��A�{�`z��T�`�o�[G�pPU�=)H��,e� >n�9B�+��z$-�-C` a5ѬSλv�/K55q�rɰZ��pc���E������pQ�,J��d�T�"�9�p��"ĊY���T��=�w0^�Ax\q�M�8�!A�ߛ��O
����hӜ� 5�����\��:$�2��X]��A�ڞ��m*���3ԯ�Ōg��d���>�d��gO��B_����\R��q����!x�{����z��g.�ӑ&+���'�i�;� $�v���W�d��IT�����>�\bM"���8<�()_ѷm�CF�n3� JL%��w����a��[���l��&�vC!�bd�Q��C�����\�V۷�2�7�y�WIw�wĻ�}P9��ztb���e��D�L��e/lƆ�2�8��'��M]Ќۥ��&ԡ��=I?X� cS�&�A��.�'+��u�qz\r<♎/d�a��i�C�1��	�!{B�^S��^�u*E��1�3=9^v��T���
�3�0̂&� x�F
;�~�H���E��pEc�L�G-���D��Lq:�f�X����#����+U�2: eG�Neg���q�;�K�Н�K��P���b�"Ŝ�'��B�l[��3�%�d8ޟ�p����ƒ�"\<.M��F��0W�	�z9��9� �}P�K��Fj��6!_[����y^�M����¸>i	�"i��0<�� S����Cb�N��ަ��*h� ������ѥ=D��wV�O��HC��AZ�ܧF�nz<^�a[����%��"wUf�T\��k�<�}�D���ky���0� :�ޠ�-,��(2 R���c���Q#��Qc�E�)?�?��nVK�z+ۓ��( �,8�x|�ʋ��E��el�\4ڛU���j̘ Z��P��d��1�g�PUX�T�&���$ΟL�Q�Y�h�|o:����rJ�$՗a*mD���1/^�{쥱v���	��=[��t@�-�����MhP�'�C�٣�\4Q�3���%�(a ��x:W߮N�����s��3	ʘ�[[PG��D��A��"�g.��*|���#u`,eC��ga�Y�{��=�����饵jh%�,[�:%<cUC�X�)��*��7@��@:�y9��QP(zk|ӝ9h؜	Z'I�G�8D���B�Y�ֻ�C�8A~(������R��L~so4�!�D�r���]�2��_�!;!�Gi��2�;�o�iz�X��Е�"�yVx|M.)��t��r|���q�%J)Lg�JP׭�}:@��3k�"� �*l��cdJg�_�q+,�a�F{�Dd#�H�N��H��M�ͶGk� �����.º�m�I+�XM |���Q��>�o=.�=
R�	9�,]��|�S��t�З�� B��r�X���m���W��;�;���UV�=��#~��4��;�;��@5)��#	1{~U<��*���{�lV+�}�{E�X�ag�Қ]��=2}~7!��C]��g�</��<�ር���6<0��v���<$�!��Cc�H�w�3��w$���t�kt��AIM��-�����b-ؗ�`���i%�׎�_9�B��5o#QL��Y���G-���=E'Hh][���0�ڂ���,0�'eџ,������΋N��+�VpI����;gE
��@���XCy�y� ��?֍��Y��4`^���L������Ѣ�-��̷����-���ҵH2EVƛ�_�M>���1�z�Nݮl8��Ũ/VJ�Vi�	�^��+F�I�7u��s�f>3�Vћ^@X���1���}enn;z��t�h���F�)1�]��U��ͨ�H<̋�=ܕ�ds��6�M��т��
�5TtǑ���^� ȅ�ur49N��	�-�'�9z_��fe�2Р���D<t3CEfv`�a�U,D�* �!��{l��SW5�$����e�-5V�w�d���1���hvxt�K�Ђ�Ӛ�	vTE�R����<��A�VG�t_��_ݻ���bs�b 텄�Թ�G;�{9)�3�A����h��9rA�&�_L�L�|'����W��K5;�0B���t��Y��P\aC�9w���ɟhI��}��uq.�ܴ����_�5>|�'|�U
�V������"���hsD�	�3pV�m�{g-Uѷ�{�״��KK�d��Tnb2U�7���]�S"3�$ڍ���\   �]���v ����i�b���g�    YZ