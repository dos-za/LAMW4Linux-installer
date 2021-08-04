#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1851771452"
MD5="68d42faa3bda77a5f86cddc7aaaa727b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23224"
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
	echo Date of packaging: Wed Aug  4 02:35:42 -03 2021
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
�7zXZ  �ִF !   �X����Zx] �}��1Dd]����P�t�D����k�̰&��\��j�i8����΀�
����<����^�@�݁�H����橦���{3�b�*�fg���!ɇD�}��,U�b2B=�Q�+��cؼ�ru��d�y$�5}�7�)�W;�|V��REc|=� ���=���\��8�n�啬z}j�v�����GH1�����F����Кo�m�ض ��4��O���-��Yv�q�r��-��t��R����rOB�)�ى�A�/��Y��Ib*��-B3��P\p�,d�N�B�RF?��$ �G ��dM���p۝���|��ۻ���;2���Z���4��ج-,g�7X?M��GC����]|t`��E-F�e �A��V�K���Xb{&��������ė��q�ôy&��O_)�]�ۻ{[o�x��N.���_Ζ�I�.m�γ�a�ξ��E�RTy��B�_��s�\ӹF�~ ոR(y���n���ר��Q�XaQ�"yK����h9_`
�W���(���[���F:�<�;��2=�`P~i�����jz'��k�����o�p�q�Qn�U�ӂqڄ'�cuĔ
�r�e��a6�\+��� �X��n�Dȁo�0�x�n��V��T�U����h�Bn̡�jo\��R��?�ÿ<���.ň�.a/U�5h:X'��X�b���!�{�0{�$���~�1E��@ �4߉��._�n�K��q�]��M���YL�}�NÇnzA��-���5�[�,����R�${��K�= ��4���LL[����v`ȣX���G�/�Q5|.����{ r420��y�	�(*}}O�|v%��D���S}���zS�u][ֽ�h��M�	���q�EQ	s+��Kƾp�gy�I�3b~d{B��0����޾"�c Y�o�Y�R%k�63$����4+�DAۉ�����Fo�(��`�nH6@�A�~I~�O�' $i����l�*t�~�l�EB���l{�? �3���6��'�Y�+uA��o'[�5�2�Zp���_t��s��OwcH�[,��H��p�?���d�:�Df�q.2k�@�M�O���r��s�1�Kh$��nn��Q���>Xo���q���x��yY��)Q�v�Yę�֤�����n�8��T��6��T�>��"�`�}�y�ȩ�H2F�W�͐:��1��!��N�� ;��\�:�D8%�S�H��D�[(�9c�)��Π�dB�;v�����!y����<���γE����ʅ�|눭�gyO�L�?G���0g_�߀;�/�p�fz��s���5(l·�`�7��O�M������Dk�K�:�$�}ÐX�?_0SR�H!�Yv+0>��h��B�%��U��Z�+�^TT
m<@�P>���ƌ�@�t`�T޴um������x?��r>6V��.6���y�y�
m�c&�tHI �kBM�+������U����!y��Q��J�[zШ�^���ǁ���'�UV�EA�GF,@%\F�M�Pv�B¿,��+��.V�ؔyଥB�A�N	XI��3���ϼ���r~Ķ�.��nB�����rm����W8i�~ ���0���z
I��)'��ԙɱ����,���;�:�l=M��>�����N�5��%�*�̢�|2��I�H���.���]r#�{{ݹ*kGsX�P0r�����]�v��X�P��Z�HV������K���^�?�哢�wd��Q��#d�MT� �t1����Wc�0-tC��77^#Iүc�p�OT�˙GX�����@������P��Ĕx�(�62�^�\��֗q�<@x�>?!���2ῄAp�G��q���A�׋������g���*B9�E�����A�Cg��T56�3M�J����N��.Zז����^~d�lC��S�I7�P�Lx3~p�f�o��D+��9X���[~C�8p�:;��YP�l�ˎ�@:��ԆcA��0=v(�c��h�f)�8�G�@'��6��H�J�N+u�E%+�%�2� .FW�R��N�i��|M�Դ�H�������q�ˤ��7V���H�����U7o9�V-8��0ܡ�sЛ�\�[-�@v�p���6~�bY�V�/r���#��OY�m=�[Լ3���8 ��] Ц�����=.T@*ڷ}���3#;�6�w��{)JK�[�Z�#ޑ��)2�!��Pf��Cr�;�g"��\ܘ�xz�>(��n���Ʉ��;�7<=�B-�2&��}�ܪ���ӗ��e�,$n��J���]7,dA}����tLsBL�O��x�,�o��h�U�����D��{P{G=�{����&�!��%�����3�N��e�RT�-'�&0�8��jnҨ�zC�1F�^A&�.�@�v�`��ݒrq&�
-���� �;��n<L���a�(���e�|^�)cǚ�_�6w����ӕg�"�9V᠕Hh����8;8͎ջA��Neg�+�4�a�^(B[ϖ7>J}h��;H�s�[Ct՘de�bE'����(�MN��9�K�mm�|�'�ߣQr�}^p�M�Ey]z<���!���1Y̝T�L�O䕪nxyb"�&n�G�$D�J���6�$�t0p�P̋&��\J���gG��}�15'���F���i�%�&:�L/��$����D9����a*s��-��Y��קi���)�ϳ�!9!+ȥ�� �n�69�Ql=�P[�]b�]��Vg�lU������Ik�%�O�ŕ������q�N���O,������4��m35�Vd�E��D��l	���p�z�/g=R���Q���~�ī�����ځY���2�����Q�sqS�4���(�m��	6��o���s�74C^�G�M��yq
�:*�m���AL/P�^����WN��Q��	��cO�@�G��e�3I�U��euM����:TeA~�Nn5 �l����2������(F����X���Uj�b�/g ?�hQ�ǭ��Z)���&�S'0�7*�	��_�%@Yқ�o�ԅq6��x�ݎ��Ph߷®���ӡ�	s��7	4���뜡��"��֜������M�ҕ'�؎R�o�F�LV�nf#o�˥/Θ׹��M�9m������q6t���Ft�ziz$@�5}��6&�3!}lS��^.�B�^����#F��'ʭ�*�z���~�R�:��A�0��z>c�9�(��������p�Ԩ0�/�.H���� �����3;)U��\~m,�'�A)��{�o�_\a�,]�JqR9�3��<U���y���ۗ�4Ew�|��4^So\��?N�/9�][K�N��ï����Q���Xn�&��iE7a�'�>k��`�[e�C����zt�����Ǒ������d9� �>f�a��M���uMyk��PF,�;��a.�!����l��s���cf����UE�i7`\LI�y.x<�,�`bH*�4b΢1�+N2P�r�0�d�ۘ=ʉ? r
���K#���9�B�#�e8�8/8n��G����_Q����r�}| 8Pd��<���.{�H�����-�Ѯ vM]51���
l�N�g�N-����$��I���ɢ�B�J�a������Z/}le�
 �����e��ء��L�@7ʺ_L�!R�>5rioq�?���� |�����]!F�����K���* �&�j�k/���Zvxy�&~ey,o���bE��yJ��l=��������6^�+�^()�o�����k���}�i%���(�Żj鋭i9X�Pj��*��E���ja�̤kA]L3�2z��ªz��P�z��̖�%�nI'��c��N�5U��n�kDU�̟�g��d�&T�85�i�6��}�v�!��ځ�3�y;�.�g�> ��!�-�l����V%]쿾л�a����Ƈ�$E���3��{$8�����o�L�
