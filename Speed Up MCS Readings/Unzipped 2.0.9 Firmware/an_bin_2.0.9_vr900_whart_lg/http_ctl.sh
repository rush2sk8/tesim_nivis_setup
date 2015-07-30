#! /bin/sh

http_cmd='mini_httpd -u root -c **.php|**.cgi -dd '$NIVIS_FIRMWARE'/www/wwwroot'

elog2flash() {
	log2flash "$@"
	echo $@
}

# mini_httpd does not delete pidfiles on stop
check_deletepidfiles() {
	retries=$1
	shift
	pidfiles=$*
	pidno=$#

	while [ $retries -gt 0 ] ; do
		usleep 10000
		count=`ps | grep mini_httpd | grep -v grep | wc -l`
		if [ $count -eq 0 ]; then
			rm -f $pidfiles
			return 0 # OK
		fi
		retries=$(($retries-1))
		[ "$dirty" = "0" ] && return 0
	done

	rm -f $pidfiles
	return 1	# not dead
}
check_createpidfiles() {
	retries=$1
	shift
	pidfiles=$*
	pidno=$#

	while [ $retries -gt 0 ] ; do
		usleep 100
		dirty=$pidno
		for file in $pidfiles ; do
			if [ -f $file ]; then
				dirty=$(($pidno-1))
			fi
		done
		retries=$(($retries-1))
		[ "$dirty" = "0" ] && return 0
	done

	[ "$dirty" != "0" ] && return 1
}


start_http()
{
	echo "Starting HTTP server"

	if [ -f /var/run/http.pid ] ; then
		elog2flash "HTTP server already started"
		return 1
	fi

	${http_cmd} -i /var/run/http.pid &> /dev/null
	RV=$?

	check_createpidfiles 11 /var/run/http.pid
	PID=$?
	# this is actually a dumb test, because the daemon might die right after
	# it started. TODO: wait a bit and see if there are any zombies
	if [ $RV -eq 0 -a $PID -eq 0 ] ; then
		elog2flash "HTTP server started OK"
	else
		elog2flash "Could not start HTTP server[$RV]"
	fi
	return $RV
}

start_https()
{
	echo "Starting HTTPS server"
	if [ -f /var/run/https.pid ] ; then
		elog2flash "HTTPS server already started"
		return 1
	fi

	${http_cmd} -i /var/run/https.pid -S -E $NIVIS_ACTIVITY_FILES/access_node_cert.pem &> /dev/null
	RV=$?

	check_createpidfiles 11 /var/run/https.pid
	PID=$?
	if [ $RV -eq 0 -a $PID -eq 0 ] ; then
		elog2flash "HTTPS server started OK"
	else
		elog2flash "Could not start HTTPS server (no encryption support?)"
	fi
	return $RV
}

start()
{
	[ ! -d $NIVIS_ACTIVITY_FILES/web_history/ ] && mkdir $NIVIS_ACTIVITY_FILES/web_history/

	# save some time by starting the non-secure server first since the
	# encryption might not be activated
	start_http
	start_https
}

stop()
{
	elog2flash "Stopping HTTP and HTTPS servers"
	a=`killall mini_httpd 2>&1`

	# this will always be "" since the server output is redirected to /dev/null
	[ "$a" != "" ] &&  log2flash "$a"

	# log2flash should take long enough to allow all mini_https to die
	# still, for safety, sleep some microseconds

	check_deletepidfiles 11 /var/run/http.pid /var/run/https.pid
	RV=$?
	# still alive ?
	if [ "`killall -q -0 mini_httpd`" != "0" -a $RV -ne 0 ] ; then
		elog2flash "HTTP servers still alive. Whack'em -9 style"
		killall -q -9 mini_httpd
		rm -rf /var/run/http*.pid
	fi
}

restart()
{
	elog2flash "Restarting HTTP server"
	stop
	start
}

case "$1" in
	start)
		start
		exit $?
	;;
	stop)
		stop
		exit $?
	;;
	restart)
		restart
		exit $?
	;;
	*)
		echo "`basename $0` stop|start|restart"
	;;
esac
