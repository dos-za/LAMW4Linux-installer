#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3146838850"
MD5="c79fa6ff5fea03f3351b987b0a1ec165"
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
	echo Date of packaging: Mon Mar  7 19:12:32 -03 2022
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
�7zXZ  �ִF !   �X���g�] �}��1Dd]����P�t�D��/�M`�
h �ƕj���~�ۯ��!`��s���GS��YP��n7�m��6x('G���:�ig����~�;�ҩ녝�)�n]������~��*~؀)j(������&}���h`M�jm����У��jP�b�H|����P�8I�"��$޼X�>��	��ְ�)<�<��cYļ�X_�x��Yf9���T|�BH4t�	����׏:я4��:�P��3��`EP���e������6J����eiE'�lL5��3��g�t(�i��Q�R�d���ԟ��X�C���w�,���<���+����|5p��XU�}�/�+�a�J8�δS^�!z�t��uo�������7�	�fLb[Gv�4�c�S4�,Е&���7�
�X�H(n�DXj�hN.R'?l��#õ�Y�H_oႈ'��.����c�u���E�ehp]���af�/^؋"n�����2��ل4�^T��e�˦.���~��pY�c^� ��&wa���n`�D9��2�.��31'�R�PM	�_�	�=�;Aʓ^�Ӥ
��㺛�)h`�/�6��c�P=����u�r<����k�B��3�-���ܞd��{d�Zu�I,R7_�}�1G�����ly��D���
���&Mz+���d>6b��#�2�ہ*�d�^QL%�_����b_�]�CB[�5�E5���e�Q���ͷ�*"�T���o3]AU�H��'�\%�(�몪a��u�	G'Eߵ_v� �~0��v3��ѢF���auו��'��^�r�ŘH�4&p���d;�䰢;�5�)e朷��`������g��\|�A k��Wٛ�L~͋��(���G.V�DI�Y[��J�^�˧Ԩ�c�i����_>�떧�ѳ�dx�I�W/S\�ڌͅ"��q�cա��x�����b�8���£_��!̲�?o���ê�����/�Ш��a��`w�&�����i�w�$��.�6;�SI�O���d#�%OA��e!K���>������3aL�v̖u`DM0BMĩ��l�3�*���j����vlϓ�bO
�)����On����}��b�ϗ3����b��B�2t%��;��̩ �8�Z��u�ȶ0�{��l�cw@�TهJ� �A�3sZ���H���r,�*|�6XV�;RB@0�Ϥe��_�Oe"@h&��>�=�!W[ɉ�9����x�o]�Mx'�e������ӡ;����<�#E.��KU�{��.��h�|��m��g�j���4h��v�C,���)O,�"��|l��#Iܦ�ډ�?���ng*�����X=���g8��P�R޽�N�i��OصY��v��X�1����C�>B�(� FG�v��R�r
(� (��*05z�H/����V�Ԇ!�	��U�y��=ô�L�2Np"��k�����!-�(���Ό�f+h�1��5n�r)G�}�L%���L���rۛ���Lo��k�n�p��h� >����f&0J��yv
ݻ���ۚ^���M4yUc�ւ�[�]
	�B©K�<�X�����`\���IV4�����gp��-m�y���ku�zpq�������o��pĖ���+�e���Zi��=M��P<�go9�VEZ�&A�%�zqž���
���W&[@�~���@������tP���H��5b9?�7*���X�Ve�6(�88�"���OMV�V�(�^�ڊ��g�Xju��9�;��W�>�z��3��"������z�����B����D[ڎFM�(犴�^I�sP����:7�/��ס(ʋ��t:��o2��g��VJb�%&N�H&�)M�@<h�hOg� �k+I�~C�+@	��^%M����\ug�t�J�����5E/K�Y.br��X�:�l�ŭ���Oq2��4z�n��8��T.�Qc�胲"c���@"%UC�	@K���z�9R�Z�� z�b��m�.�t�l,�o|f~l<��XY��Z�YQd&�f"�1C���\�X~zwm{����k����`���x�;=/ٵ�Jn<D��
��H-C8&��_�4J�b���;�\2��v�����Wd��!���J	�����I�ȃ��}�ZLw�B�v�3�%��y�W�9���b����Z�^��+A
���	������]���^��鿕"��g�	5UlL�5��#P��=<�^�/ń�����Q�����d�$�;��58ǃ�]a����18/A���h$"/�c,�z<���q��CxX��[u��	/f��gG�~]m���cfb��Z�q�'�Hl�K�|S��O%SI��<���z�����Wnq��ꕖ�z2O��g�L�:E9/W�o���#*�8��3HΥ��I���T V�y"��J�n�4�7�K4����Scz��k3�o�����e���ʏ�R�U�D5|���,�!R��˫��DR-^h��yݔ�s� uzD���)Ϥ �t�� ރ��;K*�`K����&~�¦J�G���kY�����������޷'�����ZPn=#�{(M4֊��t��L��r����:�DP��iqs��/J���=<�>��[}h%"d��(bE6�f��;��CJݞ]��ګ��j4���7���#0�b T@�CQ8ǝ���O>�;k�����$p=�O�c��<���S%0,5�Rw��5�'�gc��,�C�'
��K���y�Kּ�!���m`�urp�6���/+0!�����a��_����u�e
���6�]�d��qW�R4�6t(��+�;|���{~�y6;�/	d ���`���"�Q>��,ק�屘܋��p)�2��A��˟��Bh��[�m��qY��}����h呃T��e
ɕ}٥J�Pi�����cƕ���ZQ_�0ㄲ���=q���]�f��c���3?�$�!A���= ѥ��q�1!�i����gF轠�gYW~�Z+�<��V}�s���i��S�ɮNc4�h}�I�e<^�[WJ&�Jz��h���cɏ�e��9[Z��}^�J�}�#e����d��c�m�����*_?W+T`�F"�5a��Oj�Z#�t��Ω�s�
&���Dn6{_�Q�?�l����osv�Re�sL7d�<,��MeА�Y��S���h%�\l�~�a���Ŗ�Y�=��X��^��8�����jBA�)Z�c��;ݫ�/���ܝ+ |k����?�PE��D��ymA],I�!i�U���X�pςN�r��d+.b��R�.�����K*n(�Y]���w��Vi&9
(l�r>��e8�L�p��5��p���Ƹ�sdZ4,�"�)�����լ�R���ۖ U������ S�� )�E%.�D$������ѭ�����}�˜���^!G�&6n1��+�v��f!�&�,1����P�/]�$�b\wv�õ��a��¶�-�y!��U*�i����KE\O���4c�;$��>)%��e�K#�~=b�8o�((�*^16�|9�dyaI㴃p�y]/�PG�K�'^+}s���5��7c��qܟh�A�R(�4�O?a�2Œ����Ig���+��Ύ�� ��yӜh�D��JA�L�;�c��i�r��G����FvP�T�����N�Gk��d�.u\y��W��\��N-�ӛ�id�;���!o��'�9?��#�<c�x�B�bώ���o+�d0��g^����"b����q�����S��9^ܘ�eP�JC�Ѫ��y��} R�����r<�4 �
87��3����J4���S*^8D�9Xo��|ϬQ���0j"�f�u� {7��?�x��s�VN�i��q��B�u%�lJv�z��
�Sw��bi8\���l��)�1�$[4R��Ȇw0j�*�q�N��!V5J>�jϙX�Q���s�Հ,�u$.>�;�����~Z(�<����:O�:n���a���9������X�"��Kv_��@x5���H�`+��r�_xx����>z��fq��I>����H���l��wOx���V�y��*�;�c�5�@������`��r+��`,:~��7���H`�yf$M����Y��r��A4��Hz؎N�5�����Qؘ�:�h}a�L�z�A��Ϳ+���PI����W\�GGx�S�O���;]b���|�V�1R��q�JOF�ٮ�	���3�43a�F���%��߃1U��0�sY�?)gk��&�Ӈ�DUX@�Mk��:_A�:;i�}���h��񜣛��]u�mj��H�ݣ'j�
�f�c"�i�WUY!2�`,IeB]�Kǖ��|k�6H�����%�_:��t터�_Ȥk��)�{��p)s7r�����P�ɯ��6��O�%��I��&�}O��y����,ǷyZ5w�!Gf�W������F���J�9ӷ�	�)�Ƭ���EUa'�.,�aGЌ�D�g4���º��8�t�݂�ҥK/d�	���!mpBp!3'/�%OYb� L���z��cuր�1F��4N�L�<-�r�$�{�1���#��]�l�i-D�P���ry����m�(o\�fEA㰎Vi��I>�B.3�4U�l����n�h��OY���A
��ʣ�Zu��j\u?�Q5W'uA�I;hR�ZE�m��V�6ly�]�G��e�V�:�J(�����/���ܹtQ\��Ưn��*�c�X�O�r��0��?��T�U�R�F'�������ʇW���[*0���p��47% ��g��g\�J;��JՆ�q;Z3I�Whڨ�ʹ���BoE���;$	+�l�X���e�k�����>@���/��08�I�š�9����
%tV͠�Hk�՝�������|��Bc}�o����׵���|o���M�9�*4,���h�ӓ*�5WUQ�'��8���K���t��y�gڪ�
�J!=�]_�N68��ӿ>�	���!0�e���x�*t��q�$��J]�r��D�)��3Z}��֜��0���n3�ʺH�v����3�+G�"w3�}�l*E���r�=`�6���U�4�YU���.�4]m�r:��6J��\m�
�e���y^'�2d��8ݖ�$�8�ю0�Ҁ)��������#��
1pK���t>_�!��u�@�R��	�����6b�c{O����\���,���,XO�$���*�^���:n�]�dX��Qس*�Lyg
̎�G!�����'��4���k����u���d�H�G�$������Be`�����u����c�d��',9�ךy�w�����Or�����L=��֥���$!�����&EV]Gb3��v>����x�eԜQu.D�~5t�PCHk��	���?,�*�V]�V�g�9��6�_�`���`�5!�&U��7�ؔf����l��,C;�y�n�i�FڳT&��n9Ad\����߀ثo�V�Y<=f�91�Ӧ�b 8|��c\�Կ����K�fh�te
�G���R ֹ+ɒ=~<U���4C�����'P���[pø��x����t������M��m�y�7J���hb�h_�-�%�z��*���>C�$?F*��]��*�����p��ʶ�Y�v�B���s��X�Hta���+��a���W�
�o⨻<S��I�U�D�d4�)D��������8�H�̟?{���u~Z
�єXm%^��>A��^���>
��C�޽j,%l4Z�hnMZڻ�M�ϯr��E�4��iyd����h��K]���k�*�=�P��|~�,�4(������Y9 �4~)D��O}��T5�9�$�	bE�'����p!�����<�pK	��I�],��>�l�3��~���J �D��-r�S�����?4��^u��$acN{�~\n�Q�*���:���[fcl[��-�1��ф�q��8�����v�5r�蘁k�-�!��4��B�M�f��N���^^��;���-GL>����H�W�&��\=�@��f���by+�M��0��h���)�5;5[b�2[�poTS����ᾶ#�Vr�B���q��[¶�fL�W�]ZDy��ɔ����J*s</Pi/:��5�N'�����3�����0"�Q�^X��o-�����b�%(yD^������ְQ'��T�[����pGbV��ޡSҊl5����J1f��cIL%e��T�R��e,�j_�<<�6X���<�gv�'{�{0f����6&f�t��߽u�$`. Q��n�@���ؼ���tP�ܻ��l���f��6#t?�>��hd+$�GD�_S?��������.=	�(ut��_G_o.�,��r|(�~����XI�nӢ �4�h�~
ܯ��二w4��"�ϱܺR�biw%��M%�˪�= ����u�W���o����@(������)ezj_"\�.^&U��řE��B�����de��H�N�,��ֿ͉ߒS�	.$C<�B�t@U��ޞ�+P6�T�i��c���!�MX>k���	���Z-���sZOvս`�(t?K8�r��:O�h{},�^��	����ѹ�����$؜��KYb�~Fr�=�0���bP{a����,��c�%XNX�04�1X*P�bn��)O>���;y,_���	@=T'�GЬ�c�X�:�{9O��t3h�%x�͠c�����o������jS���G$�~J��U�ZZc��=c��juF~E�O�� �'9Ɯ���8�N�EjɄ@��)4����E����)��:��ŷߴg6��X'�@&�<���<Cc�U7��ʒҢ�p���*�l3g���sL)�V��Íxm�D"9 �!�̻�<�	�A^����c��X�=%���%��P� ���l�2�[-�|F<ZZ=^���f���_�T*c8�`^5��/'O�YK���'�}œh�1Q����d�;�g�>�j���Z���,"P�mpIs�`��G���`�Vd�=e�]��k_�V�"�|}���۴�,Bx4�]�F-Q��Z�~��2���~(H�Y�bJw�%覙�1�F�sþ����>OC@�1|�R��QGA�mmF5O�eb�[�a�C�]6Ā�Y
��Л^�f���ي �RX�\��hF8[�A�nܴm/�%����\�]y�k��Dh�t�+�Է:�t��[�0]�з�[�=��[��\Ha8�m�����aw����n��rp�sh����޹�����s���_��EL�(���"��H�"~~ �ǲ&m��	��tݴSL�+R�(C;d�6��N���܌~ɶ	6�s��B�~��[���-��e��P��������)|c�f�|�x���v=��5B;�1ӏW����@g��
f����3Hw􂛦�`��0�
&�hileo�X5�7�9(����k�,�a��\h:F��_5�����f�$�%�\���q�</��$�e����Z�)�&��B����ك�> �T�`���	6��*�Y͋+D���+�B���~��|N�;�J�)� K!Zv�[+U]3Iӡ3l��h�=}וG��S�0{z{5`�q�y�~c�:!	�˩�]�3V�J+���;�T>YA�(~|�?�k��_d���!t;�r�墛g��()�H�?��ˏ��.�`XcY1.w/;�Ei�6�|8e΍ �ML/�:rL��f@�+��ZP��Fmk�̪������>��#�����߀r^�u�)�Uͫ��}gp�3�tK�a>gN�}���r$#Z���V>�$���v����>Y�C��3gN���#�fXFM����UȠB�z9��;�9'��;FJ-љd��Fr꘹��{�
��F������$@�~�w�P�p��:�0�ܵ�0�k)+�Wx[�\���x7���K1n��7ܕ�����g?��|��M��T�4���qGd񈰀��%�x5��[�"���R�7ŭ�k3m~���vI~��ؿ[_{�2I`���4l_�ú�՘RA�ȿ�&2z��c�
�q�,Q�I̅����hRa
t��D;
���I��B`o%�;4|��/�%�!�E@ۋZ���>��r�S����_�jŝ��RWT��Xl�� 壩K��݉�"\;>	��|7�Q�(o%&Rh�_��}E�2S�|Ha6�6�t.�����	�!�L5FWa�37�vl�w�8�b�[,�Ǡ���������D�Ȅ��7���e��w��0�4\qf4�lz#zRd�e��l�b��ۼ�0P)W�&��aƔ��#MwG����[���z�xn��I`�j����Z/���_������Hv*��{��C=|mh��
"�vE�o�Ԓ�a0��Yu�k)Ty�E����x�r�|3���rM��<ax��D��;��IU����?&�WUPv�Oi�iN6���3���s��Մ��Ź݁��^U�;�y�# ���G��Dg���?J�
@c]7�r�.
X}{��A;���]�}��24�T���i��9�B�͜P�{��X%2 #��Q��	!�m����%�%�hP�}��f���;@76�߶Y��o����Z�͝�܊x4�ZïT)���S%�Hl2��V9VUX*���P�u��SdT�Η	���uVv"H
4~*5��V�X�q��A^B��%�hiBb�rq�����7��m�I�p��q����(����}�������e�%4C��qU�UB�'x��׏��H�t]�Q���r"�Ӟ��}o���~�4<$V�(��x}Bn#8�z<J���a9X9����H`l��E^����]m�2�t
Pa�K�ā�3Uc��ƫ!sS~��J����u�.C������cy�Y�kxo �i���% 5	)��%��"
sA��V��O���V���*f���8m�y���p?Q�˼T0}�Jy�|���m躉e���Mie���F,��ɪ�Lߛ2q�Ƶl��C%�W��4V�������T�,1�}m�lk>s�0�Uʲ0�yw%Q��i�����㇞X��s�c�0w�r��嶈��%T:�x�R���PEk�o�Ѫ�6�udqS�����p[��z�{+���C�c�1��= 	вq���̥��#��l�@!КX\���������5^�C�`�V�,�������^K���JϤ-x�Λ��_�̂�j_u�d,��,�̪��gcH��;t�KN�HZ� ��+�jB��Qv�/���5>yK��>?n�5�7�#ǉ��7vh
���e�1�]�^r�O�Pg�)�����|�u:�^$fCX��QS����q�)CC�'�)���zOJ�7��P�GC{n��|N��v��·�5`��L��� ��G�o�Fi��[�6�,$_����N�i�`!o�R$��H�����k�iZp= �_�R�� ^d�-��/s��R"ך���H|#Q�|p�HN7���<��J\R	f����b�Ӹ��!0h,V5��ڡ/�w���!��g�oZD!l����4?��u��>�{��b{��޺�/���%7��l>�ǰ"=�-��m���x%�1YT��K���֛��Qi,Ήn	�����z�6�����+������ܦBS���Q^�^�ؑm�B�����K����.����E���M+g%��0�q���� Z�ʱ��i@�1���f�(��݉`U�i�rk��K$l��4��ŭ!�F��+9�c��Yd��F����S����A�"IO��@y�q:��m�m��J�&�sC�>�#a���G�7���O����p�`��\�m���M.qkϦ�aZ(���1/��}��b�(0��]i�DF+���i+�z�|[C�/�i����=��$�M�bx�5���p9yP>ƺ�8�l�0��0���|�����)�!�b�o�Ҳf�fD�VH��;�r�����o������w��404�N�L��Et8K��i5��I�����6�� �bDF{�d�O���v\��o�LᎺ�@�fC�'pw��y����R<*�.�-���>�}����VLZ�Fxո�ܖnS3��vD�{�J�s� �3A�E0�Г���!*��ɔk^�>X3 ��O1����)RO�W�th��@}n��`�F�*��n�>vk��<��u��C	m�I>�uXa+,�pG���sev�$��y4>+}���D⸎�A��������kh,٧�Es/�~��?���d`Db�:�c�1�;�ø�	@x�Y(*~�H�������C�p�Z�R�?/�%U�Ql��
��O%c�iڏ��}�%��D��i˩�/4)`�'i��$����� 3�
q��i�z��$�
5J^��������t͡|t�fe̭*�N�>`��?}��=C��0Ҷ�:P��ܩ�՝#RU�G�P� ��$���O(���2�_+)�66Q �UZY��w�V�J>��T(1���!�8a��߻��o���m�9t��@���ҝ2;��q�V�����V�DB@�w�XխZd0y a�!�( ߦ"��|�P��F���;0��j���4�{8I"��VR�� Q��?8������;�R/hd%mԑ��bj�0g��'��L����3����㘉�n�N��g^D
���Ao�;�v?,w8�;ByO�8�� .�]�<YR�>Ya�t�ɵ�O�i�8��zW:/�����������`&=#������$g��$��$�ǫ��f�v��K����݊rn�=	Hu��)ㄡ
N��}���'ږ�������C����/A	/��#T�Ϣx6'
�`t𖙎[>W����V[��o�݉*�-�x?�4���_�7�-�z�{EB%�X�&Jk������F b@�	y��@͟�%߮W�ҿ��29]���N���䃫�^�5O&�+�:/��|J0�ͻ��S��Bpѷ~&Ԏ��?W�2h?�bDW�6!�s��	8*Z�K���;�}�s.��v��������bk[�ڀrX��Z�ޟ煳�e{Ԧ�|E�J)�`����[*㳼$�4�.���������^�W���\���NG��Ὁ�� ���/��Ӧ���g����+D��w��u��7�bع�9�9�^f��"	�q�9�L�W`)��D�P�f*a� ��IB�I@L
����u)KN����0t�ԘW�tu@x&ͮ�Gи��C-�q���#(.?0+�OVn�Y�R���})1jh�f�����[D���Q�7���D������5�]�W<)�e\�=~�ke4&T��cR&����)��MQM��9��g��ة�.z��+�N�&'jl úʧ�y��
��RXɦ�4&��`�Uu�;ݱ%��>�ŝ�'���E��{ř��ɉ�65�:��LtR���ߝdj��(K�B���j��4��@��wM�1����s�d��=�����\Ib�et�#sn�1�,[���ڂ�)����wn^���H�d��v���)�'��$���6�_��.�s_/��_�����fY�`��x�կ�y��?�%��Md�ѝY���T�mS	do����D�R����j��7y�6ã��NiRj�U�X��@�U��	*yXW��L�Gy�cyo:��d����L�a*k+c�r]���!�C5O�2��G qX����n��"4�i��D[�`������b�q�7|u���0�;hrO�vg3�"�YX��#f�߆�&U4�7<�H����۶�I�������RuH������P�u��� c! V���H2m,$�[�	��'�~�V����X,:����vX(Ur	 �C�g?rw��+)'i���Óz���,߮o�} ��Н~���Xc\"Hv$�?�I�! _7�81r�~WQcػ59UM��)BX7ƵU$�S5���;rGiWH�AI5�S����13�XO��W��;���ו��Wuo���$�w�cu��[?)���(>�ĐH�Xyo˨MZ)��9�4</�$��XB�WBߧR�`'kC��!�-f�8��� �"�*�y��2���	���t*b������kk~�~3��(��H]Ja��:m9���]k6"V��:E%Sɺ�!�O�n[!�)7?&��xPg�3�p\a��3�Е^*t���B'NB��\/*U�#M��E%�����������7f�E?�?�7�*��&�\��
q��2�ܙBY�|a�s���L�^XǛ���Q����

