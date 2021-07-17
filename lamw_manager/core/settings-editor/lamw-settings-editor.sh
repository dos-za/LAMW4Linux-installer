#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (mater-alma)
#Course: Science Computer
#Version: 0.4.0
#Date: 06/12/2021
#Description: The "lamw-manager-settings-editor.sh" is part of the core of LAMW Manager. Responsible for managing LAMW Manager / LAMW configuration files..
#-------------------------------------------------------------------------------------------------#
#this function builds initial struct directory of LAMW env Development !
initROOT_LAMW(){
	if [ ! -e $ANDROID_SDK ]; then 
		mkdir -p $ANDROID_SDK
	fi

	[ ! -e "$ROOT_LAMW/jdk" ] && mkdir "$ROOT_LAMW/jdk"

	if  [ ! -e $LAMW_USER_HOME/.android ]; then
		mkdir $LAMW_USER_HOME/.android 
		echo "" > $LAMW_USER_HOME/.android/repositories.cfg
	fi

	if [ !  -e $HOME/.android ]; then
		mkdir -p $HOME/.android 	
		echo "" > $HOME/.android/repositories.cfg
	fi 
}

enableADBtoUdev(){
	  printf 'SUBSYSTEM=="usb", ATTR{idVendor}=="<VENDOR>", MODE="0666", GROUP="plugdev"\n'  |  tee /etc/udev/rules.d/51-android.rules
	  service udev restart
}


AddSDKPathstoProfile(){
	local profile_file=$LAMW_USER_HOME/.bashrc
	local flag_profile_paths=0
	local profile_line_path='export PATH=$PATH:$GRADLE_HOME/bin'

	InsertUniqueBlankLine "$LAMW_USER_HOME/.profile"
	InsertUniqueBlankLine "$LAMW_USER_HOME/.bashrc"
	cleanPATHS
	searchLineinFile "$profile_file" "$profile_line_path"
	flag_profile_paths=$?

	if [ $flag_profile_paths = 0 ] ; then 
		echo "export ANDROID_HOME=$ANDROID_HOME" >>  $LAMW_USER_HOME/.bashrc
		echo "export GRADLE_HOME=$GRADLE_HOME" >> $LAMW_USER_HOME/.bashrc
		echo 'export PATH=$PATH:$ANDROID_HOME/ndk-toolchain' >> $LAMW_USER_HOME/.bashrc
		echo 'export PATH=$PATH:$GRADLE_HOME/bin' >> $LAMW_USER_HOME/.bashrc
	fi

	export PATH=$PATH:$ROOT_LAMW/ndk-toolchain
	export PATH=$PATH:$GRADLE_HOME/bin
}

