#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="8328348"
MD5="6c5d94731c3221ce8c15f965cc13f03c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26036"
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
	echo Date of packaging: Thu Jan 27 15:37:45 -03 2022
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
�7zXZ  �ִF !   �X���et] �}��1Dd]����P�t�F�Ԧ	�Դ������c�=ɔ�Ѭ�)�%���ҵy�ƹ�X��۫4�5�w���A��S~�rp�m(�"���2	Uګw��S<2�#{g��Z��T��aR����C�~|)7��@��M��.��(Y�#r���KV�f��0/H��y�E����� |���$��y���� �񩨜�B�7{Ԥ��&�����'��ӜIq�i��o���d���Ӓ��-�L�@Vi
]����i(z~�0�s��d�v��Un.��E�{�t}MPl�|�J|�W�Rè�gv(��9=������b�g�
d�[�W*�_x��P�^d��5�C�Rg��������_Sȋ�0�i���b�C��$9[�����}�߳�����u��-��������v�3	 s��]�[��wD����|?a���(E��P0?f�Gr�pe�U�;,���X�V$�� b]�a�Y���*�#����n�@�}���\y��z�F_�$r|K�!���;y/��Q��nn�X��g%������i�b��lէ�%X��<aM7S�`3�J����-:@�=YmF����X̘��n��eYS����-��_n�5|3�ʧ�ʍv��pX*^D:7��Uޘ3��<
z	�[h~z�ږH�WU̓IF�l��LV���pe�b� -ʔ����QȔ
�fO�UL�B�|a'
{����,9?k������5/j#	NE >s�!�<�w0��=%K)��3�ZzB(��ejȘ���:Ԟ��h��*�Vt�Q�a�aX�g�N23���K��}�v�����b��1�B��3��a�)��t�ZH#���B��Q��i��f<��g�
X���ɜ$_�O�P�xC!
/��tV���16��{8��?V;3MpJ�L��e�o��җ���A�����@T釥c4-�v�q�V��ycR,���j)�5��6��Vș�O����we��i��ug�S������t����|N���:h�zZ��d��D��{��Z���!j:K���X5�q=NhU����>�l�v	�0Ѳ5YO.�}����!<���xn
o�&��U2���j�	���ߩܲD-'�tP$R+4���6&����gQp�Di��j�4L�"j/q���c#���f����ۀk�ñ�>��+?c'p����|	sʅ%g��x��|�swP���T�0V����۝�3�>z��2E��0�
�ݩЄ�u�LUZ��Nmd}]�����4��l��̷V�t��Q�����e;��Ƭ/VҋfU�	V7���ۘ�Ee8�2�7d���,V�4](v[���'`���FheS7�9^t3:�@���V��l,TaF%�{�37>���uR�m�i�C|��ފ-���Μ�$���h]G�V��صfS���	�/y��~&*�����(�ѱs� RV����B���%�!YK�~)�F�����yZ�*��d�JTh�,��_�q�P�����"�%��;���/AN���->E��&iYg���S,��{?$$+#!G���ɇkh^����Wvy��Hn+���{'rc ��'�A�x�丁�i�2��út?��y�- `��*���r�;.]�nz�/����M `+�D��2@�IL3 ��z(����Xߩ�a�=����W�~��x\���6�Y.����XO@�.+�7�agx2I�7�K�Mw��G|�t�r(���Փ�cpj��>)8]?ׯ:-�9�.�t�p��=G�*ϳ�K՜$Ӌz :OXkƁ�����!�5�����I��i=E����n�`��
q�e��&]�&�*+ B�T=Z$����S��_V�B�{�	���,/���-]t���f����3h+��]���� ���%!'U�sr��g��O;&3y���Y�>*U=k�=��&��.�k8����WڒJ��ݕs��yA�7@��M�s*�ilv�������I��K��f�Mf7jQo�[�o�+�ց�f}<|"S���7U{�8T�@B��� @0Q5�&�@y��G��;�=_�>�K�i�]8�>�-�J���v�����v�TDV�l�lKͪ��������� \�G�b"ߋ#a�0!s���gh-6D��YP�G��:�� �M��-g_����#%cS��ceİq��bǐ����_��l�K�5+�.��K^����֚����"�;ۊO8g�>~�qxh�L㫷'�|bP$K�_��f�Ʋt�a*�.��3�`+)I��F�]���J�.��2��#/[[T~�H�3b��z׍��2Rze�;ڌ3�g,5NͿ� LWXU�	��Pw�����O{h��a��0Ձ峘���`?���s�6DgQh�Q/��te�����,�E�%�|P���1D�l��ƒǢ�QF����I�A�s�%����o�օZ�F�9j'~�W�hT�ۏt����_%��,"g���bZ��]�_�+��	×@q�N�ᩰ��%�{���x͔��m��X�9s����n��!m
p>y����=C&���Ѭ�HkX��0k��x�0Kj�� ��0��9Xʇ&��E倂�?q�ˏ
E�9H��V��Ņ2l����~a*T&���e�q����i3a[��=v��?@u����K��d���d#����`���t"��X�L֒4��.|�����$���V�e0ɄE�X�'%��Y�=�&��3`��Z/1��
�;� ��]�)��w��ӂ�.�[�Рs���3��o���-�N�# ��"�>C�P�x�28_�eD\!Z�A ��Pe3f�cU�{b�:�)�Ba�w�֤L	7�N�'9p���N���,�F�
BY��l;�q}��Ջ��U^�������Э�D���]��[�����_���#c��]������XI���&�����`nTl�;�6W7�9�!�n�!�_
����+ΙAc�Z4��!�lę^I=��O�Tq�ZohQ�-X"�$ՍDj�qޠ��j�����Xx��Q9��	ǒw�L��qf?�N�]��H����4j��.����@cuȎ��o�İ�f])�I��x�'����u��'�ϴ�}9#�f�����G%u�����c2I6�x��v@���6Inaq;܅k�W�8�����2�(����P�|:{$C���ї�h
X�h9د����<��h��&ͭ��X6�Z:M���:�=2��|YED�*�2�����OE���㵈���dnW�w�q��/�f��uA=����CP��@�0:�Њw�����~I:z���2�d?�1R�Q�#u�RHGR:Z;����Vzο����c�BO˜���Gg�����I�U}9�6$�-`?�����P$���N�����Q�F�'�8<���ӿF�w��2�@>ip�� ��/�@�
Qm�V���°�Tރ�O��+�Y$j,i�^hF������L�>��)��FWW�8��t!fXs��R��\5s�ri-��h��4
�V�Z���3	Q�v9�)$O��L�����W�{�nf���c���/+�Q&��І����
{���uK�����]@X"fN&��jĕn�T�R-�� �<�zP67����j�a:mv�t2��@��~6r2*�I��C�!b��L4`����Ц�X���5��f�NG_��)��|^Td߷�j]É��������a�ҶX�G-��bv>kń�?���v�^�rw�L��1Cop�]��1��Qk�jY:���UE�T��)�}U�&!���&ْ��J�S'ȫ�$��� 7<�9�K
���#=�h�\�VF9]):-����V�W�w��}�u.w����ir��@)�:2�!�v�ݶ�d�Fa��F.���l��Z6��oy89������(5��È>��K�K���4�K����W�ڬƘW�m�	)
K���h!X9��uA��
9�.5�=��ႛȼ-0D���	)���K���/E�v�g.���P��HIÇciLL�aD����� �P����A3̈滓�a��IU���Ȋ��e�0r����������(V����!�)N���h��P��&9�L��%�Ya}��1��4}_h�<N���7��~�(g�{����:%�z��yٔ	�����Z7{aOE<�کv�20�a==�\�o� �����+
߮������)�>��E�ȎrLΚ0��S9?�=�8��/f$=̃j$��І�a�3��j5Dt� �����QFΗ )���pW�����-�!�Q��2d���)��2��ϒ����a�ě`?�M�E�_��Ajv�ּ��CB3O�y%~Y0&	tY�2L�E��Wo��BeQw0����Oy���+f</H�A�Ωw���4V���>�˔�����Du/�(�R�w�od��O;���6҃��Β`í;!q�2����x
j�ǥ%���n	��沿A��zr0Z���Į.	#���o��z3�d�i*���VVt�~��y!����u��}���݈N���3E����_�Ԁ����q.E/������f<��p]u��4�q�|'�˒=X�ѭ�qb�V �ȑ9`�Ä=���bN{#$1<p	MӃ� 5����[��M�(p|aV�N����~�[�^yϠ���@(������/�v�� �9c��c+#�V��7&N����,I�����p6�e�856q���>�ۭ�	̧=|5���W�G�d\�#�X�NR�B?V�B��!�=�t�!��X�k7�yk#�z�Hoq�|s~ 5LŚ��:�7(~� �~�k���2�VhM6��y���J�C�톔ق��D"A�/p����x�����I��(�N�T��*g3az������k�G�';A�ء��Γ�|io%2Q��1��%��(�1Mbv�ߥ* `�md���t:Ȗ��2�e�ڤbqm���'�:n�l֚,`l�D�; LD��(�g��	�~z4{����3Ց���Ϧ�=U�5�>�U��������%�r����"Rw�q��p���$Qtؠk��_/��.-6y='���Q�	���۳=f�>�J2F�{��E��U �����v.��ݴ�傼�1��vQn->sdZ�����	�)���ԡ�0�$�H"&�r�(�j�h�9`�=D���]~����C�|����t�����D�Ba�/!ޭۻ�s�A�8�U� �w��>xX��U�JE��<��1�F��$���B��������0:N�W��25MJU�a}	���N��M`m��d�VT����|��v�l��9���	��ia�B�=d�r0�J��Ӌ�G��5��6΍���*��5�e���O�iL1T��7�37���jPvBr��xQ��us�����禖�C@���0^ˈ	�Xs�b��cYZQ�2�eEe���1w]���װ��@n��v>�Y$�5!,��&���ڔ���ϯ�>��u�	�ƪ�Oǚ��]�[�f�����P�ֈ�e��sEI�l�)Z��P�]e��Y,Ș�.��`��i�}}��N�k��@���;k�	kl��!Mؠ���>*9b���! ٫0�ј��S�ŉ��K� Sىb�sĭy��r�a��vb����	"����� Mcqv^P��%�9�Omz��2І��[��������Ճ��}8P}�=�6L����3w�4 �b�F)j�zM��aX(�>�<���'
�\�w�\PlC4+���3}��n�b�8����N-�}/o����Y�/�[ `�8��<�M��J�_ó>���4}?�pq�a���>�`Yd4⧙�u?���8��9�����'���,�!rЄ=�xh�>��o���D�TM� (�>�s���~���7�/�9lӢ�	���Ē�˜���]��X�G� E�4��MPA�)��c�K3EѠ����	Lv�>o[p�0Q,�����#��A�;O h�v,��v��?э�%��b*m�^��,
�>ِr�1����<#�ꎰ0�������K�yT���󈔸���4�8��q�ȣ��Q6=�jqR���&���}�c��C+���X����(t�m) ���l� ܕ�� ��}��>SLw����4��弋$M�.1����Du=��!��	�u�*�����J�\�I�U��F�N�B�$:�6����u[^,��IH�Ԑ�dM���:D�@)�.�����Y��ku|�V���٠���?ge��Z�<�0u�����ȷ[�W֎�ܧ��8��tP�#�K��w%�A&�yбk�u\,�ӗw	>gu�����`��z�C�=@�����E��,�敫�o��)���J]��Z�c���;��R�����z��k������-���ČaX&�� ʲ��G���8"cK\QuBՉ�O
6�<s5X+���;�,���@tğU��� �G=��|��F�mCX��8h�8�V�{��������=0%��V�B��G�ø��"ؐA�j���j�Zb�V��K���5ȷh4�T_�W]Q4���@(����I_C��f@���
���?l�V6�9k�r'���j�{�:ț�]�wi�W_�z/���^<����]���+b���!ī
��(6������Ĩ���*'�Ѱ�)��zN�S 1�5/��պ�*.�:��ݽ�B ͚��`ݯa;ƣ֮�_-T>Ww;��}D_<�6	a�ƒ_�&cƻ�gÀ�9
#�X�*�s�^���L��Aظ�T�;�b7���w3[r����� �^���<!�gwn����d�pvw�uo�lP3���b8���Pڸ3���A�z|�JB�4k�M�Z,��ڝq�`hǗ�.^D��/�$���	k�4	{�y�aҡȟ�3s��<�Rp]�n{ڂ���"2�;�jR���븋�y�����R螣���A��� ��.�v��Ƥ�F�P�Z��bSl?�ʁE��:��N�B�$�����('Ι����zJ�Io������t��P���U��q���ZH'VI�_�#Qz�]�9��G�K	��2��A��K,���ʐW3��&�����������:��j��wG��$LS������9�E�'��О���%j1��&�*�C ���b`��S�� zvbߜ�~��#�Q��HoL(��-���t7��R�56kId�>��Dƿ�7���K����H-� ^d��ܠ����<�vb���	�Z���w+��=�R�1��o��}��q��r))	i83�kH!�qC,;qu�o���y��:>20Z.;�1�L��}bjk��]�<i�3;�S0"<[�S�	����Z1�ƨ;�<�q؄����y�!W��ه ��U��`��56(��`哻�����$��evHȗ�
�ܡF�e��]��j �)ORJ>�Jw�Q��!�ȴxM�{��<���\��H�H#R��]����Í����*�&�PC���'�B5����tʤ ��*r�G��bb+��Iģʧ,AN{��:#�%c �Dx��2���n�$�nj遐\���V�^n�����D�
c($ܘrp�f�* K��4@�8���8���+8:���[��4=���b�J�8o�>x���	��YN�ՠ�ҧV\Fz빒�~���YbH��� r=�_〕 ^!����B�+F�i[�N��nQ;EW�U+�n`��� ���z�q,���w{�_GK�R��N`��/�g�ʊ̔�
��H�wVe�VSc�
�� ��P�J��Ugf��M�/���\T��B放�#D�D����*�E���?�R��8+�-��Y��{y�CY�?�Ɩ�����'r?a���5
����7����rˇ�/�Oj��Y��	����̈́A03ZpK��_�`�~�B���p��K���|��u�;��&d�F
񨧚oƔ��6"6o������1H�Mz[S�{�g���m��Ko�#��S�n��Y(��D������(�n�/&��[_���"-�R̛���/j��h0}��b��㣿��B3.��3�h���B��;ƞ �ڹ|�� ���\_s���o׼A�GR��ذx5ED�(j��ф`��cv��e�d���,�x-v�vE�[��{�������4�+`��	�J���辴e0]!����;3�i�M�9���P9�e�)~G7~��<���d鼡7q�S<y�m?UbL�;�Di��: �����1X�I����SŞj1�	�)���|�vlx��#$ܗU�R�����Fs�)�w������3�&��u���z�5��g��+\K�\q�MF�����J�tWg��4\%�s�9�=P��ߗ�٭�Qw��кO0zX͖? v�#�!����]���A3
sx��~��9J2�E�"�lp9��1�	��6�-�(0�
�R3�4G�T����bM�-�(?!kO\љ�e�r�g\���s4֫�k��2�P���闗]�<���Ҥ&�Qg��>iOW����U��G[	8j%�>,,�T��+D�aӊ���<vJ���G�#��Bx���RS����\������i�v���ٱ�]��i��ec�)|Y���u�1���������R�	�l�[��P�B����T��()����E؊tY /�f�U<aN-zd��3Ԛ�g�W�E�+���b����>�>7ݱ�V�nG:�r�T;�WHi#,P�Z�
y�8P�2ܽ�H�Q���ا��E�����<�4o�X;1$�Z���Q�y�>�~v63H�}E�O��פ�\���,Ews�Xq;)��ǱE��?k]�)�)ʕZ(@�G���+��e|.�K5L�\>��-~��pk��`YqP�!�n��pg�7�CFqfq��x|����v�WZ;�`r�[�����HRD�Q�<��&�'��j��X���M�O�(Q�LX_�&��' >���E���'KG�٣G�r�ZэZ�˒}{�aё|��T%m�>���:g�����c�;f�b�g8�R,�>Twvqh��$Z����łpBS]�
����fE��´:���P�o��d�󼸛BO����9ϝ~�8�&9�뒨�=���5��Eb�z�,���&*H�{s+3бw�c��t.�/ gm�����t��Jю�1��I��t5���_��W���Zbk?�.?3_3������pJ@;�V�g�i�Jִm�~�2���I��� �	�ab�0�q]DG.�qy
f]6P
@�Z�)�/�B"y�8�x�Ix_�z�ŋgC���(9�w�@@�;�g+9������(�__9.x��C���:T�$��Kn�E��D��S&* *_H�A?f��������;" Ǥ���J��uo����@��p���:�/v�4�kk%F"��l��:w��F��:�<)����kCXnH�},��T��B��"�d�)�)�R�'�!W�H�Na��!�ip�ھ�Bd����^�|_Ǫ���;_��Dy����k��ݺcj���h��jj��$��s�g�*{j�UH�n���!~���
���2W�{���b�T������F�	%q+.��$9��R�:}G`T?ʢ��܊@�A�w����vl��u�v)��o���8X�����d���Jt\Mmq���T M&W�2 S���h.7�6k�Y�+��p�vO��T@4�|��Zj�ŅB§%�ۓ�,}gn�6��'�-��m��"͑�5�j�[-	�uS�H��@�l��O����C�1�w��+�O�6����G����������Ʋo�E��M��GO�Ne0�����_�R�C�l���s�?
ۋ��aKV�@t��{�@��ǖ�W4n���S��/	K�ό���j��+��x�C&I�̖��A���T�@R���C��ُ��#��yQ7rX�%b<ѣ��$�O�ͨ0���.��Fi�w�w�c&�=�R�y��%3;m��t��G��Kj�2�(-�S�g�r�/�p����f7�x����� �*��X��/��u�,;N�Q�@��a�����4
i���#�<*_�g�Q�.U���s|��?Us���X�v�tɣƀF]���`�X+����F��?�Բ� �g�����W[Xc�DA���ȼJ��&0�� ���N��"�>�M����U��*��K*��e�k��̆���h���`�d�4��$X�L��h�%I���'ŸT���@�t�%����X��D�}���y>�8({�舤���u�fٚ��L6�4���$��e;�"Z� d�b5��������pȀ�L͢a�:C�q�~O�>u���������US��3u�x"{���v���S�Et���m���!4�2i���^n^坲��V��)�3�2+ ����=B��k�Gn��<�o������L${p�Zuk�2 EJ�y 3Y�P�Ȑ�>"��"����s ���X.�7+yH�n7Y�b?��y�������a�̀J�ż���4&�@�T���#�ʇ�/�_#&�'A�*2����.U�\T�֫�-���ɼ#�K���8"��MŦd���]6��t`+�AL�{����9��3"�#�CXk�B��,� p{wks��gB�<P��<xҨ��f��f���N�\A_�Ȫ�p�8������E�!j�s��PR�g���I��)q�b#)·t�v��Y�����hQ*Z�l�V\��ɤ�s��7��	h�sã��Z�I��(����t�\=6�kr��?l6�S\�3�SkH]����;�X��5�`/�n�+�o��o�/�[&�ަ�/�[C���?)��<tqLcd�lMGY.ZmW��\��Z��y�¬"��ފ�[1Ud�A�g�7RǤ/VKna[xa�`��r��q�����c�_4����R�D�9��ϱ$�\;�d���8a�3:�oX(4ܙ����"��d&�Y�l�"��Ȃ��c�Uh��>�{S�GGd�İ;n�I�$���Xg�8�l�ưہo����î/��#�9�~9��8��
�
�c��ك�	�)��U&
�Z�]M?N����k��4^�Zq��W�9񂱑?;�����Ͼ|��[�hK��{<��I7
���W��r������/i�!6$��5F�<q�Q��h&!��|q�=L##� �2�-��B�3�>F���0"kӂ0�6���`;)���L�`M��SQU$��9*+*����u-�����HǾ�R�`΄M.~C+�����U�\[���!���h�ux�R�'%�@'�s�Rg!ٴ�Ŧ���!b׸���	��w�̽���"8����6��sM�������0����(���ݻ=[�r6B;T^�Ìm�)�8�}�e�x��p�\(�H���Ti�����]����F��f�Z��s�n��ϙCK�r}��G�8X���)�1���v�x���+��y��z��@�ZY��m6����r��vo�����S?#)\��9j4Afp��-'�wZ&EO'm��Q}A�b͕�$:�/b*�Q�r0振����!��{J�Kر��Md	
[c!�����&T ����eLC��߮�?��SK
9u�w4�W��G���s�T�Ϻ �t��9N[sE��,F���\��\�����_?R��n��c�����5M���6���i�m�,aN�
ct�YG&���g�<�~i0�Н1!l�)��v�J�e��,=�l']�tXxX����4����c�M��Ŗ�a�Em���)ب��7~�؂�ZW���K#��4A��$��ԇׂ�w���|�(7h*�֟#E�x��.;%���^��>�X7��/#�����������ƯȻ����� �
:k�����,�Ed�o��,��0�a�w�J��(я��R�9�o$�]�Z½ ?�K��<F
�i�AeH8�]y(�� ��EKE@��5y���	��b ��l:?NJD���Kд���=	���/�x42���7]~�K�SC��L���ʋ�M�r��\�~�biY	6OB�=Ӗ�Ie �{]ϝ��G����JSm�<�zp�k[�Խ2��zv~��)L���M�C�ΚG���dmI�)�P���SP
7<{u��Z�o a���S���,����=��`�|�[�?a�4��F�e׶�bD/s����T���:Y��OM��
�7*]�	-/���E��0>;��	��d�{�'���r�)��ꫩuN;ܐf�ᓼ��t����O�oF�3���k0��s�ı���M��n��xB�-��eb½=��iL��C�R޲�q?�V��^��J�|N�S���g�|��E�(��B7s�C�w������Z� �I��5�T�t�k*ҪL-�'��")h���~�k�Ht�b�*�D��ָ+HS��0��
ʚl�6���с �Ɖ ��8r�4�L��zlI���<u�Hdn�U>p2kPXIS�ĵ��C�3_�ek4��g3���)�"JJ�� ���fZs�d3�����󵌀�D�.e���|@(�\�w2�X1M�YS�Sﵺ0�k�ľ?�M��"������b���f�䓛�;#F�?�Cx��7=������E1�Z�7�*%ڙ5��TՂk"��y�PT/��]�P�5��b W��=-�ff�Q�|��&��t?��xwa�Xv�Y0��g��H�'�����E�)S�$�{d�oqUh��p�܌��U�1�%��N�Q�;��n�R���e� �+���^ڻ�������	{%�|�ݽ��r�l�v�)t~�[�65�dg��%��h>�^���۱�S���̈=�F�i�A�����1���9z��&T�&0D�+�V�.*
�XN���9�/��}v�B��p�Y��zq��<� #�a�1XG���9��*�`A>��lB�}_�Z���0�r�>`b��d7�̕�	j��X1���R[;���u���F2B�'�Ԡ|��D&�pi�*�&�[�$�e��{u;���~z���,W���,1LϾI�&�h����Jtl�Λ��u�sN�sW������
�GUIQW�����8K4w��$�1���E�e�?p��B�U	����u|�m�����S7�~Dݱ�o�Q���	oŖ��q���{9޼�#cn��	C��n=�/z��G�WS<����as�v��ʑ+؏"z�|�}�e�ͭ�����"�[�';�!�h��O��8@b̝^v^y��%�3���L���-�+4�g�l���z���!"4�w� ��%���^�>�;�R]��q������t�>��>�*k�-�Z<��~��T�z��HW�0EAY�j������t�����������9��qvBZ����uᨼ:��D�X��=���<� BE�^��`�0g�we�Bm�Yve����%�Tt.X���mO�8���4b�c ��Ζ���q3o�1��vJb��I
�?6*�������U|��D����]ʸb�J?�A��cx�t!;�±�E���<^�9�}�Ю����?(�t�NMm��z����h��pϱ�.Ո�������J� 	z�݉�n�Z���`G�fʀ�+���D픮k��x_6�`�������r�L_	��A%)L}�b��~+/�T�+G_���<�5��W�����0���Ê���*뢠3���*�=�OG�:	�vX��u1�Z���[�Jœ�����Ɵ��ز	��������R�.!�k:�5���s^��[���Љ�'l�@���}�'�����_�VP����s.ؼ�hb�
�*��!b)��0H��c�f�yB��S�~�P�����ȻZ[���r�>�|P������JkW ��Z�v�9c�	�E��{�*�AUː�cT�L��d7К=�1�2M��K&��D{�Ǉ."����g����"�328�(pD[]GL��2�>"�ϓ�6��<-Tb�-�&G��9��3�$���N�A���;�. p6���<s|]�9Jf�z.t��2�r��r���l��b����*F���4�K�9��ᛡ��5X$���i�y�pߕ��e��H���aL�_�����"���b�	zɤ"�Vް\q����j�_#w'�N��6��Y�Tp^�K�w6��垢n�K�]\H,{D��(��_�;�4�;���h#�@��]���ـ���oG�)�
��cs��r��T�ku,�=hǐ���Ȋ����!X�/�>�M�N��񩼍�x.���m.����`.��P_<�j^Q��j{뮏�&W���O�^�N�0Tb��O�4�dt��&��t��0��d:��+�}����ǵ�3|��y�\��*���z���8U�����4�+�Ғ�ɸ�=dv�E1D�y��i�b���P|�^���t7������4,"2�^���Y�ϵ}���FHRnVУ���$X��II�-�|�%Xhwv֦�s���*�6�؝��z���U�B�ް �W1<��s��U�H�Z��MĤ�*��X%`N2���7�����?jyuv�I=����)T͸÷��A�f��`�;`�l�8!�X���������ˀ]��8�0#:(��M&nce�ņ�DL+�j�����kQ�j�㘗ߗއQ�q�H�3l\�+���taJ*\���BF�l�z�産�w�^���:�R�b&b_��v�,7�3)�*ŝ��K4�q&��l�F�e[�%�9���͘�:�GT������6�K���%}Z���B��ۏ����F�;����pzM���A��az����&���p���K.�^����P�Y��܄���~B�*(H�M�����+N$Ǫ��!�����ב�^���d��ݻ$Q �wʝ�����x�Q+W֮?�Թ۶�R�~FƆW�4I��BfaC��`4��4�k�Y��ܩx �K����E��Ã��/�nCX����ԡ�����R��C����Yʌ�J�FR����_>�0��@�m��I�SP�H�G�[BY)b�������*�����9�?
��L����nJ`�|a8&�������v^�nV�n��E՟C9�w��y:'B����`�l��:?uc�-��YKG�#�5�9U��KY�p��Z�C[�VIwˈp�.�>���8�x6Lh�̀�p�<5�@T����'�tN�â�()��齌�m���n�z`qG٩&�}�-5��Vv{�6��8��n~�,o/���ΎB���������b*�;�|5�~	�9n�o0�#^Ua�5��Sw�'��ˍ�X�����ml6��Hd���J�6��A��	;_3�$�B*�,�����r�k�σ��(<�q�=�m�?	����s:�oG:&n�&#�pz^��N�)~��\#�f��2 ����?o$�+�I�v��R��O=�߻D���,n����!=�u|9=�|9�sv	�]�Ƭ����eZ�?�(�X�Bm7�8���%������u4b}ڰg�Җ�vL��v�M�ǦN�x:a�Io�{Gz~��n9ZM�TwZ����R.
*1�*��Î�:���MfT�Q&�0�`����v3,9�9U�M�0�(��%	d�dt/���#�&����E{��n��t�Y�r��)<u��(��U;Uip�E�g�i�J��"��v}x�ڢ�'�&0�D���X!|�eZ���v�2=HӲsߤ?����N�U;��S�}[{G
��Ȇ(�B)o�7?2�y��K��s'�1I2BC)������Q�Zmz9�����z� 2 ��	�<�ʠ�)����E��'����.T��?���>DD���C|:��%��ߔ�y��;�a>ǝ��s񯞍,Y��S����~�T/����+���'�m�[;4o?�Y����Rh]6�m������]''���	�~��[��m�
�W|KvEA�goT���F*�2s��:@����s��W5���N5H5Ӕ�(��W���'�lS�XT��n���@0 �;��e����VY�X�. ���sN&��T���i��`8��6��Z��LkR�9�E��� �R��kE�9|�����͖�2�x(>J{@%�RM*FN��V:3�B����d�v�"��q�p�[���p��.`/p��K���,kA~�dҸ�o$��T�)7@��k�,Tg��ɔ��ԽpH�_Zh@����K�J�$͢;<:�7Lv��p�q(�{8�U���q�H��r�����oƌ|�bD�MFђ�]�3��¹�9n���U�E��s��Է]5� )_T,���+����0���ԗ+�єCJ�?��������wJ��
���n�s�u��B`x$ßj���g��,s��H})�j��u�� ���և��^ �LY��b/?�i�PRcnc�%/��g�Jq���բ��B{U;��k����	��Hn�|����|�<Ǆn�I钄�Ϲ�Y�`��͎��eu�@�l]�/k�@������x�����R78��/a^��IcWv@�)-���9w���� ���Ǌ��)?��$Pf��M��k�x���;LJ;��$���Ҙ{"�f�$:�`:��]uj��Ʈ��X"�����d8��g�iMC���TR0N�bZK��������talXÆ^�[�r��ޓ��5�7I�.#�h�ї���?�x
��{�o�l��#k.�|���Q��l����#�E���C'��~[-@v�NF|����P��ag�u��w�0E-�>΁h�&-:�MBaP���1��:nU?A�Iܽ9g�}�e;kϘ�%�hp�Ʃ=,�(����I���͓�n�������o�w�M�>�6�rwvS�\����"�@���83.8��S�U��La��=F`��� 2�P&�����ܣ
�� �ɻn���^�N��R�@N���a|6�ׇ8T�Z�뿛\ �X�2$y��|�oh*�9��7��z���/� 2����2�f(X����_%xr�X�� 0ob�� 1�����"�?x>AB'j�R�%���<J0:[{�M_o�yk��@~[1g��p��A�_i=�
���'��P9�<�ɩ�F`|S!�$ɳ�0j�Z�AmWp��Y���x����?��[�j�/��@�;�l�u7�V~ �@D�+�rAk�����4K�]���;{-�L�+��pZ�W���iŮ���l��AL.�0����!$
�x�{@F���~�����Q��c��"52}ZQ4��ݩ�5i�
����,�P3�ǙmRK5p��Mu�O�0�+e�e����@*�������H@c��v�P%��,�A����,-&�/�T��֋�+,] ����.���ΰ����"�WO#�W��C��"6=���V��q�v?3�n�J��C'�&�Bm#��]F���U�+�j���i����^�>����CM"��x�21�r]��vV��IG��z���9��r���HČ��>3m2i@�0�[�}��7x�z��ݎ�!?F$�+������{���<H�=�ĚSIo�?Y'�[-W�^�%��k�	l�Jμ�b�:�N��P���\4�N{B���d�ˎ�j��@����_��0��
7&C��8Fn�D7~l�;�>� ��hG�Ƙ�wd���6U[yf���;;h�xu�3���WB}vR��ҩ�h�8��ч~J�Z��um�4�Q��jAR���/%��������<}�b���|F�D=5��g�o>˙QR$���2��'Qp��g�d+��W��-f[��ݤ�^m�G�6�&�g�0�����Mg�'E�!� ��R)��SVf�*��(�F4PɃ�U{�>�Ns��PK���b�v��Ta<�8�Z��(x��"����\�#�^�ɡ{ZS�I�AB�[��O9Wnq@���>(˯87�1������j&֍"ər��}��N��nĦ�J^�� �c��j����˦�n�Z-2���u-h<~�˥@n�C�_b^+�V>c]>j������!p�d������!��P�UE�g�	H�Nۣ���Lx_���&��f���c�����`���a{M^/��HMb����a��	c ��g�L5�ا�rt�F�q�����3�t���������� u���,��#� J�nG�]�ި�P}"�/�!�Z�Fo�'>��N�49ղ��A�~�∅i�Sjn�U� ��^5ؙt�'a��u5y�ً�TΞzb���^�)�2�����w�8\�ƃ{�ȩz֘r�p�ŢH��:�֯���۶���洗^�|��R,N�7�R6e���j���N�n�>;vԸ�0�v6�ϩ�<�ld[3/J
-$��F�>J.#E��#���*L7�):�;��ҍ���[�?�<�Naϔ�M|*�����e�������|���$nS�m��z�D>#�[�<�u.����B�#��H�+0+�e/x~��K֭��3T3�a��> ���������7�="Mg��q��7���3���s�|Y/pw��6���@j	Gϭ�M�L���>/F��50�*��w Ou�,{�B�R�0�=*N|P&�z����J_-����H��H��m�w��`��o�A:�(�=S��o��	t��G����=Ilc��N)=��*�<�5��$<�&�R3{d�������1�O��Y0�@�ȯ�=6̈́2����	r�yy*��f�4��m��y;�0������Ǻ�NJ>�i��甬]Y�N�q�\\?�;+�l~YG�9�k�4��c�(���8t���4Kg�F5$��咾��Р���b[N��$�}�ΐ��Aޟ�K����d9'��D�J�4@���hl�=�ݭLl&�"@P�AI�h@LU=f>�����_,���Qo'���qp�$�oWk��BHp�2� �I=Q%��t��i��}�+�~�v��C�#i�Kø�,��e��>����'NH8����cM��i����ǆ/}�r��
L�ha9�W���L/H��h�W��������+�"��w(�]_�ϭ߂�.�w�E��FX'�=YoS8�-jt��Ӳ�[����(�8T���f6�ݩ̇�}�a� [m,�V�����E����ZA/p !�4�s�AQ�����l��z���E�>�X.�bWa��E�^S̬������,�������P��fRn3��$�N�y9R�@��u�yz�fk.���3���뒝���3�� Ŗ�Qjӆ��d��	-���jN���v͸{Ʊ���p �_��2@������H\\�/���zO���幬K�b�-�|��~��d�{��w��6�8��at����l
�AP�;�A;���Y9�A}�T���b�;��Ş�F*<���B/П��t��|��-�o���BShV�=d�N��.�gI�����d�K'�����D�.lI���_6b�`�����M��>�ވ�\��^y�xV�V�V���U�ղۡ��ُx�����>���rm���mEn�ϣt,�,�dF�3s䰔r������5έUu����arm|_erY�+璣NjiN&����3{�����c�{�ɮ�k���&��u�4A�G��(?]�����y �s����Z�8�(}.ǆ�^����Dq���A�f����T^�bzY��@pN���%k��!��|��u����~^�HJt�Q;�O�5�or�u�<��E��C�`Б�mZC3
��6���V�V�}��´6�����\�to�ɖ=<}�*�7�ZT`bE9���{�N�w��/_�,�[;�M͔�+F�D����0�wB}�ZL#&�yuhM��0��������È�v�`�&�vC�6
�r��ѧ�5Q�04�ɎH�8�/{����3��n�RMə�=�ȥ�$���3�E�yx �i�1�@#�acM�)@RE����l�'���g]j���(ImG��}&�F�F��V�Ax���np��3�Һ&={h�G��q:��s3ܗl�<�S��ɇCT��&G?'k�O����΄\�U�k�?l̇��� AӋY��+?l������r��-)g5�Ѧ�]��t����¤��eP$k�R;/���3T�~޾ i&CU�T��Ġ2�H����}�e������ݬ���Q;��3�F����s����T�L�,��Q0��0P
����U>b@(��ت�d{��
��A��gi�2��K�*%�O,����1�En&�u�:S)����{�Cpx�G���<�.�U%�~��I"�������=Gr�})ۈ���%��!�?��2��Z���kY�+�*d5�yݜ[(�F����륃5�I���q5�5�G��W�8-C"� �c8�]��rn4I�<y���T`��RL� e�CMA@�����}_��ؙr���K��=�q������ ��Y4a�)&#�h ;�XĔ�;̂��KDnG\����D�x������C�q�'�'?�k�DuQ\�X�'Y��?&��KuP�|��|+ˬ*�~,�r6���m(?Q�=ᗍG8-�ҏ��Z�.��/�eܺ}:y�ۈK�%����Ǡ��-�]E o�o�T��.�g��i	aފ84W=ZO2��������烲 T5͍�^5a�������ʨ̜��{�0o=m��/G9��d�ᙞ�5�p3���D���E�[��G��5yr	�EA�]t����;6`Pʵ ��Z���Ab����
�:q���F���%K��X5C�u ��#�Y�-�YrAx��� i�v��D�)ױ�XM������ zN�kz�c�5陞�C����S�Kw%���O�Mw�����8�Y'XR.*7�z�Gsi�%��vǅ��d�,�N��4ɼrS+�Z�7�"Ur�f<m�����(�o�����F@�Z�P�S\����7�����3g��2������7=��	Bc^�j�&��� ]<{TycS#��M�]�k
��nP������x�Lx���ί����P=_�W�����������P�P��n�����O}+�{&�h�5�=������nWJ5�t�m^c>٤2P$�FO|.,�����p 9�pӼ��|�&�'��_5�$�^	�Q�Q"�x�� ��B�Y�A�l�yV�́+۷����b�i��ma�K9�"�;����͹���o[#:WE�5L���^F����/�
R>���=����}������-]�d�+�f����[����l�d�	Ǎ6�#����.Q>~ff SY���R���X~-�P�J���ڝ��� �IS��G��@��O{�,iÐ
�G������	$�eӤ�ִ|��|�{3������3~��	�a�Th�4��'2�Lط$�w�Y�DOa�*�	�P�QZ�&{�i}������?����]�k�z��b��:�2*�5���세�nb�;�)z��/@��%��c
�ӣ@�<�oҩ%������2˔�pܺfLF�-��.E�8�v\�����rns���D��P��E\���`�ܵ����eMYjKN�aI��FJ}���ۑ���}��~y��EK�Qc��v&t�z����T�&	I�`�V�������L�5&X0�[Q��G l��Gzpk����ڂRfI���=3`���0��/O��&jT�:]�餸ݼt\���J]"��y�5N�v�1@NZ��|�k�&$�4��/�����+�� ^|)��T�B�5Ϋ�}�|�%.��5kT�sȀ6`l�@�NlR.��ki9��S���U;��[�
���^����tR����!6�R�)������A;��� �Q� ���cP�!����Sv�1�@�A\�MT��.?�cu��<�Y���yP���\<�n�����) �2��(���4)X�� HXb���h�w���.�}��k}�-���[��/u"$����
�x��u��_z�I���� �Pp@�DE9�D��	��ZI��ǆ�xd�MC����~�n�Nߵ���p]��7�{ݺv�%A~�^��0_��ր��^��F��̊�]j"Z FvFt�~Κ�<bl���xy�A���������fG�c�)�D��X'��ɓgLA1q�v#���T�����t�%����S�]{B.��V40dx'M�L(��jv�sTm�'��zݎ��=��y���r��=O'�Z>�d��$b ��P>Q�<���I.$����/`SG��b��Oc��F�#_�u����v����S�4r�4��qY[�o�,6�w}sI"~�BR:V+�T�Ǫ��K�� � 1��=���!��lV5���S�S.R�`�3��*��hT���of=]"�&AN�&@/�!��,���
��Ssiq��Q2�('U��P`���B��<�[wI��S���S�-=�$�����ص�6�����e����P۴K/��v�~�֪�h	���m� �!�P4��y^cˣNC:LՔ����W��S��T�s{~a�e��ĄL���d"xA#�Ԙ�\M�(�ff*�.��m�a�T��ʴ���ґUm�Q���7�=�Z�`ӱ�h�)inp4W� m��݁��/�����>�������U��pa�ܮ���W���8��,J �x�*;��'�2xY�b�����0��3�].��gp<)����N�W�e鿀�y,?�8�L��1�Wbq*�P
��5�gH���B�e�;&�d��� 1�/;��b�E�sՒ��j��Q�����͔!G�z��4�[f��#ٽ��-/�y�T��ئ�ƞېUFZ���w�`ɸ�C�W��im���3�V�\L�R\h��j��1F]�s��kJ%��#�d �YU!Y�cUʗ�3W�0u�ŝ"�'1��|~c>����Y�|<��n��0����6/���KAS�Ya�+@�M�!C{��Ld��s�f�F���=� �T��5W�?��-�������L|Qe:O��\��dh�5�]nX��2��R��V)�җ�>�&f����I~G�t�< ����k&�����|ӄ�M&��vT �����J�C��@~$���8�$��֯�w�<�&��0[fK��("��{)}�YY�WiޏL�/�n?8�V�K#�9�X.!�����2�@a��tq3��o3��{~#�bK�3�����=$�5)zJ�w9�g�"K������ˉ®\��Λu�����X@��(��0��ll���;�l�KT�F��Z�����&v�B��\X�!YR~�*�EE�lFr�w��N�ek���p�Ӷ������n^�"EX�4N۾�^�l����6��R���GBӜ|��>��6Z9(/D�m��$�!�]�2�&�$�%ͨ�̽��Y�e]�q^Ҕ�ێ�v���{�Y���v���b�Z(K�-Z[j<������w:��ύO�l�z"����|=�C#�E����_c��)���K[�:�����%�	3�B,��5�����2.Ta@�1.�u����
~dg�oL3��h���Q�"00ZS����U ��z<�s �U�v	�I�#����{���4*;	�b渴p¨�}�7�[Bq;�uku���������y�d��XW��z�����§��B-g���5��5�����/X|��H��ML�Tn_�˓qUM��8�-w�z���zG�*ʉ�i�j���Sǁqo��N[O4��)���'�R�X?�v�-�k���'�>98���e5�u�� m�^.EN�"l�/�}ѫp����CAO�WJ=�A�B3��N1)�4{��2�2r�}為*��v}z��J�}63����%���z��$�ϊ���]���܇R��΍.?9��� ��`ۧNu���i<�q����>Fw�Z�$&;K�?�jyf��>
�}�Q0:��:����ܘ�����1o�9�"7����� � Q�G�p�����UM>�H��<��a��S������zne����W�.��b��E�N`�J��ܚbU�غm����J�:%��%R}c,�2v��2nT���
m��ب�=^��
�}���Wody�
"�[?��γ,��>`�XyT4"�FI�a��H����0b|������Xz{��6�$��`�N�.1���i`�I!��3�W�b #�o���p]eu�S6�+�dX����;���"$���������n�ĤY�0�5^���=�r7��n��D�7��"*tx�X�.jqxRU+�22�'�.���i������ov�.�����B0l%�X]z+9�oтJctϥ5�������)
��2�����G�a7t�gY����o��S���V$Xms�� g�;<k�?�
����>_�܊";A�L��o����O�G�Mm(]N'8���}µ����N��?O��Q�+|���l����&�$|IM�hS}�v*��vi�Wpο�ϫ�q��T�L���E���E������R���z�5�9랠�B�J���v�*���":�EX�$q�+���)�W���E���[z�|�湯NQٿ����Q�'�m�j��ٜ�f�MFf���tn���CA�I����+S��oj����'�3�}V�|[��1V%�� �P�oD�8;Jw�����a2иz�yEW:]H��wu���OЍ�f��mOJ��*6�����<�L��u��s���!(�]�@�X�۳	�*fv T�dS7�A�M:j�2��g�<2�_[�������9]8E%��ؾ-�.��T�v�ͬ���;bav󵓿6=����^RS/y�wDV9�;_��k����F���K2[�ШZ&s 6\3������+^ދ̦�8�eP�����	h!�v�h���p�Q$��T���y���wҗs\��}����̕U|�S��|˽,�c������QO�RKV19�q�-Ȥ̂� /*D�3F���I�����YX�=�����x��&�i**K��W�z��Ȅ�D�n်}JmV� ��v�|� �ԅ;��Vͻ� ����7�>���Yůɼ��]�f��Q�!��m�}D�%��]�1����Ե�	�ؐ\&eݜ�̟O/*	� ��E����I��xzY��m��P��>v}6�t�6B�_/��|���T6�oq�E��#���vˣ�Ԅp#?��.�oW��o����1�mȕ��'T��#��ZД����m�opXݙ�%��z����mzCH7���>���#�B�J�$G�>Gң�ʆza	���w��z�OE�ه(�kM��׃t@�hv�^>[��-Q�S+�+O�g|;"��9��J�x<���tΕ�|/�)˼S�.��Op����A$L������Z�6�?H���
� Â����(�e+��3�᫏x�+D<�}G��iU��s"�z��@��caV�:���+O���n}�y�}��Q8�0�I�&�Q/۴V����)I��g���;���h=5�򴂨a�� ؃�<�2i*@����������}V(���YI��!W�9<"�Y�2���r�n���ί�j�_��tp��:\g��V��[j�4�Է�ޑ�/�7�:�MaXxO!l-�H�ž4w�  D5	�P�0 �����e�f��g�    YZ