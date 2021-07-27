#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3156683565"
MD5="40d679fba4cad7fe717bb6cbad9b0ee4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23232"
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
	echo Date of packaging: Tue Jul 27 16:28:50 -03 2021
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
�7zXZ  �ִF !   �X����Z}] �}��1Dd]����P�t�D��~9�i��(iM��1�s����v<�6zB�>��0X�L_�2���Tw�=-�?�*���V�N�9�nb
��j�G��tG�"!�'�;��ݖK�"*�yP
�5�}�8��<�KM+d��IN�4�� �]�xǇ�u� B�gW{���6б�	躴���¥ʣ^I�L#�V1���Nj�/�]s@[��@z��l4,=d�'��-�@�U�R���[nҨ�o�>�T���4�?��I�>F��iU�%T����W�Ƨ��7��݊�CR�VշK�XK)�a$�o,�����-M��X�P{zF����6�󄵇!|bߚe"��0��6}�g�Y�hB$%������� �UXdn>���5H� ����KM�8lN��>W,�\q�˳v�Lv�� ���a���g�"��� ������i 1KN�{E��SXF}K[��m��������"^D�T9&Fts�|����^�˔���De�6Io�S�!����3d[�JI�|���L���"/")oB��o����/�0�\������_/�V�]I����|]�����@�O�'9@�u������/�1�6�{�N���秣e�0D�xm{i\U�LY������<p�<��%�\������?~^_s�y� �H��q�
a+�i�A�Y��Q�-��0��"��AΉL+���U�s_�I����wo���	ǷX�]EP'���I#�X����?�_J���^5�:�	3Z߃�F���$���]�N��m�G��`��ΙB�A=H�*���d/nd�����4�h�O�������d}w�ܪ��%�L�t���G�a�n簎"x����K�aO���J�k�w�U��(\Υ�&�����.�$��y���x�&�!�F�@.�i7��_դ5{,���RItH�<�ę�����AG1l�`�Ҕ�¦���2�x�*"�<�����A�7����b�*�'/��g��\7o�n�~��o��U�$�o�^?�mc������SL�$������O�;���6���d���ƺF�B�m�]����V�1*㿌���^z!�����xY�q�2�+m�0���p�#��ՌnǦ*�]+�6|���`�}�#���"��e��V��|���_RUy��DJQL������S�:����;�Y��_��L�"�u��3n�9��X�/:#��qʢ�LX��EL3e3#Uz�@�,bӏ[�ms�T)����
5>��a&�ypq_���o0���L%y�Kx����%e�PO+��_a~����p�!DY��B��S\[��@5��ە�e'DL�K"'p�T��Q�I�{r�*b�E��"�q�e|כNn��X�IL�S;YCZ��%���`)���n�����N8�?�k@k�]8n�f���Rp8�-k�~VE�nwf(vL�c�[K���!�R �^ �N�sp�2p
�~��)W�����m1��
'pT��,
]t"�XH"���o:���JE�i�Lptnu���zO��VtA>"�({�1�J�n�!ﴩ&?�l%�s��=F��\�B���֎ڍ]_>K�{�s��4���ͼG� N���3��HdP��)'Ⱦ� ���~cWK���_�����N9?	�(层D��x��%���}�<lX�&�ep�����rjMn��Fc8M���w�:jz[�o{������U�m�|���VԜ�k.D~p����.\ޝ�04�(��q�i�:W�Ȭ��Yr��:��iO�cy�d�qm��<��
Ϸ='�!ˈ�L�������*���v�X]B����'l*�E[d�t���ɍg�S�&fh�V�&n�c�VmL4#ϕ�,Ll5���K��HPi�>��]V�2��c^7^�MP�K|� ���ƥ����M+��a�1�����Pf�Z[����ڏ�M�Ln�/��pd��ko3oi��iJ��e�X�h���}Sy��-!}Ψ%ь��1�`+�?��17"��ݾ�v�/�j��C�@9
R�|)��Һ�����L�]	a��'�Jh��Ha�����&�=���C'Р�tP�
#�7n�uA��-3���W/,��(`�W�Z2�_�q����M	4]e��+��7����V�Cu)Pʴ4��c��[�h����(�w�C)�GZ�D�@�ē�Q����NR�*�4O�r@$ �+��@	U�?`�Nx�(��f�[m�82�a����OjBV�D76�Z�#>�a�F�z�"ޟx�y�� ��%r��N��Riiap�����d� ơ6�&�p�i-Fϡ�58���ζ4��Dq<�'J$�c`�w����4%����!q��������V	Ӱ2��|=!*�9���TQ��{�HN�H,	�:\��k�wu�mQj�%Xj��횃-�j�E��p"P�1K�st��9S�W.��]�4�:��n��ػ~��/��KD|�l~�o�����%��G�oIݹ���&��CyH~���-�&��a�ρM����B��X�ƞ���^}��?(�Lcx�
���.�-���a2���A��y0N��l׀>3)� �VH艗?�[��\u�>�ҾN1������鶌��61�)#u�Tm|�'8#4�Xӌ��ⴝC�K�ا���]FBYI�����p�g��{����j���&�G.|%c�D	��p�6�pn�G�o�`z�=�y��Wܢ��B���ȵM)^.T��^L7���t��v����.��97��Y�CF�}�[�KQHJ|���ƮR�C#{D������ �\��t_\�q D��X��
!����ڐ'dV��?�㋅K�x�kH��2[���R}��)!�����;"xC��T�Pvנ1V&.�B�iΝ3r]��:w��}et�	Fٙ�Ӥ}r�2�D<�4�8R���-����\�rO��ϻ /dX�����K��"|Heb��������e.3	Y�\X�,��8�5���~��b�Q[�����'���l푠I3t8R��=�H��=�۴wT����c�C=Xm��uN[f�$���=kJ�G������avp��mg�Oy�5��Q������ղ�����W��_y u\	edFm�E���/M�k�Ǌe����OGC=�AhR�(�E��0�ˤ�jl=�DYS��+Y�R%���$d ��c/�g�SS�L��>u;�Ѣ��i@�����#mz��\�6��#��9|c��j�<�c�4]�"3B��j2V���.��Z��@n�dȱ>�j.�Y�d��A����*t�`��"R���2�ԁ��2�@B���.��P9�E���s���3g�e�]��M��h-"����~�b���7�t��e�-��?��;I�p?�r�X#�y6��b�ų�ٰ..����A��GDP�y����h���8.j�	�������+-��Ve�zA��G�+r�=��X��"��E�o�&�����&b�A@@4�`�Y��)�V��yvW����!:Xk���J{b�I��+��,c�����%Q�8�G{�C�[\3�E=���ń���	���<7^�$|1!�\�a=$�W��kc�̨ \M`�kW�g��ͤ�Ta��&��	'�>�/ᔙ �a�ϱ�["��$S��y���]m��7ҥ͛�P=D���Y�C˜?:�2[�an�h�t���L����hgiiV*g��~�RŮ��̜̎��,�vsiQ�4���^{I,;��3�$8�)��"�����M}�<�3��#P#)Q�Ә�pj�U���k�pi�uyI���=�2\(m3ۙ��(�3�ɮM	B{�����3?����%��ʿYw��G��f�t@��eh�]ɵ^��;�w^��\@7%�|�^g� N�# �Y�@�E��m4�b�Isa7g�4�U�p�d��[�S�5
��Z�DS�Re:	�H�־�Yp�q�H��O!��Ll�j>kneyF
��-�0��c�T�[��Z��0�S�A��W�)K8>$>Z1 �,8��9�wo���	۽�����Z���r��l���棟��R�P�JB��u�y.]z��)����N� 	2�^�8���|�n(��	�E�b['۱x�j��n%?7�R��t*������m~�'?V�/@y&�ϴ�ʳ��Hq��3����Ԡ�*��F�֌>䡬!f]�_"��6��\G:F}�w��`AC7����O�:i@��� >�ċ�y<J�yv絯[�-\	��l/�&���H����|D��/Si�F�UW/�v�O��U~}�tu�jMd�ƣ�<H=fĻ�S{Ɣ$��I��q�E�����>�b�K"��1!��zK�	��΁�^H���2��g{9託���v�P&/DXz��
�o� a/�W�j:�!�:�_�,��Hs��o�#N�v���\4���}ݴ�k>��<&T�j��$K���t�zr��%�@�'���7@/��=���q�=��<�],�}��J�� ��ݞO��a\�ӻ�Ͽo��)�^(�J��ʵύ���_V� ��� (Z�]L``���|ҙ=��d�#�ܴ�D���l��zDaZ8-.^S��d���#�3�O/�r�BT�d��x���8�οm��lbuA�#�=��޷ߗL�SP���?�pqV�k+ ��RSu� )`>���N I�R:�MPq^�ם9�##G��jV.Z}DeO�+�瀕�߀�L҉j����?�c.2̴����/��G|Н�HY"O[�wsZ;��&]��sO:��v��n�����fD�W�j��⺩��o�hĂ��l#��L���YX��u��	ųC;m�C��^����M#�pR�3�!I_��@�x��ˁ��aF	Q����,uWa1�	"
@aϾ�|AxH���Z�;ƁN���GAތ oW����p�_r�/�0��|��X��A��tm���;�4�*9���4�����`W�&:�/(��5Ő�\<8>�R���/��Z�H��lXo�&�ԃ]k9�u(�WN��J��^�^i�{�;�|�fJp��2Ï�g�.��ɗ�)����Ī��xR̋�x�FIb�wv
��5��@��}�w]nx6�շ�z��Y뼔43��8��� Ô�|ж~`U���c��3�N��/Ġ!�@�f��
�@R����B�x(��[��XW�t�r�-v!�dJ�쌁�Q.��19��Z�� C�&	��d������E�������[ϲG֮�V���7xrh&���!�����z1�+�s��Gg��o��y"�V�!�d�Ĺ88K�D{����
~�e����hRj"X��t�g��^z�ߜ(�>��ͮ��}h�h�x���kD&�n�Χ�u|�;9���́�|�G�EϨM�h�֎=�Jt~ޅ���T7y���N��2�<�A�'~?ל��8���N�#��r����ӿ@�#�7P�(Y*$vr*ʆ��q��?�.���
R(}�ěl9�������Ľ���3͠$}�~�p��,��i���H9�l�zP� `�بQ�%"EM��ь>�A�L�%�/�z)X�%�d#q����\wQ�@�c��YV��
J7�̒�bQ=!��i� ,�3C�we��!�0�:Wb�Ä������$e$Ľ�*F���=�����	��� ���*��<�⁂��t�����AP�x���c��^��zq��Q����74�=���La�,�+�4����<�	S���6�"� a���,���Z��80�*�>i�;&rt�̕0Ca�� �L+�CM�U���	�=�X&��OP�|:��хX7��,�b�#x�>�D4ts��ĵ�H�̊k����pW4/`�ͫ1,H�� s�Ǜa1�&}ȗ����aӮ[�Mh��7�/
6�~;�I�3 Qj�v*|wCq�>w���@g��o�,�B�;}Z�G�'��pP�W�_�I�#�?���sT!R� D����
K]�0���b�!��]����r���c�V���u�+o̻C�t~ar3suK�îeY/��SSx�tt��$f=��Y��0�����w�rp5C~[���n�>p�4��O��Ր��	��&�X�ֵ�:����rm�'Շ�3δ�=)�h�W���>�i(?�T�zA	!�}�@�	��˨�������n��ㄇ�qc����{�N��H�����o�m��շ.�'L��n��:�/�;�G@E��8��+������+풊Ӕ�w(����<9Z���N�$a���R��0�=m2	]z��O˜z�ް����d�X v)At\��'�Wu�	��-_�#6�(`.&�ك99C�����A+Z<Lݗ�=�P�2\�s�,�6^��9U[��)ɬݎխ\>�/\8��E���,z���Pg5��H�,�0 {[k�F)�:jhi�ns9��6��v��b�t�Gp���3G��"<�g��MF�<���d�w��r�󫿈r���b�]_Q�^����gL�Z��Ũ�vuz�V�:v��oU�̃���������lu�K�қ`9����$8����"e_�l9�û�ǂf�uU߲tf�a�O�r%���xMy쑅񮛭��z�X�U�����Z��W��R��H71�x)1�i3
T��PAю����!��Iq�O9��L|���r��q��ݜ/�mϜ�Z�׆�x�y�͘���xr���LY��� ����R�k�0/X�[M�;Ҵ/�z�<ь���Ud�Ç�n�:��9Y���F�Db�p7�'��c9�ȋ�n����\��."%wZ ,��wV/�\<zU���� P̷�|8���A��_ݚD�*�����y��e$~�|Bؠv�<�r��h4��0P9�ݩ����I+���q�Pu�f����Q2��ыu˖
���X�K#zAyw��8c��h\�ٺ<џ�G"6G����#w��c]����{��I�|$S�����?e|���7Q�tN;3�iX�A�Sd�� h<Ŝ�A���ÎdI��v�!(Ĝ�ǝ��X��PTGl9:�ρ"���@~���P��w��^Jo�Nܓۓ�ˈr��a!�	�\�np�l�ߚa��TB��Q{��[tI��5�{i�\��z~�'; jҦ����|��1��IB�%�q�6�{ZvM�W-�-�!�3r�n=}E��O�5��D����E!��G^�i�S���[���+1���rƏ�� H��]��P��ج}�I��j�9��ƛ$j߉�����\,H��F$Q�c.ޒdU_[y�.�r:�����s�Ha�.�V�1)	l��,��u4�g�O(��5V�2^(ɺ� �^��W;����P*?Pn��=
��{SJ�z�x�b N�������D�����)�-�vB���%y�IJ��&��P���G������!S�[���qs	|&I}����Divhy�su�'|{��oE�*m؈-��^�w���H��8-'Y�F�5���I����/Q~a��nX�vm��l�'\���I�人5�|� �u����-՘��5�_;!柢�%�^}(čV��D>�����m�^��=N�6�µ�^aF^_�>&��b�Pk�4rt��f@����#�����^�DA���&l��L<�(cj�+��_��"Hv?d��m���}UIDgX
J�B�ߣhIװˡH�u�<8����-�Ҳ�7m�?6x�w�@�eV������{��߳�I)��EH�_HU���M� R?�w�Hv��T6&����T"��r�l���Wv��z[2���b;y����:��^I������!o���-����ҩ=�4v�=�!�(|t5D���!�]�t9��`!�΃�zJ:�jk��b�GD�ةı��>M2�!+�4���Ԩ@�Ҧ9+y���:�[�aU��l��wl6'��I�3c|����R#\�1�|ײvP�����^�VԷ�%#0���h+�����^Gc��A����m�f��U��֓���4��'}b G�?�g�J#���@�:=碯pl%�(��̰���;ϯ!��x���ծ�y�f��C�vNs�^����V��'�̩��-e+7%X����j�R^?U^Q��R0��W\���J��.�	�_�A.��IW�.��Cp�G�SK�O�h��q�*I��2��zJ��C��N�5�״-��
ǅ�<��{k�`���Ʊߨ��T|
D�;���t���r�@���$�B��{E�ג��(����$Q!TN��+���@�ǠL�!�1�1��u�اk�d��x����S9D�@�b3-e;�S����ő����It��{HӼ꾇���1̈́'����M��;�i���?x�h���xA���_���=0(�7F;v�Ps9�Y7oM��F^lߕ��,*�6J��G��ڟ_J	w��N�@�d�ũ_�Ѳ�AQ���J�������%==	���e-�;6/���s�2��
QKw��	4�b1����@�㣄��\�S��R�x�s;Q�t�\o� ����ex�b"���eΣ%*�	{����W���&�?�y�?`S�w�9Ĳ���z��5���A�e�����ʑ܉Q�.��_���Wc��t��Y#|�!��h��Y�3^P/��u�iè�Q�ҥ�~�$���2��V�>�٦�ڽxJʄl�.^vw.���[&ݺ����B�ň�L��|4���m���&c&�2�c^_�S1(�e'.sd*d\;��]S�]�t�iJ�O�3���Dk逸�gl�{d�8�3��ӑî`L����"c	?�c��ah��>rt�dp~���9�B*�Y�r7�%�6�v��8p��w ��/����l�T�o!�c�x���ILb���,�,��<��ꖛ�����#E+T~��va��n����V2$=�#
�gZc�yB$��Ö�&|՚�?��&����h��V ��U�c�=�>�1����ڹ��NP-t\4{���h��@3�O�����]����+5b��~!-�1���k�w���J�9�l!ѿ�0G[o��^6O9+����^"����vŌ����K[o�m�A{�L\�%���_Z�6��k�[��K�����(�<K�nw�%I��������&0@v'ѩl�=��?�ϔʷ ����A������Ƥ��� #R�F�Y����T�����"��Rї�	%������D�}:�'�Z<�i�&b2ɸ�i�y`����K͢7'��5h�H�)0����pNQ٫�A;�}�Za��T�o+�@yڌhC��U�} ���Ȇ���%�]�^��j�϶ ��%5[;X���`+W]�zq���`]
�P�\�q�% �Rq䝓`?(n"������,��d�y\�zև�R8���/�!'8�$�T�4*�έ��)��Ԗ��W1�\J�K�e[�����ͧ�M�"�N���f߱���| I�J�&��j]t��G	^MG��8���?l8~o�7����z�#��>Ȩ��v#rK��wW����eC1Ai�����a]���g�1)͝��_F���ɖ�r:��f�N?تq���;��S�����˯%��8�g�
f�8O$SO�K.�w�iB�=���U�DJH ��s���ȉ�w�W��
i&QѸ?ݼZ�K�����Z�$�z��?��I�^�)+��T��;^=PqgF�W�>_�9C��S�2s_�ӷHf�[�U��=�GH��2���<%{���s�zl�֊3�R�pt�\�==�o�����分§�u���O?ٞ�����<�T���3�Y3��l��{k�����:q{�����lMێ�7��M��5.�i1�~\��]�Y���Cc~�_z6e���W���QЖ�ð���6L�0�����"-s��_��{�,�B\(�����&{��;��jv��V$��.��E��B/NlB�w�f� 7܌�����t͗<8���}�$�9���2�oBaÅu[N�����R	��.ޤg@&�UMh���Tӭ�Dfu���?�r��5�<<�r�-HyL��P��;[J��K���։?%�TP��Ͽ�_��M"V[z�D�2�m��	7a�|$��W�`�Cޫ��������B1)
#���~j\oǞݖaZ�5�3��$s^=��� �rk�������eTm��Z�`��"2�w�@�8�m ��)��AO����8=���M�`4�e�E�+%���n�:R�Ͳp'�f�k���q���/S["*5�����7�Z��u���� ��g�'����r����wQ��%���]�t5����2�
��\	lc�ϳ�o�Z�b	��	�,b46��pu^J�j��H#0�נ�Y���0�)��|F���R�EWSj�i���l�\������n�h!6�Y��ȶ��U�}3���o��|��8��>�eX�?���y��]G]��׮�azh�Ī�����6DF�r;�?��w����j���=]���6��L���@<�3�K}�淜HOrj���#%[�a#���WuSK�O���f��{���M��>s������XĄ��*'�Ed?YmM��W���u|�� 
&�6A��v&C��D͗no�ة�H��:���OD�S7�aVM���~̶ K
�NC-P/��BȠ�����C&�9.&�L��'�׹�f�*��I 0��Bt����
�}���!���I�l�R�뵴h^���p���@�k2�VX�
�I,U&�����%�
���5�G�ab�4��=.�0M���\����M{N12�[u�ƄX{E��[�c�m��0q���']}QU�#ʖ��9���L_O��.V���a��U_gL?|(�4��@��+��u?�1 `�<�}~��<�{|	���nh�@�Zj���프�9���Ӏ5���Q>��)�����G�Ͻ���R1����TM&�Gè Vڼ�p�q�R�@ˎ7�2����	�������1~֮�&#�lL��z�����y����1�k����e�*U�����#��z��ԭ�[��+Ӫ'&��-�D!_�2,��A��NxM�Jx�M=��N��K��F����>�ы��Qq�a��+Y�����_�Y������B���a�j�x4n	_{>��az.���=<�$�X"��n�u`�3�R��u�S�衏�:fC|	-�uZQm���Bq��\QЉ�����FzXX�ߥ�yk�V�A��l��yTl����|�|��~- +��nb�I�6Z�o�vjΕ?	T,�˶B��&�%�+{�0�?��Es���eҥ�{a��b~@ir`p`���Fc��塶�0����Hw'��G�/�=��gȶ��Ǣ
u���C����W�R�`��E=��5�N��:)�3T��LB`����Q�1�&��2:X�$�o@�?���bu��ŀ�NF���>O��Y���t�{�ɿra���+B�]�[����'+mBSd4h#�!���%�3W�
��������K`��7¹EE
���� �ԓ���q(���{�?�h�E�Ve�zf�7��{O*�5�����e;Z���q��@����\@�� ��i�U�i�!.��F�-';Zaqq'3�3�>+���d��צ�!�x���ػL��t�������T8P����h�B.�,N0W�4-_��:7��t�ݫ�6��f�P/wv9�iκ����q�	�A�C�.��3��l�d,* *�a򄇖�z�<�0ݿ������9�J����e�D�s�#i������G�tǘ�s:e����k3!V�(�(pP�����sc�v�rB��w��X�����l�Մs��yF3;)q3	.����(�����g3>d�Z�ɩr�Lm	�b�=縌䓀� �;�(�o&����q��)�1��r��D�O][��S�G������ņ񲣨���_�*֙����Y���3UzؖȄS6V��p	��]����{�<a��gxVDcѫ��:3�J���V�H���
�C��h�4�Ȃ?�9N�����l���`b�YpȺd,>u�&�8����/Z��?>B<�f�C����p-T�h�S���&!��v�ŷ'�U��~�D^,������KtJ�ک��2e޻c+&zF���ͤ"⟒���ey~ՇֱQ򇙎A�����k,�%����-Z����Kn�M��gjP�XJM����WrX�o2�����R���"��Ztm;�`09\��L��k��V'���2y�U]�̟揂7��4_��)�@��X���`��!	�/�td'�=�{�--����A���D���K��:Ä67���{�����sv����&M7zٟ���1��k/�6�(����K��G�� ���&c"Z��%$�t
�z��;���<�{�����i��|"� ��'��������hG����`$;��p>f{r�YL1��l��ڼ��J��G���U�5祼�K���đ)���}g�ݭ���C�p�L/o��X�A���C�8����\9�ɏ���`Ԝ��Gz�P��5��EB�q��B��|vN��瑹����˰�b�	 �<�ƽ���w0�Fg����<>�yr4E�K֙�
{םuY�ΛO6M�hD%�y��ߴl�����e��bƌ��lV���)�5����Wi�c�g��z��&��:��D-z����["��/w� �����:h;N�We�|����J�pZ���#7�P��x�Q�.m�Ǽ5R@�~���>.�5�"�܀+����}@�h�X�[s��ޚCÜ����L��5�^C��^U�]ˊ�#�Q�v?t]E	�x!��BT�1jT{y���W���͐\{~-93�O����`��ݡM��oz�_b��?�yZx��'��s��Uu��?f4M��P`�w��!%Zb��g��.iw�Pj��^���K��>�~�"rn-j�0�s����&z��恲E�� ��FR~c"9�n���O-kӾL=�@���l��+l�� ���z�u�-zfA9Q�+d��q�N��>笸��.:j�+<Q���[���?m4��ŶUy�u����n��`t�2��(��u#҉$ED[�-���-¦4���e��� �WV���M M�s�]�G�n��B~�# �+e,8�-ΜƄ6]�8�RHs�CC���*.���"�?a1!�D>T�ei@m%z��da�Ev=�F��w�U�q�N�x@��ئ������P�־[���_���,�͸��e_����
@ʞb�ʭ��`8~.�F�f���F`�^~�>ƛJʮT����V��2��w5D������E�4ٝ��V�r{��6��o�oS�����8�S>��dx����u�#��Ȫ�o�U0/z@�X�V�)F���塬b~;p�<(n�*��s2��:��M��Ea'ɞ��Ⱥ�����*+	��'�����5%m�岿8������.��DYI�|ֺ�<{I@�/^�V����Za���l+[�/Xő��Ke["s2uW��+E���E ��;�N��8�:U�f�����������<�U�ǽ����č\�����33݁�癈W�]M�,�[l�\�fm���]�~~��Ta���3߼�?C������۞'��f	&O��
O�CI��%����*���Y1��1$�:�ߝ�Mj���U�S�D2���4�N��T q�[r2���¼Kk?Il�������+��_��K���tf�I�)�M|{d 3xs�G����G���vR���9��bin�5�$'����?>Nw�5z�hM$AIq'��Hn�e��o�f4*}F]�\8�W$g�hh�����b!��g�e>�����d���S�y��'gǖ/g%�ጧѪ�����zd�XP��H�gR�-ȢrD�������㝒��<����)�-BY z���l/xv�rh���O���"�痓�)5 =��_>�E��Zg��ݿs�u��Y8�/9�Uz5f4�jh.���R� fhXo���r͕��>W��\A�8�]e;��1���Γ/3�=9�%�����L���(N�wEV�[��F�5�Q��k��s�Y�6��zDl�Z���P���	�ːa~�������  �Z�钫"j<���M�Sm�4�g��$4j��>�.�xT�~C{�+Gi�/יM����{~;�%��\�6��gS�S#d�� ��G����3t^X��8a�y*p�k�;=�@�x�H��U }q�zb9��:;8��*�9�9��Z�G��hLq�#�.�u�:��b0���D�Ȧ��P���kurVhS�b�%J���'=`�����* ���}>킿�|J)�uB9��Z4��e+���He�ɩ��8��S���j��ShR��Z~��yc��d k5��ܜ*�a�� oy&��]R���-��mIll:�K��=í�0?�j�7���v#H�F�v;�1}�pM�g\(��Hu�`"��;AjE��x@���PE���U\Y��M&j-1=F��~IIl�v���*(;�l�Z�YG����;�J-T�T��������b�Hf_��ܤ�@Vߍ,��L�g��âҵ�f�����-@��%Y85L2�5���1.��N9Ijh��EҨ�}4~o/E���Y�5z����{�M5�ZF�rD+e
��#$»8b*å����|v��G�װ�`�A&9��O��Oi�!`�=e���?���(]]yɓZgN, S��RR'2E��lDPk!�i��Z��e.�ŀLa��ټ�[��փ�J�d��ͷ-�g�K��f��<=��A.O����J�������1�h{Ć���.���X~4��)�� �2��N.�P��JIi�� 6�r ���
���t���l���hɒ�D'������Z��"�� � �H��P��o̗�y|\����HR�sx��#����}W����o*Q�4čz�G�Y(_Β���Y�?U��S�u��XM�G!�q��2��]��(�!�h]�%��<6���.>��k�6f�Eɍ�����H15���Dٌ�?�Wzql])R�{� O�㼀�Rȭ��Vco������]~�N���*%���r�tEy�t� ��(���_�<�q~gC�My4�UOT܈�{�ErI�9���s_C����U�!�'�oy�F�� ���Y]����b	��׷k1ժ���m�s�cg�p�ݷm��vC�a�/�P�8�o��=i�n�d��[ߏ Y��4%���E}���m�@���I��1��4�
X���ph�$0
~���n�T�TН1�� �&�z��v$ڪ���rhJ�Q�.6���/�K��i+�#��Ŭu�:��$#ʼ>��%����w���M���\�6%Ǥ#Z�pJ��x�?��!�`k�+6�0f��d=�{j��Uٔ9��B+3t��X��]��]�haU����ʏ��	zh�-�6ǁ�U�==N�ΟY��.�Li"ԓ��&5X�p0Ҏ#xKeȾ31I�z���9ϟ���KsJ����>%4�Z�Pi7�x3�ﲸ2���x}������@'�9Xf�����9�,az����^�/V�-bΒQ�8�	7ۍ�Pw�Z�TP�� ���n��'�Q�(�y�v]t�������8�]����f���ĵ�G�{���l����B[f�o��~���A;�ebo��w�G"ٶ<�ō�8<t�b�S�Ȧ�*=L��'�(ϊ�qj��F"=�����W�6���4�Уg�
}���&�<�������#(�k�����y�(#���i��p��e�3����;C��Һ����li��XRYP�+Bf���E[F��Z�{c�\�c((b�C�c/�	��j��GC�w.����bޠd�)*��y�Rl��C�/Ny� 3ܳ�fq���Y�ܷ�*9��<3[I���= ;�<��L܀�>�d��vl����6�LI�G�0N�]JbUm����Y�2���9���wq�?�
C�����8���W��+�[�]Ⴚ�W���L;�����e�<W�|�����ׯ�����I�XQEi�� MVm�a�|�*��_Xp��M�&Ί�ZZ��SĘ�W��?X��՚j�^]���A:�`�}n��)H�p����+��MIR����L�ȥ]��p���C��fVחaU�^p-e�`u�L(�<�=�� ��Q俔�yN��R�o�Q?�Ў-
9H�P��!s��*5� �4%u��L�ݦX��<`L�2�o`PZi	��)�D���Ã��O[����G�m��6��5<QӃ�)�4j�)�[�0^��Z7V9\�1H�U��qQ�%>��ڻV�U�G� ��D�W��2�3�a�Ft�����}�j�ݙ45*�7t�Z�D�6��q<����wn6r��򛝞>���܆1�F�1宥����J��F
}�9�z0�-�KB7�C�����T�}���rڿ��=,���h�C74|~l0u�8�u|,�X`��/�lP'��AE�ΚoE��'mi��˱���% zC�j��C��W%�j)�y��n����d���o��!1�v%_��j5;��#��N��H�� f�e:T����`�Z��A{,�i�O��yz`�F񴙂/]�zX�XT��v��ǔ����Rt����.hH�׍+1>1��\^(�tb�n����j��{n
I�Ȝ��A��������5	�½%�V�az�8���.mʉp�%��=:3�b�P2�3�Y��^+�%���1��v���x�݅zt>7���3ô/o�ԉ�_���6�&9����?t��Er��C��t���W��(�(�l3�Ԩ��d�&�B6��?X�B$����`���}C��.��U�$�z�Gw���l�9;���$�;�(R�����-N:�A�C�g�Y��K*����#!��;��8�ۉ�e$��W�B�*��ӣ����J��m�\�=_4���x��^��i3�7�(�m�iR	a@�L=�e�Ί�>$���}��1�VV?$r�ɜ�C��2b��0JjY��j�����a��gS'Seb����o6_-�.�vz�nq �5K���Y�`�5~��w��i�k���
�S���Ν�B+ז���8��q�{�zDt?��?�T�mof&��h���#�5O��@y3�)P����_�	{���d��r� ���Ց˒�G�Έ��C�����/@���/}|�BOU�|A�_�p}�$�J��2V�]��O%1���ش0�z��	z��w���u���t�F��cՂ�8FYD���1��7\��yd�L�-�[��|�Y�xyF�T���W��h��XO�/q.�������>fba�#��"�b2n��C�ļ&Az����ڵZ�;5�D������NdRL����7A�_�D�V���T��S�&t�ĺv��7���8��lf�Ts"�h�s��n��=(���˨�F��2�0����a���˲��=�|nȯ�@�e��wqAF�;w�S�]���h��,\ۮR5��^[+���O�{8�}O�'���
�6����ꀙ��n#��e��y�	 (��2<ˁϲ�9�KQ+�K�X����,�^��$�c�ٍp ��DhMZ|/��n�G�Ng;e:;J��fcq�UC���/6i
#���Н����F ���h�7��@��w�:���Iq��q�BJ��
�� L�?<�4�V�}����}B��4�0�{����ǢMD:ܟ�Z��F�mNM���z�<zz�;�.2�TP⌘&��}����L*?����锩�ഺ����A��v֋��1�	n"���L##3w ��\�ٛxM(3%��=����<⁍�w(^���x@t;k���;�;�����ǹHcQEs/�S9.��@��	��5�5s�zY�W�����|�Q�d���Ǡk�u4)�{����(�����D(�?�_iY�� ��,/ *�_cb�vp���34<.R&&C� �~�6�tM��Ti�g~b��NݻA���5��.���~Mœ4h��2)=�B�$�Z������$&C�w���s��N\�p%�|�@!b�a���,�vަ�g���=�{�s[p� �ٓ���j!M��;0_J(��G�oX�I&=�텻X{!��Ҽ9g��*)􅘛�^/ýJh�/����ozV�o�L��[po��MR�ΑL$�m��n�`���*��JR�t���5cI��]�4X;0�;����޵���rb⒕�k�k������VS���
�!�7y�T_��?��B��e������!W���nϳ�Y?�`�;õc�^"X�5<8#�.l�Yk�������hCg,1��R�s�����<p��ͻ�"�\t��LJ�uܤ�SU���<0��j�zE�V�_��W��(���j3Δ& H�3?z/i�8hV�x~�˘�ga��F��)y\�,��Ү�2Y<��>��FuZo��5�����~�ϐ������R+tp�x�����}�9�;�^�
q�W9,���T5��2H��Ɯ�"6�#��s�k�9֔�U�fغQ+:F����ઠ�f�Z]d�QA���a�#�¯�@�L��B𮜛t-z铓�΄yVX��3KyfE��;rP8���	��<����L���A�?���t�8D�~K�,%}������JO̠"�>�6�&jU�!�F6�q�U��w?=�]nHة����	�2�?I �ô�8=@��n�PZ�-�����i��~1�z�R}�*�:�ף���.qCF��Q���ۆL
��m��-�ݟW��0�e5��@�d�[Z�-Q���Yt����4�^+w"~�ag�t���l�;�Ӓ�>�Dqd�e�$���al��])�\:{^U��ub~�i����'�a�Tl��|�8��}R�YoÇ�k̩&�ڙſWSH������1���D�s�FL�&,E���U+�\9 +24G�O�y�
.e��H�F�=Pߡ���@�(*!"�ì���F�\`k���y���}m�i�HNl�?STMM�<7���	�/�b4u>�����f*���p��{�i	zO.��xRcS�Y�Ǔ�٠�Hݓe�S�H��uE�IpҾ�#�~%"�R��Ө����?E�k���t�h��ܜ����f׶�T�q���`Ik��U.N�������T�C0qc0g�2��Zp�'�{��W����f=[�,������̫,���࣑�Q�JȬ+���c��E�w�w�s��oZ�Q� *ndA3buL���?1��6RVi��C;��#�]GJ%�u ��f~�C{(�v���)W!x��V���S��O��Ƹw���h��^F��n����o`J���<P,v0�^66��(mƖ�RN$���2���9l��0���r�s;F�#�U k|j'$���^@8��smW�)�o#�`یň��V .�\�D'�|���Cap��C��ry#�U���]w�|q��KAR+�Q��������T�Y?ah�������;������
1�쮫Օ�lJ4�S@�q�=��&U?��A#_
�/%��C�bI��u��1�{v�i�EƤ.���A�h��K�Xu�A���i��=\���������Q�uK�kS)�>*�V�!��8�ne�|$��.$��}c0�A�l�ė�͵i�Wz�#,��>�I������1��{����[$wM�.��>���:i�J�QAJ7�H��:H_��:���g���C�c��~#���(� $���Q�9��Oܔ��i��R�q�2q2��U���<~�#Q�l{��V1� /��m��Xr�Y���N����$}ZQ�"�q5���̂;k�]�Xi!��4
�$��#��Ϣm�K��f�s�`UtG��ŕ� q� ���$���:_m��ܦv���E�� $t�DY.-_�_�3�3����Y�r�}�Z�I�UHL��S� A6�+�_�pFmt��K�He�ݘ�v�wfd�x\���m3w�?��"��i�߱ ��	q����e1&��Y2[�IϦ9�l3G�pr,c���Ov�ѹ"��<�����hd�0��ٲ�$*mU2`�W:˥s��M`R�><X�8y]$ +�}mA�Cy}�˓��@���J g�k0����Y���ԡ��/�Y����a?&��8H	�h &�h;������t��9j�����ÿ����}xj;/WW�k�b9
ƀ� �[��{�.ii���j������a�ܣ�뼈>�ꣂ -�<�ŭÖf$g��h�Q/�+LAk���r�>��:ޥU�'�l��d�w���'˾�#�dT����ua! �Q	gV���TD�	��I:�񖬐������)��y���F�^��i�{���������#&_���J�tA��� %���|���O2���Wl�� J>A%�b�f%͙Z7|��,?�	.�ۓ{�p���K�`$t��X_ep@��zK@~�2���+4R_�?l�)��CA9�֥)�a/P�G���g.�m�RǮ|K�n-n�7\`rq�_�ӦP(�Q�}1"�^u0A�J�n�i�� 8-�ؽ���(�{�K_�� r�XD3c0q7�[C��_����2�NJ�^��2������8?�c��I�BB5�[����R�0$�%��
�g�:�#�����&D�p'�ÇV�� �fa�[	���6L�d�E��j%%�d���/�Y�>�@n#��x�B^�h>�B�����o� �P萐?P����M�L�3�P�)�~T�]Z����E] �,@Z�5Ǎ�_����=M��1d}Yv�f��a�$'���̟0EZ�_7px���8V����P��$@�u���;',<�=i�8��CB��U*Nhm�~=�z/��.��B�L�2�?2ߟ�<��_���;��E���1a�ےy��𿲀��bF�QQ(�%���0Oো��S� k����jz�GX\g���?3X
:0�I  �ѩ�^�;4�G��3k�I]o��0";��)��gC�r .w����a+�˲�V)QB��L�ߎ�5p��R?D���!nʤ�:��V*�����~�o��yK<�>D^{kZ�V�����o�N�z"�&���)��&�֘�[�]fԊ�������T�n�/_�ڪՃ���>#l�:�!��Nh�o	��|s�M"��v�#ؤ6�;�B,唦��I&�����E|���L]=�g@E�]�7z���ʝ,��U{�9�_��	�arf\R)�(����[����ȋ�2���jFP�(��ѧ�֕3���_uLSl��v��������*�WT ��%0ŏjp�S��j�a�%��(\N n
\C�*�9PXV��b�Ԗ'S�w����,�X/�7V��Ϝ%>�Ј�_�	Y�+�'��'�������~Y�,�Y���͖Vt	�N�?D�U�D`�Z�N�<�`���żh5̣U܈�N�������<�� _R��]�[e�lD��3l�9�����(��пFw�O��:I��e�k��(�,��TԵ�:�������&\c��g<c����`q���C��ک۠���a�i�c��Q&��ZlN��>U�3͑{�t�s�䌍6�\���yX���#K�sC��ɇ��Ze����� QO�v�H�5�Fݗ��t��Tա�T��'���E2^7�"�r�j�+�Ь;�N�& �-�~
"�e�4"E
�=2H.�8�j��V��-��y�.��K�X:䱩��6?>�:F�O�u�
L��/R�.����p���RJ�WaW� =T�6�ka
�����'|h���;�jz��^�uW|�
�g�f���گ" ](b)fg9-Q���g��-{4e�M:!6��ނ�GH?I�I`*��&�YW�Px���n(Gn�d���b��<.��4���X�Zk�@U�,�k�t,��y)jt� �)�X����M<�P���^���;zs����uIY��T==Jq�S@b�5�����.��b �=�f}x�=Bn k%�"vq6�1|�Ai���F�2����3��w���|��L�z-#9���s�-&+Ó$N�e�n���?��&�H}y	Þ$r��gψ�Pg���ٙj�H��u�
}9ܖ���o�����8�%��KF �S1`b���={h'p<뫚���3�I��R�X*S3��N, >7���k!�T[ܦ5�!=�O(�t��w��<1
O�1�fآ��io��4��c���zD��\�]r���T���'�mҢY)�nj�, �>θ�yuhU^&��L����mDTX��<5�ZV�(j�-�h\��]����P�\���<�J*���1tJe�,����U�Sg��q$G�s����Y���8�?j����D��9���G\�}8#xeK��*����h0�k`���k8���p���j�/V^�EE=?W7�)���o#��KVg)��Պ���;�)�[��gH=�s�l���l�Qv��3�1�;�@/^w���4�4��mqq4�W0�`1�
_�e�#唞`w���f/�e�����(zT3� k���C�2�<o?�P����9��!|�{���V�!��~� �!7ݳG쨶aO�\+7�i��f�Tu��&�1d�<;��F����L��O��:wgƚ��&��@,2fDF����7�(�����`�`?��Le|�6���o)/L�(���_�!�)�EkX�m�yÉWY�j��7�@�1�RP��P�MRى`�ػZn�%Џ:ݲ�ī���w,~��en��H,DBW�8���%X"!�	0�v&g�t>~ب�f(�Z�2�ی�h�p%2؂4�lnI"��L;��ń����#�
�R��XR     u����� ����:*-��g�    YZ