#!/bin/bash

# database should already be running prior to starting this script

SERVER_NAME=localhost
TPCC_LOAD_SERVER_NAME=l
DATABASE_NAME=tpcc
MYSQL_USER=root
MYSQL_PASSWORD=""
MYSQL_SOCKET=/tmp/mysql.sock
#BENCHMARK_SECONDS=10800
BENCHMARK_SECONDS=300   #5 minutes
WARMUP_SECONDS=10
SHOW_ENGINE_STATUS_INTERVAL=60
SYSINFO_INTERVAL=60
IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[BENCHMARK_SECONDS/IOSTAT_INTERVAL+1]
DSTAT_INTERVAL=10
DSTAT_ROUNDS=$[BENCHMARK_SECONDS/DSTAT_INTERVAL+1]

NUM_WAREHOUSES=500
LOG_SERVER_TYPE=mm
LOG_DB_NAME=mysql
LOG_DB_VERSION=5.5.21
LOG_ENGINE_NAME=innodb_compressed
LOG_ENGINE_VERSION=1.1.8
LOG_BENCHMARK_NAME=tpcc
COMMIT_SYNC=1


#for num_threads in 8 16 32 8 16 32 8 16 32 8 16 32; do

    LOG_NAME=$LOG_SERVER_TYPE-$LOG_DB_NAME-$LOG_DB_VERSION-$LOG_ENGINE_NAME-$LOG_ENGINE_VERSION-$LOG_BENCHMARK_NAME-$NUM_WAREHOUSES-$num_threads-$COMMIT_SYNC.txt
#    LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
#    LOG_NAME_SYSINFO=${LOG_NAME}.sysinfo
#    LOG_NAME_IOSTAT=${LOG_NAME}.iostat
#    LOG_NAME_DSTAT=${LOG_NAME}.dstat
#    LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv
    
    # ---------------------------------------------------------------------------
    # create initial state using tpcc client loader
    # ---------------------------------------------------------------------------
    
    echo "`date` : drop database" | tee -a $LOG_NAME
    mysqladmin --user=$MYSQL_USER --socket=$MYSQL_SOCKET -f drop $DATABASE_NAME
    
    echo "`date` : create database" | tee -a $LOG_NAME
    mysqladmin --user=$MYSQL_USER --socket=$MYSQL_SOCKET create $DATABASE_NAME
    
    echo "`date` : create tables" | tee -a $LOG_NAME
    mysql --user=$MYSQL_USER --socket=$MYSQL_SOCKET $DATABASE_NAME < fastload1/create_schema_tokudb.sql
    
    echo "`date` : begin loader client" | tee -a $LOG_NAME
    tpcc-mysql/tpcc_load $TPCC_LOAD_SERVER_NAME $DATABASE_NAME $MYSQL_USER "$USER_PASSWORD" $NUM_WAREHOUSES | tee -a $LOG_NAME
    
    echo "`date` : done, database loaded" | tee -a $LOG_NAME


    # ---------------------------------------------------------------------------
    # start monitoring scripts
    # ---------------------------------------------------------------------------
    
#    capture-engine-status.bash $BENCHMARK_SECONDS $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS $LOG_ENGINE_NAME &
#    capture-sysinfo.bash $BENCHMARK_SECONDS $SYSINFO_INTERVAL $LOG_NAME_SYSINFO &
#    iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
#    dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &

    # ---------------------------------------------------------------------------
    # run the benchmark
    # ---------------------------------------------------------------------------

    tpcc-mysql/tpcc_start $SERVER_NAME $DATABASE_NAME $MYSQL_USER "$MYSQL_PASSWORD" $NUM_WAREHOUSES $num_threads $WARMUP_SECONDS $BENCHMARK_SECONDS | tee $LOG_NAME

    # ---------------------------------------------------------------------------
    # capture more information
    # ---------------------------------------------------------------------------

#    echo "`date` : BEGIN-SHOW-VARIABLES" | tee -a $LOG_NAME
#    ${DB_DIR}/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show variables" >> $LOG_NAME
#    echo "`date` : END-SHOW-VARIABLES" | tee -a $LOG_NAME
#    echo "`date` : BEGIN-SHOW-ENGINE-STATUS" | tee -a $LOG_NAME
#    ${DB_DIR}/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show engine $LOG_ENGINE_NAME status" >> $LOG_NAME
#    echo "`date` : END-SHOW-ENGINE-STATUS" | tee -a $LOG_NAME

done
