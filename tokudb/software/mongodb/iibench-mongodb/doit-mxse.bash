#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536
export MAX_ROWS=999999999
export RUN_MINUTES=15
#export NUM_SECONDARY_INDEXES=0
export NUM_DOCUMENTS_PER_INSERT=1000
export MAX_INSERTS_PER_SECOND=999999
export NUM_INSERTS_PER_FEEDBACK=-1
export NUM_SECONDS_PER_FEEDBACK=10
export NUM_LOADER_THREADS=4
export DB_NAME=iibench
export BENCHMARK_NUMBER=999
#export MONGO_SERVER=mork
#export MONGO_PORT=30000
export MONGO_SERVER=localhost
export MONGO_PORT=27017

export NUM_CHAR_FIELDS=0
export LENGTH_CHAR_FIELDS=1000
export PERCENT_COMPRESSIBLE=90

export MONGO_REPLICATION=Y
if [ ${MONGO_REPLICATION} == "Y" ]; then
    export OPLOG_STRING="OpLogON"
else
    export OPLOG_STRING="OpLogOFF"
fi

# FSYNC_SAFE, NONE, NORMAL, REPLICAS_SAFE, SAFE
export WRITE_CONCERN=SAFE

# set these if you want inserts plus queries
export QUERIES_PER_INTERVAL=0
export QUERY_INTERVAL_SECONDS=15
export QUERY_LIMIT=10
export QUERY_NUM_DOCS_BEGIN=1000000

export TOKUMON_CACHE_SIZE=2G

# if LOCK_MEMORY=Y, then all but 8G of RAM on the server is locked
export LOCK_MEMORY=N


if [ -z "$LOCK_MEM_SIZE_8" ]; then
    echo "Need to set LOCK_MEM_SIZE_8"
    exit 1
fi

# lock out all but 8G
if [ ${LOCK_MEMORY} == "Y" ]; then
    echo "Removing RAM locker, 5 second sleep"
    sudo pkill -9 lockmem
    sleep 5
    echo "Locking all but 8G of RAM, 10 second sleep"
    sudo ~/bin/lockmem $LOCK_MEM_SIZE_8 &
    sleep 10
    export BENCHMARK_SUFFIX=".${LOCK_MEM_SIZE_8}-lock"
else
    unset BENCHMARK_SUFFIX
fi

export LOCK_TIMEOUT=500

mongo-clean


# TOKUMX
export TARBALL=tokumx-2.0.0-linux-x86_64-main
export MONGO_TYPE=tokumx
for numLoaderThreads in 1 2 4 8 ; do
    export NUM_LOADER_THREADS=${numLoaderThreads}
    export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${MONGO_COMPRESSION}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}-${NUM_LOADER_THREADS}
    ./doit.bash
    mongo-clean
done


# MONGODB 2.8 : mxse
for mxseBuild in mxse2014120201 mxse2014120401 mxse2014120501 ; do
    export TARBALL=mongodb-linux-x86_64-${mxseBuild}
    export MONGO_TYPE=mxse
    for numLoaderThreads in 1 2 4 8 ; do
        export NUM_LOADER_THREADS=${numLoaderThreads}
        export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}-${NUM_LOADER_THREADS}
        ./doit.bash
        mongo-clean
    done
done


# MONGODB 2.8 : mxse
#export NUM_LOADER_THREADS=1
#export TARBALL=mongodb-linux-x86_64-mxse2014120501
#export MONGO_TYPE=mxse
#export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}-${NUM_LOADER_THREADS}
#export STARTUP_MONGO=Y
#export SHUTDOWN_MONGO=N
#export CREATE_COLLECTION=Y
#./doit.bash

#export STARTUP_MONGO=N
#export SHUTDOWN_MONGO=N
#export CREATE_COLLECTION=N
#for numLoaderThreads in 2 3 4 5 6 7 8 ; do
#    export NUM_LOADER_THREADS=${numLoaderThreads}
#    export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}-${NUM_LOADER_THREADS}
#    ./doit.bash
#done
#
# pkill -9 mongo; sleep 5; bkill; sleep 5
#mongo-clean








# ALWAYS unlock memory
echo "Removing RAM locker!"
sudo pkill -9 lockmem
