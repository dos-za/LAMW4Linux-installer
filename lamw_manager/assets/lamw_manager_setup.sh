#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="621694384"
MD5="b263295e3d7652fae3a3634fbb7b867b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21292"
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
	echo Date of packaging: Sun Jun 13 00:11:02 -03 2021
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
�7zXZ  �ִF !   �X���R�] �}��1Dd]����P�t�D�q����Ϲ��o3�:��*��H�.z��rU[0k^���1נ��l��^�/14R�Q"��zZ�ĥ<��啦�2�ҕ�d:@�,���	�L|i�h�x�TX����M��a�
��M��V����-�\��ܸo>����w5}��HF{�9��߃0Z�*F��7��^�A��`_����c����,�:+���WP�nQpR�O�8��'�h�P�g&1�!����C]4d�S\EB�
.�Q`X�U�M�ו�4JK��Y��� c��˟	kj��2v�su�@U]Dh����M�)�xM-�;4�F �k�� ܊e�AƉx���-������b�m�n&�@��J֥T����v��I/����Ӣ��z��`���<�n�%¢��иܱ��@�e���a�.��~z.���.����W�� �B%O!����q4*.��� � �� 5�_(�i���J1Y�m+�t��<��i։+�V���*c��B����6��W��b0�@�N�sOOw�dh�u��~��\c�X��d��F>�7fo��6��fe<�1'ʎ�O�)����K� )*�Sj8�xЁ���ŕ������G���֠�<=��"�e��+�)�я���
�[Qu*��ÊjH��:�MsQ8�	~�{��sv�m���
����<��0���b�'`�J(�b��Ǚ���?QU
zr�DH/�\�����P92[&��� '�O��kz�Yc�m~,�}Mٳ]~�,�6 P�85�)L�=磷�Q,C�l-�vm��8��L������G?�G���Y7���T�in�S����p�R�^���!�����,%ņ�@Z�ڦ~9j��"���e�؝���>�pP$��8d�~�t��|�k�"�ް���~��(a:e�<��j��;��qW���k�E�``ơY#��mMA�Z����e����;G�����O#��b�؊�G���ͯ�L�=f����2 �C:������ے+^���#�u m�N=�!���/O�5�4d��{2�w�X
?�`��+�c�9*.vj�eL�"�+*��n_zR+|n*#��^�S�"�m��S;W��S�����Ŋ&P�.���X���|<��t*��75��. �!fX�]!�(y;�eo��l�@�Dj�L%:Όn�J9ԯ�K��ҴV�c&6��h�a\d8�<y6�L��% �����2�մ.���RT�h��o��o����/tן
?��%��������Xzi*��y�K̛�K�Y�*�J��!����!�i\cX��^Ӈʭ������r��<eaJ��^T8����@֋���8Iy��+��þ�d*�[�o
��ˁaݷ$�P8�/fM�t
�&A��lʫ����f����.R��n�$������FC?�����g�bo��"��?M���"K��[e}ǭ�����7S��� >G}y��*����f��ɉ��(���%�E����0������g�X�	���w�"R��]h�♔�m�_ڇ����A���V#vY�zl&H+��Gp�O�=�{�>�^�O����Sccˉd<�"y7L؟��� V����SV��;��	���4?���/xc,�آ R� {��iB?#��ECA�B\�r�v��� �f�e���s�
���h�<e'5 ]��Dn"y��{�?��D�����<�5*P@h��l�Z�*t&$�)�xG�l�gOX3��`�N٥�W'E)�����<�Ͷ��"a��`��]|끫�6~�!�;�S����!���W��<i-tKnC8�"�1�K���W%�S�dr'm�5zx}��ݫ�[j�_��O�2hż[sQ�|iH��Iض�<V3 8���<��3$��@ X��N�	#�7}���B_����r����]{S�rd�c2�įpqJ'i�pZ�V��uM�2/s�R|�j���J���1�m�m>�}�q{�d��W���*�E:��k��	O�EA �QY)/��.��h�`aJ�CnY��c?��ގ�� ]}��$Z[��6�yV�|�����(G���ޓ�����]�������B����8��6��e&�3:Ў����Q�THIȞp`a���H`2#�|_�;6SDS%��Eg~����Teu2�~s�%�Vlh�I�z/6w��fR���n�,B�j�6��KU}Et�ƽ&��D�k�"���c��=�<������Cb)t��"5s�}�!���_�����G�!��B~37�J?X	#����f��X�$v='�xA�eÝ1l�戞^bd���C�e.bK���75�+��"��+E�7���Q������y�r* ˚�"Qk�ܯ��ԕjk����)Y�'�iI>(sp���Vۨ�SN��:�c{@�vXo�7o�T�W��M:���#�-�
��xV>��&���T֢��3�e�r�-jƛ�t�#��9W}B�E�4eju	`�'�)�Zv���^6$�h�n���p�M���Dj�����;̏��0$;@N�v�=\��\r�l�]��Sn$��]~�gX�yq��F���d�Қ	P/�;��8P����u��(�ūQ��9OzB+�=�|�z��R�O��.��s�g�h!�|:c m]��!�IC#����i�S��&�Y��̻��], _� �7D�p�Q8��s�z���P��܅9������1-�jZn���_	ֺcC�>���0vj8]ueϋ}ӫ��O>��4�8qa��;D^��������g�~W�¥�Ǩ��O���-8���\:��'Y��М�o�Mzί�K�y�P���@�$��L���v�ềh�H�R�rm�E	�F�{� W)�!�nQ=�^J��JƖ�����gɦ�����+ �@�Y�}����{&�>�����L��//k�^�&ы�Ԝ��h�"�!���l�u�1|�o���<<���(��z�����w0��,Z˺�j�,f-*��Ͷ&:��3�L��4�x9�&��H�����VS�+#�(��9�_Hҋx�m4u����Y�+B��DO��BX�8���!���b�Ž�=j&eQ]���������AXo�w�?�UH�2M��4mQ�o�,�%�g��] 2>��f������9/l�$Z?��cM*���[�'"S��e�B^�� ,��a�}@�xW/h��A��Іgpބ�{�_ �gh�/���p��p}����?`�����X�4@��+��,�x����O�:�M�_}m� tR�R�s���?���y#�!��QN��x�6awq���!	-�0�hBR N�P������p�	CKcSlg�59�S˓j�P�=k�_y#Lk��n���%yt���%e:���-�t^�{�0K�J�c�G"���e�j<us��|/��ŵ�x���;q����tF���췁�+�(�@&[�z��ֶ	Z��˕�����O��L�-k��uPX�"Đ�2�<�p��~�q�Ұ�ıi��h��DW[dC<fl��Z�)�(������<W���N��y4�ݓ������~�<kv�U����^�g��h�dhO���'FS�_"�1�+��r��P�ח���[G@�5�9�� ;+K��1�Q�Z�6To�8�x��&����.^7y�E��^܃?ܮl�	ޱ��O㛅��ߩ-D����U�S�D��|k�9_uʙ)L��&��c�%�D�QxX�\���b�,A�:�;>'4��!���w���`��wln��j>%�_(|㾾�������4�]�'��.H	L��,_�H�x��g~5
�����u����h�6�| u��e�`���/oU�y@`�� o���]\
Ky�o��7G��SE<�B�1G��ϛ^j�inE�̲�b[ŗOA�B@�)Hb)]���UQ��z"߂���p���)
C �+�s�A�����((�y#�
�ѕ�`�&7�����7؃�iդ�Pk�3,E(��u7B�azg�@����{��{\�E�Pf�>�PE���;q����k�&m�D8�]�5l�����j��ғ��b�����Dy�����ъ�pzq[�JK� ���\�޾�E��xh���ҴA*��t填}�:$�8���s��'�_����!�����/���5^�BӁMr�_Rj5�{���)�S2�~�6c�>�.<��m�\w.y��$��3���uT����,f&s����k�0(����NtY��G����T1Q�A�LCz�����i	�v�_�S�a��V�Qê �F�YF�	v:*��HT^��Y/:�}b�,X�hk�Vwhpw���k$��}�����"J�G��+�U�8��/3H7�e}�&Q�t�#z��0 
~[��K��^׏C�ҔA�6A`l�-_L���H��ă��^�x���WO��?`����*������6��	�	�՝7w9NM�����.�q�(�4J�=mh�,b@Q;���)	ywR.f�>2-��k���*��%3o�2#��4N`�KF��^jK�hGȊ�x�{��`-/�*B?u{���ۈ�~k3�r�����b���KA
ńta���t!R+A����AdU����Q�b��Y%�p���ҌL#��N�	)큪�A��GL ܏�9��t&���2����!�u��Gڙ�Ig���n�����mT�%9mn�S!.ى:�D�	A�`�*��6F��NiųP}o�.꺷?ܩ��(_z�k?��hvUtoU,��"On4f���?��0�>����,6	��dR���I%��G�2FULr��Oy	WM;{u�F���Ѧ��a�e�Y�k���ۈSP�j�y<ӧ\D'K�Oʽ���w��U����U����35��@Y�ҟ�s�e�z���/�}���(�]��[q��s)Z��h*��nNs�q����R�,�P�h������7ڄ�"��->�T^[���2Z��J_B��h)��$`��:tߑ�G�#�-�`oJ�U-��g���!>�L�̍L��oq�i&�?�-1�0+�I��x㧬��SF��)a����	nh�m���|�C�Fb^��&��h�c�{q�Q�Z*y$��+���Ѓ퓵th|`�֝��V(y��42�ӄ������Ȣٸ����^St����F��z�����,:�+v�y�g�T�ph%,������k��8�Bd6����b-�$�'�����WLo�7%^ɺ(3I��-o�	�(t��B&@s)M��2��]$׽���ޘ�����a`�ѲP�j�����ߜp��6�!�|���lѼ����N�Q�j�lz"�c&¯!*������^����C���RE���K��8����3g:�y}I���R.n	�A��ܳ��_��C4���b��N;A�_�^�QJ���!#G6$��T����G�R�Uܹ�g�� �q�w>'N"C��*�wc	jh&1������tE�ڷ� tf��g����%�1'�ޕc弴md���M����u�	bc� x]y{�~���`��nx,�'Ӡ���A���j��?EA��5���,`�.g��&>���N���0�G�_�ǝ��'�(L6B�_"�0M*�G|&nf�MK*ټ����_���"���ቝ,G�@����y�@J;�{�s�S�)^K1/��M����p!~M�a�Ξ�?�I_ށje(X�S�!����% frc3�UI�.r�>^q����0�ǠI2��=x ��P�ICBЬ$`Z2l�#�lkowd3l�N��|Lv�����-�H~�^�fl/���!�����)�K��2�����2�M�&�x =�{f�1�Í"�0��v
01���Ҁ<a2�(>{?����X�U.���WB3Y��똝����w�ٔE���8�m�grD6`\�i�D����:SC�ш�ǠuQm8R�b���"�g���6��*��RO\�:��VJ������H���p��<Ɲ�D�kTׂk{m�*j� v����7�F���K5j�_���g�M
Q�������O����>]���d�Գ���ޙ��c
����w�M�h9g��Q�o+����� ��Ԭ�:Ba$�.mb^^�v��;����EJ��A�$P�#;BH�׺Qݭ@��5��{�);�������\�l6Q�:}���R��Y�;�ݫ-����T뫆o�؁ͣ~�.������`��J�VBR�}%����f�)pă�ƫ���>���5�?\��	6r�gC{fv���S�!��K���d����dW���1Z����%4�:�t��C���$��p��gG�L���â3bD����&8<Mۙ�.�����S�sD]`u%���n�ia�+ӳ̟��-�-d;�u����\�!�׺���5%�v����>�jmq8c��LN[򴘆�|=�^NPL$gJdla�|�	ְ7$�Ѳ�GA��7�`�X�nq,P�|;�}�4�6}  ��#)v�䵈B�Q�q@ִ�H8Cg��5~y����^ў)F)L�p;b	_:��]'���栭F�
�c~�#�q�:B��l�;ԓ�T@���$ߥ�Do�O�w��cH�=­�p���||�K��GLٸ�d��q�O�P���;˯���7ES~���pՁ\���۰>�U�n>Qq0 -�"ܓ85�����?�-\��z�=]��K�6��D�8����2��hM>����/��.��C� �()��6�YD���:�7ͦO'ljn����u _Q[6�Q�pgK��>F�Z����_	��K1��ED���\����>�TWhcC��=7(�/���8��,J�ҵ�F>q�,L	����8b�p���A� ֶw��kz �YO��ޠ1/��a�W5�{�V��kY
/{xO�湁^��O�lU33j��4�s6�3k;9'�����RϮ�>Ŏ�=d ���c)h��|~�q�jU�"u�*�B`�%mC4+�4է�K�6(.г�Ӊ�j���m6<8F�pS[k+�ۮϔ�j�6uXh�� 6�6ħNS:���,��n�6j�X@�&!Ќ�����Ĩ��s I6��`������*8����k�h�'�����ڍ�p��7iP�(ĖQ��՗T�����[A�j��@�i����m�d��-��4�r%������sj{�r!�����1��nf�n������Y���^�_y�R�W�M�s���j��*������lG9;	�p9m�� dO���N+c�U�97��0�Ñ��rV��'�T�C^b��RHd`f�4�]�6����/�J\�+&��k�]��H~��9U���9�CJ�#�u\�eZ��D�դ1�4�eN]i��*��#�#�����O���-\�a�^9���{���5�q������΄;o60��(K;��/zJ!��|��u�.��Q�ش�c.����+�ݚj ��`�al��7�N��[7R���j��c
v�K}] u�ęܧ���o��U3o�Rg+��{�����;&%�z����Arkx�݁Pb����*���byT�j!H-^Yf� �B���l\NϟoD���h�������Ҭ��EH�\t�$X�UD�d,K���Mf<�R�4@����5��D����n��e�bj�<����C@ o~6�R��Є�:�p��Z�J/�L��x�����%f�t�]'�� ���X�,��v0�Y�'�ve�R����d�������>�I9.X)R�0Gh�R��"�uYx(�X�
�l��Wʋ'bA@j-��ð2)z�n���3��,Bw�s��4�����Lj�VBEC��%�}7���Ά6(PG �#v�mΧ��L�Ύ��7�o"&�J5o��5z?��c�+���X��LQJ�KI\�I^��D�y�1B�/z�7�!��Ƅ�����m�i�do��%D��K� K���,sA���m�bC��5���c%��2�� j��q�HΫ'�\�z�yg׸啈�_�e�+��� �S�f����-�ꮇu�����з��m�:����,�qZ^��xL�
�"�D�w��eu��O/b���3e�C�ɸ����=�-�LX����tc0���b�uJ� ���'8~����|.�*�S?� �''n�C�sO<N���a�ާ)v&o���4^�j��vQ��.�Ǘ>?U��	�"��M��G��,.~�릦���3D�z�~s�R�4K��y�E���l�u�T�%Dch�+U
�?�T�c_k��=U��z�ɾ�a߈>�Eè?�4�d�p�N2l'���@R�gcD����a�,�^iM��H��x��
 ��*�y=*�-�R�;��G��,��v"eR�C��ǝw��i|J�r�R(��N���D,됋� @1�d����.>��c٦��D�K���t(՜a���&��j���e�S�\f���U�v�/q~��|^7�.�y�V��ѾO�T�.X�"��BY�]�<�G��da\*]Oew���Vr�����a�`l1�
�H�Ɵ=�x�.٠c�����#j ���3���|Ct�>���8���鮇��O�5巀V4�`#���0g7z�'%�-+e!=�% �ܩ4K��<n7�iaf"�d'�0�౹�O�eGN�3T��Pk��x�ZJ��0���<��J�� i$�{=|�]piR,�wd�Nj����ކ�Dgn��͏,��枲	%%�z�g��|��M�ky8K�[;*i"��oM�$�_�h�m����g��M�UV`6���w�-�#)gn��1o�ީD#�X�}ٴ�z���٭�n'���~�|.�oS8�nv2�[ϐ��>.f^�¯آe���S3��S��M�輙ϋ��c�#�r�1E���E�y��ԣ����^Y�X#2�0�P*iG5�{��*^\�\B�q��C�miP̸+����@KDa��z�.c�^w����C�Lhle���ؓ�"<�&�LM�$�ڏT]��)`޼����=���NI��,��!�?r��o�a�H�\ljĦ�e�g������p�q�ޡ)c7aP3]�[H��u;�'�����S��`_��|ӭ�:&s����~�|8��4��3� ��Ӎ��b|�WNs��&9Lc�0��J�7�+ ���j-��$eoT�!<m�Ķ%j�K���p ��p@��95�/������C�� �i��-~� �8�5���%9u7�:v�OIC[�1�1�vxt�ѥ��P����l�����6�_5�?��0�^�������̖�}�Y>1j����h��K�D��=����
�e��9.��o���)�1Ԧ�/d�}�¦�.�����	��dF-5V���J�*�p�)��t`�)������/i���F�wܤ����^�.Ɣf]����L`a΅���VƔ͕�ō�}r����#��"Oc�(���lbg��C�˴_�/�M�|�g� "����3�i[J�8)��i��C�A;M�Ըe�M'�7��ܿf�O�жC<��6�a
��+E�<�5Ig�p=��$�h���o\5���k�g��Eh���m�bW��z��/��P�C�^�z�Qց����-H�`&���*4"|�$ы��[V4��j��
?�{��N�q��&r����n����>@s�jV�?�ߒ���ë�]�˜��������F�e�z�
��é��̠]�B����Qj��j9��K�!?շKh��+ �y���b��q���z�ic�I8��m��k���~�8n�[C�V,��C�q�Y=L]�UC�5�|�N�d̈;��Hҧ���r�Uޔҭ�r/7�!E����g)eE\�;�%�N�I���۔{z���?�����7O#�f/WL5-<�y2қ�ѹ!Z7����Mn��U�tOb�@�ZCEp��K�H��G`���t�:�M�$��d/-?�æ#�\��V��{�h�9�t��Ŵ�!��q\��-E�e����{�����GF��۳��Ղ��fF���uW-[DY,��"����n}SQ���7&�}^�=;�6U�z���Le\Mv|�tu'�$w�h�03g��C�U�?3\U����OHM��V�y.�ۘ�W��*�ܤ���~��j|��?���w#���wʡ߷��X
��A���Q�T���p���Yĩc�dRg	#)��2��v�t�������]K%�!�zp��l3��ڄ;��0��/I�Ҫ?�F�X{T�8�wP~P��ږ�XS����4�v%�u[��照3���>�c�?"63��旊t���Q��`1��ؑ}���ԣϗ��·:�k<���c�q>�Z�^�<�,���E���f�-.Z
�:�q���M�m_��n��õ�p��2��7 ���z�	v�[#��y�ķU�I��!�j6 _�q���J"�D����v�p6vt:����`wf�X��;�y��=Ѧ��d�"O>܀eP��:����u�j˹7l6PS����k��zkB��S]ӹDn����&(#C3�7�Q}�� �����7��,���>h���k@�}�����S	]����Q�W_5��Һ��Ɂ��CCm�Ν�h���`��1���HB�!y�E��u��0q��ӧ�R�U��0���D�h�����Λz`ͅoOkJ��^��*�O*[�9X��� �b #U�]|`X��c��7[ͬ�HG����-Ti�p�	�X��{m�Qa�H-�e�대7:��Nt�\���}�,s��vb���Q�>�RL¬��~񺠄L=���Ώb��7���1���m�<�zs#�||��Ԅ�^`���&"��L6�s��fބP��$��Mx��hÎ�����y�Iw_4f�ן\xϽ0��We��o�P���e�9�<L�C�Q������a�%�\��B�N�o��c�~W:��)Ns�r��/�r���0�t?� ua�X{x�_y�ճ�*`�ۙ��N�樝��9�K��ݴ�g7d�<W{r̖���	<IQ��6��Ք��>�UC��ƀ���>�U8�
 1���}�#q|�� ���WL���V^JvaqΓ�����+�1���sx� @�lXh F��
