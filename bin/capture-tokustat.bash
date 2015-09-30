#!/bin/bash

if [ $# -eq 0 ]; then
  echo "usage: capture-tokustat.bash <seconds-between-samples> <mysql-user> <mysql-socket> <output-file-name>"
  exit 1
fi

WAIT_TIME_SECONDS=$1
MYSQL_USER=$2
MYSQL_PASSWORD=""
MYSQL_SOCKET=$3
LOG_NAME=$4

# kill existing log file if it exists
rm -f ${LOG_NAME}

# turn off python buffered output
export PYTHONUNBUFFERED=1

tokustat.py --host=${MYSQL_SOCKET} --user=${MYSQL_USER} --sleeptime=${WAIT_TIME_SECONDS} > ${LOG_NAME}
