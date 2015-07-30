#!/bin/sh


#script used to test the board functionality
. ../common.sh

CONFIG_INI="config.ini"

TEST_HW_CFG_DIR=/access_node/activity_files/test_hw/

get_info()
{
  
	echo "==========================================================="
	echo -n "REPORT TIME: "
	date +"%F %X"

	echo "Board up for last `SysGetUpTime`s"
	uptime
	

	free
	df	#flash space available
	ps


	
	isa_mod_no=`ps | grep -e isa_gw -e SystemManager -e MonitorHost -e scheduler -e scgi_svc -e modbus_gw | grep -v grep | wc -l`

	if [ "$isa_mod_no" -eq 6 ]; then
		echo "ISA100: all modules running: PASSED"
	else
		echo "ISA100: NOT all modules running: FAILED"	
	fi

	echo "" | microcom -t 300 -s 38400 /dev/ttyS1 | grep -q lease && echo "TR has responsed to ping PASSED" ||echo  "TR has NOT responsed to ping FAILED"	
	
		
	echo "RTC time "`i2c-rtc -s`
	
	YEAR=`i2c-rtc -s | cut -f1 -d'.'`
	
	if [ "$YEAR" -lt 2010 -o "$YEAR" -ge 2015 ]; then
 		echo "RTC test FAILED"
	else
		echo "RTC test PASSED"
	fi
	

	if [ -f $TEST_HW_CFG_DIR/ip_to_ping ]; then

		IP_TO_PING=`cat $TEST_HW_CFG_DIR/ip_to_ping`

		if [ ! -z $IP_TO_PING ]; then

			echo "Ethernet TEST (ping $IP_TO_PING)"
	
			ping -w 1 -W 3 $IP_TO_PING
			[ $? -eq 0 ] && echo "Ethernet TEST PASSED" || echo "Ethernet TEST FAILED"
		else
			echo "Ethernet TEST: will not run because file $TEST_HW_CFG_DIR/ip_to_ping is empty"
		fi
	else
		echo "Ethernet TEST: will not run because file $TEST_HW_CFG_DIR/ip_to_ping is missing"
	fi
	

	if [ -f "/tmp/Monitor_Host.db3" ]; then 
		last_dev_list_rsp=`echo "SELECT CommandID from Commands WHERE TimeResponsed > datetime('now', '-8 seconds') AND CommandCode = 120 AND CommandStatus = 2 limit 1;" | sqlite3 /tmp/Monitor_Host.db3`
	fi
	
	if [ -z "$last_dev_list_rsp" ]; then
		echo "Dev_list test: FAILED"	
	else
		echo "Dev_list test: PASSED"	
	fi

 
}

time_wait=${1:-15}
echo "Hit Crtl-C to stop test"

[ ! -d $TEST_HW_CFG_DIR ] && mkdir -p $TEST_HW_CFG_DIR

[ -f /access_node/firmware/backbone ] && mv /access_node/firmware/backbone /access_node/firmware/save_bbr
(cd ..; start.sh; )


while true; do get_info; sleep $time_wait; done
