#!/bin/sh

PROD_FILE="/access_node/activity_files/production.txt"
PROD_STEP="/access_node/activity_files/production.step"
RC_NET_INFO="/access_node/etc/rc.d/rc.net.info"
MSP_FW_FILE="/access_node/dn_fw_default.txt"

KERNEL_DIR=/lib/modules/2.6.25.20/kernel
DRIFT_FILE="/etc/ntp/drift"

#`ini_editor -s GLOBAL -v AN_ID -r | cut -f2 -d' '`

#vt100 allows us to edit with joe
export TERM=vt100

. ${NIVIS_FIRMWARE}common.sh

log()
{
	echo "$*"
	echo -n "`date \"+%Y/%m/%d %T\"` " >> $PROD_FILE
	echo "$*" >> $PROD_FILE
}

is_answer_yes()
{
	local tmp

	read -p "$1" tmp
	if [ "$tmp" = "y" -o "$tmp" = "Y" ]; then
		return 0	# true
	else
		return 1	# false
	fi
}

# $1 step_name
sync_step_start()
{
	local tmp="a"

	while [ true ]; do
		echo ""
		echo "Press 's' to start step $1"
		echo "      'e' to exit to console"
		read tmp
		[ "$tmp" = "e" ] && exit 0
		[ "$tmp" = "s" ] && return 0
	done
}

