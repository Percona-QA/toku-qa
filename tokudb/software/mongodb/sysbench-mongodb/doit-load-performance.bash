#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536

# < RAM test
export NUM_COLLECTIONS=16
export NUM_DOCUMENTS_PER_COLLECTION=1000000

export NUM_DOCUMENTS_PER_INSERT=1000
export NUM_LOADER_THREADS=8
#export threadCountList="0001 0002 0004 0008 0016 0032 0064 0128 0256 0512 1024"
export threadCountList="0064"
export RUN_TIME_SECONDS=30
export DB_NAME=sbtest
export BENCHMARK_NUMBER=999

# FSYNC_SAFE, NONE, NORMAL, REPLICAS_SAFE, SAFE
export WRITE_CONCERN=SAFE

export TOKUMON_CACHE_SIZE=8G

export MONGO_REPLICATION=N
export LOCK_MEMORY=Y



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


for loaderThreads in 1 2 3 4 ; do
    export NUM_COLLECTIONS=${loaderThreads}
    export NUM_LOADER_THREADS=${loaderThreads}

    # TOKUMX
    export BENCHMARK_SUFFIX=".${TOKUMON_CACHE_SIZE}G"
    export MONGO_TYPE=tokumx
    export TARBALL=tokumx-2.0.0-linux-x86_64-main
    export BENCH_ID=${TARBALL}-${MONGO_COMPRESSION}-${WRITE_CONCERN}-${MONGO_REPLICATION}-${loaderThreads}-1db-mx20
    #./doit.bash
    mongo-clean
    unset BENCHMARK_SUFFIX
    
    # MONGODB 2.4
    export TARBALL=mongodb-linux-x86_64-2.4.12
    export MONGO_TYPE=mongo
    export BENCH_ID=${TARBALL}-${WRITE_CONCERN}-${MONGO_REPLICATION}-${loaderThreads}-1db-mmapv1
    export BENCHMARK_SUFFIX=".${LOCK_MEM_SIZE_16}lock"
    ra-set 32
    #./doit.bash
    mongo-clean
    ra-set 256
    unset BENCHMARK_SUFFIX
    
    # MONGODB 2.6
    export TARBALL=mongodb-linux-x86_64-2.6.6
    export MONGO_TYPE=mongo
    export BENCH_ID=${TARBALL}-${WRITE_CONCERN}-${MONGO_REPLICATION}-${loaderThreads}-1db-mmapv1
    export BENCHMARK_SUFFIX=".${LOCK_MEM_SIZE_16}lock"
    ra-set 32
    #./doit.bash
    mongo-clean
    ra-set 256
    unset BENCHMARK_SUFFIX
    
    # MONGODB 2.8 : mmapv1
    export TARBALL=mongodb-linux-x86_64-2.8.0-rc4
    export MONGO_TYPE=mongo
    export BENCH_ID=${TARBALL}-${WRITE_CONCERN}-${MONGO_REPLICATION}-${loaderThreads}-1db-mmapv1
    export BENCHMARK_SUFFIX=".${LOCK_MEM_SIZE_16}lock"
    ra-set 32
    ./doit.bash
    mongo-clean
    ra-set 256
    unset BENCHMARK_SUFFIX
    
    # MONGODB 2.8 : mxse
    export BENCHMARK_SUFFIX=".${TOKUMON_CACHE_SIZE}G"
    export TARBALL=mongodb-linux-x86_64-mxse2014120401
    export MONGO_TYPE=mxse
    export BENCH_ID=${TARBALL}-${MONGO_COMPRESSION}-${WRITE_CONCERN}-${MONGO_REPLICATION}-1db-${loaderThreads}-mxse
    #./doit.bash
    mongo-clean
    unset BENCHMARK_SUFFIX
done


# ALWAYS unlock memory
sudo pkill -9 lockmem

unset MONGOD_EXTRA