9���=47#���?#}�%�Is)%{>i֢R�|�9G�L���Y"K�2Ǐ��xaOk�'���>�0�n}�]5EӇ��eI���_�v��
�ζʬ%R�T�����-����� ����Q8'��V��#ּ'�����('���v�a�5�v��Q;�}�z���T�綗e'%y�:�5�Q2z��ȞJ�t�p'MYG?��}���tg:�����:3zW1N�)���\��uݣ�^;�칃@��\����C��n6.���+��Es*�'�*C^�w��W
̧�rro��(-�*d�ur�in�H��z(R<8���N�d�7e	Rx)S�L���u�AԴ�X��G��|8��<���Z�!�I ��ƈ�L'Mx�W:�D���:�P�㌚�X�0�K��=�C��'��u92��H��i�Qh��F���T�S�dD��jx�!FΌ<rX��iX��_ء�i?U�T����n`leW�� Y-u�vI�0��I_�������㸁Oo������毧P�F=����[?MO�2��[fr��M�ǌ�%ߴ�	�r�)�!�`t�]�i�QO.U�:�R�"��+�|�2e/���Ұ�ɘ��#Yj�i�(���]j���g��o��c�h�����?�c�c�]{n�h'|�ݧğa�L�K�8�V=`�a�m����-<�݌/�$ch�Ű,��\6jt5�!$��72&� 8�%\Ϻ3oA���P'4߳��Az14m�4���O��\�1���,L�w>����rދr�n���;F�̩PE�<ۧ*��E�?����������	������"��x�_�5�r�M�9[��ZJ����@�v�5�e�o�D�h"�0�԰�$�sW�r����D������MaÍOк��͑p�{�͸M���_��*EF�ꤋ{z	|44��tkh���池+�Ր�ɹ�[ݍ[��&O�N'�T������I�d�Y���woA�2�|��������x1�Y�\C	H-�����m@)?'O|�Pi?�J��VxAsY���#���^?3��%jуj��g��c�p����He@ZIѲ"����� �)�E�_���������찥�[q֎��5E�κr��ȃ��J�}\���q���埬&���. �WZ�ν����]�c�Rd����^�?��"}q�v( l�&��췆�ĕA
��	�W��.�*�R�߳�Lv��M3r�[wWhVz wO���gj}�T�l����i迾���*�W��
L�~���ܞ�bI��/_Ry7�J��Yg��i�E�mф�%jl���y��Z����H�0�ސ��z��u�$RO\՝O��mR�9N|�^��;>�U�������蟼$C���$;��!�6 �L�M��G�@�F̫��!<6T���L���=�`%u�ρ��e`H�'� ���ƅ,N+�]r�m9�����7s4Խ��`�-a&��݈%۝z��+A=Q9�&߈�@�:��ؤ�Fs� i$��'5sm`%B鿲���П|�>�0���F��f]�R���Y�@���S�IY�#YNP�MR>,��*1��3��c����c��4�:Do	P�i�^�}.��/O�E&�>�J��ʀ�$O�j�'�w�ihr@�?�r��HG��f��Q�Oy
 ��B-ņe�Z<��@��y�����������1�su*s� �3�W�OI@6��o��~��|,�&�Dk]���J����~���&��밍=	9��Y�u�eJ�v���*/G��@wailO1o>�n��5ʡ"�U��7�r�
�`m�cSo�����G�Bit��W��!6�Y�׺׌K���A,���!�d�/�,		��0�bT�Q��,٤���O˥�g`���]���@��T��P���W�:T�4�v����z�E�<�G[��vO�+�]ܰm)���]d�� +��� �6��t���OXs��x��p��X�.��&Ak�����Gg+�>q�4�����.ki��l�������^#`<D�  ��ִ��8V�l�\����7֢|Lr�y��zg��~޼s@p�P���=[�L�6טx�ΆF�C_L
1ة�yA�y���OcV�@�@k��IϦ�q~���i�L�Y٤�-�S��ݨ��+ ϋ�~�Ri�*Y�&q�DQ��e���-B��J~�w��x >e+4���������2wbkJ��o���b��������ߋ1���o�>�RJg��fOÚW��S��G�fF�|��n� R�	Y=�^YZk�z�8Ju���p�uHr�Y)�����l��\}�˂Z�g���qc+�=|E�s��"����b����&�ӵ6�1�����;U`:���p�ۻG��A�t�};l.(#�3�[�x�vn��Q<�d������l�]�o��?�������&)�ų�lw�B�!���]C["QG�u)�C��=���r,�h���L�}ֈ�<1U{�JA� ��
֧!�������,�;:
�J��d��T�d-����渵.�Q=n,)a���LS��� h*(zh�N+���O�C�'�\��}���Ɲ;C��(E�/��N�������>"k��m�$��y�Ł�@-z�FQ��Ɵ����Ņ�*\�/E6�gw�~z�]��Cm� C��bSs�f�\k9x���6�]Xrs�!�����xO�Z�,췽�^��^��� �?��a'Zk�_�� ��.��g߬�o+�P��и,v�F{O��������VH�w+77�.�6�"���
�-j�	���Tǵq =L�v����ac��<���ok���) ��T�������~ɷ����d�V'Z��Ν�B7��Q4/�jF��IiF�N�-��q�T�h�s�tY}�`�`��!��;����B����&�o�9�p����������Ĝ�!��Z,�SRݦ7�d�����ۧ6���?�|����S�"���"�MI*�dL�y;2���X�{R�tf���F?��y';��}�U����p���F׸��������y&���?%�#�����߸%��b����d��k!���7l�n!cu)�ޏ*ߞ��U${�*�kYKpfX;�c��R���a2��K�~Sq8�w[��'��V��vQ�5$�y�3��{��Sŋ|� J�&��֘���x>��1�B�pͩc��#&n�/t�\�S�,~�$+��w1�H�/�w6�n�5?�$�@�60k־�D�7��,���}b�Q�J!C�#��D�V��7�׵��R7ۂ�>�\/:����.���ԓZ���?�gC!�b�D-0�:�M��M��|3��J_�傌���e �Xg�hċΒS��t���({�+�*Z:�:w�lT}u��L�kT�)x���W� l7���Y��I����ru�5��m9��|�<]7��"ʟcL�&`=�^$�$訌��f&9�Rנ	�(��1ɒu��|��D]�����\0���`�I}�x���A*���k�6��z�ak�΅�\�k�%"Ccr�����KO�E�J4�4�VBq�P�N����@�0clwʧ7F`U8S�!�mY�{A`B�o�v��5@�\���^�_����������_&n��ך�����Q�5t�!j�?/�D`����l	�B�Sg��=rN5�#;��SG����L��j�8��9zA����tVe��]	���U�1O1�{?SH��#P�u,��1��Z��n̍�����!@4$�)�[$<K_y��a�����<�h��S�s+���mi�o�9����!��z�h�w�6W��^"��ov�D��{��;��$��Z�g��!^�r$T/_$ĥ^�f�c����L������ڸ!�p�Q���}�/�[�_�(n=b46��_���i����Y,z���̕�j_N+�)�XIj�p����>�2լ�7L[���|�IA�}�ם�q$�0g�I�_�j� ��9���&/���C�\ȯ闡I:2�)R<�Xw1�*�cf�eD�r)�����1EF����Ԧu᠐OhF@�c2G !�/��/�om܎��݁�H.N��2��3�S�#��dyp߁���WڡT�\�
6^� ��'�����o�H�Ws����3+�����l%�|�U�L��Q��y����b��3��ڢK+���,��L�JA�^�����A7q�<4Q_l:��ս�z��ǂ�Ds�NX�a�?w���L
��	��i15��@1M�~_�7դ����F+_�2�O٣���ǨT���	�&q��R�ܥ=��(���m5�欕 �\đ"N���3�N$8m��У�L�Y�L�ǜ�6&�a<|%�CX��7�������K: "-�\v�u���3�^D'��1�	��N�<"_�#l�R�2d��E�g�˳�	�u���iߩ@.��ZG�eH��o!����<_�@=1�`�̬4��1ۖ�>n"����j���#��uϋkaQ���>���\��n���l�L��V�K�3uv����y��U�@`��j�:���EOV���F w�B$S}>ιˀݬ\�0��0j���1�Hӡ}8АtD��tW*��)�N�wJ���Vz`�O�W� <�&�
�ꌟ�zY���pGܼ3 3r�Wm:�����'���he6�:(���!�d6�h0�Tl�":E�$>���ȼ����*Er|RM~ ��a��8�f�|�r�'p���A�e�˒��s��آ�����S8q
��.��E��L;�@@<��=mY�)�ub�#J�ye����B�*����whh�+�CP,����J�L�.v/l���h�&��~�R�s�֑ )�}C�^�p��P��ؐ�Tթo�8��,��8�������q�u*7��k��p�>�-�B���8q� Ɍ���F�ѿ�g����鲨�fhb��٬ʢ�[�M��B���k39r�x.GNM����:x��fs����N���P�Ј
�(Qv�h�Ս9��]� K��� cmc64�.z���w��f�-��7R�iB=X������VK9q��U��7�tj�26�u�H*������^����+�yҰ���@�ҫ2�u(~�r{nҕ�y�+hl[eu&�X��� �Q��@�q
9�8Y�m.^<�F���
O�̠�}����7�m���#s�Q����qJ��+��'���ܲw��"F���b:K���Q���҃�Qg`��,Ex�HѹN���#9����*��i� I^O[����%"�\Aʠ����w������Q9���S���zQ>�q��!�R��e����Q��
Ҝ�m��ڠc�hD"=4��Ǫ��:�+�٤g�*G85���=�0�ڞZB����1~������ͤh"q���]Nh���߮�A���m��h^���Q_���{��-�U��˞zB�7v�=BB�R�F-�IK>sW�7,R���� �g���}ܼ�S�nd
�4�Crq��#Wh��y�r�����s�����mm�)���e�kq�M,�x^�h�;ư'�gB9w� �h�\�Tj�(�y.w��n3�p�f������|�5�w/�]X��}{�k� �,<�j��E����j�ٛ�h\�G�jJ��%��9 ���.��_nڻAjB����ڈ�ef��4겧�����קŴ[S=�����fP1qO���ͅ���-"@���]4*Ew�n|�v8m:���z��3�4�'<�%:i9a���Me	��lē%!�i�}�Ԉ���bu������<x�$e�Ũ*P��&�B��g3���)���r4I˨������yIJ�M��B,V���C����rcl԰�:��x;�0J�Y4L�
d�.[%���pqD�����Gc�ؓ�,~n��8��+j�*n�G�w��.jxϝ0~Q�i|�&����V9U��t]p��K�?��o��Co��	*������4� �A��>j~��g<@|�ě���'*s�P	�"���˘�"`t�r�\�s^}��-�"~V��l�5�.��,�NG���17_��t�<�H5�9�A��x�9w6_��N�wݥHbG�r��\~d�E1������^XI��)$��JUe �h��;<�h��[NKFFj�ܫ���QL''��R��G͠'Hd1nM��*�\���a	��䈱4v�S��(�b���e���r%ľ�}��^�͈l�v��OK�I9<�E�����V�3�W���3Ba��1����-��V�qx���D��%>+.��yt���bN�s����w{�j�L��
P$�b�Rli��؂��ˁ�Wu����iI=aV�7Ϯ\B�apu$=[�/���lq�Զ�Z�_�eߓ��=�챃R��_��ѣ�/?)q�<J0���O#���0��p���Y�j5i�j�ǣA$����RD��,���5U������~��EUEw�z��jx�fTBitRP�����̑�uX���0bm���eWs��!W���j���T(�d7[�3���Ǳ\�h�!�$TVe�_ąVV�C��C�쟱FHjx\��O�f�(�}�%<�S�4�}WR|צ���Bl�G���?��U���� ��[�[
B�!Tׇ̽O���s�h�Gw���KG�_Y)�O@�Z���}r8!j� ���l�%�L,Պ�0�3�>O���U`c|\�-_4z����֑�a2H�p�@��R!���W��(j��!c�-���A@
��Uk&7�����ڀ�M��@$J�rN�o�zO�1S~�����k�W�h�ι�-})Tv�Vz�|iv�H^�3�)�fŃ�JH�LZ�L��H@�/?U̚t��JW������� 67�n�����=l�����Rƥ�Sr�HD��� i���e\�r)���3����Ws��BzK�,@]F�P�N�� u��t�_u�|k=���^�{x��"�fI�z/���[6�88m��	MǶ[@Z�!-����� s���$Mz��O.��O��0��������}�I��@�յ��+ڐs���'r�<(�lq�*f�i��/K�3n�f����m��8���$i%��f�+K�(��"�x�,W^˨�|n�w]��*�W����ާ�_�ʪb�Z�?2���H��G����k�awnNQ�l"��5[�Mi���p�R��S������١(fqz_pj0��Y�j���v��ö��d�K{�&�4Þ�{[���˵� �����[X�<�����+?&ܦU�x��k)���mg4d�!�}�ej�-���<�:g�c��B��e�p`�.2�`���諥Io����Bs�J!�3)ں:*W=�a�����IG��(��~2����]�C���E�N!��vP�_�+��H1�[��.M�V�p�*�=�Ю��儷�S�'}(�@�J3,V#r�i�G`�a����EџR�G�wwio�����<�F���'�[1u�}Jb�"TyІ�%h�׉b}���H'�V�N�|c[�=�b�-���3 �MO85ÿbG���ky�|���fdN�	�UH~���k�$ܾ@�n�{��?�^vr�TZ k�h?�N���77��l�Ԝa�㾎�g:Z"(ٕs����VӮ���2���������'��:����?V=�! ����n��y���u�Τ���˺�h��2���ʻ!.&�B��S��G3`���d&�sF[��	�>-�%�=vƏn㏽�n6>�&�=���NǗN\�2�U�t�8a�/����桲g:��qp#��Y�,����qw�� �UV���z¹�Iz���[�R<�!��M�ޣWօ��0�E0$��Z$~��z�.Wܾ�t��VaA��k��u����\�L���H��#���+-�����mn��v�E�Px��Vj��?3[�=`�SYh���ż�q��P��~�k��G��O*F��mE����
aG�ڞrYBpf4$���K�(�ĩ��`a�n�Zv�!
�.�WH���r����z5�S�µ�$G���ev�e�o��O�de�g��B_��M�j)m�Q��X��T!������<�T(pi��x�H"��߾�`��H3V��S�=�D3p��)���J3�q�>l!�뛺5x���AȽ�:=�7����?��\;���Ux��H?�����XY4���E0Ǭ�q���C{�,Ջ/?N�'q`�D��i��kQ�V��m8o��v߯���<���-O�A�U�8�l8bJ�
6\RW�VȠV�}뭕q�<������㍂^��&�&�q܎�]��Bq���f[蓠Q�g#X��+�P����r��$[�_�)�r9���I�YG���.
���j�gD�=����
m��q�P��h�ˑeWj�,���UE�����G<�k��M/,�</^- ",!Di�j'��m�1Gz!�x�o�ʐ�b�/i�ƪ"�!݇�*ME�?�� �:^ND�ٮb�-YD!����|�C�m��B�	2�f����o�l�A��Jh���Ej�4gM���b��y�1Q@P�֏m�AQq��A�q� �PH:!�2q����bZ8�`�,Uu�( �ʱ/|�lR�P��/>|����Ȯp1��{�sM#�!h3?Q��ȭ�i�$�zk*u�
#��Տ_WF�'�� \�����60KQڰVQ�tŪQ���`��g�nR�&�.�ۚ�J�[4Czw�b�Qs�Sհ?�h��x�>A<΀����\%FI�����_7T&����:VĘT1K) &$S�߃b�帍����x'���9�8ο5F�O�I�vo�]���� `�a��z�Q?�HU4&hL�&<�=yAZ�Х��`��s4腪�?4����^׀��'GF�� ����7<VTZ�k�~x����hBa��l�)[�,L���g�� ���O
�l��M�bl���Q���Y�.�Ns-~�ݠO<X�O����I�?Y(͈2������\݃F� 13];���r�|:�ׯ(M�/�[�rB�#�E����*pK"�3pk��]%�k�jm�]�c��}n����������ڳ���*z!���j;�Z��^y��X�$�'�qv��[���e����g1ٷ���s�nu�_�#�%^�o�)������\&X�x���z��U��"ꋷ��bP�� �4���Q��Ʒ�h���ڴ0%j�BO��H�8�Q�(���O�A=D�N���a> ��V��3q潋�
12�$�T��o�b��1�
.�5mn�$�l�	C��N����HM2�'�^�V���G�L,	�����[�4�Ƹ��^5�7���O�σ�F�)s�[uU���Ǡ�n�T�HƠM��J}K_R��u;O���h��1�L.y�z�]�!f�=�M����\�d)��S����bk*���l�x1!�Y����5$坣���k��p1�pn�_ÿȰ`���Ƹ����4|*#C�X�%�#�m�Qx4��崩+~n,v���gpX�� ޕ�B@���?��ٝj���%�w�w��J���ݦ���a���E�3^��q2��G�~֝X�bMrc��IR�0��X��w���Dĥ���CԄ��;'�;��A���롵���������N�SҎ�X�����n`�Ck}�����U7��$V��}|�(�h����B*�g���2��mZ��0��'<L�رߺVHV���|k�Nh:���[���`��W�X	Ȱ63l���������SR�c#Zn2̅M�7��Z��K2�|�ۃ��2�)�#Z��ˢ�P03�ޡwvwÔ)Y�/)����4�����{/i��0|�!�H�`   Hfn���` �����ћ��g�    YZ