base_settings()
{
	local IP_VAL
	local MASK_VAL
	local GW_VAL
	local AN_ID_CRT
	local AN_ID
	local passed
	local tmp
	local PROD_FILE_TMP
	local NS_VAL
	local ns_done
	local ETH_NAME
	local ETH0_MAC_VAL
	local ETH1_MAC_VAL

	sync_step_start base_settings
	passed=0
	while [ $passed -ne 1 ]; do

		echo Board settings...
		echo "Board flavor: VR900"
		touch /etc/flavor_vr900

		AN_ID_CRT=`ini_editor -s GLOBAL -v AN_ID -r | cut -f2 -d' '`

		read -p "Enter AN_ID (Ex: 0001BC. Current $AN_ID_CRT): "	AN_ID
		AN_ID=${AN_ID:-$AN_ID_CRT}
		[ `echo ${AN_ID} | grep "^[0-9ABCDEFabcdef]\{6\}$" | wc -l` -ne 1 ] && echo "Error: AN_ID ${AN_ID} is not valid" && continue

		ini_editor -s GLOBAL -v AN_ID -w "00 ${AN_ID}"

		#unique (as in not IP-dependent) MAC is specifically requested by Yokogawa
		read -p "Enter ETH0 MAC: " ETH0_MAC_VAL
		if [ "${ETH0_MAC_VAL}" ]; then	# must be empty OR valid MAC
			ETH1_MAC_VAL=`echo "${ETH1_MAC_VAL}" | tr -d ':'`
			[ `echo "${ETH0_MAC_VAL}" | grep "^[0-9ABCDEFabcdef]\{12\}$" | wc -l` -ne 1 ] && echo "Error: MAC ${ETH0_MAC_VAL} is not valid. Use 12 digit hex number" && continue
		fi

		#ok, maybe we can leave this out in some future
		read -p "Enter ETH1 MAC: " ETH1_MAC_VAL
		if [ "${ETH1_MAC_VAL}" ]; then	# must be empty OR valid MAC
			ETH1_MAC_VAL=`echo "${ETH1_MAC_VAL}" | tr -d ':'`
			[ `echo "${ETH1_MAC_VAL}" | grep "^[0-9ABCDEFabcdef]\{12\}$" | wc -l` -ne 1 ] && echo "Error: MAC ${ETH1_MAC_VAL} is not valid. Use 12 digit hex number" && continue
		fi
		log "ETH0 MAC [$ETH0_MAC_VAL] ETH1 MAC [$ETH1_MAC_VAL]"

		ETH_NAME_DEF="eth0"	#TODO maybe read from /etc/rc.d/rc.net.info ?
		IP_VAL_DEF="192.168.0.101"	# TAKE CARE: change in rc.nivis if you change this
		MASK_VAL_DEF="255.255.255.0"
		GW_VAL_DEF="192.168.0.1"

		echo ""
		echo "ETH Defaults: IP $IP_VAL_DEF, GW $GW_VAL_DEF, mask $MASK_VAL_DEF"
		if is_answer_yes "Use ETH defaults (y/n)?" ; then
			log "Default ETH values were confirmed by the user"
			ETH_NAME=$ETH_NAME_DEF
			IP_VAL=$IP_VAL_DEF
			MASK_VAL=$MASK_VAL_DEF
			GW_VAL=$GW_VAL_DEF
		else
			read -p "ETH interface (RevB: eth1, all others: eth0. Current $ETH_NAME_DEF): " ETH_NAME
			ETH_NAME=${ETH_NAME:-$ETH_NAME_DEF}
			[ "$ETH_NAME" != "eth0" -a "$ETH_NAME" != "eth1" ] &&  echo "Error: Eth name ${ETH_NAME} is not valid" && continue

			read -p "Enter IP (Default $IP_VAL_DEF): "    IP_VAL
			IP_VAL=${IP_VAL:-$IP_VAL_DEF}
			[ `echo $IP_VAL | grep "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$" | wc -l` -ne 1 ] && echo "Error: IP ${IP_VAL} is not valid" && continue

			read -p "Enter Mask (Default $MASK_VAL_DEF): " 	MASK_VAL
			MASK_VAL=${MASK_VAL:-$MASK_VAL_DEF}
			[ `echo $MASK_VAL | grep "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$" | wc -l` -ne 1 ] && echo Error: "MASK ${MASK_VAL} is not valid" && continue

			read -p "Enter gw (Default $GW_VAL_DEF): "    GW_VAL
			GW_VAL=${GW_VAL:-$GW_VAL_DEF}
			[ `echo $GW_VAL | grep "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$" | wc -l` -ne 1 ] && echo "Error: GW ${GW_VAL} is not valid." && continue

			log "Configuring An_${AN_ID}: IP $IP_VAL, GW $GW_VAL, mask $MASK_VAL"

			if ! is_answer_yes "Are these values correct (y/n)?" ; then
				continue
			fi

			log "ETH Values were confirmed by the user"
			
			#add name servers to be used on ETH
			dns_add

			if is_answer_yes "Disable route to 10.0.0.0 (n for Nivis, y for customers) (y/n)?" ; then
				sed -i "s/\(.*10\.0\.0\.0.*\)/#\1/" /etc/rc.d/rc.net		# comment out
			else
				sed -i "s/\(#*\)\(.*10\.0\.0\.0.*\)/\2/" /etc/rc.d/rc.net	# remove comment, enable command
			fi

			if is_answer_yes "Disable backup IP 172.17.17.17 (reccommended y) (y/n)?" ; then
				sed -i "s/\(.*172\.17\.17\.17.*\)/#\1/" /etc/rc.d/rc.net		# comment out the line
			else
				sed -i "s/\(#*\)\(.*172\.17\.17\.17.*\)/\2/" /etc/rc.d/rc.net	# remove comment, enable command
			fi
		fi
		echo Updating $RC_NET_INFO
		echo '#AUTOMATICALLY GENERATED. '	>   $RC_NET_INFO
		echo "ETH0_IP=$IP_VAL"				>>  $RC_NET_INFO
		echo "ETH0_MASK=$MASK_VAL"			>>  $RC_NET_INFO
		echo "ETH0_GW=$GW_VAL"				>>  $RC_NET_INFO
		echo "ETH_NAME=$ETH_NAME"			>>  $RC_NET_INFO
		[ ! -z "$ETH0_MAC_VAL" ] && echo "ETH0_MAC=$ETH0_MAC_VAL"	>>  $RC_NET_INFO
		[ ! -z "$ETH1_MAC_VAL" ] && echo "ETH1_MAC=$ETH1_MAC_VAL"	>>  $RC_NET_INFO
		chmod 0777 $RC_NET_INFO

		echo creating /access_node/etc/hosts
		echo "127.0.0.1         localhost"      >  /access_node/etc/hosts
		echo "$IP_VAL           An_${AN_ID}"    >> /access_node/etc/hosts

		ifconfig eth0 down
		ifconfig eth1 down
		echo "We need DHCP to connect to ntp servers"
		rm -f /etc/config/no_dhcp
		/access_node/etc/rc.d/rc.net
		echo "	DHCP settings:"
		ifconfig ${ETH_NAME}:0 | grep "inet addr"
		if [ $? -ne 0 ]; then
			echo "WARNING: can't get a DHCP-assiged IP. No DHCP server or bad ETH cable."
		fi

		echo "	ETH settings:"
		ifconfig ${ETH_NAME}
		if [ $? -ne 0 ]; then
			echo
			log "base_settings: FAILED"
		else
			log "base_settings: PASSED "
			passed=1
		fi
	done
}

