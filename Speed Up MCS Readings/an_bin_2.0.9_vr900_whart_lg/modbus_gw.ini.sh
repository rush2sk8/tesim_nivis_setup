#! /bin/sh

. common.sh

mv "${NIVIS_TMP}/upgrade_web/`basename $0 | sed -e s/\.sh$//g`"  ${NIVIS_PROFILE}