3�h�f�'ަ[d����Vo͌��#$
��/���~JpL/B|ܠ�S�V�FSA.�����C�W`�&�Ğ͊w.��'�X�W����ᓛ�'bBh��3%^�?U;�AI���}�����bTf5�/)I�U��ݘL�~��l�Ä��O[����ﻗ�yK�P���{.ۉ�	j���\ֵ��j6:��:!��E�l��g����o��IP<��d�$�c���6k��3��і�TBK�UM�eH��N����gT�:͝�70�O�ęў�֡���g
.�g�o�M���8��SR�vH��3��
�eh��3}/B�� �c^w�̴���e�U$�?�X]T1jZR9�@��r�>���,��7Np�(3H���S����{F�m���
��V_{�y:]"�}ҕ@�:�GqWqݜ�?#- ��E��);��?yu�-C D8��3^�PS����ٵ&�ģ`���~�t�^��vY���K<�yG���Q��W������n�|��o��u,Kx�m+N�8�S.r�����~��#*H�.n_A�엝r�ElN���ݔC���Z�����՟Y�����-�̟[1�{�B����Y����n/�O�����g9p��R������+u�)�q�ri{��D֓^�]���>���*l�r�����X�a,��܎��s� ���@)�]�p���M�L&X	�K���-p�XD�Qg�a�l�s���/R���K���L=䴴�v��*)����<u�+ak��G����*I�HI��jd�'�{_)o2��r�G�ʴ<!����ǤF%����n 0������
2�`����7Ss��������$�����*��g��)���OV����E��NV���*�t�f�]��}l�_�(]����]p�|*��~DO|�d������$$��_s���3O�Ro�����rk{ي?��r;�����Ğ�?e��-4�65RѺ	�X�8���7�đu>�۪��nWfz7�gq21�!��֏���2�a9��1����*��@{xUL_�,�=D��Q]N�Ck¬6Ų�-&�nm�rjVQ�\����[�`�*�]�V�Ù]���q��T��Ya!��F��#a��U��=;T+���q��L�<\��Y����2��e2bf��rh���L�tr>����1�g��sC�u/��a�r������-�.���.��N�K�����O��,���T��p"����f~��O��}����ڭ�-a���e�BRd~�q]�<8Z�Ÿ0HCV���|U_Fk�yv�/��P���r2�:��� ��>�C���Ƚx���=㫠x�$հ?!ԩ$��C��6r�!*Ť��A�v(E�L"��!R��ۥQh�@v���+z�#�fc��;`r �U�V\���mw�X��[�B�JB8���7�]���\��:�y���}Q�����g�8�/�z^�)��jJ
�����E�Df<�R��S:]'��J�W+5��_)P�v5��������Deby�;6y��6�2��BS���ۗQ�A�苤�F�xvp�)����}`�X޳�t���
J������C�O,"���`��� � {�R4g�U.�+���;�5����]q�Ե��܎=�;����� ܂�� ��V�P��ݐoǯ��i>��6��V�eio	�9�Bt�� s)���F�hW�.	�`E���/b�*�����q붕����=P~��8�'4_ ��hef�wJA����~�ݘR*�?n��|�E]�
�N��|�p��6�J��N�^xd��/9�u$�F"q����q�SG�h�u����k|�`��:�~Ѯ�AU�m����u���W������w�g�h
ͮ�~"��!dܺ*Uv�������Q�di��r]K����&s��F3"����>�J���yg��oj�ˀi6
�{����ֶi5�3�u�V#[s�M���.v߰�lv�^�HΏ�Ӎt�7��P�K4QzM}Uߩ���o@���jU���a]�}�݈�ɵ
0]4&J�%��s�lȬJ�yH�^պ4��e�D����#=U��2������0��k�\N�8�>���i�ek�}�^).d�C��^Yq�O~&��JV����܁���˧��BEƝ�D4\��..w<����������2�R.)G53��C���oٿFQ��
˦���:��a�+����u�`�}ւ�$;�:EI#R�yR���=X��^�'�ђU�R߯�ȥ=��9f��%î��k��Xݲ���`b?�(�lx�EE��z�9��d�2&�i7a��Rk/��o�As������q��oU�W[m E�5��$&�sEnw[�M�U2���l'{- Ph>(�};�1�'��/���e*|��/_�$ғmzkn�j"T�*
gS��b���jv�����gXҠ�&�H4����(䇢8��z�2$߉�����n0�3�sxI���	R�)��N݆T;�].��\�M0'g->DC�+R�Vw�iW_�?ʾ.?F��P��GG&�D��D4�$��b��D��,�jl�$n���o���x���p;�a�$͐�Ќn�Q��qa�Y�7di=v�߯C��&�TS�c��a����=�D�- jRr��3����0@� ~��d-H1l��x#�R�~��:��9�ZZ�ӳ��D���=�����Ԭ������Dl鹤G�:��G���� ���q<"��j���#!��6Zo$���Y���7����i~�ᰄ�v|���?Qn�~2
|����n�~�3ج&+�5�X���Z6���.�Y��I�j�	�1�q�,K�����1Yil ^?�y$���2�J�(ES��!�e
{��.͘k���>j�]/^yF[�!Y�^FwG����*���:�N�;�������_���G���-�۸�n��L��\"IL��\m/���{��a5X�,B>>q�tW��VL/�_h�~�Q]\�}�4#��f"K�܋��x���ˏ�� _�����G�vG\�+ۮ��"C̕i�]����6U����g�Y��V�|ц��+���/����T��1�5H^������d4�#��z~�ʪ��c�e�����:v� _�5Vi,G8MB@	�㰢�hDVwc:|H3O^5�8y���p�Ǒ�i��L�;����G%L�k{yZ�3��Q��g�����+�^��r/c��g��s�E�6�y�)J)ހG�U!����!�n��Eo��,n�}e���F�X��#)�����#�xfQ��T��������i&��B:��2��t�����>Z3$�=�t�q���sQ�e��#����Np��xB6��?����f��c���_=��%��������JL��Z�پ���WhJu���mM\I_ǫ��k�,4���Duz��7-�h)q��;�d�
��P��[�?%2�`-���޶LR�'P��q�(�� �
I��G���R���7~<��9�t���I��2�'ҕ^�Xaa὞z�B�=�;$�YU�HVq�c>3�T5�(��/�on�_�\�q�IY9BHg��v��!2Z|����I��F����'�|)(⛞�w��ʶ[�-��8)F�G6F𰳹�<�cg��,[I?P�D��n�gU�V�|13�I@0�-�Q��w6f��-Zqj��
tƉ5��B[�m��@��Ig�����jV���^�E�O�^��� =������N5������Y�Ϊ�-_�5P��yN�[]�!);��o��l1�<8�?7������)�3�s?#������38��`����0��9Q-.N�?9���b�ZJ��O]��Ki�z����"�A�d7��Q�f�a;�\Ko�u�Ts�I�Gk�
Q�:f��6��}X)�:(Pp�����(+@Dበ��}��l.�{Uã�k�j��D��6Q���7�k-����M�`
��L�����Y5G�'�P �,X���r��u�3gs/E�e)^뻦>��&�L���4뷅|�8�˽!W�O�f�w��G������@���p	sK��э����"FY�v@�����|��3�ŋX�/�	���c`��E�,�H�N|JW]�7���QdU�P��܎Q�A����nXBS0��(%�Mp�N!�mU���O�� ���x��k���~kK��,�� C�{���a�Lzm���R~N�Ѵ�%�P�L�K�����0Wc�S��у�� ��3�=\Y��$���V�x�C5鶐9i��W��10f���ht_(�]v8���%�	��m3<�-Z�h��Zb���NH����Ɔ�>PA����i��A�}.�S� :*�_R/B�0A�~�;'�����ؑ&eZԛ<�q�B{��4���u�
>}����,�}�p�f�G޶�(YΫ�X�+W(e)���$'��op]���h�K������޲[M~n�o>��P�a��|�J͝y&���&����r�����BOd�8��)����@>۪?������k��X�'9�~�dg�ϥ��p��>d����C���w�49&{�*��J���)Ŀ� #����rǒѽ�&�g����9��\o�$t�.b��-�Nqp�����ܢ�\�{�7�ms�r�5�$4�Q�N��^���-�=��l�Ym��r�ڬ�2�h٩%�AH�а�AMx��*���$ꕨ�!��=��O�MF��[0�B٬��6���g��2�KV��̹K�V�|�Z>Q���A҆mc�����!��lrE�i?J��/�bY�&M/B>	?���T�흙&��vn������������FP ���I��10J�����Ձ�'��Č�����O|����A_ǁ��pW���9�3-=��ǥV9��%!L����>%{ ���A{�X�u�zMt$�|�O*R�=��ե4a��l�&ɥ�Z��/��������pX�!��ٛ@~�n�f�P�j%d���r6ul	��+�Ag'!����b-_��"�F���Ŝܛ�ӺF3#����6_�K�|=�������,|����,�+�ᏹ�{�#s�H�l���~A�6�V^��Hs� ��=#$�/�K�^>���dP' w(�����z�� �[���Bdg��|ՙ0OBT�R-Z%g18�(�{��P�gP���'�FM���.���2�$Z���y]D��`y�ώӤ|p�JO��PVE$%��f%��h�bVW�;'Q�T���7O��	��#�w�|�5�#�oU���dI���нJ���#8R���=�ng����ͩz-Ӈ��)�Ryk�����W(�[ \�x���³�甋(�������Dr�`!:dT1�+����<�:GV��[
剮?�����e��W�v��^	�f�#x��>�M�!܉��l��;�U��Ux��y��r�Gd�3v"h�?Յt�.�e�όپm��� :[~mz)T��jbWu�q�P�i?�5�:�.��^	�!b캫�)��D2F�� ��z��Ra��G�t� �;��-)�MҠ�7�&m赣����[6������a�M\�t�{.���V���u�֢�Ʋ���9����j����Ci����j����县�cP��$�p,),�uB0��a�AW��XW�SQ�?9{�����P���!G�Ђ��!��[)F"���	Ww�bI�u%��A�>�\�+YE���M�Ժ�ж;�B-��n_���܌��hK�z~n��a������i:�����S�T����cH�hJ�G�+�T�O�������$��� ��������d�Uq�x�Ӊ��FR.��`���W-anYb}.��ѥ�ųD��<g��GiF���W����ZY��I�G(ρY�Kv����9�l� M����DvA҇�;L�L&��A��b�Zi�)��*,c��s0@��m���?�o!H�b@��s�{�cԶx���>B��"��X~�]}�@��-���0��r[F0���|,yST݁;R���j��셼�-0���2��e�ei�U�0�P�����Qy�ʂ Zl��h�	�(���?pq=��pӑ4n����ॡ<Ą!>�U�p,tA6�,�Jo��f9|�R�:��DW�TE�yf+T	S{�Pw\D���d�h�u$��{7˒�>����Vŗ��RF�Y�«+��I����,|�W�ҕ9�>��$���CX��t]E�^k=���oRF�o/|�]�ʷw�I��$���/�av�
��;+u�&�h;QNH�BY������yd�Qks��>�0�������c�߂�L���h�����Ƕ�ږ�Ɠ�>M_,G�Ҕ�������6t"Xql
7�	�i2�T�޷i���k�����!?5����<��05ʌ�q�G���ύ�Q��_'hԸd�.�
����,�3��Z`i������Ė��FO(C��w����W
,�~��s�%���f�
*�Z��;|���}��/�&$��O$���'0�V�Y��A���h�9~���T�Nx5���@{�.]�yk��x����=��A_rk�%�7�q���;������tMa��� I�%� Q&)�Q2�N��}�V,��aeT���Cl�K�실�_���C��36�����<	,�ԈDRMݹ8���1�$��(���9�X�9_���~�à�B7�<�Q���l�	�?h1�ѕ��7�
Єo������l��5K<��Fb��'J����������:p�U�����N� ̙�m�X��hlٜS9�����x���L�ǲ+�a�}	xs�'�
�^��3z�O�~������v�k��"�vu�gPI���Yr�]o��rh��j���-׷z�Un����BH�s�l"����]z���pdZ��p�CQ��f�W;�oRg(p=�������Hz,�Q��
�-�gʣ��],��|m<�ے�h@.��BG0y�6��N��K�
>ؔ���f~˱�XtP���;m�����`�#�'���/@�(kP��2��=&sRt�?wg�i�M2��q+�#7���e:#�e�5F����,�2�p%�5Lʱy(C��
�����@K.��EF�E*�@�{�Y��k<q-[:�-u�f� |�d�i��%�n�.G+�HqF����mg��He��gY�%n%m2!�4�g5�b:���3`�o����ƂY'�ȶg�4�sn�U�SLIn ���j��FJ;�.V�a�(��P2�Y����{1�{��B8j����L�.�`.��B�� �S,����ʃ�Џ��:^+LuW8t/����N����yl��������j~j��k_��#p�����u7�(�q��R���a�@�&��=�fx��X�5�`��NA��^k����z0�T�����)�I|�sj}�+L��ͩ�&i	w�4SzPRY} N�ț c7�u��Z��$��y�4�#��;�_���J8��d�U�Oe^�fl`�ȴ�/H��������}�l:����d|=�o�_�����f�{�w{]8�]�%9xJ����^3�i�����1�?�o��i���ݯ��!ڮ�X��И3�s���]R�Gc7�H���Ky�_9U�yXy}!�4��#��
y:߄��G�����n��E�}��Z ��/6�3�n�[P%ax�j}�+0�S��6ݕ ��s0	7��j��E�3N�8��e�fK�[i�v��!�Ƃš6RV��
�l?��:�^�� �[.*4+w����lI>�d���@hV��;l@%�e:,F��btal�1�.��N�T�<���%c�(4Kg�������T�>D��n&rFQ�����
�������~���)���~o����=җr�`b�=�=�sC�LڷC��v&NTꧧ�'l���d�Ƈ��A�8Z�BF����'_<����.�k>�UN����]�^�����m�sd�ՙ>{��$s�O�h�}?�݁�ɛ, 	t#d,n���D�c,�uC֢��B%��mt�l���Q�p�^�d��Ϡ�*hl׆�.@�%9�E��]������$�H�A�y��f�ID�D�|+��iډV/I��s;��L���$κ�h�Aw�;�yl�O���~��j@�H"�W�,E:�5���`�L1�d�o9�j�0V����~�I�Y����9�&>"�X��'TH�f?Ms�qU�2v��k���Ke砎�z2�F(��o�K�Gc��#�Eԓ:f����|$9tܬ��%�)�������@�36��'"'$�{���҃2��_+��
�%`Y�TcPz��d��%�v�*�"�E�Cd:���ӱ��pf�M�Tl �m5c�Թ���Ue:� S���
<�a݀[�A6 ԗ5F(E>p"������G�ݱ$^����L-���OP�����J���(�tzS˓4yK021�Hmfx�nS��e��H���V4�'�")�喻��S�:�Ws�l�q��p�9d�Mf	�� /Z�N�H�Y���a\�!��������t�}wE���?�7c��xC��ȗ=s���?yA��^��Z`�į��6�1�}|fh%+l�p�6=��J�	��Vr(��U��6�\#l��v�Ǫ9-;���X�U�]e�H�7��>�׽��C�xN�rϊ���{��0�҄'���S_��7���)%�۞b�zO�Vr��b����	�j6�{�_��?d����x�Y���p��m�a j~"y8 �eh���,�� [�e��e�SÒ���!�������xh-�	��Te!3&��Qҕ%�gP��Ŷ=��3ckXM7	
(�)�BRhf)�R�ϟ{�M���p`T��� ��tV$�Vg�1�KtG��yiȽe.��E|���\�]�f��-]�s}������ԫ�ՇX��,,�T�c�V'��������3�	o ����?"W�����eAB�����|�v{�:ȫ�'���(�/~��?L�t���:-q ��'�[���E�����[�5��Kt�r�-3A�� {�ZNؖLuN�$/8"��6\�����3^ϸY���w��
�9�O^&��M�F�Ù���n�ѻ��A.��`����~�2��f�@[�0I���iH��f�V���+F��&')��w|���̓�(�9�r�㗌�
�
�~ײv�c���YR1E���<L�`3����lBçi|�U��ܔq�p�#P����]@n�j����5J�e�O�ҰIŬ������~g@�5|��:q��t���"�=J�qJ����9(H���/w��%�Q�$IK���Jn�1�x���Png�sU/L���lI�����`r$��g*$<G��3����_�� v��p�^��S�����60�h����`��`t=�iǥ�A�g��S���A��v�W����h��&���J��rW��I���Y�&��K�W�N���-13ݝ�LF�:4�$�O�,�qhgҤTҬ�C_���dM�?���n���!-�l�+m�\?Gt�� .U+ 9ŻRU��C@�HْT8��5�P��>b�[	e��B�$��	�B&�P\B� MEJ��ޚ�_���t(B�oiU6O�mĲ�v�@�Jw� ""�e���X9)| g�/@�1�d���IH��U�A��.K����2�q�nBSV��$��H9�<{���w�0l�a���ڦ��XE{j�))�0�t�94���)�2�3����6� ���١�I��1��Ӱю"�ܛeU�O�Ű�|�d� 7ئ�1a�#˧o�\)�MmQ�c�ghJ¤ⵛ��CWaC�׆/JG�a���獁�8���p�3����	~�pt�O����`��+Xw��
�D�F�j��<Z���K�$� �艬���B�|&O���������'%� y��G�+y��ak�	���\��E��$n�o�ݛ�
���`����Իl��3���`A�~��RG�4>^���%:O5����-!��z��gw�eY��7��?�A�K(4��)��6`�<6${Fz� Rf�Q �e�xPb���i���2aY�Ai�h�̇�B(�;���[�w�P���Z+��4���c�ȡ���^�$zXy�6.��k�ҳ��M.�)��Ҍ�+l�~
��Po��r�Tkg�Fu�v&�f��vV�1N~��'4��� 5W� ��>S\���.s���T�_�}��!��џ+�Vm�f����K����G�'q� a�V�ޔ��������r�3no��9][�������W���bA.vr��;xKτ�[���?$�92�V|!h�a<����Ȭ�F �J� �{D�F	0^�ISfr�Nm��MvE}upu���3;�_���yL�_�!�T�Ƌ)����s'�4<��؟��Q[?vm��-'�N|#H�!�����1_G���6B�y�FzW����S{h�������@�ہç�ϮQ_�U������nFZ�}��C�;�bY�aO�9Lx�z��xMΡ�>��u��?(��!rA2���[/W�I�,"EټM��/ ����^����g/u��9�rї|����]f�ۊn�se�vJo����"��cEGp|z�Nv�cS��.W(�^�mp���g����9`�	
�V�)3���~��{n�>>awm�~8��fء���#s�_�˾v�J眊�M�%�g�?�� T�a�m��qa����Dwo` �,8�;����c���{�	�Χ!p�Z��
���C�V�݄wN����a�+4����?]!<��ʮ�5��x�E�k.6�%�6E����U� �f�A7�'��<�[�Vu3G�j����
62��I�u�[=�� ��g���� ��l���b`p�
D�#G9��GG\iz�p��m�գ��FM��sNK����i��y2���*c��+��Ft�����BЖ�����Ҟ�ՠ�s��<�[1���xKvP
Y�sX��2�}]�_56�ʀ�)3%�/M�gM=��,�W��[��#��}$��9�����M���d�=�"��	i��Dù��"p��I�^�tkS"���c�WH00���٩�	e�8����]I|�~��������O�g~K�{�I�xW�ԛI���w�Ő-rzz���V�9Hzӯ�����xV#�I�o��Ұ�<"�����4�q����_�'�����t��Ț*����``q(H"T���X�����.���_/�Qlg����,*���_K+��)~P�/�ږk�W�9��0�}4��!%�6�|7�L�E��Q�g����s��_q� RTJ"���f&1��b h��Q�i��P�?7��4;�n;vlq�jX�nt�<)������]� ȡ�4S�8�;�
Dx������f��:Q������"��Y�K�2Un��c��'��#0�`�ٙz��*�xI��6,mL�ْwX��	#�7��]� 3���QQ�H����'H _]a��]��)���I�S����,#��`Q�b�-�ܯ�N�ٜ�3(����6׹����G�&ȓj����������w����������=�ӳzw���7�c\�d��wFr�c=��^Yn����@�jb	/=SF-�"pb7W�n���l�o����mĝ^�*��/9�g$�~\�}�>����a崼m�dui'�+o��6��Nnv����Ƽ��\�u���V�]f�����`14�I�)4�\|z���+0�z�	����j(
���{��:S@HD�+$�Sa�nj�W�:�͵��?�rP�M�kE����-�m��e@|\6ڰ"�;�q\��L�����Aw�dmr1'����ϲk��z���)?oϙ�Y9�����u��T����3&K�%�E�Ǒ:ZET!j����2����l�"D2�_c�a���~)�?__�'�������kRӗ��֖���)�Z�S��
9�(D
R׹��#<B�+0�k�*-7��}�+�ݼ��|t�
���uILS:�^���x�ʚ���1��1�Q7N�=�eGD�g��;��VJ���%�+����K��I�-:�f�ͯ���V g�TFP9g�E#���,076�fJ,������p��_�@J�֕�)������8�W��/%�x|#s��SO3Ի�'���Ā�a'qfT��)Q PH=�\o�@��f��*�/��ߖx��d�����x���\����n\!���<+����-0��\�:��8P��Q��j��ၤz
�c�v~F�R��'�ͿRאy[�ƚ�`"v����^�_�v���H���h`���_ݤΜ�視��"�;�~[�X�u\MB�
�T*̤p5.�t�H5 HD���L1�Zo3�*�$�&���y�z�2�&9L��9�ɗ�����ؒ�ྯ�r��?��*������Eðd����j��7!����a#���*M�7D�7���	*�b�%���SN	F��34��SI�X���u�"z�h�m�M�϶��Fҷ����!����ƺ6u�w����h.�8exK��Q��	��_0Q��௩*-�U��Prh[;)O��H������`y�T}��҈�D��	�+��z R	V܅��n@��w9#����E��wL\XLQ�w@����G$���>�%��U�仟=`A�N�`�Q1N�����C��^Aw9�-������
�ƥ��"y���u��@��cD^d�y��t<z/��3A����+�M��D��}�:IO*��`j����j�/�QO1���ݙ�>6VC��.��R
�����U#.�V�F�6�7WQu���߭����A/�b,�s�{H���UT���ч`�5(��}�Q?�C[���2L�~�ޝ)����
��P�/߽�9�$uQL�H �'�K훉�i) ��2�5%#`�}�n�?�ۑtu�gq�W���7<'�6,�ן�$�tTr`��ZE�0�)���7@��˙yHآک���ߔ�a�QE��^���d��)4{;�$�#��}4�X�:���{�qȧ'�GI�u�{�Y3Ɵ��u�\�]����j�i��lz�mjEs-�[ܵ�+��;�#F�&������a�vA{8�uf�vf�,r�H�7��k��t���}�y�"Bh8�9�Ƣ���Yf��c%fu�����&�{�����_׻�F"Ãjvxı����\u�����+i"��]���+V�i� s_/,N	�	�2�=��Ϭ	��.l���a�A��|���$�����у\�5@g7��� n���G�4v�����X��M��%@����x���(��ï�i�G�.��⋾x���7���B�L����nR߾���bE\��z��v��}�eP��[H-wp�4�d�=�>HoLbeԸ+���[�3-���p��Gi�k�z�FX���e׈p�
���K+5���v�6�X�H=���� qĜLt�Jx��>��BcnO9B��Y�����GT�%ia��@�S
=h��*qؖ0�~-iZ ����H�a�:� M��z}��(���t�g�4.�d���"�+�4�J]��0�!���,Ԟ,e[e��I0 ̢f�Nd?k������o ���8�0���ms��c4@��@Q��+l� P-nY1v�~�ܾȨ��۠AN��3`��fp���؛���=�������i�s��Jp�����w�)Q�CE����ǫG����햹ok#H�-�W�2U`;�.I�@�l�Bޠ������K]�s��1�R(�ơ���0<֓�G[	�\.�~��������~�g���h�	�>9�w�,:2��\̟��Ki�P?��&&	�;"U����rБ0���v9��@����ь3���@K��ܸ�V�,��#Z>�^�]m��N6�;     u�1Ld� �����ڣ ��g�    YZ