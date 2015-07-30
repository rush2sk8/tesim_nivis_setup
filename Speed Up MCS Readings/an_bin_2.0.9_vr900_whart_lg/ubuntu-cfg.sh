#!/bin/sh

# TAKE CARE: Next executable line is used by other scripts 
#    (build_minipc_cfg.sh, get_installed_version.sh) to get version

UBUNTU_CFG_VERSION=1.0.4

LOG=/tmp/`basename $0`.log
CLI_SH_NAMES="ubuntu-cfg.sh cfg.sh cli.sh tgc_cfg.sh"
SM_CFG="/usr/local/NISA/System_Manager/bin/config.ini"
MH_CFG="/usr/local/NISA/Monitor_Host/etc/Monitor_Host.conf"

# $1 - call name
# return  0 - if is a valid call name
# 			1 - not valid
cli_sh_name()
{
	local sh_name

	[ -z $1 ] && return 1

	for sh_name in $CLI_SH_NAMES
	do
		[ "$sh_name" = "$1" ] && return 0
	done

	return 1
}

FILES_ALLOWED="/tmp/SystemManager.log /tmp/SystemManagerState.log /tmp/er_updater.log  /tmp/ubuntu-cfg.sh.log
"

log()
{
	echo -n "`date \"+%Y/%m/%d %T\"` " >> $LOG
	echo "$*" >> $LOG
}

# print text on the console
# and
# send timestamped text to the log file
log_echo()
{
	echo "$*"
	log "$*"
}

ADMIN_CMD_LIST_HELP="device ipconfig file ini exit bye"
ADMIN_CMD_LIST="help debug file "${ADMIN_CMD_LIST_HELP}

CLI_INI=$NIVIS_PROFILE"cli.ini"

cmd_help()
{
	local lcmd=$1
	if [ -z $lcmd ]; then
		echo "Commands: $ADMIN_CMD_LIST_HELP "
		echo "For help about a command: > help cmd"
		return
	fi	
	
	case $lcmd in
		device )
			#echo "$lcmd id [id_val]"
			#echo "   id_val=[0-9A-H]{6}"
			#echo "   needs device restart to activate"
			#echo "$lcmd type"
			#echo "   type=root/leaf/alone"
			#echo "   needs device restart to activate"
			#echo "$lcmd wan_link"
			#echo "   wan_link=eth/wifi/gprs"
			#echo "$lcmd srev" //no version check for minipc w/ system manager & host application
			#echo "$lcmd restart" //no soft reset support for minipc w/ system manager & host application
			echo "$lcmd reboot"
			echo "$lcmd version"
			echo ""		
		;;
		
		ipconfig )
			echo "$lcmd address [ip_val]"
			echo "   ip_val=Dot-and-number IP address"
			echo "$lcmd mask [mask_val]"
			echo "   mask_val=Dot-and-number IP mask"
			echo "$lcmd gateway [gw_val]"
			echo "   gw_val=Dot-and-number gateway address"
			echo "   TAKE CARE: this is the ETH gateway, NOT ISA gateway"		
			echo "$lcmd dhcp"
			echo "$lcmd restart"
			echo ""				
		;;
			
		ftpconfig )
			echo "$lcmd address [ip_val]"
			echo "   ip_val=Dot-and-number IP address"
			echo "$lcmd username [username_string]"
			echo "$lcmd password [password_string]"
			echo "$lcmd ftpdir_base [base_data_folder_string]"			
			echo ""					
		;;
		
		file )
			echo "$lcmd list"			
			echo "   list available files"
			echo "$lcmd watch filename no_lines follow"
			echo "   if parameters no_lines and follow are missing" 
			echo "		all file \"filename\" content will be print"
			echo "	 ex: CFG> file watch /tmp/backbone.log"			
			echo "   if parameter no_lines is present and follow is missing"			
			echo " 			the last no_lines lines from file \"filename\" will be print"
			echo "	 ex: CFG> file watch /tmp/backbone.log 100"
			echo "   if parameters no_lines and follow are both present"
			echo " 			the last no_lines lines from file \"filename\" will be print"
			echo "			and the file will be followed"
			echo "	 ex: CFG> file watch /tmp/backbone.log 100 follow"
			#echo "$lcmd ftp_upload filename"							
			#echo "   upload file \"filename\" to the ftp site configured with command ftpconfig"
			#echo "		on ftp server the file will have the name filename_YYYY_MM_DD_hh_mm_ss"
			echo ""
		;;	
	
		ini )
			echo "$lcmd SYSTEM_MANAGER SYSTEM_MANAGER [address_value]"
			echo "  Show/change the address of system manager"
			echo "  address_value=<ipv4>,<ipv6>,<port>"
			echo "  needs CFG> device reboot to activate"
			echo "$lcmd BACKBONES BACKBONE_ROUTER [address_value]"
			echo "	Show/change the address of the backbone router"
			echo "	address_value=<ipv4>,<ipv6>,<port>"
			echo "  needs CFG> device reboot to activate"
			echo "$lcmd GATEWAY GATEWAY [address_value]"
			echo "	Show/change the address of the gateway"
			echo "	address format: address_value=<ipv4>,<ipv6>,<port>"
			echo "  needs CFG> device reboot to activate"
			echo "$lcmd GATEWAY TCP_SERVER_PORT [port_value]"
			echo "  Show/change the listening port of the gateway"
			echo "	port_value range: 1-65535"
			echo "  needs CFG> device reboot to activate"
			echo "The values in square brackets are optional."
			echo "  Value provided -> change. Not provided -> show"
			echo ""
		;;	
		exit | bye )
			echo "$lcmd"
			echo "	Terminate the program"
			echo ""
		;;
	    * )			
		echo "Command $lcmd unknown"
	esac
}