dns_add()
{
	echo "Recommended: enter at least one nameserver"
	ns_added=0
	cat /dev/null > /tmp/resolv.conf.eth
	while [ $ns_added -ne 99 ]; do
		read -p "Enter nameserver (leave empty to stop adding): "  NS_VAL

		[ -z "$NS_VAL" ] && log "DNS added: $ns_added" && ns_added=99 && continue
		[ `echo $NS_VAL | grep "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$" | wc -l` -ne 1 ] && echo "DNS ${NS_VAL} is not valid" && continue

		echo "nameserver ${NS_VAL}" >> /tmp/resolv.conf.eth
		ns_added=$(($((ns_added))+1))
	done
	mv /tmp/resolv.conf.eth /etc/resolv.conf.eth
}


#try to read time from several time servers and set it on the board
set_time_auto()
{	#alternate: `ntpd -q -g`
	#The problem with alternate: it takes 3 minute to discover the NTP servers are not reacheable
	local out
	NTP_SERVER_LIST="pool.ntp.org 199.240.130.1"
	for S in $NTP_SERVER_LIST; do
		log " trying to get time from $S"
		#ntpclient will return non-zero on name resolution failure
		# but it will return ZERO (suzzess) on timeout
		# Therefore, we must check for both retcode and out string
		out=`ntpclient -s -h $S -i 20 2> /dev/null`
		[ $? -eq 0 -a -n "$out" ] && log " set_time_auto: ok" && return 0;
	done
	log " set_time_auto: failed"
	return 1
}

#start ntpd to calibrate the drift of the crystal driving Linux clock,
#but ONLY if it's not yet calibrated (file /etc/ntp/drift does not exist or contain 0.000)
start_calibrate_clock()
{
	[ -f $DRIFT_FILE ] && [ "`cat $DRIFT_FILE`" != "0.000" ] && return # calibrated, nothing to do

	# driftfile does not exist, or it contains 0.000 => Linux-driving crystal NOT properly calibrated
	rm -f $DRIFT_FILE
	ntpd -g
	echo ""
	log "Calibration of Linux-driving crystal drift started..."
	echo "Do not power off in next 60 minutes"
	echo ""
}

#return true if the Linux-driving crystal is calibrated
clock_not_calibrated()
{	
	[ -f $DRIFT_FILE ] && [ "`cat $DRIFT_FILE`" != "0.000" ] && return 1 # calibrated	
	return 0	# not calibrated
}

