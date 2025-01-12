#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.6.9
#Date: 01/12/2025
#Description: "installer.sh" is part of the core of LAMW Manager. Contains routines for installing LAMW development environment
#-------------------------------------------------------------------------------------------------#


#auxiliar function (must be override after change tag or branch)
afterChangeBranchOrTag(){ :; }

#this function return true if computer is multicore processor
isMultiCoreProcessor(){
	local dualcore=2
	[  $CPU_COUNT -ge $dualcore ]
}

#This function issues slow execution warnings on single computers (or VMs).
singleCoreWarning(){
	isMultiCoreProcessor && return 
	printf "\n%s\n" "${VERMELHO}Warning:${NORMAL} running the LAMW Manager on a ${NEGRITO}single core processor${NORMAL}, this can make processing ${NEGRITO}very slow${NORMAL}!"
	sleep 1
	if  systemd-detect-virt -q &>/dev/null ; then 
		printf "%s\n\n" "${VERMELHO}Warning:${NORMAL} running in a ${NEGRITO}VM${NORMAL}, check the settings to enable using ${NEGRITO}more cores${NORMAL}!"
		sleep 1.5
	fi
}


checkOldCmdlineTools(){
	local ret=1
	local cmdline_tools_prop_path="$CMD_SDK_TOOLS_DIR/latest/source.properties"
	if [ -e $cmdline_tools_prop_path ]; then 
		local cmdline_tools_query="$CMD_SDK_TOOLS_VERSION_STR > $(grep Pkg.Revision= $cmdline_tools_prop_path | awk -F= ' { print $NF }')"
		local cmdline_tools_query_result=$(echo "$cmdline_tools_query" | bc)
		[ "$cmdline_tools_query_result" = "1" ] && ret=0
	fi

	return $ret
} 

resolvesCmdlineToolsConflicts(){
	if [ -e "$CMD_SDK_TOOLS_DIR/latest/package.xml" ]; then 
		rm -rf "$CMD_SDK_TOOLS_DIR/latest/package.xml"
	fi

	if   checkOldCmdlineTools ; then 
		if [ -e "$CMD_SDK_TOOLS_DIR/latest" ]; then 
			rm -rf "$CMD_SDK_TOOLS_DIR/latest"
		fi
	fi
}

#set old Gradle from $LAMW_INSTALL_LOG
setOldGradleVersion(){
	[ ! -e "$LAMW_INSTALL_LOG" ] && return 

	local current_gradle_version=$(grep ^GRADLE_VERSION= $LAMW_INSTALL_LOG | awk -F= ' { print $NF }')

	if [ "$SET_CURRENT_GRADLE" = "" ] && [ "$current_gradle_version" != "$GRADLE_VERSION" ]; then
		OLD_GRADLE+=("$ROOT_LAMW/gradle-$current_gradle_version")
		SET_CURRENT_GRADLE=1
	fi
}

