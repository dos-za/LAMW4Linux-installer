#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="500824836"
MD5="d36b7cf4b5b5f46411d9eacae821ef04"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21417"
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
	echo Date of packaging: Thu Nov 28 19:52:18 -03 2019
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
� �O�]�<�v�6��+>J�'qZ��c;�]v�"ˎ�ҕ�$�$G�!�1Er	R����˞�c`!/vg ~�e;i�ݻ7�a��`0�7@����Ӏ���m�n>�n����A����Fc�����F������~�>̀���W������S�sq1^��9���d���lm�s����4���g�T��'��OLv�T����*�S�^ҀٖiQ2�L���c3��a�1�G-gab6�jۋFw�pjSwJI�[�t)՗��swI����D��È]�l��m}���Z(��"��U�v�،�foFB�z��G��W0=����	48�$���4 3/ *��:��.��Sgg��B/}h��<;=4�ckp84��c5i�Ō����p�::2VH4�۽A�P���ag��y�igsuNF��x�w^wGYsf?k�*�U���@��t�J���v@��\��PŞ�7D�}��_���ZT�nw�U*���0��atD����:��m�N>�!��Vֳ��\B��@�A��|k��b�;�|kc���@wۢL��]��C٣�k�T^���������΀W�*,փ���n`�����X�}�g��]L`sp�h�eCh
����Né>��'%��bX�[`���]�n�81յ?�o�HvSY��R��s���.��	�l<�F`~SP�y`��Qۄ��y C�jB�ZK@�r��	J�ifm\�j����)Z��T|,&�g��CF<�� ̘���	�MW��wD��g�)ʜ��@����|قLg�f�	�U5����v���"7�s@߮G���n( ��v�wj6��%JY{�*���?����96h�;3���9�szI���K����Z���y�:=��#h�~�O�Op��r���^.L~@����zi��^��{5��ïW�StBZ\?���4�R�.�k�T�d���A�&b%n�esSXI��7��.L�M)U����e����S�d��t�O�NM�9���3���(H9ኬTd���r�VԤ�%�~�����C۝�!��!���e��������&{����ӝ����K|�{h�"Fs6iW�4I����9��d�W���#q�ȇ~��.�k��J>�"߂�_'��_�� F�ߑ�777�
���l|������Z%���!9�u|C��;n����Jڽ����頳O&W�(	FzY�W��@�E�(�0��QXp�=����B&	�O@�e�l�I �a|܄�ca=_X��}3`"���bAx�׃�U��8�'�&F[Ա6���&�;ׅyNuf����,�`@�5����v�Y�lWדau�ӿLQA��rV�V{�A>C�ʑ嗾�2ў�	������L��t(p�N�j�a?���y�ES�V?�Z�/i�y��߬��ln�����b�U�D�cѠ�ξ`������7�~��_���X�o�O�����~�3�\�0��Єԇpd�����w@�ԥ;H !��_ģ���x�������li��Z�g[_ȱ+U��t���|��X���8�3-���	�M,�-?�=�ͥMy��\Ll,x)<@:跱�\Q*�7�=�Y8��ڣ�l3ѺK�,3,�p�z^X}��N"7�H�� �
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
0�3�E�D�.b+yi_�X��CC>C������^aX"���qb6�.��a	�446�D:��8 x�:n��d������Wv����O�D�$_5����Չ{��;�]u�`�%��?���UWʘ���3��TxJ��xD]s�Vh�L�œ���:�����ڬ� �cc��eN%���gmN�֨��!�#�]�N�F$V�;5�N�J�d��!w/e-�쎬RYMJ1���FA�.���Z�g+�T�YÄ[��,������m$Y���rZ��$EJ��ezF�h��eI!J�3cu0 ��&	 ��v{��>�؇}��}8����63�*�@Rj��KF�"��WVUV^�<�J8�C�W�$E���VS/�z˞~��OU�E(���3L��Я杧���ƌ�R�W���(�pP��/���.��C��d�)!8�J�;])�Q���<��T�E���V)%�����	2�
�wF�͌��+����;�1,�����L��{B�zno�� \�P����B�/�T2����0:�=-f���W4��h�U�"`�k��R-\�m+�ެ����#���Y�����>�rf��=+����t��7ƨ�Ikt�\%�T�"k����;�����<}�U����W
���ĆXs*�����<F�/���P6g�*҈��1�P���,�����`�/jdo��ZD�Ɍ��FK�p�kz�5�d�el$�#�d)���y1��7f�i��M-F
��ɠ��&r�\H׎�~��N����_�	��1G,�|8I���d5R��������t"������vn���m.w!?����	�������8������8��?B�x�]ڴ�YU,�$վ�$~ī���%��2��b2�sј���r��wֿ$}d��a��	�E��q���S�E
�ay�����{��fH#_Q�ƿ�_���+0��)����~"&��ɗ�T}�O��ع�6��m��;��#񍨄E��u��IM�Y�7�.�#"
��8��}�}IӉ6b0�x�i��"=i_E�lூ��� ����/,�����Mb���0�Q�>/��i�l1:Si1r!1�/���38#����}���m�yu	�:/�Js�aĩ�����E��Ϊ�M��;�[�wAW��f�uJ� 5~��E�gk�(�r�
��م�#�
��7��S�З�*u�k�N�LFWr.�� |�xV��d����R}3%������ψ�<7�=m���1_��*�]�Fy���Q���z
*�F"9����^j�b�d�(�ofMiA�V�""���ܞ�L�o2ٽ�U������BnĊ_��K`��GKj<p�'�٢�ł�G�h�&�G7����5���Ȧs��"w2�9�Z.����Y�W�*4I��	t'@��&D���o�EO<��ǚ���|��̺V����e�=w����VIŐ����Phݏ��B�|�(�&gӱϭ����j�Ŕ<���,�^lH_]�e�������M���3��N�D������2ә/��)���Z� ����I�h3���l�����T��%�~f�C�F�1���'��.H�{^HL�bgS�C��^gr��u��w�_��S:N���6~Ax����g��Xv�3��[�TNjƩ-�S)�Z�s���~a�ݻI�Y+B�4�x���b�-{�丿�ۑ����tT�92]��#�p4���n܍��F�{*����|j�+�|�n����2��r>��r;�M�f��ϔ�
�;g
�2{�fu�ڞ����G ��!�}]�MRn�*v;O1��؝{�-� FkC3����M��j����O�h�G+e��v�ȥܪ���h�/ݾ�+��sJ7���xR~�%6�"ƹmv�
t"qa�o�W7���K�
4�߷�J򂐕�g�h@N	G��s$g��'��f����YN��Un�Q�j��c r|�5	W���޵0^?&��z@�����(x���'�<%��nTbC�˄T�{;��h��oY���zZ��b5U�j5��rsE��@�Wk��Vr/(��+ ���co/ �	r���=��xX̗���y�>���Ð�ɾe�J�G<GE��~T	��6�	����&Wlc�)T������dET�w�&F�^}C|Pёq@_j�����?~Z����Bq��L7y.ψ��^qy\�VVZ��K�m_y�'�8�>jn����`���tܓ�W�'S/���T�uǗa�����Oz��=^[�W�-�O��h4	�)�Ӥ�W�
	���,!B��{�@�U�ge��5-m�WϚ�/��[~���h5�
��#^0=/`\��m�I40��֑�|abݼ�*�M2Bq>�P��J����8'���}��]#�_�t�gg2`Ok�0/��[YcTN�ښ]�a��ʚ!_�4_	�%���6�(94�	Y�7m�?��ª��02�hc�O6r���O���]<崾��q��8��8i����q ;�g�ě��$�i� �G�/�=�,�E�.����Vp��=�D��k��_��o|��GV�a9�%���6ڛ�B���2���m��e����h��o�7#�ט�h�yl�{l��������؃�F����7x/ރ/���
�|�7��z�����~�h��{�ڗ�0���SF���{����VN������hE��}��;����F��w��o�w���z��}}�{,����HVUcy�7ʤd�F���6��iV4o��^~�C��m^z�rß���#�k�So���$M�Wo�.��x�L�YU���ƾ�9�;�.�S,4��C�3%�e<*ug�C��XnNՁOt�19s�h�D�mr`�����(�p0x�jg���0�#�dNy:���&�)�a� o���*��n���:u���~�e�<k����/M9�*I�O0�
e�w�������$�D7x�����Yi5QY�h��N�1���Q�<��}Ŭ���t
������;+���˘�C����7�q>x��N!QhV�2�B׌���ˋ���s��"�J�Z�'N?/����z�E��P¸��4��0��ߣC�h�K��`7��V{�= �\�	��8�k@����D�!�*����=:�k6��� j�TT�=�Z�خ�ɧ2L�K>Ъ��G��l�6��Ӛu/R�m�/
`S�k*U�
��Xp�o�����������㚉���0-��E��y�	�����l�[�u@���}�4(�I�N���páiޙd�EV6�ý����N��h�oX���F�MN~sе�P�Tlr�Jz�Y�Z�0�Ч��psx.7��L�4	W���5��D���5
@c�R����66��;�FV�� 9sZ�L�Q�-,j)�eF����R�*&��l(�&�x	n�g���P�L(�%�@[�6e�[��	�'��Skm��jÊʞ�	�}���������e@���I-+�^�H�e,��/�-#e�wN"̐�D���!4��G��K�rx��~S��q,&�$b<{��M���7�F�C�q�n^�7���3'�+1�N&�`�qn�:̔�Fnsb�y|�3%���n]"蕗����3Wl+X �k��hR����4+S!�i9C�K���Ο�o�}[��P�JO$��8�Q)ie���@�އk��qF2��(aֵ��e���}3�왘c��Μ�nFkr�ͳ�2��#5�ʺ:��F@k���������
Sz��Φ�o��W�mK-��s�6V�	�Q�r�p�]�y�p��%46ǹ�&�h������*�&�Φ��M�a��:5,3YEܬ�����Z%����#�s��8��)���q�[������o�0\�?ݙh�#�`&tr'�`�ft��/�T[�B <"9L�y�'ĺ����P/\�qI�9����0q��눕�oYM��
��PU���lD;'iM��AJ 5d�t}���Q2�{���J����MG�"͇:(k��L� �p;��u�<��A�$Q���4� n�w��<��~��F�B������i��]��4���S녉ȒΘ�-��o���v*ܭ�]�Q�%t�z��s��H��S��tΏ��}�b�`��S�E氠8�P�	�J{�,b�GP�O�^�R��Z�{(T*ت֖	�(��'����3�p2�G#��"��?�AC�`Lq�֯�8�utU���)�(EW��_�'��ҁ���C}b,�e�U2OY�p�� �A�&*�/mR��J��S�T�aw��~K'��}�1�X�El��뺾����~b�y�+�7O5�@��0+�i<���4q�������q;�g�!<Z����o���-���S���~^�X�F(wQ�
��k�r4�/ٽ:�4P�sݜ�HV�#7�[Ǹ9D�/�>�	u�ƙ�j��������[���c�<
u�����#� ;�L�51�F�g���z|.�br�7	�>��"���k�i<
��}�'@����1�Z�$��H�RB1�;q�]�1|�hb���-���o��G�x�JɃ�
�����<��%��[x��/m�o ���R�@i�B��d��"�����T	�/	�k�BW�{��Hs��2��h��86�M.�Io������֋ifW*Ren�
k�K�t�p�������*K�~����G�9%O&!�2��[٫����]���)�ޒ7M#�f�_�!O�#Y��ыG����>$���?~�߰J��,F����[��$<���"iuVYm�ڬ׀�[�w{�L�1��,� H�ĩ+�H2��U�#ZA�fT��/�d�SU[BH�Fb��)�"b�����M��Ҹ�-@&Êe�k�W|*MmHF�h)1���w��}��rPM4Ϥ�o��j>.	����{�ݣ�����*.��m8�?�ü�
�zc7͈:p�SZ�A�Z���;�fh�	��s�:�5��Z��QL
c���]tE�%GC1~��ƺ9l�h�w�;��C�ݺx2uZY���	�B���<���|�Dg�x�D��fn�I�Ϧ��ۧ���|��]R����1~�T�,��DZ7%�����M:�y�V랊�L	��fBwj���qO��@=ጦ�H''���!�ROhm�i?r
y�����`z=4)uK�93kk�������e��6������	yR-^�Nã����4��> ���׾��P5
5����ߗ���o���kν#�!���X=���׉!]>�{��X�̧�U���ɹɑ�l�8t
�����}Q�;%0��0M�p��pF��d_jy��~6?a�u�N��� ��Q�	#9��7�>��x�%;��	��K��q�P�ͷ�=}���5%�$3���_V2Tl8+Ui��-!���U\��ƹ*aVs�=�øP�+�b�v�X���`S�r���yԩ���t�K���a�����)�
�V0|������ܧ˭e�T� 2CԸ�\s�BmjbM���Tmi\�fR�dʒc�I�;�Q̐�bN�XV�h�Yi�����^F�Y/�_�{���o6O��Tx�"��C���"y�d�"�ܚ�	Ԕ���3�7RdpD��������$�{�l�=jt&oK(II��O�,����nNh^�Yr�s�<O�.���1\"��A�|!��d�Z���l��v����`�5�h��4ϼ�����s�RH �Y�AN6�-���86�������������'d�I�oI\`�T���~���� ������O�s
�C}m���1�G��uM]�ؐNz�>�sM�m�A*s� �&�JF��|�����,n?���r�{:6K��Ԗ���f�v_v�{������.0�x�ׇ� '�k��>�Q!�u���?�Ei���M�9��������Q���ⷰ�Kڄ��ǎ[��w[֗�*����,�-hj�G V�^�6����FK��}�V2_6A����{'C�6_'����|���e0��/��J��R� �aK�����@����nUr��+n+Gݽ�v��l<=C0�k����^A��AI9wd�`�v��������2�%���f�� JFU	*�Δn~�\�Dw�8�,�Nt�&��%T	�_�T�p��s�~C@	i��o��Gp(5D�p�2��6w���']�B����K���Lţ�KU[g� (��&�w��w%r	�#�{��&��kaX
�� ��(W�$��ϥ�b�we��{�5}����=4��䕌���.Bh/:��`ܣ+�p����,^�z�Yy�xի�0֌��aY8�fa^0��7��ų��1>�قњNM����������D;?��5P���t8��<�_���kf5y�[���y�Y̾cT9���ǏY��d�tؼ��.�y���u��W��u�V��]����q^����'����H[�Z����Xli7xtY�����q�@>0R�5���µ6J�5jU�h΋���[�c�6I0bB�F�P�؋��2�"C�A�t��e:*������7ۯw�'�>����t��YgU�&A�WR���W��qc즿�3#��&�d3!5�a���	ږ���%cx���l����`�U���	x��碹�],���Ɍ�&g�ҘMv��+hې>bz��Y��f�٠rS��F���R҂���ǃ����co�f����AO'�CѤ��
�����O�?�#�}s�s�h�͇r��(:')�P�w�0����I��Em��Z�uS7U*����d8��3�({��q��J!m��[k�b��8�mL�eK��w��ivva	�CJft@�`��|����9B��������cؽ�����;`�mMWo� �}��wW�a�����8L�U:c/r�U�)���v}���W��H�#���$�S�u7n?l�]["%�p���qEà�D m%F	�]�S�/����Ok�0��<�_ah�AЩ��N�;wa�6Y�%}�Ѧ����e,���@"A���x>��ȽR�,�S����/�� �#n7���X����%��3�f �޼��a������mU]���VIq!���2�ҡ*/�х3dc��9g��M�,�[����Ԝi	-3u���f+3qc�����7��_c_s�.���~��kbh{_4���)B��+��q�������c�4�H��)�.�T/^���	��҂��q&M�ŋ?}��q�sN\�÷撧�����0Ҳy���}���������>!��%Ҝ�l��}}��ж{����]m6�="�n�g�yD��`�+��"5�W�E�ض�=���5�E�ȏ�J�mU�*W�+�U�I�BZ�h]6dA��y�27�2V@���r|���~f�q�OC�~dh���vnv
�I���Y[�W��Ym��Fjl�r3U�ÊT�3C�{L�0�6�37X���U��K�&���r�b�/8~��'Uvz�鞰�c�CMp���F�{���
|�8/�`<�&�a҄y�rā�r�,9�B��:��^�z���O�eŋ!K�~�/$g�Ow�|#�U�,�z�s5�T�O���~T�͹�JB�ɘ�xf��}Z�i�d�G�1�����A�,�⸰x¸b躨�䐕�Xc��7��~L�H�FxV>��ċ��fݯly-V��e�%��S:߳ ��Q�葈0"xvF�ʒoֈ��'�\��N���;����5V�
y�_C)���FA1Lā���,,SDU.+��凎6�������4`�<X_b+8�h��Q�`�Ԩ���������z��#L�]gYh
3��9)
�y�0̜7���z��@�\��0(V��Rʘ�+��,�G��%���`�{�����@[B(�(�`@��H(\A$�!e��[I�Rܧ�.0�ʲ2j�"қo�_S��f6�F��A�,}d��?���?ZdC������{���q� !,�s�g��O�n$ �&g{l	�8 Y@���_Ϲpe]]07�Bs��pNX"ݬ-���ܰ1��~�jת���c�jge+c���a�*3��q3ÅN�ΰ�;�_������pc@�8�?��$r��I�;?���'n+V$1!�-ɚ^-9�ޚP��̤=��-�&��k:g�R2�|�PCZ��I���C�V*/����Ҡ��[U	�����}���6��;/���."�0p��aȚY�\��Xti�[]�g3�j�x(7��hwl#iƲ����8�պ1ۥ��t7&���^��=���w�����0x�G�k����1e�ά���s	V2�l���AEN�n�+ÜJ�ת�%{�J$n�t����h��ͺ�p��W�n�PJo)�3���+�kV��N�����֓�i�娙��N��qz�q�D����\����7��2_�X7YE�p�9���c����׭��5wީy��uw�Ƀ��QȮ�g�d�Oo��6�����t��0����7�{�/w���/�������.\����^��x�kq��*�7+�F���]�R�.oRS;���YCȪ�Y ;1G������YH�e� 3T�(9bJDGn_ki�|���plP�i�a;ɦ�}48g�����IǍ��/7"��z����j���cc�9��M�Ȫ0DP���S�4zG~��N�#˲�ͮ����w�Ƽ�c;1�@�F�BT:� �cNɩe= ��,�l�FI�R�%,�"�3��-�����a�Y��<~����o������oK���⿕��XQ�8��
�M�^g�����4S���j\��^��� {�,n�p�h�0�O��V'�JQv4�C{�����_�#�I�V֞�5�D�)"��1?a�;xsx�=��E�(���vzo��K�N�2�,MQ����3A�u����R4��7	�T�"[�9뒿|I�x����m��:V��~��H�a���u�?�B[ׅz]d��D
�F�u��+V6�L�x���r4�7���������w��8��������G����������sÆ�y�.����/�j=I���\�Β/�-�	�q�$i�� ��J��啇����Z��{^�G�y'�=fbE	����w_�����U�q����uDJ_s�����d��WKI`H\�<���=c�k�┅8Z���.=գ�ݿ������nw���'ˑ�8^�%����t?B2��L3+���u�ug�x}z-|�S-/P0�^��U0��ɽ��������4�~�LʶJL�����iz]1y��x�0��!��0��)�g�R:kou�������]�#%�'�Z��l�Wx�$���� ��K�S*� �\ ��:: "���cDX����?j4$=5��S��ӞZ@�:�z�~���|��;\g������d������Q*�~^QcQD.��#����}w|p���LY\G�x�b1k�3�M\2Oic0���Q
�s�T=�h��8���� �S nQì�K�d��A�=���qw�������?>�n%R��L�����z���ĭ'gz���E�u�	NG+��h܇'���6m#ߘ�fV>Q�� ���	���j�\'�3sL{�`����T������ˢa:�X�MP$�[ewVڏ1�
��8�5�uG�Y�Um���tk��>s,������,�|��3�̱�~r�UY�V��ެ�̜}f7����	�;W��9�C�/����@%�����(b�˼�@I����٣C�#d{�E��������h��g���
$L�-*2N�=��蘈
f���NW��	�Ө���'B�04/���OF�Z+w�K����`���HU��+
���7�>��)�����=�1�����7A]'$ZQ`iߧ�_bj���h��c>���
��h���_��[k~�xѧ[U���UM�݊���g�%� 7�	FFF�&⏢K?��$M�QZGC�|�ꐲ��Ƈ�]G�5���Y1�5��1�	���u���{T����zq�Ua<(�����H��ٔŜ���I��">tќ���iu���������Q�uǕa�Ln�l6O��'V����\�L��{Zi��"���Eg��~�adS�ኗbԫ ��z�Աc�h�z9n��A0� ϐ5ES��w�4�ͅ�G�L9p������=� y.��iʢ�	輓c�F�ƃ�����)�,%���q2�$�B%�O���8�mp��ʣ�^��}�F]t�c�B-q�jT����g/O$�������D���}�j�����1��J �z<�|�L����v�����ʚS՚�魍[�m@k����Ɲ�9֬^�'6�S���������c�HN������D<�O�XTc8yO �!��u�٭s�\����tA6p	�ǚ{WM?�T����9ۋ�]����B���6�������L`�G��ݿ�﷏vq��9�G}��p�!�Ge1�1�9�2�z18�=�+-�هV�����]��a�R���1	?�Mϵ�/����k�"jeo?�I*�{�{��ŻA]ք���p�nd���d0�w����ƒ��% ���>`|z��ƀ�ސ!(�f��c/f���9w�?c���UB<�Śc��m��8�;Sл����S&�&�{S�/@�b��1I���`�h\�����:zv�Q��I�}����0�-]���\%��n�s�$���.��<JY,��LH ��lk��K��4y8ޡ\�ߑF��������csH"�՟II�'.3i+�;9D2`�v��G�;���o�E~V�ݜ�E�k�sf�|�C[rgȒ����5�Ш���4fԜ�����\���bo������o �W(�.���J���%\n_��Ռ�;��R�.+����U~�-�=,d��J���|���{�S�+
W���&�����8�Z���M�!z�`]b�SN5EdAvS4�A
�΅�nAx�Ma����:i�7�m�_�յ�ew&������i6�>��m���Ik�F�����fw����
��D��v�K_`��K�ǩ��)W�f�i���2��[���3�zR|�t?��&�W��,�	FmVo�JR���7�b�G"�Zݲ}i�ɯ�)k)��7[7�)��P��t� �S��~����4���#��4I�i/U{.-2�*ᄡ>! �d��K/��3 �6�5d4{��5����+�jԂ�sӣ�Z��JIhHP�(�ʫ�T3�gu:����|�:�����a�Pa:��`�E@F�쀯�����o+�<m�ٍ��r���w��F]���ɛݣ�bM<�m��Yh�vcpV�7Z�-Y�E�Ƨ�/�Q�u��y��O��Z�n y���jWE���ӄ�H&*:�
��0a
����#BH�3���ߓ���?��9��P�Ct¼ֳ�"D��T_�d�-{��\�_��������W��wcsi�����c�uk0��og�M��c�L&�dU�E�}�Kh^�}�G�h���z�������O���V�[n�fؒ��d@��h\OІgd�<F(�E[����;�>*u�KX.�:վq�?�e�֩���9|)�L�s8阠��ÿ ��Ho^�Ȼ}&U@�$4��3��䃕J�EOr:'H�֟s<gƪ��h9���������L����G귲���	K�-�b��[���Q����G���o��MnM�j��Mo�,�3�
^V�/�7�(YD�9�i����2��K���Ig��1�L�<|Q@��Z,8�M���͈�)����"��96ʵ�.Z��;N�ձ)���5�Nγ������O �
�pq��rO@	@�k� ��┧e�<�I|����vt�Yԧ�d2��H���PA����R�ip�&��)�74�cVO΋ޢ��'�,�U��BIlR���`���"g?a���M�-*8aز�^B�����Z��0�#a�&%+�C�Ю$��@2�� 掣��i����ʔ�u�*m�d��1���]h�u��7-�B�i�[����&�L!C8�x��jyjl�(J���'wx3��qC���!������E9yT�O<�.�� ��R��c��T:ڠ�@�"ºgN�lABu!8+��g���X��i�a$���{���[o�͉��$<�@- <��L�ClN�m�w/�g��o�
����cv[wvQV�J\H�N�У�\FQ�"����q�*�MUu�<n>\ͧ͛���o�X�A�0�yHn���r�dE�=]��x�#�?��M,	���ƈ0�V�X���ˢ�##6�T��d ��*�v(���؀�2��|��f��hÒ ���h�P��֝dٙ-�
~�[�'�D�z�nq@Ió���(iq����Z�pǽr^����-�K���n��ؼ,�r?C��"��3ZI:j��z�0DO~�Nh���kUh���Ú�2�&`���9�z��8�
9ٱ�·_~��g�k���m�"�n�D\�gp}"�C�w0UG�3�ƲZ��6Y�Q>\�����x� �1�]U�"��D���!� �c�	�ޘBB�уp?rDD���i�P`�J�=]r�/M_�ak�WI��&�z@,�}�ɜ�F3�ຶ��u�	��4n �[����Lss�}��
W���OM�L�d�b�l=��Ř�5@�Q���ʹt7�n�b�nmY����Er��eAâ��l�r��y'aFg��1VB�T��I��Ū�o��E���h["ظ���\�t�1�1��P�,����}�3]傑���c۫�b�m����вzBM��D� E�N��{�?! �b荃���Q¦)��x����CI�[�Jm��3�$�J�
1w��XTB�>��77b��Ѱ�H��{�X(�����o�|��FӏI��1�?9�O���񿱇K�ϗ�@���1���z{c3?�7.�����2���;γ�s��ڲg�蹅6�wϚ�������:���A;�L��V�{��կ�0�����2t�3�����̲�xXA#����ǳ�����3�y�`L҄%�%$v��M>O���MS���,�+���y���)��H,ĳ�6�gM���l�DC�pG#v�ڪ�N�Ӂ�����9�X8�4�S�A�,+�H������T�A�di4�����T�πQzނ���Y��Q����eD+8�U����0̋dn��(�KZ���Ӯ�W�#~i H��KR�@�$���M�����0:u*�"���h(KjA%k3���_r�ˌ�>Øa$��,����0~�E
�����g��������o�����}-���X�h��6֗�__f�O]<�'�Ɔ�Jc�q��ɸ=a.�U���k=q�
��/�2Ո$���4z߲��7]�4�<UI�(g<LYz����ݞc��,v4<���������H?��?{�s0'�gKdM�˥4�,�t��*ͪd��U��S~��pѐ�<c��ǚ8�xNֽ���n���.5�1X{��%�=�<��a�����8�\9B�<o��@�q&ː���t�Tg]i�����!��I���Ƌ	yl�%��䆒��J-���ir��|Ge�M��W.��Ș����XOfL�-������<�
��R��W��Y�0�\0����fR����H�#�M��%�Gv�L|�m��s�%�0զ�	m�b�Xh���d͗;I8�A#�3l�5� �8
���n�����*�"c���8e^�Dyk��P�T�Ժ�%���kJ��"u��]nz���zS���f�2���aRR�2�e}���n�?�1�����N��=8r��l�>=�G�֟�E��J-��,�������Z(c߻�- �{��0��=|���}!��K>��P�p|�B!���'���C��'*T���0��,���&�;���c�N��;��e��D^�^V���/���N��ː>Ŕx�G9��0�f�p��&H��l�g�删��w��J.�@u�A�v���0�|�ZM��Mp�K�$t��w[v�3~���}zք��:B2��W�#���SL�1RP�0P'8�h������Q�gM$�$���n'rͷ�_'f-i�)t�:Ĩ5����C�U�B���)�翌
�f����?���|��Q��l<Z�������������)� g�̮�y���K�l
�:�E4��؏.����~�k' W�~���S}��*V@R�>P>�����6�A��H64�$B�`[Q!�����E{W: E&uN����}��,�g�i썓����ה���c'���|8�躖���+sb0��$Ɏ���&��g��0�gd���č����P��Oj�6/��#2�P�q�	�y��zZ�k��f� I����8>�t��.{�����Hp|�{�@�$ ��WS:x�Y���$�ҢZ�zV9F�+Ɇ(��\�A����?�CY�D�2ɫݿvwJ�0�i���6N20����~��!'�\h�U��NZ��0��g���4iX�g%��?��"�&Z�mX�G-��LR�0����Y���ў>`�궧x���x���
�4�˖�A��XOB
��["��F�)���z��aк1,��U�;�9L���,O��0�,�R#+^WqY�"C�H�I�d{��P%mžA]0�XE��d�W�Ԁ/��xg����'�Y�V����3�J�)AM��	8�=>832P$����	��qS����Am�|:��\�ro���}�"H�'��
ry4A$��x�#�s}s��Ѧq�'�6�����i��D��haf�w�Z�%,L
'�$��1�)Z�_6 z ���!?��S��-]�7*��`��/�O���+/ގBD4���̈́r��Zhp�����_���x�8���ۏ���/����Y2����٭���4�/+�)�o��R%�HF����}ǹ���wy����	hd�gf��e��7�����y~E�hle/IߦXvһ�-���P�e�f�v�|,˩T�Zs��J\��̿��W�7�8�Z��	�����b�rӥ�������t@���P�Χ��c�И��%A$�א�|=M��}fA9JYU��@�.�@g�n�� iJ���}YI6�if��@�#��B�R]>[+�|C��݊�M ��I���1msbVaP"Z�5EY����������D�����?~��@vQd̆����$��cT6���0Y(���ܥ��vjE>�77t���a����U�w�JE��1����A��$Ft��L�(��r�?p����7ח��������h��T��iS��U�%�+�������y7
�ϣ�0���q���4�ϋ�,��w�U�`��$�3"�U�42�$J��ǽ�N��g��Lh��G��7] {Wɏ�#M�
pB<!q����E�-�0['���jd<.�ҏ&2_x	��o�;Z1��ZG�<�ֵ���("���$�D��O����:���=D1%�Z��g.m�e$6�G��!���؂9�T������O����&12A~��>q���q{{�	���õ��K'
MRHz��A�a�&&��t%1��$"F2������GR���+i���&���M^W%���2~PzB���:����d)Bj�%F��uZ�4�}��)�{��8��*�(�+0ڱO��h��~Y!�$�,K��v8����̬H5�T��O�bA��3��)�	Ŋ�yt��Dw2�icD�^�4qPE�H��4���#h��MΉ�F���Q�i�&�o�L����{X�o�ꡯ�y�0��`�W�e<3Wm��h���h��_�������,?����,?����,?����,?����,?����,?����,?����,?����,?��W���5h�� � 