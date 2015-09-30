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
if [ -z "$LOADER_LOGGING" ]; then
    echo "Need to set LOADER_LOGGING"
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

LOG_NAME=log-load-sysbench-flat-files.txt
rm -f $LOG_NAME

echo "mysql_storage_engine = $MYSQL_STORAGE_ENGINE" | tee -a $LOG_NAME
echo "mysql_socket = $MYSQL_SOCKET" | tee -a $LOG_NAME
echo "****************************************************************************" | tee -a $LOG_NAME
echo "loading ${NUM_ROWS} into each of ${NUM_TABLES} into each of ${NUM_DATABASES}" | tee -a $LOG_NAME
echo "****************************************************************************" | tee -a $LOG_NAME

# do the logging for 48 hours, loggers are automatically killed after loaders complete
LOG_TIME=172800
SHOW_ENGINE_STATUS_INTERVAL=60
SHOW_SYSINFO_INTERVAL=60
IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[LOG_TIME/IOSTAT_INTERVAL+1]
DSTAT_INTERVAL=10
DSTAT_ROUNDS=$[LOG_TIME/DSTAT_INTERVAL+1]

rm -f ./loader1.log.done 
rm -f ./loader2.log.done

if [ ${LOADER_LOGGING} == "Y" ]; then
    # verbose logging
    echo "*** verbose loader logging enabled ***"
    
    LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
    capture-engine-status.bash $LOG_TIME $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS $MYSQL_STORAGE_ENGINE &

    LOG_NAME_SYSINFO=${LOG_NAME}.sysinfo
    capture-sysinfo.bash $LOG_TIME $SHOW_SYSINFO_INTERVAL $LOG_NAME_SYSINFO &

    LOG_NAME_IOSTAT=${LOG_NAME}.iostat
    iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &

    LOG_NAME_DSTAT=${LOG_NAME}.dstat
    LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv
    dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &
fi


T="$(date +%s)"

if [ ${NUM_DATABASES} -eq 1 ]; then
    echo "`date` | drop database" | tee -a $LOG_NAME
    $DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} -f drop ${MYSQL_DATABASE}
    
    echo "`date` | create database" | tee -a $LOG_NAME
    $DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} create ${MYSQL_DATABASE}
    
    echo "`date` | creating table sbtest1" | tee -a $LOG_NAME
    $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < create_schema_$MYSQL_STORAGE_ENGINE.sql
    
    TABLE_NUM=2
    while [ ${TABLE_NUM} -le ${NUM_TABLES} ]; do
        thisTable=sbtest${TABLE_NUM}
        echo "`date` | creating table ${thisTable}" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE} -e "create table ${thisTable} like sbtest1;"
        let TABLE_NUM=TABLE_NUM+1
    done
    
    echo "`date` | starting loader1" | tee -a $LOG_NAME
    ./run.load.flatfiles.loader1.sh &
    
    echo "`date` | starting loader2" | tee -a $LOG_NAME
    ./run.load.flatfiles.loader2.sh &
    
    echo "waiting for loaders to complete..." | tee -a $LOG_NAME
    
    while ( [ ! -e "./loader1.log.done" ] || [ ! -e "./loader2.log.done" ] ); do
        sleep 60
        echo "waiting for loaders to complete..."
    done
    
else
    DATABASE_NUM=1
    export DATABASE_NUM
    while [ ${DATABASE_NUM} -le ${NUM_DATABASES} ]; do
        echo "`date` | drop database ${MYSQL_DATABASE}${DATABASE_NUM}" | tee -a $LOG_NAME
        $DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} -f drop ${MYSQL_DATABASE}${DATABASE_NUM}
        
        echo "`date` | create database ${MYSQL_DATABASE}${DATABASE_NUM}" | tee -a $LOG_NAME
        $DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} create ${MYSQL_DATABASE}${DATABASE_NUM}
        
        echo "`date` | creating table sbtest1" | tee -a $LOG_NAME
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE}${DATABASE_NUM} < create_schema_$MYSQL_STORAGE_ENGINE.sql
        
        TABLE_NUM=2
        while [ ${TABLE_NUM} -le ${NUM_TABLES} ]; do
            thisTable=sbtest${TABLE_NUM}
            echo "`date` | creating table ${thisTable}" | tee -a $LOG_NAME
            $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=$MYSQL_SOCKET ${MYSQL_DATABASE}${DATABASE_NUM} -e "create table ${thisTable} like sbtest1;"
            let TABLE_NUM=TABLE_NUM+1
        done
        
        rm -f ./loader1.log.done
        rm -f ./loader2.log.done
        
        echo "`date` | starting loader1" | tee -a $LOG_NAME
        ./run.load.flatfiles.loader1.sh &
        
        echo "`date` | starting loader2" | tee -a $LOG_NAME
        ./run.load.flatfiles.loader2.sh &
        
        echo "waiting for loaders to complete..." | tee -a $LOG_NAME
        
        while ( [ ! -e "./loader1.log.done" ] || [ ! -e "./loader2.log.done" ] ); do
            sleep 1
            echo "waiting for loaders to complete..."
        done
        
        let DATABASE_NUM=DATABASE_NUM+1
        export DATABASE_NUM
    done
    
fi

echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | complete loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

echo "" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
echo "Sizing Information" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME

currentDate=`date`

TOKUDB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
TOKUDB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
INNODB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/${MYSQL_DATABASE}*/*.ibd | tail -n 1 | cut -f1`
INNODB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/${MYSQL_DATABASE}*/*.ibd | tail -n 1 | cut -f1`

TOKUDB_SIZE_MB=`echo "scale=2; ${TOKUDB_SIZE_BYTES}/(1024*1024)" | bc `
TOKUDB_SIZE_APPARENT_MB=`echo "scale=2; ${TOKUDB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
INNODB_SIZE_MB=`echo "scale=2; ${INNODB_SIZE_BYTES}/(1024*1024)" | bc `
INNODB_SIZE_APPARENT_MB=`echo "scale=2; ${INNODB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `

echo "${currentDate} | loader TokuDB sizing (SizeMB / ASizeMB) = ${TOKUDB_SIZE_MB} / ${TOKUDB_SIZE_APPARENT_MB}" | tee -a $LOG_NAME
echo "${currentDate} | loader InnoDB sizing (SizeMB / ASizeMB) = ${INNODB_SIZE_MB} / ${INNODB_SIZE_APPARENT_MB}" | tee -a $LOG_NAME

mysql-show-frag ${MYSQL_USER} ${MYSQL_SOCKET} | tee -a $LOG_NAME

bkill
