#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="864100706"
MD5="632def867e24a10472d0d14327f4c18d"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20708"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Fri Jul 17 21:17:37 -03 2020
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 160; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j�ʊcm��x��V�Ꙛţ�{��L� ߼��QRUΉ�)�)(P�x���*��#���'�(�K>v��c�"�ag>E����/���-p�Ig�#��4B��]�Qe"
�
�%U��k�'B���#*Ql��y�"۶|Y)�;|c�ro���&)M�}�����[@ Y��Ձ����Y̲�t-(fu�8�2�V��7OXU���x pv��υ��->B.2�ZD����_^���� {*���f�q�8����[����ί�-�Θ|V��<C�3�mg�l-�oH���DN�;�U>��<�;?���^D,P����B_����^��hNX3z'��V7Z�L���b�,C��R����Kq��k�
{�<T٪[��P�	��1>���1�Bt�5	�;ã���z	�8*&�G��R��M����ς�n�6A�u`?x��F�g[Ⱥ�5�Q9���1�L�^�uG�/l�nx	S'���v�J;��_	OW �K	*|�~ړ�Eľ�#]��B���(qlH3nK�0�0]L��͉8�)�j�}C��!7Q�D#�%��D��\����Dlq���a���k����O$'�.����q���ܨ\?�5U�!����cq��	���.�s�w�ա߫m���Z �U��r�ۍi�.��̞�}S��Q�l��7���0���0xy&�y(���n:��sv9��厀��7s~�<�m%�!����7��t�+4���>:�#��q%�l����b�`���E�|��S��<S��F(�T�&�u?/�g���	q&K�y��/@�w�!��8��,-3r�Ya�BD��wUե�m�(�����&� (����>���^;���H�� �LU��)W�7u�9�����8����9	r�B%-�=ǲ���QJ��	R�w��2��I�"F*�&��aQ�$zAD�#��'� hKW[b�h����k��Y��]g�	`��B��}��щ�E�Sr����a���v�];��;ߐ��Рy�Nh �k���3}��9�2-�L��O�e��'���濔a�y��&��A�8ۉ�����Y/-�= ��SAbf�;�]�U2��j�~�j@���`�C��7���4�j�T���Y��ռ �,�*�9Ř��S��+n�>��g>B�������}�5��,���
�F?~�7(C�����%񍷯�@ȉ�=:9�
��ڼ��@y͚� ��3<Eo�I�۠)��SR3�6�j���8�ޟ�WO��2���H�?�.#��CjD�`*��YK��!�o`��w
n^�4=Zq��G��,���A�EZ���� ..&��o�~���n�2mk')i�����0���T�w�:��f��������������0rL1cD�~�撓�I��۩%���\"m2y��f��)���K_�����|�mS'�ZY�|�#�R>��fh�;a�F|a,��6�����|~ |�k�̻�ڣF���+&��Ɇ��vR��6mE��(�j����U�qN'��B-�gV,C��}]p�-d��d;�@݅��8�(I��*S���&�^�W����SK~
n����Q>��.�'��ܙ]��e UȺ?�Z:��W�?��`b�)|2�y��W�!Ege�؅��p���4cN<7v"�T&Xᒃ��������v'ƹw�	�op@�<r�a��Mj�����<��S�tIa9�wAm-�ܬywf�����0��=t�ͬWI��fi�:��v�yD�i�r��3��b���^�ePj6*�?��	�/�M�#��㯑6���m�>*]�����t�������ؔ-ul��u|��XI��{��|�D���I�r�z,C�`�W�;!���q�T.��QJ�Y�YT�Y���U�|P=���/����	dR ��]���>�k]hE�8����f��;_K�xfYSf̷\���u��H$�BzC�&;�S�AT�SGN^.��g�F2��hG�~��P�<��ʢy�S� H��w�33�=�=+���=-�����u=μ�c�ܹ*�A�}7e3�gi\r�s��+zF5��?�r�� �5����3����ǇK/5�"��K&NJ�M���+�t���� ��oXM97\� �]l�^$cLK�G��R�C��\2�+��[S.��:��AT��J1k{��f�����Li^[-�jH��!߫��p�q��uX����|���LS���}����5���1
}���8LS"
�8�p1�6�Mu��^�9�U�1�Z��8"E��H��Z�'���S�		W��ok`��ة���� ����la2��Ȯ���EO)z�!�X悆��	=�wǞ�d���.O��Dj�&6Q}�:�B�uWyzo������U���v�W=<�n�o���v;T�W�� %�}�����u{h�	��Mr����a\�ҤV�.$��4ޛ?p��.�$���C����F~E�K��`�2�S!�sR��3*��<I3�fC�$i��@�d!"�a��� '��0v�2�h�7�D��ji�ڀ�T~����V���B]@���3�+m����;��N����]Oa�/���J/0X�~��zC�ד���W��I�!c�؄��m���X,>I�� 3��G3��o�����+
��d~��7^`��?�ALE��D���MQה+� b�={|Ղ���&��꾦!O�"Ư�ǖ7�r��5���dOw���7;=���i���DU�+rB�|u�YE��=9�����&���d!9�n�Sf��:�f@`Q�:�;N����ى���	�
"[�ڊ����r_��ڞ����	�	���$D��{gU2���2?�����s@���u�">��}�-w�9l7!q*��c�`��'v�_��&t޷v>Ht�bn/���@�#��*ӻ��j9�}���`V|婸�����E�L|��P���g�J��l�x%�Q���ϋh�����[�˪^��i�,a�x�'�;���
�Gn���V�8���gc.�d�#u�/�)|e��Q�������p�:�p���j�`0ރ��;�#Da?*[�¤�0!��^
����3�PȚwz�H��p��s�X8%
�+�36�V����֒�8
 ���C�a�*�u"X�L��xBq�Սb���κ?��֮>&��NЏ?Z��c��y�����D�����=���&�-䡹B)�e8
�=�H�f���?����r8�J!H-;�o�sq�4x����и�tC��^�5��С�}Y���O�P��p�".�����/X�pI.2VwQ��.}����4 �n�K�/+�7�����J���޿���@�"�D��8���tlX)t^3��Oػ��
��}�c������&���P�\�E�q�\�1Ŷz7�q�pQy�%��dg�h�!���B��{:E�_����4��)��7$��y���	�ˁL����yr���W�X��=�ȻsX�
8�~c�Nq�4S��3�c�^0u6��	OD�E�6�C�:d�Kܸ)!TRܷl�&��s�o�O~je'���Irme�bͧ��S�V��`�nJ��#l>���s�K��H{��ႝ�V��O�1k��'�F�G�b�&E:����E�?�κG���!�&����63�beE�W�����OV��׮����3xI�M�8��yҭMq��Z�z|��+O��v7�Ӽ�Z�gZ�K�������,}�ENcܶK8��ݫ/#��y�/��i���R���:zcw/�Qkg���:?���r�gU�NSNsj��<�(��1�ߵy> ~��\b@(��:��-������H:dc��v��tv�E=������b^Z.��g�MJC�1�����U�_x.��'�"E���pH��ȜK䥏�f=]?P�P�9�sv�O>��@�\޸ƖF�N�wP��-);��r�����Rlp��)���	�b�a�������C�5�R3*=��h�Oࡁ=qB8j�"R�V���50�тǢ.�	(��X�0y����*�s�N>�!ɓ��}	�k,3�-~�B�a����V�rc����[� ���e `�v#��5h��}6����:�7��T�VF"S�p���7X�M��jM�K�'�Gr �_�U�����s�N�O�}��6�xFrA1�����j^ϫs�T��i"���v�	�p�@��D�y����.n8_�)C���j�p͕������H����OI�У+�q�C���q�mY;]�/ �����{�R�b��ؕ��s�yڤ!2F�]��V�t�B��c��!y5T������d!��&��.����7�ֲ��T��kP26�Q���#sI>��zt��f� �HE8��{c�!��Z�h ��_���]ɻ��h�ei�=�Ur��tJ|VTrh���K�Ao�J;�RD�B~Π���H�q��ua3�s̻��R*(ׄ:G9
�,��]�9�y�����=ٝB�\c�-��XO��^��K3LV�z��݀����]e���$�,�e*-yy�/w�쥈���@�~����B��TI�$���/,�?/��M"J$z��}�E�ʣ o$CѥE(�*#���2�>>KBC�:e/����a8���n���Q�"anK�r�c��`�h@mU��F�Y|nB%�v��2��e���@��=�^>@\)���X���z�\�l��Ĵ_!���7��K�TŤ@��1�^��U����|ԅ��d�r�Lr���_����.mXM*�#A�A��l�﹃��� 	��|ܔ�S(����x�b���+���\,iT*,(��0u�	Vo2e���bd����K��J���X7i�1�l_^*�m
�Dx":�4�q�HQr݂��O��>z��v�7��=�/yI���*~�ƌ�9I�����{���!��!)�,q��߄|�}�T�!��a��U�0m>�d���ﳶO��:�pp��J}�\v�'8�b�F+]���3C���&�n.�֌C�ZÔm'�_Ζ-]�y{6p�m	�|�O��Ƴ�+	��E�}� �oRR��	�;[�l:�<<�3�"�w�(�a?�d��4dr��,�rIR��z+�!r�+����W�6V��� m1-�.c�O�9-8"�H7H�0g,7��}�qR����(r��e�$9���]�����
���-�T�<$�Ў��k���C�rP�
&Nnt�n����3�d�>����ɴmƖ�{���I	�<��hbJ(}�rV��.��Q���΂̧9\���"5O<�J'��C�?:�f@6��ΐ"�/݁Z%��	|�۰X�CƵ����?�q~g���b���E�qy���:�P��dqp
��94��%B�Ǎ��`���C�� ,a��[�֬I��!n�����"g(
*��R2�U��~�[]�y�{JH����iۛ궭������X|[�?�p����խ�����._��wgv��Y|f�|�b4獊��K��R��a��ML��,_��߄0�}�Y�3B5��=yN������!�]�:����Ha'L�a���Q}f!"-��bWa ����գٮ�ȭ}"&#�5dq=X��ͬ�;O;=&y~�~ kYW�9��i�.��X�G_�8d�*F�)򯽓���صO�s�O�z����5��{
����z�ʵ�:q��&�d/�F�x#b��� \�]�ָ	_�˶T�\w�i׼�ϲ���ͺ��8@�S6᣽�P�ّ}�����z�ZG�)�#�7�D7�1�yt=)C��<,�|3��K��(���&\u���$`pN]و�N��4̮�sâ0XI������4�!�p�=���qS@�³6�!�@�a�0@	����G�l]�a��my��7g�B�U�0f
�E��6kK�^���e�j�u����lqZE��@e�f#��\��0 �`CĶ,�	���{���_�l�/Z�z��C*�t5��@��kL��3�H�a�7oX��=�M{?��7���׸P=;�����k�^�oUx����Rc6rK2����aFdF�\CO�1TK��Mh��,~8�G/��$����w���@l�4�U�z2rP�_9�*����cz���De��&�'�q�_T}C&����������d��~��쾃�&Jg�DΌ>p?=�
���1�̙�#b�?�(A=���r�E���R!����m�2���i"�!|�vg|!��$0������X��!�)#�zr���[�c�@�ʽ�pA����P{ �L(��%��@j��������Crd�-��}�}������å���7�3��/�C53���Nbd
��3��6S�x�I��>����[��]s
�-�uڪ%��*� ��B����� Z�|��+�v�{-N�6r���R�'�s B�����6�P�
���3�~��-
у��M�(�i��wu��(žu�G��0ꊀ��=wL:ݖʬ�q)Rf�n;tkf���xp��(s��8�2��&E#,�ش�_$����BB�8{�@�<C��Dl)�C�(���s��C|c�m��6qu*E�СM� ����Q+̺����и���Ό�F^9!aY�;u�P� Ur�����y�pe�(�Y��-
��PDs��<c�)�WT�'>�%�S��,aCVv��mWy�j��jT
��E�Wz0q�s�H�-���Uo)�J��	�H=|e|e��ՠY�P'6����&��^�q�'o$^ ��O���ɿ{�q��f�~R� ���%d��Ng;!�3s�@8.���^�%#Y�@O��iO(�`mʵ´�E�1Xve}����|'�$���1_\�X��aߕ�l@�(J��e��긚�n���G�,�w�r���v`��6�2�
�X����;ex��Ĵ���=���ߋ�g�$w@:k$-��%������b�Z��7�+{̇Z�3]V��S��
��fY���Q1�_S�#�8�<9i3��_��0d���=��I"���(�م�n���*�3\Ym���v���?���Ֆ�f'34�ݐ)����ꁢ�cÈ���Ϲb"Y�u�Q�rZ3������1ȃ[�z��g�-:+r׿i�W	"�uQX�R'��4���Oz��V�I>�:2�s��v��R�DC�3KRv
�bk'ΑaQVC�#�.l�P��v�.f���")SX(�]ї=��5A?([D���cyR���>[�	J�l���d����9;�\�H-k�؄R�C��$�@��s���Gn���t�����7���;sp����Tzc#p�����L�Nu�[/�QN�jn<\������'�gLK� !���o;{�=S����p�T����������N���Q��[�ۄ�%|�zˈ�����=E�����FM;v�����2���+��|�����/��u�dfRϙ�("���Y�LO�X���|3=p˪0����jM w�>� �5����������鱑�esPz�ooyNk�I�tY=��
ˈ�(��ً8���4���{
��Ή�*)��?<����Qk�;x%� �f����LhfL���6-�/~Ш?�ݻF҃���>��f_�JXaeSuV՞���7�1�=���1�C14�T�Ѵ=�z�k�׶��&21�!��Ҽ��_�""��wN��8չqI�C�W�!��jT:�U����,'�3�u���z	�O)�r�j�Z�-�V�=E>	,��`�Td`,�ښi���u�+�����t�5����$;oJۭ
.MT��7�~
����`fv���./�����q����}��:.N�+�~1m!��ǔ;Ps��W��<�౜�:kJ��Е���9z���4��V׀�?�Z
�[��1Ud0H8~)���7��!H�-���r�+L��?�\JB�RM8D�A`���UR[f4x�	W�R��Ƣ��L�!\�Z|4�������aN�[?��g�y�"d@�Ș&لO.dYLx�$�v D����_�=�{|TrP���E_}�]�D�ou�>�u�kN�~�N0E
��*Z1p������a�@����I ��	�l�8��^�ꞕ�x+U�BS��sY�'P��gQ�I3fzzE�掁�O|��P;�CBKj�Ѧ�t�]��X�����sk���L�]�WcB.��z4����C	��U3�����;_d�T?��ַ7{�Qu�UG�ք:���7|_w���}�[0P��vs^�T���ˠ�����^�i8&�#0��r3H���R�K��)�5���׸�g�R�`��Pg�ʫD6v�E�� �܂���^,����k�6[-��oz�1��5�暺R8f�*�t����D�t��	�'�m��T6��%�W8K��@DYx�)v��cH#�����A�z�����Ih�Ƀ�O���U��՘�I��j���������$i��\,%po�?*�B��*p)#�?��l:���#hڂ�p��J��K������n��ۚn͛u`x��x� �$�+^C
<pl�d�ym�.�ɡ�)^�~�Ozy�����EٸXJ`U�8���=�T�'K��5��IOא���q�:�Q!������I��Ӽ�C@���s�K�v����d\z\��:�c�b '?�Oڅ�<�����Ǽ�$�y0�t��H�@:��z��s��0s��'�=�D�3?�D� �K5�s�'K7�w�"m0Q�k;��9m]L�Ъ��]�8|p�L���MWQ�՜�� ��h�)���.�^Er�O38�	U�-�� �7i&s0F���ǮOʁق��:W�x�mg��Om������~c0E%�{|@!��[]8�ՄS��u^��|�%�s�������९A-�*:�^�k��ׁ�k��^ij�����$+�A�D�op��ʝS�1wq��v��i�<�ϔ��w����>�)No��)FU�������ҽݔk�f�����Im�D�����H�Rk���k�����$���6�$�L�[����?q��RX"L02_G��Z���YD������b�;Iӑ�#�bGy�i~=�zz��b΃x%�+���V�jJ]�_@n[#9d#I��cO���2ڨ{U��,)��yR#j��� �n��,C�+�׏�t��ܐ���: Wh�Dn)A9��4='6�*��%`l!�E��@���վ��0��8Jʗ�P��YX���; ����#I�E����K�o��ڠ� � �N#(i�ۂ(���Վ�L�'{{��P��v>N��r���`(��Gz�{��Ց2�������Q��
7
rjno�9�����R�u�������I6�#��/ca��0A*�lniTd�Y�͞�a:�d�)7暆�>�~��XB��5��6�U�<�\vlʵe�Ot�L�'�Cq�+|�ʯ��=�Q���c
OS��Z��f�#R�'���7T(�W��kR���yV��>-��=��g��m�)�/h�h\�*����Tlz~�b;\��y�t��#�dM4C��@��3�8#*C+�w�lo�� ���)a�\Y�-gT;�}�E'^�-���ꂧp�7����H��ɩ*���wNV�-�5���Lr�4�H�nڔe��bl�����j2�p�n��˳^�3�Џ�a�(%�IIJ/��������
�3��ϋ1����l2!��I��|����j��O׃6<K�i���Z�U�P�յ����`cu����d�S���q�ܦ���½���,�f̔"�7j�rh�,��
����!)��'/�S�m�3{Q�rh��o��J��#������!��� R�[b��Wa�GV�鬥q;_Eͪ_Y���}Ķ%��"r��3�p^$��k��E���ۢ��T�i>.p	P�t��9 _&LӴ�Y��6��7i$��q�#wmQ�D�Y��
YcQHvS��V�����r�0�҃�q��H`D�\ۉ0d��^٭G��f1���p��ol��$Z��֬cߑzq·�Ŷm�V<���_�����U�`�e=�2�|��'��KҶ����M}qi@TѩuO죢��'2]�44�!�.��]4��"r����2T�2��ܓ�5n_ޢ��~C��l�P`�J\�� �9���;Puc�e�A\�g�HU�̗
tZ�ۭf��ZH�D��=�L��ͷ��4ق��>�M�AQv��|}0�z���|��� ��%o�7�
����8��e���Î��/C[kA 꾓�e,��Ԝ�x���T{���f�	o4�f`�ZX�C��epo�y�8C�ҩ���� �1v� �{�D1��N��#gr�޳y�|���$�Q/��/�po�Z\9z�r�m�ȩ�De�߲)}bO�N�l��!;�<�Մ�ɿ���#�������b���#��dFߓ��9��2���\��T�����mDYB��O��Ƈ]�Tz���7��?��j�cg�ʀuΚ��	��f;��> �j��^[е=��~SAEO���M����U� ��u���؎>B�\�E����@�HԶz��5�����$���APRԘƋ�V������/�|�C�fW���Exǵ�f�w��9S��	�`ބ�Z|'16/U6 z�kU��~�}-n�zC]n��$K�<w��y=���͑y�<��h��b�o'�_�W��̯��ji@GE�{U����66���P����0)l��c༥��*�;ζP�ܩC�o���ǉ��&�8�����>�}�o�$���G�/ɬM��i�Y�[���L�����
���SH�LWJK�q�qp0��V�'�=s���c��Hp@��8`�������[{��o����d$/����7E�y��?ʝm �5��U&��1�/���㏫����3A���u�c����i����h}�<�j����t��I���")/wEb�&7�����q�
ۉ;3����BN�Λ�b2�^���?ld�\6���q���U�r|v�t�/��!��z"F"������V���A���k�w�ȿ��@��z�ֹ��\�PF��r��@�j||�e?��iD"�I�婠��|>tqWR-v��f�a��c�4ʝ	��CS����h��R(��
[��f��~���9��z�z}f����!^����=�w���Z��y��B�f�^��że]�|�X�Z_�2�����#�!��3��I6�,�$�:Of����8p��ȸ˩�&Z�c�0"#k�?M%r�8ZB) �
C�����l�Ȓo���/mIV�x|{I0r�Ak�3��,�$�����o5~)kзu]E�?�U�j����[��*���aT��7�)qN*uO� �A��Dߪ@)���:���0Q�	D�=8h$+�0��W!�4�����É9��Q��f�h���ďQ�
!}�m�]S���z����_�ֱ0��y���ʬ�������c�O�Ri%øPhe�� f^��:�Wg҂�Q��`^�g�8(�덨�O��G�~�@�[�J�e�
�	rXKo�M{֙�o.��p�g�Y��ְ���t���gl��\�A�II6P��'A�F��hݨe���K� DS&���bS�v/�v���M�O{,���/�j�'6_N�Vi��SCY/7F�$�+�C���H��������B�/��|�ְ�}�*���0�kW7ۺ�'!<��B��vɔ~\��`aO���}~Z��2��nt Ea�ɱA��A
!��G��I?$��k +\�_y���)TH�@B���i�T�����ψx+z�\��O�u�g�X�ܕt���|	!I/Hm�XO�'nC{�c����1�����ek��������!��Sy�;� �v��`�dt�0s��$0���v9x9��]JX>��D�� �<�'��g�8���g�э��Fcj����p��K��wJj5#�K����t۱�h�P�4���mȍvu�3��8}s�+=5=��ۤ����[�h�� 1�̓������[�
�ce���|R���r�6M��SpT�:.�J�]���bT�]��#�7���[lNF�E�2�;�ɼ��'�(GБ�]�������J�^�	w�t5���$�)�¿����$+�W~*�����..L���N�f�:�t�e�x��c��r�f�z)�i���9Y~�W8E�C2;/�p�pS�:��O�"B�=�T���� #�j��,��w_�d��F8�>��"E��l�k? ���E
*S���Dc�#I�0����e��g����hQ�g���bx����fkύ�tp�Ô�z��xXL��6���"���UOD:3Cp�3�T�(*��V{�q]�u�U33��x�P##����~�v2/Q�YDJ�%yW%���(���u�ݶ�uy����t��1J6�0<�d��*]u�t#OH�g<�����$L�j��g�Z�㋷� ��%]*��/��gF���5�9�|gE�_�xZ��qPͺ� 4��IԮ� 7��w�G�Ws�J�f\@oF�5��mcʢ"��6�tY�/�O75F�v�/���� �����oqeڣif�q\��яiv���]Fu?;�
����~�C����S
���v���uT÷|'ڕ��Z���[�.p?+�śh��)�y ��Գ��uɿ���4����A����O�91��&t��]��ऑ0���kz�@��	C����v��8"�e���L��ܨ^$��"��7 6j�
�x��1Yd�r���m/2a��j�a�"�:q�Ps�G�>b�B�[B7���b�C�.�z!��:tͭ��]�~�[-KK� ]�A21�j��3��x���9�r1ڵx��P]I^ڒD-�S���(���֑�b_�"I��	���AT��x�MV1hĴ$)Ԕn}�vQU?vk�V,�]C�> S⩺5�\��ˏ�ŗ�����gN�"��h�ծ��|�4Z,S
[#>�8�������	�ќ��Y�K���;�y�b��) ��%�-��n]^�,�Y^!N0_�̉y3���s�B�>�O ,t:��0
~-c��b�k�"���C"P�.r-X�Ϋ��BA�c G9I]�g�3t�����ȷ�e>��:MCh�)~eل�+����Z�h�ů.P�E'R��y��/A�%��t;�������/� t��]*����F0@����2�D� h�a��$6��ή��񿜉�D��d�X諂�B�d,�LЯ(k�d��q�̓ȼ;\����64�~1l��<��?(��kɥc5<5�\N�Ծ��֦.&:�!��F���	v��:�y�P�c�;�HL���,#]���D�2n�\_��������ǂ:T]|x,ޓ^ct��ʜ�l=��<�J�ڦ�3�l�.������yY3������{�RN1�cD�ڍ���4��"��C|��^��q���b!�.x����ǋ4��?����ql�1�V�/1�������������(zǧ3X� �}�lzet�>��I�z���.�%f �r���02��`ݕм̡��|���7?���|V�-��Xp.�M-N�x9��@o���'=�I�g�\->�m�?�W�_q�**�i�F7/�8;�)�벃ܧ�L�c�+\k��ByG��'&t�ۃZtNJe��$�2�%v/QF���O�FnB!N~��<�6��7e�m�)�w)��|���^c�խ5Q�bM���{l�)>-�����Zic�����~���V��s��o[h?olf��r�e�8�B/e[��qE��tn�j>��_x������Y!������g���*�֤~E&.pY�/��/�j 8�I�]-��}�~��(ğnSg\�!���/�>���A@�qX�V,��cz3Ut�?��ݢdţm�[�O1�YǸ�귭���m)ڎ�h��ՇkCP�|��͑�ǐ9�a'���O�y�A��K�b��}l��6v�g�{	PϙZ�/\3Đ��AA^D���rа���EY�� Z��.f�!�"��h]�n[�o�7�6��tq;�_��$��py��XD.^�h�+���РM�g�ӊ0C�z$妯u�I�eN��Y�&���9�)+�KZ�=�=�����ƻR���2��Ő.g�1�;rhj�T�s�K��M:���nk�׀�_��P-�B��/�H�A����p��+5�g�4sl�~av�j�V�j���{_498���"������sF�Ê�ЍjH(��f���n3,*!�4E��ա�%�-y�������d����S����}��5�`��W{����I�%�A����^��I��c���jPGW9�$$�1H����S��!L�v�V�6v�b���_G����=k: ]�����!� ѣy������4"E��s��?��aU��g���=@��������T�*�.�	�[����I؍%z�p�r���({���
�<j�^�"�8E�}�$�S�"�ƹ=��K@��X�h!��b'��q
.��b\�r9��c�T�[|���{��d���c��*8/����3�ޖ�N7D��U��z���@߆85U��)��� Uӝ�a�3������#l��b�F4��ֱ�����ArQ����9���u��?AZx��pWOP�[�z�FK/o����XoțI~{����M�oؓ y1c|+%c׿א�i�~��5=�WN9�.I;fb�]���
!3Lϔ�{��aLRW|�$cяu���5}�/a��_[�`��hK�AJ~/�u�
ǋAR�����0���I���a��O�	�s%��fm��ќ���WL>�n��P~��tF{�_336%�$8%��*��$�+��G:���{�zܖ|A3����W�]�fbf�K�*��^|�қe(qF�4}��Kd�qKc*�A��K1��Ng�{�-�8~�HzZl��쯪�k�����&��Zz�{[���H�w�&��)������<\َ߳���vRƪ�<^O�UFʦ���ϲƊFd���-8�3xe9 ����S|��~�y��_x2����.��`�x�� ��Z�4��m�����8> �`���_�_�Β*�h�!r�,��]RknTn�`8뺤ٿ�Ǯ�p�k�FD�SBiPކ(,�x�+�S�j�t,Ow7�N-Of�{�5�O{띹�:��}?�=x��E˺?DF|dʷ�
���56]:Ƞ".b��h�68��`�]��xi ��Ѥ����.�{N �2"�k���ި���t��ev���
	�QS�dH�����2�A��dn����M֭/ࢬz|A����N���=��e�Ӡ�
|�5I�ә��l���f�+;>X��W���(�i��ӂ�t h���}ۘUJ�:w�R�ǽ��K�������X��}K�`G��Qzq����!�����4�����3-���sJt;��"*՘���[^�JR�w_ȍ[d��D��Y���W#���[��c9݌/[��N�x��`\�xB�k�e��q6Ӧ���}�`�BԈ�*�F�Z9|�f��㹀û[�Z`/�ժ�B�a>���t�:�K�]me�d�i�$U0E\!t䀜���p{����v���tZ���c������!LI���+�))s9V�������!�0��>y����Dj�OCwՂ�����$���^Ƀ�[M����F�&|i�;.0~��� �O��l�Wu�'�J����p���f׍i�0�b7��1H�C�gPO�w]�����/q���k�������4E��S�.��@�k�3���;K�g�|��DrhL]�w�I�5�`��.rZ��@��^�=���b<i-�A{=������J$^�g�����L�����Ub�E���ac���R��H� 7�>o�-�0�nӄ�H�~�	�L6�}��Y�3��EQ�p!��L�'�
��u�0MM�N䈵5̳{ق6��Wޙ��s�^��o�>4��X�S���î��r:���d�G��qvP��i
Y%��A���&E��Sk{�z�C�	o�r��A��������(����M�����Z���(�P�咰()�?U�Oڿ��rL�%��q�D��u���n?}A��X���_Z�FL�^�%��?`�Xਵ��-�Ğ楣�q���G����^�=; ��%��#���A?d�rIoc@�����t���1,�o��(0- s�8�n_%����c$jH�?�t�A1��@������!'2�M�+����V���/�"!�!i������e�a06N��u�}�3��Zb������a��ҙ�u�}A*�J�4�@Y��7�AS�؄}�(:0H��2�>���{&�7,i7�M{�o��qU���ű�SI��x��
r6����=�}�=/��_��	����u*�&�X��W�9�>�=�-twb�/d�@KT��[����Q�*���
>o�f��X�T�F_�*�ҦV���Jp�fF�)[�o:e�v�7�0�|��q�GT�/_���e"�
�t�Q��UI��$U~�(j���;� ��K��cS�dj��7�]\"u[t���g�����-��}(�]gւY��<n������-�G�a8B7��B�[��ܘx�e7AF�C��-�oQ�CX
\*q��	0p�V�y����Ǧ�<
�K����]�_���"�y����l�<�������f�!��'��+�mvpF�i��I4O�,�!1�%�\g�AH������,N��pH��G�z��',p�_&����E��L�N���c�cO`>vp�GQ����p��H�Mh�0a�����-P���*v��n���{��-YznS����5�r�]��z1"�����f	U�����]�)��p�u+��4*m)f�	���g����)�톇wlx�^B�o�~�zio�r���v���'����mj� '����9�[���YT��!�O�����C��4���#~�� ��B3�upWbD>���e�H�1��3��0C-����xz޺!����*rầ�~�$����:C����		O��Hd���yŏ�*��q:zP%w���*�4�5���҃gF�"Z���'� ��H�e_3��D��@voɟ^C&;t�G��_:aS���aq��al92`�OJ���$a"���B�g6�[E$Ա����tP?'��tdp�p�4�-{����)�K���`�5�5|�l�]���$�M����6Z��ҫ�ǐ搏مpA��T�8�����.�y;X(���}sH��T���{���-F�w�[-G���!����o�Q֫�C�QA"��������q�6�y�W�<��$]nV�dY-�V��O����h>���|���`���54l: �1=TA��^����fWY���[����������I%z���!aB��Z����!ӱ�����,��]���1c2߆И���!O�%?.熊�vP��s(�����������������M�,M8�)4�I|Fq�|���I���g"&
��p�L±���E�j�E*�WXfU~�_�����Ĺq������Φ���z��~9/'��$"�P�u�$��! k�)TΥS�Vt��~��뎬�\l���U�_. dLX������d}Ĕ�����N�5e�Ȉwe�ݚ Ga(x�x��������zg![GѢWO���_7�W�,�X�"�Y�N�ф�N�A$��;��8(>��&��d]�-�󽆶uqp`�]h������B�U��
]�V~�5%o���&lb<�',T��Zc�zD��te�����m��p�Z:EM㰔���/.�pD}V-X,*I]�����ѥ�EhEkH�@���P}ث�!�r���qN+;����(�����A<)46�h�A�/��4_�⛭��ŏLk�jv���hT��E$\��w����^%:�����:F�����ɟ�߿��o��MQq���c�����r�ZB�*�$��7ЉFT��Z�KM���?Q�K����I����2*�/`Z#�濔e�>s�9|vJ{���i�U�5�GJ޷sR�5!��ցYrKͷ2�!�S.�f�E�D�v��D���pg�5�)�U�+��*j�����5�A杀���1�8�ͬ���_Q��Jw/�#d\p�I(E �:�u��D�ԠӍxY�$_c�诙����@��ha����y�s9���F㓝i�p�GJ�x�q�*I�b"�w5���6	�5�r|���CA�%W@��]�Ky�R�:�<S����B��(�W�[��'D79��\�����A���������dpE^�<�F�ȹ�B�*��1�������5�4�]������OWdz:6��m�	��[��{��|�T�k��쵗�D�>\�7Pm��㙤5��/�7��A��(�#�Ƿ$6��ƷGz��߳r�^�P��ks�9N;F��# �=`�y�V	6�q-G�����shf+����l ��:-{z�ȥ�u�� �f�r�"�if�򘈲��@B(�ъA�� h��\��ض��?�l�N��k�i��S�o��vtdҟ�MH.�9*�r_����	�T�c'O�g`�>��q��b��sXq���Ʉh,�o��x�b#�nj��(o���,h��x�| ;��qq�Lr/���o�FUkO�>�ki�Z��4��歁,�q����=Ɋ��p�33�nQ; p�|Z�&�~��R��=�̢DTt�A��zj����UYxBC�Y�g�of���7�=x�m5,��?�@O��#Wk��4�@�1�n�l�I�^�n�s"�>�H�$�e�tڔ#zo�	41�U)�d}x���go�d]�'�~ߧj!�J��ҏx<z��f*��������8�?�=���о�d\�D�5�(m\�m�oSM�'���L臆���ab�z-�R��N����}�Иw�P�-%���v�cŜ����QA2m�Tx�<
/dQA%�|y�$q��bd�n$�w��P~�����N%~XN��'a7�������5���o�*{4�JiF����=���Յ���Ra{�C��q�Y�Y1�i��>F4��K�XŁm���V!�Y�u�����hq�e���8�q�W(K1��J"q螊 �%Ժ3pu�>r�k]��;�>��e�O�ˑq6�����Hy0L;����)"���u$U�V�:���i�|��7a_ �=���uE��FT_[���`��C�v�q���3u
z�H��R�'��3�S�'�[G�D�)�l���Rus���+�Y.���Z^�}��{������%��@����9�l�{İu=I����ALKA��r��S05
����FA�W�&��I��N��Bn����O[/}d��"�J<�������O��D@/c|q��ڦ)_3�f��T��䀺th�c5�E1�r�q7�޹B��,gp������
<E=i�o0��Ӗ|YA7�Lfo_���p�P���Q���d7�o�k�zϫp��q�bA,�]��þ��|����������D 	C�;��;gO�O.�}��A�&V.A.F<�2�A�� ��G����:D�x����c���>�WU�t%~�ͽGK!H�������ݘ�����cc���Rg��-��!����nS�HvA'EɾG�i��5��?����4��$�{���h�y�z[��*8�j���J�K�FQI ��G^��L�_	�����y.� ����2Q����A�u��F�*�N�-��x�-ut��� a��ͮ�bi��g�~��gP��<ʮ�_���=gy��>oY6�ӚQ�b��i��x�w���v��aW��mz�x����O�%�V���h.��zt��W"���;CO6*1�/PjK��ժ@t�Tʏ����Ғ�a�eC 9N��<a�H%����X(��)+��� ��@�L�sN��Ek��pI�U/1)�z�ZJ57�I��eP�$� e�pf�V��~kL�G�{�N�j���q�qǁ�Lz^�Y���=SvFf�&aV���5R�AIdu�nO7b7��dB��T!$�d���6##���$`	�!��_��B�t�H�;|�����
�.D�.ʈr)]B��}|�ӊcW��]����$���W�w�-+�A�ȏ��,f�x�E�����#���5�x��0j-���ԨVs��^���p_�$t�~�裂�Vמ�����q�o{7�5����+���l8�]�E{Z�q�H��	�Bh�"���d���~W�Lx��Ҷ/��Ǖ�P6Ts4�K ^ذ�w,���'��)x��@�+;�״Xas`R�z]�Ez�;HW��J�{P8�gS�=|Ӌ��y��W��~�PaIQӂ/1    ���� ����i�6��g�    YZ