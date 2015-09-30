#!/bin/bash

if [ $# -eq 0 ]; then
  echo "usage: capture-iostat.bash <seconds-to-run> <seconds-between-checks> <log-file-name>"
  exit 1
fi

# time to run in seconds
RUN_TIME_SECONDS=${1}

# wait between checks
WAIT_TIME_SECONDS=${2}

# number of intervals
NUM_INTERVALS=$(($RUN_TIME_SECONDS / $WAIT_TIME_SECONDS))

LOG_NAME=${3}

# kill existing log file if it exists
rm -f ${LOG_NAME}

iostat -dxmt ${WAIT_TIME_SECONDS} ${NUM_INTERVALS} | tee ${LOG_NAME}
