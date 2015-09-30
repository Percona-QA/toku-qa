#!/bin/bash

# pick your storage engine (tokudb or innodb or innodb_compressed)
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    echo "Need to set MYSQL_STORAGE_ENGINE"
    exit 1
fi
if [ -z "$MYSQL_SOCKET" ]; then
    echo "Need to set MYSQL_SOCKET"
    exit 1
fi
if [ -z "$LOADER_LOGGING" ]; then
    echo "Need to set LOADER_LOGGING"
    exit 1
fi
if [ -z "$MYSQL_DATABASE" ]; then
    echo "Need to set MYSQL_DATABASE"
    exit 1
fi
if [ -z "$MYSQL_USER" ]; then
    echo "Need to set MYSQL_USER"
    exit 1
fi

LOG_NAME=log-load-sysbench-flat-files.txt
rm -f $LOG_NAME

echo "mysql_storage_engine = $MYSQL_STORAGE_ENGINE" | tee -a $LOG_NAME
echo "mysql_socket = $MYSQL_SOCKET" | tee -a $LOG_NAME

rm -f ./loader1.log.done 
rm -f ./loader2.log.done


T="$(date +%s)"

echo "`date` | drop database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} -f drop ${MYSQL_DATABASE}

echo "`date` | create database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} create ${MYSQL_DATABASE}

echo "`date` | creating table sbtest1" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < create_schema_$MYSQL_STORAGE_ENGINE.sql

TABLE_NUM=2
while [ ${TABLE_NUM} -le ${NUM_TABLES} ]; do
    thisTable=sbtest${TABLE_NUM}
    echo "`date` | creating table ${thisTable}" | tee -a $LOG_NAME
    $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "create table ${thisTable} like sbtest1;"
    let TABLE_NUM=TABLE_NUM+1
done

echo "`date` | starting loader1" | tee -a $LOG_NAME
./run.load.flatfiles.loader1.sh &

echo "`date` | starting loader2" | tee -a $LOG_NAME
./run.load.flatfiles.loader2.sh &

echo "waiting for loaders to complete..." | tee -a $LOG_NAME

while ( [ ! -e "./loader1.log.done" ] || [ ! -e "./loader2.log.done" ] ); do
    sleep 15
    echo "waiting for loaders to complete..."
done

echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | complete loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

echo "" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
echo "Sizing Information" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME

currentDate=`date`

TOKUDB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
TOKUDB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
INNODB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/${MYSQL_DATABASE} | tail -n 1 | cut -f1`
INNODB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/${MYSQL_DATABASE} | tail -n 1 | cut -f1`

TOKUDB_SIZE_MB=`echo "scale=2; ${TOKUDB_SIZE_BYTES}/(1024*1024)" | bc `
TOKUDB_SIZE_APPARENT_MB=`echo "scale=2; ${TOKUDB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
INNODB_SIZE_MB=`echo "scale=2; ${INNODB_SIZE_BYTES}/(1024*1024)" | bc `
INNODB_SIZE_APPARENT_MB=`echo "scale=2; ${INNODB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `

echo "${currentDate} | loader TokuDB sizing (SizeMB / ASizeMB) = ${TOKUDB_SIZE_MB} / ${TOKUDB_SIZE_APPARENT_MB}" | tee -a $LOG_NAME
echo "${currentDate} | loader InnoDB sizing (SizeMB / ASizeMB) = ${INNODB_SIZE_MB} / ${INNODB_SIZE_APPARENT_MB}" | tee -a $LOG_NAME

bkill
