#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (mater-alma)
#Course: Science Computer
#Version: 0.5.2
#Date: 12/06/2022
#Description: The "lamw-manager-settings-editor.sh" is part of the core of LAMW Manager. Responsible for managing LAMW Manager / LAMW configuration files..
#-----------------------------------------------------------------------f--------------------------#
#this function builds initial struct directory of LAMW env Development !
initROOT_LAMW(){

	local init_root_lamw_dirs=(
		$ANDROID_SDK_ROOT
		"$(dirname $JAVA_HOME)"
		"$LAMW4LINUX_ETC"
		$LAMW_USER_HOME/.android
		$HOME/.android
		$FPPKG_LOCAL_REPOSITORY
		$LAMW_IDE_HOME_CFG
		"$LAMW_USER_MIMES_PATH"
		"$LAMW_USER_APPLICATIONS_PATH"
	)


	for lamw_dir in ${init_root_lamw_dirs[@]}; do
		[ ! -e "$lamw_dir" ] && mkdir -p "$lamw_dir"
	done

	[ ! -e $LAMW_USER_HOME/.android/repositories.cfg ] && touch $LAMW_USER_HOME/.android/repositories.cfg  
	[ ! -e $HOME/.android/repositories.cfg ] && echo "" > $HOME/.android/repositories.cfg 
}

enableADBtoUdev(){
	local expected_sha256sum='c2bcc120e3af1df5facd3b508dc1e4a5efff4614650ba4edb690554e548c6290'
	local udev_usb_rule_path=/etc/udev/rules.d/51-android.rules
	if [ -e $udev_usb_rule_path ]; then
		local current_sha256sum=$(sha256sum < $udev_usb_rule_path)
		if [ "${current_sha256sum%%' '*}" != "$expected_sha256sum" ]; then
			cp $udev_usb_rule_path "${udev_usb_rule_path}.bak"
		fi
	fi
	printf 'SUBSYSTEM=="usb", ATTR{idVendor}=="<VENDOR>", MODE="0666", GROUP="plugdev"\n' > $udev_usb_rule_path
	systemctl restart udev.service &>/dev/null
}


AddSDKPathstoProfile(){
	local profile_file=$LAMW_USER_HOME/.bashrc
	local flag_profile_paths=0
	local profile_line_path='export PATH=$PATH:$GRADLE_HOME/bin'
	cleanPATHS
	export PATH=$PATH:$ROOT_LAMW/ndk-toolchain
	export PATH=$PATH:$GRADLE_HOME/bin
}

