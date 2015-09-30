#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536
export TOKUMON_CACHE_SIZE=12G

export NUM_COLLECTIONS=16
export NUM_DOCUMENTS_PER_COLLECTION=10000000
export NUM_DOCUMENTS_PER_INSERT=1000
export threadCountList="0008"
export RUN_TIME_SECONDS=3600
export DB_NAME=sbtest
export BENCHMARK_NUMBER=999
export WRITE_CONCERN=SAFE
export MAX_TPS=31
export SYSBENCH_TYPE=OLTP

export NUM_SECONDS_PER_FEEDBACK=10
export SYSBENCH_RANGE_SIZE=100
export SYSBENCH_POINT_SELECTS=10
export SYSBENCH_SIMPLE_RANGES=1
export SYSBENCH_SUM_RANGES=1
export SYSBENCH_ORDER_RANGES=1
export SYSBENCH_DISTINCT_RANGES=1
export SYSBENCH_INDEX_UPDATES=1
export SYSBENCH_NON_INDEX_UPDATES=1
export PAUSE_BETWEEN_RUNS=60




export MONGO_TYPE=tokumx
#export MONGO_TYPE=mongo

export BENCHMARK_SUFFIX=""


if [ ${MONGO_TYPE} == "tokumx" ]; then
    # TOKUMX
    export BENCH_ID=tokumx-1.3.1-${MONGO_COMPRESSION}-${WRITE_CONCERN}
else
    # MONGODB 2.4
    export BENCH_ID=mongo-2.4.8-${WRITE_CONCERN}
fi    






ant clean default

export MINI_LOG_NAME=${MACHINE_NAME}-mongoSysbenchExecute-${NUM_COLLECTIONS}-${NUM_DOCUMENTS_PER_COLLECTION}-${MONGO_TYPE}

for threadCount in ${threadCountList}; do
    export NUM_WRITER_THREADS=$threadCount

    export LOG_NAME=${MACHINE_NAME}-mongoSysbenchExecute-${NUM_COLLECTIONS}-${NUM_DOCUMENTS_PER_COLLECTION}-${NUM_WRITER_THREADS}-${MONGO_TYPE}
        
    export BENCHMARK_TSV=${LOG_NAME}.tsv
        
    rm -f $LOG_NAME
    rm -f $BENCHMARK_TSV
    
    ant execute | tee -a $LOG_NAME
    
    echo "`date` | pausing for ${PAUSE_BETWEEN_RUNS} seconds"
    sleep ${PAUSE_BETWEEN_RUNS}
done

