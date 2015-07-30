#!/bin/sh

#Sync Linux time with time servers time
#if needed, it also updates RTC time

#if first parameter is "affect_ntpd" then kill ntpd before doing the sync, and start ntpd whenever it is not started

#write an entry to activity log
log() 
{
	echo "$*"	#remove this line after you done all tests
	log2flash "$*"
	return 0
}

#synchronize clock to ntp time
#returns:
#	0 - success
#	1 - failure
set_time()
{
	local S out
	for S in $NTP_SERVER_LIST; do  
		echo " trying to get time from $S" 
		#ntpclient ret non-zero on name resolution failure but ZERO (success) on timeout
		out=`ntpclient -s -h $S -i $ALLOWED_DELAY 2> /dev/null` 
		[ $? -eq 0 -a -n "$out" ] && i2c-rtc -d 0xD0 --sync -w 0 && return 0;
	done
	echo " ERROR cannot read time"
	return 1
}

#set the external variables NTP, OFFSET and OFFSET_S
#returns:
#	0 - clock in sync
#	1 - clock is not in sync
#	2 - unable to check
read_time()
{
	local S SUCCESSES=0
	for S in $NTP_SERVER_LIST; do  
		echo " trying to get time from $S" 
		#ntpclient ret non-zero on name resolution failure but ZERO (success) on timeout
		NTP=`ntpclient -c 1 -h $S -i $ALLOWED_DELAY 2> /dev/null`
		if [ $? -eq 0 -a -n "$NTP" ]; then
			SUCCESSES=$(( $SUCCESSES + 1 ))
			OFFSET=`echo $NTP | cut -f 5 -d ' ' | cut -f 1 -d'.'` # microseconds
			OFFSET_S=$(( $OFFSET / 1000000 ))                     # seconds
			if [ $OFFSET_S -lt $TIMESHIFT_X ] && [ $((- $OFFSET_S)) -lt $TIMESHIFT_X ]; then
				echo "NTPServer-System drift is $OFFSET_S sec, allowed $TIMESHIFT_X. Close enough. Clock NOT set!"
				return 0
			fi
		fi
	done
	OFFSET=${OFFSET:=0}     #protection for the case ntp server is out of reach
	OFFSET_S=$(( $OFFSET / 1000000 ))                     # seconds
	[ $SUCCESSES -eq 0 ] && echo " ERROR cannot read time" && return 2
	echo " WARNING: system time is incorrect by $OFFSET_S seconds"
	return 1
}

# start ntpd if not already running
start_ntpd()
{
	if [ $param = "affect_ntpd" ]; then
		netstat -uan | grep -q ":123 " || ntpd -g
	fi
}

. common.sh

[ ! -f /etc/ntp.conf ] && log "ERROR file /etc/ntp.conf is missing" && return
TR_TIME_MASTER=`ReadVar TR_TIME_MASTER`
if [ -n "$TR_TIME_MASTER" ] && [ $TR_TIME_MASTER = "Y" -o $TR_TIME_MASTER = "YES" -o $TR_TIME_MASTER = "1" -o $TR_TIME_MASTER = "TRUE" \
						-o $TR_TIME_MASTER = "y" -o $TR_TIME_MASTER = "yes" -o $TR_TIME_MASTER = "true" ]; then
							killall ntpd
							echo "WARNING: using the TR as master clock"
							return
fi

TIMESHIFT_X=5
ALLOWED_DELAY=5
RTC_NOT_SET_THRESHOLD=2009 # year
NTP_SERVER_LIST=`grep "^ *server" /etc/ntp.conf | grep -v 127.127 | sed "s/server *\([^ ]*\).*/\\1/"`
NTP_TMP='/tmp/ntpadjust.tmp'
NTP_FAIL=4
RTCFAIL_TMP='/tmp/rtc_fail'

param=${1:-"normal"}

LOCAL_YEAR=`date +%Y`
if [ $LOCAL_YEAR -lt $RTC_NOT_SET_THRESHOLD ]; then
	log "ntp: Date not set. Correcting..."
	set_time
	if [ $? -eq 0 ]; then
		i2c-rtc -d 0xD0 --sync -w 0
		raise_an_ev -e 3 -v 31536000 # one year
	else
		log "ERR ntp date correction failed"
		start_ntpd
		return
	fi 
fi

read_time # this guy creates $NTP, $OFFSET and $OFFSET_S

STATUS=$?

if [ $STATUS -eq 2 ]; then	#unable to check NTP servers
	[ -f $NTP_TMP ] && ntp_fail=$(( `cat $NTP_TMP` + 1 )) || ntp_fail=1
	echo $ntp_fail > $NTP_TMP
	if [ $ntp_fail -ge $NTP_FAIL ]; then
		log "WARN ntp: fail $NTP_FAIL times"
		log "ntp: raw [$NTP]"
		rm -f $NTP_TMP
	fi
	start_ntpd
	return # we are unable to get the time, so there is no point in messing with rtc: exit now!
else
	rm -f $NTP_TMP
fi

if [ $STATUS -ne 0 ]; then	# local clock / NTP are out of sync
	log "ntp: status [$STATUS] raw [$NTP]"
	log "ntp: NTPServer-System drift $OFFSET microsec"
	X=`time i2c-rtc    2>&1 | grep -e i2c -e real | tr '\n' '/' `
	log "`echo $X`"		#read RTC time
	[ $param = "affect_ntpd" ] && killall ntpd && log "WARNING: ntpd running but clock wrong"
	log "ntp: Correcting $OFFSET_S sec system offset"
	set_time
	if [ $? -ne 0 ]; then
		log "WARN ntp: set time failed"
		log "WARN ntp raw: [$NTP]"
	else
		raise_an_ev -e 3 -v $OFFSET_S
		STATUS=0 # we have successfully set the correct system clock, so it is now in sync
	fi
fi

if [ $STATUS -eq 0 ]; then # we know the system clock is good, so check/set the RTC
	X=`time i2c-rtc -x 2>&1 | grep -e i2c -e real | tr '\n' '/'`
	DRIFT_MS=`echo $X  | tr -d '-' |cut -f4 -d' '` # trunk the drift to seconds.miliseconds (take care of negative numbers)
	DRIFT_SEC=`echo $DRIFT_MS | cut -f1 -d'.'` # trunk the drift to seconds
	if [ "$DRIFT_SEC" != "0" ]; then # RTCDRIFT >= +/-1, and we know the RTC is wrong because the system clock is right; so sync them
		i2c-rtc -d 0xD0 --sync -w 0		# attempt to set the time
		if [ $? -eq 0 ]; then
			log "`echo $X` Correcting RTC"	#SUCCESS: log2flash the full output
		else				#rtc MALFUNCTION
			if [ ! -f $RTCFAIL_TMP ]; then
				echo $X > $RTCFAIL_TMP
				log "i2c-rtc MALFUNCTION (will not log further errors): $X"
			fi
		fi
	else
		echo "RTC-System drift is $DRIFT_MS sec, allowed +/-1. Close enough. RTC NOT set!"
	fi
fi

start_ntpd
