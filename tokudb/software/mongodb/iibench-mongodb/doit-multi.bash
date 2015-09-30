#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536
export MAX_ROWS=50000000
export RUN_MINUTES=999999
#export NUM_SECONDARY_INDEXES=0
#export NUM_DOCUMENTS_PER_INSERT=1000
export NUM_DOCUMENTS_PER_INSERT=250
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

export TOKUMON_CACHE_SIZE=8G

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

# TOKUMX
export TARBALL=tokumx-2.0.0-linux-x86_64-main
export MONGO_TYPE=tokumx
export MONGO_COMPRESSION=zlib
export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${MONGO_COMPRESSION}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}
#./doit.bash
mongo-clean

# MONGODB
export TARBALL=mongodb-linux-x86_64-2.6.5
export MONGO_TYPE=mongo
export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}-RA16K
ra-set 32
#./doit.bash
ra-set 256
mongo-clean

# MONGODB 2.8 : mmapv1
export TARBALL=mongodb-linux-x86_64-2.8.0-rc4
export MONGO_TYPE=mongo
export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}-RA16K
ra-set 32
#./doit.bash
ra-set 256
mongo-clean

# MONGODB 2.8 : wiredtiger
export TARBALL=mongodb-linux-x86_64-2.8.0-rc4
export MONGO_TYPE=wt
export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}
#./doit.bash
mongo-clean

# MONGODB 2.8 : wiredtiger - ssd
source ~/machine.config.ssd
export TOKUMON_CACHE_SIZE=8G
export TARBALL=mongodb-linux-x86_64-2.8.0-rc4
export MONGO_TYPE=wt
export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}
./doit.bash
mongo-clean

# MONGODB 2.8 : mxse
export TARBALL=mongodb-linux-x86_64-mxse2014120201
export MONGO_TYPE=mxse
export BENCH_ID=${MONGO_TYPE}-${TARBALL}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}
#./doit.bash
mongo-clean



# TOKUMX

#export TARBALL=tokumx-1.4.2-linux-x86_64-main
#export TARBALL=tokumx-1.5.0-alpha.1-linux-x86_64-main
#export MONGO_TYPE=tokumx

# run benchmark for all available compression types
#for c in none quicklz zlib lzma; do
#    export MONGO_COMPRESSION=$c
#    export BENCH_ID=tokumx-1.5.0.alpha.1-${MONGO_COMPRESSION}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}
#    ./doit.bash
#    mongo-clean
#done



# MONGODB

#export TARBALL=mongodb-linux-x86_64-2.6.1
#export MONGO_TYPE=mongo

#export benchmarkList=""
#export benchmarkList="${benchmarkList} mongodb-linux-x86_64-2.2.7.tgz;2.2.7"
#export benchmarkList="${benchmarkList} mongodb-linux-x86_64-2.4.10.tgz;2.4.10"
#export benchmarkList="${benchmarkList} mongodb-linux-x86_64-2.6.1.tgz;2.6.1"

#for thisBenchmark in ${benchmarkList}; do
#    export TARBALL=$(echo "${thisBenchmark}" | cut -d';' -f1)
#    export MINI_BENCH_ID=$(echo "${thisBenchmark}" | cut -d';' -f2)
#    export MONGO_TYPE=mongo
#    export BENCH_ID=mongo-${MINI_BENCH_ID}-${WRITE_CONCERN}-${OPLOG_STRING}-${NUM_SECONDARY_INDEXES}-${NUM_CHAR_FIELDS}-${LENGTH_CHAR_FIELDS}-${PERCENT_COMPRESSIBLE}
#    ./doit.bash
#    mongo-clean
#done



# ALWAYS unlock memory
echo "Removing RAM locker!"
sudo pkill -9 lockmem

unset MONGOD_EXTRA
