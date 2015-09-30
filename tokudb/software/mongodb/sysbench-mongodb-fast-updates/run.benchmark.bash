#!/bin/bash

if [ -z "$MONGO_DIR" ]; then
    echo "Need to set MONGO_DIR"
    exit 1
fi
if [ -z "$MONGO_TYPE" ]; then
    echo "Need to set MONGO_TYPE"
    exit 1
fi
if [ -z "$DB_NAME" ]; then
    echo "Need to set DB_NAME"
    exit 1
fi
if [ -z "$NUM_COLLECTIONS" ]; then
    echo "Need to set NUM_COLLECTIONS"
    exit 1
fi
if [ -z "$NUM_DOCUMENTS_PER_COLLECTION" ]; then
    echo "Need to set NUM_DOCUMENTS_PER_COLLECTION"
    exit 1
fi
if [ -z "$RUN_TIME_SECONDS" ]; then
    echo "Need to set RUN_TIME_SECONDS"
    exit 1
fi
if [ -z "$BENCHMARK_NUMBER" ]; then
    echo "Need to set BENCHMARK_NUMBER"
    exit 1
fi
if [ -z "$BENCH_ID" ]; then
    echo "Need to set BENCH_ID"
    exit 1
fi
if [ -z "$MONGO_REPLICATION" ]; then
    echo "Need to set MONGO_REPLICATION"
    exit 1
fi
if [ -z "$WRITE_CONCERN" ]; then
    echo "Need to set WRITE_CONCERN"
    exit 1
fi
if [ -z "$MAX_TPS" ]; then
    echo "Need to set MAX_TPS"
    exit 1
fi
if [ -z "$BENCH_TYPE" ]; then
    echo "Need to set BENCH_TYPE"
    exit 1
fi
if [ -z "$ENABLE_FAST_UPDATES_SECONDS" ]; then
    echo "Need to set ENABLE_FAST_UPDATES_SECONDS"
    exit 1
fi
if [ -z "$SCP_TARGET" ]; then
    echo "Need to set SCP_TARGET"
    exit 1
fi

if [ -z "$NUM_SECONDS_PER_FEEDBACK" ]; then
    export NUM_SECONDS_PER_FEEDBACK=10
fi
if [ -z "$SYSBENCH_READ_ONLY" ]; then
    export SYSBENCH_READ_ONLY=N
fi
if [ -z "$SYSBENCH_RANGE_SIZE" ]; then
    export SYSBENCH_RANGE_SIZE=100
fi
if [ -z "$SYSBENCH_POINT_SELECTS" ]; then
    export SYSBENCH_POINT_SELECTS=10
fi
if [ -z "$SYSBENCH_SIMPLE_RANGES" ]; then
    export SYSBENCH_SIMPLE_RANGES=1
fi
if [ -z "$SYSBENCH_SUM_RANGES" ]; then
    export SYSBENCH_SUM_RANGES=1
fi
if [ -z "$SYSBENCH_ORDER_RANGES" ]; then
    export SYSBENCH_ORDER_RANGES=1
fi
if [ -z "$SYSBENCH_DISTINCT_RANGES" ]; then
    export SYSBENCH_DISTINCT_RANGES=1
fi
if [ -z "$SYSBENCH_INDEX_UPDATES" ]; then
    export SYSBENCH_INDEX_UPDATES=1
fi
if [ -z "$SYSBENCH_NON_INDEX_UPDATES" ]; then
    export SYSBENCH_NON_INDEX_UPDATES=1
fi
if [ -z "$PAUSE_BETWEEN_RUNS" ]; then
    export PAUSE_BETWEEN_RUNS=60
fi
if [ -z "$COMMIT_SYNC" ]; then
    export COMMIT_SYNC=1
fi
if [ -z "$threadCountList" ]; then
    export threadCountList="0001 0002 0004 0008 0016 0032 0064 0128 0256 0512 1024"
fi
if [ -z "$SCP_FILES" ]; then
    export SCP_FILES=Y
fi
if [ -z "$CAPTURE_MEMORY" ]; then
    export CAPTURE_MEMORY=Y
fi


IOSTAT_INTERVAL=${NUM_SECONDS_PER_FEEDBACK}
IOSTAT_ROUNDS=$[RUN_TIME_SECONDS/IOSTAT_INTERVAL+1]
ENGINE_STATUS_INTERVAL=60

if [ ${SYSBENCH_READ_ONLY} == "Y" ]; then
    export readWriteState="ReadOnly"
else
    export readWriteState="ReadWrite"
fi

ant clean default

export MINI_LOG_NAME=${MACHINE_NAME}-mongoSysbenchExecute-${NUM_COLLECTIONS}-${NUM_DOCUMENTS_PER_COLLECTION}-${MONGO_TYPE}-${readWriteState}
export MONGO_LOG=${MINI_LOG_NAME}.mongolog

if [ ${MONGO_TYPE} == "tokumx" ]; then
    if [ ${COMMIT_SYNC} == "1" ]; then
        BENCH_ID=${BENCH_ID}-SYNC_COMMIT
    else
        BENCH_ID=${BENCH_ID}-NOSYNC_COMMIT
    fi
