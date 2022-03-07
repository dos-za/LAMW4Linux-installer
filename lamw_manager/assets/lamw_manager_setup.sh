#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2440041046"
MD5="7661d5ba629909705ebcbe0803bbd9bc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26608"
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
	echo Date of packaging: Mon Mar  7 19:15:29 -03 2022
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
�7zXZ  �ִF !   �X���g�] �}��1Dd]����P�t�D��/�,(��lڋ����]8-&h'̴xE�kQz��Qb64p̙�q#gF�1�<�aB�<�Չ�ch����"��P�bN��93�l�������𔑈�4��<�ԧ��mn�:bk��)N����	�� ��k�h������y6�P�b'��Xq�}�^�y��<�����u����?�-WѤ� Y;#�N�������J�U���LoB�뉯id*���!Xjް�H9�`Y1f�գ�ع/&g��s��qɵf����0rN����x��	�p��������#قy\��D#%NJ�Tyx�)}�*���K�A�9��e�q9q˙���Fg�&�ŀ����lX�ޕ6J�;>�s�^f��9�dd<��(RN�&���o���{��
�r1��b;.P�\%�v�C�9�`��C�rNJ�S ���{�G����-H�.���T��*1�#x��I?�urNIj��%�(��ڝ��$)��]d)	1�)왉[����T�� 2l��W�V�:�4
�0��ŀx�PYt���������U��T�_�tOX���T��*ܾ�R���y���\;�O�$0�'��(�����<�'�lhL�[���V�a�!���;�h�p�_�-�N[��sVf�cV��;X�Zѐ���I�	���'�A�ܵw�*��>j�D�nqS-0u���,�ܡsy�WUp���)�G�8�eޯ}��q Fv��FL�KyM���'��I2Tś�z�]UU�<L�o� �o&��f�!(3Lǰ:��o���=�j�#�`l�»��>���8q_�O9���v��U���� �^2=�Y�Uo}��3��[�,�+cmk�`N�fm.t���a���^��B�R�<<�����®��xK�3]�1�W��kP�����:F���SDh֜j�1�!�9����W�轷��p誉O��n���� ௄V?�<��2|�Tcd�����Ԝ)�uK�I�L�嚐�{�zߎoKD�\�X��	�}�9�7�C`�����$b���� f�MT�e�7	������p��^x(��^�ܿD�Ј�� ��ZD�rл���yD`��i�|h+U*a��F���X>����-aE>;�`8�#��;�|%�<�_3�,Y^�Fw�GY}���wɿ|>���J�0�/��
,�O����AieF�����-2�x�Om!'m�q:R�Gz�����z�l_Nm)�^�Aã����˰��+ɘ<$AZ׌#�+h�R|N��|�b�ŕ���e,P�Xè���Y� �y3�Ԝ=���G�BT�^�Sh0���'6�1�pү�el�?�R��H,F"��>�����W�O0��g���q�e4�|k����W�XJ�נ"J��7�%Y�&�A:��l�v�7��Z��	�]��=s�q{��`ER
0�7��p��H���v5�,[6��2[	;P%4y���f����żl?�(���(���9����熧2�(�d$<̏�j���A�H�I���f���-��o��lŀIK�Bǿ�.+�]͖�&�Cn>�p(��3����/*�Y�+æ���
�V_����D��7jR��~���H�y���&�5o$*��Q6����ngo��/g��J�c;�!ue��ܢ�`��|2���ۄ�#u�E*��FQ�(�����6t�W���l��
��U,w�������� �K;B1���NPJg8�X1�}up�pE٩�1��}���+�as]m�q^�T���D$����ƕ�z��qw�k-�� ��<��k �x�NHX��]V��ZW�\.p�����KQH��Jd7O)fk*�r�-���a����f��[�٢�7�p��_�n�]�_�֐���P��E��"���t�*����V-u��ڰ1o�+�)L�{4���� .;!I|fN�w �����q3*�y�gɜ%K��@`��cb�b���[XI�{�6�v���O^�s{~G>���w�4B�9�AKFf�pht���2吰�՞2h8�*��H�RME���87w/��#�ψ��Uω7��{�ǝ���ĂN��V��]-,�v;�)m���"�כ[�i�r��߫]��5��+��ՁpSg.�}/��.`Wϴ�,很�^�i�>�C�� @�8�p(�Ţ����3 j���:�2:��.��.h�]��	%�艰5l�W�a�/9L����C���De���x�T8����4�������[Z�,^���5�5yM*DQ�T9���a����̀�A ��6�X��,e��6�PIV�z�[���~X��b�[�-�Q�2���;���c�5����K4��r�]�/�/�&=�,YRd����۴�C.���Y��;0^�������\��Zc����c�QH�Z�������1
;W�b���Z'}�6�jو�R�������JV�����s��w,{�Æ+W��[�Bn��f����1��n��w�q�8�YJ���㺺�ہFV[����@q�V]�}jb��*Ӫ�(w���7�4�yZ^Z8;th�_�Ș~aR[���>q@��z� ��P����=[<�b)!uc~J$/U[����*��&bl�a`��sB>8���@瘆N��k��t�US[k�6@�:�V��s�V�f'�@ �}���6��G:L���i|ȥ��.B�,S���%!�o׋e5���`K������.y �3���3��A��.�`y:�AU��B�e�����[rOIR���~\j���W3�ϲk�f��̰��Rs���goрY���'��Z�� Y��ݒ!#L�,F�J�|������^ژ;��:�p�uƊQ�Њ��_�;?C�(>�j2[ç�QA��|T+�:�Ԣ�߄��շt9�'�U��7���ͤw���g��{���'��D��a~��?�lTc�BҴ+ZJ�z��[�B�پJ�%�FK�C�<)�Zk8r��z�r9,�t��G�SV`d�ҡ�}��|����[��UN<N�aaz� k�f�K߉�֖~�W����UvT�`Ǿ�a3W�x��x9���PS��耓�cA��F+��F�⦮I��w�$˺��O�����z.�����$�-�ctW���?�X������E`B�	y���7Ŭ�W�d�[�N��2̒7�H׋~��������+L���1���3&�)��&���^�z
AycA�\1!�!�������\ڍk�ձ~b�1[V���M$�+�2�]�O�YɛC��*L���+0��h���3,�O�m��u�	J��\-�����`?N�-v��e�)�[�-5��S�tG��z����a�IQ:��d��P�y=G�]�(��|S����o���<["�}=�4e�*���|k��@�L������:)�o���%s�I�*S6箢f��6�(m�A� �ٯ?���� O���R����m�L�J�X,ʬ�Ae���Go���7�bWy1��,h��(���r��e(c�)�"�4R�Z�յ���#^�m3��i89�:%%��6sT��Mϛ��#/=�D�Q�i,i!��e��!~���ię
M����Z3�@J��A�=�'�Mm��(�{�m�9�`5�=o��nҕ�M����ELŮND&���&�e�o<i��xy�Z&����ׁ�s'�,�&��p�:���n�ID��u*;I�t*M��I�j8wxe�zI�M������oriǹ@�I�mhW l��3�$��͖&�ç>Ph��K8�Λp$���n����2*��ߨ� ���}c�,��_�M!9�Ɋ�c e�����m�3by��e���'�[4���D�2MQ�%נ�q~к�����"�8	��ƥ��CZ��k�B��Z��p�8���}�.��QS��$a[�D7��2�IX������]F���oʿM4�"��O��L��C}%�$��'cd��d6T��F,n��b�d~�_�pl��6\�P��.��h4�E�0$%2+i��gZ�j.qʌ�%�L����6)$�1���*���f19(����<��K�I#G��	�,��"Ū�	o���D�!���@��d3T��Of�j�4�"�;V�6b[�pB�S�֠8��{�)i���|��<x�<�#��T��y��W��~P� �a��k�ƃ���D��v�>{���r�K5�f7��\�.(b���z�&Y�	�Ak�S?J9(���-���8�ED� �E�`A�J����ATu�l�X���{<�w���اJx�l:k�),��b��o�n�e�\?�9Y�f�>�u/����l���26W�P wW�*��41q%X�� �湗�����������+��M�PyyӀ��.�Iɀ�{��Cނ���%O��<���p��[(=�. �CK�£ԫ����ME_��:�[۰%�Ke�z� s8e���"��6?TZ6�����e@t����^8�v5�5X���[ٵa��XW�!�u<�eUE��?i��[�ty�(�F����]d����,�|z�V!
S̎
-�:���D�������8�=�?�ę��.u&�}����`��sbI;AX��l��?�;�hV�NR\�/æ�H��!�6�;��
{���;�
UC��{�&<���_���	�[�ӆ�'j����R���F�{p&�!�ߊ������{��;��"}��Ξ�ٔ]�RY��-�K�gZ���ȏ;j�f�m�m�~���<���6��yiq��V3�i����p���%�����
�l�B����xg���V��Na$#u�_M�6���EU(�<�晦�`�;�y�y� �lMw#�Lpe��L�hz"B"ü�-�۠rnS����c�~p��
B�D�6AE�q�>㼘��˒��j)#���x�k�h۷'x$�\`���u���e��@��=�4�{3��#�B���: �h��V
��@�3�9E&�@G������Xi2�Tc��%�Fo�e֖�#���l}��mÆ��KG!^j�H|by��H��: eщ�V���%:���F���A� x�p��Os���#Y�n䅨���&]�f�c�k���q-����2��i�����������!��O����'#�p+��Na\=��	")���9�H�Czjv)��+H�J$ͱ�����ߖ��H������±-Ӏ!nkǋ���	x�ݛHLr�`������0G2�t����<��^ ��Q�,��ꢂ��s2k�o�B�@;���Ԙ'�>���d��)>�� �e�hoĴ&�!⠄ݴS����8$��-ѱ#��+A�AZ�&�A�b_��*�;�h#�B�D�99��.�f[<JO�F���	�'a�L�s�ӦV;xS�ӥFv���������S��g��,'S�b�y�5�(�}0)��jB��L�	�=�[y}�\J�e�m�P��5�Ѷ��W���'�����(��4��;!�^@�N9�TM�
��C�J��0��*ì����f}
Ў��W&ŮB�Фg��fm6�A� ^}��z�w�+��#�6FK0�-~֖w/�"}i�"\z�^o��./5�����Z2T䄹f�\K�j<��nG�^�Z�:����
�ע�k��<.V�Y:'=nF�6J�l�R>~�{Q���Ez��f��)r��nL�e�U�?@���b�;>*C�~%�'	�R�kbkV����!qA�sa�-�F����|���eB�H�$����#��/����;�w�J�]��ak�'XZ�G�
A} ��ȑ��&��L���P��h>>������b[4�.&B,5��36�kS��G}��;T�ٓ$�Jŵ���P4��TD�M� ���(�nz����u��9��>�+��6�|���u�t��Ñ��UrJ�%�Ѫ�u�!!A|$-�,�4+�z50�+��`7����)�+/3���(�B�h�Zc��~�|H�P~U7���.q�:�_��)9�_�4�ʉ���q����e�r��̓ 6�:��[��䊁� \�'�Q�f\"�  �^<r�_��p�[:���$�����P�|�=v�J��^n�I-�)*k9_���vЧ#����2�'<�p֣s�(X8-��pd���#��-a�#C��0wc}f�f��f2\ �a[�	/�EKHy=x����:�Z�Ж��a�%�N��8`!L/n@+11Z�ZzJ	�A�S�[A]�������$D�ȫxe<7��%��P��9��WA;���te�[���`+�H.#T��Z=���	)	p�*���e���d�Zz���ͳs�jmB����DteE�mg�������P5b��)� ��s�%�����uy��)�6��*�-�x1�h�o�>����������\����F&UTo�ZV����\�e/Z��8e�%�GQ�X~y���@�s�˽�0_	WaA$g9n�=e.��+$����ԉ�1ȗ�ɖ�Q�]VijJ���!ܥ�vߨ�+��@�h3ŽFF%Z�G��Mc�+U쓻�T�]��ϑJ��@vnWL�X5�lOD֝qq
���B�t�p	p���'sq�6�*٤��Y��EM�������% �5#�<^��N��|qR9PX�]PY�t�M!q�e�����}1X0=
k} �����J*�l�?��x�4��A0̍A��|^7]�ӿ���E���Χ�p�%�^��+d	hg�Uy��m�4����9�FћR���l[��(��g,3�����E�� L]Ffo:)#�X�(�������.�딵v~�uҎ�Q�F��e�;���R�/]�����[*dף���y��ycZ]��_��4�=Ep��ʊ%�����hU|���l���3�{lw5�h(�4"$PF֗j�L��?ѧ�;~Q�0x=��+��C�c�Y]7;����>����Y�[���ܖ�����
6p�*�k�]�Ї�-�'X&,؃ �$�c�#C7Y1]C�/�B�f�nA`+y+E�ܻ���=����$攠��^���ϸb:�ڤ�tY�d[�7��S��|ukY�3K&d"@���o�UY�[t �H1�Ё��h۱s���;�X9q?3�T�0��~�yg�I�5}�L��=��:`��g���Xg�� �������i���/m���-=���|��8�8H�p�&�F��U�r9뒶m���ѐ����z��y�g@[�M1o[�#��TQ�_Z"��\[h�w	�,�w�:⮁Ŀ�b�@�����j���Pə�
��Q��g�3�v�y���r�*�hø�F�'�Zd��">Wv�OLs��#y��l:�}\��@Ց���e86��^wJfk0u�5���}�2c�x<1sS���}ߔ>'��r"��:n 86��%�q>E��C�hF_�X+G6�r�>/{@V��T%���6l�2���&�$���׸e]0�ck"��vb$�o���J�O��촛W|���q`U�mCN����!!�����1Eu�b�f�D�ڀ�zd
�KfP-�L3P
U��SD�z��pz낟�g�b�O�UW�XY��9P��vS<��w�^L�s��j��ځAϧ��Ψ��kQԉ�rfY��Q�Fw c�E	�>�Fe�س���U�EͣIL��PH7�uX�����:�Fyj6��^��Ѿ27R�z�kn���ٷ1�5����(cƎ���{�.�lc��W��? B4�d�� �-� t&^�q��&���"�ڀ� #J��deS�
�i_b�����;��z��S� ��/Cd�f���׹�jc(N>�/Lj==�c�#��rA6��C���<_���9Y�<O80�11��;�p�b�7m�X H��fd�I�a�&o0t�E՛�d��8�|�$͉�/M?���`}�'
S%�ΒL�oD̽��}�8� y/�7�Ѧ�\b���e�'U5��b�����F�'��!1���]v$o-Fݮ�$	m%NW+�jr��pȫ~������=Y&�(G�DEDu� PC�{�٤׫�.�4d_�`�{�W��^e�X)���k� S(�܅�ʑ���͊�v.��)�a��sBZ~%��Jdi�&���L�Y<~q��*�F��v��%E�`;U�P�i�*��Xf~7����R��[]�&G6�a5&+�s�7���Q�Ԣ$'�)�5U=݉|����f�f�I�qi�����+(�z�$�N��]��\cd�F�t�v:e�@#`�t?Z�p�-�%�$�F�f{�&r	�֨=-���E;�������'�l7�/^^OD�RtO������׆��R��Q����rsmD(E`�N����816������v��WI����.]�1E�����H��rB��i N���NR�և���Q��\��+��lN��
-��g���#�1۔��S���'[
�,�z���#�z@����cԘ���hE�X�����U���XQS̡v�9�݈��!�j0(������dG�?]2��P%�d�����yq��P�t(�mR�*�#3�� ��<�A��2�'|�ΰ�)&�	���r�]�Dp�ZH`!�\�����I,�)���J�^0���m���2�,��ǊK� kn�f�<+?���X&h��/�{%b�$���J!-�ò�y≝4\��T�"J"d,?�~l(�n��&Gu�)I�p��ʹ��7AX�GP�q�D�Y�`��ԍt��äx q�T����mYP����ȩ51�|�;��J4���Ҙ�^�L���� ��E*;�ǖ��$?�/
H���% ?��r��3T���<P�R��BF���5�LuDʎ[���0.�ý�KHߔ|��ޭ"r�.1�Yn�jUgx�����?y��R$o/�_thd)ᝋ& ��H��'㧣bz�T]�_#��մ�'gS/�gM Q��0ɾK�)z���Z�T��-e��l�e��=M.����� V��r��[o?�]]X�F�s��7�R�D��T�;@oa��uF�g"P��ĺ�'���j���PD.U-�w5� S��Iҡ�5���8����6���U��[�.'���|a��A�@F������V2>[t��d;շ7&�+J�_w�b�>&~�1X��iJn�����E�����9��_k����!<��R�i��e;��0�m��;V��Q5�G���y�VOB��H�m�xuř���I��ƺ��>K-Kp�lRi#6�Z�@ŝ ��
	�C!N�
�D�8h��_���'��Zj�[3����=���2�-L�x�%�n;2�2�<ޛF�����P/������U�=�O������5�����+�_�6�F��,�$�l�q�0� �R�AP�$�����࿿����ycg�}<�B��������vhA6��~���`!Es���CIƀ�H6G�dV��Jl�c���  /e�����e��^�RM�83e��5���$丶�8!c|0j��
��0��3���Q��1ȹ���x�=n�'8#'P��Y��4�3[�WE���$,Kd45X�[F%҃���ۘ�����@4
[_�*{�����b�1W!��eo�S�k�BpȾ�|~n�J�� ��A���Gc{+OD�u�bA\f�e�ԓ8dᯋ6V�U��G=5����Q�RU{��\�;�rg��
?ɑe�����n��=D*Ɇ��������]�#�����>�BN���ٲ]d�$�fΏBTp��?/:���@6�8Z����8�Дu3ï�2TcFq���d�e�[�(y2��T��𕮿�[7���5�K�k1B��DV�.�8@ ����7(����%GLq��J�O)�'����"�~ӏ��ո�l�5_�-&�JQB����}�C��w���X��������O������LM ST���k��!2 {@���l�[�]�	� k��ZM����a\t�����5��G�x�MG����ݼ벏�``s�D���y*�A{9^�G|�ǥW`��~S�xR�g�t��&�m����v�?�������u}��q�Rq(YoZ��t5�'�߲F�4��R$�����MsD��Y�ۭ�-��	��
���hz7�!Vެ�~ޟ���/�3�4��J\��|�Cc���t��8�<�%�+�Z�ew�a���|��'��7Y�jcҘai�z���a̙�ʛ+q.�h����q糿�]'�ÎУ����L$7��)M�w�N�n�b�G�;y���˶����+�W
��37j���C	�lP�`��S�Mlp6���V&(`��
��)��P'�Bf���j��b�;�YA����;D%8]jN�j
ku�f�:Y��?Gy�����Z#��yrж�G��@��߹Q�i��p�J�����:	ܕ���!�R�1p��f�+ ��{��]�i��`���֕�9��&9��"S���+�E9\��G���m�z=$g�ۼڸ�J��v��l�]�h�9Y+ �>
Oʰ���$D��L($����`T#��ӫ��gh�}o��w��l�,b5�f�!=j�g��@���m��=̒f�+�ۏ��c~O�K��@Ƒ�e|�AO4����],�����sI�8�@�7�����K9��Z~� �8�͓����z;6P�Y��h���z����\�TP�UN�f��KF	�R�W��2����.�%$�4.b����(�E�bS�P@���e���8�+���y�јJ����
�6`}���
�e���rL�B���9�y�6�A� ���A���N�O�,����N���ot�x�s#�|�D6iW��	������3p���[*��0�Z,�\'&4EyUC[��ytIp��[-9����p�8;1(�iU�7��wC�����~��ۯ���It���%��ƚ��^,� ��Q����T�84����b)E�(+i�x�d~[T�����d�+�w�3�ShY8����q|R�7��[�M�	;��JM���1�8&+�Z'?��
.X�A����e��;2�R�)���x�_��~R�B"�0���s���!F��S�ﵵ?+�[n��.���,�Z�&ͼA����ڝ� ������s��Z���W��R� QG��+9W����ku��[2�Ɗ��J@�!���zi(�7h����֝��58gX瑰�k'q*u.�b�9�L���.�Dvy��&ة	���)��G��'P�7�fC4��?��9<����X�~7(rk+�h;�&C����*6�n� �~��j~�m4|��Yr�=
)u�����`ꇲ��w�]�1�ikTz�w�-�Ƣ *����L��F.v?X��*H}���n,�A?��=�Q�V+K)�
ǿ�Y��{AW�$wIBn�� �@�.ӔX��*�Td9�1�߯b�����}���cPȨ���)�0�{�Y��^��?��>-�A!��� c�7�?�����@f���H�,T�ܝ�����3!�-
#���o+�+�T7Ԡ����y�J^�g�1�����k�k[Kv�OS��	Y�}
�����U��_Ƹ��14u�T�l��/˄N(t� 6F�'�.MJ _	�W򌌏#��h��|�m ����Nu�\�c�%�;ݰF��S6F^�@ ���S2f
#���P�ҁ;a�Y�x��l��_QT��a�J����7��3���|X�.\�/3]��gĆ�sFo�)w��(�D��G�s���dur�%}�is�j���5i��}��Xާ;Q0�����4Ђ�]q�{�9$��do �+��4�@��hՄ�O�Č	5X��8S�.�-�����SX�$	pм�ĩ/(��5F��f�oD���z�BIobH���FR�`�L�R��A�۬�P�Q[�9�d8����p�������J�$�dk�~��jcz��zZ����K��24����x�ט�#�zZ�SX!�J�9�m	��2YF&RY�g�p!�G�&6M��$g?�eN�,[5n�m��Nv!��� e]{>7uZg���oT2O���&>l��C�f��{�!O���,��Lg�1�b����Ԥ��?nI*pK�}����8W�I)�xb�T= ��:V��l�]�6�4}X�
}CCPƼ7J �׶)�����𽵛���	�͡*��)��]�4�U��V4ƢP�	��^���>��*����ӳ�u�jB������.m1b��C8z�]R�,���1���=#�̘��.�����V}�!����9�Gr Qt�A�X\j�K�(i�9
�7�EG0���=���c1`� ����k��*q��׮9��pX���[��[�� Kқ|�à+��������4|���J�	%:*�J�KJ��� �[K�9
�I�*%x��������¤�nhw`8IG���Ol���c]?�	`�L�L���]{����[�5ԍ��N b@�Ə],�v�UP
�09"b�ܵ��eK����# �B����2����3t�S�#Z@��J ���݉3����`?p�<u���~]+�q{�q,���H�6۹#B�.�8P5y��H�<�&PF�4�z5N���b�L��_Ƭ:�K�4�j���2Z���K���[F�y؈w�נor{���CXde�������`����S1�PB�Q]�<)l��[�[]-4��jqr-�͇�d�w2�6��u�	,ףi<��p=��w&F�����B�Z�{F:vk^i��>5������up|�59(��Ǆq �9�3U���ۿ��.��a��2*��t���!���4�Ba��f�X��;ߕ��W	+���1����e��
� �	w����{O@��O� ?kU�V�+.�w��)�jS���p��в �,���	�(�+��s���B�%FW	k��+�K-5���YQ`�x����&�i8�E�k�/��V��{'���(�hw��'�M��ƅ�s�'�^,.pְ��j���-gJ����T�$��*O��b�ՏV���5��F���"���#�J�6��ʙs�{[0�3{�u����>)���$32H�9�W[�'�37J�ȯ�0�L}'�|�`��l��"�@<D��k�b�+��J�$�F�c�E���!/t˹�+0�kZ|�3sS''�QI��ĸ�=��룒_�m��bns��V�V�<��P(أa~Հ k��'r�0�o킻����� o8�./����!�Eɇ����<d�������n���cs���l�i���X���Oi�Xg)���%p�HU���ީ]
W�l}C_�`���D�p��	�%Wh�!ʞp����8Dn�4邋q%2|���$Q��OE�ׂ�IMiі�﮺Ί��l��2����<�U�R&�� GI�~`��m�� R�3�y ��B~`�����>�1��M6�Czn���<lRu�M�n�Q�^�qM���r��Q�O��j Iz;%�&�d�D�1��@拰��N�-�N�%���o(R��*�;�h�6[��#��*�����[΍|�vwqn�	x�f_���,��Q�^<P�`�D��xFL�� ID�Ʊm���|-D� �K���4�dĢ�:���^s��[��qvk~eY��s@�]\��A������Q�I1/�y-�k���2�'�9�I�i`A����o{ؗ@�S��/�4���� 
��x�i=��s+�Կw����Y����EoB^�.���dcBB��:�_�kpȊ�����&�O<��J�xm���-���)�����9� ���S��sA�YbohC<� '�5�0utJN��gy�ۏ.u�������ϚW���ˬZ�k�@����_�i���� �����,������e�{����|,��8-�5����H��a����hjN�:�qY��7���[�Q؃p�����&�$]������B��f�m����w^:(�#�z%(�@Ec���ބH:\dx�e������{X��揩�����8���-�owV�N��8Y �$� )�
��b��k���.M��IT��4�p����O@��u�d�;����6)~��O�
&cH R�q��X�s�w|���{��#T�"u�=�������1�e���L���{Q$R����Hs)@l<tCF�p�4�~hW,��9�L�<��p8ǻUȯk���Z���C��Ш�dт��ԕo��{C�-�����K��lrw�F �*V<VЮ�xꈙ�-w��v�?����J:��iLD�j���m�����4XϬ�{jC��2(:��|��_'6��^������+Z�!����!+Y:�4�ɸ�G� �R�3��Q�]����1��M���/.�M�p�eHd��ԘO�q�w��#d��2X��߸�|��=��)\�٠��"D�M8��^P��/Bާibנ�%B�W8Yow|l/���q	Z/�V:n:_��H�w��%�3ۼ��k���j�k�^��b�x�Gw�bԛ�ZL\��L��lq ��6�f
Q�OiSN;��_�<�h�=�M�=$��cn�a$[��_:��{r�x�%���J?���M��ocsu�c�8	���g��	�����y��G}F��%�P�hYP�p�+T�X�|{^�'�XȺ^�_�Ubj#�
�bA�.I��B���~��Ϭ.1"�M^�-i��Ŷ�!V���7�6�H]z�9��ӪR"��{�m�5��j4j��p�S3"^�Y+�'�g���xz$�xIޫ<������B��P!�Fm�'�op!�D\�[�bj�Oyъ~Ԓ!�F����(��֧�VƊ9R��ǔf�g���L!���0-��
ю����Q��0}SKm�cI:���Ylu�������Ϋ�A��#�\P�.I�<�|�_p���u}�(���(� z��Uo%��ѮT��F�����(�{�q�H�r;�v��:�����X,b��8��Sq/��	�6BgX饹Db��җ�O��s�(F����]y&-� ��+"93�����h���]��h�i�Jc�N��p�\�	�%_�X:``�w�����Ψ�W�`\$T�$�����0�˼ѫ�|ab�|B�4�2�CP¬O���6/9ijB-.HG�^ʹu��b��X�-,QE�	��:������﮹��-�_�e�M�x:"�[ɝzTs��Nj[����HKOHy��+�y0�'X�'��Doe��`��C8���PeFnp��m�{��n��|b�L�p�v��*�h~TfOH~�`��i���}���L�.�!�V��zP	׈�}G&.*�������	'���%�4[��9p5?�s�>"��liI�*�����@���ށ��H/)�G�e��(��s��f UA=�c�r%Z��m��\i@ �T�g!
����̐�q)�#���Ә㶱��������*Y�B�h��3?���t��#��x�4��\H��Z��-$E:]<䣍J���Dʟ�����Ml�t
H�^Hvk���5x>"M��"� C	��7��a"����<�k�^�f_�Z�>�dD('VL�S|m͙���V�PFG��m�{ �9m}�T�`�"N��C�T<G�0�YO������F�q�������:C�<�.��V�§@���W�����k�b���W<�*�7��W��/6�k���x����6��X���k����*\俰�)�e(\�,䙺;��D�v��#�/[k:�y/l�T S!D�~�d��Y��.�q�B!�����תE�p�_|���Au�ǝ.�A[|�L0Ax� ��R%;:o���@���X���X�EF�"��v�n8ɼO��	�Z���b����$<���t������trĦ�zT�P�h�0ܶE�0�1�<��؆*�ۦ>��G������[_�d�K	~;.�)����5�s��']~��{��Ϊ���'&@3���\�w�������Ԟ�J��̨�Y�+?+��4׀�#������?��� ��c�n`t|�{v0B(���S��v����ViF�{�t�tSI�,]9\�Lֈ��5��+(\���vȘ�ɡJ��8�ٚ��_ w���EA�������g���VR�*��#��0e�����}�e����1_��T;���$x�y��2��lI�[H���?S��gq��"yd��,G2�P�f#�[.�X��]
P��~��Q#����D�u(����c�S�7��c��|!�7*o5QHR9M{�'B.�mJ�V>_F�A2�,o�P"t�f�/���J·�Kg�(g�Sw��v��m0�iUD����c,�svY�6\Rx�5rN���mm�^�B������tS0yVP� h�]�ܰ&C�q)�E��H����o����It��8�֙x*�Y���<v�f�����񫍷6Z�A�����@�.DY@'yPu�߉2r��{�<��maa�Q���YX����(�K��^��/�� :9���Y��I�)��+���ڇ,�9�n���Q���e���(������<7IY;���1:�F�Pߗ���}T�:�#�^��$�VR'�z����%k���أC��&�#8��kj�O� �\�]�|��so���ʞ��\���I<�{�͙�s�xڈ�q�7���*MHu�92���tq�9T �?Z�_��D���5�d"�6�_�"��iU�ۻ���-��o���.V�蠓�M��0�����,h����8@q�6n�ze��N[,�>qσ��wݜ�iM��"@M�z�K�{ڶ��aW�/��f��G�����l(<�1�CV&N*2��DϷ֩R�t��R)�@�3��#�	�a�/A����b7�96����*�n�TWU�����V��=��jJ��!R��p��*p*߿%5����M=[JMo���|�a\jip�G��?1X�9�-m`���ls1�E#��e�����{U��[6�1�N���ѯ�Q�� �O ���L�ى�3h��g�S9NQ�(�N�N�
Y�,�:9
P�1JR��+2x'��P��vb
m�b�t-���׼��2k�A3܇GsHzM���0��څ�>�o��K��]{H�u+��D�V���R4j3.�� �f��}�- b��N`�9���K��J�����|�2��K��3�6ʵZw�myC&%@�Gf~������`/pK��$g7{��jj�)��k+(��[S#����h�{Z����Sg�I�25�T{�g>���a6�H5`���t$Ⳑ����^���q�?ppC�ܽ��|7� �0��d�u�Z'��	b��Ϋv7��e)�cS�]v��#m���XhZ{�o���֓�?���J�L��)P�ALg�h�ʂf����n�Ȣ�=^��^��7_]� �y\�0��+	4:���4ƭ#�CN�ǫ��ܫ|��\�<�� �-$�
q��f��0�z]��xK)��{�GHc��/��g�UOgK�>���N���lC'N� �5Pt_��؆�zf&/{�oϴ/�Q- ?�"�@M�)�G�ahԠ�a�[]�M���GC���0TZR	ZY��4҂!grk�PE~U���v�e���M�O��Y�a��3�D�Cښ��xv�E(CM� ,�?�nU��I��0y{����T%5>���Cϟ�o4ޗ�Qu���mg���L44����ex-z \|7��^x�q�Q��&q�>�Vޤ[8�;��}�%ʡC9��s�sH��!�'3}�Ġ+[�t_Vc�	��Nbgg�]����	�����k�\���;x"ia}܂���uz�p�*�R�쒢Z��/��2�N��%'˫���"�nkP�Gɱ.kG`HE���o�tk���a_<�W��Z�*��)����.��p��/&��zA�/G�ΩT�s^8em�>Ю�>�Y��K��([nZ������J|vG�g*���f��}�w�Mdpf�r
���$�l
ܐ��.!���-ȅ�gf	8_�<5N�C�����}D;��J��UR��Q�+U�$1,�
FS����+*Y'�)yp���L��~��F�]�mܱܭ\���;ճ�6��61&	�O՝}5�v5�����h��ĭ~����#6_�Ċ�#��V܃������g#A�v§��	;��9�U�y�
���3x�fP�d��=�Yȏ���H������jM��;}�����"m��Ut���k����J!t?�x���2�yU���'����b�f?���2i���d�f���5E]�gT��iĦT��ל ��f�<S��>H�f֛}��}%��)��k��%��/�>%�{8uMڽ��Ⱥ@CE&�L.IL����;3`-�,yf�o�/��f͢{jYd�ر���0X3��@,��J 7ߙi�WԬ��w�A��
6�M�����A&����Pu19�B��n��G�ijT��������ŀ����LIX,���C���>ؚ"��$���|Hw}�&C\X�jTI��Ț���}D��.�ƫ/_69T�;�k�H����{�G|��dv��PK�>�(�ma՞%����'#�q�u�ڴ���/�$���G1��&s��;��%�}�p�~�U���-5km���u�^ᘣrl3��P���2�iJ�`���"�ݤF�����P�&����dq���9s����%6ϖ,����'�(� ._��ү~�Z�Cp�yC�\��ddϞ�`!�����@Q|Cm޿iZ�����v���m������6�5o�8,64Y�@�F�UJ�c���]����iH�<��u�eK[������������9�O�}�P1)�r�Z���X�0����7f��i�Hva}���1�`�_��ܬ��o��,d;��^�<�o?\]���|>� ��z[H���R���u
�Wh#X��p�7jxV��)��<������?Z$3B�FF�7x�A4N�/��K�h^�6�~�Ln2��eQ�`Z lׯ�f�k�ƏT#�l1�1zV��mE=c�"��W�]:R�&ر�I�G�IW��j��q�8�ZjHy,��e@�FQh����P:�=m�:�-:�/w�aoW���y�>�� ��l͞?;�]�.8S=��>%��= ~_D���P�WX�k�#Η��O�@�qP�����$�~UH�����������_�,�����]���%�L���%(D��$��ܳ%�xr�#T���UQ�����E�'h��^
��Ż��S�E��=�"���k����4G�Z^Ԓ�����/�خ��.3`��Fh����7d�XS���>vx3{tޢC�"��s��a��5��8�/`%��	Z:/��U�U︬��yD�����X %U�\cc�Ⱦ�.M)��=������VG�]*m,G�$��D��wC柑��s�t��C 6���/�I^���y��^@��^���z�ÃCs	 R�2�wߊ��4JE�f�,�!"b<���d�H����pJ+����0T~��ڡL)�r6>���)��p�{����oo��A[F�	�\Ff{0?��g���>��X�>��ub��C��3v�e��w�QGL�jSjZM�M�#;'Hy�l`J&[����& Ral�.���Ņ.|�T��A� \�~�J91|��ׅ��F��,�u��X׻�q��b"q��V� �
xy�|�T렪�{ye�L*�N�x�2�~�mU����*ֶ�f��$�ʹpљ��Ƣh B5���⤵�R%-�Q,��n�	IK;EL����
��i�b6b6��� j��[ɉX�V��?�R!.�Y\��k��ͣ(����죜0m�	T�e*�`��AϿ��gֽQ��/2@����s#%O���z�K�;�CZ;m�����*^�
n�"�����?�G�����NV�,n^����P��0e&FUT�}���������I�*d���)+��m��5?�>g���ܐh]�A8�/�03��[;�c�� )&�}}���n<���g�=�W�a�W�K��t�vl�C�LV�1���?5i��-ߖ���)�	�`���T6�|R6�QK����4��`5�������ü�O^1�����J�;��y��#Q��?�"i�w9�2˞�dV�L��2�*咲����^V�L��7�y٤��"��v��`3�>��D�7�:����&t�s�v�1��Ԃ��W��n�<�����7␡wY��
��57��|�賲ȑ`�rj���T5a%�q&
Eզ��Rrw�i��������ŜE,ff�M��! ��:�"s����Ė�7�!�/f�	�b�5T��q���U�P�yn�[ٰۢ�3��M��#�_"�0����˿s�%w���à���wܔ�}���J*����\,��Dk�i@!���!h�Ţ���,���
�(����.�f��8)�@r=$�%q�߸�eG�3X����T+�%u;[���Q�.ы��LŃ΢�Z9��P�u�K�?���.wb�Y��΂�V�.
�E)s�������).ϡ���L��U�N��C�'3][Uc^$J!_�L�1����Y(�����So�6����"N�5��%��"HD�;���3Q��kwX�]w�0׶�Zëub���
��(��fR�fp���]�����i� �}a~[Y�^������T=�dZ���(��a7���8[a"��(��T�wx(��j��|�Z�wK�������3�qq�{��{Y�v'Og�-����_�-�h�L���������#:��6����e;.B���?������0��@�%�,^S���=�]�|���h��I�Ơ����N�˙�C���ZCPN�_�ݥr�~�+�J�?�)C9w_��ޠ ,�$�d�X%�~eD6ܭ���Q5��Bb�7Il�X&u���*�)��˳f����V;*X��d���U{�w�̂x�c�/�����tS��p�H�����4h-��z9�I;�=�=��I��ģ���˧�8���L�*���$���RE�f�L
ΰ0�33u�UJS5n�>%��xuo?����r�D8��������`�vM��몃�֖��~mS�ɇ���'c׮�Gj2�=&��J�g�Hs?�M�ͦ.)�������/<)�"w��p����^��B��!WY:�e������A�z�R�����4��	�)c�[S�����9���U���nL�&o
��8O����BT����dλ��B���څ��k �-���	��=��-�L�H�l�tǁ� Ҁ�#��8�ʮ0Zo�M߼�� 32�,SD!�t﬊�W�[�Ή��2T��g?���uj<谘9�}��� m����Q��0�M��n�7P�j���_�A�:1�9Kfy�Ky�qV�i^2_��N��zgjn	PD0O�+����K}g�e(�'6�mL�S��v	�S�5�<����+$��̚^�{c��N��`���1Y�����9{�� �ߛ�}���DzZ �%�J�-)����z4_V���h5�� ^f��Zh��!Vׯ/�d ̾��[�����h�7�@�������rnr?����j�;�(��y%U�$q�=(���-V �����U�%�$eK;Yt�G��J4�br0��霷��	�;`X��z�ЫZGY%��w�C0�u����\�d��u"�?�ɲ�MG��
j�z)�S���?�H]R���[M&T�qn���P�r�C����`�3���0�Y;��?��LŤ�`��6��٫�O'�)v�12]���7�u<�P�͙w��Z���!�h�y��R�K�L.���ϔb�ȹ6`׏^3�U~C7+�i_�_��s���<����ܻd�Xoec쏧`<�`�(��ҩqF˭����g����,��*%�����wS�@��WNa�xM��2cZi��.��8�vtTP)�/��z	��E���pH�$CX:�[��YbD�2�f'%���>i�T����w����5S4	��-\"��%��������.'�����A���۝���'�(��j� ��m�ɔ�S)w��De�4�����p*0�m��*CW8�VS!���߳����ӳ�m&v8K�Q�PUÆ�� o�jP���O:����^�>UO�w;Cx=�릒0}��o 2_������,ޥ�x����)3�/������63�|C7.L,���Â<�4_t����7uTr�5������mد��y!��D)�v/�!����H�E%�S=��k/]8FO�nׇ�����t�g��ض�?�������!��2��>�ڝ�@^	+:¾����3��[7}8��|>�n�p</��6=�G�H�ъ%+<W34&�iLq��(hN��l�o�Y�mzx��3�m�)�d����-��M=�ؿKf��+m���)�K�]5�W[�|��BV��K�5r�X��,|�+�]f�;o��'�����Ƕ��qR���+���&_����o����nƉ G��B,p���5��u�S�h�o�U�<��9�X��Ki�
I�TL៟+n��Aҋ�ļdWF�������-4}|5;y��CA��3FQ�v���bakR&��@v���!qͱx���,e�?���,; )k�Ⱦʓ�N�)ݞc 30�f ��D �(�F��Kt��c��O9tLv0�nc�&��QC�d&�.�)��6�^Έ�Ȫ��������~�gl�F55nً4(�w�}T����A�����������0+�Ne9�ƈn�_��ŬK�k�k���I�n���,��������aO�F<4ln��ha�S㤜9�D�#���k��`.(Lr&�@V��)Ya�K��w<��и\֚q�󾩽�S*�j��v��Ykv�\�~�k���B��fQfm:Q9[�v��{�X�n�_eĪs�X�?"�]�t�:5>v���(,t�dd.��j�[�Mf�ų6�mK*N������	����LV*�
�t�lv��[�%<��X�=g��:�nL�moO�5+㹄���( 	᫋��I�'ٛ�P���6'w�R��	����mp�,�D��6N]�Ɲ5{�q_ïXZ��6P����0�3�S]cV��&��$�_��7:d`��@0�%8K��&� =�e��
Q9��"#�s�R����	:U}�� 0�^����7|ER��׷?��hK6vlE-p4�P�2%�8�b=qQ�)�pԻ[�;F�|ky�ĩ��QVW�uL���̹(�D�����+��(#�b�;�d}~38�Z��o��j.�|����uP�)I��Q���Y�*���D��`Tv#0���a���R�Ρ�^U6���`���S7;i��}�ߌYC��9�v����hUf1��2PC~���o�GT� =�.�������Ή�R���	9�
�gz
\��>)�,�)2��00#�8�u$��В_�u���\�loT��}
Wֻ���8&���;��[ۼ���,W���2�N?q�
���|�?��=çHn`�	�mN�V�2Z+��J�;�&B\E�#/��m��͜���� S�;|"�����'&���g�>:E�L��~���;����B]|&BG���[�ݣ�����D6��/
�n�x�<�*�����aF�Y?`��뾭�m�6J�6ފ���ld����+5i��\W���d��b��a�K����#��n{��m�W}�t����}3���5N�Ƽ���J��W�+Q�ó$o��H.�NW	v-{��ʋ$�+6�<}FA�o�v`�B+�v�"Vu��#������$I���|-I@�%�f���g�ٮ��Tu�E��Z���	2JI ��%u�t
r�/�@/1��{v�J�fY������z0 �$�1�a����A}��v�b�g�˜�����2��^�����h�P���|\���%(,�{��|�S���*��!4�.��)�����p��#���%�0� �T��^ۧ��͟�큫����c�g3�k�U�53�!�=���r�A���G.7E� ���:�C�B�E�R�b�X���E(S��q �'�׍3���Љ���Zrȯ�#jg\�_@��� ����?Z�r	jj�C�L����'���yD/�N����	DY^�k�x�i�� ��G�k	�M�f��@�W�ϱ����AN�V,��� ���{D�:6���$�x�[�b�1,h���9����*�N�<fX����5��d��FKL�]��[�Vq=�d�'Zf��=���;���t�$�F��-���7�J-�����f{�1���h?�4(}� ����&���I�ɩ�θ��ߕI,�HC��C�?0�߹a��;�{{��`��(�[��S�!�O �	��Q[� /���k���E�j5��e�w��&��s=�/��[�#?7 �K�$+n�� �}Kt��\S�����[�5�@Vr>���B���W;ٻy[�xI���.�����NC5�;��Q>���ʽ6A��/���}�g��ƺ6>�o�Y�hif� E<��f��I��qAAJLL	�ޑ��.2������5����֟GF_�UO}�į�z6��P�\	E5�,-y�STB�s�?uHڹ�)�]��U"���mո�����P r��V^�_n�="e˵����Y+ W�����Kc��=B/<�Mr�9�T��,�^��?X�]������:}�6T��R�b�qkN;��2��ٴ?H%J"��I$j�ODt�T'N�~J;��#�����x=8> Eg=Q%��B�]����T�{��.�A:g�2�Sᝳ�^�c�W���l(wqQ�~�ob��@[��_��M:gƀl�9�M_�Y�?���_c�a�Eu*��"!�`Be���til��	@��ɶ �8�=y��ɥ��'G�T~�ۊ����>��F��k9��sC���x4ҟ�Uoɳ�C�
a���됬�R6����86u|S�@tp�[��(���"{V���J�5�ʱ*��t�&Ŀ���'�����p�'�rN�]o��4�%�WHa�KĔ�ߠV�Rpbܿ��h�&�w���]��*R�j��w�G0�.J8����T�g�D��.|��x��f^-'pӜT�:uw��H[/Ծ;�m��iN��H�>��tGv+���l8F��4G;��749�R����T�+�Es!� �٧n���:�ݺF-�{���xl9��i�-3�|\��o9^Ẏ#Uq���y���wj[�����U���:�1�i{�0�Oc����e����ܮ۾D7�D�ч�ť��bԸ!�� _l�*'��<�&C̳���d��'�Py>�W�duyH �c�xH<�xM}@Gz��gX�����Z�Y������p��4��$�qA#��Lu�o\��p!Sw>�I�t�wz�A�� �<��.�y�`�%	M��N���M���CZ�ko�#�2��#4B���T�-��O+&����\uk{�Z�dA�<� �`o�FE�����<�r���K�:0W�[߫��㫄j"7�1~2ޟz0�P7��'q.�.L��	q���y��I�[(bDZ�J���f�N�L�q�a�/U�c�f����;�<�7i��!���]�W����RH���(��㍺/��G�)v�P|x�(�S�HB�o�0.��W����u��Yʡ �n/�@�0�^P){�wtz�%H����[�?�*���96�0���Ɖ�}JA��?,[[p�2����B� ����1j&��nb�Ԍ��q�p	�w�G�u�F%���Ux¾y��{˨X�(����7�RV�ryF~$򱨓S���!l��\�~��N�h��qȕ����Zo�W�9�ÁHD��m!�N�p`E���5�n�\6�kF�]����JZ�0���pҳ��ˡ���ͺ���ܫ111cwM�iy���{��`�����Uj2�z�]j�9	E�Y�/�������Qڈ6��ܕ������l��
:��,vۄ�Ui��xN~;\��x�|ߚ�3�q��4��"j~�$��p�V�����&��� �L	��o*!-St8HDQD>qY���)$�;���]=zb9 SWN�8i�ʗ������;QqMa	���>�H�����ɲ�����@�N��0���L�qf�!��_%��Pze�&�܆@��T�>&m#�*㾦0�{5p �PW�K�iB���B�B�#� �a8�!�W.���P?�T}���e��G�Ԅu=1�d���f�	�����U�������1Osn!����C��ہ�~@y����%��R*܇t�u��  ��g��a�c �����)��g�    YZ