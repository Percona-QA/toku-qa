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
if [ -z "$MYSQL_PORT" ]; then
    echo "Need to set MYSQL_PORT"
    exit 1
fi
if [ -z "$MYSQL_HOST" ]; then
    echo "Need to set MYSQL_HOST"
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
if [ -z "$startid1" ]; then
    echo "Need to set startid1"
    exit 1
fi
if [ -z "$NUM_LOADERS" ]; then
    echo "Need to set NUM_LOADERS"
    exit 1
fi
if [ -z "$maxid1" ]; then
    echo "Need to set maxid1"
    exit 1
fi

LOG_NAME=${MACHINE_NAME}-log-load-linkbench.txt
rm -f $LOG_NAME

LOG_NAME_RESULTS=${MACHINE_NAME}-results.txt

# do the logging for 48 hours, loggers are automatically killed after loaders complete
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

echo "`date` | drop database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} -f drop ${MYSQL_DATABASE}
    
echo "`date` | create database" | tee -a $LOG_NAME
$DB_DIR/bin/mysqladmin --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} create ${MYSQL_DATABASE}
    
echo "`date` | creating tables" | tee -a $LOG_NAME
if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    if [ ${INNODB_COMPRESSION} == "Y" ]; then
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < ./sql/schema_innodb_compressed.sql
    else
        $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < ./sql/schema_innodb.sql
    fi
else
    $DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} < ./sql/schema_tokudb.sql
fi

echo "`date` | starting the loader" | tee -a $LOG_NAME
./bin/linkbench -c config/LinkConfigMysql.properties -D host=${MYSQL_HOST} -D user=${MYSQL_USER} -D password= -D port=${MYSQL_PORT} -D dbid=${MYSQL_DATABASE} \
                                                     -D loaders=${NUM_LOADERS} -D MySQL_bulk_insert_batch=${INSERT_BATCH_SIZE} \
                                                     -D startid1=${startid1} -D maxid1=${maxid1} \
                                                     --csvstats $LOG_NAME.final-stats.csv --csvstream $LOG_NAME.streaming-stats.csv -l 2>&1 | tee -a $LOG_NAME

echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | complete loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

# calculate load speed (per id)
ROWS_PER_SECOND=`echo "scale=2; ${NUM_ROWS}/${T}" | bc `
printf "`date` | ids loaded per second = %'.1f\n" "${ROWS_PER_SECOND}" | tee -a $LOG_NAME
printf "idsPerSecond = %'.1f\n" "${ROWS_PER_SECOND}" | tee -a $LOG_NAME_RESULTS

T="$(date +%s)"
echo "`date` | shutting down the database" | tee -a $LOG_NAME
mstop
T="$(($(date +%s)-T))"
printf "`date` | shutdown duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

echo "" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
echo "Sizing Information" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME

if [ ${MYSQL_STORAGE_ENGINE} == "tokudb" ]; then
    TOKUDB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
    TOKUDB_SIZE_MB=`echo "scale=2; ${TOKUDB_SIZE_BYTES}/(1024*1024)" | bc `
    echo "`date` | loader TokuDB sizing (MB) = ${TOKUDB_SIZE_MB}" | tee -a $LOG_NAME
    echo "loadsizemb = ${TOKUDB_SIZE_MB}" | tee -a $LOG_NAME_RESULTS
    #mysql-show-frag ${MYSQL_USER} ${MYSQL_SOCKET} | tee -a $LOG_NAME
else
    INNODB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/${MYSQL_DATABASE}*/*.ibd | tail -n 1 | cut -f1`
    INNODB_SIZE_MB=`echo "scale=2; ${INNODB_SIZE_BYTES}/(1024*1024)" | bc `
    echo "`date` | loader InnoDB sizing (MB) = ${INNODB_SIZE_MB}" | tee -a $LOG_NAME
    echo "loadsizemb = ${INNODB_SIZE_MB}" | tee -a $LOG_NAME_RESULTS
fi

bkill
