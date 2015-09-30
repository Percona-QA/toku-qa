#!/bin/bash

# pick your storage engine (tokudb or innodb or innodb_compressed)
STORAGE_ENGINE=innodb


SOCKET_OPTION=--socket=/tmp/mysql.sock
DATABASE_NAME=tpcc
USER_NAME=root
USER_PASSWORD=
FILE_PATH=$BACKUP_DIR/tpcc-mysqldump-1000w
LOG_NAME=log-load-tpcc-flat-files.txt

rm $LOG_NAME

# Get time as a UNIX timestamp (seconds elapsed since Jan 1, 1970 0:00 UTC)
T="$(date +%s)"

echo "`date` : drop database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=$USER_NAME $SOCKET_OPTION -f drop $DATABASE_NAME

echo "`date` : create database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=$USER_NAME $SOCKET_OPTION create $DATABASE_NAME

echo "`date` : create tables" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME < tpcc-mysql/create_table_$STORAGE_ENGINE.sql

echo "`date` : load customer table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/customer.txt' into table customer fields terminated by ',' enclosed by '\"';"

echo "`date` : load district table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/district.txt' into table district fields terminated by ',' enclosed by '\"';"

echo "`date` : load history table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/history.txt' into table history fields terminated by ',' enclosed by '\"';"

echo "`date` : load item table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/item.txt' into table item fields terminated by ',' enclosed by '\"';"

echo "`date` : load new_orders table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/new_orders.txt' into table new_orders fields terminated by ',' enclosed by '\"';"

echo "`date` : load order_line table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/order_line.txt' into table order_line fields terminated by ',' enclosed by '\"';"

echo "`date` : load orders table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/orders.txt' into table orders fields terminated by ',' enclosed by '\"';"

echo "`date` : load stock table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/stock.txt' into table stock fields terminated by ',' enclosed by '\"';"

echo "`date` : load warehouse table" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/warehouse.txt' into table warehouse fields terminated by ',' enclosed by '\"';"

echo "`date` : add secondary indexes" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME < tpcc-mysql/add_idx.sql

echo "`date` : add foreign keys" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME < tpcc-mysql/add_fkey.sql

echo "`date` : done" | tee -a $LOG_NAME

T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

echo "`date` | loader checking TokuDB sizing = `du -ch ${DB_DIR}/data/*.tokudb           | tail -n 1`" | tee -a $LOG_NAME
echo "`date` | loader checking InnoDB sizing = `du -ch ${DB_DIR}/data/${DATABASE_NAME}   | tail -n 1`" | tee -a $LOG_NAME