cmd_verify()
{
	local cmd
	for cmd in $ADMIN_CMD_LIST
	do
		[ "$cmd" = "$1" ] && return 0
	done
	
	return 1	
}

#
cmd_device()
{
	local ser_id
	local tmp
	local lcmd=device
	local arg=$1
	[ ! -z $1 ] &&	shift 1
	local value="$*"
	local write_val=$1
	
	#echo arg=$arg"|value="$value 
	log "CFG $lcmd $arg"
	case $arg in 
		version )
			echo "SM:  `cat /usr/local/NISA/System_Manager/version`"
			echo "CFG: $UBUNTU_CFG_VERSION"
			echo "MH:  `basename $(readlink /usr/local/NISA/Monitor_Host)`"
			echo "MHA: `basename $(readlink /usr/local/NISA/Monitor_Host_Admin)`"
			echo "MHS: `basename $(readlink /usr/local/NISA/Monitor_Host_Site)`"
		;;
		cfg_start )
			echo"TODO: implement"
		;;
		cfg_end )
			echo"TODO: implement"
		;;
		restart )			
			log "CFG $lcmd $arg"
			start.sh  
		;;	
		reboot )			
			sudo reboot
		;;	
		* )
		echo "ERR cfg.sh: argument $arg unknown"
		echo ""
		cmd_help "$lcmd"
	esac	
}

