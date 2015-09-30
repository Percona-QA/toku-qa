#!/bin/bash

if [ -z "$MYSQL_SOCKET" ]; then
    echo "Need to set MYSQL_SOCKET"
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
if [ -z "$NUM_ROWS" ]; then
    echo "Need to set NUM_ROWS"
    exit 1
fi
if [ -z "$NUM_TABLES" ]; then
    echo "Need to set NUM_TABLES"
    exit 1
fi

FILE_DIR=sysbench-mysqldump-${NUM_ROWS}

if [ -e "${LOCAL_BACKUP_DIR}/${FILE_DIR}/sbtest.txt" ]; then
    echo "using local filesystem"
    FULL_FILE_PATH=${LOCAL_BACKUP_DIR}/${FILE_DIR}/sbtest.txt
else
    echo "using nfs"
    FULL_FILE_PATH=${BACKUP_DIR}/${FILE_DIR}/sbtest.txt
fi
LOG_NAME=loader1.log
DONE_NAME=${LOG_NAME}.done

rm -rf $LOG_NAME
rm -rf $DONE_NAME

# Get time as a UNIX timestamp (seconds elapsed since Jan 1, 1970 0:00 UTC)
T="$(date +%s)"

TABLE_NUM=1
while [ ${TABLE_NUM} -le ${NUM_TABLES} ]; do
    EVEN_TEST=$[ ${TABLE_NUM} % 2 ]
    if [ ${EVEN_TEST} -eq 0 ]; then
        echo "`date` | load sbtest${TABLE_NUM}" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "load data infile '$FULL_FILE_PATH' into table sbtest${TABLE_NUM} fields terminated by ',' enclosed by '\"';"
    fi
    let TABLE_NUM=TABLE_NUM+1
done

echo "`date` | done - loader 1" | tee -a $LOG_NAME

T="$(($(date +%s)-T))"
printf "`date` | loader 1 duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

touch ${DONE_NAME}