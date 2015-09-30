#!/bin/sh

#RUN_TIME is measured in seconds
#RUN_TIME=3600
#NUM_ROWS=50000000
#NUM_TABLES=16
#REPORT_INTERVAL=10
#SHOW_ENGINE_STATUS_INTERVAL=60
#SHOW_SYSINFO_INTERVAL=60
#IOSTAT_INTERVAL=10
#IOSTAT_ROUNDS=$[RUN_TIME/IOSTAT_INTERVAL+1]
#DSTAT_INTERVAL=10
#DSTAT_ROUNDS=$[RUN_TIME/DSTAT_INTERVAL+1]

MYSQL_SOCKET=/tmp/mysql.sock
MYSQL_USER=root
MYSQL_PASSWORD=""
ENGINE=tokudb
DBNAME=linkdb

LOG_SERVER_TYPE=mm
LOG_DB_NAME=mysql
LOG_DB_VERSION=5.1.52
LOG_ENGINE_VERSION=527.38674
LOG_BENCHMARK_NAME=linkbench
COMMIT_SYNC=1

javac com/facebook/LinkBench/*.java

# create database and tables
#mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET < ddl_${ENGINE}.sql

# optional load optimizations
#alter table linktable drop key `id2_vis`, drop key `id1_type`;
#set global innodb_flush_log_at_trx_commit = 2;
#set global sync_binlog = 0;

# LOAD DATA . takes about ????? seconds.
#java com.facebook.LinkBench.LinkBenchDriver com/facebook/LinkBench/LinkConfigMysql.properties 1 | tee $LOG_NAME

# You will see last line of output like this
#LOAD PHASE COMPLETED. Expected to load 49999998 links. 49990000 loaded in 5057 seconds.Links/second = 9884

# Check size of ibd files (total should be close to 10G approx)
#ls -l /data/mysql/linkdb/linktable.ibd
#ls -l /data/mysql/linkdb/counttable.ibd

# REVERT THE OPTIMIZATIONS DONE FOR LOAD
#set global innodb_flush_log_at_trx_commit = 1;
#set global sync_binlog = 1;
# this takes about 48 minutes
#alter table linktable add key `id2_vis` (`id2`,`visibility`), add key `id1_type`(`id1`,`link_type`,`visibility`,`time`,`version`,`data`);

# Check size of ibd file (total should be close to 20G approx)
#ls -l /data/mysql/linkdb/linktable.ibd
#ls -l /data/mysql/linkdb/counttable.ibd

for num_threads in 8 16 32 64 100 128; do
    LOG_NAME=$LOG_SERVER_TYPE-$LOG_DB_NAME-$LOG_DB_VERSION-$ENGINE-$LOG_ENGINE_VERSION-$LOG_BENCHMARK_NAME-$num_threads-$COMMIT_SYNC-DEFAULTS.txt
    #    LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
    #    LOG_NAME_SYSINFO=${LOG_NAME}.sysinfo
    #    LOG_NAME_IOSTAT=${LOG_NAME}.iostat
    #    LOG_NAME_DSTAT=${LOG_NAME}.dstat
    #    LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv
    
    #    capture-engine-status.bash $RUN_TIME $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS $ENGINE &
    #    capture-sysinfo.bash $RUN_TIME $SHOW_SYSINFO_INTERVAL $LOG_NAME_SYSINFO &
    #    iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
    #    dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &

    # REQUEST PHASE. Repeat this step a few times and see if the numbers are consistent.
    java com.facebook.LinkBench.LinkBenchDriver ./LinkConfigMysql-${num_threads}.properties 2 | tee $LOG_NAME
    
    # You will see last line of output something like this
    #REQUEST PHASE COMPLETED. 2000000 requests done in 1155 seconds.Requests/second = 1731
    
    # Also, look at innodb_pages_read and innodb_pages_written during the request phase. I
    # have seen values of about ~2000 for the former and ~200 for the latter.
    
    echo "BEGIN-SHOW-VARIABLES" >> $LOG_NAME
    mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show variables" >> $LOG_NAME
    echo "END-SHOW-VARIABLES" >> $LOG_NAME
    echo "BEGIN-SHOW-ENGINE-STATUS" >> $LOG_NAME
    mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show engine $ENGINE status" >> $LOG_NAME
    echo "END-SHOW-ENGINE-STATUS" >> $LOG_NAME
    
    sleep 60
done

