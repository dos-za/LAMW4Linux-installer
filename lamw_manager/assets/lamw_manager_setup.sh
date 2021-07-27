#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1076325429"
MD5="53cd55411db1e25ab44a7e3cbcbba775"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22944"
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
	echo Date of packaging: Tue Jul 27 12:29:05 -03 2021
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
�7zXZ  �ִF !   �X���Y]] �}��1Dd]����P�t�D��ub�
Cr���OK��-03l`vh؁�IO)�0E����\a(o'ľ$�=1+�����$۫_�ʧ�	�Շ�f�:�ji���4��PBd��&��?�=`L0�[x�W1�ju$���-��	�⯌ޥ���Ø���I�s�h8��V <�{9bĖw�a�ү��x��D���2�}pn�R���(hNk��fPB�韠�\���8NP^jɩ�c/4鶒�u9Mߪᡝ7Шg��@BW�}>����i�7���a����V�49y��|��o��'XUqy�Wg骟S~~�~�����A{)����(W("	I�B=ۑx|GX��}��8�	7�K��ϯ�����zk7rN�RJѫ�P0Xy�[^m�4��ϭ��f���e�M�ϣ����{�O�M�&��Т$b�.�[t�d#;��y=ږr�? ��Ӛ[)��%S�pll�H�J�\�O�WVUĻi�尴�U}@��y��O[�DSQܲw/�]����ѩ�Υ���$(�A��0l���s�7��[n�L�����A�<Un+���[[[F�L�z&�����C{-?U#K�X�����4j�Uq������JTSu�=��RW���m:]l�M��������\���0(#��>�䠖el��K7�RO��}��8$��b���CV⍔N��D�BH�����h�s
!�Q��]1��P��z�U��,f�A�(ȟb�����0���"U4����3�������e��zއ�ܒ����� n�jR��'0yYK��P����!��^v��v�z���O�7�x�Rl��dX��ޕy���5E��G���	<h�(��4��a�����8��H�$�#z�*����ؼw�miFԮu��T�Ɯʼ�X|%���v7p��� �H�V>����]�|�����:�D�8)8Hs�s�A�\���yў�=\&��k���C9Qx�pŞݭi�%x �Z|Ҁj�'M:���Pq�g�!ْ�2�ƛG3k=�):h��N%�KHN���M�r!	k�� �0��!����P��ަk��x�9�|�
�y���?��ؐ=$��Pu"	�ۙ�
n'�_�7��jS8����C�i�W�w��7s� "`٣��r?�����!�����$.:J!8E��d� �V�s�[��H��e�y��+���AȐ\�����̣��c/8W�[�8S�y;�@�[�PI[Ξ; ��o�Y_�hDR@����*
�m`ن��1����x/�5��5E."6�_0�EN.5<�),����0�$���X3DQ��X���	�!5��L<����򹀖G��G$U�=t{��.j�	9���ՎOFw,�X�Pԝ'D�=����2<BZ�P��1�%��[��z���
�<քF^/tǗ�s<����1�6i�?;@?���i��
>���OU#���t����d!X*� TVS��+,��=hpk�~?���쏮��v���I�*�_��v��"$W�����<��ϳ�t`�.$��/���t�����T�Ftt�}��)|b�-v⡟�n���r����b�,�&z�(h\pP!�c-�R#�!����m�s<��v<�)"�B�>�]�N��B�U6�-@��em��a0�;dnv=\�3X�yiU�wX������|���<���*I�p�� �!���Z��y�K�jy�/�����.���E������J#���`Z��r���3(��2��1��-j�{�SQ��d��(�Aht��z�r�����7G�K�M�ٰ(�/����v:�ScA�xh8�|���Ԟ1��'���u#��?�+��0Q[�5������z%V��qq{�G�Xu�baVr��$h�?���ml�gI#�B����m��a;W��3+�����;�YH�Ţ�I���+�:A�$�μ����ʰ�o} ��~��FƌD��e�^�G�0��ԟ��Ȟ�:�p;�+�J��u�J�݌�[�C����}p���wxX��3�Hݑ�&P~wI�(#���֝Q��c����=d5���
1�L�1ܳ�E�P�����:X��$Ǘ�m���Ъ���܉= ^��*�p��Hj^��q�N[�$�&��v� � 
Ƽ�Yl�>F�֬6'r#ş����9�!�X����%�!:�ӥ��f���v���o�y����� ���q�ۃ���}��6M<�"��B+�wbB=���<����_��t�_F�0=�lib��@�b�*�/��@m�fy�`^���F(z�q��3�u����ԹWI�2],O~��jt1U��-�7�;7��Y�qG��Ka"�n��fT��V��ok��:��&G'�����闯F�֎��vrؾtA��(2��e;J������m!�ӑhh�%���z쾺Nť��[z��b��P�rE${�E� 5�Q�c�0����*��.��ї��'C��&J~ �N�������7y�6��3�UZV��O�m�z�-��� �v��j[�>(���)Y� �U�\�S�&�@Sǹa��d�[	n=�G A�	����p�^�8��S���׍':_�gP&��˺%���h���Щ{Bf �z&J^u�#��aE�����Y�}p��B��Ǩ�2@��$���%�q�*�%j�������A�;�4_J�qC�H(���ÆBB�Jǣ�Bl�zj��ݎ��hJC><���#�R�yP�p�{�`�-�E-����t�� ���k_����R�-�Ў �T��#Ŧ�=�#"�Ł��7\����/���W�����GP��N����gCv�&m��y�i��9�kishe[���%~��l�=�3�i6v�z� ������m��.TJ'���t�u���R K���ޓ?.�����+p��>�������[�>�~������á�Ǡx�Se�V��tV%��j� ��u,������3�8oD�����)���(���r�F˂�M��'x.��������ƒ���%�M���r2G������[v�]���$�MC�ٞ���1Gw �ػ#�X��8�o_Ei]��+�xN�n|��]����%��n�#�R�~�Mq��K��aş(@��C:=�!j�a�c���onZJ�%��_d�����P*3����^J�{�t5�)9�
 �jЪS��i�V�m���� ��(u'��	�j�0����!B�=&+9��0R;�R���W!��J�vg��6�4�x�4<������|1�ܾ ]���Z���JD���%4dK �a�Y��S�a"L�{}Ͱ^�ڮ����_7�L�6��*z#�T�'d7g$����G�8��6����ē��X7~���~���	�.M�~c��1%ۯyU��fݎK�Y[Ņ͗�$�hC��%&�i��s�i�`:��Xd��L��;"�j�Wj�Hġ��G�IZvksw��o���nFa�ﰉ��%-x����Tm=au�YKo[��F %�V�nRAǯQTy�S�}�Ϳ@� P�O���2���G�@����ލ�U��`~����%nx&%�̵��͌x[Q��k�Ȩ
��ު8$]���`���G��������dTX��d�)1o&���E��[?�g�z/���[�;k��$�!���X�	�0���T�r���m.�qZ�eQ���h���r��o��S�����׻��J���x\|�l�)#�3e�K���]�ո���N��u��b�(��
Bn�R}�(2W����o810���-@�H��G:ć	4�����g��v�c.�����?D��XgB߽�}�ᷝH�pq�t�jY6�#}0�HI묒�knX)��	��&J`�����(��~�g}j ^��f�F�4�H݋�ׄ��"]ٽ��hk�}Մ$��V=��"�i�IPۼ��r��|�Ϗ��+��7hW���G�[@B4Ȧ��L��I�MC`j��kL�;��� )C�U��wt����'�7�(�s�M���q8	ǒ8!H��P���y0��V���wh�Hn�ȅ���3�Z$���?4�m���Ϸ���-d��5��0V���ńE��������2�G����������� ��s����o'����*و�J������Y."�N�I���/���*�ڝ�X��)�@;W	��A%������� ]� ��A�2�a������d�E�� ���L�*���M�W	J'���1�j%��봰i�zo�h9b�a��M�uԭ5��Πw`����.0��G
/�Bo�{�m�����F��R�Jš?+X��T|�����UP;
CJ��!uw�}��D; �$��f��$��ϯ�����)�|,���Ő��-�a��x!�����4�7>oJr���T[h_��
C��r
W�㫄��yڀ�OpQ>��[���U[65zw�g�����t��>���d����{ڢ�#�-k����-�L$X���|-����Y��<�n`,a!�n�S^�[G��]�-�:�+iHŶ=n�e������g�qE�7�h�Q�r����}���dv fi|Y�xe�L(W@w��tT����[u�j	�/��%���U#�KI�_�P���-}A_@��1>�c�~��j|�x�I��C \����rۍ!�Ϥ:Ğ���܉3p�l�k�9U�'ќf�"�~j��B%I��G��z'PXq�,�{�\�7�F�������)�R�``?P��V�_���n���EptQ�ё㬯0�-B�)PT�<ߝ)�pD��<<��h�0���' ��ɐ[N��X�8%Y�#e��:hk<,��c�.����LNO�nq�)�Ɗ?�5x���14&�s��I���;3o�����
�r�*i��(��x[�1��ɍ<Tqh�diN����n��_��A��U�;�����F67I��X/g>t/h_|2Mt涪��R� ˉ���"D	-A+���e�e��I� � X=�#�*��S���.[�G��'���r>�+*��&^���c��¨Ƀ������l���R����,��0�^��k�"3�l9�f��GG�B�A���,�3�J� � {<�@Z<1�}���rս��77�^�F�NA=�J����n�6���~%m��n�@7��e��X��w�H��~zt��pI��r��%����~V� �*��]���ܴv;�r���[�rV�L�T	Љ	�{8��׳�J>��J7�o�x�����X�x���jD��ⰁE�̿�<mZ\Kb�sA�n 0$;8E��&��z�+���-հ,߭b�e �?�@��k��u�l�,R�V�'�ń��V��"`XD�C8)U��v��Z�7����� T�(s�;���CHI�2T�gw�fs�14���p��������\}�"<Z�����I;��e���K�)���|wI���憱�	ƨ�u�&5�sc
��SZ�狍��ء�Їd�1˓Q�H�5f���Ҟ?qu��=���9j�'��ڇ��"� p4�gu�&?z���$���l�[f',[9�گ
�{IKն28�����.%`���%�a�|���DV�p@�}g�oW@�zĪ��}O���w�՘�6͍z�������QxS�h&!�h�;� .�O|�2(�Ӑ�T��G�4��e�K�KY���f���m�H�(�i=����V���xc)�ȡ�O�����T�����f��)1�V��8��bJ��B���Q��\�3�Ὁy����^��e���Sc��1�i'����	٧��nT���:�>6q� 9�R��W�5t�P=;lgV������虪��~��pɝ)jL>�p� C׷g>���p���Vč���RG��LF^���լb�fg��k���{��[˥qS7dEz��n^���}-�x�E��r캴"�z�.�[�����-r�5,��B�/���ٻ����*�(i�����34u� ��2����H��b�F���6pY�[�p�ԏ�A�2����cR'�����(QR'C)��9��.N݃(��==���7�|R�"��~P�>��� N~Y1b![\����w����ƕ���9���cOc����E�Kv"���e{�L��ڷEf���<O��{������C[����Q�9�[c����f�&�R�8��)g������Po�z's$Hə|��Ea���T鴌Ԃ��Y��!|	Wo;�:C��oT�>�x�*�]I^	,�c�'�z{����|�gp��r�	鍣+�F�y�P���c���e="���R=o�I �R"lN�ʌ�ɯ$7b�	��FE�d��u�`�F�uf͗��E�)�.x'�-y!��`�dE|n���8A�-ɄT�/Q�a�a��ؐ!G.R�K.ԕ�������_ͷ�w@A�"���lAԜȰs��̄˝I$]���(����>���%�Њi���k�gb���l��(I;�cxyKyh��>ު�]ĊH` bP��b�4|��>�E�B�9&��	G��_f�u&W# ����q������eo��
��]]�x�Q�Vr�Ì��x�Ȁ0h��i��aK呑��I�D�9{6���rzˊ��ׯiy�kR�������X�HBLՍ,5Gd�T^}�lv ����l�~TA������,��<��Y���Q( G���(�;U���	2�cL���+��0��.�Q�8ĕ�D��e��6�Z��`?�5S�l�%X@�W��>h�pg˥r6(�e�E�|���vÕ߄�'��ExL�����]`+7�Ō͏���4?hr���/w�Dw	Ls�2|B�����k:���Ep�69W�*#���u�Rl�N�g�ʝ��fs헦�]s$/~��#�r�@�B�_
w��r�W|&8�i\+����D���WP�o/���w� K<w~g�	*��j���S����B������m
�{�+ǖ��ωn���������6�X���%��
R�+���O͸8���*_(!$�vG:\>�ʔnK��h��K	�����L��܉��F�J��43���yw�	��F֝Z���;J��V:Lg�%���R�Q��sX�@e���7��ȥ6�L`'�ba-r��=f��5+�V��Afު1&~���j'dZt{�b-�����ܸ������������qU�(�^�"�O��n1��29>؝5͑T�٪��vHy�iXn���)V;�����w��`��)�X���s�Qc�	Ux������6_?A��`��L_a��`+
����Y�����,�t0z�˅
��D�RP�B���Z�[�;�&9�1ʰ�열�5x�˟I��h��$b��r�7.�7���A6ѩ<~���Mq����z8���C;wr�����H݄.�cN�<pZ�\	��b�T����W��8�Ї�:/*�ܓ��)i���_.�gC̳ {Mdp��,d�������z
k�6�T�q��28�Q5��X�lX�v12֬�����rr,:�Ώ������UjF��P[5Ě`��j��Pm�f��'0�p<}Ů��Z<�BX-C:��r�e�w�F��� ����E!SdaĆ	��G�^���J���q�~�􈛳@�6�i��2���↻��I-a���9�XaA&{��82�?w}�������pC��9ů̈��簇�[�0BgQ��r��{I�h�YG����5��k��:Sض�B��WMv-��6ӷ(��R�^� ��&5�����OT��)�*�d��1\��~��~���L�c`�Ɛ��H�g�=F�͜hUS�o�� �Y�E�_���s84�]c�,b5�R��qv���NY�<�+UPG�I� |�����e����z&>���C)��Dr���D;���o�u���@h������m�&�.Zw=�!1���o�ڋ���~�eQ/K�#Ё¾S�����n��t"T��3x�4��jeP-(��s��@��=!]2��a(����M��6L�lI�\`�Mгv�/��QlŒ!��@����)�KX�YĔ��u��"�/���BX�����vH�hzڊ�>ݻZ��/Z��&8�ʡ�2m��`�M�B`�a�
�]�3@���~��!��|pNXˍ���g�W�c������|��5�v���럛��������{c�m�����X?-����MҮ-[ӅҴ�B�x�����G�ǔ�"����j-�I�B������G��=�"x�.0��\��s���&�_#1|TX�gT�1�'%)z1��L���2��㥼XҸ
�}�4�`e���b���7-J�i�����Xp�>Z׌s��-�cEx�^W���.���+���p�s
�:a��%��x|�c�@��̄Boz���D�Ϗ��M'���i����ݮ��V.��j�X����l�cy������|��)���(iFE 0K�N�ݳ�]��S���Ƽzd�$��r�6D�'JA���r0�\�@|_ׄ�y�[���W{�8�T�OV��	����(����0'�m���Xqt�U��f�2638LI(e�4��yil50�ϭ,Xj@b�^��{�:���-����VC]��K��y� ǎ�2�sF�77P��?�_I*��'oQ�I������PPޣ�UD�d �b���X.K��z�V�E?��*��u�;���Rz[�񵛘"�c���d�6�;�EYR�����{ig�&��/�
r����sB+bs�J⋛��i��p[R��)@c�%�j�GI�P�rDO_��,��.-�3i����k��9L2S�,�|K�@uT�i]�_��g�7��t�`�4����[,4�*0��a��U�˴���G	J}�cR0j��Kj9k{d�~��S�4��d��nr�G��z�R��&D4��]D�7]��E�b=#5U z8w�f]Ϙcؐt��T�MqL���p���la��G/)�͟7��h����r�$��U��`����:Q��g�:u���Z���Q���Z��^�'s����3�ޅM�R>K��e�S[��s�p��c;8-֏�;0f����2����^���	����׋��d�'��ϛI;i���^���s1j[�CwL������hX#�Ks�β+��磜%�b��Jb��J�ƌ����L�&�M2�˯��4Mt�~}&xzK�� �����b?g���sL,�n�Q("���>7�zl�&��<��Ȏ�o��ʗ��d�Mv�/6���{�݁����Ԫ�v���}K�b�姐����:��Ņ���쩓ڷ\e�J��`��h7�fc�uW�n�c[�����Ĕ��
*)�vx} �>[�GIFP���<�e![m�(\��U�<��O-��6�7c�b�_��<���$�R��?` �i���"QjLa���h,�6�,{~�����#��NZ�|);m���L��)�6�"ț7��V㉴���=�2�g�37�4�q��>��=��pͷi�s}'u��l��B]a8##9�?v3i���4�pMV�-�yw�Dw���K¾�� �g����f��AX���jԿ�	�h��L:��;��T��W���<���iYb�+�!h��=MAc���ҭ�M~���W���"��ʓ��,t0���e�m�2�b̝1�m��׌
S��vyM��� 2��k�v�vI+d/z����z'S뮦���TM樌�8������.����
������x{�'�CH��I
��E.�b���=��:*��EF�>��0�>�`w�e�ɴ�H�ŭ<>$b:�l��?�Vn��;iG<Ē#���b�'�I���Y��,u���ϥ����c��В�� ��.f�r�,�W�?��XM�}�e4��7^	8�Z{��H���5�0�C|d��:��A�%z��33�b}FK�0��=�?�L_������aA�H�1�&��$��"�\D���mv:���sg�h+��Y�Nt^�������gK �6�'!,M���||�7w�}O<�qw���c�cJ5�J�&$Z�2k-�����5���ʞ_�iŮ	ī��R��_i*c�@n`�!9�E|{�`�O�_q���٢p{�?l�~mos�fg�§\�fT%�b�B��:9��jｕ
��.�®T�P<i +�mMZ(�䖸�?�\Bs@�5� �d�.��ʜ�l�N�Sp��GIR����U�Tn=U�\�pP�yg=9��o�L�P;����� �*�����;���G�ҟ�*�����#�9�I?��h�N׆����Ǫ����[���r+�2$=֞%������v�R���O`�<j�a˻Vt_WY�ږ��߱s5A3�l�/��}Ͻ,�!���,��1��C� J�r����©����@r�iQu1�F�왮L�f��)V�E?']�*U�m���w��:�:�u�+]4N��/?c}X���$Ĝ�9�ع�u�Ԝ-s3z��� �R���O$� 0!��6�w�ußl�n׽J���e�&W��*�"8;-WK��qZ���}�[�G����vi�U�{PS���Į�H�m�1CU*��l|�!���Rd���-�*�������.)��k�+.>�B���@�����r�c"�6!�i���>�Y��S�{O�'� �_��Z-	��)l%l�$3� `7:�=f��eSzK�ͤ�~������`#݊�u�&�Fx��y?��T�L���0UnU��a+�\&�Q�*�Io;���yS�"n�@�Ӗ�^���n�I\^e���GË���?���g�\T%9j����S�a���߱*��@�#��0'6�rY �а��'x�Yx;b�;�.m��@N�^��R���_,���GϠj�	Q�y¿Q�5���j��3��)u�|��YMm��vz�3�O}���C�6{��w�d��|	��QN��#�2P}Pˏʊ8(&v�ފ��)a�([1!�舊-"mxZ:�6˲���W�bjdf���~ɭ�	��� ��%C�_q��]Qk�n��a��qB䙒���R�����~�0Z0K��d8��0}�N��NSs������XIeb�E��^cȥB�*�GG&�؅m;,R�Er�8B������:m��}���=��@um�S�g�i+��_	D��,9�R3]|�� Ȳ_c?��ᣏ��q $xW&���ȸ��8�.8S1%��.��D�k�C��������?z����'��bmaȂ��J$�\�h���ZԘ�507��0��ů)Y@��̰ԋ+;j�a�����	���P�u�(�
�n��c����őS���p��T��^z䱾hQD�V^�n�����|�Fm����V��
%+��UM�u�^	�a�L�1��~�'	��z.v�_-?eb�j��o[���۝�`dV���['����V֥.9R�V���{;��+)��5�OhP;�?�j��ɷ����M�;=�� K�E��B��P��у*�����pC=>sNj�PD�P\���T�ˊ�k���q�5�7�a�}��r��
v�B]�1roE�#�q�m�����p��?W[�z.>:���*���v� D��I� �r����_H0`���z_������-v�ON��C�zK�=Z��Y,q �kP����8o�)���m�
\B����l ��ջ1��M�Ӗ?�
�ի�ٓ��5�d�s4�vH^;į�o��i�eu��"��gô��h�o8�g�*���y�71����hcS�K��8��]T����}������p�̖���tb��B0 ��m���_�x�b�{J�J�n9	~^nۭA�i|I������ӷ1�V����3����|m����
F�~�-q�Z1pQ���[&����+��f�V���R�������ɹ[�_���t����D�I�<)L����ض>��hG�i��S�
�)��R�]������\��w�u҉4��Q`vNs����҃*՘�#�@�q����ܯ��%qO���}�m6�]���	�L�xR����3n�*d��}���8���qX�-@B|Ct)��T������T��ܰ��\���7O/Kw�
�p�����:ȃ�� '�+[Tt����Ux��|�٬�=��倫�x�A�����-}8-��6��>`<�Z>.T�)��_�����LW��0 �����w�mc6E�6�����.�����W�����J>l���e� �#F4	�L�w�B8R�O�; �ĩ@/�	�(p�0P�`���	q�y��m��&Y9�
�ي�Y&���!�r��_���s�*���&C�|�nc��s�ك�J2�O�)���F�jOQ�l{��6��`���8�_��p����I��
 ���|<3���� �fq�g(���GF���?>�)\�ؘ[�4�I����&31Y,h�Vt�Fbu�$��T��K��>6���\͕�>-�z�LԐ8 �J�2�U�����u~NP_��;�ܘ�L)k(�Yﶔ��nH��*�+�+Rw�玖ts����.B;����D����a

��*�9��T-�v��kA%ڋC_I:1���\E��4����n�aw9��D�j	�
C��L�[��0�
fz3���� (n]��͎��O��12̀i"L����G�����v�Z옔�L\qm.�B
�*����J����_*q�Wi5��i��:%�N�vBr�r)z��'�� ���E-s�g�g�`Eۊ������d�R	�{��"sT���z�i
G;�}Տ���
���)���&�Ȏ=��5��!x�e�;v��F���L�����(GL$^�t�V˚uԜ�t�~�sW��#Oe����Ղ�A����q��f	aB��N�C�C��	2��Y�Z��[+�_�Ht6Y��zZ������OU �r���Z]
Ӑ��Y��?���A���/������o&2t=]��/��G��ypǕ\�н�Ё��_�,2xAR� I1B�Ծ-M|�&m�����`!O�Q�Co��8 �?��F�]N�����"Z@��'�%0̨����v���-ফ/�l�ό5���x��f�DG}K"�"4R.���%���(�A�~Q�v����7^`^8X}:f�ú[ZE�#f�����".앜�JwcN`	�6e�0qZߤ.�%� 0W���fxV#���u-�����o�u^��1����4�"��&M�<������\�"O������˄��:��"��NN)/"�c��٠a���\�eA�zź�3^)��m�z%j��;���|�//`s��A��`�IU���huOw�
w�;�8`�I����d����,6��+��FF�3h�=\7&U� ��#𥰠��2�s��K"���[�=r)@H@���	P�h}XLz>?0߈�=(���lǨ�	��<�ѡRè�u�"�|�����"���Yn	aD��#������b$!|hjT� )|p��#�d8GI��M���~��#E �{�����>��w���fd�ڟr�X�%49ZE�	*�{�Ц�!<��H�ҽr�R�L"���;���M�ϱ�f���K`&����/�H� ��!���q�*���~k�Bc�ޯ�:uTr2b���ӽ���W3� [�\�J:G~�!ݾ��a����o�EJ�'�AɌ�+�ǄF	�Y�������{n�	z�P�r�-+�:�+���6�������[U��uKڊj�X����ݟ���~�' F��ż�"ڳ�N����ʯL
��Q��;( �j���^�ۋ<�]�\q�E2�Û{���
�A0��-7X��6�yӽ�B-gMr���?v)#���Pi�)ovߦ-��X�i������A����I�)/��̷�6�=�?�#��}i4>.���E����[;`(zx⽓i
�а/My,n �&��"�TO�\��D�e �$2X~b�#�����z���8*�)�o��վ��)��ٰBz��"|:�b/N�������}%me^�a���:z��,���X�ְC ��|��?�(\��k�33 �lR~Ix����#�W�̏���"OC�����<ͮy�x�Oóu�F��x���Nj3��x��YP? �L��s����T7���z�������G�g�9��K��%��OQ|V�mu�fo�r��!�@#NlJ~�Nq˴��!%?Q�A<<��Oa���JA9�����\�����6	�~q;J�Ӗy]8����:9�r܀�_��g!B ~&��-��L����0F;+W���?~�6�P�l��Χx`*Yp��@�S���TJ��<��"���j�v@6��2��p������V�;0�D��x����8�Y'p=�$���	I5�"b�L�Ļ�q�)��G�|�&UZ�ʱ�����׋�l�1J�W�@o�IaGeU&!>�o�Y��ml$aNE�ǋ��'��'kO��z�l�-?N�mEO�O��L"�^�!�E�i!CO�^A0y쿔,�n�����l���I�:�$zTB�դ�XJL6}�q��Bȥ��u�'7ѕ}�w��cg�0�9�3a�k�݆�ō�aH����U �\G�v��"�AH�\.��,'@+���)���$�sZp&����?LL���a'�㲖�� w+�p��H�!J�Z҂fS��J{���<Vu.�b`��k����:0�%�"�A+h��$F���w s͑��&#��������������9�����l�L4���P��2���_��<h��7����
�S� ��ī�}�R� e������b5�����,���������(G/��A��˾y��:��[[S.TػpG}�1���VZPj;}���fC�_:��L; ������6� ��z�=u�'Ne����^x*)˸�u5 �ĒBC���)��>�H��W$Jİ>th��)�K2�P�� �(!(�{�}=�N�z'u|R�j z�i-��UE����y3�����Y��K�1R�5P��k�.}I�'���i��U�b�-7��|)5SG�A��P��]�����{
7 �s���AU�/��E �i�J��~����ˌ�T(w��?i�����@:mN#�DB��FK�E,U(���ˆ���#@N>3�r��A��uMIp��1���1��)��#-��_s���ί��`�Y( �����e2/��4Bw����F��g�B��	��zW�=n*�w�@|�-���Q1�ǏD��3�|�~�Qie�B�(�����F��u�	�׋�����=}`�J|�~[*�^�5�?|�<�|Yq�@�Oė�D+�X��K{��x#�q43�zV�O8W�A�� �
����1S�AdL����l�y�W�:P@�p�]�s�:V���1����,�Y$ݸ� ��@ 0Q�Q{rF�\<u��tA��]�I	��9�������ƲG����e�����^q���s_ܯ A��KᷮV�Q8�����5�c�Mxk�#;��+(t��2������Rc��"��@ʴ�~n�-G��֥�� ��/1��Z٘������i�}�/GVL���"t�mɤ{ܞ���܎���-��&�0�����v��^~5�~�k��c����2�չ���*}���d���N��M�������QJ%���L�w�ڿ���NC�0�g�K����[`��)��ھ���������htX� �?�_fRV<-���8ֱ<�D����ZM$q�r�G2�z����4D��+�s�_���j]�ā�
�#�����|�Ύ�9%���AMZ*�����qΦi_�hY�gY״А��7(V����9obS$:�Clj�+��KK�5}a5�<ތj�T.�_��̓/���P�,��v� �~�%ݳ����ׁ�bܞ£LXGԢ��:�<nR# 0����}~�2�Q�] K/9�7rxv�R�w]n��:ac��E�GT��ƨI�}���T#&_�D�,e��ŭ���>��l���M�sF�Q�}�?�(��Q�t.N���o����͊4��#U-6�9�Rf)�1�#�kq7���C��[��qxCm���A��*@:+��Pbm��N2��>�}}���2���J�s�귊$k�Y�d�P�*F�I}���?܄~Tm=]=�����{�H�$3V]�o$߹G��+�T�vZx���GI��:KVk��&�C,|a�֖.�-��)Z�;ߩ���ǃ�^��o��|�dǚ�P�7���e�E��Cl�,�"uTa�g�� CShO��������w����&���S�oz��-��q�J��3}���@���`8�wX�ήR-(m�g��X�����T��F�ȱ��@m.��O@��B)Q&�����h�zǡ�:���%�� �Eu�ŶKW��6�e	��V���;�AÂҢe�j�	�	:���c0%[f���BO��[��a��?_&|2?e��>�������u�¦�����ٲ�(�%�5h���%~�u�t��:Ep�ɶ�%� R�+�����2�V��Vbg�z�>������ӡW_̐����F��Jf7��|��@��)���p�SϞP1�V�)�CJ�u�%`�*"{�55���@���Nk��0Lku���9���w@#�$����bN��F��J��X<i	��"2��#��6
�ڸl~.�!�ā�:���~&����K$įZ�-��2�ɓ�a$�G�H��y���1��no�A$.in����I�_�����5�Tҳ׬���ϖ݈n�~cd�Ѐ�O�������PyE�3��~�=K��`�E�h;�mwR^�aH�%]�D�O����Aj�w�7�/�<��V#F�qVD/�q(VnO��<�Whb5|��kt�TV��s�ܕ�K.�%�9�5�[��`�X �X!�\��q���M \��W+��Q|�=����ź��4j6��)�g!��=s��F9������Qr=��ơ�Ȅ	�I|�R
H��X�kR$qeZ���皘!��x��=�b�64x�h�m���"�l2�wHXRe�D��iL�a+ڧ^sҊ6XdKld����z�I!)%��qIb,�}�fJٞV�:�Wv�<�4�oYs�ȭ*��)����8rr�;y��m�~*����3N~&p�
�	`���m.��R蒴P«��Ё1��~A>`fIɽ3��xư�����>��H�y@�X/�ǡ�K������%��/���k~����%r<�ɰ���O�#��qeʏ�]�H���<��ן"v}ک8>��y_����2.�YT�ߔ�;1�j{�f�^�3Nl�U����ƭ2E4<'�#�,�5��7o��Hݻ�Z�����j��jH����j�5����v�	�Yf�F�:�tx��\��G�ܚ��ҺX|@5�w�}� D�f�C�L�W|�P e>lE��։�7�מ-F�h )��{���w>��{���zʹ ��G��/��*�W���H������V����uٽ�Y�kX�̍�R���^�P��d��9$6e�����EJ-�Wg���,����픈��S�5��]�/hޫ�;���_����lw�L��d������%���t���{gk�c��b,
2��F���<��������e�O��`Z��������3����8��U�u��|�u  6�S��IGi$�b7�<�LRl��H��9�i]xBg7x�&����<�%H&�S 	!���~�|\�_0�	�e�ōZrd�@��B��M�5�%�/��w�WWB���������� ٵ�˩r��Û���g���Nhq�"����S���e� 	�^8���WK=��FP���c �^�r��_�hNN�,���џ��֣���O���h��Y����۱K˲F���2#�?z��4=ћ�\bq���y���i�Lm.^�V&�l�%�&'&m��_Y��%�A �w���)b!����,i(�9L�Y��Pd����b�p a~&23=)�EހE�Nn{ �`ً��:��p�#�]���c���݅���X����aa��0��zmit��M���L�PhJB&�A��JE��%K���4+p����3�R�Xv-`V��Oe�%M�,���8���r��S�mc����CШ�w�d�'��YT�r�6��UcX��|�El*��a_�?Nan�JfK��_)�Q(����m�?"nn���\����ܒe�E]L����A�3c�! g�*�M�,�:y3..���{��,җ�X4��|)[߿y�FQ��M�|ߋ�ɺ���Y��D��_Id�{>�z1����CwC���Z�OMe�dEP���(f�(o�7!j�Os��ˡb�hl�����B�������jB�f9Vt:����[�������E!�z�ESh�ƒ�qeې��Y�Fy+Sgyy�#M�j <��{����|4���#D�V8��g]�p�zQhE:�����yT��M�SR�ۼ���3FR���Jf���~�k��� b�f0�r�f
�v2	������2� G��$BXpi�H�G�7j�X�ǡm�s/:i�N+��5�z�^��#�X1��E@#d�2�7M6���uW��u�`<e�E��+]�үɒ��eAA�����z�N�R��������֖bCA��(ϣ�� ʺQ���� �+s��~������H�9a��2tK�i���m;�R�a>}+}D
Q�S/h���+g���k��k9�+���u�Q���p)9/l���pA�y��e {���)���j!|)�pt���3��]F�I�p���"��<Y!����iƜCdl�֌^b�>�U>��pF��NM#�i_ӂ�����LѶs/���0��%���!qy?l]T/:o�hI���!����>���J3ue�U:�3�\��òS�6��۝������6���QM�HG��0�{�#	�E(B�	��x�Y��CWj0I��Q0`:;�	]C��l�͔���ɐ�0�(k�k"0V'��TFq�j՟�jV+���~Qm�ytDu�
@}��u�=�I'i������Ż��3��W�dhW+IF�x)l>���YU��ɂ�њ�_��o���<!�O5���Z9����xQ��Q��c	��m�5�Y,*4Eǥ��ԓ���$�sO�33v�:��h����9ϸm2���Ol��F����7k����e D�~Yoo�X��-�N�<
U��P�&�'o�H�ƣy�㖓�L�pE�`'�Q��X�T���@z�o�Z�P�i)0s���O��`״���L���O
��i�QxQ倛Q���l�#o xц�������j�� ���K��7Zn�u����g(��`��o T�D-ig�� �v���V6D��?� 2�\������u�\�n�"�y��V�w������16|5qi�þ4�?��V�F*��M�<��mp���̙�C��h����܈�[Q9+�q6>�m��X������V�'W�z�ϕ�Lb[4n�WFv>B��ҵo��ހϘc��)G{��&lׁ��yI'��MW�6gV���*�QrS��n�� ��$V���k9�q����E��7?���\��c-��*���J���$�I~d�KQ�J�ΰg8�ҶȭcY&XL����J�y

7�-����]�:�ԀI'�?Dk�4�5K�(�&��7��겝��{��n��a2D݃<���n�y�(���w�),����G���QN/{�wB��ZmwM��O��x�D��0� �e�����������+ŕ�NX��U��Z2�=��SҶ�(�)����R����Y���1̅� �J��W�e�Ŗ�����#�9v�pr�� ���q�u�鋗n`z����H��h&'�Vq���?cS��fd�|C��zȖ����VI�A��Y�Ȉ�ם��ߧ��d��s?EY�Å\e���F�(�<Q��������_���q��{F��@�0I]X�0���[V��&@A��cah�?\�J�^�D���X$;A$���J�u���!�48Є�6�lm���ow�R�) �Q�|9�����`e%*-Uj���W=/�KSSE0���:k��w�!k�#ٮ���~I_��&Og�W<+�U)C�7�� �������<&��c [�.������ uZÏ�S����ǋ��T�QB�vШ������,� D3P�[��v���/����8��e>s8	��n�'���w��ڔQ��E1�-B��m�j���׫r3����Krhʃ�Z"scp�P�$�iy��ϯO��]�a("���ˢ��ؕ:q��5�y�i�
���k!X&�����S��I�~�Y�S�䝗w�e���1�$��F#�O��ۙ��gJ�~kT#���1_�IN��U�6��M��*��jDb^�/�SÛ��?�/X��T\oީ������+����o��� �Փ�]�����w��D
��e=p?��Gݱ�^i\�{����G^����T�:�ctP�E��	tm@^@\�[��0��`�`hذ�B���ۦ�[l<%�I����Ş �"vB�I�^hG%�t]��9�GٍQ��Mö@Po�5{']Xw��$�!�����q	��|r��D�h��ה|�NP,fČ�	pS��#5�����皣�a�NK.�JsSI��t���c��Wb���S"��֢r���8��%m�����ŗd�m| a�#�"�<o���j�#OE�[5��+ɕ�ܖ�,n8�>_}�N����}���O�f��0٩c�9%��[��h��Og���6�kL��(����@�$3�	8.Qҗ8��r��G3i�%�MQ��H(�4���A�A[B�-����%�"ou�O�8]6�dF��׮����a���e�����k�>�|F�P�q�����'�\7������Bʞ��݀�hmc����?��k�3pj�id辸�@�R��	~��ZV���G7�)	I�oc�F�D<q\g�E�^"�|��e���,�����Ċ4X��?���ia��6i9�:ǧ�|�l�Us2�1'*��8�W<�|d&wH���Ҁw}�k<���TA"�.)/��_��������ߕ*"Ȏ��&�h@���ڳt�BPb�Y�Nc�6������dQΛ�k�"?�V \A�I��}L�yj���d;&�l|Vr�K0�P��<1���^�}�q���M!1h�gM:�����gY@�$�Zb��H�it��U]�f@*zz"�(��VZ�jl�*@D��bo�z &p�$MҚ��i���"6�h?<��-kc�S<gCX�Ut�K��҇��Z�+�S�e�D�Y�\غ����P�;VL�Cz�.�/�y �-���f����^��u����v�!�mK��p��з�����Y��w#E��(��"OcܑZ��n�h�bQ/>!a~��!.��D1wUj��w7e���M�j�_�����ݶU��\��B��m�R��d�0�J�������"��Է�t��xQʾ���Es�r�������P���o`��w�J�7�
�םY�D��;.l_K+$j�Zr�u�x��;�f���	;�$/��l����'��;�,����Y8����O���9�XC'^��!����/d����x�x���>�:�k�n��\Q�H����&Y��2����v�?��E_����#�c�MF��'�/�r�#�S-��b.͂F�?J9]xK��r�JnIO咰�l��H������}	�l}i$/��#�o�1%WC�lZm�-��bpI��)*��ż�!p�8�)�*��О�'��Q�k��%���/��r/�_�1��r�_�����o���!s�e���29���܁��i��\����i���M3S0��Y�-A[3%��l.����,��_���8�d|��'�1�M�k_���p,��<v|�!P[�P5��
rnu_y�=�����[9��`�L�m�53�@�\I|�8A�������^Npʨ��� �.���>ue��^g8}�-(d]3��`U��y�q���V�/�b�����Y cu���������'�_S�Ra��g���u��b�;�v	m�7���x���X�2�t`�z�a~h�w�_�Jf&�XVr�����'/���ؑބ
���Mh�ܱQ�/(v���Ԁ^�δ��0��y�
qAŢ]�����"�n��:�B=��������s����V*G�#�wQ�P$hyA�qi����x<u���L~�v�|���{�3��5��ǭr$����L�/���K���%d�Գ���r*g<M�#^�]K�-��>��9�)W�8�-�@�����ן��TL8׎58��-��tRM��R�����w�W~%�ȫSx����EDii-s��w�6B�m�F��ǨBN:�� ��{�m�e��W�Iu�qz^�{Sy����Z��L�Ɂ3h����n#�g��u��ﯿ&a��$�E�^}\�p���6<     �-�B� �� ������?��g�    YZ