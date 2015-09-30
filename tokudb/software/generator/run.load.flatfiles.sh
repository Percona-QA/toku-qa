#!/bin/sh

# pick your storage engine (tokudb or innodb)
STORAGE_ENGINE=tokudb

SOCKET_NAME=/tmp/mysql.sock
SOCKET_OPTION=--socket=${SOCKET_NAME}
DATABASE_NAME=test
USER_NAME=root
USER_PASSWORD=""
FILE_PATH=$BACKUP_DIR
LOG_NAME=log-load-flat-files.txt

rm -f $LOG_NAME

date | tee -a $LOG_NAME
echo "create table" | tee -a $LOG_NAME
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME < create_tables_$STORAGE_ENGINE.sql

date | tee -a $LOG_NAME
echo "load table" | tee -a $LOG_NAME
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/stats_data.csv' into table tmc_plan_test fields terminated by ',' enclosed by '\"';"

date | tee -a $LOG_NAME
echo "done" | tee -a $LOG_NAME
