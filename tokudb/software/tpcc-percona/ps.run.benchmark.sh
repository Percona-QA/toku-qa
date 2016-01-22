#!/bin/bash

if [ -z "$NEW_ORDERS_PER_TEN_SECONDS" ]; then
    echo "Need to set NEW_ORDERS_PER_TEN_SECONDS"
    exit 1
fi
if [ -z "$RUN_TIME_SECONDS" ]; then
    echo "Need to set RUN_TIME_SECONDS"
    exit 1
fi
if [ -z "$BENCHMARK_LOGGING" ]; then
    echo "Need to set BENCHMARK_LOGGING"
    exit 1
fi
if [ -z "$NUM_WAREHOUSES" ]; then
    echo "Need to set NUM_WAREHOUSES"
    exit 1
fi
if [ -z "$MYSQL_SOCKET" ]; then
    echo "Need to set MYSQL_SOCKET"
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
if [ -z "$SCP_TARGET" ]; then
    echo "Need to set SCP_TARGET"
    exit 1
fi


if [ -z "$SCP_FILES" ]; then
    export SCP_FILES=Y
fi

if [ -z "$RUN_ARBITRARY_SQL" ]; then
    export RUN_ARBITRARY_SQL=N
fi

if [ -z "$DIRECTIO" ]; then
    export DIRECTIO=N
fi
if [ -z "$WARMUP" ]; then
    export WARMUP=N
fi

if [ -z "$SINGLE_FLUSH" ]; then
    export SINGLE_FLUSH=Y
fi
if [ -z "$END_ITERATION_NUMBER" ]; then
    export END_ITERATION_NUMBER=96
fi
if [ -z "$END_ITERATION_SLEEP_SECONDS" ]; then
    export END_ITERATION_SLEEP_SECONDS=300
fi



# compile custom tpcc
pushd tpcc-mysql/src
make
popd

SERVER_NAME=localhost
WARMUP_SECONDS=5

POST_BENCHMARK_SECONDS=300
if [ ${SINGLE_FLUSH} == "N" ]; then
    POST_BENCHMARK_SECONDS=$[END_ITERATION_NUMBER*END_ITERATION_SLEEP_SECONDS]
fi
LOG_SECONDS=$[RUN_TIME_SECONDS+WARMUP_SECONDS+POST_BENCHMARK_SECONDS]
SHOW_ENGINE_STATUS_INTERVAL=10
SHOW_PROCESSLIST_INTERVAL=10
SHOW_SYSINFO_INTERVAL=60
SHOW_FILE_INFO_INTERVAL=60
IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[LOG_SECONDS/IOSTAT_INTERVAL+1]
DSTAT_INTERVAL=10
DSTAT_ROUNDS=$[LOG_SECONDS/DSTAT_INTERVAL+1]

LOG_BENCHMARK_NAME=tpcc

if [ -z "$BENCHMARK_REPORT_INTERVAL" ]; then
    BENCHMARK_REPORT_INTERVAL=10
fi


COMMIT_SYNC=1


if [ ${WARMUP} == "Y" ]; then
    # warmup the cache, 64 threads for 10 minutes, don't bother logging
    num_threads=0064
    WARMUP_TIME_SECONDS=600
    tpcc-mysql/tpcc_start -h ${SERVER_NAME} -d ${MYSQL_DATABASE} -u ${MYSQL_USER} -p "$MYSQL_PASSWORD" -w ${NUM_WAREHOUSES} -c ${num_threads} -r ${WARMUP_SECONDS} -l ${WARMUP_TIME_SECONDS} -n ${NEW_ORDERS_PER_TEN_SECONDS} -S ${MYSQL_SOCKET} -i ${BENCHMARK_REPORT_INTERVAL}
    sleep 90
fi


if [ -z "$threadCountList" ]; then
    export threadCountList="0001 0002 0004 0008 0016 0032 0064 0128 0256 0512 1024"
fi

if [ ${RUN_ARBITRARY_SQL} == "Y" ]; then
    LOG_NAME_SQL=${MACHINE_NAME}-${MYSQL_NAME}-${MYSQL_VERSION}-${MYSQL_STORAGE_ENGINE}-${BENCH_ID}-$LOG_BENCHMARK_NAME-$NUM_WAREHOUSES-$num_threads-$COMMIT_SYNC-DEFAULTS.txt.arbitrary-sql
    if [ -z "$arbitrarySqlWaitSeconds" ]; then
        export arbitrarySqlWaitSeconds=900
    fi
    mysql-run-arbitrary-sql ${arbitrarySqlWaitSeconds} "alter table order_line add column new_column bigint default 0 not null;" ${LOG_NAME_SQL} &
fi

