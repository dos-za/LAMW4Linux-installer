#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1930224086"
MD5="dce32910a0ed8ab80e6b6ef625898d82"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21164"
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
	echo Uncompressed size: 144 KB
	echo Compression: xz
	echo Date of packaging: Mon May 18 17:57:32 -03 2020
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
	echo OLDUSIZE=144
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
	MS_Printf "About to extract 144 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 144; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (144 KB)" >&2
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
�7zXZ  �ִF !   �X���Ri] �}��JF���.���_j��ҡv�í�&�L��a#�,�@�	r��@�2����}�}\˙���)F��U�`���M$R0��TvS�`�5	:��S�fa�.�S-/]O��5ko����QM����`���d����$�]�0�<�:���N��( a��v ���F��,���#~��W�/�O��XZ
���:x��(4*�����d���|�k.*׈}����GϷ��p�"ti���]w������{�Ϣ�;"�� G�+���7\f_���w�����D?$Z2�T���V��'ץr�����9k ��f�}*oL%�m�q��WlS������B����a�!Gp��[������@�ZK���F�dk�s���jqd+ޜ�د��=6�Ď��:��uy��`Ǻ��*%B%�X�x�d�Dt|����!�s@��J������Y���B��C���p��(HzcE��'�֪���O�K
�PD�ۑ��In�w[���7�F���"�v/. C,��3���H��%�?�K�����G6uk#��8���g���Y�m���-�i2.SE���L�d�;�ΙtFU��v����f{$]�Ee��Պ�)��D���.���/�,��8�7���^�Ggb�<�F\Z�P���]�*xM]�w�RM6�,J��_�<h�q�WT��T��Ae�\��'�S80l�w
v1o�bx�oOV�:���'��yؓ����>esW��<�A�_�ً�(�j�s�l�J��F�|�O�7�9���7(�!ꨆ��cH�ܔ�pAm]�k��4c�C�!�� �psaT5ҨIT��ât2e���ڠ;l���ઙ���d8����"T�0���	v���,��{�(ܔ;�Z�v{4_���@���;h�E�4��&�(ҹ�UH����8�I�kf�/-*���\!@��g����7�e�J�\sߵ2�[�	��,�W��N!�s�c�C�lPQ�Pp��k�͙*�q�%���%�.�!�!�X����`̓�P��J<�$����#�Ss����:�+�y��UëI6�%����b#����giMS���YZ�AX[q(���W6�R��UZ��{l$ɏ+��n󢩊xBIU�L�0@u������5휥��xD� ����[�΃J),4����G�#Tf'��~�e9��:��y�rM{/#�o���R/ۺ��Rx�3��yy�,6��/c��Y\�dq0�T>�4�W&��������g��C"/������� ��ʴW�NL`���|�h�7@��$��Z�	.�v�[(�ξ�]��1�M�Ƴ����5���K�FqM��y�� �P�C}g� ��4�T�=z�1�/�0�������������`n�[�I:9')ܹ>�
U+��:$���FZ���A���3�k���:ŏ~��U����R�{E�t!G�L�*G6��^Y2�:�$�:�iڏ�:�m�M� ��0B���� �j�A͝g���C��VI[��x��e��}�-�ڃ��a ����n�!��������go�ˎ6BT͑xi����H�x#��M!�LWlƱ���{H�n���pG<M���zF��k@�N�ۙ�u#o�2�ZiZ��w�6c����|�����8�up|����O9}Ǟ�+QX+-��\;3� ��5� Vq�iP��C�2hc�=�����?r��!Є�)*�� ��V�m"�:ʷ(m�s��@������Ղ�pHB,r�΁��D:5˓	��?�mLĠ��q���p����M4�z�^��FN�v����iE�;��v��F��V��X�1OZ&�c6�^b�*��fO��KT�%�G�&����z"�C���1&`�Xn�u�l7� /�y�0��/m�zI9��k�E�VAJ���Jq����|�ӳ�S��]���}��]�/6������4�-C{nP�~܁C�~���U��/������hA �@��Ԗ�+��;�zgP"��/%�D�`w(A/��N������Ա;�)1�f���{7>��*�G46)���Ì3�ah�U���$��)o7��U�]	CD�?v$�X���@z�!��1��{L>���"�X�(	ur�_�l;r*a�֑Y�˻��ӢW��/1�긥�:'Кal��70�DQ��T�Tt��R����XKʹg�5h,�z�Sпl�]�(�h+�Q�WX��r���ih����D;�d.'G�z�٫]s�g��Y"�:%����X���~(����T�M�C�Tx��;/��N	�{�N��w�h0e8,��t��T\
JK�Q�����C^�������~f�kvE�B�2bt���3�=�˲�0,Tjmg�r��k��8�VYc5��:3�����K.�x��o��4�~�\'�Ӷ2��z��[�@g�jD�6ɱ@K���VF�2EG��:ë?��=�_ᑀ?
���Ϻ��P�H��K��>땐������������x�(����:8�e	O���v��*�,\�#,U��К�9�A���	�9Ő��C�x���@^i���DUzxD��s����]��t�&[ޑ�*�2Ɔ�0���QP�33+�Nx}�<1���C}���Ul�;���b�ٹ��l�`^g����[8�$g!�?�Sz�$0�'��̦D�9`=q�*������
�rE�#��6);�}>����1ᒱ{���5ˡ�{��E�	>�c3n-y0I�
=Ul�00�Ep�	����~Ѵ��ljCy�7a�{�>�N{�mڽcW�Jk"�"��d;<G��`KF؞��?�g�㿽�)&�_Sov��8�����'9�4������O_�;h
�b����-�x�w���K2�z
p��D8�2;"����"Z�8; *���rܱ� P��&����S��o�oN�Q�L6��o5�o���
�J���Udsdj�1���-�;~�ߚ��\3X��ˤ���n��E�m+ �7)���@�+�ka _`�OW���73��H�Vm����2$A��5�ߎ����f��5�ۓ�p���Z~��`��{eK�yZ#��9���!Z�gy�����[� ���S�Ｘ�V_��W�Bm�1
��潐�:�/��V<�������9�EA<�<9�z~�J�3N��Xϳ@�ǳq�5\tX�Q�<<;$*?�������,�My�kR��[Q{U�m����2A�-�����gL�ŉ������U���[IN6&��5��u�Cx�S��Ph2��3�FB �S��D�%# <��1�:��K�Ғ@�a������Ѩ:��T�bq=���?9��%@xۇt���5=�X�>�zX]&��V>�{�=WL&x+-��J���`څu��0�ݍ���B[��l�]US�U*�B��߀�M��.������Ŧk�d,��sf�:�q�����΍#1(I�?#V�[�@��������;	W�O�G��yp�8���EY��H��S�����}񔛞S�/a���xeDf���(����ꔕ��d�L�, �y��'���sE���ߖ,O�l �M9��اV]�f�`����t)=\yS�KAk���g?�(��`M����e��WqN)J��<#3	��<��@�g�Y͎X����+Á3꫉���V��u�2����T�����%�j���ͦ&�����'�`2 �[@f��j|���g]��l�ft��) ������&|�u�������o�<�+\�w�ʃ$nW���9UT�ؽ��\�`GT,�0hz��Y��g�A��ݹ��R&�=�^DQ9,ϒ3j�ms��K�>�C����Xf���c3װ;_��F���	E9p�-+-��;�Y�6�)���b��U6��u�Fq�3��[V�	��y߽[2ImH�]���f���и]|���ք��C!)��7��v�"�!��=�������Ϸ��l��BUG�N���n���a�%Z>y��W��Yȍ����pD�G_�#�a����<���{%�Vu`�3?�������i/�l��]��٬�����`��KFoN���t��c)�Q�:�"���;y�wM�:y��p��,C Q��yѸ��-?�k���ݷo���hbq��.u ��'T�W_�\�]�% ��؄
խ֖4p�U!�X77ǚ���'�`���ڛ�*�mzbs_L�� �-�v�wK�rh��~k��i��v�������z*�{	F�S+"I�&��F���6�/��)�*�͢�=��y��QfZ3��-q�2���#����k�A%�L�E\������A9���?-�霡Z�˪9n<�dR*�v�������OӇ�Y8��,w�Dv �'!��0��FeLZ�.�N�ԃ*9��z�~���N����)|Z3�}��|�)������5��0��]b�`k�CC(��c�9��j#woWex<���K���f��Vٯ޳U����*4���x�4��yvCNBJ�Q좚=԰��h�~�9�>�>/?=2�Q�Nk�����G��3��M��c�{�U�֓/GfW���8c~T/���q�P����S7�����6��z�ڶU$��7����$(t���y)=�@�X��_�" 	�w��L@��g"x^�8����?�$)Xk�+�??7��J�����^�,K.+�s��Mc�����A
!��b-�jW���	�����ebu��5Q�~���B��xޫ_ka�l"��\��qZ���EPs���0O��'U�K�3��	1�S�A���S�`����5� ����s��&E{~�'�p�؇�=>p�EI����%E�e��Z��y�S6[A��!-J������?.�72z7PF�_�LT��}�ލ��]���5N�2��5(�[�Փnݴ#sD��7իx\��G�v�N`9d�HQ*�W.5��*�7��e]��*�hN "�R��xUf���P�CB��8�YD6@���Z4�)�{S������`��zkd0�{��`��z�A������NF�,���UqK�&���O`�� W����&�SR����;�G��dvبP"|J��Ɍ�����Ь`��[q��E�zK�o�ü���jU~�Wޠ�	�|$�Z�R��m6���d�."T�Z��rP�B<�#�q���C��q	�?,�I�ӵ��:h<�U����n,�.�A���#)yxO���f
��^�*��V���Զ95��ހ�ꙡ�o�s*���j:;U� �F�ϙ0:���)�'.P��G�t1Ӿ���ΆK���t�d0��(t,�˵�u�Z\h�W��{���WC�(@NF���3䔘#1>��s��S�nPD�3D���%E�4!I:d<*Qޒd��3����ommr�� �Y��KW��
R͌Ѷϙ#��Oi�9��{�.�&��o�EQn���O�3Z~ǚ�
J�S*<̌�(RnǌU\�ɤ6�5�9�>f�J�)�p�\,�s<0P�s)	���֕~�[�ma2�vZ��8O:��&��<�Vy��=Ղ����|�M\=���O��xm�`��1��L��<L���C>�!h�D}ʠ�=�9��?v��n~���\(��
Al��������I;X,����r�W*�Ί���ףp]~}H��y�y���D��g0��М��΅fu��O���+*��}+H���^ҝ�+�L8^$����`0�,u]�x�ȭ�k�L�	3ҶC��'��gf���ڳ�	މ��lYTr���9�Ša���y�1��LN�1r���˪c���L)�F��7��G�jQ׸R!�=�������ٜX����tR�1�EP2�&v�{ ��~&�8ߟr�kR����hzDy���Z���V")s�	��
���{�p������i�VY�w�5�FKC�,N�>"*�@y��ϰ�^FE�Q:�G^�%.�ތ��"$aB?�	7��{5GS��jF|YE[��ȁ0�����Hfyi�P��� ŪHِxo���6�-iLS,�: ���nY����[[C��*��_�ׁ ���ɒ���϶V,.�.�������g+�Is��sjw���%o���PɚoM���}kn��]��E4;F��y�1߈���_~m�̀*����
�Ql�2�f*�-�Y��Z���hU����^�x�'Qp�׬�$?T+��NcXO}�[���m5�)��9�l����C�yU��-"�������cYhE���[�0�=
҉r��OyS��� ��:x5dj��'�F1!Wb�U4�˻��o�D��=�Ɗ���PTh@Ne�P�NR׺���.F��Ta�9H��N�����p����t6�K��I�
�?3TϙmԸA$��ˣ������ZѓW'�zg����̅4��9�N��������^�<��dtC�����'�<�7T��I|��+��/���ܶ�:���I]ozH�-��������.�c/�I=-k�!gI�F@���k�l ��&	���������9za��/�:����d����wB��[����<���^8��� �x=�u;W@�yyE0��HK��dg�:�0cm��	ܣ3 ���!Nd���{c���1T�ǆ(Z�2?c��-aX������ ��ŵ��V�M�S�ރ\A� ��QuDI��z-�-�L��j��brݵ����HUf�����8�H�\~�d��% 1��){u�Ν�`��+A�	��}��p�w'oE�����/�,<.���.,p�O�#E����r�5ptȐW�P�|��w�  y�o�ڈV��3��d���>��lv������`�A5Bf�����`Ul$��κHb)L�N�E�)�֓�¥�?���Y T��\����MAz9m���-F"@�dĬ��y2�N�W��3V=e���݋R
*2�K�g"���S��"ΐ�����f�2���I��4�&`".��0�#ב��Sx��(�^Q>�,4LW=8:?期V���ZLv���Xeztە:��c���E�z,��
�Z�/>�X�����쳍l��!�Mf�c?>�)���N0YA��cqX�m���|�u���X�>��Y��_ 4����ԙ" ��N��=���:W�Nd�FK����aT�8v#�[;�$�Z�9{����NT�:A|�䃑��oH�jo�6HC��rο�������8�Snő�T?�2-0f���?��`���J���b�. J]��%�u��"~K8��c��hsRF;��+F�o�S�V ���.|�u"�B�k�L��v�J\wp���ԚZt~��R�-o�'�4���ы���<��;����[��?8��ɔ�_y�Y+�uҘpp(ٖj�@�D�7`I�p5`��s!ڋ�7@��DV�������X��R�;1ś��_xV��h�>��+	�K}<��@��]�\���\qu�C҄���#��3Ħ�Uv�S:��xyb�o��3�*�YZ�\����ayI�����u7~��������O6��f���|5�Z�fv
*��oƾij�P��D�5�/��Uέ�#�Dc�7q�d_cnM��9UB�)���[CX�^��/��O�yC�\$Q�F'�gc���a#^G�j���4[q�	�<�U��a��V96���)ۣ���	?�zR:�,v�d�9؋�i�@2 �0���)��(��sp�VH����$�=�krF$Ҽ� �(U�/�}�v_4c��J�`a���_�qG�5�UH$���&�ډ
�_��D��,��8P�<������EG
z(C�=�+M���c��ű(���G�2)�&R������-���?�l�f�tĵ��$��1o�XX�����J��e6���A	�R�{+����
4o���py�tլ����^�r�E��u��b�����k{�6sw�gᾁ�K~%�Z��¢��������V���a�4q>�'�(x�����ܥ�'���[��7gDbz&>��]�~�AdM�/$ߪ�j^�����)0k���z2fu��>0	D�Ԝ��S��T�䕑���U�d6W~���ʈ�n<���#,$��U�۵r/_vd�5\DP��Rϵq3,L߂�d��i#%�Y����x�c{?([ɢ���M�v. H�����B߁!�e{�Jhq���i�v�R�ѯ�@Ƭ�[�|bk�~dF��{t��9z���GY,�V��x�gY_��|�Mz9�xu�}m�Ѳ�ZZ��si�5*'�%y@�(alc�%���Kի��g��W�P&�:A�:_�u�H����=z>lO�B��yT�i2�l2��ҌV!~�wnP��)��ž�3�`2�?��Tp�{�f}/��!-y�A/�[|J���!1Ղi��$xT^�)��t�!� ��pQ1���z<�%h�� `���K�Og5r�>�Ӟ}]��D��U5�A��m��&#SMRow�Er�{��R�oj���Pr�+��#w߼c�D��V�С�yY b �;邮 e��+yi+�R���Rf�f�D��e�A���>��癳Y�ixl�$�˅=ɦ%�@�W�1����H�&r;��I��(�:7.Cb��3z;S��z���ce���{$6!�����3"odzb5�E�k�f!�+�'�OI�8Xh���Y���1'�أOޠ�l܁n,g�O5v#rEʵ�)�eH^e�@f�Vf�/�aV��K�pJu5*��A�e}w<dVd��AoX4W6=�{����U�+��`Fg,EΖ��'BhU2�r�q��!KR[��q���Pe��V�f���%FZ0O<�n��C���u�p����Z$2��[��\y�j ��V]4�f���$��L��HMt���(�ǚ��-v�>��������!ei��lY��������*Ř\Ky2���R�T�0G�I��\���|�g�ʬ�qծB�g��d�!������%�����ۧn���P��T�Z�٩���(���i�P���ҙqH�$�~�)��s�0Խ1�=���v�oFy��dϊ8�x��D�Yz�>[��ɑ/��'�Jr����& ��!���f�Ν�[��~�������L��q�|�ɟ�WD+�7s�v��T���b�`i�#*9�3�f'�^��N\]o^��N�3����GWu��4��+�p���ư��d��a����Y3i�~�)?�����cHq���C@$D�-�Q��,�$��Q��n,MK
��l�~�k������dY��ha��D�������-���륐�A���z�]�Ϣ�+2�=����ΰQ�I���2�:N��p�����ۛ��/���n@�%4�L�c��:�L3��6ش��in�u!�,�O��
TŉUfS( X��������+�`�@��S�F3a�����@qJ��}r:�h'�@��1;��YƋ�r�7 2e�dT�J����{e�ң���o���'x	��D�
6��I|^�uA(e)�
(�s�h�;
�[s��*E�	+	��4U���5�/s8�Ҽ$���&��X��9S
mq�6Y:�]d�oYx$�nzY�G�n���2�ӹ|bMs���W�́�g_Ϩl;Y\�|o�hF���<ث5�xc��"��4�lgHRR�G���t���@0����*1l��$�y�vD��纵H�q�>]D[�X8�N>k��*�p��r��.�D�%�Q�`нӅ�p��'��b�� S��]�Q����Ot��5��@y��Q6bg��ӽ+i��
�wX)L� %��#���$e��ܧ�У������X> *>p���e�<��=�gv�.�A��i���ԉ*��Ԍ侊��Q��~�J�6̏�⦸�NT�5ݵN�� �4,�2W(�6�B0g�F�r+:� QL{x��}���3�IV"�B`g"(�}����^}NUx�7��HԢ���2�ʝ�}�sFy�N/�w����ķ4ٕ�Be����Pq�v:�Ȫ�_@@Mɮ�9�u4d;��i3J}g�^�cw*�<jf3����I��7tM��5�WѳK��F���]�
��p���n�Æ�jdHI�֌>9ҷ�)EX꿱p�'m��E�O/s��د�L�&�T�T{x\=[+���P��QS�S��m�\�⌔tv+��/n��f���	n�����������)٘(�����D�i�HK&!9�ؠ�͍�hҼ�bU��m�C�������㑓J�*�Rv�DN���*ē8Vq��L��q5�k�%�MŇ��;F2
%��4e�Q��n8���P�D�o��GU���y�����5=x�Hd	��srv/�y�������e/��Y�kW��.b��b�l̸8���y�P-R���!,~�^+���6Cx,�1ͼ-���9�J|����.F��O������A��������U�wu�F=æ�Q��[�j{��q������aJ�������h�V%��4X�+ V�� ��Y�d����k%�t{�0�����ؗ����������U�(!3�,⣨�������+��K~������e���"�!�/Gk[~:�/w9�8�G�
��` ���R������B`�k�� [�[��@H7�7Ĺ�a��Qy�-Q�i��m�ߥ�{U )�%1�g���IS����@l�STج�t����p��/��}U�Dy��3����g�:"3�:�>�Ѕ��&+�C�`i����ٱ{�S��?�)J+�w���wBAu8�̲>+�Ov�&(6w[�����A`�B�ʼ�=%���B��.�'f�_���޴C�R�J�1�1�D�0�}�#O9,_���,�'���8����_E`=�%�D�m�RHgYt�9��a��&O=��{m?�X�$��A,cv7�mp�ўz�Ǆ��Ł�ʯ��S�E�w%4&I����U ��G���������:�\�6�P��Zj��A��c���~q���m��Z�˷!Q�G��>����Hh�xLɄ��Ie2�@��3�
�H�$E=�I�S��d�|,�p��r\��/�k[z��T�ֽa��/G�@���B{�.f"w�H��}���?�4�'����)��������n����&T:Ѯ%�#���@#�� =E���%�"os_Ss�ʢ%����.qS<z���W=ͯ�"Z�!���(����Z���(ڕ��������W��*�Q�������M�:��#��Z��j�[_q�����1��5�;BL���X~�&	��e�����)��&ӕF�	&�˕�R.�#>d�D��H5����>=�%	�Ϋ�,
�T�¸��i��}���<k���-]��J�v&x��B�z�-�>xM�js?����ٴ�^c����^W���#¡]5���锭X���9�#�k�?�a�6�+M,P��Z�o����ʠɶ{("x˅G��䣩jL2���J�^Moٵ�>���p/�l1oK��\]�o�k��K���q���C�n�N?	�Ê��c4�A� �t��c|���M����KI���<�u�~����_d2�#16�6L�������}Ŀq�!�a����i�n�U���iA�=R[ίʾ���\�!ٖ&�D�ȁ��	�M`T$�K�	r�H<��o����sP~��Ѣ�(9����*k��==�־d�~�o�����zʷ�^�D�_/:F:b*�t8��@I�y,U�ϐ�Pj�ON`�MTj^tvY�����|�+��a߿���}���q��h�q&�>��'�q�q����U�-+C2U��~��\�OЯ@�cҮ9�	A�f�A=�u<�K�������!]� ��9�G��{���@���۫
� �(��I ��a� ���W��F i-��L �١~�<��S�ŌO�M�;9��=�
	.�+ak��39�ɶ�Q���7���a�Ǽ%�y�)Jví���\�J�
l΍�#/n~�R����q��dI�wDF�u-����k���1�^��ӵ˝s-3��$m��ct��[�_�,P'1���Lldx*`�e�=��SZ���x�!��2`���J����)�	��A���3�e���z<]�m�#x����
Ҫ�S�9;�I U� ϓ�uÖ����&������ �h�䪉թ[����$!�+9���k��|���IMd>��5aY��U"�H�s�ek������/�cv���"��k����m��$�v�x��aݰ����W��<���Q�q�бR�v'  ����b��7,�.���]�g���r^P�U9��Z#��j�^��{-��i�+ܾ<����
x4���f&�6��@`'��?���4Os"�v����N�
F�s�q��7��X�ʳFwKb(�'�4(<�a� b�!~E������s��}�[ֽ�4<�U���8�#�]���-��w�J{*�+܆qL�`%4�_���$�x����9�]�@�R^n�"q���ɆkıM��	�Y;s!9�"Y�y�|�;��=w����[/1�߃*�)�?�M�%����-7$�I�`���8�n�p��{)��C�Q~n���;�]�{<���u&�=8�*ѧ����(�O(ڎ>�;��P�����X���%��8F�"��`D l}g!H����`:�Ĝo�k���z;- ��U���%�����~���v�Q;��T�Z�ZFxN526��N���7ҧ�<�afڼUa������x:�	GIi�f�lyR"`9���?aߚIP�N(9�|�tDfZ�φ�φ��¨j�6��Q���5��|��ULd��2w�N���y�o9x��֠˟vk}t���N�F��"� ݭ�yh�x�E/e��J¢��Cl>,>�t�ő��^>��'���R���Gް���b��ף��/[{�7��Z��Q�k����s_��Ղ���?���R�������%�ܱ4C�����]n��U#��\\i|P�|������8������]C�z�>�����۷F4�	ۊ}]�rC�pu���7¹l'�9o�9��6�
�h�%@�C$�.�@JA��Î�@���b�z�>������Bd$�ў�~��wt@�2ow\�8��Ov潦ҽ�fy1�����[mn��	f�5,���� -8�
nyG�}���e/�_��w�Sa��~�̀ǵⲾ�r�%��9yq���H"ߟ���&y�{� �|�iQJ)��0d,8�t�qa����wg��Z����(u/-���0��Sq�H��!a�3T�a{����K�R����f詢��w�B��<�1��[�HR�h�;�C�rR���\���7�m�"a���e�<���8:�p�g��
�O.�6��9�K�����7H ���:�{�2$R���������������"�T.���Q�ej�5�Or@.[#�e���NT�����X�Ө�Tj�痏��8������?���qz�9��tr���%q��d�j�[��h���0�^.��� �[�q�����1�0�����rͥ��ڬ���{h�2��'�ަ�I�=���z!j���J#���J��[��/����A��O
�9�/�A�C�o�߄�m�A�B�Ҷɹ8��5�i�{D|��<B�Ƈ~P��9R&W�S&SѾbdx:�e��Q��Ѭ��k��I�AFє�#��h'���l+���J
K^c?���s���{��S�
�W  ��^�m��9�lX��ꆣ?Ӳ/O��O(�ZOC<R���~;&��-��L�օJ�K*��Z4\HX&�x�G�ldZ�h�'�\�F`.���<�M-����0�<���$�}
�(� q���ۛ�Xg�� ��Yڋ�����F���d$���'�]�:Bţ!����G	n�x��M��[)��F9�Գ���\_ʘ8���=�(��f���"�wc���
��M�/��CY�S�s�=���Ʈ3�v\�W�Z�E ��{"���2����I�`>���Ё&"akI� �j��#4��B�F\+.3�h��g֠���uЕ�֮�D��e=0�	N�#�Au������Q�oo�w�b�j�Ns=����/^M(ze�Z$�o�o��/Y	�r����/�_q�����A��'�K�M��j�y����Ą�W�-<9Lv��H	��۩�-������4`'�z�xS>
:J1��:2�f���,��n��D��$�,T@�׾iD��`�s��ĠVêz�����«8gv�v���u�=g��Q$IQ0b�_�{����f�L^/yȳ�`��Nh���¤X�"9�_��˔o|�L��V�VX��V-���.�3���/ʑ���rmAQզg�P�����ڰ��ʴ︀�0�`?��Y&�qT��5ݕ���v������h��M�=Ѧ���U�i�F�iKtñ0�:����sS���vYq-@�0����4`�Ls)���}��MZ���u$�<��u�Ղ� nuȵPˀJ?�1��&�;���^L�}���A92�ڃl��)�㳢'���$̻�T2�L�T��KRN�Bք�L*�RtV��i+̈́��y?���w���]�^U<�d4G'"�z��^�uה��W�sw��F�mzV��܍��࿵�]�}W��2�"��JA��'"tf�2G�RL�;L��� ��U�#��e�����&Ҵ�?��4DU7��9Oz:3����?A��b��M�ރ�JZ΅��>���a�H;��p'�#��� �UR]�e�5%+S���_�t�6n����@��y�5l�n���3|��z">@`���h������n1�H�G�MV�?�[4j�L3'B�T��'N^���
5'm�6��.��>H�����]Y�j���{�w=�،ˮ�G�w}�Ƅ�{"������\�f�n��yZ8أ��U+�O��hZJwm)԰b|`�Uu����}f��؉��,�����-��U9q�y�x̉�!4<­�V?2�<�����=�_�6����v�
l@J��FF@Z��i[� �^�x>	�*�'|��[�)S����s�)c��V[��b�"�����U;���������5X����*�FD�7D�dv��\l��!<�ɿ��y�h1���˂pqƫ�z�uz�U��͛Ot_gC$%V%�|�J�a��̢��$pY ��<s"�k��;�Jm��yr�{m�d�gﺸ��s����_�˝����3��"�dD�c�K��t7Gh�cl��A>p�ce��yba�#��y�^�ė�CU� Kv�EoG~v���K�OXÆt����%t"g����t�֖���)��hڗ�TT~x?dE��H�F��#RM;;�Mۀo�H�M�x�g��O�|���c�C�&�Ң
���v�1zu�	�ڒ�����X,��ϋ; �f~�6��vX��ikQ�?��Lsf�渹����Y���,B�ZԊ�� ~�z�y���v�)���`ȗ�Si���d��fv>�h��)j�hܨT���	6PK��Mc���x���~���(>��k�S��(Gjxp�=�n����($Y�L�Jg�O�(H�ZoI�7����+���Ya!����4xUtC�QŘ���Qߊ��k	�ſ$���Aӗ�X������fAi���.7Y�k�N�X��J�����h`�Y\Ҏ�ڐpB��~�`9U��`�e7�C�Ҹ�_`�(�(��$H��[ڙ�Gn�{]�&iM6v܈}�3.���4|u�E�%7/�t.8��O�E����Q�
�\%B=��=��8����`��P�\�Č|#�\/ `A�]4q0ƙt�˹��)�'
��A����k��/��f����s�K"+���3��,��q�W+h?�۠��1�T!c����܄��ռ���s*��r�� �AR��O�pf��W�K������o!��_�f=�
vt���Ĺ��iLRPt��]⛁ymg7�!؍���=>[s���JL��	\��H2	�����B�7(
��?�Eb~�g��u�R7��i���O�G�;sFE�<mXDo�r���b��!���d�������B��"
}[F�_�A�ͨ���@�C��<���+�}mL~�.NL?��_Z'�ar��d�e����k�կY���2��-ӈ���l1��0+>tfd�P=�*�����z �{ZyC�,�"��E����N!Zxi	X$W�Q� D��Z�'��>�$F�9
'�_/�"��Hw�Q:F<��iD*� ���iD��y���INk��K5�K�Gc �W�젦ʗ�x)�(>b6�Fw����XP9ќ��>h���`�ޣ��B�a> ~XJp4��ȉE+��M5n������?�������alM���&��)�͝g�P[δ���h������:k�  �i��k������3/nB~&�#���������r~�����V��a�Uc�j{�Q���`ı<.�!��i�@>��4���F���G�v����L�)�lrƫ�QZ�^P}�Ȼa���dOփ|qu��+��;QY�Uv�^�`@�Q�'n$OT�
������u6�;���I���2H2����^��[��Ӹ��$��Y�`�&�"TU�Ki��
/i/��YBr(Iؼ�x~�.��eM��v^���ri�d#�D��'�}i��.=�!{=�e����7@ذ"�-�	X!���R�=�Ն*�n��T��~M�J2�Y�GF�"w�m:0�J۶AK8�R�y� v�H�;�9��j@�)��3�S{)�jZ���ia�����C��j
���L$X[+ǧ~��]B���Z5JU��M �DL�r�vX���՞����u�O둜�6�Zƛ��tGto�8��b��,W�,O�C�0��p�!�f�����@Msj�9�;wvZ�m��C�e�����L̼>�^np�����$F�a�b�p�+n��C�3�����J����U�e�_�����7K��QB�Y'<�d��%��X��#c��C��rZ.�����J��L5�B���}iQ�����I1�����x5!M-k�/�C#�W�¡��
c�Y���V[I�y�g�z�;�:%v���N�F��v��30�"~��db{�q����Z>:�����Y�T��2N���o\�����`��f��)+g^���L2m�g�ž��M�fQ��U�h�p�)�E.���~Ќ[<mŏ�崌��M���ج�����k�=nI��c�̅�\Һf���PP���*��|\��i���H�Ŭ�/4�!��Q�����$�����A�_~C��6�
�
��������gq�j_`e)�������V���iFv�"�;�d���Q@��_��۷gwgp9@�VҩK̤X���e��o�{e��O�O���O� �W��IC�
-#r���j�����2ƾ��G��Ձ�N��|6�G���,1NO8�a�b���2����=�Fd)��W?��I�/O�Ꙧy	.hf�P��z�%((h.������>��J�����m\C(���"�b_��� �:����&���+l�X@ܼ��N�m���*�?��h'�݆�@�C!���pڠ�⬴�� s]y�X���?M���zc�cQ��Ş�=��Rt.z-|�L��0�KA��G��L�^J�-�n��d"F�9�c��a����q�_ɬ;��$�[#��E��iBI�]��qAI�����\Й3K�49 \$��<x[�.Z���F�ՅF���Yh���l��)�I�H2��*C�Bw;m�0i��m*ñ��A����?*P('}s��=��;�Z�!�6>{����G#$,c����?x�����g8��22|"%^v
�ziN�\"�1u�Q��D�����@���%��_>q�	s�myy�6��t������SP���)2�ކ��"����T"bXXC���9D���	y�w3����//V�r� nu�Q��wu���M	Cn���O�;]�x>�u`JD��B)9PߠM����0CZ�J�z�t�M���OV9*~����o��!rD�D���	��,F}P�Ļ���j
���\$CfN��SF�xS�s�#��L�"CyudU�D��4��eqn�oge�4��t��%'L��O4��V�*�{�)7�;º�dm���%�ͥn\-H7<s�D��'Tt�S_c5j�>�������(���&Wփ+� �w�x}2pn=�� �'���U�V?��:_�(R��	���Av��c�Jֹ9R̘DD�bج^��o�8�,M�|)�x�5���ut��胶�=W�ݹ�,�ź<;�8�Q� ��[`u�>��d}$?�Lp�q܇i��z�=ͳ6<�{�d ��G��K��1���L��#֛�,w���C"�jp��Z����~y�4v{\0(y�t٦�0bQ��ϱF*R�b{(<U�|�A޸�a�0�򶪽��)�X�AT^/�%�b߿���i|�e2�'��k�uo9y��-��ɢ�F1�ϜswVbGȒDC8���R�X����%�ǯ�˩�:��M`�'Ӫ�XC>/ھ�+q���_YY���(C�Ǖ���p�/�@��o]�1�jvuu�k�=�Jn+�!ԳӁ��_����.��eK���"�?^����ca�q#��$�C���z�ѡx�����Xb��%
�J�H�cN��G��y|�Ì�X��3��: �������5I5��>Ѓ:���K�nf�4h��#�]����/P�Pjwe�����qT�=:�hZ�Lm9��N'�>g�>�%i�{H���c8'
k/��5���s/�>��#;��u��+Ӆ)0�OG�U�a����P�A�1I�Y�u�h�ن��	 j�G���ld����z��[�n��lwk�:��5���E�/Y�<�~򸎬����d��ǫɷx5��n¢�/�����RO�x��Eo8z�d����*H���R�-X��}�aI|�����t����5�Ͱ��v�����F�zoU�=�B���Hޘj[����}+��p��E�)��^��i�*B(��N��N��j�u�&�`5�F���m[z&��f?
s)_��U��_��}މg��vA,^������|AS��	�+jw"#3�r�2b;ix"mC;y�R}�y<�U���7cp-(Z^/<c�}�d�T�5�ϳ���`�W�ӟ��0$/�l˥�#:�6����n4m�_L�,��0<��������|�g�΀��n�?�N�WO٭�#�і�5r�[
��A�E��~��ʁF�O������و)�,t��2u�΃HJ�L$:��� ���xD_jh��o�[�H�U�˫!���~�&X�~2Z%��O��a�$�}�O���Ւ5��6��>��(��J��9���KMՑ��R�7���ǉ!��G$D��nA�����r�[�Q��F� �Eh��FN�5��M�[�������sô-����x̫ٗx��I�S���ol6� `O�ѿn��.j�|p��P��f�Ty��Yto}TAj�Kv��T�l�:�s��4y�D��i>d�"��ζ�yG�f�k�b3 �WL�[k����e��������~�߾�C�I�|*Gτ)R��K��=��$�+���VPS��a�c�+�8s}z-~��� ��9�D=/��4.�|Z��٦������tެ���#!F���#%��2�6�Wf�
6E��	�(��ɹ����
k�x��2ͱ��ű��.e��CT����(�k�c#cD������+�E{�&/AVw��Uy���:�]C(T���UK�n�L^�� ���ԇ�yX�<80`�RG�.���~�M��NB�e���q	G�4M��ɧ�_1�A'P����=�ZN��y������m�t<�s��&�)�֬������P�&�����dN��zZM-�
,�k��^W�`��L��<��TM.A���(��6��H��86a���S2.�F.&����{_~C��Q�>U�n�;����}����B,:|�$�g�T�՞�J)��C��W~��u�V�_3ތ^DZ�SA*諙� gȈDa?��Գ��a t�!z���p~�֐��*�F�����:zT�j{�}�@��9�hS�d����'��q�R_���jͨ8 �g*i��K^�E܀`�F;Ar�.�Gʘ����N�X�Ka{]\�ʯ��餁�k���w�R5��g$�xP������Ji(����t�|�7qJY�[�;}�<�;��pt�� ���{����1>��Ϣ��g��,��%�?&!Ӣ��$��,vc:RN�S�-9!>�f�C)>��� �s�+��+�v�[�f}��B".����l����Fk��a�e������F{�x��4g�H�m�Cer���!:�<����gީ�Ԥ�	�-ۧ1��[֓�f墵C�NC�tDT8Zn�˵�m��zۏ�hE<z��^����o�#�==�S[������_�_zS��v�����MV?9e�x�CǏ�R0*$��B�70[q��[:[�r{��f�g' Շ���e��}c�@o��S���J�v����]�ƃ�?�O�0J(~�{�wr0Bil��p;��N;���ؾ�i%�]&(�2_�m�Z��h7�n���<�~t�P$mЬEw8�	��nWUo.���_�Bz�\��4�R��F$"���#����'��PH��l� �?�9e����{�u�̉ᷣ�	�U��z��Qʱ2��T'-�?y���t��8���zc��K6�\As�ف�a|�8�ӏ/17䏽	�~��6�YӱH)$-1�������эV���ݔ��8�w%��o.3$SJ�� m�P��~��<����#) s�(����`�>��0�x�O��IQa�4�F�r�ٳ�Y���}U�G$p��f-�iW"6�;�ף˓��H�¥=گƝ�KIe\�     �+xݨ��� ����=y����g�    YZ