#!/bin/sh

. ${NIVIS_FIRMWARE}common.sh

# $1 script name
ShowHelp()
{
	echo "Usage: $1 [reset|preserve]"
	echo "		reset - keep only AN_ID, APP_ID"
	echo "		preserve - add new variables from profile_templ/config.ini"
	echo "				and force set profile_templ/*.ini_force  "
	echo "		one_time - used by one_time.sh on fw upgrade"
	echo "				add new variables from profile_templ/config.ini"
	echo "				and force set profile_templ/*.ini_force  "
	echo "				add files that exist in firmware/profile_templ and do not exist in profile "
	echo "				depending on release overwrite some files (e.g Monitor_Host.conf)"
}

# $1 - file
# $2 - group name
# $3 - var name
RestoreVar()
{
        local cfg_file=$1
        local group_name=$2
        local var_name=$3
        local var_value=""

        if [ -z $var_name ]; then
                 echo "RestoreVar not enough parameters"
                 return 1
        fi
        var_value=`ini_editor -f ${NIVIS_PROFILE}old/$cfg_file -s $group_name -v $var_name -r`

        echo "Restore file=$cfg_file group=$group_name var=$var_name val=$var_value"

        ini_editor -f ${NIVIS_PROFILE}$cfg_file -s $group_name -v $var_name -w "$var_value"
}


action_reset()
{
	cp -f ${NIVIS_FIRMWARE}/profile_templ/*  ${NIVIS_PROFILE}

	touch ${NIVIS_PROFILE}new.rule_file.cfg

	#config.ini
	RestoreVar config.ini  GLOBAL  AN_ID
	RestoreVar config.ini  GLOBAL  APP_ID
	RestoreVar config.ini  NODE_CONNECTION_MESH  MESH_OWNER_ID_LIST
	RestoreVar config.ini  NODE_CONNECTION_MESH  MESH_AN_OWNER_ID

	if [ -f ${NIVIS_PROFILE}/old/cli.ini ]; then
		cp ${NIVIS_PROFILE}/old/cli.ini ${NIVIS_PROFILE}
		ini_update -c update -s  ${NIVIS_FIRMWARE}/profile_templ/cli.ini -d ${NIVIS_PROFILE}/cli.ini > /dev/null
	fi
}


copy_if_inexistent()
{
	sourceDir=$1
	file=$2
	destDir=$3
	dir="`dirname ${file}`"

	if [ ! -d "${destDir}/${dir}" ]; then
		mkdir -p "${destDir}/${dir}"
	fi

	if [ ! -f "${destDir}/${file}" ]; then
		cp -f "${sourceDir}/${file}"  ${destDir}
	fi
}

action_preserve()
{
	echo "Add variables that not exist"
	ini_update -c update -d	${NIVIS_PROFILE}/config.ini -s ${NIVIS_FIRMWARE}/profile_templ/config.ini > /dev/null

	echo "Force set variables"
	for force_file in `ls ${NIVIS_FIRMWARE}/profile_templ/*.ini_force`
	do
		echo "force_file=$force_file"
		ini_update -c set -d ${NIVIS_PROFILE}/config.ini -s ${force_file} > /dev/null
	done

	touch ${NIVIS_PROFILE}new.rule_file.cfg
	#[ -f  ${NIVIS_FIRMWARE}/profile_templ/rule_file.cfg ] && cp -f ${NIVIS_FIRMWARE}/profile_templ/rule_file.cfg ${NIVIS_PROFILE}

	cp -f ${NIVIS_FIRMWARE}/profile_templ/log4cpp* ${NIVIS_PROFILE}
	#[ ! -f ${NIVIS_PROFILE}/tunnels_config.ini ] && cp -f ${NIVIS_FIRMWARE}/profile_templ/tunnels_config.ini ${NIVIS_PROFILE}

	files=$(cd ${NIVIS_FIRMWARE}/profile_templ/ ;   find . -type f)
	for file in  ${files} ; do
		copy_if_inexistent ${NIVIS_FIRMWARE}/profile_templ  $file   ${NIVIS_PROFILE}
	done
}


action_one_time()
{
	echo "Add variables that not exist"
	ini_update -c update -d	${NIVIS_PROFILE}/config.ini -s ${NIVIS_FIRMWARE}/profile_templ/config.ini

	echo "Delete variables"
	for del_file in `ls ${NIVIS_FIRMWARE}/profile_templ/*.ini_del`
	do
		echo "del_file=$del_file"
		ini_update -c del -d ${NIVIS_PROFILE}/config.ini -s ${del_file}
	done

	echo "Force set variables"
	for force_file in `ls ${NIVIS_FIRMWARE}/profile_templ/*.ini_force`
	do
		echo "force_file=$force_file"
		ini_update -c set -d ${NIVIS_PROFILE}/config.ini -s ${force_file}
	done

	touch ${NIVIS_PROFILE}new.rule_file.cfg
	[ -f  ${NIVIS_FIRMWARE}/profile_templ/rule_file.cfg ] && cp -f ${NIVIS_FIRMWARE}/profile_templ/rule_file.cfg ${NIVIS_PROFILE}

	cp -f ${NIVIS_FIRMWARE}/profile_templ/log4cpp* ${NIVIS_PROFILE}
	#[ ! -f ${NIVIS_PROFILE}/tunnels_config.ini ] && cp -f ${NIVIS_FIRMWARE}/profile_templ/tunnels_config.ini ${NIVIS_PROFILE}

	[ -f ${NIVIS_FIRMWARE}/profile_templ/Monitor_Host.conf  ] 	&& cp ${NIVIS_FIRMWARE}/profile_templ/Monitor_Host.conf    ${NIVIS_PROFILE}/
	[ -f ${NIVIS_FIRMWARE}/profile_templ/Monitor_Host_Log.ini ] && cp ${NIVIS_FIRMWARE}/profile_templ/Monitor_Host_Log.ini ${NIVIS_PROFILE}/
	#[ -f ${NIVIS_FIRMWARE}/profile_templ/rule_file.cfg ] && cp ${NIVIS_FIRMWARE}/profile_templ/rule_file.cfg ${NIVIS_PROFILE}/

	#[ ! -f ${NIVIS_PROFILE}/Monitor_Host_Publishers.conf ] && cp ${NIVIS_FIRMWARE}/profile_templ/Monitor_Host_Publishers.conf ${NIVIS_PROFILE}/
	#ini_editor -s SYSTEM_MANAGER -v FIRMWARE_FILES_DIRECTORY -w /access_node/activity_files/devices_fw_upgrade/

	files=$(cd ${NIVIS_FIRMWARE}/profile_templ/ ;   find . -type f)
	for file in  ${files} ; do
		copy_if_inexistent ${NIVIS_FIRMWARE}/profile_templ  $file   ${NIVIS_PROFILE}
	done
}


[ ! "$1" = "reset" -a ! "$1" = "preserve" -a ! "$1" = "one_time" ] && ShowHelp "$0" && exit 0
ACTION=$1


mkdir -p  ${NIVIS_PROFILE}/old
cp ${NIVIS_PROFILE}* ${NIVIS_PROFILE}/old

if [ "$ACTION" = "reset" ]; then
	action_reset
fi

if [ "$ACTION" = "preserve" ]; then
	action_preserve
fi

if [ "$ACTION" = "one_time" ]; then
	action_one_time
fi





