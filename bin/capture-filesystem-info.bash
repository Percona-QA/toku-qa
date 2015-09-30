#!/bin/bash

if [ $# -eq 0 ]; then
  echo "usage: capture-filesystem-info.bash <seconds-to-run> <seconds-between-checks> <data-directory> <mysql-user> <mysql-socket> <mysql-database> <storage-engine> <log-file-name>"
  exit 1
fi

RUN_TIME_SECONDS=$1
WAIT_TIME_SECONDS=$2
DB_DIR=$3
MYSQL_USER=$4
MYSQL_SOCKET=$5
MYSQL_DATABASE=$6
STORAGE_ENGINE=$7
LOG_NAME=$8

# kill existing log file if it exists
rm -f ${LOG_NAME}
echo "timestamp allocated_mb apparent_mb fractal_tot_mb fractal_free_mb fractal_frag_pct" >> ${LOG_NAME}

while [ ${RUN_TIME_SECONDS} -gt 0 ]; do
    DATE=`date +"%Y%m%d%H%M%S"`

    if [ ${STORAGE_ENGINE} == "tokudb" ]; then 
        SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
        SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
    else
        SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/${MYSQL_DATABASE} | tail -n 1 | cut -f1`
        SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/${MYSQL_DATABASE} | tail -n 1 | cut -f1`
    fi

    SIZE_MB=`echo "scale=2; ${SIZE_BYTES}/(1024*1024)" | bc `
    SIZE_APPARENT_MB=`echo "scale=2; ${SIZE_APPARENT_BYTES}/(1024*1024)" | bc `

    if [ ${STORAGE_ENGINE} == "tokudb" ]; then 
        FRAG_SQL_RESULT=`$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} -e "select sum(bt_size_allocated) / (1024 * 1024) as size_files_mb, (sum(bt_size_allocated) - sum(bt_size_in_use)) / (1024 * 1024) as size_free_mb, (1 - (sum(bt_size_in_use) / sum(bt_size_allocated))) * 100 as frag_perc from information_schema.tokudb_fractal_tree_info;"`
        FRAG_INFO=`echo $FRAG_SQL_RESULT | cut -d" " -f 4-6`
    else
        FT_SIZE_MB=0
        FT_FREE_MB=0
        FT_FRAG_PCT=0.0
    fi

    echo "${DATE} ${SIZE_MB} ${SIZE_APPARENT_MB} ${FRAG_INFO}" >> $LOG_NAME
    
    RUN_TIME_SECONDS=$(($RUN_TIME_SECONDS - $WAIT_TIME_SECONDS))
    sleep ${WAIT_TIME_SECONDS}
done
