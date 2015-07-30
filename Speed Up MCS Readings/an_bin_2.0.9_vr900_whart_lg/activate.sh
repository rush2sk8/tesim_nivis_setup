#!/bin/sh
#folder names: two FIRMWARE_<id> and two PROFILE_<id>
#old_profile old_firmware new_profile new_firmware
#search in id.profile and id.firmware for id's

#TAKE CARE: the relationship between fw version and fw folder must be:
#	an_bin_<version>_lg
#	version is extracted this way; folder is constructed from version this way

ARCHIVE_PROFILE="LGProfile.tgz"
ARCHIVE_FIRMWARE="LGFirmware.tgz"
PREFIX_PROFILE="an_profile"
REPOSITORY="ID.Repository"
FIRMWARE="firmware"
PROFILE="profile"
ARCHIVE_SETTINGS="${NIVIS_TMP}LGSettings.tgz"
NOW=0

. ${NIVIS_FIRMWARE}common.sh

#write an entry to activity log
write_log()
{
	echo "$*"
	log2flash "$*"
	return 0
}

#extract id from archive
#parameter: $1: profile/firmware
id_from_archive()
{
	[ ! "$1" ] && return 1
	[ $1 = $PROFILE ]  && tar xzOf $ARCHIVE_PROFILE ID.$1 && return 0	#extract version from ID.profile
	[ $1 = $FIRMWARE ] && get_folder $FIRMWARE "" "" | sed "s/an_bin_\(.*\)_lg/\1/" && return 0	#extract version from folder name
	return 1
}

#read ID from REPOSITORY
#search for profile_new / profile_old firmware_new firmware_old
#parameters: $1 profile/firmware $2 old/new
id_from_repository()
{
	sed -n "s/${1}_${2} *= *//pI" $REPOSITORY
}

#create repository
create_repository()
{
	echo "profile_old = "  	>  $REPOSITORY
	echo "profile_new = " 	>> $REPOSITORY
	echo "firmware_old = "	>> $REPOSITORY
	echo "firmware_new = "	>> $REPOSITORY
}


#create/update link to folder $2
#parameters: $1 firmware / profile; $2 destination folder
update_links()
{
	[ ! $1 ] && write_log "ERR update_links: bad call (1)." && return 1
	[ ! $2 ] && write_log "ERR update_links: bad call (2)." && return 1
	echo "Update links to $1 -> $2"
	rm -f $1
	ln -sf $2 $1
}

#update repository for profile.
#parameters: $1 profile / firmware $2: old id $3 new id
update_repository()
{
	echo "Update in $REPOSITORY ${1}_old=[$2] ${1}_new=[$3]"
	sed "s/\(${1}_old *= *\).*/\1$2/I
		 s/\(${1}_new *= *\).*/\1$3/I" $REPOSITORY > /tmp/$REPOSITORY &&\
	mv /tmp/$REPOSITORY $REPOSITORY && return 0
	return 2
}


#return the name of the folder to hold new distribution/profile
#		for profile, folder name is an_profile and profile id
#		for firmware, folder name is extracted from archive
#Parameters: $1 profile/firmware  $2 id $3 old / new / empty(or anything else) - in that case return folder from archive
#	$2 is not used for firmware
#	$3 is not used for profile

get_folder()
{
	[ ! "$1" ] && return 1
	[ $1 = $PROFILE ]  && echo "${PREFIX_PROFILE}_$2" && return 0
	[ $1 = $FIRMWARE ] && [ ! $3 ] && tar tzf $ARCHIVE_FIRMWARE | sed "s/\/.*//" | uniq && return 0
	[ $1 = $FIRMWARE ] && id=`id_from_repository "$1" "$3"` && echo "an_bin_${id}_lg" && return 0
	return 2
}

