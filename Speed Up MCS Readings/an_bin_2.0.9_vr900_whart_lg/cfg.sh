#!/bin/sh

. /access_node/etc/profile
. /access_node/bin/def_an_env.sh
. common.sh

LOG=${NIVIS_TMP}`basename $0`.log

CLI_SH_NAMES="cfg.sh cli.sh tgc_cfg.sh"

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

#FILES_ALLOWED="/tmp/backbone.log /tmp/isa_gw.log /tmp/SystemManager.log /tmp/SystemManagerState.log /access_node/activity_files/activity.log"
FILES_ALLOWED="/tmp/whaccesspoint.log /tmp/WHart_GW.o.log /tmp/nm.log /access_node/activity_files/activity.log"

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

ADMIN_CMD_LIST_HELP="device ipconfig ftpconfig file ini upgrade exit bye"
ADMIN_CMD_LIST="help debug "${ADMIN_CMD_LIST_HELP}

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
			echo "$lcmd srev"
		    echo "$lcmd start"
			echo "$lcmd stop"
			echo "$lcmd restart"
			echo "$lcmd reboot"
			echo ""		
		;;
		ipconfig )
			echo "$lcmd address [ip_val]"
			echo "   ip_val=Dot-and-number IP address"
			echo "   needs $cmd restart to activate"
			echo "$lcmd mask [mask_val]"
			echo "   mask_val=Dot-and-number IP mask"
			echo "   needs $cmd restart to activate"
			echo "$lcmd gateway [gateway_val]"
			echo "   gateway_val=Dot-and-number IP mask"
			echo "   needs $cmd restart to activate"
			echo "$lcmd mac [mac_val]"
			echo "   mac_val=MAC adress, hex"
			echo "   needs relogin to activate"
			echo "$lcmd restart"
			echo "   activate new settings by rebooting device"			
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
			echo "     all file \"filename\" content will be print"
			echo "   ex: CFG> file watch /tmp/backbone.log"			
			echo "   if parameter no_lines is present and follow is missing"			
			echo "      the last no_lines lines from file \"filename\" will be print"
			echo "   ex: CFG> file watch /tmp/backbone.log 100"
			echo "   if parameters no_lines and follow are both present"
			echo "      the last no_lines lines from file \"filename\" will be print"
			echo "   and the file will be followed"
            echo "   ex: CFG> file watch /tmp/backbone.log 100 follow"
			echo "$lcmd ftp_upload filename"							
			echo "   upload file \"filename\" to the ftp site configured with command ftpconfig"
			echo "    on ftp server the file will have the name filename_YYYY_MM_DD_hh_mm_ss"										
		;;	
	
		ini )
		    echo "$lcmd SYSTEM_MANAGER SYSTEM_MANAGER_IPv6"			
			echo "   print the IPv6 address of system manager"
			echo "$lcmd SYSTEM_MANAGER SYSTEM_MANAGER_IPv6 address_value"						
			echo "	set the IPv6 address of system manager"
			echo "  needs CFG> device restart to activate"		
		    echo "$lcmd SYSTEM_MANAGER SYSTEM_MANAGER_IPv4"			
			echo "   print the IPv4 address of system manager"
			echo "      0.0.0.0 means module determine the ER IP at run time"
			echo "$lcmd SYSTEM_MANAGER SYSTEM_MANAGER_IPv4 address_value"						
			echo "	set the IPv4 address of system manager"
			echo "      0.0.0.0 means module determine the ER IP at run time"
			echo "  needs CFG> device restart to activate"		
		    echo "$lcmd SYSTEM_MANAGER SYSTEM_MANAGER_Port"			
			echo "   print the port of system manager"
			echo "$lcmd SYSTEM_MANAGER SYSTEM_MANAGER_Port address_value"						
			echo "	set the port of system manager"
			echo "  needs CFG> device restart to activate"		

		    echo "$lcmd GATEWAY GATEWAY_IPv6"			
			echo "   print the IPv6 address of gateway"
			echo "$lcmd GATEWAY GATEWAY_IPv6 address_value"						
			echo "	set the IPv6 address of gateway"
			echo "  needs CFG> device restart to activate"		
		    echo "$lcmd GATEWAY GATEWAY_IPv4"			
			echo "   print the IPv4 address of gateway"
			echo "      0.0.0.0 means module determine the ER IP at run time"
			echo "$lcmd GATEWAY GATEWAY_IPv4 address_value"						
			echo "	set the IPv4 address of gateway"
			echo "      0.0.0.0 means module determine the ER IP at run time"
			echo "  needs CFG> device restart to activate"		
		    echo "$lcmd GATEWAY GATEWAY_UDPPort"			
			echo "   print the port of gateway"
			echo "$lcmd GATEWAY GATEWAY_Port address_value"						
			echo "	set the port of gateway"
			echo "  needs CFG> device restart to activate"	

		    echo "$lcmd BACKBONE BACKBONE_IPv6"			
			echo "   print the IPv6 address of backbone"
			echo "$lcmd BACKBONE BACKBONE_IPv6 address_value"						
			echo "	set the IPv6 address of backbone"
			echo "  needs CFG> device restart to activate"		
		    echo "$lcmd BACKBONE BACKBONE_IPv4"			
			echo "   print the IPv4 address of backbone"
			echo "      0.0.0.0 means module determine the ER IP at run time"
			echo "$lcmd BACKBONE BACKBONE_IPv4 address_value"						
			echo "	set the IPv4 address of backbone"
			echo "      0.0.0.0 means module determine the ER IP at run time"
			echo "  needs CFG> device restart to activate"		
		    echo "$lcmd BACKBONE BACKBONE_Port"			
			echo "   print the port of backbone"
			echo "$lcmd BACKBONE BACKBONE_Port address_value"						
			echo "	set the port of backbone"
			echo "  needs CFG> device restart to activate"	

			echo "$lcmd GATEWAY TCP_SERVER_PORT"
			echo "  print the listening port of the gateway"
			echo "$lcmd GATEWAY TCP_SERVER_PORT port_value"
			echo "  set the listening port of the gateway"
			echo "  needs CFG> device restart to activate"
			echo "$lcmd GATEWAY HOST_APP ipv4:port"
			echo "  set the address and port of the listening host application"
			echo "  This option makes the Gateway act as a tcp client, instead of server"
			echo "  and thus ignore TCP_SERVER_PORT"
			echo "  needs CFG> device restart to activate"
			echo "  "
								
		;;	
		upgrade )
			echo "upgrade wget url"
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
	case $arg in 
		id )
			if [ -z $write_val ]; then
				ini_editor -s GLOBAL -v AN_ID -r | cut -f2 -d' '
			else
				if echo "${value}" | grep -q "^[0-9ABCDEFabcdef]\{6\}$"; then 
					log2flash "CFG $lcmd $arg [$value]"
					value=`echo ${value} | tr a-z A-Z` # Convert to capital letters
					ini_editor -s GLOBAL -v AN_ID -w "00 ${value}"
					
					#echo "Critical configuration change accepted, \"device restart\" required."
	            else
					echo "ERR cfg.sh: id ${value} is not valid"
				fi
			fi	
		;;
		wan_link )
			if [ -z $write_val ]; then
				ini_editor -f $CLI_INI -s $lcmd -v $arg -r
			else
				if [ "$write_val" = "eth" -o "$write_val" = "wifi" -o "$write_val" = "gprs" ]; then
					log2flash "CFG $lcmd $arg [$value]"
					ini_editor -f $CLI_INI -s $lcmd -v $arg -w "$write_val"
					#echo "Critical configuration change accepted, \"device restart\" required."
				else
					echo "ERR cfg.sh: device wan_link ${write_val} is not valid"
				fi
			fi
		;;
		srev )
			echo `cat $NIVIS_FIRMWARE"version"`
		;;
		restart )			
			log2flash "CFG $lcmd $arg"
			start.sh  
		;;
		start )			
			log2flash "CFG $lcmd $arg"
			start.sh  
		;;		
		stop )			
			log2flash "CFG $lcmd $arg"
			stop.sh  
		;;	
		
		reboot )			
			log2flash "CFG $lcmd $arg"
			stop.sh  
			reboot
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
				. /etc/rc.d/rc.net.info
				echo $ETH0_IP
			else
				echo "$write_val" | grep -q "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$" ||\
					{ echo "ERR cfg.sh: Invalid IP."; return; }

				log2flash "CFG $lcmd $arg"
				sed -i "s/\(ETH0_IP *= *\).*/\1${write_val}/I" /etc/rc.d/rc.net.info
				echo "Needs device reboot to activate"
			fi
	    ;;
	    mask)
	        if [ -z $write_val ]; then
                . /etc/rc.d/rc.net.info
                echo $ETH0_MASK
            else
                echo "$write_val" | grep -q "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$" ||\
					{ echo "ERR cfg.sh: Invalid MASK."; return; }

                log2flash "CFG $lcmd $arg"
                sed -i "s/\(ETH0_MASK *= *\).*/\1${write_val}/I" /etc/rc.d/rc.net.info
            fi
	    ;;
	    gateway)
	        if [ -z $write_val ]; then
                . /etc/rc.d/rc.net.info
                echo $ETH0_GW
            else
                echo "$write_val" | grep -q "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$" ||\
					{ echo "ERR cfg.sh: Invalid GW."; return; }

                log2flash "CFG $lcmd $arg"
                sed -i "s/\(ETH0_GW *= *\).*/\1${write_val}/I" /etc/rc.d/rc.net.info				

            fi
	    ;;
		mac)
			if [ -z $write_val ]; then
				ifconfig eth0 | grep HWaddr | sed "s/.*HWaddr *//;s/://g"
			else
				if echo "${write_val}" | grep -q "^[0-9ABCDEFabcdef]\{12\}$"; then
					if grep -q ETH0_MAC /etc/rc/d/rc.net.info 2> /dev/null; then
						sed -i "s/ETH0_MAC=.*/ETH0_MAC=$write_val/" /etc/rc.d/rc.net.info
					else
						echo "ETH0_MAC=$write_val" >> /etc/rc.d/rc.net.info
					fi

					log2flash "CFG $lcmd $arg"					

				else
					echo "ERR cfg.sh: Mac address must be 12 digit hex number"
					echo "Exmample: AA0102030405"
				fi
			fi
        ;;
		mac1)
			if [ -z $write_val ]; then
				ifconfig eth1 | grep HWaddr | sed "s/.*HWaddr *//;s/://g"
			else
				if echo "${write_val}" | grep -q "^[0-9ABCDEFabcdef]\{12\}$"; then
					if grep -q ETH1_MAC /etc/rc/d/rc.net.info 2> /dev/null; then
						sed -i "s/ETH1_MAC=.*/ETH1_MAC=$write_val/" /etc/rc.d/rc.net.info
					else
						echo "ETH1_MAC=$write_val" >> /etc/rc.d/rc.net.info
					fi

					log2flash "CFG $lcmd $arg"					

				else
					echo "ERR cfg.sh: Mac address must be 12 digit hex number"
					echo "Exmample: AA0102030405"
				fi
			fi
        ;;
		restart )
			log2flash "CFG $lcmd $arg -- rebooting"
			stop.sh  
			reboot
		;;
	    *)
		    echo "ERR cfg.sh: argument $arg unknown"
			echo ""
			cmd_help "$lcmd"
	esac
}

cmd_upgrade()
{
	local lcmd=upgrade
	local arg=$1
	local write_val=$2
	[ ! -z $1 ] &&	shift 1
	local value="$*"
	
	log2flash "CFG $lcmd $arg [$value]"

	if [ ! "x$arg" = "xwget" -o -z $write_val ]; then
	    log_echo "ERR cfg.sh: invalid format"
		echo ""
		cmd_help $lcmd
		return 1
	fi
	
	#only wget_upgrade for now
	
	atomic_act /tmp/fw_upgrade.lock "wget_upgrade.sh $value"	
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
				log2flash "CFG $lcmd $arg [$value]"
				ini_editor -f $CLI_INI -s $lcmd -v $arg -w "$value"				
			fi	
		;;
		# password must accept any chars, including special chars like # or " 
		password )	
			if [ -z $write_val ]; then
				ini_editor -f $CLI_INI -s $lcmd -v $arg -a -r
			else
				log2flash "CFG $lcmd $arg [$value]"
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
		
		ini_editor -s $section -v $var -w "$value"							
	else
		ini_editor -s $section -v $var -r		
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



