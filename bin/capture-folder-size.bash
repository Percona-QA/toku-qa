#!/bin/bash

if [ $# -eq 0 ]; then
  echo "usage: capture-folder-size.bash <full-path> <seconds-to-run> <seconds-between-checks> <log-file-name>"
  exit 1
fi

# directory to check
DIRECTORY_TO_CHECK=${1}

# time to run in seconds
RUN_TIME_SECONDS=${2}

# wait between checks
WAIT_TIME_SECONDS=${3}

LOG_NAME=${4}

# kill existing log file if it exists
rm -f ${LOG_NAME}

while [ ${RUN_TIME_SECONDS} -gt 0 ]; do
    DATE=`date +"%Y%m%d%H%M%S"`
    USED=`du -cb ${DIRECTORY_TO_CHECK} | tail -n 1`
    echo "${DATE} ${USED}" >> ${LOG_NAME}
    
    RUN_TIME_SECONDS=$(($RUN_TIME_SECONDS - $WAIT_TIME_SECONDS))
    sleep ${WAIT_TIME_SECONDS}
done
