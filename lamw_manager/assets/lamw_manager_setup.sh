#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2079389286"
MD5="bdcf53aa01ac933376d8b5d9b5ce5ae9"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20820"
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
	echo Date of packaging: Thu Aug  6 19:14:35 -03 2020
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
�7zXZ  �ִF !   �X���Q] �}��JF���.���_k ��Ͷ㞎(�4Nʙ����=�����M�Fl,��P�+�b�U+��s�����|�ߠ��ƅm����M�]�Y|���sn��S}�:+vX�1O�KM.�����L�i8�B��`;�ʑ.qN�	�Z��d�����K��������E��;�8A�H1�ֿ��8��w;�t� �M��9��Qt���P�yݞfhz���߄�\ޕ� W�<+K�2�v	��pU�(ٔy�<�^l�t]�}]H=^�aH!j+���΍x�G1�w;_Q���=�_�g}[�s&�f�o@ny�}6�J啜� ��te�W��c�{)��R���hLf�YY; �Gr�EV����T}�82��T�ڸ$=�VO�ϐK9��֘�����r�+o9�6��1
�ʇ2q�X����B.�๧k�8��L�"Ka�h\{#+g��in�0�PT��SS�@R�/CZ~��X`�𤳽�Sz�XpXRc-� ��RVh��+�l$.y��i�dS�h�� f���&��/WXM6Ac�Z�'�ҁ1�'|�m�g��R����`�5�n�9Ԧ��.��嗫���R�(�@���	3��e����~�po� �hT�o�Ī�.�8��C�;� ���׽mާ�Vu�'P�s)4QŃt�9S\��S�l̋ɒq|t)��w4ր��k��Pi̻ �#�b"��&�g%,6�!��66��to�8��:�o¨�Uȏ��~m��=U�o��x�լȔ"<�^�!�����6F����N�l���Z֍\e3z��S��>����T��#�k��] -�)�+���(?%��'#%u�h��; [�wB���f/���`S-{�R󢌲�eT=�oI�t�d2�A<A���7W��Ia
8��yס(Sg��*ȲF2�����]���g�s��Qt{�*p"�Fl'H�a&˙1��.�?,�?�ZB��
�L�H�<�TM"8X����rh���.>�H\�v��7�3�r��(Z������c�i�=Yw������>�a��ʱf����hy1�t��)=m4�f�k���4�3��e�_�����.��o;�ǳf��	F)�|f�e�>��
�椿=1Y~g�(ֱ�ݷ����S�"	����C�u�%sP�ҧޢBM�&�SO��/����+����?ݝ7�D��K�N�6��xVz�L�e����_�N���ɘ������Z��|*,E,%k����޹�.nɛ�<,�+D�«Cv��<#N�d�	����&���A
&Rk?���Ƥn+�P��>Nʥo��@��p~ҙ���+��f�n�/��Z ���V�M��7�c��� 뮯���@/(����bIx�]A{U��5(��o�w+Q"�rs4�Ҽѝ���Iv��a'���C�
(��SD�j(L��y�^8p/T�xdu������/s�@}af�&k��pV�Q��Ho�g�ӵh+���H���QOm��m�4��J���h����/�V�1���GےƤ%�|[��䒉���$']	����'�5���y|�����23�qq��$����sv�!lu<���*siK!g������� �P��I�#wA�7��F��Z��pP���C��@�b(#�7�$_�s��Y���v/�@a�\�O���tG�F!i{�z*�v�:�/Ւ܆��U֚+a	�P�����8�|F���ա��$�E,ߛ��ř<�"���o���pm�N�i[�;e�g���v��Y�]r��4�W�!��� b��߼B�bɟ�	��񖹖�����YV�#D��'����n�@F��.'����S�PY����Tb(dŪ�_ou0�� ��2������ޥ���s�0~�~� �g�V�K����١6?5,ۍK�M��&V�Ùn�kSs�1�K�)ى���"���I�<u�	qÀ�_6υ�� (w�~F7�wp9�� ����Gо��=dI�=�"�ҫ�6��r�Tf�n�X�֍Z�KS��7���`�R{,��lK�He�� Ŗ,I��Uu��
�*��a�)w��n�_�+�]�Y�öiKS��k��=��hcx7_�r肞���~�#H"Q[m��H�ٽ�5�
�쾷J����3%�Tƅ�ꁨ�G	8����~�,�#R¹!~҉W��0kh�#~�eD�x�.wS��g!M���ؑ����93ڕ�#�u�Awz��逰��#�n��Tp�>�s�I��w�X��`�G����5�rL��0�����*w�8h�� ���)��y/xIW�0H)��K�aa��'���@��'̫:	>�q�����������$�w.G:Ƃ�
GmoZ��MH4Ʋ�D�rN�?�� J�Xό����R���,w��� {����q�����s��G�+��e���N'Tu��H��8%�6� �ǂ�T�e�.�A����"����9<U��P��l�����0m�q��ٓ4YF
�#N1���:!�1��o�M�������|r�Z�:N,}�]%��1H4����]Y;�4H���M���N	��f�2��8�<�%v��~��p�+*��XZ���쟒$b�Ҩ@F=���/�&`����6��G[�n�ssϖ"[���,;��Y=]���V�A>�3�?A�Kn��ޅV�Ko�(y��z��tΨ���T�T��R!�5/�8��$�Y��P���%W�p�`�j��A%��o������Y�8��i`#�^}ϊ{'q�L-�6��8sO)5Vb�<�zJ��!�:����W��]�ik7o^
+����ƻ��{u�g���U���"�F?�3���=${?Ċ؀e��̑��@�%�&6Z��V�S��U�&S]��o{�w�6��a5�~�D�qz����r5L���S�|7%�BՄϿ&@�՞�B����]G��VV�R�+F%�ʲ`	��O	L,+����8��_nMzΈ�Q�����d�̽r���H������j�1�bFJj�rM��5��A�g����[��CѤ�Ni��#�c�d�?�7^�c�1d$����<4E{�^G�e�s���Ci�m�sˮf`�^��v���V��LfsŖTo񫍣(�
���c0-�)*a�v���$�>]\����2E�W]�zfCg�$��L)��/x��-��G���K�����?�|D�#H���M�hw$��~g�$1,�Le�H�w��y�����C.��ҰX�l�ֲ7�N��5	=�*7����w�qY�t�40��#n+rpLخ3HPm��Y��Hx}XG*=�I�X�c�ڐ��CJ��lq���$��L�k���',�f���S�e�XU�?��z炧-'$�i�0��x����Ds&����� �'Qڳ1Z#6Sꡁ�4J�st��a;�.'5���� �:����HW;	�Х�%Y�������RGt��p �[���Y�����]Z �9�}q17:�(zdtL�@��i;�e=ӓY�1���_Gru��^���6�{���v���ˎ[���g�5Iq[`#� p�?�ta9�,S��bȺ�#�T�Q�$�H��B�/�ň�YA���
��g#�]� �0�>�-�����H�!I�$;-���;����$_�/J�0'4�8�
�o xhf(�x���T�l4N� n�ؾ�ń7�ޝ�U<A)��S��L��� ݗ���	װ_Z�r�NA"��C[XE�����{�MA9�i��t��[��g�q��C!�6�8�mSk��p��D�\�zxa�m������|A
R��v,�4�3�2h��U�a��jo2ܦ���H�5pb>���`�d ר��ig[�3���0/�Q.KӍ�����Þ7�"��,ߢ�9���ֹ-��x}Tr�[����M{	�1��5[e����ᾼ��"���7�Y���&�9C�3���3�[��
W��G�E>��Qbu؟��w$�Ĩ�0���p��n�K+�LG([u`�SE��M%nY?�b��x����˺uS��ن�٥����t��1�'S������|���L��e���Jcм���	���4/�)���M=
y:E�:O� �k���Y��`!��}L�����l�,`S�SǏt���[_��?4���OR����ObV�����%��t���u���X��_�Q~�I���y�`s�T�v&#6���	���T��p�k;����6 �	�' ����u��Z����Ҧ��H�������W���n�b�υ��P�vn3M�c`����R!�K.�j�\�(շ7��u$<OOil�z����e]�́�C<���De��Ԙ�Wu8a	i3�:�:		�Y�A����k@��!�~�{�x�n��L�m\�",�2źd���Z�X�V wh� �W����{��J4��I��<Nrsd����A��
0����AA�#s[�c��[�TC5��?Ȉ�����@��"ؖz�[�%,AF�c��&3�$�b��G`��5�vL63������l��r�+�Y�t`h�W3����W�Cs�#X�|p�[�°��-_�dˮ��z�]�J`^�����#�z�f@�/��19v�h��5���e���ŭ��a~�-Y�6n�j����{��^��[5�^��*�?�t��ģڛ�e=i���
,�A�gD D��r9_�u�W�} �@�Fs���ݡ���<Xy�Z��l;$T����C�����r������bq�Y��1w�u��r�2�h��Qֶ鷅��@~~���v@�~zd�S�#��r�C�%�� .�a'�PBi0j�W��:'-���*�T$�(,tf�a]�jO�Iq��2�4)[rR�fƦ�#u4;S�`hN�a��Jʒ_�8F+:\�7�b�R�.D�+tfG�ZbY���y.b�����M�i�LL��Q��Ey�@��j���>��2:�$Eh��<���{����rX}gb;���2F}�Vdpkk������R��Q�����VI���Dᝆ����Ouu%��(����е�ʟl���%Z�N'�a�,t��M�HfK�f��Q�k/`����/��\��cD��	oc��U�ڬ.�b.`�D��}��Ma�G5_�g���`d�nZ�������X��y��9��?DuiA���$������K�g꼹�]3�����D<��4	�r���H3h�!6l������]�n��J��y������f^{+�[G->D�؟��|U��$V�kM!��F�@��@�<j�J�{Д)�
�
O}5�����)�@�#�}G;C��oAeJ��*�P�0��"��O�
@')O���Z�ڑ�A2��9O@ �]!@y��=b"�x���E��*���� R�wņamǣ�
�����1w����<���"w�z��1D��Z������"���a�@4� N9�{�:�����Ҡm'ae��Y��]t
ʢ�Pє�������h�������M\�w~�f��v1ъ	6a�xT{�=X]����x
�x�-����9iZy��X�!�`f�y�h:
����P��jZ�sU̍.��lu��ȎF���Ƅ��K/�A�N�
@�p]x�(�|	�\+����F�v���IS{��G@�x�r��p�KL  �W�]b.�,���)P��Tc���N�<����w�JB�?:��[Z ��\��@yFv�)_�z0v�N ��jW�ە"l
k�PY�R4af�8�J���3 ��oX�����ia��{,��K��m)�t]�ܐ���Fs�l����4.ȕ���Jv�o��ɲӥ%��jI��;>q�e�Aޣ:��z>��)x��a�c7[���6�����\eFt��.�/�t�6�c�ӧhPɸ/C���Ñ'����a���:�x����@�Z�H�5���j�SqV|��h�z	4������������7�!b��k��[�o��.H�4��c�;�Q���G�~��)��k�Ȥ��&��n�j%�ӏL��!���@|��~�9|�����&�$�����̠�B#}f�!���_Ζ�v?�@��ۤ]TC��d	���4WYGi�����)
�7^Q��@Cmˋ�c�<#/M� )Rj�������5�� �����fQ�Tl|�g�z��7/v��,�~8d�0f�����4����>��X�&K1Ele�n��T�h'�����cv�X��=���LT;�����Sյ>���g��H#��LJ���Z������b�[����߮f� �EDJ��q\V�.��*;Ŭ��&/�. d^����'-���}dK�l��e:'�N���q�T�"�������re}���xD"��@�ο���~�b��~+���3������\s���K��?��KL��Z��>�5j��2������m�����V�I��MtB�a��eW!qQ�`'I����Wr̐��?3x��!��� flêd������nW������a̍ ĺTvik����P����F2��SDȾ�D��~�q��M2���w/�D����a:����-N9�Q�ޏ��V}A�;��*b~�Lz�SN�k�����
��#R�����Z}����e�_+L�ԅZ@��s�*����@����^腡�}��Y��P�����b�����W���6����+x�VB�b/���ksۘ�0�D���F3rX�d*�c��d����qH�%:�;_u�ɸ��E5�C���I�o��:�N�_8��9|��8�P�0/SP���$6&q�AjPgd�>�5&<y��g��9~DJb�ݟ��%���9�p�x��l��)1��U�;���Sv�y��ǡ��Y��8��{ގ�d�^�ˊ��I-D!�C���~��G�m�r5���*L7�'İ \p�t���� �Np�����\��ɏ�s�.�Q���؏�q#?��@VBj����P������rp�J��H��Ide]0d�{�����Pv��?�
�`�̿��Z��)������lJ�"��/#�s�&��r��cԸl���ص�Ib-.�غw`4� IjF]���,������8��p���o�|����h�gwW�8�TG�w|
T�Tx%�n �Q�PWnuq�N���d^-���1��nѦz�	�v��>�h��;��ï����F�͑w�z�|�[q�B�������I���k�� Ev��> �W
�9�QQ��&��c��/Tw��L��פP������yN[quD�ijR;�,�Y}�^6������;҆�J�I�3PZ�$�
Z�Jq������FL=r!@F*��~�[�i�[a�? ���j��/�Ei�VHq�oڪ�X�W�Zx6�R�:���eU�����
~���R�N���\D�0���7n�|�@I^���Oq/��Ѯ�RM���Ij��`����X]�z.�}�mg>J����.�PleC��)��EX�
���`~�AUvH����P���09�r>���}3�ʶ�by,Q�Q�7*7g]2�ɡ<�� �k���*�j�����Ǣ�G�^���ȕp�$R����J�B@~)����0�]ƙzϜ���g`hf�.�~!:���J�l�dN�b����7��"�;s�G���T����r^��Š�C�He�Ȯ�B��d-�[����ٞI�R�Ih��x�%�V�L;:H��yn~���m�1˦�Dh�^ހH��@~}/?u��b��u�K�%C'w]f0J���833?:Ԝ��)�i50�+j�Q��P7ŞT0�6�.�ɔ�&�,.��v����q�y�8H�.�z���SDZ�-
CᕥQ�҄�suZ���b�Zq��.�A�y��D}X1��J�u#��U�U�?�,,�^�w5���K���y���oTU�pd�U�@- �-\�O�Jiٺs����zמYv����z�Ņ���hG��C�wX-�-u�Z�9W��!�E[�j�b�Z���J�U$�_6렽������pEV��w9,�ԓ�ܳ|��=<c�T�+U	Q�d	�A� �YD��F�{|1��)�V^*�1^������g(x���T�V	{3�^]�z��@��y�p��#�Q.(�ɦ�E<E�5?M-�?-�_\d�J��M�Gݦ-�{����zC�1"�����M����o��T+��F�,��8&�MrJ�b�,�����S�}���<�d��]�	ـŸ7��,ĭ:̧�������ȑ��?0�Nh<���6!����n$�E�,�g��G9 :��Tc%��[gFD��w�F�3K������O�!�U�:�}�����vBx�!C֞������a�3�*�P8��D.D�"�ǒقM݀\L���YZw:`w�ݷ�<&D4/oS���hd	���?e����%�~u�/9����9�7^l��R^ϐi�v�جv`�U��ȩ�M{
Z�1��H�mĆ=6|J���3�R;tinC0��&�%���8z �ɻ'ٰJ�����7�N����{���-�6���N�vw���+E�C�+�?_�(�=,�6S��đ9^�;���QL+ehiW/�����}x[��]_ d	»�~�P�^�Q��6]ﺬ�MG��C��D�6$M�;�k~b�ZN�ѕ���c�h�5���k�6��r+��99��b3��e�8v�����ݾr �>�v/��[述�9EI3��rC�SJ�J�Ӓ�<�j� ����/!��}Ƒ�pZ�
���>WO;K}�.�Wҿw$�������U��7�d�吠7�ņ�/�Λ��4lҖ�w��n�H';g4�-� �
3��lf��Ş�M����m�Qv�̒yo{�<�N2:�ǖ�%0;��Bm8�g[���C�$nB �_��ş'Ow�V��-%h$j������X�P�0c����nӕz��8o5#�Y�w�@Q ��l�g'�����dք��B���S�{�Rۤp\O�BdBI�h^H�+�ɕAz�;4�����"]�(�E��^��S�5:���dY�~�i���y�Q4�=��-B�s��d��s#�	�V���T�����#��@Ll
��(nZ�∓�9�\RԽ{��Q�;U��5��b�p�#.+�=e�ǋR��=���(\�����*�����:Y�d�W�dRz�8E8y����_�gX�<��0Hב�$Ҙ�:G�by̤q�A�X�&�:��O�+]=~�?��C
~����P�����R&D��#�W���}^��Ĵ��J�b	�}���m��K�L��ʫ�(�����?,sܭjT
��X}���lr�^�8���ʨ��j��py���_�����-#A��9���'�EU̟3�<L������6'��u�[���CE�_����4��B�6/�[��?T�|k1���G�P;��[n�)�53��"~e�̙^>gC������~���5|�ߊ�_ kY��Z���91�l�KC{�KAv!��h���R���S���
JH��X�H渔��r���-�>�2�x;:}o��A�ٴwZG�3��VM�._N��!7>�>�ȧ�W��#,1C)�_of�ɨޣ�p܂7��x��"�ϵ�[#����p���~ǔ�f�@�������/�V���
e��/�=t���R�E+����QSI	*M�²T��W���"��&��GӯRa��5O�9�U����&�!�s]$�۩*�[�T���QQ#��3H�=�dNƎ%����'w��ȁ��N�r}�/U�O��R��0���>�?�[L���/�N\���O��_��9򔅊q�%� *E���~�J����
�GPo�e�̀U�b����NA�m�^l�E�G�:5�k��j�
���vo��稰�	P�~��"�.�Te7���ٞVP������|U}���r�qӰ���4�)0霔9K�\m�f�mhp{��*z/r~��OX6"fU�󭀘y�)@�a"x85��n楌���T2����/�dT��tƃ����R���/��=�	�A%n߂8gB�L�`��ߖ�kzpƄ����h!H@��n����xQz������s����3z]��
��W�֗��<UJ��!c���x��kJ�$��Ɇ�m��aQ�hUJC,f�V�������䉈,LaZ��{k��SdOM�2[�f%���%�!�g�!Z�GN��v�l \rV6Q0Ҏr��f��@�o�P6o��%P(9�A UL;�!.���#�ix��9K�|��8C�R���(/�H|�ߛO�ӗ ٹ���;Ǡ�b� ),ea�lt�����0/�MD�[�:�d�r� ��_���_��^L����6��ЬڳG��O��>��Q�l�$�bb���_;����x9D,O�v��Hս��wޛ�KD��\Ѧ�
-��sjRX��+Ƅ��(�\O���y�AhO���q�d���:�\��_�ao�N��	E��U�Ͼճ��h*���)"YP�+EI,L�?���?V�m��_ф� �5����B G��%!�x�.3���;H��!����� ��-zL5��r�ޝxA�]�!�:���X�y*,��N;�kf�ųg=4���`����j�O��:>� q}�q�g��;�*��,s�[�/���Tv�{�g�Q�t@��XgL�لK	d,��H��J�{2���� �x_ {�b.Cg c�'��N�X_���:�S�������������Z�3뒾����#�$a��u�lf�;Z�(���t�����;,��S�jC��kݍ�����ܒ][��lH�Oqm�Is��:f��u	��rg�**��
Bɾ�,ӽ�p��V.�
EV7���+�\�hS��n�� �ftSs��t~��S�O�N�I�fƋ}���˵���o��ϫFLG�4�����2]�Y��h��sS��Q�+��`�w"A"�� �,-F q�q���y7�y�����<���q�em�OvAv@�W��d��y���%4�P*����-�+Ŷxz�d����xU����ylv����&����4ŵ�5G��X����io�P+�n0�?/��#�ċ��B2:�����B]O@�TSJn�䘪H�XsC2�F����������6���IB=�<���*��\Sg�!�G�0�b6H�nd��~����ODۯ����L�6.x�9#�T��];ho�-
�K�Ȭ�,Nhͮ�>(.2�Iha��W~à�����X�⩤�.t�=��l�t��Έ%7_��*�ȁ﷬~�E+�Ƹ��*��:���0�o�3?��y2�
\s�Ue�(t�D%��<J�COĳ۬g�<tH��14�?�-K�Dw��z��Μ{��7�I#��|}�P��y���J���	r��06�7ڒ���O���{���;�G1�6?r4kC��q�u�(C�w�I��F�E�"0�
�s-��l�B��tq�Q����^ٖ$����$�����9+%�iņ�N �z@X�R�}) ���;<e�ao�։`���T4N�S��lxB(�..��#��\7XH7S�'H��VT���$#����$@�_�ޱ	���n���w��ˣc�_)��U� ����7�c��7�Ք�+��Z�n̝u�+��yuZ!�M��y��t�sC�%!12⢬Ц����.�&�B��T�;{?�]�op]<����Axm1>�:����l���/fl��w�~Txj���k$�&
tW�l�_j��^���z�do�k}���a<�u�6ZGv;�t7����Qy+��t��\�ˏr`�;Q�-�X���t�������G5B�Q��4�~��ud�����;df��^9y����P�i�Y�u�O�E��٬YY�ߋ4��i�l����	�%�8�T2WM��3:��ecg�Ky[F���*갺���O��ՙ��FW�`>��`"x���i��s� >�d��!��!P� i7���|M��ʳ?�{����ل���S8��;�-�=ېc��M^��XWڄ��F��Y�ϣM���[�CB��3-ш�#1TI�V��4��U�)��{p�\��^9�3njozea�|u�,�ܾv���8}�%g5ǻW��u&���&�\��]���N@5����ҫ����$�;�G%i�24�+��yq���	q;�"�E�U��&\�L0'3i_��ٱ�Yq	�25�_ߖ�#��r#���3������9�kkw G�������^w�F3B����~w��J��Q	�E�t����a��E�>�Fja}�ZD�Kd�����P�S<�ɦ�t�ce��;A"�~�W?{m��N�L�
e���=.]p2�Sr���ᩣ�W9!��pGG&$�H��o�*Yj�]ùe�[�x6��uI�M��	������ؤ�!���a�ĚZ�<N���z�X�ڒ�x����=ŷ�+���<CŲ}H�R��f�G6V�m#ڈasϸ���|�f^���nL"���( �w-��7hT���T�A�z���^��u���g5/�-U>�F�u�[�Ja͉� ��d�!�[����B�E�"��T�z'i��2M����>UH6*\(����P��0�6��$���?������_y��d7y����^������l��� �ݢ"��-e���*�bI���/����	M�����̱�ӱS���m/vjJ�K��d�?:X��kWO�ć��xv8^����n��v8�������'�SkQ��kV�1�G2�}���S�./���A`,���U>��5p!�+M��\��˻�^RLO�mpΰ�Ң�f�<֤GѺ~��_@�~�bG��M�7z)!�$L�/��W�q��d���Ƀ=S��o�~QS@,�2'Iqo5C$r[���SiK����d>��N���[4P
H�Ӣ�$��c���M�^�ij�[<�	�M=ކg!���C��ܒ�p�lz�r��M.�)B@J�gKqh>�Cl �%�%��H��W�';�x<�XRMA(�l����� ^	�s�Z~�(���U��}[�"YYH��MW�Z$LR8%7�DQ�P�IM�-R#c�W���p����]�]B��Jzv��zI����VF���v�b?�:z�����-�:�U����jn*����Z\_"
D�������c�����!U���xN 0JY�2��!ކ0t���]p��>���sL��k�`ۡ�a|xK����@y�]3:5��C�g;hŌ5�a����@&���d����+J\���� �V}�+޵���"Ѩ����O���,���C��>$�Hq�����W���.� �D���=8���dc��!�����Ǹ�SR�WrLc��U�85._������=�@�<1D$IIx����3�'d�jg��)+�[�-�	�o��7�[�*�=�f�%�ƔLg*HIV9�*&�͡�mW$����_i���+I��WU������!�6��_�{��t��t}nh�Ř�?�9ڿ��R�W��\u���*�-'�=���~w�@����gN��o�tcj��Xy�E��l��@�Vsn�/�c�Z�V��[%y n~a��	m��e4�F����n�.p�3>��=�Z$�� ����C[ ߹G��[���Q�F&TK�
�6����<����e�Y/����-U�TJg�Y�0W��5�FRK��n#{�?>���"����b�$�����}�a$����Ug��n�u���(�q�m�f(X����~uH�P�$;;h�nO3
~��Ŝ����o($p��ȴ,�YB
�m+��N6���]iRG�{�1�`uL��۔�m9��=�'t�Uke9�?͏6)#a4w��-dM	�ViR�E�����\N��Z���T��_�tF�+�ޤ�:�-�������J��Gb�U�[]r���X��ÛjO���ɓw����.���J$;��2�
�f|�U҈�$�y9lrιc�������`���C��Kc�5���.���x���eAG4��MƧ�'���HB�7�	ű����i6@ހ�?���魰$�G�6�:.SB�X���s�3��^/���d��~�����+X��:\m?�� D�6^Uq�|9[��k�����ɝ��C�j��	����d�?��J}[zK�P�V_8�������/���A̘���� ���W����U����*e�	��~o�uh9��4E��h�zx�ԙq� ����J���^�H�L�Ǽ�SD:�L-���u�+� ÿ7!Ɲޜ�8w:���?�`�<�G�li�Jԥ���K%������t��''�~����0�σ���@�ȨԌ�vˉ@n�d�t.P#�MG7�?Ŀʨ��?��E�,��π�<&�n�[��ԇ#�o2�$�Ը� /^��Z�c���W������nu�~��:5����Z�x	���k�
e�
Գ6��c��k��a��=AE-�O��s�&�Q Ue�Y���
��KR�!ƙ�Lk�A�&�Ş���{��;���/,�O�-�M�k ?U���0�ℬ�Y{F��gE��V��A�|�6,��/�)6�/�!��\��w�N:��=T�T	��4�!r��l�701�j�-r:6�K�cL�����	a�GQ� e�Ș���"��c���(��ԄW�P�	����j�ٷLN�}P�$gf��٧M�[7�ƐZHh�RǑ,�o�){�s�"���\V���X`� �8�67G�m��׭�����x4h�(�0��ND�_��w}�F�8̫T��@?��fp�;��M��)�}���D��j�a�lk�O����J�0����jc���>LU�p�e����Rurg�N �K�5?2s_s�{��@�U��-�B/F��*��C���4���?%�1����dʄ��CՊ��DM��������J������Ølk����,b�,� ̝M�ѻ�^�,P6z�.�t�Jh�J1�>I�\�U�S S����[qM�r�G3,� l�-@�����(�u�"��!��_ݳ8VWT�k1Z�@ϖ:"(	�Qn������̽DDֽ��"�b�
���D^Ӭ��U>�v>���)�x���v|��rA&Ox��� �r����Q�m�զ�1?�N�t�ǳ��ҭ1-f�W�dF��a�|��!A�N���A�7.��,o�YU����̣�����{��#!���f���������{a:���j}�8�(#�}{���r�&/��ƿ{F)&ۻ���a�9����T��zuR�:t��(��mwV$$�t�kG�b�M��ɬ���bƿ_¶9_!�6H��Ю�i9J!'����Y[r�S�(�}=��<�����f�Wnn��C��Cɰ��Q�f�������)(h�����e�#(F�Ƨd�7�x��i¡��WJ%k��ѹ���1�Z���^����������H[�\��R�ŬU���S� p�g��CU5�Q�3��3��И
b&�:�P^:%��_��;ӂ.�7O��Ǩ�	���j�c\�*̞=4�"�PHA���Pd������
E���W�!�5��.�N�`пfs��]ì�N�C ߱��"�u~������jS�vJ����.�$4s����X7��v�u���L��-.��o�iA]:��dX����ɿ��%[l�I�5x��)w�M(���(�j�靰����{_t��T�.u�uyEϔ��$��y��a���,AOEX��J��Kdө��V��j�1�b�w��m����*�.ܶ����:�m]4G
�m~^A���=_�\�QǦ����h3����۔Ͳ}I@�e�Ċ�8��E�g�\�s��af�&p��Ap��7k�t���ŧ��PZ�s����)�\2}�=�d��C"}�B,[ˈ��V�H;��x\������r�_J�,��D ��o��.>�]�N�����8���:E�ǃ�z�W*�MC����� ��e:���dU֌^:
�b9%�W��8M�vߗ��F.d �x�{!�*�OǿZ�p{��������TY���.`���z��Ͽ�RG 3��H����;x���U�@���tB}����L�S����N�=z�	����£����G��
���A�$#,/�G�Ү�am�0�I���5�Di,��c���b~���9#>j�j�V7U�:��A�ޔ�|���O3:��(f�Kc����jD!󱛡|���q�GPH*w�@�0#���~i�k6G, 9?���(���,,F!l�u����h�<� v���\"���Pۓ4�Y�㸠z�M��n��]bf
�Z���%��|���d⾡�/�CBtZ:�P�K���J��y\���!��q�%VuP{�`��-�)��T`΋��U)�1��RiV����Y֠��z	p�mA#$� ����o�9Ukq!D��z��O��*]Y�l�<6�ܖ��a2Ry�H��"�e(ɯ#�B�gM1�xM7n�5:��:���~�����K�yG���]|������#="N�d��m*b汬��ض���:�f��.��Й�N���$�Ӡw)�+�$番�6������E�����LU��[<Ɵ�y}�F�h�Q��x�SnAW������M#���3Zt��b�]�3�`��-��t����Y�w�P=J�'�n���)K������;�YD\I砪�e�C��q
|46�p8q�?�c˩F��ڔΠ�����1��;}��A��5ʓX���PFI��Y×|7��GƲ����� �Į�`�ܴ���97�t]��ac����wJw���o4�0yu�y�1(���ܜ
��-tǸ�@za7,4�^�gO,F�9�̅�fg(w��m���s3��n)�t�8>9�J��@m��n�i/�=6[���s
�!?g������`d"0��g6�U{�V�񔸵z����KhI��%��ʥjZ��`uﵱZ	�а������Y�/m=�3m�'M�.���9�"�.����4G�[B�T��m ��~q�H���%]v��*<��k���/��P��G�y��s�5����"rƆ����������y=`��q��ʛjT���d��_�T�/�4dr�P�݄�("Պ}��p�,�hfRH��5� 8����!�6Z:	5!&AF�[#���z
i/m�������H�5yՊ���M
�BT�4�:XJ/g��`�����_��a�ɝ�R�.��-4��]�wJ�戸��݀�}���X��F�fb�SUL�-+��.�u+�0V��A$X�����G�87sW�\V�Z����%LA�)Kޖ5mڼZ��uq�BMf�u��(fy���h<I*��k1�h����Y[������A}�z�O�R�q�L��8"P&T���ix�i��V���Ŋ�D���{�	����ܒV�yK���}��uW����4k{g��
W�Ta����6n[$<W�#0T9�;��	|�0�ڸ�ϾGI)���̭�Ok>#�e�z$uf�g���*3N���Uy�m�.:����(߉bc̍�)a�2�z��TWւ�¾�"� NxV]nȄN��^~ܴ�!��{����>ã���E�_	��G��9Blj��ڍCcRb���^���U9���6y��9'Hg��5�ё���X������I�A�8h����@����#�&�j#�zd�9�j�<7C�)���I�\��!����F D��Ί�nR���8�M�5Lq���E��]=Փ�j*|��hnb��C9�w��g�E���\���PA񀩻w��������hz<C�	o�v����4�z�aQ��/<�p�Dr�����D0��c��/��ĩM�H�	�Icʃ�݅��vcm-e�N*J
��Zx�aTE%��j�$�p��#�ܒ���~�{N���W_�  ��!����𨑋D��#�i�s~�=?��l�"8��Jgp���|m�s�7n8C���Te�EP�w���U��:+.R�{'�N/���x���C�g��z0�J}b�o[.m���lF!�Ϳ��@�����Qd��5T_����lD2,��|�J]����ubI�t%��������x1�Nd��ͅ���+�r�ܔ	�v&���\�����'TSC�x�1��Ҕ��c�9��SB]
��/�&3��a��Y7��mC�f�m�)-��/A�ړ��:�cbc�;'{�d3���˺<���¬`qR*�0�_����9B�?T���5���,"7�����ڷ⏄��ϟ������|����"d�i3�'WH��]����o; k��Vzd���nV���#}�k�oV�R�ポO��x���_?[}�>,�n�����sur����f�?U9��Jtg����!&KZ�����-X��4y�A })��-b��$��0����Wa�%�������3��3�;���veP�
(kQ4��θC�RKw�,]�395����'��i�{#c,Ǚ"�=�������W��-��ğq����e�3�{�7R;4s��""�hr�3�a���|;���5�m䶘:�Ĕꭅ��x�ѕ���R��_�,Ӵ��^�q"׸yn�:6͎i4d50��%L(��@�RY�nb�D��R7����9{\���Cu�Q�UPR��W/�=T0����E�>��h�������m
�����t;�SʣA.�D�i|ڪ$���u�¥>����O&��!�m��1xft�E��W�5��F�w�Çj|�ElrN2�[�19�,p���I=��=�T��ɕQx�����0��'|o��s���y��~�͢���O��M���V�4҈�G���Y�VJ���u��DI௖4����C��C���; k�+*w-����� |@X���;�l�.��`4�M��t@��̖��	{�@��6��u�� (��DU�ץ�4q�:7������bzX�&{�y2��\f�}�mye��]��X#_��F�YD�Uzk��Yנ�C/�bCEh�R��Pv�n�n���	9� ��c�H1�p��iSvy��j�>Ѕ���TJv*O9��E��S�%��	{��pfjm��f��q�jФZ�Z�c��9�
�;�׉,G�O#���sXK3\�G�{F��6*CA���ݮ�*�@�ΝL�/!��Q��SmXA�����A�&1�?۵�c�����������5�1��`�u�q���2S�>#E�^,�3j�G�MsejA���X�6�HCZ��US����p��p��{˪gD��f �������ˡ����ى�Sf�
����^=u�.�n����O���zn�@ZOT��`(�Q�II���;�%']�nV�Q�l{6����d\�M��?�,T�m�#y����,�03��h�X�_�hv��}}��ҝ+�����zS��D3��qNQ��_����"��}G�֙z�mt�\~Z/Y�l���#��h�����@K\?�������Ը�j�����C�~r#a�������T�>�?�.�ם�y����&?+�l��W ���b]i�l�{5@����l����f�N�?
\޴��a��^�H�Թ�Dy �'x7�H��Jt��Hs�U>Ò���C��_�M��ΰ�!+���4Y�F�l��X4 :t��@.��H�!@�'�ߠ\3;���r�z/����O���D�U�u��-׹��(�x�\v-�ׄzRQ�ߛ��C2(�C�L�FX��³�X����8J��ן��D�n?����}!NZ�9�k��)���m�FX��ۼ�k���Y6_�ȵ�����������Rd0Τ�mL����qU��f9���!�@հ�-앜)���%md��1���� �
T�� ۴:?M� ��I*�G;��F��\�U*����PgDZN'�Ms��[{�A^'a��Y���l����u�C��,9�W� �[�^����mĔ�ҵW8��6���� Eb�PP�U�Ɓ����{ �LT���_�e�"=�ܣ~LIx/h�%m�0s_�39�c��S�|��Q^#Cr��³+����`r���o恤��BҾ������Iܚ�#���K<�r��rF�1�ݣ�#�{V�h��t��p Fi1A�N�F��,�S�OH�6�r��;0� Χ��6����si+�W�$��Sv��+�Y�uL����O���/}�M�ƚI����sr��ks_�-f�]%�|
cUG$�d\?��Fm�����۸
����w=�a��܁���)�7se~��*X�x�U+0g�ln�|&2�zy�<JҖ�Zn�%GJ7�P����� ��s���	ʊ�ˉ:�.�����Kn�u�ofD�SZް�E2`�����@%xK](D��#])(�]�-����0�9vPb�O�e�gY�͏i�~
�	��E�oL���2�eJB��4cS'n�zQdjTǏH	g�;"�i��F����^���hM�b/���%n{�|�`B`}6�\r��G�$.?y�^��G\b�r�m�7����4.z�,c8�+��b�   Zj�9kΥ� �����I���g�    YZ