cmd_ipconfig()
{
	local lcmd=ipconfig
	local arg=$1
	local write_val=$2
	
	case $arg in
		address )
    		if [ -z $write_val ]; then
				local ETH0_IP="`sed -n "/^iface.*eth0/,/^$/p" /etc/network/interfaces`"
				echo $ETH0_IP | grep -q dhcp
				if [ $? -eq 0 ]; then
					echo "eth0 configured by dhcp."
				else
					echo -n "eth0 address:"
					echo -e "$ETH0_IP" | grep address | cut -f2 -d' '
				fi
			else
				echo "$write_val" | grep -q "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$" ||\
					{ echo "ERR cfg.sh: Invalid IP."; return; }
				sudo sed -i "/^iface.*eth0/,/^\$/{/address/d}" /etc/network/interfaces
				sudo sed -i "/^iface.*eth0/,/^\$/s/\(.*\) dhcp\(.*\)/\1\2 static/" /etc/network/interfaces
				sudo sed -i "/^iface.*eth0/,/^\$/{\$s/\(.\+\)/\1\n/}" /etc/network/interfaces
				sudo sed -i "/^iface.*eth0/,/^\$/s/^\$/address ${write_val}\n/" /etc/network/interfaces
				echo "ETH0 configuration:"
				local ETH0_IP="`sed -n "/^iface.*eth0/,/^$/p" /etc/network/interfaces`"
				echo -n " ETH0_IP="
				echo -e "$ETH0_IP" | grep address | cut -f2 -d' '
				echo -n " ETH0_MASK="
				echo -e "$ETH0_IP" | grep netmask | cut -f2 -d' '
				echo -n " ETH0_GW="
				echo -e "$ETH0_IP" | grep gateway | cut -f2 -d' '
				echo " If the above is what you want, do 'ipconfig restart'"
			fi
	    ;;
	    mask)
	        if [ -z $write_val ]; then
				local ETH0_IP="`sed -n "/^iface.*eth0/,/^$/p" /etc/network/interfaces`"
				echo $ETH0_IP | grep -q dhcp
				if [ $? -eq 0 ]; then
					echo "eth0 configured by dhcp."
				else
					echo -n "eth0 netmask:"
					echo -e "$ETH0_IP" | grep netmask | cut -f2 -d' '
				fi
            else
                echo "$write_val" | grep -q "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$" ||\
					{ echo "ERR cfg.sh: Invalid MASK."; return; }
        
				sudo sed -i "/^iface.*eth0/,/^\$/{/netmask/d}" /etc/network/interfaces
				sudo sed -i "/^iface.*eth0/,/^\$/s/\(.*\) dhcp\(.*\)/\1\2 static/" /etc/network/interfaces
				sudo sed -i "/^iface.*eth0/,/^\$/{\$s/\(.\+\)/\1\n/}" /etc/network/interfaces
				sudo sed -i "/^iface.*eth0/,/^\$/s/^\$/netmask ${write_val}\n/" /etc/network/interfaces
				echo "ETH0 configuration:"
				local ETH0_IP="`sed -n "/^iface.*eth0/,/^$/p" /etc/network/interfaces`"
				echo -n " ETH0_IP="
				echo -e "$ETH0_IP" | grep address | cut -f2 -d' '
				echo -n " ETH0_MASK="
				echo -e "$ETH0_IP" | grep netmask | cut -f2 -d' '
				echo -n " ETH0_GW="
				echo -e "$ETH0_IP" | grep gateway | cut -f2 -d' '
				echo " If the above is what you want, do 'ipconfig restart'"
            fi    
	    ;;
		gateway)
			if [ -z $write_val ]; then
				local ETH0_IP="`sed -n "/^iface.*eth0/,/^$/p" /etc/network/interfaces`"
				echo $ETH0_IP | grep -q dhcp
				if [ $? -eq 0 ]; then
					echo "eth0 configured by dhcp."
				else
					echo -n "eth0 gateway:"
					echo -e "$ETH0_IP" | grep gateway | cut -f2 -d' '
				fi
			else
				sudo sed -i "/^iface.*eth0/,/^\$/{/gateway/d}" /etc/network/interfaces
				sudo sed -i "/^iface.*eth0/,/^\$/s/\(.*\) dhcp\(.*\)/\1\2 static/" /etc/network/interfaces
				sudo sed -i "/^iface.*eth0/,/^\$/{\$s/\(.\+\)/\1\n/}" /etc/network/interfaces
				sudo sed -i "/^iface.*eth0/,/^\$/s/^\$/gateway ${write_val}\n/" /etc/network/interfaces
				echo "ETH0 configuration:"
				local ETH0_IP="`sed -n "/^iface.*eth0/,/^$/p" /etc/network/interfaces`"
				echo -n " ETH0_IP="
				echo -e "$ETH0_IP" | grep address | cut -f2 -d' '
				echo -n " ETH0_MASK="
				echo -e "$ETH0_IP" | grep netmask | cut -f2 -d' '
				echo -n " ETH0_GW="
				echo -e "$ETH0_IP" | grep gateway | cut -f2 -d' '
				echo " If the above is what you want, do 'ipconfig restart'"
			fi
		;;				
		restart)
			sudo /etc/init.d/networking restart
		;;
		dhcp)
			sed -i "/^iface.*eth0/,/^\$/{/address\|netmask\|gateway/d}" /etc/network/interfaces
			sed -i "/^iface.*eth0/s/static/dhcp/" /etc/network/interfaces
			echo "ETH0 configured for dhcp. If this is what you want, do 'ipconfig restart'"
		;;
	    *)
		    echo "ERR cfg.sh: argument $arg unknown"
			echo ""
			cmd_help "$lcmd"
	esac
}

