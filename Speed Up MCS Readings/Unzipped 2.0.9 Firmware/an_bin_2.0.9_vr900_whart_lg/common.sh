# common scripts functions
write_log() 
{
	log2flash "$*"
}

# $1 - file name
GetFileSize()
{
	ls -Ll $1 | tr -s ' ' | cut -f 5 -d ' '
}

line_count()
{
	wc -l < $1 
}


# $1 - timeout
waitpid_timeout()
{
	local pid=$!		
	local timeout=${1:-"10"}	
	
	[ -z $pid ] && return 0
	
	while [ $timeout -gt 0 ]; do
	
		[ ! -d /proc/$pid ] && break

		sleep 1	
		let timeout=timeout-1	
	done	
	
	if [ $timeout -le 0 ]; then
		echo "Timeout expired -> killing pid $pid... " 
		kill -9 $pid 
		return 1	
	fi
	return 0
}

# 
SysGetUpTime()
{
   cat /proc/uptime | cut -f1 -d ' ' | cut -f1 -d '.'
}

#echo the 
GetWatchedModulesLogs()
{
  cat ${NIVIS_FIRMWARE}/fw.cfg | grep Watch | cut -d= -f2 | cut -d\" -f2 | sed s/pid$/log/
}

Renice()
{
	process=$1
	prio=$2
	pid="`pidof ${process}`"
	if [ "${pid}" = "" ]; then
		echo "Renice:No such process ${process}"
		return
	fi
	renice ${prio} -p ${pid}
}

#find line number where section with name $2 start. Search in file $1
section_begin()
{
	(grep -in " *\[ *$2 *\]" $1 || echo "1:") | cut -f 1 -d ':'
}

#find section end (at new section/EOF). Section begin at $2 line number. Search in $1
section_end()
{
	sed -n "$2,\$p" $1 \
		| (grep -n "\[" || echo $((`line_count $1`-$2+3))) \
		| head -n 1 \
		| cut -f 1 -d ':'
}

#replace value of variabile  in section
#$1 file $2: section $3: variable $4: old value pattern $5: new value
replace_in_section()
{
	var_start=`section_begin $1 "$2"`
	var_end=$((`section_end $1 $(($var_start+1))`+$var_start)) #`
	sed -n "1,$(($var_start-1))p" $1
	sed -n "$var_start,$(($var_end-1))p" $1 | sed "s/\( *$3 *= *\)$4/\1$5/I"
	sed -n "$var_end,\$p" $1
}

#used by stop.sh scripts: 
#	- signal modules to stop (using signal SIGTERM: 15)
#	- wait up to 30 seconds for modules to stop
#	- kill all remaining modules (SIGKILL: 9)
#TAKE CARE: MUST put double quotes around modules, to be considered a single argument
stop_waitable()
{	 
	local endUpTime TMP_REZ_FILE=$NIVIS_TMP/123.tmp
	local modules_alive="$1"  stop_timeout

	echo "Announce to stop modules: "$modules_alive	
	killall $modules_alive
    
	endUpTime=`SysGetUpTime`
	
	stop_timeout=`ini_editor -s GLOBAL -v MODULES_STOP_TIMEOUT -r `
	[ -z $stop_timeout ] && stop_timeout=30 
	
	let endUpTime+=stop_timeout+1
		
	sleep 1
	while [ true ]
	do                     #wait until all modules stopped or timeout seconds elapsed	
		ps > $TMP_REZ_FILE
		modules_temp=""  
		for j in $modules_alive
		do
			grep "$j\( \|$\)" $TMP_REZ_FILE | grep -q -v "grep"
			[ $? -eq 0 ] && modules_temp="$modules_temp $j" || echo "Module $j ended OK"  
		done

		modules_alive=$modules_temp
		if [ ! "$modules_alive" ]; then  
			echo "All modules ended OK"       
			break
		fi
		
		sleep 2
		
		 [ `SysGetUpTime` -gt $endUpTime ] && break				
	done
	
	
	if [ -n "$modules_alive" ]; then # 30 seconds elapsed... kill whatever module is still alive
		echo "Force kill for modules: $modules_alive" 
		log2flash "Force kill for modules: $modules_alive" 
		killall -9 $modules_alive > /dev/null 2>&1
	fi

}

