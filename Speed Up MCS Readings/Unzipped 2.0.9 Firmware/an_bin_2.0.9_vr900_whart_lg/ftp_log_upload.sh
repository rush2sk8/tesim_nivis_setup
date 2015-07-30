#!/bin/sh

USER=nivis	
PASS=nivis
HOST=10.32.0.17
FTPDIR_BASE=logs_an/
ARCH_B4_SENDING=1

renice 5 -p $$

FTPDIR=$FTPDIR_BASE`hostname`
LOCAL_DIR=`dirname $1`
old_path=`pwd`
cd $LOCAL_DIR

log_file=`basename $1`

if [ ! -f /access_node/no_tail_kill.flag ]; then
	log_to_kill=`echo $log_file | cut -d'.' -f1`
	pids_to_kill=`ps | grep "tail.*$log_to_kill" | grep -v grep | sed 's/^\ *\([0-9]\+\).*/\1/'`
	[ ! -z "$pids_to_kill" ] && kill -9 $pids_to_kill
fi


up_file=$log_file
if [ $ARCH_B4_SENDING -eq 1 ]; then
    gzip  ${log_file}
    [ $? -eq 0 ] && up_file=${log_file}.gz
fi

ftpput -u "$USER" -p "$PASS" $HOST "$FTPDIR/$up_file" "$up_file"
ret=$?

[ -z "$2" ] && rm -f $1 
[ -f ${log_file}.gz ] && rm -f ${log_file}.gz

cd $old_path

exit $ret