i2c_check()
{
	local passed
	sync_step_start i2c_check
	echo ""
	echo "Step: RTC"
	passed=0
	while [ $passed -ne 1 ]; do
		echo ""
		echo "RTC check"
		echo "Make sure that RTC battery is in place and Ethernet cable is connected"
		read -p "Press Enter to continue" tmp
		
		#Try to get time automatically from several internet time servers
		#This assume we are now connected to the internet 
		passed=1
		set_time_auto
		start_calibrate_clock
		if [ $? -ne 0 ]; then
			time_ok=0
			while [ $time_ok -ne 1 ]; do
				echo -n "Enter current date/hour (YY/MM/DD hh:mm:ss):"
				read tmp
				
				local YY	# year
				local MM	# month
				local DD	# day
				local hh	# hour
				local mm	# minute
				local ss 	# second

				tmp=`echo "$tmp" | tr -s '/:' ' '`
				YY=`echo $tmp | cut -f1 -d ' '`;
				MM=`echo $tmp | cut -f2 -d ' '`; 
				DD=`echo $tmp | cut -f3 -d ' '`; 
				hh=`echo $tmp | cut -f4 -d ' '`; 
				mm=`echo $tmp | cut -f5 -d ' '`; 
				ss=`echo $tmp | cut -f6 -d ' '`;
				
				if [ -z "$YY" -o -z "$MM" -o -z "$DD" -o -z "$hh" -o -z "$mm" -o -z "$ss" ]; then
					if ! is_answer_yes "Incorrect date. Do you want to try again (y/n)?"; then
						time_ok=1
						passed=0
					fi
				elif [ 	`echo "$tmp" | grep "^[0-9 ]\+$" | wc -l` -ne 1 ]; then 
					#must have space in grep [0-9 ] to match the separator too
					if ! is_answer_yes "Incorrect date. Do you want to try again (y/n)?"; then
						time_ok=1
						passed=0
					fi
				else
					if [ 	$YY -lt  8 -o \
							$MM -gt 12 -o $MM -lt 1 -o \
							$DD -gt 31 -o $DD -lt 1 -o \
							$hh -gt 24 -o \
							$mm -gt 59 -o \
							$ss -gt 59 ]; then
						if ! is_answer_yes "Incorrect date. Do you want to try again (y/n)?"; then
							time_ok=1
							passed=0
						fi
					else
						log "Date input by user: $tmp"
						date ${MM}${DD}${hh}${mm}20${YY}.${ss}
						if [ $? -eq 0 ]; then 
							time_ok=1
						else
							if ! is_answer_yes "Incorrect date. Do you want to try again (y/n)?"; then
								time_ok=1
								passed=0
							fi
						fi
					fi
				fi
			done
		fi
		
		if [ $passed -eq 1 ]; then
			i2c-rtc -d 0xD0 --sync -w 0 || passed=0
		fi
		
		if [ $passed -eq 1 ]; then
			echo "Date apparently set ok"
			echo "Reading back"
			/access_node/bin/i2c-rtc -d 0xD0 --date -r || passed=0
			if [ $passed -eq 1 ]; then
				is_answer_yes "Did you read valid date (UTC date + few sec (y/n)?" \
					&& /access_node/bin/i2c-rtc -d 0xD0 --sync -r || passed=0
			fi
		fi
		[ $passed -eq 1 ] \
			&& log "VR RTC Set/Test: PASSED"\
			|| log "VR RTC Set/Test: FAILED"
		if [ $passed -ne 1 ]; then
			is_answer_yes "Repeat i2c_check tests (y/n)?"
			passed=$?
		fi
	done
}

