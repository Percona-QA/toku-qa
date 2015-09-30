#!/bin/bash

# this is the "execution" script for the benchmark
#   it must be called from a higher-level script

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
if [ -z "$MAX_ROWS" ]; then
    echo "Need to set MAX_ROWS"
    exit 1
fi
if [ -z "$NUM_DOCUMENTS_PER_INSERT" ]; then
    echo "Need to set NUM_DOCUMENTS_PER_INSERT"
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
if [ -z "$DB_NAME" ]; then
    echo "Need to set DB_NAME"
    exit 1
fi
if [ -z "$MONGO_REPLICATION" ]; then
    echo "Need to set MONGO_REPLICATION"
    exit 1
fi
if [ -z "$RUN_SECONDS" ]; then
    echo "Need to set RUN_SECONDS"
    exit 1
fi
if [ -z "$WRITE_CONCERN" ]; then
    echo "Need to set WRITE_CONCERN"
    exit 1
fi
if [ -z "$MONGO_SERVER" ]; then
    echo "Need to set MONGO_SERVER"
    exit 1
fi
if [ -z "$MONGO_PORT" ]; then
    echo "Need to set MONGO_PORT"
    exit 1
fi
if [ -z "$NUM_SECONDARY_INDEXES" ]; then
    echo "Need to set NUM_SECONDARY_INDEXES"
    exit 1
fi
if [ -z "$STARTUP_MONGO" ]; then
    echo "Need to set STARTUP_MONGO"
    exit 1
fi
if [ -z "$SHUTDOWN_MONGO" ]; then
    echo "Need to set SHUTDOWN_MONGO"
    exit 1
fi
if [ -z "$CREATE_COLLECTION" ]; then
    echo "Need to set CREATE_COLLECTION"
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
if [ -z "$QUERY_NUM_DOCS_BEGIN" ]; then
    export QUERY_NUM_DOCS_BEGIN=10000000
fi

if [ -z "$CAPTURE_MEMORY" ]; then
    export CAPTURE_MEMORY=Y
fi

if [ -z "$MULTI_DB_BENCHMARK" ]; then
    export MULTI_DB_BENCHMARK=N
fi


IOSTAT_INTERVAL=10
IOSTAT_ROUNDS=$[RUN_SECONDS/IOSTAT_INTERVAL+1]
ENGINE_STATUS_INTERVAL=10
IOSTAT_DATASIZE_INTERVAL=60

ant clean default

export MINI_LOG_NAME=${MACHINE_NAME}-mongoiibench-${NUM_COLLECTIONS}-${MAX_ROWS}-${NUM_DOCUMENTS_PER_INSERT}-${MAX_INSERTS_PER_SECOND}-${NUM_LOADER_THREADS}-${MONGO_TYPE}-${QUERIES_PER_INTERVAL}-${QUERY_INTERVAL_SECONDS}
    
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
LOG_NAME_IOSTAT_DATASIZE=${LOG_NAME}.iostat-datasize
LOG_NAME_MEMORY=${LOG_NAME}.memory
LOG_NAME_ENGINE_STATUS=${LOG_NAME}.engine_status

rm -f $LOG_NAME
rm -f $BENCHMARK_TSV

# $MONGO_REPL must be set to something for the server to start in replication mode
if [ ${MONGO_REPLICATION} == "Y" ]; then
    export MONGO_REPL="tmcRepl"
else
    unset MONGO_REPL
fi

if [ ${STARTUP_MONGO} == "Y" ] ; then
    echo "`date` | starting the ${MONGO_TYPE} server at ${MONGO_DIR}" | tee -a $LOG_NAME
    if [ ${MONGO_TYPE} == "tokumx" ]; then
        mongo-start-tokumx-fork
    else
        mongo-start-pure-numa-fork
    fi
else
    echo "`date` | using the existing ${MONGO_TYPE} server at ${MONGO_DIR}" | tee -a $LOG_NAME
fi
    
mongo-is-up
echo "`date` | server is available" | tee -a $LOG_NAME

if [ ${STARTUP_MONGO} == "Y" ] ; then
    # make sure replication is started, generally you don't want to do it for the loader
    if [ ${MONGO_REPLICATION} == "Y" ]; then
        mongo-start-replication
    fi
fi

iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
capture-tokumxstat.bash $ENGINE_STATUS_INTERVAL $LOG_NAME_ENGINE_STATUS &
./capture-iostat-datasize.bash $IOSTAT_DATASIZE_INTERVAL $LOG_NAME_IOSTAT_DATASIZE $BENCHMARK_TSV &

if [ ${CAPTURE_MEMORY} == "Y" ]; then
    printf "`date` | starting memory capture"
    CAPTURE_MEMORY_INTERVAL=5
    capture-memory.bash ${RUN_SECONDS} ${CAPTURE_MEMORY_INTERVAL} ${LOG_NAME_MEMORY} mongod &
fi

T="$(date +%s)"

if [ ${MULTI_DB_BENCHMARK} == "N" ]; then
    ant execute | tee -a $LOG_NAME
else
    ant execute-multi-db | tee -a $LOG_NAME
fi
    
echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

if [ ${SHUTDOWN_MONGO} == "Y" ] ; then
    T="$(date +%s)"
    echo "`date` | shutting down the server" | tee -a $LOG_NAME
    mongo-stop
    mongo-is-down
    T="$(($(date +%s)-T))"
    printf "`date` | shutdown duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME
else
    echo "`date` | leaving the server running" | tee -a $LOG_NAME
fi

echo "" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
echo "Sizing Information" | tee -a $LOG_NAME
echo "-------------------------------" | tee -a $LOG_NAME
        
SIZE_BYTES=`du -c --block-size=1 ${MONGO_DATA_DIR} | tail -n 1 | cut -f1`
SIZE_APPARENT_BYTES=`du -c --block-size=1 --apparent-size ${MONGO_DATA_DIR} | tail -n 1 | cut -f1`
SIZE_MB=`echo "scale=2; ${SIZE_BYTES}/(1024*1024)" | bc `
SIZE_APPARENT_MB=`echo "scale=2; ${SIZE_APPARENT_BYTES}/(1024*1024)" | bc `
echo "`date` | post-load sizing (SizeMB / ASizeMB) = ${SIZE_MB} / ${SIZE_APPARENT_MB}" | tee -a $LOG_NAME

bkill

if [ ${SCP_FILES} == "Y" ]; then
    DATE=`date +"%Y%m%d%H%M%S"`
    tarFileName="${MACHINE_NAME}-${BENCHMARK_NUMBER}-${DATE}-mongoiibench-${BENCH_ID}-${NUM_LOADER_THREADS}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}${BENCHMARK_SUFFIX}.tar.gz"

    tar czvf ${tarFileName} ${MACHINE_NAME}*
    scp ${tarFileName} ${SCP_TARGET}:~

    rm -f ${tarFileName}

    # keep the server log around if we aren't shutting down the server
    if [ ${SHUTDOWN_MONGO} == "Y" ] ; then
        rm -f ${MACHINE_NAME}*
    else
        ls ${MACHINE_NAME}* | grep -v mongolog | xargs rm -f
    fi

    #movecores
fi
