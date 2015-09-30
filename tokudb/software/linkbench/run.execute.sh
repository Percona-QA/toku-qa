#!/bin/bash

if [ -z "$RUN_TIME_SECONDS" ]; then
    echo "Need to set RUN_TIME_SECONDS"
    exit 1
fi
if [ -z "$BENCHMARK_LOGGING" ]; then
    echo "Need to set BENCHMARK_LOGGING"
    exit 1
fi
if [ -z "$NUM_ROWS" ]; then
    echo "Need to set NUM_ROWS"
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
if [ -z "$MYSQL_DATABASE" ]; then
    echo "Need to set MYSQL_DATABASE"
    exit 1
fi
if [ -z "$MYSQL_USER" ]; then
    echo "Need to set MYSQL_USER"
    exit 1
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    echo "Need to set MYSQL_STORAGE_ENGINE"
    exit 1
fi
if [ -z "$MACHINE_NAME" ]; then
    echo "Need to set MACHINE_NAME"
    exit 1
fi
if [ -z "$MYSQL_NAME" ]; then
    echo "Need to set MYSQL_NAME"
    exit 1
fi
if [ -z "$MYSQL_VERSION" ]; then
    echo "Need to set MYSQL_VERSION"
    exit 1
fi
if [ -z "$BENCH_ID" ]; then
    echo "Need to set BENCH_ID"
    exit 1
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    echo "Need to set BENCHMARK_NUMBER"
    exit 1
fi
if [ -z "$NUM_REQUESTERS" ]; then
    echo "Need to set NUM_REQUESTERS"
    exit 1
fi
if [ -z "$NUM_REQUESTS" ]; then
    echo "Need to set NUM_REQUESTS"
    exit 1
fi
if [ -z "$startid1" ]; then
    echo "Need to set startid1"
    exit 1
fi
if [ -z "$maxid1" ]; then
    echo "Need to set maxid1"
    exit 1
fi



REPORT_INTERVAL=10
SHOW_EXTENDED_STATUS_INTERVAL=60
SHOW_ENGINE_STATUS_INTERVAL=60
SHOW_PROCESSLIST_INTERVAL=10
SHOW_MEMORY_INTERVAL=10
IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[RUN_TIME_SECONDS/IOSTAT_INTERVAL+1]
DSTAT_INTERVAL=10
DSTAT_ROUNDS=$[RUN_TIME_SECONDS/DSTAT_INTERVAL+1]

LOG_NAME=${MACHINE_NAME}-${BENCH_ID}-linkbench.execute-${NUM_ROWS}-${NUM_REQUESTERS}-${NUM_REQUESTS}-${RUN_TIME_SECONDS}-${WARMUP_TIME}.txt
LOG_NAME_EXTENDED_STATUS=${LOG_NAME}.extended_status
LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
LOG_NAME_PROCESSLIST=${LOG_NAME}.processlist
LOG_NAME_MEMORY=${LOG_NAME}.memory
LOG_NAME_IOSTAT=${LOG_NAME}.iostat
LOG_NAME_DSTAT=${LOG_NAME}.dstat
LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv
LOG_NAME_PMPROF=${LOG_NAME}.pmprof

LOG_NAME_RESULTS=${MACHINE_NAME}-results.txt

if [ ${BENCHMARK_LOGGING} == "Y" ]; then
    # verbose logging
    echo "*** verbose benchmark logging enabled ***"

    # capture-extended-status.bash $RUN_TIME_SECONDS $SHOW_EXTENDED_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_EXTENDED_STATUS &
    capture-tokustat.bash $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS &
    # capture-show-processlist.bash $RUN_TIME_SECONDS $SHOW_PROCESSLIST_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_PROCESSLIST ${MYSQL_STORAGE_ENGINE} &
    capture-memory.bash $RUN_TIME_SECONDS ${SHOW_MEMORY_INTERVAL} ${LOG_NAME_MEMORY} mysqld &
    iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
    dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &
    #pmprof.bash 200 2 1 mysqld ${LOG_NAME_PMPROF} 120 &
fi


# run the benchmark
T="$(date +%s)"
echo "`date` | starting the benchmark execution" | tee -a $LOG_NAME
./bin/linkbench -c config/LinkConfigMysql.properties -D host=${MYSQL_HOST} -D user=${MYSQL_USER} -D password= -D port=${MYSQL_PORT} -D dbid=${MYSQL_DATABASE} \
                                                     -D requesters=${NUM_REQUESTERS} -D requests=${NUM_REQUESTS} -D maxtime=${RUN_TIME_SECONDS} \
                                                     -D startid1=${startid1} -D maxid1=${maxid1} -D warmup_time=${WARMUP_TIME} \
                                                     --csvstats $LOG_NAME.final-stats.csv --csvstream $LOG_NAME.streaming-stats.csv -r 2>&1 | tee -a $LOG_NAME

echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | complete execution duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

# get the average number of requests per second
REQUESTS_PER_SECOND=`grep "REQUEST PHASE COMPLETED" $LOG_NAME | cut -d= -f2`
printf "requestsPerSecond = %'.1f\n" "${REQUESTS_PER_SECOND}" | tee -a $LOG_NAME_RESULTS

echo "BEGIN-SHOW-VARIABLES" >> $LOG_NAME
$DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show variables" >> $LOG_NAME
echo "END-SHOW-VARIABLES" >> $LOG_NAME
echo "BEGIN-SHOW-ENGINE-STATUS" >> $LOG_NAME
$DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show engine ${MYSQL_STORAGE_ENGINE} status" >> $LOG_NAME
echo "END-SHOW-ENGINE-STATUS" >> $LOG_NAME

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
    echo "`date` | post-execution TokuDB sizing (MB) = ${TOKUDB_SIZE_MB}" | tee -a $LOG_NAME
    echo "runsizemb = ${TOKUDB_SIZE_MB}" | tee -a $LOG_NAME_RESULTS
    #mysql-show-frag ${MYSQL_USER} ${MYSQL_SOCKET} | tee -a $LOG_NAME
else
    INNODB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/${MYSQL_DATABASE}*/*.ibd | tail -n 1 | cut -f1`
    INNODB_SIZE_MB=`echo "scale=2; ${INNODB_SIZE_BYTES}/(1024*1024)" | bc `
    echo "`date` | post-execution InnoDB sizing (MB) = ${INNODB_SIZE_MB}" | tee -a $LOG_NAME
    echo "runsizemb = ${INNODB_SIZE_MB}" | tee -a $LOG_NAME_RESULTS
fi

bkill
