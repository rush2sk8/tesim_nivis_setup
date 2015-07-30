#!/bin/sh

. common.sh

CMD1="uptime"
CMD2="ps"
CMD3="du -h /access_node"
CMD4="df -h"
CMD5="free"
CMD6="dmesg"
CMDS="$CMD1,$CMD2,$CMD3,$CMD4,$CMD5,$CMD6"

SNAPSHOT=${1:-${NIVIS_ACTIVITY_FILES}snapshot.txt}

(IFS=','
for i in $CMDS; do
	echo "# $i"
	eval $i
done) > $SNAPSHOT


(for i in `GetWatchedModulesLogs`; do

	echo "# tail -n 200 $i"
	tail -n200 $i
done) >> $SNAPSHOT