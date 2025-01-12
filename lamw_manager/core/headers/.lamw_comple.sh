#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.6.9
#Description: This script contains routines for completing LAMW Manager arguments.
#Ref:https://www.vivaolinux.com.br/dica/Shell-script-autocompletion-Como-implementar
#-------------------------------------------------------------------------------------------------#


if [ -e ~/.bashrc ]; then 
	source ~/.bashrc
else
	[ -e  /etc/bash.bashrc ] && source /etc/bash.bashrc
fi

_emulator(){
	local cur prev opts 
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	opts="-list-avds -no-hidpi-scaling -no-mouse-reposition -guest-angle -usb-passthrough -append-userspace-opt -save-path"
	opts+=" -no-nested-warnings -wifi-tap -wifi-tap-script-up -wifi-tap-script-down -wifi-vmnet"
	opts+=" -vmnet -wifi-user-mode-options -network-user-mode-options -adb-path -qemu -qemu -h -verbose -debug"
	opts+=" -help -help-disk-images -help-debug-tags -help-char-devices -help-environment -help-virtual-device"
	opts+=" -help-sdk-images -help-build-images -help-all"

	if [[ ${cur} == -* ]] ; then
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
		return 0
	fi
}

_lamw_manager() {
	local cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	opts="--help  --minimal --port --reinstall --reset --reset-aapis --sdkmanager --avdmanager --server --update-lamw  --use_proxy"

	if [[ ${cur} == -* ]] ; then
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
		return 0
	fi
}

_sdkmanager(){
	local cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	opts="--channel= --help --include_obsolete --install --licenses --list --list_installed --no_https --package --package_combination --proxy= --proxy_host= --proxy_port= --sdk_root= --uninstall --update --verbose --version"

	if [[ ${cur} == -* ]] ; then
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
		return 0
	fi
}
complete -F _lamw_manager lamw_manager
complete -F _lamw_manager ./lamw_manager
complete -F  _sdkmanager sdkmanager
complete -F _emulator emulator