#parameters: $1 firmware / profile; $2 destination folder
unpack()
{
	[ ! "$1" ] && write_log "ERR unpack: bad call (1)" && return 1
	[ ! "$2" ] && write_log "ERR unpack: bad call (2)" && return 2

	echo "Unpack $1 into $2 and delete archive"

#HERE: we can remove one_time_cmd.cfg because there is only the current rule in it
# the website cannot send more than one rule
# in current implementation, it is impossible to activate in the future
# two separate things (fw/profile)
#TODO: in theory, we should not delete this file in FW case and find another
# way to prevent re-execution of rules

	[ $1 = $PROFILE ]							\
		&& mkdir -p $2							\
		&& tar -C $2 -xzf $ARCHIVE_PROFILE	\
		&& rm $ARCHIVE_PROFILE 					\
		&& rm -f one_time_cmd.cfg				\
		&& chmod -x $2/*						\
		&& touch $2/*				\
		&& touch $2				\
		&& return 0

	[ $1 = $FIRMWARE ]									\
		&& tar -xzf $ARCHIVE_FIRMWARE					\
		&& rm $ARCHIVE_FIRMWARE							\
		&& rm -f one_time_cmd.cfg						\
		&& cd $2 && rm -f config.ini rule_file.cfg events.cfg && cd ..\
		&& return 0
	return 3
}

#unpack ARCHIVE profile/firmware to old folder, IF THIS IS NOT CURRENT ONE
#unpack the archive, (check is done to avoid overwriting old with current)
#then move links from current to new.
#Update repository (new becomes old, downloaded becomes new)
#Remove old
# parameters $1 - profile/irmware $2 command line id
set_active()
{
	[ ! "$1" ] && write_log "ERR SetActive: bad call." && return 1
	[ ! "$2" ] && write_log "WARN SetActive $1 no ID provided"
	echo "SetActive $1 $2"

	id=`id_from_archive $1`
	[ $? -ne 0 ] && write_log "ERR SetActive $1 NO ID in archive, can't create" && return 2

	new_id=`id_from_repository $1 "new" `
	old_id=`id_from_repository $1 "old" `
	folder_create=`get_folder $1 "$id" "" `
	folder_delete=`get_folder $1 "$old_id" "old"`

	#we will not allow the same profile/fw in both folders. we must be able to fallback. (command might have arrived twice...)
	if [ "$id" = "$new_id" ]; then
		write_log "WARN SetActive $1 $new_id already activated. Delete image";
		[ "$1" = "$FIRMWARE" ] && rm $ARCHIVE_FIRMWARE || rm $ARCHIVE_PROFILE;
		return 3
	fi
	[ "$id" = "$old_id" ] && write_log "WARN SetActive $1 $old_id already OLD. Make NEW" && folder_delete=
	#check if id from command is the same with id from archive!
	[ "$id" != "$2" ] && write_log "WARN SetActive $1 different ID's (file $id, param $2)"

	echo "SetActive $1 "
	echo "  into folder   [$folder_create]"
	echo "  set fallback  [$new_id]"
	echo "  delete folder [$folder_delete]"

	unpack $1 $folder_create

	if [ -f $folder_create/build_info ]; then
		. $folder_create/build_info
		
		if [ "`GetHwVersion`" -ne "$hw_no" ]; then
			echo "ERR SetActive: board hw `GetHwVersion` != fw HW $hw_no "
			log2flash "ERR SetActive: board hw `GetHwVersion` != fw HW $hw_no "
			rm -R $folder_create
			return 3
		fi
	fi
	update_links $1 $folder_create

	#update repository for profile. New becomes old, \downloaded becomes new
	update_repository "$1" "$new_id" "$id"

    # switch standalone, only on the machines where the script exists
    $(which switch_standalone.sh || echo echo 'switch_standalone.sh not used on this machine. no action.')


	#force rules reload (in theory, neede only by profile upload...)
	[ "$1" = "$PROFILE" ]  && touch ${NIVIS_PROFILE}new.rule_file.cfg

	#remove old profile, if threre is one
	if [ $folder_delete ]; then
		echo "Removing OLD $1 $old_id from $folder_delete"
		rm -R $folder_delete
	else
		echo "There is no folder for OLD $1, nothing to remove"
	fi
	write_log "SetActive $1 $id done. Restart in 30sec."

	cd ${NIVIS_FIRMWARE}
	[ "$1" = "$PROFILE" ] && [ -x raise_an_ev ] && raise_an_ev -e 15 -v $id	#an event: profile activated
	if [ "$1" = "$FIRMWARE" ]; then 
		[ -x raise_an_ev ] && raise_an_ev -e 27 -v "$id"	#an event: firmware activated
		touch ${NIVIS_TMP}skip_db_struct_validate
	fi
	
	if [ $NOW -eq 0 ]; then
		# close stdout/stderr to avoid http hang
		#{ exec 1>&- ; exec 2>&- ; sleep 30 && start.sh; } &		#30 seconds should be enough for events to propagate
		
		{ sleep 30; start.sh; } &
	else
		#restart now
		start.sh		
	fi	
	return 0
}

#move links from old to new.
#Update repository (new = old , old =empty )
#parameters: $1 profile/ firmware
fallback()
{
	[ ! "$1" ] && write_log "ERR Fallback: bad call." && return 1

	new_id=`id_from_repository $1 "new" `
	old_id=`id_from_repository $1 "old" `
	folder_fallback=`get_folder $1 $old_id "old" `
	folder_delete=`get_folder $1 $new_id "new" `

	echo "Fallback $1 to $old_id from $new_id, link [$folder_fallback], remove [$folder_delete]"
	[ ! "$old_id" ] && write_log "ERR Fallback $1: no old to fallback to" && return 0

	update_links $1 $folder_fallback

	#update repository. Old becomes new, new becomes empty
	update_repository "$1" "" "$old_id"

	write_log "Fallback $1 to $old_id completed"

	if [ "$1" = "$PROFILE" ]; then
		touch ${NIVIS_PROFILE}new.rule_file.cfg
		touch ${NIVIS_PROFILE}
		touch ${NIVIS_PROFILE}/*
	fi

	cd ${NIVIS_FIRMWARE}
	[ "$1" = "$PROFILE" ] && [ -x raise_an_ev ] && raise_an_ev -e 15 -v $old_id	#an event: profile activated
	if [ "$1" = "$FIRMWARE" ]; then 
		[ -x raise_an_ev ] && raise_an_ev -e 27 -v "$old_id"	#an event: firmware activated
		touch ${NIVIS_TMP}skip_db_struct_validate
	fi

	if [ $NOW -eq 0 ]; then
		# close stdout/stderr to avoid http hang
		{ exec 1>&- ; exec 2>&- ; sleep 30 && start.sh; } &		#30 seconds should be enough for events to propagate
	else
		#restart now
		start.sh		
	fi	

	cd /access_node/
	#remove old profile or fw, if threre is one
	if [ $folder_delete ]; then
		echo "Removing $1 $new_id from $folder_delete"
		rm -R $folder_delete
	else
		echo "There is no $1 to delete"
	fi

	return 0
}

profile_create()
{

	if [ ! -f $ARCHIVE_PROFILE ]; then
		write_log "ERR SetActive profile: can't find archive $ARCHIVE_PROFILE"
		${NIVIS_FIRMWARE}raise_an_ev -e 10 -v 0	#invalid profile on AiNode
		return 1
	fi
	set_active $PROFILE $1
	[ $? -ne 0 ] && ${NIVIS_FIRMWARE}raise_an_ev -e 10 -v $1	#invalid profile on AiNode
}

firmware_create()
{
	if [ ! -f $ARCHIVE_FIRMWARE ]; then
		write_log "ERR SetActive firmware: can't find  archive $ARCHIVE_FIRMWARE"
		return 1
	fi
	local DISKUSE_PERCENT="`df | grep access_node | cut -f 1 -d'%'`"
	DISKUSE_PERCENT=`echo $DISKUSE_PERCENT | cut -f 5 -d' '`
	if [ $DISKUSE_PERCENT -gt 75 ]; then
		write_log "ERR SetActive firmware: not enough space on flash (current usage: $DISKUSE_PERCENT %)"
		rm $ARCHIVE_FIRMWARE
		return 1
	fi
	set_active $FIRMWARE $1
}

reload_settings()
{
	write_log "Activating new settings"
	tar -C $NIVIS_PROFILE -xzf $ARCHIVE_SETTINGS && rm $ARCHIVE_SETTINGS
	touch $NIVIS_PROFILE/*
	touch $NIVIS_PROFILE
	if [ $NOW -eq 0 ]; then
		# close stdout/stderr to avoid http hang
		{ exec 1>&- ; exec 2>&- ; sleep 30 && start.sh; } &		#30 seconds should be enough for events to propagate
	else
		#restart now
		start.sh		
	fi	
}

reload_local_msp_fw()
{
	write_log "Activating local msp firmware"
	NC_LOCAL_PID=`ps | grep "node_connection local" | grep -v grep | cut -dr -f1`

	echo "NC_LOCAL_PID=$NC_LOCAL_PID"
	if [ ! -z $NC_LOCAL_PID ]; then
		kill $NC_LOCAL_PID
		[ $? -ne 0 ] && sleep 10 && kill -9 $NC_LOCAL_PID
	fi

	tar -xzf LocalMspFW.tgz LocalMspFW.txt
	chmod a+rw LocalMspFW.txt

	dl_done=0
	while [ $dl_done -eq 0 ]
	do
		echo "local_msp_loader LocalMspFW.txt"
		local_msp_loader LocalMspFW.txt
		if [ $? -eq 0 ]; then
			echo "Local Msp loading done OK"
			dl_done=1
		else
			echo "Local Msp loading error"
			raise_an_ev -e 40		# dl failed
			sleep 10
		fi
	done

	if [ $dl_done -eq 1 ]; then
		#success
		raise_an_ev -e 39
		rm -f LocalMspFW.txt
		node_connection local&
		information.txt_get.sh; ra_cmd.sh 37 3 /tmp/information.txt
	fi

}

#$1 fw_id
fw_wrap()
{
	local dist_name="an_bin_$1_lg.tgz"

	if [ ! -f $dist_name ]; then
		echo "Distribution $dist_name not found"
		return
	fi

	mv $dist_name LGFirmware.tgz
	firmware_create	$1
}

#$1 fw_file
#IMPORTANT
#IMPORTANT	Starting with this FW version, we allow two file formats for FW distributions:
#IMPORTANT		an_bin_<fw_version>_lg.tgz   -- old format
#IMPORTANT		fw_bin_<fw_version>.tgz      -- new format, eliminate "an" and "lg" from file name
#IMPORTANT		the fw_file option will accept however any well-formed .tgz filename,
#IMPORTANT			but will issue a warning if the formats above are not respected
#IMPORTANT	By well-formed .tgz is understood a tgz including FW version as defined in ADD
#IMPORTANT
fw_file_wrap()
{
	if [ -z "$1" ]; then
		write_log "ERR SetActive firmware: no fw archive provided"
		return 1
	fi

	if [ ! -f $1 ]; then
		echo "Distribution FW file [$1] not found"
		return
	fi

	local fw_file=$1
	local fw_folder=`tar tzf $fw_file | sed "s/\/.*//" | uniq`

	local fw_ver=`echo $fw_folder | sed -n "s/.*an_bin_\(.*\)_lg$/\1/p"`
	[ -z "$fw_ver" ] && fw_ver=`echo $fw_folder | sed -n "s/.*fw_bin_\(.*\)$/\1/p"`

	#write_log "SetActive firmware: fw_file=$fw_file fw_ver=$fw_ver fw_folder=$fw_folder"
	if [ -z "$fw_ver" ]; then 
		write_log "Can not extract firmware version " 
		exit 1
	fi

	tar -xvzf $fw_file ${fw_folder}/build_info -C /tmp/

	VerifyConsistentHwVer /tmp/${fw_folder}/build_info || exit 1
	rm -R /tmp/${fw_folder}/
		
	local id=$fw_ver
	local new_id=`id_from_repository $FIRMWARE "new" `
	local old_id=`id_from_repository $FIRMWARE "old" `
	local folder_create=$fw_folder
	local folder_delete=`get_folder $FIRMWARE "$old_id" "old"`

	#we will not allow the same profile/fw in both folders. we must be able to fallback. (command might have arrived twice...)
	if [ "$id" = "$new_id" ]; then
		write_log "WARN SetActive firmware $new_id already activated. Delete image";
		rm $fw_file
		return 1
	fi
	
	if [ ! -z "$old_id" ]; then
		update_repository $FIRMWARE "" "$new_id" 
		echo "Removing OLD $FIRMWARE $old_id from $folder_delete"
		rm -R $folder_delete 		
	fi
	
	echo "SetActive $FIRMWARE "
	echo "  into folder   [$folder_create]"
	echo "  set fallback  [$new_id]"

	tar -xzf $fw_file -C /access_node/
	if [ $? -ne 0 ]; then
		write_log "tar error -> rm archive and folder"
		rm -fR $folder_create
		rm -f $fw_file
		return 1
	fi		
	rm -f $fw_file
	update_links $FIRMWARE $folder_create

	#update repository for profile. New becomes old, \downloaded becomes new
	update_repository "$FIRMWARE" "$new_id" "$id"

    # switch standalone, only on the machines where the script exists
    $(which switch_standalone.sh || echo echo 'switch_standalone.sh not used on this machine. no action.')

	cd ${NIVIS_FIRMWARE}
	touch ${NIVIS_TMP}skip_db_struct_validate
	if [ $NOW -eq 0 ]; then
		write_log "SetActive firmware $id done. Restart in 30sec."
		{ sleep 30; start.sh; } &
	else
		write_log "SetActive firmware $id done. Restart now."
		#restart now
		start.sh		
	fi	
	return 0	
	
}



