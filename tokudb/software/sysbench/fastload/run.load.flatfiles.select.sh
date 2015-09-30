#!/bin/bash

# pick your storage engine (tokudb or innodb or innodb_compressed)
STORAGE_ENGINE=tokudb

MYSQL_SOCKET=$MYSQL_SOCKET
DATABASE_NAME=sbtest
USER_NAME=root
USER_PASSWORD=""
FILE_PATH=$BACKUP_DIR/sysbench-mysqldump-25mm
LOG_NAME=log-load-sysbench-flat-files.txt

rm -rf $LOG_NAME


echo "`date` | drop database"
$DB_DIR/bin/mysqladmin --user=$USER_NAME --socket=$MYSQL_SOCKET -f drop $DATABASE_NAME

echo "`date` | create database"
$DB_DIR/bin/mysqladmin --user=$USER_NAME --socket=$MYSQL_SOCKET create $DATABASE_NAME

echo "`date` | create tables"
$DB_DIR/bin/mysql      --user=$USER_NAME --socket=$MYSQL_SOCKET $DATABASE_NAME < create_schema_$STORAGE_ENGINE.sql

echo "`date` | load sbtest1" | tee -a $LOG_NAME
$DB_DIR/bin/mysql --user=$USER_NAME --socket=$MYSQL_SOCKET $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest.txt' into table sbtest1 fields terminated by ',' enclosed by '\"';"

for TABLE_NUM in 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do
    echo "`date` | load sbtest${TABLE_NUM} as select * from sbtest1" | tee -a $LOG_NAME
    $DB_DIR/bin/mysql --user=$USER_NAME --socket=$MYSQL_SOCKET $DATABASE_NAME -e "insert into sbtest${TABLE_NUM} select * from sbtest1;"
done    

echo "`date` | done" | tee -a $LOG_NAME
