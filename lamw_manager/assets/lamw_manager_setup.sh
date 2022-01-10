#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1414004621"
MD5="36634de99afd808d7fca9200d2f8085e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24300"
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
	echo Uncompressed size: 172 KB
	echo Compression: xz
	echo Date of packaging: Sun Jan  9 21:14:51 -03 2022
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
	echo OLDUSIZE=172
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
	MS_Printf "About to extract 172 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 172; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (172 KB)" >&2
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
�7zXZ  �ִF !   �X����^�] �}��1Dd]����P�t�D�%��Y�g ^�T�B���?�/}�a�$$�����F��6��q}�uyړ=�q�*8�Y�!�8n����s�`�suw_H�s�	�if)d �}��c`�:W�������d�h��%6�H3�z�i���Ҹ���`�����{�k[h�Ko�oܚGS�;�skDCK7�t�4�9��l���R�A�q�}����o8�4��.�)v�k�n�;!�?��(��-�����<�zX�U�	�*y#��4�"`�Q*�E��U��ґi?+��*"lz-�u���l�K}�0�v�`��R"XTQ�?&	t|˳��-�?/�}r7��z���sS��I�sUl�\%�J�D��b���I��a��t����^�����װf�@�|�;���1FͼY����\N'|�y�6�Ub�������bc7���F߫n'Hn�dN�Ij{��U����T)=E}"L����H��n����3#���q~��EO�U�C��h����i�(=l��g�lA�%&[�4��C���=-w��'�s1��z@�]S�
���V���𾢂&�R��YoQʍ�j�w�j �-+N�Y3�H7�_��%(d����
�j�����Gb����-SJGa�K��S��[J��FK���ݶ�� �W�c�H����y�k�=�m=�,0��{�8�U~������Mg�?ȣ���.��P���$C�?������-bw��]��(m�7�έ��,'����۾��5$�$~���DH�>���q��շ����G1�-L4
���E�:���C��4C�(H�<V5��$�)�kV��(�т��D�	ar�Դ����TevU��ہ)��RC���GR9���~,@��+���T�@���c��9�����t������{k��Ƕ@C�˔p�}|\�vf?I�67*�~��#�c)����0�LϽ��7�����^�|+�4Y^�^�Sq7����Ċ��2 ;�F~�:u?1r��o��ԃ��b.�^~�m�@��!Ev�e��ǵ��Ñ8����2\��AY^G^Pr��� eZ���!'B�� �}9�x)䃰N��$7����x-�	 Z�w�V��q@�E�?��1��l8�)%c��XoRm@y@����>��Y��
���)��B���Ɖ�-�Ҡ:'|�J��μڐ�)�8��ܴZ����\���js%�?w�;����Y$/Tx��NʍK�#U�nTc:7]1�-�vϴj�N���M�W'��oj�a�T�A(R)�vI9X(���㙯�g�PdFKP�p��
3�C�f��A��V�WC��:�g&(��2}W6�6\�`���+��G����;Bb��Bs��]��Gڡ�l�8zj����`��S�н� ��)�������h��Y�a9�����\:&H���&�p����e��0��SЄ����C���+�{	�����6l?!ū�y�`�0X��?F}{��ri���?��I� ={�T5�l�� ���C:�c��7U�M��Mn�`�j�c�2%RQ��A�f2Q<��x̉~�q�cQ3���m��w�_��-�[���/���v�/�,�v���ZBfc�%l�:���P�Xo�֥�D9t���ؒidy��u|�kI�����}�7\6��L�2
e���1��eFxَ*ҧ����J�	v�~ZGc��U�$�+��;\UiZ���/���^~>�u��~p���z�𾣻�~���A��1����l��u�>{�����{T��ﰑ���N�ދ���ə	�o���2屒��L\x����9�r|��Z���Jz�2�<��|(��Ղ4EM2�W�Ot����Ucʾ7/�|i#yȮ�T6�!-�a -�b�\Q�ro`���M+{�9�ݥM.�,+O��*:Je�}!�׳�GޛҾ)u<�[���>�iHIH7Q�i�ˏ�f������������0�=Ս�mޑcjq���>���Lp�
��#��߇�l#Rԡ���7O�آ2S�d����1�ёJM��T��b髋3|N*�L/��ן�q@���;���u����k�}�ˏ����\�?�_ ��x���#U��L�׹l�qujk�B���d�c/���vD���������<9}�\�\&3��u��������XSʍ5M�qjٰa�JV�t���x~#�p�H��*F�DE�*i�(wbq��o��0q᝟��ݦ�ۤ�)���U}O��%͎�D�I���M��PKWأN��Mg�gq+���n��D�GҦ�/鴹XeU�CwB� 1�J�}��}U�c�!�g\(�"%[P��-�p���Ld�G�7у7Hv8	^oxͅ`I#��i�V���?}<�Jo7a�ը��1��-i[1��v�p�� X�S������6"��z����SΤ�ޜ�8c����~'����G�de��B�a�|(�fP6m����7��^7<Ax�Z�Lx�/1a����F� �u��nH����37�-8=�q5C�Z���Ez?,K��W����qC� �VE��!�� ,�u��3������Ek��8�}��L��?\�>?�|�H�Y>�@�UsZX0�O7�a-�j�2���uR��3�;���i�ؠ�j�YL��Mr��)i���/��
�Q�$ō��3�����&��9�/����@^z0�"��2~ZZDܽ����
t��I,U��	h���n��
����&�ݎ�YҔ�hK8#_{���V��i�\ �$����|}��ŗ��L��S���A��>2#��.��hvŲ�m�˄����^��X$F/�Q`=�Ö��g<��9��+��F�y�����*N��/��>�x��H;G��/�٩���h��$<p�!�N�dF��xM󗮓�/OߐLa5L��ꏀ6g�����6I�A���g.L�Fv� 8��}��P�a^�ȓ��3@݊��4UA����DF�� �2X�T,�D��"���7beM ����l(,۔�o	q�RQc��M��;Cbe6�ӲtS�{���ʑ�-e�|�T�Y���JlId�X�������j[��p	p$�-�8���˄��>���de�mp@|���r�.k!4e�y6��Q���'E\����"��� ^
�
xO�;vbS���g�h��w�+TR�Z.�e_�B�;�*��Oƫ,w� 祰.� ��=�>N/a�R��:���ڧab�lG�uK۰�YڠB-����i!�����V	��>����X�{�,�]�Mܣ5o6�L�]ǳ{�dbط��a�+�y���`��%<��
4`YA���r�O�׽�Z���A��2�K��`Q�P��xcޘ=۫��\ބ��~�?�z�Um;�M�̳b>BVm�/�d�ϐ"��܇g;��*	��o;����~����l�tJNp/Vq*/�h�y��6�nRC����,�&E�T���k��.���FX���w�_Pl�ܵ~������c��;�c;m�)g�#����ƈ���֠�#�Twz���ӎ�{_�_�-t.#%i%��B��f�ܲ2��iR������|��fh�,���օ�%�����dTG��4[�ݙ��0��@������P62.R�b�-������(Lm7 G�E�]�Z�:�c;5�V�G~�G���Ҍ�,aA�� ���MϜ�nplX_��⡁�@���{�a�a+/����	lKfi��02�=��Ym�e����5���Dǜ ?	�Y��{)W����} ���.z�a��: %���*�S:�]'��!��}�X�;�֤A��Ґ��hfF"��~˃-m~� �H�_���]�q<�'\����9÷�<�D��3��6?9�B�e�I��~d�9�����YD�@BpT���X�A�9r�m�\�ۄS^��=�� ��ȹ3q�>I�s��n��"D�5�/�)$z$��-L����ݗi�@I�n��߰�qNA�2�^Ubx���
�%�@ɚK�g�hIa:M��/�7�ϖ�u!��m���G�4*��y;�^��Nl��.�����8�%bE4gY�Fs[T�:~��n8�v��>�|�ϙ�S�+2ݥ�T^;HOB�>@%������|:WR�!(��C���(Ax;hb���V����{w��*��G����e�b.��i���?t�3`I
���*���&�A���
3;�x!Wv�a��V<���
�Rس�+d���Z�q���L�c���V� ���frW��0=���=�K5�9��uj�8!�f*1�H���k���3�]@��M{TB 
JMq)��.��b{(��d�R��S��
h�|��|bGٷ4w��O�z�A]���|ݝ@��}":q�E{��h;y��{ n�b��Y���+Qy�� NI��ۡ]�|8�������0�.F�:)�Y���'��
�l���c��0g���ᣭ�٩�P��2�$gͫ�Bۦ��6���P�m�~�o"R7|h@d����w��ų�Oq���VTn�ZC'���|�R2�c"��+�k��2;|
 �9ujI��w�ǻ��/h��-hЮ�Q�Q�2��zzvS؏��XR]G+Z-�!X4������
������9��U���J�A{�n1v� ��?(���GAɝ��%P�:#�����V�"lp�f�vͅ�&\�-�*�7@��IZ{����Q��lU瞸R�I�kzU�{�o�� <?S	���<�"��8_]1`zR�1˕�4ds��ɻ����H�P�9�[�����N1��g��!G��k�g�8�9K|8a�o�F�j>�f{�r�u�p�v��CJ�p�0�Be�Ҏ&�W��dZ~���N�v�1N�~=���oʉ�5Vg�I?����W۔<�f���Q�L�9���L�����������7�Nh7���N40�q�PjF���bK���^���o�������	����F����B�e�Z���+�hz4">����a�Ty!�~�է�p��@L�'���18��w���N峽h��C��aF���&J��˓|��x�}��uJA��3Mz�@�� �h���Y:u���Hp�SBкIjյ��v�-OHD� �����i��e���^wJ��y�/!�D��x`Ym'�����F�np#��TGi���3R��(a\DY*P�k�N�j�MG�ό)g���ɴ_�+�5���-����F*jCDa��wC+Qd���
�Ӫ��R�;ƈ~�I���Yi`l�ɮ��Ю@�
DˀN%9��g�����+w�;އ�Ma㖣}���)%��Ƀs�����`� ѻc*_@e��k`lt�ߕ�e�DǔE��!DNA�%΀��T�A�5b��n-7�:.�8��7*�NXc��O��M�Z�Ra���D襨CK�e�`V_��0���$�۱�⋥V�~*��5�"�U �i�!���v`�b�V�G& �`<�f�Ȱ=�G�wu���� -��+�`���RCaY��]Ҝf�n���'�8t���h�s��`$�YK�-|_�@r#�J�)L=38`���	4�W S5 ��ڨ����ҳ9��)xzd�&@y!��h�c�l�T,P�bV�����vm7�/�pn�,���*���daޮ��`���p�m?�ϕ��Djwrw�`I ԟ�����Ֆ��R�y}� �>6sQoF���R]�s��?��Z
�K�2�ŐZ
6 {Y�=���;\�^l��D��i�c�����<������BFU.~0�p(�$)�T��7]Z����P{8�d��bct��[������2�S�[x�bۄ��wK��u���C+��S���-�i����Ƀ����A��%$�r���Vb�;|���P�<0����E��& {�ڜ~��:�����X�H[:���-4�ҴN���b�_�Yt��AӇk,��g�΋6J�yYp�t		b� 0�Z�O	�/ߤ��E*�V�Vos� �S��G��ҳ9��XN�o���Ƙ�#Vx��P��9�������.VY�Qh�~�J��o0��������8�*R� >T�2ݬ�*`]��):s6�R�M\d�:�O��@Ƚ�Ė�?.?�^��K9N膛�N��[j�5P��~٨�������~�F�ɍM�����8vU�2��h�#�<8.��?�c��U" �Q^P����nr��O�CV?�I%�>�w����4~Y��Ot�N�q���ĕF))��B��10�W��H�vu�Ӱ���"͕� C���+��?Yi=�Ip�o��k�R���_��e'�:c��h���LW��!9���nb2ss\E1�c������BkK��,�?��357G!D��4T��&�	-�M�h������(6���[W��8h�<$ qA@#����\��z�p [�R����JFS2������O����1� )���dz���ˡ�˅[:�M��
>���� َ������8��J��>@Ko�@�4jeӫ��	����-{��m9��¥��2y1�O�fF<1�з��?O2u�|�s`$�<.m�Z趭i��=�4;�'M��$酃nePc�Y\���l�e�Y��z�?�#Z|�VE 7B�X�W>#�V��0�x}�J�*dl�R��kw7KeT��81�(;0ko�������Fh�p��?J�U�"Gt�G�q��K�Q^U�:ASn0�󃊩e1��2�VC�ϥ
"�b���GY��U������7E]E�X:�`����֧J��
�JN/i�R���ȯ�^��2e��͝7�)x���L�Q�Z`�	3��.�������b-�@����j�mw����<zǽZ�Sd��l<@�O�ɨ7����0n�a��;��hk�]O�l���H�(�H��9'J��0��}Z*��%U�?\�Y
>;M�������e��kڶ��GE���Xi���0�,�D��|�� aC{�^Ł�82]o(�vo������w�ft�[�����y�i �.������4���+� y�Wh�1�;��T��pzK��䝢�H	0�1�A�mw������u	�~*p䟉�^;���l�F�.����Ӧ#�`�U	%��>�o���X�Z4W~��xK�q�	�T��`I�2-���BǪ�`��t�,��U�ٴ8�*�o ��:{a��U������xG�7By�~qA�G�[��h�^� �?"��5�hE
��2�#~�T�H�D
�'cϟ�?jh1�����`��M����p�(n\N�b4�0;��f��rsA[j��o�	A0)z]��Kp��@�Y��t�"�=I�o�*s�}�'^JA���&@]��_�z���*��vM�篖#������O����ѡ� 0�������XKiK�|�M����IaG��ֵi�0����AaA��OE�<���Zy����2��6���!qLa����<��lT�P6fx4m59�3��!�>k���*��Iuc~��j�A<]ki��4���]�\����t<�3���A���B��Y�H8��ۭ���/�4���I.j�����
|�VN_]&�3��t�R} t���6���/��Yq?�����e�k�V�=}������� �D!h4�,�Đ<�0��s�|Y�w5��:��/7�Sg'�R��@ŀ��`}����=�M=?U�@l�Z�l Ql**�E�r��(�<���d��Ik�B��Ł���:��0��p��S��WF���=<�,6M*,e2b�'^:Q�Oz��F��Z�4�deO���"���i����!E�|��XLL�1�0�<R���?�E��;r}�����A��%?̦r�B�R���Q�5���(�|��q9*x�w�@=���rc��/e�ճ�m�� ��E��ƽ�+�ښ��X�]�pDP�g�p.G����L����#����v~�WQ����	�?����,���2_�_�m��!+An�I��	��[�?{Ȝ^y��]5w�`�4�*�� ����5V�_����C�L񶾿�$��i���n����,20}ȩvfL�K���������!VF�V����>�Zѳ�G��b�]4e��
���M��u��s�x���V���1���)���+S��	�A�|BF���\�>M��3�F2��d_;�u��l����h��^H�to�>���l%`�ed�{z�}#����&ݚ��Zl����;
��៪�6)����������q�����m�[`���ws9�#�x�,�Nu!4x���������e�[7U�> ���c7���%dN�Ŷl�ùc�Q�!:	6U��՜���O�]K��"��w��ȮHtI���ŏ���~�=�a�s:���'Q6L�/����J�2c�?s{G:!/(��C��4�O�4j��_P��A�:��1a����C��L��z^���c�cE �ZD� ����H�5T�0��/{����H?�^Ż�#��|�	D�Co,�)h����x]o{ut��9���ٞ��zp�xV%%�U��,�-Jߔ��}�;�H\��b����U���� ���-r��@�7�I35[;�V�O`�(��]���?�q��� \kQb<��=,�c�[;��Q{{��Z.�����2Qj��1׹<@��6�z�mI�;�&���3%P�ZH��P�ն-��/9���X�����$B��s�¯�֩���)�N�fG�5��U傘��g}���8�r�!_�����Ĵ�y�.;��F�Ѵ Y�hs%�>`��H5�������o5�z2P�V�Rס�r�2S�6�E�KU����E2���F/��M�8��}*�������b�n��;/(�i�c~`��{�i�t�k�%�S��Vm<�`��Zpo�o0���-�\��Y��ss><[��s���pB5!���������Ht&'�����d��O�Ǘ�m7*���g��Tݛ^� mFȘXI�~,���x:�:i�x�_�
�j��0~2���yZNEU�J�ٺ0��ݼ���<ݭ���c-N���T��]�;��<O���)A�?��Q�.��N�Wf]���= ��6��t�8f3�-� �c���ˢHT�z`��]�"�z΁&X,�nU	�g�ъH=cϖ �廓��f���x�v-�(�g$��)CcF8�NvJX�}�oV��3�,�m3Js6�"��U8���h(8E���!ʟ��� ܅��i��zpk�7`�P=�h?1򱴂���wÐ�}��s�_^�CLe�6]�
I��c��1+��R����j=ݴ״+z��>���I��g�ypdvQY��d@#��2*����җ�XƘJ�;�_��k��Y8t��^���m����<����񽅫M�&:����)��=�4�����Ϋ�!��6�\|�L�H��{�嶺"�F��5��l�K�kGk��_rF��4���4��aV����56�&�~��0�O+m�0.�H��͏=�P�ao�ʛ�3{zlm����E�Q�^4���غ�:4:i�� R���r��]͸r��@-�{[N2���ƺ����|ˆk�ϒ�0�y ��F��@�*3�M�6���#�w.��p��gO���x�Q��#���r+n���q�ր�F&z]��k^�*7�\t�Y���G~����g$��*p�܋&>Q(lcM�4͸�����oB(������/v�?2e��⯼�e�m�N��H�'�_Ї����]�{�+L��P̩pt�.�@�T�?n��},������H{Y�(��9�4��;*d9��?���a=�J|lK ��u(�M����,�R��Ǡ���Ŷ��U�:�<h4���{�h>�O@�O��ub�/�� �b}V-+�P�M�M�ߡJ{Υ�-��q��8;0�isd��H���5����}����]i`�ה��/'.�����kB��k�;�B��t�ʟ���3�`�FUt�B;�Z�I��Z\ú���/"�n����M̈́��T�%g�8�����֑x�'O�rd���H����.�O��#~�濁�%��֥�����(�R0*y����]��{,���b9�~P�cm���Э�}U�J���K�+mO#�?S�����6��ܞ���Rz8�V ���^�ww� ���S��F��bzo����l���(;��J,�	%�+W���{�s�/4�����YHX���Yx��=Sl}��b֔) s	;nȤC�t�j,��\��,�Q&	��MB�JER�K�:�5=wB%�a�r���0f�?n���YT�^�΀W��'�^���!�����M��T��hR�ݶ�`�[�*�����UD���"V��;�<�0�I�� b�6��e,�/����k�4d���؋mC	r{Ȝ,]�^�7"o��h���`�$0�Ӳ+D'-�NF������ߏ���iN�.�&ئa�#�D46y�ڞ�|Wl~ⒶsuZ!�u��f���"x��~3�I����h��E�~^ߎ\�z�Q�*I�Sn-��Wo�'�a;E,��9��~dZ-�������������B�~��Fm0Fh�����*�u�$&�$C��=x̻��U�1x5�I�*�<��[�Z�i�s���C{y�n���0�=Vo@<� ��6aS���]A&u.�&�>*���)Ȋ{��U�!&>^���I�es~�r4�@�R�1���Dj���{5W�s�6S��e`�<����l��Ԑ�*\ҥ�"t�~�`�|�\x[b{Q���?��,��&��~�|8�̵��j�Dv1�;���R*�u<>�Q^&���P�����������j���P���jVjD�2��;��=�6� ��HqL���L����S�(Rg�!��&meX���KȠ�ƍj�)P��+U�4�G�(ulQa��q*>]�tZ��O�-3���7e2�Rz�p1g�GA�W0���	��6��`�Rq���r����M�[���%5_UI|�������,�^�cڷt㭢�cjFk�P����-�d@v�@DsU�J�iE-�p~Ɋ�̩B��[��nf��G\�me�ֿ�X�{��/�W����c��D�\���>��ێw�O����&�
,n�*~1���?Jwl�sO^ ?!"/1B���Zn	�e�L��Θ V��؊��a����� ��o�ٗ-p�V �-&n:����}; :=�]B�:z!��B8� gT���᜼_\�р��`�c`|��㪝�x���yJ8��^�.	j�H �,�M�0�M���+x�S��!� 6��x{�Zr���7h�Q�Am�	�Y^b&��p��'@Ҍ��2�7��l<#m&(�մ���VJX�8���	�-��)�l~`�d�� �6�YL!�Bax�WP��4�`��6b5�[G�7y����Te"8;�u�a�V��̢�K�ҴD�;a�+��KOO���A�\�Q-�8�`X�VS����P�q����s��$��t����h6��p���a*���0�(`S50p] �ãԳ?%oIc8�y�cf���qr�����:��	F/9�H�T5��<Q�����l~���`5���4�(���}�M��d�H$�NL�Fkvn"��S��q�HD�`�J������!�U������i*d��뎏�z��}��.�g*]�+ZX�Pv���A�0�`c�|��L
��?�#z"�����R'v4x��TP.�$�R��B��+Ԭې'h�r���36˿S*d�zS���ZE+��)�`��ۚ4t���Μ�U���x��b�R�X'�R� ���J2�Ɂ���S����'mS3�pa@fyj�͚��t�!1pV��"_jN�I���e0Y�#���L��K[,�#n�,��6}�G=�K���x���Xڐ�5j���)�UOa�)�*�S���пЎ�y0�H���7,���c{��SMO_�!��e˽q͕�?�Sql3�������4	/��cu��66X�mO[��rUP�JhT4�~3H��G�(m>`Yl�)I���'����r24U�Hv�s[�o^����`����<��I�fY~���X?V�z>��H��E��L�s�n*
ʍSv{�;UW�9W�9���j�3��};��m�n;j�E��&},l�V�A�`3eO�ـ�w�]��=y����0�c���q�)P�0�h�o�j>]���	(9�!��M��:�d�&j�r����^ ������_�E�gK=@�Z^��?��e��Lz�}��GZ�V���o/�����S�ei7�T�˝=���=�2�	L���S��W�2���)�`��\��I��u����� Hj_��b��P'`�ۈgN��|��aޭ՗:#[�f�Sr��l� z^��PT	W���B{��_3�����3l�����c��+���S-�U�\���/�\>M����������;���'���+ڜ_�FK����������<���:�u7���[�e��ȷ.��+�T��d���G{�OH�N����|9 ��0z��a�~��ЛۃAҬFE�,���/iɆ-�<M�{f�P:�����~��'�q~4���E�R\tô�_js�Ɏn����`{Ȣ�ꭧ��e$LgD�Ԓh�g�O-L$5�g8�^�ܡ�?2����&I��yS�*�P���f��5�Dy�G�d`���9�q��ܔ��{����x2�S �D��s��/\թy�y�+1fZ[3d��*>\J�U�����@�Z���{=å1ϙ)���26�(\�]+X8�A�s��% �De�$�pI_r]�Wa�![�Gϫ:�+>�~DY�*�?9�I'���`Bz���3&s�=6d�U7���pW�`.{8�A�f�$��m�Q!5�ԁ<ذ2��v3�ÂZɓ6�ʵ��tԃ��D׊L|��@_��"�����W��ٜcEô\��+g�W#<�
����ǫ/]�1֑&�����!���E��a0�9aQ�h{�3;wUSir�/����h�ٞ�1�׿��c������ Zəimi^�9cXR��Vx�i2=�+��j���d���$f\����j8?����L�R/|�l((����Y����#��3>	w͢�N��a^��������z�x��V��׮A�`&�
��Z�;�Go���kB3�Jy&�R�7Y��1­;�]2|��~�J�^?@Y;^����IkE�����^}��|9����̣�l)f�v����kn�獰`C-�Į����Kϴ�B����v��-m�����&���B56��(2� ������6���cAy��jo�8�op�C'��x���B-���&ʍ��K����2	&��@N�&�?���a��o+k���̔�# J�(�@���ׁGڟ��
}9
P-A�6�	B�v,:߯�. ���R�diq㳈,����N"�d�J�����\�q���p�l�o#J�U�)� X���_��P�vǿ��Tg-���g�_����m��Ѻn�fΔ���9H0!�	�P<	,5�l��*�Q�*�^8�#|&]�j�A��y/���*l	qi%�A>	X�F��)��T�K@��W+!�y������c2�~A��/7mؘ��Ȏq�!�1՘�����Z0�ky�.X���R���!�}���#�l��`w�aw1�����
,��nǊ¨�7#v8O�Y������?VMă�O�(�7L$�$S�	izӖ�������j@���
��A��f�b��]@�R�'?�>E����6ж��dF8�c����T�	 ��7V��[4Ql�[٠���}}�Z��JI�~�٧H�·���j\��JA�l�H%c���q{9�G�Z�8�
��a�uzٻ�e�d��m+�Dq{��SE
h����-�q�q�X�8$7ʮL��s罚�T$	M��/n���	�ýIa
N��ʲ|WM�̳��-�:aS�VQ"(���t�|F�D��1?�̛i�9e�\���X�ƞ[F$e���;aœ�3�Aa��+j%8�[��	AV�ʅ{W��NA2��x�
�a2&� �Tc�#����$�G��ѬY��,�B�dR��9m��٥�P�75���,Y�U� ��9-M��I�@q��GZ�}��ﶂ�����Ē�hH� ��He;������7{D3����[�lz�������gLI���eoB������>D�ih��AUc0�2�|�Oj��>�-�1���^9H)���W���HGڑ��*I���`�xl�y[/��8z�G��o���@����x�I�[��I�n�\EZ�`?�b'�5%�Te�����42z���D��pN��G�D�`,	��Q*��pܼ����Ļ�6��Ƒ4����j~��>18*D��58QM7��E>L��!����%��~�-qHo#K�W�O'(�"ḿ�N���P�n�����n��qj�3�E]���Z!�W7�[���ϖR�9�yҤ�=]j��`��b�a�T~|���NRi�Ԫ�90�r�[wA���]��鏤H�}s�ƒ!��,U��i'�{��(,g�����$�[�<3 �H�{�I�O�Q�v^op������c���:�s#5V��P�s�'���<����2�X&y ��.����� ���gv'0���5>M/�*#���� =D����������I������@��$ܝA��p�~�z 5�0?AVټ������@���G�)�����ۨ�B�ydT"���	���oyQ�.�Г?������W�=[��`$�O�ݎ�u����(n~��*J�؍aUNX�)�u��k�4�x�C<���¾0Ds?8��+�#/&<�c��u���J�#������3,,����=s�r��f?M�p�%T�
x!H�N��$���R�����
��E'�8E���Fw3��� D�S�kWupvd��C�>���O�8�/�f�6�t�5�鰉��a^�n�Rw #&z+�D�Q�F\�Ep��k���)��Y���(J9R�dZ�H8)��ԓ����$�U2>��8�ګ��x3g���`���#%���d��Jd�P�QD,n��W�k�{�cG�CzT[W�b�:��Nfx��Rf�T���kۧ�Z�F���G��k����^����$I��~o����t�Y��}à����¦{7��u�L$aif�)W�]�R�q5Bإ�)��U��L��7	��l�/��$
�;�o�l+��6N�����5|�rR�#n��k��ј1] kH�^��$R5pyՇ��|N(Lk��H�+,�1���;�;�wegm�Ρ?	�_%ݼ�4�.�$����	��/���uʈлS�t��&s�@�n��uR<R���'ɕ�����s`{�fnhT�㔣%	Mq���ƜF�ӭ@/�=�?�H���v�;�oFb�M��~�ᵈAQ����뭾(���>��Cn9���?̈́1�{*X_�B"�����@+�$�Ľ��<��,Qd��
ʅb�36�0�Jjb��A���}t=:u�}~�^��"_�#��q�J�$|������c1������\3�Q�̌���;s59ߴ��vW{���Ū�[N�W���;Sdk�gH%3���"�v7�iu}`�y�Z�q��7ֽ�]��HPo/8�3��5[cQy��v{�44�8��Y��v�^���3D(�Y*< ήd5,���ޯ����mGd�g����kH����c�[�r�"j�#�����S�Oo�^)ox[���h&�
�)�}zV�`�B.�^U$w}1���]Z��}�?Al=�߱��'g��|�U�EB�|�]�|!�y��Q��4�C�7d���@�?���o���:ژL�;n`j�@���q�fnR-��m�Pۤ������'�=T��?h�lLe L���V���Ж��,	�5�x�̜q�H����dA�.`�x8Wb���0v�d��w�p1R6�_mn���S��:m�ݶe�=������)n�f�?n����ѷ���J�
D��&'�����'bD�b��Hһ��R���k�7�!n�\CF���Y���=�N6.Ěhˎ�����L����L��A�	��nK��]�)H>��[��V<}g)�����p�S�YXʢ�������**)#��"$�fu��ap��"7JM����"��՘ٽ�*�$Tꦓq��i7����=�.���%��"D�7���0�p��a��܏����W�<x����/��C����'L��������ץa��SN�o�
Of"n��G9�Iw��_I�[YY 
�'"w8]L;�Y���4"٢e���l�6��րu�,{8ov
_^J�j4�j}���2�d#����4�a�|��Բ��~�u��c}I�Y:�)��d��J������_�H �y�%��.h�A�[+�b�ZI�}�U;��y�}�7��o`|>ب*�)]��l��H��jUwvަb��#�w{�����>���%��
P~'����<D	�ٰ���-EU4���I*E��f��	�f�J���z���a��9u��d5Kڊ(
�����g"��4�|3'�o�d����#�S7`�j�b�����:��U��5X$ȜkJ2����3L�|�Q����M���AT�Y�	����t6��A-R�]E�C�f�D'U� �*L�� /�ڜ|��n������+>\�Mf�T���O�R��Z�E��vK����V.X7~��@�}�5?�}Z�&-q~o��y��2����^�f/B�Y_&[������sc���"�u���~��Kr;�,98���|#��!�X��E���-�B^�ya�r�j�e���[v|{�cJ��-�L�A#f�Yy]��e�d���ߺ�W�gc�P��bړ,����2�g��evR~�ڻ�h;K��xR�ݺq��>˖�TZ@�jK�(DJ�_�G�ӌ�:Rs��Ѽ��+�3�CRU_��[��yZ�}���etn��p��M���*A*���Ȁ������bB��o��QNY	�;S���t�E��7�&��kIv#���)�ƭn�"�©�Hri��F�ow\�J��HE��<4���0��X���� <���2W���[��������R6򤱈�S�1�1����'�s� ���^ҭ�O��S���?E]�&�.o $.�����u�Ӳwl��GQ��N��6�X��hﰚ����W���ʼ�<p��\׬.1/��E��T��1?�������� �v=
�WcX%:E�@o�H<,8p#C��5�����ec�u�RG�XiA���7עXG ��C�q�s>m��Ji��E4A<#��M���oNm���Q��0��9�՚u�5Sz�����U/��K�9b�PDŢ�O�Ā�x��k;ެ/�!&·� ����0/9"�U��A||�w�Uv��s�p�Y��_]Npy��s]Z9�����[��g���T;�de~9R�\�[�}Z"�-R�]��8M�8u(f.� İV����Z�����,�X	9w��i��ؐ
@	�W��Z��p�[�ALw��bG�i��^C��������[������[�KMy8���N���d@%�6�M0��A{*}d��/�a���
Q�-�{E�t�غ�B:��F��������j��H�_= �k�I;��ts̀�KOi�+��(@��K�I�nȤkcM��r���n&�w�@�
qR�5����C1�u����� /S�3�:A ��)�o��6&V���9�y�d�B��Ă�HT}ǇuKZ@��K�ّ�X������{��ϩy`��w	ð��C$_!��o��@��Bz,��q~���	#t/aIP��ucs#v���U޾fS�j�]G0�UWt��b��lJ<KK1κy��\SiS���Yw�8U$��/���f�(7�)��\7�&I�6~Wb9��ﭕ�u3$L����*�,�@*F`���s�/�z�o�3���i��٥�E��a��D��Z}֍�E�U���e�k�|��9�y�r�E�ڨ3�^��>�`D��u����ϵ��YB>����5����1����hZ���V=��6غYv+$'�#���M�<����� `��!��k�O�?�̯�8���ة���?9*������T�<��
�K�MP���?M�7����,�mj&����,'�Sy��k�܆ں)���
�T�>��\oU��>0"8h���RQ%O����ɀ%�P�Py�q���%^���iy)�f<�21Od��}��:���)"�������Ți����63}m**���H��0QVN��B�6�������+�<j�.|4��F��������f3:}6�����j��g.���f-�wN�
I!(�6T~�h�0b��`W[*@O`e�E�촨��3��R�{�:E�3x9�|�k/�J�as���W�{R����%ꆅ�Q�)�|�G���qͧ0�piK�`bz�F7���rWz���i�����4�W^��&RݩV��H �m�%��9�\86��
�=�ςp��ڲ1�c&�9�n{�'X���io�^�0���E{D�E���}�:�C�Ka���.�.Q�=�/b�,3*l����#�o�ؾ�e.ck�Y�v[�^�Ln�鍢z���YS���*�^�^�$i>#��8�5�=�֋���og�T �I2V:F���(�@ڞ�y~�>}����ֱ������w�.�`���ݒ�[�����lA5�d����w����s��l�I�����L��* Al>��K�"5�L"7������/��oѹ�ft��{�C"޽�WR�1�M������A`:����`K�y]ITa@bX����a���=ƛ�k���㧄
ӎ�v��k���;	vc���Q'��Kٚ�+�V�Q�x3�z�,�۶D,P����,��zi�5n� uN�<ʲ?l�k�u��U�pU��8�����;�~�+x���{{!|2�Y�/WGX�r�q��U�Oֻ{��T.=�]�����%ͧ<���x㡗�Q�c���+{v�A2�|k���YCA�LI�˸mwq.KA����V��>�ݍ�j���T���;�[s��z4A�M�؋ٓi��J6k�FL��1T��b�/�p�f�眧"u��6/h�A�k�zŪ���6n,��IK;�Ӄ�,�����a �cd��ߖ�]�O�a}u���g���Ҹ���QA�$uj:-�&� ���
��ҹ�Hv��4�������3n�6[=�Mʴ�E|,=�1��P��0�F��vx�;,9Y��^���A�p�5��.����Nυ��AH��Lem��O�H ���
+�Q�}[Р��!*��/�
0�Bz�\�����^���ǘ���0���L̫w����D�:}6KCɸ~7���B�M����z��)�Bb�ϟ�$�33�ūV���R�	��Ӷog�M�ML>�Y�6 ���)(��|�`�����T�C��7et�����N��b���a��e�d�$ׇ<%ދ,��	���ȸ�Y��l��o�S���E1Q阭U9n��`��ҳ=�?�!wɵ�O("��5,�|��.�"BW�l�U�P��\h���%Y��ǜS�멤�O���TK�M@��!�8�ɂrE,��z�ъvB��ja}��>!��O$��M��E���;ނ>��8�Q����-q�ʸ�M�����Dm�P�����|�9w!��B�Y��O����p�&�s�p �Ti�[P�<x3��Z�[�?�3A~�-߳费��fLd�6����%?>���Z.�ػ�m8�,�L�Ҹ61`�|����t-���!��?�,��o��;��Xצ%Ю9�e�`��o�x�ڋs��y<E"��=��WI�q���OR5��n���n���u|Y�60 tzQ)�^G8�~�cE�f	�Fb�v����w�8��	��$$�7�o�S)�o��N)��֑�k���\�:�q@?}!��Դ������EhI��p]Ĵ���݊��9�j��;m��܌p��C�8�W�Z>0�0���*ig��[�r���]$�@dǚ�Zz��W~f��<���6�8�� ���z:��d��S*8Y4v2I�*��<��g�[�R��B��s�R����7�M�C�x�!SV�Hb��g<����Z��/;���x���'����?��5� ��pU��!����p�O.iW�.�c�wR-�$���pO괅�H ��p�[+<�8%ް=N�*����+�_epr2�^3�a��T�ۓ��o�TY����mn]��� ư�`!��?�(��
ɡ���d�}�]�]C
���Su=���o���ա���⠽>d�]E	��J�5�׮0��qM �Εl$m��ߖM�����|Y]�Jm�� �y�F��@�TT�em��>5�q����B;�[ #�zJ�ss�������ɽ'�9"����.�,�]�M�%��{����jD�H�:�6���zS���_�Fmw���?	��,����OR<���K�E�w<��c^�F�����t<'&�Lw"U�U{��9��
"6���7���+�d��J�2o�w�4�CE�ʀA*%�P:��f�lR�lT�t�:�ӈ�G��j'�%�JN~S��_0��u�/��YS_�x,����X�9�2>��E
�t.lg�  ۍ8t��Q@z��	A�b5�I:��)nJY"�W9�
���X���!�e&� ۹C\	��%���c�FQ�n*�a<�CO���\xJ����y���h��[��8�'�d�j.L�n�3AD��.� �� �'�hZ �G�wrT.���M s0>N9@�IS\��.�E��A$��~�Ӫk�!
�Z�q��d��!�v=���/�x�Y9<6C�`����p�̋B��0c���[�r74��B�ć3�ڝ��v?�d�BS���Z'�M�E�3�+��&#�}�ŖdF���QF���kT)������B[[� R�Q�{NZ=\��!O���н���	����!t洷����gx������l���gnF��%ca_{����.��!r�u���=624Y^98��E��/Z_q�;�h���hs4�V�y�N�$q�����|:��;�,C�ߐ��,r�~�n�E9��Q�<K��-�%!O2폆@h�3oQ<ʍAwk��hc�ݱ,e�=��U��Oצ�Sx]��l�^�4@>jQmgi3cn�ǩ1����s�$0t8C*�Ԑ�e�L���e�n?�M�Iǽ­�O]p��X�EH�0�-	{�F�9���n<Mw�dG��L��xbP'�n��I��ʷ�,��xYI�Cjg5	��z�P�  3|�gng��I��Q��z��$V�-9ԗ��i���#����.W���'{H歉���b�ՇgSQ0��*�̰������E@U�L�֢_S+�s)ʡc����C`"9�"�a�Wxݧ�!������cw�|��CH����j�7�6"�����c�9<�i��0�r�Q�Tj���h������(�t�g��Y��4�����G�ml%�kP��j�Q|��jk�􁲑� ��EZ�������e_�nG\+8JU 8J�Q�tU�4Z��O}��L�;�ōE�)o�em2k	F{������-W�h�Jn
�%iF�eJ���C�P�H�Nꀉ��p�/+�ݎ�A?�EckЬ}޲�5=77�� Ϳ��|@xu�B�w�^�GPw����o�b'�ʴ4��i���$<����� G��J�y���|C�./ߺ��MG.V�2s����@�Ȝ�� ��Z ��jFm��V�Wd�})�c�������Qm~�C�2tWcJ�A��Mx��x��A�l�D�)E��LD���ʐ�VSXcv�	��ż@eI-^����(:"�Y��P.�&{��8�(J0����1��c�M�t� ��y���b�\Ȼ�k�UZP�1}��#�ʊ�x��������4O��N8�y;��p���h�F�o��Fq U�S��5o(���Hqq�| B= 8WnAQb7��?5�7�<=����;��,%w]Ό�iUMŦ���$-˴���>�X+Ӻ�w�)cg��JE~�$~���,µ}v��8k�5���hZZE8� � 4ͦ��Ik��]C��[� &�Y�LD8�a���(���I.��іP`g|s�\�}���ׄ��ȕ�-���-�P���3�D�6�e'H�s��{A~C�+�!�e:G��Q�QG��T/L�ht&���K�i��4ݪt�z����ۚ��mт�-cO󼕎�l������x_�L�����ٸ.�I�#"HO�~�[G�!�[��5(�o���]IǼNh�$m+oK�
�8�r9�ʩ��9}������7&\��1�Ѳ��?R�*7���t쎢�KUA�|	i ��z��S��Mc1���o�r�^��>�N�L�n��=҇f�9�?��[4[l*tG��K����"��3$qHAӶ��vp:,$��t�S��'���a�9�>�sn��8��p*_�>����ի]���9��ZJ\���I�2)��G�5��E�W�L���7a}�~6�6F{)�j3K�5­�r.��0}�����ݏ��))��!�vH��2��h��t�/�hؿ�f�,����#� ��zT�8�bՎ
�nM�0�q��������IA�a=�;%�Ϝ�R��YM�kE�I�?V�9�cC�P�k�n��;%NN *�}�:9������d�)��G��ϯ��w�%;�NL���"-�h2�|t��>3(J�^���r*�aj��Ɇ���O�#ޖ?����М,m�䠘,O�A��죀; �6���x��z��G�W���O?�)\�p�
C����TfEM�T�^�P�;��6G�j�R��޸�b�Y#�ۻ"�|�\#�.����#�r	����L�S���dNu[4�$�T��~�=*� ���$�>�m�}���;�E)F�k���UGso@v�y������M+P�+�ـ��Æ�a�O��Y� ]��ms� š검.����ED(�:��ʧkĠ3Զ:�7�F��d�T?*,ć����ԯT�i�*��R�M���]�;�)���"�K+X�2��-�S�5o�[td*f��	����%�f�9�\YS�tM�N���a����a����[[�O�5�r���m�Z�,�-�����%2��sկ�
(k���s��Z|L��;�8X�lwQv����ymp�]��ڌ�G�'��J�����w�"Ά���6� �g�������'���3�Pd�y�B�{�d`���}�l�N�P�̉�;8�^�b�g�6�{ֽ(a�QF���IOV��6D����hM.�k�yL��B��ub��Z�)�U%� �'/ �"������*��߫��|���09�!s��X� �����Ur�s���?�	�FQ���k4`�9�O��-D�
E`��>=i��][���!)����3���顫�)�J��]�ܒM�2P	�.�)�0e���&��~��]A��`������*�\���o.���i��Ib�!��N�9����2>n�k�:rڙq�߷W�����#4��-Y�X�(J�	�rp\RO�s$\��d�xź_���'��P.�@�3&��s'v��r`� ��G[X]�܆���ps�-�FF��LY�3Β��G����F��_�y���_2�[��sV�p���i����{eQ��\)k��_�n;*,.P����c��zG�4Yx�@��4��R�a@c{�>`#���_ �T^�)���X}��\�'"��1�{�_��5�7re���A���84T�i#Pc�0��
�1�f�3��4
�k�Ǿ�ga6t�.Z��-��(He�O����=~�(J�2���&e�|���ϼ�Ă��pĪX�/����e�Z�Le��~b�񴽊�m�Q�w�Z�!��]��w�L��K��j���qwρ���`M��	]�z��+l����f  S�����nH Ƚ�����ڱ�g�    YZ