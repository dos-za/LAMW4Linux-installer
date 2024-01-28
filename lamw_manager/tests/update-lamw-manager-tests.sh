#!/bin/bash
TEST_MODULES_PATH=$(dirname $(realpath $0))
source $TEST_MODULES_PATH/tests-header
source "$LAMW_MANAGER_MODULES_PATH/settings-editor/templates/update-lamw-manager.sh" &>/dev/null
export ROOT_LAMW=~/LAMW






test-checkLAMWManageUpdates(){
	initROOT_LAMW
	
	wget(){ echo '' ; }
	echo "Generate LAMW_INSTALL_VERSION=0.6.2"> $LAMW_INSTALL_LOG
	checkLAMWManageUpdates 1
	
	assertFalse '[v2 empty]' $?

	wget(){ echo '{ "tag_name": "0.6.2" } ' ; }
	checkLAMWManageUpdates 1
	assertFalse '[v1 == v2]' $?
	
	echo "Generate LAMW_INSTALL_VERSION=0.6.0"> $LAMW_INSTALL_LOG
	checkLAMWManageUpdates 1
	assertTrue '[v1 < v2]' $?


	wget(){ echo '{ "tag_name": "0.6.1" } ' ; }
	echo "Generate LAMW_INSTALL_VERSION=0.6.2"> $LAMW_INSTALL_LOG
	checkLAMWManageUpdates 1
	assertFalse '[v1 > v2]' $?


}

test-compareVersion(){

	compareVersion "0.6.1" ""
	assertFalse '[v2 empty]' $?

	compareVersion "0.6.1"  "0.6.1"
	assertFalse '[v1 == v2]' $?

	compareVersion "0.6.0" "0.6.1"
	assertTrue '[v1 < v2]' $?
	
	compareVersion "0.6.2" "0.6.1"
	assertFalse '[v1 > v2]' $?


}

test-trimVersion(){
	local v1=()
	local v2=()
	local v1_str=""
	local v2_str=""
	local rv_limit=4

	trimVersion "0.6.1" "0.6.2"
	assertEquals '[Trim 3 digits]' "06100" "$v1_str"
	
	trimVersion "0.4.0.6" "0.6.2"
	assertEquals '[Trim 4 digits (4 digit less then 10)]' "04060" "$v1_str"

	trimVersion "0.4.0.10" "0.6.2"
	assertEquals '[Trim 4 digits ]' "04010" "$v1_str"

	trimVersion "0.3.3-r1" "0.6.2"
	assertEquals '[Trim 4 digits -r ]' "03310" "$v1_str"

	trimVersion "0.2.1-R1" "0.6.2"
	assertEquals '[Trim 4 digits -R ]' "02110" "$v1_str"

	trimVersion "0.6.1" "0.4.1.7"
	assertEquals '[Trim v2 4 digits less then 10]' "04170" "$v2_str"

	trimVersion "0.2.1" "0.5.3-r1"
	assertEquals '[Trim v2 4 digits -r ]' "05310" "$v2_str"

}


test-get-lamw-manager-updates(){

	checkLAMWManageUpdates(){ return 1; }
	get-lamw-manager-updates
	assertFalse '[No action is required]' $?

	checkLAMWManageUpdates(){ return 0; }
	wget(){ echo ; }
	get-lamw-manager-updates
	assertFalse '[lamw_manager_setup = '']' $?

	wget(){ 
		echo '{"assets": [ { "tag_name" : "0.6.2","browser_download_url": "https://localhost/lamw_manager_setup.sh" } ]}' 
		echo 'exit 0' > /tmp/lamw_manager_setup.sh
	}
	

	echo n | get-lamw-manager-updates
	assertFalse '[no run setup ]' $?

	echo y | get-lamw-manager-updates
	assertTrue '[run setup ]' $?

	wget(){ return 	1; }
	echo y | get-lamw-manager-updates
	assertFalse '[wget failed ]' $?
	


}



. $(which shunit2)