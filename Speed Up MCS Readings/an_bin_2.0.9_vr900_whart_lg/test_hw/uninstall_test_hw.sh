#!/bin/sh

set -x
#script used to test the board functionality
. ../common.sh


old_path=`pwd`

cd /etc

link_name=`readlink rc.local` 

if [ ! "$link_name" = rc.local_test_hw  ]; then
	echo "Not in hardware mode"
	exit 1
fi

cp /access_node/firmware/test_hw/rc.local_test_hw /etc/
chmod +x /etc/rc.local_test_hw

ln -sf /etc/rc.d/rc.local /etc/rc.local
	
rm  /etc/config/hw_test_enabled

echo "reboot to enable normal mode"