#the HW version, which is 6 for both ER550 and ER570 (aka Trinity)
#The HW version must always be a number (integer?), so we can make lt/gt/le/ge comparisons
GetHwVersion()
{
	hw_version_1=5
	if [ -f /access_node/etc/hw_version ]; then
		hw_version_1=`cat /access_node/etc/hw_version`
	fi
	echo $hw_version_1
}

#the specific HW type. The HW type is a string
GetHwType()
{
	[ -f /access_node/etc/flavor_er_550 ] && echo "er550" && return
	[ -f /access_node/etc/flavor_er_570 ] && echo "er570" && return
	[ -f /access_node/etc/flavor_er_570_A03 ] && echo "er570_a03" && return
	[ -f /access_node/etc/flavor_er_700 ] && echo "er700" && return
	echo "anv5"
}

# $1 - HW version file from firmware with abs path
#		if missing read firmware/build_info
VerifyConsistentHwVer()
{
	hw_ver_fw_file=${NIVIS_FIRMWARE}/build_info
	[ ! -z "$1" ] && hw_ver_fw_file=$1

	[ ! -f ${hw_ver_fw_file} ] && return 0
	. ${hw_ver_fw_file}
	
	fs_hw_ver=`cat /access_node/etc/hw_version`	
	
	if [ ! -z "$fs_hw_ver" -a ! -z "$hw_no" ]; then
		if [ "$fs_hw_ver" -ne "$hw_no" ]; then
			echo "Board hw $fs_hw_ver != fw HW $hw_no "	
			echo "Board hw $fs_hw_ver != fw HW $hw_no "	>> $NIVIS_ACTIVITY_FILES/work_time.debug
			return 1
		fi
	fi
	return 0
}


# $1 sh script name
# the lock file will be /tmp/SH_NAME.lock
# returns 	0 - on success
#			1 - on error - logs also in activity_log
singleton_sh_test_and_mark_begin()
{
	local singleton_name=$1
	local singleton_lock=${NIVIS_TMP}${singleton_name}.lock
	
	# See if start.sh is already running
	# if it is, then log2flash and exit since
	# concurrent start.sh is not allowed
	#rv="`pidof start.sh`"
	#if [  "${rv}" != "" ]; then
	#	log2flash "start.sh already running as pid[${rv}] -> $0 pid[$$] shall exit"
	#	exit
	#fi
	#lock="/tmp/start.sh.lock"
	if [ -f ${singleton_lock} ]; then
		date=`cat ${singleton_lock}`
		if [ `date +%s` -lt $date ]; then
			pid_var=`pidof ${singleton_name}`
			if [ "$pid_var" != "" -a "$pid_var" != "$$" ]; then
				echo "${singleton_name} might be running -> exit"
				log2flash "${singleton_name} might be running -> exit"
				return 1
			fi
		fi
	fi
	expr `date +%s` + 60 > ${singleton_lock}
	return 0
}


# $1 sh script name
# the lock file will be /tmp/SH_NAME.lock
singleton_sh_mark_end()
{
	local singleton_name=$1
	local singleton_lock=${NIVIS_TMP}${singleton_name}.lock
	rm -rf ${singleton_lock}
}

