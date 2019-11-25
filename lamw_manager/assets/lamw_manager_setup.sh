#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2572347823"
MD5="4cab9cedb432f1258b19b85d56cc3a74"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20580"
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
	echo Uncompressed size: 124 KB
	echo Compression: gzip
	echo Date of packaging: Mon Nov 25 19:10:44 -03 2019
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
	echo OLDUSIZE=124
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
	MS_Printf "About to extract 124 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 124; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (124 KB)" >&2
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
� dQ�]�<�v�6��+>J�'qZ��c;�]v�"ˎ�ҕ�$�$G�!�1Er	R����˞�c`!/vg ~�e;i�ݻ7�a��`0�7@����Ӏ���m�n>�n����A������vc{k�A���|�x@�|�O�B3 �e���-pw����u�\\��k�i�/���'[ۅ���i�< �����?�o�����)U�s�J�Ե�4`�eZ�̨E�!���=rx�y�Q�Y��B�������]2��ԝR��~]J�%"��]Ҩ?�?Q��0b�4zs[�l4�ʦ��5:�D��]%6#��ě�z�^@��Q��Lρ�dt`0�E`�>����c�i����ٙ�E8��K���;�N�F����XMp1�����{2������E�vo�1Դ�t��_t^w��\��Qg0�Ɲ��Q�܆Y��Z�熊r��@�1�0:�R=�@��i�WE��6T�g��`�j�W�z�����Ýs�J9�8�w]Qk���=����o�2���,����0�j� ߚ��Xx���(���!|�<Н��(S�iD���P�h�(��Wz���<t}�3����� {����}F��0�`�B�YdydA���2t�ځ�25C��p��/��_�<����~&�E��9NLu�O��4�݄�TVŮ�Tu|�ǜ3>�K/�a@:Ϡ��T~خe�6a��g�ꆚТ����r��i�Y׹�5~�z�V�!U _ �I�Y&�v8 3f�o�zByӕe|�Q!�h�2��3P���>_� S���iBeUk�o�]��l����ŷ�Egf�
���杚M$|j�R��J%�|�Okg�{����Ō�|n�|N��^�)���w���֯F-�A^�NG�{��ڲ����\%��e+���Pƀ*pD���^�!����^@M+���UD���׏+�+��u���%U*�$$b��I�X��b��V�m�1��vSJ|�du�����T*�&����Se�C�����&�3
RN�"+��8���5icɃ����?x��v�dqpH�zx~����5�����B���������K|�{h�"Fs6iW�4I����9��d�W���#q�ȇ~��.�k��J>�"߂�_'��_�� F�ߑ�777�
���l|������Z%���!9�u|C��;n����Jڽ����頳O&W�(	FzY�W��@�E�(�0��QXp�=����B&	�O@�e�l�I �a|܄�ca=_X��}3`"���bAx�׃�U��8�'�&F[Ա6���&�;ׅyNuf����,�`@�5����v�Y�lWדau�ӿLQA��rV�V{�A>C�ʑ嗾�2ў�	������L��t(p�N�j�a?���y�ES�V?�Z�/i�y��߬��l�|�����b�U�D�cѠ�ξ`������7�~��_���X�o�O�����~�3�\�0��Єԇpd�����w@�ԥ;H !��_ģ���x�������li��Z�g[_ȱ+U��t���|��X���8�3-���	�M,�-?�=�ͥMy��\Ll,x)<@:跱�\Q*�7�=�Y8��ڣ�l3ѺK�,3,�p�z^X}��N"7�H�� �
&�?�.�G`섌�]����#ۍ.�1�P����GRfN���fFƓz����9�a���Ddl��g�����slҁ�zhΙP���qc�P%L�e|�}6�F�U�X�;�r���>8L��� �q���ټ�r�9괆C�u◝���;1�%ދ,�&�T3�#��?�K[�Z�֭K�^�NO@�e\��3MsPP����+-�W�8���f���Vz<����pn
�ʰ`�.����}O�I`����?A�0(�蒧�>'�^L>�ӱ���B��Fr�x���_�q��n_��������\��u�������J��_��t^w��\���3���TE��mĕr��������I9�"G�uS�o��-���E�^��7=O����*仴BB�OϕU8<A�#p�8�hpz򂤆|���؟c-�m���&��l�
W�^i�����&�:>�������G�[Gݓ�����vfBt
�cH��y��d�:��Ʊdƛ��Wu����7�du� �N�����BoJ���F,ץ� �"�⠧�u+My�3�P[]{�xH�����Q ��
�ŋ�	�PLx��<æ6�9�`!Ny�LwN�s�����"%��uW*X� S���}�N��d�#�-�v�t<j;#���U���9RIo��������P �}�z��E����A���$��t��ܙ��B�/7f W
e��*R��$H��;�;����9�f�^+
6?�Aȇ�l?a���YI�����;�G���s[#�A��i�{7&�"� ��]r h�����>����ut�a�l�b�T���W�c�Z���Z���~�\��BU��e�_���+ /��rf�z �
6�p$*	�e]hӳ��R}��!+�ni��&��D�����`E�˨�M���ϸ�<MJ���1G3�R2��M����&|,���}H�[��ȑ�칠y�u/����&rǐl"*��-l��a[<�p�ϕ-�@��B�=��T����&]u98j�zh4['��^w�Q�΃�S�$d�͖��Djx��j���?�����3BR�rޖ�V��#	���Y6�T�ŤoN��9w�s�:=�7Jm�E��ۮE/���$$�k���w7��\@�p�k��߾�˯1q�iԲ���ae���[;�����_��?��.��������$� ���%�z��2�s�=q(��r�xЛ�ب�����e%��V�n�~;���9�i(ո�e�tI����(8d���؟9�o0�%.a��B.瀙h~��>:��g�G�ԓx(�*�Z�4��[�����]���l�Q��pJn�W����g�{>�&�Mk�Y�ZtɹI��n8#��φ�G�c�P#6Q�'��hpm[/�ky�4���s���}ǽ���6vvv��p�;���Ds���u�W�(���8���o7���:oB�xI�˘!P<-�cU�!K�f��^z������\��gL����Te�+#rƛ���"`�o�g�������*����%�H"�����-���j�a[?M3!Mj�{ k'�F�r$R��4EI�<E<����-�zd��Ԝ�Z�}��R��]�\�3s�`z��@'���M`Lؓ�9�ߖSgo���C�s �|G/'j�����P��nQe��b��C� �o�Y
#�G`�o�����G�� t�]����������Hb[H��YxC�Hr�#,B�¸n�.�]��\��ə$Do�x����r�ݨ3�HM�����Q��	.Vh.(.l���Ƃ���f�ǖ8xhA��ZH���Ք�>��u*!i�>�V�,�:�B�x���	�EK|lX���SE^l2 ���"�*�g<Lj����wk����QG �{��`�B�I��g���N$�H����!���(����Vk2T�9]J�.Ka�|������WWH1�O�V��1�i��'�b?�v�h$n2k9�;p��L-5(?cq�oEÍ|	����h*�-Lȫ�<3A�[M|�c=���x�=)#�F1�_�3w�p��a�cF���ڋ�Ҽ7���Ef`{D\�қz�_j$�&��aefC��ޅK��㤑�8�\�*���!�D���
@���ac.�����X���]hD�5�x옿�.c�Y�\ؿ�A���j��1���ϭ��_�xv��8)���"�*ƙ�f�4��_֛�yYg��5��HQV��Qa0�����-��M�K0�D$������P��<zd�=���uUbΛ��n���� r��84�d0�ݍ`�FIw��D���+� ��Z���9���]��#�#o����@;kC��>�T��(w��AL�U(M9�P\�z��.�ye���D�3o�T�Z��v��۴�\x�9��)����7x1�p�����X�V6W�:3&�'�~0go�C���Y.��w�?��6�Vh���K�3Ƙ��9���^�h�A�4q��}�Tz���e����1���6F69D������~o02n%U�$�MM�n�~m@F��P��4d*�s�^�X��u����]��ި{��xᦸA�M�
A��G��[����p�]R&^o������S�`����ݼHmx�����쥸j��+���/߂��D�$[f��F�fl=�N�1�K.����}'}�!��S~ �/(��a�`#Q�����]�2 ca!˗r�;�pJ��xa/��� +���{��7g�-��C��vf���f���Gމ�E=1�ȶDMM�=-v>�ڹ����h���4$xaW�Ȩ4����x>y�*�rx���u���p0�^����(*���0��C#7���vMǘ��a��ʧF+۷�m��9�����BH�9�<�p�b�������=a�qM���혌�}���
�e�_j�����ރk�(���.V:Y9 lη����F,o��{��EaRǼ�|A���X��彾Xr� �4~��'���g�Ȗ}�4�vw_k/�;�	,eI;�!��ݼ��ￇ!�|���DԨ���kMܭ��-_�V���5i#щs|[i�ֻ��q��t�u����T�0�=���|wI��A�_�Ӡ��B<��_�z}~�R@@:��m��}@g�{Qg���s�[P~�Դ@�uv�B����6�l���La!�X�A���"H��g�©��Ii��I��tsC�r�|�%��%>;�2��H�=P�Cc6g�?��&���`����%���, uݓ.O���x���J0�²&�g�@t�Dɔ��P��KQ��X㼻5Ի]���1��2�g�S�"�\�GT���^fY
P�{�<�*��+A�0콹4�ȕ��k��;��u��9��߸x~���p�[皹� &%7�~�Î����;(UM�Bsa@��#��AX���)�P�!�������#�x�J��U�J�~���V�_�s���X{��N ,���ll�*92?��%0����$�;��֮��2�l�%�0-9ߓW�%�� �r��(�^���S4)9�}ᬄ1�2��{�j�ڌO ����p@��qg%)���G�Ih�>�KK�/����:����s��*�0�
0�3�E�D�.b+yi_�X��CC>C������^aX"���qb6�.��a	�446�D:��8 x�:n��d������Wv����O�D�$_5����Չ{��;�]u�`�%��?���UWʘ���3��TxJ��xD]s�Vh�L�œ���:�����ڬ� �cc��eN%���gmN�֨��!�#�]�N�F$V�;5�N�J�d��!w/e-�쎬RYMJ1���FA�.���Z�g+�T�YÄ[������涑d��*��2�iI^�)�2��ڢݚ�-H��3�����6I� �d���_���>��L���c��̬��I���s�[d�/YUYY�_NO�#�C�W�$E�m�W/�Jݞ~��OI��(����7L��Ю��ӟ�Ջ�����;8n�d��7�lI��ov��x�N���c-������AЇ �MU!^��Hk�zD��\R:�AfWAr�`��T���
�V.�ǰ�:?�L��=!I��7�Z �b(�s�P�� �Lc�r>Oa�@��*D����wvY�*����A�h�j�ܶb0�͊�O8\x��s��r���j��O��騴fe�u�R������9i����BE. R�6Jhn��9K�˵�wX����`9�h^Nl�5�Ҝ���Bi�W��C�+�fT�B/�tu�9'�S�&�hDD���>�E������nF2�zu�Z���;�֚�d��l$�#�d)�*�Y>��7��i��M5Fr�g�~/M� �����{5��р��w8�8b	��3�I_�������Apv���N�w�^6�q��΍������?�W��1������7Jq�pM2?�Q�#B�x�Mڴ�iU,�8Ѿ�$��W=��K���e<��d�:I�T�?"�wُ=���n_`��	�E��q���c�E
�a���������F@#_Q�ƿ�_o0�����P(�4+��HL}���D}�O�>�ع���m2�'�w:���7��aX�\�y�'I8d��^���(�R�W�e�M$M&ڈ����N��Ë��}Yҁ��O�������g�xn�,n��,��f�R���y)EF����L��ȅ���,9N�����۴%��_�C�ͫ�HP�y9�ks#N����TG�-��tV:����ݩݪ�s��U6�����wG<��n��/ݤ��gav���ȬB>gUz�T8Hnu�kKO�TFWp.� ?����ɢ�'���̔p�{����`	7�=m6ܮ���]K�&n����ШT����zr
*�J"����"�a�J����ҦT� Z+wxN|n�o&�7�Av�e�45{������<Ǘ��B��ɒ���l��b�E�^8I�ܣ����ĚUPYdӹKq�;눜�Y.�B��Y�W?Uh*��͟&М 10�1b��@DW��b��� ���&����y1qY�ϝ/>c��U�d���@U(ԏ�Qp.n>�l�N���x����|O5��b
�go=��WW~� -�s~gEh�o�}�:�q�h77�R^^�a:32p-�r�ϫ�[N�(��O6��Y��f�(,a.�`NeF]2���g�84l`)<Aqb�����$�g���*vV1K��`�t4��L�|�������nqJ�əX��.h+��=���n�7�qt-R���A�8�ew��V�-g#���{7����y��Z�￥a�Ϻe/�����72;�[Y���6G�ɑaq$�f�ݍ�Q��~O�}_��5wy�m��rr�[��B��d�̎2���3e���ƙ��̞�Y���g~����cX��_Wu������R�b"v�b�������$C�s��]P5����'U�3̣��Hp�X�RnU�p�h�/ݾ�+��sJ7��)R~�%6�"ƹmv�
t"qa�o��kE�%G����%y~�
�3�7 � �#�e9�Ӑ��'B�l����iNe�U��Q�jc��c r|�U	W�g��޵0^?&/��C�����(xK%�fO��$���TbC�˄T����iu��,���r�Քȫ�p�7��z	��pu9A^�\ E�,{{�` HN��H�$�YL��|�t����q]Z�?��[z��D���X��TB�f�xB"/���K���*���_[[�"*��;�J#m/��!>���ا/eY��������:C�Pc�*�U��3�f�:F@�W\�ӕ������`ۗ��	5����[���p��d������3�O/����B�?���ǗA�Q���Ob�����.�-ū��'n�"�5���	�4)�տB��(K�i����We�Yi��5K)�yM�E�tˎ���*^~Zp������-6�&��:Ҕ�M���P��'C(n�-T�+Ҳ���u1�����>A��/l:k�3��'�����h�]ZeT�R�>� CM��5C�Fa��KZ.S�PphP�6n�~����s�adNQ!�:��m�r!џ`;�u����ǙA�/�q�x}҈�yX<&ޠĨ$a'M�0(]2��	f�u*v��緂#���!'"��F������2���V�.g�����z�������=��=������m�Z7��,�o���1��H��n�w6f�G�.���\]��o�s^ʽ_>(��$��2oN������.����A��.��U8#4��^��ow����������-+��{�N{��G�A�z�=~	�m��P���7��#���&�@��K\�(��m	[;�Ul��iV4�[�G�݃W�u�urk���L>�㑀�ki�7A�b��fT��_��W �8�UX9���g<p�U'� �=�B��a w�ء��{�n.��x0V����C�!]�e��1zlL�҅�#�u�����O�x�k��?·�!:a0� !dN�:5'W'�~��� ��ǀqG���y�YS?q� �c�H��˾y�ȡ��;j���'<<�<b�*�"!��^�c�I���3����m\i�QY,�	�L�1��z�,��,�X�a�tr���!wވ%��������e��!sˍ|�8�f'?)I+�	ˁk��P^���Vs���<䩽$�JB\r2N?/��/y�y��P¸��4����^�?�nC�h�K��`�m��W��R S]�	*+熫� DW�D["�*��A2$͕U~�Mf5�**�Ӟj-�qW.�d���������	��j'�����ߋ( n���,qw6K%�4�W>�`A�y��Z���U���~Մׂ�\�����ȼ���t��|6��J; [W�>���$�'\����4�MR�"՛�����Q{���tZ�R��P6��tr����%��nA�TI�(��Y��}*lב��ԹɄ����>xQ�]#�JJ�@ZX%4*%���NicSN��n�%��3��N�7J��E-Eb��}x�ǨT��I�+[��J'^����5����NJ�E������N)�z:{�
�j��[�Z����P~Z�o��U����X�`�.��r�b*R�@�-c	|	l)C��p��`��$r�W�p�0^�G&]��i�;S��;F���Ԋ��9�;:w�^��	�	�~��47���ac.]bR�T6�a���4t�)Q������
�Vg�ky��r"蕗�����SWl+X 	q_��R��t�4+S.��NC��ž�Ο�o�}[��P�/�H��q&��B�Ju)�����L��d6�Q¬�7#����͌Rrbj,���;s���ɭ6ˊ�D6��xj�ߨ�j�6�nnHo�y�إ7�!�lZ�$��*\j��,n����a�:a���iw�;[荂U�P��M��'
�m�R�@p�x;�&�7�!��� ΄�q���+"���J4��/�;��Qp	S~��'�6\�`}W�U$��4`���3�.4B��<���'�4]��~�'�����a*8��AL�wh�����7� ��q�J&���}}0��U��)�_eKZ��F�s��wP_n�'�ZC��0O��Qt�:#z�Z����t���|�#��	j�Ĉ��sa\'0Γ(��qƏm�@���{����(����k�4@�t9AdX�F <ܥ^N���>����4���2���&H����5ƀwk�e�(�������$cNi`�9?�x�M����OQr�Â2>H�O'4*U�R��AE�>mo� !�
�:7[XZ�VշL�P�֍=�V���ׇ���(1!����$�c"�s�r�	��Ue:��آ���j6q�d��+� <�+Ů�yJ��)�c5Qqv�h��m/Rb.�g	+���E�[Z~�⌉��,b{��\��=7��{�\���w��T��*$�	����n{���������������z��g�q���Ͻ�����.���/�����n�r)�?�Y��~�<��&��
�p$���O�|�Jt��~�W�Ƞ���jBM;�qj���w�o���R\�1.���g���#� ;�Pkb�c �[Y��LB�d.jmH9<�E�Y���u���R� ��v6-�|���'�=ХK�!�����ב�Ç�&fYj�Ҫr��z}�~�En��,HX���p�\XL˿��������2/^^��!�R���T�g���|⚯?j�������j8�ܲ�HTF@6Z�,�M
d�Idқ������z1��JE��x8~����Lc�L��p���t�uUe���w�N��I���Yh�z��{s��W�����-y�4�aiZ���U�8�%��h����C�_�����4O#����p����{�M��JsȓVs��W�U�U�㯯�U}��&��֟%��$�@���	�24D� hՌ�t��@��#}�jɕ��HB�4eRDL@�4����R�dx��I�b)�Z&�/@�(��������Յ���&	�G�3��7�+4��q����Q���:�������݆���e��׳(�iJ�Y�k��*�׺��h_�1TC�N�d�����)�X�J^��b�#�������Wתk�`�9���no��qwk��Ԭ�N���l�?<��Z�`�����e��"��>3Z�$��
��N'���i�}>��-)2|�Ep��oj��es�I���<bӘ{��^��6�C���P�Ͳ�=��1��ǜє� ��$s5T��X�q�m҇�O�B^��{/� L��*�n��/�fm��:@>�r
�)���̵��j�)=��m��Tʢf�Jꑊ=2��A[FX������F7���3����?�hu �z��0�h������C�z:�ɀP�&a:2ᆏ�*����)������x��^��N����BI8��mG�\}���L�熐��<%���0��X���R�2�F�Z��<���OX�?��Q�6�����~�H��M���A0ϼx��|��^��䢇�����l�����_U�PR�J��M*�솃\�F���[��]p��)ʜ��=W���Z���B9G��W�,���$�Gj��r��O��$�Lp�c��D�]�]��B��i}��gn9M�j���u�b�{�S˪M�kKc�5�%ۖ����Ď����&�@�C,�h+M��5��5^����t��m���o�Ɵc\f�z3�U>d��9��n3k�'PSjt"{	�ہ�"�J�:f~��Ѓ�%�\b-��74��9�-�XK�^�KS�ˑ���
��Aչʐ����L�2�j�`K+��ed'��1F�k��S{d�g�l�Y��A�p��Hj����I'6#���HS�����+�e���=���n���"�p�Bt60�(�ɘ��&4�D�n<��u�9�#D_S[@l5��v�0��
�4�Ԑ�����I!�Qe+�帳�T8ɍ�2w,��L�'c�4�5���A����#P��Ϋ�~�݅�������ͯR}�~8{侅��a��K��偫UT���X�^k��������*~k��M���7݂Ƹ��آ��U�tngf�AS+����2ך�̀7X*.-�c����	:�PN���ی�-�i|�'�\E?���/�ܞ���<aK���}�P����nUp(�,n+��n��mת����L��Z4j��+(Vp((���N����WZ� ���4@��*�hֆ�͎�k���Ǚ���k��`EnO	����&�3��<:C�7ı��\H0
�)��*<��n��v�����+ek#J.Ql�|uі���T�u&���9����+�0�����0N��{��F�DJ@�:$�̨|.�䋼+�7�#����DC!��+.�&p��h���!p����!��6�x�R�3�T%�W�a��òp��y>l�[���,��͍�Y�t�pjj���D���%�7��q\���M��!�籰��'�)�d)oq����Bd1��Q�HO�>e��e���n��º��e��֡*^��k�MZ%�wq\��o���(87_�3�Nً�M�?�r�J%�6��K2pţ�ℶ���5������V��ZX�Q��F3v�$�'t��P�c����om��%��U;�)2�M˘�C�L#q�<�Mx��fy��aog��Cs��jz�^IY�O�p��Ԙk��7��Q�] 0$u	�i�I��MP�%
����$k`�Z��窮�9�~/�Ds15q�����&gDi�&��f��mH1�1ܬAk�R��\���B�B |	=����}´�co�`+���~M'ɪCѤ��
�!���O�?#�}3�q���C����b��[��t�n�5[䍝Il�EU*���{w�I�P)7j}?H�sg<P����&쉕BL�9���[����)`v�D��º;ov��`���R\�ø�V>j��R,g{��>�ƌΫ�Oԕ:��Z�-���k;_�d܈$w�;��l�KH
�d:m��X���%��@
�y�Q����p��K$;���s*� 7j<�6��]["%RCăa�<χ~�/	�Z*c����'RO���0�֒a��nq����h��S6#LR�w���m(�6:lK�8�_�boʆ�쌶MA"A�]?����R�ԃ��t��Y1�G\�X�´����T� |����8Cx��!�}�%\yA�H������*(.@� �Xd_Y8T�e���0Հl�):Cac�L���bE�%�E��ۡ���Vo�����c�e���7��_c_3�8����t{�D���h|��Sq�
A_��i-y�7�#�0�;����+�G�T���]�[X��6θƷx��]�еpݱK��\�45��`^FZ6/�}�\�E�ho�G`5�<5g������X��v�E�������T�d֍��?I۝�݅O�Ym�I����[l�j����c����Y%ж�ԫ�J��-��e��ɺlH�
�e.nC32���j�5�90�E����í�赮2Z��V�۹�)�+�85gnQ_Mg��v�����T�=��?3���l��)���H�o�j?u�_�6��u�C-�~�!W�
�R-L��� k�G�Ý�.0���R��`�yY��5�E'��,�#�aeɨe�z��x�W�i������mU}�,+^����l!K�gf�~��g��������l��~e�Na7��+��&��rX��`0�Ŝ�L������h"�f\mW�+;9dX ֘�Tŕ�A/�(��� �u�E��c3HP������_�!�����(��H��<#;j�7k�A��9���A�MD)��{��t���Eŗ�P�� �Q:9�q,o�<�Q��rh١�/��&�Lp��,֗�
|��ц�$�USZZLM�҈���d�Z��|���ԛ�鲇���ȼ��f�?y��d����w�PM�@+[�=���y-6��J�%�D�`a�{d��h��@[��(\?ဠ��H(�Wb$��x��\A�RT��=0�K˲2�rR�3F��2U��p��j�KLe�t����#�[��9c$jy	�)�珌Q�!��8�~�M ��(�0��s������|���{k����Y��s�4'm�%~��ڲ�i��!離v����fN�vV�"���H%�2]R'03��Tt��ߑ��ʩ��L�6�J}r�M8'���r���Y���b�X�ĄHK*kz��4H~kB]�J0��t:�Q�[L���J���4�#ii�'	�+������k�hIe0�SĻ�J tev�Ig�ȇ�ԯmm�L���������%�TS��j�G��K��"<�����CY�9�c�I��ޒ���s]��]ZZ�JiBq���v�s}q�yN��|����5���ۙ�bv3x�/�Jf���ӂ7(ω�-we�b�U�ZT�C�޳��k4�do/<��b�.8�g�ߥ��(��A,%uf�@VH�5�'�3�0�#XS�2UK�53�����{���@���~Cْ8}�k�8�b�����S[w|�ء������� 6C���W�ЬDr�u�����c��M�P�&ւ���B�ӛ���;��y�s�k�:�2z{�m���<أ�����/��H�Ai�nV��������]��K��f!+��>��'�D�?�(C�0-�Lb)�#�Dt���Vʗ�����z�Ӑ��Ѿ�sFN�̝t\!��r%d��P�>��J�Î�Y(e$�6�"+�A^x�(O�Pa�-^�~8ُ,�F�Uن��v�9sk��D�q
Q錃,s�9������T��Er��+�I1w��ΐ{4�� ��J0Y(������������������{��{������{�[Q�8�'
�O�)4k�.�lS��]]]U/�K/��y��z�p1�u��S��V!�RQv8�@{Ê��E_�#�����=+�L�[�S+�/»�Ar�w�i�����@$��0������}G__�w�v`���"��+0>�Д�*p�G=k��y� r�^�h��4A*D���x���O��Ϭ�d��콦Ыu]����Xy����2�{U*";��R`G҅�8�U^��!ez��9*7�Q�ݼ�G�3c��.|X�Q���_��Or���������w��zt�Sޔ�Ā��$Ɖq�W`u�/��/���q��&��-+��K�M�絇6���������}agA'��&T�`s�?8�y�p����Y���a�]W�Q��&��V�^-%I ���y����T&�:��!d���	��*uZ;c����r������+1�����/ͺA'��N3+�������:j�!G���o��1󀜎��:V)�KK$����
��'�4s���Mʶ�gL�(�'�Ir^��
o{����!�� ��:�'�R:�o�u��䡀��#%ÀcB�b�'յ�{��E<�F��= w���R��9� �u� �d�鞏aWF|VѐՈ���S���5��,�;/����}�rP\gfx�q�l�_�S��)pX?-��ȃCAk����Hrv�;:8�u�qp�LYTA0�J�8���3.�����ڟz���(�9M��Ϭ����^ܦ�D��t�0k�]*�mz`����6�������O������khK�v�b2�mͨ��T�u��H%�1�i�~����I��F�mdht����lV��[ͪ�T�պ�dl�f�iW��3W�j�2�	4���k�c!�5�ER��{s���-����Yu
�4���Ye��v�f@0Ǣ̫��nͲr��<~K��'W ��oel�:�lfv�A��m�1�s�y��>T�ҩX�6T"َl?�"fGf�0
d�.��J�!�΃�bzJÏ�	z�fB\�dV����{Z�q��������	ma���l�e�.�t_|�Ǉ��Xȵ1 �0�����d���rۿ$>�0
��	���T�Ⱥ�t=�x}_����hq�/{�����Q{�Ho�j��H�#֊�K�!	a�S����j�v3\��6�y���Y�#NO"��Z��Ƌ����:���T5�eG3�O�K���z�H�5�xEl�)�EǏk<QRA��l�+��
���ǟ\G7����Ys1�5��1�	���u:��.�*�~��j�{CU�0�OJ�)�,5RQp:�D1gƨ�t�e���]4'2xbZ]$b�(=<�<{��n�ҭ����9k��j����������J/�<�={-W��U�������~��[�ኗ��3��z�Ա�,i�z9��E�?� ϐ�j����;�k��g�LX�8�j�����o�<�B(��^-��t��1n�U#���{�0Ū�$5�X"N&��_��z�Y�r.9����0��s���Z�=u]й�e����Q���H���X�O��~��)i�E\e@W��޷�]�=~�*�֣��S�e��x�i��������U��5�[�p�8��B�+h�;?�3�Y��Ol8��h|6T&�~>8���{�Q08��39�� �â���B��g���g�
G$���(Hd���y��w�d�3M�n��߳���G�{
W?��j�Y�H@�޻��Ʊ�i�i���ouvp��:��N�`+\1�aT�~��ӞX;������w<{4 ^8Z�ӏ�ze�_�wz�|��J����$�x:=��^����yXOc?&q"�{�-���_�5�q>�&��7
w�������X<=��d6�>��O/p����2D��8�q�EL^8��N�9�#ǤPwv����6Rb1�)d2!w!�	!���_�s����rL�h�5�8W���(��f2wT l��޽w�B�0�ڐ��؜�d"�TG;@bo[;p�wlX3E�<�R!�v��y�.|�0��\��r}�GB!���N��F���I�#��;�TJ�<q�h�I����!�����t�DZ,ʾ]�Yivs^u�iΙ��mɝ!KV��7�֡Q�/�M�9���Kuhٹl+B��F��+��a�_G�/W�]���
��<.���c5˅�ճ���J��|d��t�m�:�Y~���څ��^7v~
����v���2�Us�9ʦ��t�}L��.X����SM�����ձ� �s!��[0~Mh����F/���l�_�յآ;�R��C�D�z���6\��5�p�[�H[���{�_���A�3��˥/����������ɟpL���$�ٰ���G �����>�۟߅�L� �|��U�|BJ���U��H���6��%��/�����ě���֘��3+|�l�y��}~u��MQ}G!�q'JO��=��l�@��=�/ �d��K/�;9z� lu~kH5h�HCk���WXԨ��GE�tHKIG��Q�(�,���T3�7gu:�����\��z\FsȰ�^�0�����3��4��_+����m˭<m�ٕ��r���{��J]*z�x�e��]����M�4s-Y@oΊ�j�I�.+÷Fѱ��8��~�`�n��_��^^+$o1_����#�?>�I�d�܄<b�P*	b��N 4� (!⣜JH��9ڿ���a*��Ѣ�Z�N��6�R}������s��/��[_�4�����^��^�k��׭�4R���������7��V����X��n�ǻ��ע�Y��
����~vηJ y[6C��]$�ׇ�J�:�8#��1\�/�*�Ɇ��q���y����B��3���`<qp5��a^
&M�U�%��l��N�E����C�W���as��S�$\Z*�)$��Iz8�f��N�F�!�F<�S�P3��O�o�9�O	bL9)���|W�Q�0D�Qo��� ��Ӟ��b�`�e=��#:� YT�Uf��Ь]�1P+iD68�ټ���R�(�lN`D�qs��nMB�����,��&QZ�jg�r�~�e�p>v��r-���/25�Ύu�O�ۓ1qGŗ{'c&F�L���#�����n1&�Π xӵu�osyq�fQ!�e	V�������æ !��\�L��Dw���P�U��D�7�����p�*�Y��6〆�e��\H%���E8�0�	��1K+2�H��]���-;�%���N@O�}9v�^��מ��K|qD!#nb�8��pd7��Li��T���Q8`8�!���Nѷ������'?�I:���Đ^0�Z����(��mz l3�r6Dn2����!8��K��E9Y{^��>�0��i���_)��JY��6('�����3]�PEΊ��K�<�D�pZ{�����<B�H����F:���Wgk[@���2�w,�!�'�`<x�:��3��7��E��1����;�(�[%.$�Sxh��Q�26��d܆�
1hU�3π[��W�i�F�#&�(9�砬�,�� �M�I9t�"�.Y{����zkU�M,���Č7`���}&��1/����؈P^�㡏 u�Tڡ��cC��J���d�{�:	�K�����C��[w��g���ȁ l��c�饻��93y�p̭S����te�����y1V~�0.���A��c���s���uq�J�Q�Tۋ�Zz�tLD�\+��X(:�j���6��1�So~G[!'=���������Ӵ��qmX�岭�K�u����O�x,R��J��|�_Vn��+?�����1cW�#�L�}o���$B���V���l:$�t�7����!Cэ�G�pz^�>�]1�m!�R������@��ik#2lm��*i3դ $�%�/1�S���6쳭��gbBf����%�-��\o_$��K�Q�&Q�Q��T�p��f�w�v����d�R�fZ��Z�S�g׷,�P��"��Ⲡa��fPP1�ͼ�0�3z�1VB�T��I��Ū�{��"riG4,��ߵ�����cvc��@�Y@�5J3�"g��#>w&�m/-�os]�E��Ubjڬ%�	�t�>(�	��O�p�#ӥ7��6M����+G��!�J*��Wj�U�IUJ|sWY~��Gh�'� Ç�F����14v	�@�seqv[��C�~�����e����Z���d���'k��߿�|�����5����������?���__[�g�����_f�O\|䜠;^V���ѷ&$�3��*kM�Y���U nl.q�2Ոn���T�߲��^�1U5NT�$�(Q�����aw�똭9���;9{�%E'g���]���ߘ�9�["k^.��dA܀�7��eUw+ժ��	g�!�54�����]G�p���m���:;�X�@r@�*|����G����Z�G�p.�j���v�#��ͅhX���´����(	��J�#k����Ɔ��u2��?τ"�%��d���%�Z�����XǙA��:]z^1���"e*��c��̘2L[������y"'r�%�U��o��ꆁ�TG���r�L
#���߉�lR�W����Ȯ���Ζǻ
�
U-�Pв-V��Ve-A�|ɱ�S4B�a#��m�(x�kFv�BޛY�+Q^:�S�"@�`�Wy���`Ӻ�%���kJ��"u��W=����)j�Gi3Q�Q�0)�vڲ<b1��]3(��Z�bt �/Zm�G�t�,4�ʀza���0���M�W���?�=�?����U����:|A�����������{�����@fN5`c��ވ5T�g��9pN6��ؙ�%����)0�d/Ru�KR�~`����S?z�H/� �O^8K��$
��/��o���k��O�����a�B���p�"����8���6a�@���9��!����#v�k0�$գ�)=3�ɞ���"���I5�x^��Y�:r�hROс�`8�α�����r~�k��j�#)A�U=� Ϊ�!�7��+ �
��M�&��/����D��5a9��w~hoL !ő��`7�&��T.��q\��Kn$^a��4�ƴg���6��I_����<��p�j uu��ޟ$Dc�Y���FJǝ]}�r�����oA��KJ���AH�*�qX�-W�"�oơ��TE0{$�hA�$����#F>�����C��%��8�:�c�-��A�H�H
����/��@����.L��<tq2� F.�a�����ώw~F�ڌ�zB��jŪ�>>#��a �DI�����3#!�W���Vg��iM����Am�|:�5�~�z�����!ѹg�7w�u��� �N�f9e�cP��IG��Y�h�<S��fl���y�5�̼?l��3��]�v�Q�¤p�_��!C��5�e����c������"�����c,�����X�b� ����� �s�ѭ�F#��{>��8�K���������O3����^��E>~3>�'[��:�R_�L��|���ƽB����2�?|�8���V,��O"_�S<3C�,˨Q!�x�P
��W�Ac/�$y�ܧ��M����!�K�f�v�|,ͩD�Zs�hq���8y��{�+��I�%�|5߭�ti�ns���.��8q5�E.� ���)�x�3$�o3�$�d�����)��,(C)�XUh�E��9��`!Mi�] �/*�F�<�1>��D2R�_(�g��o��o�[1���5)��:�!	��(�,�&@�Cʎ�MQ�f�|7������������D���O>:�.���������|��Fv�OE=������E�N�������C<u�{��5�J�P�h����_l��@"�;�g\A!�^������Y��Ǎ��=��e��	�>�z8��}�G�*f%)�8�^ >I��Z|#<�F����Y8�W(R���@����C�\O����J!��_����l�8e��
�b�l����c�f��]�uZ�t˩(iH�t���ʌj�vk{�dﾐ�R�������ó��@ש��!���w�
�urSeT#���p�՘���b�?�:��bd!|<���k�;��(W��p�@%�?>T�U�e�a���C.Z���e�KjY�/�d���(��DO��ȢG>�舏4 ��x�D^j�DFvq�����Z?Q鐠q &f��  Z
�`s�$˱q����Z�	L����x���u��V����7km�7P	(�&��(O��
#>�at�DO�F]�Mګ�',�G�`D>(�R���#���-�+������?�������s�����?���d��G,� h 