#!/bin/bash

# pick your storage engine (tokudb or innodb or innodb_compressed)
MYSQL_STORAGE_ENGINE=innodb
NUM_ROWS=10000000
MYSQL_DATABASE=sbtest
MYSQL_USER=root

if [ -z "$MYSQL_SOCKET" ]; then
    echo "Need to set MYSQL_SOCKET"
    exit 1
fi

echo "mysql_storage_engine = $MYSQL_STORAGE_ENGINE"
echo "mysql_socket = $MYSQL_SOCKET"

echo "`date` | drop database"
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} -f drop ${MYSQL_DATABASE}

echo "`date` | create database"
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} create ${MYSQL_DATABASE}

echo "`date` | create tables"
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < create_schema_$MYSQL_STORAGE_ENGINE.sql


FILE_DIR=sysbench-mysqldump-${NUM_ROWS}

if [ -e "${LOCAL_BACKUP_DIR}/${FILE_DIR}/sbtest.txt" ]; then
    echo "using local filesystem"
    FULL_FILE_PATH=${LOCAL_BACKUP_DIR}/${FILE_DIR}/sbtest.txt
else
    echo "using nfs"
    FULL_FILE_PATH=${BACKUP_DIR}/${FILE_DIR}/sbtest.txt
fi

# Get time as a UNIX timestamp (seconds elapsed since Jan 1, 1970 0:00 UTC)
T="$(date +%s)"

#for TABLE_NUM in 1 2 3 4 5 6 7 8; do
for TABLE_NUM in 1 ; do
    echo "`date` | load sbtest${TABLE_NUM}"
    $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "load data infile '$FULL_FILE_PATH' into table sbtest${TABLE_NUM} fields terminated by ',' enclosed by '\"';"
done    

echo "`date` | done - loader"

T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

echo "`date` | loader checking TokuDB sizing = `du -ch ${DB_DIR}/data/*.tokudb           | tail -n 1`" | tee -a $LOG_NAME
echo "`date` | loader checking InnoDB sizing = `du -ch ${DB_DIR}/data/${MYSQL_DATABASE}   | tail -n 1`" | tee -a $LOG_NAME
