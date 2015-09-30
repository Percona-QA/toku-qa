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

LOG_NAME=log-load-tpcc-flat-files.txt
rm -f $LOG_NAME

# do the logging for 24 hours, these need to be killed manually for now
LOG_TIME=172800
SHOW_ENGINE_STATUS_INTERVAL=60
SHOW_SYSINFO_INTERVAL=60
IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[LOG_TIME/IOSTAT_INTERVAL+1]
DSTAT_INTERVAL=10
DSTAT_ROUNDS=$[LOG_TIME/DSTAT_INTERVAL+1]

if [ ${LOADER_LOGGING} == "Y" ]; then
    # verbose logging
    echo "*** verbose loader logging enabled ***"
    capture-engine-status.bash $LOG_TIME $SHOW_ENGINE_STATUS_INTERVAL ${MYSQL_USER} ${MYSQL_SOCKET} ${LOG_NAME}.engine_status $MYSQL_STORAGE_ENGINE &
    capture-sysinfo.bash $LOG_TIME $SHOW_SYSINFO_INTERVAL ${LOG_NAME}.sysinfo &
    iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > ${LOG_NAME}.iostat &
    dstat -t -v --nocolor --output ${LOG_NAME}.dstat.csv $DSTAT_INTERVAL $DSTAT_ROUNDS > ${LOG_NAME}.dstat &
fi


# Get time as a UNIX timestamp (seconds elapsed since Jan 1, 1970 0:00 UTC)
T="$(date +%s)"

echo "`date` : drop database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} -f drop ${MYSQL_DATABASE}

echo "`date` : create database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} create ${MYSQL_DATABASE}

if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "`date` : create innodb tables" | tee -a $LOG_NAME
    if [ ${INNODB_COMPRESSION} == "Y" ]; then
        echo "`date` : innodb compression enabled, key_block_size=${INNODB_KEY_BLOCK_SIZE}" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < create_schema_${MYSQL_STORAGE_ENGINE}_${INNODB_KEY_BLOCK_SIZE}.sql
    else
        echo "`date` : innodb compression disabled" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < create_schema_${MYSQL_STORAGE_ENGINE}.sql
    fi
else
    echo "`date` : create tokudb tables and indexes" | tee -a $LOG_NAME
    $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < create_schema_${MYSQL_STORAGE_ENGINE}.sql
fi

./run.load.flatfiles2.sh &

echo "`date` : load customer table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} -e "load data infile '$FILE_PATH/customer.txt' into table customer fields terminated by ',' enclosed by '\"';"

echo "`date` : load district table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} -e "load data infile '$FILE_PATH/district.txt' into table district fields terminated by ',' enclosed by '\"';"

echo "`date` : load history table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} -e "load data infile '$FILE_PATH/history.txt' into table history fields terminated by ',' enclosed by '\"';"

echo "`date` : load item table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} -e "load data infile '$FILE_PATH/item.txt' into table item fields terminated by ',' enclosed by '\"';"

echo "`date` : load new_orders table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} -e "load data infile '$FILE_PATH/new_orders.txt' into table new_orders fields terminated by ',' enclosed by '\"';"

echo "`date` : load stock table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} -e "load data infile '$FILE_PATH/stock.txt' into table stock fields terminated by ',' enclosed by '\"';"

echo "`date` : load warehouse table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} -e "load data infile '$FILE_PATH/warehouse.txt' into table warehouse fields terminated by ',' enclosed by '\"';"

echo "waiting for loader 2 to complete..."

while ( [ ! -e "./log-load-tpcc-flat-files-2.txt.done" ] ); do
    sleep 60
    echo "waiting for loader 2 to complete..."
done

if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    echo "`date` : creating innodb indexes" | tee -a $LOG_NAME
    $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < innodb_add_idx.sql
    
    if [ ${INNODB_FK} == "Y" ]; then
        echo "`date` : innodb FK support enabled, adding foreign keys" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < innodb_add_fkey.sql
    else
        echo "`date` : innodb FK support disabled, adding as indexes" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < innodb_add_fkey_as_idx.sql
    fi
fi

echo "`date` : done - loader 1" | tee -a $LOG_NAME

T="$(($(date +%s)-T))"
printf "`date` | loader 1 duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

echo "`date` | loader 1 checking TokuDB sizing = `du -ch ${DB_DIR}/data/*.tokudb           | tail -n 1`" | tee -a $LOG_NAME
echo "`date` | loader 1 checking InnoDB sizing = `du -ch ${DB_DIR}/data/${MYSQL_DATABASE}   | tail -n 1`" | tee -a $LOG_NAME

bkill
