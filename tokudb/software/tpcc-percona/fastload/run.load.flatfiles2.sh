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
if [ -z "$NUM_WAREHOUSES" ]; then
    echo "Need to set NUM_WAREHOUSES"
    exit 1
fi

FILE_PATH=tpcc-mysqldump-${NUM_WAREHOUSES}w
if [ -d "${LOCAL_BACKUP_DIR}/${FILE_PATH}" ]; then
    echo "using local filesystem"
    FILE_PATH=${LOCAL_BACKUP_DIR}/${FILE_PATH}
else
    echo "using nfs"
    FILE_PATH=${BACKUP_DIR}/${FILE_PATH}
fi
echo "loader 1 : loading from ${FILE_PATH}"

LOG_NAME=log-load-tpcc-flat-files-2.txt
DONE_NAME=${LOG_NAME}.done

rm -f $LOG_NAME
rm -rf $DONE_NAME

# Get time as a UNIX timestamp (seconds elapsed since Jan 1, 1970 0:00 UTC)
T="$(date +%s)"

echo "`date` : load order_line table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} -e "load data infile '$FILE_PATH/order_line.txt' into table order_line fields terminated by ',' enclosed by '\"';"

echo "`date` : load orders table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} -e "load data infile '$FILE_PATH/orders.txt' into table orders fields terminated by ',' enclosed by '\"';"

echo "`date` : done - loader 2" | tee -a $LOG_NAME

T="$(($(date +%s)-T))"
printf "`date` | loader 2 duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

touch ${DONE_NAME}