#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2844880163"
MD5="4fd3abc6679805aef477dc12bbcd02c0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21509"
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
	echo Compression: gzip
	echo Date of packaging: Fri Nov 29 21:40:25 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
� y��]�<�v�8�y�M�O�tS�|K�=�YE�ulK+�Iz�J�d��!H�n��_���|�|B~l� ^@���twfv6z�D�P(��u���i����~7��4���󨹵󬱵��|�|�h667���G_���yd��{}�}��G?u�1���s�S�{k{�������G��u���O�}b���d�JU��?U�z��K0�2-JfԢ���yb�9
<�<��,Ll���Rm{Q��Nm�N)i{?�.��
y�iԷ�[J� F�fCo�蛍��B�4���F用����f�7��x3B��(�>n����9P���L��&�Lߧ�yQq�!�vA��:;W�'z�{@�A��ّ�H[����֞�I.f|r4wO����B�����:����;���ΛN;��s:�ƣ޸�;ʚ�0��yk��PQ�R5FgC V�G��:���w��*���%�[���@�ע����s�R)'����k j�u7��osv��-Qf���ŵ���R�\ �[3����9�[��;�o���e
4���?�ʞl����J����O=w�BV�`�dVu���� ���@�=�,�,�b��p�3F�.B;P�T�fHtN�y�E>�������OD��Rw#ǉ����|c�F����ʪ�5�����}�sƧu�e?H@g�4�*���C۵��&����B�PZ�Z��STNP:M3k�:W��/]O�귤
�`1	=�2��`�l�VO(o���＃ *d>MQ�4|��>9��d
8�43M���a-�M�+5�m�y���v=��̌�pC�V�üS���O-Q���T�d���y�}ϱA^ڡ��/���_�+:%�]�����Ũ�?ț���Eo�A[��|>}�����lE�ra��P�v��+;$�z]��i�~���ȝ�B���q�|�����p�\��J%��D25)+qS,���J���1&va�nJ��O��.C=x^Xp�J%��X`�X��}uj��y�<�U���dvFA�	Wd�"�@X '�÷�&m,y���>�/��!�U��? ����^��mn>+��[�vv���_��»D�1��I{J�Iz>x>��y�&+��TF��G>�{n�0v1]�W���� ��$/����_L�� ����=��=y��n<�������JF/�Cr�=�����w�u1b���{��ݣ�A�L��Q��"�0������xQa�ͣ���{2�gӅLb��,<˞ِ�@0���	%���z�,����f�DT'+���ȯ��T�!q�O4M���c/lL&w��2�̈�#$��Y�-���k:12�1���0�ٞ�'�궧��������N�|���#˯|�e<�=7&0^E���͙N#��P�L����~���:���~�}��_���ÿX�����Z����?�«6�lǢA����6{{��o�~��_���Y�o�[���EA�@.H�znhB�C82�F|����; s�Ҁ�$��v�/�QAkp�|Ft�j�/v�5�r����/�ؕ�EC:M�Qp>��G,���i�ƙ�I\����&���;�ͥMy��\Ll,x)<@:췱�\Q*�7�=�Y8��ړ�l3ѺK�,3,�p�z^X}��M"7�H�� �
&�?�.�G`섌�]����cۍ��	�P����GRfN���fF�V�Qo���ǰPCM"2�t변BdQ�S��96��E=4�L�C�xk�7T	`w�����C�#�=���*���0�!�h���t6/�t�;�a�P��Ug0��N�x�"K�I#Ռ�b�w������}璠���dW?�A�m�F+�J�U. 1��+/j��O!��:���2,�C��.%�c�o�s3���(� 
8,��)C@��/����p���<�т�0�3��q\����:��� �!��{{�>c�xm��������.�70;������� U�dlq�\���� ��zvR���Qm�T��a�@t�~Q�W�<�M��'�
�.����eO���,N7���$�!�(,��XˁdE۬7�	�5���nVھ}�=�͡��bb��t����q�����E��������X �!a�:��n�q,��.�U��>�U-Y]*��ӧry����lx��u)>����8�)a�JS���1�VW���"��!���~@s�y�ba �(ϱ��qN+X�S�sӝ���~e�b�H	�dݕ
�6�,<z_��`9��Hjˤ�?�Z����0���#C�,�$v�U���"�"�Ao8�m�^=k�={u����D����a���;S\�����J�L�TE*ٝI{g�vGpT��"��kE�F�'1���',Q�}!+�����j��Ȳ�tnk���0�E���\�^�G-��_�էvs����oU"��Wl�J�X"�jzlZ+�~Ct�گW��Z�J�����@�}�e\άV�Z���D%���`z��]�1d%�-������H~^;^�H{uw	������II2=�h&XJ&V�)�2㏶	�ʥ�m�|���"r$'{.h^n?���6�ﶉ�1$��
�v�0s���=/���seK.�2��`ϣ !���-�IW]�[G��������=�rT�� �F<	Ys�%�/Q��8����%���!'�A�yŌ�����%1�U��HB�Į~��+�!E1��sN��=��ΎG��R�~�$�k�+~�%	I��ok����'�5P&�Ze�����kFL�a�lpe�[������j�g��������,�j��0��/I/�k�yc��?�<���\fO�k�!��.6��1�:qY	����_��%���m<s�hJ5�d���%]R���A�7
�z�1�gN��k�K�����`&���>��N����x�QD-�$ʼ���0d���:(=���p�m�G9�g� !����Ǖ�!*���;��	b�:xzg]rn���������/�Q��0ԈM��Ik4���+�Z^p�z�9=�~����A�P����p4���w�9�U߹�	��l��b|�w�����w�ZLi�7!�K����$�e�(��*���M3�kd/=��T�?�]�{>0&Y	J�J���ɕ9��W߈f�r�7�sc}�R��Q��IE�X${�X��U�t5�0����O�&��=���X#T��ES��$�q�"��X���q=2�MjNl-�>tj���u�����Z0=��j����u�&0&�I��o˩3�7čܡ�9�C����]�Q��F(�E��2�e�J�v��,���#0A���X�i���G�O?cL:��.��u���E���Q$�-$U�,�!F$9��Ra\7�m��.^d.���L����<�J�O��nԙ��&�`��̎(��+46��PcA��3�cK<� �p-$�q�jJB�JT�:���XW�[���c��<t~܄���%>6,ZnJ��"/6�ŽFH��3'5P^�ſ{��A��#���=~u]�y!�$��s�t/p'�w$R�	ԇ��� ^@���n�5����.%~���t���^�zū+���'o����4j�x��Y�y47���=8�vG&���ǟ����w��F�I��e4��&�ՅxQ���k��&��1���S<Ǟ�
��	����� 8��0�1�W\�R�E`i>�I�"3�=�
�i�M���/5�'�ǰ2���Jf�ҥA�q�HO�z�s_��C"}�B VVrǰ1�n��Duj,�S�.4"J<v�_c���,K.�_� �vb�݃�������l�/y<?�c�R�R�N��Y3i�R�/�M���3^˚^N�����0�s^�@�W�&�%qB"�D�xw�K(�S�<��ƾ���MUb�ۧ�o���� r��84�d0���`�FI���D���+� ��Z����9���]��#�co����@;kC��>�T��(w��AL�U(M9�H\�z��.�ye���D�3o�T�Z�����۴�\z���)����7x9�p�����X�V6W̺3&���~0g��#���Y.��w|0��6�Vh���K�3Ƙ��9���^�x�A�4q���Tz���e����1���6F69D����g�~o02�%U�$�MM�^�	~m@F��Q��4d*�s�^�X��u����]��ި{��xᦸA�M�
A��G��;����p�=R&^������=P�`������Hmx�����쥸j��3���/߂��D�$[f��F�fl=�N�	�K.w���}'}�!��S~ �/(��a�`#Q�9����]�2 ca!˗r:�pJ�xa/��� +��<x��7g�-�.B��vf���f���Gދ�E=5�ȶDMM�=-v>�ڹ����h���4$xaךȨ4����x>y�*�rx���u���p0�^����(*���0��C#7���vMǘ��a��ڧF+۷�m��9�����BH�9�<�h�r�������}a�qM����혌�}���
�U�_i��>���>�k�(���.V:Y9 lη����F,o\�{��EaRǼ�|I���X�����Xr�0�4~��/���g�[Ȗ}�4����h/:�),eI;W!��ݼ���?�!�|���DԨ���Mܭ��-_�V;��5i#щ|[i�ֻ��I��l�uN���T�0�=���|wE��A�_�Ӡ��B<>�_�z}~�R@@:��m��}@g�{Q����s�[P~�Դ@�uv�B����6�l���La!�X�A���"H����©��Ii��I��tsC�j�|�%��%>;�2��H�P�Cc6g�?��&���`����%���, u��.O���x���J0�²&�g�@t�Dɔ��P��KQ��X㼻5��]���1��2�g�S�"�\�GT���^fY
P�{�<�*��+A�0샹4�ȕO�k��;��M��9��߸x~���p?X��� &%�6���aW������&m��0 Q̑��? �B��N(��t�y�I�ґd��%OҪH%k�I~~�ï��9IS��E�}��N ,���ll�*96?��%0����$�;���n��2�l�%�0-�ؗW�%�� �r��(�^���S4)9��}ᬄ1�2��{�j�ڌO ����p@��qo%)���G�Ih�>�KK�Ϙ���:����s��*�0�
0�s�E�D�.b+yi_�X��/CC>C������^cX"���qb6�.��a	�446�D:��8 x�:n��d������WvN���O�D�$_5v���Չ{��;�]u�`��Ǐ?���UWʘ���3��TxK��xD]s�Vh�L�œ���:�w���ڬ� �cc��eN%���gmN�֨��!w#�]�N�F$V�;5�N�J�d��!�/e-�쎬RYMJ1���FA�����Z�g+�T�YÄ[���Y���}[wG�漢~E��1I�  uiQP%R2��C�vw�>8E�H��0UR���/�4g�e������6"�R�YY HӲg8G"P���������\^��=4|�wR$�Nm5�!������Te�Q��m�q~���	�j�����1#�T�us��L8x�g����fW�Q@�d()!8�J-8[)�Q5D}x��*$�A�i�R�h�S�kJ'8��:��3e?7�F��No��ǰ���:��oIꅻ1�pC��'忌2)4����xZ�4�o�h���>�RE �׾:�<�Z���L{�b�W�d�\����`���/�+g>*۳���Q�O��|c�ʜ�F��UOE. R�6��n���*�+ͳwX��w��J!Ѽ��gNe9�
o7���+n�:7��T�B7�ttL�$T0�&�dDD��<}���hW-"��dƍ�F�%�	���{�5�=���H.G��4)Rzԓ�b"Cn�Ӛ�L-F
�g�~/M� �����v��h��S�;$���$����~���� ���M'�;/�Ѹ�_�s�����.t�O�5�q������'���Z�>�@3�g#I���:^|C�6�k�FK+ʹ�*� �UO>���hOp9�lL2�M9ď$8�]�Ӏ����ﱏ��ˢc�8�}�>��"�|��WQ��C�x3�����_�_�o0�WP�S(�4+�}OB}�/���"��Cܠ'���7��m2'�w:���7��aX��y�'Y<d�7A����(�R�W�U�M$�&ڈ����N��Ë��}Y�ϣ������g�xa��"nǷ7�ɳF�(F��\�"�Yz��hO��ȕ� �T</����d�.k����m켺�e��s�9�0�L��Lsd�e���Y�@D%�N�N�]ґ���h��,@���;�"�7k�(�r�
��م�#�
�d��
��x8��^�����й��d_"2l a��Y��öO��H9�)a���]F��!�i��nD�v-U�����*C�Rٍq��TʍD,����^j�b�f���o�MiE�V�"*���ܝ�L�o2���U�������5bE��H�0~�GGj�p�'�EӋ��z�$K;>H�~~�kVA5�M�.�A�t�#r�ke8��2a�����L$	�_M�;b` 44!b�/���>>�������DgֱB�</�.���[>�Z%C��{�B�}t/N�Kq�1t����O�nm���oU��,���lֳpz���p��B6��V�6���g�����v�-��e�3_7�R�~��Fz�	E���f84���b�%�̩��%ؽg�M�E�6���'&O�ɽ($�vP�����M�����3����''{o��)=��b}���x,�.=n\t��t+R���A�8se�*�T������'�ҽ�6Ϛ�"TL�y����0-f�r�H��[��[����NGE�#����8�G��������6��Sq��F�S�_��t���G�y�����G)�#k5�T}�\G�_9SЖ�s5�������>����n�rkW��y�9\���Clq1Z���ui^ܴ�沽�����%<:)����@)�Nu��A����1[��k{0�t��?w�O�Ɔ9�8w͎Y�N$.L������Vs�Q����v4BM^���+��{�Drӵ�D�c��r64ϩ���-4�Xm��r@�o�&�jCp����1y����|ә��W��>{2�3R��F%.�>�NH���Ϗ����,��g��-VS��VÁ��\��%��ڃ��E1� �b��� �� 7*p�,pHг����|���\D��ZY�?��[~��D���Hx�UB:fD��C�,�����`
��l�䯭-Y���μ��H�K�o�*:2�KM�����w�V�6C%�Plc�*�M��3"�@# �k��+��Jk�p|e��+�����G�o5�}8��0��z�������s�������U��c4�?$�����|�ז��q��3��>�M��i
�4��տB��(K�i���(Te��<�󦣍��yS�E�t��H�F��W���y���l�M���w��,����@6�d���jmUzv�.�}B۟������Y��ɀ<��¼|&k~e�Q9�jkv���/k�|��|%��:|�
�(/�dӠ&�l޶�X�>��(��A�s>e�ȕR�?�v�������B�7�i�|����xL�I��H�M�f`P���R�	f�-*v��淂#���!'"��F�����d�Q�m8C�~�����fˎ��Z_��X��������-�́�f��s���v����0`c~���А��(����!��{��zYZA��σ��U�����g�l�S{�W�*�	�|�(�����vj+g���F{��B���>��?����F��{�6⯶w���z|���x�Ddi��%�����g�I�6���?�Wl��9Ҭh&<�>:��������߼
���`����^˟�/�Yj����!��#�fZ̪
�_$��3�ޚ��钡�=�B�ag�ԣ��G����d0V��S�? �ؘ�9e�̇"�690������(�p����6B �hL�o�y�t�#NQMLSvæ�8�cf��\��J��g�8L5�/|���v\�ۡ���S�������!C�P� q��Z�M�Lt��m>ܝ�V�ŊFO�4þ.�/��x�ℵ>��^�8<�a��qg���`w�1f���v�]F8<�f��(4+�	k�oF�P��AV�u��9�]}%}-���W���W��2e|(a\�oI�D� �Ќ�J�e�%�0ঝ��j���k8A5�ph]����6�B��7x��Ggu�E�_~i�LEeq�S����*Z�|*������*��_�ͳf�}Zӡ�E
<��El*<rM���Cq��=�滠��v����?m}�f"i��C.L�p~d�pkp:B| >�v���֕���e;)�	�6N84�;�,��ʦ{��wr����>>���*f���D�c3��J�ۂ����I^G�Vx�8���9���M�&6M�$Ip�D*)��ia�B�X����s:��M-�λ���7HΜ�:�ʨZ�Z�Ă���ǨT��I�+���I'A�L��=�C��	�Ңdh�Cצsk#�=���uuj�-�[�`XQ�S�1���6�S�3S�h�>\2��`��KQ)��%�%�e��9��D!���I$�Wa�a�>�+]��i�;�M� &&����,�q�'9�w��0���ݼ�o���gN�WbR�\����ܴu�)Q�dsb�y�ՙ�Y�F�.��ˏ������/�
@����-0c7��T�eZ�����?J���w�+����KO$����Q)i勺�B�����IF2�.(aֵۑe~��fF�315��ϝ9)ݎ�$��EQ��%����u�}���ƻ��-��W���V']L��o���ۖZt;�Zm��S��8�� ���-F�IKhl�s�M$��$��5c�T �M<�M� ꛄØ�ujXf"��8Y]#�'��Ph�d:&_�l΁>��
��2L�ƻp܂��h4��^|ن�����D\h �13��;�!�iFgA~f��h��a*���AJ��]n�z�WאT���Y������X	���T��+U�JZ�F�s��v�4nfPCv��O7_���!JF��8�;�F���Q��HeM34�I�N�"�N`�'I��4N2b�@�����(���k�<B+�9AX�F <�R/��ŧ��'�1[��9���ګp�b|�n�;�~��Q��=��""�`Ni���k?��Ū��_�����aAub�����LY�b��"架o�(��	��P�T�U�-*Qt�@����g�ag�;�G,�E�?�AC�`Lq��o�8�u|]���)�(CW�p�f'��ҁ���c}a,�Ke�U2Oy���� %a�&*��6���ڏJ��S�U�aw��K'���1�X�E��?s溮�蹹���s^`�)����SM"��'�J�}Z�,�M�����<zҶ����G���e��;�����T�`��W2ֻ�]���`9���g��^�$!(�>�n�!��	$+ё[ǭc��B�a̈́:nL��o5�G��Iߑ�[���g�<
u�w��#� ;�0kbR� �WY��BB�X�7	�>�ڡ���߬�x:W��Q� ��;��c^h}Г��*�JqŰ�s��P�u�v��!��Y�������^���[(�	+�@Ay@4Ki���ȃ_�:��<@f�,��9�Q
U��릊��CWL\�JH�xI�\#�"_�CG�{v����FKf���@6V"���Uo�̭�̮T�(��@Ѱ��4�6y���*K�~���K7sJ�LJ�g���[����ޛ�=�����ޒ'M#�f�_�!O�#Y��1HF���>�����~���J��<A����[?�4<���"iuVYmo�Y��5��s{q��cn��< �#�~!F�!�T��hu��Q�N��q�OUm	!�2��:����	��2��7�[j�*F� Y�+�#�Y��T7�������8ǯއ������`k�y����~���2n����{|�}��ͮ����'�gr�WX^�a�Q��:�U��uoѾ�ch�6�`ɺT�ZSޱ���|Ť0Fx0N���DXr4���Xo���������N����.�L�V<��v��(���7'��/;_3�Y�{/�>Շ`F����}Z������Y�v�=���K����/�i��es�J릔�0<dӔ6{����BEm�����P���|�ҕc�=PO��)���I�jhHñ��Z�䷉?r
y��}�{	�`z]4)�K������� ���9�S��3�U���D��r�Z���G����3�i� <o� ׼ǿ���F���yY�2@�tq�h���{�"����sq��� �q0K��(b�/��rn,�����N��[�����w�F�f�G+vgT�O��e��ǟ�`Sa��Zh�:���>e�g�����G0O�t�?�L#!����^{s�����$\SZH2c�1��a%Gņ�R�F��"[ �]G���)j\�f5��Ӑ9����(FIk����1�*9���N-��g�nO&�f�����NyW ����L�/��ls�.��'S���P�s)�=*���5U�fS��I͚I��)K�eNRO��	����s�ǲ�F��J��e��2�̺9�2�����}�)dJ�P]�f�X-b�*0E�\��U�֚�	Ԕ��ϙ$�)r8"�c����CW�@�<�G�]����t��w�<�<����4��,���0ϓ��ek�?|��_����Y�����=V���2���Z��⤶�b�Q{w��9[]H �YaAI���r�;����:j�{/��|D��o��q.	9b �-�,�jԇ�p#��(̒8%��#��A�mø�6�����Gк�]�`H����sM�m�A*s� �&�JF�*;���~G���x_�E�b��fi�����A�Bk��a���Aw��w��vo<���è�S��GqTeF����^AZ�*`C�ak}�}��f�����V�;X�%m�e�]�/i����-��}����f�4��#�~�p����n#����>v+�/��C|�齓�h��S�{.Z�	3]A�:��]�'ZAI� (EpI���.�G��5hf��U���Jد�V�w�w�����ӣ1��X{����
��Jʹ'�c�s��|D����-Igv7ODP2�JQi;S����f���q�Y��5�PR�P%Po|iR9Á���������́��G� �]����@��a��<5�8���x%�(6^^h�T<��T�u&�a2�� �|]��`<B�E1�`�I���eP� 
�����:$�̨|.���/�7�'���5
������1����e�m�Eg��Az�e��`�%KV��(OU��z=� ��u8,O�Y�La�9g�~a�/�`��SS��8#�}%�q0��Ѷ�q��S4��8#\���k?���Y�My��=ߏ"��g�*��x��	�_���~6o,��h^&����Uz�FݦU��z�,��qv�D����u�c�o�$Җ�V*�![f�����^4n�F�dͬ��p���j�Z���Hm1�h����9��f��#&.��HJ1^�Sh9(�~�0�C�LG�U�:�r����=�I��z{;��*C��0�#)����W��qc�f��#�b��!�t35�a���	ږ$��cx���l�����U���	d��W���],}�2�)��4a��]s�
�GL��6k�ڬ�%Tn
�Ш^F���h�>�A�`ڣ�q0l�U���0I��lM��h������Phӧ����X�>��{k]��P�|�E[�b��q�� c�\v3	���m5W��n�M��+%���A��[�㉀���=na�;)��Ԝcka�T\��䳍�`�\���b�b��=X���P;�(��V��G��u��{�wp܋+i�o߁�j�8z�I�H6'�]Ô��'�q�i�t�
^d3��iRPͫ��&�=�W\#��G@�Iѧ�������n<�]��Z�����8����$i(1NH��*=QG'l�|:K�������
C��N�T�p�(�܅��Tditؕ�QN�F���"��j � 7�.���J��.�Un���k �����x7C!V~O}�����"̙�~3�6�7��h��D�Cuë�3_t����x�M]�c�P��I����1��h����S,���iq�.5緄����\i����1���v���?b_-WXχ�A��5���'����[��׸�Y{�rߛ��4�H��)�.�T/^�����҂Ï�8�&g��Oj��a�:��S����n0j����*��l^� �f=~A�z���C��_�i�h	1��ށ>`6$���Ճ�$7��+fc�#2'c=/b2�v��2�-<)R�~�\�Ŷ�-o8�.�G�8�b��V�R�X���2L�i�G�!B�Ϋ��8��Ȑ���7�������ɇ���э[}1�#C�6�s�S�$y�=�E�a�8��wc�+��T���*�����pD	0XKf*2XR�q������ؤ��}�[����J{Re����	<�=�.��V� h�#t��[� ;��:o�cE�4a��g�I(�\(�e�Q�aA�!Z�	�+��@�U��ZV�(�D�3�ˬ�Ίv#����q�s=֮>��_Y����s�J�1e9���`0�Ŝ�L�|��
��xt�eVOG�.ʞ��kL7���᠗�+R��� �u$h���W��+}���_�!��Y��¨gHE<;#Oe)7k�A�~.di�Y}A��������� ���勊�¡TQAb� �&���tx�)�*�P��#�W4V�Ax�lV �K�����Zv��mS��b�F�F�7X$�պ�0�t��)��74�8����s�0�!$&�i�sc X9h?�R��^!�f�?7l0)& < ����BBG	r�DB�
�"a�)��J���>�v���T��Q����|��ʅ*�7�a5���B&`v���/�(��h���GAk
G@��Cc�!�4D�(.��	����H@zM����IH���Fo��n�p�]]07�Bs��pIX"ݮ-�V[n٘My>U�k����9��Y���6�#�}��ʌ�l���p�S�s��"G���`���Sl7����C*I��Or���Y�/>qX�"I�nI��j�i��΄�m�&��tl�,���\ӖJ���4Cii����&�T^�xM/��A�)�nU%�.{;d�QF��n����Ax��EY���_
C�����z& �K+��"2�aT��C�ѕE�c�I3�]��ĥ�֭�.-�`��ݘpR-^��=������K�(}���͵�A��2lgފ���?�(i[%�oPQ�_��0����w^�ꛒ�g%�J�o/���Y�lγ�wu.�R:xKI��"�_a]���t�/��	�����M�[���d�������O�@;���̵*v��I/��u�U�я���8�|�ѳ�@�s����;���_��<h���b|l@�d�J0h�@�L]O�ӛ��x{���j路����=�م#x5 ��g~�[j��op�B6"�W���vx�7�sj\�5������9_0H�?ǈ�B�0-���RD�S":r�ZK+��mDc��M��nH6�G��%#��;7���܈D<2�F����%~KX�ZA�v�Ua��� �4v�`h��/Bߜ�[���f�PT�Ø��N=�f�P���Ȭm�+ٵ�daۘe^�/��8�^����]ĵ�|�#�[�`�P�6��?O=*���v���'O��oK���⿕���;Q�8�g
�M�9^g����4S���n\EWA��� {�<i�,��b؟:��N��x\���u5(H>*G>�WZy{VטR���`^1���w���x�h�o�^��
��=<�龣���;Iʘ�4E�C{@�:��}�5��:JѼW���$B?Pa�@b��K���e��UFtY�Gh�'�����fG�u��\��S�/d�ep\��EvM��nd\1p!��feC�����*G�y�ZxY��O�aM&�g��l��l>.�B�%�_����n��?Oއ�5��1@�;��c\���Y�yB�� �"�5.���<�T�4�Y����T@���sb��|�]DI�}�L�(au����d�5z��`�_���YtqSG��5O�:<LVY{��t �����,�?s5���)IY��5���S=���;�9d�o_��������)�W�����<ݏ���~�������󦷳}���ݎ�����?(��h/}ϩ�i�X/����c���`�yL�O&e;5
&MT���,;��Ä<Tw�q��Vz���C@)�5����:�GGT�Y�@������S��b�Ǎ�M��-�xj��w�o����)�M�C. �^��t��1"�����o4$=5��SqY�=u�^u��,*��"��Uw����\���IEO�BߣT a���Ƣ�\�A�k"1����������%
eI1��5��xxt��΀6��<}f��4hL/F��yR�d��~�9�S�� ^�E�.����x 7���$�͍��'z��J��'��B���s����$���z�۵E�u�	NG+��h�ǧ�{�7m#ߘ�fV>Q�� ���	���j�|�rә9�]}0�O}E�Ec�Ќ��h���4֑	��n���J�	&[�=��敢�h�;k��"�lL�f��3�a���n�2���<~���'�Y��oY��fe��3�٦~��H�ݹ���Q�|�ԝ~*�l��O���/m������٣C�#��2��Oω1|?�`�`&�)�~������SC�o�.#:&�������+S̀�G�i��|��B�04/��.�OF�Z+w�+�ӎ�������HU��+*��I��>��)���v�ഷw���H����8!Պj�H�!����U,l��"�c>����z������$->�[g~`��ӭ*kaiO���&�n��|�s�a��###i�GѥO�p�	�&	�(��!�]ŧ:�l�������}�a�m��@�+A�0JLnBj�������}*U�~��FCU��&�J�Q��$:�r��3c�S��,/r�C͉��V�� ��7O��ۯ;�+���f�f���}bUο�Q��dc����
]����~���s�lʢ1�2�zb�� �znlmT�ƍ�$'�Ҡ£�hj3.Ӧ�\�q;ʀc�A�m�/.��ɭ¦)�jP�'��N�q[Y���V�)�Xs��fK�ɤ����j<mPΊ癶 	S+������[u\Х�
��-��"���[y���T�Oha}��)�LDR}@G��_��1f<Z	�ZOFWO�������뽿v�<���U��azg�n�Z�}%�q�[�%���|ǆ}���R�A}¯��c�HI�w�D�K����D<�OzXTc8�@ ��7u~�[�p����l��1�5���,~���;5��l/w.�"���C��?T$�}���`��X=�}��W����r���}{�3�
��0xT�c�O�!֋��q��p_ak��?�Z�Ax���e�����I��|z�=�Q��/X#�q+�1K3�=�>ho.���&�7.��l#�F�}/�����p<E�6�Nϯ����!��5�A84�t�	�G.��sv	�(Z%���]�y.�yb#U��ܙ��%�g�2��0�ߛ"}�C�I���:����ѳ�
&���w�Wj��tQ�Wp����dH���=8�{.x��X빒 v;�֢l�>h�4����z}�GB!�;Σ�f�O�I"� V�%A��D5̤�\��ɀ}��<�ދ�X�}�.����.�RӜ={�3n�R:C����?�9�F��Ԥ1���(���5M犭��}�c8� ߏ>��@��P�[��ߕ��K8ܾ*��w����YVZ� ���_l�,d���j8_�ep�����v���:�5�ݜة���dѦ�+�%v<�TSDd05acf@�\������FZ��^�����7�/pu�mٙ��p��al��z�G�����m�yk�ykV����H(d_�Q�}�5�g,�g��g�
�4{8�b�g?����-�~�{������w��z�+�3�b�f����B����U��Hd|�VC��4��������ě��̔�X��x:V�h�)��~����i�7e�����i�)�^��BZd�U�	��t�l�tR�
��h����D����!Ӡ�#��v\�P�,����rLVJ:@C�
G��P^�����8��	��������e4���
�a�x���[�����!_+Ϭ�b��V�����[j9~u�=�R�.�������c{���6��,�d�1�+��Ǎ���E��g�/q�u��y����F�n y���j�E���Ӕ�H&*:�C	��(e
��f�#FH�s��3�B������.0���捞�!�m`��r'�n�3��������-�
�������ki�5����`�����������L�ɪ����,q�
���}���c����?���g�+<��y\n���lMDA���M�q��cX�-���h0ͽ�z8�K�E�����D�^�g��9�u�y:F��/őI�&tTx��5�����E��˨�C`R�AB��:SOI?X�T[�ĺs��m�9�sf��AO��C�M��=�g��~?V���<}B�X*Hm�w�����8��4�z�m�hu����]�	���������Ȣ�h03�p�e���|�a��Ed�C1�����)���=��;}r�vVks�D����Â�$Jˁ،X�2N�|/b^]`�|����d�[���.PL�Q��޳<���9q~{����w*-�����O��r6WT�<++�YM�+h�'�`�訣cȢ>5'����Dń
��<�jM��6�M}��9�zzQ���0�V%�i$�Ia�s�_�g��
�~��kכ�[Tp�pe^B�����Z��0�#�&%+�C�Ю���@T2"{s�QE��q�ރ�|eJϺJ�X;�p�k:C�Zc�b�M�U!��4�-�O~��v��!�	{�`v�<� �Ig���'wx3��qC��� ����?Ey���'n���o������-�X�?��6�'\DX�̉�-H�.g偲��U^KB"ح�D��;d��'�֛s�k3	-PC �*(��ہ�q��"�{�/�
����c~�;?(�S%.$z�\�����`dl���x�*�MUu���>\ͧ˛���o�8���0�6$���ͷI9t�"�.E{<���	U�M,A����4`�*j#��)�/������H
P!o�a��j�T�P���s=l�~�v��汩�aI���]4z��~�N�|ϖh��-տSl�t���8���ٍ�,��-JZ>�#�V*�q�\c� p��9��D>?./܇�ߠZo���9�$ťv�d��?K��@�Z7���aMC�E����<N�E>��B^�m?��᧟�'y���vie[V$���+��O�x$R S%p9#n,��Ym����xw����I�n?��i7K�$���I0�6�2@�b�����[< �/��B�-DP*�tQ���4}mD��-|�m����D�%&s�7��׵5�KL��qhܱ�=�2M�z�"I�PG���F�F��S%¹zj�Ř�t5@�Q�y����rS';<���2b�I��˂�E'��6��+�v��r�X	֮�7"�x�Ū�oQ�E���h;"���i/T'�����֔g�v9p�5J3�"g��#!ǿǶW+t���\~Q�e���6k�$a�.�D�_�����爡7/B�*��)��|�	���CI�;�Jm��=�$�J�b�+�X��&>�>0������h�(,�MV,���m�X�i�����Fs���oZ���X�?�֣�b���?�k� 	�W�Ic4�<��0���?���X��}��?Ƞ�S�y�'/�
ޖ=G/���ބ7t-��<9����[�d���5{lU�gɻ�5R�>s��{���1���F�/ފϛ��cޜ�~8�R��ԓ���3v&��!;�f��y
����z�yS|E-X��W0lxϛ0"��G2?���E��g�x�NG���$f�,��g��g��/*x=�Jz�	/�`�@��M�T��ADzт����%������}G�ˬxn13�!^�����3l��Ұ�����{h>�<�R�A$���}���d�:UP��qs������gDQפ4ǹÜh��������5L�0:�e��N�3�Z~�;~����۝� �?i?Y���y�u��9�c}Ö�77֗�o�g��|��&�ƈ�jc�q�)�?e>�ձ��%k=��J��/��2Ոn.C�kt�b�ow=�T�L%�bk3�,ݽ�ã�^�3[s�x
"fwv���]G?��gc�Y���D�4�\JceAܨ�7�ViV�[W�:��q������繨l<����s�����v_�Qc=�hGg5��C{�yt����G'q.�t�g2ۺ��2z�',CJc�6ƨκ�A���[�eߒ;,5T��g��\&��kJ,F߳����J-�� hr���Xe�M��W.��Ș��$�̘2L[⁡���y&'r�� �*��,av��,7ǐ�fR���~��H��M�b*�Gv��U|�m��sQ�0է�	}�buX����d͗;M9�A#�3l��� �8
���n��﷖�*�#c���8cA�T�k��P�T�̹�%���gJ��"uv�=nz��6S�L�f�eP@�ät��З�!K\�����@HX�1��1_m�'_{64����^�_����E-��-������0 Z�+c��S�.��}Բ�7��R��<�_�i�V����@v���H6T���@HH 6L��Pnq�� h���t�%���M�Rnw�>�*��!��<F/^1d3�9�W����$=*Eǡ�y����J���8드�0I�9í����W��j���;�Ä����aX��{h�D��[
{aB����'\�C(����&̕��71�[�~�Ǆ��p����d��Y��w:fƬ�����%=o"�,��W4�H��:x��n�o��oϪ���wM���~oU���ݧ�|f=�)�rU�=�y%��[W[�|�k�|����.���#�]q^�F�i�?az���\�o���FA������=���90�O]�_4Fx^�:�����]�AF�����OA�C����]�c.�C�W��jh?~��5�@�-�`�ۮ�y�j�˥w Ka����Mp0�:3ƁMᄐe�V�_H�Ac� ���>2P�tĞͱ�0�5��,	��$HP��LQ͊[�t�` r�S=�A|mN����D��q�褉�09[����W����	���Z�Ӡ���
}�0"k�G:K�.��/0��j�Oo0�iJ[R $y��;����1��Oh6B�@p���=�����R^Oi��;����R�j��n�Y�q�4�����0ưH|)��;��$'B�I^��uw��N)�mR��I}��qɥbڑ�c���>�Io�he7�L4�&O��D��T��LK�K��u�I��Ӳu9����;=���P���w�֟���B���z��4��P�JHq�~�J�=Zi?g^O�7Z9���E�N���k�aR{��KZ8M�G���թG�d�PK�H�IZ'�[РTK�x`P&V�n���_0R}���.�hK��;O(�J�X���g�BS��()pt�|pfd�H�u��	��IS����Am�|:���&���{�|�2L����}At��͎��̠�ۓ�6��>Ѯy��7�J�9���|ᢅu����k�k��0)�r�jc��l]~�d��`�F�{p����[��od�1�b�0^�O�j���G�E�hx���	�0���9����-�/,�?Z�xd��������g�<x���<�l�����jk�?���b<쒬����!�J��E22��<��4#�o�U����b¼��af ��*��<���+��1�z)�S�;]�*��]�F���nU�˭��]SZ��Wr7S	<6����,]��&W��/vݚ_�8�J�c�O�	�d���_c4!;!�����|nU���[k�E�_et��)1ӘY�EU��1�hH"1��(+�A�!��֣�$1�43@��՜��������L�����r䶌���K\��Zϵ1�T���D=l5E���]���垉'y���X�0s�YΟ�Fd��K+Y�ȘW|W����'�ɶto9�܆��'�s��_�ظi�n��-v{�a��6�����4����o�����No���ޠg)f��+S�B�F@�qF�dK��6�?1P$F����Q��9�?7���Gm8.�����0#nFS�տN�$�UCU*q��}F\*C>V\l�R�(���E<�רI��H��C��,����WF!L����*ɋ
�f�Y8@^{/�3���\غ4�w�w�������?�����a/�~E��p+�ī��V����TF52�׎q�W�� �/���w��Y�2��K�����V��LZV��n���>ԟ����'N�(����?�����بU�G\���>�6�b�W%�����Ş��M4����hW3��WP�9L�>����b/�W��/m�4I�kE��/�"47��e+�!n��1��	̟��\�8�����v���vT��&�}XQm��OW�V����4���Zj��$杖w���M����/���\7�h6��p\J���M�Qj8(+䄔�e�u�c�Wx*�MQ����)Dk=�x8&KB1�C;��1ѝ�n�rc���X�*S��	̬AI�Nj��Ai䤟���!kB�&̴��6��5MX=��:/M[�FA�:���m��U[�)��i%��6�[
I����,?����,?����,?����,?����,?����,?����,?���������D � 