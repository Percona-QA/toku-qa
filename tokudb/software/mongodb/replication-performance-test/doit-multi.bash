#!/bin/bash

export MONGO_COMPRESSION=zlib
export MONGO_BASEMENT=65536
export NUM_COLLECTIONS=4
export NUM_DOCUMENTS_PER_COLLECTION=10000000
export NUM_DOCUMENTS_PER_INSERT=1000
export NUM_LOADER_THREADS=8
export threadCountList="0128"
export RUN_TIME_SECONDS=1800
export DB_NAME=sbtest
export BENCHMARK_NUMBER=999

export TOKUMON_CACHE_SIZE=26442450944


# lock out all but 8G
#if [ -z "$LOCK_MEM_SIZE_8" ]; then
#    echo "Need to set LOCK_MEM_SIZE_8"
#    exit 1
#fi

#export BENCHMARK_SUFFIX=".${LOCK_MEM_SIZE_8}-lock"



# need to lockout memory for pure mongo tests
#sudo pkill -9 lockmem
#sudo ~/bin/lockmem $LOCK_MEM_SIZE_8 &


# TOKUMX
export TARBALL=tokumx-1.0.3-linux-x86_64
export MONGO_TYPE=tokumx
export MONGO_REPLICATION=N
export BENCH_ID=tokumx-1.0.3-${MONGO_COMPRESSION}
./doit-load.bash
#mongo-clean

# MONGODB 2.2
export TARBALL=mongodb-linux-x86_64-2.2.5
export MONGO_TYPE=mongo
export MONGO_REPLICATION=N
export BENCH_ID=mongo-2.2.5
#./doit-load.bash
#mongo-clean

# MONGODB 2.4
#export TARBALL=mongodb-linux-x86_64-2.4.4
#export MONGO_TYPE=mongo
#export MONGO_REPLICATION=N
#export BENCH_ID=mongo-2.4.4
#./doit-load.bash
#mongo-clean


# unlock memory
#sudo pkill -9 lockmem
