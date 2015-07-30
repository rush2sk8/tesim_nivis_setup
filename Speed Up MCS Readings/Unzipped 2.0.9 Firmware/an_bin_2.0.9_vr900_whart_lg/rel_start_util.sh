#!/bin/sh

. common.sh


rel_start_modules_config()
{
	#TAKE CARE: nc local must be started first. cc_comm, history, rf_repeater must be started before scheduler
	_BEFORE_START_="cp take_system_snapshot.sh /tmp,rm -f /tmp/*.pipe,rm -f /tmp/shared_var.shd,watchdog&" #
	_AFTER_START_="sys_monitor.sh&,ln -sf /tmp/nm.log /tmp/WHart_NM.o.log"
	
	_NC_LOCAL_=""
	
	#MDL_* variables are only used in common.sh:start_update_dynamic_modules by start.sh with parameter [inc|exc]
	#MDL_MonitorHost if not empty will trigger DB save to flash
	#TAKE CARE: must have a space between module and &, for correct wdt watch
	MDL_SystemManager="WHart_NM.o /access_node/profile/ > /tmp/SystemManagerProcess.log 2>&1 &"
	MDL_MonitorHost="MonitorHost-wh &"
	MDL_isa_gw="WHart_GW.o &"
	MDL_backbone="whaccesspoint &"
	MDL_modbus_gw="modbus_gw &"
	MDL_profinet=""
	MDL_scgi_svc="/access_node/firmware/www/wwwroot/scgi_svc &"
	MDL_=""
	
	_SCHD_="scheduler &"
	REL_MODULES="$MDL_SystemManager,$MDL_MonitorHost,$MDL_isa_gw,$MDL_backbone,$MDL_modbus_gw,$MDL_profinet,$MDL_scgi_svc"
	DEF_MODULES="$_NC_LOCAL_,$_SCHD_"
	MODULES="$_BEFORE_START_,$DEF_MODULES,$REL_MODULES,$_AFTER_START_"
}

rel_stop_modules_config()
{
	# can this be shared with start.sh ?
	local REL_MOD_COMMON="whaccesspoint WHart_GW.o WHart_NM.o MonitorHost-wh sys_monitor.sh scheduler modbus_gw sm_log_upload.sh sm_extra_logs_cleaner.sh"
	MOD_SML="watchdog ${REL_MOD_COMMON}"
	MODULES="watchdog ${REL_MOD_COMMON} scgi_svc "
	     MOD_EXC_WTD="${REL_MOD_COMMON} scgi_svc "
}


rel_renice_modules()
{
	Renice "watchdog"  -10
	Renice "whaccesspoint"  -9
	Renice "modbus_gw" -7
	Renice "scgi_svc" -5
	#every message goes through gw should have a priority >= NM
	Renice "WHart_GW.o" -3
	Renice "WHart_NM.o" -2
	Renice "MonitorHost-wh" -1
}