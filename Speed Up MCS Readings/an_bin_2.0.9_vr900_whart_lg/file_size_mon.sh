#!/bin/sh

. ${NIVIS_FIRMWARE}common.sh

LIST_MAX_1M="/tmp/hotplug.log /tmp/wan_watcher.log /tmp/command_mesh_led.sh.log"
LIST_MAX_2M="/var/log/messages"
LIST_MAX_4M=""





# $1 - file name
# $2 - max size allowed
# $3 - log in activity log
CheckFileSize()
{
	if [ -z "$2" ]; then
		return
	fi
		
	local file_name=$1
	local file_max_size=$2
	local file_size=`GetFileSize $file_name`
	
	echo "File ${file_name} max=${file_max_size} crt=${file_size}"
	if [ "$file_size" -gt "$file_max_size" ]; then
		echo "Trunc at "`date` > $file_name
		echo "   -> trunc"
		if [ "$3" = "log" ]; then 
			log2flash "File $file_name exceeded $file_max_size, truncated"
		fi
	fi
}



for file_name in ${LIST_MAX_1M}
do
	[ -f ${file_name} ] && CheckFileSize ${file_name} 1000000
done

for file_name in ${LIST_MAX_2M}
do
	[ -f ${file_name} ] && CheckFileSize ${file_name} 2000000
done

for file_name in ${LIST_MAX_4M}
do
	[ -f ${file_name} ] && CheckFileSize ${file_name} 4000000
done


