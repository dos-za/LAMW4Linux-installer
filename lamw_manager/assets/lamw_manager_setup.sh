#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2248067410"
MD5="6a47f9d19fdc2c4c70162149cbda456a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22616"
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
	echo Date of packaging: Mon Jul 26 00:01:24 -03 2021
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
�7zXZ  �ִF !   �X���X] �}��1Dd]����P�t�F��>>	E}���_�GD������p�f�u����ӧt�"�zi�a�B����Qc4����zq}:��$6����CƏ���ޙ9�~f��K�����frf<g��D�Tp."�Q���t�4
^��{�mƅ�{�Z�@�I�;��Yf�˴�ښ4�a��kW9�)䜵��zO�j:^u�ڻ��	�c��?��Ѕ	��5	o��l�>�?7��>��)���vK��@�auU�l�!X��Q-�����o��J;��N4�v��o����m�Jǌ
��?�1:/o�-��F��?�*���LaD��a��)_�y��ga0�U�]��!Lt�P���S�<a2�<�$�E�T[�g{K&���DZ�3�f����۶���OU��0��ݽܶr�l�"�j��'EʉnV��EK�-�@�#Rb�֤� �k�c2H���}�^	�>�/
�J����2וֹ��(���;칪���RW�H)tM���K�G��7-��m��I���a>v41�.^3�戱e��տ����15�hkQ7���ƣ8	�0��:���%�ZQ���&�`#P߆PyĔf�4>W��Ύم�#=X��nG//��5W/Xz��Ul%)�]���B�<�������d(��c���?�D_? ���W�L��R���q��4�+lL��
��/.I�U�NO�sB�r}R������w�ɜ�w���ݷ�`eV�/���7a�y�*�[^^%��c���W�v}}����Z�*��#w� ����x H�o�N���!f6Sy�R��]?�ۘH��_��:���k꿚;qv^��o" ���iE�w�-:�F�.�.�Mp�^��L
ߖ0zs�L�R��ڡR��+��א�G��>�-�Ȧ� /�^z'o��Ϸ�%��^�ч��*B��S�|n8M�x%����i�V]��o��"�����&�~��0C=�~XN��z \�LwI�Q�֑ٿ�4p�a�o��q#�JL��bg�h�1���W+ܸ|�U�W��=�E�h]Φ���Ә���.?�F2�`N�/;�4<�MLS"�¹�R�[}60N�)	�*1a�i�Y_��1#	~Ȼ��\ZY�C�w�N:~�[��B�|���.�H��R�P+�.3��k#��:����}�q�T���;%�J�b��*������E�^�s�7	�E�5�����I�E�����	"����)Qo��>i����{K#������q�5��B�s<|��Ԡ�]�x�#}�t�s>��鞏�u���V�P�I�e�&��!�����I�K�'�Q~j���t����P��~�N�-4���|��j}l�j�)9��#�8o��w� ~���wqWr��i�L(��6��)e�U$��.�i,ՙ��'��&���+KC'�ZAe� ��-��ȱ��A�u�P,v�����OFz��H5�?�{�;�Ͻ�r�ڒ)��
o�B�E�a$p��cKCfl/�
���(t�ڙ�~�(m��ї��.ޏ8�F��9:}-a�.��8���Y�����gB����R22�꡷�E�2�ד��6$b`
ˢ/^D&�б�M9�j��S��Hڝb���{>  �r,X�����l���?�AWɞq�l���'�Z>%+I�����EKm4�Z�1Q�ywp鐱@��ځ1g�u+Ҏf�!r�%y���~m�T
M�#ŉ�	��J"����B��8Nh?n��R"��8n1����-޾�l���l�+K����l;��s{xk�~�>�jOX�V�W1�T������.��d��McC�2i~�AE���524ߨ�4<8ωV�V��r�d:���҅*I-����	�^W���)�mn"�j1JA˅��)����]���5@xDOY$�u"�/v��M�6���eA����ŽQ4EA'���Z��W��Q�ȫ�gjP�X3��}Qu���4>�����,�7Z�� ��0�/�"�e��@�,���zx��.0��/@�qH�ҟ��{�ш�SD��~ef�����~�Q�4&7<"6\?/�!�����'>#�g[��$��Ȟ���1P��&X��;Gqc�����N���m�!.�*TT��ð(��G0����Ju���d���m�k��{���a%��d��o�8��	@���@����4w��k��{�:zL/J����"��6�C!�{�+{�ٽU��U�z4zȅ^j�&4M�OퟹU:�-��¯3��r��}L+��Ce=O-U��H���LFV��D?>ب�<������7�z�p�I �:oX|��-?'׭&^ԛ���\M�����앤��r�s��*�Ԃ���i=��X#�kl
�����2BOC�D@�K��p��w��d8���֭9�e�K=YV`�
��Y�a��{��k|�J,��[�x��7 ����ɮI�.δ!	gy�	8�'{����/Eb�S�Y���;�U	��$��S/�!3�أQ{�I���p�G6@s;�r��Qě�䷫�p��Z%E���$8��m\j/z�Y���tKU��/M�U��8/����ݙ83u=��0�$�wU����0}{�m��	KK�K�n����#�j��VXv��᎕o8W�����Ϩ\�GE��#?4��[�A���ٰ���f)jQ��g������Q��Ì H+�:~��,�)��B��=�T�(B�m10��/��5��˟v��p�i�L��n�'��ҫ�� Oٗ�������&D�]x���K����W��S�c׀�Li�N�h�=��������d���5�,a���ȹ��AB?n��^/oE6KmßD��K��^��:�#�3Ix�x�2,"�.ߠ����b#��/{��rni�:��t�ͫ!V�h;q/�5�u3q�#އ݃8]V�S������A�z)zl�0y�P����t�}�Ӓ\J��[�<��r���G�#�:ė��G}/g�����{��3�#ګ��SV��)�;�$���I��Ã�1�6�!=4��������mA��a9����q�;?��o1
�X�"��� �ʰ�	������^0�?�iaRz��~]+5��3[��q@�����DӴf:��kC*撠�e��Ĕ56�r�_�(?_
2<�[�T7�֑�����c
f#(wp]ڄ�k';V�jDW�o�ʛ��xy����
2�.֔t]4��#>�xz�/�@�'�>����^�B\���@�HX�#j�!����V��'�j�4o�A�h0"���?��%��3G�~ZdC��ɜB�n�wob�t��Dٗ_���"-��)�Q�쉮o�h���u����<| q�%ʟ�8񬕸2~���ȁ�炤S�U��9_3WwaV���޼.dY��r69V�8����!q~��
�1h�:�L�â���!��QZ�-n�8[*�j�ڧ?�t��.��� ����)?�d���@�c"@E1a�D�{\��nIհ�WV��o�UrFx	��mF:�Eu\�q�Y?��v�����1�?�i��2"�sʟ��N�p8���iLh���[�?�//w�NM�N�U�	��Sfo�C�2@Ð�" ���$��R�9��{�f�v�rJ���c���A��*��Q�R�į�f�#ں(�-�X����ї�3<Huu��)˪apO�	�eC\���UQ�h� 4l���˧�#�s���ׅݴ����*���I�)��ӟ 鹼e����\��:S���lE��$
j�uk"$;=ddxHvۯ>ѥ���ʻj�Q�א���zZ{��ߎ������䩥o]}�`)ˠ��6Q9s��$��4�R��t�9��	M!�P;= |��j�A��
.���lǤ=���9��t3��.M_��/�i������{�js�%�j�,�uyĕ�.�i�#�BUovp��=�6�ZfO����1�ػ�DO��6��#۸D y��P��8��ƈqT���=�[=�Kh���d�'�`�, mR���g]������99���?W����{�}������4�o����9i��	5;��ڃhn�';EH�)P.S�邢� �� G:�2���z��	�Y-��
u�B���Ⱦ<�u��&R��<�BI ��'S�����
M�g|�OX,f�$�.f�x,�#I��i�'@�<���
{$��-�&��w��V<6�xӇ`��j���h��pm���]����ŊI*N��ב��<�x���tP|���S�gg��j�$/x�F�Ϗi6sLצ"4w`_ѴmC�]�&S{b�����'SlGw���0C����{�c:������p��j�u}�dv,H~�`���8�~��yv�kG�X�Җ�9�6g/!M�a�$�F���-�E7�I�xRi�����>V��q�
���=a��/+�XM���i�l�a��"AAZ�~�� �}351����P33��K��u'��	����popuzK�����P7�>E���������q�F��.c]�7/g�� �+�}����N�?G�.�J\���ؿ<#�0)˚ܹu�t��RS���1��v�Տ!�p�!� |&Ţ3<n+�n���Ն~��?7sY~��_��o�["�!��<F��n��צ g�_��\���_XE��&����y�ߒaR����M�$�&����pГkMߙ�_o0��F�H�������i�o�!g݈%a�T�D�{R�I���uM6=
�4��l���f�� L�f��^�s����g�4W'1f�2�6#�Ou�YN�l�A���ZlIg���X �sɘ�J��/%k(��E��b���qf�/CJ\���>2�����/�cp]y	 G��L�B��0k����7��������c�;����Qa{���!���bHk��i)�e5��/�s-u���䑃:���c޾�8R�t�{��^�Ԧ��W�
���+�>�zu�4�H/��@��x��XP���*�Rh��0{WM�A���Y���Hƪ���@&ګ�$��t��,N!RVt��	��������"�����wf�j�'��W����1恌���ȝ8�6��n�I,(�#�F��Wa���-!<3N,�(5��f�mm��OL}I�BiP��?9*����Э`��D�����|Q`���A�!��n�a�{Qx?\A)����r��t/��I�ӓQ�����穗>�o3+��I_2�G��c��������PHQD��ώwF��w�d�(�3�p(_�,G@
�K���T(�,��R��7~��.�$E-$��I�"<yG^ ��������Q"iʭreQ�AÆ����A��d��*��DQ�R���;�c�D��tSΥ&e!f�%6�Kx�~�4�j�]�+��s����
;�|��+����@b��ʟ&?��[�U�����~A�TD��Iw71�?�p���T;�6��n�%b)b�Rf�TGN����)�b�C�*�v����j�0�`:1�jx
��۟�'���R�o;ـ��Yν�քT�0Zm�#�%�E��� O鋋S��sA��\�XI����`��^{����`pR?K׌$zt�߄i6��v;4T�F��I���4(y{	�QQ�N�����O�m4����=y���iG�cf;�W#��\��ZV᪻�
T����6�G�F�9@�l-�]��B�E��R�!�9%H���*�|I=@�
�#�e�vJ�V���xZ�Cd�BB)�h'Vڻ?����?�o�RTc,ɱ�ݏ���@H��4,��)U2��O��@6��P��!�M���P�d�j�Y*riG�)q�&��Y��6k�`�>t�J�$ġHP��q��=l0Tt�x�@rۂ�=Bg� A�G�(n����ۺ]P�6!qu��qo���A���D#��"�I�h���aS��$+��o�ҪkS9>�b�xrRoc��]ĂA�}���@�����xs3�GE���GI2��!i�[��
��	��'�����WZ-�@����H�mopn���.����˟%���x/G�Q�����a�NBˉd'�Yxv�����+ڜ�;5��_U����P=ѳt�R�^~�j�}���A�r�E��~W��`�S���ԭ�>�k��9�6�xz��p�t�l���z�-s
^4�Ug���bQ�*(�rP�)��VQ���	J`!�r2��ѩ+�<��?_�� F�0��,����5D��%��k	QK�hU B�6s��Lc���E_=A��.P�N���?��} 3 ���Ԏ6m؜l�k��__o�K�$K�瞋��ڢ1�l,xe��=ڴy��.�Q�b'%��KSm� �>@�K�t�@��#���T��ӸLs	�K�%�Yښ�T��6�&Ч�ܯY�B�tlו���u��u�q'wM�)v�t:SP�������2��?��=�j=����G���X7R	�L��7z�wإ�t��T#�X@q�M;Qu���Gc���qQ�A��&vQ�67��#N�k�a$zuU��LVx�5�+�FΨ����m��u�H�j�0F-�Xƛ�b�g�6�{���c�������ri;,�)������{Ķ�Е!�(J��C�5�S���[dj�"!��W�Q�C�O�RÄbK�4�gS �����6%F�|@ɸ��@J�s��.��}OLq	�R�����n�t-�K��mf,��MAf�6mX@ɆgāS�l}IVze=�>�#3���=�J��S�l_/w���+5e}.����L�$�)�Ցa�3������%�n��~�ߢ�_-s�2��&�>D�@�M����ķH�	��l��lI:{𿄶�z�Κ�O��c[�wN��p�vX<G%o?�O�����rBr-��ǟ���l�}uy������+^���K�*�� 2��)��$���c�IR<�{ Z?��FMU�?�2u��42k)��쒃/�T������f�������4Y�5#��p�UT�͂��_>�,���T�7� G�J��qj'X�ɘ���?�����b�����t�C�!��/���	BBT�]U�i��cQ��~����@�*'.r�r��^^�9:����Q��j�(�gBr2��	�r������pPNx��ѝ���j��y��Sw�.�15���=��7���߳`7�[슰7�	���n�ѥ�?*axy)}�����`/��)��$�/p�k�έ��D�Ȿ��;h�z�}�n�n`�.KwF׸(�ij�}7A~�����f�Z��i�@o�p.����3���e�3���"7��M?#&��'7��ٴe�n���V;5Jň��kȪ�����ݜ�0 �n��r��l$�+h�
SN~��C���]�_)=yd��s�t\�Q�'=�o�|O�P�m��K��p��)��,�A&��.�^��oD������4�'��
�>�?}���H����8�M.Zݰn����7M[�ӄJ���E����rY˔���lnq<jf�/�F�@���1çr(����X��o	=��!�����T��ێ��9�T��L��PJMW�[˔?��&�IB,�r
����{��;�.,��(Zu(�����_�;И��hF����f
	�O�n&��F
s���i��˾��C�����E+4�n�'��J_ړ/�w��=8m�h�
_Ss�8w�:(~o�q�%��W�.f�4"�bm�;MV�W�A���{9\Z$��k� �gI�s���۾eV��93�`A�nk�h7�������hD3�����[�Y�Bh�S��`ڢ:����^��6��?f��R���%�T3��� ��!����hsp������Vm�ք����C}BW�	J��7�����J�Ҫ6ef�RԜЀZ�v	N�*ؼ�H��:��>������_�\�05�m���v���3]UssK[z�I@� ɾ��
Ru]�u��jc�~�r�q�F�'	���+��l�2i8X����0���cL$�I��SW%=��r�[�[�ԏ��0��	]��p���a�a�q�Y,����e����n��hqƽ70=��ߛ�!3Q��H��%]�z��ku�������6;���YAB]���W�^@<֚�7�.�Zς�����d�9/F@��!V~�t�%��w~��B��=�I�+W����&��G�|*�P�!\W;���׸�L���S������'Bmv�Ok�Z0�������\�Y��f{f�`��v!D�|�œAl�������B,���O?``
$�>�&!I���c+�o�&�<��5n R/'��h��-��Ee���ڬ�(̨��w ���:S-6�j���\&IZ���5%z���y�goz�\m=�z:uZ� �e��|�aY@w0{�U��$1nJN�.ӂ�q[���~m5(�#��x�K	�Y6������1<W"+�2�%��9��1e���O��Sd�����r�+I�����F'Eh�ݘ�e�9U�0+,n�i*�����,в�G�,C�*G�+�p亮���jm(�5����9Ѹ����k9ȱ�q�� =�������!��0�w+��0.z����J�B�ȳ�I��2��7e����~{��6רj�-G4���JVF��D�����&;��N?7�)���8�h,�Hn�/PH�h�PZ݄t�d�e��E���C�R��y�
##\���"���vf>��	��f]K�M�ρ�Z����M��T���Γ<�i�����T��us�o컎v!DL �,ڭ���q�{�K���pּIk��*���#*H^��H��[�/&A�����[� #!�
� >���`�.���Y�_Y�eT�����c�W��_�]I��K,Q�T���o\#����"ը�Q� ,G��:w�er��I��w�i�s@�`Q�����?W�)��	D� '`'�^���`{O���h� ��E��S�~j�!�m��qwX�7߁�8�	s���FjR�^R� �xl��%n��!�g|���	�bA(�cf�����19A�������*�0q��P�*ٸ�<Uy�Yb�u��������S�#D	��PkZ����Z�\։�I��8X2L8ر�����r���s�锚�s��_��i]�yP����8b�1�1�^)E,��_u[m&�o�#��E>�2𷐈Z{P���r���¹1[>:6�f�#� m�@�h��X�b_JT�e��U����S�Y
2���n�g�t@����~Ժ�u?�?��czD�Ssʊ���U�����&DB
�����D��Y�#��f�V(ܙI��p����+~�O���,7&��DFjv�)�д�S�FD��lǑ�;џ\����U�7�"���ٺ��BTM'��袈������O��λOޗ������v�ܓs��pUNȆ+�[K�0ם���ϾD/���-��$��%�ZO�UbXR+b_�����5=�������g�5I������;�"tųt=�颕�}-�6�-~�{l�L�>��q@�	1�(����,��a�ە���e��������1�>��Zi�;��G�z�
�Qe
��Do����z�#YL����º�,�zσ�г�2B6>7[%��Z3�!�6 \K�SQ5��r&���H<�)i��Fd?��\�yr�m��H�KO�y5�z��rUB�r+��Kå�m��?��ho7��V ���Iuw��5��C~�汦 0�i�ǉJ�bG�iIR��rB�<���l3�LS�6���l8��*B�Ѥ���F!����^����8�3�r'�Н~�5W��.X4W����W�$}�P��{�lf�!2��O@U�����T��[o0)˱�;�b��q�Z'�9��V�j�à�[t5M�T
��s��F=�i��k��+P���ok$���lj��ߺ�L,�Hg�Z�Qϕp�2�奝��b��
�DJ�:��Wx���´��lۊJ:���/Ӎ�YW�q���`���;�Q^���*0v��j�L0�8z~���NF��/&ܟ����`���'+8߽^��+�}q9�Q;�����I���#�:Ӎ��iZ�>�\NF��܃��R!�n2\~ER�lzH�L�KR���D�����n���A��ч�	�a �L!HL��r lN����cYK|����u�Ґ�%�E�)�k�F�|��v�*P�6��P:�* �x��iW��2��6=�ĀZ��R��
�%;���,�fsS3^�*�� �,b�u�X�S�{���1�Ȇx"?e0-LO�Ҟ��%+�DC|?�4+����-��.cC��l5J�B�*�3�ΐ�c߈8`Vc`DDT�2{���y&���GT�h��K�
�_h�8�޴'�d� 4�D�*W��W�],�WF �M�)�����A���ʖ�G�=��� )豟�:H%X��hwZMA>�u�1j[\�����X~RQF��V2����l8��Z�f�y�LCjp'�xw_��eF c�MR��(�!(Ҹyz�6���W�p}��r�x �$Ѓ�8=d	$�G�5�	ԛ��RDH�U��{�w�Gm�\��e�M��̿$:�	_��MW�6����g@�lړs��?8���`8=k>QP9٤F1q�0��M٭[Rt=7�㞑l��K���4��7�P�"��-��م���O�V�����k��#�e��tv7���ʙ(����;f"$�bN�ڍ]�؛�o#a}Ms�G�i������{�=�=���NvK��\�t���:�BSJ%;fM|m�ag2�e��ؿk�cU�ެ苓C�^�H�4���Lf�����C�`ҷ���GJbiF3�n�7���� ��I��d�G�%��gc^�=l���)It���� bC}U�i�,m����Sh��)�M�c7��e�<�}�K��Q��J�J�֎�ZʐQ����U�s:�z��Xo�H<��x%+Y�p�����;nZ��jP��HF�a��z�����V^leh�p��ӆ���5.�z�ڊ��3��\,��*>�`G���~!yа2��O˔9Y��	�,\#�{�U<�g���>c�X�E����=�(��:�I��h�� �b,����9��/`e��;��x.Z��RV��L�QvV�l��o`����5�-��E
34�VIT�F�6��Zc�eC��0��߰~�W����<&�0���BM�GT1x�Ӏ���R\q�x�$�����/;�mWTt0�nTiz�E�v�$�ƖQp��{qH��A.$!�^VB<�Ia@�4v���L��X2T��B��!�KX8k���Xg��f�}����eBB8���j��\N]��;F�͖�H��%Xh��?�2��C��z��d	i<�[1�8��9_�\t�S.Z��z0)��z�U:_��1��KS��������$�^0��\��[t��~�> a>�_�:�q��>7������,1��'@��|�$p�%��l�,n�S=+zr�����
%�t}�f��z�b��4+���@��3�t�,d��֥XP�m�!�ۢ+ƥE��֜��/�.�e��������5���8�eI�hL�RY����H��|�([u�~u
�NٺK�V%>�C���������>a�;�*袗4%L;����_�\�.���r?Я�2����1?�'�D��O�U�~�/�x��y�]9[��DSk�o9Z�4����!�(j�K8������%L�yζ�ӿ��Ԙ�Vn�>�H�|h���O�[0f�[���j�JE>��g����Dr/G�<k�&8� ��G쐓S����]�B�>&���Cʇ��H�!	m(;@,J:|��'�Al�e<��|���<;4֠M?��x���b��h����=kn�X�I<z:�O��{+ɐO@q(\>Y������Dj��Ǖ/�
h鋓L��n�d'�P�����x�!����no�r���T����e7q��/��w�:k�dd�V��2�^Sm�d�x~��j�C��,����][��}��`�������;��݁怸�XE��j�o�%7�ϻh���p�zGYiA�V�Օ��BO�f���~���a^�/�-y��V����1&a�Ѓ���D�^��D��w�J'�#TY�J4:�i��q������Y?���`��kP�1)cw�M��^}�h0�EDg!$ںP�'V�z-��-�M����.^�C�q��.h0��8|G�� )�KY�RU�L�K�b��"��0��pP��(�ʸ�g�P�F/ҾܦH7ZLxMˠ5re���I�\�.�`�EtުLo$0q����L6{���Jb�u�g��2�Nz��z���}��{/FH��F���r�L�/c_�tS���w��p�q���a�ox��h��f��W�61؅�qG�4���+�0�;�� Db;�5
�Տ�
�χ!�i�G�q��\<��a�]o���T:Nm.���B{����7��W$�ff��3Ҁ�I�/��w���w�,hjdEqC�F�@<	�V���$��e��A��_��ŴN���C���s�vc�H�*P�e��x���[�S�m|8��Ϣ�䴆���3�D���k0%�Z�Ѵ������[��8Mxy΀#�:eB�I��j���L=C3.Y��A�}Y��p0!�?�R{u�j�1&>g=g+ޟ�i�_�������9|�R<�#�A%Wh�,��f]P5��������^s"�B�D�h����7��YJ�2��q%j�/��5���p��s)4��M>hlb<�sɊӷ�$&��	�lڻ�y.��,ic��v�n�o3u��Ԓ)�'5i�B<�� �p3)(N�5��坑���뮬%�8�!а�,���Y��e�@���0�?͖��sҝ�-��j)@ϓ��qi� ��q��ʬ^o��@�a���f�lh�W������挟'�6�"�Uʴ�*0�+�ET:�lV�.q~ەu��<P��bڧ0�+<�3a�lS%¿h��8a,�l��`Gi8ni�F@yaƇ�� P�'�ςтA��x&mN�	.��^����f�����[�ǴD+���&�c�d�+�<��֎��U����FA�&Bi��3PO�x�Zx���k�|���&����-����\H�h�d�_$�dHK��nkx�h�-�
LY�)�|������@���(�k���T��̴�u��S�L|��f 4�w�k��q���fSh)]���F� Fr����)1°���c��z�a��bŶ���3��,�5�N{����<�UZ�hU���ƂvѦ��p-��Di!��)����T�j�+��fp�%����ZG}t�J�5��$/J��E|�)e0FpOZ�G���bָ�J��H@㠼�	��}���|᥾2�-��#���t�9�E�D.�=����a��A�CiGXp:A����f���	2)���|���i�������P�
���5)Ѿ�Q�	rh�M0���vP@��M��G'ᒊ&!�\��H���,t�HsQ}���Y�J;�"<~zVdf�hU��u𷷤�Ĭ�e����[n!;dv��~�+�	!�����6Ld*��R�
I+�Ը?�͟���V<{eҨ��	���q�#^�눸���Ek�P�
�Oc�Z¨_�>z����e��ڝ����A��A�����m.�Fj�ձSC�sW|�w�XBN!o�/O��ie�֠�H�5��E=;�368Hɟ��?������䊧����Z�{���}�oG��ꮰ�������+1J���J�q�0/��/�~�i.�_c���X_�e��}���9a��3줒}�aG���1k�"G��U?,`�~�-�������I_ƈ[>8f����X2 Y��B�/O���tO�1 q���W�0q��U�v�Y �8ŭe"���A�ċ�,�ry>}�$��'P�&��nW�T�a �m߳���������{���`���ލl�R��h�{ZXJ3��UM'�c=l/I�i뎪��!^�Ǚ�\�n-��ٌ� �\�e������ܸWW�}~��5%s��l��\�|��9���F�����O�`=�w��f�pٗ'r�e�[Y��fZi�K�}0�u�� ��C ��N�C{�������[��4[����_�����́\2�˕��I>��.��|.nr��Y^�z}(r(Mf����6:���KP{ks�A����O:5���6�A��O����3���u/�S�:��4[�_�g�:�#6�p��B����ӣ#d�jYU�.c��-kt�x�~ڗ_��r_���d��E�/��M�Y��*����$釻�-3��W�����I��6�f9&���f|��e�G/���K=��'�f�՞`�����#;�1̢��@��̌Rw����vJ�m�*ډ3F՟Y*��ԇ����)A���Ϋ��J֓�SQ4a�nIT��K��q�5�93�j	��-��ǣf D�skL�]d���>^��H�t�j�o3d����;V�x��	e��/ǿ�k�!?����t�5�>�=�
�L~i밷)o`6XF� u����`T^~�Wg[��J����3M]�\��kK��W�P��v%g�k]D��1Ԟ���ř���
^t�I�./1q��
#g@������⪁����}�_��'Q|����T�śeX��S��l�?޵�D̚ן��;kBvO�-fBY��\�<�崚�C؆z��{�ڈ1�創���EKw�`c����)�R(4+U2Wh��j�{�ɘ �C�'혺�:���J��	#��+Ym�q=?���3�~��X���-햛�"��?xD��s�d��>k/ �%9u�QT��/L�S����I�E��&�UQB%5�̞݌�͹�5��G��Ѧ\�-U�
���AS� �l����	l-ѝ��q�MF��!5�g8���E\XJ�+/%�����^�
�;<4�1���"�#�r�>�ZÇ.�-�Fn@0Bς ����-у��X�főG�^��{d�8���jPе��^xK;��i:�-�܆��.8tH��+Ax��s��'*+:�%��Ipi��,�?u�a��_� d�l�_���ccrt������n܊y�����hg��y
�;K��eB��%%�$v4��TͳH�����˓_��QR
���#J�U�93��W�ƌIپU�B�����sB\�a�pdRx�Q�9n$P��f#�<$��d�5��5��0�)�t@���ǌ��3��Of������*)N���1tѕ#?#��O����	��+�<�CfC�Sf���t�'i�7�-�c�뼬"  &�r�Qp_�,WnY��9	�:�QRD��Z�U��O�Y@����8��	?^<��iQVwA���b�:ߋ����-����Y�^gtT���E��ޢ�G�C��H+�4۳�SO�z��Q��}��uƎ�?H���ɨ��%��?�sv���mR���NE�����|[|�,�V�]C^�����q�ӎ%�g2�ƃ�"lwN0��Xn �:�$e+pEr{}�_�{+W,��U.?�Hy�8FuAl[i������)3I�Yi�gq��
j���^_�U��
V^|�*@���5�8�g�RV���@������u	5r���r�m���H�yD=1�1�mC0W�,	���L��j% �%����L�ں�ܖĞ3RX[˸s(:�|A�>�q�����h�	 gF�a��Zuk,�@(�U��.��-R�4��X��Q���R� �c����Yn��N��Ì��l	�~�)2�Z���������b\�?�h��g�yq+�z����G�4�@<B-#�c�b�j:W�t�'X�4��6�d��0 $��m�}b�}�?vk��%�)�Tv�\C�V�a�m��66]�=y%���iZo�Ҡ����)j	�﷗g	5?���������
]���hj�W&Zt��r�A	z�X�.J�K�DN�h�EX�b^�A���S������D�n�i������tU�=)��W�L�X��56(��ѽе)lj4��m<�p�uG�Yd.2t��7�¼mL���ﶸ�G1�z��n�����N�;�	 �\#�m7����xJ3+�_��p;%���dJ5�Y�&�\�!�h��C�'!ýxI�I�6j�{y.�ѿ�P���ug�Xn,�J��4�����ʬ{9j�F�Z0(�8�%9��7�1j}�!@l�X�.DO���l	J��c?Q�GaZ�v���~M=�r
S�L��������tB�4��j[D���TC�BMN5��:�jwz7-r�Vb��[܈P���}27�k���;+l쐎�"���eP��NL �>���������1�w�7Ɯ7.��XX�R�����P���)_c���tN��ƾc�WZfsŎ�:���}!Bܢ�̧��r��aIס��^�cT�[�Y���}\�=[�̓?r��[*#(��k���1u�g�U8m�;.8b	b2n��o��\�rqT�
j�����pA'0�Z|�s�v�~W�ܩ`�~�_��0{u��m�ɤ�]-B��������ѡ���h�N�eϥ��~"�	��Y�v�]\���e��?��"���n���u����>S/��.�7KQ���d���c��l�R��2����0KK�A���g���s��Yvl��^~>5h���m��n���ܷk��-���bR�lʬCx�҉���	s�*?j�!-�q,�xp_Ċ
��ɛ	6=� N����(�m~�@=P��B��:Ǵ=��FR��&gclk4�'�]0��O�Uwa륀�>ӾFi����;2�x|�����sC
[R�Ke�*��+��
^8�~|m���ɺ�l|�~��g����C���O泗[�#{(<�2M��V��$�e�1v1�-�k^V�M����k�� 9�%��WTJ5��1%zM�)M�K+��3�m��;Ѻ�4z��EQ$
*9?�Q���Rt�䯥�u5S��������cޘ�9�ZOW_K�jI��:�j�����/}���Tl&��O+/y#Z'*�P�����q^	��n��ᆫ�L�h�9�p4Mb���9�I,)]�!�9 �.bb�J;X�(R��5���X[nH�/�*�f%{"H�A-��hG�T�6���B�yRIA�j��4t�l#�V{7��S k0(NTIX��Ԕ<7	�� w9�z*{��{?��%?JQ��o�z4��/S;DtVP���jE�3��su���J>��Q8 R�w�� ���)g��BSGط����X��C���z����� c�X���h�ۨ��e���L�����(D�)���_ǈ3W��Kj�ҏFã���u�|G�kMu��DY"�h���t���SyR8�Jf!F��A9�����|��yNb'/dY�[�F�%����~��(b�d��z�:��ک}�E�%���؁��-7g�������d�7U�?�%��	�ƌ�3O?��һ1�����Z��veӱu_�lF2!/x9��y�x���a��C=���Sb�+`��5ƻ��U%8?������i�
 �^�Kk�%�kdm��3�z���<���Dr�g�
��B�l�`}���#�cL �$�Q�'�`�<aJx��i!nu�%j=/�ł��5Biw����Dk�jщ[m!?R�ȾFA���rݚ+�����J�,�v�^?0��0@���b��R�{�q~$�2E����淢O�H��h�?�O�MK�������E���N{��
6.�)"��H�0���K�f��D���Vٮ��k����_0K��<�D�<^��+6�<�X�sM�9r$�H˘5�iq�9�A�✯��)ʵW��]�C��/r����sg��⊱���m�|��{<Pϑ�a�S=��7��&�����Y�.$�FB��2������&t&@��f�\�ܨ���̞e����?Mn\��;"Q�ˊ)/y��K3�ʚ.O�jj>�,��?��d|�5JlʏQ9�����6,}p���CyXB8��ф���c nN_�޹��kh\�O�:�D��Ϋ�Y͙Ax�-�HHާP%u���k1Zf��G�:E�ZF#;� �Nz_Cׂ�t���T�(i+�,�/�A�:���sgL{�@c��)��0phI9���zd��D��d�� 7g��%�9V�i�b���2���uM�Xv#J]�.ҷ��A�݈���m���o�][�2"��dɈ��(;|��H��4������~�ib�(�H�գ 6������m:�����{����4�ӥc�0�'R�9=3�ޮ�n�/���|)ut�sF:�R��vB$N��%�{%
X��켏�>`����R��"=��L�����KS�}i\�V��b '�P�*��r8���=�{��?���5���
�F/����b�ʣ�`�_�������.�����hʞ���,���ۚ����A�m��@yA��'�D]�:9�>Di���>/[�!�s�M����CQ&��	�
g�~TC���� �H��|?�>��O�ʉ�+%���LS��>����!�R��*��\�,Q�v�$����S6�>=��Lg�9����ѷ�Ժ�i}9�����2D�`���� Ы~�L.� ��w��Ǩ���_Ԙ�|��ou�� �.���<������;"��ں���*�0Mt*�Nh��S?����.5)r��
!v�U�6x�~ǎfޘH*½ 2ā� �cmj�%b�4�n��:���w�T��3����� [�˗ߔ6��.�8�J��e��0EF�h&���;�)g���S�gj�Q9�hȶ��i��/�$�Z�>���l<��vz]�ꬂ���=�K=E��,���Q@Oʳ�Ϳ�����B����Q�#�[L~^��N��JlOpK�h��Z玺m��j��7gE�tr�����6�k<��BEz�ߣ����(��˝�/����J�����t��c����㶑��#��wb���8QFU��t�DES�cAgc#�vٕ/�e��0j�7��AL��j�?l��\ ��[ϟ��Z�T`������/�F��M�ʹ"i*ڨ��`-'
�8��g���{}k'�M��:�>G��b�����]��u������,�� �_�(o\$�H�M�.�r�)���}���泊�ӜlW�F��O%[ T�1���ߐ�t�%�"�i)���[3.D,�F���z鋗_y��֏>���r�c�`A|��nǾ'��N��Oȍ�s��uMS�� w�%�Q����Ɇ��oϮ���j\�_�	�FF�E1m�B�(�5ՍDw��]"�g_c-e�5ȟkz�fe^�/���3��I���@����2z�sU������_u!JY�%L0rj�^uyD��y���&�(��9g�,Z�V�fKsq��U�e���2M�31��;�^s�5�4n�^�ټ����g2j��ܝ}yh�}��;m�K���{ƌ��Fq&�w"�}&ٹKH��hq�I��#م���*��o�+��AE�f?�wg1�>|��%�r�=���{�۽�	�B�q}&�r�X��lܿ�W[�"����w����p�~M6�u7���s���س���0 �tw��h)�GC�YX=�ܮ�s��Nr"`/s��B�7S<���G��CW�[��rtb��'p�xx��U}z����|�!���U���g��_�I.h��(��*7�%(Eu��X����u��݄DM�a��_�/�7��!!��f���K��1���{�	2�C����}���g��wѶ�?���nc��Qr����[��]?/Ⰶ��c|>X��2��Oj7�6�-#Z,���) �����s]�m�/��H�bs�oe�����w����eU����.�g�i�� ��:�����e������0;\d[�o����Y����r9�tѠ�xkc���Pk���r�p��z
���2�	�)�m��NS�o1�!U�m^xb6��B�`��i��[�F��`�\ճz�`����˾�'Wp�����I��K��Ӡ��1�|����D�[����4lM��[?�?>>L�
	w�w3�_e~S�%?���w;AaS=�ɝ(��ȖV�p�����f�����w!��{��p��0T�QG���Y��r��l�r|�8��g5���pD��è���x�q�\����zE��K�(�-�w�����Hd��"�y#_�>�$xyM.��o���>��H�A�`������v�M���c���!����:�.Bϖ'��x��sܓ#�3H��B��t=�bD+_���D�`\q;:�(�.���U�P�h�W0��}]���|/�zԍ_��Ќ��<��zlL)�ζ��aj��K' �ۣ$Ԥ/7�NB<���;��t��*5�)�h*�֙R�'�����xG6?�*��Ы�@R��f���dC�.����H��l�~�"`0QC�$��Ȃ<��Nˡ�,�.C�^�%���g�q\3����aR��cQ�${V�%H�E3C�7�{���iƤ����b^�F�e]�Ъ���q5Ev��g&��ǋ�z��,t�G��
