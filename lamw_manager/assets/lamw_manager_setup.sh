#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="705389589"
MD5="f4edd6b0710fc81a9d1014bdc17495a0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25516"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Sat Dec 11 15:34:29 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
�7zXZ  �ִF !   �X���ci] �}��1Dd]����P�t�D�"ڒ��u}�~�{ ���L����!��'Be��t������y<N�'����B-�(f`�:��ٮ�`iM��d�uG<�V�C#u�V0�X�p	��z����e{ N�	�&֭\]�\�w� 3�N��(�L��}ԩ��b�뜞�K�:��W�eU���ml��	�)6,Z��a��E����غ��B߱bX����B���B�l�]���L��h�t���hޘY�o�����k���ܯz�a�qy�?��X�ޖ:��Hq��A�*�'�ȦE�����?�R��:���gI�^f������\���W���������%b֎��	�<Ê�,�/5z@��V-�{ҹD[�{���b�y�{����,L%'���N��D�|)ZT���
M'���+�t�ҡN�!�L�@W�iy�z�9	��C��*霚F��dYo�����T�0�6/�����^�
T�ADg��x���3^(|.�J�
��G[���2D�|����0�@+����oF�
�'��BI���DU�٫
Z�4������8	����6<1M5��\^�?6�1	
���.�/j��n@�eam�>����0�����::3Oj�q�dq((�dv`>�O����1s��`sRr��Jm\=�g�h�)�jn�sl��9����N.�-�y�,��V�>���{�J��}��,�4�g�o�V��&;z�[�i�9���i����LiND�s�m�>c�>�32�p��ŮN�)r�@�ֻ�cya�q�����I�
��3K��;R7b�%������WS��ګ0�Kt��!��x- 5��h���^��M[���|�������?�6�#mk�$�e�>
!K�\��SF-Ɵ�ۻ4KĚ�r�j��pT���gqeVS8�ۆ���IZ[����-�UU���&��$�d~"������Qj�)Wa!��l݃}�?W��5�>��=]	��.A杙x�%!�m���d����x�`ǭ�P�Bgt@�EVt�'�'��]�so�Wd"	唗nZ�q2�"�(���$������2bQ�.�_xO��T�wt�����G��m��%��D��]���ͦ!�%5b�ِ`}ţ�Ky�o��vڭ�ˈ�����i��QCb�|��WG+uV�I�� 6]X�����$y�s�b9��k:�9	Z��2�5�����玙��'¬��)�ɸ�ţMQ_�M.e�t�Q�BY֖Z��َ��(�6��Q�C�������XM��!Fj�>���Q�a�qN�F�<�/�yP�rw*/�Š�c�r��1Di�T�� R�]#���_"��wY]� ����}������a e��p,J

�x����Sd�����V��\�~���ѣ�*
�m<f�>6��&^J�Pi�/ ����6��vr `Z�>:�*���K^�v��u�[Þ0 g�, L�Q�kr�9f�O�I��۽�6*w)(\�C%�$*j�����:�/�b�)��ɱE��C�1xX�Q�N�I9���
����<T���̩+G��I �	(p��WR9�;VV��@(f.�1�-w�<V��/
�T�m�h�vV޿3�}>��.8��,�#�/�]�y�Ȟ�C��*-gV��Ǣ�+4+�{;)����v�]2�~�����,��~,��8dq~�l�><�|	�?R=��m�$�ъ��[a���<������t��L���GQ���f�>�2/������kx�i�f}���f�V��<xڟW.X#ml�x���ȳr�B�噲�E�2����9N@ѧ��������S�ޥ.H8�c���b�D��Pwb��(W�~�������3]j��F�mK�;��@��h�~A�~�B覅M,&�k���s�I]r�{B�EH�N<MH��+��Ӓ
``�`i:c�o�쏖����g����Aq��5#�6�[I��Ԅ	[�5\-l��ע��/C���nK�!�?�Лe)��vz1Q �����#���w����H>�@OqC �=yXigl���z�l���k<a=xy���_C1d!3 �"-4�ҫ�,�1������SA��f~=Vw�h-n�������f*����B4NkͰ�׫���+M�7��O���z��K@+��B^�`:Ε����2y��D����%\�mznqb�̡�lVR#o�
�b#��B�������{?����{�B��*�������Fࠊڒ��e���Wo�� ��& �I����O��89̕㻺�Ǹ~�iہ&�7R�^���j�	��������a�?�~ɱ����0��<[�F`�d�[�J�����d�1��L0��o��� ;7]&̑��?
�(�ٵf��\��/%%l-��L���jdZ������I�<��:��!��Z��������`�,x,ݴ� ���ݦ(j)z6��z��jkY5Z-Ǻ&pQx��ds�6?�������׾��D{��a�*vH7��K�����.-� ��!����)���*!^Q����(f��)�Z4�L��}m��}'�~N���E�*�9��T��B��h�]BJm���]������ �B��{$T��5B�m�fɀ���{h(���H����&ӱo3�DLv����W��NS�����8���kf5��4��#����L����iD�l׭��5֦�bV=���n=��/߭�˵;l��b�L#��L]���O_�847�I�i�%[\�U\J,[L���%��+���f� ��I�j׽ Y��&���-
+ػ��(�< a礌��ɉ�-`����o#W�E�,i?õ5��Xz��ʄ;�sGy7Z:���,Y�0&�������A�8+J���3}�zM�f���s�A�?rb$�M/8b��̂p��(�����X5Y��d�_���}ky��f�9&��HGe
������qUx�L~.�$�aj`Yb�:9�-�q�ż�+�`<N�	��R='��H��J��� �=����$<��v��%\�Q���;�C�k,��[���-[�V0�`)�|A�o�=���Z����t4�c.�>����.E&]DA����چ:I�f�Bn���J�b`��:��Q��l���.w��?�
�ޛ���$!���;�M�v��p�rn�F���5�а���Ӽ�[y��FV�5)T��h�D���6 ��9v�Wh������td��M���M
8rDh�͞��v�C��fۄ�ή!��i��"X>:�)��c�w��?70�ɫ�ô �7�+�lg
-n�n�L���}_�,�ݟs��C6n�s��-�:���Ym20��7��e]f�������MP�e����;��g���У��0'��&�ۯ�X]Rn<aTT�s�W͡�u�o�Ӊ���j���
���������r@$�j�Ӗ@�;���N�����Q޸��KZ�6��z<{�!Zm��~�֓Π�c�#��R��Uv�&���A%���A�/�|�p�G�v\5�v�^���v��%�TZ
�4D/����Q���No���9gC�٭�>[�$A��/�u3uʢ�Q�ȱ�L���(��͈1���Vhpp����Ò]��	7�Iާ��7u}
r.��H���������+6��"�Wt�8�6>��{���gz ~�4��~��-G�y0lde\p��Z�B�tӼ҅Y6Ǭu~p�O�i��%�h�-}�>G�z9�����m���z�"b����y��X
2j����jI	�	!����ٽ�(����Jz��.�*w��{AE)��)g�o�����_�ݠ��]M��N+=h��N��@���i�G[�M���˵�������i��2rZ�8��	s�r���.SN��j�v��"@�<d��^�_b�[�����7B�\;d :o814g7����$Y�E�s��g���	5V��޹ã%����n���$~�����Â�w�q9��+��o>۠�(�+@��1�i������}/YGw?�l�w�d�$�� Bg;v� i��}j��=[zo�NE6Z�L����uizRBQ�Rq��v�R��]nʫ8yі��t��̜�9����Wmލ���R�VIc�b^��*k�
I:��J6�E>)�u��#�����t9�aƄ1^��s��Ef�Y=�-�`�c�å��ՠ^����{�^�Ȓ�����Z�5�} ��e>�Ux�K�:	�4�h��uY��Z�lP��M�#��4ӣ"��*s�j�;o9�wG�Ԧ��ؒٝ��]�$܄����CMCv#ıc�Sv\���^�f���ܿC��/�f��(��ƈX׌ݬ�(��$���i(S�~��)��P$&v�tQ!}а���H#>�Ϥ��=;�����'1��v�?�p�͘{$y��lia���fR�}l��!/Z�W�B��住��0�T�X��'�<Ar8�"�e�Ac�e�a����$��Z���Ĝ@�(���4Fb�A���"��\)�"���^A^����oz�ǄS��&<n�@��r�G"X�\<t���{����y�0��'��� N(����W\^�ѣm�G1�/��4�bR��ߛ��uT��('�NTHZe֯�X�7����2�Z$��`7�=v��p�����oyh�&ŷ�L�D�Ӗ0T�|Lt�;����o����F%)�Q�K'��7!L1iwo ݐl�S\����H�>�
��ķJ�i�����N�'������� �	_�@H����iE�	�kJdA�l־�(7�x�xP�����P'�!j.�w�B!UhEԼ��|���!�Yx��I���`�ꁙ��u��P�QX�>��u�ո����I��y�����y�Y�\�UY�v��]����s�"S��J�>[��a�6}xL$C�sY���*)���$�uI2���l&�o��yV�C
�ʽ�0
@��gܩ�"@�9U�y6s�h��h�_{p�[z� ��[��H�P����36�{дtL�����/a��b�S ��U���D���@A�"M��B]���&�S-6�<$b?^)7GnTS��S��c ��?��?
��ZȦ	ny0'9)�Q//�`�H�[e��D3�Y(��߬DH=4)	�̴����b�M���� '�hM�E��;��.�͙���]S���r�Q�\�Z�����1Ku��p�����2��%�ޚ/_,\% ���/�a��*-�:��^���n��f�ƙ@��g�����'��$ńɷý�Q���kG�}8n�;�o6F�Ϙ 3�C\�|�+�k<�2�C���a�u\�4%��z�iؚWBF$ eh�8!PW�>@�]����CW񲢘 �|1^q(Ӛ�mɨa4�yf����F�8K��Q]���
����L�{/�t����#L����a�kፄ9��L4e��4�M��O��7ۤ�������n��� >l6�iБ��Z�2����a���3�$Y�ݯ(ؑ��@���Er�h+�� q�N�q�xŹKrW��󪗋U��e�i�[��LgΡ�[_j���RGʟ�-.�ǟ�As�TSFx����v >���3Ĕ?tj�ʖ8���ѽ�Xb��|�]���y�Tƒ�] �T޹�=�9Y��:Ԓ�;�g�|s��Futh��Rͮ��U8Q�˂���ɢ3�lsԩ*��x���-�ަk��f8�{py$��%�Y���٪�'@�F�pd-��Ў�~�Hʗ�p����N}b�mW�L�����{�Wz�*�^��i59��a[ćmw����4��܃?�º�f/�s�M�-�0W��/�&���
]l(yos�?C�1B�;��q�J��U�"�c�(�%��՛��E3�a��rYhƴ5N|����V��_�q6�D�Uɟ�Z�ܢ�Y���T�F+�_Lδ��z
:nk2�`ߨ��2��� X��e0\-�A�c�$}��"�G�B��~��W�@�֦��C�SE:�9�"���+�J��x�}�7'�%�1z��?���_�%�V�G�m9�*x�!7�t�.�M���Fʸ�E���5�s���������z�_���s4�&�
Li#��sr�4=��"��vt��0����������V�F7�7��]�u����I�8L���:��8f�����}��Y�r~^)�;�� j�8nyq���h9`���LIP}����s	�Қ!F+	�^bNވ�(7q�&@Ո�����G_���[k+���Dg��A�F���|puӺq���΄���1��Fe�{�ߩL�^����er�mU�(�X~}��\R�!�
3���i�sU�Yg��Orŉ^=����<{�"����a�h��ިH��K��+ز�W>�s��7��R��q����:`�������F#��v!0�"�Yєy|�*�@�9'u��Z���Z�hm�%�eC�DۂS�N��8�s�j�j����k:�ǝ�����Z��a� �0U��V��̙v��;9�`Vq\�I��Sh�bYdG�g��g�<�f�eB��>�>dgB�E +�3T3i#^�6DO�m�A��/+Q��D�]Ra߻�?go�APq`��M$��2�uMj�sN}�љ!�ڛ���.��<�3�ڶ�'G�D���Ew����sኾy� a���N�Tg����B�A�]��7��gc\;ݓ��g��<���a�#'��K7A�	~�&��f�ɵ�V����cd�Jx��q��x<�t%�)��Ѹ� ��'L�\m��!�~;eeE"������jq�������j�1ƞk��`-h��#��-�K��1Y���)F$��&6��G�9��e��r1q	�| }��V���[7�m�z>���%���d|�j�LU����e�5p���фa隊-�v ���@���V�7��R8s=be�蠉v4���	�]z�/����m�=��L%�2�tW��~��<?l׍gV������OA�w6[!��n�/ �2.#����¶M9�'�i#�L�p!Pkߴ�J��?-~��N�@t8��_�=��N�w�)����G�4���D�o��A�E~2kc ;�'f��z<�U(Y}�B<Ӭ�6H�cv�K����,��i����̱�&m}n\J�C�>z$��W�[�*6O	�̴���2�^�&l�f'"��Q�"ҕ���?��fd!�����>�Fv��m��\�G�v�^N��Iez�<����C"j%f�Zz��˜����>�_�s\�Vh�XydI+G~ *T���9�,j��w~��$��&7������BT�[�C��_��S�96ߴ;�1jZ\�?�������1��$�ǆ{25Q�=�T1����08�\Ș,E���ȼA��^������o�N�Y3	����s��}V�&�Z�Q���� ���_i�P��$T�죂|C�Q��z�-M�1�T����2SM�Z��}ݲ%�#��WʲY��L��%�גfk�-���R[���?��07�:%ٍh��H���.E�@H�c�D�_�4w����"<4��B��6 ̲�M�_�m|(��]dY'�^�%{���Eٱa�JJm�NB/�?��aB�(}�O��m�Kʐ��
�˘TP�4x[~�7��>C�7���:�C��Æe�D�ծE~x�h5%
�S�w�A�T��I�K�3��8�ҪK[��P�p���8�s�-�����G)�ߺ��V�AYseS%��R���-�!����f�J�(X|�V:J*~M>S�����`�VpƋ��5%݈�N��ϓ[KlSiM�)X$�tf��/�ʡbBH^�O�3u�Ql,.FԘ�@��U*F.�v����ȍ���Xd��'�[���`q�r#�S��+�7�7��
��-$^���B��˔�Z�0ە]��uV�8h�J`Fx����]�4ӹ������+���G%{����9���� zwq������Y}oD8S�W�:���ipӇ�r�O�����߯7ŋ����&F����F+�_�:�cs�8%��^i�~y��"{A/<D4�쮾�+�Ky��X0�0��M��}o�)��v��Y|�/�wH�Z��
�_͠"��o�-S,�����
1ө�����hk��Y��jI(���˦�ɉg�}/�'/XTjD�"֢UT��U尲Bt<�2���"�h�E��q���T����"�z.�p�|�3������@�i�
�>
`��N��}+�}@̗���k��ĩjB�ak-��C7��Ҏ��a~Sg��'��7��6�ͨ}+�2A�� �e�M���6��W���,n0�ٕx�'�pg�D��"�.^5�Q��Dp��	z縀�֠]��G_QA�z�2��*�c<�&+���ӿn�q��Z gY�c�J�m��5$O�{��JLčǓJڝ���{�!kFr%_K��$H�:����$%���|z�q�!";UR�Y?s�&=.M�e�������w(��Fݏ�j�����&�o�p؅�Λ�����`��P23��S"�72/�2f�Xi�=ҐP�l";z�+�k)����k�=D�0j���N�/i��s�s9�ﮁO��Ö�.� "�ATT��� ���"r��y}6<��c���)U��I #g��IP���l�@P�k�x�3�	� -�k>���v��p|UW�\ K�T(l|�D���Aq���d'���P$X,^�Եv��^�=d����Ơ�U*�H��ـ�Q׉|� ��{��d~X�|i�E�I�+v+�
`C�m�s�i^�ьԚ�"`���6��9Ɓ��~�Y�l�m`�Z�Q�?���]�w�cX9����=��!�%�/�e���\����r��X:�ɮ�]�2a�kQ���b�s�4H���_�q[��g��%:��� ;�|�	�)S�� &Ee�]w>db��N�c�d�e�:S
M�߽�Mjc��k=�F @m�IU�R��Bdn�q�n����4���=��Д��l������Ca�؇o�a Y��/[G�x�?.:���Ec<YS�i������x9��P:���+�+�����#��w�H�%4����6)���u��v��~&��#t"eU�Zcdł@�>�bs)�jf��3���cvt��I݂��Q�d:��#C�x�d�M��0_��&�.6�A��`0܄�<~#����I��v����J�.� ��>O(.��\5Jv&U�W|T렽F.�Y�GО���m]�L���@*� �R��p��yyD_v��D��Q�����	�N��p�"�
���*5r��g��g ���9sU�~F.�:�e��ǝMM"��P�9��6�Ү\G(��;oHvL'�k������T�H������M"�y��� |Rl �~��~�J��e������ۘ�f�P�K�|-���j�VwhQ%,;�� 袡��~N��joq�A�nac�_w��Qn�U;�/���Aj�Lެ}�ފl��U�0��j�"�B�a��^���Uy��������h�V� ���]�X�>�2�=�}����}��L$)9\y���dߌ"�g(h_�c-���Qҋ�u�������1b�C)�ZJJA�����J�()�t�ř�Ͻ�����+;�G��9�3	�@�����㍅8�M�%���H:i��j�&ڡ��=$�u�c�hu
�v+�Wܻ�*N��-�g���%A������k'��H_>��fl�U�m�3ʬdex�8Y�T�&H5�vk�cvd10	���ʼp_�(�������	/Ù�N�?C���l7#��3s����X�$��y}�4ZHN�%b�z�č�th�Gi���[-H�k��x�P�Z9�o�bP��z]u�\��jٕ?�0YmS0��IЋ�E�k�����3Ws5tVM[�����[:!ᵿ*�w�zl�
�\��RZTKRD0V�!ǻ�f0ga.���`��/�
V!�P�@����Q��q�#[Eϰ�\Nd)�����	�#!���G~�7�P��.��g#��}��M~1�ib-p�;�I1�V���Pk-ΐ)߶�� RD�6	~�6�H}��?�)���l\"!�,��V�#�R`~S�C�����U���YB(�!E�T6�)[m��K���ǀ��4*�fp�`��ϗ�;y�XQ�X"U�=��}�6p�}=�A��?vr�1e���ʃ������Z��v��!/12��,��Z&`�\��=��������fC����͢��s=��'/>����͌뫘��ԟg�.N��H��j��wA�L#Z��4I����!nwL���_��< �]U87��e(6�&�m7����UFF��8��x1�=�d���%/;R��`L�ۜ�V]�{�q)��{Ѥ8k*�S ^�����M��W�Qi�i�A_��;A#����6��K,y&�TN�,�D��#���I%FVb���s�$;ƴ��?άܸ|TP�F�_ʲ�$�j%������{I�u���w�� �m���-1| �k@�B��T�x>n��6��bO3���z���� �G	vw���m��Vk>H�#��'}�AmS�g�[�bF	T:���=ƿ6F2	 ������U�J��^*���*�F�@�7x��������i%���'�}��G�Y��$/�������ݕ�0�-��J��\�r����P9��a�3K���P�'D�	w��0�xc�C��n�]ѱ�٘FCT�]�{����Viv��Ȁ0x�b��ٜ������R�A��h��a�X�o�\7����
���l����b�X�T�5�(r � rI"X��[��m_Z����ޢ��L�YG�P	N�nm(lK�|��a�0Z�5}Z��<��;��o�u�� �e'U���%��^��v5�- ;Z�ʥ�/2m�$nA&� ���+
�D޴�c�n�������)�h�B\��\d����6�|F֑ )q�c�4�@�_�޳��p�e#NCK#s{�;!��@|Ht�;��FO�<?u�`ə��7Q�'5g7ffl��eGh����=�ㄶؒVJ�T��
D�8����4J�<�^3���~ HylƶΗp �m�Xk?؂;r��_'�h�{1�I����H�K�J�=�'#�lc��?���+�r��߱�v�j�XB����+�SKG�i�I�Cn��`T�C����o1&Vȏ�'?��G�~2�?�J��Z+�z��d#��+�`113 %N�����l������"ӍCce��-�b�bj�s��J�x��z�iA�-�,�Jl9�fdP^I5â���ug�/��.eG�����Lt��6!F�C���~��V�<3�� hTd���	Us�����I�3���ݮžj`�ݓ��e-�2�:'ܩ�D�J�5�g�;���e��PgO������o����oƈ@�VLeQ3�N͊y۵�G�h��~�.��Q���I賀u���a�RI֪ˠ�<ԆIeh�MlR�.Ip�zR[��3r%>��Ed�4{�*���"�^�]�s�� :5�5�Ń�c�i��#k	�.�BX����"���K�f��Y��]�rW�V��P��K��g�����	���?aZ����oXD�)��M�#�y>���Fa�
Y�@5+��dH�����
J�%�ݢ9}�85D���\�2���Nd�������9N_���ą�?b|΍�/��p�x2��23 j72�A���1�ߤP�;�$�GSD�K�Q҈���3��B���`�J)l���?����Co�r2��?8�O�l,�2�qKל$����q}������O���f|�D��֭m8��D���8�¬o>��'�N
}���+��f�]<��F)/���s�\����j�?�ȱiH�l�(�~1s��v>�F$R�Бq���c�Ϥ�0�����(R09T���,l�3�O���l+�Z�ҳ�eS�A���b�X�$/�%	�J�[l����_#O��G�.��ѯ�_`檣+]_�F�^O\b�i����28�FfќΫ��} �����0|� t���q���ǩ��ORds��;��ځ�86Jl�������6���sx��=}��<'��&���5+| =YݗA��ޤ�-�<Q.�|�h�{�7�eG��uP~4Żp���榊Vw��M��U��7���Y0t|K*(R��g��I�&^��)���6�nQ܋ĺ(ns��<bi�1Uj
#B�g�� ����[E�.����vQ��4��؜�p0�mʛM���E#��ŭ7��[bH��Ԍn����]���m+\����T���
Ir�|oj������'w-�X���I�с6�xK�,V^o̏�c��!;p7J��5�B�V��f�`4�k�.�R��T��z�>�5����p���Oa[�g��LS��eiv�kv��ø7�����d���3���o��79�[�D�\r]D�ɸc?�Qپ�=+y;�C��+4�d>w�U��7�া�l��ɬ	�H�-���B̈-�\snʝP�:�㘳!Y�h8�edp���z���7u �뗳:��R�][��Z��d.��x��k��M�*�߰����_���Y/�Ϋ3J�Y(Q��Lϴ05��D8$����x�"U��k��E�q̲X����&�+�N|(��� ӥ���8�R�ⶀ �X��M~0n�8��E�P��	�<X6�ַ5�����^�$���;�=�Q�6����l�+5��@o���&�S��Ó��<�K�~�����a�D1̬x�鬴��)+���w,JH�/�:�첻䚆����1������*�>�^N3�+�j�ػ�g}��I
-�]2G�J0��F�����M5\J�����YLPD�>E���|̼$Yk@&h0�ɽe�I�ح
��fx�v���ii�~���<������I��GK���B{�T
��:f�a��1l[~��2��g��O�Y�)���%�����X(_���T����7�	�J��P.$�]r����cK4qm<�c��*/; ����=��0�C?�e��u1�p��
.�����g*F�\6�����Gf�,N�@�tѲ�4ϳ�
��P�6�1�eeզ$���7�
�+Ϧj� 皁/OaK�+IT���ϻX�wI�̆���L�_��'ެ�E�9�0�dU������� t�N��1�����hPK����=V?9�����'r|�U�_��F�Gn1TEQ^�$c����w���腱�=P#D���A_�r�wjp����,f�%v��.�|�#Q��ӝ+��Y�⅄
��G�*%��G���s�����#���Y���r�juM��1#G�Tg
C{aG���	�����5����Ύ����?9)I��^; �-%��$�Q\x���R�L׀T�}��o�͊^p~��f��c�"��J׈�=a��ӌ̠-���[D|.g�*������x0X��G���=7R� �1�^"4-Z��+�ǩX6&b꿕�� ���գ9hS�68l�kG>%�P�B�[�swL�^�{���@�b�GŤK.O�f`o�8�����N�v���,�rA�x�E3kFF��C��fE��|!o/��J���Z4��%��VeM9��V[�^�!2=��G�L��9&����TYE�e#Ch=h� H�O�FWv�!x�D�R�Q��T�g�Ty(�4G�ɷ�������;���]��9M
�۵�x��0Aq�7]��ɹv$�ծb�<�F��>��DWL�4L����I�;���f�`�����"n<�#��������H�7�\�����n�8\�]˒�����~��|��U�"y}(U�����g�b�8���������ƘO(q
�T&��6�M�}b����Ц�,
Q������%�,\��0؝�7��@`f���g�~��F2��|-��^��r��qʳT�iHa��i��CK�8�&�5	�s1+��=����q�&�3g=���l4N����n�Co.��7)~4�~�I�
��4��������j�ƮW�I�`Yȹ	UGW:ǜ�1�އ�Q����@|��*��M�	D|�͹U�Ӻ�;(d�3�6'Ng����pu@a�5�uX����}�ͤ������o'�+�s5H��p�݁;�L�1��5�_�)�}r�-�qNk@/>L�2̷�v_�E*����?��$���\8��\�|Sy�gI��e�C�I�9�u����H˱��8ƐZ��K��W�}c��*RwT��(��B9[�`3�q<�@S
9�w��4�9�/��a%hDc�m���u
�xV��!@�n��k��n?��H��I��0�z��1Lv��Y�'#[���/tB+y�y����$����*{σDכ,~�b���dC�=F$�q^�����VJ�̹�0�o	����pmW�c�.���|;�jP�8LX��
\{��~B�so�ٻң�T3��H����Tըw�m��7F'�s�4ɑqp��<j+�Q�%��e�дh��]�ɀ�m�/�43���̵ɤ�NŸ�pf�ӻ�E�},Z;v8͛$g��Of�/8��?�LL�����N�4�{���S��;#q�{�g�,u��x��T�e6��LLHSJS�{	R���
��n����Q`�'��bP<��V�ZJE�s���l	~y�����$�y��������r;F><s13�͘��/���}�ΐi��l�}&�_:�%u���ïUp�M�u�"*��3���M��qj"M¶��[�Ԭ�$�{ iTuCB��QS�F;&��^���%��>C�N���l�A�H�Tf?���@��o�?�l�"@�h�<���)���l{���p�ْ=~Mn�?�S��_U	�UZ��3�G��#�B���4�\o��E���U���|�L"r�X��M�ܯ8D�,�RH�ze���c�G����@J1�l�5�=&I���� �O8�:b�2��w�]��HF#�]	p��	��+�_C�aL4	���&M��a��fL\�6�
���X}��@fY��Hf�C7f����i�;{Gy�re]Qx>����S���d�ӟ�ĠB������]2/����:���H�
�@�A<�й���Ԕ����H�ϸ˜4$�M6˘�~?�H*���{���&dG-_�2���W�^�,�+��1_�a7�����>�6�cڳ������Xi���n�₉�8���@_�����v5p9��p�M�������̮�=���%�A��W�GX����A���n+��3q=�����`�Ch�����PI(�y�P��(��K����]����d�\�ݏ)=���+� 9�y�'�&\O'�2�<`(l<�ɶ�˒9c�n>�uL�+p����;�V?����S3�0;��~�B`*�~�:3�(൥�����V�;�D��YPM��C�e�u�ko� I�yw�9�K�9�y��%�� 
 �(�u��m/8{��h�B�_Ȳ.��9s/ˮ��u1�@a�������(�D��|̀2�nM=���X9��� A�)Q'��v.x3ԗ5h2�/�)����-3���� ����}�TZp��x�a�R�3��w���b�Z{��� �!~��b�G�.?��\C���H���[&$�F��3��ڶ�7����D4v=�B@ &���	/H�[�5�J`O��`�>|��#`�h��H�@Kk�a@@Kc0�S-[0^�>N2$!r�ۦ]�@�X��AwIy�����U��ǟ�m��D�s�9�Q���YA��`[�����X��UT����hŀC�ASs��f͝��ѳ~I3��I�����Ǭ���l���u�ag����}Z���/�^`�S*h/d!��g��(��=�FDd�LEܾꑿ�	�54ۂ�JR{��DU J���2�7��y���̙|]���f=�C͊��Iu��	�i ��ף�Ig��+�[��gVfa�T��'c��Dn� 0Z�,Fs�C�Z�έ�-K��}�5�@TM����Ɨwy�w�Rq��z�q�Da��Ϝ<���,���\�폩��<G�aD'P�2��A$�_( z]��V��Sg;U)�1}��(��;Ŵ���:��|s@�s��s�1Z�ɽS$,ZY�ܲ^�灒C��9�k��{ vE���t��r��}�o!�36׸Yk˞������}�Zt����ΙzHC�����N��>���ԛB6�;��E@֌;��ͅ�����3M������;*�A`��D5s��OA�����,B�b��#��� <���좿ͫÑ��͡�'n�u�A&�D�)*�:g�.ꌑ�>9���C����\[g��6���#��� �Ȫ��.i ���Wt4U�ײP5�#ixg�w�=�K�$���+�a�����Mª\�tT}�O�:j����.�[غ
�&���x�&�1Q���ٜ�љa�@��Q.P<��b�z�ek"I5�+w`�n�|)ϛ�3�h�2�H�%���I���næ��S *6��ى�Vc�y.4�Ԭp����!-����cI�
I?�\n+�������+���՝������? mv�>�����k+�H���Κb�u�y��>�9I;��m���g�[f�⹸�`� �6�cN�����~���$�j�.�U5�wo�v��^l��S�����;�n��G��|�+�P.�&y�Z]��V�t�4��'J�1vLKc�ii��5����':Ņ�����1�?��\������^N��Ի7��	'P��JG�ma�[��7%�/)�CF�t�~Ug�<LG7�f��٩
��f��B4/���E6Iwt�Zt�.ނ m��������5��7�����ظ�
@�Hb�M� x<��a?Rj*��Nf]�ͥ9[���|�$��f�>��S��$ע��XVH��;�(T�J����Q�Շm��=_J�"�����)XF���sX�`GP~~�6���v��K���}ɖac���[���h��N��X�x���n��6�F�]��(��mQ���!$�At3@l/g|r��?Ѷ��ϩ�1��n���z��7��!�\�͌�����N�Y*}uFӾ�<�.����O2�X2�"��%1u;#>iC�El�~e����Q;^�:]��g�9z��e�p������Vܖ�g2먥�+���֓�{���9- _B8��u�l�q�Y�K��#�N���`>��fK�w\�A��a��\���G�s"Ռ�R�9��<8._�)��㯿�/�(�2��u[J�(/�*��M�
A��m�7i$��fF	S���H!o&���U)UЈ�n4;�?)u�����[�a�iۗdr4�Ĭ��~�Iϥ  v�vIWE������W��N]��k�6*�A���@�J�`$�8����>����D�O�j�o�Q� �Q�A9�e�����M�l�p|=�D����>�Gg���M=m o(�6o�l�-�)��ލ9����f�������d-'�Y���["o����o�(�3�>M~֎�l����}�yo����x�S�<��\��ֶ��9L��9����2�W�������	���1��8��&V�E��=��ҟ�V�����9.��gM4����������D`� �����1������W�a���̺���_��8�;�{Cli��5�*�o�cx�|SV���S�+HWJ�cn�#�	��0� pm��Mƽ���Ǉ{n��i������	x�]ҪE� ��"��[��q%S�pB�_%i�����,m�#����p����J�EK���X����-�4�=)=i�D�Z���KB�pH~�[�	j���J��8͔�(܆�,5&�g%W�U'9�z���q�vKG��ok�p�ko�ܿ���ٱұ��1~��iͬ^���ǘ�>�B�:>�¥Fy��7�����f4����q���<v��FR( ��wsӿ[���F�Z��������~έ>2ga������U�gݺ��v���+,�3��x��39U�G���B�N��j�XL�u�z�����Vڃ.�r��X���PB��|×%���z�bDK>h�H�J09��X{@�c���B;W�d�0�����s��g��_I��(��ȧ7-7��:���k�2��w��2�_�_�Ep(�������充�#JxHm�����rM��L�	-��a�ϫK$1+��d��\ ��N�Сp؋o<�t���bv�\�d�~�P��,���c�SFp��Q�o��\jh=�^5�4;�����3f�	t:���X�Va�P�dc�?z���:BC�fas�5��"~F8�4Q�؆�@O����ǆ�`�d�,|����>j6d{d*NRM.t��<"hT�[�ݣ~?� ��j(u _K�u�c���(���[[E]�o��6xf����<�Hl���X����)���b?��-�%�O���o5:�[�մՖ#��#��ʖ��ސM��jQdB�p	+�%5�w&���=�}>L0d�^��tEzԲ��~YW��o:�>U�	�ʨ�/��S��R�|�'�$��rD?�I:����� �S��l�JH�
�*Ԗr�}��Z^���t3ME'c�Aw�d[Kf�*ۮ�w⊘/H�U�D[2���_�|с�v�-g�J�5�����6ʱrr`C�]A *�Ǖ���X@I?"���l�6���塕*(ĉ�{L��׀cj��c�7�c���3r������ĒZ�#\/{�Ø��|%���o���5���t}�{fQ�,r'䱮\G�ԉ�յ�!#cC�L"?�a2p����zM�������S�bG+L���kMд0c��|�qA} �$�ȣ�Q��+�Y)��V�^:6��Kj+�'�NX#IR.P%����e�>��D7T����֙z}>�<7�[Rp��)ڏ���;+��w�mŉY��&j���V�3�Ҡ{����uB��u-��״p1�Q�u<�{�=�>�h���j�x�^W��]J`)
������:�/W�`�=^��]<���:mW3�y�,C�83n\L�W��K����U0O����wuu)R��G���{d��q�D��$���ɘ.����#mg%e����ͳOkһI�ڮ��p��5̔�
����Vd�T�;�ߢ��;��J��N��a�Y�YfyJ�4d�3:�n%ד�xq-�ﵫ�{��7���o�t����C�h[�ڇ�Ȅ[��}TE��X�����~\r٣h�Y�5�b��jҚ����R۷�n�)s��3���jg�"�x멑8)t�b�8�v��4�Io�Ѧ���ׂ*?R�ţs�8�X��2T�)��@�l6�P)'�*�(G=�i{V%���y����)�N/7��s�W9����2�_�I���*(��R���r>�'�:�(���N������>��"T��O�@�
��	�(y�<FuN�W&,���|��Q������7z��b�2��f�[pT����ՖKb�����/<�Fo�nB6�9ʯ����_x�w6�n��E�D����~]ݮYA�:Lu+Rr���^Za(�ze���L�}�[�~'�������=�k���M�`8���_��y_��3MMp�N�{o�:q�ruT�]�{��~�_p ;���od�$@�P`s����3q�e���3�=�I�$��M�v��3r=���e�:� M�s�0���׭w�!���s�T)W9�צA��M�ll`��c{cqJ���Y�O3Sa���9��ti��g��Z�Zpٌs-��ݐ+^9�l�|՗�y���6T�>Wx�P�D9���T���\�4���5��|�����No�LT�㾰ə��$�w� ��X/ƚT�;䚨�G�B��M�*�Z��V�f<�#ޘ�ߩ1�&k	%�B��&�{���-p4�vҗ �E�K�	`u9��0�k;�I=uZ7v��$6��>��K�����ݷ�h�`|�pS��H�O�|���e��#���{�5u�����&	D��/)X�Ps�D��,�p������(hI�1�|Y��wD�u3p��[����t}�S�OZ���7%�b�l�k����A��+�#;�]c��	��SZ��7��`�+���%��=f9q�%, ���Ca�[��!�˱�H�F����y�u���1^,�y����>#���hԥ�r��Fe��]��uS.i��E�5�g�;lGOa����u?�Vc4�����J�g�Q��[ޞ��۷E7��O��44����ױc�s���٘h,�D&�@�xl�M=^�T-��*[��Mۛψ՝̕b=�ɅNݴ^�C~��1�G����Ph\w�ƒ54�*c?W*�
�Z�o+8�"����|�F���ٓh�Y��z�"5AxШ�`F��K�7�@�s^�a�G���ct�jb�l���!�w.|>�{���3�;#-�������j����+��u�5����g�\��d��.�r�B�쮡2�M-}�'Ő �lͤ�����)L(��Fx��~��%kI��c$�H��A�V�t��и�B{�U���Z��#C&���t���l� .; ~%$+����2g7[G�U�������(�����Q��L$���6��(������ K1Y!��N�G�vV�y����7�H}j�����F��)�㼜�#��$��0�������	dl z3��ϡ`L�F�3�m���ce���2ܶc�����x����<,r�OD�,,���8k�K��{�CM�N?)5s����ɤ9d�L[����T=0Fv�A�u�ĎR�'�j܎;f�oAd�K3�,��^�"G���8I��֊%��+Ӵ�N>=�_����ѻ�H$�2ۀ��;�B6��.E��4z�tї�������x�8#��bݕ�tZ`hͳ+�C&���u��`Vj���#�̆��q�ƾ�s
Z�l1H(���*a�;��$��`���U���X�Z��]�T��[��e��)��D�f�v�����]F��m<O-iCA�~[Zp�l�ċ\�f�8�l���j��<�^����䈵��o���h0k�s��8��4�Fu�YU+�� �v�6@�xC䓆_�C3b� ��d�@X�-3��oC3b%��+8��Q�0����]#H�������F�����YUf<��Ȼ��/��%^�S4�j�[�;���kă�H���᧭����E�OLɸ��9��Qࠦ�]��|�ձ'1iP��x�SO"B�,���#��*T�y^��33~L��O �������'�����5�q���P�$F�[������
�.�+��T!�R�Sr�4�<p�FyS#X�R�<���*����&z:"����w>� �hJ<�6�tKX}`�T�z_�@�2�U䔏�\����@E'MY����Kyj_�0/Ԣ��@��OjZ��	�d5�M�g�G[��n
b���5'�;͜�m��$;�[��\�@�X(�'��6Փ���3�� �	�G�\�����*u�����U��t��Lm>8��P�gƩ��#%S�jW2jQquk��W���N�ʐ2϶�(*�GA���vn4"�p��C��e��a�	�Ϝ�8�}
��L�Y�C�5���S�Egو�����>�2P��+�m���#�TY/�O�pZ�l/���Z�!��3/�����4Na4A�֗$I��� 7�Fy�G���uu���9E�o��3�-a�rؐĻ���Z�)�6`��F���vy�2���a�ɺ��3."�A�����N޴�?)�c{Bp��ڳ�J�).�2b5U��K\3l��@R�D|�Tf%�X�⇕aI���R
1\WC?u�D��3��ԀQ�O��k"R'3��}�/DY��X�(�7��1�s�3m�߯]�ݡp96�AyUgEE�;ϰ�\KWc�;�[�l�0��Σ�h��7"1���"n��^ER|��F6����l�a�-;�b���w`~A	CEdQ����"�k���cd��!ǫ�M�ak�d��f�Ѓ��N���t/GT�1oΠ#�	�J�=	Z)F�@.tI�ֆ��2��Iw�Fr��Y���N��p�r����</%�(����p2��UI��,��6!!�hoe�Ů�i�{�"�C}|K�;���3D���h{�O�|�FM�A�$��%�".6��'�����]è3m[�C�|�Φ��n~��br�u$e���_�:���q��sg�щ^�[^/,�4z�}��=�c!U�Ǻ'nT��&��2Y�?#��L���������b���s��F��m�w�s%sM�H���vU�:�:u�{�M��IP%N]�Վ�<F�f�ܦ/u�0��P<;�28A��]�X�d�{ZX.���l�?�ѓ���'��4�C��;/]����L�"S�Nz�������'VNͶ
���E|�G��\_�a�.�x���l�:$T~!���6-������o�v�(�]��H�V�,��u�Jn���$�����:���eF!�t��O+���C"u���U���5\cdHQ�lA����ό��[@���@��o~��4Tv)G�dh�X�U�8����"��T��v�z�%��h� ^0�����ڀ���M�{%mG	ӳ��z�_$��/���¬Z 5��9�sd���2��n�м�ig"��h`ڟ�:uu׆��c��P���H/�{6�2j"!��z���
@w!~���|#��{ p���F�*�b��S���3�K�En�2e�b�p�|�/�s��f�b�K"׻�(�M�(�o��߸��0/gJ_��_pވ�|�)=���J��(aK��Vt��+\�q3�,|�{������ʨ�'��������5V�zP �ÝI_�|yF׵�w�o��U
۾V��!b��P΂�[�Y�J��N[N�gQ0���[�l�ɫ�E4�C�-�y��΋��@���
�R.�����cOX��=n7��j��tJ�7.�\B�Y_��a�����u �x@@>�Ϡ����f�=�*���Q�؇&�]�5��\�H�J���,�{��\���n͡�u�|�)��+T��l܎R�Ij���#V<�d+6����f�s3덮��é���WN�n�l��|A�gC	_���V�B15w+���E�h�[i�0��
D劶u���|@��S�6�L��(�8DE��U�����;"|�3��)�-�?�3�1w��7"'����_L�`�`:м����Y<����W�5��ʌ���W��N������Lǲn�ZC䍾���YL=�̼�a �|�R�O�3�d}+ه��l O���|F�O��֓�7��d5���!�ؔ�����ug\�4m��@�xGl�Vʗ�#~t��_��+V��1090�R���6����piR��Uɻ�7�_�lJ����jˋTQd�m��|8���kX��R���~�;�\qn���zJj�.�t}FAxSIr�4J>!���q"�� 6�k7|�Z��Cm^����K�b�oy{i|IR�@���;�=R!ӳP�?6A��a{s^����W��k�*�h���u��p��	��=ٽx`�T�_�zk�>��/i"F%��v�j�݊T�h��aFen�|�uZ9����./W.�*y�3K`�ё��Z��j�w�DaQ������!��j�ۋ���-;�؞ɨ���{���U�q��/ըq{|T,S|��Ōt�G:/a�e�;�+��:9�}p_�$��e�*=/y��?ܓh��6io��(���^^vR���m�*s��Hzt�����%p u��dw:��h3��vD�2�q���vZ�'E��u�I�O�/��!Rȷ�� vA�xay<�ӷE��X�����Tߓ���&�u�+ݸ.�Zp�6���aͧ�;�}��H�Mx���w�r�R����u�qU���o�O�Ns���(ƫÙ<��8�e$~*��F�
�� 	L��~3t��(0��&���)��^6���@~c�lD�������#{��s�6�+iB:�#a�)��V./��n5%ETZ���`��[�N��2��sx�U���V�D�����<zq�Yne]�N��>grSᓧP���;����G�+�	[�v����B��A��1#�vM�ddF~й+t���@��S� ׇ�w��S��{�X����?o���T6��dci�,LHr�t��6צR7��µ�Ӯk~�3*:�K�j�"G���r.(%=��o�{�r��ȷC�+P��A8"i���p)�p^E�2(6R3���h��$��q��OJT�"���Cե Ј2H`�O�o�f៺=9����������t�/̗7�h%1n~��`���(`uD$=�%W��v�d�T�s͘-�Lĩ0,X22:b���O�yg�
f�M��j�R�9ȏq��i�_o�d_� ��� ���Q����&�Y���+�"�S�FﾥMb��x�Z����u`�ك�α�������ݯ��C�E��7l�ig�#3�x�������&@�|c)�t`���<���?y�}�1�Kv�	��<mw$��
nG�N>����V��G-�P&& {�x,��������3���5�q\z����@OO���^<�.��J�&��z݅�{�&w;�K�ȕ��Y��>���Ԗl�&f�i�'\�G�M������P
LR��)���%�P���1��ȗ ��z�p$��a󴞴�Ny���䣞��ʖ�,k��[d�0�n�ms�5�T�'T����ͱr��q���2�N����CL��`������dfG��iۼ�-?@,cٴf|�f��(ʀH4Q跻P#�_���'��;y� �i�̐eJN[��m@����F���P���S�^ϵ�C�»X�M��}n��*�^�cEx=s<��z	T�#Џ�+n��%�;Ue@!_��N��)��E�����bh1����&f�
�l�θɓ�^i�i>q���4�rP��\K��"s���j7!��f��,3,�E�����B��W�AO��=��q��Я]���0!������	�rOH|]CMR�y��A�3
2Yi�&G�b�#�-;�ϛ�*��~��_y�E���_$e,#b��dE��>�����h�:|QD~��]�U��*�
wf��?��T��%*����gn��2?�w�3\���$/8����Y	�Ϣ�\X��-G&4Aۼ6:&OW���U���%�t�[��Q�=��Q�{�&$��k�Ȳ     �/�%�!e$ �������g�    YZ