# connect
# create base folder
# create data folder
# upload the file wifi_test.txt
# TODO: use FTP command output to check the file uploaded ok
subcmd_ftp_test_write_up()
{
	ftp_cmds_connect
	echo "mkdir $FTP_SITE_DIR_BASE"
	echo "mkdir ${FTP_SITE_DATA_DIR_UP}"
	echo "cd ${FTP_SITE_DATA_DIR_UP}"
	echo "put ftp_cmd_tmp.txt"
}

# connect
# create base folder
# create data folder
# upload the file wifi_test.txt
# TODO: use FTP command output to check the file uploaded ok
subcmd_ftp_test_write_dl()
{
	ftp_cmds_connect
	echo "mkdir $FTP_SITE_DIR_BASE"
	echo "mkdir ${FTP_SITE_DATA_DIR_DL}"
	echo "cd ${FTP_SITE_DATA_DIR_DL}"
	echo "put ftp_cmd_tmp.txt"
}


# connect
# cd to data folder
# rename ftp_cmd_tmp.txt -> ftp_cmd_tmp.rename
# test the existence of renamed file
# TODO: use FTP command output to check the file was renamed
subcmd_ftp_test_rename()
{
	ftp_cmds_connect
	echo "cd ${FTP_SITE_DATA_DIR_DL}"
	echo "rename ftp_cmd_tmp.txt ftp_cmd_tmp.rename"
	echo "ls ftp_cmd_tmp.rename"	# the ls is not needed... used for logging only
}

# connect
# cd to data folder
# get file ftp_cmd_tmp.rename
subcmd_ftp_test_get()
{
	ftp_cmds_connect
	echo "cd ${FTP_SITE_DATA_DIR_DL}"
	echo "get ftp_cmd_tmp.rename"
}


