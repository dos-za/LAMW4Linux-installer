#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3240029480"
MD5="3dec1bdaf73c96fe4fd5d3363f94df45"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19780"
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
	echo Uncompressed size: 132 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec  3 01:15:26 -03 2019
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
	echo OLDUSIZE=132
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
�7zXZ  �ִF !   �X���M] �}��JF���.���_jgq�ϥ�-�	�����B��Qk��z:��چzT���H���T��-�o���+���ih�|�Dƫ��+����Ab�ho���I]k��2������nX#�}��z<#�Y��GP58�4v��F+|�5��;u������8���m�)���Ҏ�Z?�N?i�Ԗ��r�	`�d�c��,�����E��خ��1w�VN��T�>ҐW
z[.�jU�溃d4*AR�cMj��F`����$@w{�#��D2�3��6wrʇfu�s���2��+�(Q潁مY���'e�!m5f������5H�̅,s;��n�{d�S.�-f�陾f9Z]�w�3H�*޷]��r*#��TؤIΆ��X��`��Z* �ĸ�c�Eۣ|P�b��A��rNm%$��A,�0�Bٓ<}�5��W6��1�oN���9��L�G�84�5-�{��c��f8�T��� �@���bzmof��^��v���'��4P%c$tBxќW�5\z���r��9���o�G�ai؄5���|k��S](���Q�i����%�ZLU06�Z=���(��*cr�)��eQ@{F��&�j��7Z�GJ����I���cjqV9�+��^n$�mm�Ӑ�$>�`�$�cԵ��F�͒��$����\
OG
��`c�߄�B�uy��&a�A�<���fN��lt��`��lߛW37$����ȑ�[+~#�Po�p0|u�nV؂�&'�*���ˈ�	X8# �6�"��[��G�)$E��ھ��@��}螴��H��0�WN�}�ЀI�(���\�ܟ�	�Y$%����A��s�9A�Ƈ�b���#+�l���n�.&��\K2�A\L!��ԓ\L��r.����"E�'a��f6�;	k HN��{�O��<�¢of���]V��ɾ �_Ō��;�G��ƏI�.���`�}<$L]�8M�aP��$��;��,V�.?bM+��0�����W��Q��g{�Dh�f�<��b������4��,��ߖeB'���3�[����e�~m*o���ia�J�:��D�����N�Jx&�����!�N��+�,�d�)g�+8�����1	*�����v	u�y��]퇭yɭ�k:��}Hs�g;�$ѻϲ[v�Y�!�!ؽ-�#�W�� ���ڵ�z+�?	r���{��|g�|"���-�Ͽ��"`d�kӼ�,��_�`+K5u(���-#���r2�O(b>���]~Z\gVJM��t���-]���D�q�L�7�U��*�
�½����R�u�2F�Y���p-���Ҝ�1���k��I��9Kh�<����C^��B�����]4����/Mjq�f�u�����#�^���]����S���Ȗy4�?F�6 �J'��Ԑ�hAr�\������������{��W��k��>�	lW����H�J)H/��KJsZ��9�%�� ��KO�xsg�
&� 5�ԕ����DP&:�yn]����9t�Fŉ@o\�����:��E�!Y�5B[7O��W/�:���!�%�wژ����8���s�o�ú�S��yt��<_e�GT��Nd�b���EW�Y��q���ac����&+*�&�j��j&ĸ	��
�h�-sh�� �-ݨ�pw���<x��� <v�<�u�u�x+]�}׳{_�v��#��ޟͷ�J��!�C��ċ/�\6F\^)�~:��*� )'6I��>�:ֻb�}�^����-Ds��d�?�? ��-E˳R���L=��'�J��sU��$�uX��z1a�nQM����2���������I�_{^鶁;R�c��i��Q�`��C�^\"f cD���052�Xg����Ȉ�W/n���6N��@f�Uj�!��2�Y�VC�p%P�
yb�Lg��������7�M,7�#��'W����]�t�;{��g�w�f��3|����R��5�r\ZhA=�mώ�L�fU�C7��R���hZܢ[�Z�*�w�"W�C�; ��"�n�z��tW���lCj��w��>@]������<�����Bx�3Yx�g
;����^������4��Y�X[o ���mx����Z;1���~��4��$E�8�$�=�>z��T{�Bo�IB�Y�.9��c��:����O;�L��jƽ)���~���w
#PTW�G�Bq������/s�|���8�q�.�������*��U��[s2���|�y��Gk�u�<�p��A.W����y*�*����
-µ�~MI�>��e[1�P�F�dN�]ɦ0C���Q�j���M ����#�.�E��E:���m���Z����!���;݃zGY�ADꊍ#���%��a�z����q���y��&IV��x]8��E����W�I�>���1P���OS�x��Et�����6N��θ+�#�C	�ʘ}�M��-ݳ�Ғ����}����:n����-�]���4<���ч�D�$;2��! ��v=�,%t��Zb�֬����Ѳ8�PJH@N����,i�r9�
ŝu�>����u�[ݏJ�|�]�ϭf����.� ����/�nh]�/ m�խ���g���ނ��R木�6).M2���_Q�lC<�h6�V��܆+*ʆ��ַ`B�od6��R��c��Ry#˿�շÖ����f�0[��v�|/E)Wp�!��b��wK���ٝ_�ʚE��H��J�7g�I4�Q�m���	tqirXZ��Y���Pd�>Ȍ!�T���~�C$�Fi�7��֥x�*���8oP���"�p3)Q�#t��?���2����s�1�A�,:�#僮C�:�cR������f���RD�MQK`�$�&v/��ɉ$;ň���9q�y��C�޲f��,Э�kk�?]v#��}�!װӞ>�{�hB��}p���/�Y��~T�^&����͉�݉�-6:S�� ��kV�QΘ��xw8N(�Jƻ���^U��Z@٦i�6�Z���K��\�:`D0�� �a�zb�������O�yR�=�&�-�죛�F�;P�a�[�V��-+ߒ:�o�̕�&�̈~��b���Ɗxw����a��Rooy-g�^H=�G�.�l��-��[l�?��.8��*���nK���feF"��\��8��{>��fw� #k$3�����Ch}v`��0��]��&=J�@Q��������lu۬���<��&��
ToAk��Fe�M%h}�P��>�R��^�.��ZA�,��֓(\�ϝ"kp7[Y�Y�k�����!�Ľ<���0�'�X��?�y]"��f�z�����k��z�q50)�>�V�)*.mv,U�1�8I&b�����M}|!+d#�z�!����s�����Xg��d�3�ߵ�Ӟ��(>`�T)o,=��a��3p�l��o�3\Ӱy���i����֮`�eZ�c�Q(�G���7�v�{K�cS�%�����ӑ<|��L㋹���=��X�͑E�<���E��/}�`�𵒶�0�]'��iqڔ���� $���O&ѷ��;�����9���7������:�=��KN�Ӛ�Kh�kJWy	k;7"���{@}f��L�p�]�PA�ֽ�k=�3���m�*�^@pY�,�W!�L�5Vr�+�\fW�����[��±���&)�wCJ�p�M�8�A�A#Sk�����V�[�/���ԯȰM.D���Ļ��`6I�ap8	��C	l��I�r?�0g��R?/h�/�y�����y�W[~ңAS➥
aP[�8n�I���+�Lz�.Н��,S��^˅49Kr3�9��~���-�!!����(Ї��^��{�T[-�pa(iY�<��?�ϝg%l�m0�b	�+?;�	xT3cT�6�g
���{5ϑ�̏���X+(��m�<�`%�0T���kUJj����G~�)���ȷ����'�0�=�j��L�Y:<���e���
:�
;���U�(�[N[LL?��Y��a����z�HI�v ~�V��0|������X`�����T���jMh��'=r���
EGgh��k..�YE[rz��1��Ԥ��^�B-�,�kM�Tdwۥ2L]^K�-Fw���gN�Ǆ�?�Sܤ a�����j���.�ӘI4�f�L���\&:�b;�S'�q�� ��z��-Fd(_��F���rx�T�c��n�~���f���)5 26�K�}����(~F���R[4�a����)A��4#+GD�kml�T��A7�]b˫�zv��DE���Ú�Y�/Q֨�Qx5��?���K�vO�|���\��`�rR�7���~ӆ��o���1J�8�e��5+{�2�˿��bd�ԮrE�#[~��U�σT+6���U_��!p/��'�.DRi�7�%�%�� ��*����t��r��Fq5�$�N1$���#(���t�sp?�aB@��l�l�_�)	ā����r�!����\�T�FZ/kڃ[17�:m[���s봔mo]V��h�e�o�'��0%��6�Y�\�/!ٻ�l�W��\�_<�_s�z|l�n -���OExg��a�fW�hk'�
�E�"�p��AöU6�k�",No��Sv�C�
���d��_��T `��]�EPF*n�⸩}l����ʏ��������TF�c�w�6��E�~&��ٝ�2d��/���:2�s�n����P 	�������H�{!�ٺ?	�1`��e�M����E-����91
�i�y��>!�?�oN� �tECY/�S�N8���:�7��~���b?�W�i�V�@����G�R�ER5J)e�{��DzI*˄�M���m�2\>#��;��"���TSn��H����^��=\���[��w����wB"#���&X�>�&B�3:ڧ��t���`M��\�q���"C�RAC�`�ۼ:�>xj��6���:�-7w.������l�z�bx���{.�OF��ֽH�j�[���ڱ��Yd�l_�(��U='��$��k8|o��v��:�>W�g���F}a���]Js�l�_�̃U4���_+�Xtƥ�\��,LR�4��ؠB�l��j��RyD�nV����[�d�#�)��ރٳ�e�ZTk �&�L��jV����y}$�L[;(�i����`	*Ppu���w=zա^}%Gʝ���x� $Z]������RhI �è���ǖT�5T�)������i�IMXb$ L4�^G�����)��Pؿ�����.T��H�g�p.��K�z�8�b��	�p�1L.��6K�78#�%��"fZl;���g��3Y&�k'��kʆ�@�$��\[*x9�`K&_��ma:�R��e��[���UP��s��9�g2�@���c���cW���wP4n������.��`�z::z��@`'�?�� |��)r�I	%��$��c���?vg�k�NGjd%��3G�}^�%i�\�B]���I9�_g�)�4��98A>8�a6苼b��1��7�Ut*�R�P�$I^B5�[;�-���G��/j��2��D%��G�yT5���x;�gd�wȪI'��ȶNX��(��!lG�ēI+�oYP9b������}G���w�j��Ն�dֽ�U�hdZ�|�)�f��<�,�y��*�
��%R]6�s���6_�������.pn"Q<�P�Q<F<o|�c����c����Đ�l�2�PpVtj��#4O�7�G�q�is-[�
�c�Ν���ni����a^��\`#�}�jY}H��o{��:���#�D|���g���[]�8^wA�db��)�Ub�;�� ��8�ⴅ~y:�6�J��G%Ѱ�Q����L����G��W��{vlqDR��Ոk�$٣�f��j%��.��ʏ���T����EɆ\d؟�1i�zB�^�#�B6�M�Ȅr�Y7r�+��ma;��X9�rk��w�����5O���
�N|%'�ӏ�����#�
C�>����ڟ����s��ǰ�5N�N��J0�?b��^o�/��Z�������Q?9n
yK�^�ZW}�"K��s�+R�w�K�����4��_L�|3����H8��e�
�wT&'+{�"]qVZ�����&6���+��g8
�X�uا���ZfiUP��2�n��)Yv*� �${d݆a�8����Ȼ	���a��m��k��a|�Z-�,u��W�`q��9������4e��71��.ˉ�ً�����`�!�]�%��W�ab��w�(b( � /}�՚���4|x�h�Oi�1�ע��m?$��l��(5�u��X�]�������x��a�u��5�FbA0��=w񮄊��҅�z��~�	���ࢨ὜uc��ٞ`�isǚGg��� qƻ��v�5��b�IGcX�y3�����2d'#����ǻNyI>z"���O�>]p �H��LQL+����W�]����C�1������ʁ��.I���>�������Ibz��qI�,��B'��Ar�8������,�Pf�~�
��@�eqW�v�8K�q���fb�V6f/K����|r�ه��, �I(Fs=w�F�q�q���R��_m�����d���BE�ض�Y�GƂ�m�-�z��8�pj��4�o�a���[�����#Y�0fj9�aWJ�����Z�C9��ER���&�sc�j[�P�U�x���k��J�HARϜ�'0-���1�������X��q����4�5���Ah������mm�Rb@V�8�0���x�#ZC�EQ����G��,���E,�3W�s�\�\&�tՁ�q��%`gbL���*��|��K<�߱��=����������f}@�4Hu�CE}3�%:cE���sZ���e�j>���i���"d���?!v�����@:��q.�/���Ly&ɮԵ�b:�8�9�%���O�~?���ێ�\'�p�6b7��{0_9�c,ϐOOu�@ϧ���Ջw�Κq�m�w�R���:"������<<�p��#h�LR�T�tT}�l�x-Jp�N/�Z�7����>����!c��g���٥�g�.��������ž���%���x{��]���"8@�6�5D0�s��~ߔP{_ؽ�5!�I����N$b������/Ӝm��������c�����1Bu#���F��tz�\m�tn�љx����o��^�+����[T-L���f$��٘�����x�s��⦯�2�\����!�)��ㅨFe����Q�Y��X[��li\#��4m��ͫ?���G*���{Myyӯ��}j���pU�������qSS�Uo6G�A�<�+rX�����hM�3*�qQw�խ�ر�L[.CV3�����1�U�y����c�gE篼�3g��č�q��e�kş���)�҉��}|�p��vP�܃�2�����=��*��*3�p���2T��|q��t�U�޽9�1�A�\��\�P�Ղ�)�A�k7C��Ɠ�b��e��+��K�j0T���cW:+AQA�
L��O�Z�E[�7�V�֊_EʂpU+����w���uĵ3YP��GY�0�8A��qX��3ࡍAt.�.I�<�� =�{>�6+�+�x�,�����e[��Ͷ�`3��4�C��O�K�Z�+��zU��1�y�P�>�����z�E�r����O��uHA��'4���68B�	U��Sx�7�Ew��[D0/a�2��gT0r�
P���תivc�F�|v�����NA�切�sd-��0'���J��Bܴ����Wi�>�k���&}+�5�걡�ؙ�F��l�I ��������K�P���A}��,�R���@
�#l{��Ob�������zv`G<� ��,��_>0E��ޏ���[]*�ⶔ%1FvKx�z#oG�4��k��_��Vc2���ٺA������*>.�*���4&�tU��O��G.孳v������7U"�����ThWy�����Z	�1Q+5W2A��O��g���An�>+Ow�A�荍�������.�j ���hO���[�ڟS����0 �� ��R�/�FC������+��7�4i��B�p������F�s���I����id�(�C/��~��R�e%a�z�
��t����F�>F�^z���K��*ׇ́3�M�����e�A��KC���.ܷ�LB֌�T�Dpx����[�O��~zp�D�lJ�:'��Kmg�8T+�?X��v�m��&S��������C�����Z��q�w����4װ�((�HnW��y6�Lٓ쨚D|�t$�1+e;��F�7"~�Q^���~�&�Ke����[�p@�HL��O�LΙt�(;� �-�ʬ*�fT�M�����0�&�:H6p@�K�{���|j�[;�K�s���C���u����>�e\�ə����	��xy�m��N��p��s�N���k{y�jh���|p�L2!��0���Zz�����d0Um)��L[Dn�h�Ӏ1�Z}�^gx���Ӛ�'�4�Z@���+��z���-�4�>��jz�DqK����XNB4�{.��0���#�@ Uڊi��C��AJ(����[/�_L�;_�@�4�}wӚ�,y�:|�H(6e޻8��ܸù������N[�^oůYo�%F��Y����A^q���lґB�ɷ�3�x��޴����G:n �6β"�5�au�t���*�����%��O��"�p���g�X�X?[h�ג�����?2~ 8d.��דd)�qVo�X|��H�a�kgr����HD
4v�u"��Rm��b�ԥ��#��S�ï�<>
�Q�n����
�'��ל�w���1������t<�}<�_�!�bL��)��9>��>b�
D��ŋsdҒ`Q/!�i���R��1;³���r��ʄ��U0!�	�#5;\�^��a�qs�a�8[���U����,�z\8�r�K�k��TKGcV=<����^��(�/����O���2ۈ)n�s;�n��-v�"�8��v���K�~������naN&˷���V�щ5�5�
�)�l�
,��z��WE��c�8�΁醰R�6�D�SO�Ҹ�6�J]G4u^VrNw�,/�!�sQ�Ж��v���������yX㩫W���AQ�O]�9���~��^>���9V����˦����X�"�+��&+�N/ȃ���fbx�.�-���G�P��+X�oѼf��Y\�x#���R�=h��R/�1[�5������D!�"l&�\�C��'��XK��ˆ:�.�d���2f^v�w��
���@�X㦸�����(�b��UpM���G�c3>{eo�����;�/#Iyil��q�x��sg�S��n�y��|5�δ�%L|<�D<ˋ�IG�W,��7Z�H���},fI�c@l~�hy��������
.�=:w���D-���M�#y�5S���H�\���.��E�����U���v(��"��S�����x
7���=�����镚zzA���PN�zI��4��^��2���@������k]�0<j���#�(��4Eơ �2D�E[����Z\�E���h��`�R�/9��ܟg}7�&�?|`�/����y���KTN���Hr@/@M�.����;��d�6�Vd���I�ZH��Qa)�5�^C5��T�Ή7�z���L���Y
�>bx���T���"�_IC�#N����4��RX�V)9"��#�F1�q�pO�;)"P��|�"߈0���m�@�<�	�gd����X�ۑ0���y%�����I��[���m�׼U�����`H��6��[h�Oͽ� ֢��5fU��"��`E}�ݙ���GOr��|�|R���8�q���W���4�h7���k��������REh�gU�_�w�{��x�N׀���`��tl�Z9��D8�Ͱ��xtNa9���ZI'����E�$~jS�n��:�qd2�`�KdQ-q�2�n�$���Z?�\ng�1�<.�^ز1�D�0��r�DE&]^Րa����}Omk9_�X�K��h
�)5����-|�JutuX��j<��h�������0���-1�T�R�m�@:�aS!ι�͉i�ޤA�vf��J;�����r!f�t��QTLZ_Q���\e�~r�����^�t�[�
���N������(�k�P����y���vEs��׳��c,����/Z~o��_�<��u�
���W����s$��� �s�yK�1�U5��=��d���F������L7�ĝ򞛼f{�����u�U�Y���+�(�3�[2��!XU�V�L��r�}��̰��;:���6/�j��~�0�.�G�	>x+��R��ZOl	��b�ueEO�[�\P
��u�=M�'Qgjpf��|��0\�S�EU�^sR�P�G���
��%#]��撫Ԟ�$��F�<ü��	� Fpp���M{�pC�"h�F�Y���Z�Py����	��a���89�&���V1�2x��M�\�>�!��BA ���8"<�����_�A�4A��Q�~r �{�G��g���j1�|��g�3[oq2�v�X�^���N�'�oP��q�8ъO��K�-2�>�\�SD�$sCw�|JQ�3�-t�@�:���M3��x]��� �$(Z�Pޛ��LOD�li�(�Qx���Y��%;�i?�2a���0��@p�\�T��̙��.T!?�#|�ѽz:2�lp��3���Z��(��ԧR�
l?�Ɣf����ƽ\�TL�V�u��V�����`��.齶�m0�V��iǽ��$�|%���Q+�k���G*֨EO u�&�c\\�����f%w��7�
#W_��I��]B �JYŚF�7�Y�L](�'�ΐKN�5�`��P<CV��U�a��:���*]�`���&���1�}�\~F3��D��kl6T��zt8��I�=*,Iq�<H<���]����T������ ԟ^�t Rl�Ո��Ugr�����X��9!Oy��A���T���>���.mD?����ce�G'{@��m�Y�� �!g�b�����(ls�o��
#��1�;����ڢA���#b>25���i�Q]� ���~q N}��$�T��M�������^�BK\�.�*��3V��`�7T����i�l�����%m���4�m6>��4qse[�B9
"�O�m�P�X)�ŬЩܔ,���@��W�A)���p;��rm/�0n��?:��$ ̦����A�е�����*� �ds��YuZ����+_04Xt��[��\���$��~����0wy�j�T,�=4!����[�n�(wl%�6��3�k~vM+��0��n]��,ի����qL�~'Tqa�;D�E
HV+�Mh�r�[�@��7��%�K�BR0N��z�J���[��ʉ"r�vX~�����97��%��1O��Wm��nSt`Za3�.j+�"�������E���n����Z�b��u�������W#1:�;S;�c��Z|�\��_ݕ��OV-Kxƹ>f�Q�F��5�g�~V��,}�Fg�:g��gX4�|��y0�KmR#�iyW�f�)�y&9X"��-7� F�[)�1új=K��xpo��b5��[�u��\�QȻ���^$N��Iiv��J��E( ��ѷ#3Mr��y::�F}�����rW���_�"�j�i|�1�ly4	ζ��=�ޑ'a�R�����o/�T�=E�ũ�"�|͙(��z�<U�U�حH^i�j�~D�ɂL:4:k��L��a��6��,fL�
OR��z=/��:����8Dn����hfW�-���{/�鿋��
r,��q:�Ł�b�A�D&���=��W!SpHOO����eɲ�X��v����^���}��#*�w�e�Mt��`����G��
?I▰C����9S��nj��ˍ�3���AC�����:� [s�������D��ۈS�$��n[��O�����͙~�}{Qƴ<M"�f��M�x���G)�9�����=�K^�n>���.�^��\އmp:AFq,�m[S*=Á3�54�l��E�̅Ej�KE�e���\���T��'#D9�`�ތ�1E];8n	���������T���9�H�/e���Kے��Po�
��ګ�Y��)8-9�À���z�Oq,?*>
AF�[��A(��殷��i*"�Ḧؠ��c���&����&L��}D�������֌�ۂ��Fs������98�i�X#YH�{��M]#G�\8%���_�������Q�cf�hŎ�O����
�S���=48QU�mGb��|I����ԁ�>��>P��&�DO�P���U�|���l��:$�xLov[ b{��J�h�3KĉB;�����d�	&�63�� `��`?=�Ay'KF�
1�2�|nѿ�:6ԁ�ӥG����mN&A�P*��|��I�@?�*�[��tbD	�a�q:UkpV��J����i`��oy�R���M6RX)�M� �/ӿ�x����bc����^O�{�d��=��Lh�S[ப2ݞ�����:Y�[T�Ab$#E��%������5|%�p!9�Y7�1���IU�4L��è=1;{6��$R���� ����es�GL&Q����۫���F���9��,�	�Y���U#3�g�$�;Je���e�[�4�"�Ȁa8��r*�A*�p��Ô@M#C�.�]�D���]�$:?b8�ze�X�^��2�;���a�*��Cn�e��(	�Z��?:z*���g���tO-�b�Ֆ�x���X��秌8�����/����IR�L3ะ:�%'��Ȏ�%~1�o����9^�7|]G�@!F_�Ck�(Jb���B��=�f�p�+K�X�UK�X���s��E�;s]�X�U�(g]_������f�!���ȩ�F����'�.½�����ˇ�L��[�5_,�CU}]�2�@���C�bў��Ŵ���j�M^G.�xG{���k���
yQ�$�X�g�K�A�A�c�x�r� H�lv�Sܱ����i��'�#�鬷*����9�{���bܕ1���3�R�b� IƧ��=d �Ѹ��M��Z&�w������T��&{f��<Ob/�ʍ2�-<8��m�t��b\x(;�Ԙ�]�V�`N�������l1�ǇJJa=|�d��'?��f�$^�&MWJ+)�{d�?x$Hgp��'@�.Pf��j��Wq�.��+�� &���^ &~� ����"f�HLR9[	�� �lOD��c)�*HL��>�X@'�m�I'9�	]~�����COd������^&l�`,��T�$�)f�I\�r_�-�w'2���E�������*�h�]�~���?G�WGl�	��"��;t��ks�˃�%c�&�;�O�W=L͡��M�Z�Rg�@3!�nu}��W4����3gkm�	�,}̏�r�W앦 b&+�M�v>C��&OB����{�{�=���E���ǥڨu��Y��CT�>i2�p��o�KNRGo��*��XP�Tpy
(�-�}.��I��m�;_�?!F&d��o(!�<Ij�ƶ~<}`�^���7���!�e@�!im�+�T��*���M��+�49��Zˎ
�l�ޟ'
H+u����P}��XX�e#r�����,?zh��{-	c_�"0 ��*8Ǥ�^��%'�{���-��|�@PZo�����L[;J�p��M�+#�ꄠu�ͥ���_�4�$U�
�b��	R�ȓ�H��`ſ"�BE����m����AT,6���2OoTO�[��kݒ7�ٷ�{������T��=������� 	՜ڌ�X���Q�+|��8�Д?�`'�މ=��v�(A�"V*��l3b�Q�	�!�J�*-�iqM�YY{��DOa�����{�ҵ�78#�)���꺞W��Hf&*�K�9��ń";{v
���1�!S`"�����N>1f�J�q�ʯ�^���iC�a*�+$���0d�CMur�%����h��
�����g;G�O���zJ���/����},�ϓ���F0�¡��e�5�JJ�� {%� �Y:���J���_��mGO=]f�t�*ιuԅu;�'����r��M��C�]V�6ү���st�C$K�����`O_U�_d��8�'��_�}�3�N�bF6�d�E�qn�؉[��q%��3H���2��
�@z�h�.�e8�)�y/s���K�da�>�����2ߋ$���a`GB���m��N�YoP�y�:�1#�(
�N�Ym��<����]����nB�?�@�w`�#�>ͨ���=9P���<�����0��f��� %�՟F:�Rtn�F�C���|�Kb@PS����	q���K۹���m?�@J�a�>��ыaa�@�H���T�2@�t��l�Us����j��49�U(PLT2�ưr�`���%�@d!����!Rc�݅U�A����m�ɗ�1��R�"�P�.C��-��k�����I�b���C�Y��Xb>��]R�6V�=���"�M�0�:��LT�o�?�4�f�C��N�I���gYD�qusM�۝����$�7���H~vSN\ڌC%�h$F�u�,e�Q���J���	�;�����5��ƚ����j|ah)��h��3o�@�k`89�*�K׹�A�U�I����d�5���G����
|T�K�����J!m�S���*�xˉ=�����֘@eن?3 9�I���ϯ��Y�����~��!����ͺ�p�5��+��Թ(�xqBN3�v���c���-G����*�T��D�Ag�N�(��AJ�z�a�)�QC�cS���,�2`#����G��ab�yuA���M�A�)�HN.����e��)Zv���'{6�MLmn�Mb�f2���5f��C�-p�P$��^?g�'�a�tۏ�)ݫGFRۧ�� �:£���q�s�������5=)�����E�%1�針�%�a&�Mʌ��
 ����ܙ�5,S;��8C7���A��&i���J���{������r�&kZ���t*!��ߢ�r�s �.@"�u��@C�_3�`SC;�;\��2u���&�~�о���8�]鹯I]�̡ �b�������%���R^ن]H�T����C�`> q��'��:U�;ߤ� +cJ���+�Ն���.O0�ɗQL�?�d}�g�J;�l�L+����!�'%�'�H�%��.o�]�5v����E�:aj��	� �5u�{ (xܘ,���_8&��M�� *jYG��-��ED�� e�xf`�KH�ք�?�/m2B)�����%l2��3 �����x���.tJ߅1W�.<6��2�F�-fRS�4F���a����k�CL�զ�T��U�U��qL��>�n\������u~��K�����舝	/��I�/#���hێk�	a;���u��4��/�a0S��l�6^��;���i� �C4u���M,���3L�?C��M�����+SF��Y[`���1-J%����4��P��(g��O�nrDrXqv�>�����ۂ�A$�����5�2h,�7���̙%ڠҧ��#�h��`0��3��ɴ"a�х�����o~�G�~������Ɖ���߇���5ob�q�-ܞ7z_?Ոi`u�k�,�<$;��b�蟪/ݡ��P�h��7���fW������Xޏ���U
���=���A5_�餅��1~>��LP�-H����DC���̈́��G��prK3�g�/T�{��J2̅�DH�����b��V�Pf�f&P:���5��@�ce��6�7,:wI"15\Φ��jdUaq�3�6������)�q�AT4u�TP�ڭ��\m|�;��Y�FW6m���D�I��u�x��]<�������j����g����T��_;�Lc*.١%�9���@��Fx��C�I�,�?h7'뀀b�H��L��v���E_ �7�غq�G�I�>��KU?yX�m�J@S���0���D�_E+�ݟu��5�o� 92��UX�����M�r�$�����5���Ԭ �_k��^��������j,��l��K��)ְa��^+���_�p�[վ��[�?$�%���}�>�#�3�X�v�u�=H��kR�M
D%�Y�N׺��yҊ�(�?�2�C���ݚ"�w��˺�|J�KЖp�n�[����n�M2
�̀D���P�����˂�[c��ŗ�8� ���A�9�C�	�<[ޭ��f���R��%�^%:'7���Y`�>�H�dn�j��s�,R�hX���l��ZE���4N��ЁZ�p6��� y�W\�4!�J��M�d�En�^�del)=�X��C��Pg1��8�6X��<:e@�J
��u�珇@92�C��&3������54�*� 8���gB��b���r��%�����z�;�,鬌�$���Aج|PEd<� w�J[�0SЃ�%_
�k��@�qZ5ӝ:�����Y���foJ<���m�߂$�i��Kw5�#�킟�.!�
m�,k���ل2b�.�u
e�GkEb��4������D��\Ҽi<�cq19���#g����X�!MV>V��%(�s w����TW�j3IE�
����}D����x�*/�,�|=&�}S>{��aO`�N	[�:\r W�*�8½kx����a �[���Ic
�cH�x�_ۦ�q=)�֍�L�ш��r�MX��Թ!_l�ӒG�1]�Ɔ��xǰ1h@ɟ\}Q_nJ�3�N�D��2�4Д	��n�w)��#��4R��_̸�<v`@��������~z�n��:��'\�zK~o�ϻv_�.�����־�����o���c�R:^��!<}e���T�{:�����js��*��q"��+*W��k�Hm%+�u%
.#�Y>�j�l�c��P�Rq�E��}gJBor��<u��6h�̑N)g�~�hx��a��If�v�$暠�q7)��P�=�E��z�!Z ��͏�?`o_b@��4���݉���|��A���Cü3��T�`�[�I*��3�w륒%���] '4��F��Ƥ��.��'0ex�4������U\?�K������{"Y�S2[h�x���[�B���Ŏ3�qx]��!ԋ�!�%dq��n��D)�r*�kԼ�b��3�VǠ�,�!:�Gױ�6�,���?��p��{5���\3=�d�=o��6k/	�J������Sw���#K/u0��>�/��e�ykc�e��l$��N�&~��]C�ѣ��l�����x�?��C8�OeS:R��W/�gv����^hqAq��Hv2��n��'1n�@���/!��ۅ���ĢY��hm7��Փ�}W�O���8*�Cj����	8��!
泴w.o��!pOh9�k�3�ӻ�ۦ_�.�Ҟ�o+�3��k���t�+#w��N�;�8��"��Y������
��i'e���G=*��m�tQU@5>:�<:vw�Ty�:d��|���J�v�Ջv 冕0��
C+��g�
�MT���a�OkO4O���Lns�ĵ�*���9�/G?d�^L���%��W#���v .Y0���/'���g%�:��k�Nz"��B��I�=yĦx���Tú����Xh��~ O-A҂N��%���,j� �}{Ud�[z�3²��-@����1�N���ɓ���{¬/������g�Q،ri��&�xS�)tK|��!��X�F��q7�'�"���eu�t! �T*,�X��琄ת���ĭ��vTu�����$j�a;�Z�>]�7=��#�0��El�ǯ�<�x*�aCp��1�r�	e�3�� �D.�U�b\�z`���6YE�XrS��$��ʗN�w�E���R��� ��+�8P�NT��V�:�B��[g���)��A���
o�ҥU�uS�ws��vW��y����X�ʰ����	�8�jN���x�,�W��P��Ȧ��s�:�L]�vX���v�*#�ޯp��{ �כ���R������Gw;��l����6�l��fO�:�J��juC#�&��ȱ�}e�dVlÀ��_Z?�>���\�_��J�������J[*H�#��S�T�XŒ$�/�E&�<����W\�LY<E1����!2���p��"#��#"�۬�U�XTLt4]�,���n�2�8���P�UZ�`�4�e.��J*�C�H���v��8��yu"�oBg�?���b�6fT�8*�;�-�� L�lc���\���r{7�V>���EuA9#FB�tx�[���j�Z+���-}[�B�
m/�;}����=�H+�:���t��o�d�;1�e;Կ��<VӇX��\E�p_���Q��B:V���`�v놇2���e��X9�,����Ҡ9P���%�_��A��������pg�� ��f���iD�`��2�_��^v��O`M�3�-Rڇ�+����n�b����h�Ǔ���W�F���	�XZ��x̉��,F�~�д�����&Y{��n��0��Vi�$8d�u	��S3d�_B�>f����4Hm�e"�i��V�Q�c����^��s���w�&�zS�TQ�x� t��
H���R�V�q+�Ŷ�M��j�(��勗��e0��N-�!�/fEŤC�*o���϶a��X:؃ۨ���K,�p���M���<,0Raˏ/�"��y�������5�8̣�/��&��ĺ�###��|i��hd��_"a�Rc��ZX	��Yt��}V�)d�g��Rk�x�FI�In I�}'%OfVc x�u��m�R�(Hr��R���Er(+�Q+�w\�=[ ��j�g�x
���E���OH��񧮓�:�R�@4�|��KqgW���\��JYO_�o�(�7~Y=o�h��O��slέ$���i�@�����3��s��e�O�{w�/�[[��.�;D�Ch�2ә���	a���$�ٟ�'+�@��J��|��-U�U+��,�5��|8���/L�'}�N";i�VN�Ɔ&VX%y)����JJF��xA+e�DzQ�{��3�ٱ��[sv@ę���kR���>�F��d�� ��:�&E���HY �9���V�<"h��0hVE��O}�<�)at}(c��	b+ǘ��d�w/{�0��k��ʥ���PbڃDP&D�w�M���w�O�=	�7BoU�J�PåGd披��Qp��N�ag\z|t��?��w2n�%����u� �m�J���;�>��}����Q��:�T6���]�$����b�u�D����[�ج�.���   �)~SM �����*>���g�    YZ