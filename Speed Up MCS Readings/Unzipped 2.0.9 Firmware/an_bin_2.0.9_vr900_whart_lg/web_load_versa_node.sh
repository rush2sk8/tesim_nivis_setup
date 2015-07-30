#!/bin/sh



. /etc/profile

. ${NIVIS_FIRMWARE}common.sh

DIR_UPGRADE=upgrade_web/

log2flash "Web Upgrade versa node request"


old_path=`pwd`

if [ ! -d ${NIVIS_TMP}$DIR_UPGRADE ]; then
	echo "ER_RESULT=ERROR no upload folder"
	log2flash "Upgrade ERROR no upload folder"
	exit 1
fi

cd ${NIVIS_TMP}$DIR_UPGRADE

FW_FILE=`ls -1 * | tail -n 1`

if [ -z $FW_FILE ]; then
	tmp_var=`ls`
	echo "ER_RESULT=ERROR no FW_FILE "
	echo "Uploaded files: $tmp_var"
	log2flash "Upgrade ERROR no FW_FILE "		
	log2flash "Uploaded Files: $tmp_var"
	cd $old_path
	exit 1
fi

. ${NIVIS_FIRMWARE}/build_info

echo "FW_FILE=$FW_FILE release=$release"

killall backbone  > /dev/null 1>&2
killall whaccesspoint > /dev/null 1>&2

#if [ "$release" = "isa" ]; then
#	killall backbone  
#else if [ "$release" = "whart" ]; then
#	killall whaccesspoint
#	fi
#fi

echo "load_versa_node -p1 -i $FW_FILE"
load_versa_node -p1 -i $FW_FILE
ret_code=$?
cd ${NIVIS_FIRMWARE}
if [ "$release" = "isa" ]; then
	backbone&
else if [ "$release" = "whart" ]; then
	whaccesspoint&
	fi
fi



if [ $ret_code -eq 0 ]; then
	echo "ER_RESULT=SUCCESS"
	log2flash "ER_RESULT=SUCCESS"
else	
	echo "ER_RESULT=ERROR loading error"
	log2flash "Versa Node upgrade loading error"	
fi

cd $old_path
rm -R  ${NIVIS_TMP}$DIR_UPGRADE

exit $ret_code