��5�ѯ&-�ſ_G�8��%�-L{²y!uԦ�cJ�H��>���8�e+��C�|�:	l��F�e_�o��y�b�;8�Y��e*��W�2�<)h0�犵76��J3n��Z"A�tk����UY�Ñ`�LT�$D�\�#��JU��ҩ�C��/�'�_+���9��7IY@E�jW�3�Z���'�E�V;Y��:h�͓�u�9%Z,q3ϵKe%���͍���,E�҆ �'����*������rK\����w�4)<#h�E ,��_2��eI	�g4�_}����٘I�&F�V��U01�ǅ06fL���0o{G�?>OQBz�a܊ֻ�t�7�Ċ_�4��Po��&mw�E)6��%�O����>t�S_;��ŵO�F�uR�ͽc�?�����)�s� Z<Nþ�7��8���,G@8���溺����r��C������>��l,����ڴ�:�OZ��c͆�P��֭�,evF'Yn��׀���7"�]��M�?H�:�@A�G���o�I�b�CX�.���k�m"����t˗v����^�4��+4�R�zʹ�Tw��K�����Lr��Ģ�>���F�@�CX�ԭ�K�f��ZSjO��,����w��/"�j�\�����'P��H�Ő�|,/}*�����T�[Rz����j�*$���z|�װ�ަ��j+�y[��������V'����~.��g�Q��UoԖ��U.��T�L�R��<�]&���~M'xɼ�����.��(n}�G�#$Dр���+�t><M����'1�NU��k1�:
2�(��<�9�#�婥e%��Iy������Xu8#�ߩ� C�K�?�F��02Ludp_��Q[� (2E15�dr�)h�Ѓ!+�K����YLo�rn��{0 ��m�Ũ��&��_�r�j��/�"0���N9��ѹ�Li�a/f��d
_��̣�@(6v�/�B��Ė������E��e1iwK�b�W��8]��&ă ����ߣY�L8Ҧ��[�n�C�i�������q�8$6�����j{e��>J��Ȅ2k�ϧt�2�R�d��s�`�����rݲ����Ӊ��j�l��e10ܷ�B�/v�X�%����kqL�}�o�?�e?F��f�Px��䁍[\Q]��#�,�A��JD��y��6D�R�}3y��W�3n���E{A�[��
�tæҨ׆n�o��?�76@x ����\�)� �^	E�Y��ۃ��?�	��m�a4�rk3�1��"+{�/�4%@�qh�o���B<�y�x2�t{d;�&@� �
K,����^'��'p�T��'��} X$K���[Pv�{Obz�']��3���xH.�@�P���a�х��ӳ��.x�I���?ñ9��`�9�d�Z*Y�_%i�<�L]��y���Ug��/��wZG��唖�V�v�B�����:30������W��⺻5F�FaH��3��~H�,<�v��1��r���h�]e��)�gJw�vú�S<wZ��&[�3���*�P+�����4'�ʭE�=�P��bMpډ�����6%D�d����l�.t&G]q�a�p�A/7W^��a���@⤬��klj=��
;d h��M&e��7�Չu�1�;����'8Vݺ0�r�5
�30s�W��������J�)Q�{���t����F����RO��O�G�p5�z_��[0�7^Y�*��[���P*m�����%�	]P5K	��_1@A�����w+��u�E��|�_Y8�TnH(�Ø��8PvK��f�?+��Oo�#�1!�g=ٖҬnx��HP6{/�T#0Al�w����-m
��1�k�!��hO�$����c��32�ˌ������=����I����Z|�K���f�f��"���~b~<;[Y�g�d���*9�����,�p�S�I�T�5(I�p�+$�^����S��p��		��zKF�<���)��냋器���Cm�]W2��9j,�{�
����y	L��fᓫ�TgKR�HI�>�u����@�����z�a�����\A�����6�|� |���*,�?Uz�"�+-�?�}JaXA��(m�~U(��.̢q8��g�f���T>Z5��'�TO���'&�[ ��4�����g�?V�QV��C��A�˼�VF#�R�;sy0���[�;qؼ�.1��ߝy~��05��q��7ԣ��<��n�q�)�R�Ѯ]<�Y���N&�������ⶋDu���Hp����1�eOyH��ן<��h��QK_�$֑���y�����n��:"���W��|`J��_�/���la��G13�k,Q.��8vf�ӥ�)���+P�������u�W�V~��=z�m8��ń\v~N�2�����.�_�hJ�a��wuU�Ɇ�B��C�R��Br��dZv��\[҃��X�۾22�l����k`�oKVɏH��zj~��'>�|Jyf�|���Q�O�]MYx��E8R����o$iV�������RF�$�%���iU����N��>"����N��^������!��!�$����2�+>�PF�S$-�6Ջw�K%��JJrH��#��Oi�j�D0	'�*���(���M��̗#��xO+�:��u�+�O��D�I�Y&���WF�P��eHhn�T�|���������x�E��f��>]�H�i��D:�#�=O��7���a��~A0q�E���_3����;[5&��HT
��B�Q�Y�>��2&$1��g$��Q{�`W�j�H.����`b 6��^\�����	�2qA"n��L�غ�zò�����&��ׄ��<$=ʧ�k�O�����+]>y�!,�
#Se$� �Ԕ�HU�h�Z?b�i��4�C����ˠ�$'�v�Q�i ��u��r/c�ƍ��\�e&�(�GT'L���Z�4�=��k�'��Ŭ=An�b���4��	%���(���	��w�}+�M�T��u�������w��{�~�V�_2׋CV��Q}Ճ����O"�ȴ�;^U;�I��;_�ƻ�����=X�$ZN�����Pl :�R;]c�zf�>�t��/;�Y0�O�a΃��Vq)MK!k!^\�ԗ��kr/g�<��д��ݖ+�r���X@�V��o���zu?]��\t,���᡾�ۿv�,���x�#q�|4�rxg�5K��q�����F �qTx�O�l{$~H�������[�24@�\u�^�ۆ��]%v	Ы�����.���4s�|��@����H��a{U�Q k��L�)�'�l^+
QL�����&lgv��w"5�8.�;� ;u�H��`�|���/R����w�j,{h]�T�HX�,0�p��6��}׽�9�7�<��sF�T���_5�[�����+]�l0�"�d�7��D�}��c)� s=2J�g�=-��	/��M��6�x�>�Z�+T��
�w$��?�2	��*=�F�+�(
�>�.��_�� b���h>9R����o��M�ՎB��B��Y�%��dy�����n8{���*+Q�l��Griҥ�XbwY�Y80zG���N�]�tsу�z����$q&;�>1=���XW`��ZHm��X�ؔ�@���ut�o4y̏}�%��
Z�>P-�yֱ��K@��6�I}�F��Z�>a�����	�����`,$���"��å/�｀0qv+}pE�(7*a������jt����&.�E緃��k��yJu�ӆY�v;A~y���e�~W�O�Ru�yKM�t,.��O�^g�J��QX�:C_�R�+Lε��ZyL��h���~o4sz��ӓ��S��R�����h���܌��S[Ď^�;eF�A��������x�xЕ�g$�&0�>m�<A����N-X�VfO'z����X�W_��W��*47F�W
�����c�ܒ�Wm5� �wٸ�Ĳ�M��:W���<�S~$��t�#OXܣxտ���}&����W��� o  w�S�%��������>�����!ǐW��[�#��ٿ�<����7z�oh�X�?�Ã$�*EϨ/#
rR6v��h��y���5d�t��%V�Bh�3�X��.Q(�!fy�K�i��o���(�1��?�c���j�yӛ�%Jr�%�N��5hM��P�����&�^�+EDeJv�L2�a5Z')�|I�]͠s�O��Sj�_�aO�8���;��a�lN���&Dw�Wy��н�������O�I�4���Q�k#���3�c�&�Y��)(^�%H��OX�nֈ|��L�pU|����b��ɑ��!�ܑ���1�OG_&p�g���;�\������@o#�֟�%�����kk�R�2�SӨL_!��Լʾ���1+	���v)Q�������	
�j4�!<����Pt%������2x��]��|�!��^��o���f*���GϘ� �ur1O�rzQ�][c����-5؞͔�J3��H�"FL�(����'��$�ޕ(��
�������|��I����am͒p��;��%�6��5���7�L�9����Ʈ���"�C�uZ�F�@؀���@W�+`���B0���c!^�j-��.㝭-��F��<�ih������a�2��,r�Z�M�Z��OǙfY2m�Y�~�g�l�� �F�k�t<��	"e�be��`D'�2sl-��x$;����!!{�%'��)��BO��PJ,�RPv���	��:�T�!u��|f^{x�S�2ӱn���{g�R���;�<���M���Y*�Azf�^�WyQ���:�-�t�ē%@t��u
��C��c�q��m�
�BV/������ �3 ����\����x�d�
/�6$(�qު��g�U���
P�n�	�%�;�mP�3��״l'*]5�rZ��v_�=g�� ѧu�n�y�lᮭǑ��4�?�@�wP'�X9�j�6�S�~H�B�89�:n-�l�)h&&��i��'��! ��\L�8w��"9��k+s!��=l0����@��.�]H�=c��f����}�98����ʩS�����V���M:I��`ś��R�������n�M�@�U�_�����nve��1�cL�in�$���r>o�O$�x,Oe��!g��~)�e?�ߠ��Z���T������_Zw��S�z�x!����dT9��(FR�O�W�>�2�[,�.��Ǆ���[ܗ�r:���C���^�M��Ja��}^>��v���b�r��R�IO�L帀iZ%LS�K��M_��#��V�n�Ӎ��c���N���9�~����g�bqbn�Cگ���p12��DO?y�2�ǂ�u
/mA�0W���j��n�1!Ei4S !P������G�k�t�_�Tf��<�����͉×�Z(��`�v�9�w>QN� �XS�o�e;�Z����m�Ӏ�[��{e�S��Y���w�c�_Z�4^���=���'QBi��>��U��"f�r����Pl�S����c4�Tj�u�mG|�dޒ���F��t��v<��*~�k��偩\�7Ղ0{��<_�z����f��NS*f�����f�E(���T��eFĲYC�S�&Z�Vk�d#�v�Q�G7��IZ�&��]��3#T����)$lwb[��jڙ�t������	a�plo�v�-2��j�E��|'|W�d�,c,-ĺ
1�(oA&Fb@�>��>!d�R����fuɞ"���T�r6�3��-i�qYO¨0�T|��U$E��R�&��c~�A�xN�Nj�q�u�X�ݾ���3կI_�s�8�F��^�P�Qk����%X���s�CTn�t-9�D�X`�x�KT��x��9�7���:����$�e�rD�C������{h����}�f�4D֒��^���76O����P��_�b���}�43�d�e����O��~��:����ͷ��8�}���Hi�g�y��-�L���F����ë^���$��qhO��G�Df���f֟v��~tHmPpѾ��<�IQ�Y�d��Zb#=M<	C���+Q坼a]��������k�
�o�0�ꝺ$���f�ۊ�/FUn��K�L!����n�D���/R����2˺�~�/u�)F��[�yś��r�ۍ�_�"/�]�
�h�Z��QS�eMo��v	�RQ�x�-AODxX��o���]qGJj��{�K�����(Qb���`���=�r���7�x��4���O�������5{E���IHVD���y����W�޷" ��U|��ZY,�t�G��̒�3ݸ.�<=�c��<BOg����஗�����@A53�GE���J���7�cD���A{���ο�:|�H �`c�O.����&s�E��T^dڔ�)P�����������5�f@$�2>9=�\�Ւbٟ�G���Y������Qe�gs@����l��+���Dq����{&|��X�*��!�_/M������X�1PP����ik��/-"G��Y��اIݶy?Z&mi��h�*!k�_�Q���0��#E#Ћ��3���Q!�}��2�p��^�7E��U�h߹D����A����� ��Z#�u�T�.�Ș����3�Ҋ'��J��F��j�{�����zi|y��Ps���e�,gj~�F��Z��V��%%y��� w|�q�}�VV�
�F�����i��d	Іq��pۧ�J�ޥ��
��P�$o��ҭI\{���%i��WI�`1������H���������ZEK+�Q0|i�5���a���.�p7 ���i�Xw����������'�3.��?tTl���Y��3vzf)�{L��YЦ��GS�����#��v�nj�,EQ���H���Ft���E~Î�<%6��bTu���@YM���"�p8-V 	����׻�r�/���+u�<|q3�#���:8�oZ&ri�����ZV����:���v��ϩ��R�d��n{�7��sG�9�0T	�&z ����g7�A}�H_����x�dM'�[�?3*��}�w�x��7b��[�6]`���Ϊ�B2~��L�O`㝦n�o�h��?T~rl��'�3Ȋ�"�\���2�5�'�r�g���l���h��%p���U���U:L�c)y�YL�H�v��l�}$�l��M�vEФ׎BS|����WV�UM�!H�g5W�ԳP��'Q��\������6��\��ݒ�X�:�{ĜG� �w�.�Ԙ�D�:��9�뷻��g�W��P.�>8�4�
ٮI��ccS�}$[r�Ӱ�&��Iq�Ҏ�G�jcV��#���
�k3p��Ѹ�,>�I4;�fܣ�%�d�l���,��(s��$�����R�PDE��C��Vf������g[�Hͻ�s�j����x+�z���'�(���>�jf��Q�+���&������)dG�����5	��%�Z���Q�f[��3���>��R��x&(%��B��[��$^�a�:! >�*���I�R�H�E�+�	2T2�*=�qЊ7�X2g��Y࠹	 +�Å��L3�����3�K'�z��eN�-��0zU&\�W���M��(�c���v�JZ��+�hɒ�r����|.5���,���䭲�'�=<�O���k1�u+�F��������[E�X�xu�2 ּm�~m3x�s�<+��Rn,\C�t���	���&�_�hK(���v��u.�wT�Phi�1�Q�QMi�W��Z���o:OἷI��Bt�҇�h^�緶�EH�]��[=�5���_p�Q������x�ī�����*�������,��~�ۈS~���1"��u�N�X���u�K>��3T����n�������y7Q7
t|�!C�z0!�3�����v
���YE�[�!��8��۸��f�ޛ��QGE�N�� b���
� 3�5��
2ԅ��t�p��=����)�h��:psS݈ӹJ,��Tq��PD���Pux%�`��6GVEY�Pр&�ihq����#�4�6�c������{Z���&�s��S�'\~_���p#j��	b�cV��RN7 ya�;�};E��~��ec�o�9��Q�<��l��M�jE��1�X�}s'��L���\"<�?r�F��J�EW0����Ƚ��kb�G��"lq4�UQ�/��<�nB=��W>J3�f�l��QJ�E�����ux�t>܇�K� �K:5V5�|0�?�L��/���U�h�aUA=���>*էCI����E�E5��B�&���F��+���ڄ_�^��l*�y4 Ӧ�re�.��[v;a��!�4�ĺ�����v	���=D��@�7�W���a15��,�:;E-�kB1�ڭ�T�[��X֝�-.M!���qk�� ��F��	��ق�"K8�/W�\�����utG9֦�Ԙ=��_&�YP�P��,�9d�j��M�)��U�4�:h�~
O|�)�f��I̲�6σ/����~J`c�j��mt`%?1�	R�����Qh����@L�R�4:����3��/h���(+p.���9���r��=�1�)[(�,Ǆ<p%��J������
<0��4k�����a�b�y� )'��d<-���A_^a/��7�6����2�$g���Pl���n;���>��X����Z�Cͥ��M�?�<Ǎ��P��>%�0�^=4L���[˚�V\
l�1o� �h+��^9� ��Jf��٬�&�.���
'��g�۟�?�����>�e���9���_	��!@��	�����ڤ	�3���6���#�A��՟##;7@���������k�0p��K8�h�����c��������꼙 �@��7��|� �.����VRR.�ڑr0չ�+�f0����묰�A�x~�λeOe��0�t�8�z����+�$�k�>�82s�����s��!9���Z��ͪzW�����b&����e*�o_C�d�t�w{-�
�a9i�^�.%��y ��B�s��S�UF4��~�"�����f�����}vD/�i!٥�6ni����S��= �I�����i��Px�4p$9b�T�^!����Bl�=Q�ca3�/O�؞Jr2�><�qz-+O/z�7Tic%���b��;��'!ⰽ�6 α`��8�n�c�� ��]j�	f3�	��J/�ܿ�^��7�ag=4-�?P��gڟ���l�j����*��������\�,���#Fd���8}��s*��kk�j\@GEW�	U��)8��f�t�����|�Ӱ#�<�Yp *����pۓ=��l�@X�S��h-Fz�Ns����P~XP���@�����&MT 7%��'�!T��3x{u$$����rJ��
's��;�ϡ@��.��������B#a�gǵ�Y;k���8��,T�!�����h	4nA��#?�qL�cE@�[쓧�='Va���k�=�U��eÕ���2����+@��\��] K�\�9*j�� �N�]7"��j�������n� l;@�.c>N�1�5j�ĕ��ċ<@��Vt����Y��_��>�[}���3wݤ�;�@"��
|��k��f����]W+�O��|NߤЅ]���p����g͘�bx�y�io?3<v�ֿG$�B�@ _̎ԣ�d4���Bd.����=�m�!���xYm�8�c.O�ӹ`�Y 5=P�eGh���B!*�1��D�!�f��S��U��,��ֽ?��YJm�b��u0hxCs��bt�U�dB�_�a����$g[�ϔW�������g�xz��S��ڗ���T�`|��e�j݉��yQ|�1�ay#Y�D
 �����,+��iM��kRHe�F��=��l��ms���u1˃P��ܿ�_o�����e쇫�M�����!�q�wA<���8��&�ů@&�_M��?��8��,���K��4?����a+�!`'W~�5�sk���!��/6@ԩ�]O�6g�6�5�b<��L]_I�����Xa��Jd��{S�(��r?U.�}ڏX���(��[�*O?Sv���˯H�����(mŅ �h��9���d� �~e��">&�)}�7m�ߒe���b<]��n;��\�9)Q�-60Z�vGO��+`�D�z��$jU�b���3��B��F�c�>����(x�\݃@����sa}x�͛#��n4.xmÓ;
�	x��(��ч��_��2^���K��AwG4�:�]�?tۏS9���p�p�Ħ��mE�ٹEV�.��C�^6�`�ց9�"��B����q¦˥U��
n�T��k��<xӈ�քэF�)����,ꥤ����	f� �	�AƵ��Dn�����ɲ��iA���z9�[�&��O3c	�~�Y@���_9�3���?�ȗ���?�y,�U��q@J1?~B���M�j���ϣ�#Q�M�U��O<�.%.�R[B3�$�T�tF$�΃�r���1<�*n2�u��Z8�%X@�����]td���'O'9p�����=+5�2"��&�OvJn��KuQ��O�1ڒ����x0�	�a�������,�̅- �Ht�s}�>i�J�4,C�g����d��Y�B	���.S�p�t�9֎�`�r{�
Dr�\�}}�����b7��x��9�}��y1H1�N(��i�xZ�=4��]5��q5e����?�`�4���u�#�t@��t{�gf:���F��v�=����ҙ]O���v��	!���H"e�B���\O�����ɝA,dt����k
gZT *]e
/4w=Ѷ�F�h�zJ�̅�ZK"��V`�C<������]Ë�LȖ`�e��N3��w��aE}DC�*ly�8?2�&�%�`ӽ%#<eTW�t���$:��\B��k�_Gm!#���3z7yd���?3�N���.1������5l�y�,�/��Tjv2q}�
Fy(���퐵��λ�x�0����k?����)	���+0�(`\����:^m�4:g7P�(y�X�I���QШ�bU&�g��!C�{�a7�T���i؏YO5�\p'y��,̥RQbjLHI�PX5�^�y5�[(�@�m�1
������Ǭ�y��K���7�YC�d�1ޑk��H�t�������~.�<L1D��@�̄o1���iΫ��>��SdَEG��m3��ڣ�������p<9���gSb�[M���?����^rU8��XKuK2,�P�:���}`�Mŗr��﫲P����.�ܾ��%�z�l*w')[��/7����i���"�s4"<�b�����zu�lB�6����$�l������j���8���&P]=��E��3�x�qW�r��tM�2 ��	L�ʈ�?�����U�[�D�f��=n=Li�̛�T��=C���t>?����6�ᗂeK����@*�+��{���kl���%���c7>���ܕ����V��LW�����˺	��%��_~q��{�sg|�WM"�ĴL��㟦C���eUe��T+��`��(���O��VS��G�3�K?d�0e��ۢ�	|�B��2�`/M�Ef����7#�}�
�`�s��ѭ>����
f��l�o�@^(������8F�� ���Ƹ1pD�M��3ٔ�˲ ��
$�5y�7'�k�S�6V�h��gɤ�#M6�\[_�,�#�	 �EO��cl��W#���ŕ9�&
���6��X��+9�C藐6��P`�����5-�y��[#��is���k�SĘ*DC���i�FS
�T��LWi6a�V ���o�����ɇ�^�� z��l �H��#��O<��Sǡ4��u�_�����D�T+����EK(o��0"-�ɬ��=CA�9�������Bsi%qT���{���`���w�ȭe�Q͗��Cˍ>��J�l0,H��G�k�M]{����CM"�I���^P�p}O鹾��묿��T�Åf�!��bN�.�1ᅩS�Og2�)�Tv� j8��b�	�d��q2��6A����z����0¿�aS�1��5�p�n���iZ�9��Y����a�j��K���xx�<��&�4����(��NH�n��\z]���ʹl�����ԁB	�nY��S���f�8T�uw�()�v@ȝ�<Rפ����؁�a��3)F��/K�=K�$�,�Y����,'f���2R�X��y�=��G�V�`�|*5�:��f2���pd��?�g��z�����cT�S��|I�LmU<"�=�y(Po����r���:�9���D��?E�!�b7'����� ̘�������`�j$i13��(�H�bsA��k��b����XLh��0�?rMc���K��>ܷ�����T({@�Etaf�Z�/8�bd�ǜ�2/9�$��$R}�NC9��� ��Zw�jA�gz*5IQ&�62
�iC��� �$9?�ʎ�H�qf��H�k<����3��)Td�-m�<��,��?`��4�L��LҠ;+�(�c�嚨�2�}sV0d�3�Ho�i��b�����X�mV5�K�F�����JMG/J/�rI˶�����C�$ Ek[o�A�:��%}��QiC�Jh,��Fi�����sC��QC��X���ȣ$$ܮ�J���l����dc=
�|3�;^�+�$ʼ_��nA�J�R��۩Z�d�b��%�e+��i�,���$VS�n��e���_ک&�:��|�U��������_�:5��@�������[�)0ַWAB20W]��h���'a4��=X��-�"��j�%D&���e�n:�#����3y��s�ؾ�l!���WŠw����5$�2e(��B��L��7F�*Oˎ!ⷪ�:T�OD���d���
�X��y�]�T�s�k\����Y�(����w�!tJ��7Cdm�A�<���g؝�ƻ�m�I	{A������Y��I��LOM�b|/�>x�u�#mܰj.��;�,���Lq%������a��s��V�>g��
�,~�w�~��&2��w��a�Ѵ�����|V-��6a��O�H��(1���WjJ�7ӂ�b�[-����o&+p�Zj6����f�n���Ri�|�w5-,|H�]ʙ��������u9>�� T�b��NL^J�n�v*1�>N5���?���~�L��g|i˘��
{�lBS�D^�]@0��v �k�1[Mcӊx��.<9�1�bh�qWm��+�C[�$�t����I�ג�X�aO�,�RQ}O7ZU��yF���G�\�('G����.Q#O�~&>�>S�$��m/�eѹ�3�]���P�H5��'�͐fi�XH� �����4�|�8B�zZ�Cp���#�a0�s �8�j�}�ʯ:�{7�u��`�Gc )�-�/�E|��������ٲ�	$�x}(��O��<�����a�r�rS��c���pڲ�ظ��h�B�p��Ĺ�fMՠ	�X0���MYby-s���!��|+&��ZE=����y��!z��48zY��th����n�&Y�G�?��9Ƕg�i�XdZ�I��X�E�:Mr8�Y�x
nE+G���}%�D�ʶ�pm �9`v`A?E9�f &ϝ<�����q	6:\'���q`�޿w������K@0j�th� �������'����5Ӓ�c���$Ad_3�ٓ�J�!e�� �i��*�+�Qb�������m?�f$��}~tp�n=�Iy3�80rT�Η>�����^tg��$̑��r���(�Q��U��`-���A�~��\��;�}�s%�Q�A�y���S:��P�'<��'L�������S{���l:!������D�С/�6��,�bxM��j�������嫒������D-��Ks�~+����ru��@��Z1J܃�0�QZKla@���-�o>�?�;�ŨEѐH��
F�!t���l@k^f����A�۝�Y�@��u�`p��B�!	�s��N��~�,U4m���80�ZO3�i-p�����yE�VL� �$���L����Vf����r��c?L�< ��w� θZ�4�,�ߵ��)r�A�v'V��Ň�Vfz0�a�N��zI\� h>F�/��Qh�b�Ta�Q�oJ{5"7�O;#��/ҏ�0a��N����L�eI���[d�Ţ 47���\-Vxu�M"Ll���M��(3"�3(~u\�&]N��D��V�6�hW���)YZ�}*Ѭ^��$���������SC�\�P<[|�ŖϣF#!�1�
��9RDƌĘ�H��ٴ_���
	0W�0�+� ���>��*X��aH�W�-̓�U�P�.<wT$W��l�����=��\+��*fpG.��|eA��eJ�7-ы�_k�~E�K�~���ROf�XR}�|���P	�hu���|�5�I峎��w�！-~�2�������;R�1�F���g��`⿁����@ujX@P8|	r0�ݶ(+h� �1_Ħ�c\O�Oh���C�p�7�� ��$gE�..�Xr �SEj�%S���n�����6�eq|9�a���'���aHh��[b��k�,����b�j�[nh�\�������B%#F!ϝ��s���㴿�r��8s� x����Z|�|���+HR������*xv����2u�oV?"��R�D���ߕ�P��)E��X�z�i�,�$��Gi@]f��{j�d�����>B�
�7G�����C:������OB�Ҭ�c��6�ϸ��Ď5�c�<W٩��7�����Ks�t�8���]���@�r5t�FȮݚ�8p�b�t9@[�J`�m5l5<\o2�LUM���-�t��j+m�3�5_�����wj�Eh0�̱<s^�:6$���1O��e�՛�*F����.*�q�D�T�p�u9Q2�yLykYL�Df�e��#�?�A+�B�i՞hb��[���s��t~< Ns'�B�4O�˕��\���΄)e�q�Dީh�����*ßu[ ����u�%?�}�E�p��K��&{3�Ц6˄����@�H{�lS��'T`���G�D����T��t�_��F�- KO��dp5%��y��;�Ww��ln� a5+�}���9�,����\Nƛ�;R\�`O2�˧�ÿ���UC���h���@�� �8L��S��Qǁ�&���������9=�F���~�����+�U�����:c�эJ��Rn0���߽��$B�Sgr8����]�.�5͝2ҀN��n+��#޴�r�-{��	�u�#8����P�G�N:8|+g��d39�\����N:���R�R�� �S]�`��0͞�f/c�qp��А�tS}e�+cf��s�<���
���ɬ���|0��c�M:;����uJH�3�Xs�3��٭F�HF�-q�Rأ��U���x�)ǥ��j�ƍ,n21�_i���G6K�aXD�(��#o���ب��U��=������#�3��a�v�?`���u�š���?��>�Ň!�17���PL�݂����B�����m�)����غ�M.�*;����!�E�*��IeM�I�f�t?�el�V�,�P���:r�e��������A)��С�ӎ f��k;����a�g9��]�ŏIh 0]3���݈Z�foFA��q��[(��9
���{�`��Hj���"���Gpz���F�m�urOjfT
��<�ҽj��;Y�5��'^��SE�� =���j(�O�E��3�#���_���a�hgT\�E�HB�ؙ��9���+��������ǜk�\<�:H�ȫ�oMӾ+X��t�9�#PP�m�9P��b�s/z�%�j9r=���")�
5�\Of��Z���;��ET�M9�9�39��C��3����[��Ds�pD�0�����;T�'p./dV�SP��~���'i`#f;⌮Ú�����ݲI����gπ	 �\���|1!F��T�����_fk2��j�0oy^�˂`��s�"��A̿Pc�e�s�O�듎�wcذ�=ۚ|���V��o�x���B�ˊ��������ӕ�M=����
Ԍ����=�H�0�`�5��a[)P( ��#f6@��K�ʯpL��Z��ʘ���(�0M�դ�w[�4a ����z2b��P	v��ๆ��`��olF��1q���w���E^����ՓN�v���,id������
��$��ɻ�3,�*Y&���-�=	;��!�9���l�L[��|�B�}��S8)yc������!-Pr�E�S�B�?gӅi�Yd"������n=��Ѻ��1���q@��w��`��7s;p��R��u��i�
�����bm���HR[�nIߪ]6M�=�?���@6S��o�*̝�Җh����aOwS�E��s�!�gPrd�ſ�\Kv�q[4���*�� �NB���GO�S`N����s�a?@��+��hC��\���;����#�1P�$���*���֒"$|h�DNׇ��P�#3=�xݭ���1�"�`׺��I�j��b+��u8�28�^��jnt��qI)�8��v�1 +�[y5���X_��^1�7����}�zH��.Rc!���j�W�IaF�U`��`1�XW�'�ڑ��J�w~�nc�tNr="�\Q-�0�م��r'e_$��C�a�u��Y�[
���G�k��$����q�Rz���9���/�g(y磽��f�Q�0־�D+����ֆ	�ZK ,y�G�H��8n�J\�.K׊c�g`�-��n^d�#{)L�"��˔vzM�p�U",�[��ʧ�v��T����>p�8U���*!�O��l/Q�0Ce���b+����am5i��j�+���^!u�f<)�����eV��m���S8*Y�G�B�-	�����y��Ne�%
ނ#cK�X�4�	�J+z��=l;�QI�v%�
��}]����IW"�N�R$�#����m�{/����%����39��~
���4�`�Oō�T)J}��/{��r��g�G�ܜ����i�80�ݗp�+Jy]
8�;�V�'��;q�x�S�+2s��*h2ѮbQp1�3��8�\����F�h�*�ɛ�Ά��n���u�l�8]��%܌_��d��-3
Zئ����{�P��W�vgXX&����#�4�EG8E.�#�̑V#�u�k��u�<���l�Eȗ�iE��ξ�4���{�����-��ߌ�*S"HM=iP8F���o��e����ȵ�x�J�ϗ�9l�,N	s�1��'�3�'^Ëg�R��F8� �����I���ں�_<�E8CF70��$��_�FN �!SA|�S�����K�W�N�+j���.�M}��5�k�nQ&>k��4�b� ���G�:��!�{�|@����e*Q�9�QÊSP�O�(u�`+�ñ9ֆ�+�����[R,�.CJ�8�YAĝ����_��m[f�!8';E&2���Ly��=�/����ݏ>�^�ٞ���}
w��!�����iz$�����JL�:�\G)fE(̑����������m/�q3���8�/��aD�雓X1ܺx�]3P�X�$�.�f��Ԝ��ݢ<w�f�=����8�"����2zr�Ԟ2O���FmI�s��<k�LaJ��� ���ş���ݚ��*�I3�W��#ڲS��\,��9�}4�Q�Pf��L��o�'�Hs�Ȫ���|X��!֙X���Gd
��=ZG���=p��b'n=��ld(L�>B*��Bg�O���5d�C�K ����f��b{��X3$!������3�q�D���C���P��˞��>-=����Ԧj��`�����k�r�$
��`7^��y�T:6�
���A���q2���6�C~�ށ=����j�_;7jK#���Η��KOR���H� ��������A�{*�Q"+�W<A�P?�����]"8N�Ǹ�UZ�頯V��l�`�ŗ�ʥj��5�t,�1�]����׈���ٲ��3���q�\�t/��ɸ�{�@���y������%{�7J�����>z�E�J<T(��5W�YO�W���v��8Fv= �Ҳ��XN�2Ī$��Vϑ&T��e�$���Bn�*���E�杙Y�$M��er�1�ӨŞ�0���ܩ�Lx�W|$t��h�G{�4.F���Ԗ]-.YQ�WD���gN��z�,�E�q�у����~���#كi<k�ʀ�Ʌ3H��̟�S$Hx�p��g����P1�G������T*��N\��OMs%� �$ӵ|,�h}%�S�Ա�0q�D?�1�|&�1�����bJ�4�u�ӹ�fE�<+ N�2d�����+�zc.Hlջ��v��PP�� �K��]�x&R�Uo���'k�?X�u�BQ�W��[�G�4���
��mq�(�&(�V���u��PA��Y�a���h̴jſ����g�UY������O"�hU�e� ��LU�W���v��Z�$�A}�`�4�p@��\uE��� M����2\4�q�!�Hs�_=�S��V��f���7Ϧo�CF#~=�0D6������6�y��3hx�R��%<�ZGf�#e�����jA�kf���Ϧ?!n;S����7�����d�}*�r�'��F���p��9��hR����2�L�AU�,p�a/5�흐��p�Y0�=m��>Z�S+��.$ljr��� i1�j�q�ؒnv�?�u����kk-��O�|��g�#yB�C�݀��X?͂��FU�z&/���յ
�JU�Z�#�6�)���^,і�=�FZ@�mm���xècI;.���I���/�`N��  _"��FQ(� �����9����g�    YZ