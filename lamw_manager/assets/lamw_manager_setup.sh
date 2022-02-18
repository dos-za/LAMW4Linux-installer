#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="16269480"
MD5="0ddf2e38487077c123b6c0fe1230e802"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26644"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Fri Feb 18 19:24:58 -03 2022
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
�7zXZ  �ִF !   �X���g�] �}��1Dd]����P�t�D���0�$ug��(l@���B�,�`{�$Čc����Q9�s���+���Ƕ
tȠ�i�_�cӛz�-�oo��*�Z &b�e���_�OK��O�<����
'<;T�u�'���/`�6�ca~1!eZ,V�,�4����yEZ�<F���08�0���9T
�x���L�!v�R��%��z]�ܑd��#���,�{�;�55 ��N8�Y*��G�c=��HKL��O2�W�3��0G ѡb�
�<�Q��M�2 ���=I�\h�������'�pm��w�ĲK\��X�eC�D��/��3�=��_�6�����ȮRu$�bچ�W�F�����5�"a���l*)����~���(�@\52y�Ξ�s�J���G�=��=%LU���I�0(,SR�
Z"�l�q�����R�E����Wmļ3�k���}��}&9�Q��v��g �K]�����~�d/�]�:���ߣXi��Nm�u�=q�.q� 3/� 7hէ���־ 1�����XsK�ma1�35�I�kHZ9�NqP�C0P�!f4�[z��80~N�b���`(/C��q��j&�&Vzeip��]G~�s�R3A2��j��Tj?��ؔ	{�~���\���X<��^��;[����%Ѻ��X(X���L�pG�tE��7��ޞ�ӯI���2�0{�>���h��W;b���t������k�G3����E���Y���I��D3WY*s�C�I*���a��$�
C��z֗#�]M7K���j��n���l뭕�}�:�,L¸\ܺ,��f�EI%�4L���_�,�X�fچ�^U��*��Y���yNX�+
����IA���Н�g�d�Q� �km�N�����]��&���R7��T��<��RTp'��͓<"Tߋ�кh2z�h� ���8"��>#��	=j���� ^s�xȱHw��6d��*���oM��CDG(�1�YB�[Qc��;�6�t�O�ѓ�H�r�.eaf�����u�?x;B��xNwU=���n2۔�����W{h�b(�	S������-�,*\C��NA��tXA��'dS*�n�V<4�8dȜ��Ys�R)�U��Z�?������B�t+��nw��$G�~e�Znk�\s{(�����wr���h�Kc�+qg������!mv'��m�Ka��WTS@@�)*<�HҪ��^w[u�(�H�d7�~�ѱmz\�G(P�P(:��Z�?�| |	�&�hU2E��f��	��04c���&#�Գ����]�mW2�|ˊ���r�A��8����~LPOs�
B��$'R�w���Kx^pd{�*�(f�Tf���������Gԅ��T<F	�Ӝb��n��e���@(��=-x�v��Ee�3g8b� E��y-7���hT�Z����8�xMm`8��; ����g���~�A����  ��(�����GS%�xT-:406�v�ѵ_��L��`'#e�)!��B�����ϻPggp
`�#�;�`T����O��g x]�?�ʂ�3��	!��rw�ҳ-o�V(J�`k6�rT�����<a;�@ͩ=�JQ@y���͉�P�W8�����{�;�Ďh̔[�����{
�Z�`;���X��ri�1�ܕ?�3=���f]5�n� +�����w��hJ�(��QhI�.o�$|%jb�jF����BB�V���ʸ�0��Dt�p�0>�U`7�f��r�:dq\q>���P���؆�]��S�u�)��
9u��G5X��FG!�p�{H���H�D����(����Kk����h���O�o,����8U@5�� o��t�ђ����r>+i�R����-��"P�;�~;�.�'^(|�jj0�"1XBѴ��Z^���)v����q%�=�r���(-�W=�����S($�u�-�"F9�cζ��cg��﬘������y����*.�K�1(������eJ��� ¯Wvс��(D�7��hW�qV�T�Uy$��	�Je[��z��2�!=����t�rr���������1EY�U�H�`pN�~w
X=^!�J�t�A�*R-!}j�g������m�$b�)YCw	��\�{���Ϝ�J�YiM��:<���-�X�O���E�[Aj�TyB�P��V�M�����T�ly�*�xe����b�p�(у����k�4�宨0B;mi�U���$��S�j<�ڽ�MJ�Y���nTё�vJ��2+0�}6��4]�g�L\3M�x^�iJ����ȅ��U�I��ciR�����1�zK�}?�q~�]&�)����d款:Ƴ� ���uX��M/#�~p���CI�֦����8l�=p�r�VD:>P�7�?��`[#�����,�tiF���#I�H4�u�����JGk'(�}ӟ�<
lk�.]���=A9{�uh�<p��p�ӛ��Ny$(��g�񌱸�;��B�pStԷS�I9�u��3VӪ��D˺e��9�:���lۦ����_�B�Qp�^�_Vof��a�8:r ���u1wiJ�fv����@�V�Fg�Vj�<��I@���(?0��ي�7%̘�xA�Q�$�C�!�'�3T} Ss����E��+�UɅ�>��n|��P��HDsV��*`�yz����33k�z���t�{�ao������^"��?\+�_F��l��V8��`�]�<\\�)��V�J/���V�f��46i�ֈFu��fK$�	�^�b?_� ���h��q�`yot��"�%�@̒a��J+2f�ݮ_��N �h���yޯDrߺ�Ӫh�sK ���Z�������0}a�5�{g��pGy���Pf�?֣p�& }�IX�,��Y_�l�:����w�>����Ehg�����YJvXk<t��|��\��'�T��u�2,e�=h������f@Z�_ô�]�M,���IQ��l�E��u����u}�*o"�£S�Lͣd�Y^Zr$�)XF���k�e��2D���m��-���ښ��'J�����3>���[�q�i���M^;{//&Rr��,�$��{�ջ5��HW.I���.�����_�g�_���[��!�kc�]�B��7���_R�y���~�Փ��h�S�)���m6�x��4s�$����(�-�ɖ��R��'��Ņ%�W���r^ޢ�!,���XZ�  ��ہ3��� [��*��&HB3_�j`I6*�?���'u�%�i�:Q��]=(�� ?#v�eb����7dgzU�V��	�z�wJ��¢�n~SS�4����G�Q�U�
���R	�77c/,Z��X>��7�`�@s��fҘ�'[Q��S �z~�W��#����A��mv��;����q2��ȄŮ�����=|R(��ؓkW_��H�g�1��Ұ(}fu�z���'*�]&j�Z�L�%'�}hG�/���e{�G�V�3۩uEZ�W�K��}��	DA�\V� ���Z��J%d����O	z�U8�y'>�y«�VV�,�R���3a�`�2$9%�a�b�D�=�6l��k�Xџk�:_X߻��jo�(�`���Wa�cY��Q�׬�\@��=��{z�� I�S댻�d��L!�����=*Y�g~۱jX��G�Vb:}�a�!��b>j1a<_jW��v+u�Z�-P�HA�j��.8_T}��(�we)@��8�����ͺ!����B[s(�4l5��t�CD��.�nb���a>�$�%��m�mQ�M�����Kˮ�OAkA��։F�Ԣ�Z�Q==`��w�G�x�l�e�B��/�ʲ�E��e'�r��}�O���"������j�o؇a�����aS���pO���#M&�рy�:M%�a��}g.
�6ٞւagċ��o�Z�AOy�p�ڝ$�Z�Jtc��M��~w|��̧]'J���}tQ�`��\��mA�� v/���.|^�����;.w�S�Mnw�Z5 _�*+��D~��iNL)�y"R�H"HVM���.<�+�2�bV��(D}�������R�u�1��������?���a\�]3�l��G�6��72�W���M��=^va<��\7�B�xYk�{@�̫�M����p&�Xۀ��ӎ��T��(3�d���ٔ��eZK�~������R������8����GI��R^�����7@�ii��5����c���}Ӓ�c�DϬe�{\����j�O���a�0:���?��|�(���U�0� ��
�U�~$��\?H���o<%���J����ht�������I9�*&�K	]pl�$��,׫�q�MÌ[�	,�o7�$�E
0_��
���z�Φ�5>� ���_��s`V��cC_��)4�,8�^�=R�弍���XX���|�`�2�S�t�G�IK��#��{=0�,�+�������ŽR`�7^ ,�
.�G|yd��)PET�	?�{>q�R��6�d��1~	��f�����ۛI�nRՅ����e��[�Y7�˯�|^�eeE���Q�4 $��� ��s3\�ᛆr���	���$�w���S�3�R�.�]��b�3��P)����6�0Q�,�t��i��r��/,�/��0���\(�	�$=��<�����=Y?���2�b������x�����L�?Z��C��C�ٸb��l�6_��|-Z�j�àt��=�Z劵���ș��$��=�;?�[��N�_� ��ರ���G�5�DR�:^��5��|R��'O�Kgֵ� �PZί�YV��|���s^%������[c������F9� y/�Ӻ��;C��/�9�gE�)�mj���kaK�'�zQ�y�|#I+�H7�a�?��T5�.��fB�i�����*�	������g�(��/��׷�켐���gw������17��g�)iLB �;Ö=�U."J؃��@pv{��Ci�g��Z=<�
��打�كd��j*��(����OV�����.�TR�/K�-(6-;n���癹�fj	�݊'Mob�Ö1?�-<粰ϞU��Ε[�{�.�o1����K%<L�4��u�\��y�Ee}�)��1�M��`�&��$g�,��
�����Y�;�* ����+�]"�f0�-6�Tx�y[p��L��`����O6Z�a�nC�cQn�C�&��,��=E�:��?��u��2Ӄs�k�� *���f�d�N� B���J���)M؀6���d�
ln�j�g^�o$6l��?������y����(�W3����>P{Ŝz�yR\ML	�.�R�X)�tI�#Q]�m�({g��z{�'��.(�u�:�H�&�!��9�h����6�[
�/Ǹ���:td���C���ya�l)M�CZ���
.�&��t��c���+�9�ot�S����!Q��v%D��P�ު��3�̈��_� "A%{�����J�_V5N)e���P)��R֤΀t�Cj|�����|�-�J2�}r�"��q�d������	��
����/��5G3�h�}�<���&���ηf�b�3��/���::�;��*_���g:t��g~�~R�;a-X��Y~���X �Wc+G���wxP�дF��"o�(M�K^�9�|Iׯ���wֿv���q�Ƣy/����ߴ�8����xG�raw����i�Y_Y�'�~aԹ�)�TUjη3�Ma�'}]����i4	��B!'�;�ם��+�/�&b�'a�֠,�#����2��f2��S�Τ�qX`x���Uc�L��Aq�|�CC��P�Z�~!`��
xo���Z#ރ��/��q��s����^�",�	�S|pV��Zf�x-D`E��~����[L3���;��7���o�spV�k2Q_W4z�Я��S��LT��8v�GJe�@T���虜��ʪ��R�t��o��"�'2� ��Ap^�KW$d�ᬇ}�;U��"��E;f@aq�t�{1z� ���K	��*I���V��](/�Xx�%mR��;�}���ƶ�	�g8ƲC��v^��h�bI�T�BP'P�M�lѥ��������^�]�W�o���|��2͏���~)��n��D���h�J��kH��ϖg���M�s	��D:V�?٤���g�1�nm�A�Ѳvg H����g�.u�6>L������Z�0a D�x��[׊)B�~q�R��\`O�)~˲�y7Npe�?���=An���!�ՙ�wr�a����*#��_2O�X��k~�Y�W�ո�]CA����\k�������j�|;H���2"9)O�&T�{��p�ӊ"���L�c�j�\�"Ny	�$eSTJ���q��4�G�/��`Awb�lD����OG�N]�WL�Np�k?��u�M�$������G�ͅ�	�����a���
� "D��cRd��]�$?��Խ��G>�+h]x7�Բ��]�F[�F[��Yj8��+�'���i��f���?��؟�&�'�p�="�L]�|�%3��	�ޗ��^p���D���Dt@���0?�/9�)���\) ������{��c�b�wo.�oM��{F*�b0��CMZ���3�P�}��d/Ķ�P��4�` 	�N8cT��?u��5)(�|�l�~V�C��<�00���%�@�}�{�2m��T�LF���� Fw1�	] �֊��us��ڦ��ܤ��8U�	��`Ca-�o�X�*��
���O���M.����Kp�����l�3���r��?!��k������DD9;@��^� C|-��ә�T'�yx�<4��MrQry,�����=��b��}<���F�S���_���^�T9b�}29:��O""����EzA�P�~�_k��n���ѳp�Zp��R�V\z�T)�0��I��}�8l[��6�K�*k_�T9=���Ν3�^��B�.�݋�x�K�=�"�c�UQ�,����=y��(9l�YUw��S��0�cm���a���d��9�Ny��˩���,�7QlMCV�G�r�a�3�h�Mb�6��Ɗkdj&Q�_����"��R�}�Pb9�車�8*�|O�b~~�����4��â��h�ш���|y"�Ǣ��{�7�T�7�2�@:c\bN�fn���l1��j�A?�\5Ơe| ���Zh�\*5� ��
2S|���^$��?i8#�i���B>C\ֶ��=g�P�LfJ�Џ�N���\ɲ<���3��u@�g��4�J� �U�K�=:e�0�
�}��+�&x��&��c׍�Kv�K�/x)˴㍞�j��	��E�^5D�Rx��&u�O���x��Z߉�Ѫ�?��"��ʹ�~w��O�v�̓����e�zia>��(���p�4�;����Ҁkq�ZƉ�����|�����pP��i���j�fڧG���*#d�麷*t��u;���?������;����_-M<c�j�@J$�G��u��8��u61���1-#M�2�X��8������,~��Bٺ�6�j2)�.ޏ�d�O�a�~���zʟ;p٧�
o��@�ŉ����/n� �j�,�"&`;�%w>�0*dB\������ncե^�E�B5�l �ҋ��h�;�Vv��My��X�x��.�mڮi0tx�n7::�L���l�j�<���3��0�R�%�#И�VˬX�0!��$c�m+�w�\�>��TӨ�E����.rrqx~�x�>O0>�uE0^�y�Q�p�E^�#^�$a�Bp���G!Eg�Jr��y�=���U	��]/v��9t�����PZL';����*%��"�h�����*���y*�2������B��b�<�[�R�ka�a��>;�a�O���Ų���^o�p�UN-Zgo� ���տ���VG����!N��7�,��V7�F��x��2���S@�d�T߱:f�\H��,��$?'�p��7k�3���E�BZ0?�N4{c�I䡏b]�EW�@����6P'k��0�:�p P���ev��|�'F�D�������d�I`�qhc.w�;���y��m�*�=�,.9�eְ��Z���z|[�R/[Q=wj��nz�����H%���m�$�@���ZHͰ~����4>W�lge,9>�S&�ɤYZ���]L�&��+c8P��rX7���w8��ƹo�&��k
ˀ�݁�"��_�R?*l�T�YV�O�p-�ɲ�lgw��^������4��K�eE�"�L����w ;���SnI������Cw�u�!����/�L���k��@}�
ڭ�{\�I	�n�MV�@n_P�3����-{Bߨ���7�o$)�� ޡ�)�&ߐe��~[�8�q\�2�|�VZ5'�7�cy|�{�,��B#e�I� ��\vh|�d��Z���w�����qr̿�"�=o��t��D\p���p�^�ߏ;t�6I�S*��ț�ώ+N�~���9��Y�Yϲ*��R=!rE]�Xd���<�tI5���<i5jQ����C?I)�Cbm��=�cD� �Ǘ#�0p�*/�"G��1ݴ	
#�o+5�ۍ�=(���؎�~�)j7a���:��vE	��}^Op'��p.�*`/G�_��z���ݜ}�a7@��g�&������7�8�e���9�f\�C���I�̅mK��p-5�9��('���L�i_���w,C8�B_ͫ����I��F^�����������4�oL�,�.�`�$�e\���F�[)O����~H�]��e�`�n(�E~�.�"�*q�k��G�r~gy����[WLXk�3����0=�i6���.) ��f�\��>�����]h��]*IY	��L��g�����/�" ԋ��S]\$���c����S)(�du�������F޸�-��7�~�K�j�F3��K$�4��#
,	��V��u7VpxX
a3�������[��!^Ɍӈ��9Qg�\HW �W0�k-��k�	�l�����/��eP��d��c|f�����hciV��-�ꀊ|C5��O�Z�����q��s"G�s���\b�et{�{��0"�m})Y�kl��v
ц�6nR�L�-�)Y�����`-#;�nп�ba�rA��7ić�hH��h*��:_B���zv��*�lEe�z �w�uh�q�lD)��CN)%ۍ��ǂ�ɨ��B:�����u��4�l���@�َt�^K|�}$f��C�8gx%+��w��Q�v�
@95o{4�V�'�J��"v��I[��v4�|S��oU��-|���J���^FZ%�Ɓ5n�])�S]nv�+h	`Vzo��Q�tYN:V�)�C ��ǎ���j�p���aI�)�,#|��-c8j�MQ��O���z-W�rx���B,�d�.���ĚM�IېC	MF�"̷Dޓ�BD�C�����3�neF\�G�Bƒ��<v1����;�K\�rX�R����*��7M��������d���g&w@����M�Ź&�*�4Q�!�dQ�&u)��6j&H���8	�:SE���O랹��A�2"H�s�^a�6{җ����ޒ0�R�Y-�=��w���J�-+f�Ã���?�5]�u�hN��u�����cQ��E�-H٥��@��|�R�[��,+�op�d��T)�xq0�UQD������L���wX��!�a�4��Q��/^���80YLk�U,�C��O+����!�s�*��/n��:>�2��5=��b����܄*�4H�_v�����k�O��������w�Y�?�����W�8�����!@�M� $ҦD{Ӱ��%h�2������v�z)��)7��y
�#og�0P���y!���<(9p���8�W���R�l�%0)�`�����=��������].D�Z����~�!X�KΡS1-gV�L��}��=��h��c�� �D������L�	J�i�g�������9�.���X�m��_�
>=Q�c��D�H��Ng��4��k��N��>��l���S��F��9MILi�����
g�,�����6E���
dʯ���!���N�7�
�>�
���SI�հ�n�̇y��n�5ʍ����$��ߦ��zMe>�����_�Gf2�?ޭ�_�n���5�"0E�|�������3��f�l��+�X]Wa����ԓ�!+/�rl�o��Ӟ�yۑIq��眨)�����~@��Zؓmw��&�����:	��n���!!B�ޛߎ�N��9��J��N��<�\�xp���X�n��QRp=�rV
S����5][qxr�:re���d|�8.���Pn��V�`m�	^2���?+�������4��o�4��K��_[u��> ���u�t_�@dm����n�LQ���I�������%��IP	�+�iX~���'�3!���;��&y�R+��Sp�(�<��Kl膨zFK$A߱�Q)nn�K3��Ț
|�Wk�F��}yCŝ2�Y�Z���kfvw,�f��O~�9�#�3J�t �3r3�ƹ3�~��7g~��q½�yM1A��o��VΘ� �>�Y�� �b	�1���/5}���^�)�j}=�}(�ۣ�I����SU�C&E�׷������(��� �?��TW�
�2ӱS��/��J�Gca���#�M�z���Y���[��F�h�}A�|�/reuŬPNt�c:��?~����w?����So�?��x��H�{*Oa\p��R�c{Ɔ�o��.	�:��m�2� �rR^o�ο[%����(�Υ�;,e�2�v;�i� �Q'�M�ЍcN����V�*ߒ�&o*&�Qn�8Ǜ()5����
ҕճ L�K�o^ouPW�����e]�?�=yk�!)�ʜ�����9�OlniK�AA���
��s��y�ۏ���,�!�eܸ�T�
���m�� �b�3�iҳ9()���ۆBF��&�kg����oR��Y��Յ؀i[�/w�%0��9Hn�t���I;΄���^��^��y^�1��ʣ���WM�����ܑ�R+ �oS��0� vFt�܆㦨�8
7/��� �=WU�V�q�@����ny����<{Ή�޽k�>��hk[�����c��>���� ��ǲM@�o��e0l:p��j��;�ra����p��U�!Q�'˞���[�.\Y�QnU%;��D3>�Z+oG;|GL��?WQK��f�}��5��C�|~�t(����'k�
��-�SAE��0g��M�z$-g��@V��̑��x��&A��>��	�{�M �&˞���5�h������A���e]i(�4<�b���@���[��������q�+���d�P�O��GǚH����8�ӊ��:7���9+�׉dҽ7�#�JѲ��S):�&vV!P$ Հ(�l�'�y�`�m��t����_Y
��I��_��Y���`���d�ј���ha�rJe-��VICW�|d���+�� ���3�ޙ��ѽ����V1�%Z���
��oH!�a�֥�Y��6��x�/n2���W�\[z���`=�߬U�.g%�'�����ahɽ��{���}���BA�?�����I\����k��-���#�<p ���d*���<v ���,�_�ڀ�r�ڄG��p�H�hV�7��]tq�0&�.��H�ܚ�����;�w��M��RDM��.�
�[�Э�F����! �ҦΙs�(��?MCZ����-�$+Ç�X����=b���G?���i�U����.:�_����d/Vq��=Ut)�Rc����5���J�I����`��/S�o25KO��Ǎ��4+���|u��P��d���'�,�7D�5c���d&rߘ���%��T�X����l��,E?G��H��K�a�F2
27��ҵ��ufAߓ���p�o�����nq�����R�[>� r�)&uI`,X���M]ܖ0�נbvNJ���c��1�-�_�aw��M��}��)¨��6Ɲ?���ߟ�$R�M��
���8�\m���Nj&&C� �s֡�"FZ�A�yя0B�w�����lw���!�u�Bk���谙J'ՖK"a�Qrb���=�J6���OS��H�Xff�[����X�"���0���\�I3M��p��l����v�Ǧ���P&�
�^�,np��MCR]�L�ԧ��
�'@C�8V��`�Vd��g�d����{4��A��v��;B`��l\Ӫ��C�3f���u}X6+�z�f=�����%�/�$j4��̦�V���|n��%qBi݃ᱚ#4��LԚ^"	,�Ojv���01�5��\��/A<�`�d�RǸ��� �֟-]�*OلO-��Yut�Y�¡���"sZ>k*�t��t��A��N�by��Ο\MG�.U�F�����o�2���rn�J0���(n�k(<l�������A�VK�|1��٤��`5<��pt�2W�_ҸS��D������C2-�y�6a��{�3ۼj�8{>"�j�{���H�������y��{�/����΂�� �k�-���/�S��Z�˘�p9Jv)��E�����"r&sx�u&ۻN/�:�G��STٙ�/�Ɍa�n�;�V�Н��͈��ʿk��wDtO&�����m�G��u�w�bbl�n_fk��
�5��'cg��j4��w�x�����ML�w��o3 b �ʖ��u������l�%C��%�~�/���������Gyd�p�Q���$�"��uSp��<+�bN2�b��yKyO��ܿ8�l؇��]<p"g���pz+`���	&��S85��#�r�&C�!�ф588o;W4<��M���z�dn7qG��dU�
�����7��ҥ7���IM�c�4���*Q��#�:�u}��oY�V5O�K����LqGĔ����iO͈(��7k��{�,��A\�|&}7�a1'>�ҭ��׬J��������d��ѭ��wڇ����Jv����|��R��L������� ߆�>�f(��Uk��N�K�ҷ�U�hT�>��Mk�c�/���=�LW��{����)� o-�yR=��l��B{�O�W����˿ͦ��_��3�����"/�o������y����۵�}w��2����vV-�=W�nr=F�2��Zo�v�#�Am+�=���*fU/��Ր���F��_��������t
�}��Ӥ��봸�Y�����gwV|�xd9k�(Qb��	zՊ$=L����P�qW��;�CZ��Md��b�S����H`�^-���\�������vR�oS�ft�]	�(���|ۼ���A�R�n1����f}:֌��m�?w���(������]5�� �H��u4-Tʡ.=5�;	�� �D��(/ett�R�bT�3�4Q-�#�sxd�%�V�f�)�����\�Z���@��f���53���i~h`�a�
��R��ގ���D/K5��M��e�Q�V����G�(��t>{Uy#�O��=*{�0"�\M��66����cV���!-�Kl�*��=�R�y?0 �LkH\�O�%	<
�t�\^�5�� ���^t��LpUD�S@iP�f*Z@J���QQl%\�C+�Ԇ�эA����2�+�Ge�L%B�������m�����L��Y����O��b>�#�>���|�"{g�p1Cz�ܐ?�L��8��-��5��I;���w�����f��
����CF���ޕ!&�:(��(>2K���q3�b)�v���N�V�hN�O�rBacl춾��[Jf��'��}�o�^���Y��h�o��"�/7�Ԣ������B��Ǌfq��������pN�؃1�abȘh�_!V8)̆O�b��o���R�Wᇠ{�U` HJR�l����a����T������.C���)An�����\���9}ɸExzbR�D�iO� �o���,Sf�r81������-�������~I���4<��c�=��g=�k�==L�#�!U{��Ԁ�i�o֗$\��, ݧ��e�'�z��T�T�A��N�mh���;G��d�ܹf&tq%�۬�{4�*ue�����D�
�Ի=�Np����� !�����'��K�7]ɱJ#�8�{?^��ͤ�}l_ўh�+"�h��$f%) Q6�����8��,�E��*�I"����!!]0��o]a*q���IY�n���Ƹ`��������"��'7:D���h�8�8߲*2�Y���@8�V��vE�Ƞ�#���p��m�JVڮ��1rB�o�ه�Φ*O{����/`M���!k��A�,�mL���������[(h��F��dWg���F�צ��Q6�Ȇ�\'�iN��ar�1F	Xֿq�Ӻc&�S�k�BN&Cf����=l��i�WX氯�敔K^-*��3��1�R�Ǻ�!��*����^�N�ۺ���6�aN��+�ݷ�_������Z>��
r�}/����i��5�\����
@p��� 'U�;M�P�@��Uå <=���	�	�=��� �oE�|�_ ��/`��d9�pʫ 3�[9�QF����Yo������>:�Cp

M�	�/�+�]9l/̨�y�����.t��
'O�I'Gz�/�I��Jw���*I���d����Z��Dp�h���X?�1<�Y� ��i��B���Y 99����P�"Ǎ�'����$re(6�Y+��\ �*�5��WU5�{���렲1kc}�B������GiK�K\��M��d����T`�Tc`Ѽ0�a���l.���V����;����k8'MU���/�=�)���j���ƹk2��r����a�>tY��m �� ����Sϰ�K��C,PXm� N�5ഥx%N'�� ��9�jy���Wq�?�r����3Y�d&J�ʬ JQ�X�V��G�?�P��2����)h�T�z��%x�i��ޕ���z�|_�tq�ΐz���?�M;H<'���O�J	p-�D !�n`}B��O"���-T��g����`~��W�d�U}Gj��`|s�=�s!�6�J��HfE�z�SL������V$�O�����"Ѹ�3�ۜ*�
w���x���G�����4�]�TOA�o�_�]!��s�����sg+j"5J��QwzQ��"�������@�]�����_T~��N�H��J�U3"^"tx�3��ؾV�x�P�0�tQ�m���u��^�cNFd�H�v�2���z�������o~�)���0�e�2��:U��5ĩ�ƭePMN���-�c�z6݄�h��:�a��l���"3`
�%K_��*3�z�������-[`Z�������F$Kd��s��kꄙ�[��*��J��x{��mN듸M��-�!Bw��H�$%�j5};K8��3~6�	A�JJ���J�ڱ�$��F�)��H���h�_Q9#`�G�0!s���x��:��/�7[:�;�b��N�v-6����� n���48֠�m���S��!8�ڋ��V1Q�9�f��VoIp=>�B��l��2�ە���o��D]�@��9��V�����\`�Gʓ�;%�W,�[Q�XL�� <�Q����dc�I��a_��E7:���B(��)�n�$H�S�NU���|�L�
ݭ��yR�^:)���_@��j�J ��U�X���\��wkή�����D����B�&�K$u�]���*�ʻ����?-O|K?)�ZxƓ>�`���x�#2�O6����ʼ����/��$Ș
�����e�q:BVW�$��yP��o���0��A*�eI�)�{2�[�p-��|ޥݽ��D��i-����YO�=��]����<mx�2"Ӹ�hLq�E��^sF�K�߾�{�A�z/F5�P��
�ü��f4Y���h�k0t�Sۀ��#�'h	h��NȤ&F�|=��;M�M|חdCn�7޴�0�C
\tW�ދfu����z1?��q�����8����r�/�6�e��/�b�z�ʖ��؁fg�9F>�$�܁����S[Ϗ%�w����S����]���m����.���U�*�oP��2s�i����QA���ཤ��s���V��J���8)7p	�̝���J84i��6��)�����*�#^�1OA .H�@6F��_���@JS(��H���}S\�����"�3��i�%c��$���)�ʆ$w �����J@4��rc��CS/�{��ry?P��V�3����Z��@ZM�{ssȑt�%�왽N;�H� 0�%��� ���RVH;ݹ�#Ήm:w�55�/��/Mu�xC��y�4$6�}����� I��E���	�/�KC����ac�ǖ���m�Ul���x�,��oP�ȕte�X��D���N��x�ŕ�2�m�ّ�c�_�5O��9\Ef�D0V`Q��S���sS/�7�ex
W�D������j��E�^����4����G�Ǹ�[q�3H�C!��x�zK�\���}��7blG�ط���tjW�#�MG[��c^:]X= z��v82qo�z'��JAW�ln�މ� �A�6ʯ���eu���d�6h��nZi�����8h��f��]j�Vw�cXl���\�F�'Qn�MS�b�b�Y��<���`+�6D��У�˳P"��nbg��:���l��4q׫�&���/�V����{�k�J|?F�;LX
0�	g����t�.�M$(bj���U@�e�L}�!���2��z2�����r�hw�~Z���J(���
��CV51��w�%�����$�2^�����g�u�{I��$�����*�~R�c)��w4�YC�g���RP	�wЮ�b
9�5�N�$�?d;F����Rǧ!�g1�O�9��y�[��~9�m:��qd��,ț��c}Mo�F��z�7��/�$o�{�vb�����q�mm3e_h*������d�e{	-�&�%���a��d%k����)T��T:NƔg/w=�}o8��a4?N��SQI��q�Ph/$�R�%jo����AХ��WZSP�v�U�l�;Y���u�fa��5f�i�|�!�"�P<ܑ��S�7%~&qe��T�%�(ȊhB���8P����*ş�{	|
���o	�n��{7X�N����cq] R�,���HK�-EA�؏w~㛂�U4��Vv���f�
i�~[#_�Mq��4Psֻ��i���ȫ�_��p�O�ah��w_
�YiJ�ӻ�T�^N�z�b/$��I�a�~_!&�����	�5�JX�b�Y���b�v��0'�������XR.��
�T�z������:��<
Qt֚(z��2�f@��m��8|	AFň���\�嗖���P�.�����@`����j���m$`+^�t�Gݲ�Ft��:/v�%��(��v~{�byr�F�P&ĝL�P�lY�����"Br��\��6��@ZD��76��Ҍwc�X!T���*ru��A�U���a�Qo.i4��E�C�4�
oK�%z�$zcr���H��@lk|�=.j��G��w�et��h�Ѣ8@d%����Xi0��@B!����|"���i;=Dl(���޲B;��ox�qu>����y�[�^#���.>����	�{����ɭ/���2�8��!�cq���{f�]j�:mcb��u��$i�b�u��/fH�Q^p�#-]�Iՙ����F۹�џr��:l��Q��z�*V�5h!����x�d�e�rx�삩�|"nt�;H�8��V�0X�̮���ǲ�'��|s�� o���b.���=Tcބ���&�����F�h��Q��z7Z4/��0�k�l�xY���T}rp�6
����X��Vٚ!�(n�ԴM�+X]� do�9�>˥�L�������_�'<hP-���J���{�q\oL�G��CǢ��o���J:�t�@��ªǪ��o�>�'����a/c�ʦ�֏~Ȝ��_�

��e�n4{ ���U'R����Gz_��R��[ʨ�ɝ���a��*�Q,
���"ȇ��6ĵ���"s<��J-�g�_yֈ!)l�v�;i��7�V�B��k��g�N>����ޮ��l�Bz9L�!����p�h��-R�$��hT2��h:u9���UQџ����_y��%�L��φ�n���f����	i��U{�dqE�3���m�=�'9$���zJ�=?�3q�%xϵ�52񅙿ב)z���u<z&���A�	��$7���ݓP���'��MY�3`����L�ѫ�`j딶P�n�H�3)5���Pf���=�a}X��rY�n&�62���۵��ӈ\˯ؑ�Mo F|�$�@)���9��aHX���B��+����f�������V�I���'[Rf��x��яV�km�ș\a�����a��?�#�.�0��+�Qb�X 4:K����EϮ>=�_7�����#7�OW��`t��?� F��zi��n�#fS���OO��gl���x������͚����V�+��
�W�8�B�1vK�K��?D�Y�}у�75tM������6+�Ô�"`μq_D(�@�	]�Us��!A�	CL?��������|3 �0��𿹰��R���p{�-��Mz�_�E�`��uT6-W���cK���Dn������^��!܋>C���^{��;/��ԟ��5����9I����R(�*Pu����3��r�#����	V 3��Gg��ϕ�'[,!(����hc��:v!���u��/Z1��~׬ ��vtn$�\m���{�	�}*י{�È�}t	Z [{8�T��P�V��t�.�K�E�+�l3I�� ���W��O�*�(t�wXC�<nfҦ���j�q!:1}ʷ倵 ]�%+<�!���g9��]�`}T ]׾��r�I��%H�`y^t�.ek�A��NG8eq�d������v�|JV��:M��l����Y����"�%�>=��B�9�˔4!�a��]��*�8��f2�>�k�kpGP8!�=�������9��S���4���w�5�R^K�Q�*�%��g�����~�y�D�URY	�ot�h�W����b�ŶE�%�Uk;�.D�;�QxdV���4	^�t�H�5��������=�B�RT��YPe��]C^�@ C�3��6�P�J���0-�k�|�^4�Z�)�y�������O����1���)ӟ �Z���f#l-�u����d2z��#�;�R��+�b2�6�K�l���F�����m��Vӕq����n|�:���B��&e��BN�J�7x�Y�nw�p���hO�=��~������z�8� �VN��Ä	���g6RC��V�+�&���J}��\|�P��ɱ�$��`=x�Z4�ey�*h��*Ѡ����;���&e��g(��͈����	.f�9+ ���q�,Z�3�x�" �{� >��2��[��O��"�ͅt'S��l�|�i����u��ܧ� �,è\�l"s䡟Jפd�D�Y�ҝ�J�
|�8�c��� v���O�]ʬ��6���z����o��_ig�����]좪qGrO�.�e���B_dH�j������<cM�r`ig��J���]S֏�yP�Ө3�yZ��Q�CA��� �HYv��q�nsf�N�}�����KmP��;�H��j��S��{˳����iet����R��̵�$���H�%��<T���Dz�Eo��w�����L�r���5%y�į����2B���o�ld8j=īj���SqYWhg����.X��۩?[� �}�M��2)M�
8D��$?}5�!:WPi�B� 8��X�He�EW$̢]_gt�g�l�\�s9�h�OM�P����%؄W����%E�������z��O�팶�M>��-	�Լۭ�jZ�>�/�W�͉ė����>\�h�U� n_��
H���T���.�3<V�
��ِjv����n{,�M���k�*f~���.p���tI��6Q��<�;w���mn.s���N�Ĭ�$g�^����e�2����1��p���:�C����Ҫ#�R��9A@'8�gF�8��K�ki�--ֹ����S����-�`$& oAz�6�5�~��}S�
��X~���k�d'���}��/A�l;�F։�fv�Y�9����|��a ��D#�;(w���6�����m�������&XsV�+�ޯ�sD9&�����D�cAFx$@�ڃ��6X�
DP!�!�}.�x���CA]�fԡ���,K/��+��Q#��|�y�r,1�%�grl �D(���Ǆ�l5dP�{��k�s5e��Q��$mA����CB�r"�iϨ���Z�S�<�Ў��Whc�PR9Ѓ߹Ǻ����.��z)���+�0W�ę�1�t�E���s�.�i��� TA�aC���/�6D�7��0�t:c��Tq�(�L�d��{=�
�BN�O]�-_Df_���X(�p@������ތ4BOZ��20`ǣ7˫�{P�u~%�9/�%�6���,�O-Hb��RC��l�E���n�c���U� ��b��{*A��u�ɪ`�0��P=�/�����qo�Ax~Tm9U%�PNi0�H����J�L�u`A�{\���2L� P�\�[^�>x�U[J�	>���^��Tp.E"G!a~����&Ke��RA�׏���\���Qq5��T�`�A��sf8D���3�f��ʕ�g��,:���jG�n������Ǚ�p�l6f�/cB�F�̍�}x����593'�s���E����C#��<"���eBg�T��h$��+���f��iw��]�����KTk|~��'ɮ��X��gQ!����	��Z���ԇRE��{O�+'/���R{i����]����׼|
9�Ӯ�I��O�k�6h`W>x�׍��bi��0s���Ʋ,�rA!ǌ��~?/�ǥQ�����8h���B&RsGc/���q��]��i�S�C.��d�29I�X���^�mf�\�I����$'���E�i�������-�&��ij�o�cf��6%rWN�D�8�g�ǋ�vI�:dv6�ΩPB�;��"��h?�#<�b�f/eg}#��U�þ�Wδ`�J5���ޣ�]1O�:�'�<�rw�}��k�5n.$\�����_)�jXxb쀬Ǎf�䩔jl�hb���/�����u�;9�Ȓg�2��'ؘ�a}q+�3H7�s�lw1*z�E*�]I�jP���}�$�<���Ñ��m�& ��GJ�6����hn^7?}�0���抲��e1(Zg��'��v��$���^UA���ex./HP3��hY���(�>��_����2v
�W~+y'k�ّu����օ�:pyCH&H���K��������p�6;"�݃j-������K]X�z����o��f'��f�C�Do�jm�/Hs�44W�tE�2�+N���LK��_����ΣzL�^�6m��⾉y��V�;��+�����,�w��FS��Q6��*qmn���(�ӎ�ˌ������%�A=w
@���ٓ�[�7� ��&�F
�,^ÔM�'1|��ڻ�h����͆q�AA�X0^ř�s�K������D2d-��@�M�����Cf������!�Ƞ`�a��N�M���5��3/��=kWcSJ��7̒�T�ڑ�R��� EO4�)g/H�S�E�����b�)� ���q����8�Ѣ4��ě���!*��P�re�-�.����Jj
8NjH��6G�d�� ��]��{v���(T؏���VȬ�S]oe#�H���}����T ļļ$��#f�TJ�#۴\��
\������(�q_��.�-{�fpK�3��~�yl~e�6���3��^&@�r�|2����_��V��	�(�T=[�J!�δY�lTV ��wNÄIM��-[h�+�W�j��)��o�7��B��W�; �	-ڒ�6������iP��r]�>�޼;�;�*CѢ��7�H���~�����G^���[��F��/�ڣ]rD^���k4�F����y������{��X�{2�?���K���7�H_;����t�CJ���"v�_��)����<��<w��M ����š��$(p^~*��7Ⳍ" �@�A$�/�aZr��8�o�>��M�T�CÞ0�3ԡ`e�X��d�|�(xg�HvB��h��8�c�Dhe}U�4��ǷQ�������~SG�`5�/�[v����ImE'E��^��6�����pNſ�V�޲�C�r���N�6�Ak�{�E:�:xT|Ѱ"/:8Ɯ ��ݬA����=�p�_Î�2bbd���a�oc�����|+�	K�{:?�y�L+d9]m��`��#�L�� 7i���+��>v��(�-��Λ{�R[}(�9�d�q�Fe��
�}i��G
Hҽ�ύ���rx�����Vxʮa��ZjXLx4��NWU6l��O��.si� I�=�#�v/�!q��������~>t��5�P�8�8�4����D�7� ����[�J�8 w��\>a����ȥ["�|��1�6�h�:�!������/��nO���j�� Ma����N8(�<���C`�ѧ��7�aFf��� ���V�X�Y>�R�~��8��rɘ�1>"�0p��|8Ѿ�棹0:AfDu{�c�d9�������y��E���MNv2� �}�]��5P�T���#��G�$�V�蘺���Һb���|�if2~؈�A'f�/�-��t�"������1}����j��R`OV��-�	cd���x���*��'��+x\�����q�Nj�O��gJtlR�{(��^ث�Mp~�%q�W��-d�M����_x�$@����N~XH����z�C�?�R8U6P*���U�z����� ����'QچVd�a��w�*FP�4�u8��j'=:�(�p��Z��J2ڑ���S7�}pRlő�-�~�_R�9�+n��)�rs�)iр�]���:{v��Q*Ȩ>�O}�y�g�&���\��(���1�j�  �7/T�;Q�UA�[��G�B�Z͌��b��F<�*	���B�*K�檂�>5�HfҒ���b���Í,��uZ�b.�����)�Z.�D/��> �1P��P߰CN���Ab�GdB��ՁH���ecM&����e�Tqէ�r�ID���
�3==穚�` �Qם���F�7������獖�	���sA�t	(��ŧ�U,{Ӵ��?��+����.բ0��HP��N���vbpP�%U�v�á�$`Z������c��Fu��|N�2�KC�I�9a�v;����/� �c��C[Xg�N���M�1��Tvlz$1S����Gq���h����:p��=C���~2Z`/�%��ܞ`#MElhC��7�W/Q~�J����S�(���L+Wz�M !���e�qY�?�ݿ�Y��U��Q��`��5������� S�/Ys�� �ແJC����	�-7ble���	P�z�u����F�:)�A^o��I6�I��)U��(��e�ɱ�V�0�18y���v�'��rKЈH��e�����bV�yNW�)�V$eP0٣�#'ŵ�R�Pu����6��%����N_X!��/��p�"�s���î3�Gqo�F�.���ѹ����k_¦\,�q���˟�R���	?+t�8է����}찿$+��%��c �Ci�呹�>��w�Y��N$����{D r \�%�V:0c��D�n�<( �w��Q2��x�3�-\��Ɂ��A�	ʨ+�Z4a
}D�DC��ȺTףᡏ<�����&���"$���@�!A�{�k�&b�r�p�z��6+A�v�Ҭ�`A,D�vWAZY\Je�����/�B6
tt(y�g�ۦ{�̽�PW/'����泬�n���~g��%�n^	�]ɻ��T��Q�q��UU[����Ő�N�nN�X�n<�����d#��Af+γ�˴�ұ���0�:�m��������ԩ"���c3\U��3A�vr��!�yo�e�u|C@25?��$z�e㇒�*���;xs�GP�YC�U-�����X���'�l�{�#�@�W�N������+��l9j*�g�Y��
����K��z����,9�*a��]��ü��z���.��N-�u�Ħq��ܤ�Dj��8�����e��l��e^WX(�,��˙�����E�}�|�S�k��٦��<��Ln�!�s%T����3�Z�=����F�y�˨�N�Z�p�uG�l�zU�͢��9uCw�>����� l{
Ă����|U��n��u0��76M�<-�S�s*o�q��Q���z7���x4�����*�y'�g�»�=(�o�%��}vm �(g��ya�>��w�v~���hA��> �|��q(�"�̀-Q�w9cF_>���璈���0��6(�(NjV�TqIM��j�����͆�CĎHRQO5ؕ�2�.�_h�?j�M��L/��7%0�YK~�&M��9Y�6�bB]�g=a�Q�I�߽;�0D��F�#��}!K0��y�>t��}�3���J�C|�5{�����Ґ��܆ݝt"����U.ڷV��u2�9�~�]A0 u)\n�{׫�����y�T���N>
�&	s��լ�� 5g���}���A���Ygr�/x/v��qX�@ג:Qս�X�^"�&J����*;m�h��hz��찫����~���f���r�s -��Ka��x�+�#7ܩ S��,��)�rT��ҧ�4%�x¨o�!�9z>C��#e�<p��nxj���|��6��C%ﲆ��M��{.�Vn�7L�H����#�����u�64+qx���{"Ke�<�w��i�����a{�,�Pt�����ي�i��Y�FI�9��L�_g���K��[nH���a���F�y���h[x������u
 =k3��!�6��{7
��տ/��a�����Gؘ��L_�T.�w�8����)�6pc@M������42l��uZ���9x�6]�B�:�����˼0��,&�Z�{����k$i>�'�,�\�:q����>}(Rl���MM�����"��eh&|�q��w�O_��H�߼����д�Q���f�9�G��t�ɢT����)��$O/s��I�H{���^3���`%�d�\��W%�oۃz����)�o	{S�.�q�va�}�5 }3��IW^	:�#�
q�����+�^�{+iG���<�c@��h�F,�5z,�1Ma#G���Z9$�D�X#�}`J���'�b2a�B8�V�l�ZN�M28yj�z\���ƌeL:{Ɣ�eG�׼<��/m�Z?
�A�&j[U �nm�6w޶�֯A�2�ũa1���0�;�0
Xm�AaU�ۭq���0�%��j!֙�=�)��[��w�4�RWd��4}��0��R�v|`�[� �ͧ����kc+XP�e�(7#"�Y����n��q["/��8��Pм��Ih{%�w���ھ�������WY�q�?+@��a���=��w�?u�߹ˈ�ϫ�s:��T�����^��Xұ�6�,A��5o�ɔ�F�S��e�5�c��0�Ώ3W�k����p�Tc��m��~������	��>�tLA�W�?_�09�`�7��{;	%̤�S��s�����c��`:ͥ���Q/��σK�C[��nW,�b��R��d�濥�����m�� �C� k-�����]I��L���&x�8` �(�Nδ�GU`�%��%�N��4��z���.\�I��C
��%�B�����_b�3(��8��=��[�َ6�X1A�)�*�+ʸI�l�j���K�T~������ZO��Р�
�y�)*��	G�T9�EA���W��~��h�AT	=��卣�C��'� ��3���\�\ݚץ�H�����|��t��t���=-����e�9���Z|&e�\EL봼��G�0s�R�A�q�j�bb�>\�Cg��\���X�vS�x��i�-7�{��ق�{�a�a�/��3m���Ќ6k����4z��9lx'�I���Nb�H�g9�.��N�=��5A=諁a�1?�|�d38v7k�W��n����^�&�i6    ���wDj �����M���g�    YZ