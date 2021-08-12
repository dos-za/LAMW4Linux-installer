#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3675445726"
MD5="290911e57b23e143a206d02a880e5be9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23916"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Thu Aug 12 14:14:15 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
�7zXZ  �ִF !   �X����]*] �}��1Dd]����P�t�D��Z�Se��v(�7H��M{)|+߆=����.ƛ��J�*���O�G�!��W��D{�,�_��@&�gh2��.FuEO2�%���pg��T��a^���:����P�FGXq��\D�0He��SG�3����g	���{Q�n����H��L;�*���`�'�|�V�J�n�3��-��ą"qJi�0��!����=02(gW]�FدL?��
�b�@���{ ��o,ْ
�l`#/6�yh�Q�C�R�����{U�Y#H_p)�<e�����#�X�
Ǩ�p�/>���+�x��������p%�^y]�n��VfQ �u�8�*����+��{�d}�?���*��p1�p�A�ă��	�y#M�*ZT�]�a3���Y�W���x.YR�e�`]"7g찪%&e���'&��]�d���ɰP�a6�P��=Uh
o�8�3�@�ؑۍ+�ۓ�Y��#�kM����>�� L����R���Af-:?俦u��,u��5��qb�$�4�>DkB3�aќ�3�����d���/�Y���yM�Q1���Ef6�ы����xl��0M�h�+(���݋�Kɸ��V��n�Yox�_��5qt��e
 ²�O�ɵ{���)����z�ze� �n^h��;���&IM�HvJ���)�)����z�^�����֫7L��˨ؽhΐ���	�4�@