else
    BENCH_ID=${BENCH_ID}
fi

# $MONGO_REPL must be set to something for the server to start in replication mode
if [ ${MONGO_REPLICATION} == "Y" ]; then
    export MONGO_REPL="tmcRepl"
else
    unset MONGO_REPL
fi

echo "`date` | starting the ${MONGO_TYPE} server at ${MONGO_DIR}"
if [ ${MONGO_TYPE} == "tokumx" ]; then
    mongo-start-tokumx-fork
else
    mongo-start-pure-numa-fork
fi

mongo-is-up
echo "`date` | server is available"

# make sure replication is started
if [ ${MONGO_REPLICATION} == "Y" ]; then
    mongo-start-replication
fi

# enable fast updates
delay-run-arbitrary-command ${ENABLE_FAST_UPDATES_SECONDS} $PWD/fast-updates-enable.bash &

for threadCount in ${threadCountList}; do
    export NUM_WRITER_THREADS=$threadCount

    export MINI_LOG_NAME=${MACHINE_NAME}-mongoSysbenchExecute-${NUM_COLLECTIONS}-${NUM_DOCUMENTS_PER_COLLECTION}-${NUM_WRITER_THREADS}-${MONGO_TYPE}-${readWriteState}
        
    if [ ${MONGO_TYPE} == "tokumx" ]; then
        if [ ${COMMIT_SYNC} == "1" ]; then
            LOG_NAME=${MINI_LOG_NAME}-SYNC_COMMIT.log
        else
            LOG_NAME=${MINI_LOG_NAME}-NOSYNC_COMMIT.log
        fi
    else
        LOG_NAME=${MINI_LOG_NAME}.log
    fi
        
    export BENCHMARK_TSV=${LOG_NAME}.tsv
    LOG_NAME_IOSTAT=${LOG_NAME}.iostat
    LOG_NAME_MEMORY=${LOG_NAME}.memory
    LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status
        
    rm -f $LOG_NAME
    rm -f $BENCHMARK_TSV
    
    iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
    capture-tokumxstat.bash $ENGINE_STATUS_INTERVAL $LOG_NAME_ENGINE_STATUS &
    
    if [ ${CAPTURE_MEMORY} == "Y" ]; then
        printf "`date` | starting memory capture"
        CAPTURE_MEMORY_INTERVAL=5
        capture-memory.bash ${RUN_TIME_SECONDS} ${CAPTURE_MEMORY_INTERVAL} ${LOG_NAME_MEMORY} mongod &
    fi
    
    if [ ${BENCH_TYPE} == "PRIMARY" ]; then
        ant execute | tee -a $LOG_NAME
    else
        ant executesecondary | tee -a $LOG_NAME
    fi
    
    echo "`date` | pausing for ${PAUSE_BETWEEN_RUNS} seconds"
    sleep ${PAUSE_BETWEEN_RUNS}
    
    bkill
done

echo "`date` | checking counter sums" | tee -a $LOG_NAME
collectionNum=1
sumTotal=0
while [ ${collectionNum} -le ${NUM_COLLECTIONS} ]; do
    thisSum=`$MONGO_DIR/bin/mongo sbtest --eval 'printjson(db.sbtest'${collectionNum}'.aggregate([{ $group: { _id: null, total: {$sum: "$counter"}}}]))' | tail -n1 | cut -f11 -d' '`
    echo "`date` | sbtest${collectionNum} | ${thisSum}" | tee -a $LOG_NAME
    let collectionNum=collectionNum+1
    let sumTotal=sumTotal+thisSum
done
echo "`date` | Grant Total | ${sumTotal}" | tee -a $LOG_NAME

T="$(date +%s)"
echo "`date` | shutting down the server" | tee -a $LOG_NAME
mongo-stop
mongo-is-down
T="$(($(date +%s)-T))"
printf "`date` | shutdown duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

echo "" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
echo "Sizing Information" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME

SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR} | tail -n 1 | cut -f1`
SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${MONGO_DATA_DIR} | tail -n 1 | cut -f1`
SIZE_MB=`echo "scale=2; ${SIZE_BYTES}/(1024*1024)" | bc `
SIZE_APPARENT_MB=`echo "scale=2; ${SIZE_APPARENT_BYTES}/(1024*1024)" | bc `

echo "`date` | post-load sizing (SizeMB / ASizeMB) = ${SIZE_MB} / ${SIZE_APPARENT_MB}" | tee -a $LOG_NAME


if [ ${SCP_FILES} == "Y" ]; then
    DATE=`date +"%Y%m%d%H%M%S"`
    tarFileName="${MACHINE_NAME}-${BENCHMARK_NUMBER}-${DATE}-mongoSysbench-${MONGO_TYPE}-${NUM_COLLECTIONS}-${NUM_DOCUMENTS_PER_COLLECTION}-${BENCH_ID}-${readWriteState}${BENCHMARK_SUFFIX}.tar.gz"

    tar czvf ${tarFileName} ${MACHINE_NAME}*
    scp ${tarFileName} ${SCP_TARGET}:~

    rm -f ${tarFileName}
    rm -f ${MACHINE_NAME}*
    rm -f ${MONGO_LOG}

    #movecores
fi
