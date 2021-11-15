#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2939993549"
MD5="6ba7d055577d75d5057f70c9adf0276b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24844"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Mon Nov 15 02:44:58 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
�7zXZ  �ִF !   �X����`�] �}��1Dd]����P�t�F�U`7Y���%��OUq�WAj�*5�I���n�/�}�u�ߔ�0��CmS^Wb%���{J@�6a�nN:���e����PP�%�ݐAI���zw���M1����/5�'h�{� �tz�'��>/E/5!�\Ē?%# *�N�W|�2�G�,v0�w�&���ǪL!���e�JA��ƪjv;x�f~[�UZD��$��'��!:�
��VFL���aA��m�UT�y_<bP�Zz�p�?���]��ޏ �G�{߉ʀ(UA#�r��I$�H���*�) �k`��T�ɣ�����bgU>R�-��L��z��˵r?��;Ŏ��:�$*a!V���{�U��~Z�s�A�_�X�K���7��,����F��U1r�|`���U��_�����$Q���73
K2����9�xMr��������%��������
 ~�U[�N��f�)�ZY^eT�i�e*���ṛ,��Ǔ��[r=�6`N��Y �#�tO���ʌ]�+���Jԏ�n�6jj5T�}�?x�;.L;�Q�:	:`q2·!���Id�'�d�W�3d��<)j�Q�A�7��a������|���rZ��Ox�-It��]*h������- E������l�k�[�$�a/���da�j��}>;0�ʝ�2 ?N-,� mL=��M"�I�v����z`%7e'�Ə��_���ϻ>�)��y��T8�Y+�9G�s�[DyRI�l�-1G"?|�@
�[&I!b�Ue�ȟbV'�D�½�\�Y�"�"i�8�ƑYO�J�cX֠kx���ZbX���FJ:}��M(E��z��]����(1n�9��82򠽨�K9oR��(�;�4��?t;AM�o�c����ӔȀj�td�ڠ��-�����)����4`���҄�>�*������(۶r?���m����t�ݎ���E������b�O)��/h��%�ܽ�Nb2O|��Br"�)�$:�%�tj{��YRe����k������p�a]�7e�#Z�x�z�h��wf���ܷY)x���gήi�����kf����&?רi�7g�p���������̴_�?a6����f&�8�GO��`�@uW�90��)�wlg�@�a��ax��(���jw��o�i�sh�T�3cg� >�$П,������K��S%���5	U���]��z&�5��`Ws^�e6��(so�)O��h�˚~�DT����0�����x5WS������v` FJO:�B;>����j"4}�xy��<ɒ��3�|�
�D_O�t¹`�����Sǔ|����ṕ�: r�R��� |�;(9��.ė�q'%)�T_D�@O��=���&L8njG�)������_ir��$�J���?�HFT�r�j�w�����8U��H��8QN������5���p�F-k%*�3�!��|{�ns��z��>l̐��0�'\��%��\κ@$��XخLp�d���l�,����� x���D��]�r<[1�أ�ւ�:M���6� S��i�vg��F�mv�î����YY������\1-j?5\���X!�g�Hp̚$�>������k����*:~]�\�]�'_�E�@s��kG3c
��ف�hy/���r�����6g�`�Yn4�r��[�Ԡ;곎���OHZ�D�2��L}P�d����>Z]����.K=�w)��"��Q�_K��=37�nNv���KWM
-g��B��>�����ʕd��1Q=/r��>�8w�dhS����c�G�d7���yLU���><��������+��IЈ����-�	���{��)Q��5[�3ߴ�F$�3�8d��j����.��LEP��%�2��eR�s�฾������H�
��6����R���%��P��-��$q�H��\�SX���s�d�k�h#��Q�rW&�;U؀�����b ��
��F���sH,)\)�H�|1p�q����hr䏧x��?��x�`掦?��5��_k�!ҵq�a+����co�S�[��F@�#�˛y��q�@���W\%IO>�@;Ff��'�@f�\7z�=狄������"y4�C�3/��1�'��ESų��Y���ԉL����U{�X�~�u������.zr� ��ҵ���D��hl>�$��9�]d%��T��7�#:�h������M�Wt�X���׾�BgR�Q�+4��QOg�m��Y11�N���屮�n�Z\��~橪�6�θc� n���s�oA��o>(���/��>s����
��xn�6�d!W!�֨ݧ�3�NT�'�V+���ag�k�clq�9���ƨy~3F��D�؜=w�<�i�4�����`�'�}�%��o۩�ڇ��"M����ݿ��n�F�����t[N��m���)Q[�m5	���B���i۽.�^ߪB5����o�I�G��Q)r����Wy��T2_�_��W������:���CA��P�~_i�,.��Vkڛ�z1�8�PE2 �}����S�vI��	�^S������{��T&��y��&�$���d`;����;8_�Ŭx������AjD��&��E��"��I֟E��6��~�}.��e�4	��n4�����g�(��\(�s��co�3�[���Ӟ8����f7.����qȵ3��K�|%��������4���I�����X���B��%��,=�f4{�I}?�ݪ:�r�(p�o����xòD����@���7�h�L7u�KqMy�5�΍�3��u��Y��C�<�>�@!���}�A�^7��f5��;���4�8~��N�ԓŌ���.Ԛ]�������<9	`���Y��/�h�-�SpmA_mNʞ����sޠu��/풝Hn���1�F����l=���씓��;I�rA�O��Έ��#W�������]�P�I��u�nE�P��rԚ�es�;s0Q8���`3�Q��m����N�-V,،������s�m�����������\�X�R�r�"���Т%�Oc�y~J�ވ��8t�dQ8\��ʬJr(8|*,\��96�%+،1OUO�;���N[�Z��aF@|�B��_dFE��!�T��v�{����4��YN`��7|��k�g�*[J�qN;��:�Q$�ڵd&��u�j]�����O��0���R�3~\�ŶqPyp'"�N>=)]�06jk��b����ڕ�g�4�x�7�2Y��ՔM�k�E��_���:�-����e������g������U�z�,w >�^���:�PFZLc�Z��)=3*c����� AA�XW�E.P;����F��l)��������E���-�Z�?�>}3�/H���6��#�D�Y,�����`Q�0&<���a'�� @�/�t��Bb��Ib#�wfz��hw�!,ɀ�I8�G��پ�g��H_K�s��X>$���.Lm�L��^v��z��y�kͺ/��ͱtVaW��AA� ��3�� ��%����cS�}.�m�QL�G��vD�4�L�b�YP�Yh?k/�6%�,���C�@��l]⾔�����{q
x�}��KI�O1�C�ǥm�8���v!���7!��^�kZ�b���H���9�vw���.Mp�κ�N:>�H٫<�eD�?�GY[��	D�=�rXdY���{Μ�a����uO�����m��P�.�N6����T�T
�9��D�o%�֝���nG�Բ��Ln�X<5�0
�����7�M���3�S�rdb���^��9F�5G�.u_F�9pO�04�>[K�3�r��]�],?���܊:�����	�j�tlSG%��̾iv�>":ޱ�Aᥦ�w
'�@�Wl��8�l���ǰ�TN"F��Q��hQF܆K<��gYZ�)]̩���V�⦎T@�2J���-�2-�UY�����C�VY -�0a��a��,��|���1?�/���ZN�6�@��J�7�c���$v����`̺l+dYF1x�����4U(�����f�Qo���a�*�p�s��7?��Ʀ[Iǝ�R\S�j?��N<ʷ�V�?��k�e���㲃�ן�:ӦS�Q�H����Q�k��nq{	u�}�g��7B&���Z��֚��-��pV�neALet�#wHpҒb�g�o���������:�v�h�p�ܳ��e[oYd9[I���Ĵ@��x�5�8y�����xDL�2bw�p�r1&C!��j����(?|dw��l=�m)O�R��p���)�>1�3º�,�9,��77���ҩ�f�R���������
q�%�S��ѿ~)0L܄+�T����Hq3]�2��̤�!��\����@�=l��֡C���ϷR?��7��)�|�Hܽ��/��e\�;_�t��7�b)���>/���cZ*����~^s�^~��'�-0�p��� }ݘ�X!O�_K��q!�`�k�.M5TUb�H����t++AB�{k �X�Q���Y�L�%��&�4C���>m�p����X�;�2˴� 1��_>|��ͼ��{I#����W�g���u��& :.���aou��Γ�%U��4�1k�zl��%��vs����ȱ��3��Q�>�K�5W�a7��1����_ϻ�����+�r�G��Uw�+��3��8�s�ک%�>�T�7����cO,�Uw�8c5z�����o���;_���FU���9늌SǦ�F%./�[�؄�
~,��ڙ�x:2��!��F��%�X]��dm�ʌ��R��<��|\�űxR���õ����f��+BV+��O�h�z)k�{'B��^��?j�����jq��(<YqC5��#<�z���1�dR�r�i�>uəh�O�
m��R����Q�☁���L�]Æٚ4�Εv��Y[�$:����UJ�@&ŚQj��E��"��|�Pׅi3�x�{���BP���K#h�QN��u #�bg��_���a 6�z:�,uWz#k�78��� �'oA�#wH�h�G��y����S�n��e�� F�lK
�[�?$y}Q]V@%T��
�K�4���Tm8S ���p��V�a9�"�����Lbw��qS�o�ڒ@8`)�ɵT/��%�J�y-(F�"Z)�M�!��UJ�^>���OJ�3$Qܼԕ��e-���W=���DW���d�3����t��G��s"����Jai�v<��LH<�劉��ګ����S�g���T�m�Yt���[Ⱥd6+���(J�] �d�ݥk�.�V���:b}u�Ȍ��S�}#z�${��p&��H��Z��s�aC�����l� .8����v_t�[���m��t��d�d6fo���m]㗥�(�	�h
����R`J}V����)�5�|��n V-��N����A�)v&��ek�QUf���7V��9���t��M�k n6�
�-�� _�-�ɽs�b���#��VQK3۪�;�LT�08�!��%K	�v��'����F(����J�яכU���6��7����Ț
� �V�
���4�F��&yƟ����P�l4[���o=Om�O��Qu)e��4q���&NƋ��R��N�>�&�7�S �]fP�u���;Kxz�T�f���?�#���h�<�64�j�lЮ_EQg�q�5�#Q�٨W�����s�Fe�a�ˀ�L��5�:�� �κ����t�t���a�Hj���G�C!�(ӥĮ�Od�}"���T��{�����s������Kj�P���{�ÀdT��	ʈ��@��r��$lE�3زP�U�ez;�,�@�|*A	������R�8��5�.�v���I�#*���8����Mtn�*��	��[S<����<	@��R���`�e<��GI�������\QYA�|��tSi0��v��K߈v�j�;t�4
C"����$�ʘ�!�OQ�P�����_�M!�G���l���N��+w-��Xl�����fXR�5\C�/�f�'��V	y�̺��}L�tiM�!�����}�ɭ�9�>��{��終��9�m@���/�*@���U+�8��uB�+���$�D"�\��!G�3�y�ܘ�k9��e�2><&�-���>[r@�չNۣ��-r�8N7���� j5m�B��2�5@�uJW���gڳ���6L]�!fTx(�fi[ju(�����_�#�%��"xL��q3B�&f�����1J�4R ��H�k�=vQ��[ %za��	��ƴ�nWÞZ'��q}����;>�Pj��e=��'X=78�bo���30��Ũ_ɼe�'l2��|��\}@�G�5^�Z���'��o�]������:�Áf�:�D1
Z5���1����}�*����A����%Œ��S	�om�)�(i+k����?!� aW���+��!AR��h��� <5#YT����R�`wi�r[�}�(H+�[��z}�d�X�W&0���]`{�>�*�kk)gR�Q�}��E6��x+A"�B�0�쐟 ѧv�z���j�jΘ�F=��doD�����y��h�*g�f0�t���~��dN��:���t�b�~�+��{���0zGrB�\��3��a�m[��'׶����Ow}�<As��*����r!�����Hwo��21����8�Ë���o�g�\-p ��b-:(�?5D��j	���.���<�B�t+-�PC��*\e 4^�[��WK=�����1�z��Ʋ���>�92����D�I\�_= ��d����ZJ��'ZP�t�)$�u��
�Y�|'�x!��Ք�^���-⺆��0�w�qe�����.��5j��gU�'bZ@���s��O|#)�}�9]b����9w�*L�~��o@�,��zP ���v��|���n�
["p��u|�ذ7A�^��M��n�r�f�[��0`�ТO����v��W�hO;b�.�>�8����Ц?�*�1p/p���ݏ�]�����:p-��K	uc�w�W�I'��5��G��m��R:�2�.N
M��f|Cb�[8�X���XQ,���W0g--��%O���~Ʉ[&���T\1�@d��V� uW�>�1�u8�	Z���P��G3g�(�-a��:{�+:��쇐���2�Ƣm�R��m���%c1�F�EI��L�zWAk�3��V�v���E�I�HqZ��4�����k����E�˜
�K;I�G��H<��7�Tn�bo�K�h(�jf2IC��Z,��_�W�ˡ�F���d����<��rc\L��`�@�Ӎ�:Fy\�'򫜫n0�U�,dg��X:-��S.]>�׉��LWh���0ê�l�IEfZLm��
XX�C�Bo���=�Q$Ԗ)�q��K���#.�&���DY����>ᓈb���^��A��JV������RdJ�0�~�E�r%K�~��}|
*r��n7�027^9ZL������#�D��E��@a�`�soF'P������N���ހ�78��H�����sV���.U$���M�D>i���8W'���oOt�.P Cl�#�[��xʕ�k+�������]�x�u�\i�F�� �?��Ӕ�5`ݸ�Ƴ�\���:�A(BXB��_�z�rT$)��>%�:3b~W���QR��o�m�W�K�	r��A_u�/Zw�ZF�9���7��|(��=�Ѽ�q���!x�$���hZ^��s�������'P�q��@e\ּ<|4�D1>:3�9KOE?&D];��k�RO��~I�uʾ��������(O_�)%��<��R#�?bV½�56,>y�ނ�+�Cq)1�9PF����\d���Q�u�Q�γ3��S*�4zM$+��	�%A'��3��F����҇Tn���
�LsM��u�(G�����K��w�Γ��g������;�7��F�BMYF��6��h���y�W]�A$?ń�`F�y'gKcu,l<�i�YdRȣ[�3�{�T�4�sBCt���)iΆ3jߟnz��
q6����W<F8L�����}q/nkV����Ʊ�]̫`�b-��?/���Ғџ����=�W���aH����~&\����1��!���X=�z^B�6ÚQ����x���5��1yW�?��Ky�^�����~��x!y�ߌkRz���mZ�'.�-j��י�<Ps���G���F��͔	]��֝5�U��A��	bU�ގO7C�(@ʳ���*�{b���%/���â,;�ʯ�8y�\���� K���ߟu���ˬ��+��M�CH�y[e�iQ�v��xSz��ܪA�@�=�hH��f �����s.b�	6@#8"�3?	-Ϙ?�<�o·�@Z#�R�̏UM/�j��S[�|c�ϛ�e'�s�?}�kp%y�,�����yR)��dtߖ �iQ��
����*��;U}���2���TL�
-#v��E{�Qw�е�x��' ̩��ܚ)�T����đw�M�"N?s߽%�[?O����G[�L�;�W�� ��9yʛ�n� ئ�G~��&�����Ŋ܄�v��ъ�=Wj�H�D�^�5Q�����ExC�o@Ϥac��u��cr7Y��y�N�p�Jx�=ټ��iA�f�V���K;)�#��:ɮn09��p��s��i�'u�4=G*vT������Hz�z���g'k�SA���^V�-��f7�{t���}\S�Q��1�**�Q��]<������zO|��2�k�~�#��*�/,�Tx�HY��ҍ���p9ju3����]q�����KuG�\]�>NBAb.e�~9V=P���E���={���h�)zS���{stx!5��.�!ʉˏ�*𔃑ك�|F1* љ:n�3�I���z��u ��d��r;��=��8����~�Û#�\
�]4?ğ@S}2����¾*��1���~K^e�mn"��)�]G� �lC��9ttޑ�ŉ�-���kF������;�����ܥ�����If��3�ߴC0M*��+Ox7��x���ە2�NHT�j�ԍ�i1:�r
�7�P�����$�)a���]�ye?$�|m�?u3�b���+g]=���oa(k���O9�S[C*x�P�c�d��á��"���+W!}g�����a��}���ԋxoV?y���5(�{A�"��s?'��W�S��2� �NMzf�-�K�4 1+�%�Ni`9hX|�/��{���+HK &����lb�J�������XcY�����/]�حƂ�С9��]�A�Qg�xc�
�_�}q��ȍd�-�� g����Z�4T 6�Z_�� ��iiZM�o��A�]0���y4Q�!J3󤄼(�^��T� I`,/GE׫ ���I������SG��xt�;�N��L�"�@P��� �*&��ӓ���oX%WeR^S��<��\CTt��͓��قET'���,>��w�"�;�Hִ�y�[����l�zH�UǏ��+S}�`��C�p�ZQ��'�-J�I@����n�1��s�|��RL���y����.�V6�ߎ�G�K�����A�R���,]_iv\CPr�`�X���}�[[�����v��P���n^M���r�
"R�MH�{�^f�8=����ӱ�[��O�"���w`^t1_���F�o[}�9�ܙe7ܺI�ß��CG(����T:����n�����`�,<��1�\��5'9v룊��bݲÓ��g�x��lr*��M$�[ N���P���U�D"�8c����t�)����T˚���~:;�����Z\b7�W�����ˉ@�p�@?t�Zxe����p͙F��ӈ���
�m���L��=�7C������Z��hQ�>ʫ��wh1.�Q+eq|@kֺ9d �������dj��]�3H.D�z\N�h�l���\�H��nm�Ku8��hG�3�X׈��6W�����"ç��Y����6�#l^��3RV+�"�$�J��X��	׵�� ���������V����,-��R���=j���ξ= �.j�ɶ��̰(0>�Ƌ���['E���~q��s����硣U�c]������
V;F[-�%�����k�Ӿ��Ȍ�i�zi�P,yI�h\v�8�M�		����X�AL��\�.�k}#���>�����"�"�!����b�q�� 3���Og�!�lkT�sy��֦x!�����=�9"l�Zg��e(W��0��7�k�/{�c{*]nhp���^7���NM1}��赋u��mn���1܃��\�'�[Tǣs���a1^R�C�6!A�zOS9�!�L���;�r@f��#���xڻ B�����4,�(+�b4��w�-�n^�7NLT��`��g��봃�tmH/����8��#ĉ�%����'�񲆼kr��C������]��-��ٝ5��Y3KTi�UxR2(J[e�D23 j|�`���Z�V4���ߍ���������Y��ųg5��PﾇT����#N^����L�,l͍��-_��|;Ro�\_�s*��s<�Y��!ҘEC`�8�S�]���'�Jd�5������Ma-xT��F�l���A���ի��\�r[Ua�����|�����[�����?�g2I��i�Ҩ�=�a��V��3��#gj���s�-p�^<|l9ۮ��	"Z�ƫ���L���1���!H��t]�F�i� ������g5c�_�t�@s���+D���"}\�a��\t�x���(ԛ+VH���W�GL9�q�'=f���v�$�o�����"����]��ԋ�m��y��Kq��1[��6:^�k�	DP������;3:�(c�u���w��`�'1��N`>�X�m����+����u�oK_&W�[�xRC�����f�cG�q���Ļz�4b	�A�:��j0��e9�������z��"3O�40��:0���R��g��Û�k��d��L���.m%� az·E2���v���~R@�˔»}�gB8l%�{`E-�ֈ��4���Y+{�<������w�=��!̺̓4�39I����3:�x4�C,�UͰ0����~|^�~{йˇ2�f8�[=��9�tu!��/J�֥I.�# �o�pH��X�7�	ec�D�Ph�Ϻr�J�ؖ�m]^W:�؎!7�9%1�+r�jF��y�)�8]{
cvϏ	V_=:�x%�����]֭w����gz��tJ{���f��L�kn��?o�ћk�7�Rΐ��}d�,�\YģI�X(W���"�n|���3�5��6V��s��mX�F�]��&B�8B���b��
�Gl�`��b7�v'�5�Vq9of�i�煡 �[�k�bk¬��'@ �P��,�,>횚矆��F��1+)t��-�B	|�;��}�M,\�|�-=��0���rd�Œs,�UW����qo(�y8c�w	�Bظ�PX��q-��v��0/MFS���Mru���Y��dOق{��ߖ�G����)c�!��m��{���&
L�c�/�-q�f�p��*�pb���B4m�5Q�.b>N?�Z��8}�{�R�q1���s�X��#Q�ă}�Z=�=���I(��N�Ӏ�<�{@%DF���(�Z����x�(���a��Un�~C�)��^Dd9�m���Ui�۶l���[��&��%�#)g�¥K՝�ap��Ms�D��^��A�B��oٰ��r�R=�*���U.ד����v��0KY�L�g����Ǚ��>�ћ��䣕�?����Г�>S�!	��)�(��!=�e���I�U����7]��pU����EX|W�*�T	i!�Fg7V��0�sGfI|��xVDw�9�/\�[�6sQ
\�ؚ�������[^�$i����	՜޾/u�b
J׋��E�JC���˪t �>�i^ �A�'�l.�}v�8E��5��WwSWS��69�!�x�r8���n 9}d�b�%�,������o\K�����,A�>A.�\|�p��)���r�#�w9�#�ʺk�gVѾ�qV�S����/	��GA�[�`��=c2i�X�������K	掚xg���BV�nr�����-�Zΰ����,�:�Ġ�$p�w��J�����m,�;ؤ��Z�0W���l�;u�\��hU��h\�VԷ��T��/���θط�c ���W�:7_�at�&�: C}��D��{.���F��6c.�4<ߢ�>|\$,bT0iey@̂���;oҐ��{ިZ��B��(G�z�}̙hU��S�Y��mc��]ua�'����H�Wd��(�I!V��H_SI��[�g�1ƣ��F���*��'�>�.�:�P�	;�аE�|�F�j ���.�uӼ��Fw���䛐�/���]`e�"
Z�i7���p�~����G]���[�c�h��Qʪ�hb�L��l��=o�D�f����u�]��+K5e���ߤo$�������[{����?��݇l�q�`�+b�_}�'䇨c(���T�?4��ȯǯ�w�� �L�U�� g=y\���$��"��1m����[��{��;̎F����`����"��h����rį_��c���wx�����.��"���U��,\̀Dy�6����-�+���PN��DE�kpW���0�A�2X�<q�X��94A�RC� K�䲨���l��52�J��Zv��z{=
�����w�b���<>����HNР���R޳����=�+�y�z�a�13�V����TU�P���:tU �,��!�NPZz����4�AZ���3K)����e*&t7�`�^���a&Ο���-O-M��zu ]�*%(U 0 �ߋ��Ŕ7�����t/ܨ��"�Y�jֆ��1O����o�}��#�dTsY�Ǣ{$U/��6<S�c��^���<X�x5Hc��h<�������++[ �hE�ֆ�S��<��L4�3�Dl`�x�z��t�r�C������Ccg1xA��-V?�<I����͜|?�M����j@3�Q�"���`B��͆�k�Y/0$due ��o�Ԃ�U�E[�F����&�'U����L�3��]���_�;�%_	���F��|��@C��OF�숸PĘa�a皂�UB��׼����������Dx -o����s.\);]�^�̌X���hmu�s�%Nߩ��{2yAY��LI,'���� xn���j�#�v1�[T_�ut7�q(lN�����/��)�R"EY�/\jbq^*ٓXkC�E���Q����-����T�,o�t'��Kk��۩*P��V`���^&@�3as��v����?;!
��zw����ҙMS�0�p�?2�B�ʰ��ȅ�2
|frAk����Y�n$���)&�z
��Sblh1�W1�%�;A��_�o�c.�R_}\�~���<������n��4��M�~����T|���&�="p��$�$�K ��ь)�ϸK�ǋ�I��������Z�m��WH��۩�	ex+Vܭ=�����-��f[��%����6U�S�k��N��CJa���By��H��=�ґ�йъ/;��ј��y��E#�b=a��|$z��R��P�������|�˱>	n�3�.>��Ge�a���Rk� �~��ԙ �1g�����$���\2��e?Y"Q��QjG��5v ?��G
�s*w�?N>�+,�]f�߽�/��R�mQ6hJ��X�ʊ(���oF33�AŞ>~���?��h|��}�y�N7I���yCVbrvo��'���i?��%�<��4i�DH�'h��-���r�G�uE�z���{P̓8�� 0����icm`�R��Q�[�Ǵ�Ⱥ}��
ښ�٧Zv�T�[�Y��G0�!*��w��g���8'�[��=���`�Ŝ���L��"��HɃ�- �@)�ty���8�#7�'�ȣ�넚����G��c���=�M����;�؟���Ԓz�Kf�"�!��~���h�!�Pbd�᭪g�@���dH�%Y,^�&5@YH/Z���z�y���Q�#��޴a���Ui�pt���	i���=1Gb_�~�(Ծ�%�L\R�͔�)[�F�6yn�Ү�]��l�m�>S��H�׿i�g��$����#2�@�D>N�B�7�t�����B��n~�K���{-*�ۜ�@{ᴺ��4T���7�Q1<��3�돛�������7�+����2��;
k�܉�'��M�|�s�^��53�n�L*�o� {j��[Q2��"0^���_q�N�"��7]�oI>������m����8w�g?�Nz�;��aVR]��=-P���bĩI�Q3Z��S� �:��G��ݼ���+���O�jŮZ q�e��MT~�yV�W_�4���Ī��G'�GO�p���~�gMN���n�c�#�9N��aWg�=����D�H�$_�^]�kd�i�����a^��!�Z���Aǟ�	�x?�����4��z�%�r��Qm�C�`/��Q�V�O��N��e�M�&G.='9���@ll�Ů��d{�M7 PO;C���1 *�|>5�ڡqL�%��Z��T�N��laM��m��1o���?�:����_�sY RLMS8���#�K�T\�W�3�q��_NH#��8��[k��X�*V�ڋw������`�s/�x�^�dL���3��ͧ
!V��F\��F���Y>�� ^����r�O�M�;1�;�V��h(d���w0��2�"��>���m�5��N5��QvP �X�w�����q"�g��ߋy��h)�d��~pI�a,����	[+F��Q�V;H!�����=�|�}ƻ{c+0���Z-%�Fx�ې�Ȃ���맰�����sZ&J�  �?1u�����+��ik\�W��v��^p��t��FA+q�2>�(=�EQo$v�}�gP&�"xO�zx*�6_���Ћ̊
j?��1��#�UN�i漌CG�K�SC�72Z�ێJI%!+��R�C�z�q��'���4x�~��K%�-�S� iGtΟ( 6ǋ��-��WboM&@�π�����V}a�=�vV�\�gG��0�GOr�xM7�G�)���4# �2~�1eʐ���?"Jrm��Q����^,1�G[Y�0px���K�|MK=��^.V��7LԿq�RN��#f?*��S�|�
��4�l� +�y����.
*[7m��(�/�����dّ�K��
�d̠�Pi������M��}���*�b��`D��y5
��3�m�� u�����&��� ^��r���)n�MVxu� ��X0n  �u�UK�5�k@T!�FE�>wxj�U}���R�~���N����mR��_#�cl?H�{�����[B�uZ��v��$@o�� ���xl>Δ-�Y�|_��vv�������ZX'J<�s�<�B���L��u󨶗2��0�w��؅7�����[CRب�]��C��=��� �ӵ����΁���ED�^�V�q�QQ��V����"M�A\�@��M7�!��T|�r~��N�PQ��tk��Ĵ�V�S��\7TA^1@�8�5ԟN�v�F�iLI�����Љ�/UM�(]�WY|4z�?�ފ���_P��{Eu!�/�dn A�飊��
v�2h>�Y��J���p_��y�����G��p[P�?�H3�л	����E��ժKZF�1�A��¤ڱ�؞m\���?�0�@��8��s{{�w>%dzN%�(l�Qf��=�P��#�(���v����C5WH$ �iiBP�=lx��-��������$�ĶoQ`��@��ϱH���S��N˜�So�ٽ�9�h�Z���ҵc=��T�c�����ѧJ�y��l����c����H'>��_/��Vf�=G���W��w3�}{��m����6�wKt@���!F�{������<�v9&]!`ZL�Rܼ �H��mO�}PXQ�Zx�a��
ٰ�+D���3�B">̓���%�\L�Ҏ~�c�\�62��`�ۨ���7��>�D��f�7��_	�W���c�m�h�e��R��-d��� �i���̖q+�T�̵�a�Ӡ�̋����,���UN)����=���{�U����7!!P|���f9v �T&�A�ַy���9���A���~R���!xܕ�o�gͷ�E��s��Ԕ\ĆJ�֥�G�P��4
v*��E�����T�ݐ (�n�Z��# �w6�H�{����zҩ�2Ҳ�?eB����"��J?�-�	�M� B+��F'p�P�ЉޕĿS�	H˼���'g.��J��-�O�:�'VR�-
�-�0�Γ�])�F����%@$4�[�D9"�Q�!y9�J2�,$���\� �"�Jo�U�/��?E�n9cIդ%�|7>o!b건}M&x�����X���_�,�&{,����py�aOv� /�B9��)���!�vVﳁ)�3?�G�k�C�P����
���eG��D7,!$�͘Co ��<�� q���Nkpv$�����b
~�R8(t?��@�9���� ����@�q>��$�)QYB�д� ���21�_�o���Lu��rcJ&����*S�)2�,�yH
�ޡI}��Ό�Il��	Ј��2�N|+���1���^�2@������p�#�F<��I!��a\\z!��������+�4~��2bW��՛��ۜ!$ �/���k��dGp������%vk5`��x��C�,eo<9�������|���K;P�jt���_���|�n���8�[C�$ON���<�b(e��6
�v�xzI/��l@|�ϭ�뭛Ȫ�����a�-��o�,&CV�N�&/y���Yt[Hj�
;8�)���3f���_��A󮰱e\q�	Q	߶�r�F6�
�~�[�fxB��M�����5���.j�{ѽ�y�#;��}O�W��Ŧ=H���6�&ץ{l�3�w��c��pe�{��Q�Ǿ���X����ZU�*��9������i'�FhG�m2�L:TB^%$�����l���{�ۉM���u�3t�U�_q��NV򨑗Db�d��%�AOK����2���3�t���m��� �~��0Q�ʮM��DO�c[�<܋$8@|��6D�gH��%WI��v+5���5�%6�aG�Ŋͼ���YQw�.�L0�*�W�mrU��x�w�/�)��W�����Y�m��s�.G%EQ���RME��2@�wQ��/���5��B3|sk}���XN���Z�G�3�N�S2�@|�;IB���*��r�8�\�<�.F��G.���P��Q�R �
�A'л��F�O��#�\��c7-�w�
|P��p���sLba�s�Y��d�4�j7��^�<��9Qj��G	�A��t���H.���������M�:dM$Mx��WױW���'�]-�k�'�yf{��t�0B�=��2v�����<�)���o����"8D@C�ؖ:����@���q�d�	G��ȹ���2@�ޑ��&�@�-/������d,ͦ%N m���w3k�� �S��4::Mit�g������_͢�Ӳ �1@������<q�[�8*)3�=�EI���~���(�#����Ԗ�2��B(W<��A�f��+��q�)ë�l���uwe��*1���Ŋ���J�s��~���xA�:�� �ׯR�,\*M�i<c��J@�g�}6�r�-��7��&�.���~��]�9�&�1;����7݌,�y��o�"��=v���C�����m��VS�����k�ِ��e�݆�G��.���[��vK� 	����^\�@8��8=\`5�%u;�r~���=4k���9�|A[���TQ�ǥi"|����zt��������!���Y��R�f�"�DM�G�?��&x�ah-#O_X~5Ϫc�:җ8�F��	�+���&B1���VZ��M�+Y�ZQ��G��
�G ��v=	~=	aW��(�xwA,�?�����|Ѐע��,�p����3�I����.Ӛq��)�yo.qfȰZs[�M�D�/`׼����* ����VWfG��ԧ����ou���Ŀ��g����*ri �h�,�W����0�$�J�F8��;���ܶ�l�e��2ގ�H����QЗ$6~�Y�(UNUb�swh�op��?{"G�6x��Օ��!��uVz�
�@��*=�����}*�L�B�_o��3��x��X��bO�~�	��c�����fRzΥN�
����yx����vC�ܪ=��э��<��& g|������K|u�w��_�MT{�,��'��[h��fX�0F���Nnm6�fEPsi��[���cn$�,����]� 0�^�FΧz�̌�@C]��*�x�`�k�,b����;
�<��H��O���\��`���wav�<C@�tMc!�����X��lg�+N#���h�${͢N�7���k�itF�b�(����H�%�e��J��t'dhT���+�+ꈫ�W�}IVS�ZM���܂��ae�+��wFDL�+�3{��Xؓ$`ǀ�芤�N����-؎�lQ�W�<j��|T�ı�s7����}?!ō�\�p�C̻A�z���_��g.z����Q��E��U�K�����4�xo���'V�@� ��k���G�!�����[�ڸGPM`��;X@���	9�V<cf-�W�F�����3��U��&���JGI����Vt����q#�O��i�v�c����[k�l<.��Wb�����֊�Q�WQm�~�Q�Η{0���L�פ(f�S��!��BA����'4�J�`H�4����re�u&a�e��vWmM-�'�����?lp�s�,���$(�B������{��o�2�+���ƹ�Ewr~�p�>�Zm��T{תi��0!͖F2�X��r�e�$�����J��a��?�O���*�2�߅ӣ6�йd���!�M��j���ء�򖝖�� ,���U�a�W�Pz��z�g��/�׻�����$?u���8���+5{Aը��4���� �U�v�;�p���0�>�B�7,�r<�O���I`�>B��+�uJ����oǣ��lg��K~��5�6���jy0��G�.��h�f9_�����z���k  �W���Cq���R,xN ���B�E�����LK���Hc�2I�U�mИ�p�3��MX�����YvS�!�X��z�<R\Ue�Т\6�/�1�^��~~�	t�F�4'�Gd�K�^_۹*�YD[,Z4MU�a�I�h�,lȝ*�gΧ��cj��B=t1������j��=���x�2"�C�oAu|����to$[��P]��1����a�D��I�*���ˊ@5^���(����m�b�����Y����\�m���R�G�jI���䆪�<�s�Ժ�C�V����5z�2, 	���ٜ�փ=>��$�d�@�<ړ�#s���g����Y��U���;' �͕\2+�#�u_�-%#X!�വ?&0 �6b��CT-g������~}�Fj*%��u����?��^�2��K�C���:s�*<�����	K)AY�����8���0�8�W�,�n�`Ws;�<�v1�(�'�lA�Ǥ�^r0�G�ť�*?�5���ԃ��l�Z�sii�Y�)�ln���k�K��R����?�q
��Ò���r��'�
�tw}c��z�� �xT����ugJD�-C���i�}5��E�ߖoh>P��9i�C$P7n��FF �b�ј�1;��Y��׮V�����~�����)������k�z�ӿ�J(r��at�:]zܞr������bҌ�vn�����1El׻	�sv�Iu|�s��F���Tń�ݢ�w��jj	�Y��p�;��׶+���)����+�d���r�b\��I��X��p��^��s�^Mv�6?4�8r�K�%z�Ogs��|��A;��\1�j��� >�Q1!Q���pdw�<�-��:�%�1%wS�S�f���lv�$��~+��&[
˗����X�����Y?v���� u�sF��&�-J�$c��І~����&��Po�D#�대�]��+���
�]/�."�B}��QH�.x�4J���j�*кhab(�Ge+���~��`_y�}��Bԭ3�cբm�����|����&Gt90���} ��}�§�Z%yy��C��]�{�����e�DÑ‽�����r,G�u۝|g�1S��>�An$c<%�\�AOze��N��s]�P*:\�]���y�BKR���W��ф��?�s��ՊO_�ĆcU۴<	�8���۳�}��b+aP
�"Ք��M�XRaLx����1�%b4����{�t��8N���?1������~�!�VM���w�w4: ݶ��12�Y���T(��- s'�l���])`T�r�]��˔���l���FՅ)���y7�0�<�q�B5���:L��w��t�ވ���� ����'�+�E���vfs�!� R�Ͱ����]�[#���
e�q,���߅��u�����F*�s�>��p���>�eE��Q�C�d�)x���O�p���2}���2ɚ��~�z�1��`�(8�׿lJ 8G[G4\�?�������M0'��XT�(�|�h���%�7��;G�5����-r�h�BY2���yѨh���l"NC|lP��Jt�h'6�b�H�f9T���H0~��B_���T+�:}>r�71/Q�)���q<ܻ��*��Wt��-W�zn沯o.�n� ϖ-�����R��4���{���_�_i*� .�hI[��~�̐>VǞ��gv��?
�)$p,�;���ޚ^a���|5)�B�[�1�q(�>kh+�t��2���	V�,�w@��h�.�F�Puavl�^r�p��7�5z���1�#��O���[�(�-@��\M�zx�u�AT@N�#��7����P�R���������*༢:���௥��/��~@�L����T3�S��|85��n����R	56���Ǔj���M���M$l�Zw��-9 �s�w��̤�h��e�{k*�o�"7p8�� ��M�8���̡t�`���(�id� �4!��-�=��}�����\��,���ԦNU�`��!ݰ�p(:��-,����눫�,�kS+j?��+\�Fs{wu򓩭dF�-���6�{a��(~�/��w���ʽ���HZ�"?���#q�r�2KMJƾ��ΰV�U�
��D�����y�R���8�S{��:��pU�=# u��T��"�O`D�ަ��%w��UtS ����X��9�7�W���������?2o(�'�!��G����������0���Û��g�C���	�̕[8o��\^��Dҩ��-����Z:�Y��@8g�.R
���N�PRH��̜Y��tVBi��S�cJ�Ib���t��F�CkX�Ģ�2*d�K�核��_+]���T��I�]e�(^���hB	�����s.�:��a`�Qmc���g1����s�F@�f�D�>�p�B�X{��,F��"v.9.&�
��(���+�'�3p(���d�k:>E��
���'d'y�G�(����Vzt,i.�
xs2ɯNVr����d��Oy�9dGh��G��$#��H�mZ�U�eV��?b���7�n���Hʏ����9�d6�p��zCM��,�c��M��q��5��"���X��pw�[)g��"]1�I��9���������|6�Y�f����1��9��k|o&�_���8��+ѧ-�Uľ���(�*����&���"�6�y�
O.�!M��G(��ޢ�ԥ\�j�"�f�n�pU`u�]�TC&�ϼ�����,=&�'H���>z����X*��E{�qkW��S4z ���ù�M����dl�$�8��UZm%D���8WE}Wz�4�X�;���Ta��q���V]1~v�z�WZ�����..�
4�{)�T��-������SwQ�&�B/j?a[��D�yj�&]�(0v���#T��
���;�e����R�j:_L�)��+>�SU�W7Ώ9��2R�]�����9�4]�~Y�q
{G��ፚOx��z"{���!�8G�H�v��rč��Y[�R��p����!���+y>r@�w��^G7	|`����Z��0��φQ�|(��s�xш�)_�ݭ¨���ޛ�4���H���B�g(�a�uXgi~*�����i<Âp��+�^�9�U�K��>v�X2/�����i=8�s�E&��f>�'�{k+bB��YIx��� d+�����ÿ}YL� Х�۴R��Ǥ��_5�.�Gϱ���'�% P Z�s����P�������J!�k��ƙ`aၟ��_y�v&\�b#�X0�� ������I�f��i�'��iRX�����A��/��k��/�9�	���y�����W�Ĭy0���C����xI��3�D��SK^^�F����|���b��v���ֵ/���4�B�F-�Ŷ��릢V�g&��Ϣ��ﺊ~��<cȅ�B�-Xz7�[+��'�+�F�;>�z�8D�ǹ�=�韄/9�6[�1��$����_��] � ���g�I�}W���g_A�N�Wt�� �5C���Qc�ߡ����� �xi�8�5-���
�8R����.�'k(i�f���K��X �[;����v�nx�)�͡�;��Ń�ߜ�,4;X�efʫ��ޒp\H��~.�3�+�n���2o��
� 2L���ۂx_�����`b��5��=ej�G�=�SԹ|��v���*�G��#����s���i5��%�P,e��w���ه
�L��0�;��C&<Ervˍ�M�Q�g���~@�}@N ��`�6���,Y���k1����[�7�B�Ts�>��+hY�aL3O%�^׈�-����u�1���v?��co����M=Ϗ����7���W!'�r����n��sT%D4�f(C�.-h������ u4 "��=n�5�1P}c�����A�7�e�*���/A��,�Qr��G	ʭc�n�&%&˞$�ѾzGxt����z|��l��hǡݵ���2s�w)_S1����|��.]6`6�ъ#
�N�F�zOC0#]��'���v�qd� �!{�m�í�`U/�@~�W�b%�N��� ��ƀ踃�$�藋����=�jf���}�G���M�d�C'آ�a�7 $ޯ:6��4O<���Ѱ obj9=�;V���o����eK}*A�S��?�1
X-"r]>J-�N�����J���� �p�BeT?�����i�0�qϛ��'�tVȘ�ަ��UV�ULZ"��Y�@�N��m@>��'b���ca�\>=�<�����X��l�����j"�D>PuA��8'�i� 1	4Rx���g���9N�� I�خ���v�۲�(Я�.x�r�lL60��⊎� �-Ϭ �Ք�-ܱ�qA��T��۲�$��8H~�o�N}n��-���3q+��[��(�k�8ag� ��#��W�Z(]E����O6B|�y�h��Aǌ����+9]  u�d���l��>fZ���&p�)����_��.�K����+�{@��{�;��j��4�qf��^G�8�3� )�/��E,�t�� �-���m�٬4�>{��������Gߩ]nH�=�ף�iM{8v�K�V��1��4������)M��;x�]Z\b��a�������_��}����1�y�aa� ��>~uY?�I��磔ڒ���ނx��RT�Pn���.�Õ��_�N��}�]��S���>{��Y�v���s:T<�U^B-�R�-��袀�<�l��u�9]�J��Q�ʻ	kW0�d?��0�mK(�?\�O���na�8kR�E�s��绊����`�Ǳo��]��cÝwk#����k�_#�4��YDH`~� y��ࢵVj�Ov�F`� �m�y"\̖l�ֿ��0VI��Z�)t|�-�����ޣ�8-�G�4���[&L�rN^�3��K�r�śx�b�{��z6c
mU��]�ѹ�5� �$3�`4�v�VyQۍ��W�����KW6��B��.jm���� }�v�AAD�s��8�y��0�����sz��Ҏ��L�%G�A��DH�@��~Eŵ�Z���c���j���s�F��a7! VM۽x,Acҩ������)X:��g�A��,U�:�w8��B��8 ��)գЬ ����Q� ��g�    YZ