start_update_dynamic_modules()
{
	while true; do
	case "$1" in
		"inc" )
			shift
			MODULES="$_BEFORE_START_,$DEF_MODULES,"
			for module in $*; do
				eval TMP="\$MDL_$module"
				shift
				if [ -z "$TMP" ] ; then
					echo "No such module $module"
					continue
				fi
				MODULES="$MODULES,$TMP"
			done
			MODULES="$MODULES,$_AFTER_START_"
			break;
		;;
		"exc" )
			shift
			MODULES="$_BEFORE_START_,$DEF_MODULES,$REL_MODULES,$_AFTER_START_"
			for module in $*; do
				eval TMP="\$MDL_$module"
				shift
				if [ -z "$TMP" ] ; then
					echo "No such module $module"
					continue
				fi
				T="`echo $MODULES | sed -e "s/$TMP,*//g"`"
				MODULES=$T
			done
			MODULES="$MODULES,$_AFTER_START_"
			break;
		;;
	esac
	done
}

# $1 modules
start_prepare_fw_cfg()
{
	local loc_REL_MODULES="$1"
	old_ifs=$IFS
	IFS=','
	echo "[WTD]" > fw.cfg
	for j in $loc_REL_MODULES; do
		local j1=`echo $j | cut -f1 -d' '`
		local j2=`basename $j1 .sh`
		if [ -f "$j1" ]; then
			echo "Found $j1, adding to fw.cfg"
			echo "Watch = \"$NIVIS_TMP/$j2.pid\"" >> fw.cfg
		fi
	done
	IFS=$old_ifs
}

# $1 modules
start_run_modules()
{
	local loc_MODULES="$1"
	old_ifs=$IFS
	IFS=','
	for j in $loc_MODULES; do
		echo "Starting $j"
		eval $j
	done
	IFS=$old_ifs
}

#check_invalid_date - Try to recover if the boot scripts failed to produce a valid date from the RTC chip,
# by trying to get date from rtc twice, with 3 sec delay.
# If RTC is really dead, this function will at least reset the date to 00:00 Jan 1 2008 so that the ISA system will kind of work.
# However, the ntpadjust.sh script will know the time is still bad, because of its own threshold, at year 2009.
check_invalid_date()
{
	TR_TIME_MASTER=`ReadVar TR_TIME_MASTER`
	if [ -n "$TR_TIME_MASTER" ] && [ $TR_TIME_MASTER = "Y" -o $TR_TIME_MASTER = "YES" -o $TR_TIME_MASTER = "1" -o $TR_TIME_MASTER = "TRUE" \
		-o $TR_TIME_MASTER = "y" -o $TR_TIME_MASTER = "yes" -o $TR_TIME_MASTER = "true" ]; then
		log2flash "WARNING: using the TR as master clock"
	fi
	#date was read once again from RTC at startup, so this read should read correctly
	/access_node/bin/i2c-rtc -d 0xD0 --sync -r	#much better than date -s
    
	YEAR=`date +%Y`
    [ $YEAR -ge 2008 ] && return 0

	sleep 3
	/access_node/bin/i2c-rtc -d 0xD0 --sync -r	#much better than date -s
	YEAR=`date +%Y`
	[ $YEAR -ge 2008 ] && return 0
	
	date 010100002008

	detect_cc_comm.sh
	MODEM_PWR_LINE_INDEX=`ReadVar MODEM_PWR_LINE_INDEX`
	[ -z $MODEM_PWR_LINE_INDEX ] && MODEM_PWR_LINE_INDEX=-1
	[ $MODEM_PWR_LINE_INDEX -gt 0 ] && set_cc_modem.sh on
	ntpadjust.sh
	[ $MODEM_PWR_LINE_INDEX -gt 0 ] && set_cc_modem.sh off
}


