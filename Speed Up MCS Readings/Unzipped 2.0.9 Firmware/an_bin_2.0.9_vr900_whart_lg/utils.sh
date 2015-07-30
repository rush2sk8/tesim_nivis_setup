#!/bin/sh

#this script is used to make various checks on the system

#used by all reports:
UTILS_FILE="/tmp/utils.txt"
UTILS_FILE_TMP="/tmp/utils.tmp"
UTILS_RC="/tmp/.utils.rc"

#used by login detection
LOGIN_VAR="LastLoginReport"
MSG_FILE="/var/log/messages"
MSG_FILE_TMP="/tmp/messages.tmp"
MSG_FILE_SIZE_LIMIT=102400	#bytes: 100k

#used by flash space detection
FLASH_VAR="LastFlashReport"
FLASH_DFLT_LIMIT=1024	#KB

#used by memory low detection
. common.sh
MEMORY_VAR="LastMemoryReport"
MEMORY_DFLT_LIMIT=4	#MB: this is real limit, I will not customize this

#used by temp detection
TEMP_LOW_VAR="LastTempLowReport"
TEMP_HIGH_VAR="LastTempHighReport"
TEMP_LOW_DFLT_LIMIT=1		#Fahrenheit, should allow negative
TEMP_HIGH_DFLT_LIMIT=100	#Fahrenheit,

#used by humidity detection
HUMIDITY_VAR="LastHumidityReport"
HUMIDITY_DFLT_LIMIT=60

#used by BATTERY detection
BATTERY_VAR="LastBatteryReport"
BATTERY_DFLT_LIMIT=10000

#used by NTP to determine if it's time to set RTC time. 3600: at least 3600 sec between two succesive RTC set
TIME_RTC_VAR="LastRTCSet"
TIME_RTC_DFLT_LIMIT=3600

#used by periodic database backup&cleanup
DBBACKUP_VAR="LastDBBackup"

#used by configuration changed detection
CONFIG_CHANGED_TMP="/tmp/config_changed.tmp"

#create /tmp/.utils.rc file - with env variables- from config.ini, if necessary
#load environ variables
load_env()
{
	[ -f $UTILS_RC -a $UTILS_RC -nt ${NIVIS_PROFILE}config.ini ] && . $UTILS_RC && return 1
	sed -n "s/ *FLASH_LOW_TRESHOLD *= *\([0-9]*\).*/NIVIS_FLASH_LOW=\1/pI
			s/ *TEMPERATURE_HIGH *= *\([0-9\-]*\).*/NIVIS_TEMP_HIGH=\1/pI
			s/ *TEMPERATURE_LOW *= *\([0-9\-]*\).*/NIVIS_TEMP_LOW=\1/pI
			s/ *HUMIDITY_HIGH *= *\([0-9]*\).*/NIVIS_HUMIDITY_HIGH=\1/pI
			s/ *BATTERY_LOW *= *\([0-9]*\).*/NIVIS_BATTERY_LOW=\1/pI" ${NIVIS_PROFILE}config.ini > $UTILS_RC
	. $UTILS_RC
}

# Truncate a file if its size exceeded MAX_FILE_SIZE_LIMIT
# $1 file to truncate
# $2 optional parameter to execute after the file was truncated
truncate_file()
{
	FILE=$1
	msg_file_size=`GetFileSize $FILE`
	if [ $msg_file_size -gt $MSG_FILE_SIZE_LIMIT ] ; then
		cat /dev/null > $FILE
		log2flash "The file $FILE exceeded $MSG_FILE_SIZE_LIMIT, truncated"
		if [ -n "$2" ]; then
			$2
		fi
	fi
}


