#!/bin/sh

. common.sh
#. vr900_util.sh

if [ ! -x ${NIVIS_FIRMWARE}rel_start_util.sh ]; then
	echo "${NIVIS_FIRMWARE}rel_start_util.sh  is missing"
	log2flash "${NIVIS_FIRMWARE}rel_start_util.sh  is missing"
	exit 1
fi

. ${NIVIS_FIRMWARE}rel_start_util.sh

rel_stop_modules_config


DB_MODULES_STILL_UP=0

old_pwd=`pwd`
cd /access_node/firmware/
VerifyConsistentHwVer || exit 1

#record stop time, unless instructed to do otherwise
[ "$1" != "no_log" ] && log2flash "ER Stop $1 NIVIS_FIRMWARE=$NIVIS_FIRMWARE"

if [ "$1" = "exc_web" -o "$1" = "no_web" ]; then
# called from web_upgrade.sh, or request , use small module set: do not stop scgi_svc
# activate.sh will stop all (web/scgi_svc included) after upgrading the FW
	MODULES=$MOD_SML
	DB_MODULES_STILL_UP=1
else 
	if [ "$1" = "exc_wtd" ]; then		
		MODULES=$MOD_EXC_WTD
	fi
fi

#MUST put double quotes around modules, to be considered a single argument
if [ "$1" = "panic" ]; then
	echo "Panic stop: immediately kill all  "
	stop_waitable "watchdog"
	killall -9 $MODULES
else
	echo "Stopping modules"
	stop_waitable "$MODULES"


fi

#do NOT stop http if requested not to (by user or web_upgrade.sh)
if [ "$1" != "exc_web" -a "$1" != "no_web" ]; then
	http_ctl.sh stop
fi

# Monitor Host specific - MUST run after MH stops
if [ -f mh_helper.sh -a "`echo ${MODULES} | grep 'MonitorHost'`" != "" -a $DB_MODULES_STILL_UP -eq 0 ] ; then
	{ . mh_helper.sh; mh_getDBFromTmp; }
fi

cd $old_pwd	#restore working folder
