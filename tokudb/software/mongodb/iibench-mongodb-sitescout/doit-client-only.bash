#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536
export MAX_ROWS=100000000
export RUN_MINUTES=120
export RUN_SECONDS=$[RUN_MINUTES*60]
export NUM_DOCUMENTS_PER_INSERT=1
export MAX_INSERTS_PER_SECOND=999999
#export NUM_INSERTS_PER_FEEDBACK=100000
export NUM_INSERTS_PER_FEEDBACK=-1
export NUM_SECONDS_PER_FEEDBACK=10
#export NUM_LOADER_THREADS=1024
export NUM_LOADER_THREADS=256
export DB_NAME=iibench
export BENCHMARK_NUMBER=999
export MONGO_SERVER=${HOSTNAME}
export MONGO_PORT=30011
#export MONGO_SERVER=localhost
#export MONGO_PORT=27017

# FSYNC_SAFE, NONE, NORMAL, REPLICAS_SAFE, SAFE
export WRITE_CONCERN=SAFE

# set these if you want inserts plus queries
export QUERIES_PER_INTERVAL=0
export QUERY_INTERVAL_SECONDS=15
export QUERY_LIMIT=10
export QUERY_NUM_DOCS_BEGIN=1000000


ant clean default

export LOG_NAME=${MACHINE_NAME}-mongoiibench-${MAX_ROWS}-${NUM_DOCUMENTS_PER_INSERT}-${MAX_INSERTS_PER_SECOND}-${NUM_LOADER_THREADS}-${QUERIES_PER_INTERVAL}-${QUERY_INTERVAL_SECONDS}
export BENCHMARK_TSV=${LOG_NAME}.tsv

rm -f $LOG_NAME
rm -f $BENCHMARK_TSV

T="$(date +%s)"
ant execute | tee -a $LOG_NAME
echo "" | tee -a $LOG_NAME
T="$(($(date +%s)-T))"
printf "`date` | loader duration = %02d:%02d:%02d:%02d\n" "$((T/86400))" "$((T/3600%24))" "$((T/60%60))" "$((T%60))" | tee -a $LOG_NAME
