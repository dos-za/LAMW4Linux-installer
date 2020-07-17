#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2693967376"
MD5="8ac01624da26dab7b6fc4afa02de904e"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20696"
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
	echo Date of packaging: Fri Jul 17 20:40:40 -03 2020
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
�7zXZ  �ִF !   �X���P�] �}��JF���.���_j�ʉ3�d%�y��h�ĚOrL��;�omhG?y����Zݰ�8�C�wj��?[n����݂� �z�(��p��/��/nj���h�O65S918��`e���]SqJpbE`Q�o�|7��;
S3m?��aDR荐�� pô�^��`�o
�m
7l��]�۰T��%=E�FZcc��>�-V����0�ﯥ�!�`t�q���:��؏� U���b.����x\�lҞ�r4����z_�h� ��l�=����|�t�9+�n��Z�rE��ԡ�/":6�!�%��L(��;��@|be;P��Ʋx��YY����g�G�N޴��{�<��}��C�]�?Jҭ¶T�X�.;gz�^�E���uN:�΁��ˌ��z�[�z�T`y��75�����%O�'E]�6�suOi;*G<����AȨ-����k ��m��Af��e;������Z���q�56I>H��- Tc��E�JB�V�kH��Z��MR�cJ1)6O��	�0g���	I�u���Ns�2^���[���pK�i���2���6+��ؙ��%�J�-���+���=o��{�P�=Z�/e����p�M����B�k��<$MO	X����m�B5c�ll|ȼ���Km_-Uu�ħ*68�	��2��wTQW�$��}�v���sw��2�av�W��e��i^�/��ĉ��r���@��VCA�Q�8�=�/�R����1U� nU{- q��>�Zgq�����WjM��,�B��Ro���+4P�$UZ��q��Ev�v.� ��lؒ`�Qz>б���;�2 �?���]n��BF��~���5�٨��<�[�	Tηh�>��jy��"6�5[���ƴC�t��"w}77,�����H��xV���f��
��P�sUF��y��HC�{s(�mP��UK?��_N�V+%�a���/>Ԥ�~!b�9�,�hF��YS�@U�|����G����QA�r�{N>��O�!+ !��y����Nf#p]�&�)5����5�8I-��k��(Sݵ�J{}d�d�|�tV�'D�I�]Ym-�����q)?��X�)�.�����?�' :9v�����HKc(�dƻ��
��S��x�g͚7�%����b�4�(�f�cX�t8�w�eE�E�&!i6[m w��ϖQ�dy�؟��v��a4�ѻ:m7��$cl�v��?���w>��.���6 ��pr[��R/�Y������DF���.!��V'��C�q��e�
}��8@6Flͤ!�%X���7���h�G��3�yd��:o(�0���y;f�j���� ��(0���HsXm�&���=���X�� �*�]FnRmNkL�d���k����w��7�&1�o]E��ޜ���S#�������:?k��q�W[;�A�#fGܱ��3ɵ�s *�a\�zW̿t���s*�]���Vώ�W�km�c��ҲK`�ܸB�E�&��Tm6�DU��+�ui��JJ����M�0��.5a�V2��1�{Y䡤A�O�Ԍ����5�3��b�@���9��+�yUg�4���cx9I��)�9rtU�M�V�r.����,6����d`�����~�lNM�
_��eޭك�T�F�J�{]D��ɡ$�=����ƙ�� �j�t: ����B��lc�2�IXt����CBR��T�$T	��rʰ]!��b���a��$��.����N��r�L�ר���ґ`᫟l\T���׀����������qh��X��D&����u�e��eQ��!�e���?����uZ<��	p/5�➯m�~5������Q��������R�����py���H�������=��t��[_Z����N�y��.���ߩ�uO��
eZsʧ��P�8���.�-1^4�&�h�C֓4x�7}ܺ�%����^��a/�i�/	~��o�I��N]����O-��QK�B%�	�lfⵃ���W��	��MҐ��.�����vØ#�K�4��'��L�Az�իu���+��B�����?��2�ۿ<ؗ�M%��9v�ucvd ��A���7`A111S��OW����j�P����`�z�`~��C�2���!�x@c='�G]ӡ�r
�]/A�'�~�n������-t��&m�}�I��s�j]�Z�ǕS&4�U��o�����i�� �~�ӄ�ɔ=<�y�w��mxi��7�u�fڸZ��ΰV,j�ͫ�"$����#{TjuL����*����R�]���D>�i�^,F���vY��S��tkH�^�6��1�E?�M@b�U���_9_��Gb��_d��ŉU��e�.�`h�����N�����+���f������Qt�/˄�!�V�l�TNu<�?9�^'��&�C��u�ϒ|�
��݇�flݣ���(7��2�tqv��ꉓ6��K�����ӧ&�B�T�y��8�qW���i�MX��;q�Bn��y��槞��?���&�QM�U���e��_uy��Ծ:$��BC�T�OVx�n ��I.��|[,�D
@ޮ�&�l�� Qm��+�5�Me,n���p�S[�G8��śܟRB���Mj�"_��#�Uk�T���ȞinFW��':UoP�_�������q��A��XLɉLY�����B��w��V(s��ڤ�)w�͵��u�cDq*��\���P��$<Ě�=�G�������"��\���Y�b�g�<���)���R*]!] Z�k�[�I�j�����hd���ԉ���a������uik�v�/�o�2�u�7q-ݠ�a�(;��񷂃#:�m�D�[��Փ�$�ӻ ����wˀ�}q!�?��-��ig�<��lg�M�G�[�g>��u������+ἠ֞4;FӃ�m�O�8��18�!�j�,@l�`R\��H9�"�Kn�IȌ"�ۆGaJ�.gg���(�� �������L.>���Q�"2����I�`�P�k��/���]O@��t���"��D9�G�.���D����8L��}��>���	����Ezx�'N��6+K��A��	�?��3C��E����y|7�������|��OʛS�}!�-���%��eb�d�q��5�8��o�e$d<��������Sc��jT�H�YW��p��-Qd˶����D�`�K����s��9aև3W����|7�LX���EӉ���?��8�lR -̴{4�G�����t8���i泛�?K n��}S�������ï��~W�e�>q�o6R޻���B;���|'[� li�;�M`������)�;����d8�qP���`�pnR�M\��Whî�d��yëq���o�iv�,�� �X1���������*!����S9Q�f�〆��,�h�t�bo�G���HBz@皀LE�k]��l���3n�i>���̦�-������\�i�H���Xw؊I#�����.��UQ� �M�Q���k;ϑ�0_O��	��X�>)=欴u�w,l��YR��đǟ�$���oE)'�`��h|�w��b�C��� ���j���Љ_ʲ�=���������ǎq
��x~7�S�������%w�~}��V���s��S�r'�������4RH�����6z~���xv�kQ�u�y7*�-�F`-�:$�4Y���e�>�jnةMpS J� ���ZH1��}pi(�`7����%���ʨ�ٹ�!�:�ظR�n�C�0BKd1Ǉ)̹�$'z$��{�5��n�b� bn����f~q����X�~��z9��>��\�1�����G�_�2>08�А]e
{�d"<�;8�j1�&a�l/��QS��+y�dv�]�H�m�̓�9�I�mw�!+�"j��3$H��IPu�Mƹ�K�����Yf�Q̳���u�v���Љv�<j��I9��UW.!��A%�vpNa���6#���({;u��A���Ў/T��^B�����D�D�c��W�5,n��n�3�#��ۉ��Z̧T�X�TN'+-���6�Ut��.(ְX�'�;{ʊ>Z��ǒSC[g�z~�G�w̥��C�Y=�zd��.���C2� aC�I���*��Ƃ��V�����i��(S/��� P7E)N�� �?��2_'��BE��Z8\�V��4v�c!� �wՋ�j��;:�� P��Ş�_N>>�{r�#�0�P��4��Y�m��<��k���`��ݖ��Z���(��xh��AX�F�ĕ���/3~[o�����${���WDM59���w��������7*i[I?�Rd�b���ws��FГ��_{˿�<�p[���`��&�Oʬ�K�}���>�+�@�烂#IF=8������Nq`�\;{�����7n{E���cjN��8�"|��w[f��13��6����>�O�01D�g��E���%��T-�M��;��W,��
}xH�����sS����}�/B`�X��0�y Ё|�B�=<�_� ����x�B5���'���ݫ+�.���4̽(�!#l��f:���q��y�m�Y����EF���������!�<�p�e�xv&M+j��)M�G<��Y��N#�z��Ñl����&���5�w3sҦK��x;!���͉����~^Y���&�f�}Cm�C0; 
�a��K��Ԫ ��)Rt�c}��6.�(�~:�A��0���z	���������*��%S��?� �AU}�lKؐ�W@��.4R}.(	��^3%�p�C�e��QS��,�ì��" �gc�Y#A�:���s�����*���O m�F:_�4:���6�3�b֐;�An���)�J��֥��ЗO��Y�ٰ����oû�9�ΤD�Ej$'!CZ�Ru�%h�Sr3�\�c�#���ҡ��
pK�N���I�_qEk���FN����YC��u�I�:�J߽�2f��B	C��
�;q���X3���'�����c��oͧ�k�^Ѯ��p�p�,�J���#0sL��p��%w��ש�H��$��\'�y��x����s������2�eϵ���B�gu�!I�U�<^���>N�#�{C�zm�2RLlU3�ŝk�y�D���3����~��7�Q/�j�����T�#p�b%�����ʃ;�	����X��ə��.g���s�m�%��ŕ_=��������5���%����.T�p�ob�����T���}~�G�3���$�<�smw��eC�ׇ5�SZI�z�CUKk��ݦ�>N�lqMQ���EQ�Y�8����`�9��a�p(�ʈ�W�{�d`.3�r��{&HB��qsu�����P"�.C6�
虌`������������p<"-S�Ii��[��D���ԫeg��J׹?�� ���6��K圲K�[��UT0�
�)"�V�.L���*�_�]DL�.μf.$ffd��D����}�X��8� ���7u��s��6�WzU���e�	]fO�|�>�������9��R-�I�7�&��\��*9���ByO��m�#4��n晒�1��g=h���9�52z��vW y����^'��굞ذ�	�6���~7g�A�h�����	���{�	^mzR�dI��$ѥ�����#���h� �z՛LX��qz�W5���� z7�j�{C囟�t��v��U��C��=*3,\��8���i���ν�YMk�6mz%�7#)j?F�O�^�Ial��^1��[�7(��r�t���k�K�
�|@S�GR�����,��*�I�����̗&�ͥ��f�C�o#�|���
���*���`��u�L	1��^�/c�'��Mݓ���V�8H�����Y��J�{�4�YLp躭� z�տw8���L�@�N�~�1)�	1���\��pު���q���K�a���a�ޤ��:�f���I��`�;�ΪꞍ�J�M����|c�
�џ�;*K	.�0�m���=�s�P{I�o�@f�r9��J���ΎO���}-��c�\�D`�.t�_MQ�뉙e̲~�����A�c�F�U.a��یd����?�7Djq"�N�FZDh��R�c��teV��s�1���[0�$r�˳�S3*��>��҅���@5u��P�H;�X��9A�
X�J���`���~�m�ܺ�H�,=|Q��+�9d�Y��[�no��}
*ݱ��s@e�yo�8��|�A�7�7�˝��Pg^��t_c`��;c��)s�D��jdY!�8|�X2u�j�Zy�H����,1�X)���F�F6O<�i�a�����Y|XT��1���o����H���q�Y4��@jͻ(�dk���g�M�5�ۺ�<�,¤Iϫ���\E�P2�T����������?F�_mcCV��
2�������_�P�F��&�s�'(�W�f�S�y ���ٗ
�d'wm��'�c��Z��4� ����/Q���B.Dư��*�Ꮳm��j��8�{�C*	|�Kڇ�i�wh:�A�����RL�$1C���kA@�x���ի>��o����q$�=W)��{ՠ�{H�;��rߠ���"R��M�I\�(
��kM����@!�g,X.���=�ܬ5tF�t{���[����J�T�+�����6�� �a��]k�yT�ߥ�,!2�+QB����)�V�q����O�}"����08X�ycF�G������6gM`����s��I/;��:fHp��V�/4o�7�\<t+����/�x �ѹ�H��/�"�b���Ҍ�"���q��1��ͤ�Z��v5�ȁBp[���q���v��'O�5�H'j&�]���J��lA�kť���A+h	��:��J���xA����~���<��q�4Z���eW`d�5�uB��=L%�V�/ӕ�2G����o�^��QU���������`���/6�3>e;귁�����%->ӂ�?�|� �t�a�E݈��)@e	f3�?����2Y����mU�^wi�.��}5�kf����ڜ�1�$�����z=|� ��*<']��Uu��	X�f�Ԋ�R���w^�G����P��͡�q+\����F��Y�U���㴴��diR�sѢ�!� ��Fi�+$
}��5�����������Z�
��aCeD	EE�Y��]���±S]�N^o�����n�m��o 
�M�d�y�i;�R�\琧�SV�CY���Y7}�������A�QS�͍ƹYa :|�h8�$��Pn�T�,^�y�Ν��,��q�8�;���þ�K�v�Ƀ�#��r�⸓Ċo���;��S��3{���~'��YϢ\&ڴQq�b�.#�qw�݉��HVf��Ԓn˕��T��c[�M��î�<��ʙ��	?W���P��K�q��:��U�N3���qh�Ocg�g�򭑰���9#=��>W�GN���!`3�BB���~�^O�[,�z�*��1Ѣ<_�i,�7�޵�h������Z9�"\i�-�0Q��q*bJgY���+�ɻK~�jH��HO�Wit�B��e�>�s!����i`un�[¨ݵ$Q���|G7]��?�Y���S܃� l�P!�Hy�8�������'�ME��>��91)5���?H5�uW�e�	����U|��^�[������w�}����I%����x�ԛea<�S�+�Ak�%A�t��{��A<,%�sF�=�f߃jӳҰrs�B`����r��I���L�u�%9��p�]��a�Aa��|��N�K���4;Z���|��[�}{�s�g�"F��6�'.��i(�G>�?��<ҭ��a�^�����Z&O�lsĄ��u9�fc�3�ըѓ_e���ow
М�oR��"R� �򥷃Ȳi������<h/�͂�/���|c?Y��}@�3l0%jzL\�"s��J �J�e=���DI�K쉂$%��H�/tL���_��V��X���� ^�����1c�Gze0�W��nvP��;H���M@A 3�ɀ�#�u9tøK&}�[G��_rR�G�B�}���lԶޑ�Z	R���N��1ǒ�i�* �PJ�\�����.������|��Ŝ�x)�x5.�ޫ�n�6���3ԣ��q H7��b}Vf�9��_�eoZ��<UnOt|E���1k`K�Ssl��;Ů�h�����%S��O�Q �0e��Њ+��<���O���1�/��� ��1;�4�/�H&�ܶv����@it
�ߨ"KB*k-� f�����k��R������/,���M�dt���T{��ଖ e�r3�uOq�꯱&b�t��־�� ��{���d��R�F�ᡥ� ��w�"
	0�Uo8[�C; e��C�}1mc�ْ�
K�D~=�sx�����g��"��8�y�\��"Gj�W����X�懎Jљp-p�a��V�'F|L�8W�x�$�jK'nHn��ea�M���ɀ�piᰭ����w�R�,Z�J���Z#�&�Օ6F2�nvП�8��LCk�$�(�ڦTW�a׋bE��\K��c-�T�������0h��1�&g�������>�4�sp}�;����j"���ހ#! ���w����'.�9�o����*�8H�ۮ�e:-ՙ��;�N�}X�A�CJ����y�L���������~�Y�:PeC����)j$o��s]>�ڍ 0K���8´ia�P��MN쥩��[����z�1^3�g�w��:��8F���/��('���vhF8�>�ٝ��]1�l{��g��~en��k;k�R�婥��c�q�ZG߹�Sp@�Qk��E���ӟ�x(z��s/�?f�����5�� ��h��)���鄠V?(G�&);�#Ȥ5���ڪNyP4�+����䗅L����x:M�&����*dE��C�ݓ�L鉵_l�q���-�S�D/_Y�g�ƟN���(	��5��vrq��7}� T�>��>6��1��^٧u�gO��j_t*�����}n�$-��-�/�fھ�"�����Bp��P8 ���󀸾 ��2Q|�r/'Ǒ\:pW\rܐ��8G�x�^����74W�;�%���3����N�Vf���:��#"�
�n��t�K�נ�z��ZK�r�Ys
���̿	w)��,:� �G�Mƾ3-�1����l��= �u���a�;��C��� l�_�7�`ۙѮ�9�xÓ!c\Q�v*�iCnRV2g����͕�h�=lz�8�C
�l*�1Ѝoو�cn�(:e�:�V%��˘j�T
�H]��i�R0yd}ɐ*?`��!I�[��I�dC'׺���^("��L /���}|F�v9��Oo	��^C,/�eݮh�`0����~���e6�(�&g��~)�{o�{�ZJ�ė�a����Z�t3����w�H�ء��uI�A��f�PL*$����6��d�^$��B���Xncj�5`��B�l�)��o�E�;�i���R�'��%*d�Ӊ�4�t�هP��q����o�e��M�3/��=�!��r��aEe�IO�{�N�/���z%.�����t��a]�o���YJ������S�P�b��5��,B�P�v���
�����r����{UD��5��;��3�WMxe"���_-ym�I���2~����u��_g�����q��'�="�#$��g��z���DEv�����}�*��)�B�}�IU$����KF��� 9q-֡�  į!p�P�:�բt̫� z�7K��Jhig����V|�m�.P�9�&�l`p�nH�?�ܱ�^vWQV�z��,�Q��ȧ�$b�S��%�@HX�+�WX��g^ŋ�p�tX5�8������Έm��-�V5��U������X�ʏ���5�i`Ѵ�9���-j�51��UC��53�T�A|Пdjp>�8����i��a�$��R�J��-1\�& ѫ�g�%;g%B��jӸ~�3)�~��rC@�"��� m>{���%x��*o�*We�?扛�]�M8�rut&pX�n�q7��� �!�t�K��ɳ���Ү$Գ`	;����z ��4Y����rnАl6MP�a�,/JS�J0�&�(v���7{8S����$�*	���,V�""�.%� //ki3P��4��Wm��L�m���Ű~$�`��̬d	cQ+�К�$�������Xc��^�ܫX�i[�U=3�l/#�۞��AƤ����	���(���lBY�E��{���Wsv-�b����K��x�K��YT���Z6����"����O��rW���`�]�TH�6�M|L.��x�i�DtG�X�m|fk�*�0�k��
��b:ny�Bm9�' (R3X�Ǳ�A(���|�[f#�b�v��b��z#��3mQ�0���!n�xA�፯�x��>�?x�䮫Q{R�׷��'�w||~���8�y��ɏ���lb��n��BNp�x`{3�.������|�z����1P����MS�-�&��_�����2p��*kCL~*�S�v5��n�?w�H<fK������p�ї�{��8V�W��_��	Í�S��ns���ID	�!���n����\+������@�^�TҦ�lQ_�׬��@G0�$QlЊ�v���-�Vv1�ҧ��KL�G�C!�S�B&/��!�*YK]�����e�a�e�[7�b�Y
pA{�^�� ���9\^����l�� �鱇�ݬ���g��TgR���-� ��D������Y�4�X�2ֵh��B�/����d:�I�Q��v����A�v�L�LC8���M�����8S+��N�T���!������l����`ug�Kf�v_���Xd0�p�gЭ��V��VwG��y2��"%��f:
�4��!1���C�Z�(E�@��&������4�����Z���4�#4�E���uK�v-fݧ�E�l��,<��K�E|%�'ۡ{3I�ٿw��[�F��n�D�7|�HjZ�3�"U�@����yx�f�쾗�[&[$���C�����=%�>N�\�W�'�?�V_=�������q��ƪ��]����V��}C�*�\�ͯ	��1&%?p-�?�Q��Ѓwr��ɯ*V������|ͳi���7G:��V���$�\��<����$j:Y�N-���s_$Z���H��A_���nE��c` y����Yr���yP�F ���ܙ{�
]����Q�6}�H�`������R�t�%�lg8<:�)����|��� :�e]/�$9�,*�$1��Z����n1��ʹ*�7r�P]�Q�h�|�Ŧ�:��o�^$�F�����o�d�z����q�8%���6bgޙ�Ǒ��Bm�
�.p�^���p*=�(O�R@����x��׀�E����!M4C{�e?g{���__���K�����P���"H��.��r1��^5�Hi�NI�9�
�����"�R�N��M��Hʄ��#b2e��
V�;�e�C=?#v���#����[��[�i��,B����9"X��P� Mk��6+ͤu�'����ۖ�&͊n�n���ȃY60�^$�N�#�>S��m$ y�ok�pf��!������D���B]�B/o�+Z�k�ĬSxM������J�Y�Ti^q�lj��0�~�ևI�r����=9Y�y&2�N��Õ�>c���V�e��=CS�H��!#�XQ�*XhD�L��1��o�qM.@����4�����kq��e��d;�3�e�mTNpc�@�O�����b�w��5*I&K���2C���e{+"��_#�upl����X�yc�"8!���e�&�V^���G�^�.�* ��7Z�%(�f��6��������c��s�S�l[u�����Q��(>D�A.��O ^��ǋw1k~miyc<5
�+'�8V��F���3L}=t�u���LU�2H��x����(�-���?)�^�sn:�U���N V�D5^�+"����nA鹁�a&��#y�Ŵ	���u�6�YMn3��\C�ZY�pO�~x�Eke���y�Vx��5U����Tbm�� ����ev�����75����ܠ�n<I�!����C�����
p����B��ב&��@1���˾'��?�T9�
�j\�t�W�I�	3��T�l�7I'�h&u���dJʊaA��M�+����7n���l]0�c2��\o�h�K��ψ����_G� ��������I��4�� ��u	0H n�d�|�z�V�R�ְ~OA{�pxɘ��7��Y �?J]L��)����VD�J�%+�$#��`g�"��r��D�U!j4��<$����P|\����e��d-��������: l��j�%7RB�@-l^�pJ=Hg�N��c�sm�{�$4Ӭ���Ó��c]��h�ưlsD�`>�t�����b��t���A�ѕ�ٰ��]t�������-��n�\=Ĳ
M~���}��@�^��?��-P7y���$�ZB���ģ��Ԑ�쪧���`Y��%R�f��Ыc�wQyk��ر�B#
�X��6c�.�7l�Af����FH�H���)ȯ�+z3�?�?���㰲�dD�1SO�Q6S�W���G�&V��L�#$��t�SB��*�
A�V	�WD��?�J�d�i���_�����~]"���@r�����)��BJ�\xu �v(Ξ�MŤU�c����óY!�ұH
��BtBe��x��Puho�X�c�Ց���ĺY9�N3�䷛A�Cu��*���n=Kߤ�݈�4��Ї� �N �(O�k���0lGt����KQ��3#��r�	�ݵj�o�
M�T���I��?/�M*]_�б�R��HK��+IoDg��5s3
\�3Sz�Adߧ�)GZ��>C��פ\��k��s�M~V���k��v�a��6$��H ���N�r��2�h]���%#��mJ�(�?ne�����E��=�t��t�6^�ȣ�Q�kkQ�&[����7d�1?�1�X�H������bٵ���A�6��Z>:hq�i��ߌ���j+\*��*$1�23������9�A	{6�� lsE1��a��o)Q�N�|)x,�3�
�0���K� a���>����������m����X$w�vҢ���5m.��FL�������Vņey#|��hT����ͪ �AT2Z����\�>��%�]�^Z 'ʞUB���I	�e���Q��.y��D��3��Ʈ�����0�p����|y�K�4!���#�4-��۠1��Q�!o\�;;9�a��!�)��jn����	%�=I ��O�p��(u�zd���M��;��r��f	��#lZ��&:,q@�Ei��{_ؓ2�B�D� 6��7I�"DCL?���r:��8U�,`�w2,�����n#�lq�E��$2R�=b�+��%]�6�8�vR!�:αI��D���Z^4����r9ܐ�M���V0��ҲO�
P�����~v&�P�E3d]kBwԳ����[�ka�#���D��q6�Iܰ	W4[X���W��I�Z�#�����+r�n��>��z!�h��ߕ�B�M�ذ�vT+1��&�1Ɓ�+�䭶����e)��t$ر7(��r�M{��\EU}W����30c�D�g*m0�vE��� V��SR�X '92� �N2��)�'`���������|C�.5�v��H0�������#�MYR��1�v*{,��j㴻����p�q�瀎֤���|$�)I�}Ӎ+�8��04B��:���Q�,q�v���s�i~%�w�{kV�CL�Ʋ/ϵ!X�w���0F@�������ĝ��)6�G5�&����=�^��5!�����Le2�\NZ�TGyL��ˀ�H~-ߣB2�b��L�Mc���̊p�6��)��|k���5z\�0�_����'>�n���L��(ɏ4>b�W�w��鄰��dw�����N�f�ٯ���p��3�|X+p���?�ȓ����f�z�Q��"���ʙ��)FÁ�X�b�z�~7T'ǲ�B��
��h��	B4�XY�c:en&��T���ݦP�������=�w��@�,�Hv��@;���'ͅi財�&Z�k�-��F�47�j�u���E�:��=:��_�Yy���7�S�n�Э�L7����2ٷl�Fz�2P�����.e	Pq�~+� ���`�e���*�b{��DH�B�i��2�S��o�^���Q;�Ŕb�[�? ��ّ%w�Թ��7ILv���AYvJ��},w���ͤ��k�r���n}1�}����F�x-�3�@��X/�&r/��lI7��U���ՙ�ZiT{���~��=�0��ٳ��!'��x̊m�vUQo���x���3\��~�N�5-2�N�<����}�.͢r�����9�_~��T�o��j8���g��k6�f�/Ť��bET���6½�W�o��E2�wT��<�6Z��'�ZH�{��&ō�4�Ӫ�q�.33G��"��-�<���"�E�)ouu"ȇP���Z�� AeKx��.�7[����x>5[�M k����%���mW��L!Z�J�w��c��ݪ_�KRx5��2FV���ɜ2��3���y3����b'�th.�[�U�z!�H��m�3J���c��������͕n�k�G������*���S6���d@v�.O�az��թ}���=�����f	��� ���{��2��=��7ؑw��"�a�iH��X��ʁA���C����o��9{H{���ng\S21���2�/Bwԫi���-�$%`\'ɉ!�ͥd� ���ff�'����6ᖂ�5R��H������
F��\���o>�*��G}��dy�n�}��gF�-���q�ZO:^N2�R��:o��������V#۳U�$+>W?+�~I:�����~=�#���
؍�<j����Ή}]� ͣ�moͥ�cl��D)�>���_c��vxR�c����Q��q.�B�[gʏeM^���ޢ
�%��0�a�)���H���-����?V��kݐ�" �P~��Ұ�b�� ?�1��BB��L��T֍����L�;�3��!��vrא}�u<��*��o�`%�yaa{tF��h�_!�H�����s�*)���%��~3Q�ud]�#����a��֐��d�t�ZQY��:ÚBؠG;��_2r)�3����:�Ë�����=�E%-F@���\b;D����]k\�]a���?�<�E��?�j�`�،�z�
?}k��\e�Q�[�[����\phO��xm�C�6�G^K_��"y��Z#�嫈Mk����C���ђ�����)�(᷈3�P1q�N����eQ�z�Cj戕0��~�:uH��.�BR���c^z2M�e�Pe?��g^�Qڥ�	3��`#�Z`UI��u�Sb"s(��փ���L��D�ۚqs�Ð%t��nێy�ZXs�C)����<W魱a]R�`�!�$�g�����T�=9�Nk�YT�Z������KF���Hїw
ǥt_ޕ_���Qw�7d�-��Nd�x߮�]>V�܋Pi���"z�F�K����� ,�����(���?��x�˟{�
���Y��l1�s������:�J��m�/�mL?�=0�IH��g�A��S�C��g�B����/Z�M��ݟ�,!ǫ�b�$����p����� �F�SNZ�,���@�I�H.�%�S��J�;a�y>�Kٲ
�iL ?���T�D�+Tf^sbx������}�
���º���]�k�  ��Nv�R�[����_g.�G#٧��n�au��& P�60�W���yD�Q�a2���8oK4�5�nn���MV�?�&㫞~&����b�N��ڊD�Z�,F^�֠�o^b��*�Z^�$���D�b*`fA��k�
���ys��	�~�+w�!��
�"�ʭQ�������ο�yV�3��P�m�i��z_��J�?����)|���~�/��s��+wG `z]�h���= %�k*�d�]H��|���*�e�:���g�8~K5��~�"����䥺�	r|V?��ߠe�I�F�iq	~a�����eÁb�]���Ƌu��o��&0��g�K��;+{.Ez�Q�J)7��#�wn)�3�/˫�鬭'+:�]�� ���~-�#��
��S�)*6M6�,|���0D��ד�k�l�
�p�n�U�V+��:E|h�>j��s���'�zh[0K��:	G��H�}? �W%�����������cg]��S����U�=�$���)M-,�;�@���ש;5r~WY�_��x��5�J�Sf*�{��w� d4��c)��ly��GO#�8�)_cuR���^�Q8��}���M��-���A�;�.Q���ؒ�	*B�'�|��!x�m|�G�>^[��%2���2W�*��2���7Pe�v[�w��)�:���#�����69�
[���v3�6埋�,����İH���u�vu"�B� ��G�F%�^|�""���^��tX|�S�����k�el}K�C��i#�'��w.�����t*j/b���b�Db"uFi�[��6z��g�/~C �DEf+�m�kwt, �wҥ���y��%����3�)
p$�q�_��E�VG�<_g���O�6�c��r9��� �B�
f���&aU�̆+W�"��I(��N+���ZH��y�Xgկd��<ba/�<�v�-�n�dDD�M=Υ��:3>���A8�����
�4�L?�;���?�׃����öt����68�p���Yl�������l��;>�-�h|>��`s ��QM�a�\��[�Qw=:��ے
�&7ѫ����a�>�֍	G�k��s��=q�{ h�f�.6�">�qj��L�
��	���#���%��?�Yn��r����)�=�0r�!����2s�y-s��kbk��AQ ���� �h�h�V8���fAVKF|.�����K1g�*����l��Fk1/�R��SMhⴂ%ht� ��+S�O|JF11�����=w�SE���{��������lj���օV��T��)��^O��i_�)�oD� �w}�ڠ?���A��}\�^iA`�8�"�, !$(�����E=�9s�i�xșG:>���%�U)ӥ�l��m7C9����A���`Ƴ4�n%���xw�ݍ �g�3��%�U���>
A��msp�ԫ!v�B�����\��I����ԁm'zl����4�\��1���Mr��D/�,<ˍm6~)�!F�X5�V��.�?�VJc�u��}yKJ$m.�-�+�WV4�x�eOM����M�:u�W��
&8�}��h��� $O���ϗ�Z|���ԇ������C�9����@�x�NDg�ǔ����lj�ߚ�&��IK͛�w�8��f�X�OJ6�axj4|f�]���^T�\B���a��?//��Eq|���O�[b����H�6�C`K���x=�!?����g"I�MUF����؇T��I�'�*�֒��9���>ZP{lB��܎�kg��Q�qdP�;R0%�yI�wS�
X&��ɀ�B�����G��gf�4����ΚQEC&!9��!,y�3s�mmiFզ ��G8����]u�.KS)��dd���X�9�T��{�MBu~^9G��#�$�|�9V|�6�,��G287BEF�<�AB�٤��Kh�'kc�-����Kr���V��i�����z�y��}��򽈬B9�MkҒ�+�|��Q�M�#.n�kɠ�G�&gz���fF��G�t�
�" /CP�|�D�@3��H��.��Q�jk��t5MAۤn�Xc ��C�Md�1����<m� =A~�CDb��\l#	],�H|�0�Q�"��A��B�!Z�p� n��\�[����lR�6�!�ݦ2��H���|jP����k�M"h��p��lN���|?��� �϶�0�f���B����ʮN�%30s���m%?�A��k�����7Ω2�RP���Ws�<u�%�^��_�͙e��>j���A0Q�+��hq����LSq�jA�����I9��a;�+6���r��*�@^{x>���13��g�����:Q&��Y�hqhR'/D���: �� b��3�-��sϸ9�eT!���@
6��Lb�a��]",��I%�?���(J�)�eh%]/K�����c;��>�j.�W�vե�m��n/2�t�o
/.�Hx;kv9�a�z_��̟���(�ՙd�%R�L�������÷��ɂ_�\�"nS�#����cK��,	e��}yv����� w3K�G����bXg��͌?�?7;�K��g��A�,��C�����b�W���i�~�ٿ�?M�O�8XUF�H���Y����S>��g(�[��pO��s�Ў�yj{Nߚ8W��1կz9eWI+j���	Mt�i��Ҽ�GJT��7Z5Qs'*2�Q�m�M�)�����D`� 8%�� L$0"��[T�%�BW9������j���$�w�0�}F������5 ��w��|�x_�-�]����|-Ui����L�Mav��J�1'~$(� ��7�.u�#��Ϫ"F��pw:W�sf �H��3"K�ӷ��Q6�[�#y� 	�5(��ӿU�+``cT���/i�����)��eU5�n]��+L6>��^��l�H�Dߩ:�P���!���W�z��9q?���b��olTإo8ˍV���OD`C�6X�r`�2#�&dٖ���X��}���uJN!)�"um UW2��*�>��js~sW�}�'�x��%}A2{�Ϣ%���B���^9��f%ZQ�G�E������G
ʜ��{��a���&�3hu�$�V�<��T���~{>��-:&�J� ����\{nWݎE]qvj.=㤼im�q�,��������9��bI�g�ru�m��F�>�k��A]�pԣ���.���&%�y	ӥ��}���cOg~�>Qd�ɓ�L��,��4Ц^O��b!2U��@�V�
����NN���-���h�x��$�ɒ�@�썝[7�����bA])���_���$@�{���R�S8����q*>��N4�r�����7�0��~S�?���I�a<B{/�������I�rC+E_�e��T�+�hM,Ĵ��0���[�u:���2�|5.���&�S�q�q�}�1ۺ
��[���1�"[o`ōq��o���ˡ\�l�S�t/�<�=�쮫/�ࣤ�b��^i@ ��A��(������|��(��9M{x�OJ�'*�ϝ�ˆX�ZɌi��R]�sE����8�	�	�_O��!�Y*lz��Hӗx�� ��E���m�)�gd^�������G�L��X���VL����oDA��o�� �D.Y���e;M�y˻\�K�]nP�735߾�N�d�|��D��pcJ���p����\9��B��G�~n��cLʷNu7�ߧ�@�3ef��S���^��
��[B"�%U�2 �����h$�c�Si�Py���'0ZM��'�K����!G�$�(2�}�/`�����u|�[FM��E!l�+~.�r������Nb��vt���۷�\�f%�u���}Ul<h�Rj����]pa*0~���_��m+��e�n���w�H_��q�����,��
zhW
@.����d�`F�m�E˫������X�n����S&p�ӌ��E�'Ԣv�}RH஖��c+���c�F�%���j�4��|�r���B왟�fD�惎z	���z÷q�J��Y��57쉙�&ݿv��Ppc��$�Δ=��7�$:�����$Nn"�:��&�ݎj�&��}^k�YH���Qg�^D*����X���~�=�,#d'`H�����-r+�ت�?|.'JDQϵ P�c���N�'�}��X|!�:a/9!�y!I��	�)�x��MH�!��4�X¦�;U��(����q�<�똈J����.S_F_*�_��8ٷ���hŽ#�@�k;8���+$�4����WcP(C�`	�-�ɒ�:��&�ͯ���D��]K��9+"����<~>~s�dz�&��*bTr��B�H l�o!W��T�Ў�%K���2�>q�rZ� lH6b�k�ĝPl���s�p5�z�Т��=��֖��n6!� %J`��o~���Ϧ|     �	�n�O� �����iA��g�    YZ