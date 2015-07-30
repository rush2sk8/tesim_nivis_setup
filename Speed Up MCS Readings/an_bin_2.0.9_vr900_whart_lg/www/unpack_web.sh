#! /bin/sh
# Unpack a tgz or a tar.gz to el_app directory,
# then update the firmware links so the website points to the new pages
# we need app to be a link outside firmware so a firmware upgrade does not delete the site

LOGFILE='/tmp/upload.log'

#temporary web directory
TWEBD="/tmp/upgrade_web"
echo "Unpacking" > ${LOGFILE}

#web application directory
WAPPD="/access_node/wwwroot/app"
WAPPDTMP="${WAPPD}.tmp"

# http application directory - will be a link
LAPPD="/access_node/firmware/www/wwwroot/app"

rm -rf ${WAPPDTMP}
mkdir -p ${WAPPDTMP}
cd ${WAPPDTMP} 2>> ${LOGFILE}

#unpack the new file
tar xzvf ${TWEBD}/*gz 2>> ${LOGFILE}
if [ "$?" != "0" ]; then
	echo "tar failed" >> ${LOGFILE}
	echo "ER_RESULT=ERROR" >> ${LOGFILE}
	rm -rf ${TWEBD} 2>> ${LOGFILE}
	rm -rf ${WAPPDTMP} 2>> ${LOGFILE}
	exit 0
fi



#all done with the archive, remove it
rm -rf ${TWEBD} 2>> ${LOGFILE}

#remove old pages
rm -rf ${WAPPD} 2>> ${LOGFILE}

#use the newly extracted pages
mv ${WAPPDTMP} ${WAPPD} 2>> ${LOGFILE}

#update the link
ln -sf ${WAPPD} ${LAPPD} 2>> ${LOGFILE}
if [ $? -eq 0 ]; then 
	echo "ER_RESULT=SUCCESS" >> ${LOGFILE}
else
	echo "ER_RESULT=ERROR" >> ${LOGFILE}
fi

#in case something bad happens
rm -rf ${WAPPDTMP} 2>> ${LOGFILE}
