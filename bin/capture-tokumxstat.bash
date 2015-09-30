#!/bin/bash

if [ $# -eq 0 ]; then
  echo "usage: capture-tokumxstat.bash <seconds-between-samples> <output-file-name>"
  exit 1
fi

WAIT_TIME_SECONDS=$1
LOG_NAME=$2

# kill existing log file if it exists
rm -f ${LOG_NAME}

# turn off python buffered output
export PYTHONUNBUFFERED=1

$MONGO_DIR/scripts/tokumxstat.py --sleeptime=${WAIT_TIME_SECONDS} > ${LOG_NAME}
