#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536
export MAX_ROWS=100000000
export RUN_MINUTES=60
export NUM_SECONDARY_INDEXES=3
export NUM_DOCUMENTS_PER_INSERT=100
export MAX_INSERTS_PER_SECOND=999999
export NUM_INSERTS_PER_FEEDBACK=-1
export NUM_SECONDS_PER_FEEDBACK=60
export NUM_LOADER_THREADS=1
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
export QUERY_INTERVAL_SECONDS=10
export QUERY_LIMIT=10
export QUERY_NUM_DOCS_BEGIN=1000000

export TOKUMON_CACHE_SIZE=512M
export TOKUMX_BUFFERED_IO=N

# if LOCK_MEMORY=Y, then all but 8G of RAM on the server is locked
export LOCK_MEMORY=N

# --writeLeafOnFlush (set to true if we should write out leaf nodes on flush instead of keeping them dirty in the cache)
# --compressBuffersBeforeEviction (set to false if we should not bother compressing internal nodes on partial eviction, but instead destroy buffers, like we do with basement nodes)
# --cleanerPeriod 0 (turn off cleaner threads)
#export MONGOD_EXTRA="--cleanerPeriod 0"
#export MONGOD_EXTRA="--setParameter writeLeafOnFlush=true --setParameter compressBuffersBeforeEviction=false"
#unset MONGOD_EXTRA


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

mongo-clean


export PARTITION_ROWS=1000000
export DELETE_AT_ROWS=20000000
export DELETE_PERCENTAGE=1
export PERCENTAGE_OVER_ALLOWED=10
export CAPTURE_TOKUMX=N


# TOKUMX - OLD SCHOOL DELETES
export TARBALL=tokumx-1.5.0-linux-x86_64-main
export MONGO_TYPE=tokumx
export MONGO_COMPRESSION=zlib
export USE_PARTITIONING=N
export BENCH_ID=DELETING-${TARBALL}-${MONGO_COMPRESSION}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}
./doit.bash
mongo-clean
unset USE_PARTITIONING


# TOKUMX - USING PARTITIONING
export TARBALL=tokumx-1.5.0-linux-x86_64-main
export MONGO_TYPE=tokumx
export MONGO_COMPRESSION=zlib
export USE_PARTITIONING=Y
export BENCH_ID=PARTITIONING-${TARBALL}-${MONGO_COMPRESSION}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}
./doit.bash
mongo-clean
unset USE_PARTITIONING


# MONGODB
#export TARBALL=mongodb-linux-x86_64-2.6.1
#export MONGO_TYPE=mongo
#export BENCH_ID=${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}-RA16K
#ra-set 32
#./doit.bash
#ra-set 256
#mongo-clean



# ALWAYS unlock memory
echo "Removing RAM locker!"
sudo pkill -9 lockmem

unset MONGOD_EXTRA
