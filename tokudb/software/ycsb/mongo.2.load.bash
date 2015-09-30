#!/bin/bash

if [ -z "$MONGO_DIR" ]; then
    echo "Need to set MONGO_DIR"
    exit 1
fi
if [ -z "$MONGO_TYPE" ]; then
    echo "Need to set MONGO_TYPE"
    exit 1
fi
if [ -z "$MONGO_COMPRESSION" ]; then
    echo "Need to set MONGO_COMPRESSION"
    exit 1
fi
if [ -z "$MONGO_BASEMENT" ]; then
    echo "Need to set MONGO_BASEMENT"
    exit 1
fi
if [ -z "$RECORDCOUNT" ]; then
    echo "Need to set RECORDCOUNT"
    exit 1
fi
if [ -z "$DB_NAME" ]; then
    echo "Need to set DB_NAME"
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
if [ -z "$MONGO_URL" ]; then
    echo "Need to set MONGO_URL"
    exit 1
fi
if [ -z "$YCSB_DIR" ]; then
    echo "Need to set YCSB_DIR"
    exit 1
fi
if [ -z "$SCP_FILES" ]; then
    echo "Need to set SCP_FILES"
    exit 1
fi
if [ -z "$BENCH_ID" ]; then
    echo "Need to set BENCH_ID"
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
if [ -z "$COMMIT_SYNC" ]; then
    export COMMIT_SYNC=1
fi

if [ -z "$CAPTURE_MEMORY" ]; then
    export CAPTURE_MEMORY=Y
fi


RUN_TIME_SECONDS=1000000
IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[RUN_TIME_SECONDS/IOSTAT_INTERVAL+1]

export MINI_LOG_NAME=${MACHINE_NAME}-ycsbLoad-${RECORDCOUNT}-${MONGO_TYPE}
    
if [ ${MONGO_TYPE} == "tokumx" ]; then
    if [ ${COMMIT_SYNC} == "1" ]; then
        LOG_NAME=${MINI_LOG_NAME}-${MONGO_COMPRESSION}-${MONGO_BASEMENT}-SYNC_COMMIT.log
    else
        LOG_NAME=${MINI_LOG_NAME}-${MONGO_COMPRESSION}-${MONGO_BASEMENT}-NOSYNC_COMMIT.log
    fi
else
    LOG_NAME=${MINI_LOG_NAME}.log
fi
    
export MONGO_LOG=${LOG_NAME}.mongolog
LOG_NAME_IOSTAT=${LOG_NAME}.iostat
LOG_NAME_MEMORY=${LOG_NAME}.memory

rm -f $LOG_NAME
rm -f $BENCHMARK_TSV

# $MONGO_REPL must be set to something for the server to start in replication mode
#if [ ${MONGO_REPLICATION} == "Y" ]; then
#    export MONGO_REPL="tmcRepl"
#else
    unset MONGO_REPL
#fi

echo "`date` | starting the ${MONGO_TYPE} server at ${MONGO_DIR}" | tee -a $LOG_NAME
if [ ${MONGO_TYPE} == "tokumx" ]; then
    mongo-start-tokumx-fork
else
    mongo-start-pure-numa-fork
fi

mongo-is-up
echo "`date` | server is available" | tee -a $LOG_NAME

# make sure replication is started, generally you don't want to do it for the loader
#if [ ${MONGO_REPLICATION} == "Y" ]; then
#    mongo-start-replication
#fi

iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &

if [ ${CAPTURE_MEMORY} == "Y" ]; then
    echo "`date` | starting memory capture"
    CAPTURE_MEMORY_INTERVAL=5
    capture-memory.bash ${RUN_TIME_SECONDS} ${CAPTURE_MEMORY_INTERVAL} ${LOG_NAME_MEMORY} mongod &
fi

echo "`date` | starting the load process" | tee -a $LOG_NAME
T="$(date +%s)"
${YCSB_DIR}/bin/ycsb load mongodb -P ${YCSB_DIR}/workloads/workloada -p mongodb.url=${MONGO_URL} -p mongodb.database=${DB_NAME} -p mongodb.writeConcern=${WRITE_CONCERN} -p recordcount=${RECORDCOUNT} -s | tee -a $LOG_NAME
echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME
grep "Throughput(ops/sec)" $LOG_NAME

T="$(date +%s)"
echo "`date` | shutting down the server" | tee -a $LOG_NAME
mongo-stop
mongo-is-down
T="$(($(date +%s)-T))"
printf "`date` | shutdown duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME
    
bkill
    
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
    tarFileName="${MACHINE_NAME}-${BENCHMARK_NUMBER}-${DATE}-mongoYcsbLoad-${MONGO_TYPE}-${RECORDCOUNT}-${BENCH_ID}.tar.gz"

    tar czvf ${tarFileName} ${MACHINE_NAME}*
    scp ${tarFileName} ${SCP_TARGET}:~

    rm -f ${tarFileName}
    rm -f ${MACHINE_NAME}*
fi