#check last login, generate events in for each new login detected
check_login()
{
	grep login $MSG_FILE > $MSG_FILE_TMP

	truncate_file $MSG_FILE
	truncate_file "/var/log/http.log" "http_ctl.sh restart"
	truncate_file "/var/log/https.log" "http_ctl.sh restart"

	total=`wc -l < $MSG_FILE_TMP`
	last_time_reported=`sed -n "s/${LOGIN_VAR}=//p" ${UTILS_FILE}`
	[ -z "${last_time_reported}" ] && add_var ${LOGIN_VAR} "" && update_var ${LOGIN_VAR} "never"

	i=$total
	login_time=1

	while [ $i -ge 1 ] ;
	do     #here a balance - use head for i < $total/2 and tail for the rest
		login_line=`head -n $i $MSG_FILE_TMP | tail -n 1`
		login_time=`echo "$login_line" | cut -c -15`
		[ "$login_time" = "$last_time_reported" ] && rm $MSG_FILE_TMP && return 0
		[ $i -eq $total ] && update_var ${LOGIN_VAR} "$login_time"
		login_successfull=`echo "$login_line" | grep "root login" | wc -l`
		if [ $login_successfull = 1 ]; then
			log2flash "Login OK at $login_time"
		else
			log2flash "Login FAILED at $login_time"
		fi
		i=$(($i-1));
	done
	rm $MSG_FILE_TMP
}

#check profile files mtime against profile folder mtime,
#generate event if any profile file is newer than the profile folder
check_config_changed()
{
	rm -f $CONFIG_CHANGED_TMP

	for i in `ls $NIVIS_PROFILE` ; do
		[ $NIVIS_PROFILE$i -nt $NIVIS_PROFILE ] && ls -la $NIVIS_PROFILE$i >> $CONFIG_CHANGED_TMP
	done

	if [ -f $CONFIG_CHANGED_TMP ]; then
		#save profile time too, for reference
		ls -lad $NIVIS_PROFILE >> $CONFIG_CHANGED_TMP
		log2flash "Configuration change detected"
		ra_cmd.sh 35 3 $CONFIG_CHANGED_TMP
		touch $NIVIS_PROFILE	# do not report multiple times
		rm -f $CONFIG_CHANGED_TMP
	fi
}

#check available memory
check_free_memory()
{
	MemoryStatus
	memAvailable=$?
	#no customisable memory limit, it too important...
	check $memAvailable "-lt" ${MEMORY_DFLT_LIMIT} $MEMORY_VAR 2 30 "Memory free" "MB"
}

#check flash size, generate event if drops below some limit
check_flash()
{
	flash=`df | grep "/dev/root" | tr -s ' ' | cut -f 4 -d ' '`
	check $flash "-lt" ${NIVIS_FLASH_LOW:-$FLASH_DFLT_LIMIT} $FLASH_VAR 13 31 "Flash space" "KB"
	while [ $flash -lt $FLASH_DFLT_LIMIT ]; do
		RM_CANDIDATE=`ls -1 ${NIVIS_ACTIVITY_FILES}/work_time.debug.* | tail -n 1`
		[ -z "$RM_CANDIDATE" ] && return
		rm $RM_CANDIDATE
		log2flash "Erased $RM_CANDIDATE"
		flash=`df | grep mtdblock5 | tr -s ' ' | cut -f 3 -d ' '`
	done
}
remove_var()
{
	grep -v $1 ${UTILS_FILE} > ${UTILS_FILE_TMP} &&	mv ${UTILS_FILE_TMP} ${UTILS_FILE}
}

add_var()
{
	echo "$1=$2" >> ${UTILS_FILE}
}

update_var()
{	#sort | uniq to avoid unicity problems
	sed "s/$1=.*/$1=$2/" ${UTILS_FILE} | sort | uniq > ${UTILS_FILE_TMP} &&\
		mv ${UTILS_FILE_TMP} ${UTILS_FILE}
}

check_time()
{
	ntpadjust.sh affect_ntpd
}