# run for real
for num_threads in ${threadCountList}; do
    LOG_NAME=${MACHINE_NAME}-${MYSQL_NAME}-${MYSQL_VERSION}-${MYSQL_STORAGE_ENGINE}-${BENCH_ID}-$LOG_BENCHMARK_NAME-$NUM_WAREHOUSES-$num_threads-$COMMIT_SYNC-DEFAULTS.txt
    LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
    LOG_NAME_PROCESSLIST=${LOG_NAME}.processlist
    LOG_NAME_SYSINFO=${LOG_NAME}.sysinfo
    LOG_NAME_FILE_INFO=${LOG_NAME}.fileinfo
    LOG_NAME_IOSTAT=${LOG_NAME}.iostat
    LOG_NAME_DSTAT=${LOG_NAME}.dstat
    LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv
    LOG_NAME_PMPROF=${LOG_NAME}.pmprof

    if [ ${BENCHMARK_LOGGING} == "Y" ]; then
        # verbose logging
        echo "*** verbose benchmark logging enabled ***"
        capture-tokustat.bash $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS &
        #capture-show-processlist.bash $LOG_SECONDS $SHOW_PROCESSLIST_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_PROCESSLIST ${MYSQL_STORAGE_ENGINE} &
        capture-sysinfo.bash ${LOG_SECONDS} ${SHOW_SYSINFO_INTERVAL} ${LOG_NAME_SYSINFO} &
        capture-filesystem-info.bash ${LOG_SECONDS} ${SHOW_FILE_INFO_INTERVAL} $DB_DIR $MYSQL_USER $MYSQL_SOCKET ${MYSQL_DATABASE} ${MYSQL_STORAGE_ENGINE} ${LOG_NAME_FILE_INFO} & 
        iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
        dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &
        #pmprof.bash 200 2 1 mysqld ${LOG_NAME_PMPROF} 0 &
    fi

    # unused
    #  -P <port>
    #  -f <report-file-name>
    #  -t <trx-file-name>
    if [ -z "$NEW_ORDERS_PER_TEN_SECONDS_LIST" ]; then
        tpcc-mysql/tpcc_start -h ${SERVER_NAME} -d ${MYSQL_DATABASE} -u ${MYSQL_USER} -p "$MYSQL_PASSWORD" -w ${NUM_WAREHOUSES} -c ${num_threads} -r ${WARMUP_SECONDS} -l ${RUN_TIME_SECONDS} -n ${NEW_ORDERS_PER_TEN_SECONDS} -S ${MYSQL_SOCKET} -i ${BENCHMARK_REPORT_INTERVAL} 2>&1 | tee -a ${LOG_NAME}
    else
        echo "*** running for multiple performance levels ***"
        for newOrdsPerTenSeconds in ${NEW_ORDERS_PER_TEN_SECONDS_LIST}; do
            tpcc-mysql/tpcc_start -h ${SERVER_NAME} -d ${MYSQL_DATABASE} -u ${MYSQL_USER} -p "$MYSQL_PASSWORD" -w ${NUM_WAREHOUSES} -c ${num_threads} -r ${WARMUP_SECONDS} -l ${RUN_TIME_SECONDS} -n ${newOrdsPerTenSeconds} -S ${MYSQL_SOCKET} -i ${BENCHMARK_REPORT_INTERVAL} 2>&1 | tee -a ${LOG_NAME}
        done
    fi

    echo "BEGIN-SHOW-VARIABLES" >> $LOG_NAME
    ${DB_DIR}/bin/mysql --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --socket=${MYSQL_SOCKET} -e "show variables" >> $LOG_NAME
    echo "END-SHOW-VARIABLES" >> $LOG_NAME
    echo "BEGIN-SHOW-ENGINE-STATUS" >> $LOG_NAME
    ${DB_DIR}/bin/mysql --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --socket=${MYSQL_SOCKET} -e "show engine ${MYSQL_STORAGE_ENGINE} status" >> $LOG_NAME
    echo "END-SHOW-ENGINE-STATUS" >> $LOG_NAME

    sleep 120
    bkill
done


