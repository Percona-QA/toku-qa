#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536

# > RAM test
export NUM_COLLECTIONS=16
export NUM_DOCUMENTS_PER_COLLECTION=1000000

export NUM_DOCUMENTS_PER_INSERT=1000
export NUM_LOADER_THREADS=8
#export threadCountList="0001 0002 0004 0008 0016 0032 0064 0128 0256 0512 1024"
export threadCountList="0128"
export RUN_TIME_SECONDS=600
export DB_NAME=sbtest
export BENCHMARK_NUMBER=999


# meters for geo search
export SYSBENCH_RANGE_SIZE=100
# limit for geo search
export SYSBENCH_POINT_SELECTS=10
# number of geo searches per transaction
export SYSBENCH_SIMPLE_RANGES=1
export SYSBENCH_SUM_RANGES=0
export SYSBENCH_ORDER_RANGES=0
export SYSBENCH_DISTINCT_RANGES=0
export SYSBENCH_INDEX_UPDATES=0
export SYSBENCH_NON_INDEX_UPDATES=0

export SYSBENCH_READ_ONLY=Y

# FSYNC_SAFE, NONE, NORMAL, REPLICAS_SAFE, SAFE
export WRITE_CONCERN=SAFE

# 8G TokuMX Cache
export TOKUMON_CACHE_SIZE=12G

export MONGO_REPLICATION=Y
export LOCK_MEMORY=Y

# --writeLeafOnFlush (set to true if we should write out leaf nodes on flush instead of keeping them dirty in the cache)
# --compressBuffersBeforeEviction (set to false if we should not bother compressing internal nodes on partial eviction, but instead destroy buffers, like we do with basement nodes)
# --cleanerPeriod 0 (turn off cleaner threads)
#export MONGOD_EXTRA="--cleanerPeriod 0"
#export MONGOD_EXTRA="--setParameter writeLeafOnFlush=true --setParameter compressBuffersBeforeEviction=false"
#unset MONGOD_EXTRA


# lockout memory for pure mongo tests (all but 16G)
if [ -z "$LOCK_MEM_SIZE_16" ]; then
    echo "Need to set LOCK_MEM_SIZE_16"
    exit 1
fi
if [ ${LOCK_MEMORY} == "Y" ]; then
    sudo pkill -9 lockmem
    sudo ~/bin/lockmem $LOCK_MEM_SIZE_16 &
    sleep 10
fi


mongo-clean


# TOKUMX
export BENCHMARK_SUFFIX=".${TOKUMON_CACHE_SIZE}G"
export MONGO_TYPE=tokumx
export TARBALL=tokumx-geo-20140910-linux-x86_64-main
export BENCH_ID=${TARBALL}-${MONGO_COMPRESSION}-${WRITE_CONCERN}-${MONGO_REPLICATION}
#./doit.bash
mongo-clean



# MONGODB 2.4
export TARBALL=mongodb-linux-x86_64-2.4.10
export MONGO_TYPE=mongo
export BENCH_ID=mongo-2.4.10-${WRITE_CONCERN}-${MONGO_REPLICATION}
export BENCHMARK_SUFFIX=".${LOCK_MEM_SIZE_16}lock"
ra-set 32
./doit.bash
mongo-clean
ra-set 256



# ALWAYS unlock memory
sudo pkill -9 lockmem

unset MONGOD_EXTRA
