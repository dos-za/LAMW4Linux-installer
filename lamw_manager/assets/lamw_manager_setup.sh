#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2815885634"
MD5="85fb4f932c2fb4aab5b7a6deffcb8a2e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20056"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec  6 17:18:55 -03 2019
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
�7zXZ  �ִF !   �X���N] �}��JF���.���_jg\`��i�!vo^��:�@I�& �I"�%�S��������$���Y�A1�F�\.ܒ��svҝ��5�a: �?W��-ŷzX���nr�nN�i���IL����;�}�X9�ԛ���d��qI��æ��b�-坧�0��s��Ft*������\:�����)�oÝ"�:v�W_�";]�=���2��J���m^?�ڑ�'���M��ө^z{xrH�O~���&Z��޼/虌Rx��X��Wm�2y##w����|G;�[^��Ws�����7�Y�|�ڄ����~& �ĺ\����M�Chȝ�VV]<U�?�~�k֙}�se͵��T0� p���(�r?��r��Юi����W���y�mXodf3.U嶔Z�ˏ� �䉄��6y,����}r�̓�}���Q�'\���琐�V�o����Id�����:�HpĦ7��W>mR�KX6Od�������;W�h�=Y7��柈3��xu��(5/
Ss��B���R���Ŷ���#�lX��ȳ ����c�Wo�~�4�s�XK�DJM>�Wv�/ �^ci&��'�Μg�~�Hkg�}(��TZ�(˂���������T�*��X��(�"��̔�%����Zo����#
�l8dP���I��0Q�t�H��eNYm?��!��\_�
�7󋼮�"l����e���>���⒩l��Q�R�V8�V�B�G�]�`@�d�wtr2 �ﰘ�S�omѳ����0E/⵼3�lm�3�(�.�F��
,H��+^$��������u���&|���4_�SE��\)�/����C�$y��I(�؅D�/=ժד=ġ��"2�Iv��g���P����Y��J@�u�TV����'+kM�R��T�4����l�H�5�Z���Z:����J]����B����`^�qVw��4KE�j��7D{5�C�2�
��'TO�Ҭ�[Od����Vi?�_���4��=Bn��4ؒ�.xå�t	��C��&��S��~����H�<��5�,eY2�/��2���y����(qϦ��߰��=~ ����O��q��zi����0(��\��}U_쇘7h���8v/)G�0p}-o�i�����H�j&v~��h���&ˊ{��Q��"Xx�����$�s��+�G��
7X�`��*$㰰@�mt/Dls��O�����h��&�tE�1� �a�7�/����t2׼�h=��������nHU0C]0�~�	�G��J0�3�`�i��K�����{��&'��6�IʹS:�����O�*�q8�Y�~����Hr����Y]yF�1_�a�R��z;��{x���v���U厉P�.��O���S�lU�5���״���K��	�h���k��w�T+��lt8O���I��ؙ.;8[�hb� m)�5�Hs���,X�8�q�o��>�uXN�]6,�^�Ub�)��b�PHB߹)��)Fd��&na�	j�MF=P�mcs=�(�����^Z��Z�͘�+��	#e� V���zAGB��P頤;m L*�"��v�t[^�dbH�zp��~��OV�[[ǝ�Mo[�~�n��ӼZ�kn�94Rⓥ0��tnE%>�[���'��҃ٲa��̞e	)	���K�2��Ǹj꒱>Z��ӛ�٩ܫ0Z��uh��"n�[~i�.B�x��0��h��ܙ�Z���p�������z�a,H�t9��K����} � v<84�9�bBL�m3��:Ӫ����߇'��i�0ܬ���Gxg��qu|��0cp�<�B��d���/���W��Z���9���`<��,'о,O�]�~�m��s\�&��r���K�.@o���c��u�^���WiZ�Q�6��t��Y�
G�zd�m����4��>�'���᜿�D,/Jr_��$(D�&�Ł�FQ�D��*��P-� [�g �W��|ݳ+	�j CEm�'Ά���� �\/�����XG�Q�b� ��3�K[�U�/3pOIτ5�R���� �}�bΠ^�{�gcFxh|��SVX4c�#����*=����׼1'��}�3q#��L���\��aq���a��cM2B� ڨ0�C�E�\:���j�_���/*�w�dmL��m� 8�L�W�zd�l���Vm� �5}���~k�a
a�_G�b7��ۯ�M����YĄ��ȸ,m8Y�S���sk�p@��&63
 �K<9�Seы��Lc�wb���&R#�G��5�}���Ŀn���O�``:�,����Jd�.O�zjΥ�>�FK;�Ե�m1���l�>c>�Y�*��9ªn{��֎bT
�]�T�7{��o*�$6�����٠�|r��7$�I8Q��x�D�wd�项w���R֙���r1j��jd,n!���_�~i���y^{��#�P��xAU�u��	���S��J�='�f�H/7�l�}yT�.�TM�V6�I�g�J�Y���ᛤ:�0Ά)��3Xd��3���8;��Pϙ��Vh�@�Դ*U7��BC���~�r4W1��a�w}�܅��6Y�CN"��Q�T���J�2A����nS�;���Y����:��n�e�>�'��op�H)������9?|������Ƅ���'�_�T���X�>�43j�M��7����띥�����aְvw���韕���e�S�:+��҉��$/^��i��	Lo�8^e+FGXK~kxX�4

?j��߽]�Λ�W�k�w���x�e�z~��o��|�z ����%�%��q⎭��|Ԝ���{��$ANʆ���(JQ��,;�\��BL/a��F|�c���V#�W�d�.�n&~��-˵#,�{�G9�B��\��I��T
'���3#��޽��ȱ�n~#V0S)E�abk6�I�CF(r��xʻ6�.!����V���9'�����w���INh)�u�bUfC���rk,�/�٪�>��yO�E��d�x��S)��� ��%9��h�'F� ��Y����K�7�ii�@�j�¾�Ӈ�8,�ݍqq��|2�@އ���}/p⾘�y��x7�%��eC�Gӻ9�iɅ���0�x�������М�����-���ܯ�-������VRJ)��]ժ͚=�d6���Sg]jLԃ�:���:;�؝W�#���[�o�X��c���~�pz�Y�cE�����P��WoX�����w �g<��i-�oR*����N��ûPg ��1eM�T� �T��&�*�֫X�vR�*$�f\|ҕ��YӕC���xHυz&W��X��[z���הRQ3)�����2�X�{��눣Y���5�Z�\-���Q�M�sj,z�8~�DJ9]H2-�	�ݜ�.đZ��mr�_��"Z�O��t�1`�j�	e�.�AZ	�_���j�%-k'2�з��0C=C�)Cúm���엧�5_��W*{N��K>���������%fs�}�ly��^��9��*��k���v�R'�&�π���u��H�8�E�Ċ�+� ��C�&��qc�8�G+��Q}R*u�/�; I� ��٢��Y;vՋ��G�R���⁼�޸uk�����.��7��05]_�u��VmI�6 2i�p���]���2rR���*$j/O�b/��G����wZ��	�FW�y�R�� �=�B��鏣�ه𪥽2��.h�gC(��`�d�Q�d���a�U��]Q�B��H�4��x��������E���tt�D �F���a�p��p��k��'�����zC��������=���,�O9��iåv���r_Sn�8b�t~�-��B�T�Ϭ1�R����ٯ���K?%O�ۥ�\XI8��� �ES�S�{��CH�̙f'�bZ����`�� "A/�* ���n��PN�����oY���-�i8��c�cQ��r��vT@b#��>��C�%�诅�'��Ӫfޠ��G�m����NrM'��\�,�cXI��>(��N#�J�Q��5O͗wޢ{�+؃h��F��fY8y��^�Wt�gF|oV�J���r�#�"j��2d�y�L���8���OY4zf߀xzޞi��FJ���8L~߸b[��9�Q�4`<��b�Ķ�j���K>P�΅p�ky-�9��&u�K��f�`���.A��Q���	G�N��\6o#�.d��[-�|���E����@7�lC�
�^��	T��H��k�iI.h�z@⨒������Y_��;�`�����Q��+���{�G��z&Ǽp�'s�Ecۻ[��L�8�&i.{���kXqtV���\�U��<�I��9�2I�Ym�����#���'
<2��X�Q�j���;��$��Nը&����H�ީ��ӑ�;�l�IVZZp+�Ck�gb���B�5�q�i�j|�6�|���!�@zM�*Xi!}�"fr�=��(̠'�" ;7����_�� s�ר��'��z�`R<kT@�&{�KX��%а*5�l��pV��������s���)i��� �5,���R���ʂF���#Y'�1+��V,�J*���p�I�[���Jo�\=R%���}�z��z%E_b�fSg�Rui�V&[gق���������wd/�9)G��p.% ��_ye*�5J��Zm�\�����h\)L�{b��䱋c�n��B�3�6����Z[1ms\���3hSo�Uӽ;�n�}͔�ru��$9vf�k��p��Y�n��٭��P��gwhJY"B�SB����2KA�1J�"�0���Is�v����K�wy��2�5��c���&Ȳ��B�_­�7a
Ɖ�$��A��\��U*�1D��#Id�{�m=M4$#_F�30^��D�J�⣧���b�-Хxl��Be~�I�tؐ+����؃���c��5�J��dNM��%� �l"Oa�wl�,~ʤZ�
h��_.�&R����q��w�Y���� �nrF��+5���}��D�?���&���nh���ft����O'�~9���kH�}Dp�c���Hh6鼊Ճ�9�C�|Q��)�]U���Ւ��O��ρ>7�������j"�s���S)��	�ܘ3���̠-p��	�)�_;p������s�ɍ6Pn�U��f%"��E���xO�${Bq
K��>=A��"�ѫu=�r�~ڻB�#s�"3�*�t�p�m��I i�-f�ᒀ�| s��?N�Z���&�F��]��"�auT�������v(�F�z�.N���L�/i1�����w}򝡶A�f�BGm���s��9��T��,��`�����p����!�b���f#��rU<�˅�C�#%?y*˷�`+5R���ن��c���4��ICPBܡ������9D��j����|LY��PWҊ�����g�Y�D��"t��q���\!q�M,��
�����_�N
�rR�.�	|a�Q�����Isjn����5Y��L��y鉮�n�	-�����I93�9�-'�п�;`�wф�$9)��\+�{*��S���;6��`�������vU��/�Id:���d�-��x�Y�/_�~�����{�����*��M�o��=�{�,έ6�����bK�>K_���&��Tw��>t�`颂N<��Q��$~f/P�IF��
%N�N��O�8�(VM�����3�\����&����|t9t��W�dffTh��!�'�b�31ө_#��]� y��N�-1�lr��참��M�E��q�T�G�T����:o��W	���oߛ�F(�S�Gނ�$�y��Y����2���H�pO_V3d1�Ex��#j���P��_gc����"�f��EU�Ό54�k"�����L��*0�+�#?�yP�<�AP��7R	�0j�E�W�tSSUQ��`�^3�K�[`Q���cӬ�o�%�V�ho���E�{!'�����T[�rUY��}Յ��s��Y�2e9��{a�E�QL��*r�5m/�����]���x�EJ�<v���]�E�Q?�bf���'�����)jbz�bJgE�=͠��q�M��=���#�
�'��������Y؎R�B���f�&�+��C�f��yE��}r�ڒ�O՞����is����L��R@�"��3���.D3KR�odp1��6`���r�^"��<�)A0�%ms�?�ەH�l>�l�M�!���6B�;��@OPU�ˤzQ.Q��2���ٍ(ӕg�CHD�)�0.�C6]D��%����in�SH�a��&�ق���+��V�+<�Ș���;���>�#G��Z�ߪ�?��ɷS��U���!�(���Z��e��t��m�U��� ��!8�H���_��iy���ޮ���9���[�kg4���y#�Z�1�����4I`���a:tsp4��x���M��m�Bw�����zb�g96;?F�. �T���L���ym݊k�rŔ�>�Yj.��L����e�?L�qS��E$���y�R�r��i�J�?K' 7��τ;�����NLL�K3F�%�)g��t�@�Vͱ�܊8�	ʈ��ӧ�C�յ��o^ۣY��>Q����L)���C�]M跹��O	E��	cw�p��~lm��}is��%���۸��9�G�W�(yXՓ
DC0��I���ʵ��KK�_t���-�>�UX)����	¯1�Z��N�#��C����E�r:#�(���9\lM7 r&�a�R�-�>s�I��,e��Xe^��Vb�6����k6�0T�FB�"g�;�I�,'J,YH�d'����`�{�?�
bXvG*�Wc�΋�5a늜�~	�|�&�eK>�|:��F�q�<�eU_�~�S0`|g�&v�Ղ4�i��o!K�&~��r<�2oA�/N|�-�9Ѥr �A�ͫ!{P(ƭ��`p���x��<s}�U��Bm�p�Ӝ���L<�6q���ϓ�t�^��bf���zM���LdFl��1��G�P��F��E�����9��(�+� n8�y��R��(!�8��/^���F��M����[����t��.�Z8l���!�p�;�(������ǻ�K�k�N��d�{菕���yw�(�E�=����!#=�N'�t��0��y,�.�����8��·����ұvՌ�,�[҄�ٳy����W��ˏ=�{J#@\�4Ԇӫ�\�kΖY��M��5fU�(��{��i���2{���jrL��B\Y=���p�!��*[6Ў���9Xa����X���AGۉ7��G�R�>.蚷�g_�2#��<)mtP���B,��6�|�;O�qW}�oJc,�.�ܻNπ�K�G�Oˇ�3�����@���h�6���,���b1ݳD�"�a�k6'^��m�4N3�	"�e����fF4�*o�SA��ڝ����Q���R:��{�n��˜a&p�A����$^~TZ�٣����^�G�Mh��eڧ�Ӊ�5_ս]n�k3c��i���"�m�������z��ݯ*	�9��O��86��SM�u8Y�����ڔ׬P'�b�`��d@�|J��D�9K$]�c��A����;��i�x,¹�#�W�u
�����o�o�J�N��.�P�Ϭ�f��M�^� ����On�g��fCN��PJ�\�w��V殧܁!?tx�Ai�AɃ��p'�~L��35�N���@��
Jؔ�C��p�x<M| ����W��a��r�|#��S�x��W?����1 %DM�Vع
mh�Qf��U'U���fL�:w!%BZQm�x�}!{��CEW��1�r[hF�>������h��j���~�Kt矼2Qt���1��f��ۥ 3 "ӡB�eo)ŏ��>���)\cK4�XAw�2���)�7 �Ӂ8E��B>�.�V"����c
`��g�!�D�\F��=�]���(�U_@�/RV������o��m�y�um�G�Gڏ����^�����QW��=���ZkX�@�S'k�_����Թ�/����W�xp3��
�Y6Q��oaI�a��U����1&�
��l�uϭzݎ懰r��*[��[��d�)B�QD�A�q�@Ƚ�`<9σ����[�U�љ��-K��p��9���&�k߆9����~7�f��nKn��@g7u_�SNX0-��Bs�[��N�h�D3��V�K�.�6�0�ܫ��|��O�$���qs���#�oA���K$�ٖ����E��N����)�[�j�%�d48�{'�w�����p� �*j\�:��μ�t�cw�Ӻ�W�$Ư�Զ������v$b+�b��\�c>2_�w1TP���� �5�qϢ��%E��7�bB�P�|5��m�u]��W[���-c\�>$TJ�L�����8:e�/���tѯ�U��"����&�Zӱ�K�<g����H�'���;k�ii*��]�2g;�R|z��E@	v$�P�M�"�q��W�f��C��86�	�J��>����j�e�>�n¾I�[�g�;�4�e�������������e&�V��dq�L�긬��V�v�ZUŪN�A��1�s&�գe?��j>�AM�kv��\�֪`�/R�3�'�8J��b���3?��G�e���B�h+��껕+[�
�-��s���yiE�*�'Y!���=7v6��]%F�ն��;�Mk���f�T���Y㮹H�I#á 6Z���&�4A�I����5U#�⻺��=�&ן��-�L1�ͭ���f����c���[|^���kv�#u��ߑ{��n���l��~d�}g���FN�0Z�{p����@��I���E英��ɥ�6>��-��2O?��R��#<d_W��p���.;�P Үz
ǜK\���$����{�ԉ���=|�.r�+�r����/�'8`-��tY���
�d�޿�(M$��5�L[�������H	TG��zV��1�R�������VE#h�^hВ�D�5�O������0^6�n_^��w@|��E�HB�������G��L�FX��z���g�)tS��82C��d��R�B!tآv|g��ֿ@��G@g������#6��o���y$	��p^��#�"O$���[�#�*sԷ
Z���{*Kʧ�Ԁ�7\��gTJ�_q������$p��<@�q<4�'QTP�p�a
!D"B �WdƔ�ѽ>�1�
�{@��_g�ݞ��Ș�xH?)�N"�0��D����p�Y�����r�.�A�����@�\��ίb&ݩBNö���_1f8<3�Z�m�47 /�/��-�
��u��5��XxOXOP)K3��S8�!!��0NB�"��*S�*l�� ����Fn�^&R1R�}?.���}Nw��=�`zd��Br�D1�3�xR�Q��,���������${y��]�H��������z͍2$"�	9�1���֫�K�wdr6��=�rE}��(Y�ݜd�&���	�ș�ڟ!B9�j	�w��Ϥa��^k)���#s�%)M����e����T�ˬ��.ͳ�:��;��7�8��8vzؔ$Hs����G �j�(�&ǳi�F\X�����*��7���*w����G�Φ�����~�L��J�q������;�W��pq�F!^�N��	.`z\cHt?�	�|Й)E����7׏F�S�	��Ɣ8U��ģm�?^!0��t�tW�1{��VC��ca�}�l���T�؝�J�ȚhJ6�����	Ū�{b]��5�4q�j��xXE�^zY��kl_���D��Ӄ+��+��^�NF_�1��"�m��G�yF���d>-P\�c����;������S��\𴁠�UI������{g�����E(�'�b������IWڧ����N��.�~/������4J��[�%י��L8*��0Î����L�}&�be,��s��~�!=UxB���ӝf�I�Z(�p.,�_55��?U	�F��<�@/��20i��Y��Q]��t�]�*(�s���J�u�-fH���1V����c;�A[ߪ����j��WY�z��7��F�������@� Ō��f�i�6�Q5��v�"�������X�?�ڍ��e0��#-[US�,�Q_�*�y2�/�υ�a��<�H�o�W���
�H0���O	��9��$�/}5�"4��G$�<{�w���m��!R�/^bNxfUƍ��%�o�
��5����% p'HL�l�%J��]r"��ͻz���K%O~5хy����AZ�yؔ�� ��-�^ǘf�DO���q�{`#Q]�j��<u�i*�"�lq+~~�ҹ�����o�`��L�"�d�"q�ٗ�3o ��h���3�z�( o^ E�E���ڴB�Wa@�LTA����\�J4zoL�#���?�]��_#8�ݸ�],�Q�΃�5��3p�l�@j��J ׻���� ۅ;"JEY�;�=t�Qs�=:7�s��v�$m�����c���n�WpG���m���1��t�{��D����,�b7�N�^@���%��7d0W�#4�������S�ڛ������wV���2�{� �����������,@�j!h ��M�]*�u,��;�B�M��"��fb���I��K%���b*Z�lo����8��$�P�hs#!��e�m�}D@J�����D�K����F4��5�~Y�t����C2؎�._��d2�����A�jm7�x��ൊ�1�G�j����$�%��s6X����<��7�\�{�/�߳�X��'�0i�����}��*{�g��W��-)�/�FvZtv��?��!���,�+}=�z�2�zL8G��#p�>�L���L�h�ƭ#�~�<��3`e�FG���£ŉ�Dc��4	/:/��v��bA���y]�=L��<���S�|�A�(�p�gr���R_m%]��:��5c�=�s�o������'s��ϝ��4����6h���Č�6=���Y$%��ы�U��ˏٖ�w�*���=�k��9���yu��?Q�V��Erj�C�y$�L��]|���I7A�"�T��ZK���j<>\�+�Տ�4"	/�ﺳϹ%�'�bgD���l;E�7���f*'�u/��@Dju"ͬ��Xnݩl{L�B�A�9fU�Xj��O�O%l���p��<K˕� ȘɊ.x����4�����z9��$m�l :�?���&�14��#[����
�'�s����_F~Mc�S_� �9E�=��X��!2�N71�[8�}\�[Ծw/i�}�ꄺ�n���W���:�����ކ�g��}Ɉ��l�&^TZ�/�C���k����p(o���#�"�A}u�Z����$Ľ,��[ӧX�[
Y�!��
��i�0�~?��L�qGd��+��WD�M�;) �ԥ4��>TQ"�����Vo�ʲ�@����RMe��v�����INF`��>�P�ٮ�ʂ��������d�e W#� ������2H[�+6y?A�9c+�x�I�Y�� �()]���ı-�c����/ ��cζ����++J�&����y��$�����QPs���zl,�+J�L�E�;]�p��>=[lw��xqc�~��S|g�����}qxr���Ӆ\?ʁ0C:�/���X߲�kS�0hX^��m��Yh�jO�F��A%��x	�P����"�5�#�6ep24��e��Z<�`oZ���?.[)v��� ��r��3���˟�;�^1���R]�#�u�q-����ճ.��*��I`��5�OF�G�N1�F��s7F�~n�8Cˆ�WL�e��.8��=���Ե��ZS�U�$sH0���|�qoֻ��v
�v�ZG4p�=��=�Sy8y}�Y�*Ձ����N�#A.܀.�#�c1�����*���C�-U�I��	�VH�y|�.K��Y����DX�9SE�̯#����Q������O�?�<, �O������t�<�i��+��1���hS�D��QoTj���#7��s�Z��s�X��LL�����Sف^U ���R��%9!G���9�f�`�]��WY@jc�n�;@���Z�i��w!�7Qx��8]cD�P2`6q�;��0�U�];��V>dQ�B�b3L��vS� ]03`��g�M��-��D%�):/�_2���ɹl��J6�t�7�M*W[0}����x1ʹ
�,����bZ�I���z��Vv��`����.
���:N�F��@ >���
�׏�{�r���sf�?�;��h��o@�	>.>У�R�%��R��L �%1-��=����UMFz��dҶD�E��G���:��Iv��jg�F���z$Ǿƌn<���P�\�Թ\��ej�#�w�W)�~Hj�C�������'���r�����;���^՛f� �Na_]CSLk���>%�gb�,�Q���hŹs���UB"����4~ĕo����v��1�H ���_��9_Qh���
�Y��·/X�h{fz��g�pD��L<69�6�O����$���߅�p������� ?�R<�$��/	h��}�l��-K��̝	l��JKQ,�s���z�}��`m]�D8m�S.K�N�Bk����k&���e�HP�_��f_!���&S�4]%l�`y�����qS�J?����˝����;9q����;�2�Ēv�m`��� �(�sj�ĉ�+%=�
���W�"���Zy��9�b��U�O�N�3�m�	���M�8���Fx�aO�Ys*��:�In:�S58��3���he=.�[m�2�(
�,�9U��g���~c5���y�*�=cb`)ߒ*��]"{rMC;�C�JSv?eثI��T,CF�2B'4S}�Z��I�����0>���F��u9���`x�ƺ���t�.�Hx+2�q,��^���1;`�<[�,��}��2Y���:���)�"�]�ua0¦�K�J��!3�'y6����\��H����u,��N3R��=�xJ<�=��Ep�׺�u�rv�rM.���\��U�����ѫ�Y��H6p�6qEj��`�,���G�Zo���0P�#� ��Tߛ%'Mw�K,
&���~	pWq �{+ �t��~��W��~jˎ%�D�!������7�Hc�_.ω�՛Ö�_�ϭ�n�`���+n݈= ���u��r��'Q�𔖒���̂W0�4=�g�4�ID����|f�ӿk�BK��.���FOtpD�oK�~��������*,_��=	��H.��+��k����z�`�����T�b�+AD����ڠ�����-MV�?��9�H�������g��/�{*�+#A{��My}Q���G��.�h	�$��{=./�&OΝ;2A�tJ�_��Dx��Е�n9t#�徚B��I��gΆ��������b~A?H�8������`��Ϻ�0�b��(��ڱ��B�,-{w�ut�#kN��
���s3�?�w3z��阅 s�Z�9� e
Y-d����iu�A���Ӊ~�����2 ���ٽc�(��J%��:��s+�����X����qOf���$O�����ʋ#bt����>+a���>��f�}=���^���i�6�!��~˕p��׽TE� ��(ZH:|,+��F-Ȧ��땯��yRXKʡ�Ow�:�0Y��播��:NM�NU��庿t{](n�
��z��~Kg����Z�����VD�]���4�4^�7�_��0���R)'�_�+󩌼��Fͦ��'�IU$+� @C�y���x�Z�����}JD� q��#����
zh,�����uݹ+b������b�'>S|"�Z�׏�:���Ҹ��_� ֲS�O����DSj?�^��L�R�Z�������W�m�aHq#{���p��OD�3Jo�-ǡJ��%��hX/�EO�) }�G����X.�&甥���6�2�?᎑�3��VR�X^>w����sV�$�H�r�-)����Ѣ:�=Xn<ah��"D�z�K�<�_sϮ�����S�C61R�Oh����A�g3��a��G�8Ĭ����H���%�@R�8�+�+��}m�� �%{�ȭj#A��j������Y�t^"͈�K�]P����:S�)3�	�w�K�qM����rl{}EgNW�j�wq��I�F�M(��U(	ڈ�=��O������I���n\�k�J�ߕ2MҐ[bF�)5Hݡ�j��:Od�y��M,��2���$=�3Y!W����}�6�o�zP_[�p�j
D2RJRN] p�A�^ԀP��u�	�U�w ��V�_T�8��W/�VMq�NPp�Di>�l��V�20:��w�-��*t]fע�N�(�P.s��J��U��|q�ɀ_��-g&x޿�m����s�q�����
�\�h��$}/�@$2���2圿�N�t���<_B�9��6U5���8����F���f]�e�E�'�?�"M/a�}�%���Z9��m$�D^3J�����[z{K��j�������'���������B�'�E���:��=�\?L�}^e#������|�-�jϹ ��8H�� `²6'�ndIQ	�Զ��Z��-Ð����W����OOL
gb��hz�]�ܡ�xA@�Թc^"������noy�/��%j�šT���K�ч��
$â�?�0�~g�4�3f�Y0̑!�N���v��DQ�/iZ�}[-n>sl�t����g��鍱�h�fu4���;8A3�.4�6ak���GKh��w�̨�[�s�i*Iz�Ԙ�{=d�^�{7 ;���v ���������TBI+b<��E�qqc��Ƀr�J�%�쭵o����\�~��ɵ�D�7�轾����TX�h&c� �io�!�L9V��i$}���/����%TL�g�k�Kj�(-G�)�;��Ľ����<Aa���؏nݟ8�����/�Mg5/iio��	6��O�ù�łz�����X�V�EB;�;��\>�\*0�yި哳B���k�����|S���zdC~�3B`�M��u�ņ�ۤ�4#��^ix�A������Sw:ۓ�<C*v�o�Fb�E�����'�êRL�=��k��y�7ylv�6^��C^�i%��-GX�
}��#;Y��Q@IF�|�9HP'�R�2��;?{���O��;;��N Q��{)G-��<9���J}����
� s�0V��6��].�<�͞�gM�QI�J��<��cO&�}=h�2;�
���p����ҩ�j����"DF�j�E:
�{�}&�d�%Vyه�<Sf�K�(�F����@��r�b?�8�����L�c�F|�&(��i=%ӏ�����1 Y�8"�'�����,�,�I�;�?e�6�0�ÅO�X�����{�O=�ѵU;��y����#.`qQ�r�g]�xM�hc��eûtr&&%R��n(���-iB{���sk�� To��T�L���fK����MK�!��|el�B1�����y2h���l�Ou<^��Q�I����e��W��|>&9��Ll�0���O�g�#��Ц��	v�3))j�I�$�����|��tj.p���Kg����NFH��7r����/�O�*�$���!��8���bq�|π���P��.:����3*P�{�g��+�s�~�9�5P���t�9߁� ���l7�{�Ä ���B���Ǚe��c�}ݻ	�32����/��F�m��D�-����U�?ҮO�
��絤��M9#-��8�d����/9�����r��#fp���D���X:ŹL� ���&�����!��R،���XݹH�a�T���Ü�{�*!�N�i-Ȥ>���b7��֕��ָ����w,�/MZ_62��ŭ�}B=K6���x�^S�0Yfp��lC"xs����j�o��^�V���e4)�:��H��2���TH�Ǿ��ߑ�jފ���j�PW�" ��.��J�?�����:υ���a�Z��t��z�{�فs�0F�'�����. ��#.xǉ�'�?g����jxp]2���,�n"��;)��A���]38���5�Mѩ��;/m�u7��ߝ�������Ҥ���}�����6�Rn���u)/��3�]��s<���{�)�-cl���ñ���;���$��c�(���$0>�R���~)J��H�dt?/0&t�۽q��]�ȔW�]kpe�ɱ6�yL�d��na��������}��c1� l�]���25Po�*mSWPP_׷��܌]6)�K�L�f8�Փ�b�T��ݮ�)X���ƞ�Q��$���/';L�"�V7��w�9�*�qI�?Ǩ0���M_�IH�6�qI'F���3X+	����ϲ�����Pߏ\dF�{Ub�"������E;�#)�fbI˭`�2!2x?Iwڣ�O��(�Ʀ���l(捎��[J�pj�rJ��G�O�_ZӜ�N2#�3I�@ݣ n�Q�Y��;1r�{�褴t�������Igϱ|�M�|C;S���>w�����;���ku?�e>_�]���X����c�?���|G�I8}(eG�\,#��Pܭ��6�e-�&�/�v��f��{(�e�;Y4��"���F)����J+���e� ���:sћ��k��� j��Az3�`o�N+���}�lz��+�8Z[�����(9�]�I���|�Z�堸�}XB�i邖�5,�sQ��]�6��R�l�^��fy'�u�ގ�>$Ɠh�s��7��u�	���;��ʜi�I��׸�Ud�Gu���Q$5�lCH��1�g=�\;�@,Ę|1
�MErs�2�K�E]�����WU�>��F����R�a�"0������!�s�	^pRo�=��4�!W *�)c녾��*�C��W�'��,-��n�Ҋ�$�s9�
�Kp��gYS?Nt�se=��I�p�'�µ7�\%`B�w��ѩz	�vQJI`Y��\EV�5���eg��#��ռۉ��8�7݉�8�i��X��e�Ƌt��0&=Q��9^ς�����$�:s�5\�Wٜ/�#̝�i�2K�23K�����j�&��� �3��[̈4tLn��B(g�B�N���Zg"ZIO���_k�sV�QC����cԚ6���<FfN�6C8�m^�˗�����(���?F�6��F�{p�y����_��o��z�w��n�-�D��ī7+U`u���axV�&(�Ato�Y4M"����+�����s'V�/!orpE�r��}��+�`���)�6���*`9�ǩ���:�����&�������c%-�v�����!����ž���2ڨ #әKO^���]SD�a����I�~?�{�����Ǹ�G�b_ͷ�6o���� r�/� �K�)�����ÿ���{���!@��K�,&��H�&�5�Yf� Ŷq�&d�s:�����73l93ۥ�),��vC����X��z$��M���$�a�y_��d��?"���Jh �!ڛ�����@�A���������YN&��2�� �հ���PچmL����ʦ�1(�g�a��gD+0���Sw�'/�-b�b��E T5�V"�����ny�lbZ��P�1_q�����e0���5hF�K��5;5��9$�,� ��xrG?
��x���@��5\�.�)���ɮ0<<u�?�i�=2(lIY�q9��R�!�Q��䶷�.E�^�{�B=/d��&K:�]��
����(c�ԝ1UO��;��6"� �]!z�g��!��JYaw�v끫���^΅:Y�Q���{	H�~�fn]��{äi���'��Mwd?K)����㕇4|��m�l�߫�¦A�$K	�jl_Y��nj����9�"�o{��5��e���k�X������t��*�N��/1�zU*�~x�����z��пu���I�$�'����<W!C�i���Jmk�Qa<˦CUMU�W�-HK��6�V�"�v���K�#�6�up���#���@��uE��E
�E-j��} Д*���}Ylp��ф5��
���(���LDY���Z�P��=���W��hI��~;�:?�� �`V�ւ���D�l�������C�)�}�7U�N��l�A;����Xݰk	(�5zXK��̬�s�Id�+OZT@E��T��a�Y�cA�_<���H
k��EP'se��8�7G�ʰɚ5(l�O�-{r+��K-��Ҷ+ehD��_+��cL�_�6����}�Ϲ�QY�%{b/����M>��F,�IB�ޞ��Ƿ����R��ԓ����'/3&���v,m�e�A��S��,��b;Qc�z�Ҍ%�uC4���D��!�9Zn�g h������#��^x��<֗���)w#N�؜1�WE�(i�ڕ��46`���Թӳf�Ø��;��?�6�L)�xP�3[@�a��عk�x��#hn����Y����J�^E.�y{�d�)(L�����j�H�v�u�9��'���+7�g��� �������1���`���+vJ'E���_�k+��T�� ���Ԥw��w*�%;����	�P5q��9T�}�)2n�mǚw��ɒ�����*�H�շ����	Ns� ?����V���0�Ty��ùU��uM]��ٗ?͗��L��N��Ú�z}���i W���D�k�F/�����=�ҁ$]GMm�I�%�1��
�ڹD`�Hfwn���҅�V���k-ļ ؈�sN�kP�V�'�i2c,g8�"�5�-6�pS��V��s���7(�%�u�Aْ`�^��7偠K~C��eݶ�U�j(|�M�̹K� �J�6�MJb�Q�����
��G�!�R)��3��u�o��t���G����?Z4���D�-��6=���I6T!�t��c␼���.�B�B?~�
�Xi��-���ut|�Xx����˭���IK�"B�4�f�;(��U�QIE��z���A�[�����~c1�'�_��~t����ëG�S����[�xq�<��R�@u)Q��|K��<���M��O����B��F%y��(�
!YR���Nһ<�牨L�}N��0�y�ʪ�e�j^_��\�>�G�_`]�R�7��VE��&~��2�:H�?�l��CI�L
����G�+K4n�&`��XZ�B,��&��UI�%����<�����L��'�o�����,S,J�	�Z$o�����\�Y�26�s�"p694h���P��Jg�-}�N]�,d$	K��N�����l�X��:�KF�E���U�8�^�3Il4֥����#+"=���`T��IxH�	��z�$�"/�!��n!��S��k�@n4ςF�m�S��Zw�|͹/M@�a��ʣoo�5p��qp�*�i<�hN��>�$:b��	/�el���B�C��ݰT����� gǮ2�Q�R�.N#IG��!y渭���ec�ߊ�4Ha]�E�A�m�ɖ�b, L��=�=��c����)f��+�����qusߘ��;�X�AH}��Y�9�;��N����ZYr�z�N�N%w��@j2ِs�C��N@X17O�zm�X�뤱e�%.,[��-���ߏ1n@ߎT �7?գwѿ�^W��f��`ɠZ91y�:�=�F��jCqsH��     �V_���� ����%����g�    YZ