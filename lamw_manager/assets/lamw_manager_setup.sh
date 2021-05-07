#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="424519731"
MD5="8668e8933f78f07909bc55e5efc12f9b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21200"
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
	echo Date of packaging: Thu May  6 22:15:55 -03 2021
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
�7zXZ  �ִF !   �X���R�] �}��1Dd]����P�t�D�l;���i7H�$w@l�)�1�H��B��<:�?�ֆC��`�LW�,ݕ��.��tM��M���۵����?��3������HjZA�C/J1e&`�OC��#,u�e;Z��%��$ݿ���9�8w`��� �,��أ��b{�X�n5=ݹX�=�@-*_����'�he�n�DmEJ���Ĝʐ
'��o������u�r��0W>���!��&�A�1��d�sx-�Yk1�N�����Y B޴���0ZY���A��0Ѩ$Ћ�;�jdQ
����Vc��n����
����4\��<�8�8�
�Ǌga0���h�?V�2�v�1 ��ݿ���#"jԾ��A�
 �p _� Ohb��RuU@��+�F��V�~O��b�vV�=튥����|�À�34LA	KG+�B]��d��w�≮w>boЗ����BKI���ZO���r��RyA�Aa:xU�f���h�\]��Ǡ{-�,e�]�@�i��;���7��5�?��d�,U�
