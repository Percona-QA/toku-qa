#!/bin/bash

SERVER_NAME=localhost
DATABASE_NAME=tpcc
MYSQL_USER=root
MYSQL_PASSWORD=""
MYSQL_SOCKET=/tmp/mysql.sock
#BENCHMARK_SECONDS=10800
BENCHMARK_SECONDS=3600
WARMUP_SECONDS=10
SHOW_ENGINE_STATUS_INTERVAL=60
SYSINFO_INTERVAL=60
IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[BENCHMARK_SECONDS/IOSTAT_INTERVAL+1]
DSTAT_INTERVAL=10
DSTAT_ROUNDS=$[BENCHMARK_SECONDS/DSTAT_INTERVAL+1]

### CHECK/SET FOR YOUR BENCHMARK ###
### DIR NAMES = mysql55-innodb-#w, toku505-{innodb/tokudb}-#w, toku513-tokudb-#w

NUM_WAREHOUSES=1000
LOG_SERVER_TYPE=mm
LOG_DB_NAME=mysql
LOG_DB_VERSION=5.1.52
LOG_ENGINE_NAME=tokudb
LOG_ENGINE_VERSION=527.38674
LOG_BENCHMARK_NAME=tpcc
COMMIT_SYNC=1
DB_BACKUP=tpcc-toku520.37063.128k-${NUM_WAREHOUSES}w

### CHECK/SET FOR YOUR BENCHMARK ###
MYSQL_CONFIG_FILE=my.cnf


for num_threads in 1 2 4 8 16 32 64 128 256; do

    LOG_NAME=$LOG_SERVER_TYPE-$LOG_DB_NAME-$LOG_DB_VERSION-$LOG_ENGINE_NAME-$LOG_ENGINE_VERSION-$LOG_BENCHMARK_NAME-$NUM_WAREHOUSES-$num_threads-$COMMIT_SYNC.txt
    LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
    LOG_NAME_SYSINFO=${LOG_NAME}.sysinfo
    LOG_NAME_IOSTAT=${LOG_NAME}.iostat
    LOG_NAME_DSTAT=${LOG_NAME}.dstat
    LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv

    # ---------------------------------------------------------------------------
    # stop mysql if it is currently running (in case someone was sloppy)
    # ---------------------------------------------------------------------------

    if [ -S $MYSQL_SOCKET ]; then
        ${DB_DIR}/bin/mysqladmin --user=root --socket=$MYSQL_SOCKET shutdown
        sleep 5
    fi

    # ---------------------------------------------------------------------------
    # create the database
    # ---------------------------------------------------------------------------
    before="$(date +%s)"
    pushd .
    cd $DB_DIR
    rm -rf *
    if [ -e ${BACKUP_DIR}/${DB_BACKUP}.tar.gz ]; then
        echo "expanding ${BACKUP_DIR}/${DB_BACKUP}.tar.gz"
        tar xzvf ${BACKUP_DIR}/${DB_BACKUP}.tar.gz
    elif [ -e ${BACKUP_DIR}/${DB_BACKUP}.tar ]; then
        echo "expanding ${BACKUP_DIR}/${DB_BACKUP}.tar"
        tar xvf ${BACKUP_DIR}/${DB_BACKUP}.tar
    else
        echo "ERROR: unable to locate ${BACKUP_DIR}/${DB_BACKUP} in .tar or .tar.gz format"
    fi
    after="$(date +%s)"
    elapsed_seconds="$(expr $after - $before)"
    echo Elapsed seconds: $elapsed_seconds
    popd

    # ---------------------------------------------------------------------------
    # start the database with the preferred configuration file
    # ---------------------------------------------------------------------------
    pushd .
    cd $DB_DIR
    bin/mysqld_safe --defaults-file=$MYSQL_CONFIG_FILE --basedir=$PWD &
    popd

    # ---------------------------------------------------------------------------
    # wait for mysql to start
    # ---------------------------------------------------------------------------
    echo "waiting for mysql to start..."
    while ! [ -S "/tmp/mysql.sock" ]; do
        sleep 5
    done
    sleep 5

    capture-engine-status.bash $BENCHMARK_SECONDS $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS $LOG_ENGINE_NAME &
    capture-sysinfo.bash $BENCHMARK_SECONDS $SYSINFO_INTERVAL $LOG_NAME_SYSINFO &
    iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
    dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &

    tpcc-mysql/tpcc_start $SERVER_NAME $DATABASE_NAME $MYSQL_USER "$MYSQL_PASSWORD" $NUM_WAREHOUSES $num_threads $WARMUP_SECONDS $BENCHMARK_SECONDS | tee $LOG_NAME

    echo "BEGIN-SHOW-VARIABLES" >> $LOG_NAME
    ${DB_DIR}/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show variables" >> $LOG_NAME
    echo "END-SHOW-VARIABLES" >> $LOG_NAME
    echo "BEGIN-SHOW-ENGINE-STATUS" >> $LOG_NAME
    ${DB_DIR}/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show engine $LOG_ENGINE_NAME status" >> $LOG_NAME
    echo "END-SHOW-ENGINE-STATUS" >> $LOG_NAME

    # ---------------------------------------------------------------------------
    # stop mysql (just being polite)
    # ---------------------------------------------------------------------------
    if [ -S $MYSQL_SOCKET ]; then
        ${DB_DIR}/bin/mysqladmin --user=root --socket=$MYSQL_SOCKET shutdown
        sleep 5
    fi

done