# set the subnet ID
# set the BBR EUI64
isa_generic()
{
	local passed
	local SUBNET_ID	#decimal
	local SUBNET_HEX
	local SUBNET_ID_CRT
	local BACKBONE_EUI64
	local BACKBONE_EUI64_SEPARATORS
	local BACKBONE_EUI64_CRT

	passed=0
	while [ $passed -ne 1 ]; do
		SUBNET_ID_CRT=`ini_editor -s GATEWAY -v SubnetID -r`
		read -p "Enter Subnet ID in decimal (Current ${SUBNET_ID_CRT}): " SUBNET_ID
		SUBNET_ID=${SUBNET_ID:-$SUBNET_ID_CRT}
		[  $((SUBNET_ID)) -le 0 -o $((SUBNET_ID)) -gt 65535 ] && echo "Error: Invalid subnet ID" && continue
		SUBNET_HEX=`printf "%04X" $SUBNET_ID`

		BACKBONE_EUI64_CRT=`ini_editor -s BACKBONE -v BACKBONE_EUI64 -r`
		read -p "Enter Backbone EUI64: 16 hex chars (Current ${BACKBONE_EUI64_CRT}): " BACKBONE_EUI64
		BACKBONE_EUI64=${BACKBONE_EUI64:-$BACKBONE_EUI64_CRT}
		[ `echo ${BACKBONE_EUI64} | grep "^[0-9ABCDEFabcdef]\{16\}$" | wc -l` -ne 1 ] && echo "Error: BBR EUI64 ${BACKBONE_EUI64} is not valid" && continue
		N1=${BACKBONE_EUI64:0:4}
		N2=${BACKBONE_EUI64:4:4}
		N3=${BACKBONE_EUI64:8:4}
		N4=${BACKBONE_EUI64:12:4}
		BACKBONE_EUI64_SEPARATORS="${N1}:${N2}:${N3}:${N4}"
		passed=1
	done
	
	log "Set Subnet ID: $SUBNET_ID and BBR EUI64: $BACKBONE_EUI64"
	sed -i "s/\([^,]*,[^,]*,\)[^,]*/\1$SUBNET_ID/;s/\(BACKBONE.*= \)[^,]*/\1$BACKBONE_EUI64_SEPARATORS/" /access_node/profile/system_manager.ini
	sed -i "s/\(FilterTargetID\).*/\1 = $SUBNET_HEX/;s/\(SubnetID\).*/\1 = $SUBNET_ID/;s/\(BACKBONE_EUI64\).*/\1 = $BACKBONE_EUI64/" /access_node/profile/config.ini
}
#the certificates are created on the server with the name <ANID>.
#NOT USED, BUT KEEP IT HERE IN CASE WE NEED IT LATER
download_openvpn_certificates()
{
	local out
	local FTP_HOST_DEF
	local FTP_HOST_VAL
	local VPN_SERVER_DEF
	local VPN_SERVER_VAL

	FTP_HOST_DEF="192.168.0.10"
	VPN_SERVER_DEF="65.205.163.85"
	
	read -p "Enter FTP server IP. Default ${FTP_HOST_DEF}: " FTP_HOST_VAL
	FTP_HOST_VAL=${FTP_HOST_VAL:-$FTP_HOST_DEF}
	
	AN_ID_CRT=`ini_editor -s GLOBAL -v AN_ID -r | cut -f2 -d' '`
	CRT_NAME="client_${AN_ID_CRT}.crt"
	KEY_NAME="client_${AN_ID_CRT}.key"

	echo "Downloading openvpn certificates from FTP server at ${FTP_HOST_VAL}:~nivis/"
	echo "Make sure vpn certificates for $AN_ID_CRT exist on the FTP server on "
	echo "The certificates: ca.crt $CRT_NAME $KEY_NAME"
	read -p "Press Enter to continue" tmp

	out=0
	cd /access_node/activity_files/openvpn
	rm -f ca.crt $CRT_NAME $KEY_NAME
	wget ftp://nivis:nivis@${FTP_HOST_VAL}/ca.crt    || out=1
	wget ftp://nivis:nivis@${FTP_HOST_VAL}/$CRT_NAME || out=1
	wget ftp://nivis:nivis@${FTP_HOST_VAL}/$KEY_NAME || out=1
	#TODO: indicate if the transfer failed
	[ $passed -eq 0 ] && log "Fail to get openvpn certificates!"

	read -p "Enter VPN server IP. Default ${VPN_SERVER_DEF} : " VPN_SERVER_VAL
	VPN_SERVER_VAL=${VPN_SERVER_VAL:-$VPN_SERVER_DEF}

	sed -i "s/cert.*crt/cert $CRT_NAME/;s/key.*key/key  $KEY_NAME/;s/remote.*/remote $VPN_SERVER_VAL 1194/" /access_node/activity_files/openvpn/client.config
	cd -
	return $out
}

# download openssl certificates
# enable save of readings history by MH into DeviceReadingsHistory and reading by MCS from the same table
# enable launch of openvpn
#NOT USED, BUT KEEP IT HERE IN CASE WE NEED IT LATER
chevron_specific()
{
	echo "Enabling data history in web and MH (Chevron-specific)"
	sed -i "s/READINGS_HISTORY.*/READINGS_HISTORY = true ;/" /access_node/firmware/www/wwwroot/app/scripts/appsettings.js
	ini_editor -s MONITOR_HOST -v UseReadingsHistory -w 1
	echo "(Read the script if it is necessary to revert from Chevron to ISA)"
	# revert with:
	#sed -i "s/READINGS_HISTORY.*/READINGS_HISTORY = false ;/" /access_node/firmware/www/wwwroot/app/scripts/appsettings.js
	#ini_editor -s MONITOR_HOST -v UseReadingsHistory -w 0

	echo "Enabling openvpn"
	touch /etc/config/vpn_client
	#revert with rm -f /etc/config/vpn_client

#	there is no dhcp server on the 3G modem
#	take care, if certificate download failed, maybe we need dhcp for next attempt
	echo "Disabling dhcp"
	touch /etc/config/no_dhcp
	
	download_openvpn_certificates
	return $?
}