check()
{
	value=$1		#value to check							Example 9652
	cmp=$2			#comparison: 							Example "-lt" or "-gt"
	limit=$3		#limit to check against					Example 1024
	varname=$4		#variable name to hold last report time	Example LastLoginReport
	event_bad=$5	#event number to raise for val BAD		Example 19
	event_good=$6	#event number to raise for val OK		Example 34
	devname=$7		#device name							Example Battery
	um=$8			#measurement unit for this device		Example mV

	latest=`sed -n "s/${varname}=//p" ${UTILS_FILE}`
	[ ${cmp} = "-lt" ] && hilo="LOW" || hilo="HIGH"

	if [ ${value} ${cmp} ${limit} ]; then
		#value low
		if [ -z ${latest} ]; then
			log2flash ${devname}" "${value}" "${um}" "${hilo}". Limit ${limit} "$um
			add_var ${varname} `date +%s`
		fi
	else
		#value ok
		if [ "${latest}" ]; then
			diff=$((`date +%s`-${latest}))
			log2flash ${devname}" "${value}" "${um}" OK (was ${hilo} ${diff}s). Limit ${limit} "$um
			remove_var ${varname}
		fi
	fi
}

check_udhcpc()
{
	if [ -f /etc/config/no_dhcp ]; then
		return # DHCP client disabled, do not attempt to restart
	fi

	if [ $((`pidof udhcpc | wc -w`))  -lt 1 ]; then
		log2flash "WARN: udhcpc not running. Trying to start it."
		. /etc/rc.d/rc.net.info
		[ -z "$ETH_NAME" ] && ETH_NAME="eth0"
		/sbin/udhcpc -b -s /access_node/etc/udhcpc/udhcpc.sh -i ${ETH_NAME}:0
	fi
}

check_vpn()
{
	if [ ! -f /etc/config/vpn_client ]; then
		return # VPN client disabled, do not attempt to restart
	fi

	if [ $((`pidof openvpn | wc -w`))  -lt 1 ]; then
		log2flash "WARN: openvpn not running. Trying to start it."
		openvpn --config /access_node/activity_files/openvpn/client.config --script-security 2 &
	fi
}

check_devices_fw() 
{
	[ ! -d /access_node/activity_files/devices_fw_upgrade/ ] && exit 0
	
	echo "" > /tmp/devices_fw_tmp.txt

	ls -tr1 /access_node/activity_files/devices_fw_upgrade/ > /tmp/devices_fw_tmp.txt 2>/dev/null
	
	files_no=`cat /tmp/devices_fw_tmp.txt | wc -l`
	files_no_max=`ini_editor -s GLOBAL -v DEVICES_FW_MAX_NO -r `
	[ -z "$files_no_max" ] && files_no_max=10
	
	files_fw=`cat /tmp/devices_fw_tmp.txt` 
	
	for file_fw in $files_fw 
	do	
		if [ $files_no -le $files_no_max ]; then
			break
		fi				
				
		log2flash "util.sh: device_fw_file $file_fw will be removed <- files crt_no=$files_no max_no=$files_no_max"
		rm -f /access_node/activity_files/devices_fw_upgrade/$file_fw
		sqlite3 /tmp/Monitor_Host.db3 "delete from firmwares where FileName='$file_fw';"
		let files_no=files_no-1	
	done
	
}

