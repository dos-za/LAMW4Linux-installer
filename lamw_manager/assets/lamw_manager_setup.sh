#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="574397869"
MD5="3ed8ba212a0cbf0c471287cb7b696a9a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22988"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Tue Jun 22 21:41:53 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
�7zXZ  �ִF !   �X����Y�] �}��1Dd]����P�t�D�r�8g��]Wq���߻T��Z�ב�H��R���ɋ�W�<S�b�i�=�[U⩲��)�S8O�"�ל?+#R7����@�J��ϡ`���mW���P���4V�	=��Zc�)���n���ʞ�K�#xd�о:=�[�Qw4HݪF�\��z�d�Q�<�Ԯ���E�]r?�_�E#��]h��?L2�kp����۰�;�^����RX�!M��]%���%�S���l��Oq5Z;���C�I��Zm�YD�ϟb|�V�A�Z&S��}ַ���6����eybU.�V���(�o���CӶ����+Hn�kD <��l�|e�\��ַ������-�i���ٜ/x�����K��9�X̅,{�ݮX[��<��~���"����z��yw�p�`rʯ��}��~����-J�x������&$�֎��-���?��,�G��ծZ
����pF��פ��p��J��{:�٢�z��$���_I��ru^C�����.)H�G��&$.��Е�_Db��-J(&���|'��{��PS�UZ�����K�ւ�x������u�17c��7V���T�s�ƸDi�[�~M9�#�M�����&�;����GnUJ.F�4�'���x�H�iZ=.�^����!�]��k��b�Ā� �%t;,�$��AA�K}�C�u��:@D�c�|#r>��XHtQ��3�����q�Q�n;�1����_�8i���?�P=��#	�{y�J�t|�������@Zv�/p�Wp!���,\�q���YJ���\nG�
��^�_���3��
b��Q��8��(A��}"����ɽ�n���7��\�B*.�}���yU�i��|��_��H�Qf�$������Y.�)�K�8g�f#+�J�E�tS}w��_
�bQ�B��w�8�X/ꕌ��	��?�7d0C�pm��_����d"-V1��z���Y�X�bW��"8�5������F�\�e�]d�9,`��GWY�7p�	�S�۷��k�R?s+��h<���nœZp� ���y�LAY��"����&�1��M�z��Li��p�4EZC "�၉�W��d�SU2L`�&��r��[�H��9�����;c��Ew�x�a��`�}ޤ�Ҥ���(�+�UM�xe�Z�����}��y���G�ӘW�Ɏ����.Jk���Ђ���:���c6�c�;W�Ƿ���S"��_تV]Z� b���e�qQ-+1����E��VBl�fHK��������W�nK2(d�Ra��)�pna�X�~�y̔uC��c����Ckق��NBſ¿D�#�"	��vW��A���$)\���ψ��e��W"��j4^�=�H˗��|4�W�� ����Y��U��2���̟B*�����hGP�l��e_iC�II(��ܩ4�_�n��G�^]�EQ�}�
bqA���gq����:^��O4�X�G���Ad	��W>%� g�[9p��&�y�q�hGo�C�L�%[����qƢa�EM��w����$�fhuwdw_:k���n^}��|G|�y�F��뙡�%e��%����f4J9@{{&��� �u!�9��Z��倲��	�����M�p��R���|���XUa˖��0n#�^/�ok+w"/Qr�\�������0���/H:�4\�3���Y���<���1߽i>�0ga:��}he	E���@�z�o�f���E�^��T������C�h�Zԉ����@���>�mR���GA���ߋ�,��zt�b��,�c(���c�"V�U{-���$���� 9LӞ�ؾ��[�N0Y�%O����I�ӿݑ�0��H���G,Ϟ�y�{=�q��^��vb^��x����AU�.����B1�
$�z-We�,�:l�����y��Vs���B\�i�	q��#)3��6�z�K䄯~\��ؖ�Z� ��?����Ɏ��zX9����Q[j��>oI�uX�lZ+L��`��{�4͒!�uS.B&�~Z
�B#�d�bA��^&��u��2��Vv��]{b��lrQ��+�����;��ª���#֍� �<�A{i5��ŗ������G��:{ኰ1"��ە��ž?���Ya�!�:��3��PhSp��
Ǖ�C���!��<4�oCʭ�����
��ƣ.|nw� `��QD&-�Nv��,��B�	�0?Ar��u���xT���$c ��i�{�<��-��,���W02Jƽ���F�W��LTT0�}�����G76�6����ӂD�m`�1KP���^�r�]�ѳP9I���ėk�����y.��p�<��~�"���eኗv��3U������R�?�e.�X�oo���c�wEG���|���5�M�wJ�7���Я��Ae��U]~#T�Wo��]��Y����Ў�@0�~3
�k�o'��r�U�"9��0c����鈡Hu�\�#<S����wg�~("��a7��j��S��������S~
�[T�Y�	�.��)��%[,�&��N��p�7�W'�@p�BO�������C�@u� Y,�My��g	��ă\�qIA��Q�:K*n#�q��?<�$��-逭��)r��h6o�S��Y���l]�b�	m}�HB{�&��G�x��c�
m1b�#Y)�C�!�#l9�^���E:�|���d� "��c��Z�1?�
�?|�мJ�Xk��]��YB��(9�O����.ѫ1�q$h{�h�����Ek���4[/ɉ�4ۜ�K�ߴ+���G��:��u~1�'���-�X��i�ۗA�1>,��t����W���%#���3Et��}�>����w}x�\P,����\hp�4�b�h���*�X��i+�����u�''�@�jbݪ�@z���=����� c=; <쥁N"Xב�4Z=����ɾ[��:�_��Mާ���_���D;����
��e�99^�$�w>�%t^/W`i%==��B�0E���0�y��v���e�"�(��cqL�^G�&�C���O[��v@�|�k�c��֌n�1 hX-����?M����iggD�-{�.(��ٷ@UW�/D��rl}��':����˯�R���܆�0�ל�
:��Ԥ���{,�zc����1�vp�q�:�ӳHF�Z �#�m-|��zh�뻝�eٱ�A�p.TjZ��#'�$[��EK�~�L�
\�?�/�>haG��?!$m��du�K L����i�S�o"ԩ�G�|ˍ���Au�z}<�&��V(h5Cv0�Z��s';	1e,8�_�+����M��dc�瓛��O�eH��:! �o4Y��N�=�9l^�)��*(�ӆ�n�g`!�Q�Z���W��'6W��������j�?K2e����s�dP�m�)B
"��������=��p[ŀ��7��	�00O�����ٻ��O�����z�c��'*��fe�k��N��2��{���Fh�Ɍ�NJR�<�����8�đ=��ʉx����X��]���
������h곙7=��ge)��\�����a�W$�q��Nѿu@Ƀ���c���h4J����P�M�IE�V��"kK�l�{���'���N`	g���
V�w�@�V%��w^ɠ�#(���1}.����Y�+4n�������7�h޾?lT1��R.�r�z��XW�KlX������u��$���.��ܦ}�>��ٳ�ቐWM+��R���(�j��):2.R�~;cQ�Ϸ�a�<m/$)��M�]]ڭ� #�6%鋞8��N*��^�K�kk�U2�F���������ʴ
C��q��7�9w"�M7�r��8���s�m������VX��l���J�ªFj�e��3���+>Y�DIa�����*�j��1i?�]8P��H[C�\�E�5ԋ����_'�*���˞AW���ۘ�꣭6�]�m����Y�J�/�HVE����J1��K��\���+s�/���˯�;յ��!w �=�Ž�du��Fs��n��~�~uT�~E�M��BE�(���~�`6�}8"+Z�:�}wz�F�"R�)Ka�˥J���{��͐w5H:��i���Fh=�=�&�P<��<x�ǽ�<d��l��-��f]�,�1Dj��l��~~�a�.`��� x-����^��n��|���;'h���3~�k):�[�o��F����2���Fg��0��?��@��5ܽ�7�@����K�ڈ�$5T���x)I�����=����_���sf]�69.:4�s��}�_Y��dk���m-\��zt�Ȯ����N��
��+�/���օ+�l�����dI�����d�g-2v���Ԉ�S4avDꃾ��W% ���o��M��9{��8r��>*�˨�H�bf3[�]®�󅢺b�2IB�ZHɼ�CKM�h����]	�V���E.G/�f�W���@t��"Dh�h���CMx3#��b�^b��"�S�P�? �#6[/v���1�����m����3�N|S�=�w��"��Z�_��u�״�*�mm��������T�R�4|QR|>U.�#��byòD5���S�jW���J�唄��mcY�;��]������d�9�])�@d���v�D�i��h�%��������R���gv�8x:mv2ٽ,�nW~�
���K��HbCe'A�U`��?p"�P�x�ܗ	�K����6{j:=oi�fmJ����X}�mMW�L���c�C���(x��`P�����L����C��Ü��Z�^q��cִ�R��AS��d�z�gM��+5a��ɜ\E#&\p:y�*
6�f�@����0�����5m̯�_r�S'�ku�	�;�b��!DB�g�w�7	����b4x�U��k*�*+��^>�'߮6ߚB��?�XD�r�bz�qi���"0��"!��p���	B����(z�@b˹��䤿�$x�M���p4ޞ3�f�ɗ6�1��P�w�f_�<�!#�h����+�i��D��X�������F�ܮ�=� ����f�^������='�怩�њ\Bf��2���C��ؼ"q��0:���r����FP�H	U�s��];i&P!���^y��_�AgW0{���s���W0����F޶�)�B�닻����1ր��v�c/�`@5��Q��k��Xvyb&Oڵ�m�����k)\B-mn:i��[A_B�S�dj��׎�gZ�R��68v�S� ��*�Q�J�iM��tΠ��.J+�ѡ�I�^j��w�S���^Ro4ϚM���V���TP�lW� �)?��=6�9"�4�J�3�x�~�э���1����t@#�9l�~��� )���,,��J�uev�1R��BB�#i7\q~���g�\��N*������eK�¦�LYBC𮻑�ڽ�T���V�%���e[�a���ri�7�%�;_r��^��-x�'l~��k��!6h���2L��UvP��~��(�����t�)SB=j���		ф�C��~�_�o��K�0���G��y��7?���?��?��hk�:����6<��o߀,��ؿ�`�����"E�����]f<F��U�fJ5!�X�ǐ��9��)�z���VA���܅c�@>]7q$�O넥-ɒ:�Y�D���I}!���>�?�#)�RJ=�s��X,�|�g���څ!E#��뇦��g��� FyZ��I��R00%��.O��m�`<,i�B6f�B*E����H���*��z����o�G3�M���hw�y�d ��'�N�x�RFK���L����v��k_�dK���ܩ�xc��g�$F:�����!Z��(��
ێR���SH�>����|�s���*$��ll)�H`��D'.8�^xlc��&S���P���E�����̗��'�R�5�ўwb(װhYM�!�]�$���0��9R��ŵ@�=f���Ev���qȥ��8��s�x`��zC�����ɽ�.T�-D�	7�ٕ|�Xo��Æ޴�Y��rO��P�w}��!N6K��J��o����q�Ҙ=��)؜5k8�h���Et��W�GFo�ì񴯲!v�s{gd������+���1��̫i~�Mt��u����ʈE�[�lۯ��E�rË,�2byA��,��+�8+�̽�����*B��2>�$�L��G�'�eE/���	u �gZ�ov��l ;�T)թ�JU&i��n חzg��V�v��ݕ+��Guj��b�|��L��_�Ṱ��jQ���{�wX�o
?�S��� �W@w:�*K���Q¢�E�gA��p�-��<��$����G�8��CU��9�꺍G��)#�#���C;���3������:%p��n@�$����!��-Sr��4��[�񬬣�T2]\��t��s'%t'���p	6/	�}�A���e��S�[�������š��@�p�[�%�О�3�qM��\3�Е8m��uQ@[��˘K���14�6ywە��Uǡ�O�>#���M=	gTGSIt��n���u��+�KJU^�]E��1疁����#�Dxz=�,��i�������v�"e;���F�0�GZ�����k���u q\j���㈩�����t�����ǭ����s��r���Mȿ958O����L6!#Y,6���z]^M��j�O�=u�H/�v�8����W/��U�@�~Xd�0{�>�J�4�
9o���-��8%��w���GߤL��'�����&_���V&[���U{oY���y�m/���=8+d�Y��9�!�Kp[tj�m�V1�Ia֏�[���_+����P��)\ٯ`�U!y���U�G�:[2��Tc�� �AJt��Z�e���Z��,�l��Z� ��y��)	�O?��6�*�:�Yx�
�r�*��ߴv��^������|A�v2o6�~�c��3�D��7�hӹ�66y���f�ܐ�B��ߊ�.tB����pR:8��1�쇊z�}������{/|<;h���`,/$�mO��ޠ�}N?���E;f��N���cB4ǝ��u����e�K�����M�+����xK�H�p5��W� ��Q�Յ��
�O���r����Ҋ�ݻ��靾�wu7_l��*g��[Q������i��/����n���;�No�lo��S[�bH�Y��c��	Ŏ�a��#j��������kK�# <�%˶N�ߊs�J�C#9���[�3j)}��$[>�rt��"��֭Lԃ�!��v������4��K�!?l���F�f������.Ǵ���L���Za1�ݿ���>Z���6(��[U6��J����5���~p&���+�2.x<T3ӠN���s0y�(��&~z���r(P��G�݀l��ur�)�6L�*�>�*rq�s �Ct�I���D~�(Y��W�N@>��v�8?RX ����4�Q�B*��@xu�#�;��L^~O$#F�x��f��X�5N���U)��#��zo:���4	ά�VQ���=���C��-}`�eT�ﻱ�}�f	�!Ml��5찵,�=�]:
8*3�-BƂ'ް�O��=Z�����ɜ,ɾ�O�ĸ��q^�Z1��g���*)��(ײ��NC|�ީ�f]a�q:��!�Fc�6�f2��&J�ʲ=9�`���$�nL��?���C~�`Ę �/M-5[��uR��ᬾ��
� J�5A ���^	m0�9�~��G�&@��;�
V������j�a��B��1
C�p.��#�VX�WE�+a�T(�g��%�^LG����R3^)vo��5ɞ��WU���bٸ_��$ә��S�3(/���|e�M��fě��7��O�����S��^�J�7	J타�g�U����+ ]ݚb�d*'◭��Ϋ����q��sA���j�d�����lԢ�09���0����6�u^.U�_�I���,n\<���1~��]ߕ�68��=rwc�D�)�QIۑ� ���g��?�1x"���=�̛ƞ���콫��5��H�+b�-�?�ݍGS�K3�]X���Q,�g�?�B�3ڔq�ڙ��I�`�t�x�36����U>X(KKn/��n����0m�_s?c�/C-~����ޔ�����r}�Ѥ��MU��[�#�$1L�Є|7�d�}aV &t�`˒�܄X��<��VH4�_'�߶#���_�a,e0�H ��͗-0_z�.1Z�Ӿ	�A�w��~��vD�2����܇Z�Wx������!}��A'�9�go��b��x�[>'e>A_Ì�/X��1�)�8���
}���z �g��l"�%��9mt��x�"��]�8(dуy�;$w�e��݇��ܬ���b�+
s�};woA.��D��{�ֹ�-5�.4�z�|/Qn�L�:6P$���sEgX��(�����r�d'ٺj?68�Y��?r��3�A.)W�ΏQ���Dq�A��(%�s'��%��R�����I�DR��h�<��g�[�W��^Kk� �KZ�&��䲲��M��*�DS��Y���ز�b��j��ݤۭ�65?ٖ�@��������[��	�`�����QɩU�����ܟ�X���<�>�4�'}Ps��p�Ϻ:�iڻ"��:x����m��+fLI����_�O#���Z�Dv�耋$8��I�j��X��%�q�	� #|$VB�`����p"p�^�x_�����K�mE�M�5�^�9�7t����o�&R?7�u�b�fL����9Ҙ~4ǯ��rG�l���P�3��0�&Y�6�r�}�����҃��Q�"u`nnb�����D�@?�wrj,�$�4�Y�Sk��`�q �:{R�~��^J������7��`�� ?�8b+I�c�r_ܠ�,��|)H�o%�qdja�������3'�om��ܾ�
V���<�^牧Ԟ�b.�d�|�C1��E+�O�D�K��$6����b��~�Rp`_���(bֺ1�79ğ���9����n��+v:"/C�D�P�EFWrer�@/�!�	r�����3H���}���l��4�PAY޷0���++��&-��p���Ԥ�{?;�a�ex7~{G�<��E�Jx������) �Z��N�[�R�|��J�(Yυ��j�}U��tc�����&
�}��	42�%O�43�}HXQ���zb�L��=ԅ�D�E̬kǏ��#�q���6�>��s'Q�L�6��aY � q�M�����䬅�	/�{�D����$7����$����o��h�ߢ
D>Z��pa��|y{���,���Y��?�?��#�I�3�� ��	�bf�rT�wx��|: ��֣�%�����L���������4�}>p�LLt��T���i�z�Xsn��H��
�&.U9��;��&�XX��؊[��#�ׂMcj�7O3����E�f;�b�80����B_qF����ِ4�ƻ~�g��R�������sZ#�\_���8^w��m�Z��:0��#U�.�~� �ȿ��̺��f��}�OS�Tr3����J�?,�8ؽF����|���0oݱ��י��Z��z����y?3]k �M���ŁZ�2Xu�'��w�uĺu9�><�0?�E�n�y�PZĹ6��������_bߘ3|+G&7���2`c���5�1�5�mlV0�*�����n۱��(�7�jxRp�E�@Yś��1S3l��DFqĹ �Ʈ���Kp]��5�C�	�?3��{(ﾫ}=�����e�.��o���ƽ=�-�{}V�G��
4�gTv���;�[{���F���>���WM�>'n��I�S<�����ړ����{i�;�ɦ���CVr�L��b9VT�S��YjMZ�ל�Y�� �+{J�LX\��swp�K�}�ZOb����%��m��zx�@A�pn���
���Īm���٭SP��` ����ʪ��M�K�1j����qa�<籀v��p�@�����]�����f�u¾�_����/H����%��}XE�	�2$��%�!�����3�">ϛ佻�OX���["���s��j����;��J�<�^K�GA"D0�u��f';��������y~ʜ��.��Q\�.��� 1�ۙl� ���0�]��M��N��尝�nx܃���#��=9�ȥ�x��*��ɬ�B)#����fy��}�U���Cp���@<�!!�I��\���Q��ؿc�r�o!uRR��=�΀	n��Bf\�^A�Ͷ1�"U�񸘼��뢩�#���G5G��Ō�Ak���I�Е��$��� ���D$�(F- ��Y��F^/Jg�ו��;?��!q��8�zw4T��g��^l�GJm#*uÚ�#*eJ��>�������f�76
��V�ȫrb��O.�`�����b�g�.VJ�>o�TFkJ࿻�H��El=:z�E݂�m��i��`�վKѡ9cx�w����EѼ6���R������W�'"��U�ym?��đ�|S��Drw~��#����������>W/�������L�lu�r�T0~i�1``��w#5��w��ׁQ�	i�g���#�� yzcf�*����,��|?����Ub�KO[G��D� 8�(DA٨�Q|~n������́x�Ϗ4�WhF=�Sm�Ҕ)����&H������G�m}��y�v��ӥw�^�y[�jN��=�AVU�4C6�k�:�C�K�X�t�1,�9�v
�v��q�4R^kH���)�zf������ ��pd-���0tQ��y{���
����©ޙ����忣\���r�"��i�oڴ��>�.!G�Gt��`�5���YvP60J��r?�i�CVs+��C>w�#!Q_Ѫ���~=�&�Y����v�(�&'v�q�fW�(<�����v֢��iGz�
��v����͵T�/��ڿ%43mA�����	�PN�O�v��~NlC�`��Z�-^�&� T>��iT�W���f0��[���1��e�l\Nf�kD@�����N6�����蕱��.��m���q�:�^@�咝n}|�^T�l$I�� <��,�P�s��I0���L����C�}v�1i]����_6����=�(/�azI��h�݀߁t���n6�0�N�k���=��x7�[���	\�SZ�������X8�Ȃ�F �O�+������G�z��^���j����g�M2� �DH\�y	(���lŇ���o�܋ޗ}���1�xM��J��6���f�Xsk/'n�b[���_h��H5���ԛ*�CSOIýή�Z�.�A]�I��u���V6��\iX��:`�3�Jh;�u��ʦ�5���z�E���u���W����6D�!��榑��ŉ��I�yD����rفM�\I������7�`�U��!�a&�!�Z���s��%׊��lw��qo=(��m�`�kx�s�?7����j�}�� wn��YȜX��<�s>����3�K���쥥�N�N<��E�^�l*N�`�g��Y!BqD���4�P�'P)s�}�A_�X=��	�NR������6mB�2~��m���1���ϛ��u�W�4$��n�,�s��&#o��;b�#����۫��O��8ԋ>�kp�F`&n4lF�<m��zp�N�_�e�_�V 8�Qꀉ�6�+C8�W}L�t[-�KIs#�5"��$"�
�B���}��:(X�m�R��a| ��qo%3K��v��9���s�s�:��葯��(ڌ��d�^�_����3_�dqQ�p�2���l���ma����-02Z��'�P&���r�'_��㇁�hB�=��έ�B�F:��a���3L`�U�i:�N��B���c���Lف�xx��u���y�:jT|�"r�.�m;�����J�ق"�� 5� �y�ysxLt�����NpܒEwO�o��x�4�X ��ʯu��{�_���OssH�
��Y:;F�[���Y����b�'����#	�LY�9�����G�*�'�.�o(���z|�e�_�U'�:��M.�_
y����=_�[_G�W�|ȴk^b�Gz�@"X�0u����XcT�kđ�O�S' �ȿ%�,r�.���f#a��L]B;~6Ǝ%4�'�_�P�Qvotk�Zp�[�[�;»g�X#M��N�_�Q� ͎҄Z�������3�bi>E<�V�;;M��b�]��"��׳v��!�z*:��B�z
��o&����M�[��������Ǧ����ծ5qS)|���j'3�[�OE-s~�)ذ<�Z�<2`�\�}yb��K3�k�)��X\�|bg����nKq9Ih����j,|�|{*4&c�yO�$sΐ�#��]L�"��(���n�a�nHK̊�gwb;ě���?�ɱ�:d��d�	�Y�^[����O�
{<�hj/��[H&�4��H��C}@j"�N��Ѽ�8�Eb��������6Ǚxl��M�k�`��7SCT�W��*�|�����WB+?`��c�R��L���cy�;$_<zv�]�P�ON�9(U^A�4H�i�`��&A!�C>��}7F}�>�ۡT%�S�{��<���_�t�suWG��@�'K�z��f�uRH�q��!�!��s%�w����A�	y�e>����O��Z�l���w~�^��R��b9�>�����o;e�$���r;SҐ��eyl�|e�Y��Ѱ���.&�hW���Zy1kmH���wC}X�=$��a,��H���waͬ�d��<U�(*Wz���
ӊ'�>��ݮ?ᕔ��UN�2�r�oQH�#�'��"3�D(
g%��cx_"�M6�b�;x�P�&�+��2ۨ�t���Q��#��}�
"�&س���̑x���4ܘ�%	�����$E�iӕ�ͽ	D9���#��H;�mQ�y�\'ߍ<�䵗<B���.㖃��\���#�o)�djWϙ5�}�(i�_�w��5�D��v�/@]G�ł/�.S�)����ۊ(N�nr)�L����V�9�2�5Z�~nV�壚�] ����-�h͊x��:X�2-��qr:K���ԓjB�J!	�'���u�ޜ"K�Z��8���!��F��$�Y�79���cȂ9�c~T�9Lb�{��|�@`�^	�{����fӱ��a��C����15�Py�[�<�r�0��tK	#�����XEa�����ָKң��*$�W(IB${rC��a��!4,ȷ��q��$�tR��z�%#�B�^%	����B�2}��|r�a���do޳n/N��H�zj1��7��ˌg��,����\gp�&�`IX�[��SՖ�D�ˍPh����Y��r�F�≶��r�ӄZ��h�\�7�WԨ�+��\���͸+>p��v`�.M��-�q���ǵ�������z�T���:!�����[�>Fe3������&�����-�%?��#i,���U'���k����E�WԴu��`c�*K]�V�W�Z�i��>���R{?�z@��L���5kj@v'��9����cį��3
VDL9�����Ƣ`�SԺCC4(���}�o^/Lp�chxmJ%3ti�����R��@{�\�#�=��#o�y�шB���>}�`�D[��D� f�u���cNN���* �0�/��u�$��v%(���w�zf[�P~F+��D�Xdu���n�r/�g�;��6��M()i�!jx���ɳ�h��8�����;�o}Gw����Ӻ�>�_�Ǖ�I�x��D�K�Y*L�����f]��*��0��zw~Jb�L6���"ytv$r��<yU�R�SMj6�p��[B�^E�c�t;��pc#�E7�8gb=��H�"<�Z:M}"qX�?��L�6� W����+^�@yF�'o���6�/rk9h��"��7�῎���>/[@&SF�^��N�A��~gxg�i����!��ɿ��9�Faa$_�d��?��v1�iB��C'��Yj�)��M�;,��\j�[��gm��_IW����6_�ApB�_�`|�WQ�F4�v��ck�����Vu�p'���:Y)wP��D���m+,�-�p؉��i �ƷqN�깞vЄ���IAs����*����s5�e�"��$SU��4U��s�'���Cl��K@\���b�a�2ݤNn�B�p�%G�~�F-�u> ��Xv���r&��#�L�PXRf��U�S�/�U�:���0l#?-⣟��+6���RH�@U�Q����/ԛa�����3S�"Mb�Q�O���D$�&���l�-ړ�#�M�Y�l߉2�ې���wV5�]�ދX=�c)O�ĭ�xCc:䏎r}��P�3�Y�98T�ӧ*����Ya�T.�N(WT������7{KfǩTq0"�'j R�LaU?�EN��¡z��E��ij�q�������D�UR�C��D,^6I ��k�C�v'ܘ�R���(L�%��@%�B��.`��Z�hg�m+Hy�_��Y%oЬ�rF�g�Py_jȷ3�����=@�wQ�@�S,�v�0�d�tZ�5�)�� �r��A5S��c��V�P���\�x��Am[�ƿ�̒��͠��ϠC�́�ߜ�����΋;}Ƿǝ3pAN-~�ĩ�����Rp\
�B���eY\�T�t�K�5M\Ɛ��8� vڥ;F��C��Rb�����+ym#�p����
QʮT@��ᆏ��(!L���U�=��'�:c�֖ä�g�mQ9;g�vJ�Y]�_D�x��9Q/���\�g����_W�*Q� /2�����S��w<l�eG>O7��۟Є
��6�f�C~$����2b�jZe;��߈�z�߯ Y���IVvF{>�*�A_�پ%UKW�kE������$]47�\�qT��nA�p9�X3���V�!�sƛ�P(��غCOFjH�aY�
�ÞJajzhd�1p��a��5�l������G����2=:/;�������b6[�����~,�f��\q�qCb��N��p�.�&�}�6�6����;�s�F�W�,o���5N��^�tJ�
0�0�r�'���f��u�Brߏ{�PMk#�ԃ;Eᚷ��LU �k慡q`؃�wd�7#��*��\B'���z���;��`��
��XZ�b�.<g�L�ns�螨Ck�"7ک7P�@�B� ��^��ZS�JU��dJǤ��Պ�����)����$a�ar�u��qU�����W�@<�\'�7�[��+!R�5bX�� �PQ(`������S�^@iH��\ɓG�*�k\p���opfU��:Ӕ�{t?*VHe�����i��[Z�*��]_�MKl�[��}p��i@ˡp�zZ��.V�Y4	 k��^��+��A�,+��ez�(�����3�eZM���ŷJ�@���<�U�J���7
���&�\�r�;�A��tS��vYy}=*��9u���pA!�ډL�f�K�8aPu���� �B!������nӿ��J��	�İ.�6T�-�� �H����,�ف��L���4�8G��}��j��x�V6�U��t�Z�>Qh<X������G�6��~��=�Q�soz��½]�7��!n�O�4��fb�¬ObiDr�q�w���?��Y��k��}D#T�M����?�L���)m=�0�KWZ���J'�|�c�e�ӫ
3#�]��(��7_`�0e����X�x��MN���P\�a6ɷ(@�)�HY��8�g�� ) MK�e���%�*ջ���������Ҫ-~oȒ���\��?l�1�V2f.E��Ec=x�;
1��0)�U�b�Y�/:W�j#�Q����
��>�]����Ծ]c8(���m�7(%����n���@�!��;a�J�+H*Ȣ����@-��(��Z,}�O��~j�����å��n���
U���GA�oT�C��4�	t�c"�\���8 qȭ^�%��D�,�
�~Mc��6|:���z�F�v�Xciue1)A?a��;2_I ZqHa#[�q,!�8����Q&9��vq�4�i�r��V	�'�7n�w���3}P>f�Z����Ѥu|�`Ϯ@)�Ǌo�Q���Ɛ S�0ʨy̆~:���WE��fi��Oxt�9.�e]V���A8Ĥ�5�+�X���Xe��y��f�]G���P�̂�"l0���w8`�����,��БK�1�+�%�c�靧sd �F�����[A�%���)��&E�h�.��1<��l=���D31Žy��!]�.�!��'_����>Op0q7�簞)2�A����[	�c��-����7��'>I� ���7��	�Hes�̳w�γ3��A�4<���bA{���U���@���Uޯ�VP��I�X=D%���V�:���?�H�%�����=���������5�\W�=6kkI�����֗I�=�B���;~�����-^管�}LlB�DWv69N�9�T�$�=U���.�Җ��)�N�l��h%
x2h���,�����Ň1]`'��Z��?�ǻ���jT1�qng�sǪ��@b 4'�`B�Ho����w�i�Q6OF�� ��c�0�2�=�0v�i�#���dK��d ���
�D2�Ş�Oʝ�i hY��Q}Oc�H�i?���U�f\�M�&�BFǊ���ը?>Xb/~�p�q��)�R[$��AyH�Q:<�A)���n�~�b-k�إ��  zG���D|kh�D���PRH�eR�l+RJh4b���w��Zv|8y�+'@�!��Z��ǢI�Y�`'
ͩgB7�~P���]�	��醠\aK�����q�҃zͳ\�4��CΘ�=�6I<yP��j��|.}�U�bze���������1ŤyB��b�h���c��^�=�p7�d(�OF��񢂪!>���:�+��i����x7D�?,1���n�F�k�\�?�ED-mB�1����qe.i�k����&p���`F8�üN^�y�3�mлʳ��5!�,Ҷ��e4�9j^���rqY�}�@PSgDp��*��y��8М�!?��sb���6�97�����E���q���<:�	�+D�D/����$B�Vz�rf��]�����r�|�7[���A�#R�D�˂���jG�����ج\M�bϗ�Ez�-t���I׮$�	~��� 3d�B�/�����=-\�i��e�55�����e&��=��3o�t��8��5XyqzN;��� +*�Ǣ�������A_vU�!��=l�#�Kr[��w_�4����N�g6�=|l�*��^��g�K�&V#�ߌ♜6.�WA��S���Gz��!*-� :Y�Dw���t���9o���Z�W5�fa�VCMZ��2]�9 I[�&�w��PIs�Sa�bfGFEڤ���q�6U� ��9���|�K��I/�D��	�'1:��5DXCspJ����Lۄ�bDV7M f��)��#�| ��:b�7���z������č}�C���-�%���g��BISu�I�6泵Z��\��)�o�2n�
~2(��L��qB�v6Q�Q���	}ş������3� 9�c��$&o	q�{04���!̼w��������nJ2�%;�����k�^͏�a6����ɫ��32�f�+�"�ߝ�%�����&h�~v*����&o�R�Q�*�Z0��5��+T�,; �&�p�<Gޑ�W��A,�QGO��C\im
0/�e�70��i���8��bys0Cl+8J�2��!B�R� [WX�������͚�i����Yӥ��B	�a]���#�_cJJ�_���(OS�TR��V��ɍ����ٝ�]�XVg�v|�����eu����+I�����<�3fg��J�5:8�!z����)=]��TI�d>���:���X�׃���!�W����rZ��ƌ�x/-M��C�-���^=<r�A�<ި��8�5!����pJ��+�%���74:�(u���f�����:ۦ���Z,��Fv���(Z�{?��Q�ˎ\f�>@��a�Ӡg'Uv"b،/�j�R?i���/��|���d�΍�LB�fc�p��M\K{Y�	�o D� ���ܖ�W��E[v~�s&L4�L|��q`;Io��'i���TP��$,q�lL��@�0c!�v�UA-�6� ���]ڿ�n���X�v�ΓMʉ��/�����vW���G��Kt���'r�=�e��@J0����0y�z0Յ��,-�IQ�v�}��ֈF�`��bA��Z�6B�>������K_=�>g�Z�,�f��㮂t��g���gt��[�t�Ie�҆֠@�
U&�>>�Y��Ӊ�#E|�r��ƪ���Y�^y'�%�c��Z���#3�n���V Ǜ]BB� �����)\x�d���f	(����4��H��Y������*[�y��$l>BU�Ѱi��=L���
��S�
JP_��>\pǏg��r*ѧ6B !��G=o1+7�&
ʱ3�9��J���ǉ��j�y�;�f���I�麞�H 7	�W����郹����`zc�ll��-I�"��]s�������>�U��b����Ư����53�q�C�5��j�zɝ��'��|L����Oճ����U�Rڹ���\��ZNf����{ܛ�Ξwh��ҷ��)&��?D#}R�b��'Ϛ�o�-{��_���U=���y���ְTKs������㐆��ʬ*v���[�O��Cu?E�r�j;��-���ە7NG�DIZ�J<8�ٱ��,�)rk��T��*!�*�u�g�x��D�qw3Ny�+���CR�M% gx��VvR���z����h�.�k�Ce��o��& Qv�І�6I��8�-#��@BWN��g8����>�k�C���_�O�p���\��o�mzc/!#��.��m��!���x���d{�1��Ѡ��[-2�Ô@� ���^1�[������ou��=�B�v�������=-�>��'NHW�)���K�L�gɥ�`n�����i�f���W�L�b�)�[!�,1���M@ю,i�Z�'<��F�B*WC<y>��(n�/M\��U���/�"��x��x�`���j*�F�肎�J)T�v�H��"���(�]�p����o��)�<"��WMg���y�UH��o9�*|�B�V3<;{�͉���"�n-�Zܦ8�$�|LXkq�k��v�KϚ*���7�)H}�7��|b����lGf��,��"�k�'t}=��_���������%4x'&E��ii��R3�K����"n�˄`b&�%Pj@(3a��X���Dz��`�;b�7ʕx˔
҂�<�y���Jw�,�����>�����V��͋<5�����wX���ۀ�k���c�^M!��̿V0�󼄥����^>@D P=����&}2U�E%���Q];�k纯<�,ּ.��i���e(��s���;��~!h�ᒨ�h2�3��ԧ����ek�+��d`�����v�	�+�N���9�v��0��,/A�Y�7=2���7g���o:ߚ=Nm��Ɲ��_�"���aNc�S�)r�a����_��YcrY
��0�����f��b'cM��� �1�{���rGU��=i���;O'pC��[����������eq��-�Ac���o�����:�\�#� bB~�lZh�z:IX �K/nKpдrK�����l/]!�uX� ;3��A%�Y�H-�I�Tq�J5�c�h1C���%�d8���v�����ճ�����rط�ƽ����_ .CB�9O�,>�:M��Ѷ��#ZW6���LE��P��8T�����v��xm����w�g�����}�Jwf7� ��q�mv��u��/j7�:d��>,n�Y�ΔbA����&dT�����P�wڱʓ�nR�+�cl�հ��(|�3$��)g���`�c�y�j�7��.z�cu�#�|���`�OޠS��U�*N2|ID���i�1��6��:���g{N)�t�s��iA��r�O��l� ��)��
t�E�)��"�oE�����ٔ��A\�'
����m�%झ���\�����>�q��o�'��K3�96���ҏ��n��O@t����P��Fm΂Zl���dc	� 9��/�S#�+�� �6d4ұ����K�¿�ʚ��GJ�D�KM�R}a����x¬-���S�t�LKd��b6��Z�9�O�7�-�x.�Ԛ�ߞ��^��"��>6#6�a/m�j[U�װ�~\��2����8�lyֻ~Ե�JgG��a:sǜd����{�����٫��X��DP�E��$���5��q�PP�6zSv�B^q�%����1?��Ibr�G���	{G���í�����!ɿ��|�:�eop�bǑ��Fb�����᧤�-+�C�)[��e釳�	E�8�1�z��q�aH�M�����ʽF�
���7�x��D���3L�w��qT7PX��W:1OQ��b@��(�XTI�5����knE�O��*[�P��'⭜8�P9������J]-��{ǩ�:{Y�͈�s�5S YH�����^Pj@��3.��p� y��X+oiݏP���U�T�#8�]	:�"q���³��w5�����R���� �FA:�o�GV���Ƌ�n��BW�T�4�J����TBd�"�#�����T��M�\��*�jL�Tb�X*  �a0�97$'�D��)C�/m?N��L--QT^̟[4�z��!�qB��O�Upt�5��j7�햷r�k�u=Y���%�r�z�i�pcʬd����䴭<r��K.h'(�7��kA,`8��1lz���2�=�L*iJ���)���&�
H%��kv��`��i�u�O*��
s�1�x�����r�H��,|�z���Stxq4�[��D�pz�fߧ���JL�g�v���Jm�����*�n�8��i�]�!�s�lĆb�5��PX���P}�3�X��&���`�������|;R����ǆ7����#�_X�]�Ӑ�1��q�IKBTA����Y�-�)�$�V��K�U���V�;��P7�m�S��~�̕��E�V�55�u;��r�KA}���)���U�P6A���P�/+XV�!h6{����M�g3��f5�<	�'V��;�������`.�@*T���&L��8Z &W���������C';WR�g�Xz��v��ck��������W��"wF+��j5u���R����-��צ)z1��t4�!��#� �!q(ia�#?Q���ԝ4�������Lr��3��[��ИQ�^�7�W~S
��>	/نm��K�\��{J@�R����LtdY�!M}�-��� B&��;-V´��x��p��.��<�`x!�������~�D.2���	Џ��nr�x����U�᥀��LOT�q��5j�z���+���|��Z­��k���[R��HS+/ڡ4�$�(�T�]�لa��L�0����uT1������ ��� &2�+:�o� b��Z6�ڜ�l$c��ڷFS1y����Vm|q�0�~]C�˽��`��d���cԸ�ni{AV�񿄁;m��+g�#�,}�`�H�GUm��-��)�G%#o��Y��d�&,8W�ԿaO�
k��;�Ʒg��p�� 	"����y��V�k���cՁ`�޻�7%��~���]g`��J)#�%��C��-�X�m!��t8"d�����$�G��(Œ%��h���nՓ�+�1Ӡ�W��S@���o��߫�@	C2=? |!���w�+�p��ԿG�R�Z��4WO��%��4���0�Q��4���"�;�O��݌i�&��9����[�+�����{�(]ߍ�I�ɋ;�	��TAn)8�k�T��/�{	!Vi�#����`+�BsU�`�歼����w����f��?V�C�I-�
�F�!����졬)����S��8�l9��{V�G��"�.k��@:'���T^��5^1�S��h��p drXP�!TT��e��O�<���:�$�z6�{M���UT�r�Ȇ���ǵ
k �ŕ�2�\]YI?2!��װ,��4��@!ǀoe��U=O8�vчa��X9}HAN+�
P�/��~y���9�i�y83��Ȝ�zlM^ZM+���2Wo���7D��KR�`�x���(l�e���K�I�TW~ulB�FcG���$ ��)_�BҎ�Ӆ%|���"����!_ٚ��o1���C@T�P8����@�֠$1��>��������-�U�%��=�|q���	+���Y�*��B�D��K$�d�2U��7t'	��ۡ�c��;���J���8���,�� \X]@|e�/�����C��v���?ԁ�	�i� B����ˇ���ͿQ�F�����  �{#2踍 �����jm��g�    YZ