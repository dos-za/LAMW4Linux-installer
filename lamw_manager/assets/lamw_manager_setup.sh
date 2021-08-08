#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1016312941"
MD5="ea9ea567a4d42915494970c72f7855e5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23904"
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
	echo Date of packaging: Sun Aug  8 19:59:33 -03 2021
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
�7zXZ  �ִF !   �X����]] �}��1Dd]����P�t�D�뗟�&����m���s��k}���db��雑��cnp���z�%$p�+�XKx�*��J���/
SZ�|�H��Rl���)�5�ջ6��0��?�� ���J@f�p^q����1r����v��ux��Ӽ	�:�jhsȚ�s9�xf��oq%�n4�������e�ʣ��K��կ�����&#�VR��ɸx��Yd�)A�&�	-=4Yč��/e�wj�K�X��i����PG���E��T�c.�cJ��I�P<@	�_�f7��eH�/���]�!��@��1E����3ܬ��	P����
�n�vrwg��=�s�:�����X�Hv��E��`��tP # ����D��1����6��4	�ө�=��=��
 ;H�\#\R��t���|���J���hS�\Z,{qk|�i\H�y���{�>��TOETg�)A�6�����7�W����f�P� >�"�ͩ#U��D�7��|[��5�]�YVm��K�6��2$�Փ#�i{��>�b��U��xW�:��im5���,�^�nY��/�D��w�|]7:,�Ev�|�u����4¾Գ��m��~��1r�&��Ar�\wf����3�����4W�GI�҆}���� ��]fv��\�j�o�]�����c��,�<j�(S�e�AY�b��L��1{d9Z��3�qt��~`A������ˇ��8o|�,@�7<
