#!/bin/bash

# pick your storage engine (tokudb or innodb)
STORAGE_ENGINE=tokudb

SOCKET_NAME=/tmp/mysql.sock
SOCKET_OPTION=--socket=${SOCKET_NAME}
DATABASE_NAME=sbtest
USER_NAME=root
USER_PASSWORD=""
FILE_PATH=$BACKUP_DIR/sysbench-mysqldump-16x50mm
LOG_NAME=log-load-sysbench-flat-files.txt

SHOW_ENGINE_STATUS_INTERVAL=60
SHOW_SYSINFO_INTERVAL=60
# do the logging for 24 hours, these need to be killed manually for now
LOG_TIME=86400

LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
capture-engine-status.bash $LOG_TIME $SHOW_ENGINE_STATUS_INTERVAL $USER_NAME $SOCKET_NAME $LOG_NAME_ENGINE_STATUS $STORAGE_ENGINE &
LOG_NAME_SYSINFO=${LOG_NAME}.sysinfo
capture-sysinfo.bash $LOG_TIME $SHOW_SYSINFO_INTERVAL $LOG_NAME_SYSINFO &

rm -f $LOG_NAME

date >> $LOG_NAME
echo "drop database" >> $LOG_NAME
echo "drop database"
mysqladmin --user=$USER_NAME $SOCKET_OPTION -f drop $DATABASE_NAME

date >> $LOG_NAME
echo "create database" >> $LOG_NAME
echo "create database"
mysqladmin --user=$USER_NAME $SOCKET_OPTION create $DATABASE_NAME

date >> $LOG_NAME
echo "create tables" >> $LOG_NAME
echo "create tables"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME < create_tables_$STORAGE_ENGINE.sql

date >> $LOG_NAME
echo "load sbtest1" >> $LOG_NAME
echo "sbtest1"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest1.txt' into table sbtest1 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest2" >> $LOG_NAME
echo "sbtest2"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest2.txt' into table sbtest2 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest3" >> $LOG_NAME
echo "sbtest3"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest3.txt' into table sbtest3 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest4" >> $LOG_NAME
echo "sbtest4"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest4.txt' into table sbtest4 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest5" >> $LOG_NAME
echo "sbtest5"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest5.txt' into table sbtest5 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest6" >> $LOG_NAME
echo "sbtest6"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest6.txt' into table sbtest6 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest7" >> $LOG_NAME
echo "sbtest7"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest7.txt' into table sbtest7 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest8" >> $LOG_NAME
echo "sbtest8"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest8.txt' into table sbtest8 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest9" >> $LOG_NAME
echo "sbtest9"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest9.txt' into table sbtest9 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest10" >> $LOG_NAME
echo "sbtest10"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest10.txt' into table sbtest10 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest11" >> $LOG_NAME
echo "sbtest11"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest11.txt' into table sbtest11 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest12" >> $LOG_NAME
echo "sbtest12"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest12.txt' into table sbtest12 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest13" >> $LOG_NAME
echo "sbtest13"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest13.txt' into table sbtest13 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest14" >> $LOG_NAME
echo "sbtest14"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest14.txt' into table sbtest14 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest15" >> $LOG_NAME
echo "sbtest15"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest15.txt' into table sbtest15 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "load sbtest16" >> $LOG_NAME
echo "sbtest16"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME -e "load data infile '$FILE_PATH/sbtest16.txt' into table sbtest16 fields terminated by ',' enclosed by '\"';"

date >> $LOG_NAME
echo "add secondary indexes" >> $LOG_NAME
echo "add secondary indexes"
mysql --user=$USER_NAME $SOCKET_OPTION $DATABASE_NAME < add_indexes.sql

date >> $LOG_NAME
echo "done" >> $LOG_NAME
echo "done"