#1 wifi/eth/gprs (wan link type)
#2 text to print on the console
#3 function to produce ftp script
#4 string to parse in the output
subcmd_ftp_test_step()
{
	local cmd_tmp="ftp_cmd_tmp.txt"
	local out_tmp="ftp_out_tmp.txt"
	local local_attempts=0
	local FTP_CMD			# initialised below
	local local_pwr_cycle	# initialised below

	[ $# -lt 4 ] && return 9

	[ "$1" = "wifi" ] && FTP_CMD="wifi_ftp -b B115200 -t 3 " || FTP_CMD="ftp -i -n "
	[ "$1" = "wifi" -o "$1" = "gprs" ] && local_pwr_cycle=1 || local_pwr_cycle=0

	$3 > $cmd_tmp                                        # create the ftp script
	log "Command file [$cmd_tmp]:"; cat $cmd_tmp >> $LOG # log the ftp script
	
	while true; do
		[ $local_attempts -gt 0 ] && log_echo "  +power cycle then try again"
		log_echo "$2"                                     # print the text 
		if [ $local_pwr_cycle -eq 1 -a $local_attempts  -eq 1 ]; then
			# power cycle only at second attempt
			[ "$1" = "wifi" ] && wifi_pwr restart	# power cycle the wifi, if necessary
			[ "$1" = "gprs" ] && gprs_pwr restart # power cycle the gprs, if necessary
		fi
		$FTP_CMD < $cmd_tmp 1>$out_tmp 2>&1 #execute the ftp script
		log "Result file [$out_tmp]:"; cat $out_tmp >> $LOG  # log the output
		grep -q -e "$4" $out_tmp && return 0 || local_attempts=$(( local_attempts + 1 ))
		[ $(( local_attempts - local_pwr_cycle )) -ge 1 ] && return 1
	done
}

# $1: wifi/eth/gprs - the WAN link sustaining the test
subcmd_ftp_test()
{
	[ -z "$1" ] && return 1	# Incorect call
	
	rm -f ftp_cmd_tmp.rename
	log "subcmd_ftp_test $1"
	
	[ "$1" = "wifi" ] && wifi_pwr start	# power on the wifi, if necessary
	[ "$1" = "gprs" ] && gprs_pwr start # power on the gprs, if necessary

	subcmd_ftp_test_step "$1" "  +connect" \
		ftp_cmds_connect       "^230 " || return 1 # connect   #"230 User .* logged in"
	subcmd_ftp_test_step "$1" "  +create the upload folders, create test file on FTP" \
		subcmd_ftp_test_write_up  "^226 " || return 2 # mkdir/put #"226 Transfer complete"
	subcmd_ftp_test_step "$1" "  +create the downdload folders, create test file on FTP" \
		subcmd_ftp_test_write_dl  "^226 " || return 2 # mkdir/put #"226 Transfer complete"	
	subcmd_ftp_test_step "$1" "  +verify the test file was created and can be renamed" \
		subcmd_ftp_test_rename "^250 " || return 3 # rename    #"250 Rename successful"
	subcmd_ftp_test_step "$1" "  +download the test file ftp_cmd_tmp.rename from FTP" \
		subcmd_ftp_test_get    "^226 " || return 4 # get       #"226 Transfer complete"

	rm -f ftp_cmd_tmp.txt ftp_out_tmp.txt ftp_cmd_tmp.rename   # clean up the mess 

	log "subcmd_ftp_test done"
	return 0
}

cmd_ftpconfig()
{
	local lcmd=ftpconfig
	local arg=$1
	local write_val=$2
	[ ! -z $1 ] &&	shift 1
	local value="$*"
	local tmp
	local hour

	case $arg in 
		address )
		if [ ! -z "$value" ]; then
			echo "$value" | grep -q "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$" ||\
				{ echo "ERR cfg.sh: invalid IP: $value"; return; }
			# change var on ini file - on main flow below
		fi
		;;
		username | password | ftpdir_base  )	
			# change var on ini file - on main flow below
			# nothing else to do here
		;;
		*)
		log_echo "ERR cfg.sh: argument $arg unknown"
		echo ""
		cmd_help "$lcmd"
	esac	
	
	case $arg in 
		# Do not use ini_editor option -a (raw), we will not accept
		# special chars like #, " in the username or in the address
		address | username | ftpdir_base  )	
			if [ -z $write_val ]; then
				ini_editor -f $CLI_INI -s $lcmd -v $arg -r
			else
				log "CFG $lcmd $arg [$value]"
				ini_editor -f $CLI_INI -s $lcmd -v $arg -w "$value"				
			fi	
		;;
		# password must accept any chars, including special chars like # or " 
		password )	
			if [ -z $write_val ]; then
				ini_editor -f $CLI_INI -s $lcmd -v $arg -a -r
			else
				log "CFG $lcmd $arg [$value]"
				ini_editor -f $CLI_INI -s $lcmd -v $arg -a -w "$value"				
			fi	
		;;
		* )	# Nothing to do
		;;		
	esac
}


# $1 file to be check that is allowed
# 		if $1 is "" list all files
file_allowed()
{
	local lfile
	local file_to_check=$1
	
	if [ -z "$file_to_check" ]; then
		for lfile in $FILES_ALLOWED 
		do
			echo $lfile
		done		
	else
		for lfile in $FILES_ALLOWED 
		do
			[ "$lfile" = "$file_to_check" ] && return 0
		done		
	fi	
	
	return 1	
}


