#!/bin/bash

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

export MYSQL_STORAGE_ENGINE=tokudb
export MYSQL_USER=root
export MYSQL_DATABASE=test
export BENCHMARK_LOGGING=Y
export MAX_IPS=-1
COMMIT_SYNC=0
UNIQUE_CHECKS=1
ROWS_PER_REPORT=1000000

# first run, prior to upgrade
#MAX_ROWS=100
#RUN_MINUTES=1
#LOG_NAME=iibench-tiny-1.log
#rm -f $LOG_NAME
#python iibench.py --setup --db_socket=${MYSQL_SOCKET} --db_name=${MYSQL_DATABASE} --max_rows=${MAX_ROWS} --rows_per_report=${ROWS_PER_REPORT} --engine=${MYSQL_STORAGE_ENGINE} --insert_only --unique_checks=${UNIQUE_CHECKS} --run_minutes=${RUN_MINUTES} --tokudb_commit_sync=${COMMIT_SYNC} --max_ips=${MAX_IPS} ${IIBENCH_EXTRA_ARGS} | tee ${LOG_NAME}

# second run, no --setup and run much longer
 MAX_ROWS=1000000000
 RUN_MINUTES=600
 LOG_NAME=iibench-tiny-2.log
 rm -f $LOG_NAME
 python iibench.py --db_socket=${MYSQL_SOCKET} --db_name=${MYSQL_DATABASE} --max_rows=${MAX_ROWS} --rows_per_report=${ROWS_PER_REPORT} --engine=${MYSQL_STORAGE_ENGINE} --insert_only --unique_checks=${UNIQUE_CHECKS} --run_minutes=${RUN_MINUTES} --tokudb_commit_sync=${COMMIT_SYNC} --max_ips=${MAX_IPS} ${IIBENCH_EXTRA_ARGS} | tee ${LOG_NAME}
