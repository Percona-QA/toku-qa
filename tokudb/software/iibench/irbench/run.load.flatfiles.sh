#!/bin/bash

# pick your storage engine (tokudb or innodb)
STORAGE_ENGINE=tokudb

SOCKET_NAME=/tmp/mysql.sock
SOCKET_OPTION=--socket=${SOCKET_NAME}
DATABASE_NAME=test
USER_NAME=root
USER_PASSWORD=""
FILE_PATH=$BACKUP_DIR/iibench-mysqldump-1bn
LOG_NAME=log-load-sysbench-flat-files.txt

rm -f $LOG_NAME

date | tee -a $LOG_NAME
echo "create purchases_index" | tee -a $LOG_NAME
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME < create_tables_$STORAGE_ENGINE.sql

date | tee -a $LOG_NAME
echo "load purchases_index" | tee -a $LOG_NAME
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/purchases_index.txt' into table purchases_index fields terminated by ',' enclosed by '\"';"

date | tee -a $LOG_NAME
echo "add secondary indexes" | tee -a $LOG_NAME
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME < add_indexes.sql

date | tee -a $LOG_NAME
echo "done" | tee -a $LOG_NAME
