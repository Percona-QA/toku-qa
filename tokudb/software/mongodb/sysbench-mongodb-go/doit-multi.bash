#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536

# < RAM test
export NUM_COLLECTIONS=16
export NUM_DOCUMENTS_PER_COLLECTION=250000
#export NUM_DOCUMENTS_PER_COLLECTION=1000000
# > RAM test
#export NUM_COLLECTIONS=16
#export NUM_DOCUMENTS_PER_COLLECTION=10000000

export NUM_DOCUMENTS_PER_INSERT=1000
export NUM_LOADER_THREADS=8
export threadCountList="0008 0032 0128 1024"
export RUN_TIME_SECONDS=60
export DB_NAME=sbtest
export BENCHMARK_NUMBER=100

# FSYNC_SAFE, NONE, NORMAL, REPLICAS_SAFE, SAFE
export WRITE_CONCERN=SAFE

# 12G TokuMX Cache
export TOKUMON_CACHE_SIZE=12G

export MONGO_REPLICATION=Y
export LOCK_MEMORY=N

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



# TOKUMX
export MONGO_REPLICATION=Y
export TARBALL=tokumx-1.5.0-linux-x86_64-main
export MONGO_TYPE=tokumx
export BENCH_ID=${TARBALL}-${MONGO_COMPRESSION}-${WRITE_CONCERN}-${MONGO_REPLICATION}
export BENCHMARK_SUFFIX=".12G"
./doit.bash
mongo-clean

# MONGODB 2.4
export MONGO_REPLICATION=N
export TARBALL=mongodb-linux-x86_64-2.4.9
export MONGO_TYPE=mongo
export BENCH_ID=mongo-2.4.9-${WRITE_CONCERN}-${MONGO_REPLICATION}
export BENCHMARK_SUFFIX=".${LOCK_MEM_SIZE_16}lock"
#ra-set 32
#./doit.bash
#mongo-clean
#ra-set 256



# ALWAYS unlock memory
sudo pkill -9 lockmem

unset MONGOD_EXTRA
