#!/bin/sh


#script used to test the board functionality
. ../common.sh


TEST_HW_CFG_DIR=/access_node/activity_files/test_hw/

if [ ! -f /access_node/firmware/test_hw/rc.local_test_hw ]; then 
	echo "file /access_node/firmware/test_hw/rc.local_test_hw is missing -> install failed"
	exit 1
fi

cp /access_node/firmware/test_hw/rc.local_test_hw /etc/
chmod +x /etc/rc.local_test_hw

ln -sf /etc/rc.local_test_hw /etc/rc.local
	
touch  /etc/config/hw_test_enabled

echo "reboot to enable hardware test mode"