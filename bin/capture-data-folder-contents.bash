#!/bin/bash

if [ $# -eq 0 ]; then
  echo "usage: capture-data-folder-contents.bash <seconds-to-run> <seconds-between-checks> <log-file-name>"
  exit 1
fi

# time to run in seconds
RUN_TIME_SECONDS=${1}

# wait between checks
WAIT_TIME_SECONDS=${2}

LOG_NAME=${3}

# kill existing log file if it exists
rm -f ${LOG_NAME}

while [ ${RUN_TIME_SECONDS} -gt 0 ]; do
    DATE=`date +"%Y%m%d%H%M%S"`
    
    # make sure we have at least 1 loader file
    if ls ${DB_DIR}/data/tokuld* &> /dev/null; then
        USED=`du -ch ${DB_DIR}/data/tokuld* | tail -n 1`
        echo "${USED}" >> ${LOG_NAME}
    fi
    
    #echo "${DATE} ${USED}" >> ${LOG_NAME}
    # ls -lh ${DB_DIR}/data >> ${LOG_NAME}
    
    RUN_TIME_SECONDS=$(($RUN_TIME_SECONDS - $WAIT_TIME_SECONDS))
    sleep ${WAIT_TIME_SECONDS}
done
