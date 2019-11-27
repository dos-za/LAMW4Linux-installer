#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3085507347"
MD5="875da8d5b52293e4e5e2b46ddecb959d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21126"
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
	echo Date of packaging: Tue Nov 26 22:06:17 -03 2019
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
� 	��]�<�v�8�y�M�O�tS�|K�=�YE�ulK+�Iz�J�d��!H�n��_���|�|B~l� ^@���twfv6z�D�P(��u���i����~7��4���󨹵��lk{��l>j4��;��Σ/��Xh�<�L׽����������t�9�)�����S������#��������>�]}b�s���џ�R=s�%�m�%3j��t�<1C�cy�r&��`C���(`t��6u�����A�R}��<w�4�[�-�z #�H��7w��F�Gh�l�~�P�sJTY�Ub3�AH�	�w��N^���NF� &�� �\��Ӏ̼��8��f� JN���_��
��=�������h$�����PkOդ3>9����Q���X!Y�\o�CM�φ�q�e�M����9u�Qo�y�e�m�e��5|a�(W)
���! +�#
����^p]�;ls@{F����}�׊kQ��}�9W�����`~��5�ƺ����9;���(3[Y��Znp	�
�a. �z���j��QP��7��	l�2�Ft��eO6n�RIx��_�Cק�;^!�H�X����	��tzA c�} ĞE�Gt1��Q8��A��(P*S3$:��<�"�����a�o��'�[t�����T��L�1H#�MXLeU�JEP��>t�9�Ӻ��$�����M@���ZFmvxz��n�	-j-Q�)*'(����q�������h�[R�����e�`�0c6��'�7]Y�w�A2���(s>uj��e2�A��&TVհ��&ڕ��6�ܼ�Q|��XtfFN�� H+�aީ�D§�(e�i�T�����v־�ؠ/�P��v���/���.�Aw�?n�b���M�l��7莠-�M>�>�UR�Y�"{�0�e�G�K��z���ԴR�N\E�N�	!hq��b��XJQG�H�QR��IB"�����)��Ma%�V��0m7�T�'NV���</,�O��ib,�j,��>�:5Q�<D��*�`2;� �+�R�M ,����[Q�6�<��Y��mwN��Ԫ�W���no���67����g;Ͼ��_��»D�1��I{J�Iz>x>��y�&+��TF��G>�{n�0v1]�W���� ��$/����_L�� ����=�sss���ۍg_���3��V��EwH�����NZ�.Fl��v���{t6���u>J��^D�5�1x/
!̱y\O&�l��IB���g�3rf7���XXϗV�{����d�C�� r��<$������u셍a!�����ua^PF�1�y��32�P tM'F� :��=r�>���dX���/STP����ռ��i���rd��o��G��f�ƫ(3;`�9�i�3
���w�a��7}^gє�Տ��V�K�^r���7�;_��_r��Xx�&��X4���/��fo����ݯ��k��3��M}sk]��(�<�	S�MH}Gшo;8�dN]���.�E<*hN�ψNZ�A���FZ�x����R�hH��	1
�����呙?��8�2��~�`��Ĳ������)/V����/�H��6֝+J�񦸇6�3��Q{�V�m�"Zwi���a���X��OճI�i�PW�`Z����إ��������>vl��9��4|�H�̩�����ت7�<����j�IDƖn}P�� �q�^0�&�����u( o��*a,����q�5za�z�ݱ'8�CU%���Q�<��V���E���q�5������ީ/�Ad�5i��qQl��\�~В��\�bwz�,���1h������he]i����$��4s�EͰ��)�W�sS T�~pѥ�u�{�M{n���@�E�<eH� @�a�b���=����'7Z��{f6�"�K4v��W�$5�~�c�X�gL����tW�t�ե�f��ܞ�#��*��m#����� �DUW�N�19����as=l��/��J�g��y�d\T!ߥB~z����	�����F��ӗ$5�#���k9��h���6נ�`�U���J۷ﴧ�9��QL��n?>2�>���t�`�s�SX@:$��W����-7�%3��彪�>�翪%�K�t�T.oVz[��6b�.��Q=%�[iʓ�9���
���C�C�8�T֏h.V /^,L �b���96�1�iq�{n�s��ۯ,T�)����R�����G�+p,'�Im���g�Qkp�&X�^d������αJzô_DT�=����ԫg-��g����T�_�9�1pg*�U�ܘ\)�Iܒ�H%�� �c�l���J^���!z�(�h�$!~���%j�/d%�{ߟ^�rYv��m�8\���������t����!�e��k���nN{����J�ղ!���R�K_M�Mk�گbh�NS��j9[UI֗�H>������˙��t@+� �u��$`�u�L�w�K��!��d���~��|���kǋ�i/��.�Z{?��T4)Iƣ��K��
7�^f��6�S�T���C���:\D��d������F��6�;�dQA�naf�����00}�l�:@��y ����6���q�h|�C��:=���X�
wd�'!kn�D�%jP�g�P����9��<<���җ�$��*_I����ϲq�2�(&}szaΩ�������Qj�/���v-z�/�$a �� ��m�������ʄ�_�����_~͈�� L����w+�]���]����<�z���q�w��_�t��X�%�p->o,��փ�����Cym�#ă���F]<&^'.+�u�z��p��X���ۡ�g�aMC�ƕ,�ߵ�K�x>?h�F�!�^o4���	~��x-q	Ã�rp�� �D�s �'���p~?/=�����C�W����ޚ\����(g�$�Sr����<D%?���t��5AlZ�C�̢K�MB��v�y<<{>�e8�����=i�F��zE]�n��O�:���O�w�;�jcww������N4��;�1!���RQ����s��Y�NS�)��&���`��p�����b<V�B��i�쥇���ǿ�u��$+A�]QIU?�2"g����,V��fxn�/Xj^! �r9�]�$by +�٢j��ư�c�4�	ҤV���vk�*�A� !�hJS��1�S��+���"�GƻI͉��݇N-UZݵ.t�1C0W���Zt2Y��ۤƄ=	�c�m9u���;�<ra�w�r���?�~@����U��,V�<�������0�z&���9���g�	B��%P��Z���(Y� �$���
��7���$':�"T*��Ʊ�R�ŋ���IB���'Z�x�)W܍:������������b����j,(<�`fzl���$���9n\MI�S�*Q����ju˲@���s,����Ώ�� _��ǆEˍAI0U��&P���(��}���k��w�v4hwr�����6/���}���D�΀DJ<����x��H�PY�m�&�@��ӥ����w[��\�xu����m��#�FM~/�!k�!�F�!��#�G��Ȅ�A�R���31��N4�ȗ ����R����/�#0t́��ė�<F�C��q��ؓ2B!0a��5>s� �?f�Q��,�3�Xd�G@T�5-�����F�d�Vf6Q��]�4h9N鉣Q�u����bH��Z� �ʊA�6�ҍ��N�Ey
مFDXS�ǎ�k�2�aɥ����N��{3����%���a��B�Z*ҩb�9k&MS��e����u�kY�ˉ�a�^Cx������
݄�#NHD���n�{I yʓ'��ط�T��J�y������w�@n����f���,�(	�^��h�ձq�ĞbY�2�C��;���K��v�t�ͻ�Qr�obgmȑ�'��V�ޔ�"�I�� �i ��K>B/�Ӆ� ������]w��ឪ�\�q�^�t���K/�`�9�1s_�/�w2��K����YbƤ�4���{^ޡ9��q���R�f�
b��Q�b�w����3��s��3��&xz ��J�S�R�65桰���F#�(�����F�����䲩�Iܫ=������5�p��L��|��k+5~�.�05��p�u!�7�)\!(B�{��!_�3.�G��띻^������;ڻ���3�߲���W�S���޹��[��<6��d��lrA݈`Ԍ͡���;��b��W�����=�Q`u�d���#�a`� J9������Qd,,d�R�C'N�/��}Q`�u�����E�E��<�����L:���{�����ٖ������.�GT;Wt�;z-����/��Z���r�'�PeQ���2�����]V&���6t1E{tuh��F4Xخ�34L4]��he����2籃!��a��Ui8��G�^��u�����/�>�)�_����"�O`;9Y!�
�+M�!��O����aM���>��J� +������""Uڈ卋|�Գ(L��b�/�5�������@�Ə��w��Lzٲ�������AG;��,i�*���������0Đ�7�2��u`|�������j�&m$:q�o+M�z�5>霞����I��������H�8��K;`�9\�����Q����A
H�7�MQ��,}/�:~}�z�ȵήYH��mQԞ�#,��`�"�ZI|�<\8u44)m�:	��n.b�_-�O�Dq��g�_&�	y �th��l�'��dv��{^��TT���{��RvO�}#QI FYX��!�, ��(���=�{)J�k�w��z�KVW<F�P��,*P�k��j���,K��r���Y%1u`%��}0�f�2�Iv-��r�c�V���;�?C��o50��B3Ĥ���[?�����Rդ-4$�9����U�}��	%���9/�/)X:��7�P���AZ�d�7��ou��0'i*����_�	������R%��ǿ{����?��ds���M��B���&�%�r⊷� tA�9�e���x�&E ���/��0�X&y�S�Y��	���`���13�-�$%�q�� 4	���pi)���CRg�b.4^��aX&|�����%Blc%/���7�eh�g"t ����kKD~9N�f¥�[ ,ᐆ�f�H��!�R�-���~|�b4����	�~�h��Ǝ��!�:q�q���N,������'W?���JS�{�x�B��
�c�� ��k��
�)�xr��Cg��U^�u�ul����̩�Z���ÉZ�U�9�n�K¹�i݈Īqǣ&��W	�̛x!����E�ݑU*�I)F\�(��յ�QK�S��l�j�|6b�p������m�m#Y��*��4�)I^�)�Ғ�ْ]��-D���K��d�I�C��Un�٧�}ؗ�؇�Ǯ?�璙�$���5�d�-�����s�N2�PJ8�C�W�$�	�,����'*uw�U���JՏQ�<ί��7���~5�Sm�5f4)�|Ek�ก�	G uxْ~�_�:�%
HO���c-������nԁ���B�����*�DS�,)"��M4~/��~jԍ\q��V�C�aѝ�eB'���+wc��*��NN����X�\���3�b�
/���1g'��D�^���u�I����U��[1��a���_�3պ~a�\9S�lO���F�2��E�i��۫��\0I��(�����[��X����U��T�.��ʉq�Ԗ�oP�y$�V߰�l(�1PU�
iD��0'�3�&�Q��B[x���5�70T-2݌T���z�.�	8�=�њT�%R6��H3��E*/���2�����ᦋ#9�ٰ����H>�k�?�^�E���/����#F,�<<%��u҉���%�F����P~��e#t�+�ܨ��6X�B~������?�B��8���3?���g~������_�4�8XZ�����tc�z��Kud�8�հ�:�4�?F�E����=T�~�}T�X]�c���I<�)��C�3��J��gQ��|���ߠۥ����S(�sV~�����^N���,~����u���o�n8����/��,�Â߀pY����P�Q����O�g�(��}�~�I�C�b@R<�ij!yq>_e���7�E��ɍ�Zx��-���m���&1i�H��K_��W�4K����YH�˒�������e-�w�b�l^�D���ʹ\�aq���9n�E���y�@D�N�^�]ѕ��Q���(@�_�;R��Z/�_�Ks���BMˑi�|Κ�J����U�*u�k�HO�TFWp.���pv��Y_��öO���H���)����|F����i���6��ڍT�o�6��̑F��6ƥ����d�[��{z!g�%+y1|-mJU
��r�������1Ѿ�~��Z�IS�gH�f
��9��</4��˟����@N��n�o��q��{��[�X�
*�l&w)/rg�S����/-�������0�$lVM�;b` 44!b$��-�|zx�k�6ќv��0���R{�|�|��%K��g�B�}t;EW��c�F�4���lm����adS�x��3wz�!���/"�\6�V�1����8;i��͍���Y�N}�?��H����՜�=��ga�.�n#�e�0�e��2c.�[��3C�`)<Aqb����$�����*vZ1K|H4:��u�v�������VqJ�˹X��/h/��?���n�w��L+R��iC�`���-�S��9[ξ���I�V�C��jWx�-��|�-w�丿�ۑ����t��9�]�,�#�p4���a܍��F�{"��u>���Y�A���>B��+}��/��ݎ2hؤ�#庂�Ƒ��L�i�v�gv���M ��K���&)wv�����E��=��w��a��)���楦]�j����L�3̣sf��v�ȥܫ�^w�:�_�?�V~kf�n��S���lJl�C�s���)���_��*b�tԠ1|ߎ�(�#Q��!�y`8����H.bR[�9V�/'aCӜڋ��B���&X+c 2�٪������w͍׏�K�m���������l�H�4*q���eB���|~�}�`utm�ӷXM��Z��Z��l�K �+�ǫ˙�ȗ PT̲��`���FΓ.	f��0�/���e�>�K��Ò�����Jԍ9ǒ�����5#�m�yAU�^r�S�dK�~mm���$�wf�&)�.��!>��� �/eU�0���?}^v��By�Y��4y.Έ���$�ay\�VVY뇃k�m_~�G�8V>j~�����wa�i�g�o+/�?��^���?�^���Q<@�#?I���/�����-��������&�Ӕ���
	_��,)B$��~��*ڳ��/k�6ҫ�5���-K#�5:M�´��f������ۓ��:������P�i�{P\�=T�+ʳ����	�|�m��tW	�6���,����
