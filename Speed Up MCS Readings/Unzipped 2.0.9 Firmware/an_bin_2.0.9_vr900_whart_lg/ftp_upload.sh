#!/bin/sh

#USER=nivis
#PASS=nivis
#HOST=10.32.0.12
#FTPDIR_BASE=/tmp/logs_an/

if [ -f ${NIVIS_PROFILE}cli.ini ]; then
	USER=`ini_editor -f ${NIVIS_PROFILE}cli.ini -s ftpconfig  -v username -r`
	PASS=`ini_editor -f ${NIVIS_PROFILE}cli.ini -s ftpconfig  -v password -r`
	HOST=`ini_editor -f ${NIVIS_PROFILE}cli.ini -s ftpconfig  -v address -r`
	FTPDIR_BASE=`ini_editor -f ${NIVIS_PROFILE}cli.ini -s ftpconfig  -v ftpdir_base -r`
	[ "$3" = "ip" ] && FTPDIR_BASE=`ini_editor -f ${NIVIS_PROFILE}cli.ini -s ftpconfig  -v ftpdir_info -r`
fi
echo "FTPDIR_BASE=$FTPDIR_BASE"
[ -z $USER ] && USER=nivis
[ -z $PASS ] && PASS=nivis
[ -z $HOST ] && HOST=10.32.0.12
[ -z $FTPDIR_BASE ] && FTPDIR_BASE=/Nivis/
	

FTPDIR=$FTPDIR_BASE

LOCAL_DIR=`dirname $1`

cd $LOCAL_DIR
 
 
ftpput -u "$USER" -p "$PASS" $HOST "$FTPDIR" "`basename $1`"
ret=$?

[ ! "$2" ] && rm -f $1

exit $ret