#/bin/bash

export RUN_MINUTES=60
export INSERT_ONLY=1
export UNIQUE_CHECKS=1
export MAX_ROWS=100000000
export MAX_TABLE_ROWS=$MAX_ROWS
export ROWS_PER_REPORT=1000000
export MYSQL_DATABASE=test
export MYSQL_SOCKET=/tmp/mysql.sock
export MYSQL_STORAGE_ENGINE=wiredtiger

LOG_NAME=~/temp/iibench-wiredtiger.log
rm -f ${LOG_NAME}


if [ ${INSERT_ONLY} -eq 1 ]; then
    BENCHMARK_NAME=iibench
    IIBENCH_QUERY_PARM="--insert_only"
else
    BENCHMARK_NAME=iibench.queries
    IIBENCH_QUERY_PARM=""
fi


python iibench.py --setup --db_socket=${MYSQL_SOCKET} --db_name=${MYSQL_DATABASE} --max_rows=${MAX_ROWS} \
                  --max_table_rows=${MAX_TABLE_ROWS} --rows_per_report=${ROWS_PER_REPORT} --engine=${MYSQL_STORAGE_ENGINE} \
                  ${IIBENCH_QUERY_PARM} --unique_checks=${UNIQUE_CHECKS} --run_minutes=${RUN_MINUTES} | tee ${LOG_NAME}