if [ ${SINGLE_FLUSH} == "N" ]; then
    for loop_num in $(eval echo "{1..$END_ITERATION_NUMBER}"); do
        echo "" | tee -a $LOG_NAME
        echo "" | tee -a $LOG_NAME
        echo "" | tee -a $LOG_NAME
        echo "----------------------------------------------------------" | tee -a $LOG_NAME
        echo "Post Benchmark Delay : Loop Number ${loop_num}" | tee -a $LOG_NAME
        echo "----------------------------------------------------------" | tee -a $LOG_NAME
        echo "" | tee -a $LOG_NAME
        echo "-------------------------------" | tee -a $LOG_NAME
        echo "Sizing Information" | tee -a $LOG_NAME
        echo "-------------------------------" | tee -a $LOG_NAME
        
        currentDate=`date`
        
        TOKUDB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
        TOKUDB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
        INNODB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/${MYSQL_DATABASE} | tail -n 1 | cut -f1`
        INNODB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/${MYSQL_DATABASE} | tail -n 1 | cut -f1`
        
        TOKUDB_SIZE_MB=`echo "scale=2; ${TOKUDB_SIZE_BYTES}/(1024*1024)" | bc `
        TOKUDB_SIZE_APPARENT_MB=`echo "scale=2; ${TOKUDB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
        INNODB_SIZE_MB=`echo "scale=2; ${INNODB_SIZE_BYTES}/(1024*1024)" | bc `
        INNODB_SIZE_APPARENT_MB=`echo "scale=2; ${INNODB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
        
        echo "${currentDate} | post-benchmark TokuDB sizing (SizeMB / ASizeMB) = ${TOKUDB_SIZE_MB} / ${TOKUDB_SIZE_APPARENT_MB}" | tee -a $LOG_NAME
        echo "${currentDate} | post-benchmark InnoDB sizing (SizeMB / ASizeMB) = ${INNODB_SIZE_MB} / ${INNODB_SIZE_APPARENT_MB}" | tee -a $LOG_NAME
        
        mysql-show-frag ${MYSQL_USER} ${MYSQL_SOCKET} | tee -a $LOG_NAME

        echo "`date` | sleeping for ${END_ITERATION_SLEEP_SECONDS} seconds" | tee -a $LOG_NAME
        sleep ${END_ITERATION_SLEEP_SECONDS}
    done
fi


T="$(date +%s)"
echo "`date` | flushing logs and tables" | tee -a ${LOG_NAME}
$DB_DIR/bin/mysql --user=${MYSQL_USER} --socket=${MYSQL_SOCKET} ${MYSQL_DATABASE} -e "flush logs; flush tables;" | tee -a ${LOG_NAME}
T="$(($(date +%s)-T))"
printf "`date` | flush logs and tables duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a ${LOG_NAME}

echo "" | tee -a $LOG_NAME
echo "" | tee -a $LOG_NAME
echo "" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
echo "Final Sizing Information" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME

currentDate=`date`

TOKUDB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
TOKUDB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
INNODB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/${MYSQL_DATABASE} | tail -n 1 | cut -f1`
INNODB_SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${DB_DIR}/data/${MYSQL_DATABASE} | tail -n 1 | cut -f1`

TOKUDB_SIZE_MB=`echo "scale=2; ${TOKUDB_SIZE_BYTES}/(1024*1024)" | bc `
TOKUDB_SIZE_APPARENT_MB=`echo "scale=2; ${TOKUDB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
INNODB_SIZE_MB=`echo "scale=2; ${INNODB_SIZE_BYTES}/(1024*1024)" | bc `
INNODB_SIZE_APPARENT_MB=`echo "scale=2; ${INNODB_SIZE_APPARENT_BYTES}/(1024*1024)" | bc `

echo "${currentDate} | post-benchmark TokuDB sizing (SizeMB / ASizeMB) = ${TOKUDB_SIZE_MB} / ${TOKUDB_SIZE_APPARENT_MB}" | tee -a $LOG_NAME
echo "${currentDate} | post-benchmark InnoDB sizing (SizeMB / ASizeMB) = ${INNODB_SIZE_MB} / ${INNODB_SIZE_APPARENT_MB}" | tee -a $LOG_NAME

mysql-show-frag ${MYSQL_USER} ${MYSQL_SOCKET} | tee -a $LOG_NAME


bkill

parse_tpcc.pl summary . > ${MACHINE_NAME}.summary

DATE=`date +"%Y%m%d%H%M%S"`
tarFileName="tpcc_${BENCH_ID}_perf_result_set_${DATE}.tar.gz"
tar czvf ${tarFileName} ${MACHINE_NAME}* ${DB_DIR}/data/*.err
cp ${tarFileName} ${SCP_TARGET}

cp ${MACHINE_NAME}.summary ${WORKSPACE_LOC}/tpcc_${BENCH_ID}_perf_result_set_${DATE}.txt

result_set=($(cat ${MACHINE_NAME}.summary |  awk '{print ","$5 }'))
for i in {0..7}; do if [ -z ${result_set[i]} ]; then  result_set[i]=',0' ; fi; done

echo "[ '${BUILD_NUMBER}' ${result_set[*]} ]," >> ${WORKSPACE_LOC}/tpcc_${BENCH_ID}_perf_result_set.txt
rm -f ${MACHINE_NAME}*

