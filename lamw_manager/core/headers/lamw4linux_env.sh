#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.6.9
#Date: 01/12/2025
#Description: The "lamw_headers" is part of the core of LAMW Manager. This script contains LAMW Manager variables.
#-------------------------------------------------------------------------------------------------#
LAMW_IDE_HOME_CFG="$LAMW_USER_HOME/.lamw4linux"
LAMW4LINUX_HOME="$ROOT_LAMW/lamw4linux"
LAMW_INSTALL_LOG="$LAMW4LINUX_HOME/lamw-install.log"
LAMW4LINUX_ETC="$LAMW4LINUX_HOME/etc"
LAMW4LINUX_LOCAL_ENV="$LAMW4LINUX_ETC/environment"
IGNORE_XFCE_LAMW_ERROR_PATH="$LAMW4LINUX_ETC/lamw-xfce-error.conf"
LAMW_WORKSPACE_HOME="$LAMW_USER_HOME/Dev/LAMWProjects"  #path to lamw_workspace
LAMW_USER_APPLICATIONS_PATH="$LAMW_USER_HOME/.local/share/applications"
LAMW_USER_MIMES_PATH="$LAMW_USER_HOME/.local/share/mime/packages"
LAMW_MENU_ITEM_PATH="$LAMW_USER_APPLICATIONS_PATH/lamw4linux.desktop"
LAMW4LINUX_TERMINAL_MENU_PATH="$LAMW_USER_APPLICATIONS_PATH/lamw4linux-terminal.desktop"
LAMW4LINUX_TERMINAL_EXEC_PATH="$LAMW4LINUX_HOME/usr/bin/lamw4linux-terminal"
FPPKG_LOCAL_REPOSITORY="$LAMW4LINUX_HOME/.fppkg/config"
FPPKG_LOCAL_REPOSITORY_CFG=$FPPKG_LOCAL_REPOSITORY/default
LAMW4LINUX_TEMPLATES_BASE_PATH=$LAMW_MANAGER_MODULES_PATH/settings-editor/templates
STARTUP_ERROR_LAMW4LINUX_PATH="$LAMW4LINUX_ETC/startup-check-errors-lamw4linux.sh"
LAMW_MANAGER_COMPLETION="$LAMW4LINUX_ETC/lamw_manager_completion.sh"
FPC_ANDROID_CFG=$LAMW4LINUX_ETC/fpc-android.cfg

declare -A LAMW4LINUX_TEMPLATES_PATHS=(
	["$LAMW_MENU_ITEM_PATH"]="$LAMW_IDE_HOME/install/lazarus.desktop"
	["$LAMW4LINUX_TERMINAL_MENU_PATH"]="$LAMW4LINUX_TEMPLATES_BASE_PATH/$(basename $LAMW4LINUX_TERMINAL_MENU_PATH)"
	["$STARTUP_ERROR_LAMW4LINUX_PATH"]="$LAMW4LINUX_TEMPLATES_BASE_PATH/startup-check-errors-lamw4linux.sh"
	["$LAMW4LINUX_ETC/lamw4linux-terminalrc"]="$LAMW4LINUX_TEMPLATES_BASE_PATH/lamw4linux-terminalrc"
	["$LAMW_MANAGER_COMPLETION"]="$LAMW_MANAGER_MODULES_PATH/headers/.lamw_comple.sh"
	["$LAMW4LINUX_HOME/usr/bin/update-lamw-manager"]="$LAMW4LINUX_TEMPLATES_BASE_PATH/update-lamw-manager.sh"
)

OLD_ANDROID_SDK=0
LAMW_INSTALL_STATUS=0
LAMW_IMPLICIT_ACTION_MODE=0
FLAG_FORCE_ANDROID_AARCH64=1

INDEX_FOUND_USE_PROXY=-1
CURRENT_OLD_LAMW_INSTALL_INDEX=-1
MAGIC_TRAP_INDEX=-1

USE_PROXY=0
TIME_WAIT=2
NEED_XFCE_MITIGATION=0
LAMW_MINIMAL_INSTALL=0
MIN_LAMW_ARCHS=3
USE_FIXLP=0
FORCE_LAZARUS_CLEAN_BUILD=0