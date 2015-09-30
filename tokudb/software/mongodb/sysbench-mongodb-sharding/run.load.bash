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
if [ -z "$NUM_COLLECTIONS" ]; then
    echo "Need to set NUM_COLLECTIONS"
    exit 1
fi
if [ -z "$NUM_DOCUMENTS_PER_COLLECTION" ]; then
    echo "Need to set NUM_DOCUMENTS_PER_COLLECTION"
    exit 1
fi
if [ -z "$NUM_DOCUMENTS_PER_INSERT" ]; then
    echo "Need to set NUM_DOCUMENTS_PER_INSERT"
    exit 1
fi
if [ -z "$NUM_LOADER_THREADS" ]; then
    echo "Need to set NUM_LOADER_THREADS"
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

if [ -z "$shardingTest" ]; then
    export shardingTest=N
fi


RUN_TIME_SECONDS=1000000
IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[RUN_TIME_SECONDS/IOSTAT_INTERVAL+1]
ENGINE_STATUS_INTERVAL=10

ant clean default

export MINI_LOG_NAME=${MACHINE_NAME}-mongoSysbenchLoad-${NUM_COLLECTIONS}-${NUM_DOCUMENTS_PER_COLLECTION}-${NUM_DOCUMENTS_PER_INSERT}-${NUM_LOADER_THREADS}-${MONGO_TYPE}
    
if [ ${MONGO_TYPE} == "tokumx" ]; then
    if [ ${COMMIT_SYNC} == "1" ]; then
        LOG_NAME=${MINI_LOG_NAME}-${MONGO_COMPRESSION}-${MONGO_BASEMENT}-SYNC_COMMIT.log
    else
        LOG_NAME=${MINI_LOG_NAME}-${MONGO_COMPRESSION}-${MONGO_BASEMENT}-NOSYNC_COMMIT.log
    fi
else
    LOG_NAME=${MINI_LOG_NAME}.log
fi
    
export BENCHMARK_TSV=${LOG_NAME}.tsv
export MONGO_LOG=${LOG_NAME}.mongolog
LOG_NAME_IOSTAT=${LOG_NAME}.iostat
LOG_NAME_MEMORY=${LOG_NAME}.memory
LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status

rm -f $LOG_NAME
rm -f $BENCHMARK_TSV

# $MONGO_REPL must be set to something for the server to start in replication mode
#if [ ${MONGO_REPLICATION} == "Y" ]; then
#    export MONGO_REPL="tmcRepl"
#else
    unset MONGO_REPL
#fi

if [ ${shardingTest} == "Y" ]; then
    echo "`date` | starting the ${MONGO_TYPE} SHARDED servers at ${MONGO_DIR}" | tee -a $LOG_NAME
    if [ ${MONGO_TYPE} == "tokumx" ]; then
        mongo-start-tokumx-shard
    else
        mongo-start-pure-shard
    fi
else
    echo "`date` | starting the ${MONGO_TYPE} server at ${MONGO_DIR}" | tee -a $LOG_NAME
    if [ ${MONGO_TYPE} == "tokumx" ]; then
        mongo-start-tokumx-fork
    else
        mongo-start-pure-numa-fork
    fi
    mongo-is-up
    echo "`date` | server is available" | tee -a $LOG_NAME
fi
    
# make sure replication is started, generally you don't want to do it for the loader
#if [ ${MONGO_REPLICATION} == "Y" ]; then
#    mongo-start-replication
#fi

iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
capture-tokumxstat.bash $ENGINE_STATUS_INTERVAL $LOG_NAME_ENGINE_STATUS &

if [ ${CAPTURE_MEMORY} == "Y" ]; then
    printf "`date` | starting memory capture"
    CAPTURE_MEMORY_INTERVAL=5
    capture-memory.bash ${RUN_TIME_SECONDS} ${CAPTURE_MEMORY_INTERVAL} ${LOG_NAME_MEMORY} mongod &
fi

# turn off the balancer for the load process
$MONGO_DIR/bin/mongo admin --host ${MONGO_SERVER} --port ${MONGO_PORT} --eval "sh.setBalancerState(false);"

T="$(date +%s)"
ant load | tee -a $LOG_NAME
echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

# turn the balancer on
$MONGO_DIR/bin/mongo admin --host ${MONGO_SERVER} --port ${MONGO_PORT} --eval "sh.setBalancerState(true);"

bkill
