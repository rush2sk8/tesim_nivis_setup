#!/bin/sh

. common.sh

UP_SCRIPT=/access_node/ftp_log_upload.sh


# $1 file name
ftp_up_log()
{
	[ ! -f $1 ] && return 0

	local log_name=${1}
	local log_year=`date +%Y`

	echo "$log_name" | grep -q "_${log_year}_"
	if [ $? -ne 0 ]; then
			log_name=${1}_`date +%Y_%m_%d_%H_%M_%S`
			mv -f $1 $log_name              
	fi
        
    $UP_SCRIPT $log_name	     
	return $?
}


stop.sh exc_wtd
log2flash "AN_PREP_STOP: stop.sh done"

if [ "`GetHwVersion`" -eq "6" ]; then
	dev2mem 0x80840000 b 0x00
	dev2mem 0x80840004 b 0x80
	AN6_PwrActivate
fi
log2flash "AN_PREP_STOP: turn off devices"

sync

if [ -x $UP_SCRIPT ]; then

	if [ ! -f /etc/flavor_vr900 ]; then
		ftp_up_log ${NIVIS_TMP}nc_local.log
	else
		ftp_up_log ${NIVIS_TMP}watchdog.log
	fi
#logs=`GetWatchedModulesLogs`
	logs=`ls -1 /tmp/*log*`
	log2flash "AN_PREP_STOP: start logs upload"
	count=0
	for i in $logs; do
		ftp_up_log ${i}
		[ $? -eq 0 ] && let count=count+1
	done
	log2flash "AN_PREP_STOP: logs upload done $count files"
fi

stop.sh 

sleep 3600
reboot