check_persistent_files()
{
	V1=" "

	#use -s instead of -f to protect from empty files.
	if [ -f ${NIVIS_PROFILE}new.rule_file.cfg -o ! -s ${NIVIS_ACTIVITY_FILES}rule_file ]; then
		log2flash "Create NEW rule_file from rule_file.cfg (file uploaded or fresh start)"
		rule_file_mgr ${NIVIS_PROFILE}rule_file.cfg /access_node/one_time_cmd.cfg
		rm -f ${NIVIS_PROFILE}new.rule_file.cfg 
		rm -f ${NIVIS_ACTIVITY_FILES}rule_file
	else
		if [ ${NIVIS_PROFILE}rule_file.cfg -nt ${NIVIS_ACTIVITY_FILES}rule_file -o ! -e ${NIVIS_ACTIVITY_FILES}rule_file ]; then
			echo "WARN rule_file is out-dated. rebuild binary"
			V1="WARN out-dated rule_file, rebuilt binary"
			rule_file_mgr ${NIVIS_PROFILE}rule_file.cfg /access_node/one_time_cmd.cfg
			cp -f ${NIVIS_TMP}rule_file ${NIVIS_ACTIVITY_FILES}rule_file
		else
			echo "Copy OLD ${NIVIS_ACTIVITY_FILES}rule_file to ${NIVIS_TMP}rule_file"
			cp ${NIVIS_ACTIVITY_FILES}rule_file ${NIVIS_TMP}rule_file
		fi
	fi
}


check_cgi_upload_files()
{
	local cgi_files="`ls /tmp/cgi_file_upload_* 2>/dev/null`"
	local cgi_date
	local crt_time=`date +%s`
	local delta_t
	local cgi_f

	#echo "cgi_files=$cgi_files"
	[ -z "$cgi_files" ] && return 0
	echo 2	
	for cgi_f in $cgi_files
	do
		#echo "cgi_file=$cgi_f" 
		cgi_date=`date -r $cgi_f +%s`
		delta_t=$(( $crt_time - $cgi_date ))
		echo "cgi_file=$cgi_f date=$cgi_date delta_t=$delta_t"
		if [ $delta_t -gt 1800 ]; then
			rm -f $cgi_f
			echo "cgi_file=$cgi_f too old -> remove"
			write_log "cgi_file=$cgi_f too old -> removed"
		fi				 
	done
}

# Read a variable from config.ini
# Parameters:
# $1 - variable name (mandatory)
# $2 - section name (optional)
ReadVar ()
{
	if [ $# -lt 1 ]; then
		echo You did not call ReadVar right!
	elif [ $# -eq 1 ]; then
		sed -nr "s/^[^[#]*?$1[^#0-9A-Z/\"=_-]*=[^#0-9A-Z/\"-]*([^#]*)[^#]*#?.*\$/\1/Ip" ${NIVIS_PROFILE}config.ini
	else
		ini_editor -s $2 -v $1 -r
	fi
}
# Usage of ReadVar:
#
#echo $1 in $2:
#echo `ReadVar $1 $2`

# Parameters:
# $1 - section name (mandatory)
# $2 - variable name (mandatory)
# $3 - variable value (optional)
SetVar ()
{
	if [ $# -lt 2 ]; then
		echo You did not call SetVar right!
	else
		ini_editor -s $1 -v $2 -w $3
	fi
}

#return memory available in MB (was in kB)
MemoryStatus()
{
	mem_Free=`grep "MemFree:" /proc/meminfo | cut -f 2 -d':' | cut -f1 -d'k' | tr -d ' '`
	mem_Buffers=`grep "Buffers:" /proc/meminfo | cut -f 2 -d':' | cut -f1 -d'k' | tr -d ' '`
	mem_Cached=`grep "^Cached:" /proc/meminfo | cut -f 2 -d':' | cut -f1 -d'k' | tr -d ' '`
	tmpfs_Used=`df | sed -n "s/tmpfs *[0-9]* *\([0-9]*\).*/\1/p" | head -n 1`
	if [ -z $tmpfs_Used ]; then tmpfs_Used=0; fi
	memAvailable=$((($mem_Free + $mem_Buffers + $mem_Cached - $tmpfs_Used)/1024))
	echo "Available Memory: $memAvailable MB"
	echo "  (Cached: $mem_Cached kB; Buffers: $mem_Buffers kB; Temp: $tmpfs_Used kB)"
	return $memAvailable
}
