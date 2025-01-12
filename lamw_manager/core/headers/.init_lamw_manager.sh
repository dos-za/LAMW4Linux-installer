#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.6.9
#Date: 01/12/2025
#Description: The ".init_lamw_manager.sh" is part of the core of LAMW Manager. This script check conditions to init LAMW Manager
#-------------------------------------------------------------------------------------------------#

# Verifica condicoes de inicializacao
if  [ $UID = 0 ]; then 
	echo "${VERMELHO}Fatal error: you cannot run this tool as root "
	exit 1
	
fi
source "$LAMW_MANAGER_MODULES_PATH/headers/admin-parser.sh"
source "$LAMW_MANAGER_MODULES_PATH/settings-editor/root-lamw-settings-editor.sh"
setRootLAMW