#prepare upgrade
LAMWPackageManager(){
	
	local old_lamw_ide_home="$LAMW4LINUX_HOME/lamw4linux"
	local old_lamw4linux_exec=$old_lamw_ide_home/lamw4linux

	if [ $UID = 0 ]; then 

		[ -e /usr/bin/startlamw4linux ] && 	rm /usr/bin/startlamw4linux

		if [ -e "$old_lamw_ide_home"  ] &&  [ -L $old_lamw_ide_home ] && [ -d $old_lamw_ide_home ]; then # remove deprecated symbolik links
			if [ -e $old_lamw4linux_exec ]; then
				rm $old_lamw4linux_exec
			fi
			rm "$old_lamw_ide_home"  -rf
		fi
		return 
	fi

	for((i=0;i<${#OLD_LAZARUS_STABLE_VERSION[*]};i++)); do
		local old_lazarus_release=lazarus_${OLD_LAZARUS_STABLE_VERSION[i]//\./_}
		local old_lazarus_home=$LAMW4LINUX_HOME/${old_lazarus_release}
		[ -e "$old_lazarus_home" ] && rm "$old_lazarus_home" -rf
	done
	
	[ -e "$OLD_FPC_CFG_PATH" ] && grep  "$ROOT_LAMW" "$OLD_FPC_CFG_PATH" && rm "$OLD_FPC_CFG_PATH"

	#fixs 0.3.1 to 0.3.2

	for i  in ${!OLD_FPC_SOURCES[*]}; do
		[ -e ${OLD_FPC_SOURCES[i]} ] && rm  -rf ${OLD_FPC_SOURCES[i]}
	done

	setOldGradleVersion
	for gradle in ${OLD_GRADLE[*]}; do
		if [ -e "$gradle" ]; then
			rm -rf $gradle 
		fi
	done

	for ((i=0;i<${#OLD_ANT[*]};i++)); do
		[ -e ${OLD_ANT[i]} ] && rm -rf ${OLD_ANT[i]}
	done

	for old_fpc_stable in ${OLD_FPC_STABLE[*]}; do 
		[ -e $old_fpc_stable ] && rm -rf $old_fpc_stable
	done


	#check and remove old  ppcx64 compiler (bootstrap)
	if [ -e $LAMW4LINUX_HOME/usr/local/bin/ppcx64 ]; then 
		local fpc_version=${FPC_DEB_VERSION%\-*}
		
		if ! $LAMW4LINUX_HOME/usr/local/bin/ppcx64 -help | grep "^Free Pascal Compiler version $fpc_version" > /dev/null; then 
			rm  "$LAMW4LINUX_HOME/usr/local/bin/ppcx64"
		fi
	fi

	resolvesCmdlineToolsConflicts

}
getStatusInstalation(){
	if [  -e $LAMW_INSTALL_LOG ]; then
		export LAMW_INSTALL_STATUS=1
		return 1
	else 
		return 0;
	fi
}




#install deps
installSystemDependencies(){
	if isRequiredAdmin ; then
		RunAsAdmin 0
	fi
}


getNameSumByParent(){
	parent=$1
	local -A sum_names=(
		['getGradle']=GRADLE_ZIP_SUM
		['getJDK']=JDK_SUM
		['getAndroidCmdLineTools']=CMD_SDK_TOOLS_ZIP_SUM
		['getFPCBuilder']=FPC_DEB_SUM
	)


	echo "${sum_names[$1]}"
}

runCheckSum(){
	newPtr ref_sum=$1
	local sum_type=${ref_sum['checksum_type']}
	local sum_value=${ref_sum[$sum_type]}
	
	case "$sum_type" in 
		*"sha256"*)
			sha256sum "$compress_file" | grep -i "$sum_value" -q
		;;
		*"sha1sum"*)
			sha1sum "$compress_file" | grep -i "$sum_value" -q
		;;
	esac
}

# set wget progress bar param
# compability function to wget2 client
setWgetProgressBarParam(){
	if env LC_ALL=c wget  --help | grep  -q "\-\-show\-progress" 2>/dev/null;then 
		progress_bar_args="--show-progress"
	else
		progress_bar_args='--progress=bar --force-progress' 
	fi
}

getCompressFile(){
	local compress_url="$1"
	local compress_file="$2"
	local uncompress_command="$3"
	local before_uncompress="$4"
	local error_uncompress_msg="${VERMELHO}Error:${NORMAL} corrupt/unsupported file"
	local initial_msg="extracting ${NEGRITO}$compress_file${NORMAL}" 
	local sum_name=$(getNameSumByParent "${FUNCNAME[1]}")
	local progress_bar_args
	
	setWgetProgressBarParam
	echo -e "\nPlease wait, getting ${compress_file} ...\n"
	Wget $compress_url -q $progress_bar_args
	echo ""
	if [ -e $compress_file ]; then
			
		[ "$before_uncompress" != "" ] &&  eval "$before_uncompress"

		if [ "$sum_name" != '' ]; then 
			sucess_filler="checking ${NEGRITO}$compress_file${NORMAL}"
			startProgressBar
			if ! runCheckSum "$sum_name"; then 
				rm $compress_file
				stopProgressBarAsFail
				echo 'Checksum not matched!!'
				exit 1;
			fi
			stopAsSuccessProgressBar
		fi
		sucess_filler="$initial_msg"
		startProgressBar
		$uncompress_command
		check_error_and_exit "$error_uncompress_msg"
		rm $compress_file
		stopAsSuccessProgressBar
	fi
}

getJDK(){
	checkJDKVersionStatus
	if [ $JDK_STATUS = 1 ]; then 
		[ -e "$OLD_JAVA_HOME" ] && rm -rf "$OLD_JAVA_HOME"
		changeDirectory "$ROOT_LAMW/jdk"
		

		if [ -e "$JAVA_HOME" ]; then 
			local realjdk="$(readlink -f "$JAVA_HOME")"
			rm -rf "$JAVA_HOME"
			rm -rf "$realjdk"
		elif [ -e  "openjdk-${JDK_VERSION}" ]; then 
			rm "openjdk-${JDK_VERSION}" -rf
		fi
		
		getCompressFile "$JDK_URL" "$JDK_TAR" "tar -zxf $JDK_TAR"
		mv "$JDK_FILE" "openjdk-${JDK_VERSION}"
		ln -s "openjdk-${JDK_VERSION}" "${JDK_VERSION_DIR}"
	fi
}

GitReset(){
if [ $? != 0 ]; then
	git reset --hard
	if [ $? != 0 ]; then
		changeDirectory .. 
		rm -rf $git_src_dir
		echo "possible network instability!! Try later!"
		exit 1
	fi
fi
}

gitCheckout(){
	if [ -e "$git_src_dir" ]; then
		changeDirectory "$git_src_dir" 
		git config advice.detachedHead false
		local current_tag=$(git describe --tags --abbrev=0)
		if [ "$current_tag" != "$git_branch" ];then
			afterChangeBranchOrTag
		fi
		git checkout $git_branch
	fi
}

GitClone(){
	git clone "$git_src_url" $git_src_dir
		
	if [ $? != 0 ]; then 
		git clone "$git_src_url" $git_src_dir --jobs $CPU_COUNT
		check_error_and_exit "possible network instability!! Try later!"
	fi

	[ "$git_branch" != "" ] && gitCheckout
}


GitPull(){
	if [ "$git_branch" != "" ]; then
		sucess_filler="$(getCurrentSucessFiller  4 $git_branch)"
		startProgressBar 
		
		if gitCheckout &>/dev/null; then
			stopAsSuccessProgressBar
		else stopProgressBarAsFail
		fi
	else 
		changeDirectory "$git_src_dir"
	fi
	git config pull.ff only	
	git pull
	GitReset
}

gitAddSafeConfigRepository(){
	local safe_pattern="directory = $(GenerateScapesStr "$1")"
	grep "$safe_pattern"  ~/.gitconfig -q  2>/dev/null && return 
	git config --global --add safe.directory "$1"
}

getFromGit(){
	local git_src_url="$1"
	local git_src_dir="$2"
	local git_branch="$3"

	gitAddSafeConfigRepository "$2"
	if [ ! -e "$git_src_dir" ]; then
		GitClone
	else
		GitPull
	fi
}



getFPCBuilder(){
	local fpc_deb=${FPC_DEB_VERSION%\-*}
	if [ ! -e "$LAMW4LINUX_HOME/usr" ]; then 
		mkdir -p "$LAMW4LINUX_HOME/usr"
	fi

	cd "$LAMW4LINUX_HOME/usr"
	if  [ ! -e "$FPC_LIB_PATH/ppcx64" ]; then

		getCompressFile "$FPC_DEB_LINK" "$FPC_DEB" "ar x $FPC_DEB data.tar.xz"
		
		if [ -e data.tar.xz ]; then 
			tar -xf data.tar.xz ./usr/lib/fpc/${fpc_deb}/ppcx64
			rm -rf $LAMW4LINUX_HOME/usr/local
			[ -e $LAMW4LINUX_HOME/usr/usr ] && mv $LAMW4LINUX_HOME/usr/usr/ $LAMW4LINUX_HOME/usr/local
			[ ! -e  $LAMW4LINUX_HOME/usr/local/bin ] && mkdir -p ${LAMW4LINUX_HOME}/usr/local/bin
			mv "$LAMW4LINUX_HOME/usr/local/lib/fpc/$fpc_deb/ppcx64" "$LAMW4LINUX_HOME/usr/local/bin"
			rm $LAMW4LINUX_HOME/usr/local/lib/fpc -rf
			rm data.tar.xz
		fi
	fi
}

getFPCSourcesTrunk(){
	mkdir -p $FPC_TRUNK_SOURCE_PATH
	changeDirectory $FPC_TRUNK_SOURCE_PATH
	parseFPCTrunk
	local fpc_current_source="$FPC_TRUNK_SOURCE_PATH/$FPC_TRUNK_SVNTAG"
	[ -e "$FPC_TRUNK_SVNTAG" ] && 
	[ ! -e "$FPC_TRUNK_SVNTAG/.git" ] && 
		rm -rf "$FPC_TRUNK_SVNTAG"

	getFromGit "$FPC_TRUNK_URL" "$fpc_current_source" "$FPC_TRUNK_SVNTAG"
}

#get Lazarus Sources
getLazarusSources(){
	local old_lazarus_trunk="$LAMW4LINUX_HOME/lazarus_trunk"
	if [ -e "$old_lazarus_trunk" ];then 
		if [ ! -e "$LAMW_IDE_HOME" ]; then 
			mv "$old_lazarus_trunk" "$LAMW_IDE_HOME"
		else
			rm "$old_lazarus_trunk" -rf
		fi
	fi

	#override afterChangeBranchOrTag to mark force rebuild lazarus
	function afterChangeBranchOrTag { FORCE_LAZARUS_CLEAN_BUILD=1 ; }
	
	changeDirectory $LAMW4LINUX_HOME
	getFromGit "$LAZARUS_STABLE_SRC_LNK" "$LAMW_IDE_HOME" "$LAZARUS_STABLE"

	#reset afterChangeBranchOrTag
	function afterChangeBranchOrTag { :; }
}

#GET LAMW FrameWork
getLAMWFramework(){
	local old_lamw_framework_home="$ROOT_LAMW/lazandroidmodulewizard.git"
	changeDirectory $ROOT_LAMW
	[  -e "$old_lamw_framework_home" ] && [ -e "$LAMW_FRAMEWORK_HOME" ] && 
		rm -rf "$old_lamw_framework_home" && rm -rf "$LAMW_FRAMEWORK_HOME"

	getFromGit "$LAMW_SRC_LNK"  "$LAMW_FRAMEWORK_HOME"
}


getGradle(){
	changeDirectory $ROOT_LAMW
	if [ ! -e "$GRADLE_HOME" ]; then
		MAGIC_TRAP_INDEX=2 #Set arquivo a ser removido
		getCompressFile "$GRADLE_ZIP_LNK" "$GRADLE_ZIP_FILE" "unzip -o -q $GRADLE_ZIP_FILE" "MAGIC_TRAP_INDEX=3"
	fi
}

#Get Gradle and SDK Tools 
getAndroidCmdLineTools(){
	initROOT_LAMW
	changeDirectory $ANDROID_SDK_ROOT
	
	if [ ! -e "$CMD_SDK_TOOLS_DIR/latest" ];then
		mkdir -p "$CMD_SDK_TOOLS_DIR"
		changeDirectory "$CMD_SDK_TOOLS_DIR"
		MAGIC_TRAP_INDEX=4
		getCompressFile "$CMD_SDK_TOOLS_URL" "$CMD_SDK_TOOLS_ZIP" "unzip -o -q  $CMD_SDK_TOOLS_ZIP" "MAGIC_TRAP_INDEX=5"
		mv cmdline-tools latest
	fi
}


runSDKManagerLicenses(){
	local sdk_manager_cmd="$CMD_SDK_TOOLS_DIR/latest/bin/sdkmanager"
	yes | $sdk_manager_cmd ${SDK_LICENSES_PARAMETERS[*]} 
	if [ $? != 0 ]; then 
		yes | $sdk_manager_cmd ${SDK_LICENSES_PARAMETERS[*]} 
		check_error_and_exit "possible network instability! Try later!"
	fi
}

runSDKManager(){
	local sdk_manager_cmd="$CMD_SDK_TOOLS_DIR/latest/bin/sdkmanager"
	if [ $force_yes = 1 ]; then 
		yes | $sdk_manager_cmd $*

		if [ $? != 0 ]; then
			yes | $sdk_manager_cmd $*
			check_error_and_exit "possible network instability! Try later!"
		fi
	else
		$sdk_manager_cmd $*

		if [ $? != 0 ]; then 
			$sdk_manager_cmd $*
			check_error_and_exit "possible network instability! Try later!"
		fi
	fi
}

getAndroidAPIS(){
	
	local force_yes=1
	changeDirectory $ANDROID_HOME
	runSDKManagerLicenses
	
	if [ $#  = 0 ]; then 

		for((i=0;i<${#SDK_MANAGER_CMD_PARAMETERS[*]};i++));do
			echo "Please wait, downloading ${NEGRITO}${SDK_MANAGER_CMD_PARAMETERS[i]}${NORMAL}..."
			
			if [ $i = 0 ]; then 
				runSDKManager ${SDK_MANAGER_CMD_PARAMETERS[i]} # instala sdk sem intervenção humana 
				force_yes=0
			else
				runSDKManager ${SDK_MANAGER_CMD_PARAMETERS[i]} 
			fi
		done
	else 
		runSDKManager $*
	fi
}


resetAndroidAPIS(){
	local sdk_manager_fails=(
		"platforms"
		"platform-tools"
		"build-tools"
		"extras"
	)
	echo "${VERMELHO}Warning:${NORMAL} All Android API'S will  be unistalled!"
	echo "Only the default APIs will be reinstalled!"
	for ((i=0;i<${#sdk_manager_fails[*]};i++)); do
		local current_sdk_path="${ANDROID_SDK_ROOT}/${sdk_manager_fails[i]}"
		[ -e $current_sdk_path ] && rm -rf $current_sdk_path
	done

	setLAMWDeps
	getAndroidAPIS
	changeOwnerAllLAMW

}


isRequiredReinstallDependencies(){
	local tools="wget git xmlstartlet jq xmlstarlet make"
	which $tools &>/dev/null
}

Repair(){

	local ret=0

	if getStatusInstalation; then 
		return 0
	fi
	

	if isRequiredReinstallDependencies; then
		installSystemDependencies
		ret=1
	fi

	if [ ! -e $LAMW_IDE_HOME_CFG ]; then
		mkdir -p "$LAMW_IDE_HOME_CFG"
		LAMW4LinuxPostConfig
		ret=1
	fi

	return $ret 
}

checkLAMWManagerVersion(){
	local ret=0
	[ ! -e  $LAMW_INSTALL_LOG ] && return

	local current_lamw_mgr_version="$(grep "^Generate LAMW_INSTALL_VERSION="  "$LAMW_INSTALL_LOG" | awk -F= '{ print $NF }')"
	for i  in ${!OLD_LAMW_INSTALL_VERSION[*]};do
		if [ $current_lamw_mgr_version = ${OLD_LAMW_INSTALL_VERSION[i]} ]; then 
			CURRENT_OLD_LAMW_INSTALL_INDEX=$i
			ret=1;
			break
		fi
	done

	if [  "$1"  != "" ]; then 
		newPtr ref_ret=$1
		ref_ret=$ret
	else 
		echo "$ret"
	fi
}

setOldLAMW4LinuxActions(){
	if [ $1 = 1 ]; then 
		echo "You need upgrade your LAMW4Linux!"
		export LAMW_IMPLICIT_ACTION_MODE=0
	else
		echo "${VERMELHO}Your LAMW development environment was generated by a newer version of LAMW Manager!${NORMAL}"
		exit 1
	fi
}

checkChangeLAMWDeps(){
	if isUpdateLAMWDeps; then 
		export LAMW_IMPLICIT_ACTION_MODE=1
	else
		setOldLAMW4LinuxActions 1
	fi
}

#get implict install 
getImplicitInstall(){
	if [ ! -e "$LAMW_INSTALL_LOG" ]; then
		AUTO_START_LAMW4LINUX=1
		return 
	else
		grep "Generate LAMW_INSTALL_VERSION=$LAMW_INSTALL_VERSION" "$LAMW_INSTALL_LOG" 	> /dev/null
		
		if [ $? = 0 ]; then
		
			checkChangeLAMWDeps
		else
			local flag_is_old_lamw=0
			checkLAMWManagerVersion flag_is_old_lamw
			setOldLAMW4LinuxActions $flag_is_old_lamw
		fi
	fi
}

getCurrentLazarusWidget(){
	local lazarus_widget_default="gtk2"
	local current_widget_set="$lazarus_widget_default"
	if [ -e  "$ide_make_cfg_path" ]; then 
		current_widget_set="$(grep '\-dLCL.' "$ide_make_cfg_path" | sed 's/-dLCL//g')"
		[ $? != 0 ] && current_widget_set="$lazarus_widget_default"
	fi

	echo "$current_widget_set"
}


getMaxLAMWPackages(){
	local max_lamw_pcks=${#LAMW_PACKAGES[@]}
 	[ $LAMW_MINIMAL_INSTALL = 1 ] && ((max_lamw_pcks--))
	echo $max_lamw_pcks
}


installLAMWPackages(){
	local ide_make_cfg_path="$LAMW_IDE_HOME_CFG/idemake.cfg"
	local error_lazbuild_msg="${VERMELHO}Error${NORMAL}: Fails on build ${NEGRITO}${LAMW_PACKAGES[i]}${NORMAL} package"
	local max_lamw_pcks=$(getMaxLAMWPackages)
	local sucess_filler=""
	local build_msg=""
	local current_pack=""

	local lamw_build_opts=(
		"--max-process-count=$CPU_COUNT"
		"--pcp=$LAMW_IDE_HOME_CFG"  
		"--ws=$(getCurrentLazarusWidget)"
		"--quiet" 
		"--build-ide=" 
		"--add-package"
	)

	local bg_pid=''

	#build ide with lamw framework 
	for((i=0;i< $max_lamw_pcks;i++)); do
		
		current_pack="`basename ${LAMW_PACKAGES[i]}`"
		build_msg="Please wait, starting building ${NEGRITO}${current_pack}${NORMAL}..........................."
		sucess_filler="$(getCurrentSucessFiller 3 $current_pack)"
		startProgressBar
		if ! ./lazbuild ${lamw_build_opts[*]} ${LAMW_PACKAGES[$i]} >/dev/null; then 
			stopProgressBarAsFail
			if ! ./lazbuild ${lamw_build_opts[*]} ${LAMW_PACKAGES[$i]}; then 
			 	echo "$error_lazbuild_msg $current_pack" 
			 	EXIT_STATUS=1 
			 	return 
			fi
		fi
		
		stopAsSuccessProgressBar
	done
}

checkIfNeedRebuildCleanLazarus(){
	if 	[ !  -e $LAMW_IDE_HOME/lazbuild ] ||
		[ $FORCE_LAZARUS_CLEAN_BUILD =  1 ]
	then
		 return 0
	fi
	return 1

}
#Build lazarus ide
BuildLazarusIDE(){	
	parseFPCTrunk
	export PATH=$FPC_TRUNK_LIB_PATH:$FPC_TRUNK_EXEC_PATH:$PATH
	local error_build_lazarus_msg="${VERMELHO}Fatal error:${NORMAL}Fails in build Lazarus!!"
	
	local make_opts=( 
		"clean all" "PP=${FPC_TRUNK_LIB_PATH}/ppcx64" "FPC_VERSION=$_FPC_TRUNK_VERSION"  "FPMAKEOPT=-T${CPU_COUNT}")
	local build_msg="Please wait, starting build Lazarus to ${NEGRITO}x86_64/Linux${NORMAL}.............."
	local sucess_filler="$(getCurrentSucessFiller 1 x86_64/Linux)"
	
	changeDirectory $LAMW_IDE_HOME

	if  checkIfNeedRebuildCleanLazarus ; then
		startProgressBar
		
		if ! make -s ${make_opts[@]} > /dev/null 2>&1; then
			stopProgressBarAsFail
			make -s ${make_opts[@]}
			check_error_and_exit "$error_build_lazarus_msg" #build all IDE
		fi

	 	stopAsSuccessProgressBar
	 	#printf  "%s\n" "${FILLER:${#sucess_filler}}${VERDE} [OK]${NORMAL}"
	fi
	
	initLAMw4LinuxConfig
	installLAMWPackages
	strip lazarus
	strip lazbuild
	strip startlazarus
}

#this code add support a proxy 
checkProxyStatus(){
	if [ $USE_PROXY = 1 ] ; then
		ActiveProxy 1
	else
		ActiveProxy 0
	fi
}

requestFixlpSnapshot(){
	local _page_=$(wget -qO- 'https://sourceforge.net/p/lazarus-ccr/svn/HEAD/tree/')
	
	local _sesion_id_=$(
		echo "${_page_}" | 
		grep -i session | 
		sed 's/[<>]//g' | 
		awk -F= ' { print $4 }'
	)

	FIXLP_VERSION=$(
		echo "${_page_}" | 
		grep 'Tree' | 
		awk -F/ '{ print $5}'
	)

	export FIXLP_URL="https://sourceforge.net/code-snapshots/svn/l/la/lazarus-ccr/svn/lazarus-ccr-svn-r${FIXLP_VERSION}-applications-fixlp.zip"
	export FIXLP_ZIP="lazarus-ccr-svn-r${FIXLP_VERSION}-applications-fixlp.zip"

	if ! wget  -qO- --post-data "_session_id_=${_sesion_id_}&path=/applications/fixlp" 'https://sourceforge.net/p/lazarus-ccr/svn/HEAD/tarball' >/dev/null;  then 
		USE_FIXLP=1
	fi

}

#auxiliar function to get fixlp into subshell
#in case of fails, subshell dies, without great consequences.
getFixLpInSubShell(){
	getCompressFile "$FIXLP_URL" "$FIXLP_ZIP" "unzip  -o -q  $FIXLP_ZIP" 
}

getFixLp(){

	[ $USE_FIXLP = 1 ] && return  
	if [ ! -e $LAMW4LINUX_HOME/usr/bin/fixlp ]; then
		MAGIC_TRAP_INDEX=6
		export -f  getCompressFile Wget check_error_and_exit getFixLpInSubShell 
		export -f stopProgressBar getNameSumByParent startProgressBar 
		export -f stopProgressBarAsFail stopAsSuccessProgressBar
		export -f setWgetProgressBarParam	
		export WGET_TIMEOUT FILLER VERDE VERMELHO NORMAL NEGRITO MAGIC_TRAP_INDEX
		
		changeDirectory "$ROOT_LAMW"

		#call subshell to get fixlp,
		if ! bash -c getFixLpInSubShell; then 
			bash -c getFixLpInSubShell
		fi
	fi
}

installFixLp(){
	[ $USE_FIXLP = 1 ] && return 
	local fixlp_dir="$ROOT_LAMW/${FIXLP_ZIP//\.zip/}"
	if [ -e "$fixlp_dir" ];then
		changeDirectory "$fixlp_dir"
		if "$LAMW_IDE_HOME/lazbuild" -q --pcp="$LAMW_IDE_HOME_CFG" --bm= fixlp.lpi &>/dev/null; then 
			cp "./fixlp" "$LAMW4LINUX_HOME/usr/bin"
			changeDirectory "$ROOT_LAMW"
			rm "$fixlp_dir" -r
		fi

	fi
}
mainInstall(){
	getFiller
	checkLAMWManagerVersion > /dev/null
	singleCoreWarning
	installSystemDependencies
	initLAMWUserConfig
	initROOT_LAMW
	setLAMWDeps
	LAMWPackageManager
	checkProxyStatus
	requestFixlpSnapshot
	getJDK
	getGradle
	getAndroidCmdLineTools
	getFixLp
	resetTrapActions
	getFPCBuilder
	getFPCSourcesTrunk
	getLazarusSources
	getLAMWFramework
	getAndroidAPIS
	CreateBinutilsSimbolicLinks
	AddSDKPathstoProfile
	deleteCrossBinLock
	buildCrossAndroid
	configureFPCTrunk
	BuildLazarusIDE
	installFixLp
	LAMW4LinuxPostConfig
	writeLAMWLogInstall
	changeOwnerAllLAMW
}