# uncomment PS_CONTRACTS_REFUSAL_TIME_SPAN / PS_CONTRACTS_REFUSAL_DEVICE_TIME_SPAN
# enable alert forwarding to GW - set timeout to 120 sec
# get time from TR
# configure for STAR mesh
yokogawa_specific()
{
	echo "Yokogawa specific:"
	echo "    Enabling PS contract refusal timers"
	echo "    Enabling alert fwd to GW"
	echo "    Use TR as time source (not ntp)"
	echo "    Configure for STAR"
	sed -i "s/\(#.*\)\(PS_CONTRACTS_REFUSAL_TIME_SPAN.*\)/\2/;s/\(#.*\)\(PS_CONTRACTS_REFUSAL_DEVICE_TIME_SPAN.*\)/\2/" /access_node/profile/config.ini
	ini_editor -f /access_node/profile/sm_subnet.ini -s SYSTEM_MANAGER -v ENABLE_ALERTS_FOR_GATEWAY -w true
	ini_editor -f /access_node/profile/sm_subnet.ini -s SYSTEM_MANAGER -v ALERT_TIMEOUT -w 120
	ini_editor -f /access_node/profile/config.ini -s BACKBONE -v TR_TIME_MASTER -w yes
	#defaults for YK rel 2.0.46: STAR
	ini_editor -f /access_node/profile/sm_subnet.ini -s SYSTEM_MANAGER -v ENABLE_STAR_TOPOLOGY -w true
	ini_editor -f /access_node/profile/sm_subnet.ini -s SYSTEM_MANAGER -v NR_ROUTERS_PER_ROUTER -w 2
	ini_editor -f /access_node/profile/sm_subnet.ini -s SYSTEM_MANAGER -v NR_NON_ROUTERS_PER_ROUTER -w 10
	ini_editor -f /access_node/profile/sm_subnet.ini -s SYSTEM_MANAGER -v FREEZE_LEVEL_ONE_ROUTERS -w true
}

# comment PS_CONTRACTS_REFUSAL_TIME_SPAN / PS_CONTRACTS_REFUSAL_DEVICE_TIME_SPAN
# disable alert forwarding to GW
# get time from NTP
non_yokogawa_specific()
{
	echo "NON-Yokogawa:"
	echo "    Disabling PS contract refusal timers"
#	echo "    Disabling alert fwd to GW"
	echo "    Removing all settings from sm_subnet.ini"
	echo "    Use ntp as time source (not TR)"
	sed -i "s/\(PS_CONTRACTS_REFUSAL_TIME_SPAN.*\)/#\1/;s/\(PS_CONTRACTS_REFUSAL_DEVICE_TIME_SPAN.*\)/#\1/" /access_node/profile/config.ini
	echo "" > /access_node/profile/sm_subnet.ini
#	ini_editor -f /access_node/profile/sm_subnet.ini -s SYSTEM_MANAGER -v ENABLE_ALERTS_FOR_GATEWAY -w false
	ini_editor -f /access_node/profile/config.ini -s BACKBONE -v TR_TIME_MASTER -w no
}

target()
{
	local passed

	sync_step_start target
	echo ""
	echo "Step: target"

	passed=0
	while [ $passed -ne 1 ]; do
		echo "Choose target"
		echo " 1 - isa (ver. 2.6, 2.7 or later)"
		echo " 2 - yokogawa (isa 2.5)"
		echo " 3 - wh  (VR910)"
		read tmp
		case $tmp in
			1 | isa )
				isa_generic
				non_yokogawa_specific
				passed=1 ;;

			2 | yokogawa )
				isa_generic
				yokogawa_specific
				passed=1 ;;
			
			4 | wh )
				passed=1 ;;

			* ) passed=0 ;;
		esac
	done
	
	if is_answer_yes "Disable telnet for deployment (y/n - reccomended Nivis:n Customers:y)?" ; then
		mv /usr/sbin/telnetd /usr/sbin/telnetd.stop
		log "TELNET disabled"
	else
		[ -f /usr/sbin/telnetd.stop ] && mv /usr/sbin/telnetd /usr/sbin/telnetd.stop
		log "TELNET enabled"
	fi
	#resetting the name server list may not be necessary
	cat /dev/null > /etc/resolv.conf.eth
	if is_answer_yes "Enable DHCP for deployment (y/n)?" ; then
		rm -f /etc/config/no_dhcp
		log "DHCP enabled"
	else
		touch /etc/config/no_dhcp
		log "DHCP disabled"
		echo "DHCP client will be disabled starting with next power on"
	fi
}

