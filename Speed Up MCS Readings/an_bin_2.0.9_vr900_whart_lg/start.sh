#!/bin/sh

. common.sh


SH_NAME="start.sh"
PARAMETER=$1

if [ ! -x ${NIVIS_FIRMWARE}rel_start_util.sh ]; then
	echo "${NIVIS_FIRMWARE}rel_start_util.sh  is missing"
	log2flash "${NIVIS_FIRMWARE}rel_start_util.sh  is missing"
	exit 1
fi

. ${NIVIS_FIRMWARE}rel_start_util.sh

rel_start_modules_config

# enable if you want to use inc/exc parameters
#start_update_dynamic_modules $*

singleton_sh_test_and_mark_begin $SH_NAME
[ $? -ne 0 ] && exit 1

VerifyConsistentHwVer
if [ "$?" != "0" ]; then
	singleton_sh_mark_end $SH_NAME
	exit 1
fi

if [ "$PARAMETER" != "no_stop" ]; then	
	stop.sh $PARAMETER
fi

old_pwd=`pwd`
cd /access_node/firmware/



#this is intended to be run only once, at start
#	(Example: after install)
[ -f one_time.sh ] && { ./one_time.sh; log2flash "one_time.sh executed"; mv one_time.sh one_time.sh.EXECUTED; } > one_time.sh.RESULT 2>&1

#this offers the possibility to run some script at every start
#TAKE CARE: use this only for quick fixes, not for permanent solutions
[ -f quick_fix.sh ] && { . quick_fix.sh; }

check_invalid_date
check_persistent_files
[ "$PARAMETER" != "no_log" ] && log2flash "ER START: firmware version `cat version`"


start_prepare_fw_cfg "$REL_MODULES"

{ . vr900_util.sh; vr900_tr_init; }


# Monitor Host specific
if [ -f mh_helper.sh -a "${MDL_MonitorHost}" != "" ] ; then
	{ . mh_helper.sh; mh_putDBToTmp; }	
fi

if [ -x /access_node/ftp_log_upload.sh ]; then
	echo "mv /tmp/watchdog.log  /tmp/watchdog.log.1 -- to reduce the risk of watchdog blocking"
	[ -f /tmp/watchdog.log ] && mv /tmp/watchdog.log  /tmp/watchdog.log.1 
fi

http_ctl.sh start &

start_run_modules "$MODULES"

rel_renice_modules
Renice "watchdog"  -10

echo -10 > "/proc/`pidof watchdog`/oom_adj"

if [ -x /access_node/sm_log_upload.sh ]; then
	echo "Starting /access_node/sm_log_upload.sh ..."
	/access_node/sm_log_upload.sh &
else
	echo "Starting sm_extra_logs_cleaner.sh ..."
	sm_extra_logs_cleaner.sh &
fi

singleton_sh_mark_end $SH_NAME
cd $old_pwd	#restore working folder

