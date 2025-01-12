#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.6.9
#Date: 01/12/2025
#Description:The "cross-builder.sh" is part of the core of LAMW Manager.  This script contains crosscompile compiler generation routines for ARMv7 / AARCH64- Android
#-------------------------------------------------------------------------------------------------#

#this function set env to FPC_TRUNK 
parseFPCTrunk(){
	_FPC_TRUNK_VERSION=${FPC_TRUNK_VERSION%\-*}
	FPC_TRUNK_LIB_PATH=$LAMW4LINUX_HOME/usr/lib/fpc/${_FPC_TRUNK_VERSION}
	FPC_TRUNK_EXEC_PATH="$LAMW4LINUX_HOME/usr/bin"
	FPC_CFG_PATH="$FPC_TRUNK_LIB_PATH/fpc.cfg"
	FPPKG_TRUNK_CFG_PATH="$FPC_TRUNK_LIB_PATH/fppkg.cfg"
	export PPC_CONFIG_PATH="$FPC_TRUNK_LIB_PATH"
	
}

BuildFPC(){
	
	local pp="$FPC_LIB_PATH/ppcx64"
	local install_prefix="$LAMW4LINUX_HOME/usr"

	case $1 in
		0)	
			#ref: https://www.freepascal.org/docs-html/current/prog/progsu221.html
			#ref: https://wiki.freepascal.org/FPC_recompilation_automation
			make -s  clean all install INSTALL_PREFIX=$install_prefix "PP=$pp" -j $CPU_COUNT  FPMAKEOPT="-T $CPU_COUNT";; 

		1)
			make -s  clean crossall crossinstall CPU_TARGET=aarch64 OS_TARGET=android OPT="-dFPC_ARMHF"\
				INSTALL_PREFIX=$install_prefix "PP=$pp"  -j $CPU_COUNT  FPMAKEOPT="-T $CPU_COUNT" ;;
		2)
			make -s  clean crossall crossinstall CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android\
				CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=$install_prefix "PP=$pp" -j $CPU_COUNT  FPMAKEOPT="-T $CPU_COUNT";;
		3) 
			make -s  clean crossall crossinstall CPU_TARGET=x86_64 OS_TARGET=android "PP=$pp"\
				 INSTALL_PREFIX=$install_prefix OPT="-Cfsse3" CROSSOPT="-Cfsse3" -j $CPU_COUNT  FPMAKEOPT="-T $CPU_COUNT" ;;
		4)
			make -s  clean crossall crossinstall CPU_TARGET=i386 OS_TARGET=android "PP=$pp"\
				INSTALL_PREFIX=$install_prefix OPT="-Cfsse3" CROSSOPT="-Cfsse3"  -j $CPU_COUNT  FPMAKEOPT="-T $CPU_COUNT" ;;
		*) 
			check_error_and_exit "${VERMELHO}Fatal Error:${NORMAL}Invalid CrossOpts";;
	esac
}

buildCurrentFPC(){
	local error_build_msg="${VERMELHO}Fatal Error:${NORMAL} Falls to build FPC to ${build_aarch[$i]}"
	local build_msg="Please wait, starting build FPC to ${NEGRITO}${build_aarch[i]}${NORMAL}"
	local sucess_filler="$(getCurrentSucessFiller 0 ${build_aarch[i]})"

	startProgressBar
	BuildFPC $i > /dev/null
	
	if [ $? != 0 ]; then 
		stopProgressBarAsFail
		printf  "%s\n" "${FILLER:${#sucess_filler}}${VERMELHO} [FALLS]${NORMAL}"
		printf "%s" "$build_msg"
		BuildFPC $i
		check_error_and_exit ${error_build_msg[i]}
	fi

	stopAsSuccessProgressBar
}

getMaxBuildArchs(){
	if [ $LAMW_MINIMAL_INSTALL = 0 ]; then
		echo ${#build_aarch[*]}
	else
		echo $MIN_LAMW_ARCHS
	fi
}

checkFPCTrunkIntegrity(){
	local sucess_filler="checking integrity of FPC ${NEGRITO}${build_aarch[$1]}${NORMAL}"

	if [ ! -e $FPC_TRUNK_LIB_PATH/${ppcs_name[$1]} ] || [ ! -e $sha256_current_pp ]; then 
		return 1;
	fi

	startProgressBar 

	if ! sha256sum -c $sha256_current_pp --quiet; then
		rm $sha256_current_pp
		stopProgressBarAsFail
		FORCE_LAZARUS_CLEAN_BUILD=1
		return 1
	fi

	stopAsSuccessProgressBar

	return 0;
}

registryFPCTrunkIntegrity(){
	[  -e $sha256_current_pp ] && return
	
	local sucess_filler="calculing FPC ${NEGRITO}${build_aarch[$1]}${NORMAL} checksum"
	local pppath=${build_aarch[$1],,}
	pppath=${pppath//\//\-}
	local find_paths=("${FPC_TRUNK_LIB_PATH}/units/${pppath}" "${FPC_TRUNK_LIB_PATH}/fpmkinst/$pppath")
	local obj_regex='(\.o$)'
	startProgressBar
	protectedTrapActions
	sha256sum $FPC_TRUNK_LIB_PATH/${ppcs_name[$1]}  > $sha256_current_pp

	for file in $(find ${find_paths[@]} ); do
		
		([[ -d "$file" ]] || [[ "$file" =~ $obj_regex ]] ) && continue

		sha256sum $file  >> $sha256_current_pp
	done
	stopAsSuccessProgressBar
	resetTrapActions


}
#Function to build ARMv7 and AARCH64
buildCrossAndroid(){
	local build_aarch=( "x86_64/Linux" {AARCH64,ARM,x86_64,i386}/Android)
	local ppcs_name=(ppcx64  ppcrossa64 ppcrossarm ppcrossx64 ppcross386)
	local max_archs=$(getMaxBuildArchs)
	changeDirectory "$LAMW4LINUX_HOME/usr/share/fpcsrc/$FPC_TRUNK_SVNTAG"
	
	for ((i=0;i<$max_archs;i++)) do
		local sha256_current_pp=$FPC_TRUNK_LIB_PATH/.sha256sum-${ppcs_name[$i]}.txt
		checkFPCTrunkIntegrity $i && continue
		buildCurrentFPC
		registryFPCTrunkIntegrity $i
	done

	local sucess_filler="$(getCurrentSucessFiller 2 android/Linux)"
	startProgressBar
	make -s  clean > /dev/null 2>&1
	stopAsSuccessProgressBar
}