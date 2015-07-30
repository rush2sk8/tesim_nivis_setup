#! /bin/sh

EMPTY_LOGO_DIR="/access_node/firmware/www/wwwroot/app/styles/images/logo/"
CUSTOM_LOGO_DIR="/access_node/firmware/www/wwwroot/app/styles/images/"

PRODUCT="ProductLogo.png"
COMPANY="CompanyLogo.png"
TECHNOLOGY="TechnologyLogo.png"

if [ "$1" == "true" ];then
  mv "${CUSTOM_LOGO_DIR}${PRODUCT}" "${EMPTY_LOGO_DIR}${PRODUCT}TEMP"
  mv "${EMPTY_LOGO_DIR}${PRODUCT}" "${CUSTOM_LOGO_DIR}${PRODUCT}"
  mv "${EMPTY_LOGO_DIR}${PRODUCT}TEMP" "${EMPTY_LOGO_DIR}${PRODUCT}"
fi

if [ "$2" == "true" ];then
  mv "${CUSTOM_LOGO_DIR}${COMPANY}" "${EMPTY_LOGO_DIR}${COMPANY}TEMP"
  mv "${EMPTY_LOGO_DIR}${COMPANY}" "${CUSTOM_LOGO_DIR}${COMPANY}"
  mv "${EMPTY_LOGO_DIR}${COMPANY}TEMP" "${EMPTY_LOGO_DIR}${COMPANY}"
fi

if [ "$3" == "true" ];then
  mv "${CUSTOM_LOGO_DIR}${TECHNOLOGY}" "${EMPTY_LOGO_DIR}${TECHNOLOGY}TEMP"
  mv "${EMPTY_LOGO_DIR}${TECHNOLOGY}" "${CUSTOM_LOGO_DIR}${TECHNOLOGY}"
  mv "${EMPTY_LOGO_DIR}${TECHNOLOGY}TEMP" "${EMPTY_LOGO_DIR}${TECHNOLOGY}"
fi

if [ $# -gt 3 ];then

  if [ ! -f "/tmp/upgrade_web/$4" ];then
        echo "No such file:[$4]"
        return 1
  fi

  fsize="`ls -l "/tmp/upgrade_web/$4" | tr -s ' ' | cut -d ' ' -f 5`"
  if [ ${fsize} -gt 10240 ]; then
        echo "Image bigger than 10kB"
        return 2
  fi

  if [ $5 = "true" ]; then
       echo "move to custom"
        mv "/tmp/upgrade_web/$4" "${CUSTOM_LOGO_DIR}${COMPANY}"
  else
      echo "move to empty"
        mv "/tmp/upgrade_web/$4" "${EMPTY_LOGO_DIR}${COMPANY}"
  fi

fi
