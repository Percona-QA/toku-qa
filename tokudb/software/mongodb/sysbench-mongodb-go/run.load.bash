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
    export NUM_INSERTS_PER_FEEDBACK=-1
fi
if [ -z "$NUM_SECONDS_PER_FEEDBACK" ]; then
    export NUM_SECONDS_PER_FEEDBACK=10
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

#iostat -dxm $IOSTAT_INTERVAL $IOSTAT_ROUNDS  > $LOG_NAME_IOSTAT &
#capture-tokumxstat.bash $ENGINE_STATUS_INTERVAL $LOG_NAME_ENGINE_STATUS &

#if [ ${CAPTURE_MEMORY} == "Y" ]; then
#    printf "`date` | starting memory capture"
#    CAPTURE_MEMORY_INTERVAL=5
#    capture-memory.bash ${RUN_TIME_SECONDS} ${CAPTURE_MEMORY_INTERVAL} ${LOG_NAME_MEMORY} mongod &
#fi

T="$(date +%s)"

${GOPATH}/src/github.com/Tokutek/go-benchmark/benchmarks/sysbench/sysbenchload/sysbenchload \
   -basementSize=${MONGO_BASEMENT} \
   -compression=${MONGO_COMPRESSION} \
   -create=true \
   -db=${DB_NAME} \
   -docsPerInsert=${NUM_DOCUMENTS_PER_INSERT} \
   -numWriters=${NUM_LOADER_THREADS} \
   -numCollections=${NUM_COLLECTIONS} \
   -numInsertsPerCollection=${NUM_DOCUMENTS_PER_COLLECTION} \
   -outputSecondsInterval=${NUM_SECONDS_PER_FEEDBACK} | tee -a $LOG_NAME

#   -numSeconds=${RUN_SECONDS} \
#   -queriesPerInterval=${QUERIES_PER_INTERVAL} \
#   -queryInterval=${QUERY_INTERVAL_SECONDS} \
#   -queryResultLimit=${QUERY_LIMIT} \
#   -numQueryThreads=1 \
#  -charFieldLength=5: specify length of char fields
#  -coll="purchases_index": collname
#  -host="localhost": host:port string of database to connect to
#  -insertInterval=1: interval for inserts, in seconds, meant to be used with -insertsPerInterval
#  -insertsPerInterval=0: max inserts per interval, 0 means unlimited
#  -nodeSize=4194304: specify the node size of all indexes in the collection, only takes affect if -create is true
#  -numCharFields=0: specify the number of additional char fields stored in an array
#  -numCollections=1: number of collections to simultaneously run on
#  -numInsertsPerThread=0: number of inserts to be done per thread. If this value is > 0, then numSeconds MUST be 0 and numQueryThreads MUST be 0
#  -partition=false: whether to partition the collections on create


echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME

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
