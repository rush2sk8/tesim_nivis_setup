#!/bin/sh

set +x

. /etc/profile

. ${NIVIS_FIRMWARE}common.sh

DIR_UPGRADE=upgrade_web/

old_path=`pwd`

if [ ! -d ${NIVIS_TMP}$DIR_UPGRADE ]; then
	echo "ER_RESULT=ERROR no upload folder"
	log2flash "Upgrade ERROR no upload folder"
	exit 1
fi

cd ${NIVIS_TMP}$DIR_UPGRADE

FW_FILE=`ls -1 an_bin_*.tgz | tail -n 1`

if [ -z $FW_FILE ]; then
	tmp_var=`ls`
	echo "ER_RESULT=ERROR no FW_FILE (expected FW name an_bin_*.tgz)"
	echo "Uploaded files: $tmp_var"
	log2flash "Upgrade ERROR no FW_FILE (expected FW name an_bin_*.tgz)"		
	log2flash "Uploaded Files: $tmp_var"
	cd $old_path
	exit 1
fi

stop.sh exc_web	#reduce the load for a faster upgrade
#TAKE CARE: do not use --now option, it breaks the answer in browser and the upgrade is attempted twice
activate.sh --fw_file ${NIVIS_TMP}${DIR_UPGRADE}$FW_FILE > ${NIVIS_TMP}${DIR_UPGRADE}/act_out.txt

cat ${NIVIS_TMP}${DIR_UPGRADE}/act_out.txt

if [ "$1" = "reset_db" ]; then # remove DB; it will be replaced by .fixture found in new firmware
    echo "MH DB Reset"
    log2flash "MH DB Reset"
    rm ${NIVIS_ACTIVITY_FILES}/Monitor_Host.db3
    rm ${NIVIS_TMP}/Monitor_Host.db3 
fi

cat ${NIVIS_TMP}${DIR_UPGRADE}/act_out.txt | grep -q "SetActive firmware .* done"

ret_code=$?

if [ $ret_code -eq 0 ]; then
	echo "ER_RESULT=SUCCESS"
else
	echo "ER_RESULT=ERROR at activate.sh"
	sleep 2	# activation failed... start the modules back closing the fd's and leaving a small time to respond
	{ exec 1>&- ; exec 2>&- ; sleep 30 && start.sh > /dev/null 2>&1; } &

fi 

cd $old_path
rm -R  ${NIVIS_TMP}$DIR_UPGRADE

exit $ret_code
