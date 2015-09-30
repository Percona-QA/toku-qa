#! /bin/bash

export NUM_TABLES=16
export NUM_ROWS=1000000
export MYSQL_STORAGE_ENGINE=tokudb
export MYSQL_DATABASE=sbtest
export MYSQL_USER=root
export MYSQL_SOCKET=/tmp/tmc.sock
export MYSQL_PASSWORD=
export PARALLEL_TRICKLE_LOADERS=8
export SYSBENCH_DIR=$PWD/sysbench-0.5/sysbench
export DB_DIR=$DB_DIR
export LOG_NAME=timbo.log

$DB_DIR/bin/mysql -S ${MYSQL_SOCKET} -u ${MYSQL_USER} --password=${MYSQL_PASSWORD} -e "drop database if exists ${MYSQL_DATABASE}; create database ${MYSQL_DATABASE};"

# parallel trickle loaders
sysbench --test=${SYSBENCH_DIR}/tests/db/parallel_prepare.lua --mysql-table-engine=${MYSQL_STORAGE_ENGINE} --oltp_tables_count=${NUM_TABLES} --oltp-table-size=${NUM_ROWS} --mysql-socket=${MYSQL_SOCKET} --mysql-user=${MYSQL_USER} --mysql-password=${MYSQL_PASSWORD} --num_threads=${PARALLEL_TRICKLE_LOADERS} run | tee -a ${LOG_NAME}



T="$(date +%s)"
echo "`date` | flushing logs and tables" | tee -a ${LOG_NAME}
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} -e "flush logs; flush tables;" | tee -a ${LOG_NAME}
T="$(($(date +%s)-T))"
printf "`date` | flush logs and tables duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a ${LOG_NAME}

echo "" | tee -a $LOG_NAME
echo "" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
echo "Final Sizing Information" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME

currentDate=`date`

TOKUDB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
TOKUDB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`

TOKUDB_SIZE_MB=`echo "scale=2; ${TOKUDB_SIZE_BYTES}/(1024*1024)" | bc `
TOKUDB_SIZE_APPARENT_MB=`echo "scale=2; ${TOKUDB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `

echo "${currentDate} | post-benchmark TokuDB sizing (SizeMB / ASizeMB) = ${TOKUDB_SIZE_MB} / ${TOKUDB_SIZE_APPARENT_MB}" | tee -a $LOG_NAME

mysql-show-frag ${MYSQL_USER} ${MYSQL_SOCKET} | tee -a $LOG_NAME