����h�_ZT�R�>� �L�W5C�Fa��KZ���PphP�6��~�������02�h�O6r�pҟc;I�x�s}ـ�̠q*MqR+^C��Ɂ�<,�9oPb4�pOM�@�������:;w�[�����4I���ʯ�#+[u�������덍z6�G}m�c��6��:�[��m�7���k�0�,��#��a�"�(�s��a�j�PWp���K����rYZA������������o��S{��}���|�(�����6�������FY�?�>��?�Wk�n=}�:{��;�zC?>�}w�w*����
HVW�x׶ʤdV����6��4+�	���O��Go�k!��׮���?\ᑀ��i0D�b2N�W���>��x�����+�#t�t}o�K�w)���b�u�A/�;S��_�Q���ݰ�LT��T�ti�b@Μ*Z�`�;��'�;
+v��ڹ+�D��
/�<���ST۔ݲi���GWp�lف�p���}э����o^6r@��嗶�r�$�/�OZ��ǈ;(`]���me��<h0؝�V�%�FO��h �tT��'���G�.���r�@�P�n������ã��e�l���F��#�v��)$��JsB�r�ۑ0t qu�5b]�=�:��d_I^K����5��H�R0�J��~%)a��?�C��MK��`7m��WZ�= �\�*�8��0��+��D�!�-T(}�'�{4WV]�o2D4���,�{���]GROU�X�Lh]i�|���k5�yՄ��)�O��Y��5K%��B{,����/ە��U���Ӫ���\���*�(���ए� <��V�P�+n!�vR��6�n84�;�,��ʦu��wz����>9���*G���@����Lm7���r:S%�Ӵ�f9��q�Sas���3�I�&��}F��'������:�h�Sr�gtʠM9���HK2�F�H��2J��E-�ɂ{���OP�^	��W�C��7��[�t)r&�J�R`�-]�R̭�t�����,׷�o��aE�O�`�u�,�맲g@S�h�Z>\*��b%�KY	��%�زRƼ���`��$j���\͏L���i$�;�M��&�"`1�'Y��s)ort�@�aЇ�t�il �1�ܯ�z�Ȁ�Ǳi�0S���I�s��ْY~cZ�����G"����Ӆ/�,�䵯P4)[`�n��)�˶�Қ��K����+�l�X�ӂ,0.%wT8��E]J����0�qF*��(a�ջM�T��FF�3	M��3GN�Bw�kj�Ͳ�*��#��ʦ:��(`��~4��|��Dp��`�i�[z����͹֠Ur�:��"����������8�l"��!�(�+�!o��l2��a؋���2��U���1>ٯ�K�UF�9�bds�E�0�War>؅���j��S��7 �Ow&څ�R�S0:��q7�:��,��_�ccu�s��h�a*8��nB��.φzaU�$U��Q����x���!V�e�*�BU��F���b�4��c�!;�����G�tt+%c��w�[i;�ޘw���H�	ʚ�� &Av����::Gq'L�8y"h�9� nIp�iz�������Њ�C�&�R�'�mf�Z�D�t�plY&�x$յ��n���ǵ���~BW��8u.	sJ������o��e�B��&���3U��3m�=���{�~�1�O(��Cai	[U߲�BE7	T�Zs|�ANF�Gq_�a�����C99W*�09�u|S��	�h��aw5��K2T.���~�����W�8��ÉD���$�p�AŶ�?i���+���"���<ʏq�dc9��^�ț뚹�g�6~bϹ�%'��0O7�@ҟ0*1?���U���9�������y#�g�i��B����~���O]�|s���獊�n�r��?]#X�a~�"������@7���$���ȝ��	6�Ƞ�Eݰ�fBM7�q귚�#������V)��Y7�\]��"��# �z]!͚�b#ȳ�UVet��b2�7�>��C�a�:�#׹�'GqT.�ٴ[M`��L�=0EKyJ��3hw$�:�]�E>D4���tK���ۚ�Q���R� a�B(b2(�f	-�:^y�KÄ���l�����#�2J�J�S�T�C2z芉k��4���Z����5=Ԑ���]$?# #Y�&��$�盻���ә�b���y�������x�0�M����v��6M�R?�z�"͜�'�F��������Q����x�F����M�
�eX�r�
�)1�%^�Q?�%�Շ�|����Vi_�P<�r�^�VǗ!��'�P$��(��V[T�P_��n/�)s�� �8q�
1�en�VAЪ)U�ӗ�>#}�j&��B��جi�h2��$BF,}S��4nɊ�
Sa�Rĵ�+^�ZS��Q*ZJ�c��}���Kb9��&gR�7�{5�%l����{r�}�������w������"��0v3���ך�UZs����}a��m2ĒM��Q���ci+�|�$G#�'���X���[��U�lb��8���i��'S���>���"
��k��a8���wBvVp���&	��Z(���?N:o7ӷ���̊���`��զ�Y5���nJ��a���$t�s�z����L	��fC7����iKш=PϘ�T� ��$w54�a,����6�6�ϐ�{ۇ��0L��&�~� 0cf��E>�r�)����wզ���(qtB�T�Wc����qz�0M��.M@�5o��vߡjjx���~�DOo���k����!���@?gm��$p^��i3��I�.E���_�X�Mfj��6&�9C�na"p��!�w'F�,�<E$�Q�2���B�<�Py�����^L��\�I8����Ar��`�{�H�"Hv��W��T�߷q�P������E��U-�$3���/+)*6���4B�V�@�&�.MQf�J���DhOC�0>T�K�ͭ�D$��d��%�Q��<j�#L~>h����i��z
i�v�J+�t����6�t��4��] Af(���%0�(Ԧ&�u)�MՖ�5&5Z��8�n8L<�c'D�!��L�)�e5���5��5���0k���t�����`C��Ku�7�"b�Lv���S��,Sd�Y�@�Չ�=�p+E
G$}a���˲?t%���g���Qc2y[RIJ�&>)�T��!���y��d�y�B]�-[�D��A���L�Z9�2jv�X{�?���f-��f���6�=�=t��
	�4˝"��f�C�e���5��:��{�[�~D�����8�1	p�-�,�jԁ��#�?�ℼ��'p�ں�����*��Mк�._nHg��6�����4 ��8@�I��Ѡ*���d����e��v�L���4�@��DuP�03��ذ��f�����l��W�J�u�AB�� nSBY*4����#H�W9lh��a�ۇ��vO�ov���_�&\�?5������آ�<T��loj�9�V8���2۴V��w[	��M�-��lr�S���E�~�8�3k�.�B��h7$^t�=1�4%/.(��;����D�٦ݪ��P"�W�VNv�w�[��*�ӣ1�P;��mM����@f	�S����NGGA���M�(��Tf�)�,�|�D��� �fJ���ʍ��Y.��?���l�#��2s��z?�"���z8Kfp����Aצ��+�D��J�a,S�h�R5֙�X�
��:��������A��(��X���'b��IAs"�@�:��R��ٓ/�̃�ힲ��-2��HOު�X�}�*6��wz�=�*��z0L�%K'��S����z1�fd��34��� l���̟����r$��<wjj�gD�� 6��$�Y:��@s���^G�y,,��I�7�j�3o�i���\�b��Đϟ?����
�Y�p.�Y��經Tū�~��K���!�X�ۃ��(�����O�zW!���R	7������uqB׋j���L�ɚZiu�Z���Z��m4��Gb���[ �T��M��Tz��0�0b4�L&��2(��T��C��D�u�:S9{��ny�������k�$��"�TĨ���ad\���_�}�h�L�f"j�����h[2�{o���$?���'�E�U]'g'��>^_��bjt��3��������`69욛W0�!�bf��iDk�R�lP�|.�ޘ��ݨ�>�0��� �5�
|�{t8M��UMC٤��K�!���O�DC+�&�I���]����;��7�3�b�l�����Qv�1�m5׈�n�
ŕj�6���7w��Jߛz�܀=sΐ��c���5����<mL��J��w��iv�`	BJau@�`��l����9B����޻��SؽXH��F ���ȫ7/Hr�is����0U|Ez�Sm��U:e�s���)��Fe�c��+�H$�Q@�s�i��?j<�6�O}W"-�p��^�*��za8(�@Z��'�w˧J[���UOg�@��_���_�4��I�H���;7~zZZv%}��M�r�>KYc��Dr:�w���|!�J��p���-\}�&���g�A`�Ċ��w/�H�� ̜m�7E ����ʏ{!r�7A4~�oc��:�e�
���G��y0���LrD���M GD� l,���`Y´N˱���9�:F�^ce�Vj�&߷��oz��}͸��z>�u���+@�۲�m�N�e\s�;��������=��Q�$����˚~��lo_"�~��3��/�����6Ʃ�9�	ߙK��Fz̪�J+f%F�q�$����?�	�-�fPK��{�&���Ю{�-Nn���7�Q87֋�2&�qR�� �K���Iq6�W�y�؆�=���t�=�Ӵh[ն�K%���oK�$s!-r.� dt^���fJ���m�E����OJ�3#�[e	�#C�1�s�S�&I)��mQ��&Nk��6Rk+U���{-)Ž��'�0�F��fx��Kb=�\�~꛿�m�X�>��~���ʞT�饦{�Ol�E���rmx����z+�bǹ��A�<V�I�I8���˅�d0r=�q<2D�d���z�7�ƪ��YV\�Y���l!�~�+f�XA��g��;007C���~���n��W*MŔe���n�K�y�o�:`"�u�2˺8�-����.*;8d�/טi>��a�=�W$@#<�.��a0Bc�u���uX�ۗU������^��-�rƀD�1���TV|�19�y�υ,��/(��8 Q�=�^%����|Y�u�S"*Hl��TA�M�gi�"��Ee,K:����j*hGi�f���V2�h��QM�����|�F�F7���5��0�st]��)��7Ds$)
���O� f.�E�r��zK�@�L��4(֎�R���˅�,�Gb��bc`�� �r�@��+�[B(�(!A0 G_&�� 	N�>!e��[A�J�g�.L�X�?��7比��|SV+��� y��>�����?FdC���`k
)`���E�A� ,�����O�n$��&�{lI�QH���z{���q�J�:gnQ�植aNX!ݭ-��ܱ1�~�k7����a�j�e+b��
�a�*;��u˅N�N��;�_9������p�C�8�Rs�~V�ggu���&�rE�ܒ����3��	M�(�L�ә�B���jMgP
���Ci�'	�+M����kz����O��U�@ڻ���GQ@e#���z�u�k�&\4q��+iȚZ������ʷ4�f�0=�]Q�;1���c�-�����ߙ�2�ʍP�Njf/t�1������s��}X�್ե�/�aʰ�i+�7�sV2�l�ܠ<'��ܕeN�V��T�����g[%�eo/<�b�.8���ߥ��,���[J�Me���
kF�Uo�S}avO���djZ�8j�F'{��K�v>���~G3ג<}�k�8�ė�&���uR�q�|�ѳ�B�s����;5�ӿ��6y0<=r�M��؀4���MU`�6p�������a6��88��{�w��~s
e��vv�
^
`��3_�呚��ܬpQ�+qKɸ�)M�צ�P��vbF��#ܟcDg!q��Ձ̰�GɑC";r�Z+�����5�m��iH6�������=s'��_6"��,�zv���R����bJ��K�(J@"(#E�S�4zG~��0'���؈�f�PT��;cc��b;1�@2����t�A�9Ƽ�S�y@掍i�u�"9����0w��ΐ����L��z��������7��������[����(�Oǉ���}�Q��)��uV=`l.7�����M�:�b�'��ՋQ�w�Z��T��
�Wʲ�A�WtԠ`��P��L������
-"�L�6���	{��������_(��D>l�pt���������)c���������}���
\JѼW���0B?Pi�@l��K���k�Hǫ����'h�g�l��c�aGjt� ��ש��
Yl\*����4؍�� 	��[QDRa>�?G�N9�����yT=S�*�}kr�|e��F��Ƴ���������������<}bP�t�ω�<I���\�Β��-�	�q�$��� ��*���m�����V��{��G�e4JƏ��%�n`s<<:�{�^�;�WK4�8��� R����M�U�^#%]�!yx��d�K��T��z�S��h�>�]zJ'�{;Gb�������.��nq\�#�g��L?B2��B#����y�]{g�t}ZM#|�����B������D2/������y0���=��{N������8�	G䡺��'�z�ңQ�Nɿ��[��,�hS����v���T��?��m���V�ŋ��	�t��ΧT:4A�\��=9�Ir�������^K��Hz���S��3�:@��kf�~���C��3�y�o�r�Y6S���(pX�,kZ䑋����}GSr��;=:�u��{�L٨���*�b<:>5ZgA��d�>���$�N.�c`�Ӥ��z���s@���mZ ^�E�� �����{ ���;Iec}}����[����>S���v��d<�����3��ڢ��c��Y6��g�g���o�}3k��iE S��zV�W뾗qәJӖI��_Oռ1{�L�e�0���&(�����ˍ�l�{2�e�+D�1@wV��E[��1ݚf�/<���i~�5�0ss&��:��O�YU�oe���:��٧v�A���0�s�Y��>Tx�T�~:�jG��V�_f�
d��M!����W����6���C=LEV a�<oq'DP�q����eD�FT�ӵ�vvU�)���1�JJ�����J"E�� C�qYxܴ�|�J4Z�^�v<�;ct)�b�uE�p2:��84����|_v��{��Vz7�U���"��(�
,�q��Z��mT���ϥ�̯�=áڢ�I�a�u懍}�ueu,��P���=��<�_2r5bdd�!�!�(���M.:aR㗰��4��V�)�p��~���L_s8:�5G�Y%h
#��HU&���n�S�r�7멎 ����)�Ԟ"�ҔE�3F�zJ']Ƌ��ys"�'���Il礇'�gϲ���
+��p;g�v^��?��_��BTr�39�1��ru�a�'"������#��h W�1F�
1Xj�I=7��A��A�r�� ���&�ZWI-�\�l�ǐ�[�\^Y���gBH��4�Aޞ��;E�4��4���L��(I�$���I%�*�^}Q��K�g�V 'L�<9j���'��`r�j�-�QO_�V^�9>S�ZXinJ9�_��U���۷>ƌG+X�������x|��v��M��.�z%�i��ٸ��� Zs���=@w>�3�Y��'6�SM���v+CV�ƤQ�z�bu�`�_�#~�Ƣ���@��g���f��p����r��%�ik�C5Y�LS�{5�K���HE�~���x���)`|o?<1�q,������~�dw����pҶ�
�X�0xT�c�Ӟ�B�磁��c���]|��+�������ج�/�x���K�a'�FqC��5r�ӷ��X}��7W�;U�W��x=�F�}/��m��p0A�6�L.�Y�,���P��G���@P�f�F�H�+s�A�B\�?�V	5p��U�<O�HI0���л����S!�6�{M��A�b��I����xP�����
zv<P��I���O�Wh��t��Wp��K����L����f��Q�b9��B8�T[�]��`@Ӑ�s�=�����Ka��0��*�?Ԇ��b��R�D�B�ʵΎq�ow��'��˲��E>+�n���5�8���⡭�3d����f�I��B��t6�F�y���h:�mE��Q0��
���G��ב�����91����ⷆ�}�YJ�e�� ��o���g��,�Xξڇ��^�v>�Xᐻ�nT7PF�jo7������n�O��3�
;�r�!"�K��:�0�Y�����^�FZ��X#����g�vu�mѝ����ncl��J�M�q.b�����4��,��^�G|�C!s��Rڎ���<�Xr;7Y�c�=��c��}��~[0�)��'������a�W�f>è���R!�	�z�*�~2>���-��;�0���Z�}�f�&3�5��8�4� cJu���mvu��MQ}���y���i/U{�,2�
ᄡ>! �b��� ꡞ3 �:�5d4���>p����5g�lzTT�	Y)� 	
%�Bqj�LT��i݀N�tL�͕٭�e4c�0
�à���Ydd,�x�lf�J�-"���6����ۣ֩�Zu�ׇg�wO��5	ж	�f�%s؍�Y�V�?��Ue�k��Ҿ�c�C��]���׷t��/vP�	(*>�$dE2��)��H�D����t̸1Bz\(��#E���ػ�T���N��fvZ�h����˝��U��x�i�k�|]������y������ka�5����`�T����'����L�ɪ����Kj^�}�O�h��M{����?ew�ǟ=��V�[��fْ��d@��xPIІGd�<V(�y[����;��]T�Λ�.�,��z��u�?j���c�31B3�R�L�K4lڠ���?'�(g�(o.�\E�6�j @Z�ք~J����R��dtN��a>g<g!J���j9���������L����g������	K����b�V�����Q���s��Ӟ��-�n��fVGDlzӢZ�
;�t��ѵ���%��C1�����S��czzIw��U�\)c�=5_��JN`�(-�Y�<U�\�^Ƽ��F��E��yǩ`�&6��.PB�QQs�e<��������`E��TZ�c�	h�t]�m./N�,*d������_�|�41TQ�k�a��3	�bC�sBJ�j�aۀ�<�r��D%��{�f��Q"�e$�Aa�S�_��ъ�����n6Ŵ�����{	5����$Z�E/T�pG�R�!�,hW��[ 
q{�c�(�2~� B��^�ʳn�D[;�0�5�!���N1�CU�!8�u���_�`���2DSa��̮���v�c������N�c�Pt��~�''!���(/�j��gҥ�7����+e];֚O���	�."�{f�̖S�"gŁ���%.O�B��pZ� ��wv�?"��Q0#��P��54�2��89��ѣ4 3����ih�,
o��]Tn��EY�*q!�;�B��?pE������pV!l��s�p���z<]��y'�šʆ��BrK���T�S��t��㽏|�0H��7�$���A܀}�ꨍ��'�/�{���؈�!o�^��j�Tڡ�ӷ�z�J�γ�{�Ʀ�K�N��C��{wR�g�B{���o���a�륿ŀ��g7>�p¯S�<������Ď{ż�(?�[:�<�� ��qyY�9��j�y"�8�j��]j7�"���tBD�\+Rc,V�Y4���ǳ7���������|���ԯ�i%��pi[�H��2�,�O�x*S��K`9+n�(7DyC��e�qw����)�V'�Ik<B���Qd0"��G2�� o��`@!�!��A�y2"w�r�r(�\J�bO�܀�K��Ff��f���f�I�K�^b*�����.����p]r@� �[@�%��-��\�_$��K�Q�!Q&*�z�Y8WO�x1v;]0pT�{�s3-�M�۩ܳ�[(#�n��rqYY�i3ۦxe�I��3R�X+!s*�AdO^�bu��f섬#�6���k��O�;ϼj��ܘiv_�H�X02�=���DW,�͵�uZVI�iӖ�(�K'��G�?" �b��+��z�Q¦)��~�I��2䔤��|��^��Q�T�D���*�{,*�i�r>�7b����Ѱ�(��G��+��m�X�I��~��j�w���c�~2��z������@��ɰ��~���Fc#��{��t}���*�?Ƞ�C�y/���%Ԗ���s#y��oH--�>ٻ���[�x��H%{bE�g)]�*	�E����LV�s_��(�L-�P��T���~����Bx3�t:�p��X����x��f�O��d�H/���^U*/k�+��"<˂^�{Y�x��K�����/;[��k6�@�Q�Jx�����mzK�!����I ���լ2�m�*Y`8LC!]�K`�^��'�yY�*��*���T*KHl��@��d[-#"U�mL���%�oYD��jp��i��7� �g'큒&P���؜��\EĽT��%u��;��W�K�,E�Q'%��aOkE�"��N"�Oa8I�sF�\h�T����|��F���������-���<����㿾�^����-�����x�э���\��[�q{!|4�ۓ+Q�Bj�_:�U�>I��B߫������m�y�����0ei���Z�ݚ��g��a��/_������'�	�n���ߘCx�<W"g.��d� n�ٻf�0����V�W����?aѐ�<e��ǆ8�zNֽ����n���5ֳX{���݋��I/� G���D��#O��n}��ޘ��2�iS]9�Y�u��7����!����^�^B���Pn(����!�K:9��4���q�x���6�f^I\AU�15����2L[`�o���<W
��������i�o/2Y_"����*)������L�PMR<(�Gu�xQ|�6��9���T�jSפ��k�:,�+�Xh�i�KN�%<����P�H�B0���"���%��APT��N<�E�hQ�*�j��@�ε�L��8Sڭ���c����ڪL�kl�6�u��jW�/�� ��-0��PZ���^����vv��щ��f[�҃vܮ���x܇[Bˬz���+���`�t����	���m�����6��ב���z�����-
�$�>لU=��'>Qc�b�������q��pq*ӱ ,�ȡ��I�t+ު�NE��t��hp�Xw����y%v�A/�()dn�<����Q��Oѽ�%��$| N�M$$�W�� ����I�.ΉU/c�O7��R8�c,L�L�PҜ�eGe�T�M��{�1����D�-�e~���\M��x2ä��$�s�{!t|��_�F3L���y�o����tq���'<z�&�#? <�\Ĥ2��a0&8\��+AxUϻ&�<`(v�NؿGO��!
 )�r?����i	��SK��(b������`TC�%�=�h�P�	��3_족kw�!-&�L�bs�2�j�a@�R5��I&�X]8��v����N�@�3�ؑITcDp �iR5�J����v��F���X�ռI�?r���^_}���QX���ޟww
���i�T�������T8�E�^�(�6�4T��Q/ߺ3Q_��zZ"��S���
�fWf�I�k��1�1�h�M�1��N�M*�۞\�R��=f3���R�kErÚH��J��
<S��9�N1�P�f��`�5� 1r�
B�;
�~`����EC,A�q�j�R37�w�A$ID
�jN�;L��"�*]kv1�:
*���}@|}/��
 9K���֍���B1+ԊU�}<"o50�DI�DV�g�L�@A�**�����������̉�0_�P����8��Wa����E�L9H���z'�ճf�ݧR��l�k�)�	����Q� nz}ٟG���#t��vj̄���[Sc��;k�ˆ��݌iP��d���e�F���}L��{��߳�>�d�A˷����01v��V-D���쿾�����������3���l���*�Ǐ�\$�-��]���Ca(~E>O��^�T��d��?��ǏQ��p+V" ��ۀF�zf��Y���}>?V���e���$}��X��M��?�o�.}5��{�iN�r5�c�֢��e��:��Eg�M��ԯ滕.C�m���<��;� '�淨�U�2v��+9!,��*�I2��7�(ۧ��)�h͋<�Y��/*�15�[�ƾ�$��4S��B��єQ�B]�X-���z����p� �]S`�c	3"aiP �4E[؏��������&�H�R�Ϧ�2:P]�S<���{ʵ�FE��EB�d��'�s�_Y4�g+�80��n� -���,[��U�w�Je��1���b#����p<�

y��������ic�ق��:���1�>z8��e�(Pu"JJ���;�%�8*���x��Ð��e���7(RAi�,M���æ��+!��_��PXt�
q�`%(ن��AL.z����n��´�_�m��
e�% t�˨A����%���w�
surSgԔ	�2,Rb�QMH9�� ���ֹc�
�z�?�|�Bl��#�j�+)���D���ʋ
����"Q�x̢��u�Y�尣K������U���d{�d ��Z�.1�a���ht�&Hde��Ir	��J��=�7���Dͥ(�61��x9���$�!�E2�!��oR����� ת^�`h��F��TJ�A��1��Ӓ2FT���hi���u�ji��P!`.x�%PK4���(z�>�$�i!�$V-J�-��X�.>����,>����,>����,>����,>����,>����,>����,>����,>����,>��?��� ��� � 