�/Ȟ��yEP'�5v��ʛ͖�+a�LQ}�b�! ��Ҭ���!�F?b(��	@I
27\2=�1:&-�����3�=h?�L��P��D��1��~ �$ʌ�11���4��r��O����S&�#=�a�]�*%a�8�+�zR<�74>�G&��
��PZL]��E:�	�"�r��U�Zi�8SU��F³���Q!��v�Ԥ�� �WEp�Kɇ�uП˥"E�`�%�Q	7���$�Vp���
fn�)��m��
��x/�{0N��De��*$#W�lR��m�O�����b�����չ/Z1��s|#�uC�A%vf�i��������x���i3.3�ї�ƿI���<��c�����N�2�6T��Έm�}("��#��H�S��������5\�si�1�e\�w �^W6���z��{����$C��6=1hf�qKA�H����"�s��X�Y4�}*(R��Xh)d�p�w@���$-�>�[��g>H�lu�Z����t.B��^2HϘ�d��!�Yƹ��@�����U�éd��M1+$B#�Y�Q;j��8}���/�@�i�� ���μ���jф���W�I��q�����Y2�qqDa��f���dS��s��<��Я-�NH,{jL�� w}��+>c��1Z{쪒��F���<�:_�=� �$�r��)6H��Z�^K���8[´�r%��S#�P�7eO0?�[�IS* �H��5ܫ;��`,��4�[S<)��k��z�p�`8/�zx"�g�C�z0�8?>nm�t����@_oe|<ZTy��+$����^S� Q/ÍS�v�E���T�������s���沤�z��CH@��~W�T&y9���쑣ի��hmJ��B��Z^�A������]�_�Bu�z�|�n9�����c�����$Gy�~�w�EW�g/+���A�3�ƶá=}K���C�^^i�#�NGh^��I��cfW���*�(��Ez^���ad��vX�h`��F*�H��7�0f���+	G3��C�O�Ҧ�wt��$pl���ܧ>t�\�\���/С[(�r��§,��ՙ������5�{[�$�����1	��r�2�&��TY���&n�nk�%���ܷ��r�͎��H����C���7��֑���ov�7�PWugoAKUXy
���9������&O�U{����`˂eD��-��Ă~�q�uq�5դ9q�#4�~�Ɛ��u�����)�*g�$��y+
���53�/��p��{8��y!��rW�b�xF#x &2�oC�'EH�?o�=����I�]�<�kLմ����tRƣ�]�8"�`�=�!��m���c��VJ�2�vH�ZR���(�]��h�8��J!�94P��lʫ-<o��t.�?�b�K��m�����pw���h���'F	=�Ѭ�K.ۧ�p�Gk�b��k��
��Ӏ
~����w���A�
���f�8��ڜ*TR����x�0"`������ �^:�4����.���:U��2�p�K.��N��~����{La�82%�Z��a2zt�"�D`��%�P+,�i֤饥8��a8b�RR護��I�{O������
H��뀽�wB�T���)�'�#���ձ�F��v���#��yӺY?�{9���-�1�w��g�)g9���)x�lP��Kf�r�#�����ɔ~����*H0��qORF���+���!K   C�౰� �����V� ��g�    YZ