#!/bin/bash

# time to run in seconds
RUN_TIME_SECONDS=$1

# wait between checks
WAIT_TIME_SECONDS=$2

MYSQL_USER=$3
MYSQL_PASSWORD=""
MYSQL_SOCKET=$4
LOG_NAME=$5
ENGINE_NAME=$6

# kill existing log file if it exists
rm -f $LOG_NAME

while [ $RUN_TIME_SECONDS -gt 0 ]; do
    echo "******************************" >> $LOG_NAME
    date >> $LOG_NAME
    echo "******************************" >> $LOG_NAME
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show processlist;" >> $LOG_NAME
    RUN_TIME_SECONDS=$(($RUN_TIME_SECONDS - $WAIT_TIME_SECONDS))
    sleep $WAIT_TIME_SECONDS
done
