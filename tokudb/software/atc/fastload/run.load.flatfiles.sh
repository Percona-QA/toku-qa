#!/bin/bash

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
if [ -z "$LOG_NAME" ]; then
    echo "Need to set LOG_NAME"
    exit 1
else
    echo "Logging to file $LOG_NAME"
fi

echo "mysql_storage_engine = $MYSQL_STORAGE_ENGINE" | tee -a $LOG_NAME
echo "mysql_socket = $MYSQL_SOCKET" | tee -a $LOG_NAME

echo "`date` | drop database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} -f drop ${MYSQL_DATABASE}

echo "`date` | create database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} create ${MYSQL_DATABASE}

echo "`date` | create tables" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < atc_ontime_create_covered_$MYSQL_STORAGE_ENGINE.sql


FILE_DIR=atc
if [ -z "$FILE_NAME" ]; then
    FILE_NAME=atc.csv
fi

echo "`date` | load file is named $FILE_NAME" | tee -a $LOG_NAME

if [ -e "${LOCAL_BACKUP_DIR}/${FILE_DIR}/${FILE_NAME}" ]; then
    echo "`date` | using local filesystem" | tee -a $LOG_NAME
    FULL_FILE_PATH=${LOCAL_BACKUP_DIR}/${FILE_DIR}/${FILE_NAME}
else
    echo "`date` | using nfs" | tee -a $LOG_NAME
    FULL_FILE_PATH=${BACKUP_DIR}/${FILE_DIR}/${FILE_NAME}
fi

T="$(date +%s)"

echo "`date` | starting load of $FILE_NAME into table ontime" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "load data infile '$FULL_FILE_PATH' into table ontime;"
echo "`date` | done - loader" | tee -a $LOG_NAME

T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

# calculate rows per second
ROWS_PER_SECOND=`echo "scale=2; ${ROW_COUNT}/${T}" | bc `
printf "`date` | rows loaded per second = %'.1f\n" "${ROWS_PER_SECOND}" | tee -a $LOG_NAME

if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    INNODB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/${MYSQL_DATABASE}*/*.ibd | tail -n 1 | cut -f1`
    INNODB_SIZE_MB=`echo "scale=2; ${INNODB_SIZE_BYTES}/(1024*1024)" | bc `
    echo "${currentDate} | loader InnoDB sizing = ${INNODB_SIZE_MB} MB" | tee -a $LOG_NAME
else
    TOKUDB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
    TOKUDB_SIZE_MB=`echo "scale=2; ${TOKUDB_SIZE_BYTES}/(1024*1024)" | bc `
    echo "`date` | loader TokuDB sizing = ${TOKUDB_SIZE_MB} MB" | tee -a $LOG_NAME
fi