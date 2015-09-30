#!/bin/bash

if [ $# -eq 0 ]; then
  echo "usage: capture-memory.bash <seconds-to-run> <seconds-between-checks> <log-file-name> <process-name>"
  exit 1
fi

# time to run in seconds
RUN_TIME_SECONDS=${1}

# wait between checks
WAIT_TIME_SECONDS=${2}

LOG_NAME=${3}

PROCESS_NAME=${4}

# kill existing log file if it exists
rm -f ${LOG_NAME}

CHECK_PID=`pgrep -u $USER -x ${PROCESS_NAME}`

while [ ${RUN_TIME_SECONDS} -gt 0 ]; do
    DATE=`date +"%Y%m%d%H%M%S"`
    CURRENT_INFO=`ps -o rss,vsz,pcpu ${CHECK_PID} | tail -n 1`
    echo "${DATE} ${CURRENT_INFO}" >> ${LOG_NAME}
    RUN_TIME_SECONDS=$(($RUN_TIME_SECONDS - $WAIT_TIME_SECONDS))
    sleep ${WAIT_TIME_SECONDS}
done
