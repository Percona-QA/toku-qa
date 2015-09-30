#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Need to set DB_DIR"
    exit 1
fi
if [ -z "$MYSQL_STORAGE_ENGINE" ]; then
    echo "Need to set MYSQL_STORAGE_ENGINE"
    exit 1
fi
if [ -z "$MAX_ROWS" ]; then
    echo "Need to set MAX_ROWS"
    exit 1
fi
if [ -z "$NUM_ROWS_PER_INSERT" ]; then
    echo "Need to set NUM_ROWS_PER_INSERT"
    exit 1
fi
if [ -z "$MAX_INSERTS_PER_SECOND" ]; then
    echo "Need to set MAX_INSERTS_PER_SECOND"
    exit 1
fi
if [ -z "$NUM_CHAR_FIELDS" ]; then
    echo "Need to set NUM_CHAR_FIELDS"
    exit 1
fi
if [ -z "$LENGTH_CHAR_FIELDS" ]; then
    echo "Need to set LENGTH_CHAR_FIELDS"
    exit 1
fi
if [ -z "$PERCENT_COMPRESSIBLE" ]; then
    echo "Need to set PERCENT_COMPRESSIBLE"
    exit 1
fi
if [ -z "$NUM_LOADER_THREADS" ]; then
    echo "Need to set NUM_LOADER_THREADS"
    exit 1
fi
if [ -z "$MYSQL_DATABASE" ]; then
    echo "Need to set MYSQL_DATABASE"
    exit 1
fi
if [ -z "$RUN_SECONDS" ]; then
    echo "Need to set RUN_SECONDS"
    exit 1
fi
if [ -z "$NUM_SECONDARY_INDEXES" ]; then
    echo "Need to set NUM_SECONDARY_INDEXES"
    exit 1
fi
if [ -z "$CREATE_TABLE" ]; then
    echo "Need to set CREATE_TABLE"
    exit 1
fi
if [ -z "$SCP_TARGET" ]; then
    echo "Need to set SCP_TARGET"
    exit 1
fi

if [ -z "$NUM_INSERTS_PER_FEEDBACK" ]; then
    export NUM_INSERTS_PER_FEEDBACK=100000
fi
if [ -z "$NUM_SECONDS_PER_FEEDBACK" ]; then
    export NUM_SECONDS_PER_FEEDBACK=-1
fi
if [ -z "$SCP_FILES" ]; then
    export SCP_FILES=Y
fi
if [ -z "$NUM_COLLECTIONS" ]; then
    export NUM_COLLECTIONS=1
fi
if [ -z "$QUERIES_PER_INTERVAL" ]; then
    export QUERIES_PER_INTERVAL=0
fi
if [ -z "$QUERY_INTERVAL_SECONDS" ]; then
    export QUERY_INTERVAL_SECONDS=60
fi
if [ -z "$QUERY_LIMIT" ]; then
    export QUERY_LIMIT=1000
fi
if [ -z "$QUERY_NUM_ROWS_BEGIN" ]; then
    export QUERY_NUM_ROWS_BEGIN=10000000
fi

IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[RUN_SECONDS/IOSTAT_INTERVAL+1]
ENGINE_STATUS_INTERVAL=10
IOSTAT_DATASIZE_INTERVAL=60

ant clean default

export LOG_NAME=${MACHINE_NAME}-iibench_java-${NUM_COLLECTIONS}-${MAX_ROWS}-${NUM_ROWS_PER_INSERT}-${MAX_INSERTS_PER_SECOND}-${NUM_LOADER_THREADS}-${MYSQL_STORAGE_ENGINE}-${QUERIES_PER_INTERVAL}-${QUERY_INTERVAL_SECONDS}.txt

export BENCHMARK_TSV=${LOG_NAME}.tsv
LOG_NAME_IOSTAT_DATASIZE=${LOG_NAME}.iostat-datasize
LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status

rm -f $LOG_NAME
rm -f $BENCHMARK_TSV

capture-engine-status.bash $RUN_SECONDS $ENGINE_STATUS_INTERVAL ${MYSQL_ROOT_USER} ${MYSQL_SOCKET} $LOG_NAME_ENGINE_STATUS ${MYSQL_STORAGE_ENGINE} &
./capture-iostat-datasize.bash $IOSTAT_DATASIZE_INTERVAL $LOG_NAME_IOSTAT_DATASIZE $BENCHMARK_TSV &

T="$(date +%s)"

ant execute | tee -a $LOG_NAME
    
echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

if [ ${MYSQL_STORAGE_ENGINE} == "tokudb" ]; then
    mysql-show-frag ${MYSQL_ROOT_USER} ${MYSQL_SOCKET} | tee -a $LOG_NAME
fi

if [ ${SHUTDOWN_MYSQL} == "Y" ] ; then
    T="$(date +%s)"
    echo "`date` | shutting down the server" | tee -a $LOG_NAME
    ${DB_DIR}/bin/mysqladmin --user=${MYSQL_ROOT_USER} --socket=${MYSQL_SOCKET} shutdown
    T="$(($(date +%s)-T))"
    printf "`date` | shutdown duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME
else
    echo "`date` | leaving the server running" | tee -a $LOG_NAME
fi

echo "" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
echo "Sizing Information" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
        
if [ ${MYSQL_STORAGE_ENGINE} == "innodb" ]; then
    INNODB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/${MYSQL_DATABASE} | tail -n 1 | cut -f1`
    INNODB_SIZE_MB=`echo "scale=2; ${INNODB_SIZE_BYTES}/(1024*1024)" | bc `
    echo "${currentDate} | post-benchmark InnoDB sizing (MB) = ${INNODB_SIZE_MB}" | tee -a $LOG_NAME
elif [ ${MYSQL_STORAGE_ENGINE} == "deepdb" ]; then
    # nothing here yet
    tmpDeepVar=1
elif [ ${MYSQL_STORAGE_ENGINE} == "wiredtiger" ]; then
    WIREDTIGER_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.wt ${DB_DIR}/data/*.lsm ${DB_DIR}/data/*.bf ${DB_DIR}/data/WiredTiger* | tail -n 1 | cut -f1`
    WIREDTIGER_SIZE_MB=`echo "scale=2; ${WIREDTIGER_SIZE_BYTES}/(1024*1024)" | bc `
    echo "${currentDate} | post-benchmark WiredTiger sizing (MB) = ${WIREDTIGER_SIZE_MB}" | tee -a $LOG_NAME
else
    TOKUDB_SIZE_BYTES=`du -c --block-size=1 ${DB_DIR}/data/*.tokudb | tail -n 1 | cut -f1`
    TOKUDB_SIZE_MB=`echo "scale=2; ${TOKUDB_SIZE_BYTES}/(1024*1024)" | bc `
    echo "${currentDate} | post-benchmark TokuDB sizing (MB) = ${TOKUDB_SIZE_MB}" | tee -a $LOG_NAME
fi

bkill

if [ ${SCP_FILES} == "Y" ]; then
    DATE=`date +"%Y%m%d%H%M%S"`
    tarFileName="${MACHINE_NAME}-${BENCHMARK_NUMBER}-${DATE}-${BENCHMARK_NAME}-${BENCH_ID}.tar.gz"

    tar czvf ${tarFileName} ${MACHINE_NAME}* ${DB_DIR}/data/*.err
    scp ${tarFileName} ${SCP_TARGET}:~
    
    rm -f ${tarFileName}
    rm -f ${MACHINE_NAME}*

    movecores
fi
