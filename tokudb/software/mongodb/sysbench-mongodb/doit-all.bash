#!/bin/bash

# **************************************************
# this script assumes that mongod is already running
# **************************************************

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536
export NUM_COLLECTIONS=8
export NUM_DOCUMENTS_PER_COLLECTION=200000
export NUM_DOCUMENTS_PER_INSERT=1000
export MAX_TPS=200
export NUM_LOADER_THREADS=8
export threadCountList="0064"
export RUN_TIME_SECONDS=75000
export DB_NAME=sbtest
export BENCHMARK_NUMBER=999
export WRITE_CONCERN=SAFE
export BENCH_ID=all-test
export MONGO_TYPE=tokumx
export COMMIT_SYNC=1




# ******************************************************************
# LOAD THE DATA
# ******************************************************************

export NUM_INSERTS_PER_FEEDBACK=100000
export NUM_SECONDS_PER_FEEDBACK=-1

ant clean default

LOG_NAME=${MACHINE_NAME}-log-load.txt
    
export BENCHMARK_TSV=${LOG_NAME}.tsv

rm -f $LOG_NAME
rm -f $BENCHMARK_TSV

T="$(date +%s)"
ant load | tee -a $LOG_NAME
echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME




# ******************************************************************
# EXECUTE THE BENCHMARK
# ******************************************************************

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

ant clean default

for threadCount in ${threadCountList}; do
    export NUM_WRITER_THREADS=$threadCount

    LOG_NAME=${MACHINE_NAME}-log-run-${NUM_WRITER_THREADS}.txt
        
    export BENCHMARK_TSV=${LOG_NAME}.tsv
        
    rm -f $LOG_NAME
    rm -f $BENCHMARK_TSV
    
    ant execute | tee -a $LOG_NAME
    
    echo "`date` | pausing for ${PAUSE_BETWEEN_RUNS} seconds"
    sleep ${PAUSE_BETWEEN_RUNS}
done

