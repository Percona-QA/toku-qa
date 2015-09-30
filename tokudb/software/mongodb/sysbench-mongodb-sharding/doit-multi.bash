#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536

export NUM_COLLECTIONS=12
#export NUM_DOCUMENTS_PER_COLLECTION=10000000
export NUM_DOCUMENTS_PER_COLLECTION=1000000

export NUM_DOCUMENTS_PER_INSERT=1000
export NUM_LOADER_THREADS=${NUM_COLLECTIONS}
#export NUM_LOADER_THREADS=3
export RUN_TIME_SECONDS=300
export DB_NAME=sbtest
export BENCHMARK_NUMBER=999

# FSYNC_SAFE, NONE, NORMAL, REPLICAS_SAFE, SAFE
export WRITE_CONCERN=SAFE

# 4G TokuMX Cache
export TOKUMON_CACHE_SIZE=4G

export CAPTURE_MEMORY=N

export MONGO_REPLICATION=N
#export LOCK_MEMORY=N

export MONGO_SERVER=localhost
export MONGO_PORT=30011


# --writeLeafOnFlush (set to true if we should write out leaf nodes on flush instead of keeping them dirty in the cache)
# --compressBuffersBeforeEviction (set to false if we should not bother compressing internal nodes on partial eviction, but instead destroy buffers, like we do with basement nodes)
# --cleanerPeriod 0 (turn off cleaner threads)
#export MONGOD_EXTRA="--cleanerPeriod 0"
#export MONGOD_EXTRA="--setParameter writeLeafOnFlush=true --setParameter compressBuffersBeforeEviction=false"
#unset MONGOD_EXTRA


export shardingTest=Y


export LOCK_MEMORY=Y

# lockout memory for pure mongo tests (all but 16G)
if [ -z "$LOCK_MEM_SIZE_16" ]; then
    echo "Need to set LOCK_MEM_SIZE_16"
    exit 1
fi

if [ ${LOCK_MEMORY} == "Y" ]; then
    sudo pkill -9 lockmem
    sleep 5
    sudo ~/bin/lockmem $LOCK_MEM_SIZE_16 &
    sleep 10
fi



# TOKUMX
export TARBALL=tokumx-1.4.0-rc.0-linux-x86_64-main
export MONGO_TYPE=tokumx
export BENCH_ID=tokumx-1.4.0.rc0-${MONGO_COMPRESSION}-${WRITE_CONCERN}
export BENCHMARK_SUFFIX=".4G"
#export TOKUMX_BUFFERED_IO=Y
export TOKUMX_BUFFERED_IO=N
#./doit.bash
#mongo-clean


# MONGODB 2.4 - with lowered readahead
export NUM_DOCUMENTS_PER_INSERT=100
#export NUM_LOADER_THREADS=1
export TARBALL=mongodb-linux-x86_64-2.4.9
export MONGO_TYPE=mongo
export BENCH_ID=mongo-2.4.9-${WRITE_CONCERN}
export BENCHMARK_SUFFIX=".${LOCK_MEM_SIZE_16}lock"
ra-set 32
./doit.bash
#mongo-clean
#ra-set 256


# keep the balancer off
$MONGO_DIR/bin/mongo admin --host ${MONGO_SERVER} --port ${MONGO_PORT} --eval "sh.setBalancerState(false);"


# ALWAYS unlock memory
#sudo pkill -9 lockmem

unset MONGOD_EXTRA
