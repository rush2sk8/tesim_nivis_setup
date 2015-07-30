#!/bin/sh

. common.sh

CMD1="uptime"
#TAKE CARE: CMD2 is used by modules_dead; change there when changing CMD2
CMD2="ps | grep -e modbus_gw -e WHart_GW.o -e MonitorHost -e whaccesspoint -e WHart_NM.o -e scheduler -e scgi_svc -e tail | grep -v grep"
CMD3="free | grep Mem"
CMD4="du -hd0 /tmp /access_node/" #du does not count space locked by removed files with fd's still open
CMD5="du -h /tmp/Monitor_Host.db3*"
CMD6="echo pidfiles=\`ls -l /tmp/*.pid | wc -l\`"
CMD7="echo ntp_drift=\`cat /etc/ntp/drift\`"
CMD8="echo -n 'FreeMem-FreeTmp:' ; expr `free | grep Mem | tr -s ' ' | cut -f 5 -d' '` - `df  | grep /tmp | tr -s ' ' | cut -f 4 -d' '`"
#df(used) - du accounts for files erased but still open, probably by tail
CMD9='X=$((`df /tmp | grep tmpfs | tr -s " " | cut -d " " -f3` - `du -d0 /tmp | cut -f0`)); [ $X -gt  256 ] && echo WARN Locked tmpfs $X kB'
CMD10='for I in ${NIVIS_TMP}scgi_svc.log ${NIVIS_TMP}modbus_gw.log ${NIVIS_TMP}MonitorHost-wh.log ${NIVIS_TMP}whaccesspoint.log ${NIVIS_TMP}WHart_GW.o.log ${NIVIS_TMP}nm.o.log; do grep -sH ProcessLoad $I | tail -n 1 | sed -n "s/\/tmp\/\(.*\).log.*ProcessLoad.\{24\}\(.\{4\}\).*/\2 \1/p" ; done'
CMD11="netstat -tp 2> /dev/null | grep -e telnet -e dropbear | cut -d':' -f 2 | uniq -c"
CMDS="$CMD1,$CMD2,$CMD3,$CMD4,$CMD5,$CMD6,$CMD7,$CMD8,$CMD9,$CMD10,$CMD11"

SYS_LOG_TMP=${NIVIS_TMP}/syslog.txt
SYS_LOG_SAVE=${NIVIS_ACTIVITY_FILES}/syslog.txt

SYS_LOG_TMP_FAST=${NIVIS_TMP}/syslog_aggressive.txt
SYS_LOG_SAVE_FAST=${NIVIS_ACTIVITY_FILES}/syslog_aggressive.txt

#limit is in bytes
TMP_LOG_SIZE_LIMIT=1		#1 -- to force every execution to flash
SAVE_LOG_SIZE_LIMIT=256000

LOG_LAST=0
LOG_INTERVAL=600
SLEEP_INTERVAL=10

LOG_LAST_FAST=0
LOG_INTERVAL_FAST=10

CLEAR_DEAD_LAST=0
CLEAR_DEAD_INTERVAL=2700

DEAD_FLAG=0


get_file_size()
{
	ls -Ll $1 | tr -s ' ' | cut -f 5 -d ' '
}

# not counting out tail & scgi_svc. Scgi has variable number of instances (1 at start)
modules_dead()
{
	if [ `eval $CMD2 | grep -v -e tail -e scgi_svc | wc -l` -ge 6 ]; then
		return 1
	fi
	return 0
}

save_log_to_flash()
{
	cat $SYS_LOG_TMP >> $SYS_LOG_SAVE
	echo "" > $SYS_LOG_TMP
}

manage_log_size()
{
	local tmp_size=`get_file_size $SYS_LOG_TMP`
	
	if [ $tmp_size -ge $TMP_LOG_SIZE_LIMIT ]; then
		save_log_to_flash
	fi
			
	local save_size=`get_file_size $SYS_LOG_SAVE`
	
	if [ $save_size -ge $SAVE_LOG_SIZE_LIMIT ]; then
		mv $SYS_LOG_SAVE ${SYS_LOG_SAVE}.1
		touch $SYS_LOG_SAVE
	fi
}


while [ true ]; do

	if [ -f /access_node/sys_monitor_aggressive.flag ]; then
		SLEEP_INTERVAL=5
	fi
	

	if [ $((`date +%s`- $LOG_LAST)) -ge $LOG_INTERVAL ] ; then
		LOG_LAST=`date +%s`
		touch $SYS_LOG_TMP
		(IFS=','
		echo ====
		date
		for i in $CMDS; do
			eval $i
		done) >> $SYS_LOG_TMP
		manage_log_size
	fi
	
	if [ -f /access_node/sys_monitor_aggressive.flag -a $((`date +%s`- $LOG_LAST_FAST)) -ge $LOG_INTERVAL_FAST ] ; then
		LOG_LAST_FAST=`date +%s`
		#touch $SYS_LOG_TMP_FAST
		(IFS=','
		echo ====
		date
		for i in $CMDS; do
			eval $i
		done) > $SYS_LOG_TMP_FAST
		
		ps >> $SYS_LOG_TMP_FAST

		cat $SYS_LOG_TMP_FAST >> $SYS_LOG_SAVE_FAST

		save_size=`get_file_size $SYS_LOG_SAVE_FAST`
	
		if [ $save_size -ge $SAVE_LOG_SIZE_LIMIT ]; then
			mv $SYS_LOG_SAVE_FAST ${SYS_LOG_SAVE_FAST}.1
			touch $SYS_LOG_SAVE_FAST
		fi	
	fi

	
	if [ `SysGetUpTime` -ge 600 ]; then

		if [ $((`date +%s`- $CLEAR_DEAD_LAST)) -ge $CLEAR_DEAD_INTERVAL ] ; then
			CLEAR_DEAD_LAST=`date +%s`
			DEAD_FLAG=0
		fi
		modules_dead
		if [ $? -eq 0 -a $DEAD_FLAG -eq 0 ]; then 
			DEAD_FLAG=1
			save_log_to_flash  
			take_system_snapshot.sh ${NIVIS_ACTIVITY_FILES}/snapshot_crash.txt ;  
		fi
	fi
	sleep $SLEEP_INTERVAL
done