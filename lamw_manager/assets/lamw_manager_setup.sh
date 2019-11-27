#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="97392603"
MD5="689c2e5f597c25279cd53fbb41f6fef5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20867"
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
	echo Uncompressed size: 128 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov 26 21:35:11 -03 2019
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
	echo OLDUSIZE=128
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
	MS_Printf "About to extract 128 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 128; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (128 KB)" >&2
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
� ���]�<�v�6��+>J�'qZ���8�]v�"ˎ�ҕ�$�$G�!�1Er	R����˞�c`!/vg ~�e;i�ݻ7�a��`0�7@����Ӏ��'O���IC�N>�[Ov�nmon>}���lln=}@�<����f@��tݫ[����?��뎹�/Lל��_���[�O
������i|�����~�OlW���L�j��SU������-ӢdF-����f���c�#�Z���l(ն���Ԧ���#�R�/���F}���T�a�.i6��}���Z(��"��U�v�،�foFB�z��G��W0=����	48�$���4 3/ *��:��.��Sgg��B/}h��<;=4�ckp84��c5i�Ō����p�::2VH4�۽A�P���ag��y�igsuNF��x�w^wGYsf?k�*�U���@��t�J���v@��\��PŞ�7D�}��_���ZT�nw�U*���0��atD����:��m�N>�!��Vֳ��\B��@�A��|k��b�;�|kc���@wۢL��]��C٣�k�T^���������΀W�*,փ���n`�����X�}�g��]L`sp�h�eCh
����Né>��'%��bX�[`���]�n�81յ?�o�HvSY��R��s���.��	�l<�F`~SP�y`��Qۄ��y C�jB�ZK@�r��	J�ifm\�j����)Z��T|,&�g��CF<�� ̘���	�MW��wD��g�)ʜ��@����|قLg�f�	�U5����v���"7�s@߮G���n( ��v�wj6��%JY{�*���?����96h�;3���9�szI���K����Z���y�:=��#h�~�O�Op��r���^.L~@����zi��^��{5��ïW�StBZ\?���4�R�.�k�T�d���A�&b%n�esSXI��7��.L�M)U����e����S�d��t�O�NM�9���3���(H9ኬTd���r�VԤ�%�~�����C۝�!��!���e�����������������K|�{h�"Fs6iW�4I����9��d�W���#q�ȇ~��.�k��J>�"߂�_'��_�� F�ߑ�777����l~������Z%���!9�u|C��;n����Jڽ����頳O&W�(	FzY�W��@�E�(�0��QXp�=����B&	�O@�e�l�I �a|܄�ca=_X��}3`"���bAx�׃�U��8�'�&F[Ա6���&�;ׅyNuf����,�`@�5����v�Y�lWדau�ӿLQA��rV�V{�A>C�ʑ嗾�2ў�	������L��t(p�N�j�a?���y�ES�V?�Z�/i�y��߬��l�|�����b�U�D�cѠ�ξ`�������_�����'�����ֺ�Q��y���������vp �Ȝ�4�a	 D�]��xT�/���Z���m��\+�l�9v�jѐNCb܁���#3�q�e�#�6�z��e�凿���)/V����/�H�6֝+J�񦸇6�3��Q{�V�m�"Zwi���a���X�����I�i�PW`Z����إ�������vd��%9��4��H�̩�����ت7�<����j�IDƖn}P�� �q�^0�&�����u( o��*a,��q�5zn�z�ݱ'8�CU%���a�<��V���E���Q�5������މ/�^d�5i��qQl��\ھג�o]�bwz�,��1h������he]i����$��4s�EͰ��)�W�sS T�~pѥ�u�{�M{n��	�@�E�<eH� @�9a�b�៎=����'7Z��{f6�"�K4v��W�$5�~�c�X�'L����tW�t�ե�f��̞�!��*��m#����� �DUW�N�19����~s�o��/��J�g��y�d\T!ߥB~z����	�����F�ӓ$5�#���k9��h���6נ�`�U���J۷o��79��QL��n?>2�>Ꞝ�?�w�`�3�SX@:$�×'���7�%3��彪�>�翩%�K�t�T.�WzS��6b�.��Q=%�[iʓ�9���
���C�C�8�T֏h.V /^,L �b���6�1�iq�{f�s��ۯ,T�)����R�����G�+p,'�Im�����Qkp�&X�^d������ΑJzô_DT�=�����˧-��g/�/�T�_�9�6pg*�U�ܘ\)�Iܒ�H%�� �c�t���J^���!z�(�h�$!~���%j�/d%�{ߟ^�pYv��m�8\���=�����t��v��e��k��ԮOz���эJ�ղ!���R�K_M�Mk�گbh�NS��r9[UI֗�H>������˙��t@+� �u��$`�u�L�v�K��>��d��ݾ��|���k��i/��6�Z{?��T4)Iƣ��K��
7�Nf|n��\�~��!�wl."Gr������h�o#�a��C��� k��3�il����a�>W�� ��<
R���R�t���u8>��l��z��q,G�;2Naē�57[��5�ታK�I\o�rr�W�I��y[SX�/�$�J��gٸRR��9=7�Tx���A��h�(��I�n���^�0�Ԯ`������|�Zse��U���/�f��M�Q�W����o��n�����4����\�]`�W3����Iz\��K$����e��2{�P^���7w�Q��׉�Jx]�^�2�.)00�vh�sD�P�q%��w-�:��ڿQpȠ���?s��` ^K\�p��\,�3�� �	|t:����K�"j�'�P�U���i ��&�A��=��l�=��<�	��>?�$Q��|�|�!uM�����;��s�?��pFO��:ǆ�Fl�~OZ���ڶ^R��h��e�d�7���{�Cm������w�7T߉�W}�>$��Q*���q"?K��bJ�	i`4X�5\$/c�@��U��P,m��_"{��b��r��1�JPr[TR��O���o��F4����������G��\N*B��"��C��g@������1l�4�x�4��������m� @H-��%y�����J~@췈��nRsbkq��SK�Vw�s�w��Ղ�1�V�L��6i�1aO��~[N�y�!n�/�=ρ\��������P4B�.�E�!.�U*��(�5�g)���	b��rNÇ=B�	c��y(v	��{�~o(JV/�"�m!��f�q0"ɉ���
�qd��v�"s&g��i��V"^x�w�Τg 5���fvDA�&�X�����ax�
Oߛ�[��I�k!q�WS�T�Jԩ�����Zݲ,�>��~���&D,�-�a�rcPLy�� �bf4�x@�D��0����.�ݭZ�G�D�!���!&�KD�9�{�;��3 �O��� � 0TVw[��,P��t)�,���ݖ�:�+^]!�<?y[%��H�Q�����L��}ȣ��iȬ�H��Q�;2!hP�Ԡ<�D����7�%HrF.���0!�.t����]s l5�e ���.w��9���PLŸ���E`�������b�j/K��L�#���UpMKo�E$��<� >���ET2{.Z��Fz�h�s�������* ��b�;���pc�'�ScQ�Bv��T�c����gAXra�f��������?��C|���QG㤐���t�gΚIӔ�~Yo��e��Z��r"EeX��G����r��c��B7!/���$�ǻ�^@A���m4��j�U�9o��ٳ��nȍ~�� ����w7r��%!��~m�:6����S,k]v�7r�\"�w	ގ���yW4J.�M�9r��R�
����[1)W�4��Cq�G�ez��䕵����μ]�SU�k1�-�n�~r���7�4f������N�c	8Z�\1�\̘�������u��;4g�8����X�ڌZ�AL|2�V,=��cڟ� z�z��a���O��3R�wʗAjҦ�<6B��h��b2�����ȸE�T��\654���G���BҐ�X�Ͻ{b��/����wNz�����!����7�+E!bo�[�Ktf�EvI�x�u��V�wO��9{��w�"��qF�{�����y
��X�[��|6���lY�M.����9��;y��V,���Jt������4
�N���� �{�}�!�D)g4��?v!ʀ���,_ʹ���)ݓⅽ��/����r��bޜݶ(;=�Gؙ�/�I_y'r��\P#�55����E��j�NsGo��"w�4���\i"��xbR�����,��5\ƶ�ԝ�����D�z݆.ƣ� bc/����|܈�5cf����+��l�b6�AR�<v0�:�̶�
!���ы���.�ڞ����5E���c2Vd�1l''+���~��;�{�)^0�{2���P�g�X�d� �9��RDB�J��q��z�I�J���[c1CԖ��bȡ����֞��^�Io [�!Ӽ��}����h'��%�\���w�.ۿ���񆗦Q�L㏯5q�V÷|�Zm��פ�D'��m�	[��ǝ��qw�9N�R��<�Bv��%)�~iL�>��x�3|1���y:H��)�����E�Qǯ�]oA��R�����B��<�-��3q���B`�R�B� �������&�-S'a���E�˅�Q�(Ζ������#!�@��ٜ�����ރqo�뗐�����tO�<Q�N�	�o$*	�(˚<D�`с%Sھ�Bqb/E�c����P�v���(�ԟ�O�`rmQ��#{�e)@Y@T���0�$��Y°���L"Wf<ʮž_.t��j׽~���~�����}o�k���|� {�u#7?wP�����D1Gڛ���
=��S:��C0�=��%KG��
�<9H�"���:�����$M%6����'� X
�)�� Urd~��'J` ��S	H6w.��]�/d�٪K `Zr�''�xK��B��Q&�����hRrB/��Y	c�eґ�*՘�� ����3��"JR�ǏB�Њ}���_0�K9$uƱ�	��B�U�a�`�g��j�H]"�6V�Ҿ8?�z�_��|� Bpm-0oK;�°D䇑��l�!\���ihlƉtRq@�,u�B9���(F#������:��I�j<�V3DV'��w�wՉ�E�\�>���G2T])c��P?S�}(���u͕�Z��3�O.~g�L���k�����u�C��9�Tˣ��q8QKX�J>�܎ wI88��X5�x��:�*a�y/�ܽ��Ȳ;�Je5)Ũ������!j	sj���S-��fAn�M�������6�,�ye��Tc�Z @�Ҥ�J�d�y���[t �@�*@aP )Z��/�4��2�0���c{.�Y�UY H��a����ɓ'��ιz��wh�4OR\����$���Rw�_���Rb�l�����O`=�]͇�|��/f�(�|E���q%� ��eK������(�w2�k��-����.b�	b�F��#��`I�Y\G�F�O���+�Pl��6���Q&t�=!I�r7�Y �b(���d����D1���e?>��3U����Ɯ�U�{�����&��ܮb0���'�d�\����`�Z�/�+g:*۳���Q�L�h|c�ʜ�V��]�2,R�7Jhni�yK�˵��X�ُ��r.Ѽ��gN�9�_7���V��C�e3
��P�Q�:&�	唪I�z<��PW�F��S��B7#�q��^��sp��hM��%R6��H3��E*+���"�����!�E����٨ۙFj�|H׈�Z�Ew��~���1#���^���*���I{��E�k:��x�lD�.~��W�^��.��O��Ä����?�C��8]��N2?���'B�x��&m�g�F[+��:I/�G��qW��\���a.��	�@U�c�w��I@ߡ����;²��?�pJ�LA8,þ�)+|�mD42���5���A�G���r(�Հ5+�~"&��T�t�?d�~��(��z�F�pD���@~�*�O�a�/��s�G�x$��bo�.vq<�E�+e���J�d���1R<�ii���z2>e�t���קA$3Fk�Yk<��R��g6�ĤY#��/}A�_��,l	:Si3��ؗ%�K�3��Q�ߥ-���A6��"AY��\��Q�8Sw�3[ItQ�tV#Q�S�S}�t%�lT�g4P�W�|���Z/�_�M���BM͑Y�|ɪ�J����S�>����Щ���\�#2 �$�ǳ�H$�n�7/��߳S�i��F�#��
̴�p�b�v#U򫸍�*sC�Se�z��)�+�d�[��{����Ւ����6�*�F����s�sw~k0Q��r[-뤩�3$E5�̈�9��:/T��˟����@N����n<�ģI��{��[�X�
*�l&w)/r�C�S>+��_j 1���O��$�`��� BC"F�qD�e����0�hκVH����e�>w����Qɒ%��3U�P?���Ky�d�t��O�=�6C��}�0R�)�MzN/	����AZH��ފ0&� t�9�I��nn����H�tfd��Z e�W�W�w��A4J�m�}���� �QX�\���ʌ�dn��yh�V�}��ŉ��Ir/r��T�b����t4��LQ�v��d��]�8���L��b��Oƞx�I���y<S���r:PC8���{K�T+tΖ��o�{?����y��Z�￥~�Ϻ�.������2;r[9���6G�ɑeq��f�ݏ�Q��~O�}��/5y�m��r����J[!�7���fG�	4tR͙r]�~�LA[f�լN;�3�����gY�����JʭM��f)�0�w���ho`f��7�y��.W5����S*��ѹ�Hp�X�R�TG��h�/ݽ�+��sJ���9R~1%6�!ƹkv�
�D�����Q�֊��5h߷�J��H�gHo@^#�e9�󘞭GR�쀗���iNm�U��Q�j��1 �lU�ՆY�}�]��c�o:Dk|ߜ���T�m�T�M��J%.�>�LH�������IVG�f9��jJ�ժ�ӏ��F���R~���� /F���b�-�^ �%'��H�$�Yl��|�t��/"�q]Z��L�-��P�^�9�<�g����l��������kl0�N@�t��֖��Jb�3�49�����AeG�!}�U���?��e٩3T��1f�2S�8#�1�Ex�򸜮����W۾��q�l��zu͇@7��i��'o+/�?��^���?�^��W�8�
�!��$���=�-ūc��3��!�5���I�4%�5?!�+_�%E�4|�`겊hV��e��F�zY�}15ݲc$I�S�+L��`=/�\��n��h`�]�#M����YUX6ɨ���B���,��\��9a��H�	Jw� ����d���W`^�ǫ�Ҫ�r�J��Xj
���5
�`\����.`����C����q�8�c},���m��9E��|*��˅���I��g�֗8��z)Nj�{賱8���ͳ`�J�J�i� �M�/y�`[�bN�t~+A�W9-��j����_�MFY٪������W_ol�s���?����]��okպ���@��|Fc��v{$v��P���s.�4��m��
�|��]xi��}P.K;HV�u0޼һ����{����]4jos�o�~<F�O�����N�Y^>�׷��e�2|���w�Qk��ƵO_�A���Fo���ֻ�����&W@��G\�*��mX	��z���H�iV6���N:{�o�k#��׮���>^⑀�kih0B�b2I�n��R$^A`i&�������=�[���]
T�'_h�NЏ�Δx�W�W��r/����9��=Zw��1���D:�&�.>ߓ���O�ٹ'D)���A�Nm�ɫ���n�4@�����3[{v`�+�3_��01���⛗���C��-�\!�����Z��1�
���:v�D�h&6g��De����d:¹.�/��'ⱨ��^�8<�a� ��|px�Zv��=d~������烽�`vr�"A�Ҝ����'�@\]d_�ϡ�%�W�ג?q�y��>x)_&���U���$O�!;���j%Z[�X	j�\)���{@���T�~Wa��(֐D�!X-T(}A�͕U���� �TT�=�Z�خ��P��%����>k��ZM|Y5��e
���El��s�R��C���=�������v�k�?l��j#i��C.L�p~A{p:@| ��l�������U;��	Ks7�i�I[�e�>��=9i�t�������ʙ�l4Q��d����%��m�����IZG��f�T�V�g���dR�I�r@��8��E�V"���*����)��s:e�M9��n�%�R3g�N�2J��E-�ł��=�OP�^	�ҧ ��IGA�D��-�C�	�Ҧ�h�CӦsk=�=i��u5��-�[�`�Qi(L���u*{c*�mXˆK%u\����5���o�-+e̔���3d&Q�^�A#�>Z�tu��Hdw����MG�b�O� Ƴ�B���܁z�` �4�in �N�WrR�Td����4L�)Y�"sr��&u�d�cL��^��Hd0�S��<�%Y�H^�
E����Y�r�l�yZS�{����N�we�? %~��eA�;*\Z�.%Pu��F�8#��d�0���e���fF�3	=��ϝ9��n�)R�eEU"Gj�*����5F�6�\o�z�0���!�lZ����WֶԢ��c���`��DN�����`�����8��"F!�(�+�!o��l:	��Q؏���2��U���1>ٮ�G�U��!��gs�GW0�ar6l�u�w�Z�%�����LD�zR��3:��I/�:m�,H�/É�;�9Gx��0��a/!օ}�g]��S�5$U��]Q��ąx���!VƊ�NzE��\I=��v������	Ԑ�y���#q2���1~�;�Dο7��t ��|d��&T�I�n�"��`�G�&I�<D�a�"�[\�Z��~�_�G�#ԢA�#��i���T��4��Щ��D�IgLǖ�r�7Az���جޯ���	]��?�ҹ@D$`�)0������E)���t�=,(�C,��tD�RŞi�X�T$���CM�B��
KKت���(�I��Ԛ�3
�p2�=�"�M�b�����ŹR���	��ue:�آ	�"���l�l�P��>U�r��:\�V'>�8L�D%ٍcL*���YK�p
�%��f`���2�(?����,�����뚹���6~bϹ�%'�?O7�@ҟ0+1}yp�U���5q�������y#��g������σ��;����㛫|AG?o��w˕�,H;���r����ٽ4�����9��'��dGn�N�:D�/�Tj�1�S��4�K������{�u���e�Ud�q�a�'�Z�PlYָʪ�/TL�����ц��rs@�e��#׹�gGqT.�ٴ���胙�{`�$��C(�ݟ3v�ү#�XÇ�&vYz�Ҫr��f}�~�En��,HX���t��YBۿ�W�h��� ��g�`"ȡ�R���T6�琌�|��OBz���Z����5-�p�ٲ�H~F@6F�,�M
d�Id�7w��'s��4�+�)�27`�5lO��4a���S�v��6U�R?���M/sZ�LB�f�B��Ө��λ�]��2F����M�r�eh���
�)1�%^�� �9�Շ�|���/�vi��Q<�r�~jVǗ!��'�'��(�૶��5��*VMj/S���?�; .q�4�H2��U�!ZA�fTe._�����-XH�rFb��-�����2b����qK�� U�r+�"�e�x����z���8�o>�ݏ-�A}p4�<��}üW�$�տ��NZ��'�߷�_4Mmx�o�a^9x=����D�u��,��Z�F���;�jh��lr�:�5�K[��K/&�1q�!����FC3~�յ�=b�h�Z;��#�n-<����	x�I��Q }_����v����{/C_�C0��B�������v3�]v�gVܥ�?c8�/7�ͪ�/�vS�-{O�4�ÞS�돴�frH�)��,�����#�@=eFS������P���ԓ*jۤ���y����>輆�`zmT)��5kg��s�����M=�����	uR-^�������C5��W{� ׼ß����(��!-��X9��#&���kϽ����t���^�:	\��`��^ DD�G�~�� Vs�Y����a�PI-Ln�5���)��w��$G+O	gT�����Po�?Tá"�'����#7tN�t�z!H�~L��`(^��|�����ɇ�>{3��3I�8\�RHRcJ1�����b�Y�K#Tn�-Ԯ#8��e檤Z�u��4��C��T����uDbZO�ZR�Z�Q�a�a{�FHf���SH}��+�Vj�0������l���d�vY��!j�;��ܣP��X֥:U[�l��h���Xz�(�䏝�Q̐d|N�/��`�\���q[㽌�v��L����7$O��T�x�"��b�*���2E��=�	��Z���3��R�pD������,�CW��=� y���5&��%I鵉O�4��ȫnFh^�,�����Pt�Vn�|��o�(��V�����=����2����FKS�,�!����C�l� ��f�S9��y(I����\ب�������G�����SN�� 	o�_`�U�.���Q��d'dUw�?��<��[�ז�[�tZ�~˗����0+h*kKR��tL���
U�,��{MX��,�_EE3Ş�Ҙ����A����#b����A�Ն�;��o�W�J�u�aBTswȏ
���(4����#H�64]�����w��Λ������ڄ��Ǧ_��W[ԗ�*����,�!��
{ ��^f����n+���Ҳ9v˩-�\��뽙�h�щ#�Y�w���F�!���ČSҌ����WBD��"�A�24�CԪ��P"�W$+ǭ��v�U�<=*CE��h�5uWP�~PP�=�%X���,�#�4tthA:��i"Z ���YcJ?;~�]�?kg�z/o�6��%T	�_ګ\����љ�~K@	�����A�Cp(5��!�,���m6����']�B[Qj�b���Me�ܭj�3� ȱ��&�}��wr	��/���^���kO������D��2u��3��'_�}��k��K�[d8�E1��U>����e�m ���w��=��	��Z0��%K���S���^�1�f���3^�9�A�~��Y<��㋱X�[�©�}��վ�8�ޒhg�q��S4���8#�ca���:�P�ɮ�ŗ=��-��w�CN<�\T��
��| �7�m4/���vU�.�[�n�*yc������pr2�.�����O�z[!���R	7��&���UqBWD5`�@��5���µV��j�d4c�Gb��[�cl6I8������a��e2E��A��G��&*��ՙ�����v�'�>�����\%�*���"Ʒ;�^J�5��;����Q�Z��d�l&��!8,�`��%��F�O��p�},Y�\�u2v���Յl.�FK?C?�k3pV��l��57�`�!s�Lm��!Jm�AeU��F���&�
ڋ�v��]�~C��ܣ��x:���1�M����r��k�t�s4���01�GWnʃ��[�I�c��~�mc�<v���n5��n�M�+�6�A�ӛ;�i���;nn9WHC�9��Yre~��6&��r�§w��ivva@Jau@�`��l����9B�����݃�^,�E��6��y��I惸lN��J���+R/�a41v���aV��
���W��=�W>#��G@�IЧ���q�i�Q}�i�������q|���A)���8A �>U:�<F'��|:K��o��h���suR1�裘r��oC/K�î�OӵiuAҗlXʒ��������<B�ҥ�ཥ���MT`{�z������S߾�"qý0s���`ӛ+?���_�䉾��Sי/�UP\�@<R��Ȃ�p���$Cti�rDtaa�����vZ��K��+�c��4W�l�*n°}�]�f����׌����~/%�X�ޑ���7y�~�=� s6���{�:����$O�w9��#^���I���O@8��x����t�OpΉOp��\�44��`^VZ1/q0�N:�@�z���c��_Pi�hI6q���,$����A���K�5��������1����tм4�-�W�y�\��6��ܖw��摟g�@dU�*/�+���I�BZ���6�A��z��͌)+��|��	���tx�Ό^�*�H��/������_��C�,��i�6ލ�Z�TS��"ZR����� ���LyKb=&�����/�L{�g�b��_��I��^��'u��v�x8�]n�Ahޯ���v��:�o�bE�4a���@�q��\(KF#���#]�N�x��z`�/�m�EI�%��eɨ��]1��rj�=�݁��O��駨vsn�Wiʧ,�l�z=�̓X(��xc���������	�a�Ee'����3էX�/�u�E4³��zcT�qi�k]^���}Y�/����E���(gHD<� Ke�7���'�\H�������u?��UQ2
y˗_�}%���VA�1L���ty��)�*_�PƲCG/����6��lV �K���QG3z�j	fU��S5r4����� U��u�	_��"uMa���1�!EA0��������@.1Uo)�Hß+�
��p��A�2v�r�5��X�����"  ��<����J?J8 �c JS�怐2P���Z%�3t;�r����v��+e���T��r>"3H�@d��t��|o��ِV� ����0{���a� l���g x�'e7PV��-�$��8$Y@g���Y˘p�]]0�(As��0'��nז�L[n٘u?յ�����0sF����m�G���w����:��eB��S��<E��+��Ჳ�d7�䋓�!5'��/j���Y�_XV�HbB�Y�3��r��3��%�Iw:[h��[B��J���ڮ��4ٓ�+vM����k��V
]��ȷU�@����G�C�#���z���+�\4	q��K�Țj�^�1��J˷��f)��xh3�"owb#i��[��)1�U�5�e���P�Nj��q�Y��{��9A�>,^�������0e�δ�����+�e�
NnP��_��R�R��w>�����gk%݆�m�A��Y��4���B)�RRo&��WX3�z3���{�5��'S�"�Q3�;�=�8���a��=0.�Ts-��>�/��R_6UVG?ꦆ���Ka���u'��E��uj֦͟��`Xz䲛������ś���m�}3u�.�a6���?��}�{��~set�wZp/@��D��̗ky���*�7+$#�z%n`+�7�R;�ƵYC(J�y�������s��,$3�:���(9rJdG�^ka���A4�V����:I��m4�3��`�c�:��J$2�R���ݕ
�=�P�H]�EQ�!�2�q��;9;@�w䷸�prYB�U����(�¼��v��dIQ錃,s�y��������Mr'�7�-a�q�!_��V%�$���������O���{#����x�{��-�[����ō��D���S ��z��\l*5�����UtĬO٫��Z��6���pm���e��
�7�h�A��+��1�z�J۳�*���;E��J �'о�������_ȓD��
;?�����&Ns��0�������v�п����{��J�"����Vƺd�?���t�*����|��~ͦ�<?z�F��O��%�:��A[ׅJEfgh"v��:ȁE�(Ra�/��r����k�<����
�'_��Q��,��������w��\w��|�)k��� u�$։q�\.pg��q��ʂ�����r�T�b�^RҀ���6@�S	E��i�=o�q���#acEI� ��'�o�J�`��j��0�D7DJ_�����n���k��0$�P�Lw����1�UOs�Rm�G�IO�x{��b�Pl��m��x�<u��
Y=�g��Z�o4�ʻݟw�uv�O�����4��n�x9 �bD��S0���D���{�c���`�٧�{e;%
��(�g���Q|��Bu'Fa_�a�G� ��(���qX��>:���&�%��(�T��?��m���v.�E6�߄�a�C�3�J�&�!� ao�a��4��!"��hi��/��Q+T>��Ы暙E;�_����Pt������-_���f
����e=y�"h-0r������N�`_~�]"S6� �^%_��G'F�,h��Ӈ�ڝ���`�s�� =Y�7^x���M ����a6��t��ڠ `?6'�l���?��36+Q��f
�_��uLƢ�9��87sݮ-J�{Hp:F�_d�>�x�y��k���5����U0�NK�g�z��{3��c�6����K5��ބ5���+�c!�5$�2�[+���x�ɖ�'s�\V�B�tguVYD����,�}�9�OM�ӭY����3�Wj�F?YgUվ�Q���(Rg����s�E���U�u��P�Sq��D��~ZE̎��$��	�=�1�&2@J.�ɇ�9��#t=�DV a�<o��P�q����ǈ���`����T���h1�����C��J"E�����,<n�p>Y%��	��O;�?��	���t�Ⱥ�@8����
`�jq�/������Ik�J��j�ߪH9!1��K�q��S�I�F�N������e�^��jk�/I��֙/�t���X�s+P��q˞ak��/����32�M���0�q$l�I��U|�@�*ܫ��~�=�����f�ļ�#��^HUL�;nm�Q�����T�a�ׅIk�t�M�e�G�S^sf�zJ']Ɗ��Es"�'���El礇'�gϲ�M_����p;g�vV�u���/|�BTr�39����ru��:OD|?���9z6��x�z��� �znlcT��Ջq��ӧA���ljm\&�lsaƳ^So�{qiqϷH�qA u�R�y}:��7����0��b�Q��I,'�J�*�^}Q��K�g�V 'L�<>l�;�����`r��j�5��!�>ԫ�xst��'԰>�ܔ2&"��ң�����o}��Z��ǃ��/�����v��M��.�z%�i��ٸ��� Z���=0�|gX�J�Ol8��h/��UF�l<�Fq��qԻ�9�� �`Q���# F�3�T�e��p����r��%�ik�}5Y�LSq���[���HE��~���x���%`|w�0�q,�޵�,��>�E�����;[�c�%��"���˜h�r����g���
GKt��^���+���/'�X�_p�E�ΧF`7��qC��=r���O�d����G#��C��j�s�?���_�{)m���)"��dz~�d1>���8jt��204�t8�B]�sz���#o�P;�X�\��DFJ��܅��%�gB�r���5�>ً��$�^C�a����*h�qO�~��G�+�ark�h��˹J&ҭ�s�K��]��{.x�"_k�� N;��<o��>�4d����r}�R!�;Σ�F���8�%�X���y�ѰP�r��#\��4�}/�bY�ݺ�g���y]4��9g��W<�w�,Y��Yv�n�Jc��S���T�B4�˶"���8�}�~�	(�:r}���B_�+�s$\n����M�g)y�UZ��H+���۞u��b9���^���B�����nT7PF�j���lj��G7٧t虂u�O9���LMX�X�,D�w�c�I%�l�����g���[tg"�<�;�f�R�P~$��E,���uĹ5��5�H�+���C!u��Bꎲ��<�Xr3��6�	�V{8���_6,}�z�`�cj]O�;�/��Q&�+H3���f�����v�i3�)d|zVC��R������j����m��֘��x:Ԑ��)������3�o��;��O�d�U{����)V'����)6+�
�>���c`�V緆T�f�4��츆?�F-X>��rLZJ&@C�G��P\�Z5S�pqV7�:�������6����
ӡ���?,>�	H�X�^���l[Dn�ϭ���㷇�#�T������[��͚��[3ג���X�֟U�2|k��Ӿ��C��]�����7t���/6P��+�O�"i�OD$�J�Dh|�0nG���
���H����U�^`*tE�G#�3;mB���J��N�ݪgp<��������o}������ƃ�׃����;+�K�n:`�ڟH��gR1&������X��nѧ{��ע�Y����1K�<�[n�+��K�/�a��a%Aj��E�X��m:Cu���QwѼt�e��+u���a;ŵ�x�����bdҟ�Q���9aG9�����Apu;L�� HhQZ:��KK�:�dޜ i�g<g!J�j��nd�� �)�I5��L�֚#��P����\��gm�n�qJ�i�uz!�<�P�<���l!6p�_6�:<bS,�j�*�ҀWT�Wv��-J��b"3��1��ԆǴ�����ˤ�RF�{6jF��JN`�(-�Y�<��\/}^]`�|��C㔳[��c(!��r�e,������v�`E.nTZ�c�	h�t]d2��l�YV�
F��.�?:j����/�Ѩ��Q���:9!�Z5�m@u[�oh����\�E3~O�]�(�΅R�� 7�)�/���hEF²k7�bjT��peZB��vp:��p��H��I�
Lo�+	��-��H��1
���6��z�w���[*i'EƸ�;Dz���):�t<�Nk����g.��3��L�����i8���D?`ۀ�do'�>n�;CA�ē�߁�[��5A5��3�R���.Bm𕲮k�Peh�rIE�v���r	U���Q�����qH�N� =���^@�8��d�;���
Z��� �S&�!�'�6<z�:`�3��7���E��1��Jҝ^���7�iz����(
X�2���l؂�
aSu�3π;���������.�砬�,$�āM�I5t�"���X{����:	��M"	���%B7`���k#��	�����AJl�h��I?D\5]*Q(m���R��l������`)���]�z��~�N���Vh9��-ݿSl�2���PҲ�ưw!�:%���A�KKl�W̋��c`��q�����"����C�oP������V-M�Z����ߥ� �r��c��j�̢
XϠc��<G[!/=����𷿩_��JƵ�p�*�2�\�e"�Y\�L�T�@
�K`9�o�(7DyC��e�qw����)�v7�I{2F���Qd0&�ŴO2��o`H.�!F�AH�<鑻��}9�
l��S���Fn@��mk#3lm��ki3դQ�%ro1��|���.����p]rBf �[@�-�i�i׻I��u�iH�i�\=�,���Y����8*YZ�$����IN%ͮo9����E��ⶠa1��l�b��y'a���q��	�S�"{�������E�Ҏh8<���i/t'����cv땗A�r��+��FBƿǶ��芅��6��B�*	5m��4餵���G�?G�ax�BWA%M�P��O��!�J*��W�U�IuJ|�WE���#4�I!��c�k.w����"�b�,f�b=�&A��=����^�Mj�is�_�_���^���Ӈ���5�p��~O��|��0�_y�����9��k�����z����������#Tc�ˊ�1S=�ֆ�x!||V��KQ�B��O��J5��e�{����`{��٪g:�$�(Q�����Q{��٭9{
fv�%Eg�?�O8t�gc�e�s\��i�\J�ɂ���/+ʪ�V�Ug�3f�!�Z����
6�#V8i�PW`�vZ�7ǻ�X�Br@�ٻ�~�1�G'Op.�j���v����B4,Cia�TVNuV�Ai��5���=5cC��z����R����2C)ĒN-2��hr��, �l�.3�\AU�2��1�LfM�-��3��|��	�\�iե��g(��#S�����j��*G�ǿ��L�PMJ�
q���5�` �l�p��P�Tբ�I-�fuhhU�В˚��8Mx�A#d��`��A�B0�d�-彙-�� �
�O�B�����_��C��`ӹ����gJ��2u��.���-�����i3QP�0)�vڲ<	���(���X$���_��NO�=<���,+=
�ĝ�?}�'p�i�����ÿ��$����V�Z�g��j�ok���F��{�����:��O}���'�o��@H�]z�z�G|��@��1���i)����{@��D��ͦ�2��^��W/�a^8�-�T)JER��@V��B,�;L����_���e-x��
Y�!�g��!��{�w�m�} '��&ǫ_Y ��e���]�Q/4`[��iF��Q8�I
���
��,�$gxY�Y�Z��ȣW ���W��%�<��q�Jx'��f�8lB[��8^���+�!���ռr�]�*MqW����b�r_&�ѫ:��?/kP�ܖ(����������l�e��
�o1i�X���T�]�ʜဦmU��'Nksf٪H�5[R���#ͧQe�8f�t�%L��j���5��o�d����Bmv.l����|��&�{��=�7�r���O���s�[B�c^-`ב�K
���D�kq҇�]}>�d/Z��+R��b'솃�p�D�^>Z�����C{�<��#�)�v��P�ԓǑ-(l�`T#3��V2#�p�pq̈]Tv�M���P��,6��XH�@{��j�A�m�Y�J�Ф>��b��$��Yb�;��� ���@p&%�jf����5$v��Z���X�ݼI�9�?�|W��>R�A�FX����?�v
&��b�`*��b�|D�B*�E��F�m�	�P)��7gw&�+������H�j��%�ѯ��j��:�����hBkL�(Ze�zi,���=s�r�mO/������_A)յ��a-$KB�����D��M��`�C3�_��
.��B��|�A�7�A��&��!��ԸL5O�y�;�$�$"E3��-^s��J�Z]0�X9��e�! ��ta �����֍��B1+ԊU�}<#o50 �DI�DV��������T��������59߷��9��aF�P��ޮ�Gz�a��oƢU�H��rzǚӳV���6��9Ѯy��Ǭ�&��G`��d�����~p��X	/�S�.�6�-���ǆ �nb�,����n�}Y����F�,����t�O1Y 1�2v!8�%z"$�������AN�_���-{�\����:��6�O�������o���h���ɂ��W9P�"�'��^����(2�?~�y��32|!)V ��ۀ��̌gfU���x�X=<ϯ(㍥(��۴����4��1���pi����O�9����#ZKV��l�:��%g���@w	����Vf���n{���|��<�W�k��U�c��W<sBX/�?dFI.��k�N����}fA����Ja�ֺ���o�E8���y)x�/*ɵ�9͌g|!�qh�(yp�[�X-X����m��p� �]S�_�c�f$�R-�@
�i�������,Bzga�H�=��?�t��(3�Cp���%��1*�yCh�,�dv���+��jE��+:HM��0OׁkD�J�P�l��'�x��H�?��D�.8�I���x�����<�������W��Nh���é���pL�*QR�~�C�d��қo��� y?^��~|�"�1�����c���Q��w}%�8D�+
A_���-W!Q��m���:pޏϥ�@���߂e�Rd����d�% t���A7���%���w�surSg�#�ȰH�EF5!�����Ϥs�(F��������m>0�V�\I�=��@%�?�>V^T�����*E�G,Zl`âe_���Ŀ�����ZŞ��I�W�J�����#<zx���.�����8In��m��tHиG���I�Z��hs�N��HO�>��&#�9q��&��4���p�*"�#�o6ڦn�
PJOz��a䟶�1��,�����Q׻Ɛ���6���=�B���E��G�=-�ĪE����|����=�{��������=�j� h 