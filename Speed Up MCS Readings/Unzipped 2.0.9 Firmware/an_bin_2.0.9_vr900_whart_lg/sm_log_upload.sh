#! /bin/sh


LOG=${NIVIS_TMP}`basename $0`.log
UP_SCRIPT=/access_node/ftp_log_upload.sh

GetFileSize()
{
        ls -Ll $1 | tr -s ' ' | cut -f 5 -d ' '
}

log()
{
        echo -n "`date \"+%Y/%m/%d %T\"` " >> $LOG
        echo "$*" >> $LOG
}

# $1 file name
ftp_up_log()
{
		if [ ! -f $UP_SCRIPT ];	then
			log "Start upload script <$UP_SCRIPT> not present -> rm -f ${1}"
			rm -f ${1}
		fi
		

        #local log_name=${1}_`date +%Y_%m_%d_%H_%M_%S`
        local log_name=${1}
        local log_year=`date +%Y`



        echo "$log_name" | grep -q "_${log_year}_"
        if [ $? -ne 0 ]; then
                log_name=${1}_`date +%Y_%m_%d_%H_%M_%S`
                mv -f $1 $log_name              
        fi
        
        #mv -f $1 $log_name     
        log "Start upload $log_name"
        log `$UP_SCRIPT $log_name`      
}


FTP_INTERVAL=1800

DUMMY_LOGS="SystemManagerProcess.log"

last_sent=0

renice 5 -p $$

cd /tmp/
touch $LOG

while [ true ]; do

        if [ `GetFileSize $LOG` -gt 100000 ]; then
                mv $LOG ${LOG}.1
                touch $LOG
                ftp_up_log ${LOG}.1             
        fi
        
        crt_time=`date +%s`
        
        if [ $(($last_sent + ${FTP_INTERVAL})) -lt $crt_time ]; then    

                for log_file in $DUMMY_LOGS
                do              
                        cp $log_file ${log_file}.cp_tmp
                        ftp_up_log ${log_file}.cp_tmp
                done 
                
                last_sent=$crt_time
        fi
        
        log_files=`ls *.log.? 2>/dev/null`
        if [ -z "$log_files" ]; then
                log_files=`ls *.log_* 2>/dev/null`
                if [ -z "$log_files" ]; then
                        sleep 10
                        continue
                fi
        fi
        
        log "log files ready for upload: $log_files" 
        
        for log_file in $log_files
        do
             ftp_up_log $log_file
                 #ret_code=$?
                 #echo "ftpupload logfile $log_file ret_code=$?"
        done    
        
 done
               