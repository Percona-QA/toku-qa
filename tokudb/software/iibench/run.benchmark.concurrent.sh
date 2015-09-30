#!/bin/bash

sleep ${1}

THIS_RUN_MINUTES=$[RUN_MINUTES-1]

CLIENT_NUM=1
while [ ${CLIENT_NUM} -le ${2} ]; do
    LOG_NAME=${MACHINE_NAME}-${MYSQL_NAME}-${MYSQL_VERSION}-${MYSQL_STORAGE_ENGINE}-${BENCH_ID}-iibench-$COMMIT_SYNC-UNIQUE_CHECKS=${UNIQUE_CHECKS}.${CLIENT_NUM}.txt
    rm -f $LOG_NAME

    python iibench.py --db_socket=${MYSQL_SOCKET} --db_name=${MYSQL_DATABASE} --max_rows=${MAX_ROWS} --max_table_rows=${MAX_TABLE_ROWS} --rows_per_report=${ROWS_PER_REPORT} --engine=${MYSQL_STORAGE_ENGINE} --insert_only --unique_checks=${UNIQUE_CHECKS} --run_minutes=${THIS_RUN_MINUTES} --tokudb_commit_sync=${COMMIT_SYNC} --max_ips=${MAX_IPS} ${IIBENCH_EXTRA_ARGS} > ${LOG_NAME} &

    let CLIENT_NUM=CLIENT_NUM+1
done
