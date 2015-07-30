#!/bin/sh

set +x 

. ${NIVIS_FIRMWARE}common.sh

DIR_UPGRADE=upgrade_wget/
FW_WGET_LINK=$1

old_path=`pwd`

if [ -z "$FW_WGET_LINK" ]; then
	cd $old_path
	echo "ER_RESULT=ERROR FW parameter missing"
	log2flash "FW parameter missing"	
	exit 1
fi 


cd $NIVIS_TMP
[ -d $DIR_UPGRADE ] && rm -R  $DIR_UPGRADE
mkdir $DIR_UPGRADE
cd $DIR_UPGRADE

wget $FW_WGET_LINK
if [ $? -ne 0 ]; then
	cd $old_path
	rm -R  ${NIVIS_TMP}$DIR_UPGRADE
	echo "ER_RESULT=ERROR WGET"
	log2flash "Upgrade ERROR WGET"
	exit 1
fi

FW_FILE=`ls -1 an_bin_*.tgz | tail -n 1`

if [ -z "$FW_FILE" ]; then
	cd $old_path
	rm -R  ${NIVIS_TMP}$DIR_UPGRADE
	echo "ER_RESULT=ERROR no FW_FILE"
	log2flash "Upgrade ERROR no FW_FILE"
	exit 1
fi


activate.sh --fw_file ${NIVIS_TMP}/${DIR_UPGRADE}/$FW_FILE --now > ${NIVIS_TMP}${DIR_UPGRADE}/act_out.txt


cat ${NIVIS_TMP}${DIR_UPGRADE}/act_out.txt

ret_code=0
cat ${NIVIS_TMP}${DIR_UPGRADE}/act_out.txt | grep -q "SetActive firmware ${fw_ver} already activated"

if [ $? -ne 0 ]; then
	cat ${NIVIS_TMP}${DIR_UPGRADE}/act_out.txt | grep -q "SetActive firmware .* done"
	ret_code=$?
	echo "Match done $ret_code"
fi	

if [ $ret_code -eq 0 ]; then
	echo "ER_RESULT=SUCCESS"
else
	echo "ER_RESULT=ERROR"
fi 

[ -d $old_path ] && cd $old_path || cd /access_node/

rm -R  ${NIVIS_TMP}$DIR_UPGRADE
exit $ret_code
