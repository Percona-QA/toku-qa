#!/bin/sh

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ ! -d "$DB_DIR" ]; then
    echo "Need to create directory DB_DIR"
    exit 1
fi
if [ -z "$MACHINE_NAME" ]; then
    echo "Need to set MACHINE_NAME"
    exit 1
fi
if [ -z "$MYSQL_SOCKET" ]; then
    echo "Need to set MYSQL_SOCKET"
    exit 1
fi
if [ -z "$MYSQL_PORT" ]; then
    echo "Need to set MYSQL_PORT"
    exit 1
fi

export STORAGE_ENGINE=tokudb

MYSQL_SOCKET=$MYSQL_SOCKET
DATABASE_NAME=test
USER_NAME=root
USER_PASSWORD=""

date
echo "create table : using engine=${STORAGE_ENGINE}"
$DB_DIR/bin/mysql --user=$USER_NAME --socket=$MYSQL_SOCKET $DATABASE_NAME < schema_$STORAGE_ENGINE.sql

RUN_MINUTES=100000
RUN_SECONDS=$[RUN_MINUTES*60]
SHOW_ENGINE_STATUS_INTERVAL=60
SHOW_SYSINFO_INTERVAL=60
IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[RUN_SECONDS/IOSTAT_INTERVAL+1]
DSTAT_INTERVAL=10
DSTAT_ROUNDS=$[RUN_SECONDS/DSTAT_INTERVAL+1]

export LOG_NAME=${MACHINE_NAME}-${STORAGE_ENGINE}-iibench.txt
LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
LOG_NAME_SYSINFO=${LOG_NAME}.sysinfo
LOG_NAME_IOSTAT=${LOG_NAME}.iostat
LOG_NAME_DSTAT=${LOG_NAME}.dstat
LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv

iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &

ant clean default run

sleep 15

bkill
