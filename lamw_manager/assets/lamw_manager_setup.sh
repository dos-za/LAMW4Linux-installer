#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="532006236"
MD5="d629230e28a5d36fee1df5bc102d83b8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23692"
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
	echo Date of packaging: Sun Sep 12 23:41:57 -03 2021
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
�7zXZ  �ִF !   �X����\J] �}��1Dd]����P�t�D�of��^Gư�Ӭĵ�o���CO�Bm�5K9��s6���d���gΪ��/���g����HD�D��fg�ˤ��:�D0:+�f��yw9��~�R�N�~�A�x�n�iX�&�o3YL���3�HIde��WE1����@$(��8Q���8f�K�l��虚�Չ��ijI��T|<;�d>B�&0S�Z8E �^�c�o^�N�pm@��Mzh0�[���;M����b������dG�aR���P^��~ �(CJZ/Jo�]G�yA��h	z.[��I���@�� s~�bm �Y�G�G�v�>�/IQ(c9�s��V�H�N�W�-cA���i?%�m��X�Pm Ƴ���g�tzg�Z��"�9�ؑ�,'"E)�r�����B�$�M3�5��it!"�;���J&�C�	��U6�IC�Y9�<Ջl��<g���˨̳֨~���E�S\�?�`S�'�de��!��4�o��ӷ�]�����-�)�-R%���K=Z���L�%���yW���hWG�@�i�q�;`��Cj�V�����H��d�q�L���W(�́�jdr!���}�U�9�����g.�D�΄���yy��@��� ?��N\d����6�-�Y�}���#e:>�������\-��^����~�[��f��aZ	�w}aH��q~ �\i4�5��5_���s1ݛ/HE�q��ue�;s%V�����M��u��.0�{�A;jnēD۳�kV��+ 첔F,c�]����"�4R���H��*�h� '���U��;�O)}�Ha _��)7nߖ}	'v4���� +�`@���1�3��5�C���j V�D������/�s�+d�sU��u�#Ȳ�~��`=�ʍb���Y�$��A&������,�7��].�9��������[j�m*�o�I���vJ���,�N�'��+�(�4 l��M"%�6�gb��o�D:���v
~c������.���⁣�E�v��iS쎿�*�,�y吟�Z�O�Zd'�'�B]�ߋ��
��'�tjI�޴Jv*�Fo�i��K~tk���2� �,�<�1�>0UvFLʶߓ� ��<q���zF��f�sR'�w}�"�A���I����P0Z@Ps����=�p��@^t �n(4�FY�`�m�	p��c�(�C�*0��U�1�"�F�Z~rG����!�AKI՚��@j��.�3��f+rXs�lx�Ew���^�ݥ��آY0��|1esf6�s9?y�82&#4=_��j��`Vk����~rF��?�~�e(m<sV�[�����`���)Q�;��ׂ����;�:�k<���a@��X+�ţ�^Yl��.�n�Z.����ұx��#�����]/F��x1 ��,�P�k$npD�
 �x��.��w8�!.9���4��zp�*v?���8�p��F�ͱ��l�;SL-�K�����ˇ !���T�����W���Xd6	�+,gw�:�v��k�����X��w�.[�B;',�ZJs]��+ϓ�ʲR6Z�zׅ�6���.��Z���ii��Iܟ��l�!���L�R��!��W��^L" dB�{��#ԐCÄV��m~��cZQ��QōZ���U;��e�����Ly��?���(�1+ �a�|ChYȴ"���DC�q2�$����a�2������C�
����>%���e0j�%�ǿK��1\f����aځ�X6C l}�G��/usD@.�K�L7� W�qJ��'��[�����I�q�hyi��C~	ڕ�-��Og�9�&�V���ҝ�?d�=3Ę�j����g�^���P���ŖYڛ���Gl l5ų��3%�L@��U�s`��52z���wq���j _Y̯
Á�/7����)��G3�	�&�MS����å"���G��A��s�"Nʸ��0��
cO��~t�zv�����p�lvH"���;-�P�m���a�t������T����� ӂ��
��U\�P�p�SK�Fӷ�c�D��>��������Y�j\U������&^p����4��	���c�/G~	q6P�߰?��>���䲓�j�V�51�u>�ˬO����Ll^'fn�^�� �m+\2��6#�c�u'X�}�b������sYEkAu��W�e����C������.Ё�mZd-N�zKWWek,U�R� Y�9�[jE1���щL��{o ���:Eo�A�������\�����IĶ�I5w.\Eש Lp��e�ՠ�a�|��W驓v%�q[Ո�;�̸<F2�O`�|�����Y���^���ѓ)��CV�$��;uUǯh�sUs�t8���WI�	�w���J@
�����-6Kҋ.)���Hk�w���%��!8�p�ov���6%��Xj�����NH@җA����1��[>����b�����*�-8���:���;^���7�.c����7M���+J_���u�PQ��q�����x�vW�$��}�s;���Qh�,)�:x�;�D=��"�zY߃�������#_���&E�G�i��6�u�E<i��A#�_�u�^�)Y������u�fj�K��Z��o���C�&V�X�N!9	#�*�+oWWq��\o6f�|xe����92%�B�����{-a�l�@t*�[�|���_b�C�9&�(Y��D�M�б��G��[��n�[�	9�ҫ��1t�*���ٮ����әJ�~C��R	�mz;�g��.�<���ͽ�G�tb	�B}N7�gɝ�����B�A�(��TVǢ���Y�����"$��+�d� T!���]#�d�,�6.t(��4���G>��Ő�D9��>K��Ϸ�w0���S����l�c?5>J��G�"Q�H����
��蠻?�<u�f��0@��Fb��S ^��`�?�w �$H�1e����R��}H��p^�I�d�����A������a��|��S����^��bb�4T/�+׸	yޗ�V��
?���P,���;��&� '�{c"��_<9_�ϵ�hd|J9Ö�ɮ����@X��#K�{yd$��	|t���+w��L#3�x�s��Cy]xsq���7��?����;j��j�����/
�o�Ԅh"�D8QbGfC���Yף���oJ1��q����N��[�Lf-��^��&?v��tcX�2��]�����?�p6W�M?K��2A���Nw�b��"� � {����U�E�e�xprS#y�DBr�\�!F�~���S1���6,�V���.U�uY�'[��,"���j���� '� �ѳ�g��W5	����:s߬��xf�Q���Lv�İ��F=	�)�˂b(�ѥ�|r����y�$N_��sy�;qt�Q����O�=�Px��t�Yb�T�&Zd�^�VU�����xƢ	�����{���K��q�Uu���Ju*̒�w��˹�V�p�j��J���L۱���j ������������,g#��K�"#H���Ԉ�������P�W���|�NRL�m_.��ꐛ�� (6a*�ux*Tqw��|�n�Ӓ���R��X�0����=����b��8�v��vUw��ۑI�y��}y���O�m.(�����-�H����u��탱��]�sN��y����z3��2���>��vu�&D��@�`|��v����T�F�͘lM����w�=.�1�#�����|�m���� ��Z4��%ӎ<�W���O�57u>���;�P� \�$m!	�(k�8�������)����,G*ᚊ��^���D��"� -��M�J���D�L�"A��v��ˀ��	fcx�I-f�����4��ń��:h�o2;g��䘗���pl>m]�D:};'�ja�q8��1��ﵵn����f䦐�J�zx�&��-u��OM�-�~?�^	'�v���C�����ѼF�!�i�"�uȖ�:�l ��N@g�J~�g�GH{��'�0��7:��@p��L�i�8�-��Q�{_1w�h��添:`]Qi"uAE?�C�%x���ҔKe����o�|_���u#���/'��QtĲږ�^ |��tVÓGq���)װE�[�8g8�j�^��k����5^͕�d�'<xCʕ6)��b*�2�����4�oO��Er��xwD��C���K`���ǣ��U�
d��A�ybU3�>��Gs_h�;�_T�E[�/
c��E��~���琿�$��8���#{ۚ,�ne�F���b�g��۶��	�q~�'0�Y��L�6n'���|��� �Y���r��芌*���L`� �0��(ad���"3��F��D��H�h��+�H��s������`�Hl���y6[����}0�m�ϭ���3]�/�9��W�u�B�m�hnYb�3����<LP���]e��� m��@��@���wu�h����<a����=.h��0N �$1�<z��Mv>�&Lץ�Ɯ�LE�9�t�#�4��YM����Uݍ?����'�$�d�1*NZ}�?Zݗ���ɱ�/�@N���'��Z{�g�vѰ'���2bpXm��
j����p0O-��u��Mm�ef��V�V�i�{U�X�K:�	jh���gAغ�)��1Ӟ���b�m�ENC�U)��g��?/�OD�]��x�c,k퇴�oſ����3��3"9��^l��]`"O��S4񰬥X���b���l�:�����9̋tE@mU~^&#jD��!w�@F߾�*��&����d�#1�rtӌM�	LSEa��SNibp$��pFG��op=�mw�]�&����J�|;GI{�mPg$�O���3fmW/+� ��ed��̇u+rA�'!-i�i	�R?Fu�&Bl3
��b��#m�ȅ�d��農ӫ��U=.���@������0�-��DJ{z�r�'��Q/S��s�����仰��� ��l6ǋª d�����&QPd�LAPF�-��K�d렫�Iy�*v"$�PYȘ��&��rt3럿Nd�%8�AǮ��fؚ�����j�TNt����yѫ��FP�\�
�0�}Ք2�</�Y�C���@��E��J2V�T���F{�\4����L������Rc��uZ����kw"�1B��)L �^�`�̺3�-`hZL��%Vӛu@m��EzT�^Ŷ>Zr͛���k��B�κ��\j#`s���7�!/�Xn�w���]7��aY�g]j;�ݲ�o	Z��?����C
����Y2H +�TF񖆀����e�娔E=i�ds�c�i=1�y�o"�����!�@NN��;͵(g $XG���H��r�Q��G�j���^�F�{UY�J���7�^�8��o�#�=�1�o$��%�f~(��[uy�D�
Zۍ�s��ШC`G�ڒ;�e�暪GQ�iމ���Co�;��WI'�/�Ttc2~DN:��,z�[=��'�ps�>��#N}r�8��\�?Ҿ�H��9�-K���OjuA�.�GAE���V=@b�������-����+�z�`̗�ܴ�Ɏ���/��-����5@�	��-;��I��I�g��5���Y�Ou@.[��6=�`ԾD�1wnrw�<&G��U���3U��#gdB��/j�����^���D�x�{���֋伍jL]�c��3�|3��y����-���4���6�|Uܣh���u���r�,� U]�M0���~>/jۉ��՗Y�/xdڳif	9pu���{4��.�o�o����T"����
�]�VE�J�n���*��R;8��%�)�iź��Yd��zق�b�G:�Ȩ|�M���~;��HA_�,����j�u,tJ���yA����K�m�B�8E��$I�>k�r]��,��kp,������ �q�ܩ�nV�0�5�O坔��H� <�ۮ@����yP�9	�m��0��eY��ֹ�[�j�����{׹�L7��ԑ���lI ��-�/i��P����UD���+xz`�����Б
��F�|�5t�����¿Ī���������!�؝�B�?�����8�;5��D���Ҡ[k�P*w�f�j���5ѱ�� B���Vq]r�7M|P���j��Ĭ����^�Q�/S�SU���]��f�-Qb+u��s�ڋ�o;�ug����]��`X���o-�)�&p�J2��tMC+�2z���pxd�;� k�ȇ>H���ۺ�A�wĔ�D8�	+6K�Ձ��T;���	6v�w���P��I��j�Y����׷�!�$RΚN��*����r,f�
k���nC�ş-J8f��Q�9xV�`�;� _�6X_	�c�'�k�.z�.����Dlm���3�.=o(�tu�;��7�+��6�����z��fĢ��8�����"P�w&@GL�p�m�0Q㼂P�v�H�\f	ؼ K`ӽSJ�A]H��� .��ߦ	�4�>�`�� �,6��P
(��K��aNAp�gB���mE
G��ǭ96�t�"�Z��y��J�!��7��%ѷ�m�R?��R��~n�J��"��%o]�W���=����"�"K�"��7Gں���i�;���o��C���!���҄�b��᎔�!�ػ�6��d�E;����8h���^�j��sM+�a����=���9��̓���|��z�����3-���� �XL�Y@Y68�K�/
e[X�\���y��ߜ�6��Y����]�f��[/%��"�LO �+�%U���k]�D��b�#{�|�vL�2��Rރ�.���t��\�
������<��]��,+�����>����j��!خ��)`�b�"��t�� l�Lׯ��G7Hn�0�#r�b�!yE��|��mh�Z�	��b�U�Wu�5�����.Ş�#c����,{��ק׹�e��[^���]y�*��߈������K�&�j��3��Xf���C����s��[E�`Th��mJ�r�y0���� ��A&VŒL�H`���6��<5�]
S��1�j���3t'O[
�#��&:ť�I�����J	Z!�)Ep�y�D���]��Ք4�'�4i�/��;�d�9%����&�a�z8B�E/D/�u�!?Ǻ??�g��?�U����0����c��8�q����� o~;���0�e�<���q�.�s���P=ZB��@�aqͼ�{�����r�����x�ݡ'�w��AU��#��Mw�#��ë�tX��*l7��<��[/5���.4��#����,ЅI�����QQT��	�n'�O�\�	5�@F�_�/&S�)h4�"z��Q�Ex��0�@3���hY����<EzA�C�W��V:�jz��?�
���G�����o��	�wb#�)۪����{l݈U'��1�r$G�'Ж��X>NG$�'b�����Oe�bf���/D�w��	����3�h��A]l�˝��*��Y���`�Zj-��<Ǻ���󙽫�*�2���lƞ�>vd�G[LOPf+
|PB�I G�	8�Uu��a�fM�IXp��u�����Î?��e�m�6�)����"�j�E��8^l��:�@���#vGo����sh�Z����z��Rp�9��m��G�T�ɸ�V�n���i����f�����)��3ă�BL����e9�bx�Ҕk`D?`y�Ӏ������r3i�.0��;ӥA;��vɇc�b�� i����D?b�rQ��J��P�m{��y&�Vu6�N�E2+Ϡת~�bk�2q�os!ͷ��]�/��Zfʲ+�D���wzf�Qe���@�W��~!Lz��"�������e�6��b�`����}�R&D�L���`Ґ��
�0��MrG'�Jt4��o �ώL�Fme$
\���? 3@hD��>�Q3����M dS�@�uܨ�~%��V6i+�h��4�����2l�D3w?E˥:�d�,a��ZDE�Ƕ�@�r�Ă}Ė�.�kD:��'_����N����b�Kg�$6Y��e�D6��Y�
d��ռhr'1W*��kh6	�Y7Mi$�;�{ $+��Bͺ��8���bx�2�ȅT��������	>�Τ�0�{���Ig�?R��_J��ʐ᫑�{J��,��	")H`�9��qV�� 9@9�o �ZQx�YU��F�a><���^��������{�����԰��h�)~�;�Jփ��gA�/L�ljP�M�_s���J��G��1��V*gՍuJ��䅡�����x�A�h�N��y�9{>�6l�@su�)$q�JP��O(�i��K�j��w�W4j:�4QW� �
���"�_��3h*J�7Ij����e!�-�pKo��&/h���Mõ�[c�u	�O�狶"�8O��R�ج��S���qr�C��dZvp#RgCO��X	9�)o2��fC�&���ˑ (���S	�e���q��@`�)5m�
Tė��R�����M(���}x�m.�U~{b�H�/���'��؊��H�4_���N��Fr�����u"S��R�7�M��+�t�R�����@s���FxԳ�U:4��.���N�x�ֵ{pA0NLԅq�6� ��K߾6�|��2�a�n��mA�P�cwF9�!rƠ���о��a���'�n��sQ�( 
8�M�ԣL�17�Cr�;���:�]��N?��gؠ?��z	vd�*>�!,Ƶ��+x�X��qd� r���Y���2�L�� �+�̲��;]۰h�>�B�:k^��2�s�c{�jX%d�IG�ˊJ���s#{��eY��5�����&���*��V��i����n� xE�`�s]�΄��t-ɺ�s�x�UW�<�y4�,	漰>��į�� i�z���#Ѡ�Wv �W�K``���PN�ϽN���ᜑ9�V��Y�U��q�)n���������k�Š�=?~M��Y?}��N�hx��y�!�6!1����U���L|�q���:���Z�qM�/��������P?a�����B-
d!3=_"��`�VKܮ����)Ee���lCס�ľ��%4���=t~�7��4N�շp�����W��a�)��_gэ🝼���O-x�b��;1�d-`[���^�5h�?0��y,�g틑4����;��ן�Ql& �6����B���Ǟ�$eDg�m��ULERC�] �,̓u��I@��6I< #����d�=�prبz_�L $�D�3dR��P�����=4��d����s�/56ꋸ�(��Ѕ��I���}���+��̽q���4�ۓ���5s6(z�^x�%~��ȁ�Ȣ�%�i7��aP�Ҡ4�$1�ۨB�ظ�|��s̗�QC�>ov?��-۝���w*̘��;F9zG^y�2�*�V��z�e�����(b�]����\/�S��a�o�3�Ĥ�]�����Fxf�j�݃�z��W�jj��y8#|j��RX��1�v�Ŏ�l�8�u���:�yya��U�V���ɉ�gP[��îl���H�"�u�C��۴�x
\ԥ��E��gx�%�TG���vG*��հ�N�^ҏČ� C�ï�94����\�St��5����u�x;�R+�]=@J�}���c%�f=�΃!XL�al��M	���*���l4�-��쌳� ��$$n��u����Ǯ���4�����bmpQ�H�"y���KkΚ��J���R�a?�4!��7�俐L�߶o� ��:hC�9��%f{o��[�s��b��މ֌�!�����b�eH�V��������%�KF�'�P���I����|>���&�- )�����M�"�zV4�������ڋ7�d�+�W�0��N������ʺ�]ٴ��G�ƋY�ӱ
�ߧ��Pjͨ�s���k~O{+rEfH�Eח6;3*t� �h��>$^@��S��.�u�֪�ݼ���r�:�G���z�bG���(�i��K�$��
��US�7�!��\��$O[�b���85¬�vlp�*b�[�NW�e#�'D�4�@�_����X�i'���K�>�Mm�p�<�R<G����ڲg���{�/�k�vd>��:lC�V���S?�c��
���kee�{)<$��!��}L;<dO�)����_M,K ����C!(���v'��A)�rB��S'zv-��U��'�LQ���vk�'�β|���d���*�lr��>$�ԝ=����О�<K�-�6s+Y�;Y��k6"ќ^�<��5(w��<���Ԅ���KN�P��*4=3F\��?�)�0f\�M X��W�*�i�轙õ���m6@�8���v���^����=T�oߐm���������o[�9�ģ�]RG>>�v���ɧX��(��ԥ�'Js���SW�SHN��E5���us3Qk�=R����`����*���u �4���=�l�B�4�S�m4O0r�з��_L6X��v��{��=_(�	�2*�
,�l�&�aL��� ��>�s�,=(�{���X:�S��f1]I��6�x�+��h�{eo�N"�8��Dg�7[t�ˢFM�c�/��Ѫ��k+\���y_ߠ�W�\�ZP���w�?�U�& .ov����\�qN?V	B�JpB��զ�;~������&��TgOR�,X����6�t65��AhZF���$��+i؞^l��ǘ+�)��[J�ƪ�i��{=�h�o\:����\��[���
1y��h��л9�8G�m'^?��s{�
�_�	W8�����&�q�Q]@�η����	�Q �I�q�U0�\+ۥ������a�*��'(��+��ȶ�>3��_C���2㔦yi��Ȃb��
�Qv�+�����3/��Ɇ�(�m��ǹ���=��l�@^q���Lx�u� N���a�Y�K������B�0�,i�YӒc�q.��_��'d[�V�C����ڋ��J�=$�1�s?��@��1�?!5�t�ʺ}��������v�c�Jf+d|K,D�r�H���5L4�v��g�_*��O�i�?��,+cA>��fՉP1��P�]ߠ��*����c�!�cZ��������ߥ|����n��?��i�����L"��/�/�4&�R�A2;�*A�� ڶ�a�6��NhKH.��䨴���G�w�)���fMN	���6�f���P�!�ە�D��o�l�'���'á�1r+^D+c���3K.��7�0~X��H_ޏ�*g�o3ɟ,��8}���M����&�إ`���[�g?%��.��n�*�M	��H|"�;���d�3�r:DUj$>�Xi�l�{�2�s��T����2�+6�q��S=�ع�������IY?N?%)��n��b���
�-�6��m�cJ3a~%��F|�����Ŷ;�	\5��,"$����_zX��0�q�v�U�5B;��jM�>�R���;��C�g5�x��|�A���,����C��f$q��!0�IW,�w�s��^�P�����yҙ�ͤ:��FB���)6��i�1v�U��V���2�gk��I�EZ���� �����M��'�������ۂ3؁b�����s�o2�-<�BmG�(��Y���秂N9��z�O�#�c��@]UbP����I�(�������V멕	+�����[�&��=��-2�w�Ua��.z(x���,�&3aX������A;2w}$d������)Y
xB����H�0���x��I�6�M�R��J�R��8���m�:����,�)�<.z�qJ���F]�~i�;�kN>�����l�����a�n��k�|(dqѣ����p�(�*�m2!7D���.7J���քU���gE��
l��NC��/�y�'"xpҌ�	�jW�clkh��MvA�݃�kt��(3�[�;��挋��cIȌ烰�u��@Z��^RT�@���[v/��0D#{�C��1�<��:WVT��KD5��LS�ӳ ���Nj������l��H�����Ab<O���>�p�mz�������>�dф�Y*B3�z�d�5\��)����H�:�����]4]�.��a���:ꢸ��J���EjBh�H�$�FFPX�]F=���k�Azn�==(A��*���(~4�{�8�/�.�G<�~ts�i�fe�6B���#R@��.W�n���S
�c_Z�'(�I輀ET�r�<1�)jn��kb�NY�3�=����^�^��e�hE�&�s+a��,�
�W�pp�/��T��f,>7�
��>�e�Y��"f�
�R�;C��	i�$?��ő����j�n;Z�ڵ���)+�_�������<%��ϲ�\�_�����)��t�/��V���ue��a�
���� s_��c8����كv��
�����w	ʝ�3�H[�n&�4I�rq�P+���qY��%�9,؊Ԧ���������)8%���z`_�k4��k�ϻ�Po���@�q�ՁL+���ܽ��R
�XI��(_�G��XJ:�d�C�̰�	iq�a�nw>Z�p�U�d��bh��W
i稘��{Lxx����w�6���N�4j�W���:96�Rf��D�Wm�Oe�!�(��J &��1���F��od�F��(3��G���F>$=:A�[�@�7/tJ�n.�<E�Fƙ�@a��W��F}�(E��RZ�t����/:E��f�1�}Ӑ�8��%2٩�r����E��'��i$��L3�*骅�	�$g���9u���U�U'��N�x��q�`��U�tz���S?�� �3J��F߂f�O�c:�~ф�>0����gPT�ߦB�C�����d�$��(
݈�J}0x�f�ku�&F� ָ�3~a�^��ɭ����������e r^g�/F�����a�^�b�Z���qK��}F�\	��?��$_G��-W���|O�MR�ΰc�AN�m>���Z����c�tz!!G��EL��x�=�`bǲ�5,������/����1�J�@R�{��V#d��kZ��j��E%� ��� ���~=�*{GMk?�`h0�g�^���A����KU~2��GC轲fî�
?]�C�1�=��d1��G�,�%�{��Զ�);Q�To��y&�}H�¯�|i�O�*�m�ts��:9Ц�6���P.�Ј���=O��XMmlws����C}!�A���WV?�}9��\��_CL��HБ�K�D*��\WH��v��&3�kk�r��σg2���a��ᮾC�-շv�ݖ�p�X�$�����kW4��o|�7Vq�!=�9T`"�X�	���d����l�<�n�����3��mi96=�#e�;s�#�V�|���OפdAT���ۓ�-s4qV��m<��a�V��
�P��# s�;F\-�R���sK��6�A������Y�Kf$SDj���Zl�ԎY�`5x Wo�
��O�]M�G\�������=܉]��w��<b�N+ٕ	�@�e��#=���(.���"z N"�m$y����^oZ����{>td�}�\��7����ʻ�4va��q���t�@h�u��is� �>�h�c|�L�-�d�
�8$O�{ ������^$�:l�T�/_OMr��8�ҜW��A�S��G#����2�����r�q���\�7�*$t���D�]�Wd�r��Y��P� q�F�@�����~r��s��<\=���Z�0��^�����j�F���8��:X�es�*��.J?�aԱe���I�V�-�Da�C>�g�Lw�|̸��a#��*���K���s)w�t�H�/�z܈y��Ҝ�z���&a\���L~r?��dt�cL�3�����DcTx;o�v���F!ʠeRv��Y��i,��9�@�X�2eٹ����4��\C��s7N��g���G�՛1a]��L�Jb'�^������\w3 p��`����4��K���t':`0�#k�m�}�=Xh��CgZ���w��,�q�1�	�8b�X"�TY�~��0�"��2���s�Su�4���6H��5 Þ��D������d��m��e���u�\�����k��	�&N�OZ�)�c��{n�z���ү�G�����_-:`#7G�w
����D�:���Uy��D��)��v�G.B���I,U�-P���Δ�U�ǼN�����L��w���Eww�Ҋ���K_���=��"��o$�7lU�k�)�3ߴ��d����шՔ����@2����@{�Ʈƃq��r���������c��Pº��&ȿ��db�A���،�O�d,kf���P�˲PP�' �_�X�7	�V�v��Xۈ�x�t���#��y�TJ�oD�e�}���-����Q:���ǧZ�A����K����"&	�]�5s��
ͬEmr�T�,���,Q�'��2�;jH���(N�>�?b+�2�m��n>�d3�R��V��s륒W��S�LF�ō�Z ���
�*{��퉻���]� TZ%ݟ�"�dS��݃^�f�>&�x˰���N#U�Kzh_2V��Ãս�64�)�NpS�x���B���p�
>k���;-�0d��B�#<��k��i��]�$\>§�r�q��cZ��6�[����.�{3˞����)\&H�J�
n
����+ŀFY��ڡs/�r?�lTC��g��c8"�3DfjMa��y���٦2����tB�YdE��L����o�ݻ�5.�Y�N}5;dZ�\���JϧE��E+�RZ�������o�P��Q�E@d�nG[uX���-NT�/H�'k�ϭޟ�G��)��n%�� �z��(��B܄e��!�ʙVbLo��6
�:��F�w�x�Ke,�q��֠��C��%i3	�-@l�k���XѢ./�<2}>�V��N���m��?d����mTZ
O���;���i:�1Om;W��WϑaKD�Ǹ*����	m���s��е[���D���3#�?���y��&���3M;m{���q"�}���\LK��#<`ʰN�S������W�KBh�t �U/�x���9�� �z��q�����˱\�]\��9�M,*�����l�M��cx �t�-�M�D�,)�w���|6�<���x��h?CQ��
-��q�،�ʕ��F����_qr4��M��,��'����c�?�34&vL.��ܵD�[9���h�Z��,�+_]��׺�f��2W�[��5������NQ�� �+�S�	j�.�Ɖ�I8ɂK�A!e<#�\�)3�®6���r��&Ӟ�/m�|���To4��wX��d���5���d�J�:�F��J��z9���J�T[�o�vǵ�)�$�<���Vx`0uX�n�2s�i�BT���	�'�0�\c~���bCH��H@A	$gr���$��®��Yġ� �`Ϧ-09=gնt�je�:F�Sܴ�����d�2bŅ��y����[�.�7�YQ��&��D�ަ��l�Z�	{� �NEQO4x��O�F�x)֯�ln��):bD�QJ��{H�I����h���7 �Xz�M�|�o��z��审{�
�#�R�^�BZ�&fU�N�
Y,�2���T���ڢd3=�z��U����iNo��c����������]��a>�����#��1��in�?J� <�&A�K��0Q�k�	4����İ��B�s$Q�܊��5@9�,����].�	c������s�����Qk�='j�3�+����Y��3&���*����o���o���BH<6�`��ے���c�z��Px�0��U�Q�s�M��{����gC�0D��50l����̋��MB�:X�q��� Y�(���<���P?�I�4�tkulӂ^0���$_���l'za����T�\t�o]��\hByI�ʎ�����c^��=�Z�{�D�z<����p�
�+����z��w5,h�uЧ��~�	nqۙ���O������,}kc�6�!���e�H1�}'��<�PX����� �䄄 �����'�?�"[���[�$�HJ�8�Ց�Ruu@޺�<[y
�$_�!�Mg�����[��J>���b�m��`��ox|h��0�_Q�HR:�������hl+��������T�-^�b7�4������n��ՔY��M����}3;�18�at�c�{;F��/-���j���N��ZQ*���I�H�5���'kf��ۮ+yqw��H4]#	^�uy����0S�-k?u��	nL��[\�3��)����������(@<	2C������b�W�8|m�	�3a��>���ڥZ�=X�.~
Ň#2�&;f�Vd�E���Zx"��z��d;�b�y,�R�8bvo��&@6Nls�&Š�T,�n���n2��5(dO
}��IV� 9�g���3��k��Ծ*�M{��߅¥²-��AiN���M�n���M]��|p�ҲE�&pΧ$�AIus���[�G���yGC*+��@VNa�J$z��3�1�5���47��CpM��=�)lW��������mΒ�Q3h�zt\	�7��y�P�73eo	a��"�#�rKv�e���m�������piQ(É�2Ǔ'�h��/K�:��4l���`���|4_�sÖL�?\v�nH�Õ�<?Iv����.�:�^T�j�|�O�4�.F3s��en��D9�ڎYt|��S�B����'���[N�Kװ��=]�G	�Rc��<b\��઻�T|��$���&3���.=�L�@
����!5��c�w��J��m l&��,�
��"��](��|��_Q�v���E���Mj�i��Z�Ɖ�Z%a�vfF��+��'�`�0qn/�~��Q8��K�����N���d��X�n'����}�� ?0e��i+�+��b��Ĭz��:q59/?$,6-Qb�_��n���Y�1��JF=�{�4^i���B���#&��yY)o��G|�/ý��q���7��̅��C��AG*I/�վ��Q2�-��+I�� ���ʌqS�i�ۄ��Y��XN��W�w�o�h�%�kg�VO�ɉ��mW݀�����7#�Hp�Aqf�,��|-�������k�<(��{��$&]�ު}s�c�t=I�EA
�?ϼ'�Ur����ƙP׿~�?|��u|�c��K��|.��y�/�A?���q��3>H��=bW]�g[�����X��ŉ��]�Z��Q3��4��l�2GrH��[{�� �#��,i�/��!���Q���̔� 7LUo_�}�˚�h�`������ؐ�-w���Zh��F��=N��gV#�1,�l�Mh��S�g�J���D	�� ��YRO� QV�Zm��\�8�0����\J����(?�WQ����^6�ZY-���M��6�żQ��~���+��#���#|�����i��j�X��C���R�zd�ƺ��#"�ts8
J�N�8��\�����Mk֒e�JgU7�+�ޜPL{37O��! A�[���8��q�g�#���$n;�)r����G}��M8�j)�m�V��/���~�Yg�c��'�d6{�i�@� ��Ǩ_b9@C�+�$�b �뼚����Pi̈́p~�x|��aGw�)6
�"��;�;&�ÍI�j{ߛz���v%��?TX�.ӅҘ ���U=�%<��=�igD�{��
tH�D�����26���:űc@;��z���J%���|�����|�ұBh�C�
�����Z����@D��8QY	��B�Yԛ��wI���h��3!�k�k��]�3���u�[R	2{���JI鰼�5�؃�����C��Xx�eß�Q�o��nun7��C�%l0��L�	ӎ"@\��Q��
�0a�c�̈́q6;�C1'檙�k2[�o�"�f=�#K��p�L��HWb��٤�-
�C���! 
�c��������y.��e�X�5���S���}����n&�݀���򣗳�x����A��uc�aҺCb]�ɽk��D���^0yKke���ȇ9����
?||���l��D�s��%���r���7��I>A��W��ҿ�E\��~S�AR:�ro��L������߹>�,t4���r���x-���7ձ�ƺ*[C)�ox&�`1������)ۋ��؊e�$�_ۊL��>�"���Ҥ�� �=z;�����+����;�)�0�SϞ��vSL�E�CI�ֽ�b;
H���#\0��_Y&�B���u��� ���wi�o�vc�o��H;&�
:������(t�挗�E6CZ�>b�8J��]=7�����G�8R���}3�r�4��ͪJ��C -I3O�L��/�2��lǝa����,�`"k�Mz�x��$�0���sm&s�9,&뜑�J��f9��䵨"7$"Y�Wt���c"�4Tp�����QW{	�����E!�X_�R�Q�oh��8GI�.u%����|�L��,�F7үWU�.���qRi˩�Kg���VZF|	�}in����t0�+,|���Y� �0'��_I�PV�w�'z���a#Xcٕ��힟�ZP��G����O�-��F�>���\Q/P���-.�&(�`��x�X�F�[�@ˀ����!�h'[П��z0�vc�&���L������0ʞ��ް��E�����ۓ�~�1=�@��T��r�~٘ݯ0;��KIn%W{����N�B�.g����aF�,1+����̅cm�LO7L���'��"��f�!���Sg�p-���!�N���;~GpcbE���	�	����]��ާqE������v�C'+��)i�#u�R�7i�Xr��1����ƞC>���E5�z ��%E�T�l�20�;s��"���)�����7��m�<n���a��}C�A�y��U��^���۫ܥ����)�br�6�@G!�-�n��`�e+�:qDyX�r؛���dvF�I~���ͪ���a���v��с�S��I�
 ̒D5�2`�3}%0���Y+8���jȊ��p�o"Bn���G>�Y4�OW1B ��I`�|=Č�O���P7����G1��L`�}���!��)�W�S]����<�T�^U&9w�������@�*�O�n!
9T�%�b��;�ZJ	�*�h;����!�V�46�p  �gtN��G��Xjw �&@^:��7�:��P��?��o��e�M�|D���ZFd�������1Λ���;��%��]�S]�Z�@�N�\�:d�x��q���3��
�	F�bW�0bb��kaG�4�SՎ��e�Pdˈ�zhq�eK��W-F1p�9 �:�P����Kt��w�q��]���a�)GuL�}2o�.2w;X
�k.v%�:z��ou��tS]�>q#�TI2b�e�o������0�)t���_�GA�Vc;6�:sk�0�[��wϰڛb@��Mn�&f�E���[وcD8��4�(W��ۆ��\�oU���������<w����E��}�u9��Yq��;�[�B7�X����}��~��)u�	��l���w��=���-c)3�"(����_3`��ުy"�V���o�>�R\L�����c�bјi�#,�m*�/ƺ��cːȰk�r��پƧlbM���f��㌴0@	�cn�xQ���ĸ��00�KV�- rA�l�%v_�M6c#G�&6޴�Oe�_lJ_?�G�V_���ձ�����*�����Q�O�}�虲0	�2�dA@B�U���^*��eՁƧ�t��,��G�b
�%�F1ԑ�l��57�Z��V�ʁ��vV6�u1�����@?��c{L�j��JKp�<]
)��e
�\#�c�;?����/]�S:�ì�O��r��ٝ���ʴ��ً�D�a�v�L08�X�M]5����$;��$�@^�io���*O�E�,�S��h�<���|�KMO;�)����"9Wշ��\�e���T����<���8D�K��ևܫ����(j]���3u�}/�$�]���b�q��[s�|�B������Ž8g����z�>7� z��XV�hܫ��MLΡ`�"e00��n^�Z"�e=�^�;sA��Wl_o��1u,5ٵ�B$�X'�XS�>ےw	ٝ������;2�u��"����c�6�n�W��Y�s$©y$	ΫT�'�[YAh�R�n䀑�M����ҁà�x�"�Ζ����kz�����c�&c�йF�I�$2���A�w~?8wa$#���B
\�tLaZ�ILOH���Y�|^�R�a��S0�h�w/U�Y��_�@��݃���Fc���4H 2䣄��w��?����{Hʴ��H$~܊���t����Y�ۭ�9˙��s^�s���@�ϹF!�J�d�w���8����f_����u������tto|BE�A:�rz.�G䮏���>�(���.Fa�	�M��?�����!xDo�x�j�8����F��tI1��-�>�o�j�S�A.�Sχ���]}p@O��%OzECcEP����m�vU���D]��8}�cY�Uv`g��4���X���k�hT���-��Q�#�{I&���w��`f��D�Q,�b�i��i���i�|���陈���d͇Dn�y��Q�d��,�vlr>GK�s\��3�r$��%z
`mUٴ��Lթ�(15��S�[ޭ�Q�`�\H^��� ]��wE���(�lr�0�5F�Y��*v�]��L�4�[�x�y��ϻ��=�\5r%F���&��疁��+�uM�DK��ƝUg%#C/������|�e�բy��ކ�b���45D�|�:��}�bP�W�|�y��&��9̙
��^�9/p��Y�V:��g%-���R)w*� �A�I�PEeZ�bڷؕ
AN��g_7,[D��q��G}��J�����m'5��rt�1�ŅM o*��P�uFU�f�2�tm�����*!�I�
�&���S]�����5-��}�������/�§c�~�C����,�z�P�^����џh�~p�Tw��P�	&��΃�0\-�B;�Rr��s���Rvl���J�^N�V��Rf��)%��~�S@�B�.�#���PG�6:7���|�L�G��G���UL����i� ��;I��0��(����R���B�Q�sF�=�΀@���X���̬ �]�⻶���J�v73M��]���_�ipe��.>gbӑ��8�e�4ݤ9Ui{bU��"{��XY'�փJ��ÃlC%���.�����/��W�.�e��JVA�XΙ�:nĠ����A�3l���WO����#.Ɇl�!�Ǖ���L;x�
��Tq�Gn�]R�1��	�ʫ�|�J<��7^!�G7����T��JU�OvV-!>r�Ór��E�Ψ�K:�ى��+�g/�yDn�K�S�P��$�j�&֞�t^S����yev|@��-�aP�`5ε�s�_�c�l���t�(�h@V�t�Ѝ�fXz���K�g�Uwr�DY�I���?��H6�m�MS�Vߜs?��C�X���kbt��1������g7*�G,�/wGh�;�[Y�������b�<�*4|�\]lM\)��� �b��j.��W���k-���9���E�P���YJ<�!g<c�Dx!h��7�r^X;e'�!�,���E�3#	�3��Q��u���a��J����Wx�[��Gq4�^"���j5Xw~|��l��$�c|[���ؿ�<��A̐aV_q$���oƨ ��+��`d��bP�F�8��O�&d����;���oSd�?�.�V�2�6�r	�t���g��_���RWb���AǙ�$���z����]�m�g':�w�;#Xio�)Q��'S��B>�f��{Pn�ܜ�2�g�ȿa�r�8���_�JS�4j��M̬�l%��q���x��7El	h�GO�o���	�X��Ӵp���)Opæb;��W�33*+O�v�~h��aS!�8��>[�[%���CP���(%\}�,�^)NyX\F�r*�� A�e�� ���bZ`*�/�v�8���������0�G:��._�L?=U $�E�K{ j�;����;4�C�'<88����V��~�?�E���Ӕ�5���Y�)�1/��f�o����I��Vn�<�lv�z�H��vf�]���[:IZщGb��YR)'-6v]�8'$�	���e9?�-�(i;#?��r
�Ż�v������.^�,r"<w�L&CuN�j������.��k��l�t۱d`rA�k���+c�1^���z���'x��0�ǜ\8l���&H�=����嵉1;��la��F�Xeoq�G6Y�3�GL	r02�ؑȂj�uB5�W���`��l^[�r?z��@�㦴t�L���E�M��9E6&�l��lnO�0���2���N�PtXc^e��䁘K�G�d�����W .��m�0׋�*U��	2[��1n����W��d�"� d�ԟ�N�|^��2̢3�GaI>��[��t��^[o���Rb�Ѕ �A��n��|$�aP��Q'|߉�����(��%���E
�d���5��R�pG�p=��i�2��4^R�����HܦT?�C�qg�������g�o����w[&J�z��� ����s�~�u҆57]�
Az�;n�◷�%�!Mս�~�U(� �����٣7Y�N���S��꧌O��s�kV�.��I�縱og�D��l�i��/r����2%	��Mn��E��f�����7{;���
�4��hJ�ş&����gx���^ZnR� =��Y�ށ���#v����o��6H~c��Nn"b�a~��Ai530t��(���t"Pga(2<�j�������������?�̾��ƭ��@,||E�elo���pg6�7vԵ����S3���ɫ@�D$��{<����7��  �@�s@F�S��HT�S��0T?z��)yc
~�|���������OW%2m/uiK�D:z�� {ϒ��e�v�y
�N���^�f�`��    !��&,��P ����Q�/��g�    YZ