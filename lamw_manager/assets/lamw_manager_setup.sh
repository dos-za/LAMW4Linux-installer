#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1734383159"
MD5="4ab9d467156e3bfe180848648bc32c9b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23260"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Sun Sep 12 18:18:50 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
�7zXZ  �ִF !   �X���Z�] �}��1Dd]����P�t�D�G�.:1X���d��_<Q��?�����f�7��-Rf8Ӄ(��;�`�-��S����(U�}_FϞ�&���.��1-@�N�0aq\�./#+��E��-��%�'H��Z��Wb~c��Qxl6'ٖ���rLc�n�.�hx�݈E}��(:�2��?W䒫�Rȵ�r�$��m�p������F5m<)����!'^v_XA�c�������r�3���#n�I������׫j�OO�?����g�}��Ga�S@9���������� ��yFj>��g�cu�a��3 P�Z���wb=i�/cqv��U�Vw��L��	�	;��,����p%5�R�n��ǘ`��SF�MAn0�������Oa����Ώ�$	���=��W-��[��X�q�U������A�O�����A/��}�i=��(p��Ҵ�<��RJ�?��F����.(e��Y�l�pm�>̊���gb�h�u�L���ߴ��8��Z�	�S�7}���T
��"f(N����R]Ӆn���m�5 ��������X��b�X�B-��qQN��,y�����C���l��=޸zA_N��֖|�
�������v����N��<�x���Y���� ���2��OB5�R2y��S^�J�6�r[��	�1����%� Znf�
t��ۉ������ ԗ�Y>l-�#�:Ps�6� ��P�,�Í��I�sS��<�O6n�7��k���6�4�uU� ��J87�G�8Zn�>�f��E���In�ї���>Q2�ij��5e�82����U��}�g,��gu�&zh%�Cfc4���r�8��c/��q�]���}���7y�����~Z�3lM���^���/fO-yU_Χ�����}]�et���(�=���@ܧ"�{|�K�ޮ���7|�^�N��5B�ɘ��Nlz�}�q��i��sX��|c�x�d��̈́��Qsv.;�[�_�ْy�  A�<�����ܹ�I�+J�}��r�R����2Ǿ3}��g!�Xcj�r{+�005������}t%1w�����N�e<np2�쨍��
�t�⺶B�4r-�H0];�s�ܩ�b�^����N)���BR��y�]ˡ���sE�3���iC��k�As��d���H^����1�k)k���$L������C�2��$�a;δh�*���^hyKh�D�
����R�X�Zhf?/78Ѯ|��K�~������%DN-����Z�Ҕ7�k��,�Pϱ��n�"�� ���@Q�:<~�:8+��D�d�_�@�dg��8U�ͣ���꾬�<��	�Ί3�o}�x"�+Ohߗ+/{o�jf� M�ZZ��&s��eJzg�P��Ӛ����� cYk����P�pXҸ�|��%�����m����q��	�DB���o �}�\m"W���&��z��TS�6�y�_7+�j�f1Fq]h���U��Ո؁�zw Y{(5��q
�n��a���w�􂷨@i�͡�y����M�����*���f#�HT߂X��b;�
Y3�i�g��uO�Ͻmr�Uu�z�Kf�5�$L�`K�߇j]t|`X�G�L'���v�D]�����V-�.�����4G-��3#:ڄ�E�����#�L3����g�'l���G�c��d�:n ��9MFb��1�@�W\�O�=���͝�ۘ>{��ݩuS�7�~���Nitb,A�MB{Y����4�C��F�ˤo����˼+d��:K� �fn�}���B,�$���ӑK�.��S$Kz1���*��mWLbOv��z�%����=w�4�혒��|���`����#g}I�'VZ�۝RE}T����}�2��#�g�h�&��â�	n~�>p�?�ȬS`V�f�ƭ:I"A���p��5�����������&��:.���L\h����q���T�و����:��i06��ʡ-�_s���p�xoy��X���R�7Q���lZX��'���b��� �"#�݀#����d|�A y�f7�e��#�w�NM|\K�Ի�bSx��w)=�g����`���-\$�d��ٳ��xC�����W��9,��$)��B�>�t,�T�8�5B'�pYc1~%�����t�ў�:|هҤ+h3fE�3��mB����؃��~+��Y��G�����6�#�͛g�������I{��U�&�9�ψ`�S{h��q�4n��~}z�Xv������_�?�=8�vu�&M��s-����Ε�B�*ʠPiv+͂��q1��V�hUS#��i��(4#j9��s*z�\P,>
��EdѤ����������3�å�y��i�Ԍ]z:�|:≲�.1rQ��	կ��P�ɟq,>h˺tZ��ܞ<]Z��X���&^ Map[I���Lew+���x2�]�u���(����P���T����\�Oc���ǵɴ���]�۸l'^+<����Xdǐ��E�`J�����_Eok�� �g	������dr����R�&A����8=z'�/�]�F���EJ8�+,�����ԛ���A޴�t��
�Ff'�4�_�S"E!��31��A3(�kqy�i�H��E!�e�����] ����A��.[i3�f���4�(�\��8�*t;j�l�B��Ï�@�uxG]�3��ĕ,���~�!��i��ϵB�u�,>��*�Y�H+�	�o˜2T��C�Xl1�"��V*�G|����oa��h��a��aF)T�̓>�]asQ@��$�s�j���u�em"�O���Z��m�	�9KG|	:�b6��I���w�.���d�?>��w��I|MrH�MFƀ���W�5�z'���_Tws�J�>!B�JX�7��J�I�4P9����e�6ٿڡ]DjwM��B��>����I�۵I�vUN�m�������?������Ԃ.@��;�]��~*��c4PX�S���	�D���DӋ�b%q���a����9yQ#骝=|<��0�{����*�D8���p��5+���+f�SsG�ĭݯ�惢��]��T�SmQ:�Zqm�9���4�41����lbq��8=ї>0;�v(��x/��dxDﺁ�I�z���n���u�M!�{Ҏ�^J�I!�9c����-+��'����ٌ2�d��O�Ђ(+�Y��.1A(��q�R���Ƌ��
�o;���qf�7E������J�ۉz�h�*��R�{���@�/�>�owXh�d��r��5�+�87HI,X�C����n��R�Tq�z$�N�;9�K�AÏ�Fj�	��m!�����vH��c�C_c�������R�zñ(�Hsj���;tX\�L	=�
��,qv|T*ξ���۰���$��A9*�hp�%��d��
zZ"��������9$)�=࿌a(׷��N�ԇ����k$T\ÞG8|�ٜ,
_��W7��܉��ҔF�����ޕBu(��:L�dee�#�4\JT&����hq�ĉ��1'u������@�������T�R�t�\�Q�/ʟ�͸�iy	�����䌞'�£�}Rכ��mڑ_�}�dt�A֞��Uw��F�@
y&v���Fܼ�&����:�B/�pf��P_�_p]��H093�e9�E4k RS�x��G\��	uh#�R{�B���A�)Wx������]�������gx��D��z���iX��	�?�Ʋ��;���e������h�-�+vЈ��|14�a�,���f���s��G���
�|�|�rX 퀭�e�gqn(�͚��wvYC��h�
����t��|�G�>	]ѭ�T%���w��h_Og������l��{Y��슌�����]6F�V�7��w�Ck�S��Jh�^��_�\jx?�)۲ j�$����W�1��7H��lf�|��k��p*;�~�-r��� Z�b��%�az�E��{�Kߜ|�ћ�;)e����7���=���r.�+ u��䇚��C��BE�{a�D�� �{D����yܷ82H�r_0�Ҧ�~0ٞV�ܣ�����˜�r�f*��D�@
c���%,��+���6ۈ=�m�����)Mt(��e�������4e���p���Jy�:T�~G+�e�F=�4���R�4<�� ��59�|��E>$�нכ�MS�"AKAJ���7si�'��S�Z�l������,�D6}r��U]�+���7���77Z(jC�_�˳�iaO���4���}Z�	v9�xX��>�D]L9[E�Y ��(4���%}����;��\Vqc������X�(�[�i5R5�Nb#���ir�u�7u�^č
d������e���S�������,W�O�	��+kӚ��
��<\\�'I�g��^�Qޱ`����P��8�J3T'���63��3,���M��7�N�Q7p0f����[�sHk�m/�QߜO��ENp/�B����E�;��5⏹Y���\��s�2���� h����$��$6C��T�z�IAl�G�)8�#	�����5�j7߀[e�6h�޾���#�������(G`-���Q�����]�դ�W!��.�1s�DL�,4*��J?�ԫC�^���n�����ܣ'�!�$�T6�?@O�^�&/��RH
̜N�B�S>�1j���� H�[�0WQ��լ�Mٟ�=�]"�Q���9K��,�� #!L��	���P��� =Q�Z3x7 B�܄���/������w�]6m���B��!������g��qufC�����>��8�]�8�����<�#�
Y|�"� BC���$�j��v��h6/�e�6z�7K������\��f�60��b�Շ��6��3.m���~�y���AdԔ�S�15}szcɇ�[�9�	����&���ɖ�G�+<���x���QZ�b�Lݖ�YOߪ�h8qKA�.��fќ�S�R�J+$'�eQi��w*vp�ZL�Wc��łC=ρ+�����Z�����
6�Lw!�b�n�ۡ��&äy$V�C��E�.��m�ߨ<�N]OA� �|W�E.u�+#-����q���u��V��>c����p%f�  ���XJ#O�Y�~�MK{ůL���?�߼���I��N�汀�Y��-�dsɊ��h��Bf�T��:����Z�����w�ȝu�Ҵ�/O�![��&c�K�����a��.|ӟ&�����޾l۪�	�C<���S	˛��f;#i�}�SԜ�������K��B�v.ד��k~���;����5����<9j6O'��Ft�C���0ji�u?��X��>�J���3�r`<3���('dJ�h4�4�^�=N��>�7�V�[y���P���}���M�U��������Y���1�9�Aya�?c Js�k����ӟ�P��������H�(b;�����c�4��������]vQ��� ���کY�kݩSOu�&}�t(ʛ����H���\�Y64��Il֋%�w�
A~@�ح>��NՏ����`-�d���M�"�g���0+}uۆ�B�v��nV��v� ���:�Xa�4+���/]E�m?]7�H� 0eG!P�\zr�P�E�j$�F'�i�>�o�þW�P���R�xJٷ��y
�2���I#6�$~U�i9p�$��J�[��+��	FtM�M�!A�b�)��Y�k�E/�N��2���^>�uA�V�)W��_�k/;�O{O��7kQ@'U�cS!`&��֗b"�"�]�e8˸�i�W�<�#��#��|�X�ȕ�â2�R3>()�G"��~u#�ա(mμp��y|�mk�'-��U�N�:��?hұ�)��=�J\��=iJpnp
Щ����B���}���Y�eG��b͋{8ʦR?Akɺ����=I����98j��|��x! ^�A����N�҃��ʥ�nv(Ƈ{v���+c�i)!&�G��N�%�}�q�ô�X�SC$����0#N!�#|�٬��������,a��)���#"j�~(c���t�Do�4!nu`?�K�����M͵>5�Pl=�Z�7J���8W���1/���į0�Ia��Sk�1���͔H�N3�"��:�:s�o��?Pn
�K^��3p?-��0u�}��&Q����r��� o���.�e�׎~g�7��̘^��x)qPe��W3m�����d����7�^ Zm27
�B`���-����a����J1I�����rA>h�/W%0�-뺵"��FQ;#�IC�TU��kS�W��%��W.6E7�G&�dX#�y$aձF�N���4��%��@�.5	�e���/=,��j�	�f4�7½uVLD�>���{���!쀋�~��>w�k����pV5K	"��.�dc��<�ơ� �@:Џ[!QM�V���+ax��fP��ml�m�9�A��{#C�ʄ�o`7d�$
ı��P�K�h����� ����?5���~3�I	�����5pg�K�hu��ʏt��h[�`�b���H��cd��������ij/�U�<|�2�KW�e�Y��������,�Շ¡(�K,!V�=���ϡ�=Y�x����hU֘ �9�`-��r�.v*�g���P�kc��u�]0�{x�n7�;l�7��ܜ�w缔*StCVk��u����L7��A��_��hYr�&�!Ȝi��r��Ff�3P�ZV����K�Su��L�^�'�' ��X�Z��/2(&�g���E@=>|eN��,��h�ņj��-϶��d϶�X�&�pG:����0�\��g �����i�k"!���U^pi�iڸ��1cR��X�Cj����I$h�%֮��4n�Ht%�m�x�[�5t���?
*���t��C;���vPS�|<��1CtOJH�樊��"�̪��`g�m��@l�^>��	�:�v-vQ(Êg?
2�W�ɾ����%�PV��gk�rc��e �fi�^@)0�BW����	���)+k��ē�Ӛ�;���y7�?��a<#W9,"c��]�
]x	���±�)��yy@��o�����|�E�Q/̵�߂0)��`*�D�`��e��20&Lq��7{��.�B\��ijۜx5���%��B�W�L���I_p;+������.���`�ݧ��p����4����Y 1��*��.�{��6�3�Җm��jZ8�=E��@��,��?$������6<�)��W��N������{�7wތon��O�[���Ƣ� 8�?~��k����ێ
7�ó.���'����Ni����!��>m�9��i��*�r)�Y��"�Z+X������ @aO���1����<d��>�O"4�vTյ�ު!D�'y��,��q�}�������~l�VH�[4�Z;�>�����%����o�Jik9��	m����OkJ�|��F3�o]��xL8MA�+S	���+ n��E�-�s���R9uT�3F:��x�q�#Y$���l[�����Dl��F/V���c�	��˕��8���Y��\�ޕ_�G���<������&��ی�2:�k�o?�T�N���>�m	�w)�S�~Ѩc�~ds~X�Wl�.�3��N4�{��0 ,X>�*b+FB���"	�dȊ��s_w@2l6���P�6g����͆���^����,� h�U&u-M֙Y�!F��fq��r�7Ё7a^�N��������Y]�^I��wn�>�-d�Tr��M�?;���ҟ����(w� �_����5쓓��oI�?U�'WH�m6SB���[j���I��O�$��َ���&ګ0���ͬ����p�����T5�C�D�_1���!	ᗼ�a�@'�]���K��{���N={���u_m����`2Z��1��-��C@���ԥ,]_M���808؅�D����+r/ʻ�P(����tTxިEF�h�H?S��6Κ�8~��P"��ZӃ�x�E�=���I��J���$�3�4O�/��).�l�<��Fhzmi�<r�(�$Q)D�����~k�F��2��n�n��'��g$�l��f�v|����;
�a�y&��<��L���
����X	����㕼̬�\(eg��p2�w؂�]q��ls�`���@щ|ml��%C�	�-�A��i�D��;H��I��/��Ö���y(9�P��![��,�5�V�0�1z�L�P���g~������=ݽ~�X�~l}f���i �n�-g�58.y��E�np98��w{G�Mt�����2�(���蛅���X���qN.�p�ױ:V֣:�i<G���?W��lP� )8�?)?0E�tYiw�]���J����9���cmH;�gt') n��{��+�#�c[���B��;�R��s:IIY�~V gYM^������ĝA����8z��iж�y��I�f����`/:��S�&�-� �JG^�c�H`�5=�5/�I�5r�ɿ<�6���8���t;I,r~�ڿ�z`k=�R�!J��v���d�]x����C"^q[R��
/t�Hᅩ���������HU�I:�J~ ��O���0$P�7)R�ZH��k���x�e���A><�B�k�9~G�QQ�e���(���Oh�N��QÌV�n�\����!�r\%�u(�'�Mu���>���i+�t�*�mz�Ȧu��m#�r�h8�#�0$~���v�8��n��v��(�l^�J�,�]/�(�=��m=���^��H\��Zwx�K)����g���9���������x���C��	�{J�{�t�V�X���i�~����Τ�����<@���YJ#ԜZ�vZ�K�װ�~u�բ9��7����c�'h��o�Oƍ�0L(T�a�i�>gv4L7����9�� ��Slq�_�Q�����[���/��h<�-+Pt�~�uӸ�a�� ��#!s�[Xx����#�S���94��ǄC�e��ʺ4�qlN�;"S�Gr�]7>�Y�	��Y�[�q�C|d�Ȓq��m/��LP���QQhua��p$ǖ5 ���s���u���Ҵ��@��uB�>uT� ]��F@�-�	��I}�e�����Ҷ��<bk�B<y3���X����[�;Ɖ:v
~}!׃\^<ergA۰������Łߟ��x8 g�m���ܪ_g��3�p�
!L
d%��D�M�g�O:GVS?d�H,4c�e��nКB,e�c
��D�_�e8�a[;����^��j�*b�]M�h�#o���);������������Pf�yO,�,��%0��B0`�������G���n��f4���]�+�o�'����!XS4�q#�	h��O���K4����W��,�p�?�����������"�i�l����4o�A�ݺ�YF�u�����F���-�/&����mƱ���8��@&J1  y\�4Oqt��p�v	+Ph���O� #��8d��`3mJ&9��F�\�ۢ(��^6�)&�'���8�5fzK�ߝ�xD!	��W�+��ƪ/��`�� �4��hI��/b8��<( vΨ�ڽVc�vd���w�&���-rY�{��A�=�t�n����PI}�A����Dq�2�k*��úW*W�����ٱZk`gO_�b)��p��r7��m�1��t�fL��y޽�^�Y�>>��O(���k��n߇�:�!Ъ_��4 ��b���^�9Q�T�H�=��p��}��*^�-ʀf^
@75��~n0KO\�J�;���~fjW���w����+yS���6ø�ZJ�A, =}Vq,R|5Y��-�����]���������!_sĝ(�_�%�\y���{%��UD �^�z�q;�N�����<ޗd�Amd�>u���r�ń�.�����<m�b�[9dׄP�i�P��۟ѽ|����"t]�a��e�s��9,�`�����^_A�a\V���l�۴"2U���І��u� ��q+��N��V��k��Kڄ����`D-�����y�.��0�.h��H1��.��wC_'
[X��r&�P�W���x>�||H��yl�&t)�/f%$3�CP�*���d����T'X��HFeK��lLƤ�G�8�M�F-�s$�"�)'|F�Tg�h&�f���݆S�CM>h�����d�މNU��k�Y��ڻ���C�p-y;h�3P6�X7ցTu���	��C84����Ď3�6���#��
u��Qh��\���ߴ{�v�d]�����.���b�߈��7��QZ`���a,�Bb��*UtI����J<L�y�B��P�Q|��I|��!nAڷ�|��j�� �Xۧ�`s�DS�ҤR�a��:�#eA�!��m -zh}�t�.߆�!��B�P��B�V?��-\���Ic�%�5ܲ�2�0�iշ!��_� +L��FǤ�����r�ӛc�3R�˕ BM���:�vuq9>��(O�ȴ���B����܈j�J'}��U.�b�ƄY��9#^�ⶎn��Xh�l�����_j����D���%�*�{�%o�Z1�`���q��7���UQ��d����߿Ul�'9ŕ~Ϧ����%�7+ �za�Ki���b�f��q�������T��
#�e�̬ɸ�+�a�T��6����ȶ�ct'��]}u:�׸���i3���Kk�_g�u]��9/Aς]X�7�����?����m�O0���rmwٸ���iv�>��{��f!R���+�Ϋ/&as̠�.2��Ya�H��uX��6
%�� ^��d�('!�Dx`Pb],a%�J���旽���0��b��S �������؅��Y�H�	d���(��7�7�Au!����';7�����~D��@��o"�%����FW!L�X�R�_��`.Dxbw"�nz�5,9�.��Oߟ��N���bA@A�P`S~��0zM� �
E��-k([�!	�^����V���YF�l\.��[�̕T�Hj�lg>'��X6l(B��߇ͼ�3ѯ�� �{l2����&ۿ�WO�����<.]�Ո�br������~Ɉ���& t�l\S�xJ�q�>#��n*��iw�������l����x�$t@R��(��ź�-(�ͿA�Y7�m�C10}�;��@��6��;�'뵮��,ňNњ��?�Dj��w�Fi}���j�/[4��[��E՘ 7Ha)Y�M�}�F�UO��������t��G�=��;s6�n���U�Hb/rq�9NaN�I^ �%����H�h�@����8��9)ƍ�8F��?�~m*j����s�Gяe���b���l���h�ϪY��У�-���es���Rm,�����y��M�0�z����u����Ilj���)�����~¡�6%�ࢭL[[��SY[K�~�h���#�Y��a�쉠�^����X ;�u	���t�N��������)�g�����J���J��}J)�!�I0<�;I`|�-��d��Ȯ��oE��_�WV)���}N�|�ҷ�!�{��rg�ZX�	�w҅��pe+j���<4��
����D�T.(�8�[���(&��WN(;y�����(L�A�ߚ�5ƺg�������G�eY�)��N%��@>�[+����9�������f�h���%�&�;��C���×_��l,�$^�xV�j[K<���Ѽ��p[�{���n�2�Ȣ��҄�[�����})�B�r9�>-�{,F+qz�?(����7��:I��r!���R�	z������)+��9��_b?v6��|���ެ�XeL�\���C��1���^�<��[r�`��,u3�pNa����S(�*A#M����DN$��<�P�a4lςY�2�.�g�&��gkl��rل���cS�HK�������+Қ@�/��5�E�N�N$^�����.��o�6��6ū���"�r)�Me�X���B�I�`�̉��	�)A<�IZD�y��_(n�����
��o@ū�.�v�P�q4��J�5���>�t��P�-i�蕊eQc���ο��^��)�f���/�;�Z�w�V�+��1 Tȣ���?�����N�E��?9��l�̩�'2�2z,��JZ����#��p��?0w�)���5��襥���/|c �^ggn�Q���0]w+^�W_m�)�!�g��r���ʗs
A�=�������]�����Ɵ4a�Y7��3�2������T17��E@پL�C��q�T7GKf�'*�Ƴ�:�u�[3��A �Z�I�d�#"�}��&,���G� �&g�=�,�-�j�`�X[+���}`�Y���Jk���fU�_7�=H�.���g���n�f�R�a��Y-*�lg�8Y���;��1&q:
Q�4�E�:�Z�U��>v"x�+H�[�������K?�;n�:]:�<��VtX�n"j*�7��vAcV�G���+W�v8� V�1%e� ן��p�Z�4�j<�h-�\��n�ѓ�+R�Umi]�e'f�
��)��L}�zjkcÑgX��-�c��ʙ��ǀ-�ѹ�k��k����tH�E3�Ms���4�Q- +��PC���5{c9��t�Z��(�;��<� Ф����ʒcۥ%�������\/z�t��R9�ibS-_zI��f��'�����8ʺʄ�0��5�v����a~�x%OFf�O���PKI)�ݞ
�~U��O[U�M�w����}^i?��� �O�\S�nM��5�u�Jw�)�߯����2m\�y��9�'07E��s�	i������ �%��6͜[P>l�ʣI����Lj���dSn�-�r��,D�Y� �z���D̧Z��j
og�Ω\�g�cɋ�,��ߛϪ+�~U���ܗ��dJ]{����Ő��M)�%Sn7?u%�O���?�?hUPT|ӛ>�4�G�+�8h���Β�mM�t�8��ـuqv��§�Ppy +�2���u�-�7M��1���f�:��N��)fjz_<��z�7[g&'MP��i>6ZK�eKc�9�DLvNz����t���������L��"�`�qC	=�}�µ�2�?��iy�km���ӯ�ͩ�e���ҳ��6r�+PQ%���{�)����05�P�g��G�䯭���)����RD���qub����Y`�E��*�ad�`&�G�2��)��:Q��GEj��_��M+�($��xT9r�}	���u��h:�aVB��_HfqEW�.����0Vq��5�ӳ��M������P*����E�b�,-���ۯ#Ƣ�����B�k:��Jr���ʕ՞��blF���=�Hμ9���.}���Z3@��Cvl��f�4���A�K�2���u��o�,�B��xQߪ�5�x�<�(K��.�Ҵ�#���S�Y�PLtt��r_jI8?�i����.��dH��@2�6O���-	8ԥ��oN8
����� # ��%Hq�������|=8<G�\5�`R�+�Fo%?>�(��ӣ����k
�l�0����e~^~�lt){р�j;�f�S�)W�1(�Q؍�?�G���Ήw	Wþ�8r[�����E�!l.�<�aAV�����66(��� �ge@g���-��(�0���<$�a����k�?��ͧ���OТ;�Y��^\���	�T�5p�f�hN��B)�x �7Z|�?���"	���1{��|��M���M��δxd��+�OW�,Φc3s]���ֆ�]恝;�%��Kw��q9w�e��I5vcR3<�����_D�>���dy��1#��f���}^�H�����9k�������:��Jt����E�4~��@�f��R�`iK��mN��Zȵ�.�����ew�:��D�����X�8�T�v��fwQwd��,=R�.���1�=9����~?�L5���d^g�"nN�|B��=y)0O�3)b��'���&WU�Xm��؉�' ��X�`ӵ�ݓ�bj���׆B�&.@���E+?#�W��^��&N$��pk"� |��� �X�`�f�GP^x_l򏸍��*X���}�L���ۗ�,`F���^���u��p���.�`�U���e:̀5�7K�O��"H�F �/D9֫a#�B(rT�����#g�eǛj��a3�{7+�����	o��N�Ť~{�1A�j���0;�П,�����0���� �Y�|��$��6mm
o�W�(�����[����'�$Z^ݩ٦���й��O/e9�&ȗWBx	�"
sj3y#g�T��˗� ਰ�b�i0����T�� �3��b�
L�a�/��������/��������>5��	m�I�k����.W��r17e�6' �Ǎ�,N7�m���/hD��/b�O����0*tp�}o�I�����ek�s)�
b^}s��I\��*J�FЮ�� �?��O	������R��KJ�<x�`qP�e�WK�(P�d�퉧��d�1�*}��_Nl�ܙt,cs�a����h� ����$q%�$����C�%V=���2���- ����Hʢ���9P�k�b�`qA��9�16�Y��A�)�e9%e������H|���\��~������MNaN�h�H!>e
�~^S���;�ȵ��ܓ(r���!ۖ�`ڇ���g�C����w��%��%+DɆ��"n�Q�?�[�=F����-4PV������J�s����Ɨ�0��QB�|�> �+��d�^o�n �d�8�H���%m�(>���փQZ���a�3�r������Q-X�yX�.֫Ƃ��^x!�5]R�Ҹ��Ź��_�&��ͥ�I�	{�	9`cu�'�;����>)@�Q�p�y��S��� ���6���?�i���j]�%��/hQ�w��*�~CPw{(�i�F���֤q'̸�b��]����}0O� ��I��N�c�J$jt�����a.X�{�鎧���i�����h�%���G�
9P�W@7�u>�M*	�D�5��FH���8�\�iԷ��y��56+ꖈ#�g6L�m��r��m?�\�����������}�isu4�2K���'"�J���I���(�	�s�e.�<y�=���=��].��ٯ;��7[�s������"�w�b�&ׅ����G䉎�E��&M�>�y���U�ߓ�����n�v#�7������Ld۞�׊�X����|�7�L��rrO<�.�W���H� >Ӎ6��>A*)�z�8��#��oH���^�m˓�n�zIrx?�ǌ�g�R>_�/d����xY./$����KJ*`��x��4]�=��y�mB���P' �vM+ߥTa|_
�G�� %��z^�7�fu(�4�>�B��r1��j+�J��ڧr�T��纪H�`�&�9�Y�!҆>���{��8\H��(���a����N��N|+�^JnjXך�~߯��<ٔ`Q�v"y��lkq�<�,��A�I��*�C�XG����Q��"�[�9"�W���!�&�{q�V��<�yAD�_L\1M�f���W�RӓI�A�õ���Q���xy�8@rX\q
�q:>��H#���ڲ�Z��I��Sʖ U:��Ν�AΌ�'��o�i��4�⋡c�W�Sf�4?�nμcZ����6\|!sr�MR�{Dq~O�(�o��S��Ұ�̄��i�|��D�U9�u7���)���8����j5q`��ޛ�L�l`X�+��٥D�Ь�����Ge����S���LdQܯ���~��s���0el۸��ai� e!4s�7/\�C�X���E�hO��u΀�R-�li?�^�/&K[�pu�ᆎ���oJE�a��1�4��-��#��Lg�Y t�e���n,07��f_xKFqg�����(A��E
��U�z�o#��Td !\��B
N�ـ�
�ޜso��M#\_JV��x�
%����������PQy���E���eu�*Xr�e�Y��1�P����j�$j�V��:H({_Q*6��?�����8{R���	)
�?.-Ul�.PRt��4
k��s��iDeyd.��V/'^�	Kg�C��ʎ�kBK�k<9�V�-��o������g�1�s�����"
�4Z�s ���K��,�V��:sO�Mk���R�5U^*��i�~u�����.��<�o೦��,01L��|I�֓�cC�A{��s'zv���Sj��T�\r�{��dT�ȲR^JGi�k�fw�	|�y{	���V�7�d�&E"I��%�x�6�j��~&����p]�a9��"��2��`o	;˷G�����D�5��ծ����Լ��gm��4�#�^vG��Ⱦ�%@Y�	����Z�����S=zGJF����%ǜ+��h(�H�*UN�@�#��\���qwL�àb�fn�^�Uճ��.��^_�G�F�YJ��3�k4��;JTj|�FutTN#y�8J%b�o ��Ԃb��x��:����y���W��}��������܈?�H1��5�x,3����3(�0b0�� W�+���B����4c%#�23�Oɢ�D��b��t�[@ʨ�>��t{DE��7e!Иnk�vSSgK�g��)C�&���5�*�uD�3:��Y,_�d��$D���M��)�L)<��K)i�6����p�D�����u�%Z�r�����A@����O���pRʦ��K���Lb���[϶� yW�lTyg� ��O߂˳�>g:]��z�NK�U<C�\9lHy�c�Cz�hf�S������I��X�ꀜz+��Nb��x̊?�A2<J��l*�2��Ql"��@��������qg��#�����<"�&-N�B �^S�.0�-�rR�^����b�4�d�3�lٜ�W�Cd>��w)�O`�{�{� ~3�T���m4��
(�{`�f����[�г�!�ȥY��q]��S������#�%��z	�|�ӯFJ���/�m�0Za������~ZΏ�ŝ4|��2�#�
�o��O��3���XQ4����#��]s �i{�,��N�\g�C�
*��/D��pͭ��D�fI�pX�l�8�11+e���a�������hh��A.�/��{ք�ŧ]m	^Gm�1N���-E�u�\QU����㫊,d�bG����ҨI�7�S�SY#aJ/';��'�1u�b�6�f�MJyj�]��*�d՝Me����_B䕵e*���D��g�K��u�����Ũ�c���C���J_f�j�)��CqTƱO�S���U�ʏ�#U<��b?r��i���}!��"��<OF��r���6v��R&�z_�j)��yP�
S��wD:da��T�q��T3�M�؛��Y9l������V�gIondW8kz;��s�%f''�%�;�����/?%��TH���B���B+
���S��(ԧv��Q��-��X�!a~���{�C�d0)���]�;�qb�F�"���$��*`l t�hkP��� ����K��'�*�*�W�y�Sb!%���� m0��ϭc-WW�)�_C١�Fơ9��QU
!�g���ӈ:�>]��ߌS�0�Ӷ�Q�l����P裸P~�B�O��~TP����}���aJk��~]ᰟ�- �������Q��X�A�-f6i���rGI��
�ryt�,��{#;87�Z�l�x
�jD���3}/6Z3��}ò�t" ��9���j���3��x	P��,oo�l���N�j���Qsu����P�U� 4�t�{�ڔ&)v����g�d��ؾ=v'�rv9�n���.��u"�u��O�!K���JĖ}��HKn�d��37��^(�����է4s>V�����u�������c�o�KE�4K����>��o�G�;��������[I^)�����nu��ץZB-=Q�e_�޾���^-K�#��6�A&*}����`��p�wc~���٠���$��@<�Z!�����!����0��aE�`Z���?�C�+�J�����0)w�g���)���F �F�a"���رur^�=��Hr����%��CF��e�>Р�pX�mux���	��u�'�mK�.���ݯ��|%�8�<!�p� 7��n=���m�J�;SN=_��͖ѩ.:²h��
r�%�뺱8��!6h6�<j������{ �2��x �d�_�N+��
�����|o�D>�θ�W��!�5e�$Y�J�p�aЏ�'����.��}�Y^��_"�e�wX�հ��� b��w��Z��K�f��W�%��h?�w�H޼UT�n�J�����W@w1ߖ���#b�q�r5��Ώqn닧ӧ{�%ݽ��d�$���7M R0�5�\lSH�=%+a����s;ɯ%|g3j}��z��T~�`/V���2��װ0�p�_� JB ���赉�HW�~��J��;��Q��72��h�[�:&��k��[k�7�x�Z�"b��I���[:����r�>�$�l�'Q�S��yZFm�E���jrK���c�hR������g/�٬ �?~k�|'TrY9��H'� �R3�k�X�5�����-�������$-6^h�?����iL릡d�eՌ���jes$��	� ���%N�s���,g�ɋ �)�	(�9,7`�žw�з�*�P����`�p9N'G�X�M������'k�/��L�8�����4�qTA��cc����$`���Tz�v�q~{�Y������`K�_M�[T�j��uڡ)�����;,?R�" f@��#'Z�#��f�al��4~ u�<�i���^� ��9�� J��|�-a���҉7EP~	�����e�6l�r����� y�ʮ��
+;L���f����ҷ�,5��6�F�	��7¥_��p��/W45���xl ڇ2T�#�`k������a�XZ;jPf�Q�M�t��HJ��B��S��O���)���ơm�{���~N�!���v���K�)����(�BE.�R����~�ɦy�g�G�Mx���k�ʧ�k��v�̯͔Z�sҍ��p�d��l���8��d�y���`rXvo�=����k��d���DF��1g�#�^�h���'�{���I���F�3�m�m�6�haHh�ayW6^*ۓ�H��s�a���g�ĪI����l��F�b�V�\ׂ��1M�,��y~;ܧ��Y���z�A��]�x��oe�r��T����|�N��v���&�t
�X�8��0�7E,@<?������6�Y��gL����b����:k��A�Y�N���&��j��S�r�uF�, z�hؿ��x��QB�����ɜ����F��"zx)�&]�?3��d�X�+E��r��{�4t���]C'�+z����G�z��aCh]� V�s3�!vה�QA���	��$�e��=<��6�]����+�����Iv�G�$����h�	"`�Lt_�H�Sձ��s�a���am����0�R%�_|���W:�M-�2<A�w(��-f�\m_�􌤗���ƿ�A
�9߾��,�$˲�bD�ŵ!�|�;(���F)ߢ+��$�`F�9:�L%������ъfh��!%�iUw,�봛�yG�/�3�:��W��*��Ex� g��ؗo�ԫ�Z��B ��i��iƹ�|m�uS����T41&kY���v�(Y�~�uD.��_hb���F���?��; W�4�7�-���0��Ww���z_�A���⦥0��� ���&@U�Lâ����T�^@��+��x`#Bi[={��-�5k&c;r�dX�SP�1���H@��#6�K�"mP�{"u�Əb�sт@q5!���<787��� �}y^v�?���+���vH�D0f�0�ұ����O���!jEzR�-툈�+�۠���V��a�W�Sgm�?�9э(;���n�4�f���&��/��Hi��I�p����d�|wʗͮES�k��{����P����"P��VpA�d� �����e��G3�p<�[�^M�E�nv����,�"�s:������.�	�A�,�����1��#*��)?[�J�b��&J4�v6�z�i���t]�R<a�~"�'�>�Ʌ����:����J'�b��$%�|���@�����_�
Ǌ���y���.|�u*H�d ~���p�)w��	��>C������OQ!?Wu:w�։�(��n]ħOl;��}~ЭY���F>w}��"��0N�ao�[f�#��wyUȦ�b ��QC�ʯuEX=Ư���FQ ��(\������ű	I�KV���rm+��AH�C5+.�'���F�m�ʨ���M���Ǧ��݌��j�f���8��г�aF���v�7ݮ�ۗL���wq\2S%쭺��"z&���C�����:9Uv��������n�r��=~���:`\2��$B�����쓭��C�����Tr�*��6
�:�Vt��FZ�f��z���ea���Ѓ�엦�0�������6�{)Æ�Z�;J��d��΃���PM����嗝�G��e<8j�<�&̴���
���U�_zed�P���Z��{��Z֤�����	�RZEF�`c����Ȏ���'�e��q��i���"�R�o��Y��<��a��U3@�����J�#�8&�w����Z����z,��UDx�b�����(FK����������p���w%����7�	�$�c�N�Y\�;=��.h� ���*�>���D}N�F��S2[���"�l�X��)+�j�C���YNE�0�(�M!�O���'�a���I �s�������楮���'��u84=�;�8�M�S}Se��,�=ʖ����ߚ$���mϬdd���Ѧ��'�(vu~A3Q�;��?И�۞�g^h�����d!QU!�L���e�]��u)��X� *�\�p�C���W_�$���￶��r�k�Z,\Mt���Řn���vk�i	�E���B#�O���r�X�Q�My�:5��ͥ��S°fq��}�-���eaal/�j�f,�a��f&CEVYZ@�zͫ�V�E����G%�QE�������Q�n�PY.?;��Qd[*���Z��(mSćӷ䭮��r�/�l�^�$�:����7�K'PG��@DLv0i��$}gB�<�-S��2op���gZJ���?_Z'b�ȴ�o爙|��� ��>d(|�"?ҔW�5|l�X�1���1���"���`B��?Ю�V��c�,��k��(Y�H�e~[3����H��I5���i�Xi�f?f�^�����4���lu�X�-�B���ǈ{�Ϳ�[�V��/��(������)�r���E����iz��:FK���P��@�9�}���>������K{�)�D�a��c��>�sf��T�s�VN8s��,Wξ�M����0~�LH���7d������ .�t��l�Wk�Z1�M_ :��0�rw�\ϛ+5j���ի/bO�`�$��YǤ6��O7����A���
c����V�Ag���_��a#�������H�pZe�(�����X�χ����Wm�+���M55�7�)|{t����?#n'8�)�X|@)�C5��J�Y�*��o��"9�I���G��z㡼%�S��\��D�=$�����ŮC̻�HV��]��H��i��T�ⲣ�j���v���v��0IZ��#~btq�&���߽�N��T%�� ˇ?Jq��C5��t\٩��D$�&+
���~��w������Ӗ�{���(��b=�
��8��D�J����Ƥђ*<@�G�M=�	�_��$"�C(_	C�����v�D��۪�s̱�
���fa���q������$�c�ïA��+Sf
�u.%��
��ekк�Kf�+! ��de��3#�-�� �@���#�B�:�{ν��*��FM9���_�/�D��-%Zc��g_�f���������P������7���V�f-��V�Z
�L�zA�&Z��"i�ǜ�2��v}�u�+ꡭN�v�/lq�?��c?�p,�2���`~������w����D��hP@�T�h��t���[3#�x#bE�,u0���MwIat�:9��F���k�P:M�Xa�]��p}|����K������cЏ"�׳]Q|�=�>�׈����-q`f�]��Up6�C(TO��[�bhޙ�Q��s)������I�+��c�Q@�5�3f^�)���"x`������Ͷ�;�"Q��X�Z[����l�8fg�8'�W�s՜!�,��f$�e�1��)d@e�Z���g�q��u+��@�.���EA�`FƏ�%�Y�_E��G�����.�3!zM81a����_�\W$����~���V,���H��`�I�����x��RTn�a�S�t!b 8�;-&Y�����N�O��^�B����z���=�>G�Սq�s���bQ<_���.,��w(1�.�br��m���$i-�,&��@�2/G�8�}5H�d�7Gݏ7��`��z���.��֪+��a�V��m��o��U��WŸ�3`#b� `: L�tX�iw\��Y:�ӜzlSKB;�'8��#��å<ۙ(xC*����Іw��z1=�8�"Iό���ݵ? �rh6��/����/�sо�>*�L DO�oq*厔�Ⱦ�B�D���� ��KE�0 �%x��,�#&�pgRh���h�tSc5SѼ��:����.`x��[uPM�('���	�#w����R�}    ��o �������s��g�    YZ