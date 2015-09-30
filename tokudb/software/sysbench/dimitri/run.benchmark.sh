#!/bin/bash

if [ -z "$SYSBENCH_VERSION" ]; then
    echo "Need to set SYSBENCH_VERSION"
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
if [ -z "$NUM_ROWS" ]; then
    echo "Need to set NUM_ROWS"
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
if [ -z "$NUM_TABLES" ]; then
    echo "Need to set NUM_TABLES"
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


# compile sysbench
echo "compiling sysbench : ${SYSBENCH_VERSION}"
pushd ${SYSBENCH_VERSION}
./configure &> ../${MACHINE_NAME}-sysbench-build-1-configure.txt
make &> ../${MACHINE_NAME}-sysbench-build-2-make.txt
popd


REPORT_INTERVAL=10
SHOW_ENGINE_STATUS_INTERVAL=10
SHOW_SYSINFO_INTERVAL=10
IOSTAT_INTERVAL=10
DSTAT_INTERVAL=10

MYSQL_SOCKET=$MYSQL_SOCKET
MYSQL_USER=root
MYSQL_PASSWORD=""
DBNAME=sbtest

LOG_BENCHMARK_NAME=sysbench.dimitrik.${NUM_TABLES}
COMMIT_SYNC=1

SLEEP_SECONDS=15

if [ -z "$threadCountList" ]; then
    export threadCountList="0001 0002 0004 0008 0016 0032 0064 0128 0256 0512 1024"
fi

# point query test - PRIMARY KEY
for num_threads in ${threadCountList}; do
    IOSTAT_ROUNDS=$[RUN_TIME_SECONDS/IOSTAT_INTERVAL+1]
    DSTAT_ROUNDS=$[RUN_TIME_SECONDS/DSTAT_INTERVAL+1]
    LOG_NAME=$MACHINE_NAME-$MYSQL_NAME-$MYSQL_VERSION-$MYSQL_STORAGE_ENGINE-$BENCH_ID-${LOG_BENCHMARK_NAME}-$NUM_ROWS-$num_threads-$COMMIT_SYNC-DEFAULTS.POINT.PRIMARY.txt
    LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
    LOG_NAME_SYSINFO=${LOG_NAME}.sysinfo
    LOG_NAME_IOSTAT=${LOG_NAME}.iostat
    LOG_NAME_DSTAT=${LOG_NAME}.dstat
    LOG_NAME_DSTAT_CSV=${LOG_NAME}.dstat.csv
    LOG_NAME_PMPROF=${LOG_NAME}.pmprof
    
    if [ ${BENCHMARK_LOGGING} == "Y" ]; then
        # verbose logging
        echo "*** verbose benchmark logging enabled ***"

        capture-tokustat.bash $SHOW_ENGINE_STATUS_INTERVAL $MYSQL_USER $MYSQL_SOCKET $LOG_NAME_ENGINE_STATUS &
        capture-sysinfo.bash $RUN_TIME_SECONDS $SHOW_SYSINFO_INTERVAL $LOG_NAME_SYSINFO &
        iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
        dstat -t -v --nocolor --output $LOG_NAME_DSTAT_CSV $DSTAT_INTERVAL $DSTAT_ROUNDS > $LOG_NAME_DSTAT &
        #pmprof.bash 200 2 1 mysqld ${LOG_NAME_PMPROF} 0 &
    fi

    TABLE_NUM=1
    while [ ${TABLE_NUM} -le ${NUM_TABLES} ]; do
        echo "starting thread ${TABLE_NUM}"

        # LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${DB_DIR}/lib ${SYSBENCH_VERSION}/sysbench/sysbench --num-threads=${num_threads} --test=oltp \
        
        ${SYSBENCH_VERSION}/sysbench/sysbench --num-threads=${num_threads} --test=oltp \
            --oltp-table-size=${NUM_ROWS} --oltp-dist-type=uniform --oltp-table-name=sbtest${TABLE_NUM} \
            --max-requests=0 --max-time=${RUN_TIME_SECONDS} --mysql-socket=${MYSQL_SOCKET} \
            --mysql-user=${MYSQL_USER} --mysql-password=${MYSQL_PASSWORD} --mysql-db=${DBNAME} \
            --mysql-table-engine=${MYSQL_STORAGE_ENGINE}  --db-driver=mysql \
            --oltp-point-selects=1 --oltp-simple-ranges=0 --oltp-sum-ranges=0 \
            --oltp-order-ranges=0 --oltp-distinct-ranges=0 --oltp-skip-trx=on \
            --oltp-read-only=on --mysql-engine-trx=yes run > ${LOG_NAME}.thread-${TABLE_NUM} &
    
        let TABLE_NUM=TABLE_NUM+1
    done
    
    let BENCHMARK_TIME=RUN_TIME_SECONDS+30
    echo "sleeping for ${BENCHMARK_TIME} seconds"
    sleep ${BENCHMARK_TIME}

    thisQps=`grep transactions: ${LOG_NAME}.thread-* | awk '{ print $4 }' | cut -b 2- | awk '{ sum += $1 } END { print sum}'`
    echo "${thisQps} QPS" | tee $LOG_NAME
    echo "******************************************************" >> $LOG_NAME
    
    echo "${num_threads} ${thisQps}" >> ${MACHINE_NAME}-performance-summary.txt

    echo "BEGIN-SHOW-VARIABLES" >> $LOG_NAME
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show variables" >> $LOG_NAME
    echo "END-SHOW-VARIABLES" >> $LOG_NAME
    echo "BEGIN-SHOW-ENGINE-STATUS" >> $LOG_NAME
    $DB_DIR/bin/mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --socket=$MYSQL_SOCKET -e "show engine $MYSQL_STORAGE_ENGINE status" >> $LOG_NAME
    echo "END-SHOW-ENGINE-STATUS" >> $LOG_NAME
    
    sleep ${SLEEP_SECONDS}
    
    bkill
done

bkill

if [ ${SCP_FILES} == "Y" ]; then
    DATE=`date +"%Y%m%d%H%M%S"`
    tarFileName="${MACHINE_NAME}-${BENCHMARK_NUMBER}-${DATE}-dimitri.k.qps-${BENCH_ID}.tar.gz"

    tar czvf ${tarFileName} ${MACHINE_NAME}* fastload/log-load* fastload/*.log ${DB_DIR}/data/*.err
    scp ${tarFileName} ${SCP_TARGET}:~
    
    rm -f ${tarFileName}
    rm -f ${MACHINE_NAME}*
    rm -f fastload/log-load*
    rm -f fastload/*.log
    rm -f fastload/*.done

    movecores
fi