�r���TR>��?+3���r��WB~��$� ��!;��#-Ca�2�3��ݟ�,'�}|������Dr߸DI��]��dن�mxw�����1(\��u{~C�1�������X���tu�^�-"IV��0x��y�o�L��S%���F
�����{̻3��F/}�/}W�4��݊4г�?�U���~�ym���S7eZ�+�c��u�����k������BS�8�_G4��Vh�ɴH<FB:!��f��VL�1�D�N������C��� 卶��ڪ������n��trp����w��;�����k�7/��Y��/�Zi�A}2 d�y��/*Qp�iwEۮA�St�,��1'h�*V�K��_.���jPP���X��w���N��6��CҭK��5��Ip�Yp�.�S��=�C~�tCd&�\�7�(�I� L�{�n(*���6�LwC4V���|�iӊE)M�]l^b�2n��7m��*xƴD����.�|N:�aI/�"�$�7�a�
XR^e
eA�lս7~'�Ŝ��MN�V0�&��q��d�Jk{�Ψ�RCOd��z&�$B�O��:������K�՛��n�Xuɚ�%���t��)3cx����o�mj��sW~C8u
�\���;�<���t�W����s̨�� ��v��Cݏ��+M����)�x�A�3a�oiJJ�!��G�7���ƌ���
�f�_[���)@����ē�k[�<��'/N��$R�?�6���xq��Xmn����vg�N$�����.���.7g��� �+f3α%b҄o��vtzwgw�,^D$�ܼ���ӅeV���<Ӝ(fn������D��L<L�
]��I��ޏ3ׄ��e�"�qA/҇�Yg^�k�j��n��x�Rv����Jq?4�S\����K���QϩsTM��G�X�$�"n�2����F2h��{�pw��֟�y��,�B��a>�����2��h�Cf���Կ�iNt�A"c���*�9��h*ԇB��x$v���^v1h�o�~Edq*��V��.�TQU�IG��c{��e���B�耄�%���|�ʨH�6.��������:�S����]ͫ�?�z�6s}��ǙS}[�-�`ݼK�`F>eQ�": Z���O����P���wbL�����J+o2e4,��)w�����#�n� ���,px��р/��%�X��`�2=*���sgY�Ϗ�0�����I*�+(��h�@��Q�i���d�����o����W:��li��n�iH~u�1(�@ t�S�����W��8Hm%S����Dg	&pK�$�x�#5��x��}�,=�`��뗭������1�ĢG��$b8�O�لK.3�&HWQ1�{렐��Q�����b*�:���'�Ñ�]���E��(YS�bNd�:���h[�7�FڜBb���l�^@.-�m۹�ۀA k5 ?BQH&��Q�`ѥ��o�Z;w׬2���.eh�u.���땴���r�����%2d��qb��+3�5^��K��GС ��m��S(�as��O��Y���+�)��ч���0t�98հ�_����"r�U��ֱ�b0=x�4M�G� J$�wl������_
]����x?ڿ�����$v��;����l�(C��7�^:t������^2�	�٪�4B�^�x%A2�f�Q�uS� t��XbӒb��C�g�`���=�7Z���c+�u���?�z\6�J�hG��� ��{�)z/'W������c�y�Α^�9��a.~�I�A�i����e |�ks�:u��s�/Q�n�(6��\��Y�Z�+����Mf�3�8(���#�r��u<����Џ[�\����8���<ز�@�B��� ��;B�>s��ʠ�* ����?w���'�Y?�RR��O��;s��m���*,����v���>	�#���h�M�41;21�4��x�Hb���J�IBSoP���*�@ W���$����b�hm�=/86#�Ѧi�"���� �C���_���"_�f@�Ϳ���,3/��vX����D�ǳB�$:�2�uD� =*:y�x���P���董�7������j�2X��u�c�;*`�Oe^�\���û�M�Ê?�d�?��āS��'��ݰ�9_w95'��V/��f3z�4�.��w`��c��g�����{��p=8q�R����B���[�$����.Ӗ���B���{1�����QN�2Ś�y�/�u4oüI��W���Ҍ��Tb�8���� �jK{8����Y��^U��C�Tn���Z��k$}�`f�>$���T��	[;���7�N��|=>�r����O��3	J���eT8��~e-1��b��5�hn��Y�Y�؁Z'"��:��p6TҘ!�ª��OC��(�ɜ1����_g��K���E��K�" �V���oC��.�����|�,��+����~��I���8���g�ݞ&U�P�"I��e���#�Q$���h�L�e�,'�Ľ��lVx�(\[b9?[K�Z�N�������.f^!Ss������ٗDss��Ǣ���٦&40L�T�9�yӏ/�}��ڮP����7M��d0��.7q�Nl���p�ڻz�Wh3��0dM�x�t�������������.iO9/	�Tu�I�l��`����CI�֣rx��SX�S�L��lq���XS��H�����	���^#�,��<��|�}�l�El�,]
�����.
*��f�V�/`����)6jH(NiE���&����>�Ǭ��u@�f����	����
&p��h�O���@f�E�}�#��K�8��L�h�lD�_�m���Xr�ʳ�.�EMLe�b����U���P����]��舳{�u-��}��xPt�/�m#��v] 0������+nrBC�c��]"~������FEճ�M	+����_�wN�*�cuo�P��R��X\EE#�Z��"�*S<R��oHw}tX���P{�M���'���$tZ�]�o�^z�bv�(?��ҵ��E\��Xu}�5���ue��)Gsɵd�f���|�7�S1n	L>���&����G�鱨_��B�+fM����Go�����hM��o�2p�/e����]d�!H@���z9��?<)��	�O����r�p��%�؈���#��(/55i+Y�^d@�W�{��d�v�x���Һ����3梌(s�fӤ4*`�z���@�6Y4��@=E/�%p����-����U�D�8X޽�o������|Ys����$P:c�V�.��#�`��&�����,J̟=81Tl�|�:RI�1��t�a��̽�Eo8x�u�;z�+�CrB�����紝����O���$8N��-nW� �Ϧ~������n"�����\�.g�tc�` '��iAK��y�:�f��W����g�h9zՈ��(z\�q��z%������r���4}�Y'&&����de4��4� EX�=�ps��,�+�t�m ����47]S7D�jOI@�v���h̨(8�s�R%7���d#�2x^�q���i�V�J�:�0��F�ZN�Gڗ�Tg�7?�1�&M$�_yW.�������zPy�π�rK����	O���~-��aa����S���� !���i�:e�A�D�����'h,#?F�Vt4�J����8�TY��@��ʰ' $w.!����9ub�.�Y�0��&R���G��-Rl�OVNʴ�� �j��|@�z{,lS8�Ĝ#��I�(��	K;�څ��a���u��V�Q7��h[OZ���p	/~*����|Ͳ��,���_�Vck�w̾+R*������^�T%rX���N|E+��q�n�%��&���B�-ƬM�A����Y@�JG���O!�����k�y�6[k��r�SHj5hW��/ɵ1XO����4�9e���a�QFw�	��6񗜇�f^��s�@t]�߶2W~"�y��Y�mYA
p�4��	r� ��G楸.�́��P�r�>bq�V��g���L�.�iK%ǽ2��W�V�[h�h��B�陧[n�&~B^��X::���
	�\C�U.�OsHגL���u�䇞��2�!?�>�Z��1�줻O��?)��"�!���_R;S����]�j8)�ưD8T^ȉ�:��G���W����	���-��JC�Ȩ�G�>R�㒌��mb���,D7�3,��b���lJ������\S��;[_l~]!O*�= '��)��eK�����Ґa���j������x�;������=��q9�>`S�L/J�5���U[G�����g� Z����hQ���9�*ֱ�	[-G�qT2��G>��ر���q�������W���L�����C����z)6���NO�4�&.R%��e�x�����[5���t�0%���Y33���Vv�;x����.��\��N�&To�'�Ҿ�«f�^���93�R�ſw����G%��؏��>������)hm��K���
�����;.1q�p�r�8����Q:����ɽY�k�l׉�v�b���^�����[�+c�>o�Í��z�k�u<��pZe��]�k�U�=Lӌ�<�zPK��B��/N�o=��9�*�I�_Lճ~c�#~�F��F����@cEF���g._N!i��M�^p�~p$>f��/�J�Ww*2.��J�:�=��
�
[l���j��h��e�ĕ�8�2��~��z�g-�i��ةu{����[5X��``Y����7��ef��m�{���stQ���k�2!��Q�uH`����5r:*��9�R�c���	�T�!r(�?����	���d+��5��{λ��K���gX�fk�n���mp�QN^N2�wΚ�/!E<�`CY�j�����bHy����,U ���*����IH�b93)jG�kW%�C���J����n��}����@�ٕʋ�F�S���V@���&�IؙǑ9��L�~,S�	�G$�CI�{3�a:$x���A3��:2sicՑD��[X$�R�,�"Z���G��V�v���L���i�X��|�1�_��D,<̯�� \{�D�*2Լ���m��rPF�e���t�K�� f���@(*#�F�Z�:���޸���<���B�s#NR"�s��D�J�u��N�# j�#�2��$�db�2h��2�"�U��Nj��U�S� ���g�b�|��S?Ȇ�|�=Ӽ�;��o�q����i�M3�;��h@"���PCy�8��;I*�w7��%-����r���� �}�%�&�&��ܱL���xh-�~p��?�lX?���Ρ9���W4.�Z#���)���W�SsN�Ə�d�T���R�p��E-��z�	>�5p�,�,|������	��{i�O�c�Rx^S^��T��]�n� �-3�x�
t�ϯP���#x'!�g���<��*�r�m^<{���
�Sw����#	t;Za 1&����'e`G���kŭ+�f=�1��zv���J4��D���3����c!�2�9%(9�Ld(&�=��7��ҤAXzTqz4ݥH���Y6�f�d®@�<���t������^I��ۡ$j=��z�	�Rc�����e����(���u���u�t�:=����iP�����l���d��Q�K���le�,�dī܀���&|���_oQ��&�W���DS^� �� ki�`��KK�6ߦ��B��vML��XN�
��}*���GOP,�F�`5t=��6N�6<l$��ʢ����͟ux�[{�
����8Ȯ�	;+rm2�3��>�ؚ���W����E<xk9���tQ��&
!4�;z���DF)_=�F�ǼL�J�E5���	��D���&�����`f�2
�{��1�0=x����R�*;G8�`s�`ε/QxI�$>��O��*�01��4sQ�ƹ'���:�_nd�{��Ux�;�}�[Oq�å�;��o�@D��
k���ws¡�B���5���t�򣁛`��W�����?l&��!e,�r����P���%}�\T�"X�c�����]�5}��g[�K��] G#	r<�8O�@FW��I�O�[��懽~�~�ô���e����-]��l-VZ��)ں�;�6�ٝ�F�Xa�#�K�&~яA-/h<4;���H���yʥ#Р���+▅{����m�xl������{�
�p�=i\��u���0�[ݐi�V�,�ٱ��k
}ھ��A[�8�af���y$��2�j���L�64�բ��g砟P �EY���1 �2�$�<Ǐ�}�C3	��F�0�TrW����1�Y=;N�� l4�'��z���&8�����>�Ǉ�Y�{{�$A�a����M>}�c��ݲ��o9�G�C�X���c1d��9�E1�Y�a���i��4������|Z���d4߰����r��jEy�-�f�Jz� �Ha����Z�tqǷ�#rY���o���x�� V�Jj7�o��P˭�	��XP/6@����z,�s�$c�����a9�S��#�'��si��fpen
eI}k���0�7�L��m =Ƿ�)o,�>����ޠݯ�F,N\D.�4�B���a��9�a�	�=9;��B~\�SаY��Q0���`�d���*�'���-�}���i����骀�~>Wи�o�h�]�Ҋ/C��-�J�/{�j�9{�������J�R><zr�ɬH&�����蔗�ћW�b�be�}� X	H����{y@�*�a�P����.��'y�j_\���C#�r��T�x��H��g�/�t?萩��.ۡ�d�W�Ό�"3��R=ҖAYv�t�ߐ��EW�å�U �֏��F-������ӓm�2�yp+�
���&��&}�����>_��^~�wo�����ť�RF�%2wc�jV"������s��iQ��W| լ�)g���kI�Qg@�ܰ��Gmܣr���Q��Ѹ2�`��2���Y�����L,�Ig��A�#�����:C1�Ŋ��z��O��".��3ܳ�V������� ���5ޖ5V1���� �ɒ��ُ�S)l!�u��ёuLÎbQ�^�]&Q(�����EZ�|5 j	���ԳQ&�a���/B��7�;H���m�"D�)����I������9j���K�|y�����ɣ�����L8.��9�E�?���N�V��рy�Ǣ�l�	�^;�'BS��r�2�gIy�I倇��dB�A��V������4�F8Q�.�R�躢4� uĖ��H>U�;��Z��6��b�-�����
�U4g��Cjy���z��OJS�gd {�ϡ�����r.cȨ���c��i4��	��:ٛޝ��`��ӓDy�E�9k�����)���4�m*q�/f��#M�^�@4�?%�F�l�r��^�P@�0zX�;��;���XΆ�ԟ툦�K|Uyi��,�� ��(�uDG�?�a�i.Ѕ�ƈڐ}8������C�V�O&���yu�T���l��FY���x�H��I�h�7�MY��p�>�2�8CZ���Lݚ��_`� ����w.�v��R�3vٮ']�s:̕��P�޳�K�ۉJ�I�%��S2 F���a���0j��>�����;32G������[:���s��T��1�%�p��^!aA�v��s%�E?�l3da��J�$� :�
T��/E&]�%(��dm@�ϬE���h�&�e�fZTy��1��MƝ9��D"E/���]�hB ��!�e��
�D��UAcA���0�n�HK�*p2-��;�@{�����,�^���?��&�@^����
խ
�L���|9W��5o���Xh��+�?�,5�%�;cB�?p��L�]!z!H�b�'��Ӂ������tdR�j?��,�xų�5����D`>nGwb�[l]�<c������47K��?�ȧ?UΉu��,�I���}�m��vX�ƚc�0v
� '����	�}g��%���#|�/�Yl�|�ǲ����z� B�P��x���k�������4k��{}�J���4ڶ��VD�q���C5�:I� 3�L��X�yrZ+#�ZB[>7��l:bIvR�tT_d@�����@J�c�G���wj��:&#�0�����w�G˶�pç���:8�������蹕d2X!�+sy�̦�'s�׷��^dZ��Ddk�$��lk�t8��Q�A.(����<�5(��'ʩB����X���&N��׊g}�&Т1�&����T��;@�cy�kQ�%+�-��������L|�ԕ�	�Y0��J�Iˋ�����iciᵾ4�������SgoUzA �}���fS
���u��E"��&{��Fq�p!��y)��M6?���X��E-�����,�:�u2�h���O��� 
�[�V��帲Ž_u�5lQ�B�U����>҅�RDoG
w�c��B��F��:CNJ�؟ߓ��Xs������J���1Q��y�ߓF� �l�`�{�-�z�z�a�d�'T��|�I� _�W�
�f=9<��&����#uX?jS�M �;��MA�-LӅ��@�{~���H�Ů<A`��K(�I�=�U�C�
��R�?&�/W�
�
�	��\�D��?�*;/���P���u+x``��}�@>�*Âj�/�>p#��C��=��\L�CE�g��2�57V��E������E���Clh���]DO�	���l�x��Jz��Cޔ��G4��|Ub0��ϼ��n|�t��[Ю�;��[���`������cu����	G���Z�4�F���Ԟˋ�T ��E�#��R�J`��"X���CP�a��Fb�V�ҽ���˚�4�S�j�[���TC���;[x@�]�P�%��sBх�ݫ��M�[����>��{�홸/
��"����5v�K���^��S��kr��y��o�������Wz��)���m���@I����$�z�PF�;�f��Z�{�^�:d���~��S�I�g+�1<1�}��p�V��.8$�/K���F[�
����i;�y�q�[�b�+W}���;أN�?wB���(�n5���k�J�%q��x$|��� r2��}��	8�N�*jץ2?��S[��*IQG��+��ػ�{�R�`�"WN��;73e�9گG��!b�Z�¤���=��1����s8�_�d�ʹN9���f"���_�b񑡬.^|ĜReON��P�'e�9��.s�oY�@�"�+��Y�=�S�F���.��H���i�MØn:q0��Q̌+���G8?���)x���Ù�����׆j����O:��b������L�Io�8��,Q/�¢�,D��_�lW�E�$q^(d�鼘�<X�P��8�xq����ɛ;�;�5yQ�s4��Z�:�#2��5�v���hѰ)sZ�1�'[�]�M G|D�5��K8O���L�i�gb�� ��I�����A5� 43�R��"�.A��
�c;S��z�3��Iz>D=�G�o�k��~J����oXg.���٬�Û6C�H�]����p��H�n�	���)0���2�w�๾��w�mH�:p�mb�!{A�����e�U5��x�f���.^q��̺�դ_�H(F[x���_%���T��1�H}�cB��D.�Ve��贮捩�VF�kh�&���~�kq_n���1rC�N�t7�%�sߖ	�e���;{ohgB��5Z������L�A�)A���q��m�U��"��K4�h�%X4��!H��.�8|�*�e�	Zk&�7�]įC�䘧�xp����&W�4��9"�G�"�͊_?�սH�b�L���'���dJ>�?*�F��Dʫ}�]j8������8�z1ױƠ����Kya7���L�g>/|��`k���$���/�2���9E xbi�c5���t�p꧄0��	�����V��#���%v��[�Ѝ$����P�ל�N�5��-T�'倠���7�q�^%]
k���ߩyY ���bG����B���'y 0$Z����l�&�/'jP祈	ϑa��]��P��u��7�KX"Y6H�oH��n*���(���y�mR��MWϛ��*c�<-����w��(��s�G&�>D��#Z<X��
����a�o(E,������T�[�{D��X�10M���yx�ld��v�&����~�oke��Ez�PҌ����u?j�i<6Nm?��}i�w���&�ݝ$��ѫD�vCkSD��þ)U��]A���L�l�O�5ڇ�U�|��<ު�`��'��(m�k@$9κ:{�L/t�����<��s�n��ɟ��.iW�k�����0b��)��x���B\��ե!�/���+��׼�� SD˅˕�Gz�q��TR�{�t�k�9f�9�=���{N�S�i�j��;fD�B�&�c8�.��>Q��m�}�6<�]F��B�+9�����vO��Y�B���>ٷ��U�?(fY95��?��v*s��\ϕ�yqM��?�����=f��u��a �z������u��V�w'���2��,�q�4���jX��&�x�Eܥz�M���b= �z���E�fe�`A�	�y�e�=�-���M�ͺ�(��a���Yd.�(g�2z$I��^O������V=+������]b�� �f�f���Ս��V�BYꄟ�1-�>�%G�q�(4W�g�8�{V�|�B��ǎU���Y��r��A
7�~L� ��B׋e�D�R�$��H>����!��0QOWm�����nΊ�J�ɕ��i5�C��5����9��,�)�O]WV#g�w�b?$���I�m�9�eL��O���n��uq����"�\�/ë+���	9�>J�S�re����6ŀ_�O_���7օ 8�򻧬�h@����
0Ѭ����S�4w��%b]��@�g� J�XF���0�&W�����~�����#�O7ڧz'K,,��to��ReKf�$�R���d�J^�A�62I�v�Z�D�ִѯ���rK~lU��`��0�x�N$:�C���W�x"��Fl�ql6������C:�p��fY���wd�+2.h�e.7�h-,�3Q�=Ѿ�e��)�S�t.�T�S���|0��=z7�*�|s�Ɯ�+����j�fϊ4���G}�¹b4�d�k[k ����u[M�·��)9�L�xx@�xNh�nc�w�Q~�t�6�¡�oO���_�� �ٴ"o|�]�7�ڤ���ܼ���"ַ~b4�8JZ��PA�_��ke�b�弼�A6r�[aQ�n϶��nG����N�
�'�h|dP|���4��I�c���W6e�#���P��� ���n	�&��L��HxĴBד����%*��6��d|T	C�L�p����lJ~R �%��m�N|�$D��Xk=n�z٘z�� 4ASܸ�T��o�A6q��l��~u�q��?~!�<#�c��nM/�N���&�^���g=��^:�l	��ɷO���#�wٚH"q)��u*Wz�{�.1���zz�Bm�����(cL%Tr���,$\�J�^�d���2Sͩݻ�����9n$��5V�y�7�	16B�[��s��� W��f�_/"
�����d�g�����a�����u���EY�q[3Bt�ж���8��̦�h�1B���9�l	
�����B$9�F&i�\1QFN�?]�פ���������C�	O&b71Q)nc�����f�S��f�vc����S��I�?spt���q��4������s�8gu?��w�Y��#= ������ˎ�4*'GD:���z��(�2B%��
y�H�����r'-��Gz�iq�����V�J�袱:�aC���P�ߡc������z�E�3����}O�DW��j	4��'?A�SjXx���X>y,�r��s��P/3�����
Pfv:���?v-2EY7�:K?j$�����Ab��V��n��/���0d� ��W~?����|���Y��/��pM̼���d�ߎ;��ei5y��/�ߞO��a�ZP���T�V|��z,7����q���D�q�c�'iI�����I����Om�6�.aЎG��}�Hu�a�0����p�@�=�C�
�19�7XTP�Fk����\�g�?Z)�vvt�ns �q-�ހ}�JSx&_I������V�x��i�N�T�Q�������R� VV��eϴH�u�����%�F�WH����GD³�Z�v��	<ョ�]@�ɣX�#��Q$/y��YW��tZ^O�c�^(����������{ƕ�')+�⭆�7����8'�Ux�m��We�ɡd(#��Q�&�qr=��e>���)ʮ��7^�^Q灈C�9H�H�w�{�-���xL��D�y��"c�ݱ�/!ɶL:.D���a.Ic�\c�(ɚ�s)j��9Lo4�x�� Y��~��K�S�Z��Z�.��z�ߡ)��Ӳi$�;9�%
��ct�PPI�L��Å�}%]WF��r��W��WGﻥ]O�J����	IB佢�:�#���	f��m��3D�FbX��@��8�,ֳބ
���Jx��q�ڥȏ��ɻ!���`}B��ࣜu��3 ���=��čj��:y�����2T�SS�5����I�~V���Tlz� ��,�H�^+^T�|�nN���j�6k#]�������ls�p��o��	ZQqǽrl�>�_���P*��m���#GJ,��]�>�3C�3��6���!y��\���HS�V=�ih�J4�MP ��s;{?۔Y��2����x�!�Ũy�9e�T�$E�*nR��x<_���+�>���:��*����-��5UX��E�i۵��W��\ �+z�Q|�`?j;��a6Ѡ�T$�[:~B^P��>ct#%�e���l�e��a1�8�LAF=��DP��eq4�n&��+Q��f���Q7�� ���`����~���mz89d�dI+=���f#�3e���Q��Q�YV%q�b̢����tM��|�\��!��NU���@�����3�+_���ŀ�x9�|�;�xgE��|�Ib�ic�c��(w��_��k9y��7����Kt�ɟ	�(N3�/�%�"fE� �<j�� �����v+�	Zs��߃���&p�I@���px���6�@
dK�k�b��:or���U���F�C�O��,��1a���y�����D��ɕAUK���Ǒ�3��_QON��s�����`y����(m;GfC�������>����2���#���ߢ��ȉ�Z��]|h�3E����riDCp֪���{d�B�U�Ө{<	��>6.|0�)3I�����U���=~ؑ�"_v�v�4+��������y��O���~O'*����Vz�}�z17/X^���M��^�����CU�����b'ҫnwq}��ZY�����v�j�]Θ0x�<��Ik�wha,�b���J���#$U�������RƉ�a���C�y�f��������[�@�ԇ�2E�@��)v��NT�i��oye
IZ��nk� �<$y~��W�?{�y��� y��yM��;�A1�ɿU*����Ųx�l�4�N��������%϶��\F0�'�W��P��627Ӻ��s�R\X��:A엣$���ʻ�:�(�eUJ�d�Ғ��G5���s������/y���moCT�L��y ��2�D/�;m����K:HB� 1����u�Y�4��
WC�T�	��03�X��f�#LzE�q�I�]��2׹��S/�������k�=Yo}�ç��<E�:�D�E�y�_����M[<8����%u�ǥ��n��%S�	,���|ڳK� J�K��APaz�h��݅�z��6�E;~���c��N5�l�~��Y�9h`J���9#豎�UЫ��"��R8�g�w*W��C�������Q�5��{�V�ĚFJIQ�е ��YI��9Zy��#�V	��|k^ƼL����h�ƞ�i.�9���heC�+��O!Ѝ���oU�����6�ꋬ箂�ɭGii��F�pTx�����Qt�7����@� 4cc'�g�d�n_�hb �9,�fN�pMxz�5�f��n�y�Ÿb�����(�[�xw����0H(����3(����\�$���D鉐+��\[g2���B��3Q���-.%G'���]��mi<A�5��P�&�y���f�)���N�1�t��S��l���x�5��d��
Z>J��*2�9bM��#� ��pz�>r�Г���#^�Lm(��z�RqF��L�5au]G�/��j�\�`�da����
3V��n�R�J��W�s��!��at7�I+N����)��1���qj��M��=m0���C8����u�i_g'@�tg���d�VG��c�g�-�?�il��:�k���J�?�e�����x9����k�QnY;�����V,���q���XW,���{��6t���'�?��=~v�l4#g�"�Wq̼:�0��g�|?�u�Y\������=s��<��I�x��/��'��i��I����_�{�j�(�����ޗ�M�!>��ĵ@�N��B+��Li�t��n���Zt��=8`�D�유qML��]�TB@�{�ec|�˄���P͟�؅pw�����}a�r�O�&�`c4����,���E������;�=�|����7�:1�>��nHho	�q.V�����*�D�૖��?��|���ZH�O�}�)��wTy�����O��pE�%�-ۻX0�����h�9yI�����8���O�@�,�tQ�����.������p;�\�֐�Ck:���t��+ K�z��O*��$i,X��/�pg�B�Q��a�٤\i�%h4�[4����t�g:�/�=[ 	���_������}�]4	��<Jj(zǹЅ58B�Q�i���6hq�C��\f�SFIW���"�G@�S��	�}����)r��yw���q�r�mHE[d��%'�{�j�*;5��-6�;�T��(�ԻbXP����Ó����6(F46�[m�[���I،#?#�8Y�4"���C\e�y�ts�1qw7�S&y��5�8�[R8��Z�i�?������;�,����$���%��dm�T�d�&��/7v)(`�Cdm�?�y����瞾:q,�^���$�3,�s�XFpV��5��I��ܶg]u�)����_��*dX �>��ͻ�w�"?z�){M�[p�r�6�w��^���Ĉ�R�D��O�nӆ�9��?x��H�o�D�I�@�Q��M1]�P_�W7��;4ɝ���A�}X�7��\J�H��;�(�c���k����3>��C�ޱ{�{i"nL�L�%��V�1X�u|-C�bHn�]�رY7���%��G������W�=\MC�Y���;~`�?�8�O����J�M�t܆���`]��J��{�57=&m�����柝�hʮ����7�z[b5e���<��#dX�x�|�QE�%R���~#�|F�ZQ\��)%i9x�"�{e�����cW�_q�7�B5�7Ɵ�A16۱d�B�
����4i�fbu�I_�c'�����f׭�� �{sO�n������|�vZ�mߵ�T�I:�6��iT��(�J�na:�d�Rޣ��4*�oB����#ܮ+�`Z�R'��f/&lI�M}pxt;V�*�&@�b�-쉫�Wɞ;t������ Ϸ4�����xX���0�*
2��'��2��Q�@4��N�A�������Nq��E�3�QL6d�w��<P�4�A�U`�u�[x�吷/W�
5���z���V-�0{��Ի笡p6���FVp6�`}��pZZ���c,����	�������v�>�_2�W~�K���?(>��>+�U���0�`z��6]E#�F7�͟ss��@�!��}����[�À�T���g�����GR��1ٺ��w���':�u3~��[?]ە'T�6B���)���I����s�鰸�d@�aū�Q9�[6���S����@�vK��qvM]S{��v��]��>�\J��t�����1"q�'F��r�fzw8�x_|�=��XRm��E�%�� �~���@C��A�+�a��~xx ���Ply���j&�Z�W���3�^4F����6�-"6���F&H�U;Y9��'�9ѻ��acXI8[��7nޏ?ғJ��nV0]Q�qY������NOmPb;� �$���g�@ [���x��(9�O� 1��(PJ�4n���(6Do�$I����I��������*m�`����Ӻ�Ĩ<ǃ@�-�����E��
���@���y6:sF�I��t<�Cu'��C��c�T\O��e��?,�����9%�W�E�A9H_|�N@����iw�������V�s���O��9��p�|_�P3-��:�&���#�3w���m3ɞCA,�J]h�|���裱��7%g���
�!�p,������䷯����$�F���ќZz�>[5ԟ�3��$���J�
����ό�˪� 9'���`*��)��/��K��@�E2gd�C�}"�Kx?^2�u�^�-��4�{�KrN懩6����o�����s��k�q�e��E!k��k!>�nK\,ɷ|I/�%!t=z�F��p^M�Yª&�`���`u���T������A�-{|Ќ Sb@>h=,7�f���g?��@y�P�z���6�þ�%�NF�Tǈ��t��)�٪}�X����:1�u ��EW�8I���RA��6a�~�	���*�h"׬���P∖4E��������-"�L������kͯ�"�QN�D�;w��Ww�l���@�H�|���v/�S����/�NK�-�o�O�醏������@�imVAN/u҈f���h�&�%'c�҂���o�f� �*�� n�S2��0�d�y�9�h�?͝�d\����c!c���3n��iY��.��ӨI�w&���S?�D8���bS��߆����z�!}�^�?���<���GR�b��Z�4�-��6"LFT�Q�\#�Ω��:��lWt��C���f$;ǝ�;5�xzLϕ�i;4JI(��}�L��F�hy@$*��"���;����l�kB�=^��{�t�y���/�U���W�-��$�J���s-��13k��Tj �Z\t ���$����'9>����ґ���PGD�73��Y��	 br��7�����K�`�����dq�1��}�E�H���vķ�!�@�^�R���*��HR��GL�u�1<=~4
]ItReQt����.��oB��P!��*q�	�B5�3�C�aL&ݔ����x�&G��v����)Vå�%O+=��@O`έJSb��~���vF� �x+�����R�dXT���"`�c-���+Z���=��?��X�^�#����پ�1���<ɘ�{�!p��;X�(�iE�Ⱦ*X^�s͑T�bw�b*����J,b$����J��X��{� ��|�����G{���j%"W�������@���Ͱ�x��4�=��+:�P�4��Q�2���*��ԇ-��b'����5~	W�ڕ�<d�J�G�EJ�d�ي���,Fsꡖ�k���p��eTt)��έ1�76J�/6�(��ˮ�&C�T�6�	:q�|���roJ�K2c�miu*r��c�T�f����Ii�x*m�����X�� ��M��@�M�5�n��Ͷ�f�Tva��9�����n��x�֗6t]"]����yP�ƚ,�\_F�P���j�#�V@�r>�R�KCZ˺���m����?:RtP.�}=�Ȱ��'mG�@�T�4�{��~���3q8�[t��5D)Ⲁ.�}B})(n��.��Lܶ� ��*��]���!3��2���Q�v{;�7�m@9=�Ov\4X��F�ܛ����CmjB�ݪ"kH(��6�r�1�aF��_�79tDKw����0r��m��L���D���v6	> � ��������	d:�9�ꀜ8�vs���T��,D�
��,��yC�fZ19��C��yo�4ِue_�E0t�2��� �5UR���l��؜l��3-�n9��f���EYVf��g��"��6��~�"r�0R��[��.��d��FC�ԑDK���+�;�n�@Ů��kO,��u� ø�����'p�0�O��B4s!C�˥��b�	�L�"I���q�����?����q�q�A��衎�lyT�L	7W����?��8��'�H������;T64������N�
��9!�?7\�@��+n����J-�1}���e�C�>~������[ݍ%ݗ���$K�!H6ù�����W6�)���a������e���?�a��>-��b�t#_�/OcI�,u��>3�����_��S)W܍ܣ;�>^�Po��&�{�w ��.
��{W"Gy�W�![C+i��_.!3��������&C
�N������6�r^Q�#�j�޿n��S�.%�E��{^���&χ'�h�w��:󞲑 ~�j���2$;��ɋ'�E���.�c�Nl&�.z� %�:��m����/1��Uf�^�z���������I�)\��������Ͳ~�E,5�� G+/����ˌ�&�:H�~\xK�SkPJ����У�|2�QH1U��4�����k(M3\������xڜ!vL�v�]ȸ��������,b>��NDg�.|�3I��T���߃�	�� ���m�����qrSĕ/\:��E�	���:2�Z��%i�?w��k]��>��MŘ�8�w��\�~G�Ax���]!��'~\��<���m�����+�VJk}s0!A�]���rX"�����ѿ�6j�Aϼ[�<?[�n�)��/a���˧�`~�K�[�Q&+(�n�NEE�TO��8{l�?B�M�r$��Aun�$�>*��v4����-�2(-�sY$��Δy(=�&������u�rÎӑD�+H���f�27�O��F$>E�(���Z��Ԗ.=�ZDZ��yC��q�gk	A/{��>�m���@�+B���O�J!=ɱ�n�'ڐ��,A�^\Ӷ�?|��UX,p;~	�K @Q�	��oK!v|Hg$�IlI�x�q�Z�9��B>G�U�uX��Gٹ�����?m�HZu���:]k����a����l�p��Q��C	G�'�];��x<�b��2�u+z5~��·���z�:Y�~��*��4M�V��T$cq	�df�N��J��e�yϙE�ܗ�y�_c@�uQ�5a�by�	�qkJ�����Q�m��4�U!eT�U[��:��Ŵ����cO�ћ��0�������B'�J9�zb��>~��-�)�+ʲ!(b��!�Y\����9�r�mq_��T~h��-ht�M�^r}��)d�.t��Mv��g�bB�|�˅`���/�c�6�.�L�n�ʱ�j�k�^UL��1��������hE���3�L���W+���Q?��p�km!�*D�����ޝ�fD�/4�}.<H���E��<�aR�q�NQמ�0̳���w^���}6��k�e�����3��󲶂Nn��w�ɣ݁���f�>Xv��#���'��~�ls��H�_8"@���Mz����s����!���1x��X(�0Qҏ�����k��4=l[+�P �Q�\���C�]8�{�b �b�cc��i��9ة�b��Z*P::q���[g���GSW+����������T�?�c�P��rB�-J=�e���d���}����(��|t2B�y�����1C�kL� ��Q#��و5��_Qi3/} d9��I�^�q�P��K��|O�c�|-�:M����FYj���~&����S���h�+FF�gՍ2��s��5�oE��^�M�� +��-Iݨ���3�+��Oq�`�����/V����k&����ߎ��sJ������u�?I(3�N��J�����/�T ~�|�Z��K&o9��kZ]�W�}��M�^�����������"~�I����:��1_��D�j6� ��Ƞ6��:�ͱuNQ�r�dtq��p.��t$���&0�XU�6:�
$c��z{j�@Tj��.�K�L���^�n�v��L8�E"�A"d�� w�8�NА�M�!�j�_g��T�2�e��]� ��	���x4-0K`�����UH�E�6|���KG?�핑�C�ռ���]��,L�W��,�ȪA7 ��i"u@^v��3���d��M��������jLR��tU �j�֍��[n��J��L߈Bu�����f���^�O��~>*kFF�Β{,>��9�8��3�V��!��:�ܿ�}6��?ʭ�K�K�]`����/f��P3�e ��s��K��B}O��E �/�vm��Y��	gt�t�I�����YW�:��'��f�I/Y��ԑ�歕�m>�Q��ր�
7��BBѽ���������ne�ki2��8E��h|���vtCi���~�Ѳ�Vi�9ğ�aQTt�>�����S�P�y�8	��r�7���N���N$��
�է�fP	��h�ֆ;��Yx�G�-g]%5��m�p�y��)SCh�����y��T�	��X�F�]�%H�Vh�	�� ���n���� �4Q�pz�ҫ�Iq�)P�A���l+�8xC�𱂼X��F���� x�t��o�x�<�G����c�u:�v'!)W߶xhO3-�2�� �	8��ˀiKy^m����Ɔ:�*]�a@l�_508��ED*�\Gg8Gt�w�;����i�Dv�Fq2��A�Ϣށ�'�4����*' �]6]l����J�\֑D{�����D�R6V�����V`����JZ�|	.R��P|M�
�'�JQ6�utO�{�A�/.Ȍ���)9���28�ňU�w�~�0�<�/x��4���̓�p%�[���S����bn��W�����q1�n�ab
�܃e��X�p�,[g5���9�@Y�	y���MA
I�}v��<H�$uB/�DI�sB��S1�6?��7E��Z��o�}�/@P�79%�{l%���V�m:����.�U���3y,h���@�����'�G��J˩hۂ����#Xg^-#�uzsf�Ȭ�+��Q�eX��D��J�v��V�n"tb��$
L$���ִK�#�$�RlzKS�h���0�λ#m��7��%lh,Z�!ij��s�r�g*���[^��iA1%��W����<)���3��� �kXc�i��,��/��˦��ʛ�(���p̛�l�čr�ֲ@�Kj����]G��1'��3�^Zn�h�����ãp�MY�g؜\	ˍN�D�}�aV�f0�<	꛻�M�Q��U����j�<�0�m���c߭�[J�6c�P��ƕ�ں����"��>��I��T�sl�����^�o7�����������6� �uq�3�l:{Y���Q/�٥���(�֝���.�Ԁ$TAqg�Wh���9�"����=F:� g��ù:�b��eC�����^}U��MT|!c������s����!-�-]u�:6��
	,��L&F��q6���b)��Ed�E���gu U��,�������'�E!n襐wF-,���K_�2;�2Q�~�rw�.��䘋���d-��h���s��	�3
N��R���ߔ\[cr�4��r�Vƛ����f�/�J
5}$����d2��va<����A��3CYL ��ݤ���(��_0��K�P6�`g�o3�3�?M�.��+$�o�3E���Q-���P:��N�|�EQ\��jKX����O�~�DW!�%�e�C\MTX�@
�@�b�G�/ L�p*<ا�!�K�dd�I��1@�rѐ�<B�o��(��rD�T�އ͓
kv������it�D�A�m����Um��_��AZu[b�74��/:�/���?���CI�$�s�϶��ULs�F{W`�@C�t�C�PzWL�`st��,Gt����~�`Zw��W�k�<��M�G�o~�M��+\�����y�%�������7�J٧pX� �y7	N�fm-�x_1bA��N�N����sSD�k$1HBě�)�R%]��|Y蹋�u�)0�L8�@ɱ~�.���c�B��A�8o��w�1��d͛O)��R皒�:^i���v�����3q��W>�L���p�}����܀�	�� �������1��~"����} ?���}�u��[_ڋjր��W*3�|�/���C:	�����-�oE��&��BZ*]݇3��k���]m�z@����6DZz�ڞ�ɢ9�0�m�z43;4Yj����co�sc�����k|SU������>�	
�9�)�zl���h�
_b{��Vv�F�ɋ�Eb��K��*�P�^��x/�piۻ��UrIP���I��I1O�@�"�FD� f�G9��0 s�\۾�g����l�8�����Q��l������ؓV�0��g04=fyG��)G�	�-wM�( �KB��<{��^s�m��V�c�r�G�-}��e`�͊�VN   7�ר�6" �����8��g�    YZ