#Esta funcao altera todos o dono de todos arquivos e  pastas do ambiente LAMW de root para o $LAMW_USER_HOME
#Ou seja para o usuario que invocou o lamw_manager (bootstrap)
changeOwnerAllLAMW(){
	#case only update-lamw
	if [ $# = 1 ]; then
		local files_chown=(
			"$LAMW_IDE_HOME_CFG"
			"$ROOT_LAMW/lazandroidmodulewizard"
			"$LAMW_IDE_HOME"
		)
	else

		local files_chown=(
			"$LAMW_USER_HOME/Dev"
			"$ROOT_LAMW"
			"$FPC_CFG_PATH"
			"$LAMW_USER_HOME/.profile"
			"$LAMW_USER_HOME/.bashrc"
			"$LAMW_USER_HOME/.android"
			"$LAMW_USER_HOME/.local/share"
			"$LAMW_IDE_HOME_CFG"
			"$LAMW_MANAGER_LOCAL_CONFIG_DIR"
				
		#	
		)

		[ "$NO_EXISTENT_ROOT_LAMW_PARENT" != "" ] &&
			files_chown+=($NO_EXISTENT_ROOT_LAMW_PARENT)
	
	fi
	printf "%s" "Restoring directories ........."
	local max=${#files_chown[*]}
	local filler_size="${#FILLER}"
	local -i rate=$((filler_size/max))
	local -i offset=$((filler_size-rate))
	for ((i=0;i<${#files_chown[*]};i++))
	do
		if [ -e ${files_chown[i]} ] ; then
			if [ $i = 0 ] && [ $# = 0 ] ; then 
				# caso $LAMW_USER não seja dono do diretório LAMW_USER_HOME/Dev ou $LAMW_WORKSPACE_HOME
				if  [ $UID = 0 ] && ( [ -O ${files_chown[i]} ] || [ -O  "$LAMW_WORKSPACE_HOME" ] ); then 
					chown $LAMW_USER_GROUP -R ${files_chown[i]}
				fi
			else 
				chown $LAMW_USER_GROUP -R ${files_chown[i]}
			fi
		fi
		printf "%s" "${FILLER:$offset}"
	done
	filler_size=$(len '.....')
	offset=$((offset+filler_size))
	printf  "%s\n" "${FILLER:$offset}${VERDE} [OK]${NORMAL}"
}
#write log lamw install 
writeLAMWLogInstall(){
	local fpc_version=$FPC_TRUNK_VERSION
	local lamw_log_str=(
		"Generate LAMW_INSTALL_VERSION=$LAMW_INSTALL_VERSION" 
		"Info:"
		"LAMW4Linux:$LAMW4LINUX_HOME"
		"LAMW workspace:$LAMW_WORKSPACE_HOME"
		"Android SDK:$ROOT_LAMW/sdk" 
		"Android NDK:$ROOT_LAMW/ndk"
		"Gradle:$GRADLE_HOME"
		"LAMW_MANAGER PATH:$LAMW_MANAGER_PATH"
		"OLD_ANDROID_SDK=$OLD_ANDROID_SDK"
		"ANT_VERSION=$ANT_VERSION_STABLE"
		"GRADLE_VERSION=$GRADLE_VERSION"
		"SDK_TOOLS_VERSION=$SDK_TOOLS_VERSION"
		"FPC_VERSION=$fpc_version"
		"LAZARUS_VERSION=$LAZARUS_STABLE_VERSION"
		"AARCH64_SUPPORT=$FLAG_FORCE_ANDROID_AARCH64"
		"CMD_SDK_TOOLS_VERSION_STR=$CMD_SDK_TOOLS_VERSION_STR"
		""
		"Install-date:$(date)"
	)

	if [ $USE_FIXLP = 0 ]; then 
		local -i position_fix_lp=${#lamw_log_str[@]}
		((position_fix_lp-=2))
		lamw_log_str[$position_fix_lp]="FIXLP_VERSION=$FIXLP_VERSION"
	fi

	WriterFileln "$LAMW_INSTALL_LOG" "lamw_log_str"	
}
initTemplatePaths(){
	arrayMap LAMW4LINUX_TEMPLATES_PATHS templatePath realPath '
		cp $templatePath $realPath
	'
}

menuTrigger(){
	local path="$2"
	arrayMap $1 value key '
		local current_value="$(grep "^$key" "$path")" 
		sed -i "s|$current_value|$key=$value|g" "$path"	
	'
	chmod +x $2
}
#Add LAMW4Linux to menu 
AddLAMWtoStartMenu(){
	local -A lamw_desktop_file_str=( 
		["Name"]="LAMW4Linux IDE"
		["Comment"]="A Lazarus IDE [and all equirements!] ready to develop for Android!"   
		["Exec"]="$LAMW_IDE_HOME/startlamw4linux"
		["Icon"]="$LAMW_IDE_HOME/images/icons/lazarus_orange.ico"
		["StartupWMClass"]="LAMW4Linux"
	)

	local  -A lamw4linux_terminal_desktop_str=(  
        ["Exec"]="$LAMW4LINUX_TERMINAL_EXEC_PATH"
    )
    initTemplatePaths
	menuTrigger lamw_desktop_file_str $LAMW_MENU_ITEM_PATH
	menuTrigger lamw4linux_terminal_desktop_str $LAMW4LINUX_TERMINAL_MENU_PATH
	#mime association: ref https://help.gnome.org/admin/system-admin-guide/stable/mime-types-custom-user.html.en
	cp $LAMW_IDE_HOME/install/lazarus-mime.xml $LAMW_USER_MIMES_PATH
	update-mime-database   $(dirname $LAMW_USER_MIMES_PATH)
	update-desktop-database $LAMW_USER_APPLICATIONS_PATH
}

# This function prevents terminal runtime error (lazarus external processes) 
# in xfce and gnome environments of non-debian systems

SystemTerminalMitigation(){
	[ $IS_DEBIAN = 1 ] && return 
	
	local xterm_path=$(which xterm)
	local desktop_env="$LAMW_USER_DESKTOP_SESSION $LAMW_USER_XDG_CURRENT_DESKTOP"
	local gnome_regex="(GNOME)"
	local xfce_regex="(XFCE)"
	local lamw4linux_bin="$LAMW4LINUX_HOME/usr/bin"
	local lamw4linux_gnome_terminal="$lamw4linux_bin/gnome-terminal"
	local lamw4linux_xfce_terminal="$lamw4linux_bin/xfce4-terminal"
	
	# is a gnome system 
	if [[ "$desktop_env" =~ gnome_regex ]]; then
		
		[ -e "$lamw4linux_gnome_terminal" ] && rm $lamw4linux_gnome_terminal
		ln -s $xterm_path "$lamw4linux_gnome_terminal"
	
	# is a xfce system 
	elif [[ "$desktop_env" =~ $xfce_regex ]]; then 

		[ -e "$lamw4linux_xfce_terminal" ] && rm "$lamw4linux_xfce_terminal"
		ln -s $xterm_path  "$lamw4linux_xfce_terminal"

	fi
}

#this  fuction create a INI file to config  all paths used in lamw framework 
LAMW4LinuxPostConfig(){
	local lazbuild_path="$LAMW4LINUX_HOME/usr/bin/lazbuild"
	local old_lamw_workspace="$LAMW_USER_HOME/Dev/lamw_workspace"
	local ant_path=$ANT_HOME/bin
	local breakline='\\'n


	[ -e $old_lamw_workspace ] && 
		mv $old_lamw_workspace $LAMW_WORKSPACE_HOME

	[ ! -e $LAMW_WORKSPACE_HOME ] && 
		mkdir -p $LAMW_WORKSPACE_HOME


	#testa modificação de workspace
	if [ -e "$LAMW_IDE_HOME_CFG/LAMW.ini" ]; then 
		local current_lamw_workspace=$(grep '^PathToWorkspace=' $LAMW_IDE_HOME_CFG/LAMW.ini  | sed 's/PathToWorkspace=//g')
		[ "$current_lamw_workspace" != "$LAMW_WORKSPACE_HOME" ] && LAMW_WORKSPACE_HOME="$current_lamw_workspace"	
	fi
# contem o arquivo de configuração do lamw
	local LAMW_init_str=(
		"[NewProject]"
		"PathToWorkspace=$LAMW_WORKSPACE_HOME"
		"PathToSmartDesigner=$LAMW_FRAMEWORK_HOME/android_wizard/smartdesigner"
		"PathToJavaTemplates=$LAMW_FRAMEWORK_HOME/android_wizard/smartdesigner/java"
		"PathToJavaJDK=$JAVA_HOME"
		"PathToAndroidNDK=$ROOT_LAMW/ndk"
		"PathToAndroidSDK=$ANDROID_SDK_ROOT"
		"PathToAntBin=$ant_path"
		"PathToGradle=$GRADLE_HOME"
		"PrebuildOSYS=linux-x86_64"
		"MainActivity=App"
		"FullProjectName="
		"InstructionSet=2"
		"AntPackageName=org.lamw"
		"AndroidPlatform=0"
		"AntBuildMode=debug"
		"NDK=6"
	)

	local lamw4linux_env_str=(
		"#!/bin/bash"
		"[ \"\$LOCAL_LAMW_ENV\"  = \"1\" ] && return"
		"export PPC_CONFIG_PATH=$PPC_CONFIG_PATH"
		"export JAVA_HOME=$JAVA_HOME"
		"export ANDROID_HOME=$ANDROID_HOME"
		"export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT"
		"export GRADLE_HOME=$GRADLE_HOME"
		"export PATH=\$ANDROID_SDK_ROOT/platform-tools:\$ANDROID_HOME/lamw4linux/usr/bin:\$PPC_CONFIG_PATH:\$JAVA_HOME/bin:\$PATH:\$ANDROID_HOME/ndk-toolchain:\$GRADLE_HOME/bin"
		"export LAMW_IDE_HOME_CFG=$LAMW_IDE_HOME_CFG"
		"export LAMW_MANAGER_PATH=$LAMW_MANAGER_PATH"
		"export LAMW4LINUX_EXE_PATH=$LAMW4LINUX_EXE_PATH"
		"export OLD_LAMW4LINUX_EXE_PATH=${LAMW4LINUX_EXE_PATH}.old"
		"export IGNORE_XFCE_LAMW_ERROR_PATH=$IGNORE_XFCE_LAMW_ERROR_PATH"
		"export LOCAL_LAMW_ENV=1"


	)
	local startlamw4linux_str=(
		'#!/bin/bash'
		'#-------------------------------------------------------------------------------------------------#'
		'### THIS FILE IS AUTOMATICALLY CONFIGURED by LAMW Manager'
		'###ou may comment out this entry, but any other modifications may be lost.'
		'#Description: This script is script configure LAMW environment and startLAMW4Linux'
		'#-------------------------------------------------------------------------------------------------#'
		"source $LAMW4LINUX_LOCAL_ENV"
		"source $STARTUP_ERROR_LAMW4LINUX_PATH"
		''
		"exec \$LAMW4LINUX_EXE_PATH --pcp=\$LAMW_IDE_HOME_CFG \$*"
	)

	local lazbuild_str=(
		'#!/bin/bash'
		"source $LAMW4LINUX_LOCAL_ENV"
		"exec $LAMW_IDE_HOME/lazbuild --pcp=\$LAMW_IDE_HOME_CFG \$*"
	)


	local lamw4linux_terminal_str=(
		'#!/bin/bash'
		'#-------------------------------------------------------------------------------------------------#'
		'### THIS FILE IS AUTOMATICALLY CONFIGURED by LAMW Manager'
		'###ou may comment out this entry, but any other modifications may be lost.'
		'#Description: This script is script configure LAMW environment and  run  a terminal'
		'#-------------------------------------------------------------------------------------------------#'
		"source $LAMW4LINUX_LOCAL_ENV"
		""
		"_LAMW_MANAGER_COMPLETE_PATH=$LAMW_MANAGER_COMPLETION"
		"_EXTRA_ARGS=\"--init-file \$_LAMW_MANAGER_COMPLETE_PATH\""
		""
		"export CURRENT_LAMW_WORKSPACE=\$(grep '^PathToWorkspace=' \$LAMW_IDE_HOME_CFG/LAMW.ini  | sed 's/PathToWorkspace=//g')"
		"export LAMW_FRAMEWORK_HOME=\"$LAMW_FRAMEWORK_HOME\""
		"export SDK_TARGET=$ANDROID_SDK_TARGET"
		"export ANDROID_BUILD_TOOLS_TARGET=$ANDROID_BUILD_TOOLS_TARGET"
		"export LAMW4LINUX_TERMINAL_RC=\"$LAMW4LINUX_ETC/lamw4linux-terminal.rc\""
		"export LAM4LINUX_TERMINAL_FUNCTIONS=\$(grep '(){' \$LAMW4LINUX_TERMINAL_RC | sed 's/(){//g' )"
		""
		"source \$LAMW4LINUX_TERMINAL_RC"
	)


	WriterFileln "$LAMW4LINUX_TERMINAL_EXEC_PATH" lamw4linux_terminal_str && chmod +x $LAMW4LINUX_TERMINAL_EXEC_PATH
	WriterFileln "$LAMW_IDE_HOME_CFG/LAMW.ini" "LAMW_init_str"
	WriterFileln "$LAMW_IDE_HOME/startlamw4linux" "startlamw4linux_str"
	WriterFileln "$LAMW4LINUX_LOCAL_ENV" lamw4linux_env_str
	WriterFileln "$lazbuild_path" lazbuild_str && chmod +x $lazbuild_path

	if [ -e  $LAMW_IDE_HOME/startlamw4linux ]; then
		chmod +x $LAMW_IDE_HOME/startlamw4linux
		[ ! -e "/usr/bin/startlamw4linux" ] && 
			ln -s "$LAMW_IDE_HOME/startlamw4linux" "/usr/bin/startlamw4linux"
	fi

	if [ $IS_DEBIAN = 0 ] && [ $NEED_XFCE_MITIGATION  = 1 ]; then 
		SystemTerminalMitigation
	fi
	AddLAMWtoStartMenu
}

ActiveProxy(){
	if [ $1 = 1 ]; then
		git config --global core.gitproxy $PROXY_URL #"http://$HOST:$PORTA"
		git config --global http.gitproxy $PROXY_URL #"http://$HOST:$PORTA"

	else
		git config --global --unset core.gitproxy
		git config --global --unset http.gitproxy
		if [ -e ~/.gitconfig ] ;then
			sed -i '/\[core\]/d' ~/.gitconfig
			sed -i '/\[http\]/d' ~/.gitconfig
		fi
	fi
}

CleanOldCrossCompileBins(){
	parseFPCTrunk
	local lamw_manager_v031=0.3.1
	local clean_files=(
		"$FPC_LIB_PATH/ppcrossarm"
		"/usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android"
		"/usr/local/lib/fpc/3.3.1"
	)

	local list_deleted_files=(	
		"/usr/bin/ppcarm"
		"/usr/bin/ppcrossarm"
		"/usr/bin/arm-linux-androideabi-ld"
		"/usr/bin/arm-linux-as"
		"/usr/bin/arm-linux-androideabi-as"
		"/usr/bin/arm-linux-ld"
		"/usr/bin/aarch64-linux-android-as"
		"/usr/bin/aarch64-linux-android-ld"
		"/usr/bin/ppca64"
		"/usr/bin/ppcrossa64"
	)


	local index_clean_files_v031=${#clean_files[*]}
	local current_old_lamw_manager=${OLD_LAMW_INSTALL_VERSION[$CURRENT_OLD_LAMW_INSTALL_INDEX]}
	((index_clean_files_v031-=1))

	[ $CURRENT_OLD_LAMW_INSTALL_INDEX -lt  0 ] && return 1



	for((i=0;i<${#list_deleted_files[*]};i++)); do 
		if [ -e ${list_deleted_files[i]} ]; then 
			validate_is_file_create_by_lamw_manager $i ${list_deleted_files[i]}
			[ $? = 0 ] && rm ${list_deleted_files[i]}
		fi
	done

	for((i=0;i<${#clean_files[*]};i++)); do
		if [  -e ${clean_files[i]} ] && [ $i -lt  $index_clean_files_v031 ]  ; then 
			rm -rf ${clean_files[i]}
		else 
			[ -e ${clean_files[i]} ]  && [ $current_old_lamw_manager  = $lamw_manager_v031 ] && rm -rf ${clean_files[i]}
		fi
	done

	if [  -e /usr/local/bin/fpc ] &&  [ $current_old_lamw_manager = $lamw_manager_v031 ]; then
		local fpc_tmp_files=("bin2obj" "chmcmd" "chmls" "cldrparser" "compileserver" "cvsco.tdf" "cvsdiff.tdf" "cvsup.tdf" "data2inc" "delp" "fd2pascal" "fp" "fp.ans" "fpc" "fpcjres" "fpclasschart" "fpclasschart.rsj" "fpcmake" "fpcmkcfg" "fpcmkcfg.rsj" "fpcres" "fpcsubst" "fpcsubst.rsj" "fpdoc" "fppkg" "fprcp" "fp.rsj" "gplprog.pt" "gplunit.pt" "grab_vcsa" "grep.tdf" "h2pas" "h2paspp" "instantfpc" "json2pas" "makeskel" "makeskel.rsj" "mka64ins" "mkarmins" "mkinsadd" "mkx86ins" "pas2fpm" "pas2jni" "pas2js" "pas2ut" "pas2ut.rsj" "plex" "postw32" "ppdep" "ppudump" "ppufiles" "ppumove" "program.pt" "ptop" "ptop.rsj" "pyacc" "rmcvsdir" "rstconv" "rstconv.rsj" "tpgrep.tdf" "unihelper" "unitdiff" "unitdiff.rsj" "unit.pt" "webidl2pas")
		for((i=0;i<${#fpc_tmp_files[*]};i++)); do
			local aux="/usr/local/bin/${fpc_tmp_files[i]}"
			[ -e $aux ] &&  rm $aux
		done
	fi
	
}

	

cleanPATHS(){
	[ $CURRENT_OLD_LAMW_INSTALL_INDEX -lt  2 ] && return
	local android_home_sc=$(GenerateScapesStr "$ANDROID_HOME")
	grep "ANDROID_HOME=" $LAMW_USER_HOME/.bashrc | grep "$ROOT_LAMW" > /dev/null 
	if [ $? = 0 ]; then 
		sed -i "/export ANDROID_HOME=${android_home_sc}/d"  $LAMW_USER_HOME/.bashrc
		sed -i '/export PATH=$PATH:$ANDROID_HOME\/ndk-toolchain/d' $LAMW_USER_HOME/.bashrc
	fi

	grep "GRADLE_HOME=" $LAMW_USER_HOME/.bashrc | grep "$ROOT_LAMW" > /dev/null
	if [ $? = 0 ];then
		sed -i "/export GRADLE_HOME=${android_home_sc}*/d" $LAMW_USER_HOME/.bashrc
		sed -i '/export PATH=$PATH:$GRADLE_HOME\/bin/d'  $LAMW_USER_HOME/.bashrc
	fi
}


#adiciona criterios de validação para a desinstalação de arquivos criados pelo lamw_manager
validate_last_files_created_by_lamw_manager(){
	if [ $1 = $last_index_deleted_files  ] || [ $1 = $last_but_one_index_deleted_files ]; then
		grep "$ROOT_LAMW" "$2"
	else
		return 0;
	fi

}
#adiciona criterios de validação para a desinstalação de arquivos criados pelo lamw_manager
validate_is_file_create_by_lamw_manager(){
	local very_old_lamw_manager_index=${#OLD_LAMW_INSTALL_VERSION[*]}
	((very_old_lamw_manager_index-=2))

	local size_list_deleted_files=${#list_deleted_files[*]}
	local system_index_deleted_files=11 #index de arquivos criados em /usr
	local last_index_deleted_files=$((size_list_deleted_files - 1))
	local last_but_one_index_deleted_files=$((last_index_deleted_files-1))

	[ $CURRENT_OLD_LAMW_INSTALL_INDEX -lt 0 ] && [  $1 -lt $system_index_deleted_files ] && return 1 #ignora binarios fpc/arm  se o ambiente de desenvolvimento lamw não estiver instalado
		
	 #verifica se o arquivo é um arquivo do criado pelo lamw_manager
	if [ $CURRENT_OLD_LAMW_INSTALL_INDEX -lt $very_old_lamw_manager_index ]; then 
		if [ $1 -lt $system_index_deleted_files ] ; then
			ls -lah "$2" | grep "\->\s$ROOT_LAMW" > /dev/null
		else 
			validate_last_files_created_by_lamw_manager "$1" "$2"
		fi
	else
		validate_last_files_created_by_lamw_manager "$1" "$2"
	fi
}
CleanOldConfig(){
	getStatusInstalation
	[ $LAMW_INSTALL_STATUS = 1 ] && checkLAMWManagerVersion > /dev/null
	parseFPCTrunk
	local scape_root_lamw="$(GenerateScapesStr "$ROOT_LAMW")"
	local list_deleted_files=(
		"/usr/bin/ppcarm"
		"/usr/bin/ppcrossarm"
		"/usr/bin/arm-linux-androideabi-ld"
		"/usr/bin/arm-linux-as"
		"/usr/bin/arm-linux-androideabi-as"
		"/usr/bin/arm-linux-ld"
		"/usr/bin/aarch64-linux-android-as"
		"/usr/bin/aarch64-linux-android-ld"
		"/usr/bin/ppca64"
		"/usr/bin/ppcrossa64"
		"/usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android"
		"/usr/bin/startlamw4linux"
		"$FPC_CFG_PATH"
		"$LAMW_IDE_HOME_CFG"
		"$ROOT_LAMW"
		"$LAMW_MENU_ITEM_PATH"
		"$LAMW4LINUX_TERMINAL_MENU_PATH"
		"$WORK_HOME_DESKTOP/lamw4linux.desktop"
		"$LAMW_USER_HOME/.local/share/mime/packages/lazarus-mime.xml"
		"$FPC_TRUNK_LIB_PATH"
		"/root/.fpc.cfg"
		"$OLD_FPC_CFG_PATH"
	)

	local max=${#list_deleted_files[*]}
	local filler_size="${#FILLER}"
	local -i rate=$((filler_size/max))
	local -i offset=$((filler_size-rate))

	printf "%s" "Uninstalling LAMW4Linux IDE ........."

	for((i=0;i<${#list_deleted_files[*]};i++)); do
		if [ -e "${list_deleted_files[i]}" ]; then 
			[ -d  "${list_deleted_files[i]}" ] && local rm_opts="-rf"
			if validate_is_file_create_by_lamw_manager $i "${list_deleted_files[i]}"; then 
				rm  "${list_deleted_files[i]}" $rm_opts
			fi
		fi
		printf "%s" "${FILLER:$offset}"
	done

	filler_size=$(len '')
	offset=$((offset+filler_size))
	printf  "%s\n" "${FILLER:$offset}${VERDE} [OK]${NORMAL}"

	CleanOldCrossCompileBins
	update-mime-database   $LAMW_USER_HOME/.local/share/mime/
	update-desktop-database $LAMW_USER_HOME/.local/share/applications
	cleanPATHS
	cp ~/.gitconfig ~/.old.git.config
	sed -i "/directory = $scape_root_lamw/d" ~/.gitconfig
	unsetLocalRootLAMW
}

#Create SDK simbolic links
CreateSDKSimbolicLinks(){

	local real_ppcarm="$FPC_TRUNK_LIB_PATH/ppcrossarm"	
	local tools_chains_orig=(
		"$ROOT_LAMW/sdk/ndk-bundle"
		"$LLVM_ANDROID_TOOLCHAINS"
		"$ARM_ANDROID_TOOLS/arm-linux-androideabi-as"
		"$ARM_ANDROID_TOOLS/arm-linux-androideabi-ld"
		"$ARM_ANDROID_TOOLS/arm-linux-androideabi-as"
		"$ARM_ANDROID_TOOLS/arm-linux-androideabi-ld"
		"$ARM_ANDROID_TOOLS/arm-linux-androideabi-as"
		"$ROOT_LAMW/sdk/ndk-bundle/toolchains/arm-linux-androideabi-4.9"
		"$ROOT_LAMW/sdk/ndk-bundle/toolchains/arm-linux-androideabi-4.9"
		"$real_ppcarm"
		"$real_ppcarm"
		"$FPC_TRUNK_LIB_PATH/ppcx64"

	)


	local tools_chains_s_links=(
		"$ROOT_LAMW/ndk"
		"$ROOT_LAMW/ndk-toolchain"
		"$ROOT_LAMW/ndk-toolchain/arm-linux-as"
		"$ROOT_LAMW/ndk-toolchain/arm-linux-ld"
		"$ROOT_LAMW/lamw4linux/usr/bin/arm-linux-androideabi-as"
		"$ROOT_LAMW/lamw4linux/usr/bin/arm-linux-androideabi-ld"
		"$ROOT_LAMW/lamw4linux/usr/bin/arm-linux-androideabi-as"
		"$ROOT_LAMW/sdk/ndk-bundle/toolchains/mips64el-linux-android-4.9"
		"$ROOT_LAMW/sdk/ndk-bundle/toolchains/mipsel-linux-android-4.9"
		"$ROOT_LAMW/lamw4linux/usr/bin/ppcrossarm"
		"$ROOT_LAMW/lamw4linux/usr/bin/ppcarm"
		"$ROOT_LAMW/lamw4linux/usr/bin/ppcx64"
	)


	for ((i=0;i<${#tools_chains_orig[*]};i++));do
	 	[  -e "${tools_chains_s_links[i]}" ] && rm "${tools_chains_s_links[i]}"		
		ln -sf "${tools_chains_orig[i]}" "${tools_chains_s_links[i]}"	
	done 

}
#--------------------------AARCH64 SETTINGS--------------------------

configureFPCTrunk(){
	parseFPCTrunk
	$FPC_MKCFG_EXE -d basepath="$FPC_TRUNK_LIB_PATH" -o "$FPC_CFG_PATH"
	local fpc_trunk_parent="$(dirname "$FPC_TRUNK_LIB_PATH")"

	#this config enable to crosscompile in fpc 
	local fpc_cfg_str=(
		"#IFDEF ANDROID"
		"#IFDEF CPUARM"
		"-CpARMV7A"
		"-CfVFPV3"
		"-Xd"
		"-XParm-linux-androideabi-"
		"-Fl$ROOT_LAMW/ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/arm-linux-androideabi/$ANDROID_SDK_TARGET"
		"-FLlibdl.so"
		"-FD${ARM_ANDROID_TOOLS}"
		"#ENDIF"
		"#IFDEF CPUAARCH64"
		"-Xd"
		"-XPaarch64-linux-android-"
		"-Fl$ROOT_LAMW/ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/$ANDROID_SDK_TARGET"
		"-FLlibdl.so"
		"-FD${AARCH64_ANDROID_TOOLS}"
		"#ENDIF"
		"#IFDEF CPUI386"
		"-Cfsse3"
		"-Xd"
		"-XPi686-linux-android-"
		"-FLlibdl.so"
		"-FD${I386_ANDROID_TOOLS}"
		"-Fl$ROOT_LAMW/ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/i686-linux-android/$ANDROID_SDK_TARGET"
		"#ENDIF"
		"#IFDEF CPUX86_64"
		"-Cfsse3"
		"-Xd"
		"-XPx86_64-linux-android-"
		"-FD${AMD64_ANDROID_TOOLS}"
		"-FLlibdl.so"
		"-Fl$ROOT_LAMW/ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/x86_64-linux-android/$ANDROID_SDK_TARGET"
		"#ENDIF"
		"#ENDIF"
	)

	local fppkg_local_cfg=(
		'[Defaults]'
		'ConfigVersion=5'
		"Compiler=$FPC_TRUNK_EXEC_PATH/fpc"
		'OS=Linux'
	)
	local fpcpkg_cfg_str=(
			"[Defaults]"
			"ConfigVersion=5"
			"LocalRepository=$(dirname $FPPKG_LOCAL_REPOSITORY)/"
			"BuildDir={LocalRepository}build/"
			"ArchivesDir={LocalRepository}archives/"
			"CompilerConfigDir={LocalRepository}config/"
			"RemoteMirrors=https://www.freepascal.org/repository/mirrors.xml"
			"RemoteRepository=auto"
			"CompilerConfig=default"
			"FPMakeCompilerConfig=default"
			"Downloader=FPC"
			"InstallRepository=user"
			""
			"[Repository]"
			"Name=fpc"
			"Description=Packages which are installed along with the Free Pascal Compiler"
			"Path=${fpc_trunk_parent}/{CompilerVersion}/"
			"Prefix=$LAMW4LINUX_HOME/usr"
			""
			"[IncludeFiles]"
			"FileMask={LocalRepository}config/conf.d/*.conf"
			""
			"[Repository]"
			"Name=user"
			"Description=User-installed packages"
			"Path={LocalRepository}lib/fpc/{CompilerVersion}"
			"Prefix={LocalRepository}"
		)
	
	WriterFileln "$FPPKG_TRUNK_CFG_PATH" fpcpkg_cfg_str
	WriterFileln "$FPPKG_LOCAL_REPOSITORY_CFG" fppkg_local_cfg

	if [ -e $FPC_CFG_PATH ] ; then  # se exiir /etc/fpc.cfg
		if searchLineinFile $FPC_CFG_PATH  "${fpc_cfg_str[0]}"; then 
			AppendFileln "$FPC_CFG_PATH" "fpc_cfg_str" # caso o arquvo ainda não esteja configurado
		fi
	fi
}

CreateSimbolicLinksAndroidAARCH64(){
	ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-android-as" "$LLVM_ANDROID_TOOLCHAINS/aarch64-linux-as"
	ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-android-ld" "$LLVM_ANDROID_TOOLCHAINS/aarch64-linux-ld"
	ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-android-as" "$ROOT_LAMW/lamw4linux/usr/bin/aarch64-linux-android-as"
	ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-android-ld" "$ROOT_LAMW/lamw4linux/usr/bin/aarch64-linux-android-ld"
	ln -sf "${FPC_TRUNK_LIB_PATH}/ppcrossa64" $ROOT_LAMW/lamw4linux/usr/bin/ppcrossa64
	ln -sf "${FPC_TRUNK_LIB_PATH}/ppcrossa64" $ROOT_LAMW/lamw4linux/usr/bin/ppca64
}

CreateBinutilsSimbolicLinks(){
	[ ! -e "$ROOT_LAMW/lamw4linux/usr/bin" ] &&
		mkdir -p "$ROOT_LAMW/lamw4linux/usr/bin"
	CreateSDKSimbolicLinks
	CreateSimbolicLinksAndroidAARCH64
}

createLazarusEnvCfgFile(){
	local lazarus_env_cfg_str=(
		'<?xml version="1.0" encoding="UTF-8"?>'
		'<CONFIG>'
		'	<EnvironmentOptions>'
		"		<Version Value=\"110\" Lazarus=\"${lazarus_version_str}\"/>"
		"		<LazarusDirectory Value=\"${LAMW_IDE_HOME}/\"/>"
		"		<LastCalledByLazarusFullPath Value=\"${LAMW_IDE_HOME}/lazarus\"/>"
		"		<CompilerFilename Value=\"$FPC_TRUNK_EXEC_PATH/fpc\"/>"
		"		<FPCSourceDirectory Value=\"${FPC_TRUNK_SOURCE_PATH}/${FPC_TRUNK_SVNTAG}\">" 
		"		</FPCSourceDirectory>"
		"		<MakeFilename Value=\"$(which make)\">"
		"		</MakeFilename>"
		"		<TestBuildDirectory Value=\"/tmp\">"
		"		</TestBuildDirectory>"
		"		<FppkgConfigFile Value=\"${FPPKG_TRUNK_CFG_PATH}\"/>"
		'		<Debugger Class="TGDBMIDebugger">'
		'			<Configs>'
		'				<Config ConfigName="FpDebug" ConfigClass="TFpDebugDebugger" Active="True"/>'
		"				<Config ConfigName=\"Gdb\" ConfigClass=\"TGDBMIDebugger\" DebuggerFilename=\"$(which gdb)\"/>"
		'			</Configs>'
		"		</Debugger>"
		"	</EnvironmentOptions>"
		"</CONFIG>"
	)

	if [  ! -e "$lazarus_env_cfg_path" ]; then 
		WriterFileln  "$lazarus_env_cfg_path" "lazarus_env_cfg_str"
	fi
}


getNodeAttrXML(){
	xmlstarlet sel -t -v "$1" "$2"
}


updateNodeAttrXML(){
	newPtr xml_node_attr_ref=$1
	newPtr xml_new_node_attr_values=$2
	local xml_file_path="$3"
	
	for key in ${!xml_node_attr_ref[*]}; do 
		local node_attr="${xml_node_attr_ref[$key]}"
		local current_node_attr_value="$(getNodeAttrXML $node_attr $xml_file_path )"
		local expected_node_attr_value=${xml_new_node_attr_values[$key]}
			
		[ "$current_node_attr_value" != "$expected_node_attr_value" ] &&  #update attribute ref:#ref: https://stackoverflow.com/questions/7837879/xmlstarlet-update-an-attribute
			xmlstarlet edit  --inplace  -u "$node_attr" -v "$expected_node_attr_value" "$xml_file_path"
		
	done

}

CmdLineToolsTrigger(){
	local model_license_package="$ANDROID_SDK_ROOT/platform-tools/package.xml"
	local cmdline_tools_package="$CMD_SDK_TOOLS_DIR/latest/package.xml"
	if [ ! -e $cmdline_tools_package ];then
		cp $model_license_package $cmdline_tools_package 
		cmdlineExtraConfig
	fi
}

cmdlineExtraConfig(){
	local pattern_old_xml='xmlns:ns14'
	local xml_ns_version='3'
	grep "$pattern_old_xml" $cmdline_tools_package -q && xml_ns_version='5'
	local cmdline_tools_major_version=${CMD_SDK_TOOLS_VERSION_STR/%\.*}
	local cmdline_tools_old_str=`grep '</license' $cmdline_tools_package`
	local cmdline_tools_license_data=`grep '</license>' $cmdline_tools_package | awk -F'<' ' { printf $1 }'`
	local cmdline_tools_str="${cmdline_tools_license_data}</license><localPackage path=\"cmdline-tools;latest\" "
	cmdline_tools_str+="obsolete=\"false\"><type-details xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" "
	cmdline_tools_str+="xsi:type=\"ns${xml_ns_version}:genericDetailsType\"/><revision>"
	cmdline_tools_str+="<major>${cmdline_tools_major_version}</major><minor>0</minor></revision>"
	cmdline_tools_str+="<display-name>Android SDK Command-line Tools (latest)</display-name>"
	cmdline_tools_str+="<uses-license ref=\"android-sdk-license\"/></localPackage></ns2:repository>"
	cmdline_tools_old_str=$(GenerateScapesStr "${cmdline_tools_old_str:0:32}")
	sed -i "/${cmdline_tools_old_str}/d" $cmdline_tools_package
	printf "%s" "$cmdline_tools_str" >> $cmdline_tools_package
}

initLAMw4LinuxConfig(){
	local lazarus_version_str="`$LAMW_IDE_HOME/tools/install/get_lazarus_version.sh`"	
	local lazarus_env_cfg_path="$LAMW_IDE_HOME_CFG/environmentoptions.xml"
	local fppkg_cfg_node_attr="//CONFIG/EnvironmentOptions/FppkgConfigFile/@Value"	
	local env_opts_node="//CONFIG/EnvironmentOptions"
	local fppkg_cfg_node_attr="$env_opts_node/FppkgConfigFile/@Value"
	local fppkg_cfg_node="$env_opts_node/FppkgConfigFile"

	local -A lazarus_env_xml_nodes_attr=(
		['lazarus_version']="$env_opts_node/Version/@Lazarus"
		['lazarus_dir']="$env_opts_node/LazarusDirectory/@Value"
		['compiler_file']="$env_opts_node/CompilerFilename/@Value"
		['fpc_src']="$env_opts_node/FPCSourceDirectory/@Value"
	)

	local -A expected_env_xml_nodes_attr=(
		['lazarus_version']=$lazarus_version_str
		['lazarus_dir']=$LAMW_IDE_HOME
		['compiler_file']=$FPC_TRUNK_EXEC_PATH/fpc
		['fpc_src']=${FPC_TRUNK_SOURCE_PATH}/${FPC_TRUNK_SVNTAG}
	)

	if [ ! -e "$lazarus_env_cfg_path" ]; then
		createLazarusEnvCfgFile
	else
		grep 'LastCalledByLazarusFullPath' $lazarus_env_cfg_path > /dev/null
		if [ $? = 0 ]; then 
			local lazarus_env_xml_nodes_attr['last_laz_full_path']="${env_opts_node}/LastCalledByLazarusFullPath/@Value"
			local expected_env_xml_nodes_attr['last_laz_full_path']=$LAMW4LINUX_EXE_PATH
		fi

		[ -e  "${lazarus_env_cfg_path}.bak" ] && 
			rm "${lazarus_env_cfg_path}.bak" 
		cp $lazarus_env_cfg_path "${lazarus_env_cfg_path}.bak" 

		updateNodeAttrXML lazarus_env_xml_nodes_attr expected_env_xml_nodes_attr "$lazarus_env_cfg_path"

		grep 'FppkgConfigFile' $lazarus_env_cfg_path > /dev/null 

		if [ $? != 0 ]; then #insert fppkg_config ref: https://stackoverflow.com/questions/7837879/xmlstarlet-update-an-attribute
			xmlstarlet ed  --inplace -s "$env_opts_node" -t elem -n "FppkgConfigFile" -v "" -i $fppkg_cfg_node -t attr -n "Value" -v "$FPPKG_TRUNK_CFG_PATH" $lazarus_env_cfg_path
		else # update fppkg_config
			local current_fppkg_config_value=$(getNodeAttrXML "$fppkg_cfg_node_attr" $lazarus_env_cfg_path )
			[ "$current_fppkg_config_value" != "${FPPKG_TRUNK_CFG_PATH}" ] && 
				xmlstarlet edit  --inplace  -u "$fppkg_cfg_node_attr" -v "$FPPKG_TRUNK_CFG_PATH" "$lazarus_env_cfg_path"	
		fi 
	fi
}