#Esta funcao altera todos o dono de todos arquivos e  pastas do ambiente LAMW de root para o $LAMW_USER_HOME
#Ou seja para o usuario que invocou o lamw_manager (bootstrap)
changeOwnerAllLAMW(){
	#case only update-lamw
	if [ $# = 1 ]; then
		local files_chown=(
			"$LAMW4_LINUX_PATH_CFG"
			"$ROOT_LAMW/lazandroidmodulewizard"
			"$LAMW_IDE_HOME/" #obs: $LAMW_IDE_HOME é um link simbólico, por isso deve ser usar / ao final para referir ao conteúdo da pasta.
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
			"$LAMW4_LINUX_PATH_CFG"
			"$LAMW_MANAGER_LOCAL_CONFIG_DIR"
				
		#	
		)		
	fi
	echo "Restoring directories ..."
	for ((i=0;i<${#files_chown[*]};i++))
	do
		if [ -e ${files_chown[i]} ] ; then
			if [ $i = 0 ] ; then 
				# caso $LAMW_USER não seja dono do diretório LAMW_USER_HOME/Dev ou $LAMW_WORKSPACE_HOME
				if  [ $UID = 0 ] && ( [ -O ${files_chown[i]} ] || [ -O  "$LAMW_WORKSPACE_HOME" ] ); then 
					chown $LAMW_USER:$LAMW_USER -R ${files_chown[i]}
				fi
			else 
				chown $LAMW_USER:$LAMW_USER -R ${files_chown[i]}
			fi
		fi
	done
}
#write log lamw install 
writeLAMWLogInstall(){
	local fpc_version=$FPC_VERSION
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		fpc_version=$FPC_TRUNK_VERSION

	fi

	local lamw_log_str=(
		"Generate LAMW_INSTALL_VERSION=$LAMW_INSTALL_VERSION" 
		"Info:"
		"LAMW4Linux:$LAMW4LINUX_HOME"
		"LAMW workspace:$LAMW_WORKSPACE_HOME"
		"Android SDK:$ROOT_LAMW/sdk" 
		"Android NDK:$ROOT_LAMW/ndk\nGradle:$GRADLE_HOME"
		"OLD_ANDROID_SDK=$OLD_ANDROID_SDK"
		"ANT_VERSION=$ANT_VERSION_STABLE"
		"GRADLE_VERSION=$GRADLE_VERSION"
		"SDK_TOOLS_VERSION=$SDK_TOOLS_VERSION"
		"NDK_VERSION=$NDK_VERSION"
		"FPC_VERSION=$fpc_version"
		"LAZARUS_VERSION=$LAZARUS_STABLE_VERSION"
		"AARCH64_SUPPORT=$FLAG_FORCE_ANDROID_AARCH64"
		"Install-date:$(date)"
	)

	WriterFileln "$LAMW4LINUX_HOME/lamw-install.log" "lamw_log_str"
	if [ "$NOTIFY_SEND_EXE" != "" ]; then
		$NOTIFY_SEND_EXE    "Info:\nLAMW4Linux:$LAMW4LINUX_HOME\nLAMW workspace : $LAMW_WORKSPACE_HOME\nAndroid SDK:$ROOT_LAMW/sdk\nAndroid NDK:$ROOT_LAMW/ndk\nGradle:$GRADLE_HOME\nLOG:$LAMW4LINUX_HOME/lamw-install.log"
	else
		printf "Info:\nLAMW4Linux:$LAMW4LINUX_HOME\nLAMW workspace : $LAMW_USER_HOME/Dev/lamw_workspace\nAndroid SDK:$ROOT_LAMW/sdk\nAndroid NDK:$ROOT_LAMW/ndk\nGradle:$GRADLE_HOME\nLOG:$LAMW4LINUX_HOME/lamw-install.log\n"
	fi		

}

#Add LAMW4Linux to menu 
AddLAMWtoStartMenu(){
	if [ ! -e $LAMW_USER_HOME/.local/share/applications ] ; then #create a directory of local apps launcher, if not exists 
		mkdir -p $LAMW_USER_HOME/.local/share/applications
	fi
	if [ ! -e $LAMW_USER_HOME/.local/share/mime/packages ]; then
		mkdir -p $LAMW_USER_HOME/.local/share/mime/packages
	fi
	
	local lamw_desktop_file_str=(
		"[Desktop Entry]"  
		"Name=LAMW4Linux"
		"GenericName=LAMW4Linux"   
		"Exec=$LAMW_IDE_HOME/startlamw4linux"
		"Icon=$LAMW_IDE_HOME/images/icons/lazarus_orange.ico"
		"Terminal=false"
		"Type=Application"  
		"Categories=Development;IDE;"  
		"Categories=Application;IDE;Development;GTK;GUIDesigner;"
		"StartupWMClass=LAMW4Linux"
		"MimeType=text/x-pascal;text/lazarus-project-source;text/lazarus-project-information;text/lazarus-form;text/lazarus-resource;text/lazarus-package;text/lazarus-package-link;text/lazarus-code-inlay;"
		"Keywords=editor;Pascal;IDE;FreePascal;fpc;Design;Designer;"
		"[Property::X-KDE-NativeExtension]"
		"Type=QString"
		"Value=.pas"
		"X-Ubuntu-Gettext-Domain=desktop_kdelibs"
	)

	WriterFileln "$LAMW_MENU_ITEM_PATH" "lamw_desktop_file_str"
	chmod +x $LAMW_MENU_ITEM_PATH
	cp $LAMW_MENU_ITEM_PATH "$WORK_HOME_DESKTOP"
	#mime association: ref https://help.gnome.org/admin/system-admin-guide/stable/mime-types-custom-user.html.en
	cp $LAMW_IDE_HOME/install/lazarus-mime.xml $LAMW_USER_HOME/.local/share/mime/packages
	update-mime-database   $LAMW_USER_HOME/.local/share/mime/
	update-desktop-database $LAMW_USER_HOME/.local/share/applications
	update-menus
}

#this  fuction create a INI file to config  all paths used in lamw framework 
LAMW4LinuxPostConfig(){
	local old_lamw_workspace="$LAMW_USER_HOME/Dev/lamw_workspace"
	if [ ! -e $LAMW4_LINUX_PATH_CFG ] ; then
		mkdir $LAMW4_LINUX_PATH_CFG
	fi

	if [ -e $old_lamw_workspace ]; then
		mv $old_lamw_workspace $LAMW_WORKSPACE_HOME
	fi
	if [ ! -e $LAMW_WORKSPACE_HOME ] ; then
		mkdir -p $LAMW_WORKSPACE_HOME
	fi
	local ant_path=$ANT_HOME/bin
	ant_path=${ant_path%/ant*} #

	#testa modificação de workspace
	if [ -e "$LAMW4_LINUX_PATH_CFG/LAMW.ini" ]; then 
		local current_lamw_workspace=$(grep '^PathToWorkspace=' $LAMW4_LINUX_PATH_CFG/LAMW.ini  | sed 's/PathToWorkspace=//g')
		if [ "$current_lamw_workspace" != "$LAMW_WORKSPACE_HOME" ]; then
			LAMW_WORKSPACE_HOME=$current_lamw_workspace
		fi
	fi
# contem o arquivo de configuração do lamw
	local LAMW_init_str=(
		"[NewProject]"
		"PathToWorkspace=$LAMW_WORKSPACE_HOME"
		"PathToSmartDesigner=$ROOT_LAMW/lazandroidmodulewizard/android_wizard/smartdesigner"
		"PathToJavaTemplates=$ROOT_LAMW/lazandroidmodulewizard/android_wizard/smartdesigner/java"
		"PathToJavaJDK=$JAVA_HOME"
		"PathToAndroidNDK=$ROOT_LAMW/ndk"
		"PathToAndroidSDK=$ROOT_LAMW/sdk"
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
	local startlamw4linux_str=(
		'#!/bin/bash'
		"export PPC_CONFIG_PATH=$PPC_CONFIG_PATH"
		"export JAVA_HOME=$JAVA_HOME"
		"export PATH=$ROOT_LAMW/lamw4linux/usr/bin:\$PPC_CONFIG_PATH:\$JAVA_HOME/bin:\$PATH"
		"$LAMW4LINUX_EXE_PATH --pcp=$LAMW4_LINUX_PATH_CFG \$*"
	)

	WriterFileln "$LAMW4_LINUX_PATH_CFG/LAMW.ini" "LAMW_init_str"
	WriterFileln "$LAMW_IDE_HOME/startlamw4linux" "startlamw4linux_str"

	if [ -e  $LAMW_IDE_HOME/startlamw4linux ]; then
		chmod +x $LAMW_IDE_HOME/startlamw4linux
		if [ ! -e "/usr/bin/startlamw4linux" ]; then
			ln -s "$LAMW_IDE_HOME/startlamw4linux" "/usr/bin/startlamw4linux"
		fi
	fi

	AddLAMWtoStartMenu
}

ActiveProxy(){
	svn --help > /dev/null
	if  [ $1 = 1 ]; then
		if [ -e ~/.subversion/servers ] ; then
			aux=$(tail -1 ~/.subversion/servers)       #tail -1 mostra a última linha do arquivo 
			if [ "$aux" != "" ] ; then   # verifica se a última linha é vazia
				sed  -i '$a\' ~/.subversion/servers #adiciona uma linha ao fim do arquivo
			fi
			#echo "write proxy with svn"
			echo "http-proxy-host=$PROXY_SERVER" >> ~/.subversion/servers
			echo "http-proxy-port=$PORT_SERVER" >> ~/.subversion/servers
			git config --global core.gitproxy $PROXY_URL #"http://$HOST:$PORTA"
			git config --global http.gitproxy $PROXY_URL #"http://$HOST:$PORTA"
		fi

	else
		sed -i "/http-proxy-host=$HOST/d" ~/.subversion/servers
		sed -i "/http-proxy-port=$PORTA/d" ~/.subversion/servers
		git config --global --unset core.gitproxy
		git config --global --unset http.gitproxy
		if [ -e ~/.gitconfig ] ;then
		#cat ~/.gitconfig
			sed -i '/\[core\]/d' ~/.gitconfig
			#cat ~/.gitconfig
			sed -i '/\[http\]/d' ~/.gitconfig
		fi
	fi
}
CleanOldCrossCompileBins(){
	wrapperParseFPC
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

	
	if [ $CURRENT_OLD_LAMW_INSTALL_INDEX -lt  0 ]; then
		return 1
	fi


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
			if [ -e ${clean_files[i]} ]  && [ $current_old_lamw_manager  = $lamw_manager_v031 ];then
				rm -rf ${clean_files[i]}
			fi
		fi
	done

	if [  -e /usr/local/bin/fpc ] &&  [ $current_old_lamw_manager = $lamw_manager_v031 ]; then
		local fpc_tmp_files=("bin2obj" "chmcmd" "chmls" "cldrparser" "compileserver" "cvsco.tdf" "cvsdiff.tdf" "cvsup.tdf" "data2inc" "delp" "fd2pascal" "fp" "fp.ans" "fpc" "fpcjres" "fpclasschart" "fpclasschart.rsj" "fpcmake" "fpcmkcfg" "fpcmkcfg.rsj" "fpcres" "fpcsubst" "fpcsubst.rsj" "fpdoc" "fppkg" "fprcp" "fp.rsj" "gplprog.pt" "gplunit.pt" "grab_vcsa" "grep.tdf" "h2pas" "h2paspp" "instantfpc" "json2pas" "makeskel" "makeskel.rsj" "mka64ins" "mkarmins" "mkinsadd" "mkx86ins" "pas2fpm" "pas2jni" "pas2js" "pas2ut" "pas2ut.rsj" "plex" "postw32" "ppdep" "ppudump" "ppufiles" "ppumove" "program.pt" "ptop" "ptop.rsj" "pyacc" "rmcvsdir" "rstconv" "rstconv.rsj" "tpgrep.tdf" "unihelper" "unitdiff" "unitdiff.rsj" "unit.pt" "webidl2pas")
		for((i=0;i<${#fpc_tmp_files[*]};i++)); do
			local aux="/usr/local/bin/${fpc_tmp_files[i]}"
			if [ -e $aux ]; then  rm $aux ; fi
		done
	fi
	
}

	

cleanPATHS(){
	sed -i "/export ANDROID_HOME=*/d"  $LAMW_USER_HOME/.bashrc
	sed -i "/export GRADLE_HOME=*/d" $LAMW_USER_HOME/.bashrc
	sed -i '/export PATH=$PATH:$ANDROID_HOME\/android\/ndk-toolchain/d'  $LAMW_USER_HOME/.bashrc #\/ is scape of /
	sed -i '/export PATH=$PATH:$ANDROID_HOME\/android\/gradle-4.1\/bin/d' $LAMW_USER_HOME/.bashrc
	sed -i '/export PATH=$PATH:$ANDROID_HOME\/android\/ndk-toolchain/d'  $LAMW_USER_HOME/.profile
	sed -i '/export PATH=$PATH:$ANDROID_HOME\/android\/gradle-4.1\/bin/d' $LAMW_USER_HOME/.profile	
	sed -i '/export PATH=$PATH:$ANDROID_HOME\/ndk-toolchain/d'  $LAMW_USER_HOME/.bashrc
	sed -i '/export PATH=$PATH:$GRADLE_HOME/d'  $LAMW_USER_HOME/.bashrc
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

	if [ $CURRENT_OLD_LAMW_INSTALL_INDEX -lt 0 ] && [  $1 -lt $system_index_deleted_files ]; then  #ignora binarios fpc/arm  se o ambiente de desenvolvimento lamw não estiver instalado
		return 1
	fi

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
	wrapperParseFPC
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
		"$LAMW4_LINUX_PATH_CFG"
		"$ROOT_LAMW"
		"$LAMW_MENU_ITEM_PATH"
		#"$GRADLE_CFG_HOME"
		"$WORK_HOME_DESKTOP/lamw4linux.desktop"
		"$LAMW_USER_HOME/.local/share/mime/packages/lazarus-mime.xml"
		#"$LAMW_USER_HOME/.android"
		#"/root/.android"
		"$FPC_TRUNK_LIB_PATH"
		"/root/.fpc.cfg"
		"$OLD_FPC_CFG_PATH"
	)

	echo "Uninstalling LAMW4Linux IDE ..."

	for((i=0;i<${#list_deleted_files[*]};i++))
	do
		if [ -e "${list_deleted_files[i]}" ]; then 
			if [ -d  "${list_deleted_files[i]}" ]; then 
				local rm_opts="-rf"
			fi
			validate_is_file_create_by_lamw_manager $i "${list_deleted_files[i]}"
			if [ $? = 0 ]; then 
				rm  "${list_deleted_files[i]}" $rm_opts
			fi
		fi
	done
	CleanOldCrossCompileBins
	update-mime-database   $LAMW_USER_HOME/.local/share/mime/
	update-desktop-database $LAMW_USER_HOME/.local/share/applications
	cleanPATHS
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


	for ((i=0;i<${#tools_chains_orig[*]};i++))
	do
		if [  -e "${tools_chains_s_links[i]}" ]; then  
			rm "${tools_chains_s_links[i]}"
		fi		
		ln -sf "${tools_chains_orig[i]}" "${tools_chains_s_links[i]}"	
	done 

}
#--------------------------AARCH64 SETTINGS--------------------------

configureFPCTrunk(){
	# parte do arquivo de configuração do fpc, 
	#	if [ ! -e $FPC_CFG_PATH ]; then
	parseFPCTrunk
	$FPC_MKCFG_EXE -d basepath=$FPC_TRUNK_LIB_PATH -o $FPC_CFG_PATH


	local fpc_trunk_parent=$FPC_TRUNK_LIB_PATH
	fpc_trunk_parent=$(echo $fpc_trunk_parent | sed "s/\/$_FPC_TRUNK_VERSION//g")
	#ls $fpc_trunk_parent;echo $fpc_trunk_parent;read;

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
		"-Fu${fpc_trunk_parent}/"'$fpcversion/units/$fpctarget'
		"-Fu${fpc_trunk_parent}/"'$fpcversion/units/$fpctarget/*'
		"-Fu${fpc_trunk_parent}/"'$fpcversion/units/$fpctarget/rtl'
		"-FD${ARM_ANDROID_TOOLS}"
		"#ENDIF"
		"#IFDEF CPUAARCH64"
		"-Xd"
		"-XPaarch64-linux-android-"
		"-Fl$ROOT_LAMW/ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/$ANDROID_SDK_TARGET"
		"-FLlibdl.so"
		"-FD${AARCH64_ANDROID_TOOLS}"
		"-Fu${fpc_trunk_parent}/"'$fpcversion/units/$fpctarget'
		"-Fu${fpc_trunk_parent}/"'$fpcversion/units/$fpctarget/*'
		"-Fu${fpc_trunk_parent}/"'$fpcversion/units/$fpctarget/rtl'
	
		"#ENDIF"
		"#ENDIF"
	)

	if [ -e $FPC_CFG_PATH ] ; then  # se exiir /etc/fpc.cfg
		searchLineinFile $FPC_CFG_PATH  "${fpc_cfg_str[0]}"
		flag_fpc_cfg=$?

		if [ $flag_fpc_cfg != 1 ]; then # caso o arquvo ainda não esteja configurado
			AppendFileln "$FPC_CFG_PATH" "fpc_cfg_str"		
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
	if [ ! -e "$ROOT_LAMW/lamw4linux/usr/bin" ]; then 
		mkdir -p "$ROOT_LAMW/lamw4linux/usr/bin"
	fi
	CreateSDKSimbolicLinks
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		CreateSimbolicLinksAndroidAARCH64
	fi
}

#echo "importei lamw-settings-editor.sh";read

CreateFPCTrunkBootStrap(){

	local fpc_trunk_boostrap_path="$FPC_TRUNK_EXEC_PATH/fpc"
	local fpc_bootstrap_str=(
		'#!/bin/bash'
		"#Bootsrap(to FPC Trunk) generate by LAMW Manager"
		"#### THIS FILE IS AUTOMATICALLY CONFIGURED"
		#"export LAMW_ENV=$LAMW4LINUX_HOME/usr/bin"
		#'export PATH=$LAMW_ENV:$PATH'
		"export FPC_TRUNK_LIB_PATH=$FPC_TRUNK_LIB_PATH"
		#'export LD_LIBRARY=$LAMW_ENV/usr/lib:$LD_LIBRARY'
		#sudo ldconfig
		'export FPC_ARGS=($*)'
		'export FPC_EXEC="ppcx64"'
		#'if [ -e $FPC_TRUNK_LIB_PATH/ppcrossa64 ]; then'
		'if [ -e $FPC_TRUNK_LIB_PATH/ppcrossarm ]; then'
		'	export PATH=$FPC_TRUNK_LIB_PATH:$PATH'
		'fi'

		''
		'for((i=0;i<${#FPC_ARGS[*]};i++))'
		'do'

		'		case "${FPC_ARGS[i]}" in'
		'			"-Parm")'
		'				export FPC_EXEC="ppcarm"'
		'				break'
		'			;;'

		'			"-Paarch64")'
		'				export FPC_EXEC="ppca64"'
		'				break'
		'			;;'
		'		esac'
		'done'
		'$FPC_EXEC ${FPC_ARGS[@]}'
	)

	WriterFileln "$fpc_trunk_boostrap_path" "fpc_bootstrap_str"
	chmod +x "$fpc_trunk_boostrap_path"
}

initLAMw4LinuxConfig(){
	local lazarus_env_cfg_str=(
		'<?xml version="1.0" encoding="UTF-8"?>'
		'<CONFIG>'
		'	<EnvironmentOptions>'
		"		<Version Value=\"110\" Lazarus=\"${LAZARUS_STABLE_VERSION}\"/>"
		"		<LazarusDirectory Value=\"${LAMW_IDE_HOME}/\"/>"
		"		<CompilerFilename Value=\"$FPC_TRUNK_EXEC_PATH/fpc\"/>"
		"		<FPCSourceDirectory Value=\"${FPC_TRUNK_SOURCE_PATH}/${FPC_TRUNK_SVNTAG}\">" 
		"		</FPCSourceDirectory>"
		"		<MakeFilename Value=\"$(which make)\">"
		"		</MakeFilename>"
		"		<TestBuildDirectory Value=\"/tmp\">"
		"		</TestBuildDirectory>"
		"	</EnvironmentOptions>"
		"</CONFIG>"
	)
	local lazarus_env_cfg_path="$LAMW4_LINUX_PATH_CFG/environmentoptions.xml"

	if [ ! -e $LAMW4_LINUX_PATH_CFG ]; then
		mkdir $LAMW4_LINUX_PATH_CFG
		WriterFileln  "$lazarus_env_cfg_path" "lazarus_env_cfg_str"
	else
		local fpc_splited=(
			$(GenerateScapesStr "/usr/bin/fpc"					)				 		#0
			$(GenerateScapesStr "/usr/share/fpcsrc/\$(FPCVer)"	) 						#1
			$(GenerateScapesStr "/usr/local/bin/fpc"			)						#2
			$(GenerateScapesStr "$FPC_TRUNK_SOURCE_PATH/trunk" 	)						#3
			$(GenerateScapesStr "$LAMW4LINUX_HOME/usr/bin/fpc" 	)						#4
			$(GenerateScapesStr "$FPC_TRUNK_SOURCE_PATH/${FPC_TRUNK_SVNTAG}")			#5
		)
		
		local old_lazarus_version_file=$(grep 'Lazarus='  "$lazarus_env_cfg_path" | sed 's/<//g' | sed 's/Version//g'| sed 's/Value//g'  | sed 's/"110"//g' | sed 's/=//g' | sed 's/Lazarus//g' | sed 's/"//g' | sed 's/\/>//g' | sed 's/[[:space:]]//g' ) # remove'	<Version Value=\"110\" Lazarus=X.Y.Z', restando  X.Y.Z
		local old_stable_lazarus="lazarus_"${old_lazarus_version_file//\./_} #cria a string lazarus_X_Y_Z usando a expansao que substitui . por _
		local old_lazarus_version_file_scap=${old_lazarus_version_file//\./\\\.} # substitui X.Y.Z por X\.Y\.Z na string
		local lazarus_stable_version_scap=${LAZARUS_STABLE_VERSION//\./\\\.} # substitui X.Y.Z por X\.Y\.Z na string

		grep 'CompilerFilename Value=\"\/usr\/bin\/fpc\"' $lazarus_env_cfg_path 
		if [ $? = 0 ]; then
			sed -i "s/CompilerFilename Value=\"${fpc_splited[0]}\"/CompilerFilename Value=\"${fpc_splited[4]}\"/g" "$lazarus_env_cfg_path"
			sed -i "s/FPCSourceDirectory Value=\"${fpc_splited[1]}\"/FPCSourceDirectory Value=\"${fpc_splited[5]}\"/g" "$lazarus_env_cfg_path"
		fi

		grep 'CompilerFilename Value=\"\/usr\/local\/bin\/fpc\"' "$lazarus_env_cfg_path"
		if [ $? = 0 ]; then
			sed -i "s/CompilerFilename Value=\"${fpc_splited[2]}\"/CompilerFilename Value=\"${fpc_splited[4]}\"/g" "$lazarus_env_cfg_path"
			sed -i "s/FPCSourceDirectory Value=\"${fpc_splited[3]}\"/FPCSourceDirectory Value=\"${fpc_splited[5]}\"/g" "$lazarus_env_cfg_path"
		fi

		#caso FPCSource foi apontado para um arquivo inesperado
		grep "FPCSourceDirectory\sValue=\"${fpc_splited[5]}\""  $lazarus_env_cfg_path  > /dev/null
		if [ $? != 0 ]; then 
			local wrong_fpc_splited_path=$(GenerateScapesStr $(grep 'FPCSourceDirectory'  $lazarus_env_cfg_path  |sed -r 's/    //g' |sed  's/<FPCSourceDirectory Value=//g' | sed 's/\/>//g' | sed 's/>//g' | sed 's/"//g'))
			echo "$wrong_fpc_splited_path"
			sed -i "s/FPCSourceDirectory Value=\"${wrong_fpc_splited_path}\"/FPCSourceDirectory Value=\"${fpc_splited[5]}\"/g" "$lazarus_env_cfg_path"	
		fi

	
		#altera as versoes do lazarus $lazarus_env_cfg_path
		if [ "$old_stable_lazarus" != "$LAZARUS_STABLE" ]; then 
			sed -i "s/Lazarus=\"$old_lazarus_version_file_scap\"/Lazarus=\"$lazarus_stable_version_scap\"/g" "$lazarus_env_cfg_path"
			sed -i "s/$old_stable_lazarus/$LAZARUS_STABLE/g" "$lazarus_env_cfg_path"
		fi

	fi
}