if [ -z $1 ]; then
	echo "$0 [action]"
	echo "  list of actions:"
	echo "    prod            - normal production: resume"
	echo "    force           - normal production: force restart, IGNORE steps already performed"
	
	echo "    check_i2c       - check I2C"
	echo "    dns             - add nameservers for ETH link"
	echo "    target          - set deployment target"
	echo ""
	exit 0
fi

if [ "$1" = "prod" ]; then
	echo "Choose next step: (Production: hit ENTER)"
	echo " ENTER - Start normal Production testing"
	echo " 0 - base_settings"
	echo " 1 - i2c_check"
	echo " 2 - target for deployment"
	echo " 6 - skip all"

	read tmp
else
	tmp=$1
fi

#AN_ID_CRT=`ini_editor -s GLOBAL -v AN_ID -r | cut -f2 -d' '`

case $tmp in
	help )
		exit 0
	;;

	base)
		base_settings
		exit 0;;

	dns )
	  dns_add
	  exit 0;;

	check_i2c )
	  i2c_check
	  exit 0;;

	target )
		target
		exit 0
	;;

force )
	rm -f $PROD_STEP
	next_step=0 ;;

	1 ) next_step=1;;
	2 ) next_step=2;;
	3 ) next_step=3;;
	* ) next_step=0;;
esac

log2flash "Production procedure START"
touch $PROD_FILE
log "VersaRouter tests starting..." >> $PROD_FILE
echo "File system information:" >> $PROD_FILE
cat /access_node/etc/fs_info >> $PROD_FILE

#Check for interrupted production procedure which occurs when the baseboard is
# tested/configured separated by the production/configuration of the daughter board
if [ -f $PROD_STEP ]; then
	next_step=`cat $PROD_STEP`
	log "Production procedure RESUMED at step $next_step"
	echo "If you need to restart the whole production procedure hit Ctrl-C then type:"
	echo "  board_setup.sh force"
	echo "If the units is just recalled from storage, please continue."
fi

[ $next_step -le 0 ] && base_settings 	&& echo "1" > $PROD_STEP
discovery&	#it shoud work even in production stage
[ $next_step -le 2 ] && i2c_check 		&& echo "2" > $PROD_STEP
[ $next_step -le 3 ] && target	 		&& echo "3" > $PROD_STEP

log "The base board is now ready for STORAGE"

if [ $next_step -lt 6 ]; then
	echo "Press ENTER to see Production Test File"
	echo ""
	read tmp
	cat $PROD_FILE

	echo ""
	echo "If the production test file is ok, will prepare VR for deployment"
	echo "TAKE CARE: The production testing won't run again after you answer y"
	if is_answer_yes "Prepare the unit for deployment (y/n)?"; then
		rm /etc/config/in_production_stage
		log2flash "Production procedure DONE"

		log "The VR is READY for delivery (except Linux-driving crystal calibration)"
		echo ""
		log "Be aware, units delivered to Yokogawa do not have access to NTP servers"
		log "MAY skip crystal calibration ONLY if the unit will have access to NTP servers at customers"
		log "Otherwise please wait for calibration (60 minutes)."
		echo ""
		if is_answer_yes "Wait for crystal calibration (60 minutes) (y/n)?"; then
			echo ""
			echo "Keep the unit running and connected to the internet until it creates /etc/ntp/drift file (one hour)"
			echo ""
			echo "After clock calibration, PLEASE upload Production Test File to an external ftp server"
			echo "  the file name is $PROD_FILE"
			echo "Keep the file for later reference"
			echo ""
			while clock_not_calibrated; do
				sleep 60
				echo -n "."
			done
			echo ""
			log  "Linux-driving crystal calibration procedure DONE (`cat $DRIFT_FILE`)"
			log2flash  "Linux-driving crystal calibration procedure DONE (`cat $DRIFT_FILE`)"
		fi
		echo "Power off the board now"
	else
		log "The VR is NOT ready for delivery"
	fi

else
	log "All production steps SKIPPED"
	log "This unit is NOT ready to deliver!"
fi