;a�4Ѓ��U��o˪��ڼ����[	2��D:5s��f�L�\a�p�B Hw 
_��HT����+ek�hE�S�~ƅ��Q��Vj��-�v/���9֟x<]�o�h`n�MW�2���/�K��C����߽R5����5��ur`zl��+�c:=�Ϫ-ϊi���z���_?d?m�����4#c[S��p�Ei�,�D,�x���( t��d�*�Z����%�	�M����kM���;Ea�9���8�����9{�Iwۚ�ņ�~�ZJ̹a
�A�����ף�wRT܉^�>�h�e��H��z9�B��57�q����D ��葜H[,h�C6}�uOi��j�d{�I�C��ÿ���h���s�b@�ݪ�,�`�'/���le�U�b}����R(�� ,�d����fF.��`4�|�"n{v}��k�o�a".����BsE�E�*�zűi��L�#Ap���k�����������=b��sM�~��6�Њ،{�B�D!��(&�s�9���3��-Z�����:�>6�P=;P�rj��3����(��o����K$�R)גH�"�@��N��e�A��q��ǙU<�Wʚ0��u��>
��L�LS��u:l�?{!�bm9�qBL�k��2 fQ$o�W��w�-a�j綀B&�X���}�ꏁ(i^z�(hP]�6W�Q���F6O��@:��6&�.\ng�a����d=fX��?O+�1�$��x���[��m|�s�g��F��O�-�*%�U��pBݣy���oHV0e�&f��D����
R�A��o!�!;hN5��v΄&B&m�t=ܼ��c��z��H�:܀�K"c&�=k_��i'�z(�E��+>�ʱ���x
��[�MEc}��rZ1Bec�KQ�ɺ{Uz$�C�ڿ���s"���ώ��R�t�~�F{QU���^�?<����ȫyw�r�c�Z澆LJ�B�z`4�Ήa���g�_�pkB�v1��{�eF��f��0��q����G3f���~[�[��lMGl�֜}�v�"2�*O:����`8��1� �)��L��.��/�BOu�QTZ�x���Y�^����3��D��g aM���u��Q�GFr���ρܧ�l�~9�4蓺����A�W=��� x���#�0`�P(��}��e�Y��+ź�����Hݗr��Q���7_�x|l ���5�f	W���A˔D:�>*�>y�T�$�fM� %�.?�2��"o�%���9��d�̯Un���+mP&����p9.p��m��p��Ï�A���s�~ay�mٺ쟽���*5�\�F���1*�>v�R�ld���k�*����V�������_���-����Z�r�?�1oYi3�6�8�Y�	ȪT\�GPdr��ņ�$$�i�`H-!S���u�q�+�	�l�[;�f�a'ۣ}2�y��]b�9H�1��&/���5M� <~�鉇��+��	L�ŋъ�VɲO��#�� �14P%�7]w��e�<�9
�&�l�o�'�dO���Zq�	�6�L�VZax�I���6��*EE�|��n���!�)���To����P����Oc�v��gj_�O�ó�b��c��j?;�S�S ���i8��s���R����\�h	���Ra���fQ��[Eѧ?	X%��}��A����2�ֳ�oҹ����җ����sk�	�X8�m��%�O%�;�C_�x����p����NE�-���	(�A���GTF��1rb`�� ��b����N�@��t0��e�&5��\&���\���#r1]��:��a�D� �ĩsz���6|��.vf�0�o� ��܃���KI&�G�a$?�}���} ���Aݔu~Eq�9�K�&���8_���F ���!_�P��fw��`2��2�s�Ӷ�Q@<��m��&��8���g�^���64nD@a!b��1~�N0�~��9�M�)�PK|l��L�9�Z�#�04,u׌�W)�h>�B��_�'�n��� Fi��%�+���C�\ޥ��C�f�@(�-U����V��+¸�lBrQb����<|�	3S���"��R������=��w�Fynw�&���窐�g�E�����f�3|D38��j�@���D�lr*Ya�fլ? �l�y��:�v�#���˗��Qp[��x���d0�m�]�(�R5'���M��W�!ək� ý
�|<c����M�l./�P�r3}ݢ�="0��7�F#�"b�E�N�d��U�&��HA��ڷ���Z����=^���[E�)Fw)��rXv�ݯű��>t��n ߼ugkP����;٠�H��'�?�+��j�W�>�;F���"��e�g�{�Pbȥ�B��X�:�V�	6ߟ�R��o�Y���=���u��hUݤ=)�&p�h&.�M��ޮB�.>�� ��i�8��/A��<a����OԡKL�PU��@X-�5���F{��`�;F��q�n"����M	�L�w�<�$�>�ߏv�Dl�E�eT�h@m=�ަΪٴ&�>��BØlpzd�W�;ߎmm�>�T�ID�DJ$Hu�Mw�me�ŋc����nT�*���Bj�V� �یeB1ʾoe5�8ݯ��l`�
�
-u)j ��`�-6�Phr?FN]�w+��.\�&�9+�?5M^�n��'��k%q�/S��b�)V��1@7<������Yc���c� �Y֖N&�01��1�D����U�^��g��23��6�JH�����U�o�y>1�u�Jn�y���z86�v�J�.c�f�y��uY�����c��P 	��|�#B�bj�*�mN�7k�Z�BR�p|���
��[��)����گ���V�<��
=-gZ$Pu(�2B�l�iY�t��3� �I���̋�\!>��p*S���8j�61j_�����.Gb5����ڨ
��dm�\��́*O���g'h��z�:<�{d�����BA�.�#��o<O���A̻ĭ� ��=���Fn��\K~� X�|�D��(��텍���� �lԸb�Z[K2E��a�t�#'�Z��zFc�a��
� ��uSfTb���!�#�!{���U��=7�Y�{��MN�i��`I'��e"��zG�����h�ww�u;2�/ɍ��\���ˍ��{�u�XiqoU�}�5�T��W�7�֟}e9�}x2��cƮ\�*����1V���}F�O�#TfS��݄<A���� �b�W{�=�AH����pS/�l!g�>⬪-��j�kF��B�<�f@C'"Ek�1��4���6u��m��4�y�#ԇH����2h���5*>ga�5�F��0���4y�b�J��5��*>d������w���ySM�׷Kdb9zV������u�"��VW��Q�(�vA�b�r��,�{��q?���p:���'�:�p��</ m��c�����G�%���1Z��H<ʨ��LNhq�
��f��g%�g�Q�ׯ"�|BV���#V�4INm�&��xH�%"Z��K�T��pƘ����]�\������� �qFCڌK����� U����Ny�dY����/��2t0�<�tD�(���I#�h?|���%i���m�~f�YzŴ(c<ǣ���	����;�aЏ�uh�T����X��ٜ9.��G�@����Y��/ƕ�?9�B\)k�Dp���� O� 2]z�\�-��'C�*X.�p�����Kwl^�:�gZ����tm�7��s�_]���ʒ���'��>�%H*�:օy)� �wMpQ�|���o�rzmti���P�I����*Śq��p�Ɔ¾7���肔&��.�e��X|�8����/�b�	3"��)����Za��m�Tɖ��F93�J���#��Nl/M����G�M����+�$�p+����@ͽ!�τ�.��I$�Ab��Z�*<C�<Aw5}�%'ٛ�Db NhDZ���u]�J�sO���a%c���}�}�"3|�%�Y��A;*�����}�:�Gi��([��\NW�Mm��$�"���(���ɼEþ�%�v�8�%�7ЉZ��!�l6�dN�ہ/pϳ�9%'�b����h��`���M��"���z���!|"Vp��W����æ���/����|���[{N4��K���͐-z�`YXُ�(^��$�K�+4�Nyj��!J��XᏦW����Ww�ੲ%K�<���0�1=��MU@��f�����s���L7۾�"|��↚XXM;Yp��>f7� �.�pK�)AN�oY�ܰ�`X�b_e��=�q���Z8��ɲK�B
s���6�}�\�kd�0�	����;�!(iz���? 7�qC�ނS	7�uxN��33��i'3�B9 �l��;N|e�]s�ڗ�g����Z�&�֬�!�ʈ?���(���,�3��@xZk��P�ߧ��%���x��n%]�35����1��G�`~�Y��N���>�N������lO"Ň��4n1!<�3���I�^�:ǫ��/.Y(J��FK �W
Q� �x.����i��B}K!E�q�t�"��Q��QjT��"�	��n�8�c��P�����NP����>60���F�5���O!��Q����Bh�Vt+xSf`c����Dj5O �ӿ�1)VI��#.��j�-�&�e��z�~�]�]=sA*w�6s�:ך�Ju2�&vE隓������">��Zk8@h4����GqG{�<�9�&i[�SR(��˚�U���S���z�BE��j����'����U���=l�ȿ�5<�m��U�.5�9��q�3�b��c���P��B�y&x)�\
���P�i�Z� g��%6a����8��q�Z�?ז�3]W���Q��M��ژ�����~��0ڲ�c����}�#��M�} 쿜!��߲C�J��t�(O�ϒ�PPxF3�~����#��Q'sK�m����o_n�&�z�B�FV*�g��1/"d�GG��@��,��ћ��q��}�Я x2
c8�M��^$N[ӆ�!u,>�VԨ)y���������Bx=n���L��nOْ�D@�4�ڢ&��'\w�!G5��%Z��;� ;$F�Z��D�@�����R�l�9�uLB�A��و�`By�
)*�<]��>�{`2N��]�8�-���j7bv7���0�8x�l��Tp�b���aB���qoγ�}�׊5�� �Y���+2!�Đc�Lɐ��Y7J���ʥ�LЕX}J���w9ŕP[w|��{���D����������p����9G��8�e�a�=�`��FL9'i>�����Pnm��m��x�V*��wTN�Ocg���O���|�+�w��U�z���*�Kj����,f?��\9�d: �B���o�PMɬЫ�j�Ɠ+�P>4/��0������`��kŉ�s��{a2\���'a��*q�(�6�V>V�h����雘�1|+B�iP&稦NZ��:�P�����t���9O�E����8z�mV���U6o���W�i�ٷ/�]�z_ܢ�z+82._Re�� 9���^+uw�q"���=Οmg����V�4�Q���H��`:��{^~f�i]~0�{#�K}��h�H6�'���jOl)�gv�S�t��F<*3�?+�z�m��A�"erX�i,)�50��w�!���띔�	I��u�p���9�R�b'E�n��DbT��Ap!���;?��`MxE	�4%g����f����)��Q�}d��-����G�[��b ��3۫4
:Sc��	}��Ik6������1-[�������:zt��F�����2#t�u11��N�}>��k���0Yd��#L�Fo�R]�B��cc/����z���2��tc�u�Mb$��$��uvĠz�𵔶�"p+JkL7��E����c���Q:��u�,d8L�9��w�;.����R���W̫�%�P��Cj�q����anv�?�q�R�{^�X�_�(�"p�⁻5�+t嚪�՗�kڒ#�,u��m�t�h��6�ߋ^�0s���Jx�_^
��0��^v�dr3�y�����G�aq�����;h�7��bsU����һ�h�I�kn�{������{p|�K���X�}�C��B�A_���h��6��̶ΤW�`��LZ���rʗ.MvM#��s�)����
r8�
��T�K�C���������٪϶	��N�e�|�Y���+���z�����4(�hnؾ��	��PC.c�q�䫑Z%� q϶ez?p'�K2�}��XXaLN)6V�?N���-.jx4{�G}V��Oc�B*�:)*MV1��Y�� �B�-|���uPS���?EF�8
~"�j�����h,�7��*s��������_Aх�}���$��V���(��K�t�Ƃ�(��	�=e��ҡC�<���x�l�"�Q$���(�!H�8�|N�ۭ�b��j�LF3xP�^�ݶ�T��6!`l��h�����E];�+���*�ģf�B�eK�Z��Z��D�!�LXlkR�V/�s���H��c*�[�]  ���lcv#I�;�o�bd�F�_����3��M��2ih��Ef��04ѯs��-{Ts|pl�g�VF�xϐ��o�^�~8u�{YلP�9�p�f��ö bd	�wɚ(w����p�Rv�M�3��d'7�9�T����-��F;}��-M��d����^���00�Mh��0AQ����+�\ߛм7wԉ�b�Fh��R���qM_؆��~gT���*B�k�ɭ���6���͈hEx�������4h���%F�r����\x̥)l14M,���θ��hÃ�{��&��ES	��h<��g?{C���Ҳuc�VI�1�Z}5�|���|D�6�Fb�OaM�nG�ߖ'�������q��t���_�fBYg��v�
���f���r�U��z}�9.e�:JDu�6gContwT�G�.���'Bb	CvL慽N����G�c�C�p�ܟ����E<��d�<�o�h*����k���!�h�!\|�ԇ3��E����1��ӛ,:q��|�S~�$�U<6�o�K��c���h#�����|7-��NSi}�^��u�-ȯ��LJ/x[�%v&��WUe�`���}��#�};�*^P��O��}e���c��3��SZ��ZИ���=��y�V}�ל w�+�A��X�*5精�'����&����:�8��_}��[ ��I��N�P��$��1�N�`�|6Ej9�;�Z�l]xȃǬI\c��1����C�['�l�$�jsAF毬�n��K�>�|E4��5_����Nz��ę��CHvV�R|��Z�.���#к�|�a�U��vc:�N��j~p	����b��4
���N�/�he�QK1mr���
�r�!��(3}�h�Q��"S���@�s�m�M������'6) �Řa��^R�ۛw�~�֗���w'��z;���.�S"�m��q�.��A؃�y�%U���yW˯O���"�Ѐ������JȮȞ	8 	���y���>�]���5�^-�[�$R"a�ru�L�Mj��u��{�e�&���E꿺\!Az��էT�s�d=�՘�wx�t�/Ǉ�yKA�������d����g�;=]��� 7���i3|�����-�B�g4 �Tp��s��<�KA����6�ˏAځ��Ӵ�̩{��L1�:ĤT\�G���R��fz+O@�HgR"�k�������m�V��<\!dU��� "�>�-P}�Yd�;;���Ֆ-H?H�D�[�8]y���e�ӯk�9d��}��_�a�Q3V�������T~����]����IG?��&��!��;J�Q��@�~�<-?�'$|^vL�.���I{Th�T����_�o�ʔ�{TYB��L���i�&���H��������!�0�A��Wx�4L�r���̄a�e�����wa���7M�vqsq�	�f���礜�.�� g����-�].��Ǯ���+b���㡄�tM�s~���T�#��O�z�G0�q5���y��.|�f6?Ԃ��s�d�
�5���!�?�1b�^®�ďA�+t3.�L��Ա[˙Inq�qn�*O�w���5�������P�Y��&_�` �û*-�C��'?�]��,�B�0c#*N0�R����PG�As=�4��ہ�?�Av������.��`P��B�T+4��f����ȱ��DR{r�آ�C�a�ȷ��߇���� �V/����i΂��vq�cz�+�k5�(ջ��J��+��s�(ZX����1�_C��?��
4�@ؓ��4O�O���}@�YMvGE!�i-�oR,��F��+�����m�7l�S�P"�J�]X���4���z��Lbđ��A�����sC�0%���c�q7��2g�S����B�fi��$�4<ng���ߍ(�������	\W�'x�I���u�2/��Â�s��lH�&;�@Q-��5��:��l�@��ﮣ��6�� #�{��x�u��r����#Q�l/�D	��C>�<�弍/B��r���s��"L�7�D^��V���"�����7e�I��ї஍G��ʖ���P�WR4��\E���75y�������a�9
x��i��f`����)�L���/Y�,�K|@(��ܝE]��ߦ��e����ћ�@�ҧ4MP����%�g���Y��{#s~AԦƤ�]�T%�+o��w=b2�=�
��M�E����,�:�¢I~�˕�؅ey�8�����)=u���@!��Z�2�6��+: ��
���ykN�����E�WA�]{5^m�!lS�b�yP��v���N���f�:�LU?�¯,5F�`�ç���-����}@b�|��qˣ�� �-'�KzcH��F����z}h 3��1�����R��.ayfL�ye����7[q��=Om�e��7q@ F��)�4���o?0�w԰�/�S�� �(gq�y�}:C�
�G���ɼS�N�M�������Ib�KȂ��R��y��
{S�侯�q���ß�j����Z`;����)W��l���W��}�n���UyN$���9(Q7�ifӰU�_��.tA"$�-T��(2���zo�)N�M�Cԁá}��z�)���ND��j5���C��_���LډBʉW���~t�i������Y	���&�M��:��Hu�^!�֚"�y�g�֊�/��o'eH����3��0	)`���pA3R @��կ[�3\�P�����?����л�	����q�C�SТ\QV�m햕��:RS�qz�57����l)j_���M:��S��5�!�B�
 ��vn�Qg^�n�4@�����tN'�Nɛʜf-�X��gI:��+Scdz�p��r��~!`��6D�(ϯ�!�t�]�C����~��c	�il����^F�xb�P(��9�k�mAR@{�%X�������d067�,Vr~Z�v�x\(b�����_�q�'g�jK�e�p��	��|L��F��R��F�o7
Q[""*�L̀�:��pSf]y�Ir��ϐ���{�I���fO�����l�"���,p��u$��N!5�w�<u�Ԣl�ݚ�Vݘ���+S���~��ȕz���S�7��lU|fz�_�?�����0�{��q���HC�؂9��9u*����p�_?�I�$o�؉�C�]��u���P�E!��H��L�y%�|��ZhI;gj������d�y.� �[P����ʰ��ȧ�c��"�.�x7`AWc�[��t�D
r�����ܞ/)�e[pH���]�+�}E�]���O�/?^`�[�t��rq!�{"��ݪi����Ѩ�~N�&/>�]����C�f����GA���Ji����{/v�q����t�fLagX�B,���t� <k�Ro�n��垲;��9�Ѝ��7�3���>	��@��s�t�1a�~]_=n�R�"���(�!���խ�{&�D<��?����2[rɜ�z�u�2,++Z�)���W���k8��%�W���l�n�n���4�Q2,tХr}�eXm��kK�Ay�����*/2��~蒉4!������_
f�~v��CF��_2��H8}���z�!���s����.�@t��c���q"�1��g4+O�*�6?�'�x�R����"~�c&Cc�R��{n�KIK*..&9��G-�H����,;�FTVN<�<��E�p綷�@�-�o�`�aʍ1�ƣ���i�kAtn�̺�2g�d�Z���m�v�J������2����NL~s�X8����
z1���f��B(�_�E�r�kp��)i`����l=��.q�1�7�\��0������ai=�!˲͛���6-��� _T�Ů?9���o�R:�s3{Q�]�>n$�Z��ik5o*hnA����Sl�B�=1��!ꊏ���\i�|��5�0��s�m�E �e[� ���g
�+���"����<��лdO �i��3���|p��_���*yM��X��2��
̸��lmT|��.�e�o������f�����ζv1V���[��㲣�A+�7�/��nٶO��
�U�r�H ]Mڣ*�
e��#����^V���~���)�c�J�!�I�j�vRq>��� �Z�H�(��d}�م �z_������Q�����Գagt-����X	��SIK���# p�j@8 ��aktG��Iˡ��3P�)~n���	Wn ����xp@c.���0�6���1?�(9;Q]BK�$���y�r9{z
`m��5�-O� M��d��F;����u���Q��|^l��3j�}�ڱ� G/�(R��*n�]/��i�tἿ�&v[�*"$��W>���Z ��+@�Z�u�Mɵm�T� �C�)Y��0O�2gX�x�Է�҇����T�}����@�N4G�(��s	�1�X�>����YG��C2��3�E&��^qO�X���)U&b}���s����[Qui����cK����t�a���ٟz
�×���Z-�P�q��!��snS�AɅ��pd:�g�N۬��U�{�
���F�L�mvn�=�$s�r1n�-^��*�8ʐ=.�4k)~��u��L)ѸGs��B#�u'gy��v]�`�|�F8��/�I�~�8������+�]ҍ�*J���y��)0t��ɎvC�r�>(�?b�l��i� 1A2<��&�O��V�	����	���ef���|�Q��O�Y�@�*X_�{.o�D���S�.�遳�����ο�]w�'�nw��������phה�܌���v������^/g}�B�h�:�Ht�pF&���/vA�ܩ'W���EGS ÖSHA��К=��Ow�N.�hM�u�E̸��R���[���ݲN[�/iI�̱sOH��j���ɖ�xU,�6@4�up�: T����J`p�T:�Q�I,L�M����BMU�C�� [��xʩ܇q\.p��*
�g+��'�����
�ۊV���� 1���Pf8g�b&���\[��|~����l��h���JT����h�_���Q��� h\�cR/e�K�%��5����Y�&1S����FU��U�6Wˑ��Nk���@����F�r.����T<H%hrj��u�o����f֋ew��3~z��*S�̐�m�F=#jhUGy�@'Z��2*�^�lo�9xI�f��0�1�r̨��Rq됈����,}:Zu�fȺ!��x��$�M;������F>!�h�d���ä�VN����9���yي����V��1�	��'B=�f��/�1m��e�h�9h/È�7��;(m,�=x[jێ[R�|�2�7�?�-�b���+���zY}�-�i#M���FTvH��74�|h�'�GeOL�U=2�Q���@ &��\t�nWA��e�
eO��U���S&R>���;4�ۉ��>vp�f�N?17��)�oE2��b�i��k�nb7I ��\(I�9��<7��NT����þ�%�_�6Ԭg������ ��3��E �Hj������T!Hy,��]����=v�I>��Ez,��9>=8�?̷jʑm?��;T�t��]D��;�*?5GN/�.b���m�����ꐐ�A�6�/�/������-)#��A0$d��3��`$Hy-�wU�ffw��c�����aVJ�����gc��gl��3.s���� �1��8��Rϋ��������s#d�S���#)*� N쳍�84d��5����"�#�O]���g�'!����U
�c�Z����s9!�ӌ�ؒ��#|CIA�kM�ѡD��sBV� �X�x���˔]8,��4��Z��N�S����
'�U��/�Q�|J}7��p1�.d����'��-�f^�����xf�+�Q�xm�W���͟7ةM�ǽ���sna��e	G"��)޺P��3"	o�?o���<�Wo�js���@;={;���޴Yv�0��5qAQ��Y=S5��P,⬙<��O��	B�;�E��,���4@/�b���g�z5��)"o<
�b��mɼ�0��B�Y�|�$���������d)p� ��I戧�N;�B��|���U=~���
���{�\FI��� �j�P#��a5�Qu}t��uKo���O����ՙ�q���f�{&���l��;�Xٲ ��B�y���M�a��r�S̬XӀ>�ƭ���}��s\_A3Q yWr��s��c`����y�,mH]��ثY�a�1r�,��W��+��J�s܄����}!$i-����c?��}^BV���I}�GM�2Uh@i3��v�6Cw�4ؤ�j��\�)�x�\��f�_9L"@O�Lk&��r�-����Ñ��XI �>
�\�Ӕ=:�#�^b5��>�����@�a�Zg�]Mb�q!t�������8bв�YYD���g��j�\��܏��N���4�ݴ��ƕ�򛃟Cű��{�3+{�}@cN��rƊ�-4/E&^��P�^�s�~&}�t��/��Ѻ�`�Ⳕi�R��L����ԗZEF�c�W���J(��xљC6)ryO�`g6�N(OlNN
�+�rl��}8�{����3*���'�_ˏ�%�
Q��&��<�0DJ���@�X��Z����^y�$,Ag��I��7 �7�ld�Z��[a��^r�R�ؕ�lLF�9��Ā�T�����5�/��r㫠7e#��r�zY�I[��Ix3U�[�nV-�'O�~��t��G��a�'F'��d3����k�
xB�_�H�ւ~^}>���qw��LJ�:�cƽ��s�(��υՖ`�~�t���I�{Gf%XZg�6��)L؊ǹ�[ �IRb���?j�4�ZyB��H�mux�&�".A������d�U���=��o8X�U��~2
�j�h���l3q�>|�����\]@|��dL��U�_���S��Qt���8���0���e�y�/t���s��,����K�P$@}�%c�?��2��a$����u
>t"�#�Vt��-??�N%������W�V%[�3�n�uXl,t�(ȃ|XGO���b�\!�^A�U�p�j���M-4U����������$�AR�1��#'b��s��Q��=�Д��7&5�́��-���l3n�a)˅�R@�X��� .�D�0t�'r(i����.�7=��J�6����/k����(o��x�r	���XQ '���������{D�a�Dz�Ұ3���a���p�Pqֺ#�EO׊��O�f��9y��"+���֩�ueP!g�ˍ&Q
�	�ժ��tQ��(�����@�U�5~�ګEr�*nț�4A�*��C1��1�fL�,lu:���ް�{A�-s��wDC!z�*�b��{���B\ڔ�w<B�l�<�Ac��k(D���>�W�n�-a\J��A4م�Z ܖI9.��+4t���:���^*)ZU��)' �9��sHq�kJ)��K��\�n�̻A_B��,{��YZ$�&t�U��5�&=t���ha�D^�z��-�4�dg�$�6���W���~ ����*#_ԂC���^϶�n��mU
M�����4(���.n��['ԇYg���r�9}�@�v��TdL|�%�K�WVg����������H�p1���ٲ��O~�@����,(
�!q'-��	�ҙ�� _a#ֺ�C��t��y�d�I���=A��fn�k��a�d���}a�k�}�6�� �/��5�����,>Fs�����T��$Ѹ���,o��������c�<E������5݄���tJ��0��Ux�����Lh���2��X�����=.��}�V�#o��X|{�5�%8���rcUUC�Ԉosу';ش<�t����Z�ld�
�cKto8,�z��L�:|�F���`�	��(�w�*T�q�������EYJ��+�
C���Q�"Q�����rD���o�����K�8�~��>��|��Ը1�%S/3�����>C\��5}���8ۆ.���[Ew�!b@���� �kWrw$ ] �prk�.�Aș�E�q-�����D�zi�4�`0�3�3���]�i�-�f�W�$"�NK�6�N6ϸ�k'�U˹#��p�P�����
�ɞ��l��Ls2�ۊy�p�!��˅#7���t.Ճ#L@'�^	W5����L��Pi_>P�n>fg�������ZA"gre�o��
��\�l"Z�K
�b�y�����8����ں�ˉ6�2\�Jj��5c/	0X�cu-��n��+����b��+�Es�8��M��weJ:�#�rs:!Z.�ov�X�iD�d�;2�Ⱥ+�4u�|���9j"�x� :(���$����&�?!��%���7���i�,�%�n����(7�p�9�Cf�&"�,�SK�B��'�8h1���VE��-��B�ī��SF�h40r/�~��N7H(�����#<�g_e�O7�j��/{�fl��z���ʵV��Af�h|�j5d'����s�qIǨ;Bγ�֦�������r����.hv�,�g�6?��K�#�tֱY$�E�>�����~�.x%�6��FCkX�uh�]yƻ����ջW��G���0TZ��������M�e�2�֘�p=��;�p[v�ۨ֬��(��Tf��R���*#<S�z5W	��|�.�,_n9�9�ʓ���i6[w)��-!�G0F����l�3�����z'�Z@�kd����J	���Jrb`@���n�˰��A$�q
K��"������sm�v�oG���F<e��}�ӎ�{�uzv#�0�n�5\���(��ח4��ЩjL������)�����q����1��G�yhqKIG��������wE)��KͲRc�a��g�t� f�,�� ����uym :-x=9 6�%v�ϝ�r��h���t))N}T/�<�GTC�)�Bxz��IrϺIOG�����}^��)\g���x����ԓ�3�fU��w�~�b,��_j�݉��dW����{���Xd#}{o�F�&O�;���C/Yyդ���4�XT�9��9�r�:��.�C�9b�H�it����!+�#m䪍X.2�|;�KR�9��@�3Ԩc%����������YF���A��؍4J#[������f�xJN��byF�[_��+�TZ���Q�nf;Y~���'���b�]iџ����6����RT8.�k����M�����Տ�jY9��$�{� �nqwkB.$Z4,N٪`�l(��8% ���"8`���CYX"�T�cY�6��uJS�S�]J�v����"T����p���2P���!�����5�@}�U� v3�n�Ti�PI�]������h��MzF|��e�����Z��x0_��%c������qp~Nʓy�RG.u�#�٦d���<�++@��hwkL�^�${8��+h�ac�$$q�ŅD~���	T�C���6�猧�;W����v�}���
�`��CE�me ���M#�����Xt;�@��ذ���y��p)��.>o�G�r�_)��*c�3�*�&�Y�*�$�JWn��w�	�5��_c��+m�7���"ʯ��&��bX�O��t�F���v�W�8�|3������`t�q1Ǚ�	��/�C�6	B��Gt�h׾~���`���	Q�)|e�%���g�"�ۚ���J~��tm�O:��:���<bx��|T�!mں�헭�id��F^����(�/!�$7M�~�,x'�>��Hp֙��ΰ:�����xP�{�v9U]K��^�7�G���%Y8���������&����Q)��(��'Ц�ˋ=����L�����|�
#0pى���:s�z�p�ofI:zY| ��)L����d���������-~tZ"�-K���wVY���
*ͨ	�+���h�\7$d*�vr�K96��!��?xu�޵q�Oԕ	'-J�I"˥���ZB�����i�#ԇf�"i]g�o�'t�.Q����&9݇������na
�үy��Ɂ.�A��p��wP2�����Q��B�ж7��[dW�����}��3�/��wwӑw�(��F;�3h�JƆ4R=�o��� a�\fd�����\�+k$�����˱�s�ʒ|���&x`���ǼѠ@lB�O�K���  ���\��|�mYf:�^��ϼ��
[�,9$y�B0~�������u;�*�6Mt�F;�ݺ�Y�����G���x���p�Y�Nv�����C��dG%�O�����ċ67>�պݟ�a���WEƍo�r#1U����"������������\�J�X��͖����.�25to�cV��QZz	�*v@�]&��H�`i�W��Z�(jP�!�(�w;��R7��9l��H��ޑ��K��ݼҢ�3.��o�{?U[��[Ʌ>��ص@��C��ʮ�� �-��,����M"����@�\'�_�Qf`g8!�/��4[ӜΚ#Xm�K|�mE,pxQ&�Q�p�v�?�Q�W	s��Qk��D�l��"4`�)φ:��%͉ \0hV�	��"T�p���!�%�A$�6����OXvw���LW���m�.��	�sUm��J���Ci�i���HZWe�C|FKu�H0�c;WrVJ�f�H:)u�w�����Yk��R�_���T��I�e`�`О?��M�Ʒgf
0���1��Зf齶Mx����~�6��ZK�e�Y�0i����$f�������.K%����S�i�4�a�.����n����L}#���I��/=�~A�qf�A�X�c��7Piϔ
[7�>Q\r��l�"�����nW�߸d�S�(�+�% |��Ol2㈀ξ_�9V���犜��9� Б�X�_w�t�UK晵s6�Uf`J��:�ZAX��!h|�X�q�4/�K��R]�c�^K�`�	M��2���v�S������o���'�hPk�T���9p�{g���#�Ř�P>|{e�Q�_���^UL��,���Mı��k�n��>�{�\^=��ܡ]C���ԯRٺ��F���㰣�q�~�-h��n~�,����ziX�b�L�+˴�7��|�]#������dF�xf<��
��'�!��]�٪C4�Q5�&1���F�+�����I|o�� �V�f�-���yc������u31��In�
�n�"7����r���;:����F+��O�KT� xp�X��q��i�F�n��B�R��Z6"�h�6���\�ḩ=��ȗ��5;ݼ�1��w�٩�	ִz��'�f�z��Y�pL7Sp���s1j��<Q�]��kX/�pC�����K�"Л�QcH�)�\R�7�n J���a��V���~٩7�R���Хl���!|%q�H�m�?!XF�ַ���ϣ$��源K�����]x�V�e
 �[�s`�a��g��*@��s1��6zd�o<��i�T2w|�7\�խ��9�[�y8��P%���2��3�P������pG��@Y{5�xGp��iKZD�	~����=����̱�=c7R����~���h�ΤH�$����YM!oKn�x��]��Z�p*��w�	�=8k�!;`�;�4IubdDC!�=yレ�R���,l��}�T��fJe���E����B�67�"�Z����@EwG���|vn�� ]A�Uݒ$^���B��RŰMP���~���b:B��cA�5��p�s��)Gf�y'B� ��u	��Gͽ��d���;#X��*���ӎ+����PĚ
��;?�r!����ӑ����B'��%�?�n8�����Wgqk���j�\ �����D����&Z_��D��h?8e7
fs�ˉ��NGf�J���i�j���vд����F���'���D����W,�*���*�@;�[��~qͦ
���u�1��f�z�az�>E#�Lv����LZj��,�[�B���%�T�����F���vPk�AT����i�B�+W�l�w4�[|]�^��w�w�h
�-y{3�7�����)�/]������	��Ø�,�w��ѮY��z�;Z<o�EM�y�Jx^���g�-L�5}�Tps6R٩�Q3S��
�p������g��۹O|W�+d�F8)�ֆ��W�U��U�8�~?A�CU\5����D�q/3 �&�w^DX�>���e+=W�b��L���5>ߓ����M�e��>����ǥ�_o�7���(�s�Cc��J�3In���NN~��Io@��-�t4���ݮek�Ю�/�8p�E�IFM���|ë~�gɛ�K�q�&��ڋ�}7z8#+���|͚ĸ�t�-�����Uf�bcĞ��zg�uTH#�&�w����I��5�.�L��;���ث8�i��1�7�yE(����>�T�^�>�Xĳ�����}��4� ���v���ôM�/"�����L�������&r���2��_�.�%�jC�>**�Z�i��+���Vm(��qj��얗3V#:�C�q����t	LZ���ğ����;--P�+�������|#n?x��f[�#��S�(�0ԇ�\ʯ�5~*i��Ǟ�k����Abq�d$.�b*V�����Ќ���?2�v`����(r�)l�ϩ��c`��eEoR����
V��E�t��{.,Z�D�]�nOJe �Z�{� ��N��F��x�#&����3��8�$� .�9�}��Ѡ.ᥔ����gȉ��n�I�U5����(�VF�x�'QDj�4��x�}K���As C��S�hЖ(��?��+Ķ�C	�73��}^�P��V�gB���`mO7��Y5:�<��Q2����M Aٓ�U̦kи�����r�5�F��T�h��e\�uHn*E�4�Z��H��ṛ�#��ֿ�XdD�woN.���P�/��9'�o�_6	�A&�%�����y�VA"��	�R�}�.t 1>~���D��"��S��ԁ	�(a�<Ӄ�?�CV�=��K/ aI?���ׂ#<�sd4�,4"ۖ�m�e'�g�j�D.��xT�	�����[�������V!�v��L��S�5e���N���|�a���̝EC���U&nr������Q�lMHx�W���A�^h�M
�<�G$E������|a��;����Lb���pZd��o&'�,��n@^��������%_�4e;x�2jKz2󙠩�I�d)�����(rW�uF��(i������c�o�_~��Ob�������L��w�dӗK���ևӯ����ϕ͝��5}�5�*�XA���wx�=�i��[�
�تީ1�_���, C�t���
y����I=��Q���9Vv'���;�5��`�\t��|��S���7m`.�UI̻�R�����v����oݧ�'��u]��ɟ$P[�gGB��ҵ��|2��Pu\�]����ėsW�� C8����K	�UF�OD��U$�ϵ��T��*DO���x�-Y��W�����G�?	��������`�t�(DM�Y���8Y�4xv�m��`�Da��CY�R�����P���Ĺr�^W��2�&f��1�\��V7D�f���Lˇ���cTx,Y��9�{F�#S:�̨%櫩�楦 �D�������nm�]8f1���9Y���k�)��(M���BH�X��	N��|�
L �j"��δy��.�0:uz�Vn�a���[�����CO���8µ�Jc���p%�8Z���I����ԝ.����7̝V����iLGf�� �C�U�hD��AΞW����%}����6�v��Ɍ���3W��6L���,*�Tڞsdz̩�N�Z�,i�G��k^ˠi~'X�'"�[��o��>��;��_���H�	�<#�o�]X[�?��T�-X��:��_�,�`���"�OV��4�@�738�|0�MT�������Dr^]���P�VO��F���kз��_���
I�J�$�~�����<a�[�}D�K��	�������Y�2���ܬ���0t��2ڼ�9�믠u9����BR�ZF3>��WR:�ċ�U%7�t�A�e�w�$D�I����f��2x���[�M�-�pT� N�tC�Xa���
d`do鞫 Z��.Pƨ�xT��%�d������i{@f�$�'W&�q"$tɡںgˋi%�"���D��\T6#�X����]��s����������m2�yct	3�	�*L��)�t�R ���<� �ſ������I�&R/�aT��G�nQt[��=�Ϭ�U��Y��l�})�>��Өϊy�no���x��=B[P8&/P	�B�)6҉��C��1�����k����^P��)�зT>��f�"S���C���I�#2u(?��o.y���	еg��>���i��4>L�Ի5G"��hLM��J�c��$S<l��:��.ID���e	���}�����!d�o�_��9	��L����Lh��y$�	z�ô�3��7K����-�sow ��0����c{a`�)�ǝ�J:h�����3��䟗@�LL���]ˀ.[�$B�`q%ベ��j@����K����ñ�Y���K�=S�{�%�J����S��K࣓�x�b�!���l��YW����Tu�?�MC�T@>��t�g�?��4k��5����"|��?S���Z ٛ���P�~T�Dl!�d0�z`;����`�Ǩ~8`�w�ѫ�F)ݲ��-������o0�9pI��Nf�t|��(�^J@��t孶1�?Vhڰ���g���cn��ɍBL���t�(���
㵪�*�s���+���7̜@S/�Θ��w���:u=�D���X�U���6�b3e�� \0T$�b�:
�����P�eXO�����X���v�H!0U�@�1���'c����J����l踐L�=��a�f�]'��)�a��-�[kITE�C�'�v��KL��=�,�k��a�vCD����&s���oPf��6D�����<�*oR�j�8�$��8g���Y��-�<�W�<t~��TR���L:VV^�,��ۂhޤiO��G�v�(��12��TE�(��:�)��vS��";��$3c:ZA�<ig�I0 d��0�=�mT+W��i�֊�1�^V�'�?c	>B8�n����Y�)T�.7qu����wz��LR���R�f�v��� VZࡎC�tx�x[�T�F?D�aj�%

�|�]\)5�3?~�����e`[��5��,���u��E�bu�5�k0���{��>��̪���͕= تG��rPV*���&/{��;�\���-1�N����M7��9t���8��)����N-q���$��X�Ȧ�؟PQ��9��E+���`��O����2 ���_̌Ϋ�=��j%(����L�Z�&e�FwPF҂�A�3��?�!�"�!�Aq],K�u�n������K��R�+}�|WY��9��Wп�H67zs���9����7��{ktw��YW�zm�ĭ�6 �H����R���6p-6�pֽEI�{�ck�<UK�2ɟ4�����9�sf�a��Wm�9�ʅ䕲8b"U�(������7:�)���/�ght(�}$y^1��bR����RmѲ/�W���Q ׂ��Ͱ��C��Md0+�м�MK{W];�uV�j:���<��Tu�VUO��&���+և��z��7�JҌf�$ƟP��d|L5�/0��Џ��#&\4�R�����٢�[.kh(������;�v݊r�6ʧ��J�l`s�:A-��!��Eg�H�Ζ&�&j=;�|.���~|�����{+��gfv��*�������e�
3V�R�i�r�F��
�j�JK��FY� V���q�ش���_�`3�<��'±�0����t��僠;}xwl0�F����Fe��R��{^�y[D#O�����$��,��kZǟ<�������/bPk-�Fm�F@���iYnR H��뫀���?�0N�{�/1 �R'V
a����߇n�t�p(�I���g�<�-�����x����6p�@�X��D���9���3t���LL�o��Lo5U>��^�Wcѻl�6����""Z��W8����t�0	�P*b�$=�)D ϪzX4њ�g�A I�Cm��l�P�3���=�HTyǖ@)����<����7��    ~�v̷*�= ƺ����R��g�    YZ