# the backup file is timestamped with current time (when the backup is being made)
# delete policy: keep only the most recent $DB_KEEP_ROWS rows (at least; may exceed the number in case of identhical dates)
# with datetime + index, 22160 rows = 1671168 bytes => 75 per row => 28000 rows in 2 MB
# with integer+index, 22160 rows = 897024 bytes => 40 per row => 52000 rows in 2 MB
# backup only fresh data (fresh since last backup), overlapping 60 seconds before last backup, 
# because MH cache data few seconds, and also data is delayed over ISA. 
# Data is timestamped with device TX time but it may actually be saved few saconds later in DB. 
# The overlap is necessary to make sure the data cached at the moment of previous backup is not lost
# previous save -----v
# time --------------|----------
# DB data time ##|~~~|----------
# data on DB-----^
# data on cache: ^~~~^  - this data was on cache, NOT on DB when previous backup was made
#
#	TAKE CARE: the backup file needs special handling at recovery, to avoid duplicates (use uniq)
#
backup_history_readings()
{
	local last_backup_time
	local NOW
	local OLD
	local OLDFMT
	local backup_file
	local ROWS_BACKUP
	local ROWS_DELETE
	local ROWS_REMAIN

	DB_KEEP_ROWS=28000
	DB_RUN_INTERVAL=86400	# number of seconds between two backups: one day

	X=`ini_editor -s MONITOR_HOST -v UseReadingsHistory -r`
	if [ -z "$X" -o $((X)) -eq 0 -o ! -x /access_node/ftp_log_upload.sh ]; then
		echo "Data History/ DB backup not active: get out ASAP"
		return
	fi

	last_backup_time=`sed -n "s/${DBBACKUP_VAR}=//p" ${UTILS_FILE}`
	[ -z "${last_backup_time}" ] && last_backup_time=1
	NOW=`date "+%s"`

	if [ $((NOW-last_backup_time)) -lt $DB_RUN_INTERVAL ]; then
		return
	fi

	backup_file="/tmp/DBBackup_${NOW}.csv"
	
	# backup all data generated since (last backup - one minute) (to cover MH data buffering several seconds before save): may create duplicates!
	# To backup ALL data: take out the WHERE clause
	echo -e ".separator ,\nSELECT * FROM DeviceReadingsHistory WHERE ReadingTime >= datetime('$((last_backup_time-60))','unixepoch') ;" |  sqlite3 /tmp/Monitor_Host.db3 > $backup_file

	if [ $? -ne 0 ] ; then #database is locked; will try next time
		echo "BACKUP FAILED";
		rm -f $backup_file
		return	#will backup next time
	fi
	ROWS_BACKUP=`wc -l < $backup_file`	# number of records backed up

	if [ $((ROWS_BACKUP)) -eq 0  ]; then
		echo "Nothing to backup"
		rm -f $backup_file
	else
		#DANGER: if something is incorrectly configured, it will run out of memory
		/access_node/ftp_log_upload.sh $backup_file
		if [ $? -ne 0 ] ; then
			echo "UPLOAD FAILED"
			#rm -f $backup_file is done by the script...
			return
		fi
	fi
	[ $((last_backup_time)) -eq 1 ] && add_var ${DBBACKUP_VAR} ""
	update_var ${DBBACKUP_VAR} $NOW

# 	No need to test if we should delete old data; is being taken care automatically: the SQL does not delete anything if rowcout is < OFFSET clause
#	database is locked failures are irrelevant at this point
	ROWS_DELETE=`sqlite3 /tmp/Monitor_Host.db3 "DELETE FROM DeviceReadingsHistory WHERE ReadingTime < (SELECT ReadingTime FROM DeviceReadingsHistory ORDER BY ReadingTime DESC LIMIT 1 OFFSET $DB_KEEP_ROWS); SELECT changes();"`
	ROWS_REMAIN=`sqlite3 /tmp/Monitor_Host.db3 "SELECT COUNT(*) FROM DeviceReadingsHistory`

	if [ $((ROWS_BACKUP)) -gt 0 -o ! -z "$ROWS_DELETE" -a $((ROWS_DELETE)) -gt 0 ]; then
		log2flash "DB: backup [$ROWS_BACKUP] -> $backup_file; Del [$ROWS_DELETE] Left [$ROWS_REMAIN] records"
	fi
}

check_all()
{
#check for instances of:
#       utils.sh, activate.sh, LGFirmware.tar.sh LGProfile.tgz.sh
# and don't run if any of those is already running,
# in order to reduce the stress level
	PIDS=`pidof utils.sh activate.sh LG*sh`
	stress_no=$((`echo $PIDS | wc -w`-1)) # count the pids and substract ourselves
	#allow for max 1 process to be up in the same time
	[ $stress_no -ge 1 ] && \
		log2flash "WARN utils.sh: don't run, system under stress ($stress_no)" &&\
		return 0

	touch ${UTILS_FILE}

	load_env				> /dev/null
	check_free_memory		> /dev/null
	check_login				> /dev/null
	check_flash				> /dev/null
	check_config_changed	> /dev/null
	check_time				> /dev/null
	check_udhcpc			> /dev/null
	check_vpn				> /dev/null
	check_devices_fw		> /dev/null
	backup_history_readings	> /dev/null
	return 0
}

check_all