Tz�2���b��U��R!���"6`�/����B�/ԙ"�¤�Wx]�� b�X)6EE/��k'Z-��J`�FY����\��~�N{.O�)��>�Q/�b!tQ�}���KP ��'�C�͊P;�����c=.��g������8"�����d��iiP��X�Z�i�d�@�{�q�W��F�J����� Ds��8�KG�Hm2qxq�q�"m�$���kv��e�p5QƸ�i"ſ8�z��K���!�rJzP+塚`� �%׳~6�p5�4�%Z�Fr�� �l�������NN�@-���4�贈�� ��۹^Q���:�2<D=��;�z�_m~�E�j��G%�o�:�Lһ��o��ܳʂ�X����9�,n����p{�p%���#��!`��m/;�����-�'��A�,��1��j0�+a�����G��@.􂣗N���o!�p����d�`y���R�r����-�@�����;4����*���`���Z�����w�zԫ�\ц�%����G;0p�彍Ǒ�6��ֳ�h*߃�u����c�B�j�b|��[���:�&��oNCe�ކ����]I�]2y;#ۺ���aױ�_$���'����[�()�_��M�Qz��x:Q�'Y����2�t�S�A��� w��HE_+��{Sr9�SpcYk��1g@�xV�n��@R���o����C�ׁM�(�X4��;���������|�>o��]Wy����q�2���LN�v/0F>���U��]��wd-�z�|�7t���pɣ��r2���[=�a��bd䉺��6�|{~#|D�E�bk�h�s��q�;����/�X�^�9̓4�$8���W�����nc�� t��l1�� �r���������w3�k��s�LdZ�;�i�k�Z�H��ҫ��Q��U)��x� ����bD���6��G1�ۤ��glR��D��?4�#�����r��|��:)��V����cc!�W���]*"k��vg+�����i�_����S���3�a}'Sֺ�&VH��7��Ə�z=*���[i��������`5�?�����ʈPS�>� ��k�^}��fZfpl$I�
�E����Q����­ȟ���kO U�����fW �R��hPb�D��^4�]XgJETΏ!I��M��Ax�z��ё�������Yi��{���#0��h����|u��D"�n9_�%S9B!��F'�h)b¶���۸����]��]B��&��&�X��R�p W2dnյ���,f��A�˗q��
e�jCA7����<A����e��d�������J*eȇ�e:�.6��a���F�jv�o�8�k.������� д��R�*C����6���{$��φ�dY���8v,s+W�S���w���~��j�P��a�	zs���--ec�����Yo�&'@��G��W��`�A����b�_��/E�ig�'�������%��i��/�9)���}�oe9�h���7X�|���f�:�t8��_��ǒ��YC�+~�[TZ�5,��(
�rc)�P�nӿ��Ϳ���`1+�[�D�y���Ec���9.-�=����)���@$VW}��L�d������Q|��`�LGҕ� �[NZ�G� �?i8�W��JA��%����$�t�b_���^��l\���_n��''�qI/&6���c�X��@)Fy�c^��g�L�;��y�����t	�Ăkĺ)j��7#�MUk��sIb��e�����C�h9x�"f)�Xׄ{<�1�6(|�*�$�į��Ϝy"�*>��m�? n;��K�m��B�B�?�CJOA�c��}z���Wz��
oÑ ��]~8L�@#�� -�CxZ${\@��_qL� �8�"Gqa���%N�j˰��lsr�T�8�u��"�M��1�Du4O9Q���hpO�=>�O��r��L.l�ct�jË�
BuA<��V?�s��C7�+
�e#�{��g��l唳�.�z���<��I�z���Ƙ*?���Ŕ��=N�>=�!����~^��$zE���]Ǵ�H��**F�o��y{�
�s� �l��\O�}���eD~+7��E�<�!�D���x�J�G�X�\�V8����Y<���w_#S�;�؀��#��rb�1�=e�+��hIz�r�����Uk�3�ФF��"&?�á��: �R��`�)R�n�bX�w��41*�w U�;!��f�]=�����6��� ��%�*����^�9��myߜ/�Щ;Ft���	�Z
c��C �c7��g�E�E�p�P _�ۈ���u'��s=�з������*����5��F^���-GN�G�b�$��׌�u()�|^
ȷ0(T���^H?[:!��4SN����z�e�|��#:��e<1��U�'~C@,�H2-��!v�s VG����|{^x�ւ��É�;��GbӘ娨��U	o5O�T���d�\�)K�����K��N5�?>��f��5��ޗ/kqM�����M \g��ԫ�2��Giy4l�%�Wۚ�z�w��Z>P�d�?g��F�$�Q/�j
k��fYg3��S��I��LRgx7�z#�49 �ґ+����2Y454�����O��|���k�4�lư��и���b$����j�CS@�`,5�in����VJ8����q:��r1�2P���w�_�5$ڿĎJDkL4�8PF���x������˚}�?���9$G�t�0(��z�kB(���9
�@����?��6�52㗛(уo1���͜C(�]<L��IN���}J�?/ĝ�Ľ�^�&��18EX&�W�f	�P��>��t,Vv<"��q����}V��u�*~@�dS�d$��������ʍ�N�I�vٿ�E�4b0�҆��o��xS0=����ΥF�)��B� s3��$J�7��~<Ӧ?u"�����u���6�����o<+j'mӞX_��=�ڗ�u����`���į�3����&��mf��|���������u�2�Ħd��h(a}�(��6�1n�i�Q��m�UfX�4)�#ܕ��}�X�*&r��6ٹ%����W���H�wT�(%f"G�v�|^q��FK��9c>�W�D�|�0���" ��Ԕ٦ZA�y	ղ���
�y�z�[jT�_���O﷝S�[=tܾ���t�B��l����N�!�gO��J䮋��0)齷zx���{@q�*�:_^�}z-��̅7:�d�&��3PfD52#	���
h.Mm�ŷlb�1d�����4�s#��暢 J��X7cT�K�	Z.�� �ύ_�Y	v�)�:4'r��H����&)�P�s�LZU^v��1Z+�>S���IP느��[I���s?-�].�\��omvҀ�N�e5�����z�Y=���.�yD�s�o\�:��UWmPK��/ĝ�Qhx��	�,�~�S/`�;��ҬMQ�r5��s�����e�x0�;P�L�]�[�]���;u�6v] �W�J�sn~�%P�%>�	���|Ǎb��$/hVX�����j����21��1旕���2�u���9V,�y�U�?��.�'��Ј�9j�B���.F,�`�Q�@�mx6�	�+�f��WoQ�ѐM�eE����\Wi�6zĠI�2��Tb�A�{.2:��Ѣ��m]Sg;3�1qsm�9k��cȂ.�*�.���p�UX�*�3X� a��]�P��oQ�����1f@�}�k�6G(k�����$���"\��D�$��Ϝ�q+` )�I"�toC?)fe]�*��,q��� G�fw��*s���qW�]ᝤ���6 G�����KSƿ�h@&2<�^ϵ����Kq�=D�!���H��H#���3�jqkC��p���ّ�h�Y:��<���֣ZP�|,�5���,�/m�,q�N�h��'�$ElX�#��L8]���+�\*`!J"�M/�׏������Zfo*��ݎ��}}V���l�?!@4#6W��2�t���G��F��w�E���G���.{`zÙ*(��	�V4�/���}
��떣�|͈4Y�I�)Ѥ ��K��a��+�9��� ���0R�(��������.�1��J�R�vר���ٜ}��ò�l�t3�2/Y��u�v�[�$��@oX���/m���ʣ�}#�q�o+�0��� Ǘ�U#G�g'��
�|��ԗ^2���I�$ ـ��E�7�3�ũ���D���e�Э$��'�K��[
i��M'Iy����z�nDTed�/�O�-�t��[�4m��8���L(k��ƙx�o��JKW�ㇻ����
_���Y)cNB�"�u�K:�a!������#�aQ����{����$�۰S�
+]t�yO�}�H��@�$�5VH>V���5. ����#K_<��Hw/?�jI���1}��.��<�a$��O���g�({���Ê�y��R(�PX�uʫ3eUό�U;����
l:z�̓-=����0���ey�-z�I�����=�X*>��tpv0�ZhY�@G�gO��̞�HJQ��w(W�}O�s�e�e��i��Rp���͞7��k����p��g7�"_�-��������Z^���c|��nJ�����\��.bEt+FD�(���=8�q钱�V�F5Z]ޞx~���xjR�u���R�]`_�!J�EBǡ��a����`2�M	 �\�[g.�<�i����s	��'u���Cn7Z���:0��.K%�m���:^��(#@����t�\݃��m.m��!�	���������D�ԐeZ��m�P�����Kq)= ��IF֞���8�~'u��m������n�06������!_�M;�4�z�	�#5O&R	i?��LI5�0N��/+���� �`F'�j/�o����).������p����)�RnLv=yA?���z���BB�(�@������n����(a���#ֲwuիy�Y�B޻�ޭ�wc?= ��ǗX�e�v������}w�\?�^����ƦƬ�^s�q�2^˓���7>�:�w�"a�i��>�̉X�r�Mdl�L��n�ג����XPO%���qZMEu�����=�?�J,4�#�x�b��w��i@��q�m��Y�VY�m�i�K��&~�Tdt��M�����щs`��Ŗ
Z�;�~Է<e��.l������Q%{�����SG�k;�E�O	OH�(F�C�$�f���G�務�OA�ΚЈS���G�e0�[v-� )X�w��a�.+��]�%����f�y�Ԋ)����3���)�|�Rg�=� T˟��$,��p�v��g��L��Y�ns�AU�fg�F�z���V�&��b%:��u`<���	�1*�k�O^Ã��#TTc�ƳV�O	�Z��Wa":�=���U.�KH
n�@K���/17�_��ň������4�&����"};'��[)�h$����Wi'�=��]8:�	%��)��"�
�j��y�0�rH=����
���^�],�j� pG�U���&}��ɷк��l6���3P��>m1>���Kj^��J{Z���
T@\�x�^!�[m�\���l�5n�v�G�<�XU�7�0��~�#c�6�����%tH��Y4^:H�tH�%�s����lĻ�����#.�5��3W_S�=�A˓ �~�\|3����_ְP\���52��J鵪�9�&��)Q�-6۞�A�Qќ��fI���M\�˩���p%p��N�Mt�`y�Ι�J8^ut���ZId����>�vÍ�#��>����!f�p�Q�]�'*yx�Ƚ�y�%�fq�X�����}gF��?���� W5��}�=��r���r�(�۰�r���S�tA ڌL,m����1�!�b�9]h��`wlI�`<g���V ��(m�AT)��m�맸��U,����B�c���
B��R+�z�i�!���q;S2j,��	�����0���!��麽xc��G�X��?��S�|{�����%C�M]����*R�X�w��|���r�EWZ{��u�p7�2V&	ͅ�Z(U����aB� �'L�:O��d��ؚEV���%��c�#=r�o�[�+#,�8��d
sӐ��ɝY�$�������H���p(#p�T,�O��R��+��7�"ٵ��OJ��ڞ�$H��iRL�o� ����l5Q/ymg���P>R���q~�[]�0F��qN�l��*��=������{��R���B���;*�F�y��}}��9=uy�Dd|)L�Ѓ��!�*|۪�E��K�_��9&��fED��z8)�F�9�L���Djt�Ϟ���N�a��sގ��&��a�f�U�ܴ��@CYL/��R���P��<�/e�7J�f�k����(
�_"��u�*���=�(��j�~�t6_N����$�؟�^�j���+�ͱbyX0F�H��Q'u�\A.~NXs]l��U�&]k�ۖ�_Cf�WR8��.�<��D�����`D��*�mG�p�^�[��
�_j�\{�}8��fT��f����Hv�H�K�oU�F>l�W�kK���N��z���r@������4�����rր+�H��sS�1���k׷�l���`����WY�ŐX2i�5Zy�N��lŷQ��� �.b0| g1�������&���T�c%;�Uǩv��>f��U�7�}�ͬ;��L_+�^l�E�^d�vnc��B��C�*j��$�+�ᢢf T�l���ԙ:�����2A=�1��ȅ�[�q�Ÿo/��<�1t]���1�~2�V���c��bp�,��0��#��Q`�����j�jJ,�Vs�AL^]�����)����Kl��#��ȠRLU��ǒ%�~��04���a�v������\����	N7��EZFO:<i�7�r����Evh��"b\b봛��e���������y����"��|���na�/0���A{�*�e��f�����:q����g��e�Z�F�or���.�_.��o͡�d�R�a�,�� ��5X�$E���ME�p�0�!���)����A�X�����z��n3X���C�gZ%1MqsT��ƙ}1��Cg�6�5�J�b�o�ϖ�U�X�P��
o
��_ٲ�w"lϬ�\b�|�lUͼ/+q��i_����p����;����tŒ�l&X�����|��l13]�|J78�	q��|��&�Ր��<ȧOG��%3Vz��N����$M;�$ǔ�v�r=H��Ƅx$g�-1�*g>�͆Y�cAs���b͇�"��@A�5�1����Ŧ��&q�������O�+�.<d����II�\AG�p�gZ~����Y��1��>�y��zCX��ž����2[���9:&������0�b����9u�E�$TJH�FJ�6��#��lmVΦ]�2�W@DlwfR��f߫75�޵�P��[ƀҔH�����#P��!��H�J����,(s�i����Yw/�{���z��y�)�VB"�t�5	�L��"�E�۱�����Y�'~=`ϒ�3���Q܈0@>��}m;G��f8z`z숙�Mr��\�\�U0޷�\�t�f�@�����i����P�wW�<CJpv6��O�Vi&�4���UT"��7��~����ji���0�J�k���AG'(.�$�x�9�
u�ʇ�c9 �1�'=*)�,�@&>Or@�>?���`w�������k�b�P{���56�gO>pw%��` J4��G�8��I��^wJ��|j��8�g��W�p��l�j�:"��*�hl��]=�jlTF �%��p[�Kx-}Mbq2rөR�6P\9�#�OЃ==A[���y�����v�:(��d&�X�(�`�c|�	�_��K�~�p��8�sN�~�m�����O��;�yFq�8���m]V�-E&�y�#���!�w�9���NĀZ@�i�[AvM���"Z[U�8��:m)�o
ĕ=T서����y����ݛ����`p�Fp�&ϐ�Z
�Aƌ
��##}�v�Ds�U%uNd9����e��qV���uJ�A���R�MR�Q8�2�8," ��Ec����ov��0�cf��A�zR�m��g� �4'�=�B�<ow��][N*�_��24��ZK^�]�sC)\�!2��.(�	kްdf�"����L��I¶Y��j�w:]��<Ö��7;���/��T���?PB�+�E���LӶ�P��)IV������w%��<n�}i^����6*�.��-�/���:�J��6�7�69��
7? ��}�����ID�Okcj鐲���F�����O�p�;�!�~Ů�����U��#��?4y��dP��&r\�GNʹ3)0��z1�����!���!&q�����N���w�SqrgZ/��������骻J���g=�Gt/iձ(�rN�vl/MIId����z��lx�B�S�A/?��r��C$��S��&#����zfo�n?��G�<�0��	�2:V����o�o����T|w\�y@�j�;�������t��%ݠ�\T�F�"�D�LS[T/���؃�D��̀����M�t�YTH�3�z3G����+��������v��y� �������GĒ�E:��s�&f�S��o��
��B���Y�!����^P�4��b�O�T����&���d��R���nߺ��� ���Yl���m�aِ��d~�G7A�H���w��e-��У�,g�q'���?���6���e�NM�D�G+LzW�84�Q��D��ZQ�\V��#["Pv��B���/4�bJ�f� 4����B�wQ��~92F��-c�w��+&��#��!e�fٯ�b��e��%��0�#6B2�*Y��jE2כ����W��+t���c�L�dE�� ��Ƥ�@2�J�[+��o�.#�2�s;��Ԧ!7��&FAP�p_zj�6�,l�w��@�� p��>W���=9�zY�@����/��?���`�W^��u�x������F#��%�3.�H7H�����	`c�AMg�������B�g�C]�XZ-�'��h�[�}���V\��~�N�!P`��4&����P7�bF�xW
�@���B�"Շ�.���m��4�P,Y�@�����J�ʅR�{K�)�F35�2	@�)�X[����@�$�)�l�M�2�1�vf�6���¸�d�7�aܬꇶ%M������ݣ��U��Y�E�FF�:�<
e�l�����S�RĳG���~>����x!ף%��;���)uǶd[�#e��[(�6��$ܻ�K����f����@�?2��w�C�U����n����ڲ�5��ه	�X�d"B�_�? �:4��9��e}�_�n��Y�$94X���'(�]n��@������(���7�;�`�Ê�\)ؐ �cu��Q�ӎ����M���sm�ۮ���94>�Ø������d����El_R����<]2:eM*���nMw���{T	�ѯZ�S\���TnN���E��E�*�|Ft���F@��r5�@�XQ![���v�L��`"��� ]����žd�6�|O�g�3�K�;���f��s�(U�&i,}أ	R���>���(���\�5�<��6���݌~/�����=�(���J6���!���t�7�o �}��$x$�EBȎUS,���9��p���ϕ���M3��S^ѰG$\@�&�5Z6u�ϖ��k�%I`����P�-'��K� :�����W�1�n��;�\c�Ưs5�>�y�֯~j,�z��C���TPs?����A�1"�V�(��w�c�V�Y���A�nv��^zЎ�*��t6-` �hoc
F�e	vK��P�"�[�dU=ʜ�]a��<;|/�إ��48��x�4$gD6OV���iE;y��'�Uy^�D������U�����]����6��_����>a1 �)��i��~AG�c`��W(� ����P�jU�J���A�V1k*��l u�̡�㗑υ�陂�4~�����9B�̟i�й��F�s���dc�F�1�bO"=��BY���_3�$`��rd϶���Ș��35�m �8A��x�3?�V�ޏJ�����2��&~��R�`��4�~I�*�W8PD�����Ix���E �sd�ᆧ.1�Q��`���/Qo��b��zq���� �D���ƌ}O��]�}�����8�#3�k�v�*�Zk>x����~L\FA���Y�������=���Z�c�l���Ê����$��[-U7f�Xx �P��W�����,��:�ql��;����R�������0���U�V���dZ��ȯ�>���v��@a8���,p.�m�l )���"=�ߤ�����ʖ�\,`���d�B�3�
齘��!{Em�O�ᐵ����@>Sk���n��O}���I���W"��#\��4L�J�~�k��^�U���;�e�q�k����}� ���@z �ӻ��pz}&�0~�<91z[�Xa��$�P&�r��fs$X�Y��'��N�t;~_�s^��-�bl��SU�����N�j��&�$o��t&͓�[Wo��]���(�y�gbء0����֙��"I2s��x��i��yx������Yv	�,O*+�����9K�g�c�@A\�Z�y��8<��:�]�G��YWt�#n)����Z����uD���F�q_1U�Af֮��lމT��i��g�+�D��Ls	����k�Nյ��[}ҭo��*��L���*eB0�h�>�ܶ�Gs����R�;L:y��-�~[���z7f��.��a'��/}��!�j"�^,:����FJ��H���x�f�?	(��,��w��Fy �]���nB�"�.���0��_��zN��ZF?��G���guά�L�r�S�
L�jƠ/\�[�մ�w��fN��#g���e�k�����t�!L�+�P�0��-���	({1�E?B���vU��L����l�5�=<|�_��=� U�f�Es!����ۨWRo���H|�	�>a\�D�@��0�A��,�56�Y��QL|k��^ȼs�Y*~)Q7��p�(|���Y��PE4���λ푹��o��2he�sp�%D�Z*e��O3Ȕ0N�V�	����ǧ�1�).������w_?g�3�Cv"l"��j*�eW�D�^��+[7��K��.�!~���h���C�"����r��Q>eT�5�Iu�־����_Ň��o��P��$� �ф��WQ�eL� �4+?���$u�e9н?+��W�� 8/�O��<[�I~��'n+�~����(�;�h�rJ�L�^<�p�`��G����ۨ�э|�Ε�k�'�]��_5ca�2�]������O\R�cqH� �`����7��Ö�TV� 4ZÊ(����a�7\� 4ĸwi���A�BT� v����B��ʀ�iM��I.��8�t���:V�w;��Ry��\-F)/�H�vh���0�E>)�Z����t�'7���2~���_vj�%2���&��d�2	���2�2j	����5����o�]��8�FfU�6�a �a{�gPj���Ҍ*bމ���(�m"�6~� �q�F��Ӳӏ���!�E+p>Gƾ��q�v��<��8uZ�x��>:����j�^�3�+,�m�=͏�6�4S�{a���¯ɻFM�~��ꮗf,T��^B�ݮ�o���L�ĵȾ�9i���đ��GCi��8�<�7
�XiAed��/F�=XgEG�y���##W���À���p2y0�3��5�+��z���W�k�6;5�a�{��yM8�Ѡ�'�맡t��bb���Iǘx��r}�Xt�N,��`�:��Ǘ43��u��,ɂ3M
a9퀑#+�b�l0S��ć���r'�ag	"�q!C]�9�E����xVzRx�%ʃ7S3��V�u`�<���]x�� ��??@�E�/R"�+o�p�r���NDf��P�#Z�>���r�@� �ra��r���~��SO,'a҅:�CJ�h�&F���j��u���"t$*+MyB7r�F�J�����a�Is��{~���S�eL�xv��0�LY��	`QO~�r���y�N1'��æm�!�E�.1��B�UM���}�@�||!�tbc+�6�;��ȨѼc�����y��tD�?�&�͂�'����Sc�h�Л�tT��Af�c�0�s�k�p��Qc��K��k*�� ~��v͊�)(]�@@�S#;e����~�	S��(y\���x<j�ߌ��i�b��8:c�B��%�6������%Q4�R�*�,�M�T��{�Q��R��Yk������'�UO��s��E)��r���A�L��e�H^oN�`���:�L�L�3�BL�SyG>QH�F�3�_�1OG�L=��D�$��.��s�z���"<���f��ݮ�V+@����u�+Ev���٫�N&�,˲�XL��bl-n9:P�E�:�9���9�������P��t
�X�PO�s{�OT�4���	�w��(�y���Kfۢ����,2���y�}:����AW�P��[��S=ָi�0;���l.�~���K�����U≌H<��ki�8��y �]Fa�_y*�&�Ɨ:�;Kn֡�0�lk���n��b^�z�Z����3�	WN��0�`�M#97X�VJƖ��1A��oN�,���տFZ沚`������M���%S���r{�H�Rz��1��Tmc�a�[\#]Nʃ�r�ѪC(��������E�N)����5��ş�GI���*�D@�9@�G�􆁘&+���rZ6]�36f��؀��E�'���8�>ᅪ�Fv"#n H�m�zXZ���p�!5I(%�e�\���ώrsl�)l�=��;w�ұ5 �4ٶ��lԊd+&����J�{��1�t�`�Tip0I��\ֿ0��N8G3=�
"x��k@�$�C���/9��^���z0:�?��?ב`W�t~�Ҹ'�q�~*r����j�Zk�{�rn�2��ER�,)ܰ��ȼM~�� "�[XE�/.�M�>�<<�E�e^��B�=E�|�����u�s���#Kt���։�y[ja=�����08�W���f��,���?�׏�Un M�m�7@��})��ې\��(x����<r�W��3S�L����I�|��-\���f��x"v|݇�e�:�d���s�$�w��=I�\�B4�;%��Tf�p)L%�{��-C�%&�Y��V���|Q~���R�n�1sL�L�3J��<g�wI�F�?��@���E�0G��	�T�N@pU�P#ן��rV�80?�6�<�7F*�Vn�j��Z��X�	���*eOG�<����rRB���2`�0G���s��vz��d�_�T���u�I9�'x��� z��T��������fA"�a�������[}'�0]�1�8��ȭ�-=6$�v������鎏R��/5?�,1�?y^KE�BN�^�s��a�QJ���F1r$L���M�U����_vX��t"�	U֘^��yJ�w��f�o��w��U��;T�W �I���f��{?�=fB�$�q�ix��ÙQ&�D�u��`���� �Z���t��[��S岤XIW�&FD���N��UUf�?�ǆ[�pq1G+��%dRc���^FQ歧L����xy��eS �Ʊo��+o��������v��"k�w��XF0�5�U���B'q�d��=.M-UG�3�w
��(}�]�ρ��r�+��|��������ZAb+�E_���6N��X��uI�[^���0�a�K�*p]b���0���JPNz]�n�����))�6ȕٿ;e��~P�Y�	u�L� ����p��%ϓXQ��Í�/�%_	y�V��Eh��]�) �+�_\��zDz�n�շMy���G�.V�L|�tp��Z�:�!xan (Q<q�͢4����k�a������*����+.����4-� +��}ע��$~� Yc�7 �'��}���:A& i�� |��X(�&�^�0�o�n���>uZO(MWJ��+�|�*����r�F"i����3]��Ҽ5�߲"\uv�d��Rz�l�k4أ)hҨ/�L�Mi��/�H��&A���Brtðp�hM9����Y���\2������RP�f��%}}izE?�jG��������֡1Z�؆�>��s'����,��7�A���oŮ6�μ�Y;��:*8 ���pw��x-g�D�)�@���<�_�d[�I�	2����[�N��.��$�?k6,t��<&��D�r��yW�|%%��@�k���n��_�h,�؇G�q��)��ql z!�b:Tp����J�r�dІ��<�~�8i���.�Y�K�]i���$���g^�	���y���$�������Iꋉ�l�O+��cd�eR� ��f�ʲ�^6�:'�ɽ��ISq�*9rrl&�B����B�}"����1��єT�l�9��
8���~�e���nGb>�.p�=e��3��â�B�Ӭ�?��C]䐣gy�cmWi)��ҮV����Qi��kw�������}"n�pn�Mh�M[��Q'%����3J6����x�v�q���6�n�v
�$�vV+���{�,��5��B7qU^�:3�j��m�n+�-J�/BU�	H<�� ^^����R/z�b}�R���8M���#��^@/C�Z�)P�*��-,�����ԣ�����j��PX�� �ba��ZC��u)H���կGW|i�/P��컉O�qp�`�D�6�1�������F��R�u
~I��������9l���������������?����Cn�޽F'^��P,d��w��c�+$�h(�~,Rb�H����=9�s���h����%O><�+hS`(�h����>k�<���%�0��eJ!,���ĵ�s�Kx
q{)�4dh!�%����(4��0s��o��;,O# E	��R�D7@��@�\[w�H��<�H)����A�r�<"&ܫJnuڤ�|�h���U�U�8P�|4.9D�����b�� ħ�o�R�����F)l[���=x��z9UϠ &��%�FO��?-�%�3׭�� ����FP!�>l�c��*e�-C~��K����E_G���П���]�ol=��,��q�$���N��%qd�S�K]N�UDڵ���^�E7������b�V�Կ�*ܚ,���9nu0x�C�W��A>q	~	2-n!�t�a���Jn��6�Z��n.�m�kO���e8�wf��9�����}�},w��92�X���]AR��O rFt��q��xj��mѽ��xG�s�B�rO|�H!Ђ%K�^���k��(�|\b6�H�s}�.�})�d1J�������$(ʛ�� ����O�jl෌�5LĢ^WYy�2�#��}3�K���:n���v���>ճ�a�E��/B-����l��y�C$1�gD
B$�I�[�)T�Bv!7�lO?L�$�v5����ݯk����횕~��{�����A����������ؚ��/�!�w]�t���!�Z�MǏ��Dw�����tښ�G@�R��ʏb�o��P����-����*�/��FS?�P�3�]M��G�1���Bs_��v��b����e�����i�Gސ�x�6�k4{;>c�؈����#2�������,q:A,�c��0N���3���8��$2�?:5�=y�����~�}��v�&j=fR�M!-j�Ct5JS�vړ�*z�q��QU	������O!Y�*��N��h�Ő�$2#�P�+�MQW�(V�E,��|I *�����EB�O���F���;��ujK�cN�*��x^���=G�.�I��Ŋ9�&���������ƒ��e���p��?RF�V���"v�:z��~q����X���0E�8��Z
Պ"kV,3Ѹ�M��sl*���X�a8v�������NK�d��FR��<�vA����$؏���ڐلV��dI��%Rn���_�Ƌ���.$�S#�Z��u�s�w����y��-������Ӣ��g*=�V��,�$Eu{9�$#,����W߾�:�?-�G3,=�C�~JC' �-�)���}GR�|� c�f8K�P�9@�a�1�'���w��1���k���JK0�A�T�T,����V�e�t�U�l��(�V�����vVG�o���c�rw,��o���ǋ�P~K�rL�hQ�X��&�:yJ�l֏�+����37N�����X��ھ�E˕���6T�][r0�������?CE'&�#�G�[5_��YӞ�lW��db�9+2�f��eM�db�}T����q$�D8��Q}��[$J2j @�+բY$�����ްp�1�BX.T��{4\�G�{��M	z�s����y�4� ��k�)hҞ�U��E�,�1=� ��.�)��w˫n��0��@��?&	d�`�0�W5��.�;��u���*8��� pCw%�
��&o%'�a�r�?�#�M��FO#=�.^.{
T��ۼ�@Q�	a�(j��4`�Y�	e&0���7�0C���]l�J�K݋��:
 ��E�Dj1��Fޟrw5Uۅ��Y��Y���%CڐIH�e?!�� n�R��1%\]�ܛ��C�}��G��+�+�\3���u"s���R�Y��f�fn�4D��Ć��!�[��ȦyQ�e[����%#:\���sp�;w�z�D��$����t��%FI��՞
��y�]���%=9r�Dd�sO���2��δ˿��Xi�a���e�p:�#!��l�Gux��nG��������;
b���%�yr��c$�Z�L�Q�x�`��U����0P%67���_.��'��j��%n�>�6���#�r�U?@\�6�V��.��؊R����2�hTxçFm�g�z������;���S�u�c�Pi�f+�E4J/����wnx�n&ǭ��S�?�Q���Ż�7c�xm����:��kЗ�I-9G��?������KPglN"?� �!z�F�Q�w~-H��S�&�G��]�2�~LX����r��֌ �7��Zɡ��[�����jb��k3��:��_�ט�a&ɐ�B�l&��*�����&��i^�k�,���\ �e�?	��L����B.l��s��)�r��4�PO�_f+̠h�Zd8���/!t�[��E"\��g�!
�w���0�7ՖI��|�tkr%q���"/' �ί�Z&vЛ��\K�8�OmW8��B^I�T�h�ϦS�����}I�6哗���8@E��F"E@搑!�/���p �6���4n���'3����C������PI�ۂ�N�\F+^�]H��ݩ�\��}p�:_|�luL��P�������EL7p2&t�>Q�R��hR�� �-+ں���ɳ��^lw���Vb}7UI'���9sϴؿ�e%�%rn>��L!oX�ʁ�M=�ʯ��[���V��K�����������e3"��Y)�{(�s�ke=��#�_���>��9y�r�̴���Op�]Y�B?��8�YlB�|!f������g�G�P�ִ����Y���D�7�P�f����UZL�-,�J��s���j���j��4�P�@���O����ͺa+�{��=�-5f�`#����>����D05z��(���=�x�|���s���)����k,��M!�J����Ե��|���2K�H�õ4K��$g�-c�����=R���|e�eғ�	*�̵"biť膒�;�0�V�_?�}��A՟U2��ak���'�N+
>G%�+�>x�Ҍ���`ܣ`�c=˕k��S�3U	j�TȰh��}f*@|"��h1�7���^>g[i��Y�C��+> $�v{�nJ���C�4sQ�ToxN�����M��
����8o΄������Z�l�Z���)�Gʕ��D�^�g�]OH�H���)�)�D8Ǹ�.��Dud�Ej&�[����"dA�.�}����gR�%`!�N������$��\��Ȁ�?�#o�Z�4�Wى�Jy3��p�w���,�j�6	 ��<!��4��P��z�_s�Y��@�xVZ��|T!l����}�ﭗ4>�ǚ!�M�����jm�%I���ЂS��\�	F�ɥX�N闟�!�����>Ζ\ǀb?�����u���7l�'� JCnq��4���[j��%5�u��4ÅTK�~�d9������/ ������� DH���.��w�ay�U<{�R�^��UׄU�b����1MOt�Zm#��7%�K�N�s"��]wW����[2��eT��<)�'p����x 7��Ec袳ҟo���p��Դs@�����93.�!�W>��+γ� i��������s�R�i?H�	������ҍ���}9��]�Y�B���2e���YGTK'����Uq*f���L���1�KGs�P�%�?���������D��hy���e���R?��f�Ǆ�&�xN#�X�����!jX�G:�o���9�lt�R�),�7�J�J�Ry,�#_��C�x��j�����inm��!U� &�o��w�.I���!x�m9O�h�mr3��\�<Z̋:�\n�:L�����cV�~'Q��,�^;겅�Vt��j��`P^u|h�P�X�k���X")���P����:<�����1�������^��M��oC�;>t߬���cY�\d]�Z�����mB�E�������N��)F&\�5 3w�[D�Wyd���JP�^��il��<�X�?�6�
�CQ�������^
bS�-ɖ��R��y置/Ĺ�ߎ����[��T�@Q��9�v�L���E�����]��e�����H���#] �n�jv?�ls�"ї\�\�����H�f�7�B������^s�$�ih.�g>��[�A���i��zwO3ve:l�rȵ��|�4	��p��2���:3��l/���ﺲ8��q�8���f�)��ݴ��_ E0{���<`�?5n5v��nSy��9�oі��l�?\�Q�����ǂ��㙪aƅ�v�Ȳ)�b. ���*��WKl0r�T�I�Q�0|��	b^)�"�s����\8���dT-�gn!'n\ ,fH'߲����	�z��؅�3}����^��B�>��f����������W�iz ��EFl�հtS�oug��V�em#ӌ�}�K�"IO_+�b�S]cc�Kh���<'��-�;������ '����.�,��U]�{�'{R�Le	�鵢#�Rf�\�n�u#�7�f�(��E�m9깂�������r��È5���a�K��=;�U�=��$�K�
̮��r�,�"�� D�"��*�N���8J؀�=��3)=�L�����I�e�}������mu�S8?0hi8����5� 6���"�
�?S�R'[Kɸ;=�!+$F�L�1T�m��g���ѥ���A�C� `�H�8&A���GU �F��;����@\M�h���Q3�9�`Z���18���U�WR�Xnޓ.�n��X㐀�Zuk��sǫ�,O��P�ގ��u��m%�osJa��o�)�fΒ�,��`a.f�(�P2�m6�חH�pÜ��5�u��e8�%�- boq�f��\-��� ��{7ojj���A��6/z{����5��Sc��C�d���>�?����&�w���l���\m͂+�����V��	3��9-8 'PnLȒ�`ɜ�>?�p=��{��`9 ak  ��(j� �	+��,�:4�_y�i�r�E��3u9�zp��M3�i���ܫz)� _G���	��v8�t�ju�o�,ۦIQ`"�`�孲�h����X���Q�XU��f��ߌ��m���"e����B����(m����:r��؀+��[$NP�<U�K/Zc}�� � �9w�#���,6dQ�>t���>�$E��L��ߗԵtj7S&iPe�OC�m�1MB�A�ٜd��/��t��V��4M�]��H#2��ecD.���d��O��i��ͣ��RX�Å�q��x��X?F�T@�^q/��Ʋ�}1A#Tg���~��}�J�P���)Iх��� �+ڡxA
P�TFVX���QT&-� ��HZ2��x�N�^�s�����Լ!թD4y��Y	    �� '��� ����p����g�    YZ