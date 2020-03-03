#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4183087518"
MD5="396baebd81deefa203f9e1e988569d47"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20664"
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
	echo Date of packaging: Tue Mar  3 02:54:02 -03 2020
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
�7zXZ  �ִF !   �X���Px] �}��JF���.���_j�ٽ��aW����3��2^��l�4����z=�"4.�vn[s�`H2�� ?L�U}V�B08��d�� �mb(���$(�U�����l¢�9E�]�<Co7W%���	�]�ZD⛢*�f�X��7m[,++�/��p1���J�;X��Y��a�t���HI�ް�-�x�r|�"i��)O4e��!V4�M�EQ{��9X6u�e8������nP�V�e��5����l�T�m�j�E�����F�l����V� <�ɫ<OԍKś� �/;��v2$���Q��M��:̈́��s�g���8dFB�Ixf��kW���U��!di�
^;O�"����XD�Dh6���0 �X}n�?v3CMY��LO����"�t{DЙw��B�d�ƍ���J�h\�
�T��p$���?�u�
r��q�]00%��4�6A�~�hn�l^�	�P�s�����.4S��Zy�lы}$�R�Q�4�q<���hy�>'r��*��O����f����>b�����
��`p�E5�h����ᛙC��eRe>���J�c���&v!�>OL�����YX�ф�a&7���Ke�Hd9���%r; ��%���3++B����t��SEz�F�+��yl�D�`\�WO@lm�u�jq@��KD��g�lMJ�(��h���";է�!0_����
y���sq:z�ʳ�8 aL���R#:G�_.�U��^]�2fzD&-�=����ŝt��Ա�}�-g�y�߸����wf���bD����3��C��&�_���!��}���nxy���$"������u��_�Uo��)�%����;�2��L�͵��ї��
�%���@�ߜ���&��5���gr+~��&暯�Mś��* �̷��x o�cR�J�Fa��`U�O�`Nv���}�OGw���p���͕{r_�?�
9/q�s;#h�ʕ��>��*Ax���������`��%G6ˢ�I��I�����*>�V��o�b��LB�<��v�W
q�^1U�i=N�9��2�b�x	 �-��V��˗��n�W,��ټd`����W+��I�Rr���K�;�lZ7b�";ꕊ�Qtl�gQ�3��~��/v��n�Q}���$��&̷5+ @s]���q0YD=l���_t��T���x8�	A���������5Y��&����D�?k���7�Z��J����<b��I:��%�^��+����NϝI�D����"����7��5s+�ns^4NH�i=!	���q�3��-�H�N����_y�
k�C'Rv����o�|��ٻ�ݕ���њ`��ac�m�DH�F��y�4P�Q�.z#�	e�G�(,�bgt�#� ٨�.s4Gw+h��-���ˀ���J���%�B)sEdY/)}0�-c���
F�)7l�D�y�U�R��~��@�{5�4��.	q5���D%��A�j�ׄ0>����q8�I:���=֣V��~= )���ʣTcR�duN=,TXgU���,�1����4������2�.8٪T�zk\��8���� @�H*���q���������j.��l��Mv2��2̌-��X���\�9��<�*�x�`T���ޝ&�H�h/�~���;	8��Gdb��N��V��ט��(��1˪'J�k���^z�37��{ �����P���r�Y�8�;���&̦2�/⡝��\��aP2�L��K�`D�&�`�X�R�x�2�_7�BV��[�8�Gj�F����d][�ˤ�}�l�]��=e��6��z�,;�ŧ��w�:���O�s����j������YX��{bq�����բ�����o�z�kp�N��@�%}H��9����ڢ�>�]Y}�}�H��u�,��:���������D)�|�&P܅���f��4���$/��w������b��Il�pj�e��=���I#�P:ƙ�*,�9�:����&�79���C���+���"���d�G�|��A��}��e�ҝ1�DdٜގA[д$[U̍x������:���D��l2�@�V�.�P�A����ڃ���t�;�*X`�
KVV���G�R�����
p�❅�f\J����oP[^���gZ�s�kR�Q��rcv���7�1��k�XL��EP���h��v�$�	�:TBx����'1D�si�[�����mP;����Jj��Ą�Sr��X�P����Oz�F�uG��[{� ,�R���0���qڟ�S�S8�@��U�:��b��J+�%��kQ�5��r"�� U���-�@#��[X`?\�9��nnP�k�B�6��O�cA�q�h��_ϯ�Yr�D^�G���
l�I��g���4Z�7�ѻ������;��)6���	�A��� ��RT����D"Ɲ��ε��#��ӿ\���=�j{�O�~�h7N�
XN���p�PJ��]8@T�8۽q�׀K�Zp{l�РS��|���S�k?y��Gώ����8��ܹ��R8wڝ*��7~>�_��("4�_yDK��?�K�-�m!(=�5�.(����2���E(���-�_��z��]�b?O�G���d��ɸSt�V���裡;��1wmq0���شI?�7��#��NA�������z��縤~��K3��?�Y�$#1;�� �&�)t�Iɜ����k�0�$
޹���Cp��t2���dH��¥�D
���4Y<��q��#�Ͷ�r�A k���� ��%�C�B��&~]�exxP�*�m��S�������A[Î��Z���ӛ��D6+o���G�`���c�"\R�nI��:��#�m?��<�F9�U�E�\9n�I���B��
C������\��5p�OO��	��a@$�Ǣ�Q�P{�e��`�/x�W�f�;}V�:?|�]y�G�"{P)f���C�άIN���RSv�(x�3�Ҋ���m���eU��h ��vҁ�")3v�w��r�h����,����ɹ�fR˃�uw�|�f�z�mgƼ�G�IUq��P~�����}|�0�M}p@6I0I�+�8\<i��}&$�>t/St���Dn�<!)߀�&���GSCt�dP2GHu��s��"��=���jM��a<b���I���w��'�˷X��B3�$�@s
q��mfp��׍_�0��6x95�4�$���ň
�2G�U-&�9;?�	��&��
$I��l��u`��猽�����/%:��Z��ms�#A���>�U�/�N/�
4���2�S��4[	/�V���lڬ'��2� ����G;���g��})�e�:���d|pd0?���4�V�=�/J���eZV�ւ<���Z�w�֐�Ta��tWJzhn�~�n��B�#�__ûV�������D����bBI�����)�G_�ɗi�����8����!Yg[�w�,z�p@S���-�oA%@���8�Dc�&��I&I�3�ՄK6�l�
.���p6@��o��e�����?����9���?F��'��R׸x�Μ��t�  ff`<�ɋ"����hSHa�}~U���@��v0ٝ�M~�Փ�g��w��ω}���>_���^^9�޴97������<�$h������3��%fa�T3�j%�;�4xEݕ��֞�$���R��د�Ύl��=r���O$x��D�/��VGNj�����륮���Km ��~W&4��̘4��uv�a��5 �����d����,+O�[V��u\�H��>I%� �j\v0#�H]A�Ͳ�"8t��7܃L��v��ޗ�'8Ց�T5i2�
^�%�R�L
&}y��T�5Բ�P�����j�C�[1��o���0��ħ��50���a��%!�*:GH��r�v5�dTm������tQWB/�T猀����Ǖ=��&��:�p�ܷ�H��{ڔ�E�x)7��Y!&٧J,�.�F�Y��2���ox�x��XLx���'cZ|�C��iL:%NG�����f����v�y��~��'��.��m��Y���ah���ȅYM�Z�!�mQ�t����ቚ7���'��$�Z�QL�/���*W�7F킊������y��U�=�N�ׯҳ��,����y/^�T�[Xְ �P %����K*�pz:*�P)��*O&�i��Egv����>�j��b���E\�W�s�j�&TG�ˀ��c��e{TFJ���y=�q	�������kxD�t_����bc�V�lނ���?zCf�5 Đ6�.��7�#�~��PE�X<�Q,�4]�B�n��T��M#y��s� ��`�/\��eYx���F�/���� �#�}ur�%�Ax���tc@��VcM&�7.�y��r���Bf6��f��h!*LO�������֩VV2/A���@6�t�g�5!e� ��E�C�,�Ԥ�ViX��ъ�L��o��>X�J���$�} �1�����8,�#y�Ux�VW ^`v)��J�OD�	���@��;�ξ�G���ꠗ�ꌍ��>�X�\h�,n���k�$�B�q�p33x$�oC[�y�uQ�.��^��_��Bނ��H�#>@�q�BK��<e(W���Dl���ҪS�=k�$�&��ˌ��*��CZ31�ǮԻګ�.R�9�-���ծH�QD��~X��������x�)���I���ۯ��9Ù<�58&��}7��I; ��E*�R��C�� ������t�������?iq�e<��J�~qxm4y�l����\O)��=��H�VאԖ�E!UWe_/��5�,�Z@/gd�Ǧ��FC�ύ�R�D��L��J�z��PC�+��3�/�1^}v�n��I:»c��PQ��-�����Rb�WYo_Hj滗T�'p�J�j3��^U�������!�wf�5� �R�I�^�:�X��G��z��OH�e��D�W���_����D�\�u ����m�Qp)�M
~�F��T�P�����>�(4@����UK�4.�������seTBgB�����(p��?x�-��p���P���
�7h�N'�T���aG�����T' �֮���C��Ӊ�k�N*c@��`J݌�;�s�}�s�ߞ ��G�f]��f]��������?�WH4���tB{��v��'��]�7PYvU/�	�Z�%j8���3���Y�
���`p$���w�A֓�߯���p[�ة_cF-��at�.T��°��H�y��m��gEK$�T�K̐S���*&2T��� Ly'�e����x5I
^h,������20Y*E7����������w����8wa���{WGN���������~2ؐ�K��0��h�V Go��㒦��@��|�o�ɬ��\���U�(�i�W{�k;9�O���e~&�"V��UO��|��1������<��x���l���o���s�/�7�������1��fw���w�"Ȳ6A	�.��W9i��o����lSuim�4C(sB�N~�����eA�_ܶFi�b�]��p8�ϝ��Tp�v��^`�S�A��D� [B��W
s���T���އ>��&������ym�l$�9S�u���p�'�{�>k��ϭT8*������|��w!�-�D��es�4�=2;]�)�"5v�PMs�GQu�i��>��HۭlT�q�7a}�]�ZO��(�L�-���O�o�B����t��R����$f,Hl�Q��:}���u�x�B�c�y���������f�#K^G�_-�W�b���O�U�+x��{��(�LM�e%2��"���g|�dP?�=�m0�b�n�Txu{k�������z�^�ob�zj�]�����L?��F7*�"��[C���z?��H<�%QJ�_�$�Mױ�7$��t�g
��¸Mm��^3H�hŤ���(�%��D�x�]�k�.]A��h�����,�G����jH!�������yL�S�=pD�P��z��M�p;;O|>UT�Ozo
���)j'��	D=��e�s��O����8?�~%O��ͩѫC���Xb�?��ˬwBl��<���� =�&7+�cB�fj��+�k�ʻ����� f+��Y�m.{�jY����U�^W@�#m�>��������3(�]��7�)t���&���R��6y�]U'�*w
lL�Zׂ��*(�����MCn�7K�}�6��>�8���`u�b�R��ɭ��)sku�M8Y̪�mp��U��$�oÞ�_2��TLi`��ڼ&�=@����`á��������
K ���fn�࢈E� �fHjpJǒ�[)��]��Yy��2�-��4^���7����rg�Q�IA�)!|3b���6zǤ�v���<�/��$��'���8Q�ioȎC�=bTmTt��I��BC2���E�j"`6QQ�}�k��u��X� 6�~޺�=��똑�^�W&� b�e���!��g�{-~�S�%��m)�~W
-,�Tx�q��IUD�}zH�;�j	_h �r���=�%��v�p��N�#�ш�9x�D���ѩ�[�aŭ�K`ȗ�v�@x�c]�V���X�	B� 	*i�/����R�l�� �s�a���̋��#�c0K��LTر��6�$=� �� �6�ǎw+7>�!����݌�ٖێ���[R������gZ{�Q�e���z��s�[��r�1 ��@����~�0��b�>��E6l�6�{�A�������������F�d�,�r'���Jڳ.˪�ma<%f�2H����G��e�㵡x�ƫ�����o��0$����︽�8�&�8D[��2��+���MY��iN�ޫ�ڼ;!���=?�}H��=���#�A��K��FA��&��"��o2)�kl���N�� }{����'d�����4���#f_4�~%�ABA��d��,ӝ�DL�PӺguּG��Z�.޿�M׈t���qO�tf&D�Q0ʓ}I�#<��Ȩ��8��g�wO���J 1?Cต�
�EPe�L++8o�U/���N��g��/�7`,���{98x��F}=�/��ǆ�:)5b���$���fzNX�I�\�_376�̞��Ʃ<��uÿ���&��#x�ayNR6<�����QI��<�k�m�%��)�G����l��͔P��;h�sG�҂.1B�/�u!��^�p����u����+p/
���������[A:���TW!�J�-ew1< \ov�҄�>UP��ﺴ��xK�ɏW<���Y=��aʰw=D������>��j��^�d=8q��!@v�(�ݏ��R4�&,�3�Z�zʫt�ܝ��E���|�Ɂo�ǂ'��&/bQ�O�/I��w��ZW�s����(�b������E���%�C���3֨VO�M"���X2����-ؘ�M�2��\
��.k��)��7��$��Xo�\�#D�����l_.v�.9(�M��px��}� e�MA
Ԫ$�k�s����d-J�R���1��,�����>K�e4�~0��cM8��F��g.ղV��B��c�Gp��ܜ8;��òr��L�0����N� ���H�ue,�aIn;�ur�����V�����, �KF��Q6y������aq�d���ނhҖ��W
��#Ft�X�3���ra��أ*B{s�@�����q��1�W�c}G��d�Lb
�m�힍y�2�X$�����_)�NH+��Z���m0���� ֧���7ߗ�%�N�	���؃�G�1k�=U��|��:D��X�f�⇹�TL�.H�@�vs�L.>��b���b�V<d�Pɪ�����h�͚@�6�����'�PAI~�(@8�w��1*P��LQ�����/.���|��9X��ً�G{P��G�Oa���� x�-����g���	���G6�ޏ����-\�>���E���ЂZ
-�n�������#��[�@��p�-�8�-�&jݲ������$4}2Y��5,�6GHH՛.g;T�wۚTx2x�jd�1�`��{m�������O�o{��=�<J�Ez��c[V��3e!��C��KvS�Jդ8K[.�w��.f��;�(�q��dWq��ݲf�}�F$wPM��A a������ޮYhJ��A` �J���ح�wP�}m�=�8v@��+�D�\�_�߿U��<8����+.�}I�	 #W��Qu����k����%���(�4���h3�+8��t�b$��r� �O���+���[��vV���˘�$��[�����;�H��+i����Z2Z�-c��ȡ��zk�̀���S1��K�f.��1go�]�~�� ¸J�W�`?P�Vא�}�x������[�9t�%Q��`��ˀ��φ���Kː�"��8�M�B���Ejh�^�U�p$`
�v�!8֛�
��w-@ņ�0�� �1���vo��'e�Pa=z��=��ӎ_�8Z�@��b�ć����ߘ�����ŧ蛤Xd����u��".	����|��x8��Ǡ��P�����s.���7�0xY�s2���Ȧ"���Z�֑a�r#�u���'��(�6�A�1����娚�:ya��awy�t�hn[�`F=B�K��C��p'F�žVp&X��>�o۹g��G��'�P�o�� )3D���M�y���Ч�q�2�W���w�"}?�/��W��y��=PQ�C�"3f,گ1��8�Ëa�Eg�j�P���'Д��2X~W�e��C���Q3t�r��Y��z>�t�z͂"Qv*�fC�~.wZ���4nlg4�ĩ��`����֥��r!.������"��6������\�r+��Y����NW�����Ҩ~SP[_�� �v�=	�%��6��t"F��/��ϫ�;����_w����F)�_�*��y�V�V�W�h�Y�US�Qp�F��������R?����k���miJ�c�j}P�rt6fq�.+�ƆnHn��^�=A.U�r��L�����ØR�x�.2W���*
��ӉHU�����r���"�N��Q�qk�h8�&֧�~�'!��;�thg�b2Z��-�Y��Xd6�pƾl��Ρ�0�V��t�j?Gz�پ~}0
�77@/"9fm���q��x�S_���z�O�t�0��&�Y��w��+ˬ+�h�6%"+��9U#!������ǌRaAC/<��c��	�䒛��+o��Vj��L��i�����N��Yg�) �,^��o�.��J���X=�I����T�����e�H\]�,_���4a�
>6�(�x(�L�d�DcCc*�,�r����[��2Y�RS�rƅ3�h�n&+�.'>���"�;�Tf�H����\ʦ�E p���+3"��<e9�zo��t�G��g|7/�����2a�&	��mF��7(��瓬gr������(�ɥa!�ں�� 	�0��7_�},S����Ru���m��-b�tn�F�~e���A�:�G�e�^F�)��xr'���i�{�[hxB҃lA,I�U!�q�;�zf07�\��־�7叡��s!�_�D�q�IX�d�h�g���qD^�v��1�����淥�ǬY�?�v�K�;@:>�$�ID?]���o2<"��ϵ�ւ��B"�n{<�Ȗ���R�sy}LA
rm������$�6�8+8��^uV�dF�g�%�y�8�k�㛘
�D�O�m�����lL^��g��&���E9�x ����4�Ѷ�&�
�~8A�=������z��V������ v�x#�8�&@r�Tx�����H(��}{��C����bOs�,���A�r$��ƵW��q��HL#�:ׄ,(a��8���Y�����?��-e��Ad����4��O��'�ltX��ᆣvj���q6����5ߎ�^��X��~�E��F�����{c�k�5�4JX�$�0��w�@���k|�+��&.�uD�Zێ>e�����A`���i7�5����҄X���\�mTH��V�� ��..=��d>�<���c������\K�c	�Eh�<�;8n�ad���v*:'q�q5Zq��U�+ n��ԳxKY��#��-%mc��Xܛ����W�ka���f �%���W��W��1U~�8����/�sRQ���4v��aD�ߢS_d�>�޳a�0>��{�fy��ML1�vKN�
t����<��Զ�@�B��|��ˀEw�Ŀ�Q�p����O�}I�;�pVX�ʥ��i��>�93�Q��ǾHo��N�u5y�������fk��P4���ZhF�5��V%c�׿�ݍgdE:�����DqV.�\�ye1i{Xw�WB�9g����7D�!d��Rs�0��5����U�"��)�E�d [�q9��T�m���r�˦�p-�(�3V���c	�Ɛ8rD��$y>^X�� �:w-m��H��>��xO�0�Mk���w����o'2���˵>��M�q����|z%���* ��m|�2șb$8|����@&h��Jm򩗳|� �aQ!��ϐj�85M0W`�
$Y���`�r�
�=�kb%Ԛ�<�E�q�-T��4�N�����ؘ�5h7I=�������%"����s�*߉�e�[�i#����@�Ԟ7����)Ұ�p�F��{=��q����t�=c���m.�;}���:�H��N���ґU����_&��� ���7�H�x� �w��k>�k|��v��·R֕Ѵ�҂4��^M�[�N)FM��n��D��'��f�<�2��Q��A$h~���d��	%�iEӷ��ݚ9�ӡo�<"JUv�]����_^��
��� խ������_)�`�ߗe/4��.�9Z}���oP����'�A�	>�-��P/!��T�:߸��>M�I��	�D��-�Y�+��íH�ŧ=��_��8cl��O������i�W���wD������6Xc$��I�
`��?4����i#��7�����v�ԑ��
EL�n�-��
4Wq�Qqi�觼{�o���E�8/�-P,Ƒ�ԡG��o����� �u#Ty�X���K@+-X_�
�p�G �12��:�<�_x�MF�!(����r���!��7=��[i[�w�F7���wx��pe�FO�[���q��5���� 8���Ǳ�G22H���)�sFKJ�;�fW����]����4W�o�`����	��Ȧr�W�xD��Z*_��{�����tQ��"�Z;y��^��7��B�#Ft;%w��&K*�Ŀ���{7B"��O�O��'y3�*�i�>z&R2�Ѫ.Q�.�{NS2���tt�	<59-9v�$��1����h>���nā��_]�C��z��s-�t'�p$�:�j��}t�x)z	��( H2,W�����8�(v	 $��c���A8O�組5i9������7j8s���!"��!-�JD_W@5@�J(�$��:>��yߋdm�J�{�!��t��j�T��V���T�$3P%�
��crS��-����M��t�ni�Sn�Ì�}��Y8P�����q�Hp�f���Z�\��h����+|u�7�T|E��� ��Q��u3	i@�qϧ�F�p'8�������ۨ�8����^�xT~�7�����[�J����^k��VN�]�}.!�>H���d}�;�\�8~���Mݠ\mg�ծT�s\���I�؉���R���P��-W[��DyY��J���)��M+�E�t�TW+`|e�͈?�� 
φ�|�Na�s�_"�iS5 E�A�|�g�a�&�b*v�
��^����)z��K��o�t6�R�(��͡ w�vá�I'6��vL*p x�u}7�Z�U�+?�&Õ|��f"@o��,��<CI��lH�q��`I���O�d���J)��61��h@ۜϿp�|G�Ez4	��y>��>��I�W�C~������c����-�F�i�t��غc5�U���]qG9�^�1$�}�a��x/PZ��-x�V҈��G�ӫ/�L~���䲨ǖ@��U6�O���"\���`�'� ڷg�a?x.LH`H�4l	  c����m���8�b!I�?�0�CN6Q�40Ͷr]�,�Ȃ}��L�k�Z8bm-��V8)�4�w`ę��D�ru5��=~�D0�^d\}C9߀������H �ދ�A�c��ݾHj�҇�c2�4�mmbi��D�t� �5�Ɍ1<Z�]����Ƴc7r_�y�ߡ�'t�~�-4%?���j���:
����b(X���)�ȵ$�w�_#�l���L!]�t�K%�V<��9��o:uuٛ�O�G���[8GG���ϚCE�-�,1F�0*�E��.��]�����X �m[\�]�}�e��x��s09��߄k�!ՙxu�ܭ��֔�y�C}�\��l
 �c�s^��)�ܨ�<�ꜣl�k�є���;��Am}.v���`i�ļ)�]������ Cuc�-=Θ"��o�Œ7�ɓ:`���UT���M,쇍D����Ĩ�����6.M�$��D������|0��@ܷE�oV�Ҳl�#��F�U�y,��X���k�0ϵ0��i�P��rSn�yfK~ҴѬt���i�P!�U�h��L��&�t�X�#���*�8����˟KS�R�]D�z�"<����l^�O!h�^"�Q_XO�-�P\����+yO�Xy����؎����l�x@���<-����\؍�J�ˣ}|?CW�x�d��U�n�n�P�Ր����7�~����S��5�x2�K���NԴ��8���W<Va������]t����w'�F�hF-Ҭ�ƛ��W}������t��\��݂�9��8ƒ�.�����+m�D��&q�2G�H��.n���)Ԍ��m�\�3�J(%��[�o��7Т�!�>6�u{R5G2��g�f���vz��:77"������"��񖍘��Z��)#(5A���0a�)C �O�8̬9��Y�A�\��r�l_�ڛ��\ �����/t�.���t�Yߘ[sfE������4
�l�J�4�s���SD�hh}��4�NvB��u	긭&�2�fI:����.���*XG�����;p���B;��5�����A�mm�T��i׀m9�$�b�a1�.`^���/�̠�A(T��4$��>(�����E�I%�����@,�zY�ڣ������Ǥ���\�̥d!I�#�A��v>KP���d3j�M�TBԤ���O �/G.ɔ��a�7۹���1Z#J4���`�HvH[��^�T�q#Am�l�>��F,Tw�{�ָ�|�|"��
�*� ژ�I�QL�m�F��"b��)���CId:�:8����b�ؑP:��	������5h�w��/�\�fʤ������N��N�����Eid��$I�M(��M�g)��D�>��R�CT5�˳�֒V��r���TT�O��U�D69�hW	���ǵ
?��������H�R�Or�%y�xN@NG�|I�1�=�{�� ��W�;�]�(}��@�r�k-��1\�zxŎíwh!�,�F�;�.Ԉ�ϵ��Slm���.�ħ��`F����M�m~QX��8�X4oD�����/\dd�؃����	w(�?8�7��� �x�%=�*2X������$A/4���ykm�v�mJ�g��zk��Ni����T�h����;�ۿ��]��a�QLĲƠ��ϼ`,Fk��~P&XW��ܒ;����G�U��J=L��<�ڛ�dS�=L���S�C��+ϩ饜XN~�a.���dqKW/��uBA�ۏ��
�u���J-DbJi'H&X�T��;�˟TF��A�
����ϗ?o��Z��`W1�ê�~��EW��V�x�(�߯����^5��moYj��3˵*��Uy������m�V������	��r�%� L�0�4��͂N�M�����H�r�8J[;_ 忄�kT�Z��)� q봐yϊ&��tA�M7�"/m�|J�f�R�����o�Y_Βc����rXW��	��ۢ���\��Q=ȹ��������`f(����>�Zʞ�>�Y(l��W�_���v�g�駚wH 0��w}:s'!4��<�Q~�m~�����S�~�Wjp����h`��e�y�&���D�����ړ��G��N,Խ�%i�J�AL�=���U$p@��&�lm�t��[�{�l�b�ڪY��-/> ;K�l��,�zD �0��z��DQ���I�u�^/k��z2��5E���oPJ�PO��Y�F�i�R1D���Ե��}��1*F���Ę�����0k��Tۇ��i~F��~0��к�w�I]����,L����(���N�(
i�$�������g��?��厣�n�a�:v;��;��& �˃n�13.���ܫ�N�|�e�wRd�a��#��S�f�1y��[��&�
xF	:h\N�p��8:�����`+>j%)j�]/�H��6��	~ɐS�C��22܅1epTۀ�]*=Er�<��O���&������.P��4"2�*W���E��]z	�����.I��k�dN����5]k+�h�807�!��˙�ג����;�C�~���2+���×!�-@�Ϛⲣ�)�r��3h��G�xدҴ�#V�h��`�̳%>�Pȳ���.�m��V��>���r�O��D�d�l �n�A��7��w-l���!#U.�פ#��~b��j��.@�(��]�E�'��Q�zmO����R����"#Ź�2����C?�T|<�b�s[g���e�;7�4���3n+�[�B·]?����	�����hԬ��`�7�V>��x�]����\�����D�N�a��կ�P��J��3Od"�Z�M)ԯ��ɣ�F0���˟ӟ7H���Mu��*��F�� ����*a'��q�@�ݑ�'�ApG{� !r�S}��h�e�w�c;�
��Ќ �T�K�Z�&Mg�0K�5��WPrn�B{��`v��<?~8gT��-��;#?;u�^���
�$�a6�x��\�ā�{��ο����{�[>}
���3%)�yY��U��~!��(���|֘Ԓ�����:K~�;Ѽ�������d�kc�ۃ���׸�N;A� H/�$�3!�����aI�IjD��2|���~�{��� X�.�ôV:�$���|�a�B�0,���n�:K,�͟��"���:m�c���L����j4�	���>k�2ץd�)f:�4U� �� ����S�䋄>�Y5�G���x%�s������A�tP�m��U��΍�k\�C�֛R�(m7M�k���ʎ�Z�ЭcF�}���-�kf�t�|��/�J�+�����G��������w�P=�����O��z���'T�!o�v�6�Ie#k�wf�ܢt�N#�$�A	y���ɤ&�� `WM�����o4���B��X|Mlp8�%��P3��d6(��zb��5�gRːHѵ��L��g+bq�TO�ܛȦ>)��T۴'���Gyo*����h��TM�Y�]�l��p�d��>�KQ�8�;�������i�6-ڶ�`���!�vR��"���*������J���o�%���ؾ�\WvwR��$�������c�aj,�����H-$��y�����Į;��MR��[$"0���w(
�H��nQ�,����~��OZ��X�p��  )�<?Mf������%�g���l74&H1�%�R�Ҋ���7��.��
�D5�m�$$#���!�}�'�¡�,�3�E ^P� ���LJ��?P�i���p� C\�s�9 ٟE"��T�@D�oS3
4�h��C�2~7Ť!��L�!8h�� �Mܱ�wl��[%�CGi��7g�5�Zw��S��ݚ� ��%^�%�U�h+��.�U>dl�3v��ӖڳA����b?���R�!�l4I#�=�$�?Όs�[���E?�uy���Z����ˋHKޫ�ľs����m{�M=�J���z��\��Q����.:��n��,{��0��o���`N��6]��q>�Q�A��G"j�s����5��|�9��]%B�L��u���D���7��DM*��>yEt����k��ˣxh�����Ok���e9y�Ѡ�/~�7Un������j)�9ݡW�*'�j�������:z<���r	�Ilߎ?�*��_��u���W��"�<UC˙�c�?ؿ�M�)T�-�٩L$�d�N	pv�H56���)G���v?��L�'͐�_3�f��8Y6i1���Zs�9d��}'k%5�mB�Ę$Ǿ�F`���-7�R�S*�������\��1Қ+5����Qz||�kX_����Q?(��U>��Z�r˾�:���I,����T|^��7��H&j�R{������w�.�'~��)?��$:�V��QR�ْ4�:��/����6��@��l��*U�k�&��vB��r��֚zi1hԒHO�m��\���V���;���� p��}N��??�(T�cG���H&����}�Ҙ�.���ԑ������En��)�E���ӗL1�"tf�\c�;��wBPm�#�7�{vlKb�{�G�f�==�g�x����H��o�$(0E�ajQ��'�5�'��	֨�ڧu�KpMG7��v��$
1:���p�S��+,��Xb�{G�xQ��ˎu�HΚ������;��u���7:#Q��dݚ˧͞^�����R\��'��K;c�E�js=ԝA�q4���euVJU�V$}i!~�C  y����{�a��3k%A�����,!�t��%�`�x'n���T���q���ͤ�ͪC7��.(�u	�rq�KO@t����h4�wr�a|�;��-@u��f�ދ����}W܇�T�)�i\m��f\%�+@���m�����7��{���Clu$��]Bvv��IW��j0]~���.��G,0�xҳ�A-�Lk��z,fqDJ0i�ó���rz�!Ez�:�ӝ-5��f Z9��D2�z�0EJt�ořjI�/�<��C�s�c�ن.%����s��h���0��}4�P��l]��8�#T ^�ĥӗ6��7fȟXW�cR7SgO���˧ ��?#�ϖ�VD�ܸbL�%��,ObkS\,�9W�5���"�u�V�\��>��i1�5օd�h̀1(R���lk*l�/�S�O�"�f����B�)��@�p�i: ��w��h^'�,1�m���"��اO Bd�9�ms����	�Α����I�oL
���]�w�C�x������X!-m*�n ��ջ�H!����� m#s��J�Df�W�2�q���S�N�cmUكQ�q;�lE�I�+6�E���x�ͤ�*Z���
HW����ζ��֮iT��;��H�Ǜ�.��ܗf��mj��U��s-��E��a�0>���C���kYڏ�I��W�:>C.�lwN��B��#�j����q��r湅�6�"�e�j�a��K��^��� ���İ����<��Y�A������,��Kh�Ƶ��Е��Z��GU�E�<p\3#t78��5�l#���θ$�+<�ݾ�˻ǟ6Jȋ�WbËSG�FL0�!���'����dׂ)KU��մ̯��1�c8���PF.P�d*x���K9 \��Q��[
L�Yysw�6˃1�������߲��d�꽾�5�D�"�->�`k�oD�S�b�2Vv[/�.VW���L�_��M�9�=lْ����I&}^�>o��L�H��62��a�O2g*�j���&f�1�p*�6��J�0"uܛ�]�͓�����/�$�d���+QU�3C��G ���V-���9�.�W�ڃ����<���;�ϙ���5��|c�o������ze�m$�5�45�r�c�ȓ�&��\Mw���E0+):�5@�� �|�{C�Ȉ �)��E����d�f�!��=_�J!�G�6�{�͟{��=��w�:	�wa��O�:;��h�l���K�����X�8�B� _~�\[�#�V��)��z%%l*H.{|:�[����ݝb��Ц��-�u�R��b��If���7��l%�ȧ�|5݅C�]vk��h����>W��Ϩ�<��G��H���ݛ�U�܏���`�:�����Hp�(�!X����d���;���P+ �ω@��;n�bֽ����N��rS���&��V�lc��G8ߚzQHk����X)S�gQ�.�h;d����'�t���߈3}���� �g�P�����S�\�@|��V�2sT�!��]3���>d/��F�k�����
�뻮���E���ѯQ��b{�o��"N��L��@d(k�Y�R��>C�4(ʹI|�cC���k�PR��j��4C��'���Dw�G�%�b>�܋�1��Q1Cp� �%E4L=YK+LQ�\�ޭ#REl�T�h�->�mx{^�0ݤ�y`��0�o�3������/�X���	�ƌ�}B�Z2Ƕ��*�p� cޝ��ܓ�E\�	�F��E���y�?v��X�����z�����$T�o0P� ��_.*Q��۸&hR��+&��ۼ������ ގ{�3����C9� �VU	lh�^�͂h��[7[��lb��!�����(�N����Q�]l�
�}�I_�ۤ����@��(���;�r�'Q(����Q�.gD�r\%�ŷ^�[�)����m���{{��oeO,�D�{�ტ�M��
�\)������.��#bԛ������"t��y�c�����Rt�"�Y���<Y�ح�.5Fv_�3�y&#X��Z@5�I�K�z+�����b��% ��;G��L��9��ؘd+����������*��ts.��B���|�Ռ�(P��犫���m�p��] Y@��H��8�"�I�B�":�_���[o	�h��b��{d�ܦ7��p�	C���g��U�����d���(�r._#�~W<�wq�ľ���C����.I���%�7�1�����m]������#s� �dE�� ֕�"��Vf��%͜��Y�Z ��SP�w�z��C4!����%��K-P�1$��l�.����e�w��^֋������oԔ�=�}@0/7�O�l��E]�P�F,���c��Sˆ��B@tg-?���J �yѫc�{��W�C ��'���v�tO^Zg�y���5�XQ�^�"K����[�Y`���h��/�����մ�w�(��a�fZ�B�����0���~X&�쥧.=O�io|D	d�I>��~�C	��z@�D/���&(��[_��ro�!z���sl�(�������+�>�<a��jW	�1�7*v I2�^	���J?yr3o����]�^���`���-m�$0��w<�yˠFw����&w�j=�5E�-��ܾ��z��m�v�M
=��k�Y#,lg���kEZ1-���W  j��a]"Pp0�(%4�D��(��7{DN��k:W��5�����ھQέ������@��s���C�^E��ݑѐ�K0߱�ͦtbP�sJ�9�§���p� �P��2v9�^��2�VFd��>[?���+��n"+B��/��'�,E?��`����s��9Ư�U>�FE6�O-���>��d��s?���v�~��E�U�Hr!�G��2�߇�
�����Aɠy�K-�,��E�%g7œ���UE7�>�򳼷�T/yU��b�t{Bdq�%�ogC�8u���8�ݱ�R�����LH�c�o���xX��F�_���H��l�L^���-�%k��|xxY$���MJj�Ey��@(&��m}�R ��a��ӫ압B��u��
��s5��
�P��K�E Ez@
��{EV<���^^H�#�4YVq/z8��M�RwM�_�Y��X��HhPJJ#e�ٚ�QnH�%���3��}N�慐���z@��{������F�2�.^�Z�I�E�����}�q`x�S��p��|�:�
�����E��&��Q�;(�<-�(����R��$�(�*��s�6"Sm��K�b�|����G�g�uE.�5�VO������u�Ǩl9$֢f��#����/�-�3����Ofl䉀D)c����u��2*�U��ʢ��Vrqo����(�D  Y��zO� �����S��g�    YZ