#print usage to screen
print_usage_and_exit()
{
	echo ""
	echo "Usage: $0 OPTION"
	echo "Where OPTION is:"
	echo "    --profile  <profile_id>"
	echo "    --profile_back"
	echo "    --firmware <fw_id>"
	echo "    --fw_back "
	echo "    --new_settings"
	echo "    --local_msp_fw"
	echo "    --fw <fw_id>        #use dist an_bin_<fw_id>_lg.tgz "
	echo "    --fw_file <fw_file> "
	echo "       #Recommended <fw_file>: an_bin_<fw_id>_lg.tgz or fw_bin_<fw_id>.tgz"
	echo "       However, fw_file option accepts any well-formed .tgz, issuing a warning"
	echo "    --now #as first or third parameter: activate immediately"
	echo ""
	exit
}


cd /access_node/


if [ ! -f $REPOSITORY ]; then
	create_repository
fi

renice 0 `pidof activate.sh`

write_log "activate.sh $*"

[ $3 ] && [ $3 = "--now" ] && NOW=1
[ $1 ] && [ $1 = "--now" ] && NOW=1 && shift 1

case $1 in
	--profile		| -profile)			profile_create  $2	;;
	--firmware		| -firmware)		firmware_create	$2	;;
	--fw			| -fw)				fw_wrap	$2	;;
	--fw_file		| -fw_file)			fw_file_wrap $2 ;;
	--profile_back	| -profile_back)	fallback $PROFILE	;;
	--fw_back		| -fw_back)			fallback $FIRMWARE	;;
	--new_settings	| -new_settings)	reload_settings		;;
	--local_msp_fw	| -local_msp_fw)	reload_local_msp_fw		;;
	*)									print_usage_and_exit ;;
esac