cmd_file()
{
	local tmp
	local lcmd=file
	local arg=$1
	local lfile=$2
	local no_lines=$3
	local follow=$4
	local no_params=$#
	local file_dated=""
			
	case $arg in 
		list )
			file_allowed	
		;;
		watch )
			file_allowed $lfile
			if [ $? -ne 0 ]; then
				echo "ERR cfg.sh: $lcmd $arg invalid arg $lfile "		 
				echo ""
				cmd_help "$lcmd"	
				return 1
			fi
						
			if [ -z $no_lines ]; then 
				cat $lfile
			elif [ "$follow" = "follow" ]; then
				tail -f -n $no_lines $lfile
			else
				tail -n $no_lines $lfile						
			fi			
		;;		
		ftp_upload )		
			file_allowed $lfile
			if [ $? -ne 0 ]; then
				echo "ERR cfg.sh: $lcmd $arg invalid arg $lfile "		 
				echo ""
				cmd_help "$lcmd"	
				return 1
			fi
			
			file_dated="`basename $lfile`_`date +%Y_%m_%d_%H_%M_%S`"			
			cp $lfile ${NIVIS_TMP}${file_dated}		
			
			ftp_upload.sh ${NIVIS_TMP}${file_dated}	
		;;
		*)
			echo "ERR cfg.sh: argument $arg unknown"		 
			echo ""
			cmd_help "$lcmd"	
	esac		
}

cmd_ini()
{
	local lcmd=ini
	local section=$1
	local var=$2
	local value=""	
	local tmp
		
	if [ ! -z $3 ]; then
	 	shift 2
		value="$*"
		ini_editor -f $SM_CFG -s $section -v $var -w "$value"
		if [ $section = "GATEWAY" ]; then
			if [ $var = "GATEWAY" ]; then
				local ip=`echo $value | cut -f1 -d','`
				echo $ip
				sed -i "/GatewayHost/s/.*/GatewayHost=$ip/" $MH_CFG
			fi
			if [ $var = "TCP_SERVER_PORT" ]; then
				sed -i "/GatewayPort/s/.*/GatewayPort=$value/" $MH_CFG
			fi
		fi
	else
		ini_editor -f $SM_CFG -s $section -v $var -r		
	fi	
	
}

cmd_debug()
{
	$cfg_args
}

read_timeout()
{
    local TIMEOUT=N
    local ret=1
    trap TIMEOUT=Y USR1
    trap 'kill "$pid" 2> /dev/null' EXIT
    (sleep "$1" && kill -USR1 "$$") & pid=$!
    until [ $ret -eq 0 ] || [ "$TIMEOUT" = "Y" ]; do
		read cfg_cmd cfg_args
		ret=$?
    done
    kill "$pid" 2> /dev/null
    trap - EXIT USR1
    return "$ret"
}  

# Make sure other user can overwrite the log file
# This is done to make possible running the script with logging enabled
#   under any user
umask 0000
touch $LOG
call_name=`basename $0`

cli_sh_name  $call_name
direct_call=$?

if [ $direct_call -eq 0 ] && [ ! -z $1 ]; then
	call_name=$1
	shift 1
	direct_call=1
fi

if [ $direct_call -ne 0 ]; then
	cmd_verify $call_name
	if [ $? -eq 0 ]; then
		cmd_$call_name $*
	fi
	exit
fi


#make sure the backspace works ok
stty erase ^H
trap : INT

log "CFG interface start"
while [ true ]; do
    echo -n "CFG> "
	
    read_timeout 600
    if [ $? -ne 0 ]; then
        log_echo "CFG Session Timed out! "
        return 0
    fi
        
	[ -z $cfg_cmd ] && continue
	
	cmd_verify $cfg_cmd
	[ $? -eq 1 ] && echo "ERR cfg.sh: command $cfg_cmd is not supported" && continue
	
	[ $cfg_cmd = "exit" ] && break
	[ $cfg_cmd = "bye"  ] && break
    cmd_$cfg_cmd $cfg_args
done
log "CFG interface end"



